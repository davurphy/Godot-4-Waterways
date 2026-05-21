# Copyright © 2021 Kasper Arnklit Frandsen - MIT License
# See `LICENSE.md` included in the source distribution for details.
@tool
extends MenuButton

signal generate_flowmap
signal generate_mesh
signal validate_data_textures
signal validate_filter_renderer
signal debug_view_changed

enum RIVER_MENU {
	GENERATE,
	GENERATE_MESH,
	VALIDATE_DATA_TEXTURES,
	VALIDATE_FILTER_RENDERER,
	DEBUG_VIEW_MENU
}

var debug_view_menu_selected := 0

var _debug_view_menu : PopupMenu


func _enter_tree() -> void:
	get_popup().clear()
	get_popup().connect("id_pressed", Callable(self, "_menu_item_selected"))
	get_popup().add_item("Generate Flow & Foam Map", RIVER_MENU.GENERATE)
	get_popup().add_item("Generate MeshInstance3D Sibling", RIVER_MENU.GENERATE_MESH)
	get_popup().add_item("Validate Data Textures", RIVER_MENU.VALIDATE_DATA_TEXTURES)
	get_popup().add_item("Validate Filter Renderer", RIVER_MENU.VALIDATE_FILTER_RENDERER)
	_debug_view_menu = PopupMenu.new()
	_debug_view_menu.name = "DebugViewMenu"
	_debug_view_menu.connect("about_to_popup", Callable(self, "_on_debug_view_menu_about_to_show"))
	_debug_view_menu.connect("id_pressed", Callable(self, "_debug_menu_item_selected"))
	get_popup().add_child(_debug_view_menu)
	get_popup().add_submenu_item("Debug View", _debug_view_menu.name, RIVER_MENU.DEBUG_VIEW_MENU)


func _exit_tree() -> void:
	get_popup().disconnect("id_pressed", Callable(self, "_menu_item_selected"))
	_debug_view_menu.disconnect("about_to_popup", Callable(self, "_on_debug_view_menu_about_to_show"))
	_debug_view_menu.disconnect("id_pressed", Callable(self, "_debug_menu_item_selected"))


func _menu_item_selected(index : int) -> void:
	match index:
		RIVER_MENU.GENERATE:
			emit_signal("generate_flowmap")
		RIVER_MENU.GENERATE_MESH:
			emit_signal("generate_mesh")
		RIVER_MENU.VALIDATE_DATA_TEXTURES:
			emit_signal("validate_data_textures")
		RIVER_MENU.VALIDATE_FILTER_RENDERER:
			emit_signal("validate_filter_renderer")
		RIVER_MENU.DEBUG_VIEW_MENU:
			pass


func _debug_menu_item_selected(index: int) -> void:
	debug_view_menu_selected = index
	emit_signal("debug_view_changed", index)


func _on_debug_view_menu_about_to_show() -> void:
	_debug_view_menu.clear()
	_debug_view_menu.add_radio_check_item("Display Normal", 0)
	_debug_view_menu.add_radio_check_item("Display Debug Flow Map (RG)", 1)
	_debug_view_menu.add_radio_check_item("Display Debug Foam Map (B)", 2)
	_debug_view_menu.add_radio_check_item("Display Debug Noise Map (A)", 3)
	_debug_view_menu.add_radio_check_item("Display Debug Distance Field Map (R)", 4)
	_debug_view_menu.add_radio_check_item("Display Debug Pressure Map (G)", 5)
	_debug_view_menu.add_radio_check_item("Display Debug Flow Pattern", 6)
	_debug_view_menu.add_radio_check_item("Display Debug Flow Arrows", 7)
	_debug_view_menu.add_radio_check_item("Display Debug Flow Strength", 8)
	_debug_view_menu.add_radio_check_item("Display Debug Foam Mix", 9)
	var checked_index := _debug_view_menu.get_item_index(debug_view_menu_selected)
	if checked_index >= 0:
		_debug_view_menu.set_item_checked(checked_index, true)
