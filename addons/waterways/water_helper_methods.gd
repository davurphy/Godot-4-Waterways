# Copyright © 2021 Kasper Arnklit Frandsen - MIT License
# See `LICENSE.md` included in the source distribution for details.

const MIN_DIRECTION_LENGTH_SQUARED := 0.000001
const MIN_RIVER_WIDTH := 0.001
const BARYCENTRIC_EDGE_EPSILON := 0.00001
const EXTERNAL_BAKE_STORAGE_VERSION := 1
const EXTERNAL_BAKE_ROOT := "res://waterways_bakes"
const RIVER_SCRIPT_PATH := "res://addons/waterways/river_manager.gd"
const WATER_SYSTEM_SCRIPT_PATH := "res://addons/waterways/water_system_manager.gd"
const RIVER_BAKE_SUFFIX := ".river_bake.res"
const WATER_SYSTEM_BAKE_SUFFIX := ".water_system_bake.res"
const SAFE_FILENAME_CHARS := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
const SHAPE_STEP_DIVS_MIN := 1
const SHAPE_STEP_DIVS_MAX := 8
const SHAPE_SMOOTHNESS_MIN := 0.1
const SHAPE_SMOOTHNESS_MAX := 5.0


static func save_river_bake_data(owner: Node, bake_data: Resource) -> Dictionary:
	return _save_external_bake_data(owner, bake_data, RIVER_SCRIPT_PATH, RIVER_BAKE_SUFFIX)


static func save_water_system_bake_data(owner: Node, bake_data: Resource) -> Dictionary:
	return _save_external_bake_data(owner, bake_data, WATER_SYSTEM_SCRIPT_PATH, WATER_SYSTEM_BAKE_SUFFIX)


static func has_external_bake_path(bake_data: Resource) -> bool:
	return not _get_existing_external_bake_path(bake_data).is_empty()


static func _save_external_bake_data(owner: Node, bake_data: Resource, owner_script_path: String, file_suffix: String) -> Dictionary:
	var result := {
		"saved": false,
		"path": "",
		"requires_saved_scene": false,
		"error": OK,
		"message": ""
	}
	if not Engine.is_editor_hint():
		result.message = "External bake storage is editor-only."
		return result
	if owner == null or bake_data == null:
		result.error = ERR_INVALID_PARAMETER
		result.message = "Cannot save Waterways bake data without a node and bake resource."
		return result
	var existing_path := _get_existing_external_bake_path(bake_data)
	var scene_root := _get_scene_root_for_bake(owner)
	var scene_path := _get_scene_path(scene_root, owner)
	var target_path := existing_path
	if target_path.is_empty():
		if scene_path.is_empty():
			result.requires_saved_scene = true
			result.message = "Save the scene, then rebake to create a scene-owned external Waterways bake resource."
			return result
		target_path = _get_default_bake_path(owner, scene_root, scene_path, owner_script_path, file_suffix)
	var target_folder := target_path.get_base_dir()
	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_folder))
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		result.error = dir_error
		result.message = "Could not create Waterways bake folder: " + target_folder
		return result
	_write_bake_storage_metadata(bake_data, scene_root, owner, scene_path, target_path)
	var save_flags := ResourceSaver.FLAG_CHANGE_PATH | ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS | ResourceSaver.FLAG_OMIT_EDITOR_PROPERTIES
	var save_error := ResourceSaver.save(bake_data, target_path, save_flags)
	result.error = save_error
	if save_error != OK:
		result.message = "Could not save Waterways bake resource: " + target_path
		return result
	bake_data.take_over_path(target_path)
	result.saved = true
	result.path = target_path
	result.message = "Saved Waterways bake resource: " + target_path
	_rescan_editor_filesystem()
	return result


static func _get_existing_external_bake_path(bake_data: Resource) -> String:
	if bake_data == null:
		return ""
	var path := bake_data.resource_path
	if path.begins_with("res://") and path.find("::") == -1 and path.get_extension().to_lower() == "res":
		return path
	return ""


static func _get_scene_root_for_bake(owner: Node) -> Node:
	if owner != null and owner.is_inside_tree():
		var tree := owner.get_tree()
		if Engine.is_editor_hint() and tree.has_method("get_edited_scene_root"):
			var edited_scene = tree.call("get_edited_scene_root")
			if edited_scene is Node:
				var edited_node := edited_scene as Node
				if edited_node == owner or edited_node.is_ancestor_of(owner):
					return edited_node
		if tree.current_scene != null and (tree.current_scene == owner or tree.current_scene.is_ancestor_of(owner)):
			return tree.current_scene
	if owner != null and owner.owner != null:
		return owner.owner
	return owner


static func _get_scene_path(scene_root: Node, owner: Node) -> String:
	if scene_root != null and not scene_root.scene_file_path.is_empty():
		return scene_root.scene_file_path
	if owner != null and owner.owner != null and not owner.owner.scene_file_path.is_empty():
		return owner.owner.scene_file_path
	return ""


static func _get_default_bake_path(owner: Node, scene_root: Node, scene_path: String, owner_script_path: String, file_suffix: String) -> String:
	var folder := _get_scene_bake_folder(scene_path)
	var base_filename := _get_default_bake_filename(owner, file_suffix)
	var filename := base_filename
	var filename_counts := _get_default_bake_filename_counts(scene_root, owner_script_path, file_suffix)
	if int(filename_counts.get(base_filename, 0)) > 1:
		filename = _get_default_bake_filename(owner, file_suffix, _get_scene_relative_node_path(scene_root, owner))
	return _join_res_path(folder, filename)


