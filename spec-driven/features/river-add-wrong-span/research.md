# Research: River Add Wrong Span

## Purpose

Research whether the River Add editor tool can insert a new control point into the wrong curve span when the visible baked curve and the authored control polygon disagree.

- Decision needed: whether the fix should target Add-mode picking, River insertion APIs, or downstream mesh generation.
- Why this cannot go straight to spec or implementation: Add and Remove share picking setup, Add has a separate append path with collider/axis/plane constraints, and curve edits feed River and WaterSystem bake invalidation.
- Expected consumer:
  - `spec.md`
  - `plan.md`
  - `validation.md`
  - Other: implementation notes for `addons/waterways/plugin.gd` and `addons/waterways/river_manager.gd`

## Current Research Outcome

- Status: Complete
- Recommendation: Fix Add-mode on-curve insertion so the hit position and insertion span come from one consistent curve-hit result. Keep `RiverManager.add_point()` compatible and preserve the existing append path.
- Confidence: High
- Biggest unknown that remains: the exact implementation for mapping a baked hit back to an owning `Curve3D` span, especially on self-near curves where proximity and curve order can disagree.
- Decision or plan section this research unlocked: use editor picking as the first fix target, with shape-preserving Bezier splitting as a stronger follow-up.
- Requirements this research implies: Add-mode insertion must derive position and span from the same source; Remove mode must preserve current visible-curve click behavior; undo/redo and bake invalidation must remain intact.
- Non-goals or rejected ideas this research supports: do not first change river mesh generation to mask the symptom; do not broadly rewrite `add_point()` in a way that breaks external script callers.
- Validation this research requires: editor Add/Remove checks on straight, curved, tight, and self-near rivers; append checks with no constraint, collider snapping, axis constraints, and plane constraints; River and WaterSystem stale-warning checks.

## Validation Review - 2026-05-22

- Reviewer outcome: Validated by static local code review. No major finding in this research was invalidated.
- Validation scope: `research.md`, `findings.md`, `session-handoff.md`, and active local code in `addons/waterways`.
- Validation limitation: no interactive Godot editor reproduction was run in this pass, so the user-facing reproduction status remains "code-path risk confirmed, editor repro still pending."
- Local tool check: both listed Godot 4.6.3 executables exist at the paths recorded below.

### Validated Findings

| Research claim | Review result | Evidence |
| --- | --- | --- |
| Add mode can mix a baked-curve insertion position with a control-polygon span. | Validated. `_forward_3d_gui_input()` first chooses `closest_segment` from authored control-point chords, then separately chooses `baked_closest_point` from baked curve segments, then calls `add_point(baked_closest_point, closest_segment)`. | `addons/waterways/plugin.gd:203`, `addons/waterways/plugin.gd:219`, `addons/waterways/plugin.gd:286` |
| The wrong span can distort the authored curve before mesh generation sees it. | Validated as a plausible direct consequence. `add_point()` inserts at `index + 1` and derives handles from the neighboring control-point direction, not from the clicked baked span or a Bezier split. | `addons/waterways/river_manager.gd:641`, `addons/waterways/river_manager.gd:649` |
| Mesh generation should not be the first fix target. | Validated. `generate_river_mesh()` samples the already-authored curve and derives row orientation from nearby sampled positions, so it will expose a distorted curve rather than explain the initial wrong insert. | `addons/waterways/water_helper_methods.gd:618`, `addons/waterways/water_helper_methods.gd:635`, `addons/waterways/water_helper_methods.gd:638` |
| Remove mode is coupled to the shared picking setup. | Validated, with a nuance: `closest_segment != -1` acts mostly as a baked-visible-curve hit gate because it is reset to `-1` only when no baked hit is found. Remove then deletes the nearest authored control point to `baked_closest_point`. | `addons/waterways/plugin.gd:234`, `addons/waterways/plugin.gd:297`, `addons/waterways/plugin.gd:301`; `addons/waterways/river_manager.gd:820` |
| Append behavior and constraints should be preserved. | Validated. Append runs only after no baked curve hit sets `closest_segment == -1`; it computes a new point from the final curve point using none/collider/axis/plane constraints, then still calls `add_point(..., -1)`. | `addons/waterways/plugin.gd:248`, `addons/waterways/plugin.gd:258`, `addons/waterways/plugin.gd:266`, `addons/waterways/plugin.gd:274`, `addons/waterways/plugin.gd:281`, `addons/waterways/plugin.gd:286` |
| `insert_point_with_handles()` cannot solve the bug by itself. | Validated. It inserts at a direct clamped index with caller-supplied handles and width, but it does not compute a curve-hit span, split Bezier handles, or update neighboring handles. | `addons/waterways/river_manager.gd:657` |
| River and WaterSystem stale paths already react to curve edits. | Validated. River edit APIs invalidate generated bake state and regenerate geometry; River bake signatures include point positions, handles, widths, and relevant settings; WaterSystem compares child River source metadata and warns on mismatches. | `addons/waterways/river_manager.gd:654`, `addons/waterways/river_manager.gd:672`, `addons/waterways/river_manager.gd:738`, `addons/waterways/river_manager.gd:2055`, `addons/waterways/water_system_manager.gd:741`, `addons/waterways/water_system_manager.gd:788` |

