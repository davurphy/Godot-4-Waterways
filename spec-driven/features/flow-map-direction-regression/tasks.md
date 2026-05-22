# Tasks: Flow Map Direction Regression

Complete tasks in order unless `spec.md` or `plan.md` is revised.
Each task should be independently reviewable and include its validation step.

## Current Truth

- Current status: Feature complete for the flow-map direction regression slice; dependent features are unblocked.
- Current implementation slice: River downstream baseline, decoded vector diagnostics, unused atlas neutralization, Flow Arrows threshold, and WaterSystem diagnostics are in code.
- Remaining open task count: 0.
- Last passing validation: Human-assisted visible River check, save/reload, and runtime/F6-style check passed after the second adjustment.
- Next recommended action: continue downstream/dependent feature work; package/stage the intended files when ready.
- Known deferred work: full curve-derived river flow feature, per-point speed, terrain simulation, confluences, waterfalls, broad generation UI, and any main `river.gdshader` rewrite.
- Completion decision: Dedicated WaterSystem visible output, seam/start/end visual checks, and performance timing are useful future evidence but are not blockers for this regression slice.

## Open Work

### Setup and Documentation

- [x] Task 1: Create the feature docs from the template shape in the requested order.
  - Created `research.md`, `spec.md`, and `plan.md` before any code patching.
  - Created this `tasks.md`; `validation.md` and `review.md` are part of the same documentation setup slice.
  - Validate: docs exist in `spec-driven/features/flow-map-direction-regression/` and `preliminary_research.md` remains untouched.

- [x] Task 2: Inspect the active code entry points before implementation.
  - Inspected:
    - `addons/waterways/river_manager.gd::_generate_flowmap()`
    - `addons/waterways/water_helper_methods.gd::generate_collisionmap()`
    - `addons/waterways/water_helper_methods.gd::add_margins()`
    - `addons/waterways/water_helper_methods.gd::generate_river_mesh()`
    - `addons/waterways/shaders/filters/normal_map_pass.gdshader`
    - `addons/waterways/shaders/filters/normal_to_flow_filter.gdshader`
    - `addons/waterways/shaders/river_debug.gdshader`
    - `addons/waterways/system_map_renderer.gd`
    - `addons/waterways/shaders/system_renders/system_flow.gdshader`
    - `addons/waterways/resources/river_bake_data.gd`
    - `addons/waterways/resources/water_system_bake_data.gd`
    - `addons/waterways/water_system_manager.gd`
  - Validate: findings are reflected in `research.md`, `plan.md`, `validation.md`, and `review.md`.

### Diagnostics First

- [x] Task 3: Add reusable decoded flow-vector statistics for images.
  - Compute min, max, average magnitude, median if practical, near-neutral percentage, and active pixel counts.
  - Support cropping to `RiverBakeData.content_rect` and isolating occupied versus unused atlas tiles.
  - Validate: `flow_vector_stats_probe.gd` reports `[127,128]` magnitude `0.005546`, exact/near neutral below threshold, downstream active samples, and `6` occupied / `3` unused atlas tiles.

- [x] Task 4: Extend River bake and `Validate Data Textures` diagnostics.
  - Add occupied source-region vector stats to River bake output and validation.
  - Keep existing channel-flat warnings for foam and support maps.
  - Record stats in `RiverBakeData.source_metadata`.
  - Validate: the pre-fix artifact probe reports `river_11_occupied_tiles near_neutral=95.81%` and `river_11_unused_tiles near_neutral=0.00%`; default bake validation reports occupied and unused tile stats in `RIVER_DATA_TEXTURE_TEST`.

- [x] Task 5: Extend WaterSystem diagnostics over alpha-covered pixels.
  - Add decoded world-flow magnitude stats where `system_map.a > 0`.
  - Record stats in `WaterSystemBakeData.source_metadata` or bake settings diagnostics.
  - Validate: the pre-fix artifact probe reports `system_03_alpha_covered mean/avg magnitude=0.026898`, `active_mag_gt_0.020=17004`, `near_neutral=79.99%`; default bake validation reports alpha-covered downstream flow stats.

