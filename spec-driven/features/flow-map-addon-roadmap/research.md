# Research: Flow Map Addon Roadmap

## Purpose

This research consolidates flow-map and modern water-rendering references into a Waterways-specific roadmap. It is intended to help decide which future features are worth turning into separate specs after the Godot 4.6+ parity-focused port.

- Decision needed: Which feature directions should Waterways prioritize after the current Godot 4 port baseline?
- Why this cannot go straight to spec or implementation: The strongest ideas span authoring workflow, shader architecture, runtime APIs, asset import/export, validation, and performance. They need triage before becoming implementation tasks.
- Expected consumer:
  - `spec.md`
  - `plan.md`
  - `validation.md`
  - Future feature folders for authoring layers, runtime sampling, shader tiers, import/export, and network/waterfall workflows.

## Current Research Outcome

Keep Waterways focused on being an excellent Godot river/flow-map addon: spline river authoring, non-destructive flow-map control, robust bake data, useful debug views, practical runtime sampling, and production-grade validation. Do not turn it into an FFT ocean, all-purpose fluid solver, or heavyweight compute-water system.

- Status: Complete
- Recommendation: Prioritize authoring control, import/export interoperability, runtime sampling quality, bake UX/performance, river-network tooling, shader quality tiers, and demo/docs polish.
- Confidence: Medium-high. The direction is strongly supported by current code, classic flow-map research, Houdini/Crest workflows, and Godot renderer constraints. Exact implementation details need separate specs and visible Godot validation.
- Biggest unknown that remains: Which artist workflow should come first: layered in-editor painting/guide curves, DCC import/export, or per-point spline controls.
- Decision or plan section this research unlocked: Future roadmap and feature-split decisions.
- Requirements this research implies:
  - Preserve the current two-phase flow-map shader foundation.
  - Add explicit authoring controls before adding heavier simulation.
  - Keep generated data inspectable, serializable, and reusable.
  - Make runtime sampling a supported API, not only a buoyancy implementation detail.
  - Provide renderer-aware shader presets instead of one expanding water shader.
- Non-goals or rejected ideas this research supports:
  - Do not make FFT oceans a core Waterways feature.
  - Do not make compute wakes a default requirement.
  - Do not force waterfalls into the same material path as flat rivers.
  - Do not replace the existing bake pipeline before adding better controls around it.
- Validation this research requires:
  - Human-visible Godot editor validation for any authoring controls.
  - Visual shader validation across Forward+, Mobile-safe, and stylized presets.
  - Bake timing and generated-map inspection for any bake-pipeline changes.
  - Runtime sampling checks that compare CPU samples against generated map pixels.

## Premise Check

This research is not responding to a reported bug. It is roadmap discovery for future Waterways improvements.

- Reported or assumed problem: The addon needs a stronger feature direction based on flow-map and water-rendering research.
- Evidence supporting the premise: The current addon already covers core Waterways behavior, while the research points to missing production workflows: layered authoring, richer controls, DCC exchange, and runtime APIs.
- Evidence against the premise: The current `0.2.2` release candidate is parity-focused and may not need new features before packaging.
- Possible expected-behavior explanation: Some limitations are intentionally deferred release-scope choices, not defects.
- Confidence: High.
- Smallest check that can falsify the premise: Ask whether the next milestone is release packaging only. If yes, this research should remain a roadmap artifact and not generate immediate tasks.
- User-facing note or question to raise before patching: Confirm which roadmap item should become the first real feature spec.

## Active Add-on Baseline

The current Godot 4 port is already aligned with classic Waterways: it has spline river meshes, baked flow/foam/distance/pressure maps, debug views, a Godot 4 depth/refraction shader, WaterSystem maps, wet material assignment, and simple buoyancy.

