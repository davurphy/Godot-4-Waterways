# Validation: Two-Phase Flow Foundation

## What Must Be Proven

- The active river, river debug, and lava shaders preserve the documented Waterways two-phase `FlowUVW` contract.
- Data texture validation can distinguish bad input data from shader behavior, including alpha phase/noise flatness or variation.
- Visible Godot validation proves motion quality; static scans and shader compilation are not enough.
- Debug views diagnose the same conceptual flow behavior as the default river shader, with intentional differences documented.
- The feature does not add shader samples, bake passes, GPU readbacks, generated textures, or public runtime APIs.

## Current Validation Snapshot

- Overall status: Partial.
- Last automated pass: `python spec-driven/features/two-phase-flow/check_shader_drift.py` passed 54 checks on 2026-05-21.
- Last human-assisted pass: none for this feature.
- Latest human-assisted attempt: Flow Pattern appeared stuck with no warnings or errors after generated-map data validation passed; fixture retest is pending after validation-scene adjustments.
- Highest-risk unproven behavior: visible motion quality in Godot 4.6+ Forward+.
- Known unreliable local check or environment caveat: `project.godot` and `scenes/validation/two_phase_flow_validation.tscn` now exist, but local headless Godot 4.6.2 Mono crashes before scene checks complete. Visible editor validation is still required.

## Current Validation Matrix

| Requirement or risk | Check/probe/scene | Environment | Expected marker/result | Last result | Date | Owner |
| --- | --- | --- | --- | --- | --- | --- |
| `FlowUVW` contract exists in built-in shaders | `check_shader_drift.py` | Local static | River, debug, and lava define expected helper signature and core expressions | Pass: drift guard included these checks | 2026-05-21 | Agent |
| Alpha phase/noise participates in time | `check_shader_drift.py` | Local static | All three shader paths use `TIME * flow_speed + flow_foam_noise.a` | Pass: drift guard included these checks | 2026-05-21 | Agent |
| Packed RG flow decode preserved | `check_shader_drift.py` | Local static | Built-in paths decode `(flow - 0.5) * 2.0` | Pass: drift guard included these checks | 2026-05-21 | Agent |
| Required debug modes remain available | `check_shader_drift.py` over debug shader and menu | Local static | Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix exist | Pass: drift guard included shader and menu checks | 2026-05-21 | Agent |
| Debug steepness scale classified | Review decision plus drift guard | Docs/static | `* 8.0` debug scale is intentional or corrected under spec update | Pass: classified as intentional debug-only diagnostic amplification | 2026-05-21 | Agent |
| Alpha variation data check exists | `River -> Validate Data Textures` output | Visible editor | `RIVER_DATA_TEXTURE_TEST` reports alpha min/max/range/state | Pass: generated maps reported alpha_min=0.1569 alpha_max=0.8392 alpha_range=0.6824 alpha_state=varied | 2026-05-21 | User |
| Validation fixture available | File/project scan and selected source workflow | Local/source workspace | Real `project.godot` and scene/workflow available | Pass: `project.godot` and `scenes/validation/two_phase_flow_validation.tscn` exist | 2026-05-21 | Agent |
| Flow Pattern hides reset | Human-assisted visible Godot | Godot 4.6+ Forward+ | 10 seconds of continuous motion without full-surface popping or synchronized pulsing | Fail/partial: first visible attempt reported stuck flow with no warnings/errors; fixture now preserves manual curve edits, applies stronger validation flow settings, and forces editor redraw; retest pending | 2026-05-21 | User/Agent |
| Flow Arrows agree with perceived motion | Human-assisted visible Godot | Godot 4.6+ Forward+ | Arrows align with Flow Pattern on bends, straight sections, and neutral regions | Unrun | 2026-05-21 | User |
| Flow Strength bounded and useful | Human-assisted visible Godot | Godot 4.6+ Forward+ | Strength responds to modifiers without saturating everywhere in ordinary validation geometry | Unrun | 2026-05-21 | User |
| Foam Mix coherent with river motion | Human-assisted visible Godot | Godot 4.6+ Forward+ | Foam does not appear detached from flow direction | Unrun | 2026-05-21 | User |
| Lava variant still uses two-phase basis | Human-assisted visible Godot | Godot 4.6+ Forward+ | Lava animation is continuous or intentional differences are documented | Unrun | 2026-05-21 | User |
| No performance scope creep | Manual/static review | Local static | No new samples, bake passes, readbacks, generated textures, draw calls, or public APIs | Pass so far: no shader math, shader samples, bake passes, generated textures, or public APIs changed | 2026-05-21 | Agent |

## Premise and Interpretation Checks

- Expected behavior that could look like a bug:
  - repeated normal texture patterns
  - motion that becomes visually poor at extreme `flow_speed` or force settings
  - neutral areas that correctly show little or no flow
  - flat alpha creating synchronized resets even though `FlowUVW` is intact
- Scene geometry, stale resources, generated data, or editor/runtime state to rule out:
  - unsaved scenes with in-memory bake data
  - stale `.river_bake.res` resources
  - missing or unreadable `flow_foam_noise` or `dist_pressure`
  - bad import settings for user-supplied data maps
  - validation geometry that is too flat or uniform to show direction and reset artifacts
- Evidence that would mean the user or agent is misreading the situation:
  - `RIVER_DATA_TEXTURE_TEST` reports import/readability or neutral-flow failures
  - Noise Map shows flat alpha when the reported artifact is synchronized pulsing
  - Flow Arrows and Flow Pattern agree, but material settings are extreme
