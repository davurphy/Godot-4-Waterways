# Research: Two-Phase Flow

## Purpose

This research narrows the broader flow-map roadmap into one focused feature: Waterways' two-phase flow-map animation foundation. The accepted direction is Option A: preserve and validate the existing implementation. The goal is to document, validate, and protect the current `FlowUVW` shader behavior rather than replace it.

- Decision: Option A, "Preserve and Validate Existing Two-Phase Flow."
- Why this cannot go straight to spec or implementation: The addon already implements the core technique, so the useful work is not obvious from the feature name alone. A focused research pass prevents accidental churn in the shader while identifying real gaps around validation, consistency, and authoring hooks.
- Expected consumer:
  - `spec.md`
  - `plan.md`
  - `validation.md`
  - Future shader-tier, debug-view, and flow-authoring specs.

## Current Research Outcome

Waterways should keep the existing Valve/Catlike two-phase flow technique as the shader basis. The focused feature should harden and validate it, clarify its channel contract, keep water/debug/lava behavior consistent, and expose only a small set of artist-safe controls if a later spec confirms they are useful.

- Status: Complete for direction; strengthened with external implementation evidence and Option A validation patterns.
- Recommendation: Treat this as a "two-phase flow foundation" feature, not a rewrite. Preserve `FlowUVW`, document the local variant, add visible validation expectations, and decide whether shader duplication should remain or be centralized through a Godot-validated include/helper pattern.
- Confidence: High for preserving the technique; medium for any refactor or extra parameters until Godot shader include behavior and visible output are validated.
- Biggest unknown that remains: Whether centralizing the helper across shaders is worth the Godot import/editor risk, or whether synchronized duplication is safer for this addon.
- Decision or plan section this research unlocked: Scope for a future two-phase-flow spec.
- Requirements this research implies:
  - Preserve continuous two-phase normal-map flow with no obvious reset popping.
  - Preserve phase/noise offset behavior from `flow_foam_noise.a`.
  - Preserve debug visibility for flow pattern, arrows, strength, and foam mix.
  - Validate water, debug, and lava shader variants together.
  - Treat two-phase flow as shader/runtime behavior fed by generated or imported flow maps.
- Non-goals or rejected ideas this research supports:
  - Do not replace two-phase flow with simulation.
  - Do not make Gerstner, FFT, or compute wakes part of this focused feature.
  - Do not expose low-level UV jump constants until a spec defines safe UX and validation.
  - Do not rewrite the bake pipeline just to support this feature.
- Validation this research requires:
  - Human-visible flow-pattern animation check.
  - Debug view check for encoded flow, effective flow strength, and flow arrows.
  - Channel validation for neutral flow and alpha phase/noise offset.
  - Regression check that lava and river debug shaders still match the River shader's flow behavior where intended.

## Premise Check

This feature is not motivated by a known broken implementation. It is motivated by the observation that two-phase flow is already central to Waterways and should become an explicit, validated foundation before adding higher-level authoring features.

- Reported or assumed problem: The addon needs a focused two-phase flow feature.
- Evidence supporting the premise: `FlowUVW` exists in the water, debug, and lava shaders; River bakes already pack flow and phase/noise data; debug views already visualize the result.
- Evidence against the premise: The current implementation may already be sufficient for `0.2.2` parity, so feature work may be post-release hardening rather than release-blocking.
- Possible expected-behavior explanation: Any "jelly" or repetition artifacts may come from authored flow speed, normal texture choice, UV scale, or bake data quality rather than the two-phase algorithm itself.
- Confidence: High.
- Smallest check that can falsify the premise: In a visible River scene, set debug view to Flow Pattern and observe whether reset popping, pulsing, or seam artifacts are actually present with default settings.
- User-facing note or question to raise before patching: "Do we want this as release hardening, or as a post-parity shader/authoring foundation?"

## Active Add-on Baseline

Waterways already has the core classic flow-map stack. This feature should preserve that base and make it easier to reason about.

- Relevant active files:
  - [addons/waterways/shaders/river.gdshader](../../../addons/waterways/shaders/river.gdshader): built-in water shader. Defines `FlowUVW`, samples `i_flowmap`, decodes flow, applies flow force, adds `flow_foam_noise.a` to time, and samples two normal-map phases.
  - [addons/waterways/shaders/river_debug.gdshader](../../../addons/waterways/shaders/river_debug.gdshader): debug shader. Duplicates `FlowUVW` and exposes visible modes for flow pattern, arrows, strength, and foam mix.
  - [addons/waterways/shaders/lava.gdshader](../../../addons/waterways/shaders/lava.gdshader): lava shader. Duplicates the same two-phase flow helper for lava surface animation.
  - [addons/waterways/river_manager.gd](../../../addons/waterways/river_manager.gd): assigns `i_flowmap`, `i_distmap`, `i_valid_flowmap`, `i_uv2_sides`, and generates `flow_foam_noise`.
  - [addons/waterways/shaders/filters/combine_pass.gdshader](../../../addons/waterways/shaders/filters/combine_pass.gdshader): packs generated channel data into RGBA textures.
  - [addons/waterways/resources/river_bake_data.gd](../../../addons/waterways/resources/river_bake_data.gd): documents `flow_foam_noise` channel metadata, including alpha as optional phase noise.
  - [docs/godot-4-user-guide.md](../../../docs/godot-4-user-guide.md): documents channel contract and debug views.
- Current behavior:
  - Flow maps pack signed flow in RG, foam in B, and phase/noise offset in A.
  - The shader remaps flow from `0..1` into signed `-1..1`.
  - A flow-force multiplier combines base flow, steepness, distance, and pressure.
  - `FlowUVW` computes two temporal phases offset by half a period.
  - The shader blends phase A and B with a triangle-wave weight so each phase fades out before its reset.
  - Secondary normal sampling at double UV scale adds detail near the camera.
  - Debug modes visualize encoded/effective flow and final animated pattern.
- Existing extension points:
  - Material parameters: `flow_speed`, `flow_base`, `flow_steepness`, `flow_distance`, `flow_pressure`, `flow_max`, `uv_scale`.
  - Internal uniforms: `i_flowmap`, `i_distmap`, `i_valid_flowmap`, `i_uv2_sides`.
  - Alpha phase/noise map: `flow_foam_noise.a`.
  - Debug view modes.
