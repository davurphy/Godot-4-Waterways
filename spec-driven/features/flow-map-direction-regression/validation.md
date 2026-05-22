# Validation: Flow Map Direction Regression

## What Must Be Proven

- The current pre-fix failure is correctly diagnosed: occupied River tile interiors are near-neutral before final combine.
- After implementation, default River bakes over flat occupied collision interiors do not silently produce unusable downstream flow.
- Flow Arrows do not show near-zero vectors as confident directions.
- Unused UV2 atlas tiles stay neutral or cannot influence visible output.
- WaterSystem composition does not amplify neutral, near-neutral, edge-derived, or unused-atlas River data into misleading world-flow output.
- Legacy collision-only behavior remains available and clearly identified if kept.
- Existing saved resources remain readable.
- Visible Godot editor/debug/runtime behavior matches the spec.

## Current Validation Snapshot

- Overall status: Complete for the flow-map direction regression slice; automated/local validation passed, River-side visible editor validation passed, save/reload passed, and runtime looked good.
- Last automated pass: Godot 4.6.3 non-headless scripted probes for decoded stats, effective flow force, default downstream bake, legacy comparison, scene load, and WaterSystem diagnostics.
- Last human-assisted pass: User visible check on 2026-05-22 confirmed Foam Map is reasonable, Flow Pattern looks good, Flow Arrows remain consistent/correct, and the actual normal view is much improved after pressure/foam support softening.
- Non-blocking deferred evidence: Dedicated WaterSystem visible output, seam/start/end visual checks, and performance timing are useful future checks but do not block this regression slice.
- Known unreliable local check or environment caveat: headless Godot uses a dummy renderer and cannot complete viewport readback bakes; non-headless console scripts worked with Vulkan Forward+ on AMD Radeon RX 6800 XT.

## Local Godot Paths

Use these known working Godot 4.6.3 executables when local checks are possible:

- Console/script runner: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
- GUI editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`

For automated probes, prefer the console executable and record the exact command. If sandboxed runs cannot create `user://` logs/cache, redirect `APPDATA` and `LOCALAPPDATA` to a workspace-local scratch folder and record that environment in the result.

Recommended local environment pattern:

```powershell
$root = 'C:\Users\pc\Documents\GitHub\Godot 4 Waterways'
$env:APPDATA = Join-Path $root '.codex-research\godot_463_user_home\Roaming'
$env:LOCALAPPDATA = Join-Path $root '.codex-research\godot_463_user_home\Local'
```

## Validation Matrix

