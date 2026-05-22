# Validation: Two-Phase Flow Foundation

## What Must Be Proven

- The active river, river debug, and lava shaders preserve the documented Waterways two-phase `FlowUVW` contract.
- Data texture validation can distinguish bad input data from shader behavior, including alpha phase/noise flatness or variation.
- Visible Godot validation proves motion quality; static scans and shader compilation are not enough.
- Debug views diagnose the same conceptual flow behavior as the default river shader, with intentional differences documented.
- The feature does not add shader samples, bake passes, GPU readbacks, generated textures, or public runtime APIs.

## Current Validation Snapshot

- Overall status: Current River baseline validated for this preservation slice. Static shader guardrails still pass, current generated River maps have been rebaked and validated, a visible Forward+ runtime probe shows Flow Pattern frames changing at default, slow, and high `flow_speed`, and bounded F6-style scene-launch smoke checks pass in Forward+, Mobile, and Compatibility. A hand-clicked editor/F6 mismatch was traced to validation-scene defaults forcing Flow Pattern and synthetic validation maps at runtime; after the scene default fix, the user confirmed F6 now preserves the saved bake and normal shader. Lava visual validation is explicitly deferred and remains unvalidated for this feature closeout.
- Last automated pass: `python spec-driven/features/two-phase-flow/check_shader_drift.py` passed 54 checks on 2026-05-22.
- Last generated-map validation: 2026-05-22 current-baseline `RIVER_DATA_TEXTURE_TEST` from `TwoPhaseFlowRiver` reports `source_kind=generated_curve_collision_modifiers_bake`, occupied active vectors, neutral unused tiles, and varied alpha.
- Latest visible attempt: 2026-05-22 agent-run visible Forward+ console/runtime probe opened the validation scene through Godot 4.6.3, captured debug-view screenshots, and measured Flow Pattern frame deltas over 10 seconds at default, slow, and high speeds. Later 2026-05-22 bounded scene-launch smoke checks loaded the same validation scene in Forward+, Mobile, and Compatibility without warnings or shader/runtime errors.
- Highest-risk unproven behavior: none for the River preservation closeout. Lava visual validation is explicitly deferred/unvalidated by user decision. Mobile and Compatibility have scene-launch smoke coverage, not full hand-inspected debug-view validation.
- Known local check or environment caveat: `project.godot` and `scenes/validation/two_phase_flow_validation.tscn` exist. Use visible Godot 4.6.3 Forward+ for final validation; in sandboxed automation, route `APPDATA` and `LOCALAPPDATA` to an ignored workspace folder so Godot can create editor/cache data.

## Local Godot 4.6.3 Paths