- Existing generated data, resources, channels, or metadata:
  - `flow_foam_noise.r`: signed flow X packed to `0..1`, neutral `0.5`.
  - `flow_foam_noise.g`: signed flow Y/Z packed to `0..1`, neutral `0.5`.
  - `flow_foam_noise.b`: foam influence.
  - `flow_foam_noise.a`: optional phase/noise offset.
  - `dist_pressure.r`: bank distance or edge influence.
  - `dist_pressure.g`: flow pressure or occupancy.
- Existing editor-only/runtime-safe boundaries:
  - The two-phase shader is runtime behavior.
  - River baking and debug menus are editor authoring behavior.
  - Generated textures/resources bridge the two.
- Current validation scenes, debug views, or probes:
  - Debug views exist for Flow Map, Flow Pattern, Flow Arrows, Flow Strength, and Foam Mix.
  - `validate_data_textures()` checks flow-map data and neutral-flow preservation.
  - No visible validation scene is present in this minimal checkout.
- Current known limitations:
  - `FlowUVW` is duplicated across water, debug, and lava shader files.
  - The UV jump constants are hard-coded in shader files.
  - The local `FlowUVW` variant differs slightly from the common published pseudocode by offsetting flow progress around `progress - 0.5`; this should be documented before anyone "fixes" it.
  - No explicit two-phase validation scene/procedure is bundled in this minimal checkout.
- Current performance-sensitive paths:
  - Two-phase normal sampling costs multiple texture samples per fragment.
  - The River shader samples two phases at base scale and, near camera, two more phases at double scale.
  - Debug flow pattern and foam mix modes repeat similar sampling for inspection.
- What should not be rediscovered or redesigned unnecessarily:
  - The two-phase reset/blend mechanism.
  - RG signed flow packing.
  - Alpha phase/noise offset usage.
  - Debug view value for visually checking flow movement.

## Research Questions

- Is the existing two-phase flow implementation still the right basis for Waterways?
- What should a focused two-phase flow feature change, if anything?
- Which pieces should be user-facing versus internal shader details?
- Should `FlowUVW` be centralized or kept duplicated across shader variants?
- What must validation prove visually?
- What artifacts might be misread as algorithm bugs when they are authored-data or material-setting issues?
- What must future higher-level authoring features preserve about this foundation?

## Findings Matrix

| Question | Finding | Evidence or source | Waterways implication | Confidence |
| --- | --- | --- | --- | --- |
| What is already strong? | The addon already has the core classic Waterways stack: spline mesh, flow/foam bake, two-phase shader, debug views, WaterSystem sampling, and simple buoyancy. | Local active files listed in "Active Add-on Baseline"; `README.md`; `docs/godot-4-user-guide.md`. | Future work should extend authoring and usability, not replace the core shader/bake foundation. | High |
| Is two-phase flow still the right shader basis? | Yes. The Valve/Catlike approach remains the right low-cost way to hide finite UV distortion for river surface detail. | Valve "Water Flow in Portal 2"; Catlike Coding texture distortion tutorial; local `FlowUVW` implementation. | Keep `FlowUVW` as the base technique, but expose better authoring inputs and shader tiers around it. | High |
| What should this focused feature do first? | Document, validate, and protect the existing shader behavior before exposing new controls. | Existing implementation already uses the canonical technique; no known bug report requires a rewrite. | Spec should define expected behavior and regression checks rather than broad refactor by default. | High |
| Does external evidence support Option A? | Yes. Production talks, Unity tutorials, Godot examples, and commercial tool docs converge on the same practical pattern Waterways already uses: encoded RG flow, limited UV distortion, two offset phases, noise/phase offset, and visible preview/debug workflows. | Valve, Uncharted, Catlike, Maujoe Godot flow-map shader, Superposition Flowmap Generator docs, Graphics Runner, IceFall, Unreal distance-field talk. | Treat external code as confirmation and vocabulary, not replacement code. The safest value is better docs and validation around the local implementation. | High |
| Is the alpha phase/noise channel worth preserving? | Yes. Multiple sources identify spatial phase/noise variation as the practical way to hide synchronized reset/pulsing. | Valve SIGGRAPH 2010; Catlike Coding; Superposition docs; local `flow_foam_noise.a` usage in water/debug/lava shaders. | Preserve `flow_foam_noise.a` as phase/noise time offset and validate that generated/imported maps do not destroy it. | High |
| Do Godot examples reinforce shader variant reuse? | Yes. Maujoe's Godot flow-map shader provides water and lava example scenes/variants using the same concept. It is Godot 3-era and MIT, so useful mainly as a Godot-shaped comparison. | Maujoe Godot Asset Library page and GitHub repo. | Waterways' water/debug/lava variants are a normal reuse pattern; hardening should prevent drift between them. | Medium-high |
| Should UV jump constants be exposed? | Maybe later, but not as a first slice. They are easy to make artist-hostile and hard to validate without visual scenes. | Current shader hard-codes `jump1`, `jump2`, and unused/extra `jump3` in water shader. | Treat jump constants as internal unless a shader-preset or advanced-controls spec defines safe ranges. | Medium |
| Should the helper be centralized? | Only if Godot 4.6 shader include/resource behavior is validated across editor, exported project, and custom shader paths. | `FlowUVW` is duplicated in three shaders, but duplication is predictable. | Plan should compare "synchronized duplication" versus "shared include/helper" before editing shader structure. | Medium |
| What is the biggest visual risk? | Reset popping, whole-surface pulsing, obvious tiling, seams, and "jelly" motion. | Valve/Catlike explain reset/pulse pitfalls; Waterways debug Flow Pattern can reveal them. | Validation must include moving debug pattern checks, not just shader compilation. | High |
| What should debug validation prove? | Direction, strength, phase hiding, alpha/noise contribution, and downstream foam/normal consistency should be visible separately. | Local debug modes; IceFall test-app workflow; Superposition realtime preview material guidance; Catlike UV test-texture workflow. | Preserve Flow Pattern, Flow Arrows, Flow Strength, Foam Mix, and Noise Map debug views as acceptance evidence for Option A. | High |
| What data quality matters most? | Neutral flow preservation, smooth RG gradients, alpha phase/noise variation, and non-flat generated channels. | Local import docs and `validate_data_textures()`; River bake flat-channel warnings. | Two-phase feature should reference data texture validation and authored-map import rules. | High |
| Does this feature include runtime water physics? | No. It only protects the visual flow basis. Runtime sampling can consume the same flow data, but belongs in a separate feature. | Current WaterSystem sampling and Buoyant are outside the shader helper. | Keep physics/API work in a runtime sampling feature folder. | High |

