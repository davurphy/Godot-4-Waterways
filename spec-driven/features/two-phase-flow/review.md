# Review: Two-Phase Flow Foundation

## Review Date

2026-05-22 rebase of the 2026-05-21 review.

## Scope Reviewed

- `spec-driven/00-constitution.md`
- `spec-driven/01-workflow.md`
- `spec-driven/features/two-phase-flow/research.md`
- `spec-driven/features/two-phase-flow/plan.md`
- `addons/waterways/shaders/river.gdshader`
- `addons/waterways/shaders/river_debug.gdshader`
- `addons/waterways/shaders/lava.gdshader`
- `addons/waterways/river_manager.gd`
- `addons/waterways/resources/river_bake_data.gd`
- `addons/waterways/gui/river_menu.gd`
- `docs/godot-4-user-guide.md`
- `docs/godot-4-imports.md`
- workspace file availability for `project.godot` and `scenes/validation/`

## Current Truth

- Overall review status: Closed for the River preservation slice. Preservation guardrails, docs, current River generated-map validation, visible Forward+ runtime motion evidence, confirmed hand-clicked editor/F6 saved-bake behavior, and Forward+/Mobile/Compatibility scene-launch smoke checks are implemented. Lava visual validation is explicitly deferred/unvalidated for this feature closeout.
- Blocking issues remaining:
  - None for the static/docs preservation slice.
- Important issues remaining:
  - None for the River preservation closeout. The first "stuck Flow Pattern" report remains historical/pre-rebase evidence only.
- Last validation relied on: visible Godot 4.6.3 Forward+ console/runtime probe on 2026-05-22 with AMD Radeon RX 6800 XT, bounded Forward+/Mobile/Compatibility scene-launch smoke checks on 2026-05-22, plus `python spec-driven/features/two-phase-flow/check_shader_drift.py` passing 54 checks on 2026-05-22. The 2026-05-21 user-provided `RIVER_DATA_TEXTURE_TEST` Output is retained as historical alpha evidence, not current-baseline proof.
- Next action: none for the River preservation slice; optional follow-up is a future lava visual validation or museum exhibit pass.
- Historical detail starts at: Findings.

## Findings

### Blocking

- `spec.md` was absent when `plan.md` was written. The spec-driven workflow requires the spec to define behavior and acceptance criteria before implementation planning is treated as final. This is resolved for the current preservation slice by the focused spec and aligned task/validation docs.
- The local validation project now exists and includes `scenes/validation/two_phase_flow_validation.tscn`. Visible validation is still required, but it is no longer blocked by missing source fixtures.

### Important

- Alpha phase/noise validation is now mandatory, implemented in `River -> Validate Data Textures`, and captured for generated/resource-owned validation maps.
- `Validate Data Textures` now treats generated textures embedded in explicit `.river_bake.res` resources as generated/resource-owned instead of imported textures that need `.import` files, and includes `source_kind` in the Output.
- Generated River map blockers that could falsely implicate `FlowUVW` have been addressed elsewhere: default curve-based bakes now produce useful downstream RG support, true `curve_only` is explicit, and current validation reports decoded vector statistics.
- The 2026-05-21 stuck Flow Pattern attempt was retested against current generated maps through a visible Forward+ runtime probe. Runtime Flow Pattern changed over 10 seconds at default, slow, and high speeds, so it does not justify shader-math changes.
- A 2026-05-22 hand-clicked editor/F6 attempt found the validation scene itself was forcing Flow Pattern and synthetic validation maps at runtime. This was fixed by making F6 preserve the saved bake and normal shader by default; the user confirmed the fix. It still does not justify shader-math changes.
- `river_debug.gdshader` uses a different steepness diagnostic scale than river/lava. It is now classified as intentional debug-only amplification, so Flow Strength is qualitative rather than exact parity evidence.
- Performance guardrails are expressed as "no new samples, bake passes, GPU readbacks, generated textures, draw calls, or public APIs" for Option A.
- The drift guard normalizes whitespace and checks semantic contract points plus intentional variant differences.

