# Validation: Curve-Derived River Flow

## What Must Be Proven

- Curve-based bakes produce non-neutral downstream RG flow inside occupied river atlas texels without requiring bake helper colliders.
- Default `Curve + Collision Modifiers` mode preserves curve RG while allowing collision data to affect foam, distance, and pressure support maps.
- `Curve Only` and no-hit fallback paths use exact blank support maps with `dist_pressure.rg = (0.0, 0.0)`.
- `Collision Legacy` can reproduce current collision-derived RG behavior.
- Generated textures preserve the padded UV2 atlas layout and `content_rect` source crop.
- Vector diagnostics distinguish useful uniform direction from near-neutral/no direction.
- Flow Arrows treat near-zero vectors as neutral in the current debug shader, with a direct neutral-visible check still useful as future evidence.
- Saved `RiverBakeData` resources reload with source kind, source metadata, texture sizes, `content_rect`, UV2 sides, and source signature intact.
- The main river shader animation path remains unchanged in the first implementation.
- Bake-time cost stays reasonable at low, medium, and highest supported resolutions.

## Current Validation Snapshot

Keep this short and current. Older detailed runs belong in "Recorded Results" below.

- Overall status: Task 12 is locally passed for rebake/save, data validation, screenshots, fresh-process reload, runtime-style checks, F6-style launch smoke, and bake timing. A live human editor menu/motion pass remains useful but is no longer blocking the curve-derived bake data path.
- Last automated/local pass: Godot 4.6.3 on 2026-05-22 rebaked every canonical fixture, saved River and WaterSystem bake resources, verified source signatures after fresh reload, and launched the scene in runtime mode with `--quit-after 2`.
- Last visible evidence: Task 12 screenshots on 2026-05-22 show Flow Pattern and Flow Arrows on `CurvedNoColliderRiver` and `SeamCrossingCurveRiver`; arrows remain visible and aligned through the seam-crossing fixture.
- Highest-risk residual behavior: live animated editor observation is still the only missing proof for time-based motion; transparency/material controls remain deferred outside this bake-plan slice.
- Known local check or environment caveat: `Validate Data Textures` currently warns that generated `.res` subresource textures lack `.import` files. The bake resources are readable and reload correctly, so this looks like a diagnostics false-positive for generated external resources, not broken data.

## User-Reported Behavior Triage

This section records the 2026-05-22 visible validation observations so future sessions can separate expected first-pass behavior from real follow-up risks.

| Observation | Current classification | Why | Follow-up |
| --- | --- | --- | --- |
| `StraightNoColliderRiver`, `CurvedNoColliderRiver`, and `SeamCrossingCurveRiver` show black Foam Map, Pressure Map, and Foam Mix debug views. | Expected non-blocker for this implementation slice. | The current plan and completed Task 6 intentionally use blank no-collider/curve-only support maps: `flow_foam_noise.b = 0.0` and `dist_pressure.rg = (0.0, 0.0)`. | Do not treat as a regression unless a fixture with collision support also produces flat support maps unexpectedly. Future curve-only procedural foam/pressure would require a new design task. |
| `flow_pressure` appears ineffective on no-collider/curve-only fixtures. | Expected non-blocker for this implementation slice. | Pressure support is blank in these modes, so the material pressure multiplier has no pressure signal to amplify. | Recheck only on `FlatColliderRiver` or `BankHelperRiver`, where pressure support should exist. |
| `flow_max` can be hard to notice. | Not a blocker; needs targeted visual validation if questioned. | `flow_max` only clamps the computed force when the force reaches the cap, so it may not visibly change all fixtures/settings. | Validate with an intentionally high-force scene or inspector probe before treating this as a regression. |
| `FlatColliderRiver` controls and debug views appear to work. | Expected pass signal. | The fixture has collider hits, so collision-derived foam/distance/pressure support maps should exist while RG remains curve-derived. | Keep as evidence that support maps work when useful collision input exists. |
| `BankHelperRiver` looks good and shows expected debug views. | Expected pass signal. | The plan specifically expects bank-helper colliders to add foam/pressure/detail without destroying curve RG direction. | Keep as the primary visible proof for collision support maps. |
| Transparency controls appear ineffective on curved rivers in the validation scene. | Needs more attention after the current plan slice is otherwise validated. | Existing docs mention material controls but do not prove depth/refraction behavior in this canonical scene. The shader's transparency controls depend on depth/screen sampling and scene geometry, not on the curve-derived bake itself. | Track as a shader/material validation follow-up, separate from no-collider flow generation. |
| `CurvedNoColliderRiver` can load with `valid_flowmap=false` if its saved bake signature is stale. | Resolved for the Task 12 scene after rebake/save/reload. | Task 12 saved a fresh `CurvedNoColliderRiver.river_bake.res`; a separate fresh-process reload reported `valid_flowmap=true`, matching source signature, and `source_kind=generated_curve_only_bake`. | Keep this as a stale-resource warning for old local copies, but do not block this scene after the Task 12 rebake. |
| `Validate Data Textures` reports missing `.import` settings for generated textures stored as subresources inside external `.res` bake files. | Non-blocking diagnostics issue. | The textures have resource paths like `res://...river_bake.res::ImageTexture_*`; these are generated resource subobjects, not imported image files. Data reads, stats, save/reload, and runtime-style checks passed. | Follow up by teaching validation to treat `.res::subresource` generated textures as resource-owned instead of imported texture files. |