## Comparable Patterns

### Valve / Portal 2 / Catlike Coding

The canonical flow-map pattern is still useful for Waterways:

- Store a two-dimensional vector field in texture channels.
- Decode unsigned texture data into signed flow vectors.
- Distort tiled normal maps, not usually albedo, to create the water-motion illusion.
- Reset distortion with a sawtooth phase.
- Hide the reset by blending two half-period-offset phases.
- Use phase/noise offsets and UV jumps to reduce pulsing and visible repetition.

Waterways already implements this core idea in `river.gdshader`. The research implication is not "rewrite the shader"; it is "give artists better data to feed the shader" and make the existing shader behavior easier to validate and preserve.

### Waterways Local Variant

The local shader uses the same conceptual pattern, but details matter:

- `phaseOffset` is `0.0` or `0.5`.
- `progress = fract(time + phaseOffset)`.
- UVs are displaced by `uv_in - flowVector * (progress - 0.5)`.
- UVs are scaled, receive the phase offset, and then receive a jump offset based on `time - progress`.
- Blend weight is `1.0 - abs(1.0 - 2.0 * progress)`.
- River time is `TIME * flow_speed + flow_foam_noise.a`.

That `progress - 0.5` form should be treated as intentional local behavior until visible validation proves otherwise. A future spec should name it so a later maintainer does not "correct" it to another tutorial's exact pseudocode without checking output.

### Debug Visualization Pattern

The debug shader is part of the feature, not just a developer convenience. Two-phase flow is hard to validate from still images, so a focused feature should preserve:

- Flow Pattern: confirms continuous animated distortion.
- Flow Arrows: confirms decoded direction.
- Flow Strength: confirms force modifiers.
- Foam Mix: confirms downstream interaction with the normal/foam sampling path.

### Shader Variant Pattern

Water, debug, and lava shaders all currently duplicate the helper. A focused feature should decide whether consistency is best achieved through:

- keeping duplication and adding a maintenance note/checklist,
- using a shared include/helper if Godot 4.6 project import/export behavior supports it cleanly,
- or restricting two-phase helper changes to one shader family at a time.

## Option A Evidence Pack

Option A is not a retreat from implementation. It is the evidence-backed path because Waterways already implements the production-proven pattern that external sources repeatedly recommend.

| Evidence | What external examples show | Current Waterways match | Option A implication |
| --- | --- | --- | --- |
| Production foundation | Valve describes per-pixel flow maps, two blended phases, phase offsets, noise to reduce pulsing, and jump/offset tricks to reduce repetition. | `river.gdshader` already decodes RG flow, applies two `FlowUVW` phases, blends by triangle-wave weight, adds `flow_foam_noise.a` to time, and uses hard-coded jump vectors. | Preserve the helper and document the local variant before any "cleanup." |
| Phase reset hiding | Catlike, Graphics Runner, IceFall, Uncharted, and Unreal examples all frame reset hiding as the central problem: distortion must be limited, and the reset must be hidden by a second offset phase. | `FlowUVW` uses `fract(time + phaseOffset)` and a weight `1.0 - abs(1.0 - 2.0 * progress)`; phase B is offset by `0.5`. | Validation should look for reset popping and whole-surface pulsing, not just "does water move." |
| Phase/noise offsets | Valve, Catlike, Superposition, and IceFall use noise or phase textures to spread reset timing across the surface. | `float time = TIME * flow_speed + flow_foam_noise.a` exists in river, debug, and lava shaders; the debug shader also exposes Noise Map. | Keep alpha as phase/noise offset and add checks for "alpha present, readable, and visually desynchronizing resets." |
| UV jump / repetition control | Catlike explains jump vectors near `0.2..0.25`; Valve discusses phase offsets and repetition; Uncharted notes placement/phase offsets and minimizing distortion at high blend. | River uses `jump1 = vec2(0.24, 0.2083333)` and `jump2 = vec2(0.20, 0.25)`, matching the established jump-value family. | Treat current constants as intentional local defaults; changing or exposing them requires visual A/B proof. |
| Debug/preview workflow | IceFall describes a small test app; Catlike uses a UV test texture; Superposition uses realtime preview materials and editor time; Maujoe ships demo scenes for water/lava. | Waterways has Flow Pattern, Flow Arrows, Flow Strength, Foam Mix, Noise Map, and data-texture validation. | Option A should add a validation procedure/scene around existing debug affordances, not invent a new shader first. |
| Cross-material reuse | Godot/Maujoe and Superposition both apply the same flow-map idea to water, lava, slime/solid materials, foam, and preview materials. | Waterways uses the same conceptual helper in river, river_debug, and lava. | Preserve cross-shader behavior and guard against helper drift. |
| Data texture hygiene | Catlike and Superposition both call out linear/non-sRGB data and compression artifacts; Waterways already validates uncompressed/non-normal-map/mipmap assumptions. | `validate_data_textures()` checks readable image data, import flags, block compression, mipmaps, and neutral RG. | Keep data texture validation in the acceptance story; visual artifacts may be import/data issues rather than helper bugs. |

## Implementation Patterns To Preserve

These are the local patterns Option A should protect. They are described here as research findings, not as code-change instructions.

