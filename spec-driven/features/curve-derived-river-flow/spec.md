# Spec: Curve-Derived River Flow

## Summary

`River -> Generate Flow & Foam Map` should generate a useful downstream flow field from the River curve itself, then use collision data as optional modifier input for banks, foam, pressure, distance, and obstacle influence.

The pre-fix and legacy generated-map workflow could collapse to neutral RG flow when the collision bake found no useful collider pixels. That made the river look like it animated after a curve edit, because the shader had fallback flow while the generated map was invalid, then appeared stationary again after regeneration because the newly valid generated map contained near-zero flow. The completed regression fix now gives default bakes a downstream baseline, and this broader feature should build on that foundation so no-collider and explicit curve-mode workflows behave deliberately.

## Current Truth

Use this short section as the dashboard for the current spec state. Keep it current; move older detail into the sections below instead of letting stale open questions linger.

- Status: Feature complete for the first curve-derived river flow slice.
- Source of truth for open work: `tasks.md`.
- Last meaningful decision: extend the current serialized `bake_generation_behavior` switch with `curve_only`; do not add a parallel `baking_generation_mode` property until mode UI or a public enum is actually needed.
- Current source-kind decision: new bakes use `generated_curve_collision_modifiers_bake` or `generated_curve_only_bake`; `generated_downstream_baseline_collision_bake` remains the readable predecessor/foundation source kind.
- Known deferred items: per-point velocity, slope-derived speed, terrain simulation, reverse-flow authoring, confluences, waterfalls, and a broad shader rewrite.
- Current non-goals that are easy to accidentally reopen: do not replace the packed RG shader contract, do not encode raw world X/Z into RG, do not require colliders for baseline flow, do not remove legacy collision-derived comparison behavior, do not add broad inspector UI yet, and do not implement directional collision RG blending in this slice.

## Post-Regression Baseline Update

The flow-map direction regression slice is complete and changes the starting point for this feature. Active Waterways no longer uses collision-derived `normal_to_flow` as the default primary RG direction for generated River maps. The default bake behavior is now `downstream_baseline_collision_support`: occupied UV2 atlas tiles receive a gentle local downstream `+V` RG baseline at strength `0.25`, collision data remains as foam/distance/pressure support, saturated flat foam and pressure support are softened, and unused atlas tile RG is neutralized after combine.

The current compatibility path is not the final public mode system described below. Legacy comparison is exposed as the script/storage string `bake_generation_behavior = "legacy_collision_only"`, and default generated resources use `SOURCE_KIND_DOWNSTREAM_BASELINE_COLLISION_BAKE` / `generated_downstream_baseline_collision_bake`. The next implementation slice should extend `bake_generation_behavior` rather than adding a second mode property. A public `baking_generation_mode` enum or visible inspector control can still be added later if validation shows the workflow needs it.

The regression fix also already delivered decoded flow-vector diagnostics, occupied/unused UV2 atlas stats, near-neutral Flow Arrows thresholding, WaterSystem alpha-covered flow diagnostics, saved-resource reload proof, and user-facing docs for the current default behavior. This implementation slice added no-collider / zero-layer curve bakes, true `Curve Only` behavior, scriptable behavior/source-kind naming, exact blank support fallback, and a canonical curved/seam/bank-helper validation scene. Task 12 has now recorded local screenshots, save/reload/runtime-style proof, and performance notes for the new scene. Optional live human editor motion review and any future directional collision RG blending are deferred follow-ups, not part of the completed slice.

## Goals

- A regenerated River flow map should contain non-neutral downstream RG flow inside the river body even when no collider pixels are found.
- Collision-derived data should enrich curve-derived flow with foam, pressure, distance, bank, and obstacle detail without being required for baseline motion.
- Existing imported or hand-painted flow maps should keep the same channel contract.
- The current padded UV2 atlas layout should remain the texture layout for generated River data.
- Flow debug views should stop presenting near-zero vectors as confident arbitrary directions.
- Generated bake data should record enough metadata and stats for future sessions to understand the source, usefulness, and compatibility of the map.
- Existing material speed controls should remain the primary first-pass speed controls.

## Non-Goals

