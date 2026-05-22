# Waterways Spec-Driven Development

This folder is the working agreement for porting and evolving Waterways as a Godot 4.6+ flow-map add-on.

It turns ideas into durable specs, plans, tasks, validation scenes, and review notes so future sessions can continue without rediscovering the same context.

## Agent Start Protocol

For any non-trivial Waterways change, read these files before editing code:

1. `00-constitution.md`
2. `01-workflow.md`
3. The active feature folder under `features/<feature-slug>/`, if one exists

If no feature folder exists for the work, create one under `features/<feature-slug>/`.
Do not skip directly from a vague idea to implementation unless the requested change is clearly small and local.

## Current Onboarding Path

The current active workstream for this release artifact is Godot 4 audit remediation:

```text
C:\Users\pc\Documents\GitHub\Waterways-release-0.2.2\spec-driven\features\godot-4-audit-remediation\
```

For the next session, read these files in order:

1. `spec-driven/00-constitution.md`
2. `spec-driven/01-workflow.md`
3. `docs/godot-4-proof-audit-roadmap-0.2.2.md`
4. `spec-driven/features/godot-4-audit-remediation/handoff-latest.md`
5. `spec-driven/features/godot-4-audit-remediation/spec.md`
6. `spec-driven/features/godot-4-audit-remediation/plan.md`
7. `spec-driven/features/godot-4-audit-remediation/tasks.md`
8. `spec-driven/features/godot-4-audit-remediation/validation.md`

The audit-remediation implementation backlog is currently complete in the active handoff. The next major gate is packaging hygiene and any requested visible validation before release packaging.

Next-session order:

- Read `handoff-latest.md` first for the current truth.
- Continue with packaging hygiene unless a new validation or remediation issue is reported.
- Keep the completed second-pass hardening tasks closed unless new evidence reopens one.
- Treat visible Godot/editor/runtime validation as human-assisted by default. Local parser or editor-load signal is useful, but it is not proof of visible Inspector, shader, bake, or F6 behavior.
- Before packaging a release archive, remove or exclude `.codex_godot_audit/`, `new-game-project/`, `.godot/`, `waterways_bakes/`, generated validation fixtures, and other local audit artifacts.

The older `features/godot-4-port/` folder remains useful history for the port, but new audit-fix work should be recorded in `features/godot-4-audit-remediation/`.

New feature folders must be created under:

```text
C:\Users\pc\Documents\GitHub\Waterways-release-0.2.2\spec-driven\features
```

Copy the files from `spec-driven/templates/feature-folder/` into the new feature subfolder, then fill them in for that feature.

## Active Add-on Layout

The working Godot 4.6+ add-on lives here:

```text
addons/
  waterways/
```

If a legacy Godot 3 reference snapshot exists in the current workspace, use it only as behavioral reference:

```text
legacy/
  godot-3/
    addons/
      waterways/
```

Use any legacy copy for behavior comparison only. Active code should be written for Godot 4.6+.

## Feature Folder Shape

Each substantial feature should live in its own folder:

```text
spec-driven/
  features/
    godot-4-audit-remediation/
      research.md
      spec.md
      plan.md
      tasks.md
      validation.md
      review.md
```

For example, a feature named `godot-4-audit-remediation` should create and use:

```text
C:\Users\pc\Documents\GitHub\Waterways-release-0.2.2\spec-driven\features\godot-4-audit-remediation\
```

The copied `research.md`, `spec.md`, `plan.md`, `tasks.md`, `validation.md`, and `review.md` files for that feature live in that subfolder.

Use this order:

1. Research the problem and Godot-specific constraints.
2. Write the behavior/spec: what, why, success criteria.
3. Plan the technical design: architecture, data flow, risks.
4. Break the plan into small tasks.
5. Implement one task at a time.
6. Validate with automated checks and visual test scenes where relevant.
7. Review against the spec before broadening or polishing.

## Core Rule

When implementation diverges from intent, update the spec or plan first unless the issue is a tiny local defect.
The spec is the source of truth; code is the current attempt to satisfy it.

## Collaboration Rule

Agents should challenge likely false premises early. If the code, scene, validation data, or Godot behavior suggests the user is overlooking context or reading expected behavior as a bug, the agent should say that plainly, explain the evidence, and suggest the smallest check before spending time on a non-issue. The challenge should be proportional and falsifiable, not reflexive contradiction.

## Included Files

- `00-constitution.md`: standing principles for all Waterways AI-assisted development.
- `01-workflow.md`: the repeatable spec-driven process.
- `templates/feature-folder/`: copyable feature-document templates.
- `templates/session-handoff.md`: copyable template for handing work from one session to the next.

## Session Handoffs

For long-running work, copy `spec-driven/templates/session-handoff.md` into the active feature folder under `spec-driven/features/<feature-slug>/`.

Use a name such as:

```text
handoff-YYYY-MM-DD.md
```

or:

```text
handoff-latest.md
```

The handoff should tell the next session what changed, what was decided, what validation ran, what remains risky, and the single best next action.

## Suggested Initial Feature Folders

- `features/godot-4-audit-remediation/`: release-blocking audit fixes for 0.2.2.
- `features/godot-4-port/`: full Godot 4.6+ add-on migration history.
- `features/flow-map-bake-pipeline/`: flow/foam/distance/height bake resources and outputs.
- `features/editor-authoring-tools/`: gizmos, toolbar controls, inspectors, and debug previews.
- `features/runtime-flow-sampling/`: runtime APIs for current direction, water altitude, and buoyancy helpers.
