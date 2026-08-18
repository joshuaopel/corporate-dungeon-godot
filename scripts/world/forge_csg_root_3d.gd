@tool
class_name ForgeCSGRoot3D
extends CSGCombiner3D

@export_category("Cubicle Forge CSG")
@export_multiline var designer_notes := "Editable brush source. Use Cubicle Forge > Bake Selected CSG before shipping the level."
@export_range(0.05, 2.0, 0.05, "suffix:m") var authoring_grid := 0.25
@export var baked_node_name: StringName
@export var strip_source_at_runtime := true

func _ready() -> void:
	use_collision = false
	if Engine.is_editor_hint() or not strip_source_at_runtime or baked_node_name.is_empty():
		return
	var baked := get_parent().get_node_or_null(NodePath(baked_node_name)) as Node3D
	if baked:
		baked.visible = true
	call_deferred("queue_free")

func get_baked_geometry() -> StaticBody3D:
	if baked_node_name.is_empty() or get_parent() == null:
		return null
	return get_parent().get_node_or_null(NodePath(baked_node_name)) as StaticBody3D

