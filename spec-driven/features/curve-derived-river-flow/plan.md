# Plan: Curve-Derived River Flow

## Spec Link

`spec.md`

`spec.md` is drafted from `preliminary_research.md`, with implementation tasking now captured in `tasks.md`. If implementation reveals a bad assumption, revise the earliest wrong document before widening the patch.

## Architecture Summary

Change `River -> Generate Flow & Foam Map` so generated river flow always has a downstream baseline from the River curve. Collision data remains valuable, but in the first implementation it modifies foam, bank distance, and pressure support data instead of being the only meaningful source of RG flow direction. Directional obstacle deflection is deferred until a concrete collision-confidence rule is accepted.

The shader channel contract should stay intact:

- `flow_foam_noise.rg`: packed signed flow vector, neutral at `(0.5, 0.5)`.
- `flow_foam_noise.b`: foam mask.
- `flow_foam_noise.a`: phase/noise offset.
- `dist_pressure.rg`: distance or bank influence plus pressure/occupancy support data.

Important coordinate-space decision: do not encode raw world X/Z direction into `flow_foam_noise.rg`. The river shader decodes RG and applies it through `TANGENT` and `BINORMAL`, so generated RG should remain in the river mesh's local texture/tangent frame. The first curve-derived baseline should therefore write a stable downstream `+V` vector for occupied river atlas texels, using the ordered curve and UV2 tile layout to decide progress and tile continuity. Curved world-space motion comes from the generated river mesh and its UV/tangent frame.

## Current Truth

Keep this section short and update it whenever the plan changes.

- Implementation status: first no-layer/Curve Only/source-kind/blank-support/validation-scene slice is complete.
- Expert review status: rebased against active Waterways and updated after Task 12 local validation.
- Review corrections now captured below: exact padded/unpadded bake image flow; exact no-collider support-map values; concrete first-pass collision modifier scope.
- Architectural decisions: extend the current serialized `bake_generation_behavior` string with `curve_only`; treat `generated_downstream_baseline_collision_bake` as a readable predecessor; defer visible mode UI and any public `baking_generation_mode` enum.
- Last validation that proves the current foundation works: Godot 4.6.3 local probes on 2026-05-22, including default occupied `mag_avg=0.247090`, unused atlas neutrality, legacy occupied `near_neutral=95.81%`, WaterSystem alpha-covered default `mag_avg=0.294198`, zero-layer/default fallback, no-hit/default fallback, curve-only fallback, canonical scene rebake/save/reload/runtime-style checks, focused screenshots, and low/current/high bake timings.
- Current checklist: `tasks.md`, rebased to mark regression-delivered pieces as complete or superseded.
- Next planned implementation slice: none for this feature; optional live human editor motion review and generated-subresource `.import` diagnostics cleanup are deferred follow-ups.
- Sections below that are historical or superseded: none.

## Post-Regression Rebase Notes

The completed flow-map direction regression changed active Waterways behavior in ways this plan must acknowledge before coding:

- Default River bakes already use local downstream `+V` RG for occupied source atlas tiles through `WaterHelperMethods.create_downstream_baseline_flow_image(...)`.
- The default behavior name is `downstream_baseline_collision_support`, not `Curve + Collision Modifiers`.
- Legacy comparison is currently `bake_generation_behavior = "legacy_collision_only"`, not a `Collision Legacy` enum value.
- `RiverBakeData` currently has `SOURCE_KIND_DOWNSTREAM_BASELINE_COLLISION_BAKE`, not `SOURCE_KIND_CURVE_COLLISION_MODIFIERS_BAKE` or `SOURCE_KIND_CURVE_ONLY_BAKE`.
- `get_bake_source_signature()` already includes `bake_generation_behavior`, downstream baseline strength, flat support values, near-neutral threshold, step count, and UV2 side count.
- `Validate Data Textures` and bake output already report decoded flow-vector stats for source, occupied, and unused atlas regions.
- `river_debug.gdshader` already suppresses near-neutral Flow Arrows below decoded magnitude `0.02`.
- `water_system_manager.gd` already reports alpha-covered decoded flow stats.
- `baking_raycast_layers == 0` no longer fails curve-based preflight after this slice; legacy collision-only still preserves the stricter layer requirement.

Document rebase outcome:

- `spec.md`: now distinguishes current downstream-baseline behavior from the broader curve-derived mode system.
- `plan.md`: now treats the next slice as an extension of the current downstream-baseline foundation.
- `tasks.md`: now marks regression-delivered pieces as complete or superseded and scopes the remaining implementation work.
- `validation.md`: records the latest local baseline probes and keeps curved/no-collider/seam/mode validation open.
- `review.md`: records that the old blocker is resolved and that the remaining risk is no-layer/Curve Only behavior, naming, and validation.
- `research.md`: updates the active add-on baseline so future readers do not rediscover the old collision-only default.

## Expert Review Findings Applied

These findings came from the required local review of `preliminary_research.md`, `spec.md`, this plan, and the active `addons/waterways` codebase.

- Image sizing is now explicit. Current `_generate_flowmap()` pads collision input before filter passes and combines padded filter outputs, so curve RG generation must move from source-sized to padded-sized before blend/combine.
- `Curve Only` support maps are now exact for the first pass. The River shader multiplies decoded RG by a force derived from `dist_pressure.rg`, so no-collider support values cannot stay vague.
- Directional collision RG blending is deferred until a confidence rule is specific enough to avoid blending useful curve flow toward neutral. First implementation keeps collision influence through foam, distance, and pressure support maps only.
- Generation mode is now required as a serialized River property and as part of `get_bake_source_signature()`, even if it is hidden from the inspector at first.
- A canonical validation scene is now required. `scenes/validation/two_phase_flow_validation.tscn` validates shader consumption of hand-authored maps, not the new bake path.

## Premise Check

Before implementing, record whether the problem is definitely a code/design issue or could be expected behavior from scene setup, generated data, stale resources, Godot limitations, or validation interpretation.

- Evidence supporting the premise:
  - Local research found the pre-fix and legacy collision-only generated bake can produce flat near-neutral RG when the collision map has no useful pixels.
  - `river_manager.gd` invalidates generated data after curve edits, so the shader can visibly animate with fallback flow until regeneration replaces fallback with generated data; the completed regression fix now makes default generated RG directional.
  - Current `river.gdshader` and `river_debug.gdshader` decode RG as `(flow - 0.5) * 2.0`; neutral RG means no meaningful direction.
  - Output warnings reported no collider pixels and flat RG/B/distance-pressure data.
- Evidence against the premise:
  - The collision-derived baseline behavior is inherited from original Waterways, not clearly a Godot 4 port regression.
  - A flat generated map remains expected behavior for the legacy collision-only path if bake helper colliders are absent, on the wrong layer, below the probe volume, or too uniform.
- User-facing pushback or clarification needed before patching:
  - Tell users that the current warning is probably accurate: the existing bake saw no useful collider pixels. The feature is a design improvement to make generated river flow less fragile, not a fix for a simple raycast typo.
- Smallest check that can falsify the premise:
  - In a representative scene, run `River -> Generate Flow & Foam Map`, then `River -> Validate Data Textures`, and inspect Flow Pattern plus Flow Arrows. If the collision map has hits and RG vector stats are non-neutral but visual flow is still stationary, the issue is not just the no-collider baseline dependency.

## Layers

Editor authoring layer:

- Keep the River toolbar action `Generate Flow & Foam Map`.
- Add a small, explicit generation-mode extension point for validation and compatibility.
- Update bake warnings so no-collider generation says curve baseline was used and collision detail is missing, instead of implying the entire flow map is useless.
- Keep snap behavior separate from bake behavior; document `waterways_snap_ignore` and named collision layers.

Bake/data layer:

- Add a curve-derived RG baseline generation step for occupied UV2 atlas texels.
- Keep collision map generation, dilation, normal, pressure, foam, blur, combine, margin padding, and external bake resource storage.
- Do not directionally blend collision-derived flow in the first implementation; keep collision influence in support maps.
- Keep generated textures padded with the existing one-tile UV2 atlas margin.
- Write source kind and stats metadata into `RiverBakeData`.

Runtime layer:

- Keep runtime shader consumption unchanged for the first implementation.
- Keep `RiverBakeData` explicit and inspectable.
- Keep WaterSystem combine behavior compatible with generated River maps.

Validation layer:

- Add or update visible validation scenes/procedures for straight, curved, no-collider, flat-collider, bank-helper, and legacy comparison scenarios.
- Add data-texture vector statistics so a human can distinguish "slow but directional" from "near-neutral/no direction".

Legacy reference layer:

- Preserve current collision-derived behavior as `Collision Legacy` for comparison and compatibility.
- Treat the original Godot 3 collision-first design as a supported legacy path, not the default design target.