### Refined Notes

- The append path does not share the specific on-curve wrong-span failure; its risk is regression risk if the shared hit-test code is refactored without preserving the existing `closest_segment == -1` flow.
- The existing `Add River point` and `Remove River point` undo actions restore curve state and manually restore `valid_flowmap`, while handle edits use `restore_curve_state_with_generated_bake_valid_state()`. The research recommendation to watch undo/redo remains valid, and a future implementation could align Add/Remove with the handle-edit state restoration pattern if the action structure changes.
- `generate_river_width_values()` remains a separate downstream ambiguity: it maps baked samples to width intervals by proximity to sampled curve intervals, which can be ambiguous on self-near curves. This does not invalidate the Add-mode finding.
- Because `get_baked_points()` provides baked positions without an explicit owning `Curve3D` span in the current code, the "map baked hit to owning span" implementation detail remains a real open design point.

## Premise Check

- Reported or assumed problem: adding a River point near a curved or self-near river can place the point into the wrong span and twist or invert the generated river mesh.
- Evidence supporting the premise: `plugin.gd` chooses `closest_segment` from straight control-point segments, separately chooses `baked_closest_point` from baked curve segments, then passes both into `add_point()`.
- Evidence against the premise: no direct editor reproduction was run in this pass; this research is static code-path investigation.
- Possible expected-behavior explanation: simple straight or mildly curved rivers may appear correct because the nearest control chord and nearest baked curve span usually agree.
- Confidence: High for code-path risk, medium until reproduced interactively.
- Smallest check that can falsify the premise: create a tight or self-near river, click near a baked curve section where the nearest control chord belongs to another span, and confirm the inserted index still matches the clicked visible span.
- User-facing note or question to raise before patching: this fix may intentionally change Add behavior on tight/self-near curves while keeping straight-river behavior effectively the same.

## Active Add-on Baseline

- Relevant active files:
  - `addons/waterways/plugin.gd`
  - `addons/waterways/river_manager.gd`
  - `addons/waterways/water_helper_methods.gd`
  - `addons/waterways/water_system_manager.gd`
  - `addons/waterways/river_gizmo.gd`
- Current behavior: Add mode performs separate control-polygon and baked-curve hit tests, then calls `RiverManager.add_point(baked_closest_point, closest_segment)`.
- Existing extension points: `RiverManager.add_point()` for compatible point insertion and `RiverManager.insert_point_with_handles()` for explicit direct-index insertion.
- Existing generated data, resources, channels, or metadata: River bake data stores source signatures; WaterSystem bake data stores child River metadata and compares it for stale warnings.
- Existing editor-only/runtime-safe boundaries: Add and Remove point authoring are editor-plugin behavior. River mesh generation and bake state are shared River node behavior.
- Current validation scenes, debug views, or probes: existing validation scenes cover river mesh/bake behavior, but no dedicated Add-mode wrong-span validation artifact exists yet.
- Current known limitations: `add_point()` guesses new handles from neighboring control-point positions and does not preserve/split the original Bezier span.
- Current performance-sensitive paths: editor picking over baked points, river mesh regeneration, and bake source signature comparison.
- What should not be rediscovered or redesigned unnecessarily: River bake invalidation and WaterSystem stale detection already exist and should be reused.