| Pattern | Local implementation | Evidence and rationale | Guardrail |
| --- | --- | --- | --- |
| Packed RG flow contract | `flow_foam_noise.rg` stores signed flow as `0..1`, neutral `0.5`, decoded by `(flow - 0.5) * 2.0`. | Valve, Catlike, Graphics Runner, Maujoe, and Superposition all use color channels as 2D vector fields. | Do not change channel packing in this feature. |
| Alpha phase/noise offset | River, debug, and lava add `flow_foam_noise.a` to shader time. | Valve/Catlike/Superposition use noise/phase offsets to hide synchronized resets and pulsing. | Validate alpha is preserved through bake/import and visible in Noise Map debug view. |
| Two half-period phases | `FlowUVW(..., false)` and `FlowUVW(..., true)` use a `0.5` phase offset. | Canonical reset hiding pattern from Valve/Catlike/Graphics Runner/IceFall/Uncharted. | Any helper edit must prove both phases still crossfade without visible pop. |
| Triangle-wave weights | `uvw.z = 1.0 - abs(1.0 - 2.0 * progress)`. | Catlike and Unreal references note triangle-wave-style blending is sufficient and practical. | A future smoother curve is a visual-change proposal, not a harmless refactor. |
| Local `progress - 0.5` distortion center | `uvw.xy = uv_in - flowVector * (progress - 0.5)` keeps the peak phase closer to the at-rest UV than the simplest tutorial form. | Catlike and Uncharted both discuss flow offsets/minimizing distortion at peak blend; Valve distinguishes different offset ranges for color/debris versus normals. | Document as intentional Waterways behavior until A/B validation says otherwise. |
| Jump constants | River/debug/lava use `vec2(0.24, 0.2083333)`; river/debug also use `vec2(0.20, 0.25)` for the second detail layer. | Catlike identifies practical jump values around this family and explains long-loop benefits. | Do not expose or adjust jumps in Option A without a separate spec. |
| Debug views as product surface | Debug shader exposes Flow Pattern, Arrows, Strength, Foam Mix, Noise Map, and raw channel views. | External examples repeatedly use preview/test views because flow bugs are motion artifacts. | Preserve debug shader parity with river shader when validating. |
| Shader variant synchronization | River, debug, and lava duplicate the helper. | Godot supports shader includes, but packaging/export/custom-material risks still need local validation. | Prefer a drift check or maintenance note before centralizing code. |
| Data texture import checks | `validate_data_textures()` checks readable image data, neutral flow, compression, normal-map treatment, and mipmaps. | Catlike and Superposition warn about non-color data, sRGB, and compression artifacts. | Treat import failures as first-class explanations for artifacts. |

## Practical Implementation Examples

These examples are useful because they show working patterns around the exact risks Option A needs to protect.

| Example | Practical pattern | Waterways reuse | Source quality | Reuse/licensing note |
| --- | --- | --- | --- | --- |
| Valve "Water Flow in Portal 2" | Artist-authored vector fields, two blended normal phases, noise for pulsing, phase offsets/jumps, performance budgets. | Strong conceptual backing for preserving current shader and validating motion visually. | High: production SIGGRAPH talk. | Conceptual only; do not copy slides/code/assets. |
| Naughty Dog "Water Technology of Uncharted" | Blend two flow textures offset by half phase; use phase textures to spread changes; author flow, velocity, foam, and phase from tools. | Reinforces `flow_foam_noise.a`, phase spreading, and the "flow guides the player" debug mindset. | High: production GDC talk; Slideshare text mirrors slide content. | Conceptual only; slides/code are not reusable without permission. |
| Catlike Coding Texture Distortion | Step-by-step `FlowUVW`: decode RG, add alpha noise to time, two phases, triangle weight, UV jump vectors, flow strength, flow offset, debug with test texture. | Closest tutorial match to Waterways helper and jump values; explains why Option A should preserve local constants. | Medium-high: detailed technical tutorial, Unity/CG context. | Treat code as conceptual; adapt ideas only to Godot and Waterways contracts. |
| Maujoe Godot Flow Map Shader | Godot 3 asset with water/lava scenes, two blended layers, optional noise, channel selection, material controls, and performance/customization notes. | Godot-shaped evidence that water/lava sharing is normal and that noise/realtime preview are useful. | Medium: community Godot repo/asset, older engine. | Asset page says MIT; copying would still require license notice and Godot 4 adaptation. Prefer conceptual reuse. |
| Superposition Flowmap Generator shaders/docs | Unity shaders use flow speed, animation length, phase-noise texture, foam mask, realtime preview material, editor-time animation, and linear/uncompressed import settings. | Reinforces current channel contract, debug preview, and data texture validation. | Medium: product documentation; practical but tied to proprietary tool. | Conceptual only unless the shader package license is separately verified. |
| Graphics Runner flow-map post | Compact HLSL example for RG decode, half-cycle phase offset, normal-map blending, and reset hiding. | Confirms the baseline math and the "half-cycle second layer" expectation. | Medium: technical blog with code. | Conceptual unless blog code license is explicit. |
| IceFall Games water flow shader | HLSL/test app pattern, world-space flow maps, flow lines, slower river edges, noise to reduce pulsing, and discussion of gotchas. | Useful validation ideas: small controlled test scene, flow-line/arrows, edge slowdown checks. | Medium: technical blog by practitioner. | Conceptual unless license for test app/code is verified. |
| Unreal distance-field / simulation tricks | UE examples advect two textures with offset phase, use triangle-wave-style fade, and show distance-field-modified flow vectors with stretching risks. | Useful for validation language: excessive vector magnitude and content-dependent flow edits can cause stretching even when algorithm is correct. | High-medium: Epic/Unreal GDC production talk. | Conceptual only. |
| Dan Lord Unity Shader Graph flow maps | Artist-facing explanation of painting flow around rocks/assets instead of global panning. | Reinforces authoring/debug interpretation: bad-looking flow may be authored-data direction/speed, not `FlowUVW`. | Low-medium: portfolio/technical art blog. | Conceptual only. |

## Option A Validation Ideas

Validation should prove preservation, not introduce new behavior.

