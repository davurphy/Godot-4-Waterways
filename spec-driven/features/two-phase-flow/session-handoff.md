# Session Handoff: Two-Phase Flow Foundation

## Date

2026-05-22

## Current Focus

Continue preservation/validation work for the two-phase river flow foundation after rebasing on the newer downstream Waterways behavior from flow-map direction regression and curve-derived river-flow work.

- Feature folder:
  - `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\two-phase-flow\`
- Active add-on path:
  - `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways`
- Legacy reference path:
  - No legacy snapshot was used this session; legacy behavior is reference-only.

## Current Truth

- Overall status: River preservation closeout accepted. Current River Forward+ runtime evidence is positive, hand-clicked editor/F6 saved-bake behavior is confirmed after the validation-scene default fix, Forward+/Mobile/Compatibility scene-launch smoke checks pass, and lava visual validation is explicitly deferred/unvalidated.
- Highest-priority open task: none for the River preservation slice. Optional follow-up is future lava visual validation or a clearer Two-Phase Flow Museum exhibit.
- Last passing validation: `python spec-driven/features/two-phase-flow/check_shader_drift.py` reported `54 passed, 0 failed` on 2026-05-22. A visible Godot 4.6.3 Forward+ runtime probe also passed the current River data and motion checks, and bounded Forward+/Mobile/Compatibility scene-launch smoke checks loaded the validation scene without warnings or shader/runtime errors.
- Known failing or unproven check: no current shader-specific failure is proven. Lava visual validation remains intentionally deferred/unvalidated.
- Next recommended action: do not edit `FlowUVW`; treat any future visual issue as a new current-baseline data/debug validation task. If desired later, create or restore a focused lava validation scene as follow-up.
- Packaging/artifact hygiene status: `.codex-research/` is ignored local scratch; `spec-driven/screenshots/` is ignored local validation output; the refreshed `.river_bake.res` under `waterways_bakes/` is intentional generated project data.
- Historical detail starts at: the 2026-05-21 "Flow Pattern stuck" observation is stale/pre-rebase evidence and is not proof of a `FlowUVW` shader defect.

## Start Here Next Session

Read these first, in this order:

1. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\two-phase-flow\spec.md`
2. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\two-phase-flow\plan.md`
3. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\two-phase-flow\validation.md`
4. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\two-phase-flow\tasks.md`
5. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\two-phase-flow\review.md`
6. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\two-phase-flow\research.md`
7. This handoff file

Then do this next:

- River preservation validation is closed unless a new current-baseline visual issue is reported.
- If continuing outside this slice, either create/restore focused lava validation or turn `two_phase_flow_validation.tscn` into a clearer Two-Phase Flow Museum exhibit.

## Godot Sandbox Cache Procedure

Known local Godot 4.6.3 executables:

- Console/script runner: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
- GUI editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`

Codex may be able to read `C:\Users\pc\AppData\Roaming\Godot` and `C:\Users\pc\AppData\Local\Godot` without being allowed to write there. When that happens, Godot can fail with messages about not being able to create editor data/config/cache directories, or scripted scene runs may crash or time out.

Before running Godot from a sandboxed shell, redirect Godot's normal user/cache writes into ignored workspace scratch:

```powershell
$root = Get-Location
$godotUser = Join-Path $root '.codex-research\godot-user'
New-Item -ItemType Directory -Force -Path (Join-Path $godotUser 'roaming'), (Join-Path $godotUser 'local') | Out-Null
$env:APPDATA = Join-Path $godotUser 'roaming'
$env:LOCALAPPDATA = Join-Path $godotUser 'local'
& 'C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe' --path $root --script 'res://<path-to-probe>.gd'
```

Use the same `APPDATA` and `LOCALAPPDATA` setup for headless, console-scripted, and visible scripted probes. Keep `.codex-research/` ignored and out of packaging.

## What Changed This Session

