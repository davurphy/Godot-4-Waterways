# Copyright © 2021 Kasper Arnklit Frandsen - MIT License
# See `LICENSE.md` included in the source distribution for details.
@tool
extends Node3D

const WaterHelperMethods = preload("./water_helper_methods.gd")
const RiverBakeDataResource = preload("res://addons/waterways/resources/river_bake_data.gd")

const FILTER_RENDERER_PATH = "res://addons/waterways/filter_renderer.tscn"
const FLOW_OFFSET_NOISE_TEXTURE_PATH = "res://addons/waterways/textures/flow_offset_noise.png"
const FOAM_NOISE_PATH = "res://addons/waterways/textures/foam_noise.png"
const GENERATED_MESH_NAME := "RiverMeshInstance"
const GENERATED_MESH_META := "waterways_generated_river_mesh"

const MATERIAL_CATEGORIES = {
	albedo_ = "Albedo",
	emission_ = "Emission",
	transparency_ = "Transparency",
	flow_ = "Flow",
	foam_ = "Foam",
	custom_ = "Custom"
}

enum SHADER_TYPES {WATER, LAVA, CUSTOM}
const BUILTIN_SHADERS = [
	{
		name = "Water",
		shader_path = "res://addons/waterways/shaders/river.gdshader",
		texture_paths = [
			{
				name = "normal_bump_texture",
				path = "res://addons/waterways/textures/water1_normal_bump.png"
			}
		]
	},
	{
		name = "Lava",
		shader_path = "res://addons/waterways/shaders/lava.gdshader",
		texture_paths = [
			{
				name = "normal_bump_texture",
				path = "res://addons/waterways/textures/lava_normal_bump.png"
			},
			{
				name = "emission_texture",
				path = "res://addons/waterways/textures/lava_emission.png"
			}
		]
	}
]

const DEBUG_SHADER = {
	name = "Debug",
	shader_path = "res://addons/waterways/shaders/river_debug.gdshader",
	texture_paths = [
		{
			name = "debug_pattern",
			path = "res://addons/waterways/textures/debug_pattern.png"
		},
		{
			name = "debug_arrow",
			path = "res://addons/waterways/textures/debug_arrow.svg"
		}
	]
}

const DEFAULT_PARAMETERS = {
	shape_step_length_divs = 1,
	shape_step_width_divs = 1,
	shape_smoothness = 0.5,
	mat_shader_type = 0,
	mat_custom_shader = null,
	baking_resolution = 2, 
	baking_raycast_distance = 10.0,
	baking_raycast_layers = 1,
	baking_dilate = 0.6,
	baking_flowmap_blur = 0.04,
	baking_foam_cutoff = 0.9,
	baking_foam_offset = 0.1,
	baking_foam_blur = 0.02,
	lod_lod0_distance = 50.0,
}

const BAKE_CHANNEL_FLAT_EPSILON := 0.002
const BAKE_CHANNEL_LOW_CONTRAST_EPSILON := 0.03
const BAKE_CHANNEL_SATURATION_EPSILON := 0.02
const RIVER_BAKE_SOURCE_SIGNATURE_VERSION := 5
const RIVER_FLOW_GENERATION_BEHAVIOR_DOWNSTREAM_BASELINE := "downstream_baseline_collision_support"
const RIVER_FLOW_GENERATION_BEHAVIOR_CURVE_ONLY := "curve_only"
const RIVER_FLOW_GENERATION_BEHAVIOR_LEGACY_COLLISION_ONLY := "legacy_collision_only"
const RIVER_DOWNSTREAM_BASELINE_STRENGTH := 0.25
const RIVER_BLANK_SUPPORT_VALUE := 0.0
const RIVER_FLAT_FOAM_SUPPORT_VALUE := 0.25
const RIVER_FLAT_PRESSURE_SUPPORT_VALUE := 0.25
const SOURCE_SIGNATURE_FLOAT_STEP := 0.0001
const SHAPE_STEP_DIVS_MIN := 1
const SHAPE_STEP_DIVS_MAX := 8
const SHAPE_SMOOTHNESS_MIN := 0.1
const SHAPE_SMOOTHNESS_MAX := 5.0
const LOD0_DISTANCE_MIN := 5.0
const LOD0_DISTANCE_MAX := 200.0
const RIVER_BAKE_RESOLUTION_MIN := 0
const RIVER_BAKE_RESOLUTION_MAX := 4
const RIVER_BAKE_TEXTURE_SIZE_MIN := 64
const RIVER_BAKE_TEXTURE_SIZE_MAX := 1024
const BAKING_RAYCAST_DISTANCE_MIN := 0.0
const BAKING_RAYCAST_DISTANCE_MAX := 100.0
const BAKING_RAYCAST_LAYERS_MIN := 0
const BAKING_RAYCAST_LAYERS_MAX := 0xFFFFFFFF
const BAKING_NORMALIZED_MIN := 0.0
const BAKING_NORMALIZED_MAX := 1.0


# Shape Properties
var shape_step_length_divs := 1:
	set(value):
		var sanitized_value := _sanitize_int_range("shape_step_length_divs", value, SHAPE_STEP_DIVS_MIN, SHAPE_STEP_DIVS_MAX, DEFAULT_PARAMETERS.shape_step_length_divs)
		if sanitized_value == shape_step_length_divs:
			return
		shape_step_length_divs = sanitized_value
		if not _suppress_property_change_notifications:
			_on_geometry_property_changed(true)
var shape_step_width_divs := 1:
	set(value):
		var sanitized_value := _sanitize_int_range("shape_step_width_divs", value, SHAPE_STEP_DIVS_MIN, SHAPE_STEP_DIVS_MAX, DEFAULT_PARAMETERS.shape_step_width_divs)
		if sanitized_value == shape_step_width_divs:
			return
		shape_step_width_divs = sanitized_value
		if not _suppress_property_change_notifications:
			_on_geometry_property_changed(true)
var shape_smoothness := 0.5:
	set(value):
		var sanitized_value := _sanitize_float_range("shape_smoothness", value, SHAPE_SMOOTHNESS_MIN, SHAPE_SMOOTHNESS_MAX, DEFAULT_PARAMETERS.shape_smoothness)
		if is_equal_approx(sanitized_value, shape_smoothness):
			return
		shape_smoothness = sanitized_value
		if not _suppress_property_change_notifications:
			_on_geometry_property_changed(true)

# Material Properties that not handled in shader
var mat_shader_type : int:
	set(value):
		var shader_type := _sanitize_shader_type(value)
		if shader_type == mat_shader_type:
			return
		mat_shader_type = shader_type
		_apply_shader_type()
var mat_custom_shader : Shader:
	set(value):
		var shader := value as Shader
		if mat_custom_shader == shader:
			return
		mat_custom_shader = shader
		_apply_custom_shader()

# LOD Properties
var lod_lod0_distance := 50.0:
	set(value):
		lod_lod0_distance = _sanitize_float_range("lod_lod0_distance", value, LOD0_DISTANCE_MIN, LOD0_DISTANCE_MAX, DEFAULT_PARAMETERS.lod_lod0_distance)
		set_materials("i_lod0_distance", lod_lod0_distance)

# Bake Properties
var baking_resolution := 2:
	set(value):
		var sanitized_value := _sanitize_int_range("baking_resolution", value, RIVER_BAKE_RESOLUTION_MIN, RIVER_BAKE_RESOLUTION_MAX, DEFAULT_PARAMETERS.baking_resolution)
		if sanitized_value == baking_resolution:
			return
		baking_resolution = sanitized_value
		if not _suppress_property_change_notifications:
			_on_bake_property_changed()
var baking_raycast_distance := 10.0:
	set(value):
		var sanitized_value := _sanitize_float_range("baking_raycast_distance", value, BAKING_RAYCAST_DISTANCE_MIN, BAKING_RAYCAST_DISTANCE_MAX, DEFAULT_PARAMETERS.baking_raycast_distance)
		if is_equal_approx(sanitized_value, baking_raycast_distance):
			return
		baking_raycast_distance = sanitized_value
		if not _suppress_property_change_notifications:
			_on_bake_property_changed()
var baking_raycast_layers := 1:
	set(value):
		var sanitized_value := _sanitize_int_range("baking_raycast_layers", value, BAKING_RAYCAST_LAYERS_MIN, BAKING_RAYCAST_LAYERS_MAX, DEFAULT_PARAMETERS.baking_raycast_layers)
		if sanitized_value == baking_raycast_layers:
			return
		baking_raycast_layers = sanitized_value
		if not _suppress_property_change_notifications:
			_on_bake_property_changed()
var baking_dilate := 0.6:
	set(value):
		var sanitized_value := _sanitize_float_range("baking_dilate", value, BAKING_NORMALIZED_MIN, BAKING_NORMALIZED_MAX, DEFAULT_PARAMETERS.baking_dilate)
		if is_equal_approx(sanitized_value, baking_dilate):
			return
		baking_dilate = sanitized_value
		if not _suppress_property_change_notifications:
			_on_bake_property_changed()
var baking_flowmap_blur := 0.04:
	set(value):
		var sanitized_value := _sanitize_float_range("baking_flowmap_blur", value, BAKING_NORMALIZED_MIN, BAKING_NORMALIZED_MAX, DEFAULT_PARAMETERS.baking_flowmap_blur)
		if is_equal_approx(sanitized_value, baking_flowmap_blur):
			return
		baking_flowmap_blur = sanitized_value
		if not _suppress_property_change_notifications:
			_on_bake_property_changed()
var baking_foam_cutoff := 0.9:
	set(value):
		var sanitized_value := _sanitize_float_range("baking_foam_cutoff", value, BAKING_NORMALIZED_MIN, BAKING_NORMALIZED_MAX, DEFAULT_PARAMETERS.baking_foam_cutoff)
		if is_equal_approx(sanitized_value, baking_foam_cutoff):
			return
		baking_foam_cutoff = sanitized_value
		if not _suppress_property_change_notifications:
			_on_bake_property_changed()
var baking_foam_offset := 0.1:
	set(value):
		var sanitized_value := _sanitize_float_range("baking_foam_offset", value, BAKING_NORMALIZED_MIN, BAKING_NORMALIZED_MAX, DEFAULT_PARAMETERS.baking_foam_offset)
		if is_equal_approx(sanitized_value, baking_foam_offset):
			return
		baking_foam_offset = sanitized_value
		if not _suppress_property_change_notifications:
			_on_bake_property_changed()
var baking_foam_blur := 0.02:
	set(value):
		var sanitized_value := _sanitize_float_range("baking_foam_blur", value, BAKING_NORMALIZED_MIN, BAKING_NORMALIZED_MAX, DEFAULT_PARAMETERS.baking_foam_blur)
		if is_equal_approx(sanitized_value, baking_foam_blur):
			return
		baking_foam_blur = sanitized_value
		if not _suppress_property_change_notifications:
			_on_bake_property_changed()
var bake_generation_behavior := RIVER_FLOW_GENERATION_BEHAVIOR_DOWNSTREAM_BASELINE:
	set(value):
		var sanitized_value := _sanitize_bake_generation_behavior(value)
		if sanitized_value == bake_generation_behavior:
			return
		bake_generation_behavior = sanitized_value
		if not _suppress_property_change_notifications:
			_on_bake_property_changed()

# Public variables
var curve : Curve3D
var widths := []:
	set(value):
		widths = _sanitize_width_array(value)
		_ensure_width_count_for_curve()
		if not _suppress_property_change_notifications and not _first_enter_tree:
			_on_geometry_property_changed(true)
var valid_flowmap := false
var debug_view := 0
var mesh_instance : MeshInstance3D
var flow_foam_noise : Texture2D
var dist_pressure : Texture2D
var _bake_data_resource : Resource
var bake_data : Resource:
	get:
		return _bake_data_resource
	set(value):
		_bake_data_resource = value
		_apply_bake_data()

# Private variables
var _steps := 2
var _st : SurfaceTool
var _mdt : MeshDataTool
var _debug_material : ShaderMaterial
var _first_enter_tree := true
var _filter_renderer
# Serialised private variables
var _material : ShaderMaterial
var _selected_shader : int = SHADER_TYPES.WATER
var _uv2_sides : int
var _suppress_property_change_notifications := false
var _flowmap_bake_in_progress := false

