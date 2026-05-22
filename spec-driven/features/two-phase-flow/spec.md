# Spec: Two-Phase Flow Foundation

## Summary

This feature preserves, documents, and validates Waterways' existing two-phase flow-map shader foundation. The goal is not to rewrite the river shader; it is to make the current `FlowUVW` behavior, texture channel contract, debug views, and validation evidence explicit enough that future flow-map features can extend them safely.

## Current Truth

- Status: Draft, created from accepted research Option A and the 2026-05-21 design review.
- Source of truth for open work: `tasks.md`.
- Last meaningful decision: preserve existing two-phase behavior first; do not rewrite shader math without visual evidence and a spec update.
- Known deferred items: shared `.gdshaderinc`, advanced jump/phase controls, runtime sampling API changes, WaterSystem/Buoyant changes, bake-pipeline redesign, shader-tier presets.
- Current non-goals that are easy to accidentally reopen: shader rewrite, new bake passes, new texture packing, custom importer, Gerstner/FFT/compute wakes, broad material redesign.

## Goals

- Preserve the active Godot 4.6+ `FlowUVW` helper behavior in river, river debug, and lava shaders.
- Document the Waterways-specific two-phase flow contract, including `progress - 0.5`, half-period phase B, triangle-wave weights, jump constants, RG flow decode, and alpha phase/noise time offset.
- Add guardrails that detect accidental shader drift across the built-in river, debug, and lava shader variants.
- Treat data texture quality as a first-class source of artifacts before editing shader math.
- Require visible Godot validation for motion quality before the feature is considered complete.
- Leave a narrow, maintainable foundation for later shader presets, custom shaders, runtime sampling, or authoring improvements.

## Non-Goals

- No replacement of the current two-phase flow algorithm.
- No shared shader include in this feature.
- No new artist-facing controls for jump constants, phase offsets, blend curves, alpha/noise strength, or shader tiers.
- No runtime flow sampling or buoyancy API changes.
- No WaterSystem data contract changes.
- No bake pipeline redesign, new bake passes, new packed texture layout, or new import/export system.
- No attempt to prove visual behavior from static scans or shader compilation alone.

## Context and Assumptions

- Active implementation evidence:
  - `addons/waterways/shaders/river.gdshader`, `river_debug.gdshader`, and `lava.gdshader` define `FlowUVW`.
  - All three shader paths add `flow_foam_noise.a` to shader time.
  - `RiverBakeData.DEFAULT_CHANNEL_METADATA` documents packed flow, foam, and phase/noise channels.
  - `River -> Validate Data Textures` checks readable data, import settings, neutral RG preservation, and alpha phase/noise min/max/range/state.
  - `spec-driven/features/two-phase-flow/check_shader_drift.py` guards the shader and menu contract.
- Workspace caveat:
  - `project.godot` and `scenes/validation/two_phase_flow_validation.tscn` now exist locally.
  - Local headless Godot 4.6.2 Mono crashes before scene checks complete, so visible editor validation is still required.
- Agent confidence in the premise: high that the current technique should be preserved; medium that existing validation fixtures are sufficient until they are restored or recreated.
- Possible expected-behavior explanations to rule out before patching:
  - stale generated maps
  - unsaved scene-owned bake resources
  - flat or destroyed alpha phase/noise channel
  - lossy or sRGB/imported data texture settings
  - excessive `flow_speed`, `flow_base`, `flow_steepness`, `flow_distance`, `flow_pressure`, or `flow_max`
  - weak validation geometry that cannot reveal reset artifacts

## Users and Workflows

### User Story: Add-On Maintainer

As an add-on maintainer, I want the current two-phase shader behavior defined as a contract, so that future shader edits do not accidentally change visual motion.

Acceptance criteria:

- The spec and plan name the exact shader contract to preserve.
- A static drift check or explicit checklist covers river, river debug, and lava shaders.
- Intentional differences between shader variants are documented.

### User Story: River Author

As a river author, I want debug views and data validation to distinguish shader bugs from authored-map or import issues, so that I can fix the right thing.

Acceptance criteria:

- `River -> Validate Data Textures` evidence is required before shader artifact triage.
- Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix have documented expected behavior.
- Alpha phase/noise flatness or variation is visible or reported during validation.

### User Story: Release Validator

As a release validator, I want a repeatable visible Godot procedure, so that motion quality is proven in the editor instead of inferred from static code.

Acceptance criteria:

- `validation.md` includes exact human-assisted steps, expected visible results, failure signs, and result recording fields.
- A real validation scene or restored source fixture exists before completion is claimed.
- Forward+ visible validation is required; Mobile and Compatibility are smoke-tested or explicitly marked unvalidated.

## Functional Requirements

- FR1: Preserve `FlowUVW(vec2 uv_in, vec2 flowVector, vec2 jump, vec3 tiling, float time, bool flowB)` in the three built-in shader variants unless a future spec and visual A/B validation accept a behavior change.
- FR2: Preserve RG flow decode as `(flow - 0.5) * 2.0`.
- FR3: Preserve shader time as `TIME * flow_speed + flow_foam_noise.a` where the built-in two-phase flow path consumes generated or imported river data.
- FR4: Preserve current built-in jump constants:
  - primary: `vec2(0.24, 0.2083333)`
  - secondary detail where used: `vec2(0.20, 0.25)`
- FR5: Preserve the packed texture channel contract:
  - `flow_foam_noise.r`: signed flow X packed to `0..1`, neutral `0.5`
  - `flow_foam_noise.g`: signed flow Y/Z packed to `0..1`, neutral `0.5`
  - `flow_foam_noise.b`: foam influence
  - `flow_foam_noise.a`: optional phase/noise offset
  - `dist_pressure.r`: bank distance or edge influence
  - `dist_pressure.g`: flow pressure or occupancy
  - `dist_pressure.b/a`: reserved
- FR6: Preserve the editor debug view workflow for Flow Pattern, Flow Arrows, Flow Strength, Noise Map, and Foam Mix.
- FR7: Add or require alpha channel diagnostics for `flow_foam_noise.a`; alpha statistics are required for this feature, not optional.
- FR8: Do not claim completion until a visible Godot validation scene or equivalent source project workflow exists and has been run.

## Non-Functional Requirements

- Maintainability: shader helper duplication may remain for this feature, but it must have a drift guard and documented intentional variant differences.
- Performance: this feature must not add shader samples, bake passes, GPU readbacks, runtime draw calls, or generated texture memory unless the spec is revised.
- Visual quality: Flow Pattern must animate continuously without obvious full-surface reset popping, synchronized pulsing, stuck flow, or direction disagreement with Flow Arrows.
- Godot 4.6+ compatibility: active code must stay in Godot 4 shader syntax and avoid legacy Godot 3 APIs.
- Editor usability: validation instructions must tell the user exactly what to run and what to report; users should not need to infer steps from prose elsewhere.
- Runtime usability: existing shader uniforms and material behavior remain compatible with current scenes and custom shaders that follow the Waterways uniform/channel contract.
- Extensibility: future shader variants should be able to adopt the documented contract without depending on hidden editor-only state.

## Add-On Boundary

Editor authoring responsibilities:

- River toolbar actions.
- Debug View menu selection.
- `Validate Data Textures` reporting.
- Human-assisted validation scenes or procedures.

Bake/data responsibilities:

- Generated `flow_foam_noise` and `dist_pressure` textures.
- `RiverBakeData` channel metadata, import profile, UV2 padding metadata, texture sizes, content rect, source metadata, and bake settings.

Runtime responsibilities:

- Built-in spatial shaders consuming `i_flowmap`, `i_distmap`, `i_valid_flowmap`, and `i_uv2_sides`.
- Material uniforms that control flow speed and force modifiers.

Shared code must not depend on:

- editor-only validation state
- unsaved in-memory bake data as runtime proof
- one validation scene hierarchy
- one material preset
- legacy Godot 3 shader syntax

## Data and Extension Model

Users should be able to:

- Use generated river bake textures.
- Assign imported data textures if they preserve the numeric channel contract.
- Use custom shaders that honor Waterways' existing internal uniforms and channel packing.

Extension points:

- Built-in shader variants.
- Custom shader materials that follow the contract.
- `RiverBakeData` metadata.
- Validation scenes and drift-check scripts.
- Future shader presets or shader includes, after separate validation.

Override rules:

- Built-in shaders should remain the baseline reference for the contract.
- Debug views must diagnose the same conceptual flow behavior as the default river shader, with intentional diagnostic differences documented.
- Invalid or missing flow maps must keep current safe fallback behavior.

Shared systems must not hard-code:

- the presence of source-repo validation fixtures in the minimal add-on package
- a specific user project scene layout
- one visual texture as the only valid flow demonstration

## Acceptance Tests

