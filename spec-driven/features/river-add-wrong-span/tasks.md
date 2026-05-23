# Tasks: River Add Wrong Span

Complete tasks in order unless the plan is revised.
Each task should be independently reviewable.

## Current Truth

- Current status: Shape-preserving on-curve Add implementation completed; visible editor re-validation remains pending.
- Current implementation slice: consistent Add-mode on-curve picking in `addons/waterways/plugin.gd`.
- Remaining open work: visible editor validation plus cleanup/completion checks.
- Last passing validation: 2026-05-22 Godot console plugin-load, curve-hit helper, Bezier split, and `add_point()` compatibility smoke checks.
- Next recommended action: run or request the visible Godot editor validation matrix.
- Known deferred work: dedicated automated editor interaction tests and any separate self-near width interpolation redesign.

## Open Work

- [x] Reproduce or attempt to falsify the wrong-span behavior in the visible Godot editor.
  - User reported the first span-only implementation could still add bad/twisted new segments intermittently.
- [x] Implement consistent Add-mode on-curve hit selection in `addons/waterways/plugin.gd`.
- [ ] Validate Add, append, Remove, undo/redo, River stale warnings, and WaterSystem stale warnings.
- [x] Record implementation results in `validation.md` and `review.md`.

## Setup

- [x] Confirm the current workspace state.
  - Active workspace is `C:\Users\pc\Documents\GitHub\Godot 4 Waterways`.
  - The feature folder is currently untracked in git; do not treat that as a reason to delete it.
- [x] Read `research.md`, `findings.md`, and `session-handoff.md`.
- [x] Create `spec.md`, `plan.md`, `tasks.md`, `validation.md`, and `review.md` from the feature-folder template structure.
- [x] Read `spec.md`, `plan.md`, and `validation.md` before implementation.
- [x] Check `audit/code-audit.md` for relevant known risks if that file exists in the workspace.
  - File does not exist in this workspace.
- [x] Use the known local Godot 4.6.3 executables when running local probes:
  - Console/script runner: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
  - GUI editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`
- [x] Confirm whether the task affects active code in `addons/waterways`, project scenes/assets, docs, or spec-driven feature files.
  - Affects `addons/waterways/plugin.gd` and the `spec-driven/features/river-add-wrong-span` docs.
- [x] Run the context challenge check:
  - If a visible repro cannot be produced on tight/self-near curves, re-check whether the current code path is being mitigated by Godot baked point order, editor tolerance, or fixture setup before patching more broadly.
  - User feedback produced the opposite result: the span-only fix still failed intermittently, so the implementation was revised to preserve/split the Bezier span.

## Implementation

- [x] Task 1: Define the Add/Remove hit-result shape in `plugin.gd`.
  - Include local closest point, hit distance, and insertion span for Add.
  - Keep any optional baked index or approximate parameter editor-only.
  - Validate: static review shows Add no longer needs independent control chord and baked point decisions.

- [x] Task 2: Replace the current Add on-curve selection with a single consistent hit result.
  - Use the hit result position and span together.
  - Preserve `add_point()` compatibility while routing accepted curve hits through `split_curve_span_at(span, t)`.
  - Validate: straight and curved Add insert into the clicked visible span.

- [x] Task 3: Preserve the no-hit append path.
  - Keep append triggered only when no visible curve hit is accepted.
  - Preserve no constraint, collider snapping, axis constraints, and plane constraints.
  - Validate: append works in all constraint modes.

- [x] Task 4: Preserve Remove mode behavior after any helper extraction.
  - Keep visible-curve hit gate.
  - Keep nearest-authored-control-point removal from the visible hit position.
  - Validate: Remove deletes the same point a user would expect on straight and curved Rivers.

- [x] Task 5: Review Add/Remove undo and redo state restoration.
  - Compare existing Add/Remove actions with handle-edit `restore_curve_state_with_generated_bake_valid_state()`.
  - Update only if needed by the implementation.
  - Validate: undo/redo restores curve shape, widths, material valid flag, and warnings.

- [x] Task 6: Keep `RiverManager.add_point()` compatible.
  - Do not change its existing index semantics unless the spec and plan are revised.
  - If a new RiverManager helper is needed, make it additive.
  - Validate: simple script-level append/insert behavior remains unchanged.

- [x] Task 6a: Add shape-preserving Bezier span splitting for on-curve Add.
  - Additive `RiverManager.split_curve_span_at(span, t)` splits with de Casteljau subdivision.
  - Editor Add uses this only for accepted curve hits; append remains on `add_point(..., -1)`.
  - Validate: console probe preserves first-quarter, midpoint, and three-quarter samples and keeps widths aligned.

- [x] Task 7: Consider a minimal automated mapping check.
  - If helper logic can be isolated from editor input, add a small script-level or static probe.
  - Do not rely on it as proof of visible editor behavior.
  - Validate: probe covers at least a simple curve and a self-near/tight fixture.

- [x] Task 8: Update documentation after implementation.
  - Update `plan.md` if architecture changes.
  - Update `validation.md` with exact checks and results.
  - Update `review.md` with findings and remaining risks.
  - Validate: no stale "not started" language remains for completed work.

## Validation

- [x] Run automated checks listed in `validation.md`.
- [x] Record the exact Godot executable path used for each local Godot check.
- [ ] Revisit the context challenge check after validation.
- [ ] For Godot editor, viewport, gizmo, bake, or runtime checks, ask the user in chat to run the exact check and relay output, screenshots, version/renderer, and visible behavior if the agent cannot reliably interact with the editor.
- [ ] Do not rely on `validation.md` alone for human-assisted checks; paste the requested steps into the user-facing message.
- [ ] Check straight River Add.
- [ ] Check curved/tight River Add.
- [ ] Check self-near/looping River Add.
- [ ] Check append beyond the River end with no constraint.
- [ ] Check append with collider snapping.
- [ ] Check append with axis constraints.
- [ ] Check append with plane constraints.
- [ ] Check Remove mode after any picking refactor.
- [ ] Check undo/redo for Add and Remove.
- [ ] Check River stale warnings after edit.
- [ ] Check WaterSystem stale warnings after child River edit.
- [x] Record results in `review.md`.

## Cleanup

- [x] Remove temporary debug code that is not part of the planned validation UI.
- [x] List scratch/generated artifacts created during validation and decide whether to keep, exclude, or delete them.
- [x] If validation used a scratch project, confirm active add-on scripts were mirrored there before running probes.
  - No scratch project was used; probes loaded active workspace scripts directly.
- [x] Confirm disposable folders, generated bakes, editor caches, validation fixtures, and local probe outputs are ignored, deleted, or intentionally kept.
- [x] Add or refine comments only for non-obvious picking/span mapping logic.
- [x] Update docs for any changed decisions.
- [x] Confirm editor-only state did not leak into runtime-safe code.
- [x] Confirm active code uses current Godot 4.6+ APIs.

## Feature Completion Gate

Complete this final requirement before marking the feature complete. See `../../02-waterways-zoo-and-museum.md` for the full Waterways Zoo and Museum guidance.

- [x] Museum showcase decision: no dedicated Museum exhibit is needed because this is a narrow editor-authoring bug fix; recorded in `review.md`.

## Historical or Closed Tasks

- [x] Static research validation completed on 2026-05-22.
  - Validated the Add-mode two-source mismatch.
  - Validated append path separation and regression risk.
  - Validated Remove mode coupling.
  - Validated existing River and WaterSystem stale paths.
