# Preliminary Research: Flow Map Direction Regression

## Purpose

This document captures the current evidence for a suspected Waterways flow-map generation bug or inherited limitation, using the validation scene:

`scenes/validation/flow_map_direction_verification.tscn`

This is investigative only. It does not authorize code changes, shader changes, bake pipeline changes, or changes to the curve-derived river flow feature.

## Reported Problem

Repro steps:

1. Open `scenes/validation/flow_map_direction_verification.tscn`.
2. Select `WaterSystem/StraightRiver`.
3. Run `River -> Generate Flow & Foam Map`.
4. Generate WaterSystem waterway data.
5. Inspect Flow Arrows or flow output.

Expected:

- A single straight two-point river should produce downstream flow aligned with the river.
- Some edge artifacts are acceptable.
- Broad diagonal or distorted directions are not expected.

Actual:

- Flow Arrows appear diagonal.
- Several regions appear distorted.
- The visible river flow does not clearly move straight downstream.

## Scene Baseline

Relevant scene facts:

- Root scene: `FlowMapDirectionVerification`
- Water system: `WaterSystem`
- River: `WaterSystem/StraightRiver`
- Curve points: z = `-8` to z = `8`
- Bake collision helper: `BakeCollisionGround`
- Bake collision layer: layer `1`
- River bake resolution setting: `baking_resolution = 2`
- Generated source resolution: `256x256`
- Padded river bake texture size: `426x426`
- UV2 atlas sides: `3`
- Calculated river step count: `6`, therefore six real UV2 tiles and three unused atlas tiles

## Current Evidence

The generated bake textures are already embedded in the scene and referenced by external bake resources:

- `waterways_bakes/scenes_validation_flow_map_direction_verification/StraightRiver.river_bake.res`
- `waterways_bakes/scenes_validation_flow_map_direction_verification/WaterSystem.water_system_bake.res`

Godot 4.6.2 headless crashed while attempting to load the project for direct scripted resource inspection, so the first evidence pass decoded the scene-embedded texture bytes directly.

Inspection artifacts were written to:

`C:\Users\pc\Documents\GitHub\Godot 4 Waterways\.codex-research\flow_map_direction_verification`

## Follow-up Evidence From Codex Pass

Additional evidence was written to:

`C:\Users\pc\Documents\GitHub\Godot 4 Waterways\.codex-research\flow_map_direction_verification\extracted_bakes`

Important files:

- `extraction_summary.txt`
- `river_flow_foam_noise.png`
- `river_dist_pressure.png`
- `system_map.png`

This pass decoded the saved `.res` bake resources directly, rather than relying on Godot resource loading. It confirmed the existing evidence:

```text
river_flow_foam_noise occupied tile interiors:
pixels=28704
mean_decoded=(-0.003920,0.004206)
mean_mag=0.005864
median_mag=0.005546
active_mag_gt_0.02=2
range_rg=(126..128,128..130)
```

The saved River bake still has nearly neutral center samples in all six occupied tiles:

```text
tile 0..5 centers: rgba=[127,128,...] decoded=(-0.00392,0.00392) mag=0.005546 angle=135.00
```

The unused atlas tiles still contain stronger +Y-like data:

```text
tile 6..8 centers: rgba=[128,151,...] decoded=(0.00392,0.18431) mag=0.184355 angle=88.78
```

The saved WaterSystem map alpha region remains weak but non-neutral:

```text
system_map_alpha_region:
pixels=84992
mean_rgba=(125.959,130.279,0.000,255.000)
range_rg=(123..129,129..167)
mean_mag=0.026898
median_mag=0.016638
active_mag_gt_0.02=17004
active_mean_angle=117.79
```

Another artifact folder was added for a CPU-side reconstruction of the collision-mask path:

`C:\Users\pc\Documents\GitHub\Godot 4 Waterways\.codex-research\flow_map_direction_verification\cpu_reconstruction`

Important files:

- `reconstruction_summary.txt`
- `river_00_reconstructed_raw_collision.png`
- `river_01_reconstructed_padded_collision.png`
- `river_04_reconstructed_dilated_collision.png`
- `river_05_reconstructed_normal_map.png`
- `river_06_reconstructed_normal_to_flow.png`

This reconstruction is not an authoritative Godot renderer capture. It applies the observed flat occupied UV2 tiles and the shader formulas on CPU to check whether the current theory is plausible. It reproduced the same qualitative pattern:

```text
normal_to_flow_center_samples:
tile 0..5: rg=[128,128] mag=0.005546
tile 6..8: rg=[128,146] mag=0.145151 angle=88.45
```

Interpretation:

- Flat occupied collision regions have no interior gradient, so the normal-to-flow conversion produces neutral interior flow.
- Dilation and edge gradients can create stronger vectors near empty or unused atlas regions.
- This supports the hypothesis that the River bake generation path is underdetermined for a straight river over flat uniform collision input.

Attempted Godot intermediate dumping:

- A temporary editor script was used to try to dump raw collision, padded collision, flow pressure, dilated collision, normal map, normal-to-flow map, blurred flow, final `flow_foam_noise`, final `dist_pressure`, and WaterSystem maps.
- Godot 4.6.2 mono launched from `C:\Users\pc\Desktop\Godot_v4.6.2-stable_mono_win64`, but the scripted run crashed with signal 11 before writing intermediate images.
- `addons/waterways/filter_renderer.gd` also blocks viewport readback under headless/dummy rendering, so a non-headless editor/rendering path is still required for authoritative GPU-pass dumps.
- No addon, scene, shader, or bake-resource patches were made during this evidence pass.

Godot launch follow-up:

- The 4.6.2 mono console executable can run `--version`, but command-line `--script` crashed when Godot tried to create default `user://logs` outside the workspace sandbox.
- Redirecting `APPDATA` and `LOCALAPPDATA` to a workspace-local folder fixed command-line script mode for both headless and windowed smoke tests.
- The 4.6.3 non-mono console executable was then tested:

```text
C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe
version: 4.6.3.stable.official.7d41c59c4
```

- With workspace-local user data, 4.6.3 successfully ran:
  - a minimal headless script smoke test
  - a windowed Vulkan script load of `res://scenes/validation/flow_map_direction_verification.tscn`
- The most reliable editor launch pattern found so far is to pass the `project.godot` file positionally, not `--path ... --editor`, when launching from Codex:

```powershell
$root = 'C:\Users\pc\Documents\GitHub\Godot 4 Waterways'
$env:APPDATA = Join-Path $root '.codex-research\godot_463_user_home\Roaming'
$env:LOCALAPPDATA = Join-Path $root '.codex-research\godot_463_user_home\Local'
& 'C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe' `
  --path $root `
  --script 'res://.codex-research/flow_map_direction_verification/dump_flow_intermediates.gd'
```

- A detached GUI editor process did not persist after the Codex shell command ended, likely because the shell wrapper cleans up child GUI processes. While the command remained active, 4.6.3 editor recovery mode stayed responsive. For evidence capture, command-line script mode with a real windowed Vulkan renderer is now the working path.

Successful Godot 4.6.3 intermediate dump:

`C:\Users\pc\Documents\GitHub\Godot 4 Waterways\.codex-research\flow_map_direction_verification\intermediate_dump_godot_463`

Important files:

- `intermediate_summary.txt`
- `river_00_raw_collision.png`
- `river_01_padded_collision.png`
- `river_02_flow_pressure.png`
- `river_03_blurred_flow_pressure.png`
- `river_04_dilated_collision.png`
- `river_05_normal_map.png`
- `river_06_normal_to_flow.png`
- `river_07_blurred_flow_map.png`
- `river_08_foam_map.png`
- `river_09_blurred_foam_map.png`
- `river_10_tiled_noise.png`
- `river_11_final_flow_foam_noise.png`
- `river_12_final_dist_pressure.png`
- `system_00_flow_raw.png`
- `system_01_height.png`
- `system_02_alpha.png`
- `system_03_combined_map.png`

Key intermediate findings:

```text
river_06_normal_to_flow occupied tile interiors:
pixels=28704
mean_decoded=(-0.003922,0.003922)
mean_mag=0.005546
median_mag=0.005546
active_mag_gt_0.02=0
range_rg=(127..127,128..128)

river_07_blurred_flow_map occupied tile interiors:
pixels=28704
mean_decoded=(-0.003920,0.004206)
mean_mag=0.005864
median_mag=0.005546
active_mag_gt_0.02=2
range_rg=(126..128,128..130)

river_11_final_flow_foam_noise occupied tile interiors:
pixels=28704
mean_decoded=(-0.003920,0.004206)
mean_mag=0.005864
median_mag=0.005546
active_mag_gt_0.02=2
range_rg=(126..128,128..130)
```

The real Godot renderer dump confirms that the flow signal is already neutral immediately after `normal_to_flow_filter.gdshader` in the six occupied tiles. The final combined River bake is not losing a meaningful downstream vector later; it never receives one in those occupied interiors.