# river_changed used to update handles when values are changed on script side
# progress_notified used to up progress bar when baking maps
# albedo_set is needed since the gradient is a custom inspector that needs a signal to update from script side
signal river_changed
signal progress_notified
#signal albedo_set

# Internal Methods
func _get_property_list() -> Array:
	var props = [
		{
			name = "Shape",
			type = TYPE_NIL,
			hint_string = "shape_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "shape_step_length_divs",
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "1, 8",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "shape_step_width_divs",
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "1, 8",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "shape_smoothness",
			type = TYPE_FLOAT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.1, 5.0",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "Material",
			type = TYPE_NIL,
			hint_string = "mat_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "mat_shader_type",
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = "Water, Lava, Custom",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "mat_custom_shader",
			type = TYPE_OBJECT,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
			hint_string = "Shader"
		},
	]

	var props2 = []
	var mat_categories = MATERIAL_CATEGORIES.duplicate(true)
	
	if _material.shader != null:
		var shader_params: Array = RenderingServer.get_shader_parameter_list(_material.shader.get_rid())
		shader_params = WaterHelperMethods.reorder_params(shader_params)
		for p in shader_params:
			if p.name.begins_with("i_"):
				continue
			var hit_category = null
			for category in mat_categories:
				if p.name.begins_with(category):
					props2.append({
						name = str("Material/", mat_categories[category]),
						type = TYPE_NIL,
						hint_string = str("mat_", category),
						usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
					})
					hit_category = category
					break
			if hit_category != null:
				mat_categories.erase(hit_category)
			var cp := {}
			for k in p:
				cp[k] = p[k]
			cp.name = str("mat_", p.name)
			if "curve" in cp.name:
				cp.hint = PROPERTY_HINT_EXP_EASING
				cp.hint_string = "EASE"
			props2.append(cp)
	var props3 = [
		{
			name = "Lod",
			type = TYPE_NIL,
			hint_string = "lod_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "lod_lod0_distance",
			type = TYPE_FLOAT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "5.0, 200.0",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "Baking",
			type = TYPE_NIL,
			hint_string = "baking_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "baking_resolution",
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = "64, 128, 256, 512, 1024",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "baking_raycast_distance",
			type = TYPE_FLOAT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 100.0",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},		
		{
			name = "baking_raycast_layers",
			type = TYPE_INT,
			hint = PROPERTY_HINT_LAYERS_3D_PHYSICS,
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "baking_dilate",
			type = TYPE_FLOAT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 1.0",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "baking_flowmap_blur",
			type = TYPE_FLOAT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 1.0",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "baking_foam_cutoff",
			type = TYPE_FLOAT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 1.0",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "baking_foam_offset",
			type = TYPE_FLOAT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 1.0",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "baking_foam_blur",
			type = TYPE_FLOAT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.0, 1.0",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "bake_data",
			type = TYPE_OBJECT,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			hint_string = "RiverBakeData",
			usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = "bake_generation_behavior",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_STORAGE
		},
		# Serialize these values without exposing it in the inspector
		{
			name = "curve",
			type = TYPE_OBJECT,
			usage = PROPERTY_USAGE_STORAGE
		},
		{
			name = "widths",
			type = TYPE_ARRAY,
			usage = PROPERTY_USAGE_STORAGE
		},
		{
			name = "valid_flowmap",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_STORAGE
		},
		{
			name = "flow_foam_noise",
			type = TYPE_OBJECT,
			usage = PROPERTY_USAGE_STORAGE
		},
		{
			name = "dist_pressure",
			type = TYPE_OBJECT,
			usage = PROPERTY_USAGE_STORAGE
		},
		{
			name = "_material",
			type = TYPE_OBJECT,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			hint_string = "ShaderMaterial",
			usage = PROPERTY_USAGE_STORAGE
		},
		{
			name = "_selected_shader",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_STORAGE
		},
		{
			name = "_uv2_sides",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_STORAGE
		}
	]
	var combined_props = props + props2 + props3
	return combined_props


func _set(property: StringName, value: Variant) -> bool:
	var property_name := String(property)
	if property_name == "bake_data":
		bake_data = value
		return true
	if property_name == "bake_generation_behavior":
		set_bake_generation_behavior(String(value))
		return true
	match property_name:
		"shape_step_length_divs":
			set_step_length_divs(int(value))
			return true
		"shape_step_width_divs":
			set_step_width_divs(int(value))
			return true
		"shape_smoothness":
			set_smoothness(float(value))
			return true
		"mat_shader_type":
			set_shader_type(int(value))
			return true
		"mat_custom_shader":
			set_custom_shader(value as Shader)
			return true
		"lod_lod0_distance":
			set_lod0_distance(float(value))
			return true
	if property_name.begins_with("baking_"):
		return _set_baking_property(property_name, value)
	if property_name.begins_with("mat_"):
		var param_name := property_name.trim_prefix("mat_")
		_material.set_shader_parameter(param_name, value)
		return true
	return false


func _get(property: StringName) -> Variant:
	var property_name := String(property)
	if property_name == "bake_data":
		return bake_data
	if property_name == "bake_generation_behavior":
		return bake_generation_behavior
	match property_name:
		"shape_step_length_divs":
			return shape_step_length_divs
		"shape_step_width_divs":
			return shape_step_width_divs
		"shape_smoothness":
			return shape_smoothness
		"mat_shader_type":
			return mat_shader_type
		"mat_custom_shader":
			return mat_custom_shader
		"lod_lod0_distance":
			return lod_lod0_distance
	if property_name.begins_with("baking_"):
		return _get_baking_property(property_name)
	if property_name.begins_with("mat_"):
		var param_name := property_name.trim_prefix("mat_")
		return  _material.get_shader_parameter(param_name)
	return null


func property_can_revert(property: StringName) -> bool:
	var property_name := String(property)
	if DEFAULT_PARAMETERS.has(property_name):
		if get(property_name) != DEFAULT_PARAMETERS[property_name]:
			return true
		return false
	if property_name.begins_with("mat_"):
		var param_name := property_name.trim_prefix("mat_")
		return _material.property_can_revert(str("shader_param/", param_name))

	return false


func property_get_revert(property: StringName) -> Variant:
	var property_name := String(property)
	if DEFAULT_PARAMETERS.has(property_name):
		return DEFAULT_PARAMETERS.get(property_name, null)
	if property_name.begins_with("mat_"):
		var param_name := property_name.trim_prefix("mat_")
		var revert_value := _material.property_get_revert(str("shader_param/", param_name))
		return revert_value
	return null


func _init() -> void:
	_st = SurfaceTool.new()
	_mdt = MeshDataTool.new()
	_filter_renderer = load(FILTER_RENDERER_PATH)

	_debug_material = ShaderMaterial.new()
	_debug_material.shader = load(DEBUG_SHADER.shader_path) as Shader
	for texture in DEBUG_SHADER.texture_paths:
		_debug_material.set_shader_parameter(texture.name, load(texture.path) as Texture2D)

	_material = ShaderMaterial.new()
	_material.shader = load(BUILTIN_SHADERS[mat_shader_type].shader_path) as Shader
	for texture in BUILTIN_SHADERS[mat_shader_type].texture_paths:
		var texture_resource := load(texture.path) as Texture2D
		_material.set_shader_parameter(texture.name, texture_resource)
		if texture.name == "normal_bump_texture":
			_debug_material.set_shader_parameter(texture.name, texture_resource)
	# Have to manually set the color or it does not default right. Not sure how to work around this
	_material.set_shader_parameter("albedo_color", Transform3D(Vector3(0.0, 0.8, 1.0), Vector3(0.15, 0.2, 0.5), Vector3.ZERO, Vector3.ZERO))


func _enter_tree() -> void:
	if Engine.is_editor_hint() and _first_enter_tree:
		_first_enter_tree = false
	
	if not curve:
		curve = Curve3D.new()
		curve.bake_interval = 0.05
		curve.add_point(Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, -0.25), Vector3(0.0, 0.0, 0.25))
		curve.add_point(Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, -0.25), Vector3(0.0, 0.0, 0.25))
		_set_widths_without_property_notifications([1.0, 1.0])
	_sanitize_authoring_properties()
	
	_ensure_generated_mesh_instance()
	
	_generate_river()
	
	_apply_bake_data()
	set_materials("i_valid_flowmap", valid_flowmap)
	set_materials("i_uv2_sides", _uv2_sides)
	set_materials("i_distmap", dist_pressure)
	set_materials("i_flowmap", flow_foam_noise)
	set_materials("i_texture_foam_noise", load(FOAM_NOISE_PATH) as Texture2D)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not valid_flowmap:
		warnings.append("No flowmap is set. Select River -> Generate Flow & Foam Map to generate and assign one.")
	elif _has_unsaved_generated_textures():
		warnings.append("Generated River maps are not stored in an external .res bake resource. Save the scene, then rebake before running with F6 or exporting.")
	return warnings


# Public Methods - These should all be good to use as API from other scripts
func is_bake_in_progress() -> bool:
	return _flowmap_bake_in_progress


func add_point(position : Vector3, index : int, dir : Vector3 = Vector3.ZERO, width : float = 0.0) -> void:
	if index == -1:
		var last_index := curve.get_point_count() - 1
		var dist := position.distance_to(curve.get_point_position(last_index))
		var new_dir: Vector3 = dir if dir != Vector3.ZERO else (position - curve.get_point_position(last_index) - curve.get_point_out(last_index) ).normalized() * 0.25 * dist
		curve.add_point(position, -new_dir, new_dir, -1)
		widths.append(_get_width_for_point(widths.size() - 1)) # If this is a new point at the end, add a width that's the same as last
	else:
		var dist := curve.get_point_position(index).distance_to(curve.get_point_position(index + 1))
		var new_dir: Vector3 = dir if dir != Vector3.ZERO else (curve.get_point_position(index + 1) - curve.get_point_position(index)).normalized() * 0.25 * dist
		curve.add_point(position, -new_dir, new_dir, index + 1)
		var new_width = _sanitize_width_value(width, "width") if width != 0.0 else (_get_width_for_point(index) + _get_width_for_point(index + 1)) / 2.0
		widths.insert(index + 1, new_width) # We set the width to the average of the two surrounding widths
	_invalidate_generated_bake(true, true)


func insert_point_with_handles(position: Vector3, index: int, point_in: Vector3, point_out: Vector3, width: float) -> void:
	var insert_index := index
	if insert_index < 0:
		insert_index = 0
	if insert_index > curve.get_point_count():
		insert_index = curve.get_point_count()
	var curve_insert_index := insert_index
	if insert_index >= curve.get_point_count():
		curve_insert_index = -1
	curve.add_point(position, point_in, point_out, curve_insert_index)
	var safe_width := _sanitize_width_value(width, "width")
	if insert_index >= widths.size():
		widths.append(safe_width)
	else:
		widths.insert(insert_index, safe_width)
	_invalidate_generated_bake(true, true)


func get_curve_state() -> Dictionary:
	var positions := PackedVector3Array()
	var point_ins := PackedVector3Array()
	var point_outs := PackedVector3Array()
	for point_index in curve.get_point_count():
		positions.append(curve.get_point_position(point_index))
		point_ins.append(curve.get_point_in(point_index))
		point_outs.append(curve.get_point_out(point_index))
	return {
		"positions": positions,
		"point_ins": point_ins,
		"point_outs": point_outs,
		"widths": widths.duplicate(true)
	}


func restore_curve_state(state: Dictionary) -> void:
	var positions: PackedVector3Array = state.get("positions", PackedVector3Array())
	var point_ins: PackedVector3Array = state.get("point_ins", PackedVector3Array())
	var point_outs: PackedVector3Array = state.get("point_outs", PackedVector3Array())
	_set_widths_without_property_notifications(state.get("widths", []).duplicate(true))
	curve.clear_points()
	for point_index in positions.size():
		var point_in := Vector3.ZERO
		var point_out := Vector3.ZERO
		if point_index < point_ins.size():
			point_in = point_ins[point_index]
		if point_index < point_outs.size():
			point_out = point_outs[point_index]
		curve.add_point(positions[point_index], point_in, point_out, -1)
	_ensure_width_count_for_curve()
	_invalidate_generated_bake(true, true)