| Validation idea | What it proves | How to run later | Failure signs |
| --- | --- | --- | --- |
| Static helper parity check | River, debug, and lava still use equivalent `FlowUVW` phase, weight, alpha-time, and jump behavior. | Text scan or small script comparing helper signatures and key expressions. | One shader changes phase math, omits alpha, or uses different jump defaults unintentionally. |
| Flow Pattern motion pass | Reset hiding works in motion. | In a visible Godot editor scene, choose Debug View -> Flow Pattern and watch at least 10 seconds at default, slow, and high `flow_speed`. | Full-surface pulse, sudden reset pop, stuck pattern, or moving pattern disagreeing with arrows. |
| Noise Map / alpha A-B pass | Alpha phase/noise offset desynchronizes resets. | Compare Flow Pattern with a flat alpha map and with varied `flow_foam_noise.a`; also inspect Debug Noise Map. | Whole river changes phase at once, alpha appears flat unexpectedly, or alpha import destroys variation. |
| Flow Arrows versus pattern pass | Direction decode and tangent/binormal interpretation match visual movement. | Toggle Flow Arrows and Flow Pattern on a curved river with bends and a neutral zone. | Arrows point upstream while pattern moves downstream, arrows rotate at UV seams, or neutral zone moves. |
| Flow Strength pass | Force modifiers remain visible and bounded. | Vary `flow_base`, `flow_steepness`, `flow_distance`, `flow_pressure`, and `flow_max`; inspect Flow Strength. | Saturated strength everywhere, no response to modifiers, or strength/color mismatch with motion. |
| Foam Mix pass | Downstream foam/normal path still uses the same two-phase sample family. | Inspect Foam Mix on a river with foam channel variation and compare against default water. | Foam appears detached from flow, debug and default shader disagree, or foam ignores two-phase normals. |
| Variant parity pass | River/debug/lava remain conceptually synchronized. | Use similar flow maps/material speeds on river and lava variants, then compare flow direction/reset behavior. | Lava behaves like a separate algorithm without a documented reason. |
| Data texture import pass | Artifacts are not caused by gamma/compression/mipmap import. | Run `Validate Data Textures` and inspect raw Flow Map, Noise Map, and neutral-flow areas. | Missing readable image data, block compression, mipmaps before validation, no neutral RG sample, or flat channels. |
| Artifact triage pass | Bad output is categorized before shader edits. | When "jelly," seams, or repetition appear, capture Flow Pattern, Flow Arrows, Flow Strength, Noise Map, material settings, texture import settings, and a short screen recording. | Editing `FlowUVW` is proposed before ruling out normal texture, UV scale, flow speed/force, bake gradients, or import settings. |
| Performance sanity pass | Option A does not increase shader cost. | Count flow-map and normal-map samples per shader mode before and after any future hardening patch. | Extra texture samples or branches appear without spec acceptance. |

## Godot 4.6+ Findings

- The active shader implementation is ordinary Godot spatial shader code and does not depend on compute shaders or custom render devices.
- Godot shader compilation is necessary but insufficient; two-phase flow correctness is motion-based and must be checked visually.
- `hint_screen_texture` and `hint_depth_texture` are adjacent water-shader concerns, but the two-phase flow helper itself does not require screen/depth access.
- Data textures should remain numeric and linear: lossless/uncompressed import, normal map disabled, mipmaps disabled unless validated for a specific path.
- If shader include/preprocessor support is considered for centralization, it must be validated in the Godot editor, saved scenes, exports, and custom shader assignment paths before use.
- Mobile/Compatibility renderer risk is mostly shader cost and adjacent screen/depth features, not the `FlowUVW` math itself.
- Visible editor validation is human-assisted by default in this workspace.

## Performance and Scale Findings

- Expected scene scale: Ordinary authoring with one or more River nodes, default shader, and generated `flow_foam_noise`.
- Expected river count, curve complexity, or generated mesh size: Two-phase cost is per shaded pixel, not directly per curve point, though flow-map resolution affects data quality.
- Expected bake texture sizes: Current generated River maps range from 64 to 1024 source size before padding.
- Expected runtime texture memory: Two-phase flow reuses the existing packed flow map and normal texture; exposing more parameters should not add textures by itself.
- Editor bake-time risks: Not part of this feature unless validation requires generating maps.
- Runtime frame-time risks:
  - Two base normal samples for phase A/B.
  - Two more normal samples for near-camera detail in the River shader.
  - Foam mix also uses sampled normal texture data.
- GPU readback risks: None in the shader feature itself; only relevant when generating validation maps.
- Physics query or raycast-count risks: None in the shader feature itself.
- Renderer/backend assumptions:
  - Two-phase UV distortion should work across renderers.
  - Full water shader quality may differ because of screen/depth/refraction, which should be tested separately from `FlowUVW`.
- Mobile, Compatibility, or VR constraints:
  - If a mobile-safe shader tier is created later, two-phase flow can remain, but normal-sample count may need a lower-cost path.
- Recommended budget or measurement approach:
  - Count texture samples in each shader tier.
  - Compare default shader versus a low-cost two-phase-only preset if one is later specified.
  - Validate visual quality before optimizing away the second detail layer.

## Legacy Waterways Reference

This minimal checkout does not include a `legacy/godot-3/addons/waterways` snapshot, although the spec-driven docs mention one may exist in other workspaces.

- Relevant legacy files: Not present in this checkout.
- Behavior to preserve:
  - Two-phase flow-map animation as a central River visual technique.
  - Debug flow-pattern visualization.
  - Flow/foam packed texture contract where compatible with Godot 4.
- Behavior to change:
  - Document Godot 4 shader syntax and local behavior explicitly.
  - Avoid depending on legacy Godot 3 shader constants or import settings.
- Obsolete APIs to avoid: Godot 3 shader/resource/editor APIs.
- Risks discovered in `audit/code-audit.md`: Audit file not present in this checkout.
- What belongs in active Godot 4.6+ code:
  - Godot 4 shader uniforms.
  - Current packed data contract.
  - Visible validation and data import checks.
- What should remain legacy-only:
  - Any Godot 3 shader syntax or editor assumptions.

## Options

### Option A: Preserve and Validate Existing Two-Phase Flow

