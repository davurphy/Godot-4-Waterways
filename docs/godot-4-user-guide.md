# Waterways Godot 4 User Guide

This guide covers the current Godot 4.6+ Waterways port. It is written for users who want to install the add-on, author a River, bake maps, connect a WaterSystem, and use the simple Buoyant helper.

## Installation

1. Copy `addons/waterways` into the target Godot 4.6+ project.
2. Open the project in Godot.
3. Go to `Project -> Project Settings -> Plugins`.
4. Enable `Waterways`.

After enabling the plugin, the editor registers these custom node types:

- `River`
- `WaterSystem`
- `Buoyant`

The add-on also adds River and WaterSystem toolbar controls when one of those nodes is selected.

## Quickstart

1. Create a `Node3D` scene.
2. Add a `WaterSystem` node.
3. Add one or more `River` nodes as direct children of the `WaterSystem`.
4. Select a `River`, edit its curve in the 3D viewport, and run `River -> Generate Flow & Foam Map`.
5. Select the `WaterSystem` and run `WaterSystem -> Generate System Maps`.
6. Save the scene after successful generation so F6 runs, exports, and reopened scenes use the fresh external bake resources.

For a known-good starting point, open `scenes/validation/system_map_validation.tscn`. It contains two Rivers under one WaterSystem, bake collision helpers, a transformed parent setup, and a compatible wet material target.

## River Editing

Select a `River` node to show the River toolbar and 3D gizmo handles.

Toolbar tools:

- `Select`: move existing river points and handles.
- `Add`: add a river point in the 3D viewport.
- `Remove`: delete a river point.
- `Constraints`: choose unconstrained movement, collider snapping, axis constraints, or plane constraints.
- `Local Mode`: apply movement constraints in local curve space.
- `River`: opens River actions, including map generation, mesh sibling generation, validation actions, and debug views.

Useful editor checks:

- Point add/remove supports undo and redo.
- Width handles update the generated mesh while dragging.
- `Snap to Colliders` works with compatible `CollisionShape3D` scene geometry.
- `River -> Debug View` can show Flow Map, Foam Map, Distance Field, Pressure Map, Flow Pattern, Flow Arrows, Flow Strength, and Foam Mix.

## River Baking

Run `River -> Generate Flow & Foam Map` after editing the curve or bake settings.

After a successful bake in a saved scene, Waterways writes the generated `RiverBakeData` to `res://waterways_bakes/<scene-derived-folder>/<RiverName>.river_bake.res`. The scene keeps a reference to that external resource, so reopening the scene auto-applies the saved bake in the 3D viewport without a manual load action.

If the scene has not been saved yet, the bake stays in editor memory. Save the scene, then run `River -> Generate Flow & Foam Map` again to create the scene-owned external `.res`.

The River bake writes:

- `flow_foam_noise`: packed river flow, foam, and optional phase noise.
- `dist_pressure`: distance and pressure data.
- `bake_data`: a `RiverBakeData` resource with texture references, texture size, source texture size, content rect, padded atlas layout, UV2 side count, mesh bounds, channel metadata, import profile, source metadata, and bake settings.

Channel contract:

- `flow_foam_noise.r`: signed flow X packed to `0..1`, neutral `0.5`.
- `flow_foam_noise.g`: signed flow Y/Z packed to `0..1`, neutral `0.5`.
- `flow_foam_noise.b`: foam influence.
- `flow_foam_noise.a`: optional phase/noise time offset for the two-phase flow animation.
- `dist_pressure.r`: bank distance or edge influence.
- `dist_pressure.g`: flow pressure or occupancy.
- `dist_pressure.b/a`: reserved.

Generated River textures currently use a padded UV2 atlas with one tile of margin. The padding ring is initialized on every side and corner before filtering so atlas-edge samples do not read untouched black pixels, and generated data atlases are kept without mipmaps. `RiverBakeData.texture_size` is the shader-facing padded size. `source_texture_size` and `content_rect` identify the central unpadded bake area for diagnostics and future export workflows.