func get_generated_bake_valid_state() -> Dictionary:
	return {
		"valid_flowmap": valid_flowmap,
		"shader_i_valid_flowmap": _get_valid_flowmap_shader_state(valid_flowmap)
	}


func restore_generated_bake_valid_state(state: Dictionary) -> void:
	var restored_valid := bool(state.get("valid_flowmap", false))
	var shader_value = state.get("shader_i_valid_flowmap", restored_valid)
	if shader_value == null:
		shader_value = restored_valid
	var restored_shader_valid := bool(shader_value)
	_set_valid_flowmap(restored_valid)
	if restored_shader_valid != restored_valid:
		set_materials("i_valid_flowmap", restored_shader_valid)


func restore_curve_state_with_generated_bake_valid_state(curve_state: Dictionary, bake_valid_state: Dictionary) -> void:
	restore_curve_state(curve_state)
	restore_generated_bake_valid_state(bake_valid_state)


func remove_point(index : int) -> void:
	# We don't allow rivers shorter than 2 points
	if curve.get_point_count() <= 2:
		return
	curve.remove_point(index)
	widths.remove_at(index)
	_invalidate_generated_bake(true, true)


func bake_texture() -> void:
	if not _begin_flowmap_bake_request():
		return
	var flowmap_resolution := _get_river_bake_texture_size()
	var setup_failures := _get_bake_preflight_failures(flowmap_resolution, false)
	if not setup_failures.is_empty():
		_warn_bake_preflight_failures(setup_failures)
		_clear_flowmap_bake_request()
		return
	_generate_river()
	var mesh_failures := _get_bake_preflight_failures(flowmap_resolution, true)
	if not mesh_failures.is_empty():
		_warn_bake_preflight_failures(mesh_failures)
		_clear_flowmap_bake_request()
		return
	_generate_flowmap(flowmap_resolution)


func set_bake_generation_behavior(value: String) -> void:
	bake_generation_behavior = value


func set_curve_point_position(index : int, position : Vector3) -> void:
	curve.set_point_position(index, position)
	_invalidate_generated_bake(true, false)


func set_curve_point_in(index : int, position : Vector3) -> void:
	curve.set_point_in(index, position)
	_invalidate_generated_bake(true, false)


func set_curve_point_out(index : int, position : Vector3) -> void:
	curve.set_point_out(index, position)
	_invalidate_generated_bake(true, false)


func set_widths(new_widths : Array) -> void:
	widths = new_widths


func set_materials(param : String, value) -> void:
	if _material != null:
		_material.set_shader_parameter(param, value)
	if _debug_material != null:
		_debug_material.set_shader_parameter(param, value)


func set_debug_view(index : int) -> void:
	debug_view = index
	_apply_debug_view_material()


func spawn_mesh() -> void:
	if get_parent() == null:
		push_warning("Cannot create MeshInstance3D sibling when River is root.")
		return
	_ensure_generated_mesh_instance()
	if mesh_instance == null:
		push_warning("Cannot create MeshInstance3D sibling because the generated RiverMeshInstance is unavailable.")
		return
	var source_global_transform := mesh_instance.global_transform
	var sibling_mesh := mesh_instance.duplicate(true) as MeshInstance3D
	if sibling_mesh.has_meta(GENERATED_MESH_META):
		sibling_mesh.remove_meta(GENERATED_MESH_META)
	get_parent().add_child(sibling_mesh)
	_assign_generated_mesh_owner(sibling_mesh)
	sibling_mesh.global_transform = source_global_transform
	sibling_mesh.material_override = null;


func get_curve_points() -> PackedVector3Array:
	var points : PackedVector3Array
	for p in curve.get_point_count():
		points.append(curve.get_point_position(p))
	
	return points


func get_closest_point_to(point : Vector3) -> int:
	var points = []
	var closest_distance := 4096.0
	var closest_index
	for p in curve.get_point_count():
		var dist := point.distance_to(curve.get_point_position(p))
		if dist < closest_distance:
			closest_distance = dist
			closest_index = p
	
	return closest_index


func get_shader_param(param : String):
	return _material.get_shader_parameter(param)


# Parameter Setters
func set_step_length_divs(value : int) -> void:
	shape_step_length_divs = value


func set_step_width_divs(value : int) -> void:
	shape_step_width_divs = value


func set_smoothness(value : float) -> void:
	shape_smoothness = value


func set_shader_type(type: int):
	mat_shader_type = type


func _apply_shader_type() -> void:
	if _material == null:
		return
	if mat_shader_type < SHADER_TYPES.WATER or mat_shader_type > SHADER_TYPES.CUSTOM:
		mat_shader_type = _sanitize_shader_type(mat_shader_type)
		return
	if mat_shader_type == SHADER_TYPES.CUSTOM:
		_material.shader = mat_custom_shader
	else:
		_selected_shader = mat_shader_type
		_material.shader = load(BUILTIN_SHADERS[mat_shader_type].shader_path)
		for texture in BUILTIN_SHADERS[mat_shader_type].texture_paths:
			var texture_resource := load(texture.path) as Texture2D
			_material.set_shader_parameter(texture.name, texture_resource)
			if texture.name == "normal_bump_texture":
				_debug_material.set_shader_parameter(texture.name, texture_resource)
	
	notify_property_list_changed()


func set_custom_shader(shader : Shader) -> void:
	mat_custom_shader = shader


func _apply_custom_shader() -> void:
	if _material == null:
		return
	if mat_custom_shader != null:
		_material.shader = mat_custom_shader
		
		if Engine.is_editor_hint():
			# Ability to fork default shader
			if mat_custom_shader.code == "":
				var selected_shader_index := _selected_shader
				if selected_shader_index < SHADER_TYPES.WATER or selected_shader_index > SHADER_TYPES.LAVA:
					selected_shader_index = SHADER_TYPES.WATER
				var selected_shader = load(BUILTIN_SHADERS[selected_shader_index].shader_path) as Shader
				mat_custom_shader.code = selected_shader.code
	
	if mat_custom_shader != null:
		mat_shader_type = SHADER_TYPES.CUSTOM
	else:
		mat_shader_type = SHADER_TYPES.WATER


func set_lod0_distance(value : float) -> void:
	lod_lod0_distance = value


# Private Methods
func _generate_river() -> void:
	if curve == null:
		return
	_ensure_generated_mesh_instance()
	if mesh_instance == null:
		return
	mesh_instance.transform = Transform3D.IDENTITY
	_steps = _calculate_step_count()
	
	var river_width_values := WaterHelperMethods.generate_river_width_values(curve, _steps, shape_step_length_divs, shape_step_width_divs, widths)
	var uv2_source_resolution := _get_river_bake_texture_size()
	mesh_instance.mesh = WaterHelperMethods.generate_river_mesh(curve, _steps, shape_step_length_divs, shape_step_width_divs, shape_smoothness, river_width_values, uv2_source_resolution)
	if mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
		mesh_instance.mesh.surface_set_material(0, _material)
	_apply_debug_view_material()


func _apply_debug_view_material() -> void:
	if mesh_instance == null:
		return
	if debug_view == 0:
		mesh_instance.material_override = null
		if mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
			mesh_instance.set_surface_override_material(0, null)
		return
	
	_debug_material.set_shader_parameter("mode", debug_view)
	mesh_instance.material_override = _debug_material
	if mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
		mesh_instance.set_surface_override_material(0, _debug_material)


func _ensure_generated_mesh_instance() -> void:
	if _is_valid_generated_mesh_instance(mesh_instance):
		_prepare_generated_mesh_instance(mesh_instance)
		return
	var found_mesh := _find_generated_mesh_instance()
	if found_mesh == null:
		found_mesh = MeshInstance3D.new()
		found_mesh.name = GENERATED_MESH_NAME
		add_child(found_mesh)
	mesh_instance = found_mesh
	_prepare_generated_mesh_instance(mesh_instance)


func _find_generated_mesh_instance() -> MeshInstance3D:
	var named_candidate: MeshInstance3D = null
	for child in get_children():
		if not child is MeshInstance3D:
			continue
		var child_mesh := child as MeshInstance3D
		if _has_generated_mesh_metadata(child_mesh):
			return child_mesh
		if named_candidate == null and child_mesh.name == GENERATED_MESH_NAME:
			named_candidate = child_mesh
	return named_candidate


func _is_valid_generated_mesh_instance(node: Node) -> bool:
	return node != null and is_instance_valid(node) and node is MeshInstance3D and node.get_parent() == self and (_has_generated_mesh_metadata(node) or node.name == GENERATED_MESH_NAME)


func _prepare_generated_mesh_instance(node: MeshInstance3D) -> void:
	node.set_meta(GENERATED_MESH_META, true)
	_assign_generated_mesh_owner(node)
	if node.mesh != null and node.mesh.get_surface_count() > 0:
		var existing_material := node.mesh.surface_get_material(0)
		if existing_material is ShaderMaterial:
			_material = existing_material as ShaderMaterial


func _has_generated_mesh_metadata(node: Node) -> bool:
	return node != null and node.has_meta(GENERATED_MESH_META) and bool(node.get_meta(GENERATED_MESH_META))


func _assign_generated_mesh_owner(node: Node) -> void:
	if not Engine.is_editor_hint():
		return
	var edited_scene_root = get_tree().get_edited_scene_root()
	if edited_scene_root != null and edited_scene_root.is_ancestor_of(node):
		node.owner = edited_scene_root


func _get_bake_preflight_failures(flowmap_resolution: int, require_mesh: bool, generation_behavior: String = "") -> PackedStringArray:
	var checked_generation_behavior := _sanitize_bake_generation_behavior(bake_generation_behavior if generation_behavior.is_empty() else generation_behavior)
	var failures := PackedStringArray()
	if curve == null:
		failures.append("no Curve3D is assigned")
	elif curve.get_point_count() < 2:
		failures.append("the curve needs at least two points")
	elif widths.size() < curve.get_point_count():
		failures.append("width data has fewer entries than curve points")
	if shape_step_length_divs < SHAPE_STEP_DIVS_MIN or shape_step_length_divs > SHAPE_STEP_DIVS_MAX:
		failures.append("shape_step_length_divs must be between " + str(SHAPE_STEP_DIVS_MIN) + " and " + str(SHAPE_STEP_DIVS_MAX))
	if shape_step_width_divs < SHAPE_STEP_DIVS_MIN or shape_step_width_divs > SHAPE_STEP_DIVS_MAX:
		failures.append("shape_step_width_divs must be between " + str(SHAPE_STEP_DIVS_MIN) + " and " + str(SHAPE_STEP_DIVS_MAX))
	if not _is_finite_number(shape_smoothness) or shape_smoothness < SHAPE_SMOOTHNESS_MIN or shape_smoothness > SHAPE_SMOOTHNESS_MAX:
		failures.append("shape_smoothness must be between " + str(SHAPE_SMOOTHNESS_MIN) + " and " + str(SHAPE_SMOOTHNESS_MAX))
	if baking_resolution < RIVER_BAKE_RESOLUTION_MIN or baking_resolution > RIVER_BAKE_RESOLUTION_MAX:
		failures.append("baking_resolution must be between " + str(RIVER_BAKE_RESOLUTION_MIN) + " and " + str(RIVER_BAKE_RESOLUTION_MAX))
	if flowmap_resolution < RIVER_BAKE_TEXTURE_SIZE_MIN or flowmap_resolution > RIVER_BAKE_TEXTURE_SIZE_MAX:
		failures.append("baking_resolution produced an invalid texture size")
	if not _is_finite_number(baking_raycast_distance) or baking_raycast_distance <= 0.0:
		failures.append("baking_raycast_distance must be greater than 0")
	elif baking_raycast_distance > BAKING_RAYCAST_DISTANCE_MAX:
		failures.append("baking_raycast_distance must be no greater than " + str(BAKING_RAYCAST_DISTANCE_MAX))
	if _requires_collision_raycast_layers(checked_generation_behavior) and baking_raycast_layers == 0:
		failures.append("baking_raycast_layers has no collision layers selected")
	if not _is_finite_number(baking_dilate) or baking_dilate < BAKING_NORMALIZED_MIN or baking_dilate > BAKING_NORMALIZED_MAX:
		failures.append("baking_dilate must be between 0 and 1")
	if not _is_finite_number(baking_flowmap_blur) or baking_flowmap_blur < BAKING_NORMALIZED_MIN or baking_flowmap_blur > BAKING_NORMALIZED_MAX:
		failures.append("baking_flowmap_blur must be between 0 and 1")
	if not _is_finite_number(baking_foam_cutoff) or baking_foam_cutoff < BAKING_NORMALIZED_MIN or baking_foam_cutoff > BAKING_NORMALIZED_MAX:
		failures.append("baking_foam_cutoff must be between 0 and 1")
	if not _is_finite_number(baking_foam_offset) or baking_foam_offset < BAKING_NORMALIZED_MIN or baking_foam_offset > BAKING_NORMALIZED_MAX:
		failures.append("baking_foam_offset must be between 0 and 1")
	if not _is_finite_number(baking_foam_blur) or baking_foam_blur < BAKING_NORMALIZED_MIN or baking_foam_blur > BAKING_NORMALIZED_MAX:
		failures.append("baking_foam_blur must be between 0 and 1")
	for width in widths:
		var width_value := float(width)
		if not _is_finite_number(width_value) or width_value < WaterHelperMethods.MIN_RIVER_WIDTH:
			failures.append("all river widths must be finite positive values")
			break
	if not (_filter_renderer is PackedScene):
		failures.append("filter renderer scene could not be loaded")
	if require_mesh:
		if mesh_instance == null:
			failures.append("no generated RiverMeshInstance is available")
		elif mesh_instance.mesh == null:
			failures.append("RiverMeshInstance has no mesh")
		elif mesh_instance.mesh.get_surface_count() < 1:
			failures.append("RiverMeshInstance mesh has no surfaces")
	return failures