- Benefits:
  - Lowest risk.
  - Protects the working shader foundation.
  - Matches the dominant practical implementation pattern found in production talks, Unity tutorials, Godot examples, and flow-map tool docs.
  - Produces immediate value through documentation, visual regression checks, and drift protection across river/debug/lava shaders.
  - Helps future work distinguish shader defects from authored-data, texture-import, normal-texture, UV-scale, or material-setting artifacts.
- Costs:
  - Does not add new artist controls by itself.
  - May feel less exciting than a visible new feature.
  - Requires careful visual validation, because the main success signal is motion quality rather than static code correctness.
- Risks:
  - If the current local variant has a subtle artifact, this option may preserve it until validation reveals it.
  - If validation is too shallow, Option A could accidentally rubber-stamp behavior that only works for the current demo inputs.
- Fit for Waterways: Excellent.
- Source/reuse constraints: Uses existing local implementation. External shader code should remain conceptual unless license compatibility, attribution, and Godot 4 adaptation are explicitly handled.

Option A should therefore be framed as an active hardening pass:

- Freeze the current behavior as the baseline to observe.
- Name the local `FlowUVW` variant, including `progress - 0.5`, alpha time offset, triangle blend, and jump constants.
- Validate visible reset hiding through Flow Pattern rather than assuming it from code shape.
- Validate the data contract through existing texture checks and debug views.
- Add a future maintenance guard against water/debug/lava drift.
- Defer parameter exposure and helper centralization until those changes have their own spec and visible A/B evidence.

### Option B: Expose Advanced Two-Phase Parameters

- Benefits:
  - Gives artists more direct control over phase jumps, scale layers, blend behavior, and phase/noise strength.
  - Could reduce repetition in difficult rivers.
- Costs:
  - Adds UI and validation burden.
  - Easy to expose parameters that create bad output.
- Risks:
  - Can make the material inspector noisy.
  - Users may misdiagnose bad flow maps as parameter problems.
- Fit for Waterways: Good later, after validation and preset design.
- Source/reuse constraints: Parameters should be locally designed; tutorials are conceptual only.

### Option C: Refactor Shader Helper Into a Shared Include

- Benefits:
  - Reduces duplication across water, debug, and lava shaders.
  - Makes future changes easier to keep synchronized.
- Costs:
  - Requires Godot 4.6 shader include/import/export validation.
  - Could complicate custom shader workflows.
- Risks:
  - A packaging or resource-path issue could break all built-in shader variants.
- Fit for Waterways: Conditional.
- Source/reuse constraints: Local implementation only; verify Godot support before planning.

## Recommendation

- Recommended direction: Start with Option A. Treat two-phase flow as a foundation-hardening feature. Defer Option B and Option C until validation proves they are worth the complexity.
- Why this fits Waterways:
  - The addon already has the core technique.
  - The biggest risk is accidental shader churn or insufficient visual proof, not lack of math.
  - Future authoring layers, shader tiers, and imported maps all depend on this behavior remaining stable.
- What to do first:
  - Write a spec that defines expected two-phase flow behavior and non-goals.
  - Add a validation plan for visible Flow Pattern, Flow Arrows, Flow Strength, and default River shader animation.
  - Document the current local `FlowUVW` variant and channel contract.
  - Decide whether duplicated helper code is acceptable for the next release.
- What to defer:
  - Exposed UV jump parameters.
  - Shared shader include/refactor.
  - Compute wakes, Gerstner waves, FFT, river-network logic, and runtime sampling API.
- What to avoid:
  - Replacing the helper just because a tutorial pseudocode version is slightly different.
  - Combining this focused feature with broad water shader redesign.
  - Treating shader compilation as proof of motion quality.
- Confidence: High.

## Spec Implications

- User/developer workflows:
  - A River user can rely on built-in water/lava/debug shaders to animate generated or imported flow maps with continuous two-phase flow.
  - A maintainer can validate flow direction, strength, and reset behavior through debug views.
  - A custom shader author can preserve the Waterways flow-map uniform contract.
- Functional requirements:
  - Decode RG flow from packed `0..1` into signed vectors.
  - Use two half-period-offset phases with triangle-wave weights.
  - Use alpha phase/noise offset when available.
  - Preserve compatible behavior across water, debug, and lava shader variants where the helper is shared conceptually.
  - Keep invalid/missing flow-map fallback behavior visible and safe.
- Non-functional requirements:
  - Avoid unnecessary shader churn.
  - Keep shader cost understandable and documented.
  - Keep the current default material behavior unless a visible validation result justifies changing it.
- Editor usability requirements:
  - Debug views must make flow direction and motion obvious.
  - If future parameters are exposed, ranges and names must be artist-safe.
- Runtime/API requirements:
  - None beyond shader behavior for this focused feature.
- Generated asset/resource requirements:
  - Preserve `flow_foam_noise` channel metadata.
  - Validate neutral flow and alpha/noise behavior for generated/imported maps.
- Acceptance criteria:
  - Flow Pattern debug view shows continuous motion without obvious full-surface pulsing.
  - Flow Arrows match expected decoded direction.
  - Flow Strength reflects modifier parameters.
  - Default River shader and debug shader remain consistent enough for diagnosis.
  - Lava shader remains compatible or clearly documented if intentionally different.
- Non-goals:
  - New flow-map authoring layers.
  - Runtime water sampling API.
  - Waterfall/rapid system.
  - Compute wakes, Gerstner, or FFT features.
- Open questions to carry forward:
  - Is the `progress - 0.5` local variant visually preferable or legacy-compatible?
  - Should `jump1`/`jump2` be documented only, exposed as advanced controls, or moved into presets?
  - Should shader helper duplication be accepted for packaging simplicity?

## Plan Implications

- Architecture direction:
  - Prefer preserving existing shader behavior and adding documentation/validation around it.
  - If changes are needed, modify shader variants deliberately and compare visible output.
- Affected files/modules:
  - `addons/waterways/shaders/river.gdshader`
  - `addons/waterways/shaders/river_debug.gdshader`
  - `addons/waterways/shaders/lava.gdshader`
  - `addons/waterways/resources/river_bake_data.gd`
  - `addons/waterways/river_manager.gd`
  - Future validation scene/docs if created.
- Editor-only code:
  - Debug view selection and validation workflow.