static func _get_scene_bake_folder(scene_path: String) -> String:
	var scene_key := _sanitize_file_stem(scene_path.trim_prefix("res://").get_basename().replace("/", "_").replace("\\", "_"))
	var folder := _join_res_path(EXTERNAL_BAKE_ROOT, scene_key)
	if _folder_has_foreign_scene_bakes(folder, scene_path):
		folder = _join_res_path(EXTERNAL_BAKE_ROOT, scene_key + "_" + _stable_short_suffix(scene_path))
	return folder


static func _get_default_bake_filename(owner: Node, file_suffix: String, relative_node_path := "") -> String:
	var stem := "BakeData"
	if owner != null:
		stem = _sanitize_file_stem(owner.name)
	if not relative_node_path.is_empty():
		stem += "_" + _stable_short_suffix(relative_node_path)
	return stem + file_suffix


static func _get_default_bake_filename_counts(scene_root: Node, owner_script_path: String, file_suffix: String) -> Dictionary:
	var counts := {}
	for node in _collect_scene_bake_targets(scene_root, owner_script_path):
		var filename := _get_default_bake_filename(node, file_suffix)
		counts[filename] = int(counts.get(filename, 0)) + 1
	return counts


static func _collect_scene_bake_targets(scene_root: Node, owner_script_path: String) -> Array:
	var targets := []
	if scene_root == null:
		return targets
	var stack: Array[Node] = [scene_root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.push_back(child)
		var script = node.get_script()
		if script != null and script.resource_path == owner_script_path:
			targets.append(node)
	return targets


static func _folder_has_foreign_scene_bakes(folder_path: String, scene_path: String) -> bool:
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return false
	dir.list_dir_begin()
	var filename := dir.get_next()
	while not filename.is_empty():
		if not dir.current_is_dir() and filename.get_extension().to_lower() == "res":
			var resource := ResourceLoader.load(_join_res_path(folder_path, filename))
			if resource != null:
				var metadata = resource.get("source_metadata")
				if typeof(metadata) == TYPE_DICTIONARY:
					var stored_scene_path := String(metadata.get("scene_path", ""))
					if not stored_scene_path.is_empty() and stored_scene_path != scene_path:
						dir.list_dir_end()
						return true
		filename = dir.get_next()
	dir.list_dir_end()
	return false


static func _write_bake_storage_metadata(bake_data: Resource, scene_root: Node, owner: Node, scene_path: String, target_path: String) -> void:
	var source_metadata = bake_data.get("source_metadata")
	var metadata := {}
	if typeof(source_metadata) == TYPE_DICTIONARY:
		metadata = source_metadata.duplicate(true)
	metadata["scene_path"] = scene_path
	metadata["node_path"] = _get_scene_relative_node_path(scene_root, owner)
	metadata["node_name"] = owner.name if owner != null else ""
	metadata["bake_resource_path"] = target_path
	metadata["storage_version"] = EXTERNAL_BAKE_STORAGE_VERSION
	bake_data.set("source_metadata", metadata)


static func _get_scene_relative_node_path(scene_root: Node, node: Node) -> String:
	if node == null:
		return ""
	if scene_root == node:
		return "."
	if scene_root != null and scene_root.is_ancestor_of(node):
		return str(scene_root.get_path_to(node))
	if node.owner != null and node.owner.is_ancestor_of(node):
		return str(node.owner.get_path_to(node))
	return str(node.get_path())


static func _join_res_path(folder: String, filename: String) -> String:
	if folder.ends_with("/"):
		return folder + filename
	return folder + "/" + filename


static func _sanitize_file_stem(value: String) -> String:
	var text := value.strip_edges()
	if text.is_empty():
		text = "BakeData"
	var result := ""
	for index in text.length():
		var character := text.substr(index, 1)
		if SAFE_FILENAME_CHARS.find(character) != -1:
			result += character
		else:
			result += "_"
	while result.find("__") != -1:
		result = result.replace("__", "_")
	while result.begins_with("_") and result.length() > 1:
		result = result.substr(1)
	while result.ends_with("_") and result.length() > 1:
		result = result.substr(0, result.length() - 1)
	if result == "_":
		result = "BakeData"
	return result


static func _stable_short_suffix(value: String) -> String:
	var hash_value := value.hash()
	if hash_value < 0:
		hash_value = -hash_value
	var suffix := str(hash_value % 100000)
	while suffix.length() < 5:
		suffix = "0" + suffix
	return suffix


static func _rescan_editor_filesystem() -> void:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface"):
		return
	var editor_interface = Engine.get_singleton("EditorInterface")
	if editor_interface == null or not editor_interface.has_method("get_resource_filesystem"):
		return
	var resource_filesystem = editor_interface.call("get_resource_filesystem")
	if resource_filesystem != null and resource_filesystem.has_method("scan"):
		resource_filesystem.call_deferred("scan")


static func cart2bary(p : Vector3, a : Vector3, b : Vector3, c: Vector3) -> Vector3:
	if not _is_finite_vector3(p) or not _is_finite_vector3(a) or not _is_finite_vector3(b) or not _is_finite_vector3(c):
		return Vector3(-1.0, -1.0, -1.0)
	var v0 := b - a
	var v1 := c - a
	var v2 := p - a
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var denom := d00 * d11 - d01 * d01
	if not _is_finite_number(denom) or abs(denom) <= MIN_DIRECTION_LENGTH_SQUARED:
		return Vector3(-1.0, -1.0, -1.0)
	var v = (d11 * d20 - d01 * d21) / denom
	var w = (d00 * d21 - d01 * d20) / denom
	var u = 1.0 - v - w
	if not _is_finite_number(u) or not _is_finite_number(v) or not _is_finite_number(w):
		return Vector3(-1.0, -1.0, -1.0)
	return Vector3(u, v, w)


static func bary2cart(a : Vector3, b : Vector3, c: Vector3, barycentric: Vector3) -> Vector3:
	return barycentric.x * a + barycentric.y * b + barycentric.z * c


static func point_in_bariatric(v : Vector3) -> bool:
	if not _is_finite_vector3(v):
		return false
	return -BARYCENTRIC_EDGE_EPSILON <= v.x and v.x <= 1.0 + BARYCENTRIC_EDGE_EPSILON and -BARYCENTRIC_EDGE_EPSILON <= v.y and v.y <= 1.0 + BARYCENTRIC_EDGE_EPSILON and -BARYCENTRIC_EDGE_EPSILON <= v.z and v.z <= 1.0 + BARYCENTRIC_EDGE_EPSILON;


static func reset_all_colliders(node):
	for n in node.get_children():
		if n.get_child_count() > 0:
			reset_all_colliders(n)
		if n is CollisionShape3D:
			if n.disabled == false:
				n.disabled = true
				n.disabled = false


static func collect_raycast_collision_shapes(scene_root: Node, raycast_layers: int) -> Array:
	var collision_shapes := []
	if scene_root == null:
		return collision_shapes
	var stack: Array[Node] = [scene_root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.push_back(child)
		if not node is CollisionShape3D:
			continue
		var collision_shape := node as CollisionShape3D
		if collision_shape.disabled or collision_shape.shape == null:
			continue
		var collision_parent := collision_shape.get_parent()
		if not collision_parent is CollisionObject3D:
			continue
		if ((collision_parent as CollisionObject3D).collision_layer & raycast_layers) == 0:
			continue
		collision_shapes.append(collision_shape)
	return collision_shapes


static func sum_array(array) -> float:
	var sum = 0.0
	for element in array:
			sum += element
	return sum


static func calculate_side(steps : int) -> int:
	var safe_steps := max(1, steps)
	var side_float : float = sqrt(float(safe_steps))
	if fmod(side_float, 1.0) != 0.0:
		side_float += 1.0
	return int(side_float)


static func generate_river_width_values(curve : Curve3D, steps : int, step_length_divs : int, step_width_divs : int, widths : Array) -> Array:
	var river_width_values := []
	if curve.get_point_count() < 2 or widths.size() < 2:
		river_width_values.append(1.0)
		return river_width_values
	var safe_steps := max(1, steps)
	var safe_step_length_divs: int = clamp(step_length_divs, SHAPE_STEP_DIVS_MIN, SHAPE_STEP_DIVS_MAX)
	var sample_count: int = safe_steps * safe_step_length_divs
	var length = curve.get_baked_length()
	var last_width_index: int = min(curve.get_point_count(), widths.size()) - 1
	for step in sample_count + 1:
		if step == 0:
			river_width_values.append(_safe_width_value(widths, 0))
			continue
		if step == sample_count:
			river_width_values.append(_safe_width_value(widths, last_width_index))
			continue
		var target_pos = curve.sample_baked((float(step) / float(sample_count)) * length)
		var closest_dist := 4096.0
		var closest_interpolate := 0.0
		var closest_point := 0
		for c_point in last_width_index:
			for i in 101:
				var interpolate := float(i) / 100.0
				var pos = curve.sample(c_point, interpolate)
				var dist = pos.distance_to(target_pos)
				if dist < closest_dist:
					closest_dist = dist
					closest_interpolate = interpolate
					closest_point = c_point
		river_width_values.append(max(MIN_RIVER_WIDTH, lerp(_safe_width_value(widths, closest_point), _safe_width_value(widths, closest_point + 1), closest_interpolate)))
	
	return river_width_values


static func generate_river_mesh(curve : Curve3D, steps : int, step_length_divs : int, step_width_divs : int, smoothness : float, river_width_values : Array, uv2_source_resolution : int = 0) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var safe_steps := max(1, steps)
	var safe_step_length_divs: int = clamp(step_length_divs, SHAPE_STEP_DIVS_MIN, SHAPE_STEP_DIVS_MAX)
	var safe_step_width_divs: int = clamp(step_width_divs, SHAPE_STEP_DIVS_MIN, SHAPE_STEP_DIVS_MAX)
	var step_count: int = safe_steps * safe_step_length_divs
	var curve_length := curve.get_baked_length()
	var safe_smoothness := smoothness
	if not _is_finite_number(safe_smoothness):
		safe_smoothness = 0.5
	safe_smoothness = clamp(safe_smoothness, SHAPE_SMOOTHNESS_MIN, SHAPE_SMOOTHNESS_MAX)

	var rows := []
	for step in step_count + 1:
		var row := []
		var position := _sample_river_position(curve, step, step_count, curve_length)
		var backward_pos := _sample_river_position(curve, float(step) - safe_smoothness, step_count, curve_length)
		var forward_pos := _sample_river_position(curve, float(step) + safe_smoothness, step_count, curve_length)
		var right_vector := _safe_right_vector(forward_pos - backward_pos)
		var width_lerp := MIN_RIVER_WIDTH
		if step < river_width_values.size():
			width_lerp = max(MIN_RIVER_WIDTH, float(river_width_values[step]))
		for w_sub in safe_step_width_divs + 1:
			var width_ratio := float(w_sub) / float(safe_step_width_divs)
			row.append(position + right_vector * width_lerp - 2.0 * right_vector * width_lerp * width_ratio)
		rows.append(row)

	var grid_side := calculate_side(safe_steps)
	var grid_side_length := 1.0 / float(grid_side)
	var x_grid_sub_length := grid_side_length / float(safe_step_width_divs)
	var y_grid_sub_length := grid_side_length / float(safe_step_length_divs)
	var safe_uv2_source_resolution := max(1, uv2_source_resolution)
	for step in step_count:
		var step_quad := int(step / safe_step_length_divs)
		var tile_x := int(step_quad / grid_side)
		var tile_y := int(step_quad % grid_side)
		var sub_y := int(step % safe_step_length_divs)
		for w_sub in safe_step_width_divs:
			var uv2_origin := Vector2.ZERO
			var uv2_right := Vector2.ZERO
			var uv2_down := Vector2.ZERO
			var uv2_diag := Vector2.ZERO
			if uv2_source_resolution > 0:
				var tile_uv_rect := _uv2_tile_pixel_center_rect(tile_x, tile_y, grid_side, safe_uv2_source_resolution)
				var local_x0 := float(w_sub) / float(safe_step_width_divs)
				var local_x1 := float(w_sub + 1) / float(safe_step_width_divs)
				var local_y0 := float(sub_y) / float(safe_step_length_divs)
				var local_y1 := float(sub_y + 1) / float(safe_step_length_divs)
				uv2_origin = Vector2(lerpf(tile_uv_rect.position.x, tile_uv_rect.end.x, local_x0), lerpf(tile_uv_rect.position.y, tile_uv_rect.end.y, local_y0))
				uv2_right = Vector2(lerpf(tile_uv_rect.position.x, tile_uv_rect.end.x, local_x1), uv2_origin.y)
				uv2_down = Vector2(uv2_origin.x, lerpf(tile_uv_rect.position.y, tile_uv_rect.end.y, local_y1))
				uv2_diag = Vector2(uv2_right.x, uv2_down.y)
			else:
				uv2_origin = Vector2(
					float(tile_x) * grid_side_length + float(w_sub) * x_grid_sub_length,
					float(tile_y) * grid_side_length + float(sub_y) * y_grid_sub_length
				)
				uv2_right = uv2_origin + Vector2(x_grid_sub_length, 0.0)
				uv2_down = uv2_origin + Vector2(0.0, y_grid_sub_length)
				uv2_diag = uv2_origin + Vector2(x_grid_sub_length, y_grid_sub_length)
			var uv00 := Vector2(float(w_sub) / float(safe_step_width_divs), float(step) / float(safe_step_length_divs))
			var uv01 := Vector2(float(w_sub + 1) / float(safe_step_width_divs), float(step) / float(safe_step_length_divs))
			var uv10 := Vector2(float(w_sub) / float(safe_step_width_divs), float(step + 1) / float(safe_step_length_divs))
			var uv11 := Vector2(float(w_sub + 1) / float(safe_step_width_divs), float(step + 1) / float(safe_step_length_divs))
			_add_river_vertex(st, rows[step][w_sub], uv00, uv2_origin)
			_add_river_vertex(st, rows[step + 1][w_sub], uv10, uv2_down)
			_add_river_vertex(st, rows[step][w_sub + 1], uv01, uv2_right)
			_add_river_vertex(st, rows[step][w_sub + 1], uv01, uv2_right)
			_add_river_vertex(st, rows[step + 1][w_sub], uv10, uv2_down)
			_add_river_vertex(st, rows[step + 1][w_sub + 1], uv11, uv2_diag)

	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func _uv2_tile_pixel_center_rect(tile_x: int, tile_y: int, grid_side: int, source_resolution: int) -> Rect2:
	var safe_grid_side := maxi(1, grid_side)
	var safe_source_resolution := maxi(1, source_resolution)
	var x0 := int(floor(float(tile_x) * float(safe_source_resolution) / float(safe_grid_side)))
	var x1 := int(floor(float(tile_x + 1) * float(safe_source_resolution) / float(safe_grid_side)))
	var y0 := int(floor(float(tile_y) * float(safe_source_resolution) / float(safe_grid_side)))
	var y1 := int(floor(float(tile_y + 1) * float(safe_source_resolution) / float(safe_grid_side)))
	if x1 <= x0:
		x1 = x0 + 1
	if y1 <= y0:
		y1 = y0 + 1
	var inv_resolution := 1.0 / float(safe_source_resolution)
	var start := Vector2((float(x0) + 0.5) * inv_resolution, (float(y0) + 0.5) * inv_resolution)
	var end := Vector2((float(x1) - 0.5) * inv_resolution, (float(y1) - 0.5) * inv_resolution)
	return Rect2(start, end - start)


static func _add_river_vertex(st: SurfaceTool, position: Vector3, uv: Vector2, uv2: Vector2) -> void:
	st.set_uv(uv)
	st.set_uv2(uv2)
	st.add_vertex(position)


static func _sample_river_position(curve: Curve3D, step, step_count: int, curve_length: float) -> Vector3:
	var base := Vector3.ZERO
	if curve.get_point_count() > 0:
		base = curve.get_point_position(0)
	if curve_length <= MIN_DIRECTION_LENGTH_SQUARED:
		return base + Vector3.BACK * MIN_RIVER_WIDTH * (float(step) / float(max(1, step_count)))
	var clamped_step: float = clamp(float(step), 0.0, float(step_count))
	return curve.sample_baked((clamped_step / float(step_count)) * curve_length, false)


static func _safe_right_vector(forward_vector: Vector3) -> Vector3:
	var forward := _safe_direction(forward_vector, Vector3.BACK)
	var reference := Vector3.UP
	if abs(forward.dot(reference)) > 0.98:
		reference = Vector3.RIGHT
	return _safe_direction(forward.cross(reference), Vector3.RIGHT)


static func _safe_direction(direction: Vector3, fallback: Vector3) -> Vector3:
	if direction.length_squared() > MIN_DIRECTION_LENGTH_SQUARED:
		return direction.normalized()
	if fallback.length_squared() > MIN_DIRECTION_LENGTH_SQUARED:
		return fallback.normalized()
	return Vector3.BACK


static func _safe_width_value(widths: Array, index: int) -> float:
	if widths.is_empty():
		return MIN_RIVER_WIDTH
	var clamped_index: int = clamp(index, 0, widths.size() - 1)
	var width_value := float(widths[clamped_index])
	if not _is_finite_number(width_value):
		return MIN_RIVER_WIDTH
	return max(MIN_RIVER_WIDTH, width_value)


static func _is_finite_number(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)


static func _is_finite_vector2(value: Vector2) -> bool:
	return _is_finite_number(value.x) and _is_finite_number(value.y)


static func _is_finite_vector3(value: Vector3) -> bool:
	return _is_finite_number(value.x) and _is_finite_number(value.y) and _is_finite_number(value.z)


static func _is_degenerate_uv_triangle(a: Vector2, b: Vector2, c: Vector2) -> bool:
	if not _is_finite_vector2(a) or not _is_finite_vector2(b) or not _is_finite_vector2(c):
		return true
	return abs((b - a).cross(c - a)) <= MIN_DIRECTION_LENGTH_SQUARED


static func _get_bake_collision_root(mesh_instance: MeshInstance3D, river) -> Node:
	var root: Node = null
	if river != null and river.owner != null:
		root = river.owner
	elif mesh_instance.owner != null:
		root = mesh_instance.owner
	if root == null:
		root = mesh_instance.get_tree().current_scene
	if root == null:
		root = mesh_instance.get_tree().root
	return root


static func _intersects_collision_shapes_segment(collision_shapes: Array, from: Vector3, to: Vector3) -> bool:
	for item in collision_shapes:
		var collision_shape := item as CollisionShape3D
		if collision_shape == null:
			continue
		if intersect_collision_shape_segment(collision_shape, from, to) != null:
			return true
	return false


static func intersect_collision_shape_segment(collision_shape: CollisionShape3D, from: Vector3, to: Vector3) -> Variant:
	return _intersect_collision_shape_segment(collision_shape, from, to)


static func _intersect_collision_shape_segment(collision_shape: CollisionShape3D, from: Vector3, to: Vector3) -> Variant:
	if collision_shape == null or collision_shape.shape == null:
		return null
	var shape := collision_shape.shape
	var local_from: Vector3 = collision_shape.global_transform.affine_inverse() * from
	var local_to: Vector3 = collision_shape.global_transform.affine_inverse() * to
	var local_hit: Variant = null
	if shape is BoxShape3D:
		var size: Vector3 = (shape as BoxShape3D).size
		var half_size := size * 0.5
		local_hit = AABB(-half_size, size).intersects_segment(local_from, local_to)
	elif shape is SphereShape3D:
		local_hit = _intersect_local_segment_sphere(local_from, local_to, Vector3.ZERO, max(0.0, (shape as SphereShape3D).radius))
	elif shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		local_hit = _intersect_local_segment_cylinder(local_from, local_to, max(0.0, cylinder.radius), max(0.0, cylinder.height))
	elif shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		local_hit = _intersect_local_segment_capsule(local_from, local_to, max(0.0, capsule.radius), max(0.0, capsule.height))
	if local_hit == null:
		return null
	return collision_shape.global_transform * local_hit


static func _intersect_local_segment_sphere(local_from: Vector3, local_to: Vector3, center: Vector3, radius: float) -> Variant:
	var direction := local_to - local_from
	var segment_length_squared := direction.length_squared()
	if segment_length_squared <= MIN_DIRECTION_LENGTH_SQUARED:
		if local_from.distance_squared_to(center) <= radius * radius:
			return local_from
		return null
	var relative_from := local_from - center
	var radius_squared := radius * radius
	if relative_from.length_squared() <= radius_squared:
		return local_from
	var a := segment_length_squared
	var b := 2.0 * relative_from.dot(direction)
	var c := relative_from.length_squared() - radius_squared
	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0:
		return null
	var sqrt_discriminant := sqrt(discriminant)
	var t := (-b - sqrt_discriminant) / (2.0 * a)
	if t < 0.0 or t > 1.0:
		t = (-b + sqrt_discriminant) / (2.0 * a)
	if t < 0.0 or t > 1.0:
		return null
	return local_from + direction * t


static func _intersect_local_segment_cylinder(local_from: Vector3, local_to: Vector3, radius: float, height: float) -> Variant:
	var half_height := height * 0.5
	var radius_squared := radius * radius
	var from_xz_squared := local_from.x * local_from.x + local_from.z * local_from.z
	if abs(local_from.y) <= half_height and from_xz_squared <= radius_squared:
		return local_from
	var direction := local_to - local_from
	var local_hit: Variant = _intersect_local_segment_cylinder_side(local_from, local_to, radius, half_height)
	if abs(direction.y) > MIN_DIRECTION_LENGTH_SQUARED:
		for cap_y in [-half_height, half_height]:
			var t: float = (cap_y - local_from.y) / direction.y
			if t < 0.0 or t > 1.0:
				continue
			var point: Vector3 = local_from + direction * t
			var point_xz_squared: float = point.x * point.x + point.z * point.z
			if point_xz_squared <= radius_squared:
				local_hit = _nearest_local_segment_hit(local_hit, point, local_from)
	return local_hit


static func _intersect_local_segment_cylinder_side(local_from: Vector3, local_to: Vector3, radius: float, half_height: float) -> Variant:
	var direction := local_to - local_from
	var a := direction.x * direction.x + direction.z * direction.z
	if a <= MIN_DIRECTION_LENGTH_SQUARED:
		return null
	var b := 2.0 * (local_from.x * direction.x + local_from.z * direction.z)
	var c := local_from.x * local_from.x + local_from.z * local_from.z - radius * radius
	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0:
		return null
	var sqrt_discriminant := sqrt(discriminant)
	var local_hit: Variant = null
	for t: float in [(-b - sqrt_discriminant) / (2.0 * a), (-b + sqrt_discriminant) / (2.0 * a)]:
		if t < 0.0 or t > 1.0:
			continue
		var point: Vector3 = local_from + direction * t
		if abs(point.y) <= half_height:
			local_hit = _nearest_local_segment_hit(local_hit, point, local_from)
	return local_hit


static func _intersect_local_segment_capsule(local_from: Vector3, local_to: Vector3, radius: float, height: float) -> Variant:
	var half_segment := max(0.0, height * 0.5 - radius)
	var closest_axis_y := clamp(local_from.y, -half_segment, half_segment)
	var closest_axis_point := Vector3(0.0, closest_axis_y, 0.0)
	if local_from.distance_squared_to(closest_axis_point) <= radius * radius:
		return local_from
	var local_hit: Variant = null
	if half_segment > MIN_DIRECTION_LENGTH_SQUARED:
		local_hit = _intersect_local_segment_cylinder_side(local_from, local_to, radius, half_segment)
	local_hit = _nearest_local_segment_hit(local_hit, _intersect_local_segment_sphere(local_from, local_to, Vector3(0.0, half_segment, 0.0), radius), local_from)
	local_hit = _nearest_local_segment_hit(local_hit, _intersect_local_segment_sphere(local_from, local_to, Vector3(0.0, -half_segment, 0.0), radius), local_from)
	return local_hit


static func _nearest_local_segment_hit(current_hit: Variant, candidate_hit: Variant, local_from: Vector3) -> Variant:
	if candidate_hit == null:
		return current_hit
	if current_hit == null:
		return candidate_hit
	if local_from.distance_squared_to(candidate_hit) < local_from.distance_squared_to(current_hit):
		return candidate_hit
	return current_hit


static func generate_collisionmap(image : Image, mesh_instance : MeshInstance3D, raycast_dist : float, raycast_layers : int, steps : int, step_length_divs : int, step_width_divs : int, river) -> Image:
	var space_state := mesh_instance.get_world_3d().direct_space_state
	var bake_collision_root := _get_bake_collision_root(mesh_instance, river)
	var direct_collision_shapes := collect_raycast_collision_shapes(bake_collision_root, raycast_layers)
	if direct_collision_shapes.is_empty():
		push_warning("Waterways: River collision bake found no direct CollisionShape3D nodes matching raycast layer mask %d under %s. Falling back to physics raycasts." % [raycast_layers, bake_collision_root.get_path()])
	
	var uv2 := mesh_instance.mesh.surface_get_arrays(0)[5] as PackedVector2Array
	var verts := mesh_instance.mesh.surface_get_arrays(0)[0] as PackedVector3Array
	# We need to move the verts into world space
	var world_verts := PackedVector3Array()
	for v in verts.size():
		world_verts.append(mesh_instance.global_transform * verts[v])
	
	var image_width := image.get_width()
	var image_height := image.get_height()
	if image_width <= 0 or image_height <= 0 or steps <= 0:
		return image
	var safe_step_length_divs: int = clamp(step_length_divs, SHAPE_STEP_DIVS_MIN, SHAPE_STEP_DIVS_MAX)
	var safe_step_width_divs: int = clamp(step_width_divs, SHAPE_STEP_DIVS_MIN, SHAPE_STEP_DIVS_MAX)
	var tris_in_step_quad: int = safe_step_length_divs * safe_step_width_divs * 2
	var side := max(1, calculate_side(steps))
	var tile_width := float(image_width) / float(side)
	var tile_height := float(image_height) / float(side)
	var percentage = 0.0
	river.emit_signal("progress_notified", percentage, "Calculating Collisions (" + str(image_width) + "x" + str(image_height) + ")")
	await river.get_tree().process_frame
	for x in image_width:
		var cur_percentage = float(x) / float(image_width)
		if cur_percentage > percentage + 0.1:
			percentage += 0.1
			river.emit_signal("progress_notified", percentage, "Calculating Collisions (" + str(image_width) + "x" + str(image_height) + ")")
			await river.get_tree().process_frame
		for y in image_height:
			var uv_coordinate := Vector2( ( 0.5 + float(x))  / float(image_width), ( 0.5 + float(y)) / float(image_height) )
			var baryatric_coords : Vector3
			var correct_triangle := []
			
			var column: int = clamp(int(floor(float(x) / tile_width)), 0, side - 1)
			var row: int = clamp(int(floor(float(y) / tile_height)), 0, side - 1)
			var step_quad: int = column * side + row
				
			if step_quad >= steps:
				break # we are in the empty part of UV2 so we break to the next column
			
			for tris in tris_in_step_quad:
				var offset_tris : int = (tris_in_step_quad * step_quad) + tris
				var triangle_index := offset_tris * 3
				if triangle_index + 2 >= uv2.size() or triangle_index + 2 >= world_verts.size():
					continue
				var triangle := PackedVector2Array()
				triangle.append(uv2[triangle_index])
				triangle.append(uv2[triangle_index + 1])
				triangle.append(uv2[triangle_index + 2])
				var p := Vector3(uv_coordinate.x, uv_coordinate.y, 0.0)
				if _is_degenerate_uv_triangle(triangle[0], triangle[1], triangle[2]):
					continue
				var a := Vector3(uv2[triangle_index].x, uv2[triangle_index].y, 0.0)
				var b := Vector3(uv2[triangle_index + 1].x, uv2[triangle_index + 1].y, 0.0)
				var c := Vector3(uv2[triangle_index + 2].x, uv2[triangle_index + 2].y, 0.0)
				baryatric_coords = cart2bary(p, a, b, c)
				
				if point_in_bariatric(baryatric_coords):
					correct_triangle = [triangle_index, triangle_index + 1, triangle_index + 2]
					break # we have the correct triangle so we break out of loop
			
			if correct_triangle:
				var vert0 : Vector3 = world_verts[correct_triangle[0]] 
				var vert1 : Vector3 = world_verts[correct_triangle[1]] 
				var vert2 : Vector3 = world_verts[correct_triangle[2]]
				
				var real_pos := bary2cart(vert0, vert1, vert2, baryatric_coords)
				if not _is_finite_vector3(real_pos):
					continue
				var real_pos_up := real_pos + Vector3.UP * raycast_dist
				if _intersects_collision_shapes_segment(direct_collision_shapes, real_pos_up, real_pos):
					image.set_pixel(x, y, Color(1.0, 1.0, 1.0))
					continue
				
				var query_up := PhysicsRayQueryParameters3D.create(real_pos, real_pos_up)
				query_up.collision_mask = raycast_layers
				var result_up: Dictionary = space_state.intersect_ray(query_up)
				var query_down := PhysicsRayQueryParameters3D.create(real_pos_up, real_pos)
				query_down.collision_mask = raycast_layers
				var result_down: Dictionary = space_state.intersect_ray(query_down)
				
				var up_hit_frontface := false
				if result_up:
					if result_up.normal.y < 0:
						up_hit_frontface = true
				
				if result_up or result_down:
					if not up_hit_frontface and result_down:
						image.set_pixel(x, y, Color(1.0, 1.0, 1.0))
	return image


# Adds offset margins so filters will correctly extend across UV edges
static func add_margins(image : Image, resolution : float, margin : float, occupied_steps: int = -1) -> Image:
	if image == null or image.is_empty():
		return image
	var resolution_int: int = max(1, int(round(resolution)))
	resolution_int = min(resolution_int, image.get_width())
	resolution_int = min(resolution_int, image.get_height())
	var margin_int: int = max(0, int(round(margin)))
	if margin_int <= 0:
		return image
	margin_int = min(margin_int, resolution_int)
	var with_margins_size: int = resolution_int + 2 * margin_int
	var image_with_margins := Image.create(with_margins_size, with_margins_size, false, image.get_format())
	image_with_margins.fill(Color(0.0, 0.0, 0.0, 0.0))
	
	image_with_margins.blend_rect(image, Rect2i(0, 0, resolution_int, resolution_int), Vector2i(margin_int, margin_int))
	image_with_margins.blend_rect(image, Rect2i(0, 0, resolution_int, margin_int), Vector2i(margin_int, 0))
	image_with_margins.blend_rect(image, Rect2i(0, resolution_int - margin_int, resolution_int, margin_int), Vector2i(margin_int, resolution_int + margin_int))
	image_with_margins.blend_rect(image, Rect2i(0, 0, margin_int, resolution_int), Vector2i(0, margin_int))
	image_with_margins.blend_rect(image, Rect2i(resolution_int - margin_int, 0, margin_int, resolution_int), Vector2i(resolution_int + margin_int, margin_int))
	image_with_margins.blend_rect(image, Rect2i(0, 0, margin_int, margin_int), Vector2i(0, 0))
	image_with_margins.blend_rect(image, Rect2i(resolution_int - margin_int, 0, margin_int, margin_int), Vector2i(resolution_int + margin_int, 0))
	image_with_margins.blend_rect(image, Rect2i(0, resolution_int - margin_int, margin_int, margin_int), Vector2i(0, resolution_int + margin_int))
	image_with_margins.blend_rect(image, Rect2i(resolution_int - margin_int, resolution_int - margin_int, margin_int, margin_int), Vector2i(resolution_int + margin_int, resolution_int + margin_int))
	
	# The UV2 atlas advances down a column before continuing at the top of the next column.
	# Extend row-wrapping seams from occupied tiles, but clamp the first and last real
	# tiles to themselves so empty atlas cells cannot bleed into River ends.
	if occupied_steps > 0:
		_add_uv2_column_continuation_margins(image_with_margins, image, resolution_int, margin_int, occupied_steps)
	else:
		image_with_margins.blend_rect(image, Rect2i(0, resolution_int - margin_int, resolution_int, margin_int), Vector2i(margin_int + margin_int, 0))
		image_with_margins.blend_rect(image, Rect2i(0, 0, resolution_int, margin_int), Vector2i(0, resolution_int + margin_int))
	
	return image_with_margins


static func _add_uv2_column_continuation_margins(padded: Image, source: Image, resolution: int, margin: int, occupied_steps: int) -> void:
	var side: int = max(1, calculate_side(occupied_steps))
	var max_steps: int = min(occupied_steps, side * side)
	if max_steps <= 0:
		return
	for step_index in max_steps:
		var tile := _uv2_tile_rect(step_index, side, resolution)
		var row := step_index % side
		if row == 0:
			var previous_step: int = max(0, step_index - 1)
			var previous_tile := _uv2_tile_rect(previous_step, side, resolution)
			var previous_strip := Rect2i(
				previous_tile.position.x,
				previous_tile.position.y + max(0, previous_tile.size.y - margin),
				previous_tile.size.x,
				min(margin, previous_tile.size.y)
			)
			var top_margin := Rect2i(tile.position.x + margin, 0, tile.size.x, margin)
			_copy_scaled_region(padded, top_margin, source, previous_strip)
		if row == side - 1:
			var next_step: int = min(max_steps - 1, step_index + 1)
			var next_tile := _uv2_tile_rect(next_step, side, resolution)
			var next_strip_y := next_tile.position.y
			if next_step == step_index:
				next_strip_y = next_tile.position.y + max(0, next_tile.size.y - margin)
			var next_strip := Rect2i(next_tile.position.x, next_strip_y, next_tile.size.x, min(margin, next_tile.size.y))
			var bottom_margin := Rect2i(tile.position.x + margin, resolution + margin, tile.size.x, margin)
			_copy_scaled_region(padded, bottom_margin, source, next_strip)


static func _uv2_tile_rect(step_index: int, side: int, resolution: int) -> Rect2i:
	var column := int(step_index / side)
	var row := step_index % side
	var x0 := int(floor(float(column) * float(resolution) / float(side)))
	var x1 := int(floor(float(column + 1) * float(resolution) / float(side)))
	var y0 := int(floor(float(row) * float(resolution) / float(side)))
	var y1 := int(floor(float(row + 1) * float(resolution) / float(side)))
	return Rect2i(x0, y0, max(1, x1 - x0), max(1, y1 - y0))


static func _copy_scaled_region(destination: Image, destination_rect: Rect2i, source: Image, source_rect: Rect2i) -> void:
	if destination_rect.size.x <= 0 or destination_rect.size.y <= 0 or source_rect.size.x <= 0 or source_rect.size.y <= 0:
		return
	for y in destination_rect.size.y:
		var source_y := source_rect.position.y + int(floor((float(y) + 0.5) * float(source_rect.size.y) / float(destination_rect.size.y)))
		source_y = clamp(source_y, source_rect.position.y, source_rect.position.y + source_rect.size.y - 1)
		for x in destination_rect.size.x:
			var source_x := source_rect.position.x + int(floor((float(x) + 0.5) * float(source_rect.size.x) / float(destination_rect.size.x)))
			source_x = clamp(source_x, source_rect.position.x, source_rect.position.x + source_rect.size.x - 1)
			destination.set_pixel(destination_rect.position.x + x, destination_rect.position.y + y, source.get_pixel(source_x, source_y))


static func reorder_params(unordered_params : Array) -> Array:
	var ordered = []
	
	for param in unordered_params:
		if param.hint_string != "Texture":
			ordered.append(param)
		else:
			#find the last index in ordered with the same
			var prefix = param.name.rsplit("_")[0]
			var index = last_prefix_occurence(ordered, prefix)
			if index != -1:
				ordered.insert(index, param)
			else:
				ordered.append(param)
	return ordered


static func last_prefix_occurence(array : Array, search : String) -> int:
	var inverted_array = array.duplicate(true)
	inverted_array.invert()
	
	for i in array.size():
		var prefix = inverted_array[i].name.rsplit("_")[0]
		if prefix ==  search:
			return array.size() - i
	
	return -1
