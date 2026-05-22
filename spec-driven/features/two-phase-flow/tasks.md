# Tasks: Two-Phase Flow Foundation

Complete tasks in order unless `spec.md` or `plan.md` is revised. Each task should be independently reviewable and should avoid shader behavior changes unless validation forces a spec update first.

## Current Truth

- Current status: Closed for the River preservation slice after rebasing on 2026-05-22 against the completed flow-map direction regression and curve-derived river flow slices. Drift guard, alpha diagnostics, generated `.river_bake.res` source-kind reporting, documentation, validation fixture, generated-map data validation scaffolding, a current River Forward+ runtime validation probe, confirmed editor/F6 saved-bake behavior, and Forward+/Mobile/Compatibility scene-launch smoke checks are in place.
- Current implementation slice: preservation docs, validation scaffolding, drift/data guardrails, and current Waterways baseline alignment. No shader math or bake-pipeline change is planned in this feature.
- Remaining open task count: 0 primary feature gates, plus cleanup checks.
- Last passing validation: `python spec-driven/features/two-phase-flow/check_shader_drift.py` passed 54 checks on 2026-05-22.
- Local Godot paths for validation: GUI `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`; console `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`.
- Next recommended action: none for the River preservation slice. Lava visual validation is explicitly deferred/unvalidated, and a richer Two-Phase Flow Museum exhibit is accepted as follow-up work outside this feature.
- Known deferred work: shared shader include, advanced material controls, runtime sampling API, WaterSystem/Buoyant changes, bake redesign, shader-tier presets, and any `FlowUVW` change not backed by current-baseline visible validation.

## Open Work

- [x] Resolve validation fixture availability.
  - Completed: `project.godot` and `scenes/validation/two_phase_flow_validation.tscn` now exist in this workspace.
  - Validate: visible current-baseline validation is recorded in `validation.md`, including the later confirmed editor/F6 saved-bake fix.

- [x] Add a static drift guard or first-pass manual checklist.
  - Completed: `spec-driven/features/two-phase-flow/check_shader_drift.py` verifies river, river debug, and lava shaders keep the `FlowUVW` contract, RG decode, alpha time offset, jump constants, steepness scale classification, and required debug modes/menu entries.
  - Validate: `python spec-driven/features/two-phase-flow/check_shader_drift.py` reports pass/fail markers for `river.gdshader`, `river_debug.gdshader`, `lava.gdshader`, and `river_menu.gd`.

- [x] Classify the debug steepness scale difference.
  - Completed: `river_debug.gdshader` using `* 8.0` is classified as intentional debug-only diagnostic amplification; river and lava remain at `* 4.0`.
  - Validate: `plan.md`, `spec.md`, and `review.md` record that Flow Strength is qualitative evidence, not exact parity evidence.

- [x] Add required alpha phase/noise diagnostics to data texture validation.
  - Completed: `Validate Data Textures` reports `alpha_min`, `alpha_max`, `alpha_range`, `alpha_state`, and sample count for `flow_foam_noise.a`.
  - Validate: user-provided `RIVER_DATA_TEXTURE_TEST` output captured generated/resource-owned maps with closest neutral RG `(0.4980, 0.4980)` and varied alpha range `0.6824`.

- [x] Rebase this feature against current generated River behavior.
  - Completed: `spec.md`, `plan.md`, `tasks.md`, `validation.md`, `review.md`, and `research.md` now treat the 2026-05-21 stuck Flow Pattern attempt as stale evidence gathered before downstream-baseline/curve-derived generated maps were complete.
  - Validate: no current-truth section should describe old near-neutral generated maps as a live two-phase shader blocker.

- [x] Document the two-phase shader contract in user-facing docs.
  - Completed: `docs/godot-4-user-guide.md` explains current two-phase behavior, debug interpretation, and data-first artifact triage.
  - Validate: docs mention `FlowUVW`, alpha phase/noise offset, Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix without exposing advanced controls as recommended tweaks.

- [x] Clarify imported alpha/noise expectations.
  - Completed: `docs/godot-4-imports.md` says imported `flow_foam_noise.a` should be preserved when used as phase/noise data.
  - Validate: docs distinguish data textures from visual textures and warn against import settings that destroy numeric alpha.

- [x] Write exact human-assisted validation request for visible Godot checks.
  - Completed: `validation.md` contains the exact scene/workflow, plugin state, debug view sequence, Output text to copy, and renderer/device details to report.
  - Validate: next user-facing validation request can be pasted directly from `validation.md` without asking the user to infer steps.