## Godot Components

- Nodes:
  - `River` / `river_manager.gd`
  - Generated `RiverMeshInstance`
  - Optional bake helper `CollisionObject3D` and `CollisionShape3D` nodes
- Resources:
  - `RiverBakeData`
  - generated `ImageTexture` resources for `flow_foam_noise` and `dist_pressure`
- Shaders:
  - `addons/waterways/shaders/river.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
  - `addons/waterways/shaders/system_renders/system_flow.gdshader`
  - filter shaders only if future directional RG blending or CPU image construction proves too slow or awkward
- Editor tools:
  - River menu action for generation
  - River inspector bake properties
  - `Validate Data Textures`
- Importers:
  - No new importer in the first pass. Preserve linear/lossless data texture expectations.
- Autoloads:
  - None.
- Scenes:
  - Existing Waterways validation/demo scenes if present.
  - A new focused validation scene is required because no current scene proves the new bake path.
- Validation scenes:
  - A scene with a straight no-collider river.
  - A scene with a curved no-collider river.
  - A scene with flat/uniform collider coverage.
  - A scene with bank/obstacle helper colliders.
  - A scene or mode that can compare `Curve + Collision Modifiers` to `Collision Legacy`.

## Data Model

Add explicit generated source kinds to `RiverBakeData`, while preserving the existing texture layout and channel metadata.

Recommended constants and source-kind handling:

- `SOURCE_KIND_SPLINE_COLLISION_BAKE`: keep as the legacy value for existing generated resources.
- `SOURCE_KIND_DOWNSTREAM_BASELINE_COLLISION_BAKE`: keep as the current default generated source kind and compatibility bridge.
- Future curve-only or broader curve-derived source kinds should be added only when the corresponding behavior exists.
- Do not add a separate `SOURCE_KIND_COLLISION_LEGACY_BAKE` unless implementation discovers a real distinction from `SOURCE_KIND_SPLINE_COLLISION_BAKE`. The existing `generated_spline_collision_bake` value is the legacy collision-derived source kind.

Recommended behavior model on River:

- Current default: `downstream_baseline_collision_support`. Curve/UV downstream baseline provides RG; collision data contributes foam, distance, and pressure support maps. This is the current foundation for future `Curve + Collision Modifiers`.
- Future `curve_only`: writes downstream RG plus the exact blank support-map values defined below. It should not require `baking_raycast_layers`.
- Current legacy: `legacy_collision_only`. This preserves collision-derived RG behavior and existing warnings.
- Imported/manual maps remain part of the resource/channel contract, not necessarily a new button in this feature.

Recommended serialized River property:

- Extend the existing hidden/script-accessible `bake_generation_behavior` string first.
- Keep default value `downstream_baseline_collision_support`.
- Add only the behavior values required by the next slice, such as `curve_only`, while keeping `legacy_collision_only` readable.
- Include any new behavior value and base-strength control in `get_bake_source_signature()` so switching behavior invalidates stale generated data.
- Defer a public `baking_generation_mode` enum or inspector control until validation proves the workflow and naming.

Generated texture behavior:

- Source image size remains `2^(6 + baking_resolution)`.
- Shader-facing textures remain `padded_uv2_atlas_with_one_tile_margin`.
- `content_rect`, `source_texture_size`, `texture_size`, and `uv2_sides` remain written to `RiverBakeData`.
- Empty atlas cells should remain neutral flow where possible and must not bleed into real river ends.
- Occupied river texels should receive a non-neutral downstream baseline.

Exact first-pass texture sizing:

- Generate the curve baseline in an unpadded source image with size `source_texture_size`.
- Fill occupied source atlas texels with packed downstream local `+V` flow. Fill empty source atlas cells with neutral RG `(0.5, 0.5)`.
- Pad the curve baseline with `WaterHelperMethods.add_margins(source_curve_flow, flowmap_resolution, margin, _steps)` before combining or any future CPU blending.
- Keep collision support processing on padded textures when those passes run, matching the current pipeline.
- Any future CPU blend between curve and collision RG must operate on padded images of identical size.
- Diagnostics and vector stats should crop back to `content_rect` before reporting source-region values.

Exact first-pass no-collider support-map values:

- `Curve Only` writes source `flow_foam_noise.rg` as downstream curve flow, `flow_foam_noise.b` as `0.0`, and `flow_foam_noise.a` from the existing tiled phase/noise path.
- `Curve Only` writes source `dist_pressure.rg` as `(0.0, 0.0)` for occupied source atlas texels and empty source atlas cells in the first pass. In the current shader this yields `distance_map = 2.0` and `pressure_map = 0.0`, matching the empty-collision support-map shape closely enough to keep default material force visible without inventing pressure.
- `Curve + Collision Modifiers` with `baking_raycast_layers == 0` uses the same support-map behavior as `Curve Only`, records `no_collider_curve_only_fallback = true`, and reports reduced collision detail.
- `Curve + Collision Modifiers` with nonzero layers but zero hit pixels must use the same explicit blank support map after recording hit stats. Do not run collision support filters on empty input in the first implementation.
- `Collision Legacy` keeps the current collision-derived support and RG behavior, including flat or neutral results when collision input is empty or uniform.

Recommended metadata additions:

- `generation_mode`
- `curve_base_strength`
- `collision_modifier_strength` only after directional collision RG blending is implemented; omit or set `0.0` for the first implementation slice.
- `collision_hit_pixel_count`
- `collision_hit_pixel_percent`
- `curve_baseline_pixel_count`
- `collision_modified_pixel_percent` should mean support-map modifier coverage in the first implementation; reserve a separate future value for directional RG-deflection coverage if needed.
- `near_neutral_flow_pixel_percent`
- `flow_vector_min_length`
- `flow_vector_max_length`
- `flow_vector_avg_length`
- `no_collider_curve_only_fallback`

The source signature should continue to include curve positions, handles, widths, bake settings, behavior value, and UV2 side count. Add any new behavior value and relevant new bake controls to the signature so switching behavior invalidates stale generated maps. Existing resources whose source kind is `generated_spline_collision_bake` and whose signature lacks the newer behavior fields remain readable as legacy data; do not migrate them on load.

## Editor/Runtime Boundary

- Editor-only code:
  - Flow/foam bake orchestration.
  - Collision probing and direct `CollisionShape3D` traversal.
  - Filter renderer node creation and cleanup.
  - Bake warnings, progress signals, and validation printing.
- Runtime-safe code:
  - Shader consumption of `flow_foam_noise`, `dist_pressure`, `i_valid_flowmap`, and `i_uv2_sides`.
  - Loading serialized `RiverBakeData`.
  - Water system composition that samples already-generated textures.
- Shared data/resources:
  - `RiverBakeData`
  - packed textures and metadata
  - material shader uniforms
- APIs exposed to user projects:
  - Existing River bake controls and material controls.
  - Optional generation-mode property if exposed in the inspector.
- Assumptions that must not cross the boundary:
  - Runtime code must not depend on editor collision helpers or the filter renderer.
  - Runtime shaders must not need to know whether RG came from a curve, colliders, an imported texture, or a simulation.
  - Snap colliders, bake helpers, and gameplay colliders must remain conceptually separate.

## Runtime Flow

1. A River loads its serialized `RiverBakeData`.
2. `river_manager.gd` applies `flow_foam_noise`, `dist_pressure`, `i_uv2_sides`, and `i_valid_flowmap` to materials.
3. `river.gdshader` samples the padded UV2 atlas, decodes RG using the existing packed-vector contract, and animates normal/foam flow exactly as before.
4. If `i_valid_flowmap` is false, the existing fallback flow remains a shader-side invalid-bake behavior.
5. WaterSystem composition continues to consume River flow textures without caring about the generated source kind.

## Bake Flow

1. Preflight:
   - Require a valid curve, generated mesh, sane bake resolution, sane width data, and filter renderer availability.
   - For `Curve Only`, do not require nonzero `baking_raycast_layers`; skip collision probing and collision filter passes.
   - For `Curve + Collision Modifiers`, allow `baking_raycast_layers == 0`; treat it as an intentional no-collider bake, use curve-only support-map fallback values, and warn that collision modifiers, foam, pressure, and bank detail are reduced.
   - For `Curve + Collision Modifiers` with nonzero layers but no hit pixels, generation still succeeds with the curve baseline. Keep the collision hit warning as reduced-detail evidence, not as a bake failure.
   - For `Collision Legacy`, preserve the current stricter collision-derived assumptions: `baking_raycast_layers == 0` remains a preflight failure and empty or flat collision input may produce flat generated RG.

2. Generate or refresh the river mesh:
   - Use current `_generate_river()` behavior.
   - Keep `_steps` and `_uv2_sides` as the basis for source atlas occupancy.

3. Create curve-derived baseline RG:
   - Iterate the unpadded source atlas.
   - Use the same UV2 tile order as the mesh: tiles advance down a column before continuing at the next column.
   - Skip empty atlas cells beyond `_steps`.
   - For occupied texels, compute the tile and local progress along the river.
   - Encode downstream flow in the river texture/tangent frame, initially as local `+V` with a conservative base strength.
   - Clamp output to `0..1`.
   - Fill empty atlas cells with neutral RG `(0.5, 0.5)` before padding.
   - Pad the curve source RG image immediately with `WaterHelperMethods.add_margins(...)` so it matches the size of current collision filter outputs.
   - Keep edge attenuation out of the first pass unless the accepted spec requires it; distance/pressure and foam can continue to represent banks.

4. Generate collision support maps when applicable:
   - Keep `WaterHelperMethods.generate_collisionmap(...)`.
   - Keep direct `CollisionShape3D` segment checks and physics raycast fallback.
   - Keep existing `flow_pressure`, `dilate`, `normal`, `foam`, and blur passes for support data.
   - Keep `normal_to_flow` available for `Collision Legacy` mode and diagnostics/comparison, not for default-mode directional RG blending.
   - Continue producing `dist_pressure` from dilated collision and blurred pressure.
   - Skip this step entirely in `Curve Only`.
   - Skip this step in `Curve + Collision Modifiers` when `baking_raycast_layers == 0`; create explicit blank padded foam and support images instead.
   - In nonzero-layer no-hit bakes, skip the collision support filters after recording hit stats, create explicit blank padded foam and support images, and validate that curve RG remains useful.

5. Apply first-pass collision modifier scope:
   - Do not directionally blend collision-derived RG into curve RG in the first implementation.
   - Collision modifies the rendered result through existing foam, distance, and pressure support maps only.
   - Preserve the current `normal_to_flow` and blurred collision RG outputs only for `Collision Legacy` mode and for diagnostics/comparison, not as a default directional blend.
   - Record `collision_modifier_strength = 0.0` or omit it in metadata until directional deflection is implemented.
   - Future directional collision RG blending must be designed as a separate slice with a concrete confidence formula. It must gate on both support-map signal and decoded collision-vector length, and it must never blend toward neutral when collision data is empty, flat, or low-confidence.

6. Combine outputs:
   - Use padded curve RG for `flow_foam_noise.rg` in `Curve Only` and `Curve + Collision Modifiers`.
   - Use existing blurred collision-derived flow RG for `flow_foam_noise.rg` only in `Collision Legacy`.
   - Use existing blurred foam for `flow_foam_noise.b`.
   - Use existing tiled noise for `flow_foam_noise.a`.
   - Use existing `dist_pressure` packing for support data.
   - All textures passed to `apply_combine(...)` must already be padded to the same shader-facing size.
   - When collision passes are skipped, construct padded blank foam and padded blank `dist_pressure` images from the exact source values defined in the Data Model section, then combine or assign them without relying on collision filter output.

7. Write metadata and apply:
   - Write generation mode, stats, source kind, source signature, texture sizes, content rect, layout, and channel metadata into `RiverBakeData`.
   - Save external bake data using existing storage helpers.
   - Apply material uniforms and mark `valid_flowmap = true`.
   - Print a bake notice that includes mode and useful vector stats.

8. Diagnostics:
   - Keep channel-flat warnings for foam and support maps.
   - Add vector-length stats for RG instead of relying only on channel contrast.
   - In no-collider `Curve + Collision Modifiers`, report success with curve baseline and reduced collision detail.

## Lifecycle, Cleanup, and Re-entry

For async, rendering, editor, or bake work, answer these explicitly before implementation.

- Success path:
  - Temporary renderer nodes are removed and queued for free.
  - Generated textures are assigned to `flow_foam_noise` and `dist_pressure`.
  - `RiverBakeData` is updated and saved when possible.
  - `valid_flowmap` and shader `i_valid_flowmap` are set true.
  - Progress reaches finished and configuration warnings are refreshed.
- Preflight or early-return path:
  - If curve/mesh/resource requirements fail, leave existing valid bake data untouched unless current code already invalidated it.
  - Clear the bake request and emit finished progress.
  - For no collision input in curve-based modes, continue with curve baseline instead of aborting.
- Awaited failure path:
  - If a renderer pass returns no texture, call existing cleanup and failure finish helpers.
  - If the curve baseline image fails finite/vector validation, abort before writing invalid textures.
  - If external storage fails, keep editor-memory textures and warn using the existing save notice pattern.
- Temporary node/resource ownership:
  - `river_manager.gd` creates the filter renderer and owns cleanup.
  - Generated `ImageTexture` resources are assigned to River and then to `RiverBakeData`.
  - No temporary collision helper or renderer node should be serialized into the scene.
- Progress, dirty-state, and user feedback:
  - Reuse existing progress steps; add a "Generating curve flow" step before collision filters if visible progress text is practical.
  - Print mode and vector stats after a successful bake.
  - Use warnings for reduced collision detail, not for successful curve-only flow.
- Duplicate or overlapping requests:
  - Preserve `_flowmap_bake_in_progress` behavior and ignore duplicate requests while a bake is running.
- Scene reload or runtime boundary:
  - Runtime reload must rely only on serialized `RiverBakeData` and material uniforms.
  - Editor-only mode state should be serialized as a River property if it affects source signatures.

## Files to Change

- `addons/waterways/river_manager.gd`: extend generation behavior, add preflight adjustments, curve-only bake path, support-map fallback, metadata, vector stats, and updated warnings.
- `addons/waterways/water_helper_methods.gd`: add reusable helper(s) for curve/UV2 atlas baseline generation and possibly flow-vector statistics if they fit better as static utilities.
- `addons/waterways/resources/river_bake_data.gd`: add source-kind constants and metadata expectations while preserving existing defaults.
- `addons/waterways/shaders/river_debug.gdshader`: no planned change in the next slice; near-neutral Flow Arrows are already thresholded by the regression fix unless new visual validation finds a separate issue.
- `addons/waterways/shaders/system_renders/system_flow.gdshader`: review only; change only if debug/system flow rendering exposes the same near-zero directional issue.
- `addons/waterways/plugin.gd` and/or inspector/menu scripts: expose generation behavior only if the accepted spec wants a visible control; otherwise keep default behavior and script-accessible compatibility path through the serialized River property.
- `docs/godot-4-user-guide.md`: document curve baseline flow, collision helper roles, and layer recommendations.
- `docs/godot-4-imports.md`: update generated/imported flow-map channel notes if metadata/source kinds change.
- `scenes/validation/curve_derived_river_flow_validation.tscn`: add a canonical visible validation scene for the new bake path.
- `scenes/validation/curve_derived_river_flow_validation.gd`: optional helper script for building or resetting validation fixtures.
- `spec-driven/features/curve-derived-river-flow/spec.md`: create or update before implementation.
- `spec-driven/features/curve-derived-river-flow/tasks.md`: break this plan into implementation tasks.
- `spec-driven/features/curve-derived-river-flow/validation.md`: add the validation matrix and human-assisted Godot checks.
- `spec-driven/features/curve-derived-river-flow/review.md`: record implementation review once code exists.

## Documentation Plan

- Code comments needed:
  - Explain why curve baseline RG is encoded in river tangent/UV space, not world X/Z space.
  - Explain why directional collision RG blending is deferred, and what future confidence threshold must protect against.
  - Explain no-collider mode success semantics.
- Feature docs to update:
  - User guide section for River bake behavior.
  - Explain `Curve + Collision Modifiers`, `Curve Only`, and `Collision Legacy` if exposed.
- Architecture or data-flow docs to update:
  - River generated texture channel packing and source-kind metadata.
  - Bake helper, snap target, and gameplay collider layer roles.
- Validation docs to update:
  - Add matrix entries for no-collider, straight, curved, flat-collider, bank-helper, legacy comparison, and data-texture stats.
- Migration notes to update:
  - Existing generated resources with `generated_spline_collision_bake` remain readable.
  - Rebaking under the new default can change visible flow from flat/neutral to curve-following.

## Validation Strategy

- Automated:
  - Static scan for source kind constants and metadata fields.
  - GDScript parser/editor-load check if the local Godot environment can run it without crashing.
  - Unit-like script probe for curve baseline image generation if practical outside the visible editor.
- Validation matrix location:
  - `validation.md` `Validation Matrix`.
- Human-assisted:
   - Required for visible Godot editor bake results, shader output, Flow Pattern, Flow Arrows, and runtime scene behavior.
- Canonical validation scene:
   - Add `scenes/validation/curve_derived_river_flow_validation.tscn`.
   - The scene should contain or generate these named River fixtures: `StraightNoColliderRiver`, `CurvedNoColliderRiver`, `FlatColliderRiver`, `BankHelperRiver`, `LegacyCollisionRiver`, and a curve with enough steps to cross at least one UV2 column-continuation seam.
   - The scene should include a fixed camera and simple labels or node names that make each fixture easy to select in the editor, but it should not rely on in-app explanatory UI for correctness.
   - `scenes/validation/two_phase_flow_validation.tscn` remains a shader-consumption reference only; it is not sufficient proof of the new bake path.
- Visual:
   - Straight no-collider river should visibly move downstream.
   - Curved no-collider river should show arrows following the river strip without flips at UV2 column-continuation seams.
   - Flat/uniform collider coverage should not erase downstream flow.
   - Bank-helper colliders should add foam/pressure/detail without destroying baseline direction.
   - Legacy collision comparison should reproduce the current collision-derived result, including flat output when collision input is empty or uniform.
- Shader:
  - Confirm `river.gdshader` animation remains unchanged for valid maps.
  - Confirm `river_debug.gdshader` does not show arbitrary arrows for near-zero vectors.
- Editor:
  - Generate flow/foam map from River menu.
  - Validate data textures and confirm vector stats print useful min/max/avg and near-neutral percent.
  - Confirm duplicate bake request guard still works.
- Runtime:
  - Save scene after rebake, reload, and confirm `RiverBakeData` textures and `valid_flowmap` survive.
  - Confirm F6/export path uses serialized resources, not editor memory.
- Performance:
  - Measure bake time at low, medium, and highest supported `baking_resolution`.
  - Watch for expensive per-texel nearest-curve searches; prefer direct UV2 tile progress for the first pass.
  - Track extra GPU readbacks if future directional blending uses filter shaders.
- Manual:
  - Review generated texture channels in debug views.
  - Confirm no obsolete Godot 3 APIs were introduced.
  - Confirm documentation matches the implemented mode names.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Encoding world-space flow directly into RG | Curved rivers and shader force calculations behave incorrectly | Keep RG in tangent/binormal texture space; document this in code and plan |
| Directional collision blend drifts toward neutral | No-collider or flat-collider bakes remain visually stationary | Defer directional RG blending from the first implementation; when added later, gate by support-map signal and decoded collision-vector length |
| CPU image generation is too slow at high resolution | Editor bake becomes sluggish | Start with direct UV2 tile progress, sample at representative resolutions, move future blend work to a filter shader only if needed |
| Existing scenes depend on legacy collision-derived flow | Rebaking changes visual output | Preserve `Collision Legacy` mode and source-kind metadata |
| Debug arrows misrepresent neutral or near-neutral flow | Users diagnose the wrong issue | Add thresholded neutral display and vector stats |
| `baking_raycast_layers == 0` still aborts curve-only bakes | Curve-only workflow cannot be used without helper colliders | Adjust preflight by generation behavior |
| UV2 margin padding mishandles column-continuation seams | Flow flips or smears at tile boundaries | Reuse `add_margins(...)`, validate row/column seam scenes, avoid changing atlas layout |
| Documentation blurs bake helpers, snap targets, and gameplay colliders | Users keep fighting layer setup | Document separate named physics layers and existing `waterways_snap_ignore` metadata |
| Blank support-map fallback accidentally removes visible flow | Curve-only bakes contain useful RG but still look stationary under defaults | Use exact first-pass `dist_pressure.rg = (0.0, 0.0)` support values and validate with current default material force settings |

## Migration and Compatibility

Existing generated bake resources should continue to load. The current `generated_spline_collision_bake` source kind should be treated as legacy collision-derived data unless metadata proves otherwise. Imported or hand-painted textures must keep the same packed RG contract and should not be rebaked or reinterpreted by this feature.

The new default bake can intentionally change visual output after a user regenerates Flow & Foam Map: rivers that previously produced neutral RG because no colliders were detected should now produce downstream flow. This should be documented as an authoring improvement and not hidden as a silent compatibility detail.

No shader rewrite is planned. The first implementation should preserve material speed controls such as `flow_speed`, `flow_base`, `flow_distance`, `flow_pressure`, and `flow_max`. Per-point velocity, slope-derived speed, reverse-flow authoring, confluences, waterfalls, and terrain simulation are deferred features unless the accepted spec reopens them.
