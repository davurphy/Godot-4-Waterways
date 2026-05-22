# Preliminary Research: Curve-Derived River Flow

## Purpose

This document captures the current Waterways flow-map behavior and the design question it raises:

Should `River -> Generate Flow & Foam Map` derive a baseline downstream flow from the river curve, then use colliders as modifiers for banks, foam, pressure, and obstacles?

This is preliminary research only. It does not authorize a shader rewrite, bake redesign, public API change, or behavior change by itself.

## Current Finding

Yes, with one caveat: the current code path is clear, but that does not mean the current design is ideal.

The current generated-map workflow can collapse to neutral flow when the bake sees no collider pixels. In that state, the river may still animate with fallback flow after geometry edits invalidate the bake, but a regenerated flat map can make the visible debug flow appear stationary or directionally meaningless.

## Current Waterways Code Path

What the current code shows:

- Moving river geometry invalidates the generated bake. `addons/waterways/river_manager.gd` calls `_set_valid_flowmap(false)` in `_invalidate_generated_bake()`.
- When the flow map is invalid, `addons/waterways/shaders/river.gdshader` uses fallback flow: `flow = vec2(0.5, 0.572)`.
- When `River -> Generate Flow & Foam Map` runs, `addons/waterways/river_manager.gd` builds a collision map, converts that through normal and flow filters, combines RGBA data, then assigns the result as a valid flow map.
- The collision probe in `addons/waterways/water_helper_methods.gd` samples from the river mesh point upward to `real_pos + Vector3.UP * raycast_dist`.
- The river shader decodes packed RG flow with `(flow - 0.5) * 2.0`.
- The debug arrow view rotates arrows from the decoded flow vector with `atan(flow.y, flow.x)`.

Key local source references:

- `addons/waterways/river_manager.gd`: `_generate_flowmap()` starts the River bake.
- `addons/waterways/river_manager.gd`: `generate_collisionmap(...)` creates the collision-derived source image.
- `addons/waterways/river_manager.gd`: `apply_normal_to_flow(...)` converts the generated normal map to flow.
- `addons/waterways/river_manager.gd`: `apply_combine(blurred_flow_map, blurred_flow_map, blurred_foam_map, tiled_noise)` packs generated flow, foam, and alpha/noise.
- `addons/waterways/river_manager.gd`: `valid_flowmap = true` marks regenerated data as valid.
- `addons/waterways/river_manager.gd`: `_invalidate_generated_bake()` calls `_set_valid_flowmap(false)`.
- `addons/waterways/water_helper_methods.gd`: `real_pos_up := real_pos + Vector3.UP * raycast_dist`.
- `addons/waterways/shaders/river.gdshader`: invalid flow maps use fallback `flow = vec2(0.5, 0.572)`.
- `addons/waterways/shaders/river.gdshader`: valid flow maps decode RG with `(flow - 0.5) * 2.0`.
- `addons/waterways/shaders/river_debug.gdshader`: Flow Arrows rotate from `atan(flow.y, flow.x)`.

## Observed Evidence

The reported Output warnings for the validation attempt were:

```text
Waterways: River collision bake found no collider pixels. Check baking raycast layers, collider placement, and raycast distance.
Waterways: Generated flow map RG has limited debug contrast (R 0.498..0.498 avg 0.498, G 0.502..0.502 avg 0.502; R flat, G flat). Debug views may appear as a solid color until the bake input and filter settings produce varied data.
Waterways: Generated foam map B has limited debug contrast (B 0.000..0.000 avg 0.000; B flat, B near black). Debug views may appear as a solid color until the bake input and filter settings produce varied data.
Waterways: Generated distance/pressure RG has limited debug contrast (R 0.000..0.000 avg 0.000, G 0.000..0.000 avg 0.000; R flat, R near black, G flat, G near black). Debug views may appear as a solid color until the bake input and filter settings produce varied data.
```

Interpretation:

- The bake found no collider pixels.
- The generated RG flow was flat near neutral.
- Neutral RG decodes to almost zero flow.
- Foam and distance/pressure data were also flat.
- Flow Pattern can appear stationary because the generated vector has almost no movement.
- Flow Arrows can appear sideways or arbitrary because they are visualizing a near-zero vector, where angle is not meaningful.

This supports the current-system diagnosis: no detected collider pixels can produce a generated map with no meaningful downstream direction.

## User Experience Problem

The current behavior creates a confusing authoring loop:

1. A river point is moved.
2. The generated flow map is invalidated.
3. The shader falls back to default flow, so the river visibly animates.
4. The user regenerates the Flow & Foam Map.
5. The bake sees no useful collider pixels or flat collision data.
6. The regenerated map becomes neutral or low contrast.
7. The river appears stationary again, and Flow Arrows show strange directions.

This makes the bake workflow feel like it broke flow, when it actually replaced fallback flow with a flat generated map.

## Design Tension

Collider use is currently doing too much.

For authoring, colliders can be useful as bake inputs for banks, obstructions, foam, distance, and pressure. But if colliders are required for the baseline downstream direction, the river can fail to flow when the bake helpers are missing, below the river, on the wrong layer, too uniform, or intentionally absent.

This also creates friction with `Snap to Colliders`. The same scene geometry can be used for point placement and bake influence, even though those are different authoring tasks. A collider that helps snapping can become an unwanted flow-map obstruction, and a bake helper collider can interfere with comfortable river editing if it is not isolated.

