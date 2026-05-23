# Plan: River Add Wrong Span

## Spec Link

`spec.md`

## Architecture Summary

Fix the River Add wrong-span bug in the editor authoring layer by replacing the two-source Add insertion decision with one curve-hit result. The hit result should carry the local closest point on the visible curve and the owning control-point span used for insertion.

The implementation keeps `RiverManager.add_point()` compatible, keeps the existing append path intact, and uses an additive shape-preserving Bezier split helper for on-curve Add.

The editor picker should not map a raw `get_baked_points()` hit back to a control span after the fact. Instead, it samples each `Curve3D` control span directly, tests the mouse ray against those sampled subsegments, and returns the owning span together with the closest point and approximate span parameter from the same search. This keeps parameter order attached to the hit result and avoids recreating the current two-source mismatch under a different name.

## Current Truth

- Implementation status: Shape-preserving on-curve Add implementation completed after visible editor feedback showed the span-only fix could still twist tight spans.
- Open architectural decisions:
  - Exact sampling density and tolerance for direct per-`Curve3D`-span editor hit testing.
  - Whether any remaining visible failures are caused by picking tolerance, existing damaged test curves, or a separate mesh/width interpolation issue.
- Last validation that proves the plan still works:
  - 2026-05-22 Godot console probe loaded `plugin.gd` and verified the new curve-hit helper returns span 0, span 1, a bowed visible span, and miss results on small fixtures.
  - 2026-05-22 Godot console probe verified `split_curve_span_at()` preserves sampled Bezier shape across a split and keeps widths aligned with curve point count.
  - 2026-05-22 Godot console probe verified `add_point()` append and indexed insert compatibility after width-count hardening.
  - 2026-05-22 static scan confirmed the old Add-mode `baked_closest_point` plus independent `closest_segment` pairing is removed from `plugin.gd`.
- Next planned implementation slice:
  - Re-run visible Godot editor validation for Add, append constraints, Remove, undo/redo, River stale warnings, and WaterSystem stale warnings.
- Sections below that are historical or superseded:
  - None.

## Premise Check

Before implementing, confirm this is not just expected behavior from a simple curve, stale generated mesh, or old bake resource.

- Evidence supporting the premise:
  - `plugin.gd` computes `closest_segment` from straight authored control-point chords.
  - `plugin.gd` separately computes `baked_closest_point` from visible baked curve samples.
  - Add mode passes both independently chosen values into `RiverManager.add_point()`.
  - `add_point()` inserts at `index + 1` and guesses handles from neighboring control-point positions.
- Evidence against the premise:
  - No interactive editor reproduction has been recorded yet.
  - Simple straight and mildly curved rivers may already behave correctly.
- User-facing pushback or clarification needed before patching:
  - The fix intentionally changes tight/self-near Add behavior while keeping normal straight-river behavior effectively the same.
- Smallest check that can falsify the premise:
  - In a tight or self-near River, click a visible span where the nearest control chord belongs to another span; if the current implementation still inserts into the clicked visible span, the code-path risk may not reproduce as expected.
  - Do not treat a visible repro as a hard implementation blocker if the local code path still clearly pairs independently chosen position and span values; treat it as validation evidence rather than the only justification for the fix.

## Layers

Editor authoring layer:

- Add a helper that evaluates the visible curve hit once and returns a structured hit result.
- Prefer direct per-control-span sampling with `curve.sample(span, t)` over post-hoc ownership inference from `curve.get_baked_points()`.
- Keep `hit`, `position`, `span`, approximate `t`, and `distance` together so Add and Remove cannot accidentally mix unrelated decisions.
- Keep Remove mode using a visible-curve click gate and nearest authored control point.
- Keep append constraint handling separate from on-curve insertion.

Bake/data layer:

- Reuse existing `_invalidate_generated_bake()` paths triggered by curve edits.
- Do not change `RiverBakeData`, `WaterSystemBakeData`, channel layout, or bake resource storage.

Runtime layer:

- Preserve `RiverManager.add_point()` and existing curve mutation APIs.
- Avoid editor-only state in runtime-safe River code.

Validation layer:

- Add or run focused checks for straight, curved, tight, and self-near authoring.
- Use human-assisted editor validation for visible Add/Remove behavior.
- Use light script/static checks where practical for helper behavior and API compatibility.

