# Tasks: Curve-Derived River Flow

Complete tasks in order unless `spec.md` or `plan.md` is revised.
Each task should be independently reviewable and include its validation step.

## Current Truth

Keep this as the single fastest way to understand open work.

- Current status: First implementation slice complete locally; Task 12 local screenshot/reload/runtime/performance validation passed, with optional live human editor motion review still available.
- Current implementation baseline: active Waterways has default downstream-baseline RG generation through `bake_generation_behavior = "downstream_baseline_collision_support"`, true `curve_only`, legacy comparison through `bake_generation_behavior = "legacy_collision_only"`, curve-derived source kinds, decoded vector diagnostics, unused atlas RG neutralization, Flow Arrows near-neutral thresholding, and WaterSystem alpha-covered flow diagnostics.
- Current verification: Godot 4.6.3 local probes on 2026-05-22 confirm default occupied `mag_avg=0.247090`, unused atlas `near_neutral=100.00%`, legacy occupied `near_neutral=95.81%`, zero-layer/no-hit/curve-only blank support fallback, canonical scene rebake/save/reload/runtime checks, screenshots, and low/current/high bake timings.
- Current blocker for this feature: no curve-derived bake-data blocker remains from Task 12. Live animated editor observation can still add confidence for Flow Pattern motion over time.
- Next recommended action: decide whether to fix the non-blocking `Validate Data Textures` generated-subresource `.import` warning now, or leave it as a diagnostics follow-up.
- Known deferred work: directional collision RG blending, collision-confidence rules, per-point velocity, slope-derived speed, reverse-flow authoring, edge attenuation, confluences, waterfalls, terrain simulation, broad UI exposure, and any `river.gdshader` rewrite.

## Rebase Decisions

- Do not introduce a parallel `baking_generation_mode` property in the next slice. Extend the current serialized/script-accessible `bake_generation_behavior` string first, then consider a public enum or inspector UI after validation.
- Treat `generated_downstream_baseline_collision_bake` as the current foundation and narrower predecessor for `Curve + Collision Modifiers`, not as the final public source-kind name for all curve-derived modes.
- Keep `SOURCE_KIND_SPLINE_COLLISION_BAKE` as the legacy collision-derived source kind unless implementation discovers a real resource-compatibility reason to add a separate legacy source kind.
- Keep collision RG deflection out of this feature slice. Collision may enrich foam, distance, and pressure support maps, but default and curve-only RG should remain the local downstream curve/UV baseline.
- Keep the current packed RG shader contract and padded UV2 atlas layout unchanged.

## Completed or Superseded by Flow-Map Direction Regression

These items were in the old plan but are now current baseline behavior rather than future curve-derived work.

- [x] Default generated RG no longer depends on collision-derived `normal_to_flow`.
  - Current default `_generate_flowmap()` uses `WaterHelperMethods.create_downstream_baseline_flow_image(...)` and combines that padded baseline into `flow_foam_noise.rg`.

- [x] Legacy collision-derived comparison is available.
  - Current storage/script switch is `bake_generation_behavior = "legacy_collision_only"`.

- [x] Current source kind and metadata identify the downstream-baseline bake.
  - Current source kind is `SOURCE_KIND_DOWNSTREAM_BASELINE_COLLISION_BAKE` / `generated_downstream_baseline_collision_bake`.

- [x] Padded UV2 atlas behavior is preserved for the downstream baseline.
  - Baseline RG is generated in the unpadded source atlas, then padded with `WaterHelperMethods.add_margins(...)`.

- [x] Empty/unused atlas RG is neutralized after combine.
  - Current probes report unused atlas `near_neutral=100.00%` for both default and legacy bakes.

- [x] Flow-vector diagnostics exist.
  - Bake output and `River -> Validate Data Textures` report decoded stats for source, occupied, and unused regions.

