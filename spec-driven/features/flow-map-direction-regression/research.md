# Research: Flow Map Direction Regression

## Purpose

This research distills `preliminary_research.md` into the standard feature-folder shape for the active workspace:

`C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression`

The process docs still mention an older `Waterways-release-0.2.2` path. For this workstream, the active add-on and feature docs are in `Godot 4 Waterways`.

- Decision needed: how the existing collision-derived River bake, debug views, UV2 atlas padding, and WaterSystem composition should behave when flat occupied collision interiors produce no useful flow gradient.
- Why this cannot go straight to implementation: the issue crosses generated texture semantics, debug visualization, UV2 atlas padding, WaterSystem reprojection, metadata, compatibility, and visual validation.
- Expected consumer:
  - `spec.md`
  - `plan.md`
  - `tasks.md`
  - `validation.md`
  - `review.md`
- Raw evidence/history remains in: `preliminary_research.md`.

## Current Research Outcome

- Status: Complete enough to write `spec.md` and a first implementation plan. Implementation has not started in this feature folder.
- Recommendation: treat this as a generation plus debug plus composition hardening issue. A Flow Arrows-only patch would hide the symptom but leave the existing River bake without useful downstream data in flat occupied collision interiors.
- Confidence: High that occupied River tiles are effectively neutral before final combine; high that Flow Arrows misrepresent near-neutral vectors; medium that unused atlas tiles and WaterSystem force/reprojection amplify edge-derived or near-neutral data into visible distortion.
- Biggest unknown that remains: the exact default/legacy compatibility surface for collision-only behavior, and the final near-neutral thresholds for River debug and WaterSystem composition.
- Decision or plan section this research unlocked: `plan.md` should evaluate a downstream baseline in the existing River bake path, neutral thresholds in debug/composition, and unused atlas neutrality.
- Requirements this research implies:
  - Flat occupied collision interiors must not silently become a valid-looking but unusable downstream flow map.
  - Debug Flow Arrows must not draw confident arrows for near-zero vectors.
  - Unused UV2 atlas cells must remain neutral or be prevented from influencing real river tiles.
  - WaterSystem composition must not magnify neutral, quantization-only, edge-only, or unused-tile data into misleading world flow.
- Non-goals or rejected ideas this research supports:
  - Do not patch Flow Arrows alone and call the generation issue fixed.
  - Do not conflate this work with the separate `curve-derived-river-flow` feature, although that work is useful adjacent history.
  - Do not rewrite the main River shader channel contract unless later validation proves a separate shader defect.
- Validation this research requires:
  - Automated/image-stat checks for occupied tile vector magnitude and unused tile neutrality.
  - Human-assisted visible Godot checks for River Flow Arrows, Flow Map, Flow Pattern, River bake output, and WaterSystem output.
  - WaterSystem checks that distinguish neutral/no data from useful world-space flow.

## Premise Check

- Reported or assumed problem: a straight two-point River over flat collision input bakes diagonal/distorted or directionally wrong flow.
- Evidence supporting the premise:
  - The visible Flow Arrows were reported as diagonal/distorted after River and WaterSystem generation.
  - Saved River bake extraction and real Godot 4.6.3 renderer dumps show occupied tile centers are nearly neutral, not downstream.
  - WaterSystem output contains weak non-neutral vectors over the valid alpha region, suggesting composition/reprojection can turn weak data into visible direction.
- Evidence against the premise:
  - The real occupied River tile centers are not strongly diagonal. They decode to tiny vectors caused by 8-bit neutral quantization, such as `[127, 128] -> (-0.00392, 0.00392)`.
  - `river_06_normal_to_flow.png` is already neutral in occupied tile interiors, so the final River combine is not destroying a good vector later. The current pipeline never receives one for flat occupied interiors.
- Possible expected-behavior explanation:
  - The current collision-derived gradient path is underdetermined for a flat filled collision mask. Gradients exist mainly at edges and empty atlas boundaries, not in the interior of a uniformly occupied river tile.
  - Flow Arrows currently turn near-zero vectors into an angle even though the direction is semantically meaningless.