| Requirement or risk | Check/probe/scene | Environment | Expected marker/result | Last result | Date | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| Pre-fix diagnosis is established | Read `intermediate_summary.txt` from Godot 4.6.3 dump | Local artifact | `river_06_normal_to_flow` occupied interiors `mean_mag=0.005546`, `active_mag_gt_0.02=0` | Pass pre-fix | 2026-05-22 | Agent |
| Final River combine is not the original loss point | Compare `river_06`, `river_07`, and `river_11` occupied interiors | Local artifact | All remain near-neutral in occupied interiors | Pass pre-fix | 2026-05-22 | Agent |
| Unused atlas tiles contain strong arbitrary flow pre-fix | Inspect tile centers in `river_11_final_flow_foam_noise.png` | Local artifact | Unused tile centers around mag `0.184` before fix | Pass pre-fix | 2026-05-22 | Agent |
| WaterSystem weak/non-neutral output pre-fix | Inspect `system_00_flow_raw.png alpha>0` stats | Local artifact | `mean_mag=0.026898`, `active_mag_gt_0.02=17004` | Pass pre-fix | 2026-05-22 | Agent |
| Default River bake produces useful downstream flow after fix | `default_bake_stats_probe.gd` non-headless script | Godot 4.6.3, Vulkan Forward+ | Occupied `mag_avg=0.247090`, `active_mag_gt_0.020=43520`, `near_neutral=0.00%` | Pass | 2026-05-22 | Agent |
| Debug Flow Arrows handle near-neutral vectors | Static shader scan plus visible editor check | Local static / Human visible editor | `FLOW_ARROW_NEAR_NEUTRAL_THRESHOLD=0.02`; arrows align with actual River shape | Pass for validation scene direction | 2026-05-22 | Agent/User |
| Flow Map debug reports useful magnitudes | `River -> Validate Data Textures` in non-headless script | Godot 4.6.3, Vulkan Forward+ | decoded min/max/avg, median, active, near-neutral percent printed | Pass local logs | 2026-05-22 | Agent |
| Flow Pattern moves downstream | `scenes/validation/flow_map_direction_verification.tscn` | Human visible editor | Straight River pattern visibly moves downstream after bake with usable strength | Pass after second adjustment | 2026-05-22 | User |
| Unused atlas tiles are neutral after fix | `default_bake_stats_probe.gd` default and legacy modes | Godot 4.6.3, Vulkan Forward+ | unused `near_neutral=100.00%`, `active_mag_gt_0.020=0` | Pass | 2026-05-22 | Agent |
| UV2 margins do not bleed empty cells | Seam/start/end visual and image-stat check | Human editor plus artifact | no visible seam flip; first/last occupied tiles not contaminated by unused tiles | Deferred/non-blocking; no seam issue reported after visible pass | 2026-05-22 | User/Agent |
| WaterSystem does not amplify neutral source data | WaterSystem output stats over alpha coverage | Local artifact/script/human editor | useful default River flow composes correctly; legacy weak source remains weak and diagnosed | Pass local logs after softening; dedicated visible WaterSystem check deferred/non-blocking | 2026-05-22 | Agent/User |
| Legacy collision-only remains available | Static scan plus `default_bake_stats_probe.gd -- legacy_collision_only` | Godot 4.6.3, Vulkan Forward+ | legacy occupied `near_neutral=95.81%`, `mag_avg=0.008847`, warning labels weak output | Pass | 2026-05-22 | Agent |
| Saved resources reload | Save and reload check | Human visible editor | `RiverBakeData` and `WaterSystemBakeData` textures/metadata survive reload | Pass | 2026-05-22 | User |
| Performance remains reasonable | Bake timing at representative resolutions | Human editor/local logs | timings recorded; no obvious runaway cost | Deferred/non-blocking for this regression slice | 2026-05-22 | Agent/User |

## Premise and Interpretation Checks

- Expected behavior that could look like a bug:
  - Legacy collision-only generation can produce near-neutral RG for flat collision input.
  - Exact neutral cannot be represented as a single unambiguous 8-bit RG integer because `0.5 * 255 = 127.5`.
  - Near-neutral vectors have valid numeric angles but no meaningful flow direction.
- Scene geometry, stale resources, generated data, or editor/runtime state to rule out:
  - Wrong bake resource loaded.
  - Old WaterSystem map generated from old River textures.
  - River source signature mismatch.
  - Wrong debug mode selected.
  - Collision helpers on wrong layer or flat/uniform by design.
- Evidence that would mean the user or agent is misreading the situation:
  - Occupied source-region vectors are strong and downstream, but Flow Arrows are still diagonal.
  - River output is correct but WaterSystem output is wrong, pointing to composition only.
  - Legacy collision-only mode was selected while expecting hardened default behavior.
- What the agent should say to the user if that evidence appears:
  - "The generated River data is now directional, so this result points away from the original flat-collision generation issue. We should inspect debug thresholding, material force settings, stale WaterSystem data, or the selected legacy/default mode before changing generation again."
- Quick falsifying check before patching:
  - Compare decoded vector magnitude and source metadata before inspecting angle or visible arrows.

## Automated Checks

Recommended checks:

- Static scan:
  - new source kind or generation behavior metadata;
  - vector-stat helpers;
  - near-neutral threshold constants;
  - legacy collision-only path;
  - no default-only dependence on `normal_to_flow` RG for flat collision input.
- Image-stat probe:
  - occupied tile interiors;
  - unused tile interiors and centers;
  - WaterSystem alpha-covered region;
  - source crop and padded texture dimensions.
- Godot script dump:
  - run with Godot 4.6.3 console and workspace-local `APPDATA`/`LOCALAPPDATA`;
  - dump the same intermediate stages as the pre-fix evidence if practical.

Expected result after implementation:

- Occupied River tile interiors report useful downstream vectors in default behavior.
- Unused atlas tiles report neutral RG.
- Near-neutral percentages are low for occupied default output and high/neutral for unused output.
- WaterSystem alpha-covered flow stats align with expected downstream world direction or remain neutral only when source is intentionally neutral.

