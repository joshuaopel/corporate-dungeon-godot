@tool
class_name ForgeBlock3D
extends StaticBody3D

@export_category("Cubicle Forge")
@export var size := Vector3(4.0, 1.0, 4.0):
	set(value):
		size = Vector3(maxf(snappedf(value.x, 0.25), 0.25), maxf(snappedf(value.y, 0.25), 0.25), maxf(snappedf(value.z, 0.25), 0.25))
		_queue_rebuild()
@export var surface: SurfaceDefinition:
	set(value):
		surface = value
		_queue_rebuild()
@export_enum("Architecture", "Floor", "Cover", "Trim", "Hazard") var block_role := "Architecture"
@export var cast_shadow := true:
	set(value):
		cast_shadow = value
		_queue_rebuild()

const MESH_NAME := &"__ForgeMesh"
const COLLISION_NAME := &"__ForgeCollision"
var _rebuild_queued := false

func _ready() -> void:
	_rebuild()

func paint_surface(new_surface: SurfaceDefinition) -> void:
	surface = new_surface

func _queue_rebuild() -> void:
	if not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")

func _rebuild() -> void:
	_rebuild_queued = false
	var mesh_instance := get_node_or_null(NodePath(MESH_NAME)) as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = MESH_NAME
		add_child(mesh_instance)
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	if surface and surface.material:
		box_mesh.material = surface.material
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = Color("59616d")
		fallback.roughness = 0.78
		box_mesh.material = fallback
	mesh_instance.mesh = box_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var collision := get_node_or_null(NodePath(COLLISION_NAME)) as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = COLLISION_NAME
		add_child(collision)
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision.shape = box_shape