- GUI/editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`
- Console/scripted probes: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
- Workspace: `C:\Users\pc\Documents\GitHub\Godot 4 Waterways`

## Current Validation Matrix

| Requirement or risk | Check/probe/scene | Environment | Expected marker/result | Last result | Date | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| `FlowUVW` contract exists in built-in shaders | `check_shader_drift.py` | Local static | River, debug, and lava define expected helper signature and core expressions | Pass: drift guard included these checks | 2026-05-22 | Agent |
| Alpha phase/noise participates in time | `check_shader_drift.py` | Local static | All three shader paths use `TIME * flow_speed + flow_foam_noise.a` | Pass: drift guard included these checks | 2026-05-22 | Agent |
| Packed RG flow decode preserved | `check_shader_drift.py` | Local static | Built-in paths decode `(flow - 0.5) * 2.0` | Pass: drift guard included these checks | 2026-05-22 | Agent |
| Required debug modes remain available | `check_shader_drift.py` over debug shader and menu | Local static | Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix exist | Pass: drift guard included shader and menu checks | 2026-05-22 | Agent |
| Debug steepness scale classified | Review decision plus drift guard | Docs/static | `* 8.0` debug scale is intentional or corrected under spec update | Pass: classified as intentional debug-only diagnostic amplification | 2026-05-22 | Agent |
| Current generated River map baseline established | `River -> Generate Flow & Foam Map`, then `River -> Validate Data Textures` output | Visible Forward+ runtime probe | `RIVER_DATA_TEXTURE_TEST` reports current source kind, decoded vector stats, near-neutral count, active-vector count, and alpha min/max/range/state | Pass/partial: current explicit bake reports `source_kind=generated_curve_collision_modifiers_bake`, occupied active vectors, neutral unused tiles, and varied alpha; later hand-clicked F6 exposed a scene-helper default issue that is now fixed | 2026-05-22 | Agent |
| Alpha variation data check exists | `River -> Validate Data Textures` output | Visible Forward+ runtime probe | `RIVER_DATA_TEXTURE_TEST` reports alpha min/max/range/state | Pass: current map reports alpha_min=0.0000 alpha_max=0.7216 alpha_range=0.7216 alpha_state=varied | 2026-05-22 | Agent |
| Validation fixture available | File/project scan and selected source workflow | Local/source workspace | Real `project.godot` and scene/workflow available | Pass: `project.godot` and `scenes/validation/two_phase_flow_validation.tscn` exist | 2026-05-22 | Agent |
| Flow Pattern hides reset | Visible Godot runtime probe plus captured frames | Godot 4.6.3 Forward+ | 10 seconds of continuous motion without full-surface popping or synchronized pulsing | Pass/partial: default/slow/high frame deltas confirm active runtime motion; no full-surface pop was visible in captured frames, but this was not a hand-watched editor preview | 2026-05-22 | Agent |
| Flow Arrows agree with perceived motion | Visible Godot screenshot inspection | Godot 4.6.3 Forward+ | Arrows align with Flow Pattern on bends, straight sections, and neutral regions | Pass/partial: arrows rendered clearly and align downstream with the current map; dynamic editor comparison remains useful | 2026-05-22 | Agent |
| Flow Strength bounded and useful | Visible Godot screenshot inspection | Godot 4.6.3 Forward+ | Strength responds to modifiers without saturating everywhere in ordinary validation geometry | Pass/partial: Flow Strength rendered nonblank with visible variation; full parameter sweep remains unrun | 2026-05-22 | Agent |
| Foam Mix coherent with river motion | Visible Godot screenshot inspection | Godot 4.6.3 Forward+ | Foam does not appear detached from flow direction | Pass/partial: Foam Mix rendered nonblank and spatially coherent; animated foam comparison remains unrun | 2026-05-22 | Agent |
| Forward+/Mobile/Compatibility scene launch | Bounded F6-style scene launch with `--quit-after` | Godot 4.6.3 Forward+, Forward Mobile, Compatibility | Validation scene loads and runs without shader/runtime errors | Pass: Forward+ ~60 FPS, Mobile ~59 FPS, Compatibility ~31-32 FPS; no warnings/errors after removing stale external bake-resource UID from the scene reference | 2026-05-22 | Agent |
| F6 uses saved validation bake and normal shader | Hand-clicked user report plus runtime state probe | Godot 4.6.3 Forward+ | F6 should preserve the saved `.river_bake.res` maps and start with the normal river shader unless a debug view is intentionally selected | Pass: user reported F6 reverted to Flow Pattern and noisy synthetic validation maps; root scene now defaults `auto_refresh_maps=false` and `startup_debug_view=0`; runtime state probe confirms no debug override and saved bake textures; user confirmed the fix resolved F6 behavior | 2026-05-22 | User + Agent |
| Lava variant still uses two-phase basis | Human-assisted visible Godot | Godot 4.6.3 Forward+ | Lava animation is continuous or intentional differences are documented | Deferred/unvalidated by user decision for this preservation slice; static drift guard still covers lava `FlowUVW` contract | 2026-05-22 | User |
| No performance scope creep | Manual/static review | Local static | No new samples, bake passes, readbacks, generated textures, draw calls, or public APIs | Pass so far: no shader math, shader samples, bake passes, generated textures, or public APIs changed | 2026-05-22 | Agent |

## Premise and Interpretation Checks

- Expected behavior that could look like a bug:
  - repeated normal texture patterns
  - motion that becomes visually poor at extreme `flow_speed` or force settings
  - neutral areas that correctly show little or no flow
  - flat alpha creating synchronized resets even though `FlowUVW` is intact
- Scene geometry, stale resources, generated data, or editor/runtime state to rule out:
  - unsaved scenes with in-memory bake data
  - stale `.river_bake.res` resources
  - pre-2026-05-22 generated maps that still carry the old near-neutral RG baseline
  - missing or unreadable `flow_foam_noise` or `dist_pressure`
  - bad import settings for user-supplied data maps
  - validation geometry that is too flat or uniform to show direction and reset artifacts
- Evidence that would mean the user or agent is misreading the situation:
  - `RIVER_DATA_TEXTURE_TEST` reports import/readability or neutral-flow failures
  - decoded flow-vector statistics show the current map is still mostly neutral before judging shader motion
  - Noise Map shows flat alpha when the reported artifact is synchronized pulsing
  - Flow Arrows and Flow Pattern agree, but material settings are extreme
- What the agent should say if that evidence appears:
  - "The shader may not be the first suspect here. The data/debug views point to stale, flat, or imported map input. Let's fix or rebake that before editing `FlowUVW`."
- Quick falsifying check before patching:
  - In a visible Godot 4.6.3 scene with current generated maps, copy the full decoded-vector and alpha validation Output, then switch to Flow Pattern and watch at least 10 seconds. Obvious full-surface reset popping, synchronized pulsing despite varied alpha, stuck flow with active vectors, or directional disagreement with Flow Arrows justifies deeper shader investigation.

## Automated Checks

Command or procedure:

- Run `python spec-driven/features/two-phase-flow/check_shader_drift.py`. The script verifies:
  - `FlowUVW(vec2 uv_in, vec2 flowVector, vec2 jump, vec3 tiling, float time, bool flowB)` exists in river, river debug, and lava shaders.
  - `phaseOffset` is `0.0` or `0.5`.
  - `progress = fract(time + phaseOffset)`.
  - UV displacement uses `progress - 0.5`.
  - blend weight uses `1.0 - abs(1.0 - 2.0 * progress)`.
  - shader time uses `TIME * flow_speed + flow_foam_noise.a`.
  - RG decode uses `(flow - 0.5) * 2.0`.
  - primary jump is `vec2(0.24, 0.2083333)`.
  - secondary detail jump is `vec2(0.20, 0.25)` where applicable.
  - River debug shader and menu still expose Noise Map, Flow Pattern, Flow Arrows, Flow Strength, and Foam Mix.

Expected result:

- A stable pass/fail output that names each checked file and any intentional differences. Current result: 54 passed, 0 failed on 2026-05-22.

Agent limitation note:

- Local checks may include static scans, parser checks, or headless editor-load probes when they work.
- Do not treat local headless/editor-load checks as proof of visible editor interaction, shader visuals, bake output, or runtime behavior.

## Human-Assisted Validation

Use this request with the local validation project. Use the visible editor because headless/editor-load checks are not proof of shader motion.

Request to user:

Please open `C:\Users\pc\Documents\GitHub\Godot 4 Waterways` with Godot 4.6.3 GUI path `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe` and the Waterways plugin enabled. Use Forward+ first. Open `scenes/validation/two_phase_flow_validation.tscn`. Select `TwoPhaseFlowRiver`, run `River -> Generate Flow & Foam Map` or confirm the existing bake is current, then run `River -> Validate Data Textures`. Copy the full `RIVER_DATA_TEXTURE_TEST` Output line, including source kind, decoded flow-vector statistics, `active_mag_gt_0.020`, `near_neutral`, `mag_avg`, `alpha_min`, `alpha_max`, `alpha_range`, and `alpha_state`. Then switch `River -> Debug View` through Noise Map, Flow Pattern, Flow Arrows, Flow Strength, and Foam Mix. Watch Flow Pattern for at least 10 seconds at default, slow, and high `flow_speed`. Report the Godot version, renderer, GPU/device, exact scene path, any material settings changed, Output warnings/errors, and whether motion was continuous or showed popping, pulsing, stuck flow, seam artifacts, or direction disagreement with arrows. If editor preview still appears frozen, run the scene with F6 and record whether runtime motion differs. Use console path `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe` only for scripted probes or for capturing Output.

Exact scene, command, or workflow to run:

- Preferred: `scenes/validation/two_phase_flow_validation.tscn`.
- Fallback: `scenes/validation/waterways_authoring_smoke_validation.tscn` for River debug views and `scenes/validation/lava_material_validation.tscn` for lava, if those source fixtures are restored.
- Plugin state required: Waterways plugin enabled.
- Console output or errors to relay back: full current-baseline `RIVER_DATA_TEXTURE_TEST` line, including decoded vector and alpha statistics, plus any shader/import/bake warnings.
- Screenshot or visible behavior to relay back: debug views, especially Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix; screenshot or clip if available.
- Godot version and renderer to relay back: Godot version, Forward+/Mobile/Compatibility, GPU/device, OS if easy.

Expected result:

- Flow Pattern animates continuously without obvious full-surface reset popping or synchronized pulsing.
- Flow Arrows agree with perceived movement direction.
- Flow Strength responds to settings without saturating everywhere in ordinary geometry.
- Noise Map explains whether alpha is flat or varied.
- Foam Mix remains coherent with flow direction.
- Lava uses the same two-phase basis, or differences are intentionally documented.

Failure signs:

- full-surface pulse or reset pop
- Flow Pattern stuck or moving opposite to arrows
- Flow Arrows rotating unexpectedly at seams
- Flow Strength saturated everywhere in ordinary validation geometry
- flat alpha paired with visible synchronized reset artifacts
- lava silently diverging from the preserved helper behavior

Result recording format:

- Date:
- Ran by:
- Godot version/renderer/device:
- Scene path:
- Plugin enabled:
- Output or parser errors:
- `RIVER_DATA_TEXTURE_TEST` output:
- Material settings changed:
- Visible result:
- Pass/partial/fail:
- Screenshots or clips:

## Recorded Results

Recorded result:

- Date: 2026-05-22
- Ran by: User decision
- Godot version/renderer/device: not applicable
- Scene path: not applicable
- Command, scene, or workflow: lava visual validation was considered after River validation passed and was explicitly deferred for this feature closeout.
- Output or parser errors: not applicable
- Visible result: not run
- Pass/partial/fail: Deferred/unvalidated. Lava remains covered by the static drift guard, but no current-baseline visible lava evidence is claimed.
- Notes or follow-up: this deferral is intentional and does not justify shader-math changes.

Recorded result:

- Date: 2026-05-22
- Ran by: User report, then Agent verification
- Godot version/renderer/device: Godot 4.6.3-stable official; Forward+; Vulkan 1.4.315; AMD Radeon RX 6800 XT; Windows for the agent verification
- Scene path: `scenes/validation/two_phase_flow_validation.tscn`
- Plugin enabled: yes, via `project.godot`
- Command, scene, or workflow: user baked Flow & Foam maps for `TwoPhaseFlowRiver`, saved the scene, switched Debug View back to normal, then ran F6. Agent inspected the validation scene defaults and ran a runtime state probe plus bounded scene launch.
- Output or parser errors: no shader/runtime errors in the agent scene launch.
- Visible result: before the fix, the editor viewport showed the normal water shader after the user's bake, but F6 reverted to Flow Pattern and did not appear to use the generated foam/flow map; it appeared distorted and noisy.
- Cause: validation scene runtime setup was not preserving the saved editor state. `startup_debug_view = 6` forced Flow Pattern on F6, and `auto_refresh_maps` defaulted true, allowing the validation helper to replace the saved generated bake with synthetic validation images.
- Fix: `scenes/validation/two_phase_flow_validation.gd` now defaults `auto_refresh_maps=false` and only reapplies fixed validation material defaults when auto-refresh is enabled; `scenes/validation/two_phase_flow_validation.tscn` now sets `startup_debug_view=0`.
- Agent verification: runtime state probe reported `auto_refresh_maps=false`, `startup_debug_view=0`, `river_debug_view=0`, `debug_override_active=false`, `matches_current_source=true`, and both runtime textures coming from `res://waterways_bakes/scenes_validation_two_phase_flow_validation/TwoPhaseFlowRiver.river_bake.res`.
- `RIVER_DATA_TEXTURE_TEST` output: same current generated-bake line as the 2026-05-22 current baseline, with occupied active vectors, neutral unused tiles, and varied alpha.
- Pass/partial/fail: Pass. Automated F6 state matches the intended saved-bake/normal-shader setup, and the user confirmed the fixed scene resolved the F6 mismatch.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device: Godot 4.6.3-stable official; Forward+; Vulkan 1.4.315; AMD Radeon RX 6800 XT; Windows
- Godot executable paths: GUI `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`; console `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
- Scene path: `scenes/validation/two_phase_flow_validation.tscn`
- Plugin enabled: yes, via `project.godot`
- Command, scene, or workflow: visible Forward+ console/runtime probe loaded the scene, selected `TwoPhaseFlowRiver` by path, ran the River bake path, persisted `res://waterways_bakes/scenes_validation_two_phase_flow_validation/TwoPhaseFlowRiver.river_bake.res`, then reloaded the saved bake and rendered debug views
- Output or parser errors: none in the final current-baseline run. Earlier headless bake failed at the render-backed flow-pressure filter and was not used as current visual evidence.
- `RIVER_DATA_TEXTURE_TEST` output: `flow_foam_noise size=358x358; flow_foam_noise source=generated/resource-owned source_kind=generated_curve_collision_modifiers_bake; flow_foam_noise closest_neutral_rg=(0.4980, 0.4980) pixel=(255,204); flow_foam_noise source_rect pixels=65536 active_mag_gt_0.020=60180 near_neutral=8.17% mag_min=0.005546 mag_median=0.247090 mag_avg=0.227350 mag_max=0.247090 avg_vec=(-0.0039, 0.2266) range_rg=(0.4980..0.4980, 0.4980..0.6235); flow_foam_noise occupied_tiles pixels=60180 active_mag_gt_0.020=60180 near_neutral=0.00% mag_min=0.247090 mag_median=0.247090 mag_avg=0.247090 mag_max=0.247090 avg_vec=(-0.0039, 0.2471) range_rg=(0.4980..0.4980, 0.6235..0.6235); flow_foam_noise unused_tiles pixels=5356 active_mag_gt_0.020=0 near_neutral=100.00% mag_min=0.005546 mag_median=0.005546 mag_avg=0.005546 mag_max=0.005546 avg_vec=(-0.0039, -0.0039) range_rg=(0.4980..0.4980, 0.4980..0.4980); flow_foam_noise alpha_min=0.0000 alpha_max=0.7216 alpha_range=0.7216 alpha_state=varied samples=14400; dist_pressure size=358x358; dist_pressure source=generated/resource-owned source_kind=generated_curve_collision_modifiers_bake`
- Material settings changed: validation scene runtime defaults applied `flow_speed=2.5`, `flow_base=0.45`, `flow_distance=1.0`, `flow_pressure=1.5`, `flow_max=4.0`, `uv_scale=(2,2,1)`; Flow Pattern timing also tested slow `flow_speed=0.35` and high `flow_speed=6.0`
- Visible result: Noise Map, Flow Pattern, Flow Arrows, Flow Strength, and Foam Mix rendered nonblank in Forward+. Flow Arrows aligned downstream with active occupied vectors; Flow Strength showed bounded variation rather than an all-flat output; Foam Mix rendered spatially coherent.
- Flow Pattern timing: default `flow_speed=2.5` total average delta `0.100065`, slow `flow_speed=0.35` total average delta `0.097431`, high `flow_speed=6.0` total average delta `0.099568`; each speed changed over the 10-second window, so runtime Flow Pattern was not stuck.
- Pass/partial/fail: Pass for current River Forward+ runtime/F6-style validation. A later pre-fix hand-clicked editor/F6 pass exposed a validation-scene helper mismatch; after the scene default fix, the user confirmed F6 now matches the intended saved-bake/normal-shader behavior. Lava is explicitly deferred/unvalidated. Mobile and Compatibility have later scene-launch smoke coverage.
- Screenshots or clips: ignored local screenshots under `spec-driven/screenshots/two-phase-flow-current-baseline/`.
- Notes or follow-up: no `FlowUVW` change is justified from this evidence. The current generated map has active downstream RG in occupied tiles, neutral unused tiles, and varied alpha. `Validate Data Textures` was also adjusted to classify generated `.river_bake.res` subtextures as generated/resource-owned and include `source_kind`.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device: Godot 4.6.3-stable official; Forward+, Forward Mobile, and Compatibility; AMD Radeon RX 6800 XT; Windows
- Scene path: `scenes/validation/two_phase_flow_validation.tscn`
- Plugin enabled: yes, via `project.godot`
- Command, scene, or workflow: bounded F6-style scene launches with `--quit-after 180` after redirecting `APPDATA` and `LOCALAPPDATA` into `.codex-research/godot-user`
- Output or parser errors: none after removing the stale invalid UID from the validation scene's external reference to `TwoPhaseFlowRiver.river_bake.res`
- Stable result marker: Forward+ launched at about 60 FPS; Forward Mobile launched at about 59 FPS; Compatibility launched at about 31-32 FPS
- Visible result, if applicable: not hand-inspected; this was a renderer scene-launch smoke check only
- Pass/partial/fail: Pass for renderer smoke; lava visual validation is explicitly deferred/unvalidated
- Notes or follow-up: this check does not replace the Forward+ debug-view motion probe or human editor-menu validation. It only confirms the validation scene and current shaders load and run across the required renderer families.