Agent limitation note:

- Local checks may include static scans, parser checks, script dumps, and image statistics.
- Do not treat local headless/script checks as proof of visible editor interaction, shader visuals, debug arrows, bake workflow, or runtime behavior.

### Reusable Local Validation Assets

Keep the validation scene and probe scripts available for future regression checks, but do not include generated outputs in the minimal add-on package unless a source/validation archive is intentionally being produced.

- `scenes/validation/flow_map_direction_verification.tscn`: canonical straight River fixture for this regression. It is useful for River bake, Flow Map, Flow Pattern, Flow Arrows, WaterSystem generation, save/reload, and runtime checks. Re-generated `waterways_bakes/` resources are local artifacts by default.
- `.codex-research/flow_map_direction_verification/flow_vector_stats_probe.gd`: parser/stat smoke test for decoded flow-vector helpers, UV2 atlas occupied/unused tile stats, and pre-fix artifact comparison.
- `.codex-research/flow_map_direction_verification/default_bake_stats_probe.gd`: non-headless Godot probe that bakes the validation scene in default or `legacy_collision_only` mode, prints River occupied/unused stats, and samples WaterSystem alpha-covered flow.
- `.codex-research/flow_map_direction_verification/effective_flow_force_probe.gd`: non-headless Godot probe for raw flow, distance, pressure, effective Flow Pattern magnitude, and foam support after bake tuning.
- `.codex-research/flow_map_direction_verification/dump_flow_intermediates.gd`: diagnostic dump script for intermediate River and WaterSystem images. Treat its PNG output as evidence/scratch, not package content.
- `.codex-research/flow_map_direction_verification/godot_scene_load_smoke.gd`: narrow scene load and instantiation smoke test for `flow_map_direction_verification.tscn`.
- `.codex-research/flow_map_direction_verification/godot_launch_smoke.gd`: basic Godot script-launch sanity check.

## Human-Assisted Validation

Use this by default for visible Godot editor checks, viewport interaction, shader visuals, bake output, and runtime behavior. When requesting validation, paste the exact request in chat so the user does not need to open this file.

- Request to user:
  - Open the validation scene after implementation and run the River/WaterSystem bake and debug checks below. Please relay Output text, visible behavior, screenshots if convenient, Godot version, renderer, graphics device, and physics backend if visible.
- Exact scene, command, or workflow to run:
  1. Open `scenes/validation/flow_map_direction_verification.tscn`.
  2. Enable the Waterways plugin if needed.
  3. Select `WaterSystem/StraightRiver`.
  4. Run `River -> Generate Flow & Foam Map`.
  5. Run `River -> Validate Data Textures`.
  6. Inspect debug views:
     - `Display Debug Flow Map (RG)`
     - `Display Debug Flow Pattern`
     - `Display Debug Flow Arrows`
  7. Select `WaterSystem`.
  8. Run `WaterSystem -> Generate System Map`.
  9. Run `WaterSystem -> Validate Generated Map Sampling`.
  10. Save, reload, and run an F6/runtime-style check if requested for the implementation slice.
- Plugin state required:
  - Waterways plugin enabled.
- Console output or errors to relay back:
  - Parser errors.
  - River bake warnings.
  - Collision hit counts.
  - River decoded vector stats.
  - Unused tile stats.
  - WaterSystem vector stats.
  - Save notices.
  - Validation output.
- Screenshot or visible behavior to relay back:
  - Whether Flow Pattern moves downstream along the straight River.
  - Whether Flow Arrows are absent/neutral for near-zero data and directional for useful data.
  - Whether Flow Map appears neutral, directional, or edge-dominated.
  - Whether WaterSystem output appears straight/downstream or distorted.
- Godot version and renderer to relay back:
  - Godot version.
  - Renderer/backend.
  - Graphics device.
  - Physics backend if available.
- Expected result:
  - Default River bake produces useful downstream flow or clearly reports reduced/invalid direction.
  - Near-neutral arrows are not drawn as confident diagonal arrows.
  - WaterSystem output does not amplify neutral/unused data into misleading flow.
- Failure signs:
  - Occupied tiles still report near-neutral RG while bake is marked valid without warning.
  - Flow Arrows still show confident diagonal arrows for near-neutral data.
  - Unused atlas tile stats remain strongly non-neutral after final output.
  - WaterSystem alpha-covered flow is stronger or more directional than its source data justifies.
