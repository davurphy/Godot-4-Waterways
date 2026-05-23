# Validation: River Add Wrong Span

## What Must Be Proven

- Add mode inserts into the clicked visible River span rather than a nearby wrong control-polygon span.
- On-curve Add preserves the clicked Bezier span shape closely enough that tight spans do not kink or twist from guessed handles.
- Add mode still appends beyond the final point when no visible curve hit is found.
- Append constraints still work: none, collider snapping, axis constraints, and plane constraints.
- Remove mode still uses a visible-curve click gate and removes the nearest authored control point.
- Undo/redo restores Add and Remove changes correctly.
- River and WaterSystem stale warnings still appear through existing invalidation and metadata paths.
- `RiverManager.add_point()` compatibility is preserved.

## Current Validation Snapshot

- Overall status: Partial.
- Last automated pass: 2026-05-22 Godot console plugin-load, curve-hit helper, Bezier split, and `add_point()` compatibility smoke checks passed.
- Last human-assisted pass: 2026-05-22 user report after first span-only implementation; intermittent bad/twisted new points still occurred.
- Highest-risk unproven behavior: visible Add-mode interaction on tight/self-near Rivers.
- Known unreliable local check or environment caveat: static and script checks cannot prove visible editor picking, gizmo behavior, or viewport mesh shape.

## Local Godot Paths

Use these known working Godot 4.6.3 executables when local checks are possible:

- Console/script runner: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
- GUI editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`

For automated probes, prefer the console executable and record the exact command. If sandboxed runs cannot create `user://` logs/cache, redirect `APPDATA` and `LOCALAPPDATA` to a workspace-local scratch folder and record that environment in the result.

## Validation Matrix

| Requirement or risk | Check/probe/scene | Environment | Expected marker/result | Last result | Date | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| Add old code could mix position and span | Static review of pre-fix `plugin.gd` | Local code review | separate control-chord `closest_segment`, baked `baked_closest_point`, then `add_point()` with both | Pass, risk validated before implementation | 2026-05-22 | Agent |
| Add new code uses one hit result | Static scan of `plugin.gd` | Local code review | no `baked_closest_point`, `closest_segment`, or plugin `get_baked_points()` Add pairing remains | Pass | 2026-05-22 | Agent |
| Curve-hit helper returns owning sampled span | Godot console script `.codex-research/check_river_curve_hit.gd` | Godot 4.6.3 console, `APPDATA`/`LOCALAPPDATA` redirected to `.codex-research` | span 0 hit, span 1 hit, bowed visible span hit, far miss | Pass | 2026-05-22 | Agent |
| Mesh generation is downstream | Static review of `water_helper_methods.gd` | Local code review | mesh samples final curve rather than choosing insertion span | Pass | 2026-05-22 | Agent |
| Add on straight span | Manual editor workflow | Godot GUI, human visible | new point appears between clicked span's authored endpoints | Unrun |  | User/Agent |
| Add on tight bend | Manual editor workflow | Godot GUI, human visible | new point appears on clicked visible bend and mesh does not wrong-span twist | Failed/partial before Bezier split; re-test needed | 2026-05-22 | User |
| Add on self-near/looping River | Manual editor workflow | Godot GUI, human visible | new point inserts into clicked visible span, not nearest unrelated chord | Unrun |  | User/Agent |
| Append away from curve | Manual editor workflow | Godot GUI, human visible | new point appends after final point | Unrun |  | User/Agent |
| Append constraints | Manual editor workflow | Godot GUI, human visible | none/collider/axis/plane constraints match prior behavior | Unrun |  | User/Agent |
| Remove mode after refactor | Manual editor workflow | Godot GUI, human visible | click near visible curve removes nearest authored point | Unrun |  | User/Agent |
| Undo/redo | Manual editor workflow plus state inspection if needed | Godot GUI | curve, widths, mesh, valid state, and warnings restore | Unrun |  | User/Agent |
| River stale warning | Edit River after a valid bake | Godot GUI or script | `valid_flowmap` false and River warning appears | Unrun |  | User/Agent |
| WaterSystem stale warning | Edit child River after system bake | Godot GUI or script | WaterSystem warns child River metadata changed | Unrun |  | User/Agent |
| Shape-preserving on-curve split | Godot console script `.codex-research/check_split_curve_span.gd` | Godot 4.6.3 console, `APPDATA`/`LOCALAPPDATA` redirected to `.codex-research` | split point at original midpoint; first and second split spans preserve original samples; width count matches point count | Pass | 2026-05-22 | Agent |
| `add_point()` compatibility | Godot console script `.codex-research/check_add_point_compat.gd` | Godot 4.6.3 console, `APPDATA`/`LOCALAPPDATA` redirected to `.codex-research` | append and indexed insert semantics unchanged; width count remains aligned | Pass | 2026-05-22 | Agent |

