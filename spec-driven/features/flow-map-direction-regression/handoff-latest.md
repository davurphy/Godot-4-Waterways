# Session Handoff: Flow Map Direction Regression

## Date

2026-05-22

## Current Focus

This workstream is the existing collision-derived River flow-map direction regression:

- Feature folder:
  - `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression`
- Active add-on path:
  - `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways`
- Important note:
  - Process docs mention an older `Waterways-release-0.2.2` path. Ignore that for this thread and use `Godot 4 Waterways`.

## Current Truth

- Overall status: Feature complete for the flow-map direction regression slice; dependent features are unblocked.
- Highest-priority open task: None for this slice.
- Last passing validation: Godot 4.6.3 non-headless scripted default bake, effective flow-force probe, legacy comparison, scene-load smoke, and WaterSystem probe after the second visual-feedback adjustment.
- Non-blocking deferred checks: Dedicated WaterSystem visible output, seam/start/end visual checks, and performance timing are future evidence, not blockers.
- Next recommended action: continue downstream/dependent feature work; package or stage the intended files when ready.
- Packaging/artifact hygiene status: `.codex-research/`, `.godot/`, `waterways_bakes/`, and generated validation artifacts should not be packaged unless intentionally included.
- Historical detail starts at: `preliminary_research.md`.

## Start Here Next Session

Read these first, in order:

1. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\00-constitution.md`
2. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\01-workflow.md`
3. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\handoff-latest.md`
4. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\tasks.md`
5. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\review.md`
6. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\validation.md`
7. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\plan.md`
8. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\spec.md`
9. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\research.md`
10. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\flow-map-direction-regression\preliminary_research.md` only if deeper raw history is needed.

Then do this next:

- Start by continuing the downstream/dependent feature work that was blocked by this slice. If packaging this slice, check the worktree and exclude generated/local artifacts.
- River-side visible validation has passed after the latest adjustment: Foam Map reasonable, Flow Pattern good, Flow Arrows consistent/correct, and the normal view much better.
- Before code edits, re-open the active files named in "Files To Inspect Before Editing" below and confirm they still match the plan.

## What Changed This Session

- `research.md`: distilled `preliminary_research.md` into the standard template sections with current outcome, premise check, active add-on baseline, findings matrix, external flow-map research, Godot 4.6.3 findings, risks, and sources.
- `spec.md`: defined expected behavior for the existing River bake/debug/WaterSystem composition path and kept `curve-derived-river-flow` out of scope.
- `plan.md`: planned a narrow regression fix: diagnostics, downstream baseline, collision support/legacy behavior, unused atlas neutrality, Flow Arrows thresholding, and WaterSystem composition review.
- `tasks.md`: updated task status for the completed implementation slice and marked dependent feature work unblocked.
- `validation.md`: created the validation matrix and recorded the successful Godot 4.6.3 pre-fix dump as current evidence.
- `review.md`: tracks final review and non-blocking deferred evidence.
- Implemented the first code slice:
  - Reusable decoded flow-vector stats and atlas tile helpers in `water_helper_methods.gd`.
  - River diagnostics and metadata in `river_manager.gd`.
  - Default downstream-baseline River bake path with legacy collision-only behavior preserved.
  - Unused UV2 atlas RG neutralization.
  - WaterSystem alpha-covered flow diagnostics.
  - Flow Arrows near-neutral threshold in `river_debug.gdshader`.
  - New River source kind in `river_bake_data.gd`.
  - User-facing docs updated for generated baseline, diagnostics, and Flow Arrows thresholding.
  - Local Godot 4.6.3 validation scripts added under `.codex-research/flow_map_direction_verification/`.
  - Follow-up after visible validation: reduced downstream baseline strength to `0.5`, removed the stale flow-channel contrast warning for uniform active flow, and reduced saturated flat foam support in default downstream bakes.
  - Second follow-up after visible validation: reduced downstream baseline strength to `0.25`, softened saturated flat pressure support to `0.25`, and changed saturated flat foam support to a nonzero `0.25` floor instead of blacking out Foam Mix.