- Result recording format:
  - Date:
  - Ran by:
  - Godot version/renderer/device:
  - Physics backend:
  - Output or parser errors:
  - Visible result:
  - Screenshots/artifacts:
  - Pass/partial/fail:

## Recorded Results

Recorded result:

- Date: 2026-05-22
- Ran by: User
- Godot version/renderer/device: Not reported yet.
- Command, scene, or workflow:
  - Re-ran the visible validation after the second pressure/foam support follow-up.
  - Inspected water color, Foam Map, Flow Pattern, Flow Arrows, and actual normal view.
- Visible result:
  - Water color did not stand out strongly to the user.
  - River visual quality was greatly improved.
  - Foam Map looked reasonable.
  - Flow Pattern looked good.
  - Flow Arrows remained consistent and pointed in the correct direction.
  - Actual normal view looked much better.
- Pass/partial/fail:
  - Pass for River-side visible Flow Pattern, Foam Map, Flow Arrows, and normal view after pressure/foam support softening.
  - WaterSystem visible output was not recorded in this result.

Recorded result:

- Date: 2026-05-22
- Ran by: User
- Godot version/renderer/device: Not reported yet.
- Command, scene, or workflow:
  - Saved and reloaded after the latest River and bake adjustments.
- Visible result:
  - Save and reload worked.
- Pass/partial/fail:
  - Pass for saved resource reload.

Recorded result:

- Date: 2026-05-22
- Ran by: User
- Godot version/renderer/device: Not reported yet.
- Command, scene, or workflow:
  - Ran runtime/F6-style validation after save and reload.
- Visible result:
  - Runtime looked good.
- Pass/partial/fail:
  - Pass for runtime/F6-style behavior.
  - Dedicated WaterSystem visible output was not separately reported.

Recorded result:

- Date: 2026-05-22
- Ran by: User
- Godot version/renderer/device: Not reported yet.
- Command, scene, or workflow:
  - Opened `scenes/validation/flow_map_direction_verification.tscn`.
  - Ran River bake and WaterSystem bake.
  - Inspected Flow Pattern, Flow Arrows, and normal view.
- Output or parser errors:
  - River decoded flow-vector diagnostics before follow-up softening:
    - occupied `active_mag_gt_0.020=43520`, `near_neutral=0.00%`, `mag_avg=1.000008`;
    - unused `active_mag_gt_0.020=0`, `near_neutral=100.00%`.
  - WaterSystem map saved successfully to `res://waterways_bakes/scenes_validation_flow_map_direction_verification/WaterSystem.water_system_bake.res`.
- Visible result:
  - Flow Pattern color was light green and consistent throughout.
  - Flow Arrows all pointed in a single direction matching the actual River shape.
  - Normal view showed intense bands of visual distortion across River width, connected to the foam mix, making flow direction hard to confirm without zooming.
- Pass/partial/fail:
  - Pass for direction/Flow Arrows in the validation scene.
  - Partial/fail for normal/foam visual quality before follow-up adjustment.
- Notes or follow-up:
  - Agent follow-up reduced default downstream baseline strength to `0.5`, removed the stale flow-channel contrast warning for uniform active flow, and reduces saturated occupied foam support in default downstream bakes. Needs visible recheck.

Recorded result:

- Date: 2026-05-22
- Ran by: User
- Godot version/renderer/device: Not reported yet.
- Command, scene, or workflow:
  - Re-ran the visible validation after the first foam-support follow-up.
  - Inspected Flow Pattern, Foam Mix, Flow Arrows, and normal view.
- Visible result:
  - Improvement over the full-strength bake.
  - Flow Pattern remained very intense and still needed inspection.
  - Foam Mix was all black.
  - Flow Arrows still pointed in the correct direction.
  - Full bands and strong distortion were still present, apparently tied to Flow Pattern intensity.
- Pass/partial/fail:
  - Pass for direction/Flow Arrows.
  - Partial/fail for Flow Pattern intensity, Foam Mix, and normal-band visual quality before the second support-softening adjustment.
