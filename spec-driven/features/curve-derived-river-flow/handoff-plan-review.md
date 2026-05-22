# Message to Next Codex Session: Curve-Derived River Flow

## Role

You are the next Codex session continuing `curve-derived-river-flow`.

This feature was blocked by the flow-map direction regression. That blocker is complete, validated locally, and marked complete in its own feature folder. The first no-code follow-up session rebased the curve-derived docs and reran the current baseline probes. Your first job now is to continue from the rebased `tasks.md`, not to implement the old pre-regression plan verbatim.

## Latest User Validation

The user has now tested a simple River with two points, then made it curved, and the Flow Arrows behaved properly.

Treat that as useful evidence that the current default downstream baseline and UV/tangent-frame flow behavior are sane for a simple straight-to-curved editing workflow. Do not treat it as proof that the full curve-derived feature is complete. It does not yet cover no-collider / zero-layer bakes, a true `Curve Only` mode, seam behavior, bank-helper scenarios, collision deflection policy, save/reload across all modes, or the final canonical validation matrix.

## Working Godot Paths

Use these Godot executables. These are the paths that actually work in this workspace:

- GUI/editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`
- Console/script runner: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`

## Required Reading

Read these files first, in this order:

1. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\00-constitution.md`
2. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\01-workflow.md`
3. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\handoff-latest.md`
4. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\tasks.md`
5. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\review.md`
6. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\validation.md`
7. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\curve-derived-river-flow\handoff-plan-review.md`
8. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\curve-derived-river-flow\tasks.md`
9. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\curve-derived-river-flow\review.md`
10. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\curve-derived-river-flow\validation.md`
11. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\curve-derived-river-flow\plan.md`
12. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\curve-derived-river-flow\spec.md`
13. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\curve-derived-river-flow\research.md`
14. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\curve-derived-river-flow\preliminary_research.md` only if you need the raw history behind the current decisions.

Then inspect the current Waterways add-on codebase here:

`C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways`

At minimum, inspect:

- `addons/waterways/river_manager.gd`
- `addons/waterways/water_helper_methods.gd`
- `addons/waterways/filter_renderer.gd`
- `addons/waterways/resources/river_bake_data.gd`
- `addons/waterways/river_gizmo.gd`
- `addons/waterways/plugin.gd`
- `addons/waterways/gui/river_menu.gd`
- `addons/waterways/shaders/river.gdshader`
- `addons/waterways/shaders/river_debug.gdshader`
- `addons/waterways/shaders/system_renders/system_flow.gdshader`
- relevant filter shaders in `addons/waterways/shaders/filters`

Use `rg` to find all references to flow-map generation, UV2 atlas padding, bake source metadata, texture validation, diagnostics, and debug arrow rendering before changing the plan.

## Current Waterways Behavior

The completed regression slice changed the baseline this feature should build on:

- Default generated River flow now uses `downstream_baseline_collision_support`.
- Legacy behavior is preserved as script/storage mode `bake_generation_behavior = "legacy_collision_only"`.
- Generated bake metadata can report `generated_downstream_baseline_collision_bake`.
- Flow-vector encode/decode helpers and decoded stats exist in `water_helper_methods.gd`.
- Unused UV2 atlas RG is neutralized so empty/padded atlas areas do not look like strong motion.
- Flow Arrows suppress near-neutral vectors, making debug output less misleading.
- WaterSystem diagnostics report alpha-covered decoded flow stats.
- `baking_raycast_layers == 0` still fails preflight.
- There is not yet a true `Curve Only` mode.
- There is not yet a final public `baking_generation_mode` enum covering `Curve Only`, `Curve + Collision Modifiers`, and `Collision Legacy`.
- Current docs decision: extend the existing serialized/script-accessible `bake_generation_behavior` string in the next slice instead of adding a parallel `baking_generation_mode` property immediately.
- Treat `generated_downstream_baseline_collision_bake` as the current foundation/predecessor source kind, not as the final true `Curve Only` source kind.

The desired design is still: the River curve supplies baseline downstream motion; colliders optionally modify and enrich it. Colliders are not "bad", but a River should not depend on collision texture quirks for basic downstream flow.

## Start Here

Task 1A and Task 2 in `tasks.md` are now complete. Start with Task 3 in `tasks.md`: extend generation behavior naming without broad UI churn, then continue toward zero-layer/no-collider behavior and true `Curve Only`.

Concrete first steps:

1. Check `git status` and understand existing edits before touching files.
2. Re-open `tasks.md`, `review.md`, and `validation.md` to confirm the latest no-code rebase notes.
3. Re-inspect active code before editing if the worktree changed.
4. Implement the next narrow slice: behavior naming, preflight by behavior, blank support-map fallback, and metadata.
5. Then add canonical curved/seam/bank-helper validation and run automated plus human-assisted checks.

Do not start old Task 2 blindly. Parts of the old plan were written before the regression fix and now risk duplicating or renaming behavior that already exists.

## Validation Notes

Existing evidence from the regression slice:

- Foam Map reasonable.
- Flow Pattern good.
- Flow Arrows consistent/correct.
- Normal view much better.
- Save/reload worked.
- Runtime looked good.
- Local WaterSystem stats passed.
- User-tested two-point River made curved, with arrows behaving properly.

Additional no-code baseline verification from the docs/testing session:

- Godot 4.6.3 scene-load smoke found `WaterSystem/StraightRiver`.
- Default bake probe: occupied `mag_avg=0.247090`, `near_neutral=0.00%`; unused atlas `near_neutral=100.00%`.
- Default WaterSystem probe: alpha-covered `mag_avg=0.294198`, `near_neutral=0.00%`.
- Legacy probe: occupied `near_neutral=95.81%`, `mag_avg=0.008847`; unused atlas `near_neutral=100.00%`.
- Static inspection: `baking_raycast_layers == 0` still fails preflight unconditionally.

Still-needed evidence for this feature:

- No-collider or zero-layer River bake behavior.
- True `Curve Only` behavior.
- Curved river canonical validation scene.
- UV2 seam and padded-atlas behavior under the curve-derived feature scope.
- Bank-helper / collision-modifier interaction once that mode exists.
- Save/reload and runtime checks for any new mode/source-kind naming.
- User-facing docs and maintainer docs updated for the final behavior.

Visible Godot/editor/shader validation is human-assisted by default in this workspace. Local parser or headless checks are useful, but they are not visual proof by themselves.

## Artifact Hygiene

Be careful with generated and local artifacts:

- Do not package `.codex-research/` unless intentionally included.
- Do not package `.godot/`.
- Do not package generated validation bakes such as `waterways_bakes/` unless intentionally included.
- Do not delete the validation scene used for flow-map checks.
- Do not delete the validation scripts used to inspect settings and bake behavior; they may be useful again.

## Do Not Do Yet

- Do not remove legacy collision-derived behavior.
- Do not rewrite the shader contract just because generation changes.
- Do not assume the old no-collider warnings are fixed; verify the current behavior directly.
- Do not add broad UI surface before deciding whether generation modes should be public now or internal first.
- Do not claim the curve-derived feature complete from the simple two-point manual test alone.