- Do not rewrite `river.gdshader` two-phase flow animation unless validation finds a separate shader bug.
- Do not add per-point speed or per-point velocity authoring in the first implementation.
- Do not implement terrain slope, heightfield simulation, confluence handling, waterfall handling, or imported DCC/simulation workflows as part of this feature.
- Do not require projects to add bake helper colliders just to make a river flow downstream.
- Do not remove or silently break the current collision-derived behavior; preserve it as a legacy comparison path.
- Do not merge bake helper, snap target, and gameplay collider responsibilities into one collision-layer assumption.
- Do not make runtime shaders depend on editor-only collision helpers or live bake state.

## Context and Assumptions

- Known scene/data/context facts:
  - Current active add-on work targets Godot 4.6+ under `addons/waterways`.
  - Current River generation writes `flow_foam_noise` and `dist_pressure` textures.
  - The shader decodes packed flow RG with `(flow - 0.5) * 2.0`; `(0.5, 0.5)` is neutral/no motion.
  - Current generated River textures use `padded_uv2_atlas_with_one_tile_margin`.
  - Moving curve points invalidates generated bake data and lets shader fallback flow become visible until regeneration.
  - Current collision probing samples upward from the river mesh into `real_pos + Vector3.UP * raycast_dist`.
- User-reported observations:
  - Regenerating Flow & Foam Map after edits can make visible flow appear stationary.
  - Output warnings reported no collider pixels and flat generated RG/foam/distance-pressure data.
- Agent confidence in the premise:
  - High that the current default downstream-baseline path solves the flat-collider primary RG problem for the regression fixture.
  - High that zero-layer and true no-collider/Curve Only authoring are still incomplete because `baking_raycast_layers == 0` fails preflight unconditionally.
  - Medium that nonzero-layer no-hit bakes still need explicit blank support-map semantics instead of running the collision filter chain on empty input.
  - Medium-high that the remaining legacy collision-only neutral behavior is inherited design behavior rather than a simple Godot 4 port regression.
- Possible expected-behavior explanations to rule out before patching:
  - Bake helper colliders may be absent, on unselected layers, below the upward probe volume, or too uniform.
  - The scene may be showing valid but near-neutral generated data rather than a shader failure.
  - Flow Arrows can show arbitrary rotation when the decoded vector length is near zero.
- Clarification or challenge already raised with the user:
  - This feature should be treated as an authoring-design improvement. It does not mean the current warning is false; it means the current design asks collision data to do too much.

## Users and Workflows

### User Story: Rebuild Flow Without Bake Helpers

As a river author, I want `Generate Flow & Foam Map` to produce downstream motion from the River curve even when I have no bake helper colliders, so that a regenerated map does not make the river look stationary.

Acceptance criteria:

- A no-collider River bake succeeds in the default generated mode.
- The generated RG vector field is non-neutral inside occupied river atlas texels.
- Flow Pattern visibly moves downstream after regeneration.
- Output messaging explains that collision detail is reduced, not that the generated flow failed.

### User Story: Add Bank and Obstacle Detail

As a river author, I want bake helper colliders to add foam, pressure, bank, and obstacle detail while preserving baseline downstream flow, so that colliders improve the result instead of deciding whether the river moves.

Acceptance criteria:

- Bank-helper colliders can add visible foam and pressure detail.
- Flat or uniform collider input does not erase the curve-derived downstream direction.
- Collision-derived influence is applied only where the bake signal is meaningful enough to modify the baseline.

### User Story: Compare Legacy Collision Flow

As an add-on maintainer, I want to reproduce the legacy collision-derived result, so that compatibility issues and visual behavior changes can be reviewed deliberately.

Acceptance criteria:

- A legacy generation path or compatibility setting can run the current collision-derived RG behavior.
- Generated bake metadata records whether a map came from curve-plus-collision, curve-only, or legacy collision generation.
- Existing serialized resources using the current generated source kind remain readable.

### User Story: Debug Meaningful Flow Vectors

As a user debugging a bake, I want Flow Arrows and validation text to distinguish useful direction from near-zero vectors, so that neutral data does not look like a confident sideways or arbitrary direction.

Acceptance criteria:

- Data validation reports vector length min/max/average and near-neutral pixel percentage.
- Flow Arrows hide, fade, or mark near-zero vectors as neutral rather than rotating arrows from an unstable angle.
- Warnings describe reduced collision detail separately from bad or unreadable generated textures.