- Runtime-safe code:
  - Spatial shaders and material parameters.
- Shared resources/data:
  - `flow_foam_noise`
  - `dist_pressure`
  - `RiverBakeData` channel metadata.
- Texture channels, data formats, and metadata:
  - Do not change channel packing in this feature.
  - If alpha phase/noise behavior is adjusted, update metadata and validation.
- Import/export expectations:
  - Imported maps should preserve neutral flow and alpha/noise semantics.
  - Export details belong in a separate import/export feature.
- Lifecycle, cleanup, and re-entry concerns:
  - No async lifecycle unless new validation bake actions are added.
- Migration or compatibility concerns:
  - Existing scenes/materials should keep the same default visual behavior.
  - Custom shaders should continue to work if they preserve Waterways uniforms.
- Documentation updates needed:
  - Shader behavior notes.
  - Debug validation procedure.
  - Channel contract reminder.
  - Warning that two-phase visual correctness requires visible motion validation.

## Validation Implications

- Automated checks:
  - Static check that `FlowUVW` or equivalent helper exists in expected built-in shaders.
  - Static check that `flow_foam_noise.a` still contributes to shader time where expected.
  - Data texture validation for neutral flow and readable image data.
- Human-assisted Godot/editor checks:
  - Enable Waterways, select a River with generated maps, and switch Debug View to Flow Pattern.
  - Observe motion for at least several seconds.
  - Switch to Flow Arrows and Flow Strength to confirm direction and force response.
  - Check default water shader and lava shader if both are part of the feature scope.
- Visual scene or debug-view checks:
  - A curved river with one slow pool and one faster bend.
  - A neutral-flow section to prove fallback/no-motion behavior.
  - A phase/noise map with visible variation to reduce pulsing.
- Shader checks:
  - River shader compiles and animates.
  - River debug shader compiles and visualizes modes.
  - Lava shader compiles and animates if included.
  - Full shader output should be checked in Forward+ first.
- Bake-output checks:
  - `flow_foam_noise.rg` has non-flat directional variation.
  - `flow_foam_noise.a` is readable and non-destructive.
  - `dist_pressure` modifiers do not push flow strength into unusable saturation.
- Runtime/API checks:
  - Not required for this feature unless a validation scene also checks WaterSystem flow.
- Performance checks:
  - Count normal texture samples in default shader.
  - Compare any future low-cost preset against default.
- Artifact hygiene checks:
  - Generated bakes and validation scenes should not be included in minimal packages unless intentionally shipped.
- Failure signs that should stop implementation:
  - Visible reset popping or synchronized pulsing across the river.
  - Flow arrows disagree with moving flow pattern.
  - Shader variants drift so debug view no longer diagnoses the default shader.
  - Existing scenes change appearance without an accepted spec decision.

## Risks and Unknowns

- A small mathematical change could alter established visual behavior even if it looks more like published pseudocode.
- Centralizing shader code could introduce resource-path or export risks.
- Exposing advanced parameters could make the material inspector noisy and harder for ordinary users.
- Visual quality depends heavily on flow-map data and normal texture quality, not only `FlowUVW`.
- The minimal checkout lacks validation scenes, so human-assisted visible checks must be created or requested before claiming success.

## Context Challenge Notes

- Possible misread context: Treating authored-data artifacts, high `flow_speed`, high `flow_force`, or repetitive normal textures as bugs in the two-phase algorithm.
- Evidence: Published two-phase flow specifically solves reset popping, but cannot prevent every tiling or "jelly" artifact if the inputs are poor.
- Confidence: High.
- Quick check before patching: Use debug Flow Arrows, Flow Strength, and Flow Pattern together. If arrows/strength are correct but motion looks bad, inspect normal texture, UV scale, flow speed, and generated map gradients before editing `FlowUVW`.
- User-facing note or question to raise: "The algorithm may be working while the authored data or material settings are causing the artifact. Can we check debug arrows, strength, and pattern before changing the shader?"
- Outcome after the check: Not yet run.

## Source Quality and Reuse Notes

Source categories:

- Local active code: Highest authority for current Waterways behavior.
- Local spec/validation docs: High authority for channel contracts and known limitations.
- Official Godot docs: High authority for shader/resource behavior.
- Production talk: Strong conceptual reference for two-phase flow behavior and validation vocabulary.
- Practical engine repository or asset: Useful for implementation pattern comparison, but authority depends on age, engine version, maintenance state, and license clarity.
- Tutorial/blog: Useful explanation; do not copy implementation blindly.
- Agent inference: Must be validated visually before implementation.

Reuse/licensing notes:

- License: Verify before copying external code or assets.
- Code-copy allowed: Not assumed for Valve/Catlike material.
- Conceptual reference only: Default for external talks/tutorials.
- Godot/MIT examples: Copying may be possible only with license notice and compatibility review; prefer conceptual reuse because Waterways already has local code.
- Product documentation examples: Treat as workflow and parameter evidence, not source-code permission.
- YouTube/video demonstrations: Useful for visual-validation expectations, but do not treat video-only material as a code source.
- Attribution needed: Mention material influence in docs when directly shaping design.
- Compatibility concern: Unity/HLSL examples must be adapted to Godot shader language and Waterways' local channel contract.

## Sources

