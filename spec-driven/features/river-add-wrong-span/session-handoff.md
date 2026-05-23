# Next Session Message

Start with `spec-driven/features/river-add-wrong-span/validation.md` and `review.md`. The shape-preserving implementation has been completed after user feedback; visible editor re-validation is now the main remaining work.

Read these files in order:

- `spec-driven/features/river-add-wrong-span/validation.md`: required manual/editor checks and result format.
- `spec-driven/features/river-add-wrong-span/review.md`: implementation review notes, remaining risks, and Museum decision.
- `spec-driven/features/river-add-wrong-span/tasks.md`: checklist for implementation and validation.
- `spec-driven/features/river-add-wrong-span/plan.md`: current implementation direction and the revised notes.
- `spec-driven/features/river-add-wrong-span/spec.md`: goals, non-goals, acceptance criteria, and boundaries.
- `spec-driven/features/river-add-wrong-span/research.md` and `findings.md`: background evidence if you need to re-check the original reasoning.

Implementation landed in `addons/waterways/plugin.gd` and `addons/waterways/river_manager.gd`.

The first code slice created a structured editor curve-hit helper for River Add/Remove picking. It samples each `Curve3D` control span directly with `curve.sample(span, t)`, tests each sampled subsegment against the mouse ray, and returns one hit result containing:

- `hit`
- local `position`
- owning control `span`
- approximate span parameter `t`
- ray-to-curve `distance`

Add mode is routed through that hit result:

- If `hit == true`, call `RiverManager.split_curve_span_at()` using the hit `span` and approximate `t`.
- If `hit == false`, preserve the existing append path exactly, including no constraint, collider snapping, axis constraints, and plane constraints.
- Keep `RiverManager.add_point()` compatible for external callers.

Remove mode behavior was preserved:

- Use the same hit helper only as the visible-curve click gate.
- Continue deleting the nearest authored control point to the visible hit position.
- Do not switch Remove to deleting by baked/sample segment owner.

Add/Remove undo now captures both `get_curve_state()` and `get_generated_bake_valid_state()` and restores through `restore_curve_state_with_generated_bake_valid_state()`, matching the handle-edit pattern in `addons/waterways/river_gizmo.gd`.

Important update: user-visible feedback showed the span-only fix could still add bad/twisted new segments intermittently. The implementation was revised to split the clicked Bezier span with de Casteljau subdivision, update neighboring handles, and insert an interpolated width.

Validation completed so far:

- Godot 4.6.3 console loaded `addons/waterways/plugin.gd` successfully.
- `.codex-research/check_river_curve_hit.gd` verified span 0, span 1, bowed visible span, and miss results.
- `.codex-research/check_split_curve_span.gd` verified the split helper preserves curve samples and keeps widths aligned.
- `.codex-research/check_add_point_compat.gd` verified append and indexed `add_point()` compatibility.
- Static scan confirmed the old `baked_closest_point` plus independent `closest_segment` Add pattern is gone.

Remaining validation should cover straight, tight, and self-near River Add behavior, append under every constraint mode, Remove mode, undo/redo, River stale warnings, and WaterSystem stale warnings. Record results in `validation.md` and implementation review notes in `review.md`.