## Validation Matrix

Use this as the durable map from requirements to proof. Prefer stable probe names, scene names, or result markers.

| Requirement or risk | Check/probe/scene | Environment | Expected marker/result | Last result | Date | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| Serialized behavior exists and invalidates stale data | Static scan plus source-signature inspection | Local static | `bake_generation_behavior` appears in storage/defaults/bake settings/source signature; no `baking_generation_mode` exists by current decision | Pass current baseline | 2026-05-22 | Agent |
| Curve/default source kinds exist | Static scan and bake probes | Local static / Godot 4.6.3 | `SOURCE_KIND_DOWNSTREAM_BASELINE_COLLISION_BAKE` remains readable; new bakes can write `generated_curve_collision_modifiers_bake` and `generated_curve_only_bake` | Pass local: source kinds written by probes | 2026-05-22 | Agent |
| Curve/default RG uses local downstream `+V`, not world X/Z | Code review plus `default_bake_stats_probe.gd` | Godot 4.6.3, Vulkan Forward+ | occupied texels encode non-neutral `+V`; no world X/Z projection is used for River RG | Pass: occupied `mag_avg=0.247090`, `near_neutral=0.00%` | 2026-05-22 | Agent |
| UV2 atlas padding is preserved | Code review and image-size probe | Local static/script/editor | source image is unpadded, shader-facing image is padded with `add_margins(...)`, `content_rect` crops source | Pass current baseline: `flow_foam_noise size=426x426`, source rect `256x256` | 2026-05-22 | Agent |
| Curve-only support fallback is exact | `curve_behavior_probe.gd` | Godot 4.6.3, Vulkan Forward+ | `flow_foam_noise.b = 0.0`, existing noise alpha, `dist_pressure.rg = (0.0, 0.0)` | Pass: `curve_only_zero_layers` support maxes `0.0`, noise alpha max `0.839215695858` | 2026-05-22 | Agent |
| No-layer default mode succeeds | `curve_behavior_probe.gd` | Godot 4.6.3, Vulkan Forward+ | valid flow map with reduced-detail warning and non-neutral vector stats | Pass: default zero-layer occupied `mag_avg=0.247090`, blank support, source kind `generated_curve_collision_modifiers_bake` | 2026-05-22 | Agent |
| Nonzero-layer no-hit default mode succeeds | `curve_behavior_probe.gd` | Godot 4.6.3, Vulkan Forward+ | valid flow map, hit count `0`, blank support fallback, non-neutral curve RG | Pass: default no-hit occupied `mag_avg=0.247090`, hit count `0`, blank support | 2026-05-22 | Agent |
| Collision support maps still work when hits exist | `curve_validation_task12_probe.gd` and screenshots | Godot 4.6.3, Vulkan Forward+ | foam/pressure/detail appears; RG remains curve baseline | Pass: `FlatColliderRiver` hit count `42926`; `BankHelperRiver` hit count `9674`, foam `0.0000..1.0000`, pressure `0.0000..0.8902`, occupied `mag_avg=0.247090`; debug screenshots show support data where helpers exist | 2026-05-22 | Agent |
| Legacy behavior remains available | `default_bake_stats_probe.gd -- legacy_collision_only` | Godot 4.6.3, Vulkan Forward+ | current collision-derived RG behavior is reproduced, including weak output for flat input | Pass: occupied `near_neutral=95.81%`, `mag_avg=0.008847` | 2026-05-22 | Agent |
| Flow vectors report useful stats | `Validate Data Textures` and bake output | Godot 4.6.3 logs | min/max/avg length and near-neutral percentage are printed | Pass current default and legacy diagnostics | 2026-05-22 | Agent |
| Flow Arrows neutral handling | Static shader scan plus Task 12 Flow Arrows screenshots | Godot 4.6.3, Vulkan Forward+ | neutral RG does not show confident arbitrary arrow direction; active curve arrows are visible and coherent | Pass local/screenshot: `CurvedNoColliderRiver` and `SeamCrossingCurveRiver` show dense aligned arrows; legacy weak-flow remains near-neutral by data stats | 2026-05-22 | Agent |
| Canonical validation scene exists | `curve_validation_scene_probe.gd` plus Task 12 load/reload | Godot 4.6.3, Vulkan Forward+ | named River fixtures are selectable and scene opens without parser errors | Pass: all named fixtures loaded, rebaked, saved, reloaded, and runtime-smoked | 2026-05-22 | Agent |
| Saved data reloads | Save, reload, and F6/runtime-style check | Godot 4.6.3, Vulkan Forward+ | `RiverBakeData` textures, metadata, and `valid_flowmap` survive reload | Pass: fresh-process reload reported `valid_flowmap=true` for all 6 rivers; `CurvedNoColliderRiver` signature mismatch resolved; runtime-style shader valid flags true; scene launch `--quit-after 2` exited cleanly | 2026-05-22 | Agent |
| Performance remains acceptable | Bake at `baking_resolution` 0, 2, and 4 | Godot 4.6.3, Vulkan Forward+, AMD Radeon RX 6800 XT | bake times recorded; no obvious runaway cost | Pass with note: curve-only/no-collider fixtures stayed under 1s at resolution 4; collision-support fixtures were noticeable at high resolution, about 18.4s to 24.9s | 2026-05-22 | Agent |