- Notes or follow-up:
  - Agent follow-up reduced default downstream baseline strength to `0.25`, softened saturated occupied pressure support to `0.25`, and changed saturated occupied foam support to a nonzero `0.25` floor instead of blacking it out.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device: Godot 4.6.3 stable, Vulkan 1.4.315, Forward+, AMD Radeon RX 6800 XT.
- Command, scene, or workflow:
  - Ran `effective_flow_force_probe.gd` before and after the second support-softening adjustment.
  - Re-ran `default_bake_stats_probe.gd`.
  - Re-ran `default_bake_stats_probe.gd -- legacy_collision_only`.
  - Re-ran `flow_vector_stats_probe.gd`.
  - Re-ran `godot_scene_load_smoke.gd`.
- Output or parser errors:
  - No parser errors in passing runs.
- Stable result marker:
  - Before second support-softening: effective flow-pattern magnitude without steepness averaged `1.7069`; foam `B` averaged `0.0000`.
  - After second support-softening: occupied raw River flow `mag_avg=0.247090`, effective flow-pattern magnitude without steepness averaged `0.2945`, foam `B` averaged `0.2471`, pressure support averaged `0.4941`.
  - Default WaterSystem alpha-covered flow after softening: `active_mag_gt_0.020=84992`, `near_neutral=0.00%`, `mag_avg=0.294198`, `avg_vec=(-0.0039, 0.2944)`.
  - Legacy collision-only still reports occupied `near_neutral=95.81%`, `mag_avg=0.008847`, and unused `near_neutral=100.00%`.
- Pass/partial/fail:
  - Pass for local data after the second visual-feedback adjustment.
  - At this point, visible Flow Pattern, Foam Mix, and normal-band recheck had not run yet; a later user check recorded that River-side visuals passed.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device: Godot 4.6.3 stable, Vulkan 1.4.315, Forward+, AMD Radeon RX 6800 XT.
- Command, scene, or workflow:
  - Re-ran `default_bake_stats_probe.gd` after foam/strength adjustment.
  - Re-ran `default_bake_stats_probe.gd -- legacy_collision_only`.
- Output or parser errors:
  - No parser errors.
- Stable result marker:
  - Default River bake occupied tiles after softening: `active_mag_gt_0.020=43520`, `near_neutral=0.00%`, `mag_avg=0.498055`, `avg_vec=(-0.0039, 0.4980)`.
  - Default River bake unused tiles: `active_mag_gt_0.020=0`, `near_neutral=100.00%`.
  - Flat occupied foam support reduction warning printed for the default validation scene.
  - Default WaterSystem alpha-covered flow remains downstream: `active_mag_gt_0.020=84992`, `near_neutral=0.00%`, `mag_avg=1.000069`, `avg_vec=(-0.0118, 1.0000)`.
  - Legacy collision-only still reports occupied `near_neutral=95.81%`, `mag_avg=0.008847`, and unused `near_neutral=100.00%`.
- Pass/partial/fail:
  - Pass for local data after visual-feedback adjustment.
  - At this point, visible normal/foam recheck had not run yet; later checks superseded this note.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device: Godot 4.6.3 stable, Vulkan 1.4.315, Forward+, AMD Radeon RX 6800 XT.
- Command, scene, or workflow:
  - `Godot_v4.6.3-stable_win64_console.exe --path <workspace> --script res://.codex-research/flow_map_direction_verification/flow_vector_stats_probe.gd`
  - `Godot_v4.6.3-stable_win64_console.exe --path <workspace> --script res://.codex-research/flow_map_direction_verification/default_bake_stats_probe.gd`
  - `Godot_v4.6.3-stable_win64_console.exe --path <workspace> --script res://.codex-research/flow_map_direction_verification/default_bake_stats_probe.gd -- legacy_collision_only`
  - `APPDATA` and `LOCALAPPDATA` redirected to `.codex-research/godot_463_user_home/`.
- Output or parser errors:
  - No parser errors in the passing non-headless runs.
  - A headless attempt hit the expected dummy-renderer viewport readback limitation and was not used as fix proof.