## Original Waterways Comparison

The original `Arnklit/Waterways` repository was checked directly from GitHub for this research. The local checkout used for comparison was the current `main` branch cloned on 2026-05-22.

Repository and author intent sources:

- Arnklit/Waterways GitHub repository: https://github.com/Arnklit/Waterways
- Original Waterways README: https://github.com/Arnklit/Waterways
- Kasper Frandsen ArtStation project note: https://arnklit.artstation.com/projects/q9P532
- GameFromScratch overview: https://gamefromscratch.com/waterways-terrain-add-ons-for-godot/

### Original Godot 3 Behavior

The original Godot 3 addon already used a collision-derived generated flow map. This was not introduced by the Godot 4 port.

Original code path, with line anchors from the comparison snapshot:

- `addons/waterways/river_manager.gd`: `bake_texture()` starts at line 455 and calls `_generate_river()` and then `_generate_flowmap(pow(2, 6 + baking_resolution))`.
- `addons/waterways/river_manager.gd`: `_generate_flowmap()` starts at line 612 and creates a blank RGB collision image.
- `addons/waterways/river_manager.gd`: `_generate_flowmap()` calls `WaterHelperMethods.generate_collisionmap(...)` at line 623.
- `addons/waterways/river_manager.gd`: the collision image then goes through `apply_flow_pressure`, `apply_dilate`, `apply_normal`, `apply_normal_to_flow`, `apply_blur`, `apply_foam`, and `apply_combine`.
- `addons/waterways/river_manager.gd`: `apply_combine(blurred_flow_map, blurred_flow_map, blurred_foam_map, tiled_noise)` packs RG flow, B foam, and A phase/noise at line 672.
- `addons/waterways/river_manager.gd`: the shader parameters `i_flowmap`, `i_distmap`, `i_valid_flowmap`, and `i_uv2_sides` are assigned after the bake, with `valid_flowmap = true` at line 687.
- `addons/waterways/water_helper_methods.gd`: `generate_collisionmap()` starts at line 160, computes a river-surface sample point from UV2, then casts from `real_pos` upward to `real_pos + Vector3.UP * raycast_dist` and also back down at lines 216-219.
- `addons/waterways/shaders/river.shader`: invalid maps use fallback `flow = vec2(0.5, 0.572)` at line 126.
- `addons/waterways/shaders/river.shader`: valid maps decode RG with `(flow - 0.5) * 2.0` at line 132.
- `addons/waterways/shaders/river_debug.shader`: Flow Arrows rotate from `atan(flow.y, flow.x)` at line 128.

Original author/documentation intent also matches this. The original README says Waterways was an attempt to generate flowmaps inside Godot rather than relying on manually painted maps or external tools. The ArtStation project note states that the main interest was generating flowmaps based on obstacles the river encountered. GameFromScratch likewise summarized Waterways as using spline controls while giving control over foam generated by collisions with other scene objects.

### Godot 4 Port Comparison

The Godot 4 port preserves the original high-level design:

- The generated River flow map still begins with a collision map.
- The collision map still feeds normal/flow/foam/pressure filter passes.
- The shader still uses fallback flow when `i_valid_flowmap` is false.
- The shader still decodes RG flow with `(flow - 0.5) * 2.0`.
- Debug arrows still visualize the decoded flow vector.
- The collision probe still uses the vertical space between the river surface and `real_pos + Vector3.UP * raycast_dist`.

Notable port changes:

- The Godot 4 port invalidates generated bake data more consistently when curve points, handles, or restored curve state change. The original invalidated flow maps for shape-division and smoothness property changes, but point position/handle setters regenerated the mesh without obviously clearing `valid_flowmap`.
- The Godot 4 port added explicit diagnostics for empty collider pixels and low-contrast generated channels. The original could silently produce flat maps.
- The Godot 4 port added direct `CollisionShape3D` segment checks before physics raycast fallback, which helps Godot 4 editor bake reliability but does not change the basic upward collision-sampling design.
- The Godot 4 port fixed or altered some safety details, such as finite-value checks, bake preflight, external resource storage, padded-atlas handling, and renderer readback guards.

### Port Regression Assessment

The core issue is mostly inherited, not a new Godot 4 design mistake.

The original tool was intentionally collision/obstacle-driven: generate a collision mask, convert that mask to derived maps, then convert the derived normal map to a flow map. Therefore, a scene with no collider pixels or uniform collider pixels was always at risk of producing a neutral or unhelpful generated flow map.

The port did make this behavior more visible:

- Because geometry edits now invalidate the generated map more reliably, moving a point can expose fallback flow immediately.
- Regenerating then replaces fallback flow with the generated collision-derived map.
- If that generated map is flat, the visible difference is stark: movement during invalid fallback, then stationary flow after regeneration.
- New warnings make the flat-map cause visible in Output instead of silent.

Conclusion: the Godot 4 port likely did not introduce the collider-derived baseline-flow dependency. It did make stale-bake invalidation stricter and diagnostics clearer, which can make the inherited design limitation easier to notice.

## Expanded External Research

After checking additional comparable systems, the overall pattern is stronger than the first-pass note suggested: mature tools generally separate "how the water wants to move" from "what modifies or constrains that movement."

