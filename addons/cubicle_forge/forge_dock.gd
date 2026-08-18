@tool
extends VBoxContainer

const DEFAULT_SOLID := "res://content/surfaces/concrete.tres"
const DEFAULT_WALL := "res://content/surfaces/obsidian_panel.tres"
const DEFAULT_FLOOR := "res://content/surfaces/blue_carpet.tres"
const DEFAULT_CUT := "res://content/surfaces/magenta_emissive.tres"
const BAKE_FOLDER := "res://generated/forge_bakes"

var _editor_interface: EditorInterface
var _surface_list: VBoxContainer
var _status: Label

func setup(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface
	name = "Cubicle Forge"
	custom_minimum_size = Vector2(275, 0)
	_build_ui()
	call_deferred("_refresh_surfaces")

func _build_ui() -> void:
	var title := Label.new()
	title.text = "CUBICLE FORGE // 2.0"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("65f4d5"))
	add_child(title)

	var copy := Label.new()
	copy.text = "Editable CSG brushes for authoring.\nBake to one static mesh for gameplay."
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.modulate = Color(0.72, 0.78, 0.82)
	add_child(copy)

	add_child(HSeparator.new())
	_add_section_label("BOOLEAN BRUSHES")
	var brush_grid := GridContainer.new()
	brush_grid.columns = 2
	add_child(brush_grid)
	_add_grid_button(brush_grid, "+ ADD BOX", func() -> void: _add_box_brush(CSGShape3D.OPERATION_UNION))
	_add_grid_button(brush_grid, "− CUT BOX", func() -> void: _add_box_brush(CSGShape3D.OPERATION_SUBTRACTION))
	_add_grid_button(brush_grid, "∩ INTERSECT", func() -> void: _add_box_brush(CSGShape3D.OPERATION_INTERSECTION))
	_add_grid_button(brush_grid, "+ CYLINDER", func() -> void: _add_cylinder(CSGShape3D.OPERATION_UNION))
	_add_grid_button(brush_grid, "− CYLINDER", func() -> void: _add_cylinder(CSGShape3D.OPERATION_SUBTRACTION))
	_add_grid_button(brush_grid, "DOOR CUT", _add_door_cut)

	_add_section_label("GENERATORS")
	var generator_grid := GridContainer.new()
	generator_grid.columns = 2
	add_child(generator_grid)
	_add_grid_button(generator_grid, "ROOM SHELL", _add_room_shell)
	_add_grid_button(generator_grid, "STAIR RUN", _add_stairs)
	_add_grid_button(generator_grid, "BLOCKS → CSG", _convert_selected_blocks)
	_add_grid_button(generator_grid, "LEGACY BLOCK", _add_legacy_block)

	add_child(HSeparator.new())
	_add_section_label("BAKE / EDIT")
	var bake_button := Button.new()
	bake_button.text = "BAKE SELECTED CSG FOR GAMEPLAY"
	bake_button.tooltip_text = "Creates one static ArrayMesh and one concave collision resource, then hides the editable CSG source."
	bake_button.pressed.connect(_bake_selected)
	add_child(bake_button)
	var mode_row := HBoxContainer.new()
	add_child(mode_row)
	_add_action_button(mode_row, "EDIT SOURCE", _show_source)
	_add_action_button(mode_row, "SHOW BAKE", _show_bake)

	add_child(HSeparator.new())
	_add_section_label("PAINT SELECTED")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 190
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	_surface_list = VBoxContainer.new()
	_surface_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_surface_list)
	var refresh := Button.new()
	refresh.text = "REFRESH PALETTE"
	refresh.pressed.connect(_refresh_surfaces)
	add_child(refresh)
	_status = Label.new()
	_status.text = "Select a CSG root, brush, or legacy block."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.7, 0.75, 0.8)
	add_child(_status)

func _add_section_label(caption: String) -> void:
	var label := Label.new()
	label.text = caption
	label.add_theme_color_override("font_color", Color("ffcf5a"))
	add_child(label)

func _add_grid_button(parent: GridContainer, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)

func _add_action_button(parent: HBoxContainer, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)

func _refresh_surfaces() -> void:
	for child in _surface_list.get_children():
		child.queue_free()
	var paths: Array[String] = []
	var directory := DirAccess.open("res://content/surfaces")
	if directory:
		for file_name in directory.get_files():
			if file_name.get_extension() == "tres":
				paths.append("res://content/surfaces/" + file_name)
	paths.sort()
	var loaded_count := 0
	for path in paths:
		var loaded := load(path)
		if loaded is SurfaceDefinition:
			_add_surface_button(loaded)
			loaded_count += 1
	_status.text = "%d surfaces loaded." % loaded_count

