# Review: Two-Phase Flow Foundation

## Review Date

2026-05-21

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

- Overall review status: Partial; preservation guardrails and docs are implemented, but visible Godot validation is still required before closure.
- Blocking issues remaining:
  - Local headless Godot 4.6.2 Mono crashes before scene checks complete.
  - The first human-assisted Flow Pattern attempt reported stuck motion with no warnings/errors, so visible validation is not passed yet.
- Important issues remaining:
  - Retest the adjusted validation fixture and record Forward+ visible motion behavior for Flow Pattern, Flow Arrows, Flow Strength, Noise Map, Foam Mix, and lava.
- Last validation relied on: `python spec-driven/features/two-phase-flow/check_shader_drift.py` passed 54 checks, and user-provided `RIVER_DATA_TEXTURE_TEST` output showed neutral RG plus varied alpha on 2026-05-21.
- Next action: reload `scenes/validation/two_phase_flow_validation.tscn` in visible Godot Forward+, retest Flow Pattern after the fixture adjustment, and run the scene with F6 if editor preview still appears stuck.
- Historical detail starts at: Findings.

## Findings

### Blocking

- `spec.md` was absent when `plan.md` was written. The spec-driven workflow requires the spec to define behavior and acceptance criteria before implementation planning is treated as final. This is resolved for the current preservation slice by the focused spec and aligned task/validation docs.
- The local validation project now exists and includes `scenes/validation/two_phase_flow_validation.tscn`. Visible validation is still required because the local headless Godot check crashes before scene verification.

### Important

- Alpha phase/noise validation is now mandatory, implemented in `River -> Validate Data Textures`, and captured for generated/resource-owned validation maps.
- `river_debug.gdshader` uses a different steepness diagnostic scale than river/lava. It is now classified as intentional debug-only amplification, so Flow Strength is qualitative rather than exact parity evidence.
- Performance guardrails are expressed as "no new samples, bake passes, GPU readbacks, generated textures, draw calls, or public APIs" for Option A.
- The drift guard normalizes whitespace and checks semantic contract points plus intentional variant differences.

### Minor

- The user-facing docs now explain two-phase behavior, alpha phase/noise triage, and debug-view interpretation for this feature.
- The plan should explicitly account for the minimal package/source workspace split described in README.

## Premise Review

- The original premise is partially correct: two-phase flow deserves a focused foundation feature, but not because the shader is known broken.
- Evidence suggests the current implementation already has the core behavior. Work should harden docs, data checks, validation, and drift protection first.
- The most likely false premise to challenge in future bug triage is "bad-looking flow means `FlowUVW` is wrong." Data/import/material/scene causes must be checked first.
- This review outcome is docs/validation clarification, not a shader fix.

## Spec Compliance

| Acceptance Criterion | Status | Notes |
| --- | --- | --- |
| Preserve existing `FlowUVW` behavior | Partial | Drift guard passes; first visible Flow Pattern attempt reported stuck motion, so retest is pending before trusting visible behavior. |
| Document shader and data contract | Pass | Feature docs, user guide, and import docs now document the contract. |
| Add drift protection | Pass | `check_shader_drift.py` reports 54 passed, 0 failed. |
| Validate data before shader triage | Pass | User-provided Output captured neutral RG and varied alpha stats for generated validation maps. |
| Validate visible Godot motion | Open | First Flow Pattern attempt reported stuck motion; adjusted-fixture retest is pending. |
| Avoid scope creep | Pass so far | No shader math, shader samples, bake passes, generated textures, or public runtime APIs changed. |

## Architecture Compliance

- Godot 4.6+ API target preserved: Yes so far.
- Editor/runtime boundary preserved: Yes so far.
- Bake data and generated resources explicit: Partial; existing resources are explicit, and alpha diagnostics are implemented but not yet captured from a visible run.
- Legacy Godot 3 behavior used only as reference: Yes.
- Extension points preserved: Yes so far.
- Godot-native features preferred where practical: Yes.
- Bespoke systems justified: Yes; the drift guard is a narrow feature-local script.
- Comments explain non-obvious intent without restating obvious code: Not applicable yet.
- Feature and architecture docs updated for behavior, data flow, and boundary changes: Yes for static/docs work; visible validation result still pending.

## Validation Results

- Automated:
  - `check_shader_drift.py` confirmed the three built-in shader files define `FlowUVW`, add `flow_foam_noise.a` to time, decode RG flow, preserve jump constants, classify steepness scales, and expose expected debug modes/menu entries.
  - This is static evidence only. It is not proof of visible motion quality.
- Human-assisted:
  - First user attempt reported no warnings/errors and stuck Flow Pattern after data validation passed; this is recorded as fail/partial pending retest.
- Shader:
  - River/debug/lava share the core helper contract by static guard.
  - Debug steepness scale difference is resolved as intentional diagnostic amplification.
- Editor:
  - Menu entries for required debug views exist by static guard.
- Visual:
  - Flow Pattern fail/partial on first attempt; Flow Arrows, Flow Strength, Noise Map, Foam Mix, and lava remain to be recorded.
- Bake output:
  - Unrun for this feature.
- Runtime:
  - No new runtime API in scope.
- Performance:
  - Static preservation invariant holds for this change; no visual bake timing measurement yet.
- Manual:
  - Docs now identify missing validation fixtures as a blocker.

## Documentation Consistency Check

- [x] Closed bootstrap tasks are checked off in `tasks.md`.
- [x] Resolved open questions moved to `spec.md` resolved questions or decision log.
- [x] `plan.md` is being updated to reflect current architecture and workspace caveats.
- [x] `validation.md` current snapshot and matrix match the static review result.
- [x] No stale "open follow-up" language remains after implementation tasks close.
- [x] Latest handoff points to the true next action: adjusted-fixture Forward+ validation retest.

## Follow-Up Tasks

- [x] Resolve source validation fixture availability.
- [x] Implement static drift guard or manual checklist.
- [x] Add alpha phase/noise statistics to data texture validation.
- [x] Classify debug steepness scale difference.
- [x] Update `docs/godot-4-user-guide.md` and `docs/godot-4-imports.md`.
- [ ] Run adjusted-fixture visible Forward+ validation retest.

## Decision Updates

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-05-21 | Treat missing validation scenes as a blocker for completion. | Visual validation is required and this checkout lacks source fixtures. |
| 2026-05-21 | Make alpha diagnostics mandatory. | Alpha phase/noise is central to hiding synchronized resets. |
| 2026-05-21 | Add a performance preservation invariant. | Option A should not change shader or bake cost. |
| 2026-05-21 | Use `check_shader_drift.py` as the drift guard. | It records stable pass/fail markers without changing shader behavior. |
| 2026-05-21 | Classify debug `steepness_map * 8.0` as intentional diagnostic amplification. | Flow Strength should remain useful for visual diagnosis but not be treated as exact river/lava parity. |
| 2026-05-21 | Treat stuck Flow Pattern as a validation-scene/editor-preview issue until retested. | Data validation passed and shader drift guard passed, so no `FlowUVW` edit is justified before adjusted visible validation. |