- `addons/waterways/river_manager.gd`: `Validate Data Textures` now recognizes generated textures embedded in explicit `.river_bake.res` resources as generated/resource-owned and includes `source_kind` in `RIVER_DATA_TEXTURE_TEST`.
- `waterways_bakes/scenes_validation_two_phase_flow_validation/TwoPhaseFlowRiver.river_bake.res`: refreshed current generated bake for the validation scene.
- `scenes/validation/two_phase_flow_validation.gd` and `.tscn`: F6 now preserves the saved bake and starts in normal shader mode by default; synthetic validation maps and fixed validation material defaults are only applied when auto-refresh is enabled.
- `spec-driven/features/two-phase-flow/`: docs now treat the old 2026-05-21 stuck Flow Pattern result as stale/pre-rebase evidence, record confirmed River editor/F6 behavior, explicitly defer lava visual validation, and preserve `FlowUVW` unless fresh current-baseline visible validation proves a shader-specific issue.

## Current Changes Summary

- Current generated River maps should have downstream RG support by default, true `curve_only`, decoded vector diagnostics, near-neutral Flow Arrows thresholding, and explicit generated bake resources.
- No shader math, bake-pipeline redesign, new texture packing, new runtime API, or shared shader include is justified by current evidence.

## Decisions Made

| Decision | Reason | Follow-up |
| --- | --- | --- |
| Do not edit `FlowUVW` from the stale stuck-flow report. | The stuck report predates the current generated-map rebase and current runtime evidence shows Flow Pattern frame changes. | Only revisit after fresh current-baseline visible validation proves a shader-specific problem. |
| Use workspace-local Godot cache redirection in Codex shells. | AppData permission may be read-only, and Godot still needs writable editor/cache/log directories. | Record the environment whenever it affects validation. |

## Current State

Implementation status:

- Closed for the River preservation slice. Data validation, generated bake recognition, current River runtime motion, and editor/F6 saved-bake behavior are recorded; lava visual validation is deferred/unvalidated.

Spec/plan status:

- Research: updated with current generated-map and shader-triage context.
- Spec: updated to require fresh current-baseline evidence before shader changes.
- Plan: updated around generated data validation and visible debug checks.
- Tasks: updated with completed drift/data/runtime/editor-F6 validation items and explicit lava deferral.
- Validation: updated with current `RIVER_DATA_TEXTURE_TEST`, frame deltas, Godot paths, and sandbox cache notes.
- Review: updated to mark current Forward+ River motion evidence as positive, confirmed editor/F6 saved-bake behavior as passing, renderer smoke checks as passing, lava visual validation as deferred, and old stuck evidence as stale.

Validation status:

- Automated:
  - `python spec-driven/features/two-phase-flow/check_shader_drift.py`
  - Stable marker: `54 passed, 0 failed`
- Godot Forward+ runtime:
  - Godot 4.6.3 Forward+, AMD Radeon RX 6800 XT.
  - Scene: `scenes/validation/two_phase_flow_validation.tscn`
  - Selected node: `TwoPhaseFlowRiver`
  - `RIVER_DATA_TEXTURE_TEST` summary: `source_kind=generated_curve_collision_modifiers_bake`; occupied `active_mag_gt_0.020=60180`; occupied `near_neutral=0.00%`; occupied `mag_avg=0.247090`; unused `near_neutral=100.00%`; alpha `0.0000..0.7216`; `alpha_state=varied`.
  - Flow Pattern frame deltas over 10 seconds: default `0.100065`, slow `0.097431`, high `0.099568`.
  - Result: runtime Flow Pattern was not stuck.
- Human-assisted:
  - User confirmed the post-fix F6/editor mismatch is resolved.
- Shader:
  - No `FlowUVW` edit is justified from current evidence.
- Editor:
  - Menu paths and debug views are present; F6 now preserves the saved bake and normal shader by default after the validation-scene default fix.
- Visual:
  - River Noise Map, Flow Pattern, Flow Arrows, Flow Strength, and Foam Mix rendered nonblank in Forward+ screenshots/probe.
- Runtime:
  - River runtime motion changed at default, slow, and high `flow_speed`.
- Renderer smoke:
  - Forward+, Forward Mobile, and Compatibility bounded scene launches passed on Godot 4.6.3 with AMD Radeon RX 6800 XT after redirecting Godot user/cache writes into `.codex-research/godot-user`.
