# Spec: River Add Wrong Span

## Summary

The River Add editor tool must insert a new control point into the same visible curve span the user clicked. The current code can choose the insertion position from the baked visible curve while choosing the insertion index from a different straight control-polygon segment, which can kink the authored Bezier curve and make the generated river mesh twist or invert.

This feature fixes the editor authoring behavior first. It does not redesign mesh generation, bake metadata, or the public-style River insertion API.

## Current Truth

- Status: Draft, ready for implementation planning.
- Source of truth for open work: `tasks.md`.
- Last meaningful decision: fix Add-mode on-curve picking first by deriving position and span from one consistent curve-hit result.
- Known deferred items: dedicated automated editor interaction tests and any separate self-near width interpolation fix.
- Current non-goals that are easy to accidentally reopen:
  - Do not patch river mesh generation to hide a bad authored curve.
  - Do not broadly change `RiverManager.add_point()` semantics for external script callers.
  - Do not change Remove mode to delete by baked segment owner.
  - Do not redesign River or WaterSystem bake metadata.

## Goals

- Add mode inserts into the clicked visible River span on straight, curved, tight, and self-near rivers.
- Add mode continues appending beyond the end when the click is not near the visible curve.
- Append constraints keep working: none, collider snapping, axis constraints, and plane constraints.
- Remove mode keeps its current visible-curve click gate and nearest-authored-point removal behavior.
- Undo/redo restores curve shape and bake-valid state correctly.
- River and WaterSystem stale warnings continue to use existing invalidation and metadata paths.
- Existing saved scenes and script callers remain compatible until a user edits a River.

## Non-Goals

- Do not change generated texture formats, shader channel contracts, UV2 atlas layout, or WaterSystem composition.
- Do not add a new runtime River sampling API.
- Do not migrate existing saved scenes.
- Do not treat local static review as proof of visible editor behavior.

## Context and Assumptions

- Known scene/data/context facts:
  - Active workspace: `C:\Users\pc\Documents\GitHub\Godot 4 Waterways`.
  - Relevant code paths are `addons/waterways/plugin.gd`, `addons/waterways/river_manager.gd`, `addons/waterways/river_gizmo.gd`, `addons/waterways/water_helper_methods.gd`, and `addons/waterways/water_system_manager.gd`.
  - Add mode previously computed `closest_segment` from straight control-point chords and `baked_closest_point` from baked curve samples before calling `add_point()`.
  - `RiverManager.add_point()` inserts at `index + 1` and guesses handles from neighboring control-point positions.
  - Curve edits already invalidate River bake state and are included in River and WaterSystem source signatures.
- User-reported observations:
  - Adding a River point near a curved or self-near river may insert into the wrong span and twist/invert the generated river mesh.
- Agent confidence in the premise:
  - High for the code-path risk.
  - Medium for interactive reproduction until a visible Godot editor check is run.
- Possible expected-behavior explanations to rule out before patching:
  - Straight and mild curves can appear correct because the nearest control chord and nearest baked span usually agree.
  - Existing generated bakes may be stale after any curve edit.
- Clarification or challenge already raised with the user:
  - This is research-backed but not yet interactively reproduced in the editor.

## Users and Workflows

### User Story: Add A Point On A Visible River Curve

As a River author, I want a click on the visible river curve to insert a point into that visible span, so that adding detail to a bend does not reorder or distort the authored curve.

Acceptance criteria:

- Clicking a straight span inserts between the two expected neighboring control points.
- Clicking a tight bend inserts into the visible span being clicked.
- Clicking a self-near or looping river section does not insert into a nearby but different control-polygon span.
- The inserted point appears at the clicked visible curve position within the current editor picking tolerance.

### User Story: Append Beyond The River End

As a River author, I want clicks away from the visible curve to keep appending from the final point, so that existing Add-mode creation workflows and constraints remain intact.

Acceptance criteria:

- Append still works when no curve hit is found.
- Collider snapping, no constraint, axis constraints, and plane constraints still affect appended points.
- The append path still uses `add_point(..., -1)` or an equivalent compatible path.

### User Story: Remove A Point

As a River author, I want Remove mode to keep removing the authored control point nearest to the clicked visible curve location, so that a picking refactor does not change the established Remove workflow.

Acceptance criteria:

- Remove still requires a click near the visible baked curve.
- Remove still chooses the nearest authored control point to the visible hit position.
- Remove does not delete by baked segment owner unless a future spec explicitly changes that behavior.

### User Story: Maintain Existing River APIs

As an add-on maintainer or script user, I want `RiverManager.add_point()` to remain compatible, so that existing scripts using the River API do not change behavior unexpectedly.

Acceptance criteria:

- Existing `add_point(position, -1)` append callers behave as before.
- Existing `add_point(position, index)` insert callers behave as before.
- Any new precise insertion helper is additive and documented by use in editor code.

## Functional Requirements

- FR-1: Add mode must derive on-curve insertion position and insertion span from one consistent hit result.
- FR-2: Add mode must not pair a baked-curve hit position with an independently chosen control-polygon chord index.
- FR-3: The on-curve hit result must include at least a local closest point and a segment index compatible with the insertion call.
- FR-4: If no visible curve hit is within the accepted tolerance, Add mode must preserve append behavior.
- FR-5: Append mode must preserve no-constraint, collider snapping, axis, and plane constraint behavior.
- FR-6: Remove mode must preserve its visible-curve hit gate and nearest-authored-control-point removal behavior.
- FR-7: Undo and redo for Add and Remove must restore curve positions, handles, widths, material valid flags, and configuration warnings.
- FR-8: Curve edits must continue to invalidate River generated data and refresh generated river geometry.
- FR-9: WaterSystem stale warnings must continue to detect child River geometry, bake-state, and metadata changes through existing source metadata comparison.
- FR-10: Existing `RiverManager.add_point()` behavior must remain compatible for script callers.
- FR-11: Any optional new insertion helper must not require editor-only state at runtime.
- FR-12: The first implementation must not change generated texture channel layout, shader behavior, or WaterSystem bake formats.

## Non-Functional Requirements

- Maintainability:
  - Keep the fix localized to editor picking and a narrow insertion call path.
  - Prefer a small helper over duplicating hit-test loops in Add and Remove branches.
  - Keep any broader mesh/bake changes separate unless explicitly accepted.
- Performance:
  - Keep picking linear in baked point or sampled span count, matching the current editor-time cost profile.
  - Do not add physics queries to on-curve insertion.
- Visual quality:
  - Straight and simple River authoring should feel unchanged.
  - Tight/self-near curves should insert into the clicked visible span without sudden wrong-span twists.
- Godot 4.6+ compatibility:
  - Use active Godot 4.6+ APIs already present in the add-on.
  - Validate with the known local Godot 4.6.3 executables where possible.
- Editor usability:
  - Add/Remove toolbar behavior remains predictable.
  - Constraint controls continue affecting append behavior only.
- Runtime usability:
  - Existing runtime scenes should not change until a River is edited.
  - Runtime should not depend on editor-only picking state.
- Extensibility:
  - Keep the shape-preserving split helper additive so public `add_point()` callers retain existing semantics.

## Add-on Boundary

Editor authoring responsibilities:

- River toolbar Add and Remove input handling.
- Mouse-ray proximity checks against the visible curve.
- Append constraint handling.
- Undo/redo action assembly.

Bake/data responsibilities:

- Existing River mesh regeneration after curve edits.
- Existing River bake valid-state invalidation.
- Existing River and WaterSystem source metadata and stale warnings.

Runtime responsibilities:

- Consume the authored curve, generated mesh, and saved bake resources.
- Preserve current script-visible River insertion APIs.

Shared code must not depend on:

- Editor-only mouse events, toolbar mode state, or gizmo state.
- A single validation scene.
- Stale generated bake resources as a correctness signal.

## Data and Extension Model