Recorded result:

- Date: 2026-05-22
- Ran by: Agent
- Godot version/renderer/device: not applicable
- Command, scene, or workflow: `python spec-driven/features/two-phase-flow/check_shader_drift.py`
- Output or parser errors: none
- Visible result, if applicable: not run
- Stable result marker: 54 passed, 0 failed; `FlowUVW`, alpha time offset, RG decode, jump constants, documented steepness scales, debug shader modes, and River menu entries found in active files
- Pass/partial/fail: Partial
- Notes or follow-up: static guard still passes after the generated-map behavior rebase, but visible Godot validation against current generated maps is still required.

Recorded result:

- Date: 2026-05-21
- Ran by: Agent
- Godot version/renderer/device: not applicable
- Command, scene, or workflow: `python spec-driven/features/two-phase-flow/check_shader_drift.py`
- Output or parser errors: none
- Visible result, if applicable: not run
- Stable result marker: 54 passed, 0 failed; `FlowUVW`, alpha time offset, RG decode, jump constants, documented steepness scales, debug shader modes, and River menu entries found in active files
- Pass/partial/fail: Partial
- Notes or follow-up: historical static guard result. It predates the current generated River map baseline and decoded vector diagnostics, so it cannot close visible validation.

Recorded result:

- Date: 2026-05-21
- Ran by: Agent
- Godot version/renderer/device: not applicable
- Command, scene, or workflow: code review of `River -> Validate Data Textures`
- Output or parser errors: none
- Visible result, if applicable: not run
- Stable result marker: `RIVER_DATA_TEXTURE_TEST` now includes `flow_foam_noise alpha_min`, `alpha_max`, `alpha_range`, `alpha_state`, and sampled count when readable flow data exists
- Pass/partial/fail: Partial
- Notes or follow-up: superseded by the current decoded-vector diagnostics added in the generated-map work. Capture a fresh Output line from current generated/resource-owned and imported flow maps during human-assisted Godot validation.