## Godot Components

- Nodes:
  - `River`
  - `WaterSystem` only for stale warning validation
- Resources:
  - `Curve3D`
  - existing River and WaterSystem bake resources
- Shaders:
  - None planned
- Editor tools:
  - `EditorPlugin._forward_3d_gui_input()`
  - River toolbar Add/Remove modes
  - River gizmo constraint helpers
- Importers:
  - None
- Autoloads:
  - None
- Scenes:
  - Existing validation scenes may be reused.
  - A dedicated River authoring fixture can be added only if needed.
- Validation scenes:
  - No dedicated scene exists yet for this exact wrong-span case.

## Data Model

No serialized data model changes are planned.

Existing mutable data:

- `River.curve`: authored `Curve3D` with point positions and handles.
- `River.widths`: per-control-point widths.
- `River.valid_flowmap`: generated map validity flag.
- River generated mesh: regenerated after curve edits.
- River bake source signature: includes point positions, handles, widths, bake interval, shape settings, bake settings, step count, and UV2 side count.
- WaterSystem source metadata: stores child River signatures, bake resource paths, texture sizes, UV2 side count, valid state, bake settings, and metadata.

Planned editor-only hit result:

- `hit`: bool
- `position`: local `Vector3`
- `span`: int, compatible with `add_point(position, span)`
- `t`: approximate 0..1 parameter within the owning control span, when available
- `distance`: editor ray-to-curve distance used for tolerance checks
- Optional: sampled subsegment index for diagnostics or later Bezier splitting

Avoid using `span == -1` as the only cross-branch state flag. Add mode should append when `hit == false`; Remove mode should use `hit == true` as the visible-curve gate and then continue removing the nearest authored control point to `position`.

## Editor/Runtime Boundary

- Editor-only code:
  - Mouse-ray hit testing.
  - Add/Remove mode branching.
  - Append constraint handling.
  - Undo/redo action assembly.
- Runtime-safe code:
  - `RiverManager.add_point()`
  - `RiverManager.insert_point_with_handles()`
  - curve state capture/restore
  - generated bake invalidation
- Shared data/resources:
  - `Curve3D`, widths, generated mesh, bake data resources
- APIs exposed to user projects:
  - Keep `add_point()` behavior compatible.
  - Optional new helper must be additive if added to `RiverManager`.
- Assumptions that must not cross the boundary:
  - Runtime code must not depend on mouse position, camera rays, editor toolbar state, or gizmo handles.

## Runtime Flow

1. Runtime loads saved River nodes, curves, generated meshes, and bake resources as before.
2. Runtime shaders and sampling use existing generated textures and data.
3. No runtime behavior changes unless a River has been edited and regenerated.

## Bake Flow

1. Add or Remove edits the authored curve.
2. On-curve Add splits the clicked Bezier control span at the picked approximate `t`, preserving the old span shape and interpolating width.
3. River edit methods invalidate `valid_flowmap`, regenerate the River mesh, and emit change signals as they do today.
4. Existing River and WaterSystem stale warnings report that generated maps need rebuilding.
5. User runs existing River/WaterSystem bake actions when needed.

No new bake passes, texture channels, or metadata fields are planned.

## Lifecycle, Cleanup, and Re-entry

- Success path:
  - Add on curve inserts into the intended span by splitting the existing Bezier span.
  - Add away from curve appends from the final point.
  - Remove deletes the nearest authored control point to the visible hit.
  - Undo/redo restores curve state and valid-flowmap state.
  - The first span-only fix could still produce a Bezier kink. Current implementation now preserves the split span shape, but visible validation is still required.
- Preflight or early-return path:
  - If no edited River exists, pass input through unchanged.
  - If append constraint math returns no point, do nothing as current code does.
  - If the curve has too few baked points or control points, fall back to safe pass/append behavior.
- Awaited failure path:
  - No async renderer or bake operation is introduced.
- Temporary node/resource ownership:
  - No temporary scene nodes or resources are planned.
- Progress, dirty-state, and user feedback:
  - Existing `properties_changed()` and `update_configuration_warnings()` calls should remain.
- Duplicate or overlapping requests:
  - Editor input remains per mouse release event.
- Scene reload or runtime boundary:
  - Saved scenes should contain only normal `Curve3D`, widths, generated mesh, and bake resource state.

## Files to Change

