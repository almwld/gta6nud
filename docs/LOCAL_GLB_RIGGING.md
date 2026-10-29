# Local GLB Import and Automatic Rigging

The Blender helper `tools/blender/rig_model.py` imports a local `.glb`/ `.gltf` file, then immediately creates a starter human armature and skins the imported mesh objects when the file does not already contain an armature. It exports a new GLB and does not overwrite the input unless the same path is explicitly supplied.

## Requirements

- Blender with the glTF 2.0 importer/exporter enabled (included with standard Blender builds).
- A local GLB/GLTF model.
- Best results: an upright human character in a roughly A-pose or T-pose.

## Run

From the repository root:

```bash
blender -b -P tools/blender/rig_model.py -- \
  --input /absolute/path/to/model.glb \
  --output /absolute/path/to/model_rigged.glb
```

Generate only the rig and skinning (no generated animation actions):

```bash
blender -b -P tools/blender/rig_model.py -- \
  --input ./model.glb --output ./model_rigged.glb --no-animations
```

Import and re-export without adding bones:

```bash
blender -b -P tools/blender/rig_model.py -- \
  --input ./model.glb --output ./model_copy.glb --process-only
```

Apply a uniform scale during import:

```bash
blender -b -P tools/blender/rig_model.py -- \
  --input ./model.glb --output ./model_rigged.glb --scale 1.0
```

## What it generates

- A basic 19-bone human starter rig, scaled from the model's bounding box.
- Automatic weights for imported mesh objects; an envelope-parenting fallback is attempted if automatic weighting fails.
- Optional actions named exactly `Idle`, `Walk`, `Run`, `Fall`, and `Jump`.
- A GLB export with skins and animation actions.

## Important limitations

This is geometric auto-rigging, not AI pose estimation. The script cannot reliably infer where a person's shoulders, elbows, knees, or hips are from arbitrary geometry. It assumes an upright human-shaped model with limbs extended approximately sideways; non-human models, seated/curled poses, fused accessories, and unusual orientations need manual rig placement and weight painting. The generated motions are starter animations, not production motion-capture.

If the input already contains an armature, the script reuses the first existing armature rather than creating a duplicate. Review the output in Blender and test deformations before using it in the app. A successful export alone does not prove that the rig or weights are visually correct.
