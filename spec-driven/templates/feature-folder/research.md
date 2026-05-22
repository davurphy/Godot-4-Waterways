# Research: <Feature Name>

## Purpose

Describe why this research is needed and what decision it should unlock for Waterways.

- Decision needed:
- Why this cannot go straight to spec or implementation:
- Expected consumer:
  - `spec.md`
  - `plan.md`
  - `validation.md`
  - Other:

## Current Research Outcome

Keep this short once research has produced a direction. This is the dashboard future sessions should read first.

- Status: <Needed / In progress / Complete / Superseded>
- Recommendation:
- Confidence:
- Biggest unknown that remains:
- Decision or plan section this research unlocked:
- Requirements this research implies:
- Non-goals or rejected ideas this research supports:
- Validation this research requires:

## Premise Check

Before broad research, record whether the request may be based on missing context, stale generated data, expected editor/runtime behavior, or an agent assumption.

- Reported or assumed problem:
- Evidence supporting the premise:
- Evidence against the premise:
- Possible expected-behavior explanation:
- Confidence:
- Smallest check that can falsify the premise:
- User-facing note or question to raise before patching:

## Active Add-on Baseline

Record what the current Godot 4.6+ add-on already does before comparing external tools or older project notes.

- Relevant active files:
- Current behavior:
- Existing extension points:
- Existing generated data, resources, channels, or metadata:
- Existing editor-only/runtime-safe boundaries:
- Current validation scenes, debug views, or probes:
- Current known limitations:
- Current performance-sensitive paths:
- What should not be rediscovered or redesigned unnecessarily:

## Research Questions

- What are we trying to learn?
- What assumptions need verification?
- What user or agent premise might be wrong, incomplete, or based on missing scene/data context?
- What Godot 4.6+ constraints could change the design?
- Which parts are editor-only, runtime-only, or shared?
- What existing Waterways behavior should be preserved, changed, or removed?
- What must the spec require if this research is correct?
- What should the plan explicitly avoid?

## Findings Matrix

Use this as the durable map from research questions to actionable conclusions. Prefer evidence and implications over narrative.

| Question | Finding | Evidence or source | Waterways implication | Confidence |
| --- | --- | --- | --- | --- |
| <Question> | <Finding> | <Local file, doc, repo, paper, video, or test> | <Spec/plan/validation impact> | <Low/Medium/High> |

## Comparable Patterns

Summarize how comparable engines, add-ons, tools, papers, production examples, or community projects approach this problem.
Prefer principles and tradeoffs over copying implementation details.

For flow-map and water work, consider:

- flow-map channel packing
- spline/curve authoring
- hand-painted or layered flow controls
- foam and shore masks
- distance/height/alpha map generation
- debug visualization
- runtime sampling of baked data
- generated texture/resource storage
- waterfall, rapid, confluence, and obstacle handling

For non-water work, replace this checklist with the relevant comparable patterns.

## Godot 4.6+ Findings

Record relevant Godot 4.6+ assumptions, APIs, limitations, rendering behavior, import behavior, editor/runtime differences, and community practices.

Known local Godot 4.6.3 executables:

- Console/script runner: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
- GUI editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`

Check as relevant:

- EditorPlugin APIs
- EditorNode3DGizmoPlugin APIs
- SubViewport rendering and GPU readback
- ShaderMaterial and shader uniform APIs
- screen/depth texture shader syntax
- Forward+, Mobile, and Compatibility renderer differences
- Texture2D/Image/ImageTexture APIs
- PhysicsDirectSpaceState3D and ray query APIs
- Jolt versus Godot Physics behavior
- scene serialization and resource ownership
- import settings for data textures
- Godot version-specific behavior or migration notes

## Performance and Scale Findings

Record assumptions and likely bottlenecks before planning.

- Expected scene scale:
- Expected river count, curve complexity, or generated mesh size:
- Expected bake texture sizes:
- Expected runtime texture memory:
- Editor bake-time risks:
- Runtime frame-time risks:
- GPU readback risks:
- Physics query or raycast-count risks:
- Renderer/backend assumptions:
- Mobile, Compatibility, or VR constraints:
- Recommended budget or measurement approach:

## Existing Waterways Reference

Use this section when the feature needs to preserve or intentionally change existing Waterways behavior.

- Relevant existing files:
- Behavior to preserve:
- Behavior to change:
- Obsolete or fragile APIs to avoid:
- Risks discovered in `audit/code-audit.md`:
- What belongs in active Godot 4.6+ code:
- What should remain out of scope:

## Options

### Option A: <Name>

- Benefits:
- Costs:
- Risks:
- Fit for Waterways:
- Source/reuse constraints:

### Option B: <Name>

- Benefits:
- Costs:
- Risks:
- Fit for Waterways:
- Source/reuse constraints:

## Recommendation

State the preferred direction and why.

- Recommended direction:
- Why this fits Waterways:
- What to do first:
- What to defer:
- What to avoid:
- Confidence:

## Spec Implications

List the behavior and boundaries that should move into `spec.md`.

- User/developer workflows:
- Functional requirements:
- Non-functional requirements:
- Editor usability requirements:
- Runtime/API requirements:
- Generated asset/resource requirements:
- Acceptance criteria:
- Non-goals:
- Open questions to carry forward:

## Plan Implications

List the design constraints and implementation guidance that should move into `plan.md`.

- Architecture direction:
- Affected files/modules:
- Editor-only code:
- Runtime-safe code:
- Shared resources/data:
- Texture channels, data formats, and metadata:
- Import/export expectations:
- Lifecycle, cleanup, and re-entry concerns:
- Migration or compatibility concerns:
- Documentation updates needed:

## Validation Implications

List the checks that should move into `validation.md`.

- Automated checks:
- Human-assisted Godot/editor checks:
- Visual scene or debug-view checks:
- Shader checks:
- Bake-output checks:
- Runtime/API checks:
- Performance checks:
- Artifact hygiene checks:
- Failure signs that should stop implementation:

## Risks and Unknowns

- <Risk or unknown>

## Context Challenge Notes

Record detailed evidence that the reported issue may be expected behavior, stale data, validation-scene setup, user misunderstanding, or an agent assumption error.

- Possible misread context:
- Evidence:
- Confidence:
- Quick check before patching:
- User-facing note or question to raise:
- Outcome after the check:

## Source Quality and Reuse Notes

Separate evidence quality from inspiration. Do not treat tutorials, videos, forum posts, and production papers as equally authoritative.

Source categories:

- Local active code:
- Local spec/validation docs:
- Official Godot docs:
- Official tool/engine docs:
- Academic paper or production talk:
- Open-source repo:
- Tutorial or blog:
- Forum, issue, Reddit, or informal discussion:
- Agent inference:

Reuse/licensing notes:

- License:
- Code-copy allowed:
- Conceptual reference only:
- Attribution needed:
- Compatibility concern:

## Sources

Prefer a short note about why each source matters instead of a bare link list.

| Source | Type | Why it matters | Reuse/licensing note |
| --- | --- | --- | --- |
| <Link or local reference> | <Source category> | <Relevant finding> | <License/reuse note> |