- Stable result marker:
  - Stats helper probe: `[127,128]` magnitude `0.005546`; sample active count `1`; atlas helper reports `6` occupied and `3` unused tiles.
  - Pre-fix artifact probe: `river_11_occupied_tiles near_neutral=95.81%`, `mag_avg=0.008847`; `river_11_unused_tiles near_neutral=0.00%`; `system_03_alpha_covered mag_avg=0.026898`, `active_mag_gt_0.020=17004`.
  - Default River bake: occupied `active_mag_gt_0.020=43520`, `near_neutral=0.00%`, `mag_avg=1.000008`; unused `active_mag_gt_0.020=0`, `near_neutral=100.00%`.
  - Default WaterSystem bake: alpha-covered `active_mag_gt_0.020=84992`, `near_neutral=0.00%`, `mag_avg=1.000069`, `avg_vec=(-0.0118, 1.0000)`.
  - Legacy collision-only bake: occupied `near_neutral=95.81%`, `mag_avg=0.008847`; unused `near_neutral=100.00%`; near-neutral warning printed.
- Pass/partial/fail:
  - Pass for local/statistical generation, metadata/static scan, legacy comparison, unused-tile neutrality, and WaterSystem diagnostics.
  - Partial for Flow Arrows: shader threshold is implemented and parses, but visible debug view validation is still required.
- Notes or follow-up:
  - Human-assisted visible editor validation is still required for Flow Pattern, Flow Arrows, WaterSystem visuals, and save/reload behavior.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device: Godot 4.6.3 stable, real renderer dump produced by prior Codex pass.
- Command, scene, or workflow:
  - Intermediate dump for `scenes/validation/flow_map_direction_verification.tscn`.
  - Artifact folder: `.codex-research/flow_map_direction_verification/intermediate_dump_godot_463`.
- Output or parser errors:
  - None recorded in `intermediate_summary.txt`.
- Visible result, if applicable:
  - Not a visible editor validation result.
- Stable result marker:
  - `river_06_normal_to_flow.png occupied tile interiors: mean_mag=0.005546, active_mag_gt_0.02=0, range_rg=(127..127,128..128)`.
  - `river_11_final_flow_foam_noise.png occupied tile interiors: mean_mag=0.005864, active_mag_gt_0.02=2`.
  - `river_11_final_flow_foam_noise.png unused tile centers: decoded magnitude around 0.184`.
  - `system_00_flow_raw.png alpha>0: mean_mag=0.026898, active_mag_gt_0.02=17004`.
- Pass/partial/fail:
  - Pass for diagnosis; fail/partial for product behavior.
- Notes or follow-up:
  - This evidence proves the pre-fix generation problem but does not validate any fix.

## Historical Results Archive

No older validation has been moved here yet. See `preliminary_research.md` for raw evidence/history.

## Shader Checks

- Shader/material path:
  - `addons/waterways/shaders/river_debug.gdshader`
  - `addons/waterways/shaders/system_renders/system_flow.gdshader`
- Renderer backend:
  - Human-assisted validation should report active renderer.
- Expected result:
  - Flow Arrows threshold near-neutral vectors.
  - WaterSystem composition does not turn near-neutral raw RG into misleading world flow.
- Failure signs:
  - `atan(flow.y, flow.x)` remains unguarded for near-zero vectors.
  - WaterSystem output shows strong direction when River source is neutral.

## Editor Workflow Check

Procedure:

1. Open `scenes/validation/flow_map_direction_verification.tscn`.
2. Select `WaterSystem/StraightRiver`.
3. Run `River -> Generate Flow & Foam Map`.
4. Run `River -> Validate Data Textures`.
5. Inspect Flow Map, Flow Pattern, and Flow Arrows.
6. Select `WaterSystem`.
7. Run `WaterSystem -> Generate System Map`.
8. Run `WaterSystem -> Validate Generated Map Sampling`.

Expected result:

- Output includes decoded vector stats.
- River output has meaningful downstream direction in default behavior.
- Flow Arrows do not misrepresent neutral data.
- WaterSystem output matches the source direction or reports neutral/reduced data.

Failure signs:

- Near-neutral occupied River data is marked as successful downstream flow.
- WaterSystem map becomes more misleading than River source data.
- Debug views disagree with vector-stat output.

## Visual Test Scene

Scene path:

- `scenes/validation/flow_map_direction_verification.tscn`

Purpose:

- Prove the known straight River regression path and WaterSystem composition behavior.

Expected visual result:

- Flow Pattern visibly moves straight downstream in default hardened behavior.
- Flow Arrows are directional only where vectors are meaningful.
- Flow Map is not dominated by unused tile or edge-derived vectors.
- WaterSystem output is not broadly diagonal/distorted from neutral input.

Failure signs:

- Stationary or diagonal-looking flow after a successful default bake.
- Strong arrows in neutral regions.
- Distortion appears only after WaterSystem bake despite correct River source stats.

Suggested controls or debug views:

- `Display Debug Flow Map (RG)`
- `Display Debug Flow Pattern`
- `Display Debug Flow Arrows`
- `Display Debug Flow Strength`

## Bake Output Check

Scenario:

- Straight River over flat occupied collision input in `flow_map_direction_verification.tscn`.

Expected generated outputs after fix:

- Flow:
  - occupied source-region tiles contain meaningful downstream RG in default behavior;
  - unused source-region tiles are neutral;
  - legacy collision-only may remain near-neutral but must be labelled legacy.
- Foam:
  - unchanged unless collision support is intentionally reduced or blank.
- Distance/pressure:
  - unchanged or explicit support fallback when collision data is not useful.
- Height/alpha:
  - WaterSystem height/coverage remain valid.
- Metadata:
  - source kind/behavior, hit stats, vector stats, unused-tile stats, `content_rect`, source/padded sizes, `uv2_sides`, source signature.

Failure signs:

- Occupied RG remains near-neutral in default behavior.
- Unused RG remains strongly non-neutral.
- Metadata lacks stats needed to diagnose the output.

## Runtime API Check

Procedure:

- After successful editor bake, save and reload the scene.
- Run F6/runtime-style check if practical.
- Confirm River and WaterSystem use serialized bake resources.

Expected result:

- Runtime/debug output uses saved textures and uniforms.
- No live editor-only collision helpers or filter renderers are required.

Failure signs:

- Runtime falls back to invalid flow.
- Saved resources lose metadata or textures.
- WaterSystem sampling does not match saved `system_map`.

Last result:

- Pass on 2026-05-22 by user: save/reload worked and runtime looked good.

## Performance Check

Scenario:

- Bake the validation scene at `baking_resolution = 2` first, then at lower/higher settings if code changes are nontrivial.

Budget or target:

- No formal budget yet. Record timings and flag obvious editor stalls or O(pixel count * curve complexity) behavior.

How to measure:

- Output timing if added.
- Editor-observed timing.
- Local script timing around bake/probe execution if available.

## Artifact Hygiene Check

- Scratch project or temporary folder used:
  - Existing: `.codex-research/flow_map_direction_verification/`.
- Active scripts/resources mirrored into scratch before validation:
  - Not applicable yet for this feature pass.
- Generated bakes/resources created:
  - Existing pre-fix generated bakes in `waterways_bakes/` and `.codex-research/`.
- Files or folders that must be excluded from packaging:
  - `.codex-research/`, `.godot/`, generated validation bakes unless intentionally committed.
- Files or folders safe to delete now:
  - None identified by this document.

## Extension Check

Custom content scenario:

- Existing saved generated resources, imported/manual flow maps, and legacy collision-only comparison.

Expected result:

- Existing `generated_spline_collision_bake` resources load.
- Imported/manual maps keep packed RG interpretation and are not rewritten.
- Legacy collision-only output can be compared deliberately.

Failure signs:

- Old resources fail to load.
- Imported/manual maps are treated as generated default output.
- Legacy comparison disappears without explicit compatibility decision.

## Manual Review Checklist

- [x] Acceptance criteria are satisfied or explicitly marked deferred/non-blocking.
- [x] Likely false premises were raised before implementation.
- [x] Human-assisted editor/shader results are recorded when local tooling cannot prove them.
- [x] Active code uses Godot 4.6+ APIs.
- [x] Editor/runtime boundaries are preserved.
- [x] Generated resources and metadata are explicit and inspectable.
- [x] Flow direction, foam, Flow Arrows, save/reload, and runtime behavior are checked visibly; seam and dedicated WaterSystem visible checks are deferred/non-blocking.
- [x] Automated/image-stat checks cover occupied vector magnitude, unused tile neutrality, and WaterSystem alpha-covered flow.
- [x] Runtime/save-reload behavior matches generated data.
- [x] Performance timing is deferred/non-blocking for this regression slice.
- [x] Known limitations are documented.
