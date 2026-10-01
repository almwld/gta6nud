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

import bmesh
import bpy


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


def make_material(name, base_color):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    if bsdf is None:
        raise RuntimeError("Principled BSDF node was not created.")

    bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.72
    bsdf.inputs["Metallic"].default_value = 0.0

    # Explicitly opaque: alpha is 1 and transmission is disabled.
    if "Alpha" in bsdf.inputs:
        bsdf.inputs["Alpha"].default_value = 1.0
    if "Transmission Weight" in bsdf.inputs:
        bsdf.inputs["Transmission Weight"].default_value = 0.0
    elif "Transmission" in bsdf.inputs:
        bsdf.inputs["Transmission"].default_value = 0.0

    return material


def duplicate_region(body, name, low, high, material, offset):
    garment = body.copy()
    garment.data = body.data.copy()
    garment.name = name
    garment.data.name = name + "_Mesh"
    bpy.context.collection.objects.link(garment)

    # The object copy preserves vertex groups and the Armature modifier.
    armature_modifiers = [
        mod for mod in garment.modifiers if mod.type == "ARMATURE" and mod.object
    ]
    if not armature_modifiers:
        raise RuntimeError(f"{name}: duplicated mesh lost its Armature modifier.")

    for mod in armature_modifiers:
        mod.show_viewport = True
        mod.show_render = True

    garment.data.materials.clear()
    garment.data.materials.append(material)

    mesh = garment.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.faces.ensure_lookup_table()

    # Quaternius glTF characters use Y-up. Work in local space.
    ys = [vertex.co.y for vertex in bm.verts]
    ymin, ymax = min(ys), max(ys)

    keep_faces = []
    for face in bm.faces:
        t = normalized_vertical(face.calc_center_median().y, ymin, ymax)
        if low <= t <= high:
            keep_faces.append(face)

    keep_ids = {face.index for face in keep_faces}
    remove = [face for face in bm.faces if face.index not in keep_ids]
    bmesh.ops.delete(bm, geom=remove, context="FACES")
    bm.to_mesh(mesh)
    bm.free()

    # Offset the shell slightly to prevent z-fighting; vertex groups are
    # untouched, so the original skinning remains identical.
    for vertex in mesh.vertices:
        if vertex.normal.length > 1e-8:
            vertex.co += vertex.normal.normalized() * offset

    solidify = garment.modifiers.new("SwimwearThickness", "SOLIDIFY")
    solidify.thickness = 0.0025
    solidify.offset = 0.0

    return garment


def main():
    args = parse_args()

    bpy.ops.wm.read_factory_settings(use_empty=True)
    import_gltf(args.input)

    body = find_skinned_mesh()
    print("Using skinned body:", body.name)

    top_material = make_material("Swimwear_Top_Opaque", (0.035, 0.12, 0.18))
    bottom_material = make_material("Swimwear_Bottom_Opaque", (0.035, 0.12, 0.18))

    duplicate_region(
        body, "Swimwear_Top", args.top_min, args.top_max, top_material, args.offset
    )
    duplicate_region(
        body,
        "Swimwear_Bottom",
        args.bottom_min,
        args.bottom_max,
        bottom_material,
        args.offset,
    )

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
