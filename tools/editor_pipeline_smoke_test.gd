extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var editor_scripts := [
		"res://addons/cubicle_forge/plugin.gd",
		"res://addons/cubicle_forge/forge_dock.gd",
		"res://addons/cubicle_forge/content_studio_dock.gd",
		"res://addons/cubicle_forge/content_preview.gd",
	]
	for path in editor_scripts:
		var loaded_script := load(path) as Script
		_check(loaded_script != null and loaded_script.can_instantiate(), "Editor script compiles: " + path.get_file())

	var host := Node3D.new()
	root.add_child(host)
	var csg_root := ForgeCSGRoot3D.new()
	host.add_child(csg_root)
	var solid := ForgeBrush3D.new()
	solid.size = Vector3(8, 4, 8)
	solid.position = Vector3(0, 2, 0)
	csg_root.add_child(solid)
	var cut := ForgeBrush3D.new()
	cut.size = Vector3(6, 3, 6)
	cut.position = Vector3(0, 2, 0)
	cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	csg_root.add_child(cut)
	await process_frame
	await process_frame
	var mesh := csg_root.bake_static_mesh()
	var collision := csg_root.bake_collision_shape()
	_check(mesh != null and mesh.get_surface_count() > 0, "Boolean CSG bakes a static mesh")
	_check(collision != null and collision.get_faces().size() > 0, "Boolean CSG bakes concave collision")
	host.queue_free()
	await process_frame

	if _failures.is_empty():
		print("EDITOR PIPELINE SMOKE TEST PASSED")
		quit(0)
	else:
		print("EDITOR PIPELINE SMOKE TEST FAILED: ", _failures)
		quit(1)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("[PASS] ", label)
	else:
		push_error("[FAIL] " + label)
		_failures.append(label)