The common pattern is:

1. Establish a base flow field from intent: spline direction, guide curve, artist-painted vectors, slope/heightfield simulation, explicit direction, or authored velocity input.
2. Use obstacles, shore, terrain, or geometry as modifiers: bend flow around rocks, add foam, adjust edge behavior, pressure, turbulence, clipping, or depth.

### Unreal Engine WaterBodyRiver

Epic documents rivers as spline-first. A River Water Body is defined by an open spline, and rivers use velocity from spline points to drive motion. That velocity is written to a flow map that drives water along the spline direction.

Source:

- Epic Games, Water Body Actors in Unreal Engine: https://dev.epicgames.com/documentation/en-us/unreal-engine/water-body-actors-in-unreal-engine?application_version=5.6

Waterways implication:

- Baseline river flow can reasonably come from spline direction and per-point speed/velocity rather than from collider presence.

### Adobe Substance 3D Designer Spline Flow Mapper

Adobe's Spline Flow Mapper draws flow vector data along input splines. The node uses splines to control direction, trajectory, intensity, thickness, and attenuation into a neutral background. It also exposes tangent/normal direction modes and a flip-direction option.

Source:

- Adobe Substance 3D Designer, Spline Flow Mapper: https://experienceleague.adobe.com/en/docs/substance-3d-designer/using/substance-graphs/nodes-reference-for-substance-graphs/node-library/spline-path-tools/spline-tools/spline-flow-mapper

Waterways implication:

- A spline can directly author a useful flow vector field, with neutral areas at the edges or outside the influence envelope.

### SideFX Labs Flowmap Tools

SideFX Labs is the clearest example of separation between base initialization and modifiers:

- `Labs Flowmap` initializes a flowmap. Its documented initialization modes include empty/normal, slope-derived, and explicit direction-derived flow.
- `Labs Guide Flowmap` modifies a flowmap based on a guide curve.
- `Labs Flowmap Obstacle` modifies an existing flowmap based on obstacle geometry.

Sources:

- SideFX Labs Flowmap: https://www.sidefx.com/docs/houdini/nodes/sop/labs--flowmap-2.0.html
- SideFX Labs Guide Flowmap: https://www.sidefx.com/docs/houdini/nodes/sop/labs--flowmap_guide.html
- SideFX Labs Flowmap Obstacle: https://www.sidefx.com/docs/houdini/nodes/sop/labs--flowmap_obstacle-3.0.html

Waterways implication:

- Geometry-based obstruction is useful, but it can be layered on top of an existing flow field instead of being required to create the base flow field.

### Crest Ocean System

Crest treats flow as horizontal motion of water volumes that can affect physics. Its docs say splines support flow, and also support adding arbitrary flow velocities via rendered inputs. Flow-map texture input uses packed RG velocities, subtracts `0.5`, and scales the result.

Source:

- Crest Ocean System documentation, Flow: https://crest.readthedocs.io/en/4.15/user/ocean-simulation.html#flow

Waterways implication:

- Flow can be a composited field with multiple authored inputs. Spline flow and texture/geometry inputs can coexist without requiring collision geometry to define all baseline movement.

### Unity Splines

Unity's spline package is not a water-flow system, but it treats flow direction as intrinsic path metadata: a spline has a flow direction from first knot to last knot, and the editor exposes a "Reverse Spline Flow" operation.

Source:

- Unity Splines, Reverse the flow of a spline: https://docs.unity.cn/Packages/com.unity.splines%402.2/manual/reverse-spline-flow.html

Waterways implication:

- It is normal for spline tools to carry a directional concept independent of collision geometry. A River curve can therefore plausibly be the source of downstream direction.

### Catlike Coding Flow Texture Distortion

Catlike Coding's flow tutorial is a shader/animation reference rather than an authoring-system reference. It defines flow maps as textures containing 2D vectors, decodes signed vectors from RG, adds optional noise in alpha to desynchronize pulsing, and uses two-phase blending to hide resets.

Source:

- Catlike Coding, Texture Distortion: https://catlikecoding.com/unity/tutorials/flow/texture-distortion/

Waterways implication:

- This supports the current shader foundation and channel interpretation. It does not require a collider-derived generation path; the generation/source of vectors is separate from the shader animation technique.

### Valve Portal 2 / Left 4 Dead 2 Flow Maps

Valve's SIGGRAPH material describes flow visualization driven by a flow field/flow texture, then uses two-layer normal flow and noise to hide repetition and pulsing. The summary identifies an artist-authored flow map as the basis.

Source:

- Alex Vlachos, Valve, Water Flow in Portal 2: https://cdn.fastly.steamstatic.com/apps/valve/2010/siggraph2010_vlachos_waterflow.pdf

Waterways implication:

- The shader's two-phase flow basis can remain intact while the authoring side improves how the vector field is generated.

### Gaea FlowMap

Gaea's FlowMap node generates a flow map showing how water or material would travel across terrain. Its controls include flow length and flow volume, emphasizing terrain-derived flow paths and accumulation.

Source:

- QuadSpinner Gaea FlowMap: https://docs.gaea.app/reference/nodes/derive/flowmap.html

Waterways implication:

- Terrain/heightfield-derived flow is another valid base-flow source. It is different from a river spline, but still supports the broader principle that flow can be generated from motion intent or landscape shape rather than from binary collision presence alone.