- Relevant active files:
  - [addons/waterways/shaders/river.gdshader](../../../addons/waterways/shaders/river.gdshader): built-in water shader with two-phase `FlowUVW`, depth texture use, screen texture refraction, foam mixing, and debug-compatible uniforms.
  - [addons/waterways/river_manager.gd](../../../addons/waterways/river_manager.gd): River node, inspector-facing material properties, mesh generation, flow/foam bake orchestration, data texture validation, external bake resource storage.
  - [addons/waterways/water_helper_methods.gd](../../../addons/waterways/water_helper_methods.gd): curve mesh generation, UV2 atlas layout, collision scanning, padding/margin logic, geometry helpers.
  - [addons/waterways/filter_renderer.gd](../../../addons/waterways/filter_renderer.gd): SubViewport-based GPU filter passes and readback for blur, dilate, normal-to-flow, foam, pressure, and channel combine operations.
  - [addons/waterways/system_map_renderer.gd](../../../addons/waterways/system_map_renderer.gd): WaterSystem flow/height/alpha map rendering.
  - [addons/waterways/water_system_manager.gd](../../../addons/waterways/water_system_manager.gd): WaterSystem bake, wet material assignment, runtime flow/altitude sampling, stale-source warnings.
  - [addons/waterways/buoyant_manager.gd](../../../addons/waterways/buoyant_manager.gd): simple one-point buoyancy and flow-force helper.
  - [addons/waterways/resources/river_bake_data.gd](../../../addons/waterways/resources/river_bake_data.gd): River bake data resource with channel metadata and import profile.
  - [addons/waterways/resources/water_system_bake_data.gd](../../../addons/waterways/resources/water_system_bake_data.gd): WaterSystem map resource with world bounds, transform, channel metadata, and sampling image.
- Current behavior:
  - River curves generate mesh strips with UV and padded UV2 atlas coordinates.
  - River bake scans collision influence, filters it into flow, foam, distance, and pressure maps, then packs `flow_foam_noise` and `dist_pressure`.
  - River shader samples those maps and uses two-phase UV distortion to animate normal-map detail.
  - WaterSystem combines child river data into a world-space map for wet shaders and runtime sampling.
  - Buoyant samples one point from the WaterSystem to apply buoyancy, upright torque, flow force, and water damping.
- Existing extension points:
  - `mat_custom_shader` for custom River shader assignment.
  - `RiverBakeData` and `WaterSystemBakeData` channel metadata/import profile fields.
  - Wet material uniforms: `water_systemmap` and `water_systemmap_coords`.
  - Debug views for flow map, foam, noise, distance, pressure, flow pattern, flow arrows, flow strength, and foam mix.
  - Source metadata already names future source kinds such as imported maps, hand-painted maps, shore distance fields, terrain slope fields, and obstacle influence fields.
- Existing generated data, resources, channels, or metadata:
  - `flow_foam_noise.rg`: signed flow packed to `0..1`, neutral `0.5`.
  - `flow_foam_noise.b`: foam influence.
  - `flow_foam_noise.a`: phase/noise offset.
  - `dist_pressure.r`: bank distance or edge influence.
  - `dist_pressure.g`: flow pressure or occupancy.
  - `WaterSystem.system_map.rg`: world/projected flow packed to `0..1`.
  - `WaterSystem.system_map.b`: normalized height.
  - `WaterSystem.system_map.a`: coverage mask.
- Existing editor-only/runtime-safe boundaries:
  - Editor tools and bakes live in tool scripts, gizmos, menus, SubViewport renderers, and validation actions.
  - Runtime consumes generated textures/resources through shader uniforms and WaterSystem image sampling.
  - Runtime should not depend on temporary in-memory editor-only bakes.
- Current validation scenes, debug views, or probes:
  - The README/user guide refer to validation scenes, but this minimal checkout does not include them.
  - Current built-in debug views are the strongest visible inspection path inside the addon package.
  - `validate_data_textures()`, `validate_filter_renderer()`, and `validate_generated_map_sampling()` provide useful targeted checks.
- Current known limitations:
  - No user-facing bake cancel button.
  - Large high-resolution bakes may stall the editor.
  - Buoyant is one-point and intentionally simple.
  - No first-class layered authoring, guide-curve authoring, painted flow strokes, DCC map import/export action, confluence handling, waterfall node, or shader quality presets.
  - Local headless/editor-load checks do not prove visible shader, editor, bake, or runtime behavior.
- Current performance-sensitive paths:
  - CPU pixel loops over bake images.
  - Physics/collision queries during collision map generation.
  - SubViewport render passes plus GPU readbacks in `filter_renderer.gd`.
  - System map rendering/readback.
  - Runtime CPU image sampling in WaterSystem and Buoyant.
- What should not be rediscovered or redesigned unnecessarily:
  - The two-phase flow-map shader foundation.
  - The current generated channel contract.
  - The external `.res` bake-resource storage model.
  - The editor/runtime separation established by River, WaterSystem, bake data resources, and runtime sampling.

## Research Questions

- Which flow-map features would most improve Waterways beyond Godot 4 parity?
- Should Waterways prioritize shader fidelity, authoring workflows, runtime APIs, or bake performance first?
- Which external systems provide reusable concepts without dragging Waterways away from its river addon identity?
- What assumptions need verification before implementation?
- What Godot 4.6+ constraints could change the design?
- Which parts are editor-only, runtime-only, or shared?
- What legacy Waterways behavior should be preserved, changed, or removed?
- What must future specs require if this research is correct?
- What should future plans explicitly avoid?