The default generated River bake now writes gentle local downstream flow into occupied UV2 atlas tiles and uses collision data for foam, pressure, distance, and edge support. This prevents flat collision interiors from becoming valid-looking but directionless flow. If `baking_raycast_layers` is `0`, or if no collider pixels are found, the default bake still succeeds with curve downstream flow and exact blank support maps: foam `B = 0.0` and `dist_pressure.rg = (0.0, 0.0)`. Unused atlas tiles are reset to neutral `R/G` after combine so they do not leak arbitrary direction into later debug or WaterSystem composition. If collision-derived foam or pressure support is saturated across occupied tiles, the default bake softens those support channels to avoid full-width foam bands and over-strong Flow Pattern distortion.

`River -> Validate Data Textures` reports decoded flow-vector magnitude stats for the source rect, occupied tiles, and unused tiles. Near-neutral vectors have valid numeric angles but no meaningful direction, so use the magnitude and `active_mag_gt_0.020` counts before trusting Flow Arrows. The script property `bake_generation_behavior = "curve_only"` skips collision probing and always uses the blank support fallback. The script property `bake_generation_behavior = "legacy_collision_only"` keeps the older collision-gradient-only comparison path available for validation and compatibility checks; legacy still requires a nonzero raycast layer mask.

Rebaking overwrites the current external `bake_data.resource_path` when one exists. This preserves user-assigned resource paths and avoids silently switching files after ordinary node renames or scene moves. If multiple Rivers in the same scene have the same name, Waterways appends a deterministic suffix derived from each scene-relative node path.

If baking reports missing collider pixels or flat channels, check the River bake collision layer, the scene's collision helpers, and whether the generated mesh crosses the intended bake geometry.

## Two-Phase River Flow

The built-in river, river debug, and lava shaders use the same `FlowUVW` two-phase flow basis. `flow_foam_noise.rg` is decoded from packed `0..1` data into signed flow, `flow_foam_noise.a` is added to shader time as a phase/noise offset, and two half-period phases are blended so one phase fades out before its UV reset becomes obvious.

When flow looks wrong, start with `River -> Validate Data Textures` before changing material settings or shader code. The `RIVER_DATA_TEXTURE_TEST` Output line reports texture readability, source/import notes, closest sampled neutral RG, and alpha min/max/range/state for `flow_foam_noise.a`. Flat alpha can be valid, but it is important evidence when diagnosing synchronized pulsing.

Use `River -> Debug View` as a data and motion triage tool:

- `Display Debug Noise Map (A)`: shows the alpha phase/noise channel.
- `Display Debug Flow Pattern`: shows the animated two-phase distortion directly.
- `Display Debug Flow Arrows`: shows decoded direction, but near-neutral raw vectors are suppressed so packed neutral values like `[127,128]` do not appear as confident diagonal arrows.
- `Display Debug Flow Strength`: shows the effective strength response; this debug view intentionally amplifies the steepness diagnostic compared with the default river and lava shaders, so treat it as qualitative evidence.
- `Display Debug Foam Mix`: shows the downstream normal/foam sampling path used to judge whether foam remains coherent with the flow.

If Flow Pattern and Flow Arrows agree but the result still looks poor, check authored flow gradients, flat alpha, stale generated maps, texture import settings, `flow_speed`, force settings, normal texture repetition, and UV scale before treating `FlowUVW` as the first suspect.

## WaterSystem Setup

A `WaterSystem` combines direct child Rivers into one system map and provides runtime sampling.

Common properties:

- `system_map`: generated or assigned WaterSystem map texture.
- `bake_data`: `WaterSystemBakeData` with map texture, size, bounds, world-to-map transform, source River paths, channel metadata, import profile, source metadata, and bake settings.
- `system_bake_resolution`: controls WaterSystem map resolution.
- `system_group_name`: runtime group used by `Buoyant`; default `waterways_system`.
- `minimum_water_level`: fallback water-height offset when no valid generated map sample is available.
- `wet_group_name`: group of scene nodes that should receive system-map material uniforms.
- `surface_index`: mesh surface index used for wet material assignment.
- `material_override`: use `material_override` instead of a mesh surface material.

Run `WaterSystem -> Generate System Maps` after all child Rivers have valid generated River maps.

After a successful WaterSystem bake in a saved scene, Waterways writes the generated `WaterSystemBakeData` to `res://waterways_bakes/<scene-derived-folder>/<WaterSystemName>.water_system_bake.res`. Reopening the scene auto-applies that resource for editor preview, shader assignment, runtime sampling, and Buoyant helpers.

