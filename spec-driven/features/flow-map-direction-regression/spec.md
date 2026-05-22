# Spec: Flow Map Direction Regression

## Summary

The existing `River -> Generate Flow & Foam Map` path must produce, display, and compose reliable downstream flow for Rivers whose collision-derived bake input is flat or uniform.

The confirmed failure is not that final River combine destroys a good vector. The real Godot 4.6.3 dump shows the occupied River tiles are already effectively neutral immediately after `normal_to_flow_filter.gdshader`. The add-on then marks the result valid, Flow Arrows render a confident direction from near-zero quantized RG, unused atlas tiles contain stronger arbitrary vectors, and WaterSystem composition can turn weak or edge-derived data into misleading world flow.

This spec covers the existing collision-derived River bake/debug/WaterSystem composition path. The broader `curve-derived-river-flow` feature is adjacent history and a useful design reference, but it remains out of scope unless this spec explicitly names a boundary.

## Current Truth

- Status: First implementation slice is locally validated; visible editor validation remains open.
- Source of truth for open work: `tasks.md`.
- Last meaningful decision: default generation now uses a local downstream baseline with collision support, while legacy collision-only remains available as an explicit comparison behavior.
- Known deferred items: full curve-derived river flow feature, per-point speed, terrain simulation, confluences, waterfalls, and broad runtime sampling APIs.
- Current non-goals that are easy to accidentally reopen:
  - Do not rewrite `river.gdshader` two-phase animation unless a separate defect is proven.
  - Do not merge this folder into the separate `curve-derived-river-flow` feature.
  - Do not remove the script/storage legacy collision-only behavior without a compatibility decision.
  - Do not treat angle-only vector stats as proof of meaningful flow.

## Goals

- Flat occupied collision interiors must not silently produce a valid-looking but unusable downstream River flow map.
- River debug views must distinguish meaningful vectors from near-neutral quantization.
- Unused UV2 atlas tiles must not leak strong arbitrary vectors into visible river output.
- WaterSystem composition must not amplify near-neutral, edge-derived, or unused-atlas data into misleading flow.
- Generated textures and bake metadata must be explicit enough for future debugging.
- Compatibility with existing saved River and WaterSystem bake resources must be preserved.

## Non-Goals

- Do not implement the complete `curve-derived-river-flow` feature in this folder.
- Do not add per-point velocity, reverse-flow authoring, slope-derived speed, terrain/hydrology simulation, confluence handling, or waterfall handling.
- Do not replace the packed RG channel contract: neutral remains `(0.5, 0.5)`, decoded as `(flow - 0.5) * 2.0`.
- Do not require a visible generation-mode UI in the first implementation.
- Do not remove or silently break the current collision-derived output path before a legacy/compatibility path is specified and validated.
- Do not rely on local parser/headless checks as proof of visible editor, debug shader, bake, or runtime behavior.

## Context and Assumptions

- Known scene/data/context facts:
  - Active workspace: `C:\Users\pc\Documents\GitHub\Godot 4 Waterways`.
  - Validation scene: `scenes/validation/flow_map_direction_verification.tscn`.
  - Existing River bake writes padded `flow_foam_noise` and `dist_pressure` textures into `RiverBakeData`.
  - The current River source image for the known repro is `256x256`, padded to `426x426`.
  - The UV2 atlas side count is `3`; six tiles are occupied and three are unused.
  - Real Godot 4.6.3 dump evidence exists under `.codex-research/flow_map_direction_verification/intermediate_dump_godot_463`.
- User-reported observations:
  - Straight River Flow Arrows appear diagonal or distorted after River and WaterSystem generation.
  - Visible flow does not clearly move straight downstream.
- Agent confidence in the premise:
  - High that the current collision-derived path cannot infer useful downstream direction from flat occupied collision interiors.
  - High that Flow Arrows currently misrepresent near-neutral vectors.
  - Medium that unused atlas and WaterSystem composition are visible amplifiers after the generation issue.
- Possible expected-behavior explanations to rule out before patching:
  - Debug arrows may show quantization direction, not real flow.
  - A fully flat collision mask has no interior gradient.
  - Old generated resources may be stale relative to current code or settings.
- Clarification or challenge already raised with the user:
  - The fix should not be a Flow Arrows-only patch. The River bake lacks a useful downstream vector before final combine.

## Users and Workflows

### User Story: Bake A Straight River Over Flat Collision

