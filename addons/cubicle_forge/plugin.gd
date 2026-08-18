@tool
extends EditorPlugin

const FORGE_BLOCK_SCRIPT := preload("res://scripts/world/forge_block_3d.gd")
const DOCK_SCRIPT := preload("res://addons/cubicle_forge/forge_dock.gd")
const ICON := preload("res://addons/cubicle_forge/forge_block_icon.svg")

var _dock: Control

func _enter_tree() -> void:
	add_custom_type("ForgeBlock3D", "StaticBody3D", FORGE_BLOCK_SCRIPT, ICON)
	_dock = DOCK_SCRIPT.new()
	_dock.setup(get_editor_interface())
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)

func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
	remove_custom_type("ForgeBlock3D")