### River Generation Hardening

- [x] Task 6: Add source-kind and behavior metadata for the hardened default.
  - Keep `SOURCE_KIND_SPLINE_COLLISION_BAKE` as the legacy collision-derived value.
  - Add a source kind or metadata label for the hardened downstream-baseline collision bake.
  - Include behavior-affecting settings in `get_bake_source_signature()`.
  - Validate: static scan finds `SOURCE_KIND_DOWNSTREAM_BASELINE_COLLISION_BAKE`, `bake_generation_behavior`, `downstream_baseline_collision_support`, `legacy_collision_only`, and source-signature metadata.

- [x] Task 7: Add occupied/unused UV2 atlas iteration helpers.
  - Reuse `WaterHelperMethods.calculate_side(_steps)` and existing tile order: column advances first, then row.
  - Identify occupied tiles where `step_quad < _steps`.
  - Identify unused tiles beyond `_steps`.
  - Validate: `flow_vector_stats_probe.gd` reports six occupied tiles and three unused tiles for side `3`.

- [x] Task 8: Add downstream baseline RG generation.
  - Generate an unpadded source-size image.
  - Fill occupied tiles with local downstream `+V` packed RG using the accepted strength.
  - Fill unused tiles with neutral RG.
  - Pad via `WaterHelperMethods.add_margins(...)`.
  - Validate: `default_bake_stats_probe.gd` reports default occupied tiles `mag_avg=0.247090`, `near_neutral=0.00%`, and unused tiles `near_neutral=100.00%`.

- [x] Task 9: Route default River combine through the downstream baseline.
  - Use baseline RG for default `flow_foam_noise.rg`.
  - Keep collision-derived foam and `dist_pressure` support maps when collision data has useful hits.
  - Do not use collision-derived `normal_to_flow` as the only primary direction in default behavior.
  - Validate: static scan and non-headless default bake show `primary_flow_map` uses the downstream baseline in default behavior; legacy mode keeps the collision-derived path.

- [x] Task 10: Preserve legacy collision-only behavior.
  - Keep current collisionmap -> normal -> normal_to_flow -> blur -> combine RG path available.
  - Decide whether this is script-only, metadata-controlled, inspector-visible, or diagnostic-only.
  - Validate: `default_bake_stats_probe.gd -- legacy_collision_only` reports occupied tiles `near_neutral=95.81%`, `mag_avg=0.008847`, and the near-neutral diagnostic warning.

- [x] Task 11: Neutralize unused atlas RG after final River output.
  - Ensure unused source-region tiles beyond `_steps` are neutral in final `flow_foam_noise.rg`.
  - Preserve occupied tile seam/margin continuation.
  - Validate: default and legacy scripted bakes report unused tiles `near_neutral=100.00%`, `active_mag_gt_0.020=0`.

- [x] Task 12: Handle no-hit or flat-hit collision support without erasing baseline flow.
  - If collision hit count is zero or collision-derived direction is low-confidence, keep downstream baseline.
  - Use explicit blank or reduced-detail support maps if collision support filters are not useful.
  - Validate: the flat validation scene keeps downstream RG in default behavior while collision support maps still generate foam/distance/pressure.

### Debug and WaterSystem Hardening

- [x] Task 13: Add near-neutral handling to `river_debug.gdshader` Flow Arrows.
  - Threshold decoded pre-force or post-force vector magnitude according to the accepted rule.
  - Hide, fade, dot, or neutral-color arrows below threshold.
  - Validate: static shader scan confirms `FLOW_ARROW_NEAR_NEUTRAL_THRESHOLD=0.02`; user visible validation reports all Flow Arrows point in one direction matching the River shape.