Users should be able to:

- Keep authoring Rivers with the existing editor tools.
- Keep calling `RiverManager.add_point()` from scripts with existing semantics.
- Optionally benefit from a future precise insertion helper without migrating saved scenes.

Extension points:

- `RiverManager.add_point()` remains the compatibility API.
- `RiverManager.insert_point_with_handles()` remains available for explicit direct-index insertion.
- `RiverManager.split_curve_span_at()` splits a known Bezier span with preserved handles and interpolated width for editor Add.

Override rules:

- Editor Add mode owns picking decisions.
- RiverManager owns mutation, width updates, geometry regeneration, and bake invalidation.
- WaterSystem stale detection remains downstream and metadata-based.

Shared systems must not hard-code:

- One River shape, validation fixture, material preset, or generated bake resource.

## Acceptance Tests

- Add on a straight span inserts between the expected two authored points.
- Add on a tight bend inserts into the clicked visible span.
- Add on a self-near/looping River does not insert into a nearby wrong control-polygon span.
- Add away from the curve appends beyond the final point.
- Append with no constraint, collider snapping, axis constraints, and plane constraints behaves as before.
- Remove still deletes the nearest authored point to the visible hit.
- Undo/redo restores Add and Remove changes, including bake-valid state.
- River `valid_flowmap` becomes false after Add/Remove.
- WaterSystem stale warning appears when a child River source signature changes after editing.
- Existing script-level `add_point()` callers retain current behavior.

## Visual Validation Requirements

- A human-visible Godot editor check must cover straight, curved, tight, and self-near Rivers.
- The inserted point and rebuilt river mesh must be inspected after each Add action.
- Flow-map/debug shader changes are not required for this feature, but stale warning behavior should be observed after edits.

## Performance Requirements

- Editor Add/Remove picking should remain responsive on typical baked River curve sizes.
- On-curve insertion should not add raycasts or bake-time work.
- Any automated helper test should avoid high-resolution scene bakes unless specifically validating stale-map behavior.

## Open Questions

- Is a dedicated validation scene needed, or can an existing scene plus a temporary authored River fixture cover the editor checks?

## Resolved Questions

| Question | Resolution | Date | Notes |
| --- | --- | --- | --- |
| Should mesh generation be the first fix target? | No. Fix editor Add picking first. | 2026-05-22 | Research validated that mesh generation samples the already-authored curve. |
| Should `RiverManager.add_point()` be broadly rewritten? | No. Keep it compatible for script callers. | 2026-05-22 | It is marked as public-style API in `river_manager.gd`. |
| Does append mode share the exact wrong-span bug? | No. It is separate after hit-test failure, but must be protected from regressions. | 2026-05-22 | Research validation refined this point. |
| Are River/WaterSystem stale paths already present? | Yes. Reuse existing invalidation and metadata comparison. | 2026-05-22 | Confirmed in `river_manager.gd` and `water_system_manager.gd`. |
| What mapping strategy should Add use? | Direct per-control-span sampling with `Curve3D.sample(span, t)`. | 2026-05-22 | Keeps the hit position, owning span, approximate `t`, and distance in one result. |
| Should Add include shape-preserving Bezier splitting? | Yes, after visible feedback showed the span-only fix could still twist tight spans. | 2026-05-22 | Implemented as additive `split_curve_span_at()` in `river_manager.gd`. |
| Should Add/Remove undo align with generated bake-valid state restore? | Yes. | 2026-05-22 | Add/Remove now use `restore_curve_state_with_generated_bake_valid_state()`. |

## Decision Log

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-05-22 | Target Add-mode on-curve picking first. | The confirmed mismatch is created in editor input handling before mesh generation. |
| 2026-05-22 | Preserve Remove mode behavior. | Remove shares the hit-test setup and should not change UX as a side effect. |
| 2026-05-22 | Revise the first implementation to include Bezier split insertion. | Visible editor feedback showed correct span selection alone could still create bad/twisted new segments. |