## Premise and Interpretation Checks

- Expected behavior that could look like a bug:
  - Current legacy collision bakes can produce neutral or flat RG when no useful collider pixels are detected.
  - Near-neutral vectors still have numeric angles, but current Flow Arrows suppress them instead of showing confident arbitrary direction.
  - In the legacy collision-only path, a river can visibly animate with fallback flow after generated data is invalidated, then look stationary after a flat generated map is rebaked.
- Scene geometry, stale resources, generated data, or editor/runtime state to rule out:
  - Bake helper colliders missing, on unselected layers, below the probe volume, or too uniform.
  - Stale serialized `RiverBakeData` whose source signature does not match current settings.
  - Debug view showing valid but near-neutral data rather than a shader failure.
- Evidence that would mean the user or agent is misreading the situation:
  - Non-neutral RG vector stats and valid collision hits are present, but visible water remains stationary.
  - The wrong generation mode is selected for the expected behavior.
  - The test scene is still using old generated resources after code changes.
- What the agent should say to the user if that evidence appears:
  - "The generated data is not neutral, so this result points away from the no-collider baseline issue. We should inspect shader/material force settings, debug view selection, and stale resource state before patching the bake path further."
- Quick falsifying check before patching:
  - Run `Generate Flow & Foam Map`, run `Validate Data Textures`, inspect Flow Pattern and Flow Arrows, and compare hit counts plus vector stats.

## Automated Checks