As a Waterways user, I want `River -> Generate Flow & Foam Map` to produce usable downstream flow for a straight River over flat occupied collision input, so that a simple validation scene does not become stationary, diagonal, or misleading after a valid bake.

Acceptance criteria:

- Occupied River tile interiors contain meaningful downstream RG vectors or the bake clearly reports that directional generation is invalid/reduced.
- A simple straight River does not depend on edge artifacts or unused atlas cells to show direction.
- `RiverBakeData` records enough source metadata and stats to distinguish useful flow from neutral output.

### User Story: Interpret Flow Debug Views

As a user debugging generated maps, I want Flow Map, Flow Pattern, and Flow Arrows to communicate neutral, weak, and directional data honestly, so that near-zero RG does not look like a confident diagonal flow field.

Acceptance criteria:

- Flow Arrows hide, fade, dot, or otherwise mark near-neutral vectors instead of rotating arrows from an unstable angle.
- Flow Map and validation output report decoded vector magnitudes, not only channel contrast.
- Flow Pattern remains useful for visible movement checks and does not mask a neutral generated map as a success.

### User Story: Compose Rivers Into A WaterSystem

As a WaterSystem author, I want generated River flow to be composed into the system map without amplifying neutral or invalid source data, so that world-space flow output reflects real River direction.

Acceptance criteria:

- WaterSystem composition preserves a meaningful River flow field when one exists.
- Near-neutral source vectors are clamped, ignored, marked neutral, or diagnosed before force/world transform creates misleading packed RG.
- WaterSystem generated metadata and validation can report near-neutral flow over alpha-covered pixels.

### User Story: Maintain Legacy Comparisons

As an add-on maintainer, I want to compare the legacy collision-derived result against the hardened result, so that compatibility changes are explicit and reviewable.

Acceptance criteria:

- Existing resources with `generated_spline_collision_bake` remain readable.
- A collision-only comparison path remains available as a legacy behavior, compatibility setting, or diagnostic mode.
- Legacy output may still be neutral for flat collision input, but it must not be confused with the default expected behavior unless the user explicitly selected it.

## Functional Requirements

- FR-1: The River bake must not mark a flat-collision, near-neutral directional field as an unquestioned successful downstream flow result without diagnostics.
- FR-2: For the normal existing River bake workflow, occupied collision interiors must receive a meaningful downstream baseline or an explicit directional invalid/reduced-detail state.
- FR-3: The downstream baseline, if generated, must use the existing River mesh/UV progression and shader coordinate contract. It must not encode raw world X/Z into River RG unless the River shader contract is revised in a separate spec.
- FR-4: Collision-derived gradients may provide foam, pressure, edge/detail, local modifiers, and diagnostics, but they must not be the only primary source of flow direction when the collision mask is flat.
- FR-5: Existing collision-only behavior must remain available for compatibility or comparison until a maintainer explicitly removes it under a separate compatibility decision.
- FR-6: `RiverBakeData` must remain explicit and inspectable, including texture sizes, `content_rect`, `uv2_sides`, source kind, source metadata, source signature, and channel metadata.
- FR-7: Generated metadata or validation output must include decoded flow-vector statistics for the source-region crop, including near-neutral percentage.
- FR-8: Unused UV2 atlas cells beyond the occupied River steps must be neutral RG or excluded from filtering/composition so they cannot leak strong arbitrary flow into visible river output.
- FR-9: UV2 margin padding must preserve column-continuation behavior across occupied tiles and clamp start/end margins so empty atlas cells do not bleed into River ends.
- FR-10: `river_debug.gdshader` Flow Arrows must threshold near-neutral decoded vectors before computing or applying directional arrow rotation.
- FR-11: The near-neutral debug threshold must not hide deliberately slow but meaningful vectors without visible/diagnostic evidence.
- FR-12: WaterSystem composition must review near-neutral raw River vectors before applying force/world transform. If needed, it must clamp, ignore, or mark them neutral before repacking into world-flow RG.
- FR-13: WaterSystem diagnostics must report decoded vector magnitude over alpha-covered pixels, not only channel min/max/average.
- FR-14: Existing imported/manual maps must preserve the packed RG interpretation and should not be rewritten by this regression fix unless the user runs an explicit generation action.
- FR-15: River and WaterSystem save/reload behavior must continue to use serialized bake resources and not live editor-only state.

## Non-Functional Requirements