## Current Changes Summary

- Feature docs now reflect first-slice implementation and local validation.
- `preliminary_research.md` was not deleted or rewritten.
- Implementation code was patched in the active add-on and user-facing docs were updated.

## Decisions Made

| Decision | Reason | Follow-up |
| --- | --- | --- |
| Treat the successful Godot 4.6.3 dump as pre-fix diagnostic proof. | It proves occupied tiles are already neutral at `normal_to_flow`; it does not prove any fix. | Re-run equivalent stats after implementation. |
| Do not do a Flow Arrows-only fix. | Flow Arrows are misleading, but generation is also missing downstream data. | Add diagnostics and generation hardening first. |
| Keep `curve-derived-river-flow` separate. | That feature is broader and already has its own spec/plan. | Use it as context only. |
| Preserve legacy collision-only comparison behavior. | Current behavior is likely inherited and may matter for compatibility. | Exposed as script/storage property `bake_generation_behavior = "legacy_collision_only"` for now. |
| Use decoded magnitude `0.02` as the first near-neutral threshold. | It separates `[127,128]` quantization from useful default downstream flow and matches the existing diagnostic marker. | Refine only if visible validation shows the threshold hides useful slow flow or still permits misleading arrows. |
| Use gentle default downstream strength and soften saturated support. | Visible direction was correct, but Flow Pattern/normal distortion was over-amplified by pressure support and Foam Mix was black after a zeroed foam mask. | Recheck Flow Pattern, Foam Mix, and normal view visibly. |

## Current State

Implementation status:

- First implementation slice complete locally:
  - diagnostics/stat helpers,
  - downstream-baseline default River generation,
  - legacy collision-only comparison behavior,
  - unused atlas RG neutralization,
  - Flow Arrows near-neutral threshold,
  - WaterSystem alpha-covered flow diagnostics.

Spec/plan status:

- Research: Created and complete enough for implementation planning.
- Spec: Draft accepted for first implementation slice.
- Plan: Coherent first plan exists.
- Tasks: Tasks 1-18 complete.
- Validation: Matrix updated with post-fix local/scripted results, first visible direction check, second visible feedback, second support-softening local validation, and River-side visible pass.
- Review: Complete for the flow-map direction regression slice; optional/deferred checks are documented as non-blocking.

Validation status:

- Automated:
  - Pre-fix evidence preserved:
    - `river_06_normal_to_flow.png` occupied interiors: `mean_mag=0.005546`, `active_mag_gt_0.02=0`, `range_rg=(127..127,128..128)`.
    - `river_11_final_flow_foam_noise.png` occupied interiors: `mean_mag=0.005864`, `active_mag_gt_0.02=2`.
    - unused final River tile centers: magnitude around `0.184`.
    - `system_00_flow_raw.png alpha>0`: `mean_mag=0.026898`, `active_mag_gt_0.02=17004`.
  - Post-fix local evidence:
    - Default River bake occupied tiles after second softening: `active_mag_gt_0.020=43520`, `near_neutral=0.00%`, `mag_avg=0.247090`.
    - Default River bake unused tiles: `active_mag_gt_0.020=0`, `near_neutral=100.00%`.
    - Effective Flow Pattern magnitude without steepness: before second support-softening `mag_avg=1.7069`; after `mag_avg=0.2945`.
    - Foam support after second softening: occupied `B avg=0.2471` instead of all black.
    - Default WaterSystem alpha-covered flow: `active_mag_gt_0.020=84992`, `near_neutral=0.00%`, `mag_avg=0.294198`, `avg_vec=(-0.0039, 0.2944)`.
    - Legacy collision-only occupied tiles: `near_neutral=95.81%`, `mag_avg=0.008847`; unused tiles still neutralized.
