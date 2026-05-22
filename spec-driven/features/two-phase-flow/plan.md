# Plan: Two-Phase Flow Foundation

## Spec Link

This plan is now paired with `spec.md`, derived from `research.md` Option A: "Preserve and Validate Existing Two-Phase Flow."

Before addon implementation starts, `spec.md`, this plan, `tasks.md`, `validation.md`, and `review.md` must stay aligned on the preservation scope. Do not widen the feature during reconciliation.

## Architecture Summary

Option A treats the existing two-phase flow shader behavior as the product baseline to preserve, document, validate, and protect.

The architecture is:

1. Keep the current `FlowUVW`-based shader behavior in the built-in river, debug, and lava shader variants.
2. Document the local Waterways variant of the two-phase flow algorithm, including packed RG flow decode, `progress - 0.5` UV displacement, half-period phase B, triangle-wave blending, alpha phase/noise time offset, and current jump constants.
3. Keep shader helper duplication for this feature and protect it with documentation plus a lightweight drift check. A shared `.gdshaderinc` include is deferred because it adds Godot import/export and custom-shader workflow risk.
4. Validate the data texture contract before interpreting visual artifacts as shader bugs.
5. Validate motion in visible Godot debug views, especially Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix.
6. Record human-assisted visual testing as required evidence. Shader compilation and static inspection are useful, but they are not proof of motion quality.

This feature should produce evidence and guardrails, not a shader rewrite. Any behavior-changing shader edit must be justified by validation, reflected back into `spec.md` and this plan, and checked against river, debug, and lava together.

## Current Truth

- Implementation status: Drift guard, alpha diagnostics, user docs, import docs, and validation scaffolding are implemented. Shader math, shader samples, bake passes, GPU readbacks, and public runtime APIs remain unchanged.
- Closed architectural decisions:
  - `river_debug.gdshader`'s `steepness_map * 8.0` is classified as intentional debug-only diagnostic amplification; river and lava keep `* 4.0`.
  - Drift protection is scripted in `spec-driven/features/two-phase-flow/check_shader_drift.py`.
  - Fixture availability is resolved locally: `project.godot` and `scenes/validation/two_phase_flow_validation.tscn` now exist.
- Last validation that proves the static/data plan still works: `python spec-driven/features/two-phase-flow/check_shader_drift.py` passed 54 checks, and user-provided `RIVER_DATA_TEXTURE_TEST` output showed neutral RG plus varied alpha on 2026-05-21. The first visible Flow Pattern attempt reported stuck motion with no warnings/errors, so adjusted-fixture retest is pending.
- Current workspace caveat: local headless Godot 4.6.2 Mono crashes before scene checks complete. Visible editor validation is still required before closure.
- Next planned implementation slice: human-assisted Forward+ retest using the adjusted validation fixture, then record results and close the review only if visible motion passes.
- Sections below that are historical or superseded: None.

## Premise Check

This feature is release hardening and maintainability work, not a response to a proven broken shader.

- Evidence supporting the premise:
  - `FlowUVW` exists in the active river, debug, and lava shaders.
  - `flow_foam_noise.rg` is already used as packed flow, `b` as foam, and `a` as phase/noise offset.
  - River baking already generates `flow_foam_noise` and `dist_pressure`.
  - Debug views already expose Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix.
  - `validate_data_textures()` already checks readable data, import settings, and neutral RG preservation for flow maps.
- Evidence against a broad implementation pass:
  - There is no confirmed visual defect in `FlowUVW`.
  - External references support the current two-phase technique.
  - Many bad-looking results can come from authored flow data, normal texture repetition, excessive `flow_speed`, excessive flow force, import settings, or stale generated maps.
- User-facing pushback or clarification needed before patching:
  - If a visible artifact is reported, first check Flow Pattern, Flow Arrows, Flow Strength, Noise Map, material settings, and data texture validation before editing `FlowUVW`.
- Smallest check that can falsify the premise:
  - In a visible Godot 4.6+ scene with a generated River, switch `River -> Debug View -> Display Debug Flow Pattern` and watch for at least 10 seconds. Obvious full-surface reset popping, synchronized pulsing, stuck flow, or directional disagreement with Flow Arrows would justify deeper shader investigation.

## Layers

Editor authoring layer:

- Preserve the existing River toolbar and `River -> Debug View` workflow.
- Use `River -> Validate Data Textures` as the first data-quality gate.
- Treat debug views as user-facing diagnostics, not internal-only developer tools.
- Do not add advanced artist controls for jump constants, phase blend shape, phase offset strength, or shader tiering in this feature.

Bake/data layer:

- Preserve the current River bake pipeline and generated resources.
- Preserve `flow_foam_noise` and `dist_pressure` texture meanings.
- Preserve `RiverBakeData.DEFAULT_CHANNEL_METADATA` and `DEFAULT_IMPORT_PROFILE` unless documentation-only wording needs to be made clearer.
- Treat generated/imported data quality as a first-class explanation for flow artifacts.
- Do not redesign bake passes, resource storage, UV2 padding, or import/export workflows in this feature.

Runtime layer:

- Preserve runtime shader behavior in:
  - `addons/waterways/shaders/river.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
  - `addons/waterways/shaders/lava.gdshader`
- Preserve existing material uniforms: `flow_speed`, `flow_base`, `flow_steepness`, `flow_distance`, `flow_pressure`, `flow_max`, `uv_scale`, `i_flowmap`, `i_distmap`, `i_valid_flowmap`, and `i_uv2_sides`.
- Do not add a runtime sampling API, buoyancy change, or WaterSystem data contract change.

Validation layer:

- Add a validation matrix in `validation.md` that maps each required behavior to static, data, shader, visual, and human-assisted evidence.
- Prefer existing validation scenes where they cover the behavior.
- Add a dedicated two-phase-flow validation scene only if existing scenes cannot make reset hiding, alpha/noise, neutral flow, and lava behavior obvious.
- Human-assisted visible Godot validation is required before the feature can be called complete.

Legacy reference layer:

- Use the preserved Godot 3 addon only as behavioral context.
- Do not port Godot 3 shader syntax, scene formats, or editor APIs.
- Preserve useful Waterways behavior only where it is already active or clearly required by the Godot 4.6+ addon.

## Godot Components

- Nodes:
  - Existing `River` nodes are the primary validation subject.
  - Existing `WaterSystem` nodes are out of scope except where an existing validation scene needs a normal project setup.
- Resources:
  - `RiverBakeData`
  - Generated `flow_foam_noise` texture
  - Generated `dist_pressure` texture
  - Built-in shader materials and debug material assignment
- Shaders:
  - `addons/waterways/shaders/river.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
  - `addons/waterways/shaders/lava.gdshader`
  - `addons/waterways/shaders/filters/combine_pass.gdshader` as the existing channel-packing reference only
- Editor tools:
  - River toolbar menu
  - Debug View submenu
  - Validate Data Textures action
- Importers:
  - Godot texture import settings for user-supplied numeric data maps.
  - No custom importer is planned.
- Autoloads:
  - None planned.
- Scenes:
   - Current minimal checkout caveat: no source validation scenes are present locally.
   - Prefer existing `scenes/validation/waterways_authoring_smoke_validation.tscn` for River debug views if source fixtures are restored and it visibly covers the required cases.
   - Use `scenes/validation/lava_material_validation.tscn` for lava shader animation if source fixtures are restored and it is suitable.
   - Use the local `scenes/validation/two_phase_flow_validation.tscn` fixture for curved flow, neutral flow, alpha/noise variation, and reset behavior.
- Validation scenes:
  - Any new scene must make failure obvious with fixed camera framing, a curved river, a neutral-flow region, visible debug modes, and expected results recorded in `validation.md`.

## Data Model

No new serialized runtime data is required for Option A.

Existing data contract to preserve:

- `flow_foam_noise.r`: signed flow X packed to `0..1`, neutral `0.5`.
- `flow_foam_noise.g`: signed flow Y or Z packed to `0..1`, neutral `0.5`.
- `flow_foam_noise.b`: foam influence.
- `flow_foam_noise.a`: optional phase/noise offset added to shader time.
- `dist_pressure.r`: bank distance or edge influence.
- `dist_pressure.g`: flow pressure or occupancy.
- `dist_pressure.b/a`: reserved.

Shader data assumptions:

- Flow is decoded in shader as `(flow - 0.5) * 2.0`.
- Valid generated maps are sampled through the padded UV2 atlas remap using `i_uv2_sides`.
- Invalid or missing flow maps must keep a safe visible fallback. River and lava use a fallback flow; debug shader uses an obvious invalid checker pattern.
- Alpha is allowed to be neutral or flat, but varied alpha should desynchronize phase resets. Validation must distinguish "alpha missing or flat" from "FlowUVW broken."

Resource ownership and save/load behavior:

- Generated River maps remain owned by the River bake data path already implemented.
- Saved scenes should keep external `.river_bake.res` resources.
- Unsaved scenes may hold generated maps only in editor memory and must not be used as proof of runtime behavior.
- This feature must not change resource paths, bake ownership, or scene serialization.

## Editor/Runtime Boundary

- Editor-only code:
  - River toolbar actions.
  - Debug view selection.
  - Data texture validation commands.
  - Any future validation scene helpers or editor-only diagnostics.
- Runtime-safe code:
  - Built-in spatial shaders.
  - Shader uniforms assigned by River material setup.
  - Generated `Texture2D` resources consumed by shaders.
- Shared data/resources:
  - `flow_foam_noise`
  - `dist_pressure`
  - `RiverBakeData` channel metadata and import profile
- APIs exposed to user projects:
  - Existing River material uniforms and custom shader uniform contract.
  - No new public API in Option A.
- Assumptions that must not cross the boundary:
  - Editor-only validation output is not runtime proof.
  - In-memory unsaved bake data is not proof of exported or F6 runtime behavior.
  - Static shader inspection is not proof of visual motion quality.

## Runtime Flow

1. `River` assigns generated or imported `flow_foam_noise` to shader uniform `i_flowmap`.
2. `River` assigns `dist_pressure` to shader uniform `i_distmap`.
3. The shader remaps `UV2` into the padded bake atlas using `i_uv2_sides`.
4. The shader samples `flow_foam_noise` and `dist_pressure`.
5. If `i_valid_flowmap` is true, the shader reads packed RG flow, foam, alpha phase/noise, distance, and pressure. If false, it uses the current safe fallback behavior.
6. The shader decodes RG flow from packed `0..1` to signed `-1..1`.
7. Flow strength is modified by base flow, steepness, distance, pressure, and `flow_max`.
8. Shader time is computed as `TIME * flow_speed + flow_foam_noise.a`.
9. `FlowUVW` computes phase A and phase B with a half-period offset.
10. Normal, debug pattern, foam, lava normal, or lava emission textures are sampled with those two phase UVs.
11. The shader blends the two phases with the existing triangle-wave weight so one phase fades out before its reset.
12. Debug modes visualize the same conceptual flow behavior so artists and maintainers can diagnose data and material settings.

## Bake Flow

This feature preserves the current bake flow. It does not redesign or replace it.

1. River bake inputs come from the existing River shape, UV2 mesh layout, collision helpers, bake settings, and noise texture.
2. Existing filter passes generate flow, foam, distance, pressure, and tiled noise intermediates.
3. `combine_pass.gdshader` packs blurred flow R/G, foam B, and tiled noise A into `flow_foam_noise`.
4. The bake writes `dist_pressure` from distance and pressure intermediates.
5. `RiverBakeData` records texture references, texture sizes, content rect, padded atlas layout, UV2 side count, bounds, channel metadata, import profile, source metadata, and bake settings.
6. River materials receive `i_flowmap`, `i_distmap`, `i_valid_flowmap`, and `i_uv2_sides`.
7. Debug views and default shaders consume the same generated data.

Do not add new bake passes, data textures, import rules, or storage paths for Option A unless a validation failure proves the existing data is insufficient and the spec is updated first.

## Shader Drift Protection Plan

The selected approach is synchronized duplication, not shared shader includes.

Guardrails:

1. Define the "Waterways FlowUVW contract" in documentation:
   - Function signature: `FlowUVW(vec2 uv_in, vec2 flowVector, vec2 jump, vec3 tiling, float time, bool flowB)`.
   - Phase offset: `0.0` for phase A and `0.5` for phase B.
   - Progress: `fract(time + phaseOffset)`.
   - Local UV displacement: `uv_in - flowVector * (progress - 0.5)`.
   - Tiling: multiply by `tiling.xy`.
   - Phase offset added to UVs.
   - Jump offset: `(time - progress) * jump`.
   - Weight: `1.0 - abs(1.0 - 2.0 * progress)`.
   - Time source: `TIME * flow_speed + flow_foam_noise.a`.
