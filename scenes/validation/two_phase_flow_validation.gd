@tool
extends Node3D

const WaterHelperMethods = preload("res://addons/waterways/water_helper_methods.gd")

const SOURCE_TEXTURE_SIZE: int = 256
const DEBUG_NORMAL: int = 0
const VALIDATION_FLOW_SPEED: float = 2.5
const VALIDATION_FLOW_BASE: float = 0.45
const VALIDATION_FLOW_DISTANCE: float = 1.0
const VALIDATION_FLOW_PRESSURE: float = 1.5
const VALIDATION_FLOW_MAX: float = 4.0
const VALIDATION_UV_SCALE: Vector3 = Vector3(2.0, 2.0, 1.0)

@export var auto_refresh_maps: bool = true:
	set(value):
		auto_refresh_maps = value
		if auto_refresh_maps:
			call_deferred("refresh_validation_maps")

@export var reset_validation_geometry: bool = false:
	set(value):
		reset_validation_geometry = value
		if reset_validation_geometry:
			call_deferred("refresh_validation_maps")

@export var force_editor_redraw: bool = true:
	set(value):
		force_editor_redraw = value
		set_process(force_editor_redraw)

@export_enum("Normal:0", "Flow Map:1", "Foam Map:2", "Noise Map:3", "Distance Field:4", "Pressure Map:5", "Flow Pattern:6", "Flow Arrows:7", "Flow Strength:8", "Foam Mix:9")
var startup_debug_view: int = DEBUG_NORMAL:
	set(value):
		startup_debug_view = value
		call_deferred("_apply_debug_view")


func _ready() -> void:
	set_process(force_editor_redraw)
	call_deferred("_apply_existing_validation_defaults")
	if auto_refresh_maps:
		call_deferred("refresh_validation_maps")


func _process(_delta: float) -> void:
	if force_editor_redraw and RenderingServer.has_method("force_draw"):
		RenderingServer.call("force_draw", false)


func refresh_validation_maps() -> void:
	var river: Node = _get_validation_river()
	if river == null:
		return
	_configure_validation_river(river, reset_validation_geometry or river.get("curve") == null)
	_apply_validation_material_settings(river)
	if river.get("curve") == null:
		return
	var step_count: int = _calculate_step_count(river)
	var uv2_sides: int = WaterHelperMethods.calculate_side(step_count)
	var atlas_size: int = int(ceil(float(SOURCE_TEXTURE_SIZE) * float(uv2_sides + 2) / float(uv2_sides)))
	var content_rect: Rect2i = Rect2i(
		Vector2i((atlas_size - SOURCE_TEXTURE_SIZE) / 2, (atlas_size - SOURCE_TEXTURE_SIZE) / 2),
		Vector2i(SOURCE_TEXTURE_SIZE, SOURCE_TEXTURE_SIZE)
	)
	var flow_image: Image = Image.create(atlas_size, atlas_size, false, Image.FORMAT_RGBA8)
	var dist_image: Image = Image.create(atlas_size, atlas_size, false, Image.FORMAT_RGBA8)
	_fill_validation_images(flow_image, dist_image, content_rect, uv2_sides, step_count)
	var flow_texture: ImageTexture = ImageTexture.create_from_image(flow_image)
	var dist_texture: ImageTexture = ImageTexture.create_from_image(dist_image)
	river.set("flow_foam_noise", flow_texture)
	river.set("dist_pressure", dist_texture)
	river.set("_uv2_sides", uv2_sides)
	river.set("valid_flowmap", true)
	if river.has_method("set_materials"):
		river.call("set_materials", "i_flowmap", flow_texture)
		river.call("set_materials", "i_distmap", dist_texture)
		river.call("set_materials", "i_uv2_sides", uv2_sides)
		river.call("set_materials", "i_valid_flowmap", true)
	_apply_debug_view()


func _apply_existing_validation_defaults() -> void:
	var river: Node = _get_validation_river()
	if river == null:
		return
	_apply_validation_material_settings(river)
	_apply_debug_view()


func _configure_validation_river(river: Node, reset_geometry: bool) -> void:
	if reset_geometry:
		river.set("curve", _make_validation_curve())
		river.set("widths", [2.2, 2.4, 2.5, 2.2, 2.0])
		river.set("shape_step_length_divs", 2)
		river.set("shape_step_width_divs", 2)
		river.set("shape_smoothness", 0.65)
		river.set("baking_resolution", 2)
		river.set("baking_raycast_distance", 8.0)
		river.set("baking_raycast_layers", 1)
	if river.has_method("_generate_river"):
		river.call("_generate_river")


func _apply_validation_material_settings(river: Node) -> void:
	river.set("mat_flow_speed", VALIDATION_FLOW_SPEED)
	river.set("mat_flow_base", VALIDATION_FLOW_BASE)
	river.set("mat_flow_distance", VALIDATION_FLOW_DISTANCE)
	river.set("mat_flow_pressure", VALIDATION_FLOW_PRESSURE)
	river.set("mat_flow_max", VALIDATION_FLOW_MAX)
	river.set("mat_uv_scale", VALIDATION_UV_SCALE)
	if not river.has_method("set_materials"):
		return
	river.call("set_materials", "flow_speed", VALIDATION_FLOW_SPEED)
	river.call("set_materials", "flow_base", VALIDATION_FLOW_BASE)
	river.call("set_materials", "flow_distance", VALIDATION_FLOW_DISTANCE)
	river.call("set_materials", "flow_pressure", VALIDATION_FLOW_PRESSURE)
	river.call("set_materials", "flow_max", VALIDATION_FLOW_MAX)
	river.call("set_materials", "uv_scale", VALIDATION_UV_SCALE)