Unused-tile center samples from the same real renderer dump:

```text
river_06_normal_to_flow tile 6..8: rgba=[128,153,3,255] decoded=(0.00392,0.20000) mag=0.200038 angle=88.88
river_07_blurred_flow_map tile 6..8: rgba=[128,151,2,255] decoded=(0.00392,0.18431) mag=0.184355 angle=88.78
river_11_final_flow_foam_noise tile 6..8: rgba=[128,151,0,...] decoded=(0.00392,0.18431) mag=0.184355 angle=88.78
```

WaterSystem output from the real renderer dump matches the saved bake extraction:

```text
system_00_flow_raw alpha>0:
pixels=84992
mean_rgba=(125.959,130.279,127.000,255.000)
range_rg=(123..129,129..167)
mean_mag=0.026898
median_mag=0.016638
active_mag_gt_0.02=17004
active_mean_angle=117.79
```

Important sampled result from the six occupied river UV2 tiles:

```text
tile 0: rgba=[127, 128, 255, ...] decoded=(-0.00392, 0.00392) angle=135.00
tile 1: rgba=[127, 128, 255, ...] decoded=(-0.00392, 0.00392) angle=135.00
tile 2: rgba=[127, 128, 255, ...] decoded=(-0.00392, 0.00392) angle=135.00
tile 3: rgba=[127, 128, 255, ...] decoded=(-0.00392, 0.00392) angle=135.00
tile 4: rgba=[127, 128, 255, ...] decoded=(-0.00392, 0.00392) angle=135.00
tile 5: rgba=[127, 128, 255, ...] decoded=(-0.00392, 0.00392) angle=135.00
```

Interpretation:

- The real river tile centers are nearly neutral, not strongly diagonal.
- The diagonal angle is an artifact of decoding 8-bit near-neutral RG data.
- A true neutral flow vector cannot be represented exactly in 8-bit RGBA because `0.5 * 255 = 127.5`.
- `[127, 128]` decodes to a tiny vector `(-0.00392, 0.00392)`.
- Flow Arrows currently treat that tiny vector as a meaningful direction.

Aggregated occupied-tile interior stats:

```text
steps 0..5:
mean decoded RG = (-0.003920, 0.004206)
mean magnitude = 0.005864
median magnitude = 0.005546
active texels with magnitude > 0.02 = 2
R range = 126..128
G range = 128..130
```

This means the generated River flow map is effectively neutral in the actual occupied river tiles.

## Unused Atlas Tile Evidence

The three unused atlas tiles showed much stronger +Y flow-like data:

```text
tile 6: rgba=[128, 151, 0, ...] decoded=(0.00392, 0.18431) angle=88.78
tile 7: rgba=[128, 151, 0, ...] decoded=(0.00392, 0.18431) angle=88.78
tile 8: rgba=[128, 151, 0, ...] decoded=(0.00392, 0.18431) angle=88.78
```

This suggests the filter chain can create meaningful vector data near the boundary between occupied and empty atlas regions, but that signal is not the correct downstream flow inside the six real river tiles.

This may explain some debug-view distortion if sampling, filtering, mip behavior, UV2 padding, or WaterSystem composition lets unused-tile data influence visible regions.

## System Map Evidence

The WaterSystem map also showed near-neutral or weak vectors over the valid alpha region, with some left/up/diagonal distribution:

```text
system map alpha region:
mean decoded RG = (-0.0121, 0.0218)
mean magnitude = 0.0269
median magnitude = 0.0166
active texels with magnitude > 0.02 = 17004
active average angle = 105.05 degrees
```

Interpretation:

- Distortion is present by the WaterSystem output stage.
- However, the River bake is already not producing a usable downstream vector.
- The WaterSystem stage may be amplifying or reprojecting weak/edge-derived data rather than being the original cause.

## Current Code Path

Likely active path:

- `addons/waterways/river_manager.gd`
  - `_generate_flowmap()`
  - creates a blank collision image
  - calls `WaterHelperMethods.generate_collisionmap(...)`
  - pads the atlas with `WaterHelperMethods.add_margins(...)`
  - applies flow pressure, dilation, normal, normal-to-flow, blur, foam, and combine passes
  - packs `flow_foam_noise` as RG flow, B foam, A phase noise
  - writes padded textures to `RiverBakeData`