func _add_surface_button(surface: SurfaceDefinition) -> void:
	var button := Button.new()
	button.text = "  " + surface.display_name
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.tooltip_text = surface.resource_path
	var swatch := StyleBoxFlat.new()
	swatch.bg_color = surface.palette_color.darkened(0.55)
	swatch.border_width_left = 8
	swatch.border_color = surface.palette_color
	swatch.corner_radius_top_left = 3
	swatch.corner_radius_top_right = 3
	swatch.corner_radius_bottom_left = 3
	swatch.corner_radius_bottom_right = 3
	button.add_theme_stylebox_override("normal", swatch)
	button.pressed.connect(func() -> void: _paint_selection(surface))
	_surface_list.add_child(button)

func _paint_selection(surface: SurfaceDefinition) -> void:
	var painted := 0
	for node in _editor_interface.get_selection().get_selected_nodes():
		if node is ForgeBlock3D or node is ForgeBrush3D:
			node.paint_surface(surface)
			painted += 1
		elif node is CSGPrimitive3D:
			node.material = surface.material
			node.set_meta("forge_surface", surface.resource_path)
			painted += 1
	if painted > 0:
		_editor_interface.mark_scene_as_unsaved()
		_status.text = "Painted %d brush(es): %s" % [painted, surface.display_name]
	else:
		_status.text = "Select a Forge brush, CSG primitive, or legacy block."

func _add_box_brush(operation: CSGShape3D.Operation) -> void:
	var root := _selected_csg_root()
	if root == null:
		if operation != CSGShape3D.OPERATION_UNION:
			_status.text = "Create an additive brush or room before adding a boolean cut."
			return
		root = _create_csg_root("ForgeGeometry")
	if root == null:
		_status.text = "Open or create a 3D scene first."
		return
	if operation != CSGShape3D.OPERATION_UNION and root.get_child_count() == 0:
		_status.text = "A boolean root needs an additive brush first."
		return
	var brush := _create_box(root, _operation_name(operation), Vector3(2, 2, 2), _next_brush_position(root, operation), operation, _surface_for_operation(operation))
	_select_node(brush)
	_status.text = "%s brush added. Resize it with the viewport handles." % _operation_name(operation)

func _add_cylinder(operation: CSGShape3D.Operation) -> void:
	var root := _selected_csg_root()
	if root == null:
		if operation != CSGShape3D.OPERATION_UNION:
			_status.text = "Create an additive brush or room before adding a cylinder cut."
			return
		root = _create_csg_root("ForgeGeometry")
	if root == null:
		_status.text = "Open or create a 3D scene first."
		return
	var cylinder := CSGCylinder3D.new()
	cylinder.name = "AddCylinder" if operation == CSGShape3D.OPERATION_UNION else "CutCylinder"
	cylinder.radius = 1.0
	cylinder.height = 2.5
	cylinder.sides = 24
	cylinder.operation = operation
	cylinder.use_collision = false
	var surface := _surface_for_operation(operation)
	if surface:
		cylinder.material = surface.material
		cylinder.set_meta("forge_surface", surface.resource_path)
	root.add_child(cylinder)
	cylinder.owner = _scene_root()
	cylinder.position = _next_brush_position(root, operation)
	_select_node(cylinder)
	_editor_interface.mark_scene_as_unsaved()
	_status.text = "%s cylinder added." % _operation_name(operation)

func _add_room_shell() -> void:
	if _scene_root() == null:
		_status.text = "Open or create a 3D scene first."
		return
	var root := _create_csg_root("RoomCSG")
	root.position = _next_root_position()
	var wall_surface: SurfaceDefinition = load(DEFAULT_WALL)
	var cut_surface: SurfaceDefinition = load(DEFAULT_CUT)
	_create_box(root, "RoomVolume", Vector3(16, 5.5, 16), Vector3(0, 2.75, 0), CSGShape3D.OPERATION_UNION, wall_surface)
	var interior := _create_box(root, "RoomInteriorCut", Vector3(15, 4.5, 15), Vector3(0, 2.75, 0), CSGShape3D.OPERATION_SUBTRACTION, cut_surface)
	interior.brush_role = "Architecture"
	_select_node(root)
	_editor_interface.mark_scene_as_unsaved()
	_status.text = "Created an editable hollow CSG room. Add a Door Cut, then bake."

func _add_door_cut() -> void:
	var root := _selected_csg_root()
	if root == null or root.get_child_count() == 0:
		_status.text = "Select a CSG room/root before adding a door cut."
		return
	var cut := _create_box(root, "DoorCut", Vector3(2.2, 2.8, 1.5), Vector3(0, 1.4, -7.8), CSGShape3D.OPERATION_SUBTRACTION, load(DEFAULT_CUT))
	cut.brush_role = "Door Cut"
	_select_node(cut)
	_editor_interface.mark_scene_as_unsaved()
	_status.text = "Door cut added. Move it onto any wall and resize with handles."

