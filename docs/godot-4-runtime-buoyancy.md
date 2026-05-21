# Godot 4 Runtime And Buoyancy Notes

These notes cover the current Godot 4 port runtime helpers. They are intentionally narrower than the full release documentation planned for Milestone 8.

## WaterSystem Runtime Groups

`WaterSystem.system_group_name` is the group used by runtime helpers such as `Buoyant`. The default is `waterways_system`.

Changing `system_group_name` while the node is inside the scene tree removes the WaterSystem from the old group and adds it to the new one. Empty group names are allowed as a disabled state, but `Buoyant` nodes will not be able to discover that WaterSystem by group.

`WaterSystem.wet_group_name` is the group used when assigning the generated system map and coordinates to scene materials. Compatible wet targets are `MeshInstance3D` nodes with a `ShaderMaterial` either in `material_override` or in the configured `surface_index`.

Incompatible wet targets are skipped with a warning instead of stopping the bake or assignment pass. This includes non-mesh nodes, mesh nodes without the requested material, invalid surface indices, and non-`ShaderMaterial` materials.

## Buoyant Setup

`Buoyant` must be a direct child of a `RigidBody3D`. Set `water_system_group_name` to match the target `WaterSystem.system_group_name`.

At runtime, `Buoyant` looks up the closest compatible WaterSystem in that group. If the current WaterSystem is removed or leaves the configured group, the helper resolves the group again on a later physics tick.

When the body is below the sampled water height, the helper applies:

- upward central force scaled by submersion depth and `buoyancy_force`
- upright torque scaled by `up_correcting_force`
- central force from `WaterSystem.get_water_flow()` scaled by `flow_force`
- temporary linear and angular damping from `water_resistance`

Submerged sleeping bodies are woken before forces are applied.

When the sampled position is above water, or no WaterSystem is available, the damping values captured at water entry are restored only if `Buoyant` is still the last writer. If user code or another system changes either damping value later, `Buoyant` leaves that value alone.

## Limitations

This is simplified gameplay buoyancy, not a full fluid simulation or boat model. It samples one point at the Buoyant node position and does not calculate hull volume, multiple float points, wave displacement, drag surfaces, center of pressure, or realistic stability curves.

For heavier gameplay objects, add more custom logic around the WaterSystem altitude and flow queries, or use multiple Buoyant-like sample points on your own controller.