## Findings Matrix

| Question | Finding | Evidence or source | Waterways implication | Confidence |
| --- | --- | --- | --- | --- |
| What is already strong? | The addon already has the core classic Waterways stack: spline mesh, flow/foam bake, two-phase shader, debug views, WaterSystem sampling, and simple buoyancy. | Local active files listed in "Active Add-on Baseline"; `README.md`; `docs/godot-4-user-guide.md`. | Future work should extend authoring and usability, not replace the core shader/bake foundation. | High |
| Is two-phase flow still the right shader basis? | Yes. The Valve/Catlike approach remains the right low-cost way to hide finite UV distortion for river surface detail. | Valve "Water Flow in Portal 2"; Catlike Coding texture distortion tutorial; local `FlowUVW` implementation. | Keep `FlowUVW` as the base technique, but expose better authoring inputs and shader tiers around it. | High |
| What is the highest-value visual/authoring improvement? | Non-destructive flow authoring layers: base spline flow, obstacle/collision influence, guide curves, painted strokes, imported maps, and masks. | SideFX Labs Flowmap guide concepts; Valve artist-authored flow maps; local future source-kind metadata. | Create a future feature spec for layered map sources and deterministic combine order. | High |
| How should ordinary river tuning improve? | Per-point or per-segment controls for speed, turbulence, foam bias, depth, and ripple scale would give artists direct control without changing textures manually. | Current Waterways already stores per-point width; Crest spline/water input patterns show spline-local water controls. | Extend curve metadata carefully, likely through resources or sidecar arrays, not hard-coded shader-only parameters. | Medium-high |
| How should DCC workflows fit? | Import/export should be a first-class workflow for Houdini, Blender, Substance, and other external flow-map authoring tools. | SideFX Labs Flowmap; current import validation docs; RiverBakeData channel metadata. | Add "Import Flow Map" and "Export Flow/Foam/Distance Maps" specs before attempting in-engine painting. | Medium-high |
| What runtime API is missing? | WaterSystem should expose explicit height/depth/velocity queries and better sampling behavior, including bilinear sampling. | Local `get_water_altitude()` and `get_water_flow()` are useful but minimal; Buoyant consumes them internally. | Create a runtime sampling API spec separate from full buoyancy/boat physics. | High |
| What production UX is most urgent? | Bake cancel, preview/final bake modes, bake timing reports, and cached UV/collision work would make the addon feel more production-ready. | Local docs call out no cancel and high-res bake stalls; filter renderer and collision scan are visibly performance-sensitive. | Make bake UX/performance a first-class feature, not cleanup after visual features. | High |
| How should river networks and waterfalls be handled? | Confluences need blend/priority tools; waterfalls should be separate nodes/materials with transition masks, not forced into the flat river shader. | Industry waterfall/rapid patterns from the supplied research; local WaterSystem combines child rivers but has no junction semantics. | Add network and waterfall specs later, after layered authoring data exists. | Medium |
| Should one shader serve every target? | No. The built-in shader can remain the default, but desktop, stylized, opaque/mobile-safe, and low-cost presets should be separate quality tiers. | Godot screen/depth docs; rendering limitations; local shader uses screen/depth textures. | Add shader preset architecture rather than expanding a single monolithic shader. | High |
| Should Waterways implement FFT oceans or compute wakes? | Not as core roadmap work. Those are separate systems that should integrate with Waterways through hooks, not become its center. | godot4-oceanfft; Godot compute shader docs; research prompt's FFT/compute discussion. | Provide clean data/API hooks for external ocean/wake systems; do not block river tooling on compute features. | Medium-high |

## Comparable Patterns

### Valve / Portal 2 / Catlike Coding

The canonical flow-map pattern is still useful for Waterways:

- Store a two-dimensional vector field in texture channels.
- Decode unsigned texture data into signed flow vectors.
- Distort tiled normal maps, not usually albedo, to create the water-motion illusion.
- Reset distortion with a sawtooth phase.
- Hide the reset by blending two half-period-offset phases.
- Use phase/noise offsets and UV jumps to reduce pulsing and visible repetition.

Waterways already implements this core idea in `river.gdshader`. The research implication is not "rewrite the shader"; it is "give artists better data to feed the shader."

### SideFX / Houdini Flowmap Workflows