### Instant Terra / Wysilab 2D Flowmap

Wysilab documents a 2D flowmap node that produces a vector map from water flow simulation. The vector direction corresponds to water-flow direction and vector norm corresponds to flow amount. It uses familiar packed-vector encoding, with neutral components at `0.5`.

Source:

- Wysilab 2D flowmap node: https://www.wysilab.com/OnLineDocumentation/Nodes/Simulation/Nodes_Simulation_2dFlowMap.html

Waterways implication:

- Simulation-derived flow maps are another known route. The relevant point for Waterways is that the flow map should encode a meaningful velocity field, and neutral `0.5` means zero component rather than "unknown but still downstream."

### Superposition Games Flowmap Generator

The Flowmap Generator river tutorial describes a simulation-based workflow: create or render a heightmap, add fluid fields, simulate, bake a flowmap texture, and then use a separate river mesh on top of terrain. The flowmap texture is used as data and should bypass sRGB sampling.

Source:

- Superposition Games, Flowmap Generator River Tutorial: https://superpositiongames.com/files/flowmap_generator/docs/RiverExample.pdf

Waterways implication:

- This is closer to external simulation than curve authoring. It reinforces that flow-vector generation is a distinct authoring step, and the final river mesh consumes the baked vector field rather than needing live collision helpers at render time.

### Research Summary

The external survey shows several valid ways to create base flow:

- Spline velocity or spline tangent direction: Unreal WaterBodyRiver, Adobe Spline Flow Mapper, Unity spline flow metadata, Crest spline flow.
- Explicit direction or slope initialization: SideFX Labs Flowmap.
- Artist-authored textures: Valve, Catlike Coding.
- Heightfield or terrain simulation: Gaea, Wysilab, Flowmap Generator.
- Geometry modifiers: SideFX Flowmap Obstacle, Crest rendered inputs, Waterways obstacle/collision bake.

The part that looks unusual in Waterways is not that it uses collision or geometry. That is a legitimate modifier/source. The fragile part is that the generated River map can lack any baseline downstream direction when collision input is empty or flat, even though the River curve itself already carries downstream intent.

## Preliminary Design Direction

Waterways' generated flow map should probably not depend on collider hits for its baseline downstream direction.

The river curve already contains the core downstream intent. Colliders and geometry should contribute banks, foam, pressure, obstacle deflection, and distance fields. If collider input is missing, empty, flat, or intentionally disabled, the river should still generate a usable curve-following flow map, with reduced edge/foam/pressure detail rather than zero flow.

Put differently:

- Curve/spline: base flow direction and optional base speed.
- Collider or terrain helpers: bank distance, pressure, foam, obstacle influence, and local deflection.
- Imported or painted maps: optional override or blend layer for advanced art direction.

## Candidate Feature Goals

- Generate non-neutral baseline RG flow from the River curve even when collision data is absent.
- Keep existing two-phase `FlowUVW` shader math unchanged unless separate validation proves a shader defect.
- Preserve the existing `flow_foam_noise` channel contract: RG flow, B foam, A phase/noise.
- Keep `dist_pressure` as distance/pressure support data.
- Treat colliders as modifiers or optional bake helpers, not the sole source of downstream flow.
- Make debug views explain whether visible behavior comes from fallback flow, curve-derived generated flow, collision modifiers, or imported data.
- Improve docs so users understand bake helper colliders should be isolated from snapping/gameplay colliders when needed.

## Candidate Non-Goals

- Do not replace two-phase flow animation.
- Do not add a fluid simulation.
- Do not rewrite shader sampling or jump constants as part of this feature.
- Do not break imported or hand-painted flow map workflows.
- Do not make visible gameplay collision mandatory for water animation.

## Open Questions

- Should curve-derived flow be the default generated RG layer, with collision-derived flow blended in as a modifier?
- Should users be able to choose generation modes: `Curve Only`, `Curve + Collision Modifiers`, `Collision Legacy`, and `Imported`?
- How should curve direction be encoded across the current UV2 tile atlas, especially across tile seams?
- Should speed come from per-point metadata, curve slope, material settings, or a new authoring control?
- How should near-zero flow be handled in Flow Arrows so neutral areas do not show misleading directions?
- Can bank/foam/pressure generation still use the existing collision pipeline while replacing only the baseline RG flow layer?
- How should snap colliders, bake helper colliders, and gameplay collision layers be documented or separated?

## Validation Needed Before Implementation

- Reproduce the current flat-bake behavior in a controlled scene:
  - no collider pixels
  - collider everywhere
  - bank-only helper colliders
  - ordinary terrain below the river
- Confirm current fallback flow animates when `i_valid_flowmap` is false.
- Add data validation that reports RG vector length statistics, not just neutral sample and alpha range.
- Add visual validation for:
  - straight river section
  - curved river section
  - neutral or low-flow area
  - no-collider bake
  - bank-helper collider bake
- Compare Flow Pattern and Flow Arrows before and after regeneration.
- Verify that generated curve-derived flow stays coherent across UV2 tile seams.
- Record whether collision modifiers improve foam/distance/pressure without destroying the baseline downstream direction.

## Preliminary Conclusion

