# Plan: Flow Map Direction Regression

## Spec Link

`spec.md`

## Architecture Summary

Harden the existing River flow-map bake path so a flat occupied collision mask does not produce a silently valid but directionless downstream result.

The chosen architecture is a narrow regression fix:

- Add a downstream baseline to the existing River bake path using the generated river mesh/UV progression, initially local downstream `+V` in the River shader's current UV/tangent frame.
- Treat collision-derived gradient flow as support/modifier/diagnostic data in the default path when the collision mask is flat or low-confidence.
- Preserve the current collision-derived path as legacy collision-only behavior for compatibility and comparison.
- Add near-neutral threshold handling to `river_debug.gdshader` Flow Arrows.
- Ensure unused UV2 atlas RG data remains neutral after the final River bake output.
- Add decoded vector diagnostics to River and WaterSystem validation.
- Review `system_flow.gdshader`; change it only if River-side generation and diagnostics still allow near-neutral raw vectors to be amplified into misleading WaterSystem flow.

This plan intentionally does not implement the broader `curve-derived-river-flow` feature. It uses one small piece of the same idea, a downstream baseline, because the regression evidence shows that collision gradients alone are underdetermined for flat interiors.

## Current Truth

- Implementation status: First implementation slice and second visual-feedback adjustment complete locally; visible editor recheck remains.
- Open architectural decisions:
  - Whether decoded magnitude `0.02` is the final visible-debug near-neutral threshold.
  - Whether legacy collision-only should remain script/storage-only or become inspector-visible.
  - Whether save/reload/runtime validation reveals any metadata or resource-storage follow-up.
- Last validation that proves the plan still works:
  - Godot 4.6.3 non-headless scripted default bake after second visual-feedback adjustment: occupied River tiles `mag_avg=0.247090`, unused tiles `near_neutral=100.00%`, effective flow-pattern magnitude without steepness `mag_avg=0.2945`, WaterSystem alpha-covered `mag_avg=0.294198`.
- Next planned implementation slice:
  - Human-assisted visible Godot validation for Flow Pattern intensity, Foam Mix, Flow Arrows, WaterSystem visuals, seams, and save/reload.
- Sections below that are historical or superseded:
  - None.

## Premise Check

- Evidence supporting the premise:
  - `river_06_normal_to_flow.png` occupied interiors have `mean_mag=0.005546`, `active_mag_gt_0.02=0`.
  - `river_11_final_flow_foam_noise.png` remains near-neutral in occupied interiors.
  - Unused tile centers contain much stronger +Y-like data.
  - `river_debug.gdshader` rotates arrows from decoded `flow` without checking magnitude.
  - `system_flow.gdshader` decodes raw flow, applies force, transforms through UV axes, and repacks to WaterSystem RG.
- Evidence against the premise:
  - The visible diagonal arrows are not proof of strong diagonal River data.
  - The current collision-only behavior is likely inherited from original Waterways, not necessarily a Godot 4 port typo.
- User-facing pushback or clarification needed before patching:
  - Do not present this as "the arrows are wrong and everything else is fine." The arrows are misleading, but the generated River data is also missing downstream flow.
- Smallest check that can falsify the premise:
  - Re-run the intermediate dump after any bake-path change and verify whether the occupied source crop gains meaningful non-neutral downstream vectors while unused cells remain neutral.

## Layers

Editor authoring layer:

- Keep the existing River menu action: `Generate Flow & Foam Map`.
- Keep existing debug view names and workflow.
- Add clear output messages that distinguish:
  - useful generated downstream flow,
  - reduced collision detail,
  - legacy collision-only flat/neutral output,
  - invalid unreadable textures.
- Keep visible generation-mode UI optional in the first slice; script-accessible or internal compatibility is enough if validation can exercise it.

Bake/data layer:

- Add downstream baseline generation in source atlas space.
- Pad baseline data using the existing `WaterHelperMethods.add_margins(...)` logic.
- Route default generated RG from baseline or confidence-gated collision modifier data.
- Keep collision-derived foam, pressure, distance, and diagnostic flow available.
- Neutralize unused atlas RG in the final River `flow_foam_noise` output.
- Add decoded vector stats to metadata and validation output.