- `addons/waterways/water_helper_methods.gd`
  - `generate_collisionmap(...)`
  - resolves UV2 texels back to world river-surface samples with barycentric interpolation
  - tests collision between the river surface and `real_pos + Vector3.UP * raycast_dist`
  - `add_margins(...)`
  - pads the UV2 atlas and handles column-continuation margins
- `addons/waterways/shaders/filters/normal_map_pass.gdshader`
  - derives a normal-like vector from grayscale collision-mask gradients
- `addons/waterways/shaders/filters/normal_to_flow_filter.gdshader`
  - converts the generated normal map into packed flow
- `addons/waterways/shaders/river_debug.gdshader`
  - decodes RG with `(flow - 0.5) * 2.0`
  - rotates Flow Arrows with `atan(flow.y, flow.x)`
- `addons/waterways/shaders/system_renders/system_flow.gdshader`
  - samples the River flow map through padded UV2 remapping
  - applies force modifiers
  - transforms flow into world XZ before repacking

## Likely Causes

### 1. Flat Collision Input Has No Downstream Direction

The strongest current explanation is that the collision-derived bake cannot infer downstream direction from a uniform flat collision ground.

`normal_map_pass.gdshader` derives vectors from brightness gradients in the collision mask. If the occupied river region is flat or fully filled, there is no useful gradient inside the river body. The result is near-neutral flow in the interior, with stronger vectors only near edges or empty atlas cells.

Confidence: High.

### 2. Flow Arrows Misrepresent Near-Neutral Flow

Flow Arrows rotate using the decoded vector direction even when vector length is almost zero. This makes 8-bit neutral quantization appear as a confident diagonal direction.

Confidence: High.

### 3. WaterSystem Composition May Amplify Weak or Edge-Derived Data

The system map contains weak diagonal/up-left vectors after composition. Since the River bake is already near-neutral, the WaterSystem pass may be multiplying or reprojecting tiny vectors, edge artifacts, or unused-atlas influence.

Confidence: Medium.

### 4. Empty/Unused UV2 Atlas Tiles May Bleed Through Filtering or Sampling

Unused atlas tiles contain much stronger +Y vector values than occupied tiles. If padding, filtering, mip behavior, or sampling near seams allows this data to affect occupied regions, it could create visible distortion.

Confidence: Medium.

### 5. Coordinate Frame Mismatch Is Not Yet Proven

The straight river's UV and UV2 layout appears consistent enough that a coordinate-frame mismatch is not currently the leading explanation. The raw occupied River flow map is almost neutral, not strongly rotated.

Confidence: Low to Medium.

## External Flow-Map Systems Research

Online research added on 2026-05-22 supports the current diagnosis: established flow-map systems do not treat a flat occupancy or collision mask as sufficient information to define downstream direction. They either author a 2D vector field directly, derive direction from an authored river/spline/current, or run a simulation with terrain, forces, boundaries, inlets, and outlets. Collision/geometry data is commonly used to constrain, mask, slow, deflect, or add detail to flow, not to create the primary downstream vector from a uniform flat mask.

### Valve / Source Flow Maps

Valve's public flow-map talks describe flow maps as 2D vector fields that artists author and combine with masks. In "Water Flow in Portal 2", the algorithm overview says artists author a flow map containing 2D flow vectors, and the shader distorts normal maps in that direction. The same deck notes the flow map provides a unique 2D vector for every point on the water surface.

Sources:

- [Water Flow in Portal 2, Alex Vlachos, SIGGRAPH 2010](https://cdn.cloudflare.steamstatic.com/apps/valve/2010/siggraph2010_vlachos_waterflow.pdf)
- [Making and Using Non-Standard Textures, Valve, GDC 2011](https://steamcdn-a.akamaihd.net/apps/valve/2011/gdc_2011_grimes_nonstandard_textures.pdf)

The GDC 2011 deck is especially relevant to the collision-mask question. It describes importing level geometry into Houdini, creating a 2D vector field on a tessellated water plane, painting low-frequency overall flow direction, generating vortices/upwellings, projecting geometry normals to reflect or deflect flow, and using geometry proximity as a mask to slow flow near edges. The final result keeps vector X/Y in RG, with vector length representing speed. This is a close conceptual match for "baseline direction plus geometry-derived modifiers", not "derive the entire flow direction from a binary collision mask".

### Unreal Engine Water

Unreal's Water system is documented as a spline-based workflow for rivers, lakes, and oceans. Epic's Python/API docs describe WaterBody actors as providing a spline-based workflow, and the WaterBodyType docs describe rivers as being defined by a spline down the middle. The API also exposes water velocity at a spline input key.

Sources:

- [Unreal Engine Water System](https://dev.epicgames.com/documentation/en-us/unreal-engine/water-system-in-unreal-engine?application_version=5.6)
- [unreal.WaterBody Python API](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/WaterBody.html?application_version=5.4)
- [unreal.WaterBodyType Python API](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/WaterBodyType?application_version=5.6)
- [FSolverSafeWaterBodyData::GetWaterVelocityAtSplineInputKey](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Plugins/Water/FSolverSafeWaterBodyData/GetWaterVelocityAtSplineInputKey)

Relevance: Unreal's river workflow treats the river path/spline as a first-class directional source. This supports using the authored River path/UV progression as a baseline direction when the collision-derived map has no useful vector signal.

### Simulation-Based Flow-Map Baking

Superposition's Flowmap Generator describes flow maps as textures containing velocity vectors. Its workflow uses editable simulation fields such as vortexes, directional forces, calming fields, rendered heightmaps, and surface-flow simulations for rivers/lava/sand. Scene geometry can affect the simulation through heightmaps, but direction comes from velocity/force/simulation state rather than a flat occupancy mask.

Source:

- [Superposition Flowmap Generator](https://www.superpositiongames.com/products/flowmap-generator/)

The GPU Zen 3 chapter "Flowmap Baking with LBM-SWE" frames flow maps as precomputed 2D velocity-field textures used to animate water movement in UV space. The method solves shallow-water flow using height, velocity, terrain slope, bed shear, forces, and boundary treatment. This is a heavier, physically based version of the same lesson: useful direction requires a velocity field or enough physical constraints to solve one.

Source:

- [Flowmap Baking with LBM-SWE](https://soldierdown.github.io/HZ_Homepage_files/Publications/LBMSWE_files/lbmswe.pdf)

### Shader/Engine Examples That Consume Existing Flow Maps

Three.js `Water2` is a useful open-source consumer example. It either samples an RG flow map and decodes it as `rg * 2.0 - 1.0`, or falls back to a uniform `flowDirection` when no flow map is provided. This is directly relevant to neutral handling: the shader assumes flow direction is explicit input data.

Source:

- [three.js Water2.js](https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/jsm/objects/Water2.js)

Catlike Coding's Unity tutorials similarly present flow maps as textures containing 2D vectors. They distinguish a uniform velocity vector from a varying flow map and explain packed signed vectors in RG. The tutorial focus is consumption and animation, not deriving flow from masks.

Sources:

- [Catlike Coding - Texture Distortion](https://catlikecoding.com/unity/tutorials/flow/texture-distortion/)
- [Catlike Coding - Directional Flow](https://catlikecoding.com/unity/tutorials/flow/directional-flow/)

### Terrain/Hydrology Analogy

GIS flow-direction tools derive direction from elevation slope, not from occupancy alone. ArcGIS Flow Direction supports D8, MFD, and D-Infinity methods over an elevation raster; D8 assigns direction to the steepest downslope neighbor, and if multiple directions have the same change, direction is undefined/ambiguous. Across flat areas, the drop computation must look outward to lower elevation.

Source:

- [ArcGIS Flow Direction documentation](https://doc.arcgis.com/en/arcgis-online/analyze/flow-direction-mv-ra.htm)

Relevance: a flat uniform collision mask is analogous to a flat elevation field with no downslope signal. Without an additional baseline, outlet, force, or slope, the flow direction is underdetermined.

### External Research Implications For This Bug

- The current `normal_map_pass.gdshader` / `normal_to_flow_filter.gdshader` path is closer to "derive a direction from mask gradients" than to the systems above. It can produce edge/detail vectors, but flat filled interiors have no direction to recover.
- A collision-derived flow bake should have an authored or solved baseline direction. For Waterways' existing River mesh, local downstream `+V` is already represented by the mesh UV progression.
- Collision-derived gradients are better treated as modifiers or support maps: foam, pressure, distance, edge slowing, obstacle influence, diagnostics, or carefully confidence-gated vector variation.
- Near-neutral debug vectors should be hidden, faded, or marked neutral. Flow-map consumers generally assume RG contains meaningful vector data; debug tools should not turn 8-bit neutral quantization into a confident arrow.
- Empty or unused atlas tiles should remain neutral where possible. External systems commonly distinguish valid flow-field regions from masks/empty regions instead of letting unused areas contain strong arbitrary vectors.

## Preliminary Answers To Investigation Questions

Does the raw generated River flow map already contain diagonal/distorted RG before WaterSystem generation?

- The occupied river tiles contain near-neutral RG, not strong downstream or strong diagonal flow.
- The tiny diagonal vector is present before WaterSystem generation because of 8-bit neutral quantization.

Does distortion appear only after WaterSystem map generation/composition?

- No. The River bake already lacks meaningful downstream flow.
- The WaterSystem output appears to amplify or transform weak/edge-derived data.

Is Flow Arrows misrepresenting the data, or is the packed RG actually wrong?

- Both, in different ways.
- Packed RG is wrong for the expected downstream-flow behavior because it is near-neutral.
- Flow Arrows are misleading because they show a direction for near-zero vectors.

Does a uniform flat collision ground produce unstable normals/flow vectors?

- Yes, or more precisely it produces no useful interior gradient, so downstream direction is underdetermined.

Is UV2 atlas padding or column-continuation handling rotating/smearing direction?

- Not proven as the primary cause.
- It remains suspicious because unused atlas cells have strong vector data and may affect seams or composition.

Is the shader/debug path interpreting RG in a different coordinate frame than the bake path writes?

- Not proven yet.
- The current evidence points first to neutral/underdetermined generated data and debug visualization of near-zero vectors.

## Further Testing

Recommended next checks before patching:

1. Reproduce interactively in the Godot editor and capture screenshots of:
   - River Flow Arrows
   - River Flow Map debug view
   - River Flow Pattern
   - WaterSystem flow output

2. Export or dump intermediate bake textures:
   - raw collision map before margins
   - collision map after margins
   - dilated collision map
   - normal map
   - normal-to-flow map
   - blurred flow map
   - final combined `flow_foam_noise`
   - final `dist_pressure`

3. Test a no-collision version of the scene:
   - remove or disable `BakeCollisionGround`
   - rebake River map
   - compare whether output is fully neutral or fallback-like

4. Test non-flat collision geometry:
   - add asymmetric bank helpers or a simple obstacle
   - verify whether the generated flow gains meaningful direction or only obstacle-edge vectors

5. Test a narrow collision strip or sloped helper:
   - determine whether the collision-derived normal-to-flow path is directionally based on mask edges rather than river curve direction

6. Test UV2 seam behavior:
   - use lower and higher `baking_resolution`
   - vary river length/width so the step count changes
   - inspect tile seams, column continuation, and empty atlas cells

7. Test debug threshold behavior without changing production flow:
   - locally prototype a magnitude threshold in Flow Arrows
   - confirm whether diagonal arrows disappear when RG is near neutral

8. Test WaterSystem composition with a synthetic known-good River flow map:
   - force a uniform packed downstream vector in the River flow texture
   - generate WaterSystem data
   - verify whether world-space flow remains straight

9. Compare against original Godot 3.x Waterways:
   - determine whether a flat filled collision mask also produced neutral flow
   - determine whether original Flow Arrows also visualized neutral vectors as arbitrary directions

## Open Questions

- Should a flat collision-derived bake be considered invalid, or should it succeed with a warning?
- Should generated River flow always contain a curve-derived downstream baseline?
- Should collision-derived RG be treated as a modifier rather than the source of baseline direction?
- Should unused UV2 atlas tiles be explicitly neutralized after filtering?
- Should Flow Arrows hide, fade, or mark vectors below a magnitude threshold?
- Should WaterSystem generation ignore or clamp near-neutral vectors before applying force modifiers?
- Should `Validate Data Textures` report decoded vector magnitude statistics, not only channel contrast?
- Should bake diagnostics distinguish "valid texture exists" from "texture contains useful flow vectors"?

## Non-Goals For This Bug Investigation

- Do not assume the curve-derived river flow feature caused this.
- Do not start by rewriting the bake pipeline.
- Do not change public shader channel contracts without a separate spec.
- Do not remove the legacy collision-derived path before comparing original Waterways behavior.
- Do not patch Flow Arrows alone and call the generation problem fixed.

## Preliminary Recommendation

Treat this as two related issues:

1. Generation issue: the current collision-derived path can produce near-neutral flow for a straight river over flat uniform collision input, even though the River curve has an obvious downstream direction.
2. Debug issue: Flow Arrows currently display near-zero vectors as confident directions.

The next step should be evidence collection with intermediate bake outputs. A later fix may involve a curve-derived baseline flow layer, a better confidence model for collision-derived RG, neutral handling for unused atlas cells, and a debug-arrow magnitude threshold.