- `addons/waterways/plugin.gd`: add the consistent curve-hit helper and route Add/Remove behavior through it carefully.
- `addons/waterways/river_manager.gd`: add additive `split_curve_span_at()` helper and harden edit APIs against short width arrays before mutation.
- `spec-driven/features/river-add-wrong-span/validation.md`: record validation runs.
- `spec-driven/features/river-add-wrong-span/review.md`: record implementation review.
- Optional validation scene or script: only if manual editor validation is not enough for regression coverage.

## Documentation Plan

- Code comments needed:
  - A short comment near the hit helper explaining that Add insertion position and span must come from the same visible-curve hit.
- Feature docs to update:
  - `tasks.md`, `validation.md`, and `review.md` after implementation and checks.
- Architecture or data-flow docs to update:
  - None expected unless adding a new RiverManager helper.
- Validation docs to update:
  - Record straight, curved, tight, self-near, append, constraint, Remove, undo/redo, and stale warning checks.
- Migration notes to update:
  - None expected.

## Validation Strategy

- Automated:
  - Static scan for the old `baked_closest_point` plus independent `closest_segment` Add call pattern.
  - Optional script-level helper test if the direct span-sampling hit helper can be isolated without live editor input.
  - If feasible, cover at least one case where nearest control chord and nearest visible sampled span would disagree.
- Validation matrix location:
  - `validation.md`.
- Human-assisted:
  - Required for visible editor Add/Remove behavior.
- Visual:
  - Inspect inserted control point order and mesh shape after Add on straight, curved, tight, and self-near Rivers.
- Shader:
  - None.
- Editor:
  - Add, append, constraints, Remove, undo, redo, warning refresh.
- Runtime:
  - Existing `add_point()` script compatibility if touched.
- Performance:
  - Confirm editor picking remains responsive on a moderately long River.
- Manual:
  - User or agent with visible Godot editor records behavior and screenshots if useful.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Hit ownership is inferred incorrectly on self-near curves. | The fix may still choose the wrong span. | Prefer direct per-control-span sampling with `curve.sample(span, t)` so the hit result owns both position and span; validate self-near cases visibly. |
| Remove mode changes accidentally. | Existing delete workflow feels wrong. | Preserve Remove as visible-curve gate plus nearest authored point; test after refactor. |
| Append path regresses. | Users cannot extend rivers with current constraints. | Keep the no-hit append flow and constraint helpers intact; test every constraint mode. |
| Undo/redo restores stale valid state incorrectly. | Generated map warnings become confusing. | Prefer aligning Add/Remove undo with `restore_curve_state_with_generated_bake_valid_state()`, matching handle-edit behavior. |
| Broad `add_point()` change breaks scripts. | External callers get different behavior. | Keep `add_point()` compatible; use editor-side helper or additive API. |
| Shape still kinks even with correct span. | User sees a smaller but real authoring quality issue. | Use the additive Bezier split helper for on-curve Add and validate the user's tight/self-near fixtures. |

## Implementation Notes

- The hit helper should iterate River control spans and sample each span with enough subdivisions to approximate the visible curve at editor-picking tolerance.
- Each sampled subsegment should be tested against the mouse ray with `Geometry3D.get_closest_points_between_segments()`.
- The winning result should store the local closest point, owning control span, approximate `t`, and distance as one object.
- Add mode should call `split_curve_span_at(hit.span, hit.t)` when the hit result is accepted.
- Append mode should run only when no visible curve hit is accepted, preserving collider snapping, no constraint, axis constraints, and plane constraints.
- Remove mode should use the same hit helper only as a visible-curve gate, then keep deleting the nearest authored point to `hit.position`.
- `split_curve_span_at()` uses de Casteljau subdivision for the target span, updates neighboring handles, and inserts an interpolated width.
- `add_point()` remains the compatibility API for append and external script callers.
- Add/Remove undo now captures both `get_curve_state()` and `get_generated_bake_valid_state()` and restores through `restore_curve_state_with_generated_bake_valid_state()`, matching the handle-edit restore pattern.

## Migration and Compatibility

Existing saved scenes do not need migration. The behavior change applies only to future editor Add actions. Public-style `RiverManager.add_point()` callers should keep their current append and insert semantics. Generated River and WaterSystem bake resources remain compatible but become stale through existing warning paths after curve edits.