Runtime layer:

- Preserve River `flow_foam_noise.rg` packed signed-flow contract.
- Preserve `dist_pressure` support-map contract.
- Preserve existing `river.gdshader` unless later validation proves a separate shader defect.
- Review WaterSystem composition and threshold near-neutral source vectors only if required.

Validation layer:

- Maintain an image-stat matrix for occupied interiors, unused tiles, and WaterSystem alpha-covered regions.
- Use human-assisted visible Godot checks for debug views and WaterSystem output.
- Keep the existing Godot 4.6.3 dump as pre-fix evidence.

Legacy reference layer:

- Existing `generated_spline_collision_bake` remains readable.
- Current collision-derived normal-to-flow behavior remains available as a legacy comparison path.
- Legacy collision-only mode may still produce near-neutral output for flat collision masks, but diagnostics must name that behavior.

## Godot Components

- Nodes:
  - `River` / `river_manager.gd`
  - Generated `RiverMeshInstance`
  - `WaterSystem` / `water_system_manager.gd`
  - Optional bake helper collision nodes
- Resources:
  - `RiverBakeData`
  - `WaterSystemBakeData`
  - generated `ImageTexture` resources
- Shaders:
  - `addons/waterways/shaders/filters/normal_map_pass.gdshader`
  - `addons/waterways/shaders/filters/normal_to_flow_filter.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
  - `addons/waterways/shaders/system_renders/system_flow.gdshader`
  - `addons/waterways/shaders/filters/combine_pass.gdshader`
- Editor tools:
  - River menu actions.
  - WaterSystem menu actions.
  - Progress output and validation output.
- Scenes:
  - `scenes/validation/flow_map_direction_verification.tscn`
- Validation scenes:
  - The existing scene remains canonical for this regression.
  - Add a new scene only if the existing one cannot express legacy/default comparisons or unused-atlas checks cleanly.

## Data Model

Preserve existing texture layout and channel contracts.

River `flow_foam_noise`:

- `r`: signed local flow X packed 0..1, neutral 0.5.
- `g`: signed local flow Y packed 0..1, neutral 0.5.
- `b`: foam.
- `a`: phase/noise.

River `dist_pressure`:

- `r`: bank distance or edge influence.
- `g`: flow pressure or occupancy support.
- `b`, `a`: reserved.

WaterSystem `system_map`:

- `r`: world-flow X packed 0..1, neutral 0.5.
- `g`: world-flow Z packed 0..1, neutral 0.5.
- `b`: normalized height.
- `a`: coverage.

Recommended River source kinds:

- Keep `RiverBakeData.SOURCE_KIND_SPLINE_COLLISION_BAKE` as the legacy collision-derived source kind.
- Add a new source kind for the hardened default: `SOURCE_KIND_DOWNSTREAM_BASELINE_COLLISION_BAKE`.
- If implementation aligns better with the sibling feature names, reuse or harmonize with `SOURCE_KIND_CURVE_COLLISION_MODIFIERS_BAKE`, but do not silently collapse the two feature scopes in docs.

Recommended generation behavior:

- Default generated behavior:
  - Downstream baseline provides RG in occupied atlas texels.
  - Collision-derived support maps provide foam/distance/pressure and optional diagnostics.
  - Collision-derived RG is not used as the only primary direction when the collision mask is flat or low-confidence.
- Legacy collision-only behavior:
  - Current collisionmap -> normal -> normal_to_flow -> blur -> combine RG path.
  - Flat collision input may produce near-neutral output.
  - Used for comparison and compatibility, not as the expected default fix.

Recommended metadata additions:

- `generation_behavior`: string label for default hardened vs legacy collision-only.
- `collision_hit_pixel_count`
- `collision_hit_pixel_percent`
- `occupied_tile_pixel_count`
- `unused_tile_pixel_count`
- `occupied_flow_min_length`
- `occupied_flow_max_length`
- `occupied_flow_avg_length`
- `occupied_flow_near_neutral_percent`
- `unused_flow_max_length`
- `unused_flow_near_neutral_percent`
- `downstream_baseline_applied`
- `legacy_collision_only`
- `near_neutral_threshold`

Source signatures:

- Include any new generation behavior or threshold-affecting setting in `get_bake_source_signature()`.
- Existing resources without the new field remain readable and should be treated as legacy collision-derived unless metadata proves otherwise.

## Editor/Runtime Boundary

- Editor-only code:
  - River bake preflight and generation.
  - Collision probing.
  - Filter renderer creation/readback.
  - Image-stat diagnostics.
  - Validation output.
- Runtime-safe code:
  - Loading serialized `RiverBakeData` and `WaterSystemBakeData`.
  - Shaders consuming packed textures.
  - WaterSystem sampling from `system_map`.
- Shared data/resources:
  - Generated textures.
  - Source metadata and signatures.
  - Channel metadata.
- APIs exposed to user projects:
  - Existing bake action and debug views.
  - Optional script-accessible legacy/default behavior selector if needed for validation.
- Assumptions that must not cross the boundary:
  - Runtime must not need collision helpers or filter renderer nodes.
  - WaterSystem runtime sampling must not depend on current editor selection or unsaved bake state.

## Runtime Flow

1. River loads `RiverBakeData`.
2. River applies `flow_foam_noise`, `dist_pressure`, `i_uv2_sides`, and `i_valid_flowmap` to materials.
3. River shader decodes RG as before.
4. WaterSystem loads `WaterSystemBakeData` and samples world-flow RG as before.
5. Runtime does not know whether a River map came from default downstream-baseline generation or legacy collision-only generation.

## Bake Flow

1. Preflight:
   - Validate curve, widths, mesh, bake resolution, finite bake settings, and filter renderer.
   - Keep current collision-layer validation for legacy collision-only behavior.
   - For default hardened behavior, zero or empty collision layers may reduce collision detail but must not by itself force neutral downstream flow.

2. Generate or refresh mesh:
   - Use existing `_generate_river()` and `WaterHelperMethods.generate_river_mesh(...)`.
   - Keep `_steps` and `_uv2_sides` as the source atlas occupancy basis.

3. Generate collision image:
   - Keep `WaterHelperMethods.generate_collisionmap(...)` when collision input is applicable.
   - Count hit pixels before filter passes.
   - Record whether the collision image is empty, full, or low-gradient.

4. Generate downstream baseline:
   - Create an unpadded source-size flow image.
   - Use `WaterHelperMethods.calculate_side(_steps)` and current UV2 tile order: `step_quad = column * side + row`.
   - For occupied tiles `step_quad < _steps`, encode local downstream `+V` into RG.
   - Fill unused tiles and non-occupied pixels with neutral RG.
   - Use gentle local `+V` direction with visible speed/magnitude still governed by existing material force controls. The current fixed first-slice strength is `0.25`; if visible validation proves this still too strong or too weak, introduce `downstream_baseline_strength` as a later user-facing bake setting.
   - Pad with `WaterHelperMethods.add_margins(source_baseline, flowmap_resolution, margin, _steps)`.

5. Run existing collision support filters:
   - Keep `flow_pressure`, `dilate`, `normal`, `normal_to_flow`, `blur`, `foam`, and combine support available.
   - In default hardened behavior:
     - Use collision-derived RG only as diagnostic or future confidence-gated modifier.
     - Do not blend useful baseline RG toward neutral when collision-derived vectors are near-neutral.
     - Continue using foam and `dist_pressure` outputs where collision data has useful hits.
   - In legacy collision-only behavior:
     - Use the existing blurred collision-derived flow RG in combine.

6. Combine River output:
   - Default hardened behavior:
     - `flow_foam_noise.rg` comes from padded downstream baseline, optionally later modified by confidence-gated collision detail.
     - `flow_foam_noise.b` comes from collision foam when collision support ran, otherwise blank foam.
     - `flow_foam_noise.a` comes from existing tiled noise.
     - `dist_pressure` comes from existing support maps when valid, otherwise explicit blank support maps.
   - Legacy collision-only behavior:
     - Preserve current `apply_combine(blurred_flow_map, blurred_flow_map, blurred_foam_map, tiled_noise)`.

7. Neutralize unused atlas RG:
   - After final River `flow_foam_noise` image exists, set unused source-region tile RG to neutral `(0.5, 0.5)` or ensure those pixels were never made non-neutral.
   - Apply this after any filter/combine step that can reintroduce arbitrary vectors.
   - Do not disturb occupied tile margin continuation needed for seams.
   - Recompute stats after neutralization.

8. Write data and metadata:
   - Set source kind and metadata.
   - Preserve texture sizes, content rect, UV2 sides, and source signature.
   - Save external bake resources through existing helpers.
   - Print bake mode, collision hit stats, occupied vector stats, unused-tile stats, and reduced-detail notices.

9. WaterSystem composition:
   - Generate as today through `SystemMapRenderer.grab_flow(...)` and combine.
   - Add diagnostics over alpha-covered pixels for decoded world-flow magnitude.
   - If near-neutral raw River vectors still become misleading after River fix, add a threshold in `system_flow.gdshader` before force/world transform:
     - Decode raw flow.
     - If raw magnitude is below threshold, set raw flow to zero before calculating force/world flow.
     - Keep threshold conservative so deliberately slow but valid flow is not lost.

## Lifecycle, Cleanup, and Re-entry

- Success path:
  - Temporary renderer nodes are cleaned up.
  - Generated textures are assigned and saved where possible.
  - `valid_flowmap` is true only after readable, finite textures and metadata are written.
  - Material uniforms are updated.
  - Progress completes and configuration warnings refresh.
- Preflight or early-return path:
  - Failed core preflight leaves previous valid bake data untouched unless current code already invalidated it.
  - Default hardened behavior treats missing/empty collision detail as reduced detail, not a directional-flow failure.
  - Legacy collision-only behavior keeps current stricter collision assumptions.
- Awaited failure path:
  - Failed filter outputs clean temporary renderer nodes and call existing failure completion helpers.
  - Failed baseline or neutralization validation aborts before writing invalid textures.
- Temporary node/resource ownership:
  - `river_manager.gd` owns the filter renderer.
  - `system_map_renderer.gd` owns temporary mesh copies during system render.
  - No temporary renderer/helper nodes are serialized.
- Progress, dirty-state, and user feedback:
  - Reuse existing progress signal.
  - Print concise stats after successful bake.
  - Warn for reduced collision detail or legacy flat output.
- Duplicate or overlapping requests:
  - Preserve `_flowmap_bake_in_progress`.
  - Preserve WaterSystem bake request guard.
- Scene reload or runtime boundary:
  - Saved resources and source signatures decide validity after reload.
  - Unsaved editor-memory textures continue to warn as today.

## Files to Change

- `addons/waterways/river_manager.gd`: add generation behavior routing, downstream baseline creation, hit/vector stats, reduced-detail messages, metadata, source signature updates, and unused atlas neutralization.
- `addons/waterways/water_helper_methods.gd`: add reusable helper(s) for occupied/unused UV2 atlas tile iteration, local downstream baseline creation, or vector-stat sampling if appropriate.
- `addons/waterways/resources/river_bake_data.gd`: add source-kind constant(s) and rely on existing metadata dictionaries for stats.
- `addons/waterways/shaders/river_debug.gdshader`: add near-neutral Flow Arrows handling.
- `addons/waterways/system_map_renderer.gd`: likely no behavior change, but inspect for passing thresholds or debug metadata if needed.
- `addons/waterways/shaders/system_renders/system_flow.gdshader`: review; add conservative raw-flow threshold only if validation shows WaterSystem still amplifies near-neutral data after River fix.
- `addons/waterways/water_system_manager.gd`: add decoded alpha-covered vector stats to diagnostics/validation and metadata.
- `addons/waterways/resources/water_system_bake_data.gd`: no required field changes expected; use existing metadata unless implementation proves a new source kind/stat field is required.
- `spec-driven/features/flow-map-direction-regression/*`: keep docs updated as behavior and validation change.

## Documentation Plan

- Code comments needed:
  - Why baseline RG is local downstream `+V` in River UV/tangent space.
  - Why collision-derived RG is not trusted as primary direction for flat masks.
  - Why unused atlas cells are neutralized after final combine/filtering.
  - What near-neutral thresholds mean in debug/system contexts.
- Feature docs to update:
  - This feature folder as implementation proceeds.
  - User guide if user-facing bake behavior changes.
  - Imports/data-map docs if source kinds or metadata semantics change.
- Architecture/data-flow docs to update:
  - Generated River channel notes.
  - WaterSystem composition diagnostics if changed.
- Validation docs to update:
  - Add exact probe commands, image-stat markers, and human-assisted results.
- Migration notes to update:
  - Existing `generated_spline_collision_bake` resources remain readable.
  - Rebaking under the hardened default may change flat-collision scenes from near-neutral to downstream flow.

## Validation Strategy

- Automated:
  - Static scan for new source kind, baseline helper, threshold constants, metadata keys, and legacy path.
  - Image-stat script/probe comparing occupied tile magnitude and unused tile neutrality.
  - Optional Godot 4.6.3 script dump with workspace-local `APPDATA` and `LOCALAPPDATA`.
- Validation matrix location:
  - `validation.md` `Validation Matrix`.
- Human-assisted:
  - Required for visible editor debug views, bake workflow, shader output, Flow Pattern, Flow Arrows, WaterSystem map, save/reload, and runtime-style behavior.
- Visual:
  - Use `scenes/validation/flow_map_direction_verification.tscn`.
  - Inspect River Flow Map, Flow Pattern, Flow Arrows, and WaterSystem output.
- Shader:
  - Confirm Flow Arrows threshold behavior.
  - Confirm WaterSystem shader threshold behavior if changed.
- Editor:
  - Run River bake, River validation, WaterSystem bake, WaterSystem validation.
- Runtime:
  - Save/reload generated resources and run F6-style check if possible.
- Performance:
  - Measure or log bake time at `baking_resolution = 2` first, then at lower/higher resolutions if code changes are nontrivial.
- Manual:
  - Confirm docs and output messages do not claim review/validation is complete before it is.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Baseline local `+V` direction is wrong for current tangent/binormal setup | Flow appears reversed or sideways | Validate with Flow Pattern/Arrows and WaterSystem expected direction before broadening |
| Legacy scenes depend on collision-only output | Rebake changes visual output | Preserve legacy collision-only behavior and source metadata |
| Collision support maps still suppress visible motion | RG is useful but material force becomes weak or misleading | Validate Flow Pattern and WaterSystem output with default material settings |
| Unused atlas neutralization breaks seam padding | Visible seam artifacts | Neutralize only unused source-region tiles and preserve occupied margin continuation |
| Thresholds hide valid slow flow | Debug/System suppresses intentional slow vectors | Start with diagnostics and conservative thresholds; validate imported/manual maps |
| WaterSystem shader change masks River bake bug | System output looks neutral but River data remains bad | Fix and validate River bake first |
| Image-stat checks miss localized artifacts | Tests pass while visible seams fail | Combine stats with human-assisted visible checks |
| Local Godot script runs hit sandbox/cache issues | Incomplete automated validation | Redirect `APPDATA` and `LOCALAPPDATA` to workspace-local scratch |

## Migration and Compatibility

Existing resources must remain readable. The current `generated_spline_collision_bake` source kind should be treated as legacy collision-derived output unless metadata indicates the new hardened generation behavior.

Backward compatibility policy:

- Loading old resources: preserve behavior.
- Rebaking under the new default: allowed to improve flat-collision downstream flow and therefore change visuals.
- Legacy collision-only: keep available for comparison and projects that rely on old generated output.
- Imported/manual maps: preserve existing channel contract and do not rewrite automatically.

The plan does not remove current collision-derived filters. It changes the default interpretation: collision gradients are not trusted as the sole primary flow direction when local evidence says the input is flat or low-confidence.
