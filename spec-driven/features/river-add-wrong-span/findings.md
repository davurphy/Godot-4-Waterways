# River Add Tool Can Insert Points Into The Wrong Curve Span

## Summary

The River Add tool appears vulnerable to placing a new point into the wrong control-point span when the visible baked curve and the straight control-point polygon disagree. This can distort the rebuilt Bezier curve and make the generated river mesh appear twisted or inverted.

## Short Name

`river-add-wrong-span`

## Current Add-Point Flow

When the user clicks in Add mode, `addons/waterways/plugin.gd` performs two separate nearest-hit searches:

1. It finds `closest_segment` from straight line segments between River control points.
2. It finds `baked_closest_point` from the baked curved path.

The undo action then calls:

```gdscript
ur.add_do_method(_edited_node, "add_point", baked_closest_point, closest_segment)
```

This means the inserted position and inserted index can come from different interpretations of the river shape.

## Likely Failure Mode

On curved, tight, overlapping, or self-near rivers:

- The nearest straight control segment may belong to one part of the River.
- The nearest baked curve point may belong to another part of the River.
- The new point can then be inserted into the wrong span.

Once inserted, `addons/waterways/river_manager.gd` creates the new point handles from the old neighboring control points:

```gdscript
var dist := curve.get_point_position(index).distance_to(curve.get_point_position(index + 1))
var new_dir: Vector3 = (curve.get_point_position(index + 1) - curve.get_point_position(index)).normalized() * 0.25 * dist
curve.add_point(position, -new_dir, new_dir, index + 1)
```

This does not split the existing Bezier span while preserving the original shape. If the inserted point is far from that straight chord, or if it actually belongs to a different baked section, the new handles can be aimed or scaled poorly.

The generated mesh then samples the full curve and derives each row's sideways direction from nearby sampled positions in `addons/waterways/water_helper_methods.gd`. A sharply distorted or doubled-back curve can flip the tangent-derived right vector between rows, producing a visible twist or inversion.

## Evidence Locations

- `addons/waterways/plugin.gd`: Add tool computes `closest_segment` from control-point lines and `baked_closest_point` from baked curve samples before calling `add_point`.
- `addons/waterways/river_manager.gd`: `add_point()` inserts using the selected index and creates handles from neighboring control-point direction.
- `addons/waterways/water_helper_methods.gd`: `generate_river_mesh()` samples the rebuilt curve and derives mesh row orientation from local forward/backward samples.

## Working Bug Description

The River Add tool can pair a baked-curve insertion position with the wrong control-point segment index. Because the inserted point receives guessed handles based on that segment's old endpoints, the resulting curve can kink, double back, or twist, and the regenerated river mesh can visibly invert.

## Questions To Validate

- Can this be reproduced by adding points near tight bends or self-near curves?
- Does the bug disappear if the insert index is derived from the same baked segment that produced `baked_closest_point`?
- Would preserving/splitting the original Bezier span avoid the twist even when insertion occurs near a bend?

## Possible Fix Direction

Use one consistent source of truth for both the insertion position and insertion span. The lowest-risk direction is to derive the insertion span from the baked segment hit, then map that baked sample back to the owning `Curve3D` point interval before calling `add_point()`.

A stronger fix would split the existing Bezier segment at the clicked curve parameter so the curve shape is preserved, rather than inserting a point with newly guessed handles.

## Impact Analysis

The risky code is mostly isolated to River authoring, but the resulting curve state feeds several downstream systems.

### Likely Safe To Change

If the fix only changes the editor Add tool so the inserted point and insert span come from the same curve hit, existing saved scenes should not break. The main affected behavior is:

- Add-mode point insertion in `addons/waterways/plugin.gd`.
- Undo/redo around the `"Add River point"` action.
- The new curve shape after adding a point.

Straight or simple Rivers should behave the same or very close. Curved, tight, overlapping, or self-near Rivers would intentionally behave differently because the current behavior is suspected to choose the wrong span.

### Shared Logic To Watch

The Remove tool shares the same hit-test block in `addons/waterways/plugin.gd`. It uses `closest_segment` as a "clicked near the curve" guard, then removes the nearest control point to `baked_closest_point`.

If the picking code is refactored into a helper, Remove should be tested to make sure it still feels the same. A fix for Add should not accidentally make Remove more permissive, less permissive, or biased toward the wrong visible curve section.

### Riskier Change Area

Changing `addons/waterways/river_manager.gd` `add_point()` is riskier than changing the editor Add tool because `add_point()` is exposed as a public-style River API. Local project code only appears to call it from the editor Add tool, but external users or future scripts could call it directly.

A lower-risk path is to leave `add_point()` mostly compatible and have the editor use a more precise insertion path, possibly through `insert_point_with_handles()` or a new helper that preserves/splits the intended curve span.

### Downstream Effects

After insertion, River mesh generation, bakes, debug views, and WaterSystem maps all depend on the resulting curve shape. That is expected and should not be treated as a separate breakage if the authored curve changes.

The project already treats curve edits as stale-source changes:

- `addons/waterways/river_manager.gd` `get_bake_source_signature()` includes point positions, handles, widths, step count, and UV2 side count.
- `addons/waterways/water_system_manager.gd` stores and compares child River source metadata for stale WaterSystem warnings.

So changed Rivers will need rebaking, but the stale-resource path is already part of normal authoring behavior.

### Avoid As First Fix

Avoid fixing this first in `addons/waterways/water_helper_methods.gd` mesh generation. Mesh row orientation affects every River mesh, bake, shader sample, and WaterSystem render. The suspected defect appears earlier, when the Add tool pairs a position with the wrong insertion span.

The safer first fix is to correct Add tool insertion selection, then validate:

