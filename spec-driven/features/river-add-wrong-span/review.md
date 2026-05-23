# Review: River Add Wrong Span

## Review Date

2026-05-22

## Scope Reviewed

- Documentation created in this pass:
  - `spec.md`
  - `plan.md`
  - `tasks.md`
  - `validation.md`
  - `review.md`
- Existing research reviewed:
  - `research.md`
  - `findings.md`
  - `session-handoff.md`
- Active code previously validated by static review:
  - `addons/waterways/plugin.gd`
  - `addons/waterways/river_manager.gd`
  - `addons/waterways/river_gizmo.gd`
  - `addons/waterways/water_helper_methods.gd`
  - `addons/waterways/water_system_manager.gd`

## Current Truth

- Overall review status: Partial, shape-preserving implementation completed; visible editor re-validation pending.
- Blocking issues remaining:
  - Visible Godot editor reproduction and validation remain unrun.
- Important issues remaining:
  - Preserve Remove and append workflows during any helper extraction.
  - Confirm undo/redo restores bake-valid state as expected in the editor.
  - Confirm the reported intermittent twist is gone on the user's tight/self-near editor fixtures.
- Last validation relied on:
  - 2026-05-22 Godot console plugin-load check and curve-hit helper smoke check.
  - 2026-05-22 user visible-editor report that the span-only fix still failed intermittently, followed by shape-preserving split probes.
- Next action:
  - Run or request visible editor validation.
- Historical detail starts at:
  - Not applicable yet.

## Findings

### Blocking

- No interactive editor validation has been recorded. Automated checks confirm the implementation shape, not user-visible behavior.

### Important

- The previous Add path could mix `baked_closest_point` from the visible baked curve with `closest_segment` from an independently chosen control chord.
- The new Add path uses one structured helper result containing `hit`, local `position`, owning control `span`, approximate `t`, and ray-to-curve `distance`.
- User-visible feedback showed the span-only fix could still create bad/twisted new segments intermittently, so on-curve Add now calls a shape-preserving Bezier split helper.
- `RiverManager.add_point()` is public-style API and should remain compatible.
- `RiverManager.split_curve_span_at()` is additive and preserves the old sampled span shape while inserting an interpolated width.
- Remove mode still shares the hit-test helper only as a visible-curve gate and then removes the nearest authored point to the visible hit position.
- Append mode is separate from the wrong-span failure and still uses the no-hit path with existing constraint logic.
- Existing River and WaterSystem stale mechanisms are already sufficient and should be reused.

### Minor

- Existing scenes with too few stored widths can still trigger the existing sanitizer warning once when repaired; edit APIs now pad before mutation so the mismatch is not carried forward.
- `generate_river_width_values()` has a separate proximity-based ambiguity on self-near curves; it should not block this feature.

## Premise Review

- Was the original premise correct, partially correct, or wrong?
  - Correct as a code-path risk. Interactive reproduction remains pending.
- Did any evidence suggest the user or agent was overlooking scene/data/context?
  - Yes. Simple straight or mildly curved Rivers can look correct because the two independent pick sources often agree.
- If yes, was that raised with the user early enough?
  - Yes. `research.md`, `spec.md`, `plan.md`, and `validation.md` all call out the need for a tight/self-near visible check.
- Was the final outcome a code/design fix, docs/validation clarification, or expected-behavior explanation?
  - Code/design fix plus docs and validation updates. Human-visible editor validation remains pending.

## Spec Compliance

| Acceptance Criterion | Status | Notes |
| --- | --- | --- |
| Add uses one consistent source for position and span. | Pass static/probe | `plugin.gd` now routes Add through one curve-hit result; helper smoke check passed. |
| On-curve Add preserves Bezier span shape. | Pass probe | `split_curve_span_at()` keeps midpoint/quarter samples aligned in console smoke check. |
| Add on straight span works. | Unrun | Needs visible editor check after implementation. |
| Add on tight/self-near span works. | Unrun | Highest-risk validation case. |
| Append behavior preserved. | Partial static | Append branch remains the no-hit path with existing constraint code; must check every constraint mode in editor. |
| Remove behavior preserved. | Partial static | Remove still gates on visible hit and deletes nearest authored control point; visible editor check pending. |
| Undo/redo restores curve and bake-valid state. | Partial static | Add/Remove now restore with `restore_curve_state_with_generated_bake_valid_state()`; editor undo/redo check pending. |
| River stale warning appears after edit. | Unrun | Existing code path validated statically. |
| WaterSystem stale warning appears after child River edit. | Unrun | Existing code path validated statically. |
| `RiverManager.add_point()` compatibility preserved. | Pass probe | Append and indexed insert smoke check passed after adding width-count hardening. |

