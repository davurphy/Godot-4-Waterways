# Copyright (c) 2021 Kasper Arnklit Frandsen - MIT License
# See `LICENSE.md` included in the source distribution for details.
@tool
extends Resource
class_name RiverBakeData

const DEFAULT_CHANNEL_METADATA := {
	"flow_foam_noise": {
		"r": "signed_flow_x_packed_0_to_1_neutral_0_5",
		"g": "signed_flow_y_packed_0_to_1_neutral_0_5",
		"b": "foam_mask_neutral_0",
		"a": "phase_noise_optional_neutral_0"
	},
	"dist_pressure": {
		"r": "bank_distance_or_edge_influence",
		"g": "flow_pressure_or_occupancy",
		"b": "reserved",
		"a": "reserved"
	}
}

const DEFAULT_IMPORT_PROFILE := {
	"color_space": "linear",
	"srgb": false,
	"compression": "uncompressed_or_lossless",
	"mipmaps": false,
	"neutral_flow": Vector2(0.5, 0.5)
}

const TEXTURE_LAYOUT_PADDED_UV2_ATLAS := "padded_uv2_atlas_with_one_tile_margin"
const SOURCE_KIND_SPLINE_COLLISION_BAKE := "generated_spline_collision_bake"

@export var flow_foam_noise: Texture2D
@export var dist_pressure: Texture2D
@export var texture_size := Vector2i.ZERO
@export var source_texture_size := Vector2i.ZERO
@export var content_rect := Rect2i()
@export var texture_layout := TEXTURE_LAYOUT_PADDED_UV2_ATLAS
@export var uv2_sides := 0
@export var mesh_global_bounds := AABB()
@export var source_kind := SOURCE_KIND_SPLINE_COLLISION_BAKE
@export var source_metadata: Dictionary = {}
@export var channel_metadata: Dictionary = {}
@export var import_profile: Dictionary = {}
@export var bake_settings: Dictionary = {}
@export var source_signature_version := 0
@export var source_signature: Dictionary = {}


func _init() -> void:
	if channel_metadata.is_empty():
		channel_metadata = DEFAULT_CHANNEL_METADATA.duplicate(true)
	if import_profile.is_empty():
		import_profile = DEFAULT_IMPORT_PROFILE.duplicate(true)


func set_from_bake(
		new_flow_foam_noise: Texture2D,
		new_dist_pressure: Texture2D,
		new_texture_size: Vector2i,
		new_uv2_sides: int,
		new_mesh_global_bounds: AABB,
		new_bake_settings: Dictionary,
		new_source_texture_size: Vector2i,
		new_content_rect: Rect2i,
		new_texture_layout: String,
		new_source_kind: String,
		new_source_metadata: Dictionary,
		new_source_signature: Dictionary = {}
) -> void:
	flow_foam_noise = new_flow_foam_noise
	dist_pressure = new_dist_pressure
	texture_size = new_texture_size
	source_texture_size = new_source_texture_size
	content_rect = new_content_rect
	texture_layout = new_texture_layout
	uv2_sides = new_uv2_sides
	mesh_global_bounds = new_mesh_global_bounds
	source_kind = new_source_kind
	source_metadata = new_source_metadata.duplicate(true)
	bake_settings = new_bake_settings.duplicate(true)
	source_signature = new_source_signature.duplicate(true)
	source_signature_version = int(source_signature.get("version", 0))
	channel_metadata = DEFAULT_CHANNEL_METADATA.duplicate(true)
	import_profile = DEFAULT_IMPORT_PROFILE.duplicate(true)


func has_required_textures() -> bool:
	return flow_foam_noise != null and dist_pressure != null


func has_matching_source_signature(current_signature: Dictionary) -> bool:
	return not source_signature.is_empty() and source_signature == current_signature