- Add near straight spans.
- Add near tight bends and self-near curves.
- Append beyond the end of the River.
- Add with collider snapping and axis/plane constraints.
- Remove points after any picking refactor.
- Undo/redo for Add and Remove.
- River bake stale warnings and regenerated River maps.
- WaterSystem stale warnings and regenerated System maps.

## Follow-Up Investigation - 2026-05-22

The code-path investigation confirms the suspected Add-mode mismatch.

### Confirmed Add-Mode Mismatch

`addons/waterways/plugin.gd` `_forward_3d_gui_input()` computes two independent picks:

- `closest_segment` is selected from straight segments between authored control points (`get_curve_points()`, then `Geometry3D.get_closest_points_between_segments()`).
- `baked_closest_point` is selected from the visible baked curve (`curve.get_baked_points()`, then another segment-distance search).

The Add action then passes both values together:

```gdscript
ur.add_do_method(_edited_node, "add_point", baked_closest_point, closest_segment)
```

Because `closest_segment` and `baked_closest_point` come from different geometric sources, a tight bend, loop, or self-near river can choose the insertion position from one visible span and the insertion index from a different control-polygon span.

### Append Behavior And Constraints

The existing append flow is separate from on-curve insertion. If no baked curve hit is found, `closest_segment` is set to `-1`, and Add mode computes a new point from the last curve point using:

- no constraint: camera-facing plane through the last point,
- collider snapping: `RiverGizmo.get_collider_snap_position()`,
- axis constraints: `RiverGizmo.AXIS_MAPPING`,
- plane constraints: `RiverGizmo.PLANE_MAPPING`.

That append path still calls `add_point(..., -1)`. A fix for the wrong-span bug should preserve this behavior and only change how on-curve insertion derives its hit span.

### Remove-Mode Coupling

Remove mode shares the same hit-test setup. It uses `closest_segment != -1` only as a "clicked close enough to the visible curve" gate, then removes the authored control point nearest to `baked_closest_point`:

```gdscript
var closest_index = _edited_node.get_closest_point_to(baked_closest_point)
```

Any helper extracted from the picking logic should preserve Remove's current UX: click near the visible river path, then remove the nearest control point. It should not accidentally switch Remove to a baked-segment owner index or make the click target more/less permissive.

### River Insertion APIs

`addons/waterways/river_manager.gd` `add_point()` has two behaviors:

- `index == -1`: append after the final point, deriving handles from the last point and new position.
- otherwise: insert at `index + 1`, deriving both new handles from the straight direction between existing control points `index` and `index + 1`.

This means the current Add tool is especially sensitive to a wrong `closest_segment`.

`insert_point_with_handles(position, index, point_in, point_out, width)` is a safer lower-level API only if the caller already knows the exact insert index and desired handles. Its `index` is a direct Curve3D insert index, not the pre-insertion segment index used by `add_point()`. It clamps the index, inserts the supplied handles and width, and invalidates the bake. It does not split the surrounding Bezier segment by itself, so a shape-preserving Add fix would still need a helper that computes split handles and updates adjacent handles.

### Downstream Evidence

`addons/waterways/water_helper_methods.gd` `generate_river_mesh()` samples the final rebuilt curve and derives each row's right vector from nearby sampled positions:

```gdscript
var backward_pos := _sample_river_position(...)
var forward_pos := _sample_river_position(...)
var right_vector := _safe_right_vector(forward_pos - backward_pos)
```

If Add mode creates a kink, loop, or doubled-back section, this row orientation can flip between samples and make the mesh look twisted or inverted. This supports the bug theory, but mesh generation is downstream of the bad authored curve and should not be the first fix target.

One related downstream ambiguity is `generate_river_width_values()`: it maps baked samples back to control spans by nearest sampled position across all curve intervals. On self-near curves, width interpolation can also become proximity-based rather than parameter-order-based. That is worth keeping in mind, but it is separate from the editor insertion-index bug.

### Bake And WaterSystem Staleness

Curve edits already invalidate generated River data. `add_point()`, `insert_point_with_handles()`, `remove_point()`, and `restore_curve_state()` all call `_invalidate_generated_bake(true, true)`, which marks `valid_flowmap` false, regenerates the mesh, and emits `river_changed`.

River source signatures include authored point positions, handles, widths, curve bake interval, shape settings, bake settings, calculated step count, and UV2 side count. WaterSystem stale warnings compare child River metadata, including current source signatures, stored River bake signatures, texture sizes/paths, UV2 side count, valid bake state, bake settings, and bake metadata. Therefore an Add-mode behavior fix should naturally surface stale River and WaterSystem map warnings after authored geometry changes.

### Recommended Fix Strategy

Recommended first fix:

1. Keep `RiverManager.add_point()` compatible for existing script/API callers.
2. In `plugin.gd`, replace the two-source Add-mode hit with a single hit result for on-curve insertion: local closest point, baked sample/offset if available, and owning control-point span.
3. Derive both insertion position and insertion span from that one hit result.
4. Preserve the existing `closest_segment == -1` append path, including collider snapping and axis/plane constraints.
5. Preserve Remove mode's current visible-curve hit gate and nearest-control-point removal behavior.
6. Use the existing undo/redo shape-state pattern, but consider restoring bake-valid state in the same style as handle edits if changing the action structure.

Stronger follow-up fix:

- Add a RiverManager helper that splits a specific Bezier span at the clicked curve parameter, updates neighboring handles, inserts the new point through explicit handles, and interpolates width by the same parameter. This would preserve the old curve shape better than simply picking the correct index and calling `add_point()`.

Validation should cover straight insertion, tight bends, self-near/looping rivers, append beyond the end, collider snapping, axis and plane constraints, Remove mode after any picking refactor, undo/redo for Add and Remove, River stale warnings, and WaterSystem stale warnings.