- [x] Task 14: Review and, if needed, threshold `system_flow.gdshader`.
  - Start with diagnostics after River fix.
  - If WaterSystem still amplifies near-neutral source data, clamp/ignore raw vectors below threshold before force/world transform.
  - Validate: default WaterSystem alpha-covered output reports `near_neutral=0.00%`, `mag_avg=0.294198`, `avg_vec=(-0.0039, 0.2944)` after flat pressure support softening; no shader threshold was needed for the default fixed path.

### Validation, Docs, Review

- [x] Task 15: Run automated/local validation.
  - Run static scans for new metadata, threshold constants, helper usage, legacy path, and absence of default collision-only RG.
  - Run image-stat probes on River occupied tiles, unused tiles, and WaterSystem alpha-covered pixels.
  - If running Godot scripts, use Godot 4.6.3 console and redirect `APPDATA`/`LOCALAPPDATA` into workspace scratch.
  - Validate: Godot 4.6.3 non-headless scripted probes and static scans are recorded in `validation.md`.

- [x] Task 16: Run human-assisted visible Godot validation.
  - Ask the user in chat to open `scenes/validation/flow_map_direction_verification.tscn`.
  - Include exact River and WaterSystem menu actions, debug views to inspect, Output text to copy, screenshot/visible behavior request, Godot version, renderer, device, and physics backend.
  - Validate: River-side visible validation, save/reload, and runtime/F6-style behavior passed after pressure/foam support softening. WaterSystem visible output was not separately described, but local WaterSystem stats passed and runtime looked good.

- [x] Task 17: Update user-facing docs if behavior changes.
  - Update `docs/godot-4-user-guide.md` for default bake behavior, legacy collision-only comparison, debug arrows, and collision helper limitations.
  - Update `docs/godot-4-imports.md` if source kind or data-map metadata guidance changes.
  - Validate: `docs/godot-4-user-guide.md` and `docs/godot-4-imports.md` distinguish generated downstream baseline, collision support data, imported/manual maps, Flow Arrows thresholding, and WaterSystem diagnostics.

- [x] Task 18: Review implementation against spec and plan.
  - Verify every acceptance criterion is pass, partial, or explicitly deferred.
  - Confirm no stale "implementation not started" language remains after code changes.
  - Confirm no unrelated user changes were reverted.
  - Validate: `review.md` current truth matches `tasks.md` and `validation.md`; optional/deferred checks are called out explicitly.

## Setup

- [x] Confirm the current workspace state.
  - Active workspace is `C:\Users\pc\Documents\GitHub\Godot 4 Waterways`.
  - Git worktree already contains unrelated/user changes and many untracked project/spec files; do not revert them.
- [x] Read `spec.md`, `plan.md`, and `validation.md`.
  - `validation.md` is created as part of this setup pass.
- [x] Check `audit/code-audit.md` for relevant known risks before code implementation.
  - No relevant `audit/code-audit.md` content was present in this workspace pass.
- [x] Use the known local Godot 4.6.3 executables when running local probes:
  - Console/script runner: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
  - GUI editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`
- [x] Confirm whether the task affects active code in `addons/waterways`, legacy reference code, or both.
  - Active code only. Legacy behavior is compatibility/reference.
- [x] Run the context challenge check.
  - The issue is not solely a debug arrow problem; generated River occupied interiors are already near-neutral before final combine.

## Implementation Guardrails

- Do not patch `river.gdshader` unless `spec.md` and `plan.md` are revised.
- Do not encode raw world X/Z direction into River RG.
- Do not use collision-derived `normal_to_flow` as the sole default direction for flat collision input.
- Do not remove legacy collision-only comparison behavior.
- Do not let unused atlas cells contain strong arbitrary RG after final output.
- Do not present local headless/parser checks as visible shader/editor validation.

## Historical or Closed Tasks

No tasks have been moved out of the active checklist yet.