### User Story: Consume Generated Data At Runtime

As a game developer, I want runtime scenes and water systems to consume the generated textures the same way they do today, so that the authoring improvement does not require runtime scene rewrites.

Acceptance criteria:

- `RiverBakeData` still stores explicit textures, channel metadata, source signature, source kind, texture size, content rect, and UV2 layout.
- Runtime shader sampling does not depend on editor-only collision helpers.
- WaterSystem composition continues to consume River flow maps without requiring source-specific runtime logic.

## Functional Requirements

- FR-1: The current default generated River bake behavior is `downstream_baseline_collision_support`; broader `Curve + Collision Modifiers` naming must map to or evolve from that behavior without breaking saved resources.
- FR-2: In curve-based behavior, occupied river texels must receive a non-neutral downstream RG baseline derived from the River curve or generated river atlas progress. This is already true for the current default regression fixture.
- FR-3: `Curve Only` behavior must be possible for scenes without bake helper colliders and must not require nonzero `baking_raycast_layers`.
- FR-4: Legacy collision-derived behavior must remain available for compatibility and comparison through the current `legacy_collision_only` behavior or a compatible alias.
- FR-5: No-collider generation in curve-based modes must complete successfully when other bake preflight requirements are valid.
- FR-6: Existing collision-derived foam, pressure, distance, and bank/obstacle support data should continue to be generated where colliders are available.
- FR-7: Collision-derived flow influence must not blend a useful curve baseline toward neutral merely because collision data is empty, flat, or low confidence.
- FR-8: Generated texture channel packing must remain compatible with current River shaders: packed signed flow in RG, foam in B, phase/noise in A, and distance/pressure in the support texture.
- FR-9: Generated River textures must keep the existing padded UV2 atlas layout and margin behavior.
- FR-10: Empty atlas cells and river start/end padding must not bleed misleading flow into occupied river texels.
- FR-11: Generated bake metadata must record source kind, generation behavior or mode, relevant bake settings, source signature, and useful vector/collision stats.
- FR-12: `Validate Data Textures` or equivalent diagnostics must report vector usefulness, not only channel contrast.
- FR-13: Flow Arrows must handle near-zero vectors as neutral or hidden, not as reliable direction indicators.
- FR-14: Imported and hand-painted flow maps must keep their existing data-texture requirements and packed RG interpretation.
- FR-15: River material speed controls must remain the first-pass speed controls; generated RG should primarily provide direction and a stable useful magnitude.

## Non-Functional Requirements

- Maintainability:
  - Keep the change localized to River bake generation, metadata, diagnostics, documentation, and debug visualization.
  - Prefer small helpers over a broad bake pipeline rewrite.
  - Document the coordinate-space reason for encoding curve baseline in river texture/tangent space, not raw world X/Z.
- Performance:
  - Avoid unbounded per-texel nearest-curve searches when the existing UV2 tile order can provide downstream progress.
  - Do not add runtime shader cost in the first implementation.
  - Measure bake-time impact at representative resolutions before calling the feature complete.
- Visual quality:
  - Straight rivers should show stable downstream motion and arrows.
  - Curved rivers should show continuous direction across bends and UV2 seams.
  - Collision detail should add visual interest without flattening or reversing the whole flow field.
- Godot 4.6+ compatibility:
  - Active implementation must use Godot 4.6+ APIs and avoid legacy Godot 3 APIs.
  - The plan and validation must account for Godot editor/runtime differences and renderer behavior.
- Editor usability:
  - The normal River bake workflow should remain simple.
  - If modes are exposed, the default should be clear and not require the user to understand the legacy design.
  - Warnings should be specific and actionable.
- Runtime usability:
  - Generated resources should remain explicit, saved, inspectable, and reloadable.
  - Runtime scenes should not require editor-only bake helpers.
- Extensibility:
  - Source kinds and metadata should leave room for imported, hand-painted, terrain slope, obstacle influence, and simulation-derived future work.

## Add-on Boundary

Editor authoring responsibilities:

- River menu bake action.
- Optional generation-mode inspector setting or internal compatibility switch.
- Bake progress, warnings, and validation output.
- Debug views including Flow Pattern and Flow Arrows.
- Documentation for bake helper, snap target, and gameplay collider roles.

Bake/data responsibilities:

- Curve-derived baseline RG generation.
- Optional collision support map generation.
- Collision confidence or modifier blending.
- Generated texture packing and padded UV2 atlas storage.
- `RiverBakeData` metadata, source signature, and external resource saving.

Runtime responsibilities:

- Shader inputs and packed RG decoding.
- Loading serialized `RiverBakeData`.
- Existing WaterSystem map composition.
- Runtime use of generated textures without live editor collision data.

Shared code must not depend on:

- Editor-only nodes or plugin state at runtime.
- Legacy Godot 3 APIs.
- One scene layout, one terrain setup, one material preset, or one project-specific collision-layer convention.
- Bake helper colliders being present in shipped runtime scenes.

## Data and Extension Model

Users should be able to:

- Generate the default curve-plus-collision River map.
- Generate a curve-only River map when no bake helper colliders are desired or available.
- Reproduce legacy collision-derived output for compatibility and review.
- Continue using imported or hand-painted flow maps with the existing packed RG contract.
- Save and inspect generated `RiverBakeData` resources.

Extension points:

- River generation mode or source-kind setting.
- `RiverBakeData.source_kind`.
- `RiverBakeData.source_metadata`.
- Existing shader/material controls for flow force and speed.
- Existing bake settings for resolution, blur, foam, dilation, raycast distance, and raycast layers.
- Future source kinds for imported, hand-painted, terrain slope, obstacle influence, and simulation-derived maps.

Override rules:

- Valid imported/manual maps should not be overwritten unless the user explicitly runs a generated bake.
- In curve-based generated modes, curve baseline is the fallback wherever collision influence is absent or low confidence.
- Collision modifiers may alter local flow only where the collision signal is meaningful.
- Legacy collision mode may write neutral or flat RG if collision input is flat; that behavior is preserved for comparison.

Shared systems must not hard-code:

- A required bundled texture other than existing default material/noise assets.
- A specific scene hierarchy for bake helpers.
- A single collision layer for snapping, baking, and gameplay.
- A material-only assumption that prevents WaterSystem or future runtime sampling from using the generated data.

## Acceptance Tests

- A no-collider river bake produces visibly moving downstream flow in Flow Pattern.
- A straight river produces consistent Flow Arrows along the river direction.
- A curved river produces smoothly changing Flow Arrows without seam flips at UV2 tile or column-continuation boundaries.
- A flat or uniform collider bake does not erase downstream flow.
- Bank-helper colliders add foam, pressure, or edge detail without destroying baseline direction.
- The legacy collision-derived result can still be reproduced for comparison.
- Imported or hand-painted flow maps keep their existing packed RG channel contract.
- `Validate Data Textures` reports useful vector stats, including near-neutral percentage.
- Near-zero vectors in Flow Arrows are hidden, faded, or marked neutral instead of shown as arbitrary directions.
- Saved `RiverBakeData` reloads with the generated textures, source kind, source metadata, content rect, UV2 sides, and valid-flow state intact.
- The shader's two-phase flow animation remains unchanged unless a separate shader defect is identified.

## Visual Validation Requirements

- A visible Godot editor check is required for shader animation, Flow Pattern, Flow Arrows, foam, pressure, and UV2 seam behavior.
- Validation must include:
  - straight no-collider river
  - curved no-collider river
  - flat/uniform collider setup
  - bank-helper or obstacle-helper colliders
  - legacy collision comparison
  - save/reload or F6-style runtime check
- The validation request must be sent directly in chat when needed, including scene path, plugin state, exact menu actions, output text to copy, visible behavior to report, Godot version, renderer, and device details.
- Local parser/static/headless checks are useful but are not proof of visible editor, shader, bake, or runtime behavior.

## Performance Requirements

- The feature must not add runtime shader cost in the first implementation.
- Bake-time impact from curve baseline generation and blending must be measured at representative River bake resolutions.
- The implementation should avoid high-cost nearest-curve searches per texel unless validation proves the simpler UV2 progress method is insufficient.
- CPU image blending is acceptable for the first implementation only if measured bake time remains reasonable.
- Generated texture memory should remain the same order as current River bakes: one padded `flow_foam_noise` texture and one padded `dist_pressure` texture.
- Extra GPU readbacks should be avoided unless a filter-shader blend path is chosen and measured.

## Open Questions