- Command or procedure:
  - Static scan for the current `bake_generation_behavior` baseline, any future generation-mode symbols after rebase, source metadata keys, source signature fields, and absence of default-mode directional collision RG blending.
  - GDScript parser/editor-load check if local Godot can run without sandbox crashes.
  - Unit-like image probe for curve baseline generation if practical.
  - `curve_behavior_probe.gd` for default zero-layer, default no-hit, curve-only zero-layer, and legacy zero-layer preflight behavior.
  - `curve_validation_scene_probe.gd` and `curve_validation_bake_probe.gd` for canonical scene setup and numeric bake sanity.
- Expected result:
  - Static scans show the required current and future symbols and no default-mode use of collision-derived RG as primary flow direction.
  - Parser/editor-load check reports no script parse errors.
  - Probe shows occupied source atlas texels decode to downstream `+V`, empty cells stay neutral, and padded dimensions match the current atlas layout.
- Agent limitation note:
  - Local checks may include static scans, parser checks, or headless editor-load probes when they work.
  - Do not treat local headless/editor-load checks as proof of visible editor interaction, shader visuals, bake output, or runtime behavior.

## Human-Assisted Validation

Use this by default for visible Godot editor checks, viewport interaction, scene running, gizmos, shader visuals, bake output, and runtime behavior. The agent may not be able to open or interact with Godot reliably.

When requesting this validation, the agent must put the exact request in the chat message so the user does not have to open this file to discover what to run.

- Request to user:
  - Open the canonical validation scene after implementation and run the checks below, then relay Output text, visible behavior, Godot version, renderer, and device details.
- Exact scene, command, or workflow to run:
  - Open `scenes/validation/curve_derived_river_flow_validation.tscn`.
  - Enable the Waterways plugin if needed.
  - For each named River fixture, run `River -> Generate Flow & Foam Map`, then `River -> Validate Data Textures`.
  - Inspect Flow Pattern and Flow Arrows debug views.
  - Save, reload, and run an F6/runtime-style check after at least one successful bake.
- Plugin state required:
  - Waterways plugin enabled.
- Console output or errors to relay back:
  - Any parser errors, bake warnings, hit counts, vector stats, save notices, and validation output.
- Screenshot or visible behavior to relay back:
  - Straight no-collider downstream motion.
  - Curved no-collider arrows following the river without seam flips.
  - Flat collider not erasing baseline direction.
  - Bank-helper foam/pressure/detail without destroyed RG direction.
  - Legacy collision comparison behavior.
- Godot version and renderer to relay back:
  - Godot version, renderer/backend, graphics device, and whether Godot Physics or Jolt is active if relevant.
- Expected result:
  - Curve-based modes produce valid, non-neutral downstream flow; collision detail is reduced only when helpers are absent or no hits are found.
- Failure signs:
  - No-collider curve-based bake fails preflight.
  - Occupied source region reports near-neutral RG.
  - Flow flips at UV2 column-continuation seams.
  - Default mode uses collision-derived RG as the only flow direction.
  - Saved data loses metadata or textures on reload.
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
- Ran by: Agent
- Godot version/renderer/device:
  - Godot 4.6.3 stable.
  - Vulkan 1.4.315, Forward+, AMD Radeon RX 6800 XT.
  - `APPDATA` and `LOCALAPPDATA` redirected to `.codex-research/godot_463_user_home/`.
- Command, scene, or workflow:
  - Loaded `scenes/validation/curve_derived_river_flow_validation.tscn`.
  - Ran `.codex-research/flow_map_direction_verification/curve_validation_task12_probe.gd -- rebake_save`.
  - Re-baked and validated `StraightNoColliderRiver`, `CurvedNoColliderRiver`, `FlatColliderRiver`, `BankHelperRiver`, `LegacyCollisionRiver`, and `SeamCrossingCurveRiver`.
  - Saved each `waterways_bakes/scenes_validation_curve_derived_river_flow_validation/*.river_bake.res` resource and `WaterSystem.water_system_bake.res`.
  - Ran `.codex-research/flow_map_direction_verification/curve_validation_task12_probe.gd -- reload_runtime` in a fresh Godot process.
  - Ran `.codex-research/flow_map_direction_verification/curve_validation_screenshot_probe.gd` and reviewed screenshots in `.codex-research/flow_map_direction_verification/task12_screenshots/`.
  - Ran `.codex-research/flow_map_direction_verification/curve_validation_task12_probe.gd -- performance`.
  - Ran `Godot_v4.6.3-stable_win64_console.exe --path . --quit-after 2 scenes/validation/curve_derived_river_flow_validation.tscn`.