## Premise and Interpretation Checks

- Expected behavior that could look like a bug:
  - Simple curves may already insert correctly because the nearest chord and nearest baked span agree.
  - Correct-span insertion with guessed handles may still create a small kink; that is a separate shape-preservation limitation.
  - Existing River and WaterSystem maps become stale after curve edits by design.
- Scene geometry, stale resources, generated data, or editor/runtime state to rule out:
  - User clicked away from the curve and triggered append intentionally.
  - A stale generated mesh or bake was inspected after editing.
  - The selected mode was Remove or Select rather than Add.
  - Constraint mode affected append but was mistaken for on-curve insertion behavior.
- Evidence that would mean the user or agent is misreading the situation:
  - Current code inserts into the clicked visible span in a deliberately self-near fixture where chord proximity disagrees.
  - Mesh twist remains after verified correct span selection and appears even before adding a point.
- What the agent should say to the user if that evidence appears:
  - "The visible check points away from the Add span mismatch as the active cause. We should inspect shape-preserving handle splitting, stale generated geometry, or a separate mesh orientation issue before changing more picking code."
- Quick falsifying check before patching:
  - Build a tight/self-near River, click where the visible baked span and nearest control chord disagree, and inspect the inserted point order.

## Automated Checks

- Command or procedure:
  - Static scan `addons/waterways/plugin.gd` for whether Add mode still sends an independently chosen `baked_closest_point` and `closest_segment` to `add_point()`.
  - Optional Godot console probe for isolated hit-to-span helper if the helper can run without live editor input.
  - Optional script-level `RiverManager.add_point()` compatibility smoke check if `river_manager.gd` is touched.
  - Godot console probe for `split_curve_span_at()` preserving curve samples and width count.
- Expected result:
  - After implementation, Add mode should use a single hit result for position and span.
  - Append and indexed `add_point()` calls should retain existing behavior.
- Agent limitation note:
  - Local static/script checks are not proof of visible editor interaction, viewport picking, gizmo behavior, or mesh appearance.

Latest automated commands:

- Plugin load:
  - `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe --headless --path "C:\Users\pc\Documents\GitHub\Godot 4 Waterways" --log-file "C:\Users\pc\Documents\GitHub\Godot 4 Waterways\.codex-research\logs\check_plugin_load.log" --script "res://.codex-research/check_plugin_load.gd"`
  - Environment: `APPDATA` and `LOCALAPPDATA` redirected to `.codex-research`.
  - Result: passed; output included `Loaded Waterways editor plugin script.`
- Hit helper smoke check:
  - `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe --headless --path "C:\Users\pc\Documents\GitHub\Godot 4 Waterways" --log-file "C:\Users\pc\Documents\GitHub\Godot 4 Waterways\.codex-research\logs\check_river_curve_hit.log" --script "res://.codex-research/check_river_curve_hit.gd"`
  - Environment: `APPDATA` and `LOCALAPPDATA` redirected to `.codex-research`.
  - Result: passed; checked span 0, span 1, a bowed visible span, and a far miss; output included `River curve hit helper smoke check passed.`
- Split span smoke check:
  - `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe --headless --path "C:\Users\pc\Documents\GitHub\Godot 4 Waterways" --log-file "C:\Users\pc\Documents\GitHub\Godot 4 Waterways\.codex-research\logs\check_split_curve_span.log" --script "res://.codex-research/check_split_curve_span.gd"`
  - Environment: `APPDATA` and `LOCALAPPDATA` redirected to `.codex-research`.
  - Result: passed; output included `River split span smoke check passed.`
- `add_point()` compatibility smoke check:
  - `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe --headless --path "C:\Users\pc\Documents\GitHub\Godot 4 Waterways" --log-file "C:\Users\pc\Documents\GitHub\Godot 4 Waterways\.codex-research\logs\check_add_point_compat.log" --script "res://.codex-research/check_add_point_compat.gd"`
  - Environment: `APPDATA` and `LOCALAPPDATA` redirected to `.codex-research`.
  - Result: passed; output included `River add_point compatibility smoke check passed.`
  - Note: the probe intentionally assigned a too-short width array to verify recovery, which produced the existing sanitizer warning once during setup.
- Static scan:
  - `rg -n "baked_closest_point|closest_segment|get_baked_points\(\)|restore_curve_state\(" addons/waterways/plugin.gd`
  - Result: passed; no matches.

## Human-Assisted Validation

Use this by default for visible Godot editor checks, viewport interaction, gizmos, and warning behavior. The agent may not be able to open or interact with Godot reliably.

