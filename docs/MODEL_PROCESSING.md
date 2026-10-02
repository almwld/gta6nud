# 3D Model Processing

This pipeline processes the supplied GLB in Blender and removes only clearly identified external outerwear meshes. It does not remove bikini, swimwear, underwear, or lingerie meshes.

## What is preserved

Before editing, the processor records armature count, total bone count, animation action count, and animation F-curve/group structure.

After removing external outerwear, those values must remain unchanged or the job fails. Remaining meshes retain their materials and skinning data.

## Workflow

1. Check release v1.0-models contains anime_bikini_girl.glb.
2. Download that exact release asset.
3. Validate the GLB header.
4. Run Blender with tools/blender/process_model.py.
5. Verify the processed GLB.
6. Publish it as a GitHub Actions artifact.

If the release asset is missing, the workflow stops instead of inventing or substituting a model.

## Important limitation

The processor removes separate mesh objects whose names clearly identify external outerwear. If clothing is fused into the same mesh as the body, it is not automatically deleted. This prevents unsafe vertex deletion that could damage topology, skinning, or animations.

## Attribution

Source-model attribution is recorded in the project attribution files. Do not claim processing was completed until a real source GLB has been processed successfully.