- Output or parser errors:
  - No parser errors.
  - No runtime launch errors in the `--quit-after 2` smoke.
  - Expected warnings remained for flat-collider support softening and legacy near-neutral flow.
  - `Validate Data Textures` emitted missing `.import` warnings for generated textures stored as `.res::ImageTexture_*` subresources; the same textures remained readable and passed stats/reload/runtime checks.
- Stable result marker:
  - Re-bake/save pass ended with `TASK12_RESULT: rebake_save pass`.
  - Fresh-process reload/runtime pass ended with `TASK12_RESULT: reload_runtime pass` and `TASK12_RUNTIME_STYLE: rivers_valid=6`.
  - F6-style runtime scene launch exited with code `0`.
  - `CurvedNoColliderRiver` reloaded with `valid_flowmap=true`, `source_kind=generated_curve_only_bake`, fallback reason `curve_only`, occupied `near_neutral=0.00%`, and blank support maps.
  - `SeamCrossingCurveRiver` reloaded with `valid_flowmap=true`, `source_kind=generated_curve_only_bake`, occupied `near_neutral=0.00%`, unused `near_neutral=100.00%`, and blank support maps.
  - `FlatColliderRiver` reloaded with hit count `42926`, fallback `false`, occupied `mag_avg=0.247090`, foam `0.2471..0.2471`, distance R `0.9725..1.0000`, pressure G `0.2471..0.2471`.
  - `BankHelperRiver` reloaded with hit count `9674`, fallback `false`, occupied `mag_avg=0.247090`, foam `0.0000..1.0000`, distance R `0.0000..1.0000`, pressure G `0.0000..0.8902`.
  - `LegacyCollisionRiver` reloaded with `source_kind=generated_spline_collision_bake`, occupied `near_neutral=95.81%`, `mag_avg=0.008847`, preserving weak legacy behavior.
  - WaterSystem reload sampling passed for all 6 rivers; alpha-covered flow `mag_avg=0.443761`, `near_neutral=10.63%`.
  - Flow Pattern and Flow Arrows screenshots for `CurvedNoColliderRiver` and `SeamCrossingCurveRiver` showed coherent visible patterns/arrows without an obvious seam flip.
  - Performance timings:
    - Resolution 0: no-collider/curve-only `89..100ms`; collision-support/legacy `665..673ms`; seam `96ms`.
    - Resolution 2: no-collider/curve-only `133..137ms`; `FlatColliderRiver` `1812ms`; `BankHelperRiver` `2029ms`; `LegacyCollisionRiver` `1639ms`.
    - Resolution 4: no-collider/curve-only `886..944ms`; `FlatColliderRiver` `21451ms`; `BankHelperRiver` `24852ms`; `LegacyCollisionRiver` `18393ms`.
- Pass/partial/fail:
  - Pass for rebake/save, data-texture vector/support data, fresh reload, runtime-style serialized use, F6-style launch smoke, screenshots, and performance recording.
  - Partial only for true human-assisted live editor interaction, because the editor menu was not clicked manually and time-based animation was not watched by a person.
- Notes or follow-up:
  - Fix or document the generated `.res::ImageTexture_*` `.import` warning in `Validate Data Textures`.
  - Transparency/material-control behavior remains a separate shader/material follow-up.

Recorded result:

- Date: 2026-05-22
- Ran by: User/Agent
- Godot version/renderer/device:
  - User-visible editor/runtime check; exact renderer/device not recorded in this note.