The useful concepts from Houdini-oriented flow-map workflows are:

- Guide curves and vector-field controls.
- Width, falloff, strength, sample count, and reverse-direction style parameters.
- Simulation-baked or DCC-authored flow textures as override sources.
- Artist-adjustable masks rather than a single procedural result.

Waterways does not need Houdini inside Godot. It needs compatible import/export, clear channel contracts, and an in-editor layer model that can accept DCC output without losing generated River metadata.

### Crest / Spline and Water Inputs

Crest is not a Godot implementation target, but it is a strong conceptual reference for water inputs and spline-local controls:

- Water behavior can be driven by authored inputs rather than one global material.
- Spline/shape controls can add local flow, wave, foam, or depth influence.
- Tooling should make local edits legible and reversible.

For Waterways, this supports per-point/per-segment River controls and a non-destructive combine model.

### Godot Community Projects

- Arnklit Waterways remains the primary local and historical model for this addon.
- `waterways-net` is useful as a Godot 4 community fork/reference, but should be treated as conceptual unless its exact implementation and license are reviewed before reuse.
- `godot4-oceanfft` is useful evidence that Godot 4 compute/FFT ocean work is feasible, but it also shows that FFT ocean rendering is a separate large system.

### Production-Inspired River Patterns

The supplied research points to several AAA patterns that are useful as design goals rather than direct implementation targets:

- Rapids often need extra wave/foam detail beyond flat normal scrolling.
- Waterfalls are usually separate material/particle/geometry systems with transition masks.
- Gameplay often needs to sample the same water data that drives visuals.
- Debris/leaves/boats should follow water vectors when a project needs readable current.

Waterways should expose data and hooks for these, but avoid shipping one giant simulation framework.

## Godot 4.6+ Findings

- The active shader already uses Godot 4 screen/depth texture syntax through `hint_screen_texture` and `hint_depth_texture`.
- Screen/depth/refraction behavior should be treated as a renderer-dependent shader tier, not a universal assumption.
- Data textures should remain non-color numeric data: uncompressed or lossless, normal-map import disabled, mipmaps disabled unless validated.
- SubViewport bake passes and GPU readback are practical but performance-sensitive. Any larger authoring feature should consider caching or lower-cost preview paths.
- Compute shaders are feasible in Godot 4, but should be optional, renderer-gated, and outside the core river authoring path.
- Editor-visible validation remains mandatory for shaders, gizmos, bakes, and debug views. Parser/headless checks are useful but not visual proof.
- WaterSystem runtime sampling currently uses nearest pixel sampling through `_sample_system_map()`. Better bilinear sampling should be a future API-level improvement.
- Godot Physics versus Jolt may affect collision/raycast bake behavior; any bake rewrite or performance pass should explicitly test physics backend assumptions.

## Performance and Scale Findings

- Expected scene scale: Multiple River children under one WaterSystem, with ordinary authoring at River bake resolution 0 to 2 and WaterSystem resolution 0 to 2.
- Expected river count, curve complexity, or generated mesh size: Current code scales with curve steps, length subdivisions, width subdivisions, image dimensions, and child River count.
- Expected bake texture sizes: Current River source textures range from 64 to 1024 before padding; high settings are stress/final-check settings.
- Expected runtime texture memory: Packed maps are compact, but padded River atlases and WaterSystem maps can grow quickly across many rivers.
- Editor bake-time risks:
  - CPU loops over every bake pixel.
  - Collision/raycast checks during collision map generation.
  - Multiple SubViewport filter passes.
  - GPU readback after each pass.
- Runtime frame-time risks:
  - Transparent water overdraw.
  - Screen/depth texture sampling in the water shader.
  - CPU image sampling if many bodies query WaterSystem every physics frame.
- GPU readback risks: Filter and system renderers rely on viewport texture readback. This is acceptable for editor bakes, but should not creep into runtime.
- Physics query or raycast-count risks: Collision-map generation can become expensive at high resolution; cached UV rasterization or staged collision sampling should be considered in a bake-performance spec.
- Renderer/backend assumptions:
  - Forward+ is the best target for full desktop shader quality.
  - Mobile and Compatibility need lower-cost shader presets and validation.
- Mobile, Compatibility, or VR constraints:
  - Avoid assuming depth/screen texture refraction is always acceptable.
  - Provide opaque/stylized/mobile-safe presets.
  - Treat VR screen-space effects as high-risk until explicitly validated.