The current Waterways behavior is understandable from the source: generated RG flow currently comes from a collision-derived bake path, and an empty collision bake can produce neutral flow. The shader can still animate with fallback flow when the generated map is invalid, which explains why moving a point can temporarily make the river appear to flow again.

The design gap is on the authoring/bake side. Other flow-map systems commonly establish flow from spline, guide, or artist intent first, then use geometry as a modifier. Waterways would likely become more forgiving and more predictable if `Generate Flow & Foam Map` always produced a curve-following baseline flow, while treating colliders as optional helpers for bank, foam, pressure, and obstacle effects.

## Online Validation Addendum

Additional online research on 2026-05-22 supports the preliminary conclusion. These are not formal standards bodies, but they represent a consistent industry practice across major engines, procedural DCC tools, shader references, and terrain/simulation tools.

### Validated Industry Patterns

1. River direction is commonly authored by a spline or path.

   Unreal Engine's River Water Body is defined by an open spline. Its per-point velocity drives motion, and that velocity is written to a flow map that moves water along the spline direction.

   Adobe Substance 3D Designer's Spline Flow Mapper draws vector data along input splines, with tangent/normal direction modes, intensity/thickness controls, attenuation to neutral, and direction flipping.

   Unity's Splines package treats direction as intrinsic spline metadata: a spline flows from first knot to last knot and can be reversed.

   Sources:

   - Epic Games, Water Body Actors in Unreal Engine: https://dev.epicgames.com/documentation/unreal-engine/water-body-actors-in-unreal-engine?application_version=5.6
   - Adobe Substance 3D Designer, Spline Flow Mapper: https://experienceleague.adobe.com/en/docs/substance-3d-designer/using/substance-graphs/nodes-reference-for-substance-graphs/node-library/spline-path-tools/spline-tools/spline-flow-mapper
   - Unity Splines, Reverse the flow of a spline: https://docs.unity.cn/Packages/com.unity.splines%402.2/manual/reverse-spline-flow.html

2. Mature flow-map tools separate initialization from modifiers.

   SideFX Labs Flowmap initializes the field with modes such as empty, slope-derived, or explicit direction-derived. SideFX Labs Guide Flowmap then modifies an existing flowmap from a guide curve. SideFX Labs Flowmap Obstacle also modifies an existing flowmap from obstacle geometry.

   This is the clearest match for the Waterways design issue: geometry-based obstruction is useful, but it is layered onto a field that already exists.

   Sources:

   - SideFX Labs Flowmap: https://www.sidefx.com/docs/houdini/nodes/sop/labs--flowmap-2.0.html
   - SideFX Labs Guide Flowmap: https://www.sidefx.com/docs/houdini/nodes/sop/labs--flowmap_guide.html
   - SideFX Labs Flowmap Obstacle: https://www.sidefx.com/docs/houdini/nodes/sop/labs--flowmap_obstacle-3.0.html

3. Flow maps are data textures that encode a local velocity field.

   Catlike Coding describes a flow map as a texture containing 2D vectors, with U in R and V in G, and notes that it should be imported as non-sRGB because it is data, not color.

   Crest similarly reads packed RG flow velocity, subtracts `0.5`, and scales the result. Wysilab documents the same neutral-center convention: `0.5` is zero for a vector component. Superposition Games' Flowmap Generator also treats the baked flowmap as linear data and recommends bypassing sRGB sampling.

   Sources:

   - Catlike Coding, Texture Distortion: https://catlikecoding.com/unity/tutorials/flow/texture-distortion/
   - Crest Ocean System, Flow: https://crest.readthedocs.io/en/4.15/user/ocean-simulation.html#flow
   - Wysilab 2D Flowmap Node: https://www.wysilab.com/OnLineDocumentation/Nodes/Simulation/Nodes_Simulation_2dFlowMap.html
   - Superposition Games, Flowmap Generator River Tutorial: https://superpositiongames.com/files/flowmap_generator/docs/RiverExample.pdf

4. The shader animation model does not dictate how vectors must be authored.

   Valve's Portal 2 / Left 4 Dead 2 flow-map presentation describes artists authoring a 2D vector texture, then using that data in a pixel shader to distort water normals. Catlike Coding follows the same general shader-side idea. This validates the existing Waterways shader-side concept while leaving the authoring source open.

   Sources:

   - Alex Vlachos, Valve, Water Flow in Portal 2: https://cdn.akamai.steamstatic.com/apps/valve/2010/siggraph2010_vlachos_waterflow.pdf
   - Catlike Coding, Texture Distortion: https://catlikecoding.com/unity/tutorials/flow/texture-distortion/

5. Terrain and simulation tools also generate base flow from motion logic, not obstacle presence alone.

   Gaea's FlowMap node generates travel paths across terrain. Wysilab's 2D flowmap node outputs a vector field where direction and vector length correspond to simulated water movement. Superposition Games' tutorial creates a heightmap/simulation workflow, bakes the result, and applies it to a separate river mesh.

   Sources:

   - QuadSpinner Gaea FlowMap: https://docs.gaea.app/reference/nodes/derive/flowmap.html
   - Wysilab 2D Flowmap Node: https://www.wysilab.com/OnLineDocumentation/Nodes/Simulation/Nodes_Simulation_2dFlowMap.html
   - Superposition Games, Flowmap Generator River Tutorial: https://superpositiongames.com/files/flowmap_generator/docs/RiverExample.pdf