- Human-assisted:
  - Initial visible validation passed direction/Flow Arrows but found intense normal/foam bands before the first follow-up reduction.
  - Second visible validation reported improvement, but Flow Pattern was still very intense, Foam Mix was all black, arrows stayed correct, and full bands remained before the pressure/foam support softening.
  - Third visible validation passed River-side output: color still subtle, but Foam Map reasonable, Flow Pattern good, Flow Arrows consistent/correct, and actual normal view much better.
  - Save/reload worked after the latest adjustment.
  - Runtime/F6-style validation looked good.
- Shader:
  - `river_debug.gdshader` now thresholds raw decoded flow at `0.02` before rotating arrows; visible active-flow direction passed.
- Editor:
  - Non-headless scripted bakes ran; River-side visible editor workflow passed; save/reload and runtime passed; WaterSystem visible workflow not separately reported.
- Visual:
  - River-side visible validation passed after pressure/foam support softening.
- Runtime:
  - Save/reload passed; user reported runtime looked good.
- Performance:
  - Not run.
- Manual:
  - Documentation alignment completed.

## Important Context

- The evidence says the final River combine was not destroying a good vector. The old bake never received a useful downstream vector for flat occupied interiors.
- The current default path in `river_manager.gd::_generate_flowmap()` still computes collision support maps, but `flow_foam_noise.rg` now comes from a local downstream baseline unless `bake_generation_behavior` is set to `legacy_collision_only`.
- `normal_map_pass.gdshader` derives vector information from grayscale collision gradients. A flat occupied collision interior has no useful downstream gradient.
- Flow Arrows decode packed RG and now suppress near-neutral raw vectors before `atan(...)`. Near-zero data like `[127,128]` has a numeric angle but no meaningful direction.
- Unused atlas tiles in the known dump contained stronger arbitrary +Y-like data than the real occupied River tiles; generated outputs now neutralize unused source-region tile RG.
- WaterSystem composition decodes River flow, applies force, transforms into world XZ, and repacks. It may amplify near-neutral or edge-derived data unless diagnostics/thresholding say otherwise.
- Known local Godot 4.6.3 executables:
  - Console/script runner: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
  - GUI editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`
- If running Godot scripts from Codex, redirect `APPDATA` and `LOCALAPPDATA` into workspace-local scratch.

## Artifact Hygiene

- Scratch folders or temporary projects created:
  - Existing from prior research: `.codex-research/flow_map_direction_verification/`.
- Generated bakes/resources created:
  - Existing generated bakes under `waterways_bakes/`.
- Active files mirrored into scratch validation:
  - None in this handoff session.
- Files/folders that must be excluded from packaging:
  - `.codex-research/`
  - `.godot/`
  - local generated validation bakes unless intentionally committed
  - disposable Godot user/cache/log scratch folders
- Files/folders safe to delete now:
  - None identified here.

## Known Risks and Open Issues

- Exact near-neutral threshold is currently `0.02`; future weak/neutral visible validation may refine it if needed.
- Legacy collision-only exposure is script/storage property only (`bake_generation_behavior = "legacy_collision_only"`), not inspector UI.
- Local downstream `+V` baseline passed scripted WaterSystem direction stats and River-side visible/runtime validation; dedicated WaterSystem visible output is optional future evidence if the team wants a separate editor-map check.
- Unused atlas neutralization passed scripted stats; visible seam/start/end checks are optional future evidence.
- WaterSystem shader thresholding was not added in this slice because fixed default River output composes correctly locally.
- WaterSystem visible revalidation remains optional future evidence if the team wants a separate editor-map check; local dumps/stat checks are not proof of WaterSystem shader visuals.

Relevant audit sections:

- `audit/code-audit.md`: no relevant content was present in this workspace pass.

## Blockers

- No blockers remain for this regression slice.
- Visible Godot/editor validation is human-assisted by default and must be requested explicitly for any future optional checks.

## Files To Inspect Before Editing

- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\river_manager.gd`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\water_helper_methods.gd`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\resources\river_bake_data.gd`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\shaders\river_debug.gdshader`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\system_map_renderer.gd`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\shaders\system_renders\system_flow.gdshader`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\water_system_manager.gd`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\resources\water_system_bake_data.gd`

## Commands or Checks Used

Code/doc inspection commands used this session included:

```powershell
Get-Content -Raw -LiteralPath 'spec-driven/00-constitution.md'
Get-Content -Raw -LiteralPath 'spec-driven/01-workflow.md'
Get-Content -Raw -LiteralPath 'spec-driven/README.md'
Get-Content -Raw -LiteralPath 'spec-driven/features/flow-map-direction-regression/preliminary_research.md'
Get-Content -Raw -LiteralPath '.codex-research/flow_map_direction_verification/intermediate_dump_godot_463/intermediate_summary.txt'
rg -n "func _generate_flowmap|generate_collisionmap|add_margins|apply_normal_to_flow|apply_combine|valid_flowmap|Validate Data Textures|Flow Arrows|baking_raycast_layers|get_bake_source_signature|source_kind|source_metadata" addons/waterways
rg -n "UV2|uv2|generate_river_mesh|uv2_sides|TANGENT|BINORMAL|normal_to_flow|flow|neutral|atan|force|texture\(|flowmap" addons/waterways
```

Post-fix checks used this session included:

```powershell
Godot_v4.6.3-stable_win64_console.exe --path <workspace> --script res://.codex-research/flow_map_direction_verification/flow_vector_stats_probe.gd
Godot_v4.6.3-stable_win64_console.exe --path <workspace> --script res://.codex-research/flow_map_direction_verification/default_bake_stats_probe.gd
Godot_v4.6.3-stable_win64_console.exe --path <workspace> --script res://.codex-research/flow_map_direction_verification/default_bake_stats_probe.gd -- legacy_collision_only
Godot_v4.6.3-stable_win64_console.exe --headless --path <workspace> --script res://.codex-research/flow_map_direction_verification/godot_scene_load_smoke.gd
rg -n "FLOW_VECTOR_NEAR_NEUTRAL_THRESHOLD|decode_packed_flow_vector|get_uv2_atlas_decoded_flow_vector_stats|create_downstream_baseline_flow_image|neutralize_unused_uv2_atlas_flow_rg|SOURCE_KIND_DOWNSTREAM|bake_generation_behavior|downstream_baseline_collision_support|legacy_collision_only|FLOW_ARROW_NEAR_NEUTRAL_THRESHOLD|atan\(raw_flow" addons/waterways
```

Result summary:

- The current default bake path produces moderate downstream occupied RG and neutral unused RG in local non-headless scripted validation.
- The existing Godot 4.6.3 dump remains the stable pre-fix evidence.
- Headless Godot cannot prove bake output because viewport readback uses the dummy renderer; non-headless console validation was used for post-fix scripted bakes.

## Next Tasks

- [x] Task 16: Human-assisted visible/save-reload/runtime validation.
- [x] Task 18: Final review after visible validation.

## Do Not Do Yet

- Do not patch Flow Arrows alone and declare the bug fixed.
- Do not rewrite `river.gdshader` without revising `spec.md` and `plan.md`.
- Do not encode raw world X/Z direction into River RG.
- Do not remove legacy collision-only behavior.
- Do not conflate this with the broader `curve-derived-river-flow` feature.
- Do not treat local script/headless checks as visible editor validation.

## Notes for the Next Agent

The central invariant is simple: angle is meaningless when magnitude is near zero. The code now makes that visible in diagnostics, generates local downstream baseline RG for default River bakes, and neutralizes unused atlas cells. This feature is complete and no longer blocks downstream work; optional future checks can focus on dedicated WaterSystem visuals, seam/start/end inspection, and threshold refinement if new evidence calls for it.