- Recommended budget or measurement approach:
  - Record bake time by phase: collision, each filter pass, combine, resource save.
  - Record generated texture size and memory.
  - Record runtime query count for buoyancy/sampling scenes.
  - Maintain a visible stress scene and a small default scene.

## Legacy Waterways Reference

This minimal checkout does not include a `legacy/godot-3/addons/waterways` snapshot, although the spec-driven docs mention one may exist in other workspaces.

- Relevant legacy files: Not present in this checkout.
- Behavior to preserve:
  - Spline-based River workflow.
  - Flow and foam map generation.
  - Debug views that make generated data inspectable.
  - Simple runtime flow/buoyancy affordances.
- Behavior to change:
  - Replace implicit or fragile editor/runtime state with explicit resources.
  - Prefer Godot 4 shader syntax, physics APIs, texture APIs, and editor APIs.
  - Avoid preserving legacy limitations when Godot 4 resources/metadata can make the workflow clearer.
- Obsolete APIs to avoid: Godot 3 shader constants and editor APIs.
- Risks discovered in `audit/code-audit.md`: Audit file not present in this checkout.
- What belongs in active Godot 4.6+ code:
  - Resource-backed generated data.
  - Godot 4 shader uniforms and import expectations.
  - Editor tooling that keeps runtime data explicit.
- What should remain legacy-only:
  - Godot 3 API compatibility.
  - Any behavior that depends on unsaved editor-only generated data at runtime.

## Options

### Option A: Authoring-First Waterways Roadmap

- Benefits:
  - Directly addresses the biggest current gap: artist control over generated flow data.
  - Builds on existing River/WaterSystem resources instead of replacing them.
  - Creates reusable foundations for future painting, import/export, confluences, and waterfalls.
- Costs:
  - Requires careful data-model design for layers, precedence, masks, and stale-source tracking.
  - Needs visible editor validation and good debug views.
- Risks:
  - Scope can expand quickly if painting, DCC import, and guide curves are bundled into one feature.
  - Poor layer UX could make the addon harder to understand.
- Fit for Waterways: Excellent.
- Source/reuse constraints: Use SideFX/Crest/Valve conceptually; do not copy code without a separate license review.

### Option B: Shader-Fidelity Roadmap

- Benefits:
  - Easier to demonstrate visually.
  - Can improve screenshots, demos, and perceived quality.
  - Shader presets can make the addon safer across renderer targets.
- Costs:
  - Does not solve authoring limitations.
  - Risks growing one monolithic shader if not designed as presets.
- Risks:
  - Screen/depth effects can be renderer/platform sensitive.
  - Visual polish may hide weak map-authoring workflows.
- Fit for Waterways: Good as a supporting track, not the main roadmap.
- Source/reuse constraints: Godot shader code must be original or locally authored; tutorials should remain conceptual references.

### Option C: Simulation/Compute Roadmap

- Benefits:
  - Could support wakes, ripples, dynamic obstacles, or ocean-like features.
  - Interesting for advanced demos.
- Costs:
  - Large technical surface area.
  - Renderer/platform constraints.
  - Competes with specialized projects like `godot4-oceanfft`.
- Risks:
  - Pulls Waterways away from river authoring and flow-map tooling.
  - Harder to validate and maintain.
- Fit for Waterways: Low as a core roadmap, good as optional integration hooks later.
- Source/reuse constraints: Treat compute/ocean projects as conceptual references unless license and architecture are separately reviewed.

## Recommendation

- Recommended direction: Choose Option A as the main roadmap, with small pieces of Option B for quality tiers and demo polish. Defer Option C to optional integration hooks.
- Why this fits Waterways:
  - Waterways is already a curve/flow-map addon. Its highest leverage is better authored data, not heavier simulation.
  - The current channel/resource architecture is ready to carry more source metadata and imported/layered data.
  - Users will benefit most from predictable editor workflow, DCC compatibility, and runtime sampling APIs.
- What to do first:
  - Split the roadmap into separate feature specs:
    - non-destructive flow authoring layers
    - per-point/per-segment River controls
    - import/export data-map workflow
    - runtime WaterSystem sampling API
    - bake UX/performance
    - shader quality tiers
    - river networks/waterfalls
    - demo/docs cleanup
  - Pick one first feature based on maintainer priority. The strongest first candidate is runtime sampling API or import/export because both are easier to bound than full layered authoring.
- What to defer:
  - In-editor painting until the layer/source model exists.
  - Waterfalls until transition masks and network semantics are clearer.
  - Compute wakes until runtime APIs and shader tiers are stable.