func _warn_bake_preflight_failures(failures: PackedStringArray) -> void:
	push_warning("Cannot generate River flow map: " + "; ".join(failures) + ".")


func _begin_flowmap_bake_request() -> bool:
	if _flowmap_bake_in_progress:
		push_warning("Waterways: River Flow & Foam bake is already in progress; ignoring duplicate request.")
		return false
	_flowmap_bake_in_progress = true
	return true


func _clear_flowmap_bake_request() -> void:
	_flowmap_bake_in_progress = false


func _is_finite_number(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)


func _sanitize_int_range(property_name: String, value: Variant, min_value: int, max_value: int, fallback_value: int) -> int:
	var numeric_value := fallback_value
	if typeof(value) == TYPE_FLOAT:
		var float_value := float(value)
		if not _is_finite_number(float_value):
			_warn_sanitized_property(property_name, value, fallback_value)
			return fallback_value
		numeric_value = int(round(float_value))
	else:
		numeric_value = int(value)
	var sanitized_value: int = clamp(numeric_value, min_value, max_value)
	if numeric_value != sanitized_value:
		_warn_sanitized_property(property_name, value, sanitized_value)
	return sanitized_value


func _sanitize_float_range(property_name: String, value: Variant, min_value: float, max_value: float, fallback_value: float) -> float:
	var numeric_value := float(value)
	if not _is_finite_number(numeric_value):
		_warn_sanitized_property(property_name, value, fallback_value)
		return fallback_value
	var sanitized_value: float = clamp(numeric_value, min_value, max_value)
	if not is_equal_approx(numeric_value, sanitized_value):
		_warn_sanitized_property(property_name, value, sanitized_value)
	return sanitized_value


func _sanitize_shader_type(value: Variant) -> int:
	if typeof(value) == TYPE_FLOAT and not _is_finite_number(float(value)):
		_warn_sanitized_property("mat_shader_type", value, SHADER_TYPES.WATER)
		return SHADER_TYPES.WATER
	var shader_type := int(value)
	if shader_type < SHADER_TYPES.WATER or shader_type > SHADER_TYPES.CUSTOM:
		_warn_sanitized_property("mat_shader_type", value, SHADER_TYPES.WATER)
		return SHADER_TYPES.WATER
	return shader_type


func _sanitize_bake_generation_behavior(value: Variant) -> String:
	var behavior := String(value)
	if behavior == RIVER_FLOW_GENERATION_BEHAVIOR_LEGACY_COLLISION_ONLY:
		return behavior
	if behavior == RIVER_FLOW_GENERATION_BEHAVIOR_CURVE_ONLY:
		return behavior
	if behavior == RIVER_FLOW_GENERATION_BEHAVIOR_DOWNSTREAM_BASELINE:
		return behavior
	_warn_sanitized_property("bake_generation_behavior", value, RIVER_FLOW_GENERATION_BEHAVIOR_DOWNSTREAM_BASELINE)
	return RIVER_FLOW_GENERATION_BEHAVIOR_DOWNSTREAM_BASELINE


func _sanitize_authoring_properties() -> void:
	var was_suppressed := _suppress_property_change_notifications
	_suppress_property_change_notifications = true
	shape_step_length_divs = shape_step_length_divs
	shape_step_width_divs = shape_step_width_divs
	shape_smoothness = shape_smoothness
	mat_shader_type = mat_shader_type
	lod_lod0_distance = lod_lod0_distance
	baking_resolution = baking_resolution
	baking_raycast_distance = baking_raycast_distance
	baking_raycast_layers = baking_raycast_layers
	baking_dilate = baking_dilate
	baking_flowmap_blur = baking_flowmap_blur
	baking_foam_cutoff = baking_foam_cutoff
	baking_foam_offset = baking_foam_offset
	baking_foam_blur = baking_foam_blur
	bake_generation_behavior = bake_generation_behavior
	widths = widths
	_suppress_property_change_notifications = was_suppressed


func _set_widths_without_property_notifications(new_widths: Array) -> void:
	var was_suppressed := _suppress_property_change_notifications
	_suppress_property_change_notifications = true
	widths = new_widths
	_suppress_property_change_notifications = was_suppressed


func _sanitize_width_array(value: Variant) -> Array:
	var sanitized_widths := []
	if typeof(value) != TYPE_ARRAY:
		_warn_sanitized_property("widths", value, "[]")
		return sanitized_widths
	var source_widths: Array = value
	for width_index in source_widths.size():
		sanitized_widths.append(_sanitize_width_value(source_widths[width_index], "widths[" + str(width_index) + "]"))
	return sanitized_widths


func _sanitize_width_value(value: Variant, property_name: String) -> float:
	var width_value := float(value)
	if not _is_finite_number(width_value) or width_value < WaterHelperMethods.MIN_RIVER_WIDTH:
		_warn_sanitized_property(property_name, value, WaterHelperMethods.MIN_RIVER_WIDTH)
		return WaterHelperMethods.MIN_RIVER_WIDTH
	return width_value


func _ensure_width_count_for_curve() -> void:
	var required_width_count := 0
	if curve != null:
		required_width_count = curve.get_point_count()
	if required_width_count <= 0:
		return
	if widths.is_empty():
		_warn_sanitized_property("widths", "empty", "default width values")
		widths.append(1.0)
	while widths.size() < required_width_count:
		_warn_sanitized_property("widths", "too few entries", "padded to curve point count")
		widths.append(widths[widths.size() - 1])


func _get_width_for_point(point_index: int) -> float:
	if widths.is_empty():
		return WaterHelperMethods.MIN_RIVER_WIDTH
	var width_index: int = clamp(point_index, 0, widths.size() - 1)
	return _sanitize_width_value(widths[width_index], "widths[" + str(width_index) + "]")


func _get_average_width() -> float:
	if widths.is_empty():
		return 1.0
	var total_width := 0.0
	for width_index in widths.size():
		total_width += _get_width_for_point(width_index)
	return max(WaterHelperMethods.MIN_RIVER_WIDTH, total_width / float(widths.size()))


func _get_river_bake_texture_size() -> int:
	var safe_resolution := _sanitize_int_range("baking_resolution", baking_resolution, RIVER_BAKE_RESOLUTION_MIN, RIVER_BAKE_RESOLUTION_MAX, DEFAULT_PARAMETERS.baking_resolution)
	if safe_resolution != baking_resolution:
		var was_suppressed := _suppress_property_change_notifications
		_suppress_property_change_notifications = true
		baking_resolution = safe_resolution
		_suppress_property_change_notifications = was_suppressed
	return int(pow(2, 6 + safe_resolution))


func _warn_sanitized_property(property_name: String, original_value: Variant, sanitized_value: Variant) -> void:
	push_warning("Waterways: " + property_name + " had unsafe value " + str(original_value) + "; using " + str(sanitized_value) + " instead.")