| Source | Type | Why it matters | Reuse/licensing note |
| --- | --- | --- | --- |
| [addons/waterways/shaders/river.gdshader](../../../addons/waterways/shaders/river.gdshader) | Local active code | Current built-in River two-phase flow implementation. | Local project code under Waterways license. |
| [addons/waterways/shaders/river_debug.gdshader](../../../addons/waterways/shaders/river_debug.gdshader) | Local active code | Current visible diagnostic path for flow pattern, arrows, strength, and foam mix. | Local project code under Waterways license. |
| [addons/waterways/shaders/lava.gdshader](../../../addons/waterways/shaders/lava.gdshader) | Local active code | Current second material variant using the same two-phase flow helper. | Local project code under Waterways license. |
| [addons/waterways/river_manager.gd](../../../addons/waterways/river_manager.gd) | Local active code | Assigns generated flow textures and shader uniforms used by the two-phase shader. | Local project code under Waterways license. |
| [addons/waterways/resources/river_bake_data.gd](../../../addons/waterways/resources/river_bake_data.gd) | Local active code | Defines channel metadata for flow, foam, and phase/noise data. | Local project code under Waterways license. |
| [docs/godot-4-user-guide.md](../../../docs/godot-4-user-guide.md) | Local docs | Documents Waterways channel contract, debug views, and bake expectations. | Local project documentation. |
| [Valve: Water Flow in Portal 2](https://cdn.cloudflare.steamstatic.com/apps/valve/2010/siggraph2010_vlachos_waterflow.pdf) | Production talk | Foundational two-phase flow-map reference: phase offsets, jumps, flow-map authoring, and reset hiding. | Conceptual reference only unless license explicitly permits reuse. |
| [Valve: Making and Using Non-Standard Textures](https://steamcdn-a.akamaihd.net/apps/valve/2011/gdc_2011_grimes_nonstandard_textures.pdf) | Production talk | Practical flow-map generation and packed vector/opacity data; reinforces RG vector encoding, alpha masks, authoring tools, and Houdini-generated flow maps. | Conceptual reference only; no code or asset copying. |
| [Naughty Dog / GDC Vault: Water Technology of Uncharted](https://www.gdcvault.com/play/1015309/Water-Technology-of) | Production talk | Confirms flow shader, mesh generation, and phase/authoring context from a shipped production water system. | Conceptual reference only. |
| [Slideshare mirror: Water Technology of Uncharted](https://www.slideshare.net/slideshow/water-technologyofunchartedgdc2012/12977478) | Slide mirror | Searchable slide text for half-phase flow blending, phase texture offsets, UV-start offsets, authoring flow/velocity/foam/phase, and flow reuse beyond water. | Use only as a readable mirror of the talk; do not copy code/assets. |
| [Catlike Coding: Texture Distortion](https://catlikecoding.com/unity/tutorials/flow/texture-distortion/) | Tutorial/blog | Clear explanation of vector decoding, distortion reset, two-phase blending, and import concerns. | Conceptual reference; do not copy Unity code directly. |
| [Graphics Runner: Animating Water Using Flow Maps](https://graphicsrunner.blogspot.com/2010/08/water-using-flow-maps.html) | Tutorial/blog | Compact HLSL-style implementation showing RG decode, reset limiting, half-cycle layer offset, normal sampling, and blend factor. | Conceptual unless a license is explicitly identified. |
| [IceFall Games: Water flow shader](https://mtnphil.wordpress.com/2012/08/25/water-flow-shader/) | Tutorial/blog | Practical HLSL/test-app notes on two textures, flow lines, per-pixel flow, random/phase offsets, pulsing, and gotchas. | Conceptual unless a license is explicitly identified. |
| [Maujoe/godot-flow-map-shader](https://github.com/Maujoe/godot-flow-map-shader) | GitHub repository / Godot asset | Godot-shaped implementation with water/lava examples, two blended layers, optional noise, channel controls, material parameters, and performance/customization notes. | Asset listing reports MIT; verify repo license text before copying. Prefer conceptual comparison. |
| [Godot Asset Library: Flow Map Shader](https://godotengine.org/asset-library/asset/246) | Godot asset listing | Confirms Maujoe asset metadata, Godot version, MIT license listing, and water/lava demo framing. | Useful for license/source-quality note; still verify repo license before copying. |
| [Superposition: Flowmap Shaders](https://www.superpositiongames.com/files/flowmap_generator/docs/FlowmapShaders.pdf) | Tool documentation | Practical parameter set for flow-map shaders: flow speed, animation length, phase-noise texture, foam mask channel, normal tiling, and edge-fade variants. | Conceptual/product documentation; do not copy shaders without license review. |
| [Superposition: Flowmap Generator River Tutorial](https://superpositiongames.com/files/flowmap_generator/docs/RiverExample.pdf) | Tool documentation | Realtime preview material, editor-time animation, separate river mesh over terrain, linear/uncompressed flow-map import, and baked flow-map usage. | Conceptual workflow reference. |
| [Superposition: Flowmap Generator Quickstart](https://superpositiongames.com/files/flowmap_generator/FlowmapGeneratorQuickstart.pdf) | Tool documentation | Editor preview, material animation, flow-map import settings, simulation-step tuning, and axis/speed troubleshooting. | Conceptual workflow reference. |
| [Unreal: Distance Fields and Simulation Tricks](https://media.gdcvault.com/gdc2019/presentations/Brucks_Ryan_Distance_Fields_And.pdf) | Production talk | Confirms two offset advected textures, triangle-wave-style flow-map blending, distance-field-modified flow vectors, and stretching risks from excessive magnitude. | Conceptual reference only. |
| [Dan Lord: Water Shader - Flow-Maps](https://www.danlord3d.co.uk/tooling-visual-effects/unity-water-shader) | Technical art blog | Artist-facing flow-map authoring example for directing water around rocks/assets instead of global panning. | Conceptual only. |
| [LouisGameDev: Shader Tutorial: Flow-Map](https://louisgamedev.medium.com/shader-tutorial-flow-map-4410af832a8d) | Tutorial/blog | Simple explanation of fract-based reset, phase0/phase1 half-offset, and cross-fade to hide loop ends. | Conceptual only; Medium code/prose should not be copied. |
| [Godot: Shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/index.html) | Official Godot docs | Relevant for shader-language behavior and any future include/preprocessor decision. | Official docs; use API guidance, not copied prose. |
| [Godot: Shader preprocessor](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shader_preprocessor.html) | Official Godot docs | Documents `.gdshaderinc` and `#include` support, restrictions, and naming-collision risks for any future helper centralization. | Official docs; use API guidance, not copied prose. |
| [Godot: Shading language](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html) | Official Godot docs | Relevant for sampler hints, filtering/repeat expectations, and Godot shader-language adaptation. | Official docs; use API guidance, not copied prose. |
| [Godot: Screen-reading shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html) | Official Godot docs | Adjacent context for the current water shader, though not required by `FlowUVW` itself. | Official docs; use API guidance, not copied prose. |