- Manual:
  - River editor/F6 behavior is confirmed; lava visual validation is explicitly deferred/unvalidated.

## Artifact Hygiene

- Scratch folders or temporary projects created: `.codex-research/godot-user/` for sandbox-local Godot editor/cache/log state.
- Generated bakes/resources created: `waterways_bakes/scenes_validation_two_phase_flow_validation/TwoPhaseFlowRiver.river_bake.res`.
- Validation-scene cleanup: removed stale UID from the external bake-resource reference in `scenes/validation/two_phase_flow_validation.tscn`; Godot now resolves the bake by path without the prior warning.
- Active files mirrored into scratch validation: none that should be committed.
- Files/folders that must be excluded from packaging: `.codex-research/`, `spec-driven/screenshots/`, `spec-driven/tmp/`.
- Files/folders safe to delete now: ignored screenshots under `spec-driven/screenshots/two-phase-flow-current-baseline/` and ignored Godot cache under `.codex-research/godot-user/` if the local visual artifacts are no longer needed.
- Temporary probe scripts: deleted after the run.

## Known Risks and Open Issues

- The hand-clicked editor preview path could still differ from the scripted visible runtime probe. If it appears stuck, run F6 and compare runtime behavior before touching shader math.
- Lava uses related shader behavior but remains visually unvalidated by explicit deferral.
- Mobile and Compatibility have scene-launch smoke coverage only; no hand-inspected renderer-specific debug-view validation has been recorded.
- Pre-rebase generated maps can make Flow Pattern look stuck and falsely implicate `FlowUVW`; rebuild or verify current bake resources first.

## Blockers

- No current blocker for preservation work.
- No blocker for the River preservation closeout. Lava visual validation is deferred by decision.

## Files To Inspect Before Editing

- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\river_manager.gd`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\shaders\waterways_lava.gdshader`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\shaders\waterways_river.gdshader`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways\shaders\river_debug.gdshader`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\scenes\validation\two_phase_flow_validation.tscn`

## Commands or Checks Used

```powershell
$root = Get-Location
$godotUser = Join-Path $root '.codex-research\godot-user'
New-Item -ItemType Directory -Force -Path (Join-Path $godotUser 'roaming'), (Join-Path $godotUser 'local') | Out-Null
$env:APPDATA = Join-Path $godotUser 'roaming'
$env:LOCALAPPDATA = Join-Path $godotUser 'local'
& 'C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe' --path $root --script 'res://<path-to-probe>.gd'
```

Result summary:

- Redirecting `APPDATA` and `LOCALAPPDATA` to `.codex-research\godot-user` allowed Godot to create editor/cache/log data without writing to the user profile.
- The actual validation probes were temporary and deleted after the run.

```powershell
python spec-driven/features/two-phase-flow/check_shader_drift.py
```

Result summary:

- `54 passed, 0 failed`

```powershell
git diff --check -- addons/waterways/river_manager.gd spec-driven/features/two-phase-flow
```

Result summary:

- No whitespace errors reported for the touched paths; Git printed line-ending warnings only.

## Next Tasks

- [x] Treat the current Forward+ runtime probe plus confirmed editor/F6 saved-bake behavior as sufficient River visual evidence.
- [x] Record hand-clicked editor/F6 validation outcome.
- [x] Explicitly defer lava visual validation.

## Do Not Do Yet

- Do not edit `FlowUVW`.
- Do not change shader math, bake-pipeline design, texture packing, runtime API, or shared shader includes unless fresh current-baseline visible validation proves a shader-specific issue and the spec is updated first.
- Do not treat the 2026-05-21 stuck Flow Pattern result as current proof of a shader defect.

## Notes for the Next Agent

Start from current generated data, not the stale pre-rebase result. If Godot fails early in Codex with AppData/cache errors, use the `.codex-research\godot-user` redirection procedure above before spending time debugging the scene. The important preservation line is simple: prove the current map, prove the visible behavior, then and only then consider whether shader work is warranted.
