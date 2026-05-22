# Research: Curve-Derived River Flow

## Purpose

Summarize the completed research for the curve-derived river flow feature in the standard feature-folder shape.

- Decision needed: whether `River -> Generate Flow & Foam Map` should derive baseline downstream RG flow from the River curve instead of relying on collider hits for all meaningful direction.
- Why this cannot go straight to implementation: the change touches generated texture semantics, UV2 atlas padding, editor bake behavior, shader debug interpretation, metadata, compatibility, and visual validation.
- Expected consumer:
  - `spec.md`
  - `plan.md`
  - `validation.md`
  - `tasks.md`
- Full research record: `preliminary_research.md`.

## Current Research Outcome

- Status: Complete, with a 2026-05-22 post-regression baseline update needed in downstream docs.
- Recommendation: build the broader `Curve + Collision Modifiers` feature on top of the completed downstream-baseline regression fix rather than reimplementing it from scratch.
- Confidence: High for the authoring-design change; medium for later directional collision deflection because a confidence rule is still needed.
- Biggest unknown that remains: the exact collision-confidence metric for future directional RG blending.
- Decision or plan section this research unlocked: `plan.md` Data Model, Bake Flow, Validation Strategy, and Risks.
- Requirements this research implies: non-neutral downstream RG in occupied river atlas texels, preserved padded UV2 atlas layout, explicit source metadata, vector-length diagnostics, and human-assisted visual validation.
- Non-goals or rejected ideas this research supports: no broad `river.gdshader` rewrite, no raw world X/Z RG encoding, no collider requirement for baseline flow, and no first-pass directional collision RG blending.
- Validation this research requires: a canonical visible validation scene plus vector-stat diagnostics, bake-output checks, shader debug checks, save/reload checks, and performance measurements.

## Premise Check

- Reported or assumed problem: before the regression fix, generated River flow could become stationary or directionally meaningless after rebake when no useful collider pixels were detected.
- Evidence supporting the premise:
  - Current bake warnings reported no collider pixels and flat RG, foam, and distance/pressure maps.
  - Current shader fallback flow animates when a generated bake is invalid, so a rebake can visibly replace fallback motion with neutral generated data.
  - Pre-fix default generated RG came from collision-derived normals; empty or uniform collision input could produce flat near-neutral vectors. Current default generated RG now uses `downstream_baseline_collision_support`.
- Evidence against the premise:
  - The collision-first baseline is inherited from original Waterways behavior, not clearly a Godot 4 port regression.
  - Empty or flat generated data can be expected behavior for the current design when bake helpers are absent, on the wrong layer, below the raycast volume, or too uniform.
- Possible expected-behavior explanation: the reported warning was likely accurate; the existing bake saw no useful collider pixels.
- Confidence: High that this is a real authoring-design limitation; medium-high that it is inherited behavior.
- Smallest check that can falsify the premise: run `Generate Flow & Foam Map`, then `Validate Data Textures`, and inspect Flow Pattern plus Flow Arrows in a representative scene. If collision hits and non-neutral vector stats are present but the river is still stationary, the issue is not just no-collider baseline dependency.
- User-facing note or question to raise before patching: this feature is an authoring improvement, not proof that the current no-collider warning is false.

## Active Add-on Baseline