### Validation Verdict

The preliminary finding is validated.

The unusual behavior in Waterways is not that colliders influence generated flow; that is reasonable and consistent with procedural tools. The unusual behavior is that collider input can become the only meaningful source of generated downstream motion, even when the River curve already carries an ordered downstream path.

The stronger industry-aligned model is:

- Base intent source: spline direction, guide curve, explicit direction, terrain slope, simulation, or imported/painted vectors.
- Modifier sources: obstacles, banks, terrain interaction, edge masks, foam, pressure, turbulence, and local deflection.
- Shader consumption: packed RG vector data decoded as signed velocity, with separate foam/noise/depth support channels as needed.

## Proposal

`River -> Generate Flow & Foam Map` should move to a curve-derived baseline flow model, with collision data retained as an optional modifier layer.

### Recommended Default

Make `Curve + Collision Modifiers` the default generated mode.

In this mode, the bake should always produce a non-neutral RG flow vector inside the river body from the River curve's downstream tangent. Collision-derived data should then modify that field where useful, rather than being required to create movement at all.

If no collider pixels are found, generation should still succeed with a curve-following flow map. The warning should explain that foam, pressure, bank, or obstacle detail may be reduced, not that the flow map has become effectively neutral.

### Generation Modes

Add or internally model these generation paths:

- `Curve + Collision Modifiers`: default. Curve tangent creates base RG flow; collider bake contributes foam, pressure, banks, distance, and local deflection.
- `Curve Only`: generates downstream RG flow and basic edge attenuation without requiring bake helper colliders.
- `Collision Legacy`: preserves the current collision-derived behavior for compatibility and comparison.
- `Imported/Manual`: preserves existing imported or hand-painted flow map workflows.

The UI does not need to expose all modes immediately if that would add too much surface area. At minimum, the implementation should keep the legacy path available behind an internal setting or compatibility switch until the new behavior is proven.

### Baseline RG Flow

For each generated flow texel inside the river:

1. Resolve the texel to the corresponding river-local or world-space sample, using the same UV2/tile-atlas assumptions the current bake relies on.
2. Find the nearest curve progress or segment for that sample.
3. Derive the downstream tangent from the curve at that progress.
4. Project the tangent to the water plane and normalize it.
5. Apply a base speed scalar.
6. Encode the signed vector into RG with the existing packed convention: `encoded = signed_vector * 0.5 + 0.5`.

Recommended first-pass speed behavior:

- Use a single generated base-flow strength that is visually comparable to current generated maps, while keeping most speed control in the existing material `flow_speed`, `flow_base`, `flow_distance`, `flow_pressure`, and `flow_max` controls.
- Leave per-point speed, slope-derived speed, and artist-painted speed for a later iteration.
- Clamp output so RG stays inside `0..1` and vector length statistics are easy to report.

### Collision Modifiers

Keep the existing collision pipeline where it is valuable:

- Continue using collider-derived data for foam.
- Continue generating `dist_pressure` support data.
- Continue using bank/obstacle influence to bend or dampen the baseline flow.
- Treat collision-derived RG as a modifier blended onto curve-derived RG, not as the sole field.

Recommended first-pass blending:

- Preserve the curve vector as the fallback wherever collision influence is absent or low confidence.
- Apply obstacle deflection only where the collision/pressure signal is strong enough to be meaningful.
- Avoid blending toward neutral merely because collision data is flat.

### Debug And Diagnostics

Update diagnostics to report vector usefulness, not only channel contrast:

- RG vector length min/max/average.
- Percentage of texels near neutral.
- Percentage of texels using curve baseline vs collision-modified flow.
- Whether no-collider generation fell back to `Curve Only` behavior.

Update Flow Arrows so near-zero vectors are not shown as confident directions:

- Hide arrows below a small vector-length threshold, or draw them as neutral dots.
- Report "near-zero flow" in debug text instead of rotating arrows from an unstable angle.

### Documentation

Document the authoring roles separately:

- River curve: downstream direction and baseline motion.
- Bake helper colliders: banks, foam, pressure, distance, and obstacle influence.
- Snap colliders: editing convenience for point placement.
- Gameplay colliders: runtime physics and player interaction.

Recommend separate collision layers for bake helpers, snapping, and gameplay when projects need predictable authoring.

### Acceptance Criteria

The feature should be considered successful when:

- A no-collider river bake produces visibly moving downstream flow.
- A straight river produces consistent arrows along the river direction.
- A curved river produces smoothly turning arrows without seam flips.
- A flat or uniform collider bake does not erase downstream flow.
- Bank-helper colliders add foam/pressure/edge detail without destroying baseline direction.
- The legacy collision-derived result can still be reproduced for comparison.
- Imported or hand-painted flow maps keep their existing channel contract.
- The shader's two-phase flow animation remains unchanged unless a separate shader bug is found.

### Implementation Order

1. Add a curve-derived RG generation pass and write validation stats for its output.
2. Route no-collider and flat-collider bakes to curve-derived RG instead of neutral RG.
3. Blend existing collision-derived influence onto the curve-derived RG field.
4. Improve Flow Arrows for near-zero vectors.
5. Add editor/docs language that separates curve flow, bake helpers, snap colliders, and gameplay colliders.
6. Run visual validation on straight, curved, no-collider, flat-collider, and bank-helper scenes.