- Command, scene, or workflow:
  - User opened `scenes/validation/curve_derived_river_flow_validation.tscn`.
  - User reported all non-legacy rivers working.
  - User reported legacy collision fixture was buried by visible helper geometry and runtime water appeared red while the 3D viewport appeared blue.
  - Patched validation fixture script to explicitly apply the blue water albedo at editor and runtime.
  - Lowered flat/legacy visible preview slabs while preserving collision shape placement for baking.
- Output or parser errors:
  - Local shell could not run Godot because `godot` was not on PATH in this session.
- Stable result marker:
  - Non-legacy visible fixtures passed user inspection before the patch.
- Pass/partial/fail:
  - Partial; legacy and runtime tint need a quick visible recheck after the scene patch.
- Notes or follow-up:
  - Reopen the scene or toggle `refresh_fixtures`, then re-run the legacy visual check and runtime/F6 check.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device:
  - Godot 4.6.3 stable.
  - Non-headless bake probes used Vulkan 1.4.315, Forward+, AMD Radeon RX 6800 XT.
  - Headless scene-load probe used Godot 4.6.3 stable.
- Command, scene, or workflow:
  - Patched `bake_generation_behavior` to accept `curve_only`.
  - Patched River bake preflight so only legacy collision-only requires nonzero `baking_raycast_layers`.
  - Patched `_generate_flowmap()` so curve-based zero-layer and no-hit bakes use downstream RG plus exact blank support maps.
  - Added `generated_curve_collision_modifiers_bake` and `generated_curve_only_bake`.
  - Added `scenes/validation/curve_derived_river_flow_validation.tscn`.
  - Ran `flow_vector_stats_probe.gd`.
  - Ran `default_bake_stats_probe.gd`.
  - Ran `default_bake_stats_probe.gd -- legacy_collision_only`.
  - Ran `curve_behavior_probe.gd`.
  - Ran `curve_validation_scene_probe.gd`.
  - Ran `curve_validation_bake_probe.gd`.
  - `APPDATA` and `LOCALAPPDATA` were redirected to `.codex-research/godot_463_user_home/`.
- Output or parser errors:
  - No parser errors in passing runs.
  - Expected warnings remained for legacy near-neutral output, no-hit fallback reduced detail, and saturated support softening in flat collider cases.
  - The canonical scene load emitted the expected `No WaterSystem map!` warning because no system map is pre-baked into the scene.
- Stable result marker:
  - Default baseline still passes: occupied `mag_avg=0.247090`, unused `near_neutral=100.00%`, WaterSystem alpha-covered `mag_avg=0.294198`.
  - Legacy still passes: occupied `near_neutral=95.81%`, `mag_avg=0.008847`, unused `near_neutral=100.00%`.
  - Default zero-layer: source kind `generated_curve_collision_modifiers_bake`, support fallback reason `baking_raycast_layers_zero`, occupied `mag_avg=0.247090`, blank support maxes `0.0`, noise alpha max `0.839215695858`.
  - Default no-hit: support fallback reason `no_collision_hits`, hit count `0`, occupied `mag_avg=0.247090`, blank support maxes `0.0`.
  - Curve-only zero-layer: source kind `generated_curve_only_bake`, support fallback reason `curve_only`, occupied `mag_avg=0.247090`, blank support maxes `0.0`.
  - Legacy zero-layer: preflight failed as expected.
  - Canonical scene load: named fixtures loaded; seam fixture step count `15`.
  - Canonical scene bake: `FlatColliderRiver` hit count `42926`, `BankHelperRiver` hit count `9674`, `LegacyCollisionRiver` source kind `generated_spline_collision_bake`.
- Pass/partial/fail:
  - Pass for automated/local behavior, metadata, source-kind, fallback, and canonical scene setup.
  - Partial overall because visible editor, save/reload, runtime, and performance validation remain human-assisted/unrun.
- Notes or follow-up:
  - Ask the user to visibly validate `scenes/validation/curve_derived_river_flow_validation.tscn`.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device:
  - Godot 4.6.3 stable.
  - Default/legacy bake probes used Vulkan 1.4.315, Forward+, AMD Radeon RX 6800 XT.