2. Keep the drift check script at `spec-driven/features/two-phase-flow/check_shader_drift.py`:
   - Confirm the three built-in shader files contain the expected `FlowUVW` contract.
   - Confirm river, debug, and lava all use `flow_foam_noise.a` in shader time.
   - Confirm river and debug use `jump1 = vec2(0.24, 0.2083333)` for primary flow.
   - Confirm river and debug foam mix use `jump2 = vec2(0.20, 0.25)` for the secondary detail layer where applicable.
   - Confirm RG decode still uses `(flow - 0.5) * 2.0`.
   - Confirm debug modes for Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix remain present.
3. Record intentional differences so the check does not force false parity:
   - River has water normals, foam, refraction, and a secondary near-camera detail layer.
   - Debug Flow Pattern samples a debug texture for diagnosis.
   - Debug Foam Mix mirrors the water normal/foam sampling path more closely.
   - Lava samples normal and emission textures and currently uses only the primary jump layer.
   - Invalid-map fallback differs between default shaders and debug shader.
   - `river_debug.gdshader` intentionally uses `steepness_map * 8.0` as diagnostic amplification, while river and lava use `* 4.0`; Flow Strength should not be treated as exact shader parity evidence.
4. Require a plan update before:
   - Changing `FlowUVW` math.
   - Changing jump values.
   - Removing alpha from shader time.
   - Replacing duplicated helpers with a shared include.
   - Changing channel packing.

## Data Texture Checks Plan

Use data checks to separate shader defects from bad or stale input data.

Required checks:

- Run `River -> Validate Data Textures` before visual artifact triage.
- Treat `RIVER_DATA_TEXTURE_TEST` output as required evidence in `validation.md`.
- Confirm `flow_foam_noise` and `dist_pressure` have readable image data.
- Confirm imported data textures use project paths, uncompressed or lossless data, no normal-map import, no block compression, and no unvalidated mipmaps.
- Confirm imported flow maps preserve or include sampled neutral RG near `(0.5, 0.5)`.
- Confirm `flow_foam_noise.a` reports alpha phase/noise min/max or equivalent variation notes. This is required evidence for Option A, not an optional nicety.
- Inspect Flow Map and Noise Map debug views when validating generated data.
- Confirm alpha channel behavior by using or creating a validation case where varied `flow_foam_noise.a` visibly desynchronizes reset timing compared with a flat alpha case.

Implemented data-validation change:

- `validate_data_textures()` adds lightweight alpha statistics to the `RIVER_DATA_TEXTURE_TEST` output: `alpha_min`, `alpha_max`, `alpha_range`, `alpha_state`, and sampled count for `flow_foam_noise.a`.
- Generated/resource-owned and imported flow maps now produce sampled RG and alpha notes without turning this into a bake-pipeline redesign.

Do not make data validation responsible for proving visual quality. It only proves the shader is receiving plausible numeric inputs.

## Debug View Validation Plan

Debug views are part of the feature surface.

Required debug-view checks:

- Flow Map:
  - Shows effective decoded flow or clearly documented encoded/effective behavior.
  - Neutral regions should be visibly neutral and not mistaken for active current.
- Noise Map:
  - Shows `flow_foam_noise.a`.
  - Varied alpha should be visible where phase desynchronization is expected.
- Flow Pattern:
  - Shows continuous animated distortion.
  - No obvious full-surface pulse or reset pop over at least 10 seconds.
  - Test default, slow, and high `flow_speed` settings.
- Flow Arrows:
  - Direction should agree with Flow Pattern motion on bends, straight sections, and neutral regions.
  - Arrows should not rotate unexpectedly at UV seams.
- Flow Strength:
  - Should respond to `flow_base`, `flow_steepness`, `flow_distance`, `flow_pressure`, and `flow_max`.
  - Should not saturate everywhere in ordinary validation scenes.
- Foam Mix:
  - Should remain coherent with the default river shader's two-phase normal/foam path.
  - Foam should not appear detached from the flow direction.

Failure in a debug view should first trigger data and material triage. Shader edits come only after debug evidence points to shader drift or a true `FlowUVW` issue.

## Lifecycle, Cleanup, and Re-entry

For this Option A plan, avoid new asynchronous bake or runtime lifecycle behavior.