This keeps the existing shader and channel contract intact while fixing the fragile authoring behavior: the River curve supplies the downstream motion, and colliders return to being optional helpers that enrich the generated map rather than deciding whether the river flows at all.

## Open Questions Research Findings

Research date: 2026-05-22.

Scope: current Waterways Godot 4 codebase review plus external references from Unreal Engine, Adobe Substance 3D Designer, SideFX Labs, Crest, Catlike Coding, Valve, Godot docs, Gaea, Wysilab, and Superposition Games.

### 1. Should curve-derived flow be the default generated RG layer, with collision-derived flow blended in as a modifier?

Thought:

Yes. Curve-derived RG should be the default generated baseline. Collision-derived data should be treated as a confidence-weighted modifier, not as the required source of downstream movement.

Supporting evidence:

- Unreal River Water Bodies are open splines; per-point velocity is written to a flow map that drives water along the spline direction.
- Adobe's Spline Flow Mapper draws vector flow data along splines using tangent or normal direction modes, with attenuation toward neutral.
- SideFX Labs separates initialization from modification: `Labs Flowmap` initializes flow attributes, while `Labs Guide Flowmap` and `Labs Flowmap Obstacle` modify an existing flowmap.
- Crest supports spline-authored flow and also supports packed RG flow-map texture inputs.
- Current Waterways does the opposite: `_generate_flowmap()` creates a collision map, derives normals from it, converts those normals to RG flow, and only then combines RG/B/A output. If the collision map is empty or flat, RG can become neutral.
- The current shader only consumes packed RG data. It does not care whether those vectors came from colliders, a curve, an imported texture, or a simulation.

Summary:

Default to curve-derived baseline RG. Blend collision influence on top where collision data is meaningful. If collision influence is absent, keep the curve vector instead of blending toward neutral.

### 2. Should users be able to choose generation modes: `Curve Only`, `Curve + Collision Modifiers`, `Collision Legacy`, and `Imported`?

Thought:

Yes in the data model, but not necessarily all at once in the UI. The first implementation should support the modes internally and expose only the controls needed for a clear authoring workflow.

Supporting evidence:

- SideFX exposes initialization choices such as empty, slope, and explicit direction in `Labs Flowmap`.
- Adobe exposes spline selection, direction mode, direction flipping, thickness, and attenuation controls for spline-derived flow data.
- Unreal exposes river-specific spline properties such as width, depth, and velocity, but keeps the conceptual workflow spline-first.
- Waterways already has `RiverBakeData.source_kind`, channel metadata, import profile metadata, and source metadata. The current source kind is `generated_spline_collision_bake`, and the code already records future source-kind labels including imported, hand-painted, DCC/simulation, shore distance, terrain slope, and obstacle influence fields.
- The current River toolbar has one bake action, `Generate Flow & Foam Map`, so exposing four modes immediately could make the UI feel heavier than the feature requires.

Summary:

Implement generation modes as explicit data/source kinds first. Expose `Curve + Collision Modifiers` as the normal bake behavior, keep `Collision Legacy` for compatibility/testing, allow `Curve Only` when users disable or lack bake helper colliders, and preserve imported/manual maps through the existing channel contract.

### 3. How should curve direction be encoded across the current UV2 tile atlas, especially across tile seams?

Thought:

Do not change the atlas layout for this feature. Generate curve-derived flow into the same unpadded UV2 source image, then use the existing padded-atlas margin system so shader sampling and filter passes keep working.

Supporting evidence:

- Current Waterways generates the river mesh with UV2 tiles. `generate_river_mesh()` assigns each river length step into a tile, with subdivisions across width and length.
- `generate_collisionmap()` already walks every source-image texel, maps the texel into UV2, finds the containing triangle, converts through barycentric coordinates, and recovers the world-space river-surface sample.
- `add_margins()` pads the source atlas by one tile on every side. It also has special handling for the UV2 atlas order, which advances down a column before continuing at the next column.
- The river, lava, debug, and system-flow shaders all remap UV2 into the center of this padded atlas before sampling.
- Superposition Games' tutorial similarly treats the final river mesh as a consumer of a baked flow texture and emphasizes that UV mapping must place the baked flow data correctly.
- Catlike Coding notes that flow maps are vector textures that can rely on filtering for smooth fields, so coherent neighboring data and padding matter.

Summary:

Keep `padded_uv2_atlas_with_one_tile_margin`. For each source texel inside an occupied tile, derive downstream direction from tile/step progress or from the world-space sample's curve progress. Write packed RG into the source image, then pad it with the existing atlas continuation rules. Validate straight sections, bends, column-continuation seams, river start/end clamping, and empty atlas cells.

### 4. Should speed come from per-point metadata, curve slope, material settings, or a new authoring control?

Thought:

For the first pass, keep speed mostly in material settings and make generated RG primarily answer "which way does this texel flow?" Add one conservative bake-time vector-strength control only if visual tuning requires it. Per-point speed and slope-derived speed should be later features.

Supporting evidence:

- Unreal supports per-spline-point river velocity, including positive and negative values for direction along the spline.
- SideFX supports slope-derived and explicit-direction initialization modes, which shows slope is a valid source, but it is a separate mode rather than something every flowmap must use.
- Gaea and Wysilab generate terrain/simulation-derived flow fields where vector magnitude can represent flow amount or accumulation.
- Superposition Games exposes material `Flow Speed`, including negative values to reverse direction, after the flowmap has been baked.
- Current Waterways has no per-point speed metadata. Its curve source signature stores point position, in/out tangents, and width, but not velocity.
- Current Waterways shader behavior already separates texture vectors from material force controls: RG is decoded, then multiplied by a `flow_force` derived from `flow_base`, steepness, distance, pressure, and `flow_max`, while `flow_speed` controls animation time.

Summary:

First implementation: curve-derived RG should encode direction with a stable, modest magnitude; existing material controls remain the user's speed controls. Later implementation: add optional per-point velocity, optional reverse-direction support, and maybe terrain/slope-derived speed as a separate mode after the baseline bake is proven.

### 5. How should near-zero flow be handled in Flow Arrows so neutral areas do not show misleading directions?

Thought:

Flow Arrows should treat near-zero vectors as neutral, not directional. They should hide arrows, fade arrows out, or draw a neutral marker below a threshold.

Supporting evidence:

- Wysilab documents packed vectors with `0.5` as the zero component. A neutral `(0.5, 0.5)` vector therefore has no meaningful angle.
- Catlike Coding decodes packed RG with `* 2 - 1`, which matches Waterways' convention that neutral data decodes to zero.
- Current `river_debug.gdshader` decodes RG and then computes arrow rotation with `atan(flow.y, flow.x)`. When `flow` is near zero, that angle is numerically valid but semantically meaningless.
- Current bake warnings already identify flat RG channels, but the visual debug still renders confident-looking arrows from a near-zero vector.

Summary:

Add a debug-only threshold, preferably based on decoded vector length before or after force modifiers. Below the threshold, draw no arrow, a small dot, or a neutral color. Also add vector-length stats to `Validate Data Textures` so the user can tell the difference between "slow/neutral water" and "bad direction data."

### 6. Can bank/foam/pressure generation still use the existing collision pipeline while replacing only the baseline RG flow layer?

Thought:

Yes. The current bake path is already separable enough to keep collision-derived foam, distance, and pressure while replacing only the RG source passed into `flow_foam_noise`.

Supporting evidence:

- `_generate_flowmap()` derives multiple intermediate products from the collision image: `flow_pressure_map`, `dilated_texture`, `normal_map`, collision-derived `flow_map`, `foam_map`, and blurred variants.
- `flow_foam_noise` is packed by `apply_combine(blurred_flow_map, blurred_flow_map, blurred_foam_map, tiled_noise)`. That means RG is provided by one texture, B by foam, and A by noise.
- `dist_pressure` is packed separately with `apply_combine(dilated_texture, blurred_flow_pressure_map)`.
- The `foam_pass` samples the dilated collision texture downstream in UV space and does not require the collision-derived RG flow texture.
- The `flow_pressure_pass` and `normal_map_pass` can continue producing useful support data from colliders even if RG baseline flow comes from the curve.
- SideFX `Flowmap Obstacle` provides an external precedent for obstacle geometry modifying an existing flowmap rather than replacing the source flow field.

Summary:

Replace `blurred_flow_map` with a curve-derived RG texture in the combine step, then optionally blend a collision-derived deflection texture into it. Keep `dilated_texture`, `flow_pressure_map`, `foam_map`, `dist_pressure`, and tiled alpha noise intact. This is a smaller change than rewriting the shader or the whole bake pipeline.

### 7. How should snap colliders, bake helper colliders, and gameplay collision layers be documented or separated?

Thought:

Document them as three separate authoring roles and, longer-term, give snapping its own configurable layer mask. The current code already separates bake layers from snap behavior, but snap is too broad by default.

Supporting evidence:

- River baking has an inspector-exposed `baking_raycast_layers` property using `PROPERTY_HINT_LAYERS_3D_PHYSICS`.
- `generate_collisionmap()` collects direct `CollisionShape3D` nodes matching the bake layer mask, then falls back to physics raycasts using the same mask.
- River snapping uses `COLLIDER_SNAP_MASK = 0xFFFFFFFF`, so it can hit every layer unless a node or ancestor has `waterways_snap_ignore` metadata.
- Godot's physics docs describe layers as where an object appears and masks as what a query or object scans for. Godot also supports naming layers in Project Settings, which is exactly the right mechanism for separating authoring roles.
- Godot's ray-casting docs specifically recommend collision masks when exclusion lists become inconvenient for large or dynamic sets.

Summary:

Docs should recommend named layers such as `Waterways Bake Helpers`, `Waterways Snap Targets`, and project gameplay layers. `baking_raycast_layers` should point only at bake helpers. Snap should either use a future `snap_collision_layers` setting or documented `waterways_snap_ignore` metadata for objects that should not receive river points. Gameplay colliders should not be required for generated water motion.

## Open Questions Resolved Summary

- Default generation should be `Curve + Collision Modifiers`.
- Generation modes should exist in the data model; UI exposure can be gradual.
- The current padded UV2 atlas should be retained.
- Initial speed behavior should rely on existing material controls, not new per-point velocity.
- Flow Arrows need a near-zero vector threshold.
- Existing collision-derived foam, pressure, distance, and obstacle influence can remain.
- Bake helpers, snap targets, and gameplay colliders should be separated by named physics layers and documented roles.