- Command, scene, or workflow:
  - Read required handoff, workflow, regression, feature, and active add-on files.
  - Ran `flow_vector_stats_probe.gd` headless.
  - Ran `godot_scene_load_smoke.gd` headless.
  - Ran `default_bake_stats_probe.gd` with the real renderer.
  - Ran `default_bake_stats_probe.gd -- legacy_collision_only` with the real renderer.
  - `APPDATA` and `LOCALAPPDATA` were redirected to `.codex-research/godot_463_user_home/`.
- Output or parser errors:
  - No parser errors in passing runs.
  - Default bake emitted expected support-softening warnings for saturated flat foam and pressure support.
  - Legacy bake emitted the expected mostly-near-neutral occupied-flow warning.
- Stable result marker:
  - Scene load: `river_found=true`.
  - Default River occupied source tiles: `active_mag_gt_0.020=43520`, `near_neutral=0.00%`, `mag_avg=0.247090`, `avg_vec=(-0.0039, 0.2471)`.
  - Default River unused source tiles: `active_mag_gt_0.020=0`, `near_neutral=100.00%`, `mag_avg=0.005546`.
  - Default WaterSystem alpha-covered flow: `active_mag_gt_0.020=84992`, `near_neutral=0.00%`, `mag_avg=0.294198`, `avg_vec=(-0.0039, 0.2944)`.
  - Legacy River occupied source tiles: `active_mag_gt_0.020=1824`, `near_neutral=95.81%`, `mag_avg=0.008847`.
  - Legacy River unused source tiles: `active_mag_gt_0.020=0`, `near_neutral=100.00%`, `mag_avg=0.005546`.
  - Legacy WaterSystem alpha-covered flow: `active_mag_gt_0.020=17004`, `near_neutral=79.99%`, `mag_avg=0.026898`.
  - Static inspection: `_get_bake_preflight_failures(...)` still rejects `baking_raycast_layers == 0` unconditionally.
- Pass/partial/fail:
  - Pass for current default downstream-baseline foundation, unused atlas neutrality, legacy comparison, scene load, and WaterSystem stats.
  - Current fail/blocker for zero-layer authoring: preflight still rejects `baking_raycast_layers == 0`.
  - Unrun for true `Curve Only`, canonical curved/seam fixture, bank-helper fixture, save/reload across new behaviors, runtime across new behaviors, and performance.
- Notes or follow-up:
  - This was a docs/testing session only. No active add-on code changes were made.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device: Not applicable.
- Command, scene, or workflow: Research and document review only.
- Output or parser errors: None.
- Visible result, if applicable: Not run.
- Stable result marker: `preliminary_research.md` supports the design direction; implementation validation remains unrun.
- Pass/partial/fail: Partial.
- Notes or follow-up: Implementation tasks must still run automated and human-assisted validation.

## Historical Results Archive

None yet.

## Shader Checks

