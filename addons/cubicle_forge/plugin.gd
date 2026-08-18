@tool
extends EditorPlugin

const FORGE_BLOCK_SCRIPT := preload("res://scripts/world/forge_block_3d.gd")
const FORGE_CSG_ROOT_SCRIPT := preload("res://scripts/world/forge_csg_root_3d.gd")
const FORGE_BRUSH_SCRIPT := preload("res://scripts/world/forge_brush_3d.gd")
const DOCK_SCRIPT := preload("res://addons/cubicle_forge/forge_dock.gd")
const CONTENT_DOCK_SCRIPT := preload("res://addons/cubicle_forge/content_studio_dock.gd")
const ICON := preload("res://addons/cubicle_forge/forge_block_icon.svg")

var _dock: Control
var _content_dock: Control

func _enter_tree() -> void:
	add_custom_type("ForgeBlock3D", "StaticBody3D", FORGE_BLOCK_SCRIPT, ICON)
	add_custom_type("ForgeCSGRoot3D", "CSGCombiner3D", FORGE_CSG_ROOT_SCRIPT, ICON)
	add_custom_type("ForgeBrush3D", "CSGBox3D", FORGE_BRUSH_SCRIPT, ICON)
	_dock = DOCK_SCRIPT.new()
	_dock.setup(get_editor_interface())
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)
	_content_dock = CONTENT_DOCK_SCRIPT.new()
	_content_dock.setup(get_editor_interface())
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _content_dock)

func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
	if _content_dock:
		remove_control_from_docks(_content_dock)
		_content_dock.queue_free()
	remove_custom_type("ForgeBrush3D")
	remove_custom_type("ForgeCSGRoot3D")
	remove_custom_type("ForgeBlock3D")