When requesting this validation, the agent must put the exact request in the chat message so the user does not have to open this file to discover what to run.

- Request to user:
  - Please open the project in Godot 4.6.3 and test the River Add/Remove workflows below. Relay visible behavior, Output errors, Godot version, renderer, and screenshots if the inserted point or mesh shape looks wrong.
- Exact scene, command, or workflow to run:
  1. Open a scene with a River or create a scratch scene with one River.
  2. Create or edit one straight River section, one tight curved section, and one self-near/looping section where two visible spans are close together.
  3. Select the River, choose Add mode, and click directly on each visible span.
  4. Inspect the new control point order and generated mesh after each click.
  5. Undo and redo each Add.
  6. Click away from the visible curve to append beyond the end with no constraint.
  7. Repeat append with collider snapping, one axis constraint, and one plane constraint.
  8. Switch to Remove mode and click near visible curve sections; verify the nearest authored control point is removed.
  9. If a River and parent WaterSystem have valid bakes, edit the River and check stale warnings.
- Plugin state required:
  - Waterways plugin enabled.
- Console output or errors to relay back:
  - Parser errors, editor errors, warnings, and any Waterways stale warnings.
- Screenshot or visible behavior to relay back:
  - Inserted point location/order.
  - Any kink, twist, inversion, or unexpected append.
  - Undo/redo result.
- Godot version and renderer to relay back:
  - Godot version, renderer/backend, graphics device if visible.
- Expected result:
  - Add inserts into the clicked visible span.
  - Append and constraints behave as before.
  - Remove and undo/redo behave as before.
  - Stale warnings appear after edit.
- Failure signs:
  - New point appears on a different visible span than the one clicked.
  - Mesh twists because point order is wrong.
  - Add away from curve no longer appends.
  - Remove deletes a non-nearest authored point.
  - Undo/redo leaves stale material flags or warnings wrong.
- Result recording format:
  - Date:
  - Ran by:
  - Godot version/renderer/device:
  - Output or parser errors:
  - Visible result:
  - Pass/partial/fail:

## Recorded Results

Recorded result:

- Date: 2026-05-22
- Ran by: User
- Godot version/renderer/device: Not reported.
- Command, scene, or workflow: Visible Godot editor River Add workflow after first span-only implementation.
- Output or parser errors: `WARNING: core/variant/variant_utility.cpp:1034 - Waterways: widths had unsafe value too few entries; using padded to curve point count instead.`
- Visible result, if applicable: Bad new points were still added intermittently; one new segment was twisted.
- Stable result marker: Span selection alone was insufficient; implementation revised to split the clicked Bezier span and interpolate width.
- Pass/partial/fail: Fail for the first span-only implementation; re-test pending for shape-preserving implementation.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device: Godot 4.6.3 console, headless; renderer/device not applicable.
- Command, scene, or workflow: Loaded `addons/waterways/plugin.gd` through `.codex-research/check_plugin_load.gd` and ran `.codex-research/check_river_curve_hit.gd`.
- Environment: `APPDATA` and `LOCALAPPDATA` redirected to `.codex-research` for sandboxed Godot cache/log writes.
- Output or parser errors: successful runs had no parser errors; a direct attempt to run `plugin.gd` as the main script was abandoned because `EditorPlugin` is not a runtime main script.
- Visible result, if applicable: not applicable.
- Stable result marker: plugin script loaded; helper returned expected span 0, span 1, bowed visible span, and miss results; old two-source Add pattern no longer present in `plugin.gd`.
- Pass/partial/fail: Partial.
- Notes or follow-up: visible editor Add/Remove, append constraints, undo/redo, and stale-warning checks remain pending.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device: Godot 4.6.3 console, headless; renderer/device not applicable.
- Command, scene, or workflow: Ran `.codex-research/check_split_curve_span.gd` and `.codex-research/check_add_point_compat.gd`.
- Environment: `APPDATA` and `LOCALAPPDATA` redirected to `.codex-research` for sandboxed Godot cache/log writes.
- Output or parser errors: split probe passed with no warnings; compatibility probe passed and intentionally produced one existing short-width sanitizer warning during setup.
- Visible result, if applicable: not applicable.
- Stable result marker: `split_curve_span_at()` preserves sampled shape and width count; `add_point()` append/indexed semantics remain compatible.
- Pass/partial/fail: Partial.
- Notes or follow-up: visible editor re-validation is required because console probes cannot prove viewport picking, mesh appearance, gizmo behavior, or warning UX.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device: Not launched; static local code review only.
- Command, scene, or workflow: Read `research.md`, `findings.md`, `session-handoff.md`, and active add-on code.
- Output or parser errors: none; no Godot execution.
- Visible result, if applicable: not applicable.
- Stable result marker: research findings validated; no major finding invalidated.
- Pass/partial/fail: Partial.
- Notes or follow-up: interactive editor reproduction remains pending.