- AT1: `spec.md`, `plan.md`, `tasks.md`, `validation.md`, and `review.md` agree that Option A is preservation plus validation, not shader rewrite.
- AT2: A static drift guard or manual checklist confirms `FlowUVW`, RG decode, alpha time offset, primary/secondary jump constants, and required debug modes across river, debug, and lava shaders.
- AT3: `Validate Data Textures` evidence includes readable data, source/import notes, neutral RG reporting, and alpha phase/noise statistics.
- AT4: Debug shader scale differences, especially Flow Strength steepness scaling, are classified as intentional or corrected under a spec update.
- AT5: A visible Godot 4.6+ Forward+ validation run records scene/workflow, plugin state, renderer, device, Output text, material settings, and visible behavior.
- AT6: Mobile and Compatibility renderer checks are run or explicitly marked unvalidated.
- AT7: No new shader samples, bake passes, GPU readbacks, generated textures, public runtime APIs, or material parameter meanings are introduced.

## Visual Validation Requirements

- A validation scene or source project workflow must include:
  - curved flow
  - straight flow
  - neutral or near-neutral flow
  - visible alpha/noise variation or a deliberate flat-alpha comparison
  - debug view switching
  - lava material animation or documented lava exclusion
- Required debug views:
  - Noise Map
  - Flow Pattern
  - Flow Arrows
  - Flow Strength
  - Foam Mix
- Required visible checks:
  - watch Flow Pattern for at least 10 seconds at default, slow, and high `flow_speed`
  - compare perceived motion direction to Flow Arrows
  - confirm neutral regions do not look like active current
  - confirm Flow Strength does not saturate everywhere in ordinary validation geometry
  - confirm Foam Mix stays visually coherent with the default river motion

## Performance Requirements

- Preservation invariant: no new shader samples, bake passes, readbacks, generated textures, or draw calls in this feature.
- Record current sample-count expectations:
  - river: two primary normal samples plus two secondary near-camera samples
  - debug Flow Pattern: two debug-pattern samples
  - debug Foam Mix: four normal samples plus foam noise
  - lava: two normal and two emission samples
- Record bake-cost context if validation bakes are run:
  - baking resolution
  - texture sizes
  - approximate bake time
  - whether the bake visibly stalls the editor
- Do not promise large-scene performance from this feature. Use existing conservative authoring budgets unless a separate performance feature adds measurements.

## Open Questions

- What exact Mobile and Compatibility smoke-test scope is practical for the minimal package?
- Which GPU/device and renderer notes will the first visible Forward+ validation run record?

## Resolved Questions

| Question | Resolution | Date | Notes |
| --- | --- | --- | --- |
| Should this feature rewrite the shader? | No. Preserve and validate current behavior first. | 2026-05-21 | Accepted research Option A and design review. |
| Can implementation start without a focused spec? | No. Create this spec before addon code changes. | 2026-05-21 | Required by spec-driven workflow. |
| Are alpha phase/noise statistics optional? | No. They are required evidence for this feature. | 2026-05-21 | Alpha is central to desynchronizing reset timing. |
| Do validation fixtures exist in this checkout? | Yes. `project.godot` and `scenes/validation/two_phase_flow_validation.tscn` now exist. | 2026-05-21 | This was originally missing; visible validation is still unrun. |
| Is the debug steepness scale difference intentional? | Yes. `river_debug.gdshader` keeps `steepness_map * 8.0` as debug-only diagnostic amplification while river/lava keep `* 4.0`. | 2026-05-21 | Flow Strength is qualitative debug evidence, not exact parity evidence. |
| Should the drift guard be scripted or manual? | Scripted. | 2026-05-21 | `check_shader_drift.py` records pass/fail markers for shaders and `river_menu.gd`. |

## Decision Log

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-05-21 | Preserve synchronized shader duplication for this feature. | A shared include may be valuable later, but import/export/custom-shader risk is not justified for preservation work. |
| 2026-05-21 | Require visible Godot validation before closure. | Two-phase correctness is motion-based; static inspection and compile checks are insufficient. |
| 2026-05-21 | Treat missing validation fixtures as a planning blocker, not an implementation detail. | The feature cannot prove visual behavior without a real scene or source project workflow. |
| 2026-05-21 | Add a static drift guard under the feature folder. | The contract is duplicated intentionally and needs a cheap regression check. |
| 2026-05-21 | Add alpha phase/noise statistics to River data validation. | Flat or destroyed alpha must be visible in `RIVER_DATA_TEXTURE_TEST` before shader triage. |