### Minor

- The user-facing docs now explain two-phase behavior, alpha phase/noise triage, and debug-view interpretation for this feature.
- Older review notes about missing validation scenes and local headless crashes should be treated as historical context, not live blocking evidence.

## Premise Review

- The original premise is partially correct: two-phase flow deserves a focused foundation feature, but not because the shader is known broken.
- Evidence suggests the current implementation already has the core behavior. Work should harden docs, data checks, validation, and drift protection first.
- The most likely false premise to challenge in future bug triage is "bad-looking flow means `FlowUVW` is wrong." Data/import/material/scene causes must be checked first.
- This review outcome is docs/validation clarification, not a shader fix.

## Spec Compliance

| Acceptance Criterion | Status | Notes |
| --- | --- | --- |
| Preserve existing `FlowUVW` behavior | Pass static / visible open | Drift guard passes on 2026-05-22. Visible motion still needs a current-baseline retest, but old stuck output is stale evidence. |
| Document shader and data contract | Pass | Feature docs, user guide, and import docs now document the contract. |
| Add drift protection | Pass | `check_shader_drift.py` reports 54 passed, 0 failed. |
| Validate data before shader triage | Pass | Current `RIVER_DATA_TEXTURE_TEST` captures `source_kind`, decoded vector stats, active/near-neutral counts, `mag_avg`, and alpha range/state from current generated maps. |
| Validate visible Godot motion | Pass with lava deferred | Visible Forward+ runtime probe confirms active Flow Pattern frame changes, hand-clicked editor/F6 now preserves the saved bake and normal shader, and Forward+/Mobile/Compatibility scene-launch smoke checks pass. Lava visual validation is explicitly deferred/unvalidated. |
| Avoid scope creep | Pass so far | No shader math, shader samples, bake passes, generated textures, or public runtime APIs changed. |

## Architecture Compliance

- Godot 4.6+ API target preserved: Yes so far.
- Editor/runtime boundary preserved: Yes so far.
- Bake data and generated resources explicit: Pass; current resources are explicit, persisted, and diagnostics include source kind, alpha, and decoded-vector statistics. Hand-clicked editor/F6 behavior is confirmed after the validation-scene default fix.
- Legacy Godot 3 behavior used only as reference: Yes.
- Extension points preserved: Yes so far.
- Godot-native features preferred where practical: Yes.
- Bespoke systems justified: Yes; the drift guard is a narrow feature-local script.
- Comments explain non-obvious intent without restating obvious code: Not applicable yet.
- Feature and architecture docs updated for behavior, data flow, and boundary changes: Yes for static/docs work, current River Forward+ runtime validation, confirmed editor/F6 saved-bake behavior, renderer smoke checks, and explicit lava visual-validation deferral.

## Validation Results

- Automated:
  - `check_shader_drift.py` confirmed the three built-in shader files define `FlowUVW`, add `flow_foam_noise.a` to time, decode RG flow, preserve jump constants, classify steepness scales, and expose expected debug modes/menu entries.
  - This is static evidence only. It is not proof of visible motion quality.
- Human-assisted:
  - First user attempt reported no warnings/errors and stuck Flow Pattern after data validation passed; after the generated-map rebase and current runtime retest, this is historical/pre-rebase evidence only.
  - Current agent-run visible Forward+ runtime probe recorded current generated-map Output and Flow Pattern frame changes at default, slow, and high speeds.
- Renderer smoke:
  - Bounded F6-style scene launches passed in Forward+, Forward Mobile, and Compatibility on AMD Radeon RX 6800 XT with no warnings or shader/runtime errors after the stale generated-bake resource UID was removed from `two_phase_flow_validation.tscn`.
- Shader:
  - River/debug/lava share the core helper contract by static guard.
  - Debug steepness scale difference is resolved as intentional diagnostic amplification.
- Editor:
  - Menu entries for required debug views exist by static guard.