- What the agent should say if that evidence appears:
  - "The shader may not be the first suspect here. The data/debug views point to stale, flat, or imported map input. Let's fix or rebake that before editing `FlowUVW`."
- Quick falsifying check before patching:
  - In a visible Godot 4.6+ scene with valid generated maps, switch to Flow Pattern and watch at least 10 seconds. Obvious full-surface reset popping, synchronized pulsing despite varied alpha, stuck flow, or directional disagreement with Flow Arrows justifies deeper shader investigation.

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

- A stable pass/fail output that names each checked file and any intentional differences. Current result: 54 passed, 0 failed.

Agent limitation note:

- Local checks may include static scans, parser checks, or headless editor-load probes when they work.
- Do not treat local headless/editor-load checks as proof of visible editor interaction, shader visuals, bake output, or runtime behavior.

## Human-Assisted Validation

Use this request with the local validation project. Headless Godot crashed locally, so use the visible editor for this check.

Request to user:

Please open `C:\Users\pc\Documents\GitHub\Godot 4 Waterways` in Godot 4.6+ with the Waterways plugin enabled. Use Forward+ first. Open `scenes/validation/two_phase_flow_validation.tscn`. Select `TwoPhaseFlowRiver`, run `River -> Validate Data Textures`, and copy the full `RIVER_DATA_TEXTURE_TEST` Output line, including `alpha_min`, `alpha_max`, `alpha_range`, and `alpha_state`. Then switch `River -> Debug View` through Noise Map, Flow Pattern, Flow Arrows, Flow Strength, and Foam Mix. Watch Flow Pattern for at least 10 seconds at default, slow, and high `flow_speed`. Report the Godot version, renderer, GPU/device, exact scene path, any material settings changed, Output warnings/errors, and whether motion was continuous or showed popping, pulsing, stuck flow, seam artifacts, or direction disagreement with arrows.

Exact scene, command, or workflow to run:

- Preferred: `scenes/validation/two_phase_flow_validation.tscn`.
- Fallback: `scenes/validation/waterways_authoring_smoke_validation.tscn` for River debug views and `scenes/validation/lava_material_validation.tscn` for lava, if those source fixtures are restored.
- Plugin state required: Waterways plugin enabled.
- Console output or errors to relay back: full `RIVER_DATA_TEXTURE_TEST` line, including alpha statistics, and any shader/import/bake warnings.
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

- Date: 2026-05-21
- Ran by: Agent
- Godot version/renderer/device: not applicable
- Command, scene, or workflow: `python spec-driven/features/two-phase-flow/check_shader_drift.py`
- Output or parser errors: none
- Visible result, if applicable: not run
- Stable result marker: 54 passed, 0 failed; `FlowUVW`, alpha time offset, RG decode, jump constants, documented steepness scales, debug shader modes, and River menu entries found in active files
- Pass/partial/fail: Partial
- Notes or follow-up: static guard passed, but visible Godot validation is still required; source validation scenes are absent from this minimal checkout.

Recorded result:

- Date: 2026-05-21
- Ran by: Agent
- Godot version/renderer/device: not applicable
- Command, scene, or workflow: code review of `River -> Validate Data Textures`
- Output or parser errors: none
- Visible result, if applicable: not run
- Stable result marker: `RIVER_DATA_TEXTURE_TEST` now includes `flow_foam_noise alpha_min`, `alpha_max`, `alpha_range`, `alpha_state`, and sampled count when readable flow data exists
- Pass/partial/fail: Partial
- Notes or follow-up: capture a real Output line from generated/resource-owned and imported flow maps during human-assisted Godot validation.

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
- Notes or follow-up: data texture validation passed for generated/resource-owned maps with preserved neutral RG and varied alpha. Forward+ motion/debug-view observations are still required.

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
- Notes or follow-up: do not edit `FlowUVW` yet. The validation fixture was adjusted to preserve manual curve edits, apply stronger flow material settings to both river and debug materials, force editor redraw, and use a gentler reset curve only when geometry reset is explicitly requested. Retest in visible Forward+ and, if editor preview remains stuck, run the scene with F6 to rule out editor shader-time redraw behavior.

## Historical Results Archive

None yet.

## Shader Checks

- Shader/material paths:
  - `addons/waterways/shaders/river.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
  - `addons/waterways/shaders/lava.gdshader`
- Renderer backend:
  - Forward+ required first; Mobile and Compatibility smoke-test or mark unvalidated.
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
5. Run `River -> Validate Data Textures`.
6. Switch through required Debug View modes.
7. Return to Display Normal.

Expected result:

- Data validation prints useful `RIVER_DATA_TEXTURE_TEST` output.
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
- Foam: B channel coherent with river features.
- Distance/pressure: RG channels non-flat in representative geometry.
- Alpha/noise: A channel present and either varied or deliberately flat for comparison.
- Metadata: `RiverBakeData` records texture sizes, content rect, UV2 side count, channel metadata, import profile, source metadata, and bake settings.

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

- Scratch project or temporary folder used: none yet.
- Active scripts/resources mirrored into scratch before validation: not applicable yet.
- Generated bakes/resources created: none yet.
- Files or folders that must be excluded from packaging: source validation fixtures and generated `waterways_bakes/` unless a source validation archive intentionally includes them.
- Files or folders safe to delete now: none.

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
