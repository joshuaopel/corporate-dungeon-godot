@tool
class_name ForgeBrush3D
extends CSGBox3D

@export_category("Cubicle Forge Brush")
@export var surface: SurfaceDefinition:
	set(value):
		surface = value
		_sync_surface()
@export_enum("Architecture", "Floor", "Cover", "Trim", "Door Cut", "Window Cut", "Detail") var brush_role := "Architecture"
@export_multiline var designer_notes := "Resize with the built-in CSG box handles. Operation controls Union, Intersection, or Subtraction."

func _ready() -> void:
	use_collision = false
	_sync_surface()

func paint_surface(new_surface: SurfaceDefinition) -> void:
	surface = new_surface

func set_brush_operation(new_operation: CSGShape3D.Operation) -> void:
	operation = new_operation

func _sync_surface() -> void:
	if surface and surface.material:
		material = surface.material