Recorded result:

- Date: 2026-05-21
- Ran by: User
- Godot version/renderer/device: not reported
- Scene path: `scenes/validation/two_phase_flow_validation.tscn`
- Plugin enabled: assumed, because `River -> Validate Data Textures` ran
- Output or parser errors: none reported with this Output line
- `RIVER_DATA_TEXTURE_TEST` output: `flow_foam_noise size=384x384; flow_foam_noise source=generated/resource-owned; flow_foam_noise closest_neutral_rg=(0.4980, 0.4980) pixel=(192,0); flow_foam_noise alpha_min=0.1569 alpha_max=0.8392 alpha_range=0.6824 alpha_state=varied samples=16384; dist_pressure size=384x384; dist_pressure source=generated/resource-owned`
- Material settings changed: not reported
- Visible result: not reported
- Pass/partial/fail: Partial
- Notes or follow-up: historical pre-rebase data texture validation passed for generated/resource-owned maps with preserved neutral RG and varied alpha. Current-baseline decoded vector stats and Forward+ motion/debug-view observations are still required.

Recorded result:

- Date: 2026-05-21
- Ran by: User
- Godot version/renderer/device: not reported
- Scene path: `scenes/validation/two_phase_flow_validation.tscn`
- Plugin enabled: assumed, because the River menu validation workflow was available
- Output or parser errors: none reported
- `RIVER_DATA_TEXTURE_TEST` output: see prior recorded generated/resource-owned result
- Material settings changed: user manually adjusted the river curve because the validation curve was too sharp
- Visible result: Flow Pattern still appeared stuck
- Pass/partial/fail: Fail/partial for visible Flow Pattern; data validation still passes
- Notes or follow-up: historical pre-rebase visible observation. Do not edit `FlowUVW` from this result. Regenerate or confirm current generated maps, capture decoded vector stats, retest in visible Godot 4.6.3 Forward+, and run the scene with F6 if editor preview remains stuck.