- Success path:
  - Documentation identifies the current shader contract.
  - Drift check or checklist passes.
  - Data texture validation output is captured.
  - Human-assisted visible validation is recorded in `validation.md`.
  - Any accepted addon code comments or validation helpers are reflected in `tasks.md` and `review.md`.
- Preflight or early-return path:
  - If no valid flow maps exist, validation records the missing bake and stops before judging shader motion.
  - If the scene is unsaved and generated maps are only in editor memory, validation records that limitation and does not claim F6/export behavior.
  - If an existing validation scene lacks a clear two-phase case, add or plan a dedicated fixture before claiming completion.
- Awaited failure path:
  - If a Godot headless load fails, record it as parser/load evidence only.
  - If visible Godot validation cannot be run by the agent, request exact human-assisted steps and record the user's reported result.
  - If shader compile errors occur, resolve those before visual validation, but do not treat compile success as visual success.
- Temporary node/resource ownership:
  - Do not add temporary renderer nodes for this feature.
  - If a validation scene is created, generated bake resources should be scene-owned and intentionally saved, or clearly omitted from source if generated outputs are not meant to ship.
- Progress, dirty-state, and user feedback:
  - Do not add progress UI in Option A.
  - Validation docs should say when a scene must be saved and rebaked before runtime checks.
- Duplicate or overlapping requests:
  - Do not run multiple River bakes as part of this feature unless the validation scene requires it.
  - Avoid overlapping with broader flow-map, runtime sampling, or shader-tier work.
- Scene reload or runtime boundary:
  - Reopen saved validation scenes before final proof if runtime persistence is part of the check.
  - Do not rely on editor-only in-memory resources as final evidence.

## Files to Change

Planning and feature docs:

- `spec-driven/features/two-phase-flow/spec.md`: Defines Option A behavior, acceptance criteria, non-goals, and visible validation requirements.
- `spec-driven/features/two-phase-flow/plan.md`: This file.
- `spec-driven/features/two-phase-flow/tasks.md`: Canonical checklist for unfinished work.
- `spec-driven/features/two-phase-flow/validation.md`: Validation matrix, human-assisted steps, expected visual outcomes, and captured results.
- `spec-driven/features/two-phase-flow/review.md`: Spec/plan compliance, residual risks, and deferred work.

Documentation:

- `docs/godot-4-user-guide.md`: Add concise notes explaining the built-in two-phase flow behavior, debug-view interpretation, and when to validate data before changing shader settings.
- `docs/godot-4-imports.md`: Clarify that `flow_foam_noise.a` is phase/noise data and should be preserved for imported maps when used.

Addon code or shader files, only after spec/tasks accept implementation:

- `addons/waterways/shaders/river.gdshader`: Preserve behavior. Add a concise comment around `FlowUVW` only if it prevents future accidental "cleanup." Do not rewrite phase math.
- `addons/waterways/shaders/river_debug.gdshader`: Preserve debug behavior. Keep Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix aligned with the river shader's intended behavior.
- `addons/waterways/shaders/lava.gdshader`: Preserve two-phase helper behavior and alpha time offset. Lava can remain a thinner material variant.
- `addons/waterways/resources/river_bake_data.gd`: Preserve channel metadata. Update wording only if the spec needs clearer phase/noise semantics.
- `addons/waterways/river_manager.gd`: Use existing `validate_data_textures()` first. Add only lightweight validation reporting if accepted by spec/tasks.

Validation fixtures:

- `scenes/validation/waterways_authoring_smoke_validation.tscn`: Prefer reuse for River debug validation if source fixtures are restored and the scene is sufficient.
- `scenes/validation/lava_material_validation.tscn`: Prefer reuse for lava validation if source fixtures are restored and the scene is sufficient.
- `scenes/validation/two_phase_flow_validation.tscn`: Dedicated local fixture for Option A validation.

Files and changes explicitly not planned:

- No new shared `.gdshaderinc` include in this feature.
- No shader rewrite.
- No advanced material parameter exposure.
- No runtime sampling API.
- No WaterSystem or Buoyant behavior change.
- No bake-pipeline redesign.
- No new import/export system.

## Implementation Slices

1. Spec reconciliation:
   - Status: completed as draft on 2026-05-21.
   - Keep acceptance criteria focused on preserving and proving behavior.