- Visual:
  - Current-baseline River Noise Map, Flow Pattern, Flow Arrows, Flow Strength, and Foam Mix are recorded through screenshots and frame deltas. Lava is explicitly deferred/unvalidated for this feature closeout.
- Bake output:
  - Current-baseline decoded vector and alpha Output is recorded for `TwoPhaseFlowRiver`.
- Runtime:
  - No new runtime API in scope.
- Performance:
  - Static preservation invariant holds for this change; no visual bake timing measurement yet.
- Manual:
  - Docs now identify stale generated maps as historical risk and lava visual validation as an intentional deferral, not a blocker for this preservation slice.

## Documentation Consistency Check

- [x] Closed bootstrap tasks are checked off in `tasks.md`.
- [x] Resolved open questions moved to `spec.md` resolved questions or decision log.
- [x] `plan.md` is being updated to reflect current architecture and workspace caveats.
- [x] `validation.md` current snapshot and matrix match the static review result.
- [x] No stale "open follow-up" language remains after implementation tasks close.
- [x] Latest handoff points to the true next action: current-baseline Forward+ validation retest.

## Follow-Up Tasks

- [x] Resolve source validation fixture availability.
- [x] Implement static drift guard or manual checklist.
- [x] Add alpha phase/noise statistics to data texture validation.
- [x] Classify debug steepness scale difference.
- [x] Update `docs/godot-4-user-guide.md` and `docs/godot-4-imports.md`.
- [x] Run current-baseline visible Forward+ River validation retest.
- [x] Run Forward+/Mobile/Compatibility scene-launch smoke checks.
- [x] Record lava behavior or mark it deferred.
- [x] Decide whether `two_phase_flow_validation.tscn` becomes a Two-Phase Flow Museum exhibit or an accepted follow-up.

## Decision Updates

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-05-21 | Treat missing validation scenes as a blocker for completion. | Historical blocker resolved by restoring `project.godot` and `scenes/validation/two_phase_flow_validation.tscn`; visible validation remains required. |
| 2026-05-21 | Make alpha diagnostics mandatory. | Alpha phase/noise is central to hiding synchronized resets. |
| 2026-05-21 | Add a performance preservation invariant. | Option A should not change shader or bake cost. |
| 2026-05-21 | Use `check_shader_drift.py` as the drift guard. | It records stable pass/fail markers without changing shader behavior. |
| 2026-05-21 | Classify debug `steepness_map * 8.0` as intentional diagnostic amplification. | Flow Strength should remain useful for visual diagnosis but not be treated as exact river/lava parity. |
| 2026-05-21 | Treat stuck Flow Pattern as a validation-scene/editor-preview issue until retested. | Historical decision before the generated-map rebase; no `FlowUVW` edit is justified before current-baseline visible validation. |
| 2026-05-22 | Rebase this feature on current generated River map behavior. | Default curve-based bakes now provide downstream RG support, true `curve_only` is explicit, and decoded vector diagnostics can prove whether input data is active before shader triage. |
| 2026-05-22 | Keep `FlowUVW` unchanged until current-baseline visible validation proves a shader-specific issue. | The old stuck Flow Pattern attempt predates the generated-map fixes and should not drive shader math changes. |
| 2026-05-22 | Preserve `FlowUVW` after current Forward+ retest. | Fresh current generated maps have active occupied vectors and varied alpha, and runtime Flow Pattern changes at default, slow, and high speeds. |
| 2026-05-22 | Treat Mobile and Compatibility as smoke-tested for this feature. | The validation scene launches and runs in Forward Mobile and Compatibility without shader/runtime errors; full hand-inspected debug-view validation remains Forward+ only. |
| 2026-05-22 | Defer lava visual validation for this preservation closeout. | River validation now has current data, runtime motion, and confirmed editor/F6 saved-bake behavior; lava remains statically guarded but visually unvalidated. |
| 2026-05-22 | Treat the Two-Phase Flow Museum exhibit as a follow-up. | The existing validation scene is sufficient for this preservation slice; a clearer exhibit can be tracked outside this feature. |