- Maintainability:
  - Keep changes localized to River bake generation/diagnostics, atlas neutralization, debug shader thresholding, WaterSystem composition diagnostics or thresholding, and docs.
  - Prefer small helpers in existing modules over a broad pipeline rewrite.
  - Document threshold choices and coordinate-space assumptions.
- Performance:
  - Avoid per-texel nearest-curve searches unless the plan revises this after measurement.
  - Avoid adding runtime shader cost unless WaterSystem/River thresholding requires a small measured shader change.
  - Keep automated image-stat probes reasonable at `1024x1024` source resolution.
- Visual quality:
  - Straight Rivers should visibly flow downstream.
  - Flow Arrows should be absent/neutral where data is neutral and directional where data is useful.
  - Edge artifacts should not dominate broad occupied interiors.
- Godot 4.6+ compatibility:
  - Active implementation must use Godot 4.6+ APIs and shader syntax.
  - Validation must record Godot version, renderer/backend, and whether a check was local or human-assisted.
- Editor usability:
  - Normal `Generate Flow & Foam Map` remains simple.
  - Warnings distinguish reduced collision detail from directional failure.
  - Debug views remain easy to switch through from the existing River menu.
- Runtime usability:
  - Runtime scenes consume saved textures and metadata.
  - Runtime use must not depend on editor-only colliders or filter renderers.
- Extensibility:
  - Metadata should leave room for the broader curve-derived feature, imported maps, hand-painted maps, and simulation/DCC sources.

## Add-on Boundary

Editor authoring responsibilities:

- River bake action and preflight.
- Flow/foam/distance/pressure generation.
- Bake warnings and validation output.
- Debug views and debug shader uniforms.
- Optional compatibility controls for collision-only behavior.

Bake/data responsibilities:

- Generated `flow_foam_noise` and `dist_pressure` texture creation.
- Padded UV2 atlas layout and source crop.
- Unused atlas neutrality.
- Decoded vector stats and metadata.
- External `.res` bake storage.

Runtime responsibilities:

- River shader consumption of packed RG flow and support maps.
- WaterSystem shader/render composition from serialized River textures.
- WaterSystem sampling of generated `system_map`.

Shared code must not depend on:

- Editor-only filter renderer state at runtime.
- Live bake helper colliders in shipped runtime scenes.
- Legacy Godot 3 APIs.
- A single validation scene, material preset, or project-specific collision layer.

## Data and Extension Model

Users should be able to:

- Run the existing River bake workflow.
- Inspect generated River debug views.
- Generate WaterSystem maps from valid River maps.
- Reproduce or compare legacy collision-only behavior when needed.
- Continue loading existing saved bake resources.

Extension points:

- `RiverBakeData.source_kind`.
- `RiverBakeData.source_metadata`.
- `RiverBakeData.source_signature`.
- Existing River bake settings.
- Existing shader material flow controls.
- WaterSystem generated map diagnostics.

Override rules:

- Generated River output may replace previous generated textures only when the user runs the bake action.
- Imported/manual textures must not be modified by validation or debug changes.
- If a legacy collision-only mode exists, selecting it means flat collision input may still produce neutral flow, but diagnostics must say so clearly.
- If a generated downstream baseline exists, collision-derived gradients must not blend it toward neutral unless a confidence rule says the collision vector is meaningful.

Shared systems must not hard-code:

- The validation scene path as the only supported geometry.
- A required bake helper collider layer other than the existing configurable raycast mask.
- A one-off special case for only six occupied tiles or only a `3x3` atlas.

## Acceptance Tests

- AT-1: Existing Godot 4.6.3 dump evidence is recorded as the pre-fix baseline: occupied tile interiors are near-neutral at `normal_to_flow`.
- AT-2: After implementation, straight flat-collision occupied tile interiors are not near-neutral in the default expected workflow, or the bake reports the directional field as invalid/reduced instead of silently valid.
- AT-3: Flow Arrows do not draw confident arrows for `[127,128]`, `[128,127]`, exact neutral, or other thresholded near-neutral RG samples.
- AT-4: Flow Pattern visibly moves downstream for the straight River after the accepted generation fix.
- AT-5: Flow Map debug view and validation output report decoded vector magnitude stats.
- AT-6: Unused atlas tile centers and interiors are neutral or excluded after the final River bake output.
- AT-7: UV2 column-continuation margins do not introduce flow flips or empty-tile bleed at tile seams, first tile, or last occupied tile.
- AT-8: WaterSystem output over alpha-covered pixels does not show strong arbitrary flow when River source vectors are near-neutral.
- AT-9: WaterSystem output preserves useful downstream flow when River source vectors are useful.
- AT-10: Existing saved River and WaterSystem bake resources load without forced migration.
- AT-11: Legacy collision-only comparison remains available and documented.
- AT-12: Save/reload or F6-style runtime validation uses serialized generated resources, not editor memory.

