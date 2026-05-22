# Session Handoff: <Feature or Workstream>

## Date

<YYYY-MM-DD>

## Current Focus

Briefly state what this session was trying to accomplish.

- Feature folder:
  - `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\<feature-slug>\`
- Active add-on path:
  - `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\addons\waterways`

## Current Truth

This is the handoff dashboard. Keep it short, concrete, and current.

- Overall status: <Not started / In progress / Complete / Blocked>
- Highest-priority open task:
- Last passing validation:
- Known failing or unproven check:
- Next recommended action:
- Artifact hygiene status:
- Historical detail starts at:

## Start Here Next Session

Read these first:

1. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\00-constitution.md`
2. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\01-workflow.md`
3. This handoff file
4. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\<feature-slug>\tasks.md`
5. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\<feature-slug>\review.md`
6. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\<feature-slug>\validation.md`
7. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\<feature-slug>\plan.md`
8. `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\spec-driven\features\<feature-slug>\spec.md`

Then do this next:

- <One concrete next action>
- If this requires human-assisted Godot validation, include the exact scene path, plugin state, steps, expected visible result, and Output/console text to relay. The next agent should paste those steps into its user-facing message instead of telling the user to read `validation.md`.
- If the next action might be based on a false premise or overlooked context, tell the user before patching. Include the evidence, confidence level, and the smallest check that could prove or disprove the premise.

## What Changed This Session

- <File or folder>: <What changed and why>
- <File or folder>: <What changed and why>

## Current Changes Summary

Use this for the latest session only. Move older entries into "Historical Change Log" when this gets long.

- <Latest changed file/folder>: <High-signal summary>

## Historical Change Log

Older change history can live here once the current summary is enough for the next agent.

## Decisions Made

| Decision | Reason | Follow-up |
| --- | --- | --- |
| <Decision> | <Reason> | <Follow-up or none> |

## Current State

Implementation status:

- <Not started / In progress / Complete / Blocked>

Spec/plan status:

- Research:
- Spec:
- Plan:
- Tasks:
- Validation:
- Review:

Validation status:

- Automated:
  - <Stable result markers and commands that matter>
- Human-assisted:
  - <If needed, include the exact validation request that should be sent to the user next.>
- Shader:
- Editor:
- Visual:
- Runtime:
- Performance:
- Manual:

## Important Context

- <Constraint, assumption, design note, or project-specific context>
- <Known Godot 4.6+ API detail>
- <Existing Waterways behavior to preserve or intentionally change>
- <Any user/agent misunderstanding risk that should be raised directly instead of silently worked around>
- Known local Godot 4.6.3 executables:
  - Console/script runner: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
  - GUI editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`
- Sandboxed Godot command-line cache procedure:
  - Godot may try to create editor data, config, cache, logs, or shader cache files under `C:\Users\pc\AppData\Roaming\Godot` and `C:\Users\pc\AppData\Local\Godot`.
  - In Codex, permission grants may allow reading those folders without allowing writes. If Godot reports that it cannot create editor data/config/cache directories, crashes, or times out during a scripted probe, route `APPDATA` and `LOCALAPPDATA` into the repo's ignored `.codex-research` folder for that shell session.
  - Use this for headless, console-scripted, and windowed/scripted probes. Record the redirected environment in `validation.md` or this handoff when it affects a result.
  - Command pattern:

    ```powershell
    $root = Get-Location
    $godotUser = Join-Path $root '.codex-research\godot-user'
    New-Item -ItemType Directory -Force -Path (Join-Path $godotUser 'roaming'), (Join-Path $godotUser 'local') | Out-Null
    $env:APPDATA = Join-Path $godotUser 'roaming'
    $env:LOCALAPPDATA = Join-Path $godotUser 'local'
    & 'C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe' --path $root --script 'res://<path-to-probe>.gd'
    ```
  - Keep `.codex-research/` ignored. It is local scratch state only.

## Artifact Hygiene

- Scratch folders or temporary projects created:
- Generated bakes/resources created:
- Active files mirrored into scratch validation:
- Files/folders that should remain local-only:
- Files/folders safe to delete now:

## Known Risks and Open Issues

- <Risk or issue>
- <Risk or issue>
- <Possible false premise or expected-behavior explanation to verify before implementing>

Relevant audit or investigation notes:

- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\audit\code-audit.md`: <Relevant heading or note>

## Blockers

- <Blocker, owner, and what is needed to unblock>
- <If local Godot/editor/test access is blocked or unreliable, say so plainly. Local parser/headless editor-load signal is not a substitute for visible editor/runtime validation.>
- <If the user appears to be overlooking context, say what evidence should be shared with them and what quick check should happen next.>

## Files To Inspect Before Editing

- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\<path>`
- `C:\Users\pc\Documents\GitHub\Godot 4 Waterways\<path>`

## Commands or Checks Used

```powershell
<command>
```

Result summary:

- <What mattered from the output>
- <If the user ran the check, record who ran it, what they ran, when, and what they observed>
- <If a command is noisy but passed, record the stable pass/fail marker and the known caveat.>

## Next Tasks

- [ ] <Task>
- [ ] <Task>
- [ ] <Task>

## Do Not Do Yet

- <Thing that is tempting but out of scope or risky>
- <Thing blocked on a spec/plan decision>

## Notes for the Next Agent

Plain-language guidance for the next session. Include anything that would prevent rediscovering context, repeating a mistake, or accidentally changing the wrong part of the active Godot 4.6+ add-on.