If the scene has not been saved yet, the generated system map stays in editor memory. Save the scene, then run `WaterSystem -> Generate System Maps` again to create the external `.res`.

The WaterSystem map uses:

- `r`: world/projected flow X packed to `0..1`, neutral `0.5`.
- `g`: world/projected flow Z packed to `0..1`, neutral `0.5`.
- `b`: normalized water height within WaterSystem bounds.
- `a`: coverage mask, where `0.0` means outside generated water.

Runtime sampling uses the alpha coverage channel. It no longer relies on black RGB pixels to detect empty water.

Rebaking overwrites the currently assigned external `bake_data.resource_path` when one exists. A user can still assign a custom external `WaterSystemBakeData` resource in the inspector; the normal bake action updates that resource rather than forcing the default folder.

## Wet Materials

When `WaterSystem -> Generate System Maps` runs, compatible wet targets in `wet_group_name` receive:

- `water_systemmap`
- `water_systemmap_coords`

Compatible targets are `MeshInstance3D` nodes with a `ShaderMaterial` in `material_override` or the configured `surface_index`.

Incompatible targets are skipped with warnings instead of stopping the pass. This includes non-mesh nodes, missing material slots, and non-`ShaderMaterial` materials.

## Buoyant Setup

Add `Buoyant` as a direct child of a `RigidBody3D`.

Set `Buoyant.water_system_group_name` to match the target `WaterSystem.system_group_name`. The default for both is `waterways_system`.

When underwater, the helper applies:

- upward force from sampled water altitude
- upright torque
- flow/current force from `WaterSystem.get_water_flow()`
- temporary linear and angular damping

Submerged sleeping bodies are woken before forces are applied.

When the body is above water or no compatible WaterSystem is found, the helper restores the damping values captured at water entry only while `Buoyant` is still the last writer. If user code or another system changes damping later, those values are left alone.

This is a simple gameplay helper. It samples one point at the Buoyant node position and does not model hull volume, multiple float points, wave displacement, drag surfaces, or center of pressure.

## Shader Customization

The built-in River materials are:

- `res://addons/waterways/shaders/river.gdshader`
- `res://addons/waterways/shaders/lava.gdshader`
- `res://addons/waterways/shaders/river_debug.gdshader`

System-map and filter passes live under:

- `res://addons/waterways/shaders/system_renders/`
- `res://addons/waterways/shaders/filters/`

Custom River shaders should preserve the active Waterways uniforms used by the editor and bake/runtime paths, including:

- `i_flowmap`
- `i_distmap`
- `i_uv2_sides`
- `i_valid_flowmap`

The built-in water and lava shaders pack editable gradient colors into mat4 uniforms for the custom Inspector. Those matrix values are display-space colors, so the built-in shaders convert them to linear RGB before using them for `ALBEDO` or `EMISSION`. Custom shaders can either keep that conversion for mat4 gradients or use ordinary `vec4 : source_color` uniforms for color parameters.

Custom wet shaders should accept:

- `water_systemmap`
- `water_systemmap_coords`

Data textures should be treated as linear numeric data. Avoid normal-map import, lossy compression, VRAM/block compression, and unvalidated mipmaps for flow, distance, pressure, and system maps. See [Godot 4 Import Notes](godot-4-imports.md).

## Checking Runtime Bake State

When comparing the 3D editor viewport to a running scene, regenerate the River and WaterSystem maps, save the scene, clear the Output panel, then run with F6. If a validation scene includes runtime diagnostics, trust the block labeled `RUNTIME_SCENE_STATE`; it is printed by the actual running scene and shows the saved texture resources, shader parameters, map sizes, and sampled CPU flow/altitude values the scene is using.

The `EDITOR_VIEWPORT_STATE` and `EDITOR_VIEWPORT_STATE_CHANGED` blocks are useful for editor-side checks, but they can include freshly generated in-memory resources that F6 will not see until the scene is saved.

## Bake Responsiveness

Inspector edits are designed to stay responsive. River shape and bake-setting changes regenerate the preview mesh or mark generated data stale, but they do not run the River or WaterSystem bake pipeline. Full bakes run only from the toolbar actions.