- Relevant active files:
  - `addons/waterways/river_manager.gd`
  - `addons/waterways/water_helper_methods.gd`
  - `addons/waterways/resources/river_bake_data.gd`
  - `addons/waterways/shaders/river.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
- Current behavior:
  - `_generate_flowmap()` still creates a collision map and runs support filter passes when the current preflight succeeds.
  - In the default `downstream_baseline_collision_support` behavior, `_generate_flowmap()` combines a padded local downstream `+V` baseline into `flow_foam_noise.rg` instead of using collision-derived `normal_to_flow` as primary direction.
  - `legacy_collision_only` preserves the older collision-derived RG path for comparison.
  - `river.gdshader` decodes RG as `(flow - 0.5) * 2.0`.
  - invalid generated maps use shader fallback flow.
- Existing extension points:
  - River bake settings.
  - `RiverBakeData.source_kind`, source metadata, channel metadata, import profile, and source signature.
  - Validation/debug views including Flow Pattern and Flow Arrows.
- Existing generated data, resources, channels, or metadata:
  - `flow_foam_noise.rg`: packed signed flow.
  - `flow_foam_noise.b`: foam.
  - `flow_foam_noise.a`: phase/noise.
  - `dist_pressure.rg`: distance/pressure support data.
  - Texture layout: `padded_uv2_atlas_with_one_tile_margin`.
- Existing editor-only/runtime-safe boundaries:
  - Collision probing and filter rendering are editor bake concerns.
  - Runtime shader consumption uses serialized textures and uniforms.
- Current validation scenes, debug views, or probes:
  - `scenes/validation/two_phase_flow_validation.tscn` proves shader consumption of hand-authored maps, not the new bake path.
- Current known limitations:
  - This implementation slice now allows curve-based zero-layer bakes.
  - `Curve Only` behavior now exists through `bake_generation_behavior = "curve_only"`.
  - Nonzero-layer no-hit bakes now use explicit blank support-map semantics.
  - Flow Arrows now suppress near-neutral raw vectors, but a direct neutral-visible check is still useful future evidence.
- Current performance-sensitive paths:
  - Per-texel collision probing.
  - Filter-renderer passes and GPU readbacks.
  - Any future CPU image generation at high bake resolutions.
- What should not be rediscovered or redesigned unnecessarily:
  - The shader channel contract.
  - The padded UV2 atlas layout.
  - Existing material speed controls.
  - External `RiverBakeData` storage.

## Research Questions

- Should curve-derived flow be the default generated RG layer?
- Should generation modes exist for curve-only, curve-plus-collision, and legacy collision behavior?
- How should curve direction be encoded across the UV2 tile atlas and seams?
- Should speed come from per-point metadata, slope, material settings, or a new control?
- How should near-zero vectors be represented in Flow Arrows? Current baseline uses a dark neutral display below decoded magnitude `0.02`; future styling is optional.
- Can collision-derived foam, pressure, and distance stay while replacing default RG?
- How should bake helper, snap target, and gameplay collider roles be documented?

## Findings Matrix

| Question | Finding | Evidence or source | Waterways implication | Confidence |
| --- | --- | --- | --- | --- |
| Should curve-derived flow be default? | Yes. Active Waterways now uses local downstream `+V` as the default RG baseline. | Current code, local probes, and comparable spline-first systems in `preliminary_research.md`. | Treat `downstream_baseline_collision_support` as the current foundation for broader `Curve + Collision Modifiers`. | High |
| Should modes exist? | Yes in data/model; UI exposure can be gradual. | Existing source metadata and compatibility needs. | Extend serialized `bake_generation_behavior` first; defer public `baking_generation_mode` until validation proves the workflow. | High |
| How should RG be encoded? | Encode in river texture/tangent frame, not raw world X/Z. | Shader applies decoded RG through `TANGENT` and `BINORMAL`. | First pass writes local downstream `+V` for occupied atlas texels. | High |
| How should UV2 margins work? | Preserve the current padded atlas layout. | Existing `add_margins(...)` has UV2 column-continuation handling. | Generate source RG, then pad before combine. | High |
| Should collision RG be blended now? | No. Defer until confidence rules are defined. | Expert review concern about blending useful curve flow toward neutral. | First implementation uses collision only for foam, distance, and pressure. | High |
| What should no-collider support maps contain? | Use blank support maps with `dist_pressure.rg = (0.0, 0.0)`. | Revised plan's shader-force analysis. | Curve-only and no-hit fallback can still show default material force. | Medium-high |
| What visual proof is needed? | A new bake-path validation scene is required. | Existing two-phase scene validates shader consumption only. | Add `scenes/validation/curve_derived_river_flow_validation.tscn`. | High |

## Comparable Patterns

The completed research found that mature tools usually separate base motion intent from obstacle or bank modifiers. Spline-first systems use the path or authored velocity as flow intent; flow-map tools and shaders consume packed vector fields without caring whether vectors came from splines, terrain, simulation, or paint; obstacle systems commonly modify an existing field rather than being the only source of movement.

## Godot 4.6+ Findings

- Active implementation should target Godot 4.6+ APIs in `addons/waterways`.
- Editor bake behavior and runtime shader consumption must stay separated.
- Visible editor and shader behavior require human-assisted validation in this workspace.
- Parser/static checks are useful but do not prove viewport motion, gizmo behavior, shader output, bake correctness, or runtime behavior.
- Data textures must keep linear/lossless expectations and the existing packed RG contract.

## Performance and Scale Findings

- Expected bake texture sizes: `64` through `1024`, based on `2^(6 + baking_resolution)`.
- Runtime texture memory should remain the same order: one padded `flow_foam_noise` texture and one padded `dist_pressure` texture.
- First-pass curve RG generation should avoid per-texel nearest-curve world searches and use UV2 tile progress.
- Performance validation should measure bake time at low, medium, and highest supported `baking_resolution`.

## Legacy Waterways Reference

- Relevant legacy behavior: original Waterways generated flow from collision-derived data.
- Behavior to preserve: legacy collision-derived result should remain reproducible as `Collision Legacy`.
- Behavior to change: default generated flow should no longer require collider hits for downstream motion.
- Obsolete APIs to avoid: Godot 3 APIs must not be copied into active Godot 4.6+ code.
- What belongs in active Godot 4.6+ code: compatible behavior, not obsolete implementation details.

## Options

### Option A: Keep Collision-First Generation

- Benefits: minimal change and maximum compatibility.
- Costs: preserves no-collider/flat-collider neutral-flow failure mode.
- Risks: users continue seeing regenerated rivers appear stationary.
- Fit for Waterways: useful only as legacy comparison.

### Option B: Curve Baseline With Collision Support Modifiers

- Benefits: preserves downstream authoring intent while keeping foam, pressure, and bank detail.
- Costs: requires source kinds, mode metadata, bake-path changes, diagnostics, docs, and validation.
- Risks: default rebakes can visibly change existing scenes.
- Fit for Waterways: best match for a reusable flow-map add-on.

### Option C: Full Directional Collision Deflection Now

- Benefits: more complete obstacle behavior.
- Costs: requires a robust collision-confidence rule and more validation.
- Risks: can blend useful curve flow toward neutral when data is empty or low-confidence.
- Fit for Waterways: deferred follow-up.

## Recommendation

- Recommended direction: implement Option B first.
- Why this fits Waterways: the River curve already carries downstream intent, while colliders are better treated as optional support detail sources.
- What to do first: rebase the feature docs against current Waterways behavior, then add the remaining mode semantics, no-collider / zero-layer behavior, exact blank support fallback, and canonical curve-derived validation scene.
- What to defer: directional collision RG blending and broader speed/velocity features.
- What to avoid: world-space X/Z RG encoding and any main river shader rewrite in the first slice.
- Confidence: High.

## Post-Regression Baseline

The flow-map direction regression slice completed after this research was first written. Active Waterways now already does several things this feature originally planned:

- Default generated River RG uses a local downstream `+V` baseline via `downstream_baseline_collision_support`.
- Legacy collision-derived comparison remains available through `bake_generation_behavior = "legacy_collision_only"`.
- `RiverBakeData` records `generated_downstream_baseline_collision_bake` for the current default path.
- Decoded flow-vector stats, occupied/unused UV2 atlas stats, unused atlas RG neutralization, and near-neutral thresholding are implemented.
- `river_debug.gdshader` suppresses near-neutral Flow Arrows.
- WaterSystem validation reports alpha-covered decoded flow stats.
- User-facing docs now describe the current default downstream-baseline behavior.

The original recommendation still points in the right direction, but the next implementation should treat the completed regression fix as the baseline. The remaining research-to-plan translation is about mode naming, no-collider / zero-layer success, `Curve Only`, canonical curved/seam validation, and future collision deflection, not about proving that default generated RG needs a downstream baseline.

## Spec Implications

- Generated bakes should produce non-neutral downstream RG inside occupied river atlas texels in curve-based modes.
- `Curve Only`, `Curve + Collision Modifiers`, and `Collision Legacy` should exist in the data model.
- No-collider curve-based bakes should succeed.
- `Collision Legacy` should preserve current collision-derived behavior.
- Vector diagnostics and near-zero Flow Arrow behavior are required.
- Imported/manual maps keep the existing channel contract.

## Plan Implications

- Extend serialized `bake_generation_behavior` for the remaining behavior semantics.
- Add only the new `RiverBakeData` source kinds required by implemented behavior, while preserving current source kinds.
- Generate curve RG in source-size atlas, then pad with `WaterHelperMethods.add_margins(...)`.
- Keep collision support processing on padded textures when collision input has useful hits; use explicit blank padded support maps when collision is skipped or has no hits.
- Build exact blank no-collider support maps when collision is skipped or has no hits.
- Write source metadata and vector stats.
- Add canonical validation scene and docs.

## Validation Implications

- Automated checks:
  - Static scan for source kinds, generation mode, metadata, source signature, and absence of default-mode RG blending.
  - Parser/editor-load check if local Godot can run it.
  - Unit-like image probe if practical.
- Human-assisted checks:
  - Visible Godot editor bake and debug view validation.
  - Save/reload and runtime/F6 check.
  - Performance measurement at representative resolutions.
- Failure signs:
  - Neutral or near-neutral RG in occupied no-collider river texels.
  - World-space direction encoded into RG.
  - Collision RG used as default mode flow without confidence gating.
  - Empty collider input running support filters instead of explicit fallback.

## Risks and Unknowns

- Directional collision blend could drift toward neutral without a robust confidence rule.
- Blank support-map fallback could still reduce visible motion under some material settings.
- UV2 seam padding could smear or flip at column-continuation boundaries.
- Validation depends on human-visible Godot editor checks.

## Context Challenge Notes

- Possible misread context: treating accurate no-collider warnings as a raycast bug.
- Evidence: the legacy collision-first generated bake can find no collider pixels, and collision-first generation can produce near-neutral maps. Current default generation now applies a downstream baseline before this broader feature continues.
- Confidence: Medium-high.
- Quick check before patching: validate generated data textures and debug views in a representative scene.
- User-facing note or question to raise: the feature improves authoring robustness; it does not mean the current warning is false.
- Outcome after the check: pending implementation validation.

## Source Quality and Reuse Notes

- Local active code is authoritative for current behavior.
- Original Waterways is a behavioral reference, not an API target.
- External engine/tool documentation is conceptual support, not code to copy.
- Tutorials and production talks support shader/data-flow concepts but do not define Waterways implementation.

## Sources

| Source | Type | Why it matters | Reuse/licensing note |
| --- | --- | --- | --- |
| `preliminary_research.md` | Local research record | Full evidence, comparison, and conclusions for this feature. | Internal project documentation. |
| `addons/waterways/river_manager.gd` | Local active code | Current bake orchestration, filtering, combine, metadata, and diagnostics. | MIT project code. |
| `addons/waterways/water_helper_methods.gd` | Local active code | Collision probing and UV2 margin padding behavior. | MIT project code. |
| `addons/waterways/shaders/river.gdshader` | Local active shader | Packed RG decode and fallback flow behavior. | MIT project code. |
| Original Waterways Godot 3 add-on | Legacy reference | Confirms collision-first behavior is inherited. | Reference only for active Godot 4.6+ porting. |
| Comparable flow-map and water systems listed in `preliminary_research.md` | Official docs, tutorials, production references | Support separation of base flow intent from modifiers. | Conceptual reference only. |