func _generate_flowmap(flowmap_resolution : float) -> void:
	var generation_behavior := _sanitize_bake_generation_behavior(bake_generation_behavior)
	var image := Image.create(int(flowmap_resolution), int(flowmap_resolution), true, Image.FORMAT_RGB8)
	image.fill(Color(0.0, 0.0, 0.0))
	var collision_stats := _get_collision_map_stats(image)
	var support_fallback_reason := ""
	var collision_probe_skipped := false
	if _is_curve_only_generation(generation_behavior):
		support_fallback_reason = "curve_only"
		collision_probe_skipped = true
	elif generation_behavior == RIVER_FLOW_GENERATION_BEHAVIOR_DOWNSTREAM_BASELINE and baking_raycast_layers == 0:
		support_fallback_reason = "baking_raycast_layers_zero"
		collision_probe_skipped = true
	
	if collision_probe_skipped:
		emit_signal("progress_notified", 0.0, "Preparing curve flow (" + str(flowmap_resolution) + "x" + str(flowmap_resolution) + ")")
		await get_tree().process_frame
	else:
		WaterHelperMethods.reset_all_colliders(get_tree().root)
		emit_signal("progress_notified", 0.0, "Calculating Collisions (" + str(flowmap_resolution) + "x" + str(flowmap_resolution) + ")")
		await get_tree().process_frame
		image = await WaterHelperMethods.generate_collisionmap(image, mesh_instance, baking_raycast_distance, baking_raycast_layers, _steps, shape_step_length_divs, shape_step_width_divs, self)
		if image == null or image.is_empty():
			_warn_if_collision_map_empty(image, generation_behavior, support_fallback_reason)
			_finish_flowmap_bake_after_failure()
			return
		collision_stats = _get_collision_map_stats(image)
		if _uses_downstream_baseline_generation(generation_behavior) and int(collision_stats.get("hit_pixel_count", 0)) == 0:
			support_fallback_reason = "no_collision_hits"
		_warn_if_collision_map_empty(image, generation_behavior, support_fallback_reason)
	
	emit_signal("progress_notified", 0.95, "Applying filters (" + str(flowmap_resolution) + "x" + str(flowmap_resolution) + ")")
	await get_tree().process_frame
	
	# Calculate how many colums are in UV2
	_uv2_sides = WaterHelperMethods.calculate_side(_steps)
	
	var margin := int(round(float(flowmap_resolution) / float(_uv2_sides)))
	var downstream_baseline_with_margins_texture: Texture2D = null
	if _uses_downstream_baseline_generation(generation_behavior):
		# River flow RG is local UV flow. Flat collision interiors have no gradient,
		# so the default bake supplies downstream +V and keeps collision data as support.
		var downstream_baseline := WaterHelperMethods.create_downstream_baseline_flow_image(int(flowmap_resolution), _uv2_sides, _steps, RIVER_DOWNSTREAM_BASELINE_STRENGTH)
		var downstream_baseline_with_margins := WaterHelperMethods.add_margins(downstream_baseline, flowmap_resolution, margin, _steps)
		downstream_baseline_with_margins_texture = ImageTexture.create_from_image(downstream_baseline_with_margins)
	var blank_support_with_margins := WaterHelperMethods.add_margins(_create_blank_support_source_image(int(flowmap_resolution)), flowmap_resolution, margin, _steps)
	var blank_support_with_margins_texture := ImageTexture.create_from_image(blank_support_with_margins)

	# Create correctly tiling noise for A channel
	var noise_texture := load(FLOW_OFFSET_NOISE_TEXTURE_PATH) as Texture2D
	var noise_with_margin_size := float(_uv2_sides + 2) * (float(noise_texture.get_width()) / float(_uv2_sides))
	var noise_with_tiling := Image.create(int(noise_with_margin_size), int(noise_with_margin_size), false, Image.FORMAT_RGB8)
	var noise_image := noise_texture.get_image()
	var slice_width := float(noise_texture.get_width()) / float(_uv2_sides)
	for x in _uv2_sides:
		noise_with_tiling.blend_rect(noise_image, Rect2i(0, 0, int(slice_width), noise_texture.get_height()), Vector2i(int(slice_width + float(x) * slice_width), int(slice_width - (noise_texture.get_width() / 2.0))))
		noise_with_tiling.blend_rect(noise_image, Rect2i(0, 0, int(slice_width), noise_texture.get_height()), Vector2i(int(slice_width + float(x) * slice_width), int(slice_width + (noise_texture.get_width() / 2.0))))
	var tiled_noise := ImageTexture.create_from_image(noise_with_tiling)

	# Create renderer
	var renderer_instance = _filter_renderer.instantiate()
	if renderer_instance == null:
		push_warning("Waterways: River Flow & Foam bake failed because the filter renderer could not be instantiated.")
		_finish_flowmap_bake_after_failure()
		return

	self.add_child(renderer_instance)

	var flow_pressure_blur_amount = 0.04 / float(_uv2_sides) * flowmap_resolution
	var dilate_amount = baking_dilate / float(_uv2_sides) 
	var flowmap_blur_amount = baking_flowmap_blur / float(_uv2_sides) * flowmap_resolution
	var foam_offset_amount = baking_foam_offset / float(_uv2_sides)
	var foam_blur_amount = baking_foam_blur / float(_uv2_sides) * flowmap_resolution
	
	var support_fallback_applied := not support_fallback_reason.is_empty()
	var run_collision_support_filters := not support_fallback_applied
	var primary_flow_map: Texture2D = null
	var blurred_foam_map: Texture2D = blank_support_with_margins_texture
	var blurred_flow_pressure_map: Texture2D = blank_support_with_margins_texture
	var dilated_texture: Texture2D = blank_support_with_margins_texture
	if run_collision_support_filters:
		var collision_with_margins_image := WaterHelperMethods.add_margins(image, flowmap_resolution, margin, _steps)
		var collision_with_margins := ImageTexture.create_from_image(collision_with_margins_image)
		var flow_pressure_map = await renderer_instance.apply_flow_pressure(collision_with_margins, flowmap_resolution, _uv2_sides + 2.0)
		if not _filter_output_is_valid(flow_pressure_map, "flow pressure", renderer_instance):
			return
		blurred_flow_pressure_map = await renderer_instance.apply_vertical_blur(flow_pressure_map, flow_pressure_blur_amount, flowmap_resolution)
		if not _filter_output_is_valid(blurred_flow_pressure_map, "blurred flow pressure", renderer_instance):
			return
		dilated_texture = await renderer_instance.apply_dilate(collision_with_margins, dilate_amount, 0.0, flowmap_resolution)
		if not _filter_output_is_valid(dilated_texture, "dilated collision map", renderer_instance):
			return
		var normal_map = await renderer_instance.apply_normal(dilated_texture, flowmap_resolution)
		if not _filter_output_is_valid(normal_map, "normal map", renderer_instance):
			return
		var flow_map = await renderer_instance.apply_normal_to_flow(normal_map, flowmap_resolution)
		if not _filter_output_is_valid(flow_map, "flow map", renderer_instance):
			return
		var blurred_flow_map = await renderer_instance.apply_blur(flow_map, flowmap_blur_amount, flowmap_resolution)
		if not _filter_output_is_valid(blurred_flow_map, "blurred flow map", renderer_instance):
			return
		var foam_map = await renderer_instance.apply_foam(dilated_texture, foam_offset_amount, baking_foam_cutoff, flowmap_resolution)
		if not _filter_output_is_valid(foam_map, "foam map", renderer_instance):
			return
		blurred_foam_map = await renderer_instance.apply_blur(foam_map, foam_blur_amount, flowmap_resolution)
		if not _filter_output_is_valid(blurred_foam_map, "blurred foam map", renderer_instance):
			return
		primary_flow_map = blurred_flow_map
	if downstream_baseline_with_margins_texture != null:
		primary_flow_map = downstream_baseline_with_margins_texture
	if primary_flow_map == null:
		push_warning("Waterways: River Flow & Foam bake failed because no primary flow map was available for behavior " + generation_behavior + ".")
		_cleanup_bake_renderer(renderer_instance)
		_finish_flowmap_bake_after_failure()
		return
	if support_fallback_applied:
		_print_curve_support_fallback_notice(generation_behavior, support_fallback_reason)
	var flow_foam_noise_img = await renderer_instance.apply_combine(primary_flow_map, primary_flow_map, blurred_foam_map, tiled_noise)
	if not _filter_output_is_valid(flow_foam_noise_img, "combined flow/foam/noise map", renderer_instance):
		return
	var dist_pressure_img = await renderer_instance.apply_combine(dilated_texture, blurred_flow_pressure_map)
	if not _filter_output_is_valid(dist_pressure_img, "combined distance/pressure map", renderer_instance):
		return
	
	_cleanup_bake_renderer(renderer_instance)
	
	var flow_foam_noise_result: Image = flow_foam_noise_img.get_image()
	var dist_pressure_result: Image = dist_pressure_img.get_image()
	var crop_rect := Rect2i(margin, margin, int(flowmap_resolution), int(flowmap_resolution))
	# Filters and combine passes can leave meaningful-looking RG in unused atlas cells.
	# Clear only the source-region unused tiles so occupied seam margins stay intact.
	WaterHelperMethods.neutralize_unused_uv2_atlas_flow_rg(flow_foam_noise_result, _uv2_sides, _steps, crop_rect)
	var foam_support_reduced := false
	var pressure_support_reduced := false
	if _uses_downstream_baseline_generation(generation_behavior) and not support_fallback_applied:
		foam_support_reduced = _reduce_flat_occupied_foam_support(flow_foam_noise_result, crop_rect)
		pressure_support_reduced = _reduce_flat_occupied_pressure_support(dist_pressure_result, crop_rect)
	var source_texture_size := Vector2i(int(flowmap_resolution), int(flowmap_resolution))
	var padded_texture_size := Vector2i(flow_foam_noise_result.get_width(), flow_foam_noise_result.get_height())
	var sampled_flow_foam_noise_result: Image = flow_foam_noise_result.get_region(crop_rect)
	var sampled_dist_pressure_result: Image = dist_pressure_result.get_region(crop_rect)
	if not support_fallback_applied:
		_warn_if_bake_channels_flat(sampled_flow_foam_noise_result, "foam map B", [2], PackedStringArray(["B"]))
		_warn_if_bake_channels_flat(sampled_dist_pressure_result, "distance/pressure RG", [0, 1], PackedStringArray(["R", "G"]))
	var flow_vector_diagnostics := WaterHelperMethods.get_uv2_atlas_decoded_flow_vector_stats(
		flow_foam_noise_result,
		_uv2_sides,
		_steps,
		crop_rect,
		WaterHelperMethods.FLOW_VECTOR_NEAR_NEUTRAL_THRESHOLD
	)
	_print_river_flow_vector_diagnostics(flow_vector_diagnostics)
	_warn_if_bake_flow_vectors_near_neutral(flow_vector_diagnostics)
	
	# River shaders remap UV2 into the center of the margin-padded bake atlas.
	# Keep the shader-facing textures padded to match the original Waterways layout.
	flow_foam_noise = ImageTexture.create_from_image(flow_foam_noise_result)
	dist_pressure = ImageTexture.create_from_image(dist_pressure_result)
	var bake_diagnostics := {
		"collision_probe_skipped": collision_probe_skipped,
		"collision_support_filters_ran": run_collision_support_filters,
		"support_fallback_applied": support_fallback_applied,
		"support_fallback_reason": support_fallback_reason,
		"collision_stats": collision_stats.duplicate(true)
	}
	_write_bake_data(padded_texture_size, source_texture_size, crop_rect, flow_vector_diagnostics, generation_behavior, foam_support_reduced, pressure_support_reduced, bake_diagnostics)
	var storage_result := WaterHelperMethods.save_river_bake_data(self, bake_data)
	_apply_bake_data()
	
	set_materials("i_flowmap", flow_foam_noise)
	set_materials("i_distmap", dist_pressure)
	set_materials("i_valid_flowmap", true)
	set_materials("i_uv2_sides", _uv2_sides)
	valid_flowmap = true;
	_clear_flowmap_bake_request()
	emit_signal("progress_notified", 100.0, "finished")
	_print_bake_save_notice(padded_texture_size, storage_result)
	update_configuration_warnings()


func _filter_output_is_valid(texture: Texture2D, label: String, renderer_instance: Node) -> bool:
	if texture != null and texture.get_width() > 0 and texture.get_height() > 0:
		return true
	push_warning("Waterways: River Flow & Foam bake failed while generating " + label + ". The bake was aborted and temporary renderer nodes were cleaned up.")
	_cleanup_bake_renderer(renderer_instance)
	_finish_flowmap_bake_after_failure()
	return false


func _cleanup_bake_renderer(renderer_instance: Node) -> void:
	if renderer_instance == null:
		return
	if renderer_instance.get_parent() != null:
		renderer_instance.get_parent().remove_child(renderer_instance)
	renderer_instance.queue_free()


func _finish_flowmap_bake_after_failure() -> void:
	_clear_flowmap_bake_request()
	emit_signal("progress_notified", 100.0, "finished")
	update_configuration_warnings()


func _create_blank_support_source_image(resolution: int) -> Image:
	var safe_resolution := maxi(1, resolution)
	var image := Image.create(safe_resolution, safe_resolution, false, Image.FORMAT_RGBA8)
	image.fill(Color(RIVER_BLANK_SUPPORT_VALUE, RIVER_BLANK_SUPPORT_VALUE, RIVER_BLANK_SUPPORT_VALUE, 1.0))
	return image


func _get_collision_map_stats(image: Image) -> Dictionary:
	var total_pixels := 0
	var hit_pixels := 0
	if image != null and not image.is_empty():
		total_pixels = image.get_width() * image.get_height()
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x, y).r > 0.5:
					hit_pixels += 1
	var hit_percent := 0.0
	if total_pixels > 0:
		hit_percent = 100.0 * float(hit_pixels) / float(total_pixels)
	return {
		"hit_pixel_count": hit_pixels,
		"total_pixel_count": total_pixels,
		"hit_pixel_percent": hit_percent
	}


func _warn_if_collision_map_empty(image: Image, generation_behavior: String, support_fallback_reason: String = "") -> void:
	if image == null or image.is_empty():
		push_warning("Waterways: River collision bake produced no readable collision image.")
		return
	var stats := _get_collision_map_stats(image)
	var hit_pixels := int(stats.get("hit_pixel_count", 0))
	var total_pixels := int(stats.get("total_pixel_count", 0))
	if hit_pixels == 0:
		if _uses_downstream_baseline_generation(generation_behavior) and not support_fallback_reason.is_empty():
			push_warning("Waterways: River collision bake found no collider pixels; generated curve downstream flow will use exact blank collision support maps for reduced foam, pressure, and bank detail.")
		else:
			push_warning("Waterways: River collision bake found no collider pixels. Check baking raycast layers, collider placement, and raycast distance.")
	elif hit_pixels == total_pixels:
		push_warning("Waterways: River collision bake hit every pixel, so generated flow/foam maps may be flat. Use non-uniform bake geometry for visual validation.")