## Historical Results Archive

No archived runs yet.

## Shader Checks

- Shader/material path: not applicable.
- Renderer backend: not applicable.
- Expected result: no shader changes for this feature.
- Failure signs: any shader edit should trigger plan/spec review because it is out of scope.

## Editor Workflow Check

Procedure:

1. Add a point on straight, tight, and self-near River spans.
2. Append beyond the end under each constraint mode.
3. Remove points and run undo/redo after Add and Remove.

Expected result:

- Add follows the clicked visible span.
- Append and Remove preserve existing behavior.
- Undo/redo restores curve and stale state.

Failure signs:

- Wrong-span insert, unexpected append, broken constraints, wrong Remove target, or stale warning mismatch.

## Visual Test Scene

Scene path:

- No dedicated scene yet.

Purpose:

- A future fixture may capture a self-near River where control-chord proximity disagrees with visible curve span.

Expected visual result:

- New control point appears on the clicked visible span and the mesh stays ordered.

Failure signs:

- Point order jumps to another nearby span, producing a kink, loop, twist, or inversion.

Suggested controls or debug views:

- River Add/Remove toolbar controls.
- River gizmo control points and handles.

## Bake Output Check

Scenario:

- Start with a River and WaterSystem whose generated maps are valid, then edit the River via Add/Remove.

Expected generated outputs:

- Flow: existing map becomes invalid/stale after curve edit.
- Foam: existing map becomes invalid/stale after curve edit.
- Distance/pressure: existing map becomes invalid/stale after curve edit.
- Height/alpha: WaterSystem map becomes stale after child River metadata changes.
- Metadata: River source signature changes; WaterSystem child metadata comparison reports mismatch.

Failure signs:

- `valid_flowmap` remains true after curve edit.
- WaterSystem stays silent after child River source metadata changes.

## Runtime API Check

Procedure:

- If `river_manager.gd` is touched, run a small script or inspect calls to verify `add_point(position, -1)` appends and `add_point(position, index)` inserts at `index + 1`.

Expected result:

- Existing API semantics remain unchanged.

Failure signs:

- Script callers need a different index convention or receive shape-preserving behavior unexpectedly.

## Performance Check

Scenario:

- A River with enough baked points to make editor picking meaningful.

Budget or target:

- Add/Remove picking remains responsive and does not add physics queries to on-curve insertion.

How to measure:

- Human-visible editor interaction plus optional simple timing/logging if responsiveness regresses.

## Artifact Hygiene Check

- Scratch project or temporary folder used: `.codex-research` for Godot scripts, redirected Godot cache/logs, and probe logs.
- Active scripts/resources mirrored into scratch before validation: not applicable; probes loaded the active add-on scripts from the workspace.
- Generated bakes/resources created: no intentional bake outputs. Godot probing/import touched tracked `waterways_bakes/scenes_validation_curve_derived_river_flow_validation/SeamCrossingCurveRiver.river_bake.res`; this is not part of the intended code change and should be restored or reviewed separately.
- Files or folders that should remain local-only: `.codex-research/check_plugin_load.gd`, `.codex-research/check_river_curve_hit.gd`, `.codex-research/godot-appdata`, `.codex-research/godot-localappdata`, and `.codex-research/logs`; this folder is ignored by `.gitignore`.
- Files or folders safe to delete now: `.codex-research` probe artifacts are disposable. An accidental early `.codex` Godot cache folder was created before switching to `.codex-research`; deletion was blocked by the current sandbox, so it remains local-only/untracked and should be removed outside the sandbox when convenient.

## Extension Check

Custom content scenario:

- External script calls `RiverManager.add_point()`.

Expected result:

- Existing append and insert behavior is preserved.

Failure signs:

- API compatibility changes without spec approval.

## Manual Review Checklist

- [ ] Acceptance criteria are satisfied.
- [ ] Likely false premises or expected-behavior explanations were raised with the user before extra implementation work.
- [ ] Human-assisted Godot/editor/test results are recorded when the agent could not run them directly.
- [ ] Active code uses current Godot 4.6+ APIs.
- [ ] Editor-only and runtime-safe boundaries are preserved.
- [ ] Generated resources and metadata are explicit and inspectable.
- [ ] Visual output matches the spec.
- [ ] Flow direction, seams, foam, masks, and bounds are checked visually when affected.
- [ ] Runtime sampling/API behavior matches generated data when affected.
- [ ] Performance-sensitive paths have been checked.
- [ ] Known limitations are documented.