## Research Questions

- Can Add mode pair a baked-curve insertion position with a different control-polygon segment index?
- Is Remove mode affected by any picking refactor?
- Should the fix change editor picking, `RiverManager.add_point()`, `insert_point_with_handles()`, or mesh generation?
- What behavior must be preserved for append mode, collider snapping, axis constraints, and plane constraints?
- Do River and WaterSystem stale warnings already react safely to curve edits?
- What must validation cover before implementation is accepted?

## Findings Matrix

| Question | Finding | Evidence or source | Waterways implication | Confidence |
| --- | --- | --- | --- | --- |
| Can Add mode mix position and span? | Yes. It computes `closest_segment` from control-point chords and `baked_closest_point` from baked curve segments, then passes both into `add_point()`. | `addons/waterways/plugin.gd` `_forward_3d_gui_input()` | Fix Add-mode hit selection so one hit result owns both position and span. | High |
| Why can this twist the mesh? | A wrong span causes `add_point()` to insert at `index + 1` and guess handles from unrelated neighboring control points. | `addons/waterways/river_manager.gd` `add_point()` | Correct span selection first; consider Bezier span splitting for shape preservation later. | High |
| Should mesh generation be the first fix target? | No. Mesh generation samples the rebuilt curve; it exposes the distorted authored curve rather than causing the initial wrong insert. | `addons/waterways/water_helper_methods.gd` `generate_river_mesh()` | Avoid broad mesh orientation changes for this bug. | High |
| Is Remove mode coupled to the pick logic? | Yes. Remove uses the shared hit-test setup as a near-visible-curve gate, then removes the nearest control point to `baked_closest_point`. | `addons/waterways/plugin.gd` Remove branch | Preserve Remove UX when extracting or changing picking helpers. | High |
| Does append mode share the risky on-curve insertion path? | Only after hit-test failure. It uses `closest_segment == -1`, then computes a new point from the last point with constraints. | `addons/waterways/plugin.gd` Add branch | Preserve append behavior and constraints while fixing on-curve insertion. | High |
| Can `insert_point_with_handles()` solve this by itself? | Not by itself. It accepts explicit handles and a direct insert index, but does not compute split handles or map baked hits to spans. | `addons/waterways/river_manager.gd` `insert_point_with_handles()` | It is useful for a stronger helper, but the caller must supply correct span/handles. | Medium |
| Are stale River and WaterSystem maps handled? | Yes. Curve edits invalidate River bake state, and WaterSystem compares child River source metadata. | `river_manager.gd`; `water_system_manager.gd` | No separate stale-map system is needed for this fix. | High |

## Comparable Patterns

For spline/curve authoring, robust insertion usually uses one parameterized hit along the visible curve, then derives both the new point position and the owning segment from that same parameter. A stronger authoring experience splits the underlying Bezier span so the visual curve changes minimally when the new control point is inserted.

Relevant principles for this feature:

- Use one source of truth for selection: do not mix proximity to a control polygon with proximity to the visible curve unless the mapping is explicit.
- Preserve author intent: clicking the visible river should insert into the visible span being clicked.
- Prefer shape-preserving insertion where possible: splitting a Bezier span avoids sudden curve kinks.
- Keep downstream mesh generation deterministic: mesh generation should respond to the authored curve, not compensate for editor picking mistakes.

## Godot 4.6+ Findings

Known local Godot 4.6.3 executables:

- Console/script runner: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64_console.exe`
- GUI editor: `C:\Users\pc\Desktop\Godot_v4.6.3-stable\Godot_v4.6.3-stable_win64.exe`

Relevant local API use:

- `EditorPlugin._forward_3d_gui_input()` handles River Add/Remove input.
- `Geometry3D.get_closest_points_between_segments()` is used for mouse-ray proximity against control and baked segments.
- `Curve3D.get_baked_points()` supplies visible path samples for editor picking and gizmo path drawing.
- `Curve3D.sample()` is already used elsewhere for approximate interval sampling in width interpolation.
- `Curve3D.sample_baked()` is used for mesh sampling and river width sampling.
- `PhysicsDirectSpaceState3D.intersect_ray()` and direct collision-shape checks are used only for collider snapping/flow-map support, not the on-curve Add bug itself.

No external Godot documentation was needed for this pass; the research is grounded in active local code.

## Performance and Scale Findings

- Expected scene scale: editor-time point insertion on individual River nodes.
- Expected river count, curve complexity, or generated mesh size: typical authoring uses a modest number of control points, but baked point count grows with curve length and `curve.bake_interval`.
- Expected bake texture sizes: unchanged by the picking fix.
- Expected runtime texture memory: unchanged.
- Editor bake-time risks: curve edits invalidate existing River bakes and may require rebaking; this is existing behavior.
- Runtime frame-time risks: none expected if the fix stays editor-only.
- GPU readback risks: none for Add-mode picking.
- Physics query or raycast-count risks: append collider snapping already performs ray/collider checks; on-curve insertion should not add physics queries.
- Renderer/backend assumptions: none for the Add picking fix.
- Mobile, Compatibility, or VR constraints: none expected for editor-only behavior.
- Recommended budget or measurement approach: keep on-curve hit search linear in baked point count, matching the current behavior unless a later feature needs acceleration.

## Existing Waterways Reference

- Relevant existing files:
  - `addons/waterways/plugin.gd`
  - `addons/waterways/river_manager.gd`
  - `addons/waterways/river_gizmo.gd`
  - `addons/waterways/water_helper_methods.gd`
  - `addons/waterways/water_system_manager.gd`
- Behavior to preserve:
  - Add beyond the end when not clicking the curve.
  - Collider snapping for append mode.
  - Axis and plane constraints for append mode.
  - Remove mode as visible-curve click gate plus nearest-control-point removal.
  - Undo/redo shape restoration.
  - River and WaterSystem stale warnings.
- Behavior to change:
  - On-curve Add insertion must derive position and insertion span from one consistent hit source.
- Obsolete or fragile APIs to avoid:
  - Avoid changing `add_point()` semantics broadly because it is a public-style River API.
- Risks discovered in `audit/code-audit.md`: not reviewed in this pass.
- What belongs in active Godot 4.6+ code:
  - Editor-only picking helper in `plugin.gd` or a small helper reachable from editor code.
  - Optional RiverManager helper if implementing shape-preserving split insertion.
- What should remain out of scope:
  - Flow-map shader changes.
  - River mesh row-orientation rewrites.
  - WaterSystem bake metadata redesign.

## Options

### Option A: Consistent Baked-Hit Span For Add Mode

- Benefits: lowest-risk fix; keeps `add_point()` compatible; targets the confirmed mismatch; should preserve simple-river behavior.
- Costs: still uses `add_point()` guessed handles, so inserted points may not perfectly preserve highly curved spans.
- Risks: mapping baked samples back to control spans must be careful on self-near curves.
- Fit for Waterways: strong first fix because the bug is editor-picking-local.
- Source/reuse constraints: based entirely on active local code.

### Option B: Shape-Preserving Bezier Span Split

- Benefits: best authoring quality; keeps the curve shape nearly unchanged when adding a point; can use `insert_point_with_handles()` or a new RiverManager helper.
- Costs: more implementation complexity; must calculate split handles and update adjacent handles correctly.
- Risks: mistakes can alter handles, widths, undo state, or serialized curve shape more broadly than Option A.
- Fit for Waterways: good follow-up or stronger fix after the source-span mismatch is corrected.
- Source/reuse constraints: implement from local math/API knowledge; do not copy external code without license review.

### Option C: Mesh Generation Compensation

- Benefits: could reduce visible twists for some already-distorted curves.
- Costs: does not fix the authored curve or wrong inserted point.
- Risks: broad behavior change for every River mesh, bake, shader sample, and WaterSystem render.
- Fit for Waterways: poor first fix for this bug.
- Source/reuse constraints: not recommended.

## Recommendation

- Recommended direction: implement Option A first, then consider Option B if authoring still produces visible kinks when insertion span is correct.
- Why this fits Waterways: it fixes the confirmed editor mismatch while preserving runtime behavior, saved scenes, existing River APIs, and current bake/stale systems.
- What to do first: create a single Add-mode curve-hit result that carries local closest point and owning control-point span, then use that result for on-curve insertion.
- What to defer: Bezier split-handle math and any width interpolation improvements beyond what is needed for correct span selection.
- What to avoid: changing mesh generation as a workaround; changing Remove mode to remove by baked segment owner; changing `add_point()` semantics for all callers.
- Confidence: High

## Spec Implications

- User/developer workflows: clicking the visible River curve in Add mode should insert into the visible span being clicked.
- Functional requirements:
  - Add mode must derive insertion position and span from the same hit result.
  - Add mode must continue appending beyond the end when no curve hit is found.
  - Remove mode must preserve existing visible-curve click behavior.
- Non-functional requirements:
  - No runtime behavior change for existing scenes until a user edits a River.
  - Editor picking should remain responsive on typical baked curve sizes.
- Editor usability requirements:
  - Straight and simple curves should feel unchanged.
  - Tight/self-near curves should insert into the clicked visible span.
  - Constraint controls should continue affecting append behavior.
- Runtime/API requirements:
  - `RiverManager.add_point()` should remain compatible.
- Generated asset/resource requirements:
  - Any curve edit should invalidate River bakes and surface WaterSystem stale warnings through existing metadata paths.
- Acceptance criteria:
  - Wrong-span insert cannot be reproduced on a tight/self-near test curve.
  - Undo/redo restores curve state and bake-valid state as expected.
  - Remove mode still removes the nearest authored point to the visible hit.
- Non-goals:
  - Do not solve all possible self-intersecting curve width interpolation issues.
  - Do not redesign bake metadata.
- Open questions to carry forward:
  - Should the first implementation include shape-preserving Bezier splitting or only correct span selection?

## Plan Implications

- Architecture direction: keep the first fix in editor Add picking; optionally add a narrow RiverManager helper only for explicit shape-preserving insertion.
- Affected files/modules:
  - `addons/waterways/plugin.gd`
  - possibly `addons/waterways/river_manager.gd`
  - validation docs/scenes if added
- Editor-only code:
  - hit-test helper and Add/Remove behavior are editor plugin code.
- Runtime-safe code:
  - keep existing RiverManager API behavior unless adding a compatible helper.
- Shared resources/data:
  - curve, widths, generated mesh, River bake data, WaterSystem bake data.
- Texture channels, data formats, and metadata:
  - no channel/data format changes expected.
- Import/export expectations:
  - none expected.
- Lifecycle, cleanup, and re-entry concerns:
  - preserve undo/redo actions and `update_configuration_warnings()`.
- Migration or compatibility concerns:
  - existing saved scenes should not be migrated; behavior changes only on future Add edits.
- Documentation updates needed:
  - update findings/spec/validation notes after implementation choice is made.

## Validation Implications

- Automated checks:
  - If feasible, add a script-level Curve3D test for hit-to-span mapping on simple and self-near curves.
- Human-assisted Godot/editor checks:
  - Add a point on a straight span.
  - Add a point on a tight bend.
  - Add a point on a self-near or looping river where control chord proximity is ambiguous.
  - Append beyond the river end.
  - Append with no constraint, collider snapping, axis constraints, and plane constraints.
  - Remove points after any picking refactor.
- Visual scene or debug-view checks:
  - Confirm the inserted point appears on the clicked visible span.
  - Confirm the river mesh does not twist or invert after insertion.
- Shader checks:
  - None specific beyond existing valid/invalid bake behavior.
- Bake-output checks:
  - River `valid_flowmap` becomes false after Add/Remove.
  - Regenerated River map can be produced after edit.
  - WaterSystem stale warning appears when child River metadata changes.
- Runtime/API checks:
  - Existing `add_point()` script callers still behave as before.
- Performance checks:
  - Editor hit-testing remains responsive on long baked curves.
- Artifact hygiene checks:
  - Do not modify generated bake resources unless validation explicitly requires rebaking.
- Failure signs that should stop implementation:
  - Remove mode removes by segment owner instead of nearest authored point.
  - Append constraints stop working.
  - Undo does not restore curve or bake-valid state.
  - Existing straight Add behavior changes visibly.

## Risks and Unknowns

- Mapping from baked point index to owning control span may be non-trivial if only `get_baked_points()` is used.
- Self-near curves can make proximity-based mapping ambiguous; parameter order may need to win over raw spatial proximity.
- Shape-preserving Bezier splitting is a stronger fix but adds handle-math risk.
- `generate_river_width_values()` has a separate proximity-based span inference that can be ambiguous on self-near curves, but it should not block the Add-mode fix.
- Interactive editor reproduction has not yet been performed in this research pass.

## Context Challenge Notes

- Possible misread context: the visual twist might appear to be a mesh-generation defect.
- Evidence: mesh generation samples the final curve and derives row orientation from nearby sampled positions; the earlier Add insertion can already create the distorted curve.
- Confidence: High
- Quick check before patching: reproduce with a tight/self-near curve and inspect the inserted control point order and handles.
- User-facing note or question to raise: the first fix should improve insertion span correctness, but a separate shape-preserving split may still be needed for ideal Bezier authoring.
- Outcome after the check: pending interactive validation.

## Source Quality and Reuse Notes

Source categories:

- Local active code: primary evidence.
- Local spec/validation docs: existing `findings.md` and session handoff informed this research.
- Official Godot docs: not used in this pass.
- Official tool/engine docs: not used in this pass.
- Academic paper or production talk: not used.
- Open-source repo: not used beyond this local repository.
- Tutorial or blog: not used.
- Forum, issue, Reddit, or informal discussion: not used.
- Agent inference: used to connect wrong-span insertion to downstream mesh twist risk.

Reuse/licensing notes:

- License: local project/add-on source appears to be MIT-licensed per file headers.
- Code-copy allowed: no external code copied.
- Conceptual reference only: comparable spline insertion principles are conceptual.
- Attribution needed: none beyond local source references.
- Compatibility concern: keep public-style `RiverManager.add_point()` behavior compatible.

## Sources

| Source | Type | Why it matters | Reuse/licensing note |
| --- | --- | --- | --- |
| `spec-driven/features/river-add-wrong-span/findings.md` | Local spec/validation docs | Captures the original suspicion, impact analysis, and follow-up investigation. | Local documentation. |
| `spec-driven/features/river-add-wrong-span/session-handoff.md` | Local spec/validation docs | Defines the requested investigation scope. | Local documentation. |
| `addons/waterways/plugin.gd` | Local active code | Contains Add/Remove editor picking, append constraints, and undo/redo actions. | MIT project code; no external reuse concern. |
| `addons/waterways/river_manager.gd` | Local active code | Contains `add_point()`, `insert_point_with_handles()`, curve state restore, bake invalidation, and source signatures. | MIT project code; no external reuse concern. |
| `addons/waterways/water_helper_methods.gd` | Local active code | Shows downstream mesh and width sampling behavior after the authored curve changes. | MIT project code; no external reuse concern. |
| `addons/waterways/water_system_manager.gd` | Local active code | Shows child River metadata comparison and stale WaterSystem warnings. | MIT project code; no external reuse concern. |
| `addons/waterways/river_gizmo.gd` | Local active code | Provides append constraint helpers and handle editing undo patterns relevant to preserving editor UX. | MIT project code; no external reuse concern. |