func _print_curve_support_fallback_notice(generation_behavior: String, support_fallback_reason: String) -> void:
	var detail := "collision support was skipped"
	match support_fallback_reason:
		"curve_only":
			detail = "Curve Only behavior skips collision probing"
		"baking_raycast_layers_zero":
			detail = "baking_raycast_layers is 0"
		"no_collision_hits":
			detail = "no collider pixels were hit"
	print(
		"Waterways: River Flow & Foam bake used curve downstream flow with blank support maps (",
		detail,
		") for behavior ",
		generation_behavior,
		"."
	)


func _warn_if_bake_channels_flat(image: Image, label: String, channel_indices: Array, channel_names: PackedStringArray) -> void:
	if image == null or image.is_empty() or channel_indices.is_empty():
		push_warning("Waterways: River bake produced no readable " + label + " image.")
		return
	var min_values := []
	var max_values := []
	var avg_values := []
	for channel_index in channel_indices.size():
		min_values.append(INF)
		max_values.append(-INF)
		avg_values.append(0.0)
	var total_pixels := max(1, image.get_width() * image.get_height())
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			for channel_index in channel_indices.size():
				var value := _get_color_channel(pixel, int(channel_indices[channel_index]))
				min_values[channel_index] = min(float(min_values[channel_index]), value)
				max_values[channel_index] = max(float(max_values[channel_index]), value)
				avg_values[channel_index] = float(avg_values[channel_index]) + value
	var channel_notes := PackedStringArray()
	var summaries := PackedStringArray()
	for channel_index in channel_indices.size():
		var channel_name := str(channel_indices[channel_index])
		if channel_index < channel_names.size():
			channel_name = channel_names[channel_index]
		var min_value := float(min_values[channel_index])
		var max_value := float(max_values[channel_index])
		var avg_value := float(avg_values[channel_index]) / float(total_pixels)
		var channel_range := max_value - min_value
		summaries.append("%s %.3f..%.3f avg %.3f" % [channel_name, min_value, max_value, avg_value])
		if channel_range <= BAKE_CHANNEL_FLAT_EPSILON:
			channel_notes.append(channel_name + " flat")
		elif channel_range <= BAKE_CHANNEL_LOW_CONTRAST_EPSILON:
			channel_notes.append(channel_name + " low contrast")
		if min_value >= 1.0 - BAKE_CHANNEL_SATURATION_EPSILON:
			channel_notes.append(channel_name + " near white")
		elif max_value <= BAKE_CHANNEL_SATURATION_EPSILON:
			channel_notes.append(channel_name + " near black")
	if not channel_notes.is_empty():
		push_warning("Waterways: Generated " + label + " has limited debug contrast (" + ", ".join(summaries) + "; " + ", ".join(channel_notes) + "). Debug views may appear as a solid color until the bake input and filter settings produce varied data.")


func _get_color_channel(color: Color, channel_index: int) -> float:
	match channel_index:
		0:
			return color.r
		1:
			return color.g
		2:
			return color.b
		3:
			return color.a
		_:
			return 0.0


func _print_river_flow_vector_diagnostics(flow_vector_diagnostics: Dictionary) -> void:
	if flow_vector_diagnostics.is_empty():
		return
	var occupied_stats: Dictionary = flow_vector_diagnostics.get("occupied", {})
	var unused_stats: Dictionary = flow_vector_diagnostics.get("unused", {})
	print(
		"Waterways: River decoded flow-vector diagnostics: ",
		WaterHelperMethods.format_decoded_flow_vector_stats("occupied_source_tiles", occupied_stats),
		"; ",
		WaterHelperMethods.format_decoded_flow_vector_stats("unused_source_tiles", unused_stats),
		"."
	)


func _warn_if_bake_flow_vectors_near_neutral(flow_vector_diagnostics: Dictionary) -> void:
	if flow_vector_diagnostics.is_empty():
		return
	var occupied_stats: Dictionary = flow_vector_diagnostics.get("occupied", {})
	if typeof(occupied_stats) != TYPE_DICTIONARY or not bool(occupied_stats.get("valid", false)):
		return
	var near_neutral_percent := float(occupied_stats.get("near_neutral_percent", 0.0))
	var active_pixels := int(occupied_stats.get("active_pixel_count", 0))
	if active_pixels == 0 or near_neutral_percent >= 95.0:
		push_warning(
			"Waterways: Generated River occupied flow vectors are mostly near-neutral ("
			+ WaterHelperMethods.format_decoded_flow_vector_stats("occupied_source_tiles", occupied_stats)
			+ "). This usually means the collision-derived bake has no useful downstream interior direction."
		)


func _uses_downstream_baseline_generation(generation_behavior: String) -> bool:
	return generation_behavior == RIVER_FLOW_GENERATION_BEHAVIOR_DOWNSTREAM_BASELINE or generation_behavior == RIVER_FLOW_GENERATION_BEHAVIOR_CURVE_ONLY


func _is_curve_only_generation(generation_behavior: String) -> bool:
	return generation_behavior == RIVER_FLOW_GENERATION_BEHAVIOR_CURVE_ONLY


func _requires_collision_raycast_layers(generation_behavior: String) -> bool:
	return generation_behavior == RIVER_FLOW_GENERATION_BEHAVIOR_LEGACY_COLLISION_ONLY


func _get_generation_mode_label(generation_behavior: String) -> String:
	match generation_behavior:
		RIVER_FLOW_GENERATION_BEHAVIOR_CURVE_ONLY:
			return "curve_only"
		RIVER_FLOW_GENERATION_BEHAVIOR_LEGACY_COLLISION_ONLY:
			return "collision_legacy"
		_:
			return "curve_collision_modifiers"


func _get_bake_source_kind(generation_behavior: String) -> String:
	match generation_behavior:
		RIVER_FLOW_GENERATION_BEHAVIOR_CURVE_ONLY:
			return RiverBakeDataResource.SOURCE_KIND_CURVE_ONLY_BAKE
		RIVER_FLOW_GENERATION_BEHAVIOR_LEGACY_COLLISION_ONLY:
			return RiverBakeDataResource.SOURCE_KIND_SPLINE_COLLISION_BAKE
		_:
			return RiverBakeDataResource.SOURCE_KIND_CURVE_COLLISION_MODIFIERS_BAKE


func _reduce_flat_occupied_foam_support(image: Image, content_rect: Rect2i) -> bool:
	if not _soften_flat_occupied_support_channel(image, content_rect, 2, RIVER_FLAT_FOAM_SUPPORT_VALUE):
		return false
	push_warning(
		"Waterways: River collision-derived foam support is saturated across occupied tiles, so the default downstream bake softened foam support to avoid full-width foam bands. "
		+ "Use legacy collision-only comparison if you need the old support texture."
	)
	return true


func _reduce_flat_occupied_pressure_support(image: Image, content_rect: Rect2i) -> bool:
	if not _soften_flat_occupied_support_channel(image, content_rect, 1, RIVER_FLAT_PRESSURE_SUPPORT_VALUE):
		return false
	push_warning(
		"Waterways: River collision-derived pressure support is saturated across occupied tiles, so the default downstream bake softened pressure support to keep generated flow-pattern strength usable. "
		+ "Use legacy collision-only comparison if you need the old support texture."
	)
	return true


func _soften_flat_occupied_support_channel(image: Image, content_rect: Rect2i, channel_index: int, channel_value: float) -> bool:
	if image == null or image.is_empty():
		return false
	var stats := _get_occupied_channel_stats(image, content_rect, channel_index)
	if stats.is_empty():
		return false
	var average := float(stats.get("average", 0.0))
	var saturated_percent := float(stats.get("saturated_percent", 0.0))
	if average < 0.95 or saturated_percent < 90.0:
		return false
	_set_occupied_channel_value(image, content_rect, channel_index, channel_value)
	return true


func _get_occupied_channel_stats(image: Image, content_rect: Rect2i, channel_index: int) -> Dictionary:
	var source_rect := _clamp_rect_to_image(image, content_rect)
	if source_rect.size.x <= 0 or source_rect.size.y <= 0:
		return {}
	var sum := 0.0
	var min_value := INF
	var max_value := -INF
	var saturated_pixels := 0
	var sampled_pixels := 0
	for step_index in _steps:
		var tile_rect := WaterHelperMethods.get_uv2_atlas_tile_rect(step_index, _uv2_sides, source_rect)
		for y in tile_rect.size.y:
			for x in tile_rect.size.x:
				var value := _get_color_channel(image.get_pixel(tile_rect.position.x + x, tile_rect.position.y + y), channel_index)
				sum += value
				min_value = min(min_value, value)
				max_value = max(max_value, value)
				if value >= 0.95:
					saturated_pixels += 1
				sampled_pixels += 1
	if sampled_pixels <= 0:
		return {}
	return {
		"sampled_pixel_count": sampled_pixels,
		"min": min_value,
		"max": max_value,
		"average": sum / float(sampled_pixels),
		"saturated_percent": 100.0 * float(saturated_pixels) / float(sampled_pixels)
	}


func _set_occupied_channel_value(image: Image, content_rect: Rect2i, channel_index: int, channel_value: float) -> void:
	var source_rect := _clamp_rect_to_image(image, content_rect)
	for step_index in _steps:
		var tile_rect := WaterHelperMethods.get_uv2_atlas_tile_rect(step_index, _uv2_sides, source_rect)
		for y in tile_rect.size.y:
			for x in tile_rect.size.x:
				var pixel_position := Vector2i(tile_rect.position.x + x, tile_rect.position.y + y)
				var color := image.get_pixelv(pixel_position)
				match channel_index:
					0:
						color.r = channel_value
					1:
						color.g = channel_value
					2:
						color.b = channel_value
					3:
						color.a = channel_value
				image.set_pixelv(pixel_position, color)


func _clamp_rect_to_image(image: Image, rect: Rect2i) -> Rect2i:
	if image == null or image.is_empty():
		return Rect2i()
	var image_size := image.get_size()
	if rect.size.x <= 0 or rect.size.y <= 0:
		return Rect2i(Vector2i.ZERO, image_size)
	var x0: int = clampi(rect.position.x, 0, image_size.x)
	var y0: int = clampi(rect.position.y, 0, image_size.y)
	var x1: int = clampi(rect.position.x + rect.size.x, x0, image_size.x)
	var y1: int = clampi(rect.position.y + rect.size.y, y0, image_size.y)
	return Rect2i(x0, y0, maxi(0, x1 - x0), maxi(0, y1 - y0))


func _has_unsaved_generated_textures() -> bool:
	if flow_foam_noise == null and dist_pressure == null:
		return false
	return not WaterHelperMethods.has_external_bake_path(bake_data)


func _is_unsaved_texture_resource(texture: Texture2D) -> bool:
	if texture == null:
		return false
	var path := texture.resource_path
	return path.is_empty() or path.find("::") != -1


func _print_bake_save_notice(texture_size: Vector2i, storage_result: Dictionary = {}) -> void:
	if not Engine.is_editor_hint():
		return
	if bool(storage_result.get("saved", false)):
		print(
			"Waterways: River Flow & Foam Map saved to external bake resource ",
			String(storage_result.get("path", "")),
			". Save the scene once so F6/export serializes this reference. flow_foam_noise=",
			_texture_size_label(flow_foam_noise, texture_size),
			" dist_pressure=",
			_texture_size_label(dist_pressure, texture_size),
			" uv2_sides=",
			_uv2_sides,
			"."
		)
		return
	if bool(storage_result.get("requires_saved_scene", false)):
		print(
			"Waterways: River Flow & Foam Map regenerated in editor memory because this scene has no saved path. Save the scene, then rebake to create scene-owned external .res storage before F6/export. flow_foam_noise=",
			_texture_size_label(flow_foam_noise, texture_size),
			" dist_pressure=",
			_texture_size_label(dist_pressure, texture_size),
			" uv2_sides=",
			_uv2_sides,
			"."
		)
		return
	var error_code := int(storage_result.get("error", OK))
	if error_code != OK:
		push_warning("Waterways: River Flow & Foam Map regenerated, but external .res storage failed. " + String(storage_result.get("message", "")) + " Error code: " + str(error_code) + ".")
		return
	print(
		"Waterways: River Flow & Foam Map regenerated in editor memory. Save the scene before F6/export so runtime uses this data. flow_foam_noise=",
		_texture_size_label(flow_foam_noise, texture_size),
		" dist_pressure=",
		_texture_size_label(dist_pressure, texture_size),
		" uv2_sides=",
		_uv2_sides,
		"."
	)


