class_name SurfaceDefinition
extends Resource

enum FootstepFamily { CARPET, CONCRETE, METAL, GLASS, ENERGY }

@export var display_name := "New Surface"
@export_multiline var designer_notes := ""
@export var material: Material
@export var palette_color := Color("5d6470")
@export var footstep_family := FootstepFamily.CONCRETE
@export_range(0.0, 100.0, 0.5, "suffix:/s") var contact_damage := 0.0
@export var editor_category := "Architecture"