- Shader/material path:
  - `addons/waterways/shaders/river.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
- Renderer backend:
  - Human-assisted validation should report the active renderer.
- Expected result:
  - `river.gdshader` behavior remains unchanged for valid maps.
  - Flow Arrows do not show confident arbitrary direction for near-zero vectors.
- Failure signs:
  - Main river shader changed without spec/plan revision.
  - Neutral RG still appears as a stable directional arrow.

## Editor Workflow Check

Procedure:

1. Open `scenes/validation/curve_derived_river_flow_validation.tscn`.
2. Select each named River fixture.
3. Run `River -> Generate Flow & Foam Map`.
4. Run `River -> Validate Data Textures`.
5. Switch through Flow Pattern and Flow Arrows debug views.
6. Save the scene, reload it, and confirm generated data remains valid.

Expected result:

- The editor bake succeeds for curve-based modes without requiring colliders.
- Output messages distinguish reduced collision detail from failed flow generation.
- Vector stats are printed and meaningful.

Failure signs:

- Preflight failure in curve-only/no-layer default mode.
- Stale generated data remains valid after mode changes.
- Missing metadata, invalid textures, or parser errors.

## Visual Test Scene

Scene path:

- `scenes/validation/curve_derived_river_flow_validation.tscn`

Purpose:

- Prove the new bake path, not just shader consumption of hand-authored maps.

Expected visual result:

- `StraightNoColliderRiver`: visible downstream motion.
- `CurvedNoColliderRiver`: arrows follow the river strip without flips.
- `FlatColliderRiver`: uniform collider input does not erase downstream flow.
- `BankHelperRiver`: foam/pressure/detail appears without destroying baseline direction.
- `LegacyCollisionRiver`: legacy collision-derived behavior can be compared.
- Seam fixture: no flow flip at UV2 column-continuation boundaries.

Failure signs:

- Stationary no-collider flow.
- Seam flip or smeared empty atlas cell data.
- Collision support output overwrites default curve RG.

Suggested controls or debug views:

- Flow Pattern.
- Flow Arrows.
- Data texture validation output.

## Bake Output Check

Scenario:

- Curve-based bakes with no colliders, zero matching layers, nonzero layers with zero hits, flat/uniform collider coverage, and bank-helper colliders.

Expected generated outputs:

- Flow: non-neutral local downstream `+V` in occupied source-region texels for curve-based modes.
- Foam: blank `B = 0.0` in no-collider fallback; collision-derived where helpers produce useful hits.
- Distance/pressure: blank `RG = (0.0, 0.0)` in no-collider fallback; collision-derived support maps where helpers produce useful hits.
- Height/alpha: no height change; alpha/noise uses existing tiled phase/noise path.
- Metadata: generation mode, source kind, hit counts/percentages, vector stats, content rect, texture sizes, UV2 sides, and source signature.

Failure signs:

- Wrong RG direction, neutral occupied texels, bad padding, stale texture, missing metadata, or source kind mismatch.

## Runtime API Check

Procedure:

- After a successful editor bake, save and reload the scene, then run an F6/runtime-style check and inspect whether the River uses serialized `RiverBakeData`.

Expected result:

- Runtime shader consumption uses saved textures and uniforms without editor-only collision helpers.

Failure signs:

- Runtime falls back to invalid flow, loses textures, or requires live editor bake helpers.

## Performance Check

Scenario:

- Bake the validation scene at low, medium, and highest supported `baking_resolution`.

Budget or target:

- No formal budget is set yet; record measured times and flag obvious runaway costs or editor stalls.

How to measure:

- Use Output timing if added, editor-observed timing, or a simple timing probe around bake execution.

## Artifact Hygiene Check

- Scratch project or temporary folder used: `.codex-research/flow_map_direction_verification/`.
- Active scripts/resources mirrored into scratch before validation: Task 12 added local probe scripts in `.codex-research/flow_map_direction_verification/`.
- Generated bakes/resources created: canonical scene bakes in `waterways_bakes/scenes_validation_curve_derived_river_flow_validation/` were refreshed intentionally.
- Files or folders that must be excluded from packaging: `.codex-research/` screenshots/probes and `.godot/` editor cache unless explicitly needed for validation artifact review.
- Files or folders safe to delete now: `.codex-research/flow_map_direction_verification/task12_screenshots/` is disposable after results are recorded.

## Extension Check

Custom content scenario:

- Imported/manual flow maps and existing legacy generated resources.

Expected result:

- Imported/manual maps keep the same packed RG channel contract.
- Existing `generated_spline_collision_bake` resources remain readable as legacy data.

Failure signs:

- Existing resources fail to load, are silently migrated, or are reinterpreted as curve-generated data without metadata.

## Manual Review Checklist

- [ ] Acceptance criteria are satisfied.
- [ ] Likely false premises or expected-behavior explanations were raised with the user before extra implementation work.
- [x] Human-assisted Godot/editor/test results are recorded when the agent could not run them directly.
- [ ] Active code uses Godot 4.6+ APIs and avoids obsolete Godot 3 APIs.
- [ ] Editor-only and runtime-safe boundaries are preserved.
- [ ] Generated resources and metadata are explicit and inspectable.
- [ ] Visual output matches the spec.
- [x] Flow direction, seams, foam, masks, and bounds are checked visually.
- [x] Runtime sampling/API behavior matches generated data.
- [x] Performance-sensitive paths have been checked.
- [ ] Known limitations are documented.