func _texture_size_label(texture: Texture2D, fallback_size: Vector2i = Vector2i.ZERO) -> String:
	if texture != null:
		return str(texture.get_width()) + "x" + str(texture.get_height())
	if fallback_size != Vector2i.ZERO:
		return str(fallback_size.x) + "x" + str(fallback_size.y)
	return "<none>"


func validate_data_textures() -> void:
	var failures := []
	var notes := []
	_append_texture_data_validation("flow_foam_noise", flow_foam_noise, true, failures, notes)
	_append_texture_data_validation("dist_pressure", dist_pressure, false, failures, notes)
	if failures.is_empty():
		print("RIVER_DATA_TEXTURE_TEST: " + "; ".join(notes))
	else:
		push_warning("RIVER_DATA_TEXTURE_TEST: " + "; ".join(failures) + " | " + "; ".join(notes))


func _append_texture_data_validation(label: String, texture: Texture2D, expect_neutral_flow: bool, failures: Array, notes: Array) -> void:
	if texture == null:
		failures.append(label + " is not assigned")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		failures.append(label + " has no readable image data")
		return
	var size := image.get_size()
	notes.append("%s size=%dx%d" % [label, size.x, size.y])
	_append_data_texture_import_validation(label, texture, failures, notes)
	if expect_neutral_flow:
		_append_neutral_flow_validation(label, image, texture.resource_path, failures, notes)
		_append_flow_vector_stats_validation(label, image, notes)
		_append_alpha_phase_noise_validation(label, image, notes)


func _append_data_texture_import_validation(label: String, texture: Texture2D, failures: Array, notes: Array) -> void:
	var path := texture.resource_path
	var generated_bake_source_kind := _get_generated_bake_source_kind_for_texture(label, texture)
	if path.is_empty() or not generated_bake_source_kind.is_empty():
		var source_note := label + " source=generated/resource-owned"
		if not generated_bake_source_kind.is_empty():
			source_note += " source_kind=" + generated_bake_source_kind
		notes.append(source_note)
		return
	notes.append(label + " source=" + path)
	if not path.begins_with("res://"):
		failures.append(label + " uses a non-project texture path")
		return
	var import_path := path + ".import"
	if not FileAccess.file_exists(import_path):
		failures.append(label + " has no .import settings file")
		return
	var import_text := FileAccess.get_file_as_string(import_path)
	if import_text.find("compress/mode=0") == -1:
		failures.append(label + " import should use lossless/uncompressed texture data (compress/mode=0)")
	if import_text.find("compress/normal_map=0") == -1:
		failures.append(label + " import should not be treated as a normal map")
	if import_text.find("mipmaps/generate=true") != -1:
		failures.append(label + " import has mipmaps enabled before neutral-flow/mask stability is validated")
	if import_text.find("\"vram_texture\": true") != -1 or import_text.find("path.s3tc=") != -1:
		failures.append(label + " import uses VRAM/block-compressed data")


func _get_generated_bake_source_kind_for_texture(label: String, texture: Texture2D) -> String:
	if texture == null or bake_data == null:
		return ""
	var source_kind := String(bake_data.get("source_kind"))
	if not source_kind.begins_with("generated_"):
		return ""
	var stored_texture := bake_data.get(label) as Texture2D
	if stored_texture == texture:
		return source_kind
	var bake_path := bake_data.resource_path
	var texture_path := texture.resource_path
	if not bake_path.is_empty() and texture_path.begins_with(bake_path + "::"):
		return source_kind
	return ""


func _append_neutral_flow_validation(label: String, image: Image, texture_path: String, failures: Array, notes: Array) -> void:
	var size := image.get_size()
	var step := max(1, int(ceil(float(max(size.x, size.y)) / 128.0)))
	var best_error := INF
	var best_color := Color()
	var best_pixel := Vector2i.ZERO
	for y in range(0, size.y, step):
		for x in range(0, size.x, step):
			var color := image.get_pixel(x, y)
			var error: float = abs(color.r - 0.5) + abs(color.g - 0.5)
			if error < best_error:
				best_error = error
				best_color = color
				best_pixel = Vector2i(x, y)
	notes.append("%s closest_neutral_rg=(%.4f, %.4f) pixel=(%d,%d)" % [label, best_color.r, best_color.g, best_pixel.x, best_pixel.y])
	var neutral_tolerance := 0.01
	if best_error > neutral_tolerance and not texture_path.is_empty():
		failures.append(label + " imported flow map did not preserve or include a sampled neutral (0.5, 0.5) flow value")


func _append_flow_vector_stats_validation(label: String, image: Image, notes: Array) -> void:
	var content_rect := _get_bake_content_rect_for_image(image)
	var source_stats := WaterHelperMethods.get_decoded_flow_vector_stats(
		image,
		content_rect,
		WaterHelperMethods.FLOW_VECTOR_NEAR_NEUTRAL_THRESHOLD
	)
	notes.append(WaterHelperMethods.format_decoded_flow_vector_stats(label + " source_rect", source_stats))
	var atlas_stats := WaterHelperMethods.get_uv2_atlas_decoded_flow_vector_stats(
		image,
		_get_bake_uv2_sides(),
		_calculate_step_count(),
		content_rect,
		WaterHelperMethods.FLOW_VECTOR_NEAR_NEUTRAL_THRESHOLD
	)
	var occupied_stats: Dictionary = atlas_stats.get("occupied", {})
	var unused_stats: Dictionary = atlas_stats.get("unused", {})
	notes.append(WaterHelperMethods.format_decoded_flow_vector_stats(label + " occupied_tiles", occupied_stats))
	notes.append(WaterHelperMethods.format_decoded_flow_vector_stats(label + " unused_tiles", unused_stats))


func _get_bake_content_rect_for_image(image: Image) -> Rect2i:
	if image == null or image.is_empty():
		return Rect2i()
	var content_rect := Rect2i(Vector2i.ZERO, image.get_size())
	if bake_data != null:
		var stored_rect = bake_data.get("content_rect")
		if typeof(stored_rect) == TYPE_RECT2I and stored_rect.size.x > 0 and stored_rect.size.y > 0:
			content_rect = stored_rect
	return content_rect


func _get_bake_uv2_sides() -> int:
	var uv2_sides := _uv2_sides
	if bake_data != null:
		var stored_uv2_sides = bake_data.get("uv2_sides")
		if stored_uv2_sides != null:
			uv2_sides = int(stored_uv2_sides)
	return max(1, uv2_sides)


func _append_alpha_phase_noise_validation(label: String, image: Image, notes: Array) -> void:
	var size := image.get_size()
	var step := max(1, int(ceil(float(max(size.x, size.y)) / 128.0)))
	var alpha_min := INF
	var alpha_max := -INF
	var samples := 0
	for y in range(0, size.y, step):
		for x in range(0, size.x, step):
			var alpha := image.get_pixel(x, y).a
			alpha_min = min(alpha_min, alpha)
			alpha_max = max(alpha_max, alpha)
			samples += 1
	var alpha_range: float = alpha_max - alpha_min
	var alpha_state := "varied" if alpha_range > 0.001 else "flat"
	notes.append("%s alpha_min=%.4f alpha_max=%.4f alpha_range=%.4f alpha_state=%s samples=%d" % [label, alpha_min, alpha_max, alpha_range, alpha_state, samples])


func validate_filter_renderer() -> void:
	var failures := []
	var notes := []
	if not is_inside_tree():
		push_warning("FILTER_RENDERER_TEST: River must be inside the edited scene tree")
		return
	var renderer_instance = _filter_renderer.instantiate()
	add_child(renderer_instance)
	await get_tree().process_frame
	var source_texture := _make_filter_validation_texture()
	var combine_result: Texture2D = await renderer_instance.apply_combine(source_texture, source_texture, source_texture, source_texture)
	_append_filter_texture_validation("combine", combine_result, failures, notes)
	var dot_result: Texture2D = await renderer_instance.apply_dotproduct(source_texture, 8.0)
	_append_filter_texture_validation("dotproduct", dot_result, failures, notes)
	var flow_pressure_result: Texture2D = await renderer_instance.apply_flow_pressure(source_texture, 8.0, 2.0)
	_append_filter_texture_validation("flow_pressure", flow_pressure_result, failures, notes)
	var foam_result: Texture2D = await renderer_instance.apply_foam(source_texture, 0.1, 0.9, 8.0)
	_append_filter_texture_validation("foam", foam_result, failures, notes)
	var blur_result: Texture2D = await renderer_instance.apply_blur(source_texture, 0.0, 8.0)
	_append_filter_texture_validation("blur_zero", blur_result, failures, notes)
	var vertical_blur_result: Texture2D = await renderer_instance.apply_vertical_blur(source_texture, 0.0, 8.0)
	_append_filter_texture_validation("vertical_blur_zero", vertical_blur_result, failures, notes)
	var normal_result: Texture2D = await renderer_instance.apply_normal(source_texture, 0.0)
	_append_filter_texture_validation("normal_zero_size", normal_result, failures, notes)
	var normal_to_flow_result: Texture2D = await renderer_instance.apply_normal_to_flow(normal_result, 0.0)
	_append_filter_texture_validation("normal_to_flow", normal_to_flow_result, failures, notes)
	var dilate_result: Texture2D = await renderer_instance.apply_dilate(source_texture, 0.0, 0.0, 0.0, source_texture)
	_append_filter_texture_validation("dilate_zero", dilate_result, failures, notes)
	var dilate_default_fill_result: Texture2D = await renderer_instance.apply_dilate(source_texture, 0.0, 1.0, 0.0)
	_append_filter_texture_validation("dilate_default_fill", dilate_default_fill_result, failures, notes)
	var active_dilate_fill_texture = renderer_instance.filter_mat.get_shader_parameter("color_texture")
	if active_dilate_fill_texture == null:
		failures.append("dilate default fill did not assign a fallback color texture")
	elif active_dilate_fill_texture == source_texture:
		failures.append("dilate default fill reused the previous color_texture")
	else:
		notes.append("dilate_default_fill_texture_reset=true")
	_cleanup_bake_renderer(renderer_instance)
	if failures.is_empty():
		print("FILTER_RENDERER_TEST: " + "; ".join(notes))
	else:
		push_warning("FILTER_RENDERER_TEST: " + "; ".join(failures) + " | " + "; ".join(notes))


func _make_filter_validation_texture() -> Texture2D:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var xf := float(x) / float(max(1, image.get_width() - 1))
			var yf := float(y) / float(max(1, image.get_height() - 1))
			var checker := 1.0 if ((x + y) % 2 == 0) else 0.0
			image.set_pixel(x, y, Color(xf, yf, checker, 1.0))
	return ImageTexture.create_from_image(image)


func _append_filter_texture_validation(label: String, texture: Texture2D, failures: Array, notes: Array) -> void:
	if texture == null:
		failures.append(label + " returned null texture")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		failures.append(label + " returned no readable image data")
		return
	var size := image.get_size()
	if size.x <= 0 or size.y <= 0:
		failures.append(label + " returned invalid size")
		return
	var invalid_samples := 0
	for sample_point in [Vector2i(0, 0), Vector2i(size.x / 2, size.y / 2), Vector2i(size.x - 1, size.y - 1)]:
		var color := image.get_pixelv(sample_point)
		if is_nan(color.r) or is_nan(color.g) or is_nan(color.b) or is_nan(color.a) or is_inf(color.r) or is_inf(color.g) or is_inf(color.b) or is_inf(color.a):
			invalid_samples += 1
	if invalid_samples > 0:
		failures.append(label + " returned invalid numeric samples")
	notes.append("%s=%dx%d" % [label, size.x, size.y])


func _ensure_bake_data() -> Resource:
	if bake_data == null:
		_bake_data_resource = RiverBakeDataResource.new()
	return bake_data