- [x] Flow Arrows threshold near-neutral vectors.
  - `river_debug.gdshader` uses `FLOW_ARROW_NEAR_NEUTRAL_THRESHOLD = 0.02`.

- [x] WaterSystem alpha-covered flow diagnostics exist.
  - `water_system_manager.gd` reports decoded alpha-covered flow stats during validation.

## Open Work

### Setup and Document Alignment

- [x] Task 1: Sync the feature docs with the revised plan before code changes.
  - Validate: `spec.md`, `plan.md`, `tasks.md`, `validation.md`, and `review.md` agree that directional collision RG blending is deferred.

- [x] Task 1A: Rebase this feature against the completed flow-map direction regression.
  - Updated this checklist to build on current downstream-baseline behavior.
  - Recorded current verification results in `validation.md` and `review.md`.
  - Decided to extend `bake_generation_behavior` before considering a public `baking_generation_mode` enum.
  - Decided that `generated_downstream_baseline_collision_bake` is a predecessor/foundation source kind, not the final broader mode name.
  - Validate: no current feature doc should describe collision-derived `normal_to_flow` as the default primary RG path.

- [x] Task 2: Confirm the active code entry points and current behavior before patching.
  - Inspected:
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
  - Confirmed:
    - default `_generate_flowmap()` swaps the downstream baseline into `flow_foam_noise.rg`;
    - `legacy_collision_only` keeps collision-derived RG;
    - `add_margins(...)` still owns the padded UV2 atlas behavior;
    - `baking_raycast_layers == 0` still fails preflight unconditionally;
    - `baking_generation_mode` does not exist.
  - Validate: review notes and validation matrix reflect these findings.

### Next Implementation Slice

- [x] Task 3: Extend generation behavior naming without broad UI churn.
  - Add explicit behavior constants for the remaining semantics, at minimum a true curve-only behavior.
  - Keep current `downstream_baseline_collision_support` and `legacy_collision_only` readable.
  - Include any new behavior value in bake settings and source signatures.
  - Validate: static scan shows behavior values in defaults/property access/bake settings/source signature, and switching behavior invalidates stale generated data.

- [x] Task 4: Add final or transitional source kinds for curve-only and broader curve-derived output.
  - Preserve `SOURCE_KIND_DOWNSTREAM_BASELINE_COLLISION_BAKE` for current resources.
  - Add only the source kinds needed by implemented behaviors.
  - Document any mapping between current and future public mode names.
  - Validate: existing resources with `generated_spline_collision_bake` and `generated_downstream_baseline_collision_bake` remain readable.

- [x] Task 5: Refactor bake preflight by behavior.
  - Current default behavior should no longer fail only because `baking_raycast_layers == 0`.
  - True curve-only behavior must not require nonzero `baking_raycast_layers`.
  - Legacy collision-only behavior should preserve the current collision-layer requirement.
  - Validate: zero-layer curve-based bake proceeds with a reduced-detail notice; zero-layer legacy bake still fails.

- [x] Task 6: Add exact blank support-map fallback for no-layer and no-hit curve-based bakes.
  - Build source `flow_foam_noise.b = 0.0`.
  - Preserve existing tiled phase/noise alpha.
  - Build source `dist_pressure.rg = (0.0, 0.0)`.
  - Pad blank support sources before shader-facing assignment or combine.
  - Validate: source-region crop shows non-neutral downstream RG, foam `B = 0.0`, noise `A` present, and `dist_pressure.rg = (0.0, 0.0)`.

- [x] Task 7: Route `_generate_flowmap()` through curve-based and legacy paths.
  - Curve-based with useful collision hits: use downstream baseline RG and collision support maps.
  - Curve-based with zero layers or zero hits: skip collision support filters and use blank fallback support maps.
  - Curve-only: skip collision probing and collision filter passes.
  - Legacy collision-only: preserve current collision-derived RG, foam, and support-map path.
  - Validate: `normal_to_flow` output is used for RG only in legacy mode or diagnostics/comparison, not in default curve-based modes.