## Historical Results Archive

None yet.

## Shader Checks

- Shader/material paths:
  - `addons/waterways/shaders/river.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
  - `addons/waterways/shaders/lava.gdshader`
- Renderer backend:
  - Forward+ required first; Mobile and Compatibility scene-launch smoke passed on 2026-05-22. Full hand-inspected visual validation remains Forward+ only unless explicitly expanded.
- Expected result:
  - all built-in shader variants preserve the documented two-phase helper contract.
- Failure signs:
  - helper math differs without documented intent
  - alpha removed from shader time
  - jump constants changed without visual A/B proof
  - debug shader stops diagnosing the default river shader's behavior

## Editor Workflow Check

Procedure:

1. Open the source validation project in Godot 4.6+.
2. Enable the Waterways plugin.
3. Open a River validation scene with generated maps.
4. Select the River.
5. Run `River -> Generate Flow & Foam Map` or confirm the existing bake is current.
6. Run `River -> Validate Data Textures` and record decoded vector plus alpha statistics.
7. Switch through required Debug View modes.
8. Return to Display Normal.

Expected result:

- Data validation prints useful `RIVER_DATA_TEXTURE_TEST` output.
- Decoded vector stats show whether the current map contains active motion vectors before judging shader behavior.
- Debug material switches modes and restores normal material afterward.
- Required debug views are present and visually distinct.

Failure signs:

- missing menu entries
- invalid checker pattern when maps are expected valid
- debug material not restored
- stale or missing generated maps
- Output warnings about unreadable/import-broken data textures

## Visual Test Scene

Scene path:

- Preferred new fixture: `scenes/validation/two_phase_flow_validation.tscn`
- Existing-fixture fallback if restored: `scenes/validation/waterways_authoring_smoke_validation.tscn`
- Lava fallback if restored: `scenes/validation/lava_material_validation.tscn`

Purpose:

- Prove two-phase motion, flow direction, neutral flow, alpha/noise desynchronization, Flow Strength behavior, Foam Mix coherence, and lava variant consistency.

Expected visual result:

- Continuous motion with no obvious reset artifacts.
- Arrows match perceived flow direction.
- Neutral regions appear neutral.
- Varied alpha visibly desynchronizes reset timing compared with flat alpha where available.

Failure signs:

- popping, pulsing, stuck movement, seam artifacts, direction mismatch, saturated strength everywhere, or lava divergence.

Suggested controls or debug views:

- Noise Map
- Flow Pattern
- Flow Arrows
- Flow Strength
- Foam Mix
- default, slow, and high `flow_speed`

## Bake Output Check

Scenario:

- A curved River with at least one bend, one straight section, one neutral or low-flow region, and generated saved bake data.

Expected generated outputs:

- Flow: smooth RG direction fields, neutral where expected.
- Current generated baseline: default curve-based bakes provide downstream RG support instead of near-neutral maps, while true `curve_only` and blank support-map fallbacks remain explicit special cases.
- Foam: B channel coherent with river features.
- Distance/pressure: RG channels non-flat in representative geometry.
- Alpha/noise: A channel present and either varied or deliberately flat for comparison.
- Metadata: `RiverBakeData` records texture sizes, content rect, UV2 side count, channel metadata, import profile, source metadata, bake settings, source kind, generation behavior, and decoded vector diagnostics where available.

Failure signs:

- wrong direction, seams, stale texture, empty map, flat unexpected channels, unreadable images, wrong import settings, or unsaved in-memory data used as runtime proof.

## Runtime API Check

No new runtime API is included in this feature. If F6/runtime behavior is checked, the scene must be saved after rebake and validation must record that saved resources were used.

## Performance Check

Scenario:

- Static review plus visible validation on a representative River scene.

Budget or target:

- No added shader samples, bake passes, GPU readbacks, generated textures, draw calls, or public runtime APIs.
- If validation bakes are run, record baking resolution, texture sizes, rough elapsed bake time, and visible editor stall notes.

How to measure:

- Static diff review for code changes.
- Manual timing note during human-assisted bake validation.

## Artifact Hygiene Check

- Scratch project or temporary folder used: `.codex-research/godot-user/` for sandbox-local Godot editor/cache data, and `spec-driven/tmp/` for temporary probes that were deleted after the run.
- Active scripts/resources mirrored into scratch before validation: not applicable.
- Generated bakes/resources created: refreshed `waterways_bakes/scenes_validation_two_phase_flow_validation/TwoPhaseFlowRiver.river_bake.res`.
- Validation-scene cleanup: removed a stale external resource UID from `scenes/validation/two_phase_flow_validation.tscn` so Godot resolves the generated bake by path without warning.
- Files or folders that must be excluded from packaging: source validation fixtures and generated `waterways_bakes/` unless a source validation archive intentionally includes them.
- Files or folders safe to delete now: ignored screenshots under `spec-driven/screenshots/two-phase-flow-current-baseline/` and ignored Godot cache under `.codex-research/godot-user/` if local evidence artifacts are no longer needed.

## Extension Check

Custom content scenario:

- A custom shader or material variant follows the documented Waterways uniforms and channel contract.

Expected result:

- Custom content can use generated `flow_foam_noise`, `dist_pressure`, `i_valid_flowmap`, and `i_uv2_sides` without relying on editor-only state.

Failure signs:

- hidden dependency on built-in material instance state, validation scene hierarchy, or editor-only bake data.

## Manual Review Checklist

- [ ] Acceptance criteria are satisfied.
- [ ] Likely false premises or expected-behavior explanations were raised before extra implementation work.
- [ ] Human-assisted Godot/editor/test results are recorded when the agent could not run them directly.
- [ ] Active code uses Godot 4.6+ APIs and avoids obsolete Godot 3 APIs.
- [ ] Editor-only and runtime-safe boundaries are preserved.
- [ ] Generated resources and metadata are explicit and inspectable.
- [ ] Visual output matches the spec.
- [ ] Flow direction, seams, foam, masks, and bounds are checked visually.
- [ ] Runtime behavior remains compatible with existing shader consumers.
- [ ] Performance-sensitive paths have been checked.
- [ ] Known limitations are documented.
