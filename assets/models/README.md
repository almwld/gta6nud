# 3D Model Sources

## Rigged female humanoid

The viewer includes a CC0 Quaternius female humanoid source through the public Animate-Rigged-Humanoid-No-Blender mirror.

- Source model: Quaternius Universal Base Characters
- File: Superhero_Female_FullBody.gltf
- License: CC0 1.0
- Rig: humanoid, skinned
- Source mirror: https://github.com/NafisRayan/Animate-Rigged-Humanoid-No-Blender

The model remains remote so the repository does not vendor a multi-megabyte third-party binary without an explicit asset-pinning step.

## Opaque swimwear

The repository now contains a Blender generation pipeline at
`tools/blender/create_opaque_swimwear.py`.

It creates an opaque top and bottom from the same skinned body topology. The
generated clothing keeps the original vertex groups and Armature modifier, so
the **Skeleton and Skinning are preserved** and the clothing follows the same
animation bones.

Generate the production GLB with:

```bash
blender -b -P tools/blender/create_opaque_swimwear.py -- \
  --input /path/to/Superhero_Female_FullBody.gltf \
  --output assets/models/adult_female_swimwear.glb
```

The generated binary is intentionally not committed until it has been visually
and animation-tested. This prevents an unverified GLB from entering production.

Quaternius publishes the Universal Base Characters under CC0 1.0 and provides
glTF assets with a humanoid rig.