func _add_stairs() -> void:
	var root := _selected_csg_root()
	if root == null:
		root = _create_csg_root("StairCSG")
		if root == null:
			_status.text = "Open or create a 3D scene first."
			return
		root.position = _next_root_position()
	var surface: SurfaceDefinition = load(DEFAULT_SOLID)
	var steps := 8
	var rise := 0.25
	var run := 0.65
	for index in steps:
		var height := rise * float(index + 1)
		_create_box(root, "Step%02d" % (index + 1), Vector3(4, height, run), Vector3(0, height * 0.5, -float(index) * run), CSGShape3D.OPERATION_UNION, surface)
	_select_node(root)
	_editor_interface.mark_scene_as_unsaved()
	_status.text = "Created an 8-step additive stair run."

func _convert_selected_blocks() -> void:
	var blocks: Array[ForgeBlock3D] = []
	for selected in _editor_interface.get_selection().get_selected_nodes():
		if selected is ForgeBlock3D:
			blocks.append(selected)
	if blocks.is_empty():
		_status.text = "Select one or more legacy ForgeBlock3D nodes first."
		return
	var root := _create_csg_root("ConvertedCSG")
	if root == null:
		_status.text = "Open or create a 3D scene first."
		return
	root.global_transform = Transform3D.IDENTITY
	for block in blocks:
		var brush := _create_box(root, block.name, block.size, Vector3.ZERO, CSGShape3D.OPERATION_UNION, block.surface)
		brush.global_transform = block.global_transform
		brush.brush_role = block.block_role
		block.block_enabled = false
	_select_node(root)
	_editor_interface.mark_scene_as_unsaved()
	_status.text = "Converted %d blocks. Originals are disabled, not deleted. Review, then bake." % blocks.size()

func _add_legacy_block() -> void:
	var scene_root := _scene_root()
	if scene_root == null:
		_status.text = "Open or create a 3D scene first."
		return
	var block := ForgeBlock3D.new()
	block.name = "ForgeBlock"
	block.size = Vector3(2, 2, 2)
	block.position = _next_root_position()
	block.surface = load(DEFAULT_SOLID)
	scene_root.add_child(block)
	block.owner = scene_root
	_select_node(block)
	_editor_interface.mark_scene_as_unsaved()
	_status.text = "Legacy modular block added. Prefer CSG + Bake for structural level geometry."

func _create_csg_root(root_name: String) -> ForgeCSGRoot3D:
	var scene_root := _scene_root()
	if scene_root == null:
		return null
	var root := ForgeCSGRoot3D.new()
	root.name = root_name
	root.use_collision = false
	scene_root.add_child(root)
	root.owner = scene_root
	return root

func _create_box(parent: ForgeCSGRoot3D, brush_name: String, brush_size: Vector3, brush_position: Vector3, operation: CSGShape3D.Operation, surface: SurfaceDefinition) -> ForgeBrush3D:
	var brush := ForgeBrush3D.new()
	brush.name = brush_name
	brush.size = brush_size
	brush.position = brush_position
	brush.operation = operation
	brush.surface = surface
	brush.use_collision = false
	parent.add_child(brush)
	brush.owner = _scene_root()
	return brush

func _surface_for_operation(operation: CSGShape3D.Operation) -> SurfaceDefinition:
	return load(DEFAULT_CUT if operation == CSGShape3D.OPERATION_SUBTRACTION else DEFAULT_SOLID)

func _operation_name(operation: CSGShape3D.Operation) -> String:
	match operation:
		CSGShape3D.OPERATION_INTERSECTION: return "Intersect"
		CSGShape3D.OPERATION_SUBTRACTION: return "Cut"
	return "Add"

func _selected_csg_root() -> ForgeCSGRoot3D:
	for selected in _editor_interface.get_selection().get_selected_nodes():
		var current: Node = selected
		while current:
			if current is ForgeCSGRoot3D:
				return current
			current = current.get_parent()
	return null

func _next_brush_position(root: ForgeCSGRoot3D, operation: CSGShape3D.Operation) -> Vector3:
	var selected := _editor_interface.get_selection().get_selected_nodes()
	if not selected.is_empty() and selected[0] is CSGShape3D and selected[0].get_parent() == root:
		var shape := selected[0] as CSGShape3D
		return shape.position if operation != CSGShape3D.OPERATION_UNION else shape.position + Vector3(2.25, 0, 0)
	return Vector3.ZERO

func _next_root_position() -> Vector3:
	var selected := _editor_interface.get_selection().get_selected_nodes()
	if not selected.is_empty() and selected[0] is Node3D:
		var node := selected[0] as Node3D
		return Vector3(snappedf(node.position.x + 2.0, 0.25), snappedf(node.position.y, 0.25), snappedf(node.position.z, 0.25))
	return Vector3.ZERO

