"""Generate an opaque, skinned two-piece swimwear layer from a rigged body mesh.

Usage (Blender 4.x/5.x):
  blender -b -P tools/blender/create_opaque_swimwear.py -- \
    --input path/to/Superhero_Female_FullBody.gltf \
    --output assets/models/adult_female_swimwear.glb

The garment is derived from the existing body topology, so the duplicated
vertices keep the body's vertex groups and therefore follow the same Armature.
It does not replace or alter the source skeleton.
"""

import argparse
import os
import bpy
import bmesh
from mathutils import Vector


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--top-min", type=float, default=0.50)
    parser.add_argument("--top-max", type=float, default=0.69)
    parser.add_argument("--bottom-min", type=float, default=0.40)
    parser.add_argument("--bottom-max", type=float, default=0.54)
    parser.add_argument("--offset", type=float, default=0.006)
    return parser.parse_args()


def import_gltf(path):
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(path))


def find_skinned_mesh():
    candidates = []
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        if any(mod.type == "ARMATURE" and mod.object for mod in obj.modifiers):
            candidates.append(obj)
    if not candidates:
        raise RuntimeError("No mesh with an Armature modifier was found.")
    return max(candidates, key=lambda obj: len(obj.data.vertices))


def normalized_vertical(value, minimum, maximum):
    span = maximum - minimum
    if span <= 1e-8:
        return 0.0
    return (value - minimum) / span


def world_bounds(obj):
    coords = [obj.matrix_world @ v.co for v in obj.data.vertices]
    minimum = Vector((
        min(v.x for v in coords),
        min(v.y for v in coords),
        min(v.z for v in coords),
    ))
    maximum = Vector((
        max(v.x for v in coords),
        max(v.y for v in coords),
        max(v.z for v in coords),
    ))
    return minimum, maximum


def make_material(name, base_color):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.72
    bsdf.inputs["Metallic"].default_value = 0.0
    # Explicitly opaque: no alpha blending or transmission.
    if "Alpha" in bsdf.inputs:
        bsdf.inputs["Alpha"].default_value = 1.0
    if "Transmission Weight" in bsdf.inputs:
        bsdf.inputs["Transmission Weight"].default_value = 0.0
    material.surface_render_method = "DITHERED" if hasattr(material, "surface_render_method") else material.surface_render_method
    return material


def duplicate_region(body, name, low, high, material, offset):
    garment = body.copy()
    garment.data = body.data.copy()
    garment.name = name
    garment.data.name = name + "_Mesh"
    bpy.context.collection.objects.link(garment)

    # Keep the exact vertex groups and Armature modifier from the body.
    for mod in garment.modifiers:
        if mod.type == "ARMATURE":
            mod.show_viewport = True
            mod.show_render = True

    garment.data.materials.clear()
    garment.data.materials.append(material)

    mesh = garment.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.faces.ensure_lookup_table()

    # Quaternius glTF characters are Y-up. The bounds are computed in local
    # coordinates so this remains stable even if the object has a transform.
    ys = [v.co.y for v in bm.verts]
    ymin, ymax = min(ys), max(ys)

    keep_faces = []
    for face in bm.faces:
        y = face.calc_center_median().y
        t = normalized_vertical(y, ymin, ymax)
        if low <= t <= high:
            keep_faces.append(face)

    remove = [face for face in bm.faces if face not in keep_faces]
    bmesh.ops.delete(bm, geom=remove, context="FACES")
    bm.to_mesh(mesh)
    bm.free()

    # Move the garment very slightly along normals to avoid z-fighting while
    # preserving the original topology and skin weights.
    for vertex in mesh.vertices:
        vertex.co += vertex.normal.normalized() * offset

    # A small solidify layer makes the clothing a real opaque shell.
    solidify = garment.modifiers.new("SwimwearThickness", "SOLIDIFY")
    solidify.thickness = 0.0025
    solidify.offset = 0.0

    return garment


def main():
    args = parse_args()

    bpy.ops.wm.read_factory_settings(use_empty=True)
    import_gltf(args.input)

    body = find_skinned_mesh()
    minimum, maximum = world_bounds(body)
    print("Using skinned body:", body.name)
    print("World bounds:", minimum, maximum)

    top_material = make_material("Swimwear_Top_Opaque", (0.035, 0.12, 0.18))
    bottom_material = make_material("Swimwear_Bottom_Opaque", (0.035, 0.12, 0.18))

    duplicate_region(
        body,
        "Swimwear_Top",
        args.top_min,
        args.top_max,
        top_material,
        args.offset,
    )
    duplicate_region(
        body,
        "Swimwear_Bottom",
        args.bottom_min,
        args.bottom_max,
        bottom_material,
        args.offset,
    )

    # Hide the original body only where the garment exists is intentionally
    # avoided: the base body remains intact, and the opaque shell sits above it.
    output = os.path.abspath(args.output)
    os.makedirs(os.path.dirname(output), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output,
        export_format="GLB",
        use_selection=False,
        export_animations=True,
    )
    print("Wrote:", output)


if __name__ == "__main__":
    main()
