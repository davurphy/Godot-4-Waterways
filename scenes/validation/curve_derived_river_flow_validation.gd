@tool
extends Node3D

const DEFAULT_BEHAVIOR := "downstream_baseline_collision_support"
const CURVE_ONLY_BEHAVIOR := "curve_only"
const LEGACY_BEHAVIOR := "legacy_collision_only"

const FLOW_SPEED := 1.5
const FLOW_BASE := 0.45
const FLOW_DISTANCE := 1.0
const FLOW_PRESSURE := 1.5
const FLOW_MAX := 4.0
const UV_SCALE := Vector3(2.0, 2.0, 1.0)
const WATER_ALBEDO_COLOR := Transform3D(Vector3(0.0, 0.8, 1.0), Vector3(0.15, 0.2, 0.5), Vector3.ZERO, Vector3.ZERO)
const COLLIDER_PREVIEW_OFFSET := Vector3(0.0, -0.45, 0.0)

@export var refresh_fixtures := false:
	set(value):
		refresh_fixtures = false
		if value:
			call_deferred("refresh_validation_fixtures")


func _ready() -> void:
	call_deferred("refresh_validation_fixtures")


func refresh_validation_fixtures() -> void:
	_setup_collision_helper_previews()
	_setup_river(
		"WaterSystem/StraightNoColliderRiver",
		Vector3(-30.0, 0.0, -10.0),
		_make_curve([
			Vector3(0.0, 0.0, -7.0),
			Vector3(0.0, 0.0, 7.0)
		]),
		[2.4, 2.4],
		DEFAULT_BEHAVIOR,
		0,
		2
	)
	_setup_river(
		"WaterSystem/CurvedNoColliderRiver",
		Vector3(-15.0, 0.0, -10.0),
		_make_curve([
			Vector3(-3.0, 0.0, -7.0),
			Vector3(-5.0, 0.0, -2.0),
			Vector3(1.0, 0.0, 2.0),
			Vector3(4.0, 0.0, 7.0)
		]),
		[2.2, 2.4, 2.3, 2.1],
		CURVE_ONLY_BEHAVIOR,
		0,
		2
	)
	_setup_river(
		"WaterSystem/FlatColliderRiver",
		Vector3(0.0, 0.0, -10.0),
		_make_curve([
			Vector3(0.0, 0.0, -7.0),
			Vector3(0.0, 0.0, 7.0)
		]),
		[2.5, 2.5],
		DEFAULT_BEHAVIOR,
		1,
		2
	)
	_setup_river(
		"WaterSystem/BankHelperRiver",
		Vector3(15.0, 0.0, -10.0),
		_make_curve([
			Vector3(-3.5, 0.0, -7.0),
			Vector3(-4.0, 0.0, -1.5),
			Vector3(1.5, 0.0, 2.0),
			Vector3(4.0, 0.0, 7.0)
		]),
		[2.4, 2.8, 2.6, 2.3],
		DEFAULT_BEHAVIOR,
		1,
		2
	)
	_setup_river(
		"WaterSystem/LegacyCollisionRiver",
		Vector3(30.0, 0.0, -10.0),
		_make_curve([
			Vector3(0.0, 0.0, -7.0),
			Vector3(0.0, 0.0, 7.0)
		]),
		[2.5, 2.5],
		LEGACY_BEHAVIOR,
		1,
		2
	)
	_setup_river(
		"WaterSystem/SeamCrossingCurveRiver",
		Vector3(0.0, 0.0, 15.0),
		_make_curve([
			Vector3(-12.0, 0.0, -9.0),
			Vector3(-9.0, 0.0, -4.0),
			Vector3(-3.0, 0.0, -1.0),
			Vector3(2.5, 0.0, 2.5),
			Vector3(8.0, 0.0, 5.0),
			Vector3(11.0, 0.0, 10.0)
		]),
		[2.0, 2.1, 2.2, 2.1, 2.0, 1.9],
		CURVE_ONLY_BEHAVIOR,
		0,
		3
	)