func _scene_root() -> Node:
	return _editor_interface.get_edited_scene_root()

func _select_node(node: Node) -> void:
	_editor_interface.get_selection().clear()
	_editor_interface.get_selection().add_node(node)

func _bake_selected() -> void:
	var root := _selected_csg_root()
	if root == null:
		_status.text = "Select a ForgeCSGRoot3D or one of its brushes first."
		return
	if root.get_child_count() == 0:
		_status.text = "The selected CSG root has no brushes."
		return
	var previous_visibility := root.visible
	root.visible = true
	var existing_bake := root.get_baked_geometry()
	if existing_bake:
		existing_bake.visible = false
	_status.text = "Baking CSG mesh and collision…"
	await get_tree().process_frame
	await get_tree().process_frame
	var mesh := root.bake_static_mesh()
	var collision := root.bake_collision_shape()
	if mesh == null or mesh.get_surface_count() == 0:
		root.visible = previous_visibility
		_status.text = "Bake failed: the CSG result is empty. Check brush order and intersections."
		return
	var absolute_bake_folder := ProjectSettings.globalize_path(BAKE_FOLDER)
	DirAccess.make_dir_recursive_absolute(absolute_bake_folder)
	var scene_stem := _scene_root().scene_file_path.get_file().get_basename()
	if scene_stem.is_empty():
		scene_stem = "unsaved_scene"
	var stem := (scene_stem + "_" + root.name).to_snake_case()
	var mesh_path := BAKE_FOLDER + "/" + stem + "_mesh.res"
	var collision_path := BAKE_FOLDER + "/" + stem + "_collision.res"
	var mesh_error := ResourceSaver.save(mesh, mesh_path)
	var collision_error := ResourceSaver.save(collision, collision_path)
	if mesh_error != OK or collision_error != OK:
		root.visible = previous_visibility
		_status.text = "Bake resource save failed: mesh %s, collision %s" % [error_string(mesh_error), error_string(collision_error)]
		return
	var baked := _install_baked_geometry(root, mesh, collision)
	root.baked_node_name = baked.name
	root.visible = false
	baked.visible = true
	_select_node(baked)
	_editor_interface.get_resource_filesystem().scan()
	_editor_interface.mark_scene_as_unsaved()
	_status.text = "Baked %d material surface(s) to %s. Save the scene." % [mesh.get_surface_count(), mesh_path]

func _install_baked_geometry(root: ForgeCSGRoot3D, mesh: ArrayMesh, collision: ConcavePolygonShape3D) -> StaticBody3D:
	var parent := root.get_parent()
	var baked_name := StringName(root.name + "__BAKED")
	var baked := parent.get_node_or_null(NodePath(baked_name)) as StaticBody3D
	if baked == null:
		baked = StaticBody3D.new()
		baked.name = baked_name
		parent.add_child(baked)
		baked.owner = _scene_root()
	baked.transform = root.transform
	baked.collision_layer = 1
	baked.collision_mask = 2 | 4
	var mesh_instance := baked.get_node_or_null("Mesh") as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Mesh"
		baked.add_child(mesh_instance)
		mesh_instance.owner = _scene_root()
	mesh_instance.mesh = mesh
	var collision_shape := baked.get_node_or_null("Collision") as CollisionShape3D
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "Collision"
		baked.add_child(collision_shape)
		collision_shape.owner = _scene_root()
	collision_shape.shape = collision
	return baked

func _show_source() -> void:
	var root := _selected_csg_root()
	if root == null:
		root = _root_from_selected_bake()
	if root == null:
		_status.text = "Select a CSG root/brush or its baked geometry."
		return
	root.visible = true
	var baked := root.get_baked_geometry()
	if baked:
		baked.visible = false
	_select_node(root)
	_editor_interface.mark_scene_as_unsaved()
	_status.text = "Editing brush source. Re-bake after geometry changes."

func _show_bake() -> void:
	var root := _selected_csg_root()
	if root == null:
		root = _root_from_selected_bake()
	if root == null or root.get_baked_geometry() == null:
		_status.text = "No baked geometry is linked to this selection."
		return
	var baked := root.get_baked_geometry()
	root.visible = false
	baked.visible = true
	_select_node(baked)
	_editor_interface.mark_scene_as_unsaved()
	_status.text = "Showing optimized static bake."

func _root_from_selected_bake() -> ForgeCSGRoot3D:
	var selected := _editor_interface.get_selection().get_selected_nodes()
	if selected.is_empty() or not selected[0] is StaticBody3D:
		return null
	var baked := selected[0] as StaticBody3D
	for sibling in baked.get_parent().get_children():
		if sibling is ForgeCSGRoot3D and sibling.baked_node_name == baked.name:
			return sibling
	return null
