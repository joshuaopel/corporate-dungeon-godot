@tool
extends VBoxContainer

var _editor_interface: EditorInterface
var _surface_list: VBoxContainer
var _status: Label

func setup(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface
	name = "Cubicle Forge"
	custom_minimum_size = Vector2(250, 0)
	_build_ui()
	call_deferred("_refresh_surfaces")

func _build_ui() -> void:
	var title := Label.new()
	title.text = "CUBICLE FORGE // 1.0"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("65f4d5"))
	add_child(title)

	var copy := Label.new()
	copy.text = "Doom-style blockout, Godot-native scenes.\nEverything snaps to a 0.25 m grid."
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.modulate = Color(0.72, 0.78, 0.82)
	add_child(copy)

	add_child(HSeparator.new())
	var build_label := Label.new()
	build_label.text = "BUILD"
	add_child(build_label)
	var block_button := Button.new()
	block_button.text = "+ 2m BLOCK"
	block_button.tooltip_text = "Adds a grid-snapped ForgeBlock next to the current selection."
	block_button.pressed.connect(_add_block)
	add_child(block_button)
	var room_button := Button.new()
	room_button.text = "+ 16m TEST ROOM"
	room_button.tooltip_text = "Creates a floor and four walls as individually paintable blocks."
	room_button.pressed.connect(_add_room)
	add_child(room_button)

	add_child(HSeparator.new())
	var paint_label := Label.new()
	paint_label.text = "PAINT SELECTED BLOCKS"
	add_child(paint_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 230
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
	_status.text = "Select a ForgeBlock to paint."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.7, 0.75, 0.8)
	add_child(_status)

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
	for path in paths:
		var loaded := load(path)
		if loaded is SurfaceDefinition:
			_add_surface_button(loaded)
	_status.text = "%d surfaces loaded." % paths.size()

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
		if node is ForgeBlock3D:
			node.paint_surface(surface)
			painted += 1
	_status.text = "Painted %d block(s): %s" % [painted, surface.display_name] if painted > 0 else "No ForgeBlock3D selected."

func _add_block() -> void:
	var root := _editor_interface.get_edited_scene_root()
	if root == null:
		_status.text = "Open or create a 3D scene first."
		return
	var block := ForgeBlock3D.new()
	block.name = "ForgeBlock"
	block.size = Vector3(2.0, 2.0, 2.0)
	block.position = _next_position()
	block.surface = load("res://content/surfaces/concrete.tres")
	root.add_child(block)
	block.owner = root
	_editor_interface.get_selection().clear()
	_editor_interface.get_selection().add_node(block)
	_status.text = "Added a 2m block. Scale by editing Size, not Transform Scale."

func _add_room() -> void:
	var root := _editor_interface.get_edited_scene_root()
	if root == null:
		_status.text = "Open or create a 3D scene first."
		return
	var room := Node3D.new()
	room.name = "ForgeRoom"
	room.position = _next_position()
	root.add_child(room)
	room.owner = root
	var floor_surface: SurfaceDefinition = load("res://content/surfaces/blue_carpet.tres")
	var wall_surface: SurfaceDefinition = load("res://content/surfaces/obsidian_panel.tres")
	_create_room_block(room, "Floor", Vector3(16, 0.5, 16), Vector3(0, -0.25, 0), floor_surface)
	_create_room_block(room, "NorthWall", Vector3(16, 5, 0.5), Vector3(0, 2.5, -8), wall_surface)
	_create_room_block(room, "SouthWall", Vector3(16, 5, 0.5), Vector3(0, 2.5, 8), wall_surface)
	_create_room_block(room, "WestWall", Vector3(0.5, 5, 16), Vector3(-8, 2.5, 0), wall_surface)
	_create_room_block(room, "EastWall", Vector3(0.5, 5, 16), Vector3(8, 2.5, 0), wall_surface)
	_editor_interface.get_selection().clear()
	_editor_interface.get_selection().add_node(room)
	_status.text = "Created a paintable 16m test room."

func _create_room_block(parent: Node3D, block_name: String, block_size: Vector3, block_position: Vector3, block_surface: SurfaceDefinition) -> void:
	var block := ForgeBlock3D.new()
	block.name = block_name
	block.size = block_size
	block.position = block_position
	block.surface = block_surface
	parent.add_child(block)
	block.owner = _editor_interface.get_edited_scene_root()

func _next_position() -> Vector3:
	var selected := _editor_interface.get_selection().get_selected_nodes()
	if not selected.is_empty() and selected[0] is Node3D:
		var node := selected[0] as Node3D
		return Vector3(snappedf(node.position.x + 2.0, 0.25), snappedf(node.position.y, 0.25), snappedf(node.position.z, 0.25))
	return Vector3.ZERO