- [x] Run or record fresh current-baseline Forward+ River visual validation.
  - Completed: 2026-05-22 agent-run visible Forward+ console probe used the Godot 4.6.3 console executable, rebaked `TwoPhaseFlowRiver`, persisted the explicit generated bake resource, captured full `RIVER_DATA_TEXTURE_TEST` output with decoded vector and alpha stats, rendered Noise Map, Flow Pattern, Flow Arrows, Flow Strength, and Foam Mix, and measured Flow Pattern frame changes for default, slow, and high `flow_speed`.
  - Caveat: this started as runtime/F6-style evidence; a later hand-clicked F6 attempt found and fixed a validation-scene helper mismatch, and the user confirmed the fix resolved the F6 behavior.
  - Validate: `validation.md` records Pass status for the River preservation slice, exact paths, output, device, screenshots, and the explicit lava visual-validation deferral.

- [x] Run Forward+/Mobile/Compatibility renderer smoke checks.
  - Completed: 2026-05-22 bounded F6-style scene launches loaded `two_phase_flow_validation.tscn` in Forward+, Forward Mobile, and Compatibility with no warnings or shader/runtime errors after the stale generated-bake resource UID was removed from the scene reference.
  - Caveat: Mobile and Compatibility were scene-launch smoke checks only, not full hand-inspected debug-view validation.
  - Validate: `validation.md` records renderer, device, FPS marker, and residual visual-validation caveats.

- [x] Close the feature review.
  - Expected change: `review.md` maps acceptance criteria to evidence, records remaining risks, and confirms no deferred scope slipped into implementation.
  - Completed: `review.md`, `tasks.md`, and `validation.md` now agree that River preservation is closed and lava visual validation is deferred/unvalidated.

## Setup

- [x] Confirm the current workspace state.
- [x] Read `spec.md`, `plan.md`, `research.md`, and `validation.md`.
- [x] Check `audit/code-audit.md` for relevant known risks if that file exists in the source workspace.
  - Result: no `audit/code-audit.md` file is present in this checkout.
- [x] Confirm this task affects active code in `addons/waterways` and feature docs under `spec-driven`; legacy Godot 3 code is reference-only.
- [x] Run the context challenge check: this is release hardening, not a response to a proven broken shader.

## Validation

- [x] Run automated/static checks listed in `validation.md`.
- [x] Revisit the premise check after validation: static evidence still supports preservation; no shader math change is justified without visible evidence.
- [x] For Godot editor, viewport, scene-running, gizmo, shader, bake, or runtime checks, ask the user in chat to run the exact check and relay Output text, screenshots or clips, version, renderer, device, and visible behavior.
- [x] Do not rely on `validation.md` alone for human-assisted checks; paste the requested steps into the user-facing message.
- [x] Record first human-assisted Flow Pattern attempt in `validation.md` and summarize it in `review.md`.
- [x] Record current-baseline visible retest in `validation.md` and summarize it in `review.md`.
- [x] Record Forward+/Mobile/Compatibility renderer scene-launch smoke checks in `validation.md` and summarize them in `review.md`.

## Cleanup

- [ ] Remove temporary debug code that is not part of the planned validation UI.
- [x] Remove stale validation-scene resource UID that produced a non-behavioral load warning for the generated bake reference.
- [x] List scratch/generated artifacts created during validation and decide whether to keep, exclude, or delete them.
  - Completed: `validation.md` records ignored Godot cache, ignored screenshots, deleted temporary probe scripts, and refreshed `TwoPhaseFlowRiver.river_bake.res`.
- [ ] Confirm packaging excludes disposable folders, generated bakes, editor caches, validation fixtures, and local probe outputs.
- [ ] Add or refine comments only where they protect non-obvious shader math, Godot quirks, performance-sensitive paths, or editor/runtime boundaries.
- [x] Update docs for any changed decisions.
- [ ] Confirm generated data and resources remain explicit and inspectable.
- [ ] Confirm editor-only state did not leak into runtime-only code.
- [ ] Confirm no obsolete Godot 3 APIs were introduced into active Godot 4.6+ code.

## Feature Completion Gate

- [x] Museum showcase decision: yes, this foundation deserves either a Two-Phase Flow Museum exhibit or an accepted follow-up that turns `two_phase_flow_validation.tscn` into a clearer exhibit.
  - Decision: accepted follow-up. The existing validation scene is enough for this preservation closeout because current data validation, runtime motion, and editor/F6 saved-bake behavior are recorded.

## Historical or Closed Tasks

- [x] Create focused `spec.md`, `tasks.md`, `validation.md`, and `review.md` from research Option A and the 2026-05-21 design review.
  - Completed: 2026-05-21.
