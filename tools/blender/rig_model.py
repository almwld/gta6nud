#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Local GLB import -> basic human armature -> skinning -> optional actions -> GLB export.

Run:
  blender -b -P tools/blender/rig_model.py -- --input ./model.glb --output ./model_rigged.glb
  blender -b -P tools/blender/rig_model.py -- --input ./model.glb --output ./model_rigged.glb --no-animations
  blender -b -P tools/blender/rig_model.py -- --input ./model.glb --output ./model_clean.glb --process-only

This is a geometric starter rig, not an automatic human-pose detector. Best results
require an upright human mesh in a roughly A/T-pose. Review weights and joint placement
in Blender before shipping production assets.
"""
import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def args_from_cli():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Local input .glb/.gltf file")
    parser.add_argument("--output", required=True, help="Output .glb file")
    parser.add_argument("--process-only", action="store_true", help="Import and re-export without rigging")
    parser.add_argument("--no-animations", action="store_true", help="Create a rig but no generated actions")
    parser.add_argument("--scale", type=float, default=1.0, help="Uniform scale applied to imported meshes")
    parser.add_argument("--keep-existing-rig", action="store_true", default=True,
                        help="Reuse an existing armature instead of adding a second one (default)")
    return parser.parse_args(argv)


def log(message):
    print("[RIG_MODEL] " + str(message), flush=True)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.armatures, bpy.data.actions):
        # Remove only unused data; imported material/image data is preserved as needed.
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def import_model(filepath):
    path = Path(filepath).expanduser().resolve()
    if not path.is_file():
        raise FileNotFoundError("Input model does not exist: " + str(path))
    if path.suffix.lower() not in (".glb", ".gltf"):
        raise ValueError("Input must be a .glb or .gltf file")
    result = bpy.ops.import_scene.gltf(filepath=str(path))
    if "FINISHED" not in result:
        raise RuntimeError("Blender could not import " + str(path))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("The imported model contains no mesh objects")
    log("Imported %s (%d mesh objects)" % (path, len(meshes)))
    return meshes


def world_bounds(meshes):
    points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    if not points:
        raise RuntimeError("Cannot calculate model bounds")
    return (
        min(p.x for p in points), max(p.x for p in points),
        min(p.y for p in points), max(p.y for p in points),
        min(p.z for p in points), max(p.z for p in points),
    )


# Bone definitions use normalized height (0..1) and normalized half-width (-1..1).
# Coordinates are generated from the actual world-space bounds of the imported meshes.
BONE_LAYOUT = [
    ("hips",       (0.00, .53), (0.00, .62), None),
    ("spine",      (0.00, .62), (0.00, .70), "hips"),
    ("chest",      (0.00, .70), (0.00, .80), "spine"),
    ("neck",       (0.00, .80), (0.00, .86), "chest"),
    ("head",       (0.00, .86), (0.00, .98), "neck"),
    ("shoulder.L", (.00, .78), (.24, .78), "chest"),
    ("upper_arm.L",(.24, .78), (.52, .76), "shoulder.L"),
    ("forearm.L",  (.52, .76), (.78, .75), "upper_arm.L"),
    ("hand.L",     (.78, .75), (.94, .75), "forearm.L"),
    ("shoulder.R", (.00, .78), (-.24, .78), "chest"),
    ("upper_arm.R",(-.24, .78), (-.52, .76), "shoulder.R"),
    ("forearm.R",  (-.52, .76), (-.78, .75), "upper_arm.R"),
    ("hand.R",     (-.78, .75), (-.94, .75), "forearm.R"),
    ("thigh.L",    (.13, .53), (.15, .30), "hips"),
    ("shin.L",     (.15, .30), (.15, .08), "thigh.L"),
    ("foot.L",     (.15, .08), (.15, .02), "shin.L"),
    ("thigh.R",    (-.13, .53), (-.15, .30), "hips"),
    ("shin.R",     (-.15, .30), (-.15, .08), "thigh.R"),
    ("foot.R",     (-.15, .08), (-.15, .02), "shin.R"),
]


def create_armature(meshes):
    xmin, xmax, ymin, ymax, zmin, zmax = world_bounds(meshes)
    height = zmax - zmin
    width = xmax - xmin
    depth = ymax - ymin
    if height <= 1e-6:
        raise RuntimeError("Model height is zero; cannot generate a human rig")
    center_x = (xmin + xmax) * 0.5
    center_y = (ymin + ymax) * 0.5
    # Width uses half-width in X. Keep a minimum to avoid collapsed arm bones.
    half_width = max(width * 0.5, height * 0.06)
    # Use a small depth offset for the foot so the rig remains visible/useful.
    front_y = center_y - depth * 0.08

    arm_data = bpy.data.armatures.new("GeneratedHumanRig")
    arm_obj = bpy.data.objects.new("GeneratedHumanRig", arm_data)
    bpy.context.scene.collection.objects.link(arm_obj)
    arm_obj.show_in_front = True
    bpy.context.view_layer.objects.active = arm_obj
    arm_obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    created = {}
    for name, head_n, tail_n, parent_name in BONE_LAYOUT:
        hx, hz = head_n
        tx, tz = tail_n
        head = Vector((center_x + hx * half_width, center_y, zmin + hz * height))
        tail = Vector((center_x + tx * half_width, center_y, zmin + tz * height))
        if name.startswith("foot."):
            head.y = front_y
            tail.y = front_y - max(depth * .18, height * .025)
        if (tail - head).length < height * .005:
            tail.z += height * .01
        bone = arm_data.edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        created[name] = bone

    for name, _, _, parent_name in BONE_LAYOUT:
        if parent_name:
            created[name].parent = created[parent_name]
            created[name].use_connect = False

    bpy.ops.object.mode_set(mode="OBJECT")
    log("Generated %d bones; bounds height %.3f" % (len(BONE_LAYOUT), height))
    return arm_obj


def bind_meshes(meshes, armature):
    """Bind each imported mesh while preserving its materials and object."""
    for mesh in meshes:
        # Avoid duplicate generated vertex groups on repeated processing.
        if any(mod.type == "ARMATURE" and mod.object == armature for mod in mesh.modifiers):
            continue
        bpy.ops.object.select_all(action="DESELECT")
        mesh.select_set(True)
        armature.select_set(True)
        bpy.context.view_layer.objects.active = armature
        try:
            bpy.ops.object.parent_set(type="ARMATURE_AUTO")
            if not any(mod.type == "ARMATURE" and mod.object == armature for mod in mesh.modifiers):
                modifier = mesh.modifiers.new(name="GeneratedArmature", type="ARMATURE")
                modifier.object = armature
                mesh.parent = armature
            log("Automatic weights: " + mesh.name)
        except RuntimeError as exc:
            log("Automatic weights failed for %s (%s); trying envelope weights" % (mesh.name, exc))
            bpy.ops.object.select_all(action="DESELECT")
            mesh.select_set(True)
            armature.select_set(True)
            bpy.context.view_layer.objects.active = armature
            try:
                bpy.ops.object.parent_set(type="ARMATURE_ENVELOPE")
            except RuntimeError as fallback_exc:
                raise RuntimeError("Could not skin mesh '%s': %s" % (mesh.name, fallback_exc))


def key_pose(armature, frame, rotations):
    for bone_name, (x, y, z) in rotations.items():
        bone = armature.pose.bones.get(bone_name)
        if bone is None:
            continue
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = tuple(math.radians(v) for v in (x, y, z))
        bone.keyframe_insert(data_path="rotation_euler", frame=frame, group=bone_name)


def create_action(armature, name, frame_count, poses):
    if armature.animation_data is None:
        armature.animation_data_create()
    action = bpy.data.actions.new(name)
    armature.animation_data.action = action
    for frame, rotations in poses:
        key_pose(armature, frame, rotations)
    # Blender 3.x/4.x action f-curves may be exposed differently; set interpolation
    # only when the legacy fcurves collection is available.
    for curve in getattr(action, "fcurves", []):
        for point in curve.keyframe_points:
            point.interpolation = "BEZIER"
    action.use_fake_user = True
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = max(bpy.context.scene.frame_end, frame_count)
    log("Created action: %s (%d frames)" % (name, frame_count))


def create_animations(armature):
    idle = []
    for f, value in ((1, -1.5), (20, 1.5), (40, -1.5)):
        idle.append((f, {"chest": (value, 0, 0), "head": (-value * .4, 0, 0)}))
    create_action(armature, "Idle", 40, idle)

    walk = []
    for f, swing in ((1, -25), (20, 25), (40, -25)):
        walk.append((f, {
            "thigh.L": (swing, 0, 0), "thigh.R": (-swing, 0, 0),
            "shin.L": (max(0, -swing) * .55, 0, 0),
            "shin.R": (max(0, swing) * .55, 0, 0),
            "upper_arm.L": (-swing * .55, 0, -8),
            "upper_arm.R": (swing * .55, 0, 8),
        }))
    create_action(armature, "Walk", 40, walk)

    run = []
    for f, swing in ((1, -45), (15, 45), (30, -45)):
        run.append((f, {
            "thigh.L": (swing, 0, 0), "thigh.R": (-swing, 0, 0),
            "shin.L": (max(0, -swing), 0, 0), "shin.R": (max(0, swing), 0, 0),
            "upper_arm.L": (-swing * .65, 0, -16), "upper_arm.R": (swing * .65, 0, 16),
            "chest": (10, 0, 0),
        }))
    create_action(armature, "Run", 30, run)

    fall = []
    for f in (1, 20, 40):
        fall.append((f, {
            "upper_arm.L": (0, 0, 145), "upper_arm.R": (0, 0, -145),
            "forearm.L": (0, 0, 20), "forearm.R": (0, 0, -20),
            "thigh.L": (-15, 0, 0), "thigh.R": (10, 0, 0),
        }))
    create_action(armature, "Fall", 40, fall)

    jump = []
    for f, angle in ((1, 0), (6, -65), (12, 12), (24, 0)):
        jump.append((f, {
            "thigh.L": (angle, 0, 0), "thigh.R": (angle, 0, 0),
            "chest": (25 if f == 6 else (-8 if f == 12 else 0), 0, 0),
            "upper_arm.L": (0, 0, 40 if f == 6 else 0),
            "upper_arm.R": (0, 0, -40 if f == 6 else 0),
        }))
    create_action(armature, "Jump", 24, jump)


def export_glb(filepath, include_animations=True):
    output = Path(filepath).expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    result = bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        export_skins=True,
        export_animations=include_animations,
        export_yup=True,
        export_apply=False,
        export_animation_mode="ACTIONS",
        export_materials="EXPORT",
    )
    if "FINISHED" not in result or not output.is_file() or output.stat().st_size == 0:
        raise RuntimeError("GLB export failed: " + str(output))
    log("Exported %s (%d bytes)" % (output, output.stat().st_size))


def main():
    args = args_from_cli()
    if args.scale <= 0:
        raise ValueError("--scale must be greater than zero")
    clear_scene()
    meshes = import_model(args.input)

    if args.scale != 1.0:
        for obj in meshes:
            obj.scale = tuple(component * args.scale for component in obj.scale)
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.select_all(action="DESELECT")
            obj.select_set(True)
            bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    if args.process_only:
        export_glb(args.output, include_animations=True)
        return

    existing_armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    if existing_armatures and args.keep_existing_rig:
        armature = existing_armatures[0]
        log("Existing armature found; reusing it: " + armature.name)
    else:
        armature = create_armature(meshes)
        bind_meshes(meshes, armature)

    if not args.no_animations:
        create_animations(armature)
    export_glb(args.output, include_animations=not args.no_animations)
    log("Pipeline completed")


if __name__ == "__main__":
    main()