## Visual Validation Requirements

Visible Godot editor checks are required for:

- River Flow Map.
- River Flow Pattern.
- River Flow Arrows.
- River bake workflow.
- WaterSystem generated output.
- Save/reload and runtime-style behavior.

Required scene:

- `scenes/validation/flow_map_direction_verification.tscn`

Required visible scenarios:

- Straight two-point River with flat occupied collision input.
- Occupied tile interiors versus edge artifacts.
- Unused atlas tile behavior.
- WaterSystem output after River generation.
- Legacy collision-only comparison if implemented as a user-selectable path.

The validation request must be sent in chat when needed, including exact scene path, plugin state, menu actions, Output text to copy, visible behavior to describe or screenshot, Godot version, renderer, graphics device, and physics backend if relevant.

## Performance Requirements

- River bake time should not regress dramatically at existing supported `baking_resolution` values.
- Baseline/neutralization helpers should be O(pixel count) and avoid nearest-curve searches for the first implementation.
- WaterSystem thresholding or diagnostics should avoid expensive per-frame work. Composition-time checks are acceptable; runtime shader changes must be tiny and measured.
- Image-stat validation may sample or crop, but it must be precise enough to catch occupied-tile near-neutral output and unused-tile non-neutral output.

## Open Questions

- What exact decoded vector magnitude threshold defines near-neutral for:
  - River Flow Arrows?
  - River generated-data diagnostics?
  - WaterSystem composition?
- Should legacy collision-only behavior remain script/storage-only, or become inspector-visible later?

## Resolved Questions

| Question | Resolution | Date | Notes |
| --- | --- | --- | --- |
| Is the final River combine destroying a useful downstream vector? | No. The Godot 4.6.3 dump shows `normal_to_flow` is already neutral in occupied interiors. | 2026-05-22 | Evidence: `river_06_normal_to_flow.png` occupied interiors `mean_mag=0.005546`, `active_mag_gt_0.02=0`. |
| Is a Flow Arrows-only patch enough? | No. It would fix misleading debug but not missing downstream flow data. | 2026-05-22 | The bake still needs useful direction or explicit invalid/reduced state. |
| Should this feature folder absorb `curve-derived-river-flow`? | No. That feature remains separate. | 2026-05-22 | This folder focuses on the regression in the existing bake/debug/WaterSystem composition path. |
| Should the packed RG neutral convention change? | No. Preserve neutral `(0.5,0.5)` and decoded `(flow - 0.5) * 2.0`. | 2026-05-22 | Existing shaders, resources, and docs depend on it. |
| Should the first downstream baseline use fixed strength? | Yes. Use local downstream `+V` at fixed gentle strength `0.25` for the first slice. | 2026-05-22 | Full packed strength and then `0.5` were still visually overdriven after material pressure support; the bake now softens saturated pressure support so material force controls remain usable. |
| Should WaterSystem clamp near-neutral vectors in this slice? | No. Add diagnostics first; do not change `system_flow.gdshader` because the fixed default River output composes correctly. | 2026-05-22 | Legacy weak output remains diagnosed; default output is strong downstream. |
| Where should unused atlas neutralization happen? | After final River combine for source-region unused tiles. | 2026-05-22 | This prevents filter/combine artifacts from reintroducing arbitrary RG while preserving occupied tile margins. |

## Decision Log

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-05-22 | Create `research.md`, `spec.md`, `plan.md`, `tasks.md`, `validation.md`, and `review.md` for this feature before code patches. | The request is substantial and crosses generation, shader debug, atlas, and WaterSystem behavior. |
| 2026-05-22 | Treat `preliminary_research.md` as raw evidence/history and keep it in place. | It contains successful Godot 4.6.3 renderer dump evidence and useful investigation context. |
| 2026-05-22 | Keep the first spec focused on expected behavior, leaving exact thresholds and implementation mechanics to `plan.md`. | The workflow requires spec before plan. |