- Should generation behaviors be exposed in the inspector immediately, or kept internal/script-accessible until zero-layer and Curve Only validation prove the workflow?
- What exact collision confidence metric and blend curve should be used for local obstacle deflection?

## Resolved Questions

Move questions here once decided so future sessions do not keep treating them as open.

| Question | Resolution | Date | Notes |
| --- | --- | --- | --- |
| Should curve-derived flow be the default generated RG layer? | Yes. Default to `Curve + Collision Modifiers`. | 2026-05-22 | Research found comparable systems separate base flow intent from obstacle modifiers. |
| Should generation modes exist? | Yes in the data model; UI exposure can be gradual. | 2026-05-22 | Required modes are `Curve + Collision Modifiers`, `Curve Only`, `Collision Legacy`, and imported/manual compatibility. |
| Should the current UV2 atlas layout change? | No. Keep `padded_uv2_atlas_with_one_tile_margin`. | 2026-05-22 | Current shaders and stored metadata already depend on this layout. |
| Should speed come from new per-point metadata in the first pass? | No. Keep speed mostly in existing material controls. | 2026-05-22 | Per-point velocity and slope-derived speed are deferred. |
| Can existing collision foam/pressure/distance stay? | Yes. Keep collision-derived support maps and replace or blend only RG baseline flow. | 2026-05-22 | Current pipeline already separates RG combine from foam and distance/pressure outputs. |
| Should Flow Arrows handle near-zero vectors specially? | Yes. Near-zero vectors should be neutral, hidden, faded, or marked separately. | 2026-05-22 | Neutral packed RG has no meaningful angle. |
| Should bake helpers, snap targets, and gameplay colliders be documented separately? | Yes. Treat them as separate authoring roles and recommend named physics layers. | 2026-05-22 | Current baking has a layer mask; snapping currently uses a broad mask plus `waterways_snap_ignore`. |
| What validation scene path is canonical for this feature? | Add `scenes/validation/curve_derived_river_flow_validation.tscn`. | 2026-05-22 | `two_phase_flow_validation.tscn` validates shader consumption only, not the new bake path. |
| What should no-collider curve support maps contain in the first pass? | Use explicit blank support maps with `dist_pressure.rg = (0.0, 0.0)` and foam `B = 0.0`; keep alpha/noise from the existing tiled path. | 2026-05-22 | This keeps default material force visible without inventing pressure. |
| Should directional collision RG blending be implemented in the first slice? | No. Collision affects foam, distance, and pressure support maps only until a confidence rule exists. | 2026-05-22 | Avoids blending useful curve flow toward neutral when collision input is empty, flat, or low-confidence. |
| How should first-pass curve RG encode direction? | Encode local downstream `+V` in the river texture/tangent frame, not raw world X/Z. | 2026-05-22 | The shader decodes RG through `TANGENT` and `BINORMAL`; curved world-space motion comes from mesh UV/tangent layout. |
| Should the next slice add `baking_generation_mode` or extend `bake_generation_behavior`? | Extend the current serialized `bake_generation_behavior` string first. | 2026-05-22 | This avoids a parallel source-of-truth while the mode surface is still hidden/script-accessible. |
| Is `generated_downstream_baseline_collision_bake` the final `Curve + Collision Modifiers` source kind? | No. Treat it as the current foundation and narrower predecessor; new bakes now use `generated_curve_collision_modifiers_bake` or `generated_curve_only_bake`. | 2026-05-22 | Zero-layer/no-hit and true `Curve Only` semantics were added after this decision. |
| How are near-zero Flow Arrows represented right now? | The regression fix renders near-neutral raw vectors as neutral dark output below decoded magnitude `0.02`. | 2026-05-22 | Future styling can change, but the misleading confident-arrow behavior is no longer the current baseline. |

## Decision Log

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-05-22 | Create this spec from `preliminary_research.md` and `plan.md` as a draft. | The feature now has enough local and external research to define behavior before implementation. |
| 2026-05-22 | Treat the current no-collider neutral-flow behavior as a design limitation, not simply a port regression. | Research found the collision-first flow design in original Waterways and current Godot 4 code. |
| 2026-05-22 | Preserve the shader channel contract and defer shader rewrite. | The shader can consume any valid packed RG vector field; the fragile part is generation source, not the decode contract. |