## Architecture Compliance

- Godot 4.6+ API target preserved: Partial; Godot 4.6.3 console loaded the plugin and ran the helper probe.
- Editor/runtime boundary preserved: Yes; editor picking remains in `plugin.gd`, and `river_manager.gd` only gains additive runtime-safe curve mutation.
- Bake data and generated resources explicit: Not applicable; no data model change planned.
- Existing Waterways behavior preserved or intentionally changed: Partial; append/Remove shape is preserved statically, visible checks pending.
- Extension points preserved: Yes; no public River API was changed.
- Godot-native features preferred where practical: Yes; helper uses `Curve3D.sample()` and `Geometry3D.get_closest_points_between_segments()`.
- Bespoke systems justified: Planned only for a narrow editor hit helper.
- Comments explain non-obvious intent without restating obvious code: Yes.
- Feature and architecture docs updated for behavior, data flow, and boundary changes: Yes.

## Validation Results

- Automated:
  - Static local review validated the research findings on 2026-05-22.
  - Godot 4.6.3 console loaded `plugin.gd` successfully with `APPDATA` and `LOCALAPPDATA` redirected to `.codex-research`.
  - Godot 4.6.3 console ran `.codex-research/check_river_curve_hit.gd`; helper returned expected span 0, span 1, bowed visible span, and miss results.
  - Godot 4.6.3 console ran `.codex-research/check_split_curve_span.gd`; split helper preserved curve samples and width count.
  - Godot 4.6.3 console ran `.codex-research/check_add_point_compat.gd`; append and indexed `add_point()` behavior remained compatible.
  - Static scan found no remaining `baked_closest_point`, `closest_segment`, or plugin `get_baked_points()` Add pairing in `plugin.gd`.
- Human-assisted:
  - None yet.
- Shader:
  - Not applicable.
- Editor:
  - Pending.
- Visual:
  - Pending.
- Bake output:
  - Pending stale-warning checks only; no texture-format checks are planned.
- Runtime:
  - Pending only if `river_manager.gd` API behavior is touched.
- Performance:
  - Pending.
- Manual:
  - Template-based docs have been created and aligned with current research.

## Documentation Consistency Check

- [x] `research.md` exists and has validated findings.
- [x] `spec.md` captures goals, non-goals, acceptance criteria, and resolved decisions.
- [x] `plan.md` reflects the recommended first implementation architecture.
- [x] `tasks.md` lists implementation and validation work in reviewable slices.
- [x] `validation.md` distinguishes static research validation from pending visible editor validation.
- [x] Latest handoff still points to the research/finding context; update it after implementation if needed.
- [x] Closed tasks are checked off in `tasks.md` after implementation.
- [x] No stale "not started" language remains after code changes.
- [x] Resolved implementation questions are moved to `plan.md` and this review.

## Follow-Up Tasks

- [ ] Run or request visible editor repro/validation.
- [x] Implement consistent Add-mode hit result in `plugin.gd`.
- [x] Implement shape-preserving Bezier split for on-curve Add.
- [ ] Validate straight, tight, and self-near Add insertion.
- [ ] Validate append constraints.
- [ ] Validate Remove, undo/redo, River stale warning, and WaterSystem stale warning.
- [x] Decide and record Museum showcase outcome.

## Museum Decision

No dedicated Waterways Zoo and Museum exhibit is needed for this feature. The change is a narrow editor-authoring bug fix for Add/Remove picking and does not introduce a new user-facing water feature, shader mode, bake output, scene pattern, or visual showcase requirement.

## Decision Updates

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-05-22 | Create full spec-driven document set before implementation. | User requested the documents based on the feature-folder templates. |
| 2026-05-22 | Keep the initial review status partial/pre-implementation. | At that point research was validated, but no code fix or visible editor validation existed yet. |
| 2026-05-22 | Use direct per-control-span sampling for editor picking. | It keeps Add insertion position and span in one result and avoids post-hoc baked-point ownership inference. |
| 2026-05-22 | Revise the Add implementation to split the clicked Bezier span. | User-visible feedback showed the span-only fix could still add bad/twisted new segments intermittently. |
| 2026-05-22 | Skip a dedicated Museum exhibit. | This is a narrow editor-authoring bug fix rather than a new visual feature or showcase scene. |