func _make_validation_curve() -> Curve3D:
	var curve: Curve3D = Curve3D.new()
	curve.bake_interval = 0.05
	curve.add_point(Vector3(-5.0, 0.0, -8.0), Vector3(0.0, 0.0, -1.2), Vector3(0.0, 0.0, 2.2))
	curve.add_point(Vector3(-4.6, 0.0, -2.8), Vector3(-0.1, 0.0, -1.8), Vector3(1.7, 0.0, 1.5))
	curve.add_point(Vector3(-1.0, 0.0, 1.0), Vector3(-1.8, 0.0, -1.4), Vector3(1.8, 0.0, 1.4))
	curve.add_point(Vector3(3.5, 0.0, 4.2), Vector3(-1.8, 0.0, -1.3), Vector3(0.0, 0.0, 2.5))
	curve.add_point(Vector3(3.5, 0.0, 10.0), Vector3(0.0, 0.0, -2.5), Vector3(0.0, 0.0, 1.5))
	return curve


func _fill_validation_images(flow_image: Image, dist_image: Image, content_rect: Rect2i, uv2_sides: int, step_count: int) -> void:
	var width: int = flow_image.get_width()
	var height: int = flow_image.get_height()
	for y in range(height):
		for x in range(width):
			var source_uv: Vector2 = Vector2(
				float(x - content_rect.position.x) / float(max(1, content_rect.size.x - 1)),
				float(y - content_rect.position.y) / float(max(1, content_rect.size.y - 1))
			)
			source_uv.x = clampf(source_uv.x, 0.0, 1.0)
			source_uv.y = clampf(source_uv.y, 0.0, 1.0)
			var tile_x: int = clampi(int(floor(source_uv.x * float(uv2_sides))), 0, uv2_sides - 1)
			var tile_y: int = clampi(int(floor(source_uv.y * float(uv2_sides))), 0, uv2_sides - 1)
			var tile_index: int = tile_x * uv2_sides + tile_y
			var local_x: float = fposmod(source_uv.x * float(uv2_sides), 1.0)
			var local_y: float = fposmod(source_uv.y * float(uv2_sides), 1.0)
			var river_t: float = clampf(float(tile_index) / float(max(1, step_count - 1)), 0.0, 1.0)
			var flow: Vector2 = _flow_for_validation_section(river_t)
			var foam: float = _foam_for_validation_section(river_t, local_x)
			var alpha: float = _alpha_phase_noise(source_uv, local_x, local_y)
			var bank_distance: float = clampf(1.0 - abs(local_x - 0.5) * 2.0, 0.0, 1.0)
			var pressure: float = clampf(flow.length() * 0.85 + foam * 0.15, 0.0, 1.0)
			if river_t > 0.78:
				pressure *= 0.12
			flow_image.set_pixel(x, y, Color(flow.x * 0.5 + 0.5, flow.y * 0.5 + 0.5, foam, alpha))
			dist_image.set_pixel(x, y, Color(bank_distance, pressure, 0.0, 1.0))


func _flow_for_validation_section(river_t: float) -> Vector2:
	if river_t > 0.78:
		return Vector2.ZERO
	if river_t < 0.45:
		var turn_t: float = smoothstep(0.0, 0.45, river_t)
		return Vector2(lerp(-0.18, 0.9, turn_t), lerp(0.95, 0.62, turn_t))
	return Vector2(0.0, 0.95)


func _foam_for_validation_section(river_t: float, local_x: float) -> float:
	var bank_foam: float = smoothstep(0.55, 1.0, abs(local_x - 0.5) * 2.0) * 0.45
	var bend_foam: float = 0.18 if river_t < 0.45 else 0.05
	if river_t > 0.78:
		return 0.02
	return clampf(bank_foam + bend_foam, 0.0, 1.0)


func _alpha_phase_noise(source_uv: Vector2, local_x: float, local_y: float) -> float:
	var wave: float = sin((source_uv.x * 17.0 + source_uv.y * 11.0) * TAU)
	var tile_wave: float = sin((local_x * 3.0 + local_y * 5.0) * TAU)
	var alpha: float = 0.5 + wave * 0.22 + tile_wave * 0.12
	return clampf(alpha, 0.08, 0.92)


func _calculate_step_count(river: Node) -> int:
	var curve: Curve3D = river.get("curve") as Curve3D
	if curve == null:
		return 1
	var widths: Array = river.get("widths") as Array
	var total_width: float = 0.0
	for width in widths:
		total_width += max(float(width), WaterHelperMethods.MIN_RIVER_WIDTH)
	var average_width: float = 2.0
	if not widths.is_empty():
		average_width = max(WaterHelperMethods.MIN_RIVER_WIDTH, total_width / float(widths.size()))
	return int(max(1.0, round(curve.get_baked_length() / average_width)))


func _apply_debug_view() -> void:
	var river: Node = _get_validation_river()
	if river == null:
		return
	river.set("debug_view", startup_debug_view)
	if river.has_method("set_materials"):
		river.call("set_materials", "i_valid_flowmap", true)
	if river.has_method("_apply_debug_view_material"):
		river.call("_apply_debug_view_material")


func _get_validation_river() -> Node:
	return get_node_or_null("TwoPhaseFlowRiver")