func _setup_river(path: NodePath, origin: Vector3, curve: Curve3D, widths: Array, behavior: String, raycast_layers: int, length_divs: int) -> void:
	var river := get_node_or_null(path)
	if river == null:
		return
	if _river_matches_fixture(river, origin, curve, widths, behavior, raycast_layers, length_divs):
		_apply_river_material_settings(river)
		if river.get_node_or_null("RiverMeshInstance") == null and river.has_method("_generate_river"):
			river.call("_generate_river")
		return
	river.position = origin
	river.set("curve", curve)
	river.set("widths", widths)
	river.set("shape_step_length_divs", length_divs)
	river.set("shape_step_width_divs", 2)
	river.set("shape_smoothness", 0.65)
	river.set("baking_resolution", 2)
	river.set("baking_raycast_distance", 6.0)
	river.set("baking_raycast_layers", raycast_layers)
	river.set("bake_generation_behavior", behavior)
	_apply_river_material_settings(river)
	if river.has_method("_generate_river"):
		river.call("_generate_river")


func _apply_river_material_settings(river: Node) -> void:
	river.set("mat_albedo_color", WATER_ALBEDO_COLOR)
	river.set("mat_flow_speed", FLOW_SPEED)
	river.set("mat_flow_base", FLOW_BASE)
	river.set("mat_flow_distance", FLOW_DISTANCE)
	river.set("mat_flow_pressure", FLOW_PRESSURE)
	river.set("mat_flow_max", FLOW_MAX)
	river.set("mat_uv_scale", UV_SCALE)
	if river.has_method("set_materials"):
		river.call("set_materials", "albedo_color", WATER_ALBEDO_COLOR)
		river.call("set_materials", "flow_speed", FLOW_SPEED)
		river.call("set_materials", "flow_base", FLOW_BASE)
		river.call("set_materials", "flow_distance", FLOW_DISTANCE)
		river.call("set_materials", "flow_pressure", FLOW_PRESSURE)
		river.call("set_materials", "flow_max", FLOW_MAX)
		river.call("set_materials", "uv_scale", UV_SCALE)


func _setup_collision_helper_previews() -> void:
	_lower_helper_preview("FlatColliderBakeHelper/PreviewMesh")
	_lower_helper_preview("LegacyFlatColliderBakeHelper/PreviewMesh")


func _lower_helper_preview(path: NodePath) -> void:
	var preview := get_node_or_null(path) as MeshInstance3D
	if preview == null:
		return
	preview.position = COLLIDER_PREVIEW_OFFSET


func _river_matches_fixture(river: Node, origin: Vector3, fixture_curve: Curve3D, fixture_widths: Array, behavior: String, raycast_layers: int, length_divs: int) -> bool:
	if river.position.distance_squared_to(origin) > 0.0001:
		return false
	if String(river.get("bake_generation_behavior")) != behavior:
		return false
	if int(river.get("baking_raycast_layers")) != raycast_layers:
		return false
	if int(river.get("shape_step_length_divs")) != length_divs:
		return false
	var river_curve := river.get("curve") as Curve3D
	if river_curve == null or river_curve.get_point_count() != fixture_curve.get_point_count():
		return false
	for index in fixture_curve.get_point_count():
		if river_curve.get_point_position(index).distance_squared_to(fixture_curve.get_point_position(index)) > 0.0001:
			return false
	var river_widths: Array = river.get("widths") as Array
	if river_widths.size() != fixture_widths.size():
		return false
	for index in fixture_widths.size():
		if absf(float(river_widths[index]) - float(fixture_widths[index])) > 0.0001:
			return false
	return true


func _make_curve(points: Array) -> Curve3D:
	var curve := Curve3D.new()
	curve.bake_interval = 0.05
	for index in points.size():
		var point: Vector3 = points[index]
		var previous: Vector3 = points[maxi(index - 1, 0)]
		var next: Vector3 = points[mini(index + 1, points.size() - 1)]
		var tangent := (next - previous) * 0.25
		curve.add_point(point, -tangent, tangent)
	return curve
