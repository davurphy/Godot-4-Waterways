# Review: Flow Map Direction Regression

## Review Date

2026-05-22

## Scope Reviewed

- Documentation and planning created in this pass:
  - `research.md`
  - `spec.md`
  - `plan.md`
  - `tasks.md`
  - `validation.md`
  - `review.md`
- Active code implementation and inspection:
  - `addons/waterways/river_manager.gd`
  - `addons/waterways/water_helper_methods.gd`
  - `addons/waterways/shaders/filters/normal_map_pass.gdshader`
  - `addons/waterways/shaders/filters/normal_to_flow_filter.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
  - `addons/waterways/system_map_renderer.gd`
  - `addons/waterways/shaders/system_renders/system_flow.gdshader`
  - `addons/waterways/resources/river_bake_data.gd`
  - `addons/waterways/resources/water_system_bake_data.gd`
  - `addons/waterways/water_system_manager.gd`
- Local evidence reviewed:
  - `preliminary_research.md`
  - `.codex-research/flow_map_direction_verification/intermediate_dump_godot_463/intermediate_summary.txt`
  - `.codex-research/flow_map_direction_verification/flow_vector_stats_probe.gd`
  - `.codex-research/flow_map_direction_verification/default_bake_stats_probe.gd`
- Adjacent feature docs read as boundary context:
  - `spec-driven/features/curve-derived-river-flow/*`

## Current Truth

- Overall review status: Complete for the flow-map direction regression slice; dependent features are unblocked.
- Blocking issues remaining:
  - None.
- Non-blocking deferred notes:
  - Near-neutral threshold is currently `0.02`; refine later only if a weak/neutral visible case shows it hides useful slow flow or permits misleading arrows.
  - Legacy collision-only exposure is script/storage property only, not an inspector control.
  - Dedicated WaterSystem visible validation remains optional/not separately reported; local WaterSystem stats and runtime validation passed for this slice.
- Last validation relied on:
  - Godot 4.6.3 non-headless scripted effective flow-force, default, legacy, scene-load, and WaterSystem probes after the second visual-feedback adjustment.
  - User visible validation after the second support-softening adjustment: Foam Map reasonable, Flow Pattern good, Flow Arrows consistent/correct, and normal view much better.
- Next action:
  - Downstream/dependent feature work can proceed; package or stage the intended files when ready.
- Historical detail starts at:
  - Not applicable yet.

## Findings

### Blocking

- None. River-side visible validation passes after the pressure/foam support adjustment, save/reload works, runtime looks good, and local WaterSystem stats passed.

### Important

- The implemented default path now routes River `flow_foam_noise.rg` through a local downstream baseline for occupied atlas tiles, then neutralizes unused atlas RG.
- Visible checks showed the default generated direction was correct, but the shader force path over-amplified the generated vector. The latest follow-up uses gentle downstream strength, softens saturated occupied pressure support, and keeps saturated foam support at a nonzero floor instead of blacking out Foam Mix.
- The legacy collision-only path remains selectable via `bake_generation_behavior = "legacy_collision_only"` and reproduces the weak occupied output for the flat validation scene while still neutralizing unused atlas tiles.
- `river_debug.gdshader` now thresholds near-neutral raw flow before rotating Flow Arrows.
- WaterSystem shader thresholding was reviewed but not changed because the default fixed River output composes as strong downstream flow in the local probe.
- `curve-derived-river-flow` should remain separate. Its docs are useful context, but this feature folder should not claim that broader feature is implemented.
- Existing worktree has unrelated/user changes and untracked project files. Implementation must not revert them.

### Minor

- The final exact source-kind name can be harmonized with the sibling feature during implementation, but docs should keep scope language clear.
- A dedicated validation scene may become useful later, but the existing `flow_map_direction_verification.tscn` remains the canonical regression scene for now.

## Premise Review

- Was the original premise correct, partially correct, or wrong?
  - Partially correct. There is visible diagonal/distorted debug behavior, but the underlying occupied River data is not a strong diagonal field. It is near-neutral data whose angle is misleading.
- Did any evidence suggest the user or agent was overlooking scene/data/context?
  - Yes. The strongest evidence shows the River bake never receives a useful interior vector for flat occupied collision interiors; final combine and WaterSystem are not the first cause.
- If yes, was that raised with the user early enough?
  - Yes. `research.md`, `spec.md`, and `plan.md` all state that a Flow Arrows-only patch is insufficient.
- Was the final outcome a code/design fix, docs/validation clarification, or expected-behavior explanation?
  - Code/design fix for the first slice, plus docs, local validation, human-visible validation, save/reload, and runtime confirmation.

## Spec Compliance

| Acceptance Criterion | Status | Notes |
| --- | --- | --- |
| Pre-fix diagnosis recorded from Godot 4.6.3 dump. | Pass | `validation.md` records the successful dump and key stats. |
| Default River bake avoids silently valid near-neutral occupied interiors. | Pass local | Default softened bake occupied tiles `mag_avg=0.247090`, `near_neutral=0.00%`. |
| Flow Arrows threshold near-neutral vectors. | Pass for slice | Shader threshold implemented; visible active-flow direction passed. Direct weak/neutral visible suppression remains a non-blocking future check. |
| Flow Pattern visibly moves downstream. | Pass visible | User confirmed Flow Pattern looks good after the pressure/foam support adjustment. |
| Flow Map/validation report decoded vector magnitudes. | Pass local | `RIVER_DATA_TEXTURE_TEST` prints source, occupied, and unused vector stats. |
| Unused atlas cells are neutral or excluded. | Pass local | Default and legacy bakes report unused `near_neutral=100.00%`. |
| UV2 margin behavior remains correct. | Pass local / deferred visual seam check | No visible full-width band/seam issue reported after latest adjustment; dedicated seam/start/end check is future evidence, not a blocker. |
| WaterSystem does not amplify near-neutral data. | Pass local / runtime visible | Default alpha-covered WaterSystem stats remain downstream at `mag_avg=0.294198` after softening; runtime looked good. |
| Existing saved resources remain readable. | Pass | Scene load smoke passed and user reported save/reload worked. |
| Legacy collision-only comparison remains available. | Pass local | Script/storage property validates legacy mode. |
| Save/reload/runtime uses serialized resources. | Pass | User reported save/reload worked and runtime looked good. |

## Architecture Compliance

- Godot 4.6+ API target preserved: Local parse/load passed.
- Editor/runtime boundary preserved: Implemented changes stay in bake/diagnostic/debug shader paths.
- Bake data and generated resources explicit: Source kind, generation behavior, vector diagnostics, and threshold metadata are written.
- Legacy Godot 3 behavior used only as reference: Yes in docs.
- Extension points preserved: Existing source metadata/signature pattern is reused.
- Godot-native features preferred where practical: Existing Image, Texture2D, and bake resource paths are reused.
- Bespoke systems justified: Image-stat and baseline helpers are scoped to atlas/data-map needs.
- Comments explain non-obvious intent without restating obvious code: Partial; docs carry most intent.
- Feature and architecture docs updated for behavior, data flow, and boundary changes: Yes for this slice; broader curve-derived flow remains out of scope.

## Validation Results

- Automated:
  - Pre-fix artifact review still recorded.
  - `flow_vector_stats_probe.gd`, `effective_flow_force_probe.gd`, `default_bake_stats_probe.gd`, default bake, legacy bake, static scan, scene-load smoke, and post-support-softening local probes passed locally.
- Human-assisted:
  - User confirmed Foam Map, Flow Pattern, Flow Arrows, and normal view are in good shape after the latest support-softening change.
- Shader:
  - Static inspection and script parse passed; visible active-flow arrows passed; weak/neutral arrow suppression remains to be checked directly.
- Editor:
  - Partially run by user for River/WaterSystem bake and debug inspection.
- Visual:
  - River-side visual pass recorded; save/reload and runtime passed; dedicated WaterSystem visible remains optional.
- Bake output:
  - Default post-fix occupied tiles are active downstream; softened default occupied tiles remain active downstream at lower magnitude; unused tiles are neutral.
- Runtime:
  - User reported runtime looked good.
- Performance:
  - Not run.
- Manual:
  - Spec-driven docs and user-facing docs updated for current behavior and remaining validation.

## Documentation Consistency Check

- [x] Closed documentation/setup tasks are checked off in `tasks.md`.
- [x] `research.md` preserves `preliminary_research.md` as raw history.
- [x] `spec.md` describes behavior, not implementation details, except where needed for boundaries.
- [x] `plan.md` gives implementation architecture after the spec.
- [x] `tasks.md` starts with docs/spec completion and code inspection before code.
- [x] `validation.md` includes the existing successful Godot 4.6.3 dump as current evidence.
- [x] `review.md` marks this regression slice complete and names non-blocking deferred checks.
- [x] After implementation, remove or update stale "implementation not started" language.

## Follow-Up Tasks

- [x] `tasks.md` Task 3: add decoded vector diagnostics and reusable image-stat helpers.
- [x] `tasks.md` Task 4: extend River bake and validation diagnostics.
- [x] `tasks.md` Task 8-12: implement downstream baseline/default routing/unused atlas neutrality/flat collision handling.
- [x] `tasks.md` Task 13: Flow Arrows threshold implemented and active-flow visible validation passed; direct weak/neutral visible suppression is deferred/non-blocking.
- [x] `tasks.md` Task 16: human-assisted visible, save/reload, and runtime validation.
- [x] `tasks.md` Task 18: final review after visible validation.

## Decision Updates

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-05-22 | Keep `preliminary_research.md` unchanged as raw evidence/history. | The new docs should be distilled and scan-friendly without deleting prior investigation. |
| 2026-05-22 | Treat the existing Godot 4.6.3 dump as pre-fix diagnostic proof, not as fix validation. | It proves where the bug originates but not that behavior has been corrected. |
| 2026-05-22 | Keep `curve-derived-river-flow` separate. | This regression needs a narrower fix path and should not claim broader feature completion. |
| 2026-05-22 | Use `0.02` decoded magnitude as the first near-neutral diagnostic/debug threshold. | It matches the pre-fix evidence marker and cleanly separates `[127,128]` quantization from useful default downstream flow. |
| 2026-05-22 | Do not add a WaterSystem shader threshold in this slice. | The fixed default River output composes as strong downstream WaterSystem flow in local validation. |
| 2026-05-22 | Soften the first downstream baseline to `0.5` and reduce saturated occupied foam support in default generated bakes. | The first visible direction check passed, but full-strength output produced intense foam-linked normal bands across the River width. |
| 2026-05-22 | Soften the default baseline to `0.25`, reduce saturated occupied pressure support to `0.25`, and keep saturated occupied foam support at a nonzero `0.25` floor. | The second visible check improved direction but still showed intense Flow Pattern, black Foam Mix, and persistent full-width bands; local probe showed effective Flow Pattern magnitude had been amplified to `1.7069`. |
