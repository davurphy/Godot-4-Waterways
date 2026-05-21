shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D flowmap : repeat_disable, filter_linear;
uniform sampler2D distmap : hint_default_white, repeat_disable, filter_linear;
uniform float flow_base : hint_range(0.0, 8.0) = 0.0;
uniform float flow_steepness : hint_range(0.0, 8.0) = 2.0;
uniform float flow_distance : hint_range(0.0, 8.0) = 1.0;
uniform float flow_pressure : hint_range(0.0, 8.0) = 1.0;
uniform float flow_max : hint_range(0.0, 8.0) = 4.0;
uniform bool valid_flowmap = false;
uniform int uv2_sides = 2;

const float EPSILON = 0.0001;

varying vec3 world_position;
varying vec2 mesh_uv;


vec3 srgb_to_linear(vec3 color) {
	return mix(
		color / 12.92,
		pow((color + vec3(0.055)) / 1.055, vec3(2.4)),
		step(vec3(0.04045), color)
	);
}

vec3 data_to_albedo(vec3 color) {
	if (OUTPUT_IS_SRGB) {
		return color;
	}
	return srgb_to_linear(color);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	mesh_uv = UV;
}

vec2 safe_direction(vec2 vector, vec2 fallback) {
	float vector_length = length(vector);
	if (vector_length <= EPSILON) {
		return fallback;
	}
	return vector / vector_length;
}

mat2 get_world_xz_from_uv_axes() {
	vec2 dpdx = dFdx(world_position.xz);
	vec2 dpdy = dFdy(world_position.xz);
	vec2 duvdx = dFdx(mesh_uv);
	vec2 duvdy = dFdy(mesh_uv);
	float det = duvdx.x * duvdy.y - duvdx.y * duvdy.x;
	if (abs(det) <= EPSILON) {
		return mat2(vec2(1.0, 0.0), vec2(0.0, 1.0));
	}
	vec2 world_u = (dpdx * duvdy.y - dpdy * duvdx.y) / det;
	vec2 world_v = (-dpdx * duvdy.x + dpdy * duvdx.x) / det;
	return mat2(
		safe_direction(world_u, vec2(1.0, 0.0)),
		safe_direction(world_v, vec2(0.0, 1.0))
	);
}

void fragment() {
	float safe_uv2_sides = max(float(uv2_sides), 1.0);
	vec2 atlas_size = max(vec2(textureSize(flowmap, 0)), vec2(1.0));
	vec2 source_size = max(round(atlas_size * safe_uv2_sides / (safe_uv2_sides + 2.0)), vec2(1.0));
	vec2 margin = round((atlas_size - source_size) * 0.5);
	vec2 custom_UV = (UV2 * source_size + margin) / atlas_size;
	vec2 flow_foam_noise = textureLod(flowmap, custom_UV, 0.0).rg;
	vec2 dist_pressure = textureLod(distmap, custom_UV, 0.0).xy;
	
	vec2 flow;
	float distance_map;
	float pressure_map;
	if (valid_flowmap) {
		flow = flow_foam_noise.xy;
		distance_map = (1.0 - dist_pressure.r) * 2.0;
		pressure_map = dist_pressure.g * 2.0;
	} else {
		flow = vec2(0.5, 0.572);
		distance_map = 0.5;
		pressure_map = 0.5;
	}
	
	flow = (flow - 0.5) * 2.0; // remap
	
	// calculate the steepness map
	vec3 flow_viewspace = flow.x * TANGENT + flow.y * BINORMAL;
	vec3 up_viewspace = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	float steepness_map = max(0.0, dot(flow_viewspace, up_viewspace)) * 4.0;
	
	float flow_force = min(flow_base + steepness_map * flow_steepness + distance_map * flow_distance + pressure_map * flow_pressure, flow_max);
	flow *= flow_force;
	
	mat2 world_from_uv = get_world_xz_from_uv_axes();
	vec2 new_flow = world_from_uv * flow;
	ALBEDO = data_to_albedo(vec3((new_flow), 0.0) * 0.5 + 0.5); // repack flowmap
}