2. Validation fixture availability:
   - Status: completed locally with `project.godot` and `scenes/validation/two_phase_flow_validation.tscn`.
   - Do not claim completion until a visible Forward+ result has been recorded.
3. Documentation baseline:
   - Status: completed in feature docs and user-facing docs.
   - Documented the Waterways `FlowUVW` contract and data-channel contract.
   - Marked `progress - 0.5`, alpha time offset, and jump constants as intentional current behavior.
4. Shader drift guard:
   - Status: completed with `check_shader_drift.py`.
   - The script verifies helper contract and key shader expressions across river, debug, and lava.
   - Intentional variant differences are recorded.
5. Data texture validation hardening:
   - Status: implemented; visible Output capture still pending.
   - Document required `Validate Data Textures` evidence.
   - Added alpha/noise reporting as a required validation improvement.
6. Debug-view validation:
   - Status: procedure written; visible run pending.
   - Reuse or create a validation scene that makes motion, direction, strength, neutral flow, and noise offset visible.
7. Human-assisted Godot validation:
   - Ask a human to run visible Godot 4.6+ checks in Forward+ first.
   - Record renderer, Godot version, scene path, steps, console output, visible behavior, and screenshots or clips if available.
8. Review and closure:
   - Review against `spec.md` and this plan.
   - Move any shader include, parameter exposure, runtime sampling, or bake redesign ideas into deferred follow-up notes.

## Documentation Plan

- Code comments needed:
  - A short comment above `FlowUVW` may be useful if implementation starts, naming it as the Waterways two-phase flow helper and warning that `progress - 0.5`, alpha time offset, and jump constants are validated behavior.
  - Avoid comments that restate every line of math.
- Feature docs to update:
  - `spec.md`
  - `tasks.md`
  - `validation.md`
  - `review.md`
- Architecture or data-flow docs to update:
  - `docs/godot-4-user-guide.md`
  - `docs/godot-4-imports.md`
- Validation docs to update:
  - `validation.md` should contain a current validation matrix and exact human-assisted steps.
- Migration notes to update:
  - None expected for existing scenes, because Option A should preserve behavior.
  - Add a compatibility note only if implementation discovers an existing debug/lava drift that must be classified.

## Validation Strategy

- Automated:
  - Run `python spec-driven/features/two-phase-flow/check_shader_drift.py` for the `FlowUVW` contract in `river.gdshader`, `river_debug.gdshader`, and `lava.gdshader`.
  - The same script checks that `TIME * flow_speed + flow_foam_noise.a` remains in the three shader paths.
  - The same script checks debug mode IDs and menu entries for Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix.
  - `Validate Data Textures` output now covers readable data, import settings, neutral RG, and alpha phase/noise min/max/range/state.
- Validation matrix location:
  - `spec-driven/features/two-phase-flow/validation.md`, in a table named "Current Validation Matrix."
- Human-assisted:
  - Open the selected validation scene in visible Godot 4.6+.
  - Enable the Waterways plugin.
  - Generate or confirm saved River maps.
  - Run `River -> Validate Data Textures` and copy Output text.
  - Switch Debug View through Noise Map, Flow Pattern, Flow Arrows, Flow Strength, and Foam Mix.
  - Report Godot version, renderer, GPU/device, scene path, material settings changed, visible behavior, and any console warnings.
- Visual:
  - Flow Pattern must animate continuously without obvious reset popping.
  - Flow Arrows must agree with the perceived movement direction.
  - Flow Strength must show bounded response to force modifiers.
  - Noise Map must explain whether phase/noise alpha is flat or varied.
  - Foam Mix must remain coherent with default river motion.
  - Lava must animate with the same two-phase basis or any intentional difference must be documented.
- Shader:
  - Shader parser/load checks are useful for compile sanity only.
  - Visual checks in Forward+ are required before claiming success.
  - Mobile and Compatibility renderer behavior should be smoke-tested or explicitly marked unvalidated.
- Editor:
  - River menu debug view switching must work.
  - Validate Data Textures must produce useful output.
  - Debug material assignment must restore normal material after returning to Display Normal.
- Runtime:
  - No runtime sampling API is included.
  - If F6 runtime behavior is checked, the scene must be saved after rebake and validation should record that saved resources were used.