River baking is the expensive path. It scans the River UV2 atlas on the CPU, performs collision checks or raycasts, runs several SubViewport filter passes, and reads generated images back from the renderer. WaterSystem baking renders flow, height, and alpha maps for child Rivers, combines them, then refreshes the runtime sampling image.

For `0.2.2`, treat these as the practical authoring budgets:

- Regular authoring: River `baking_resolution` 0 to 2, producing 64 to 256 source textures before UV2 padding; WaterSystem `system_bake_resolution` 0 to 2, producing 128 to 512 maps.
- Stress or final-check authoring: River `baking_resolution` 3 to 4 and WaterSystem `system_bake_resolution` 3 to 4. These can visibly stall the editor because they multiply CPU pixel loops, physics queries, GPU filter passes, and readbacks.
- Release validation: record at least one default-scene bake note and one larger stress-scene note before promising performance for a shipped demo or project template.

There is no user-facing cancel button yet. The River progress window belongs to the selected River and closes on success or on guarded bake failure. If a River or WaterSystem render pass returns no readable image, Waterways aborts the bake, warns in Output, and removes temporary renderer nodes instead of leaving orphan SubViewport helpers in the edited scene tree.

## Validation Scenes

The scenes below are source-repo QA fixtures. They are not included in the minimal add-on package unless a separate source/validation archive intentionally includes them.

Use these scenes when checking the port:

- `scenes/validation/curve_derived_river_flow_validation.tscn`: canonical curve-derived River fixture with straight no-collider, curved no-collider, flat collider, bank-helper, legacy collision, and UV2 seam-crossing Rivers.
- `scenes/validation/flow_map_direction_verification.tscn`: straight River regression fixture for default downstream flow generation, near-neutral Flow Arrows, unused UV2 atlas neutrality, WaterSystem composition stats, save/reload, and runtime checks.
- `scenes/validation/two_phase_flow_validation.tscn`: preferred dedicated source fixture for two-phase river motion, neutral flow, alpha/noise variation, debug-view switching, and lava coverage when present.
- `scenes/validation/waterways_authoring_smoke_validation.tscn`: editor River selection, toolbar, gizmo, debug views, and a simple run-view buoyancy anchor.
- `scenes/validation/system_map_validation.tscn`: two child Rivers, transformed parent, River/WaterSystem bakes, map sampling, and wet-target material assignment.
- `scenes/validation/imported_data_texture_validation.tscn`: imported user data map validation.
- `scenes/validation/lava_material_validation.tscn`: lava material animation, emission, and edge/depth fade.
- `scenes/validation/zero_shader_settings_validation.tscn`: zero/near-zero shader settings.
- `scenes/validation/bake_preflight_validation.tscn`: clear warnings for invalid bake inputs.
- `scenes/validation/waterways_runtime_smoke_test.tscn`: runtime group cleanup, wet-target assignment, buoyancy, flow force, coverage fallback, and refreshed sampling.
- `scenes/validation/buoyant_damping_ownership_test.tscn`: Buoyant sleeping-body wake, damping ownership, later script damping changes, and missing-WaterSystem restore.

Visible validation is human-assisted in this workspace. Headless Godot editor-load checks are useful for parser and load sanity only.

For a release candidate, fully run any scene presented as a demo. The authoring smoke scene should visibly show the runtime body dropping into the water and reacting to buoyancy. Older placeholder scenes, such as `scenes/validation/buoyancy_sampling_validation.tscn`, should either be converted into real runtime demos before being advertised or kept as repo-only validation planning fixtures.

## Known Limitations

- Local non-editor headless runtime execution crashes in this workspace, so runtime behavior is validated through visible Godot runs.
- There is no user-facing bake cancel button yet. Long high-resolution bakes may still occupy the editor until the current bake phase finishes.
- Large-scene performance benchmarks are deferred; `0.2.2` only documents conservative authoring budgets and requires per-project timing notes before promising high-resolution bake performance.
- External generated bake resources are written for saved scenes. Unsaved scenes intentionally keep temporary in-memory bake data until you save and rebake.
- Buoyant is a simplified one-point helper, not a full fluid simulation.
- Ctrl-based grid or rounding behavior for River handle dragging is not implemented.
- Some legacy `.shader` files remain in the active add-on folder as reference counterparts during the port; active Godot 4 scripts and scenes use `.gdshader` resources.
