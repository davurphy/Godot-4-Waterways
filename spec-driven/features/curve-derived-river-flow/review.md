# Review: Curve-Derived River Flow

## Review Date

2026-05-22

## Scope Reviewed

- Documentation alignment and current-baseline inspection:
  - `spec-driven/features/curve-derived-river-flow/spec.md`
  - `spec-driven/features/curve-derived-river-flow/plan.md`
  - `spec-driven/features/curve-derived-river-flow/tasks.md`
  - `spec-driven/features/curve-derived-river-flow/research.md`
  - `spec-driven/features/curve-derived-river-flow/validation.md`
  - `spec-driven/features/curve-derived-river-flow/review.md`
- Active implementation files inspected for current-baseline behavior:
  - `addons/waterways/river_manager.gd`
  - `addons/waterways/water_helper_methods.gd`
  - `addons/waterways/filter_renderer.gd`
  - `addons/waterways/resources/river_bake_data.gd`
  - `addons/waterways/river_gizmo.gd`
  - `addons/waterways/plugin.gd`
  - `addons/waterways/gui/river_menu.gd`
  - `addons/waterways/shaders/river.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
  - `addons/waterways/shaders/system_renders/system_flow.gdshader`
  - relevant filter shaders in `addons/waterways/shaders/filters`
- No product code changes were made in this review pass.

## Current Truth

Use this as the review dashboard. Keep it concise and update it before handing off.

- Overall review status: Feature complete for the first curve-derived river flow slice.
- Blocking issues remaining: none found for the curve-derived bake data path.
- Important issues remaining: none blocking this feature slice. Future directional collision RG blending, public inspector UI, transparency/material-control validation, generated-subresource diagnostics cleanup, and live human animation review are deferred follow-ups.
- Last validation relied on: Godot 4.6.3 Task 12 probes on 2026-05-22 for canonical scene rebake/save, `Validate Data Textures`, screenshot review, fresh-process reload, runtime-style shader valid flags, WaterSystem sampling, F6-style launch smoke, and low/current/high bake timings.
- Next action: none required for this feature slice.
- Historical detail starts at: not applicable yet.

## Findings

### Blocking

- None for the current curve-derived bake implementation slice.

### Important

- Task 12 local validation covered visible screenshots, rebake/save, fresh reload, runtime-style shader state, WaterSystem sampling, F6-style launch smoke, and performance. A live human editor pass can still add confidence for time-based motion and menu ergonomics, but is not required to complete this slice.
- Directional collision RG blending remains intentionally deferred until a concrete collision-confidence rule exists.
- Active Waterways now has `downstream_baseline_collision_support`, `curve_only`, `legacy_collision_only`, `generated_curve_collision_modifiers_bake`, `generated_curve_only_bake`, decoded vector stats, unused atlas RG neutralization, Flow Arrows thresholding, and WaterSystem alpha-covered stats.
- `generated_downstream_baseline_collision_bake` remains readable as the predecessor source kind.
- User-reported black Foam Map, Pressure Map, and Foam Mix on no-collider/curve-only fixtures are expected for this slice because blank support maps are intentional there. This should not block the current curve-derived flow plan.
- User-reported weak or invisible `flow_pressure` effects are expected on blank-support fixtures. `flow_max` needs a targeted high-force check before it can be called broken.
- User-reported transparency-control behavior is not covered by the current bake-generation acceptance criteria and deserves a separate shader/material validation pass once current plan validation is otherwise complete.
- The stale `CurvedNoColliderRiver` signature issue was resolved for this scene by Task 12 rebake/save/reload; fresh reload reports `valid_flowmap=true` and `source_kind=generated_curve_only_bake`.

### Minor

- `Validate Data Textures` warns that generated textures stored as `.res::ImageTexture_*` subresources lack `.import` files. The data is readable and reloads correctly, so this is a diagnostics false-positive rather than a bake blocker.

## Premise Review

- Was the original premise correct, partially correct, or wrong?
  - Partially correct as an authoring-design issue: legacy collision-only generated bakes can produce near-neutral RG when collision data is absent or flat. Current default bakes now use the downstream-baseline regression fix.
- Did any evidence suggest the user or agent was overlooking scene/data/context?
  - Yes. The no-collider warning can be accurate scene/data evidence, not a raycast bug.
- If yes, was that raised with the user early enough?
  - Yes. The plan and tasks state this is a design improvement rather than proof that current warnings are false.
- Was the final outcome a code/design fix, docs/validation clarification, or expected-behavior explanation?
  - Code/design implementation is complete for the first curve-only/blank-support slice, with docs and validation clarification updated around expected blank support maps and remaining follow-ups.

## Spec Compliance

| Acceptance Criterion | Status | Notes |
| --- | --- | --- |
| A no-collider river bake produces visibly moving downstream flow in Flow Pattern. | Pass local | No-collider bakes produce occupied `mag_avg=0.247090`; Flow Pattern screenshots are visible. Optional live time-based observation is deferred. |
| A straight river produces consistent Flow Arrows along the river direction. | Pass local screenshot | Canonical overview screenshot shows active Flow Arrows; data reports occupied `near_neutral=0.00%`. |
| A curved river produces smoothly changing Flow Arrows without seam flips. | Pass local screenshot | `CurvedNoColliderRiver` and `SeamCrossingCurveRiver` screenshots show dense coherent arrows; seam fixture reload reports occupied `near_neutral=0.00%`, unused `near_neutral=100.00%`. |
| A flat or uniform collider bake does not erase downstream flow. | Pass baseline | Default regression fixture reports occupied `mag_avg=0.247090`, `near_neutral=0.00%`. |
| Bank-helper colliders add foam, pressure, or edge detail without destroying baseline direction. | Pass local | `BankHelperRiver` hit count `9674`, fallback `false`, occupied `mag_avg=0.247090`, foam `0.0000..1.0000`, pressure `0.0000..0.8902`; debug screenshots show support data where helpers exist. |
| The legacy collision-derived result can still be reproduced for comparison. | Pass baseline | `legacy_collision_only` probe reports occupied `near_neutral=95.81%`, `mag_avg=0.008847`. |
| Imported or hand-painted flow maps keep their existing packed RG channel contract. | Pass by code review | The packed RG shader contract and imported/manual map handling were not changed by this slice; generated source-kind metadata remains additive. |
| `Validate Data Textures` reports vector stats. | Pass baseline | Default and legacy probes print source, occupied, and unused decoded vector stats. |
| Near-zero vectors in Flow Arrows are neutral/hidden/faded instead of arbitrary. | Pass implementation / visual | Shader threshold exists; active curve arrows are visible. Legacy remains weak/near-neutral by stats. |
| Saved `RiverBakeData` reloads with generated textures and metadata. | Pass local | Fresh-process reload reports `valid_flowmap=true` for all 6 rivers, matching source signatures, plus runtime-style shader valid flags true. |
| The shader's two-phase flow animation remains unchanged. | Pass local | `river.gdshader` was not part of this slice; Flow Pattern screenshots render. Optional live animation review is deferred. |

## Architecture Compliance

- Godot 4.6+ API target preserved: Pass local; Task 12 ran on Godot 4.6.3.
- Editor/runtime boundary preserved: Pass local; bake changes remain in editor generation and resource metadata.
- Bake data and generated resources explicit: Pass local; source kinds and fallback metadata are written.
- Legacy Godot 3 behavior used only as reference: Pass.
- Extension points preserved: Pass; `bake_generation_behavior` remains the script/storage switch.
- Godot-native features preferred where practical: Pass local.
- Bespoke systems justified: Pass for generated texture fallback and validation probes.
- Comments explain non-obvious intent without restating obvious code: Partial; the coordinate-space comment remains in the bake path.
- Feature and architecture docs updated for behavior, data flow, and boundary changes: Pass for the current slice; Task 12 validation results are recorded in `validation.md`.

## Validation Results

- Automated/local:
  - Current baseline probes passed for scene load, default downstream-baseline bake, legacy comparison, decoded vector stats, unused atlas neutrality, and WaterSystem alpha-covered stats.
  - New curve behavior probes passed for default zero-layer, default no-hit, curve-only zero-layer, and legacy zero-layer failure.
  - Canonical validation scene rebake/save/reload/runtime probes passed locally in Task 12.
- Human-assisted:
  - Prior user-visible notes are recorded in `validation.md`; this pass used agent-run screenshots rather than manual editor interaction.
- Shader:
  - Flow Pattern and Flow Arrows screenshots render in Godot 4.6.3 Forward+; `river.gdshader` was not changed by this slice.
- Editor:
  - Exact editor menu clicking was not repeated manually; scripted calls exercised `bake_texture()` and `validate_data_textures()` for the same fixtures.
- Visual:
  - Overview and focused screenshots captured Flow Pattern, Flow Arrows, Foam Map, Pressure Map, and Foam Mix.
- Bake output:
  - Blank support fallback was confirmed for no-collider/curve-only fixtures; collider support was confirmed for `FlatColliderRiver` and `BankHelperRiver`.
- Runtime:
  - Fresh-process runtime-style load passed for all rivers; F6-style scene launch smoke exited cleanly.
- Performance:
  - Resolution 0, 2, and 4 timings were recorded. High-resolution collision-support bakes are noticeable at about 18-25 seconds on the validation machine, but no runaway or timeout occurred.
- Manual:
  - Documentation alignment performed.
  - Required docs now treat regression-delivered pieces as current baseline rather than future tasks.

## Documentation Consistency Check

- [x] Closed tasks are checked off in `tasks.md`.
- [x] No stale "open follow-up" language remains for completed doc-alignment work.
- [x] Resolved open questions moved to `spec.md` resolved questions or decision log.
- [x] `plan.md` reflects that the Curve Only/no-layer implementation slice is locally complete; `tasks.md` and `validation.md` record Task 12 local validation and optional live human review.
- [x] `validation.md` current snapshot and matrix match the current Task 12 baseline and implemented curve-only state.
- [x] Latest handoff points to the true next action through `tasks.md`.

## Follow-Up Tasks

- [x] Task 3 in `tasks.md`: extend generation behavior naming without broad UI churn.
- [x] Task 5 in `tasks.md`: refactor bake preflight by behavior.
- [x] Task 6 in `tasks.md`: add exact blank support-map fallback for no-layer and no-hit curve-based bakes.
- [x] Task 12 in `tasks.md`: data, screenshot, reload/runtime, F6-style smoke, and performance portions are complete; optional live human animation review is deferred.

## Decision Updates

- 2026-05-22: `research.md`, `validation.md`, and `review.md` were created from the standard feature-folder template shape.
- 2026-05-22: `spec.md` open questions were narrowed to decisions that remain truly open after the revised plan.
- 2026-05-22: Rebased docs after local verification; next slice should extend `bake_generation_behavior` instead of adding a parallel `baking_generation_mode`.
- 2026-05-22: Task 12 local validation passed for canonical scene rebake/save/reload/runtime-style checks and screenshots; only optional live human animation review remains.
- 2026-05-22: Feature marked complete for the first curve-derived river flow slice; optional live editor review and diagnostics cleanup are tracked as deferred follow-ups.