- Performance:
   - Count current shader samples and document cost rather than optimizing.
   - River shader uses two primary normal samples plus two secondary near-camera samples.
   - Debug Flow Pattern uses two debug-pattern samples.
   - Debug Foam Mix uses four normal samples.
   - Lava uses two normal and two emission samples.
   - Preservation invariant: this feature must not add shader samples, bake passes, GPU readbacks, generated textures, draw calls, or public runtime APIs unless the spec is revised.
   - If validation bakes are run, record baking resolution, texture sizes, approximate bake time, and visible editor stall notes.
- Manual:
  - Manual review must confirm no plan or task accidentally introduces shader rewrite, advanced parameters, shared include refactor, runtime sampling API, or bake redesign.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| A maintainer "fixes" `FlowUVW` to match tutorial pseudocode and changes visual behavior. | Existing scenes may shift motion quality or develop reset artifacts. | Document the local variant and require visual A/B proof before math changes. |
| Debug shader drifts from the default river shader. | Debug views stop diagnosing real water behavior. | Add drift guard and classify intentional debug differences. |
| Lava is forgotten because the feature sounds water-specific. | Lava behavior may silently diverge. | Include lava in static checks and visible validation. |
| Data texture import problems are mistaken for shader bugs. | Shader churn hides the actual issue. | Require `Validate Data Textures`, raw debug views, and import setting review before shader edits. |
| Alpha phase/noise is flat or destroyed. | Reset timing may synchronize across the river. | Inspect Noise Map and compare flat versus varied alpha where possible. |
| Existing validation scenes do not expose reset artifacts. | Feature could be approved without meaningful visual proof. | Add a dedicated validation scene if existing scenes are insufficient. |
| Source validation scenes are absent from the minimal checkout. | Human-assisted validation cannot be run from this workspace as-is. | Restore source fixtures, use an external source validation project, or create a dedicated source validation scene before closure. |
| Shared include refactor is pulled into Option A. | Packaging or export paths could break all built-in shaders. | Mark shared include as deferred and keep synchronized duplication. |
| Advanced parameters are exposed too early. | Inspector becomes noisy and artists can create poor output without guidance. | Defer parameter exposure to a shader-preset or advanced-controls spec. |
| Human-assisted validation is underspecified. | Results are hard to trust or reproduce. | Record exact scene, steps, renderer, version, visible behavior, and Output text. |
| Static checks are treated as final proof. | Motion artifacts remain unseen. | State that visible Godot validation is required. |
| Alpha diagnostics remain optional. | Flat or destroyed phase/noise data can pass validation while causing synchronized pulsing. | Add required alpha min/max or variation reporting to `Validate Data Textures`. |
| Debug Flow Strength scale remains unclassified. | Debug evidence may not match the default river/lava shader behavior. | Classify the `* 8.0` debug steepness scale as intentional or correct it only after spec and visual validation. |

## Migration and Compatibility

Godot version assumptions:

- Target Godot 4.6+.
- Validate visible behavior in Forward+ first.
- Mobile and Compatibility renderer checks are desirable smoke tests, but any unrun renderer must be marked unvalidated.

Scene and material compatibility:

- Existing River, debug, and lava materials should preserve default visual behavior.
- Existing generated bake resources should keep the same channel semantics.
- Existing custom shaders should continue to work if they preserve Waterways uniforms and channel packing.
- No material parameter names, ranges, or uniform meanings should change in Option A.

Godot 3 compatibility:

- The legacy Godot 3 addon remains a reference only.
- Do not restore Godot 3 shader syntax or resource assumptions.

Export/import compatibility:

- Do not introduce shader include paths or new generated resources in Option A.
- Continue treating flow, distance, pressure, and system maps as numeric linear data.
- Imported data maps should preserve neutral RG and phase/noise alpha where used.

## Deferred / Out Of Scope

Deferred or out of scope for Option A:

- Shader rewrite or replacement of `FlowUVW`.
- Shared `.gdshaderinc` helper or include refactor.
- Advanced exposure of jump constants, phase offsets, blend curves, phase/noise strength, or shader tiers.
- Runtime flow sampling API changes.
- WaterSystem sampling or Buoyant behavior changes.
- Bake-pipeline redesign, new bake passes, or new texture packing.
- Import/export tooling redesign.
- Gerstner waves, FFT, compute wakes, waterfalls, rapids, foam simulation, or river-network simulation.
- Broad material visual redesign unrelated to preserving and validating two-phase flow.