- What to avoid:
  - One giant "water system rewrite."
  - One shader with every feature and platform path.
  - Hard-coding one demo scene, terrain, material, or DCC workflow.
- Confidence: Medium-high.

## Spec Implications

List these as candidate future specs rather than immediate tasks.

- User/developer workflows:
  - Author a River from a spline, then add non-destructive local flow influences.
  - Export generated maps for DCC inspection or refinement.
  - Import externally painted/simulated maps while preserving channel metadata.
  - Query water height, depth, and velocity at runtime from gameplay code.
  - Choose a shader preset appropriate to renderer/platform/style.
- Functional requirements:
  - Layered source model for flow/foam/distance/pressure data.
  - Per-point or per-segment River metadata.
  - Import/export actions with data-texture validation.
  - Runtime sampling API with nearest and bilinear behavior clearly defined.
  - Bake progress, cancel, timing, and preview/final modes.
  - Separate waterfall/rapid/confluence support rather than flat river overloading.
- Non-functional requirements:
  - Generated resources must remain explicit and inspectable.
  - Editor-only code must not leak into runtime.
  - Shader presets must be renderer-aware.
  - Data maps must avoid lossy/compressed color import assumptions.
  - Performance budgets must be recorded for representative scenes.
- Editor usability requirements:
  - Debug views must show each source/layer and final packed output.
  - Stale data warnings must explain which source changed.
  - Long bakes need cancel or clearly staged progress.
- Runtime/API requirements:
  - Public `get_water_height()`, `get_water_depth()`, `get_water_velocity()` or equivalent.
  - Sampling should expose validity/coverage and not only return fallback values.
  - Multi-point buoyancy should be built on the API rather than embedded into one helper.
- Generated asset/resource requirements:
  - Channel metadata for imported and generated data.
  - Source-kind metadata for each layer or imported resource.
  - Bounds, transforms, resolution, content rect, and import profile.
- Acceptance criteria:
  - Future specs should include visible editor checks, bake-output checks, shader debug checks, and runtime sampling checks.
- Non-goals:
  - Core FFT ocean simulation.
  - Core compute wake simulation.
  - Full boat physics.
  - One universal material for rivers, waterfalls, oceans, and mobile.
- Open questions to carry forward:
  - Should layered authoring be texture-layer based, vector-curve based, resource based, or a hybrid?
  - Should import/export support EXR immediately, or start with validated PNG workflows?
  - Should per-point controls live on the River node arrays, a custom resource, or curve metadata if Godot supports it cleanly?
  - Which shader tiers are mandatory for the next release versus demo-only?

## Plan Implications

- Architecture direction:
  - Preserve River, WaterSystem, and bake data resource boundaries.
  - Add new feature surfaces as resources and editor actions rather than hidden state.
  - Keep runtime sampling independent of editor bake renderers.
- Affected files/modules:
  - River authoring: `river_manager.gd`, `river_gizmo.gd`, River GUI/menu scripts.
  - Bake pipeline: `filter_renderer.gd`, system renderers, bake data resources.
  - Shaders: `river.gdshader`, `river_debug.gdshader`, future preset shaders/materials.
  - Runtime: `water_system_manager.gd`, `buoyant_manager.gd`, possible new sampler/resource scripts.
  - Docs/templates: feature specs, validation scenes, user guide, import notes.
- Editor-only code:
  - Layer editing UI, guide curves, import/export actions, bake controls, validation menus.
- Runtime-safe code:
  - WaterSystem sampler API.
  - Bake data resources.
  - Shader uniforms and materials.
- Shared resources/data:
  - Packed map textures.
  - Bounds/transforms.
  - Channel metadata.
  - Source metadata and stale-source signatures.
- Texture channels, data formats, and metadata:
  - Keep current RG flow, B foam/height, A phase/coverage contracts unless a spec explicitly changes them.
  - For imported data, validate neutral `(0.5, 0.5)` flow and numeric import settings.
- Import/export expectations:
  - Export generated maps with documented channel layout.
  - Import maps as data textures with validation warnings.
  - Record whether imported data came from DCC, hand painting, or generated source.
- Lifecycle, cleanup, and re-entry concerns:
  - Async bakes need success, cancel, early-return, and failure cleanup paths.
  - Temporary nodes must be removed after failure or cancel.
  - Stale-source signatures need to include any new layer/source data.
- Migration or compatibility concerns:
  - Existing saved River and WaterSystem bake data should continue to load.
  - New metadata should default safely for old resources.
  - Any shader preset system should preserve the current default material behavior.
