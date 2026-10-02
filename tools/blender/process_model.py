"""
process_model.py - Process GLB outerwear meshes while preserving rig/animation data.
Author: almwld/gta6nud
License: MIT (for the script itself)

Safety note:
This processor intentionally handles clearly external outfit/outerwear meshes only.
It does not remove underwear/intimate garments (for example bikini/swimwear).
"""
import bpy
import sys
from pathlib import Path

OUTERWEAR_KEYWORDS = (
    "jacket", "coat", "outfit", "clothing", "cloth", "skirt",
    "dress", "shirt", "pants", "trousers", "hoodie", "blazer",
    "sweater", "uniform", "outerwear",
)
EXCLUDED_INTIMATE_KEYWORDS = (
    "bikini", "swimwear", "swimsuit", "underwear", "lingerie",
)

def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

def import_glb(filepath):
    result = bpy.ops.import_scene.gltf(filepath=filepath)
    if "FINISHED" not in result:
        raise RuntimeError(f"GLB import failed: {filepath}")
    print(f"Imported: {filepath}")

def snapshot_integrity():
    armatures = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    bones = sum(len(a.data.bones) for a in armatures)
    actions = list(bpy.data.actions)
    action_snapshot = {
        a.name: (len(a.fcurves), tuple(sorted({g.name for fc in a.fcurves for g in fc.groups})))
        for a in actions
    }
    meshes = {
        o.name: (len(o.data.vertices), len(o.data.polygons), len(o.material_slots))
        for o in bpy.data.objects if o.type == "MESH"
    }
    return {
        "armatures": len(armatures),
        "bones": bones,
        "actions": len(actions),
        "action_snapshot": action_snapshot,
        "meshes": meshes,
    }

def analyze_meshes():
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    print(f"Meshes: {len(meshes)}")
    for obj in meshes:
        mats = [s.material.name for s in obj.material_slots if s.material]
        print(
            f"  {obj.name}: vertices={len(obj.data.vertices)} "
            f"polygons={len(obj.data.polygons)} materials={mats}"
        )
    return meshes

def classify_mesh(obj):
    name = obj.name.lower()
    if any(k in name for k in EXCLUDED_INTIMATE_KEYWORDS):
        return "protected"
    if any(k in name for k in OUTERWEAR_KEYWORDS):
        return "outerwear"
    return "body_or_unknown"

def remove_external_outerwear(meshes):
    removable = []
    protected = []
    for obj in meshes:
        category = classify_mesh(obj)
        if category == "outerwear":
            removable.append(obj)
            print(f"OUTERWEAR: {obj.name}")
        elif category == "protected":
            protected.append(obj)
            print(f"PROTECTED: {obj.name}")
    if removable:
        bpy.ops.object.select_all(action="DESELECT")
        for obj in removable:
            obj.select_set(True)
        bpy.ops.object.delete(use_global=False)
    print(f"Removed external outerwear meshes: {len(removable)}")
    print(f"Protected intimate-garment meshes: {len(protected)}")
    return removable

def verify_integrity(before):
    after = snapshot_integrity()
    print(
        f"Integrity: armatures {before['armatures']} -> {after['armatures']}, "
        f"bones {before['bones']} -> {after['bones']}, "
        f"actions {before['actions']} -> {after['actions']}"
    )
    if after["armatures"] != before["armatures"]:
        raise RuntimeError("Armature count changed.")
    if after["bones"] != before["bones"]:
        raise RuntimeError("Bone count changed.")
    if after["actions"] != before["actions"]:
        raise RuntimeError("Animation action count changed.")
    if after["action_snapshot"] != before["action_snapshot"]:
        raise RuntimeError("Animation f-curves/groups changed.")
    return after

def export_glb(filepath):
    Path(filepath).parent.mkdir(parents=True, exist_ok=True)
    result = bpy.ops.export_scene.gltf(
        filepath=filepath,
        export_format="GLB",
        export_materials="EXPORT",
        export_animations=True,
        export_skins=True,
        export_yup=True,
        export_animation_mode="ACTIONS",
    )
    if "FINISHED" not in result:
        raise RuntimeError(f"GLB export failed: {filepath}")
    print(f"Exported: {filepath}")

def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    input_glb = args[0] if len(args) >= 1 else "assets/models/anime_bikini_girl.glb"
    output_glb = args[1] if len(args) >= 2 else "assets/models/anime_bikini_girl_processed.glb"

    print(f"Input: {input_glb}")
    print(f"Output: {output_glb}")

    clear_scene()
    import_glb(input_glb)

    meshes = analyze_meshes()
    before = snapshot_integrity()
    remove_external_outerwear(meshes)
    verify_integrity(before)
    export_glb(output_glb)

if __name__ == "__main__":
    main()