- [x] Task 8: Write fallback and behavior metadata.
  - Record behavior, source kind, baseline strength, collision hit counts/percentages, curve baseline pixel count, support fallback flag, vector stats, and no-collider/no-hit reason.
  - Include behavior and relevant controls in `get_bake_source_signature()`.
  - Validate: saved `RiverBakeData` contains the new metadata and behavior changes invalidate old generated data.

- [x] Task 9: Add the canonical validation scene.
  - Add `scenes/validation/curve_derived_river_flow_validation.tscn`.
  - Include named fixtures: `StraightNoColliderRiver`, `CurvedNoColliderRiver`, `FlatColliderRiver`, `BankHelperRiver`, `LegacyCollisionRiver`, and a curve long enough to cross at least one UV2 column-continuation seam.
  - Add a helper script only if it keeps fixture setup maintainable.
  - Validate: scene opens in Godot 4.6+ with the plugin enabled, fixture nodes are selectable by name, and it does not depend on explanatory in-app UI for correctness.

- [x] Task 10: Update user-facing docs after behavior changes.
  - Update `docs/godot-4-user-guide.md` for curve baseline flow, bake helper roles, no-collider behavior, and named layer recommendations.
  - Update `docs/godot-4-imports.md` if source kinds or channel metadata change imported/generated map guidance.
  - Validate: docs distinguish River curve flow, bake helper colliders, snap targets, gameplay colliders, current behavior names, and legacy comparison behavior.

- [x] Task 11: Run automated and local validation for the implementation slice.
  - Run static scans for behavior constants, source kinds, metadata fields, source signatures, and absence of default-mode directional collision RG blending.
  - Run a parser/editor-load check if local Godot can do it without sandbox crashes.
  - Run default, zero-layer, no-hit, curve-only, and legacy bake probes if practical.
  - Validate: record exact commands, environment, results, and any Godot limitations in `validation.md`.

- [ ] Task 12: Run human-assisted visual validation and review.
  - Local Task 12 evidence is complete for rebake/save, `Validate Data Textures`, focused screenshots, fresh-process reload, runtime-style shader valid flags, F6-style launch smoke, and performance timings.
  - Completed locally: straight no-collider, curved no-collider, flat collider, bank-helper, legacy comparison, save/reload, runtime-style/F6-style smoke, and low/current/high `baking_resolution` timing.
  - Remaining optional evidence: manual editor menu clicking and a human watch pass for animated Flow Pattern motion over time.
  - Validate: update `validation.md` and `review.md` with observed results, residual risk, and follow-up tasks.

## Deferred Work

- [ ] Directional collision RG blending after a concrete collision-confidence rule is designed.
  - Future rule must gate on both support-map signal and decoded collision-vector length.
  - It must never blend useful curve flow toward neutral when collision data is empty, flat, or low-confidence.

- [ ] Broad inspector UI for generation modes.
  - Current recommendation is serialized/script-accessible behavior first, visible inspector controls only after validation.

- [ ] Curve-only/no-collider procedural foam and pressure support.
  - Current first-pass behavior intentionally writes blank support maps for no-collider/curve-only bakes. Any foam, pressure, bank-distance, or edge-support generation without bake helpers needs a separate design and validation plan.

- [ ] Transparency/material-control validation in the canonical scene.
  - User-visible transparency controls appeared ineffective on curved validation rivers. Treat this as a shader/material/scene-depth follow-up, not as evidence that curve-derived bake generation regressed.

- [ ] Targeted material force-control checks.
  - `flow_pressure` is expected to have no visible effect on blank-support fixtures. `flow_max` should be validated with a high-force setup before treating it as a product regression.

- [ ] Per-point velocity, slope-derived speed, reverse-flow authoring, confluences, waterfalls, terrain simulation, and imported DCC/simulation generation modes.
