# Tasks: Two-Phase Flow Foundation

Complete tasks in order unless `spec.md` or `plan.md` is revised. Each task should be independently reviewable and should avoid shader behavior changes unless validation forces a spec update first.

## Current Truth

- Current status: Drift guard, alpha diagnostics, documentation, validation fixture, and generated-map data validation are recorded; first Forward+ Flow Pattern attempt reported stuck motion, so adjusted-fixture retest remains open.
- Current implementation slice: preservation docs, validation scaffolding, and drift/data guardrails.
- Remaining open task count: 2.
- Last passing validation: `python spec-driven/features/two-phase-flow/check_shader_drift.py` passed 54 checks, and `RIVER_DATA_TEXTURE_TEST` reported neutral RG plus varied alpha for generated maps on 2026-05-21.
- Next recommended action: reload `scenes/validation/two_phase_flow_validation.tscn`, let the tool script refresh maps, then in visible Godot Forward+ switch through Noise Map, Flow Pattern, Flow Arrows, Flow Strength, and Foam Mix. If editor preview still appears stuck, run the scene with F6 to rule out editor redraw/TIME behavior.
- Known deferred work: shared shader include, advanced material controls, runtime sampling API, WaterSystem/Buoyant changes, bake redesign, shader-tier presets.

## Open Work

- [x] Resolve validation fixture availability.
  - Completed: `project.godot` and `scenes/validation/two_phase_flow_validation.tscn` now exist in this workspace.
  - Validate: visible validation remains open until the scene is opened in Godot and the Output/visual result is recorded.

- [x] Add a static drift guard or first-pass manual checklist.
  - Completed: `spec-driven/features/two-phase-flow/check_shader_drift.py` verifies river, river debug, and lava shaders keep the `FlowUVW` contract, RG decode, alpha time offset, jump constants, steepness scale classification, and required debug modes/menu entries.
  - Validate: `python spec-driven/features/two-phase-flow/check_shader_drift.py` reports pass/fail markers for `river.gdshader`, `river_debug.gdshader`, `lava.gdshader`, and `river_menu.gd`.

- [x] Classify the debug steepness scale difference.
  - Completed: `river_debug.gdshader` using `* 8.0` is classified as intentional debug-only diagnostic amplification; river and lava remain at `* 4.0`.
  - Validate: `plan.md`, `spec.md`, and `review.md` record that Flow Strength is qualitative evidence, not exact parity evidence.

- [x] Add required alpha phase/noise diagnostics to data texture validation.
  - Completed: `Validate Data Textures` reports `alpha_min`, `alpha_max`, `alpha_range`, `alpha_state`, and sample count for `flow_foam_noise.a`.
  - Validate: user-provided `RIVER_DATA_TEXTURE_TEST` output captured generated/resource-owned maps with closest neutral RG `(0.4980, 0.4980)` and varied alpha range `0.6824`.

- [x] Document the two-phase shader contract in user-facing docs.
  - Completed: `docs/godot-4-user-guide.md` explains current two-phase behavior, debug interpretation, and data-first artifact triage.
  - Validate: docs mention `FlowUVW`, alpha phase/noise offset, Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix without exposing advanced controls as recommended tweaks.

- [x] Clarify imported alpha/noise expectations.
  - Completed: `docs/godot-4-imports.md` says imported `flow_foam_noise.a` should be preserved when used as phase/noise data.
  - Validate: docs distinguish data textures from visual textures and warn against import settings that destroy numeric alpha.

- [x] Write exact human-assisted validation request for visible Godot checks.
  - Completed: `validation.md` contains the exact scene/workflow, plugin state, debug view sequence, Output text to copy, and renderer/device details to report.
  - Validate: next user-facing validation request can be pasted directly from `validation.md` without asking the user to infer steps.

- [ ] Run or record human-assisted Forward+ visual validation.
  - Expected change: validation result records Godot version, renderer, GPU/device, scene/workflow, material settings, visible behavior, and screenshots/clips if available. Output text is already captured for data validation, and the first visual attempt reported stuck Flow Pattern with no warnings/errors.
  - Validate: `validation.md` matrix marks Forward+ visual motion checks Pass/Partial/Fail with date and owner.

- [ ] Close the feature review.
  - Expected change: `review.md` maps acceptance criteria to evidence, records remaining risks, and confirms no deferred scope slipped into implementation.
  - Validate: `tasks.md`, `plan.md`, `validation.md`, and `review.md` agree on current status and open work.

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
- [ ] Record adjusted-fixture retest in `validation.md` and summarize it in `review.md`.

## Cleanup

- [ ] Remove temporary debug code that is not part of the planned validation UI.
- [ ] List scratch/generated artifacts created during validation and decide whether to keep, exclude, or delete them.
- [ ] Confirm packaging excludes disposable folders, generated bakes, editor caches, validation fixtures, and local probe outputs.
- [ ] Add or refine comments only where they protect non-obvious shader math, Godot quirks, performance-sensitive paths, or editor/runtime boundaries.
- [ ] Update docs for any changed decisions.
- [ ] Confirm generated data and resources remain explicit and inspectable.
- [ ] Confirm editor-only state did not leak into runtime-only code.
- [ ] Confirm no obsolete Godot 3 APIs were introduced into active Godot 4.6+ code.

## Historical or Closed Tasks

- [x] Create focused `spec.md`, `tasks.md`, `validation.md`, and `review.md` from research Option A and the 2026-05-21 design review.
  - Completed: 2026-05-21.