- Documentation updates needed:
  - Roadmap overview.
  - Data texture import/export guide.
  - Runtime sampling API docs.
  - Shader preset compatibility notes.
  - Human-assisted validation procedures.

## Validation Implications

- Automated checks:
  - Static/parser checks for new scripts and resources.
  - Resource load checks for old and new bake data.
  - Data texture validation for imported maps.
  - Sampling comparison tests using small known maps where possible.
- Human-assisted Godot/editor checks:
  - Select/edit River controls in a visible editor.
  - Generate River and WaterSystem maps through toolbar actions.
  - Confirm progress/cancel/timing UI.
  - Confirm generated external resources survive save/reopen/F6.
- Visual scene or debug-view checks:
  - Flow arrows align with expected direction.
  - Flow pattern moves continuously without obvious reset pops.
  - Foam appears near intended banks/obstacles/rapid zones.
  - Distance/pressure maps are non-empty and visually plausible.
  - Shader presets show expected tradeoffs.
- Shader checks:
  - Forward+ full-quality water.
  - Mobile-safe or opaque/stylized preset without screen/depth dependence.
  - Debug shader still visualizes packed channels correctly.
- Bake-output checks:
  - Channel ranges, neutral flow, coverage, content rect, padding margins, stale-source metadata.
- Runtime/API checks:
  - Height/depth/velocity queries at known map positions.
  - Fallback outside coverage.
  - Bilinear versus nearest sampling behavior.
  - Buoyant behavior still works on top of the public sampler.
- Performance checks:
  - Bake timings by phase.
  - GPU readback count.
  - Runtime query cost under many buoyant bodies.
  - Shader frame impact by preset.
- Artifact hygiene checks:
  - Generated bakes, validation fixtures, scratch projects, and editor caches are excluded from release packages unless intentionally shipped.
- Failure signs that should stop implementation:
  - New features depend on unsaved editor-only data at runtime.
  - Imported maps silently use color/normal/compressed import settings.
  - Shader preset changes break existing default River scenes.
  - Validation docs rely on headless checks as proof of visible output.

## Risks and Unknowns

- Layered authoring could become too broad unless split into guide curves, imported maps, painted strokes, and combine/mask semantics.
- Per-point controls need a stable serialization model that survives curve edits, undo/redo, point insertions, and point deletions.
- DCC import/export needs real sample files and clear import settings before promising EXR or high-bit-depth workflows.
- Runtime bilinear sampling needs careful coordinate handling around coverage edges and packed flow normalization.
- Shader tier work could fragment the material UX if presets are not named and documented clearly.
- Bake cancel requires careful cleanup of async SubViewport passes and temporary renderer nodes.
- Waterfall/confluence work needs visual validation scenes because still images and static channel checks will not prove motion continuity.

## Context Challenge Notes

- Possible misread context: Treating roadmap limitations as release-blocking defects.
- Evidence: The README states `0.2.2` is parity-focused and large-scene bake performance/cancel controls are deferred.
- Confidence: High.
- Quick check before patching: Ask whether the next milestone is still `0.2.2` packaging or a post-parity feature cycle.
- User-facing note or question to raise: "This is roadmap work. Which item should become the next accepted feature spec after the release candidate?"
- Outcome after the check: Not yet run.

## Source Quality and Reuse Notes

Separate evidence quality from inspiration. The strongest evidence for actual implementation is local code plus official Godot docs. Production talks, tutorials, and open-source repos are strong conceptual references, but require separate license and architecture review before code reuse.

Source categories:

- Local active code: Highest authority for current Waterways behavior.
- Local spec/validation docs: High authority for project process and current limitations.
- Official Godot docs: High authority for Godot APIs and renderer/shader assumptions.
- Official tool/engine docs: High authority for external workflow concepts, not Godot implementation.
- Academic paper or production talk: Strong conceptual reference.
- Open-source repo: Useful architecture reference; verify license and version before reuse.
- Tutorial or blog: Useful explanation; do not copy code by default.
- Forum, issue, Reddit, or informal discussion: Good for problem discovery; low authority without reproduction.
- Agent inference: Must be marked as inference and validated before implementation.

Reuse/licensing notes:

- License: Record per source before copying code or assets.
- Code-copy allowed: Only after verifying license compatibility and attribution requirements.
- Conceptual reference only: Default for most tutorials, talks, docs, and production examples.
- Attribution needed: Preserve Waterways MIT attribution and cite external concepts in docs when materially used.
- Compatibility concern: Unity/Unreal/Crest/Houdini patterns must be adapted to Godot's editor/runtime/resource/shader model.

