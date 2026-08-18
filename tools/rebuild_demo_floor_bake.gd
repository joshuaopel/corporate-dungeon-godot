extends SceneTree

const SOURCE_SCENE := "res://scenes/levels/demo_floor_source.tscn"
const OUTPUT_FOLDER := "res://generated/forge_bakes"
const MESH_PATH := OUTPUT_FOLDER + "/demo_floor_mesh.res"
const COLLISION_PATH := OUTPUT_FOLDER + "/demo_floor_collision.res"

func _initialize() -> void:
	call_deferred("_rebuild")

func _rebuild() -> void:
	var packed := load(SOURCE_SCENE) as PackedScene
	if packed == null:
		_fail("Could not load " + SOURCE_SCENE)
		return
	var source := packed.instantiate() as Node3D
	root.add_child(source)
	await process_frame
	var csg := CSGCombiner3D.new()
	csg.name = "DemoFloorBakeSource"
	root.add_child(csg)
	var block_count := 0
	for candidate in source.find_children("*", "ForgeBlock3D", true, false):
		var block := candidate as ForgeBlock3D
		if block == null or not block.block_enabled:
			continue
		var brush := CSGBox3D.new()
		brush.name = block.name
		brush.size = block.size
		brush.transform = block.transform
		brush.operation = CSGShape3D.OPERATION_UNION
		brush.use_collision = false
		if block.surface and block.surface.material:
			brush.material = block.surface.material
		csg.add_child(brush)
		block_count += 1
	await process_frame
	await process_frame
	var mesh := csg.bake_static_mesh()
	var collision := csg.bake_collision_shape()
	if mesh == null or mesh.get_surface_count() == 0:
		_fail("Demo CSG bake produced an empty mesh")
		return
	if collision == null or collision.get_faces().is_empty():
		_fail("Demo CSG bake produced empty collision")
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_FOLDER))
	var mesh_error := ResourceSaver.save(mesh, MESH_PATH)
	var collision_error := ResourceSaver.save(collision, COLLISION_PATH)
	if mesh_error != OK or collision_error != OK:
		_fail("Resource save failed: %s / %s" % [error_string(mesh_error), error_string(collision_error)])
		return
	print("DEMO FLOOR BAKE PASSED // %d blocks -> %d mesh surfaces" % [block_count, mesh.get_surface_count()])
	print(MESH_PATH)
	print(COLLISION_PATH)
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