- Confidence: High.
- Smallest check that can falsify the premise:
  - Dump `normal_to_flow`, blurred flow, final `flow_foam_noise`, and WaterSystem flow for a known scene. If occupied interiors already contain a useful downstream vector before combine, the diagnosis must change. The existing Godot 4.6.3 dump did the opposite.
- User-facing note or question to raise before patching:
  - The evidence points away from a final-combine bug and toward an under-specified generation source plus misleading debug. The fix should include generation and composition hardening, not only arrows.

## Active Add-on Baseline

- Relevant active files:
  - `addons/waterways/river_manager.gd`
  - `addons/waterways/water_helper_methods.gd`
  - `addons/waterways/filter_renderer.gd`
  - `addons/waterways/resources/river_bake_data.gd`
  - `addons/waterways/resources/water_system_bake_data.gd`
  - `addons/waterways/system_map_renderer.gd`
  - `addons/waterways/water_system_manager.gd`
  - `addons/waterways/shaders/filters/normal_map_pass.gdshader`
  - `addons/waterways/shaders/filters/normal_to_flow_filter.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
  - `addons/waterways/shaders/system_renders/system_flow.gdshader`
- Current behavior:
  - `river_manager.gd::_generate_flowmap()` creates an unpadded collision image, calls `WaterHelperMethods.generate_collisionmap(...)`, pads the image with `WaterHelperMethods.add_margins(...)`, runs filter passes, converts collision gradients through `normal_to_flow`, blurs, and combines RG flow, B foam, and A noise.
  - `normal_map_pass.gdshader` derives vectors from local grayscale collision-mask gradients.
  - `normal_to_flow_filter.gdshader` converts generated normal-map XY into packed flow.
  - `river_debug.gdshader` decodes RG, applies force, and rotates Flow Arrows with `atan(flow.y, flow.x)` even when the vector is near zero.
  - `system_map_renderer.gd` renders each River through `system_flow.gdshader`.
  - `system_flow.gdshader` samples the padded River atlas, decodes RG, applies force, transforms from local UV axes into world XZ, and repacks into the WaterSystem map.
- Existing extension points:
  - River bake settings: resolution, raycast distance, raycast layers, dilate, blur, foam cutoff/offset/blur.
  - `RiverBakeData.source_kind`, `source_metadata`, `source_signature`, `content_rect`, `source_texture_size`, `texture_size`, `uv2_sides`, channel metadata, and import profile.
  - River debug modes: Flow Map, Foam, Noise, Distance, Pressure, Flow Pattern, Flow Arrows, Flow Strength, Foam Mix.
  - WaterSystem generated map validation and source river metadata.
- Existing generated data, resources, channels, or metadata:
  - River `flow_foam_noise.rg`: signed flow packed 0..1 with neutral at 0.5.
  - River `flow_foam_noise.b`: foam.
  - River `flow_foam_noise.a`: phase/noise.
  - River `dist_pressure.rg`: distance/pressure support data.
  - WaterSystem `system_map.rg`: world-flow X/Z packed 0..1 with neutral at 0.5.
  - WaterSystem `system_map.b`: height.
  - WaterSystem `system_map.a`: coverage.
- Existing editor-only/runtime-safe boundaries:
  - Collision probing and filter rendering are editor bake concerns.
  - Runtime/debug shaders consume serialized textures and uniforms.
  - WaterSystem composition consumes River textures as generated data, not live colliders.
- Current validation scenes, debug views, or probes:
  - `scenes/validation/flow_map_direction_verification.tscn`.
  - `River -> Validate Data Textures`.
  - `WaterSystem -> Validate Generated Map Sampling`.
  - The successful Godot 4.6.3 dump under `.codex-research/flow_map_direction_verification/intermediate_dump_godot_463`.
- Current known limitations:
  - `baking_raycast_layers == 0` fails River bake preflight in the current path.
  - A flat or fully occupied collision mask produces no interior gradient.
  - Debug arrows do not threshold near-neutral vectors.
  - Unused atlas cells can contain stronger arbitrary vectors than occupied tiles after filters.
  - WaterSystem diagnostics currently record channel min/max/average but not decoded near-neutral flow statistics over alpha coverage.
- Current performance-sensitive paths:
  - Per-source-texel collision probing.
  - SubViewport filter passes and GPU readbacks.
  - WaterSystem top-down render and combine.
  - Any future image-stat probes at high bake resolution.
- What should not be rediscovered or redesigned unnecessarily:
  - The packed RG channel contract.
  - The padded UV2 atlas layout and `content_rect`.
  - Existing external `.res` bake storage.
  - Existing main River shader animation unless validation proves it is separately wrong.

## Research Questions

- Why does the occupied River flow output become near-neutral before final combine?
- Is Flow Arrows showing real diagonal flow or near-neutral quantization?
- Can the current UV2 mesh/atlas layout provide a downstream baseline for the existing River bake path?
- How should unused UV2 atlas tiles be handled after filtering/combine?
- Should collision-derived gradients be primary flow, support/modifier data, or diagnostics when the collision mask is flat?
- Should WaterSystem composition clamp, ignore, or mark near-neutral raw vectors before force/world transform?
- What compatibility surface should remain for legacy collision-only behavior?
- What visible and automated validation proves the regression is fixed?

## Findings Matrix

| Question | Finding | Evidence or source | Waterways implication | Confidence |
| --- | --- | --- | --- | --- |
| Does final River combine destroy a good vector? | No. Occupied tiles are already neutral at `river_06_normal_to_flow.png`. | Godot 4.6.3 dump: occupied interiors `mean_mag=0.005546`, `active_mag_gt_0.02=0`, RG range `(127..127,128..128)`. | Fix generation source or fallback, not only final combine. | High |
| Is the visible diagonal arrow a real strong diagonal vector? | Mostly no. It is an angle extracted from a tiny quantized neutral vector. | `[127,128]` decodes to `(-0.00392,0.00392)`, angle `135` degrees. | Flow Arrows need a near-neutral threshold. | High |
| Can collision gradients infer downstream direction from flat occupied interiors? | No reliable interior direction exists in a uniform mask. | `normal_map_pass.gdshader` samples grayscale differences; flat interiors produce no gradient. | The River path/UV progression needs to provide baseline direction, or bake must warn/mark invalid. | High |
| Are unused atlas tiles harmless? | Not proven. They contain stronger +Y vectors than occupied tiles. | Godot 4.6.3 dump: unused tile centers decode around magnitude `0.184..0.200`. | Neutralize unused cells or prevent them from influencing visible regions. | Medium-high |
| Does WaterSystem originate the bug? | Not as the first cause. It sees weak or edge-derived River data and can make it more visible. | River occupied tiles are neutral before WaterSystem; `system_00_flow_raw alpha>0` has `mean_mag=0.026898`. | Fix River generation first, then clamp/diagnose WaterSystem near-neutral input. | Medium |
| Does current mesh UV/UV2 encode downstream progression? | Yes. `generate_river_mesh()` maps regular UV V along step progress and UV2 tiles down a column before next column. | `water_helper_methods.gd:405-442`; `add_margins()` comments at `790-794`. | A local downstream `+V` baseline is plausible without a nearest-curve search. | Medium-high |
| Does Godot 4.6 support the current shader-space assumptions? | Yes, shaders expose `UV`, `UV2`, `TANGENT`, and `BINORMAL`; vertex color precision is 8-bit when used. | Godot 4.6 spatial shader docs. | RG baseline should remain in local UV/tangent space unless shader contract changes. | High |
| Is curve-derived flow feature the same scope? | No. It is adjacent and broader. | `spec-driven/features/curve-derived-river-flow/*`. | Use its lessons, but keep this regression focused on current collision-derived bake/debug/system composition path. | High |

## Comparable Patterns

Comparable flow-map and water systems generally separate base flow intent from modifiers:

- Valve's production talks describe flow maps as authored or generated 2D vector fields packed into RG. Their non-standard texture workflow combines overall flow direction, turbulence, edge slowing, and foam; geometry proximity affects masks/modifiers instead of being the only possible flow source.
- Unreal's Water system is spline-based for rivers, lakes, and oceans. Its WaterBody API presents water bodies as spline workflow actors.
- SideFX Labs separates an existing flowmap from obstacle-based modification. `Labs Flowmap Obstacle` modifies a plugged-in flowmap based on geometry.
- Adobe Substance 3D Designer's Spline Flow Mapper draws vector flow data along input splines, with tangent/normal direction modes and neutral background attenuation.
- Crest supports spline flow and flow-map texture inputs. Its flow-map input decodes packed red/green velocity by subtracting 0.5 and scaling.
- Catlike Coding's flow tutorials present flow maps as explicit RG vector fields consumed by shaders; the shader does not know or care whether the vector field came from paint, spline, simulation, or collision.
- GIS/hydrology flow direction is derived from slope/elevation. A flat field is ambiguous without an outlet, slope, force, or external rule.

Implication: Waterways' collision mask can remain valuable, but a flat occupancy mask is not enough information to infer downstream direction. For an authored River, the ordered mesh/UV progression is the available intent source in this narrower regression scope.

## Godot 4.6.3 Findings

Known local Godot 4.6.3 executables:

- Console/script runner: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
- GUI editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`

Local Godot execution findings:

- Godot 4.6.3 console executable reported `4.6.3.stable.official.7d41c59c4`.
- Redirecting `APPDATA` and `LOCALAPPDATA` to a workspace-local scratch folder avoids `user://` log/cache sandbox problems when running scripts from Codex.
- A real Godot 4.6.3 renderer dump succeeded at:

`C:\Users\pc\Documents\GitHub\Godot 4 Waterways\.codex-research\flow_map_direction_verification\intermediate_dump_godot_463`

Key local evidence:

- `river_06_normal_to_flow.png` occupied tile interiors:
  - `pixels=28704`
  - `mean_mag=0.005546`
  - `active_mag_gt_0.02=0`
  - `range_rg=(127..127,128..128)`
- `river_11_final_flow_foam_noise.png` occupied tile interiors:
  - `mean_mag=0.005864`
  - `active_mag_gt_0.02=2`
  - `range_rg=(126..128,128..130)`
- unused tile centers in final River bake:
  - decoded magnitude around `0.184355`
  - angle around `88.78` degrees
- WaterSystem `system_00_flow_raw.png alpha>0`:
  - `mean_mag=0.026898`
  - `median_mag=0.016638`
  - `active_mag_gt_0.02=17004`

Godot API/shader constraints:

- Godot spatial shaders expose `UV`, `UV2`, `TANGENT`, and `BINORMAL` to fragments. Current Waterways shaders decode RG and apply it through tangent/binormal space before force and world transforms.
- Godot `PhysicsRayQueryParameters3D.create(...)` supports ray queries with a collision mask, matching the current collision bake approach.
- Current filter passes use `SubViewport.UPDATE_ONCE`, wait frames, and read back with `get_texture().get_image()`. This is useful for local dumps but does not replace visible editor validation.
- Godot visible editor/shader behavior remains human-assisted by default in this workspace.

## Performance and Scale Findings

- Expected bake source sizes: `64`, `128`, `256`, `512`, and `1024` from `2^(6 + baking_resolution)`.
- Padded shader-facing atlas size is `source + 2 * tile_margin`, where tile margin is approximately `source / uv2_sides`.
- Current `generate_collisionmap(...)` iterates source texels and can be expensive at high resolution.
- A downstream baseline based on tile occupancy and local `+V` should be cheaper than per-texel nearest-curve world searches.
- Image-stat checks should crop to `content_rect` and sample or stream pixels to avoid excessive cost at high resolution.
- Runtime shader cost should not increase unless WaterSystem/River shader thresholding is accepted as necessary.

## Legacy Waterways Reference

The raw preliminary research notes that the original Godot 3 Waterways design was also collision-derived:

- The original bake generated a collision image, ran normal/normal-to-flow/blur/foam/combine passes, and packed RG flow.
- The original shader decoded RG with the same packed-vector convention.
- Therefore, the flat collision limitation is likely inherited behavior made more visible by the Godot 4 port's invalidation, diagnostics, and validation tooling.

Implication:

- Preserve a way to compare or reproduce legacy collision-only output when needed.
- Do not force the default authoring behavior to remain collision-only if the spec accepts a downstream baseline.

## Options

### Option A: Flow Arrows Threshold Only

- Benefits: smallest patch; immediately reduces misleading diagonal debug arrows.
- Costs: River bake still produces no usable downstream vector for flat occupied interiors.
- Risks: users see cleaner arrows but WaterSystem and runtime output remain wrong or weak.
- Fit for Waterways: insufficient as the primary fix.

### Option B: Existing River Bake Downstream Baseline Plus Debug/System Hardening

- Benefits: addresses generation, debug honesty, unused atlas cells, and composition risk while preserving the packed RG contract.
- Costs: requires bake routing changes, metadata/stats, compatibility decisions, and visual validation.
- Risks: default rebakes can change legacy collision-only scenes.
- Fit for Waterways: best fit for this regression.

### Option C: Full Curve-Derived River Flow Feature

- Benefits: larger authoring design improvement with explicit modes/source kinds.
- Costs: broader scope already tracked in `spec-driven/features/curve-derived-river-flow`.
- Risks: conflates two workstreams and delays the regression hardening.
- Fit for Waterways: use as adjacent design reference, not this feature's full scope.

### Option D: Simulation Or Terrain-Slope Flow Solve

- Benefits: could produce physically richer fields.
- Costs: far beyond this regression; new data model, performance, and UX surface.
- Risks: overbuilds before fixing the confirmed pipeline failure.
- Fit for Waterways: defer.

## Recommendation

- Recommended direction: implement Option B in small slices.
- Why this fits Waterways:
  - The active mesh/UV layout already encodes downstream progression.
  - Collision-derived gradients can remain useful for foam, pressure, edge/detail, diagnostics, and optional legacy comparison.
  - Debug and WaterSystem consumers can be hardened without changing the main channel contract.
- What to do first:
  - Define the expected behavior in `spec.md`.
  - Plan exact affected files, compatibility behavior, thresholds, and validation in `plan.md`.
  - Add image-stat diagnostics before broad code changes where practical.
- What to defer:
  - Full curve-flow UX/mode design from the sibling feature.
  - Directional collision blending beyond conservative support/modifier use.
  - Per-point speed, terrain slope, or simulation.
- What to avoid:
  - Treating near-neutral angles as meaningful.
  - Letting unused atlas cells contain strong arbitrary vectors after combine.
  - Letting WaterSystem force math amplify raw near-neutral input without a threshold or diagnostic.
- Confidence: High for generation/debug direction; medium for the exact composition threshold until tested visually.

## Spec Implications

- User/developer workflows:
  - Existing `River -> Generate Flow & Foam Map`.
  - Existing River debug views: Flow Map, Flow Pattern, Flow Arrows.
  - Existing `WaterSystem -> Generate System Map` and sampling validation.
- Functional requirements:
  - Valid flat-collision River bakes must produce useful downstream flow or explicitly report reduced/invalid directional data.
  - Near-neutral RG must not be presented as confident direction in debug arrows.
  - Unused atlas cells must remain neutral.
  - WaterSystem must preserve useful flow and avoid amplifying near-neutral data.
- Non-functional requirements:
  - Preserve Godot 4.6+ compatibility and editor/runtime boundaries.
  - Keep generated resources explicit and inspectable.
  - Keep runtime costs stable unless a measured threshold change is accepted.
- Acceptance criteria:
  - Occupied tile interiors exceed a meaningful vector magnitude threshold after bake.
  - Unused atlas cells are neutral or excluded.
  - Flow Arrows show neutral behavior for near-zero RG.
  - WaterSystem alpha-covered region does not show misleading flow from neutral River input.
- Non-goals:
  - Do not implement the full separate curve-derived river feature here.
  - Do not rewrite `river.gdshader` two-phase animation.
- Open questions to carry forward:
  - Exact thresholds.
  - Exact legacy collision-only exposure.
  - Whether `system_flow.gdshader` requires code changes or diagnostics are enough after River bake is fixed.

## Plan Implications

- Architecture direction:
  - Add a downstream baseline to the existing River bake path, likely local downstream `+V` in the current UV/tangent frame.
  - Treat collision-derived gradient flow as support/modifier/diagnostic data unless a confidence rule proves it is useful.
  - Add near-neutral threshold handling to `river_debug.gdshader` Flow Arrows.
  - Neutralize unused atlas RG data after filter/combine or prevent it from becoming non-neutral.
  - Review and possibly threshold `system_flow.gdshader` near-neutral raw vectors before force/world transform.
- Affected files/modules:
  - `river_manager.gd`
  - `water_helper_methods.gd`
  - `river_bake_data.gd`
  - `river_debug.gdshader`
  - `system_map_renderer.gd`
  - `system_flow.gdshader`
  - `water_system_manager.gd`
- Editor-only code:
  - River bake generation, diagnostics, validation, filter renderer.
- Runtime-safe code:
  - Shader consumption of generated textures.
  - WaterSystem sampling from serialized map.
- Shared resources/data:
  - `RiverBakeData` and `WaterSystemBakeData`.
- Texture channels, data formats, and metadata:
  - Preserve packed RG neutral `0.5`.
  - Add stats for decoded vector magnitude and unused tile neutrality.
- Migration or compatibility concerns:
  - Keep existing generated resources readable.
  - Decide whether legacy collision-only remains a generation mode, script-accessible flag, or diagnostic path.

## Validation Implications

- Automated checks:
  - Image-stat probe of current and post-fix dumps.
  - Static scans for threshold constants, metadata, and legacy path preservation.
  - Optional Godot script dump using workspace-local `APPDATA`/`LOCALAPPDATA`.
- Human-assisted Godot/editor checks:
  - Open `scenes/validation/flow_map_direction_verification.tscn`.
  - Generate River flow/foam and WaterSystem data.
  - Inspect Flow Map, Flow Pattern, Flow Arrows, and WaterSystem output.
- Visual scene or debug-view checks:
  - Straight flat-collision River.
  - Unused atlas cells.
  - WaterSystem alpha-covered output.
- Shader checks:
  - `river_debug.gdshader` near-neutral arrows.
  - `system_flow.gdshader` near-neutral clamp/ignore if implemented.
- Bake-output checks:
  - Occupied source-region magnitudes.
  - Unused tile neutrality.
  - Source/padded sizes and `content_rect`.
- Runtime/API checks:
  - Save/reload generated `RiverBakeData` and `WaterSystemBakeData`.
  - Confirm sampling uses serialized data.
- Failure signs that should stop implementation:
  - Occupied interiors remain near-neutral while bake reports valid downstream flow.
  - Unused tiles retain strong arbitrary vectors.
  - Flow Arrows still show confident arrows for near-neutral data.
  - WaterSystem output shows strong flow from neutral River input.

## Risks and Unknowns

- A baseline local `+V` may change legacy collision-only output after rebake.
- If the baseline is added too late in the pipeline, filters may still smear unused or edge data into occupied regions.
- If unused atlas cells are neutralized before a filter that reintroduces edge gradients, they may become non-neutral again.
- If `system_flow.gdshader` clamps too aggressively, it may suppress deliberately slow but valid flow.
- If thresholds are chosen only from the 256x256 straight scene, they may not generalize to other resolutions or imported maps.
- Human-assisted editor checks remain required for visible shader/debug/runtime behavior.

## Context Challenge Notes

- Possible misread context:
  - Reading Flow Arrows as showing strong diagonal flow, when they are often showing near-zero quantization direction.
- Evidence:
  - Godot 4.6.3 dump tile centers all decode to magnitude `0.005546` in occupied tiles.
- Confidence:
  - High.
- Quick check before patching:
  - Compare decoded vector magnitude and angle, not angle alone.
- User-facing note or question to raise:
  - "The diagonal arrows are real as a debug artifact, but the underlying data is near-neutral. The generation path still needs a useful downstream signal."
- Outcome after the check:
  - Existing evidence supports generation plus debug hardening.

## Source Quality and Reuse Notes

- Local active code: authoritative for current behavior.
- Local renderer dumps: authoritative for this workspace's observed Godot 4.6.3 pipeline output.
- Official Godot docs: authoritative for engine API/shader assumptions.
- Official engine/tool docs: useful for comparable design patterns, not code to copy.
- Production talks/tutorials: conceptual references for channel packing and flow-field layering.
- Agent inference: marked where translating evidence into Waterways design implications.

Reuse/licensing:

- Do not copy external code.
- External flow-map sources are conceptual references only.
- Local project code is governed by this repository's license.

## Sources

| Source | Type | Why it matters | Reuse/licensing note |
| --- | --- | --- | --- |
| `preliminary_research.md` | Local research record | Full raw evidence, intermediate dumps, decoded stats, and prior hypotheses. | Internal project documentation. |
| `.codex-research/flow_map_direction_verification/intermediate_dump_godot_463/intermediate_summary.txt` | Local Godot 4.6.3 evidence | Proves occupied tiles are neutral immediately after `normal_to_flow`. | Internal generated artifact. |
| `addons/waterways/river_manager.gd` | Local active code | Current River bake orchestration, preflight, combine, diagnostics, metadata, and source signature. | Project code. |
| `addons/waterways/water_helper_methods.gd` | Local active code | Current mesh UV/UV2 generation, collision probing, and margin padding. | Project code. |
| `addons/waterways/shaders/river_debug.gdshader` | Local active shader | Current Flow Arrows use `atan(flow.y, flow.x)` after decode/force. | Project code. |
| `addons/waterways/shaders/system_renders/system_flow.gdshader` | Local active shader | Current WaterSystem flow composition decodes, forces, world-transforms, and repacks River flow. | Project code. |
| [Godot 4.6 spatial shader docs](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html) | Official Godot docs | Confirms spatial shaders expose UV, UV2, TANGENT, and BINORMAL to fragment processing. | Conceptual/API reference. |
| [Godot ray-casting docs](https://docs.godotengine.org/en/latest/tutorials/physics/ray-casting.html) and [PhysicsRayQueryParameters3D](https://docs.godotengine.org/cs/4.x/classes/class_physicsrayqueryparameters3d.html) | Official Godot docs | Confirms collision-mask ray query pattern used by the bake path. | Conceptual/API reference. |
| [Unreal Water System](https://dev.epicgames.com/documentation/en-us/unreal-engine/water-system-in-unreal-engine?application_version=5.6) and [WaterBody API](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/WaterBody.html?application_version=5.6) | Official engine docs | Shows spline-based water authoring as a common baseline-flow model. | Conceptual reference only. |
| [SideFX Labs Flowmap Obstacle](https://www.sidefx.com/docs/houdini/nodes/sop/labs--flowmap_obstacle-3.0.html) | Official tool docs | Describes obstacle geometry modifying an existing flowmap. | Conceptual reference only. |
| [Adobe Spline Flow Mapper](https://experienceleague.adobe.com/en/docs/substance-3d-designer/using/substance-graphs/nodes-reference-for-substance-graphs/node-library/spline-path-tools/spline-tools/spline-flow-mapper) | Official tool docs | Shows spline tangent/normal flow vector drawing into neutral background. | Conceptual reference only. |
| [Crest Ocean System Flow docs](https://crest.readthedocs.io/en/4.15/user/ocean-simulation.html#flow) | Tool docs | Uses packed RG flow velocities decoded by subtracting 0.5. | Conceptual reference only. |
| [Catlike Coding Texture Distortion](https://catlikecoding.com/unity/tutorials/flow/texture-distortion/) and [Directional Flow](https://catlikecoding.com/unity/tutorials/flow/directional-flow/) | Tutorial | Explains RG vector flow maps and directional flow consumption. | Conceptual reference only. |
| [Valve GDC 2011 Non-Standard Textures](https://steamcdn-a.akamaihd.net/apps/valve/2011/gdc_2011_grimes_nonstandard_textures.pdf) | Production talk | Supports vector-field packing and layered flow/foam/edge modifiers. | Conceptual reference only. |
| [ArcGIS Flow Direction](https://doc.arcgis.com/en/arcgis-online/analyze/flow-direction-mv-ra.htm) | Official GIS docs | Flat/ambiguous flow-direction analogy: direction needs slope/outlet/extra rule. | Conceptual reference only. |