## Sources

| Source | Type | Why it matters | Reuse/licensing note |
| --- | --- | --- | --- |
| [addons/waterways/shaders/river.gdshader](../../../addons/waterways/shaders/river.gdshader) | Local active code | Current two-phase river shader, depth/screen sampling, foam, and flow debug-compatible uniform contract. | Local project code under Waterways license. |
| [addons/waterways/river_manager.gd](../../../addons/waterways/river_manager.gd) | Local active code | Current River authoring, bake orchestration, data validation, and bake metadata. | Local project code under Waterways license. |
| [addons/waterways/water_system_manager.gd](../../../addons/waterways/water_system_manager.gd) | Local active code | Current WaterSystem bake, wet assignment, stale-source checks, and runtime sampling. | Local project code under Waterways license. |
| [addons/waterways/buoyant_manager.gd](../../../addons/waterways/buoyant_manager.gd) | Local active code | Current one-point runtime buoyancy helper and flow-force consumer. | Local project code under Waterways license. |
| [docs/godot-4-user-guide.md](../../../docs/godot-4-user-guide.md) | Local spec/validation docs | Documents channel contracts, bake limits, validation expectations, and known limitations. | Local project documentation. |
| [docs/godot-4-imports.md](../../../docs/godot-4-imports.md) | Local spec/validation docs | Documents data texture import expectations and generated map storage. | Local project documentation. |
| [Valve: Water Flow in Portal 2](https://cdn.cloudflare.steamstatic.com/apps/valve/2010/siggraph2010_vlachos_waterflow.pdf) | Production talk | Foundational two-phase flow-map technique, artist-authored flow maps, noise/phase offset, and gameplay flow use. | Conceptual reference only unless license explicitly permits code/assets reuse. |
| [Catlike Coding: Texture Distortion](https://catlikecoding.com/unity/tutorials/flow/texture-distortion/) | Tutorial/blog | Clear explanation of flow-map vector decoding, UV distortion limits, reset, blending, and data texture import concerns. | Conceptual reference; do not copy Unity code directly. |
| [Godot: Screen-reading shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html) | Official Godot docs | Confirms Godot 4 screen/depth texture patterns relevant to water depth fade/refraction. | Official docs; use API guidance, not copied prose. |
| [Godot: Using compute shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/compute_shaders.html) | Official Godot docs | Relevant to optional future wakes/interactive simulation, and why compute should be gated. | Official docs; use API guidance, not copied prose. |
| [Godot: 3D rendering limitations](https://docs.godotengine.org/en/stable/tutorials/3d/3d_rendering_limitations.html) | Official Godot docs | Relevant to renderer/backend limits for transparent water, screen-space effects, and mobile/compatibility tiers. | Official docs; use API guidance, not copied prose. |
| [SideFX Labs Guide Flowmap](https://www.sidefx.com/docs/houdini/nodes/sop/labs--flowmap_guide.html) | Official tool docs | Strong reference for guide-based flow-map authoring concepts such as width, strength, falloff, reverse direction, and sample count. | Conceptual workflow reference; do not copy Houdini assets/code. |
| [Crest: Water Inputs](https://crest.readthedocs.io/en/stable/user/water-inputs.html) | Official/open-source docs | Useful conceptual reference for local water inputs and authored contributions to water behavior. | Verify current Crest license before code reuse; conceptual only here. |
| [Crest: Splines](https://docs.crest.waveharmonic.com/Packages/Splines/Manual.html) | Official/open-source docs | Useful conceptual reference for spline-driven water controls. | Verify current Crest license before code reuse; conceptual only here. |
| [Arnklit/Waterways](https://github.com/Arnklit/Waterways) | Open-source repo | Original Waterways project and behavior lineage. | MIT per local project attribution; still verify before copying between branches. |
| [Tshmofen/waterways-net](https://github.com/Tshmofen/waterways-net) | Open-source repo | Godot 4 community fork/reference for Waterways-like workflows. | Verify license and code history before reuse. |
| [tessarakkt/godot4-oceanfft](https://github.com/tessarakkt/godot4-oceanfft) | Open-source repo | Evidence that Godot 4 compute/FFT ocean work is feasible but separate in scope. | Verify license before reuse; conceptual boundary reference here. |
| [Advances in Real-Time Rendering 2016](https://advances.realtimerendering.com/s2016/index.html) | Production talk index | Reference point for Uncharted 4 rapids/wave-particle ideas from the supplied research. | Conceptual inspiration only. |