func _apply_bake_data() -> void:
	if bake_data == null:
		return
	flow_foam_noise = bake_data.get("flow_foam_noise") as Texture2D
	dist_pressure = bake_data.get("dist_pressure") as Texture2D
	var resource_uv2_sides = bake_data.get("uv2_sides")
	if resource_uv2_sides != null:
		_uv2_sides = max(1, int(resource_uv2_sides))
	set_materials("i_flowmap", flow_foam_noise)
	set_materials("i_distmap", dist_pressure)
	set_materials("i_uv2_sides", _uv2_sides)
	var textures_are_present := flow_foam_noise != null and dist_pressure != null
	_set_valid_flowmap(textures_are_present and _bake_data_matches_current_source())


func _write_bake_data(texture_size: Vector2i, source_texture_size: Vector2i, content_rect: Rect2i, flow_vector_diagnostics: Dictionary = {}, generation_behavior: String = RIVER_FLOW_GENERATION_BEHAVIOR_DOWNSTREAM_BASELINE, foam_support_reduced: bool = false, pressure_support_reduced: bool = false, bake_diagnostics: Dictionary = {}) -> void:
	var data := _ensure_bake_data()
	var texture_layout := RiverBakeDataResource.TEXTURE_LAYOUT_PADDED_UV2_ATLAS
	var sanitized_generation_behavior := _sanitize_bake_generation_behavior(generation_behavior)
	var source_kind := _get_bake_source_kind(sanitized_generation_behavior)
	var collision_stats: Dictionary = bake_diagnostics.get("collision_stats", {})
	var occupied_stats: Dictionary = flow_vector_diagnostics.get("occupied", {})
	var source_metadata := {
		"bake_revision": _make_bake_revision(),
		"generation_behavior": sanitized_generation_behavior,
		"generation_mode": _get_generation_mode_label(sanitized_generation_behavior),
		"downstream_baseline_applied": _uses_downstream_baseline_generation(sanitized_generation_behavior),
		"downstream_baseline_strength": RIVER_DOWNSTREAM_BASELINE_STRENGTH,
		"legacy_collision_only": sanitized_generation_behavior == RIVER_FLOW_GENERATION_BEHAVIOR_LEGACY_COLLISION_ONLY,
		"collision_hit_pixel_count": int(collision_stats.get("hit_pixel_count", 0)),
		"collision_total_pixel_count": int(collision_stats.get("total_pixel_count", 0)),
		"collision_hit_pixel_percent": float(collision_stats.get("hit_pixel_percent", 0.0)),
		"curve_baseline_pixel_count": int(occupied_stats.get("sampled_pixel_count", 0)) if _uses_downstream_baseline_generation(sanitized_generation_behavior) else 0,
		"collision_probe_skipped": bool(bake_diagnostics.get("collision_probe_skipped", false)),
		"collision_support_filters_ran": bool(bake_diagnostics.get("collision_support_filters_ran", false)),
		"support_fallback_applied": bool(bake_diagnostics.get("support_fallback_applied", false)),
		"support_fallback_reason": String(bake_diagnostics.get("support_fallback_reason", "")),
		"no_collider_curve_only_fallback": bool(bake_diagnostics.get("support_fallback_applied", false)),
		"blank_support_foam_value": RIVER_BLANK_SUPPORT_VALUE,
		"blank_support_dist_pressure": Vector2(RIVER_BLANK_SUPPORT_VALUE, RIVER_BLANK_SUPPORT_VALUE),
		"flat_foam_support_reduced": foam_support_reduced,
		"flat_foam_support_value": RIVER_FLAT_FOAM_SUPPORT_VALUE,
		"flat_pressure_support_reduced": pressure_support_reduced,
		"flat_pressure_support_value": RIVER_FLAT_PRESSURE_SUPPORT_VALUE,
		"near_neutral_threshold": WaterHelperMethods.FLOW_VECTOR_NEAR_NEUTRAL_THRESHOLD,
		"flow_vector_diagnostics": flow_vector_diagnostics.duplicate(true),
		"supported_future_source_kinds": PackedStringArray([
			"generated_spline_collision_bake",
			"generated_downstream_baseline_collision_bake",
			"generated_curve_collision_modifiers_bake",
			"generated_curve_only_bake",
			"imported_linear_data_map",
			"hand_painted_flow_map",
			"dcc_or_simulation_flow_map",
			"shore_distance_field",
			"terrain_slope_field",
			"obstacle_influence_field"
		])
	}
	if data.has_method("set_from_bake"):
		data.call(
			"set_from_bake",
			flow_foam_noise,
			dist_pressure,
			texture_size,
			_uv2_sides,
			_get_mesh_global_aabb(mesh_instance),
			_get_bake_settings(source_texture_size, texture_size, content_rect, texture_layout),
			source_texture_size,
			content_rect,
			texture_layout,
			source_kind,
			source_metadata,
			get_bake_source_signature()
		)
	if Engine.is_editor_hint():
		notify_property_list_changed()


func get_bake_source_signature() -> Dictionary:
	var points := []
	if curve != null:
		for point_index in curve.get_point_count():
			points.append({
				"position": _vector3_signature(curve.get_point_position(point_index)),
				"in": _vector3_signature(curve.get_point_in(point_index)),
				"out": _vector3_signature(curve.get_point_out(point_index)),
				"width": _signature_float(_get_width_for_point(point_index))
			})
	var step_count := _calculate_step_count()
	return {
		"version": RIVER_BAKE_SOURCE_SIGNATURE_VERSION,
		"curve_bake_interval": _signature_float(curve.bake_interval) if curve != null else 0.0,
		"points": points,
		"shape_step_length_divs": shape_step_length_divs,
		"shape_step_width_divs": shape_step_width_divs,
		"shape_smoothness": _signature_float(shape_smoothness),
		"baking_resolution": baking_resolution,
		"baking_raycast_distance": _signature_float(baking_raycast_distance),
		"baking_raycast_layers": baking_raycast_layers,
		"baking_dilate": _signature_float(baking_dilate),
		"baking_flowmap_blur": _signature_float(baking_flowmap_blur),
		"baking_foam_cutoff": _signature_float(baking_foam_cutoff),
		"baking_foam_offset": _signature_float(baking_foam_offset),
		"baking_foam_blur": _signature_float(baking_foam_blur),
		"bake_generation_behavior": _sanitize_bake_generation_behavior(bake_generation_behavior),
		"downstream_baseline_strength": _signature_float(RIVER_DOWNSTREAM_BASELINE_STRENGTH),
		"blank_support_value": _signature_float(RIVER_BLANK_SUPPORT_VALUE),
		"flat_foam_support_value": _signature_float(RIVER_FLAT_FOAM_SUPPORT_VALUE),
		"flat_pressure_support_value": _signature_float(RIVER_FLAT_PRESSURE_SUPPORT_VALUE),
		"near_neutral_threshold": _signature_float(WaterHelperMethods.FLOW_VECTOR_NEAR_NEUTRAL_THRESHOLD),
		"step_count": step_count,
		"uv2_sides": WaterHelperMethods.calculate_side(step_count)
	}


func _bake_data_matches_current_source() -> bool:
	var current_signature := get_bake_source_signature()
	if current_signature.is_empty():
		return false
	if bake_data.has_method("has_matching_source_signature"):
		return bool(bake_data.call("has_matching_source_signature", current_signature))
	var stored_signature = bake_data.get("source_signature")
	return typeof(stored_signature) == TYPE_DICTIONARY and not stored_signature.is_empty() and stored_signature == current_signature


func _set_valid_flowmap(value: bool) -> void:
	valid_flowmap = value
	set_materials("i_valid_flowmap", valid_flowmap)
	if is_inside_tree():
		update_configuration_warnings()


func _get_valid_flowmap_shader_state(default_value: bool) -> bool:
	var shader_value = null
	if _material != null:
		shader_value = _material.get_shader_parameter("i_valid_flowmap")
	if shader_value == null and _debug_material != null:
		shader_value = _debug_material.get_shader_parameter("i_valid_flowmap")
	if shader_value == null:
		return default_value
	return bool(shader_value)


func _on_geometry_property_changed(notify_river: bool) -> void:
	if _first_enter_tree:
		return
	_invalidate_generated_bake(true, notify_river)


func _on_bake_property_changed() -> void:
	if _first_enter_tree:
		return
	_invalidate_generated_bake(false, false)


func _invalidate_generated_bake(regenerate_geometry: bool, notify_river: bool) -> void:
	_set_valid_flowmap(false)
	if regenerate_geometry:
		_generate_river()
	if notify_river:
		emit_signal("river_changed")


func _set_baking_property(property_name: String, value: Variant) -> bool:
	match property_name:
		"baking_resolution":
			baking_resolution = int(value)
		"baking_raycast_distance":
			baking_raycast_distance = float(value)
		"baking_raycast_layers":
			baking_raycast_layers = int(value)
		"baking_dilate":
			baking_dilate = float(value)
		"baking_flowmap_blur":
			baking_flowmap_blur = float(value)
		"baking_foam_cutoff":
			baking_foam_cutoff = float(value)
		"baking_foam_offset":
			baking_foam_offset = float(value)
		"baking_foam_blur":
			baking_foam_blur = float(value)
		_:
			return false
	return true


func _get_baking_property(property_name: String) -> Variant:
	match property_name:
		"baking_resolution":
			return baking_resolution
		"baking_raycast_distance":
			return baking_raycast_distance
		"baking_raycast_layers":
			return baking_raycast_layers
		"baking_dilate":
			return baking_dilate
		"baking_flowmap_blur":
			return baking_flowmap_blur
		"baking_foam_cutoff":
			return baking_foam_cutoff
		"baking_foam_offset":
			return baking_foam_offset
		"baking_foam_blur":
			return baking_foam_blur
	return null


func _calculate_step_count() -> int:
	if curve == null:
		return 1
	var average_width := _get_average_width()
	return int(max(1.0, round(curve.get_baked_length() / average_width)))


func _signature_float(value: float) -> float:
	return snappedf(value, SOURCE_SIGNATURE_FLOAT_STEP)


func _vector3_signature(value: Vector3) -> Array:
	return [
		_signature_float(value.x),
		_signature_float(value.y),
		_signature_float(value.z)
	]


func _make_bake_revision() -> String:
	return str(Time.get_unix_time_from_system()) + ":" + str(Time.get_ticks_usec())


func _get_mesh_global_aabb(instance: MeshInstance3D) -> AABB:
	if instance == null:
		return AABB()
	return instance.global_transform * instance.get_aabb()


func _get_bake_settings(source_texture_size: Vector2i, texture_size: Vector2i, content_rect: Rect2i, texture_layout: String) -> Dictionary:
	return {
		"shape_step_length_divs": shape_step_length_divs,
		"shape_step_width_divs": shape_step_width_divs,
		"shape_smoothness": shape_smoothness,
		"baking_resolution": baking_resolution,
		"baking_raycast_distance": baking_raycast_distance,
		"baking_raycast_layers": baking_raycast_layers,
		"baking_dilate": baking_dilate,
		"baking_flowmap_blur": baking_flowmap_blur,
		"baking_foam_cutoff": baking_foam_cutoff,
		"baking_foam_offset": baking_foam_offset,
		"baking_foam_blur": baking_foam_blur,
		"bake_generation_behavior": _sanitize_bake_generation_behavior(bake_generation_behavior),
		"downstream_baseline_strength": RIVER_DOWNSTREAM_BASELINE_STRENGTH,
		"blank_support_value": RIVER_BLANK_SUPPORT_VALUE,
		"flat_foam_support_value": RIVER_FLAT_FOAM_SUPPORT_VALUE,
		"flat_pressure_support_value": RIVER_FLAT_PRESSURE_SUPPORT_VALUE,
		"near_neutral_threshold": WaterHelperMethods.FLOW_VECTOR_NEAR_NEUTRAL_THRESHOLD,
		"uv2_sides": _uv2_sides,
		"source_texture_size": source_texture_size,
		"texture_size": texture_size,
		"content_rect": content_rect,
		"texture_layout": texture_layout
	}


# Signal Methods
func properties_changed() -> void:
	emit_signal("river_changed")
