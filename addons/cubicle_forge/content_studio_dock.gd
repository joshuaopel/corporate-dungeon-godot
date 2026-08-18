@tool
extends VBoxContainer

const CATEGORY_NAMES := ["WEAPONS", "ENEMIES", "FX", "SURFACES"]
const CATEGORY_FOLDERS := ["res://content/weapons", "res://content/enemies", "res://content/fx", "res://content/surfaces"]
const NEW_FILE_STEMS := ["new_weapon", "new_enemy", "new_fx", "new_surface"]

var _editor_interface: EditorInterface
var _category: OptionButton
var _asset_list: ItemList
var _preview: ForgeContentPreview
var _summary: Label
var _form: VBoxContainer
var _status: Label
var _current_resource: Resource

func setup(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface
	name = "Content Studio"
	custom_minimum_size = Vector2(330, 0)
	_build_ui()
	call_deferred("_refresh_assets")

func _build_ui() -> void:
	var title := Label.new()
	title.text = "CONTENT STUDIO // LIVE"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("ffcf5a"))
	add_child(title)

	var intro := Label.new()
	intro.text = "Visual tuning for gameplay resources.\nQuick fields save immediately."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.72, 0.78, 0.82)
	add_child(intro)

	_category = OptionButton.new()
	for category_name in CATEGORY_NAMES:
		_category.add_item(category_name)
	_category.item_selected.connect(func(_index: int) -> void: _refresh_assets())
	add_child(_category)

	_asset_list = ItemList.new()
	_asset_list.custom_minimum_size.y = 150
	_asset_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_asset_list.allow_reselect = true
	_asset_list.item_selected.connect(_select_index)
	add_child(_asset_list)

	var actions := HBoxContainer.new()
	add_child(actions)
	_add_action_button(actions, "+ NEW", _create_new)
	_add_action_button(actions, "DUPLICATE", _duplicate_current)
	_add_action_button(actions, "INSPECTOR", _open_in_inspector)

	_preview = ForgeContentPreview.new()
	add_child(_preview)
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.custom_minimum_size.y = 42
	add_child(_summary)

	var tune_label := Label.new()
	tune_label.text = "QUICK TUNE"
	tune_label.add_theme_color_override("font_color", Color("65f4d5"))
	add_child(tune_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 220
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	_form = VBoxContainer.new()
	_form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_form)

	_status = Label.new()
	_status.text = "Select a resource."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate = Color(0.65, 0.72, 0.77)
	add_child(_status)

func _add_action_button(parent: HBoxContainer, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)

func _refresh_assets(select_path := "") -> void:
	_current_resource = null
	_preview.content_resource = null
	_asset_list.clear()
	_clear_form()
	var folder: String = CATEGORY_FOLDERS[_category.selected]
	var paths: Array[String] = []
	var directory := DirAccess.open(folder)
	if directory:
		for file_name in directory.get_files():
			if file_name.get_extension() == "tres":
				paths.append(folder + "/" + file_name)
	paths.sort()
	var select_index := -1
	for path in paths:
		var resource := load(path)
		if not _matches_category(resource):
			continue
		_asset_list.add_item(_display_name(resource))
		var index := _asset_list.item_count - 1
		_asset_list.set_item_metadata(index, path)
		_asset_list.set_item_tooltip(index, path)
		if path == select_path:
			select_index = index
	_status.text = "%d %s loaded." % [_asset_list.item_count, CATEGORY_NAMES[_category.selected].to_lower()]
	if select_index < 0 and _asset_list.item_count > 0:
		select_index = 0
	if select_index >= 0:
		_asset_list.select(select_index)
		_select_index(select_index)

func _select_index(index: int) -> void:
	var path := str(_asset_list.get_item_metadata(index))
	_current_resource = load(path)
	_preview.content_resource = _current_resource
	_rebuild_form()
	_refresh_summary()
	_status.text = path

func _matches_category(resource: Resource) -> bool:
	match _category.selected:
		0: return resource is WeaponDefinition
		1: return resource is EnemyDefinition
		2: return resource is FxDefinition
		3: return resource is SurfaceDefinition
	return false

func _display_name(resource: Resource) -> String:
	if resource and "display_name" in resource:
		return str(resource.get("display_name"))
	return resource.resource_path.get_file().get_basename() if resource else "INVALID RESOURCE"

func _rebuild_form() -> void:
	_clear_form()
	if _current_resource == null:
		return
	_add_line("Display Name", "display_name")
	if _current_resource is WeaponDefinition:
		_add_enum("Trigger", "trigger_mode", ["SEMI AUTO", "FULL AUTO"])
		_add_spin("Damage", "damage", 0.1, 500.0, 0.5)
		_add_spin("Rounds / Minute", "rounds_per_minute", 30.0, 1800.0, 1.0)
		_add_spin("Pellets", "pellets", 1, 24, 1)
		_add_spin("Spread", "spread_radians", 0.0, 0.25, 0.001)
		_add_spin("Magazine", "magazine_size", 1, 200, 1)
		_add_spin("Reload Seconds", "reload_seconds", 0.1, 5.0, 0.05)
		_add_spin("Recoil Degrees", "recoil_degrees", 0.0, 12.0, 0.05)
		_add_color("Body Color", "viewmodel_color")
		_add_color("Accent Color", "accent_color")
	elif _current_resource is EnemyDefinition:
		_add_spin("Max Health", "max_health", 1.0, 1000.0, 1.0)
		_add_spin("Move Speed", "move_speed", 0.0, 20.0, 0.1)
		_add_spin("Contact Damage", "contact_damage", 0.0, 100.0, 0.5)
		_add_spin("Attack Cooldown", "attack_cooldown", 0.1, 10.0, 0.05)
		_add_spin("Preferred Range", "preferred_range", 0.25, 8.0, 0.05)
		_add_spin("Sprite Scale", "sprite_scale", 0.25, 4.0, 0.05)
		_add_color("Sprite Tint", "sprite_tint")
	elif _current_resource is FxDefinition:
		_add_color("Primary", "color")
		_add_color("Secondary", "secondary_color")
		_add_spin("Particles", "particle_count", 1, 128, 1)
		_add_spin("Lifetime", "lifetime", 0.05, 5.0, 0.05)
		_add_spin("Minimum Speed", "min_speed", 0.0, 30.0, 0.1)
		_add_spin("Maximum Speed", "max_speed", 0.0, 30.0, 0.1)
		_add_spin("Particle Size", "particle_size", 0.005, 1.0, 0.005)
		_add_spin("Light Energy", "light_energy", 0.0, 8.0, 0.1)
	elif _current_resource is SurfaceDefinition:
		_add_color("Palette Color", "palette_color")
		_add_spin("Contact Damage / s", "contact_damage", 0.0, 100.0, 0.5)
		var inspect := Button.new()
		inspect.text = "EDIT MATERIAL IN INSPECTOR"
		inspect.pressed.connect(_open_material_in_inspector)
		_form.add_child(inspect)

func _clear_form() -> void:
	if _form == null:
		return
	for child in _form.get_children():
		child.queue_free()

func _add_line(label_text: String, property_name: StringName) -> void:
	var row := _row(label_text)
	var edit := LineEdit.new()
	edit.text = str(_current_resource.get(property_name))
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(func(value: String) -> void: _apply_value(property_name, value))
	row.add_child(edit)

func _add_spin(label_text: String, property_name: StringName, minimum: float, maximum: float, step: float) -> void:
	var row := _row(label_text)
	var spin := SpinBox.new()
	spin.min_value = minimum
	spin.max_value = maximum
	spin.step = step
	spin.allow_greater = false
	spin.allow_lesser = false
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var original_value: Variant = _current_resource.get(property_name)
	spin.value = float(original_value)
	spin.value_changed.connect(func(value: float) -> void:
		var stored: Variant = int(value) if typeof(original_value) == TYPE_INT else value
		_apply_value(property_name, stored)
	)
	row.add_child(spin)

func _add_enum(label_text: String, property_name: StringName, options: Array[String]) -> void:
	var row := _row(label_text)
	var picker := OptionButton.new()
	for option in options:
		picker.add_item(option)
	picker.selected = int(_current_resource.get(property_name))
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.item_selected.connect(func(index: int) -> void: _apply_value(property_name, index))
	row.add_child(picker)

func _add_color(label_text: String, property_name: StringName) -> void:
	var row := _row(label_text)
	var picker := ColorPickerButton.new()
	picker.color = _current_resource.get(property_name)
	picker.custom_minimum_size.x = 90
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.color_changed.connect(func(color: Color) -> void: _apply_value(property_name, color))
	row.add_child(picker)

func _row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 135
	row.add_child(label)
	_form.add_child(row)
	return row

func _apply_value(property_name: StringName, value: Variant) -> void:
	if _current_resource == null:
		return
	_current_resource.set(property_name, value)
	var error := ResourceSaver.save(_current_resource, _current_resource.resource_path)
	if error != OK:
		_status.text = "SAVE FAILED: %s" % error_string(error)
		return
	_preview.content_resource = _current_resource
	_refresh_summary()
	_status.text = "Saved %s" % _current_resource.resource_path

func _refresh_summary() -> void:
	if _current_resource is WeaponDefinition:
		var weapon := _current_resource as WeaponDefinition
		var shots_per_second := weapon.rounds_per_minute / 60.0
		var burst_damage := weapon.damage * weapon.pellets
		_summary.text = "BURST %.0f  //  THEORETICAL DPS %.0f  //  MAG %d" % [burst_damage, burst_damage * shots_per_second, weapon.magazine_size]
	elif _current_resource is EnemyDefinition:
		var enemy := _current_resource as EnemyDefinition
		_summary.text = "HP %.0f  //  SPEED %.1f m/s  //  HIT %.0f  //  SCORE %d" % [enemy.max_health, enemy.move_speed, enemy.contact_damage, enemy.score_value]
	elif _current_resource is FxDefinition:
		var fx := _current_resource as FxDefinition
		_summary.text = "%d PARTICLES  //  %.2f s  //  SPEED %.1f–%.1f" % [fx.particle_count, fx.lifetime, fx.min_speed, fx.max_speed]
	elif _current_resource is SurfaceDefinition:
		var surface := _current_resource as SurfaceDefinition
		_summary.text = "%s  //  %s" % [surface.editor_category.to_upper(), "HAZARD" if surface.contact_damage > 0.0 else "SAFE"]
	else:
		_summary.text = ""

func _create_new() -> void:
	var resource: Resource
	match _category.selected:
		0:
			var weapon := WeaponDefinition.new()
			weapon.display_name = "NEW WEAPON"
			weapon.muzzle_fx = load("res://content/fx/muzzle_teal.tres")
			weapon.impact_fx = load("res://content/fx/impact_paper.tres")
			resource = weapon
		1:
			var enemy := EnemyDefinition.new()
			enemy.display_name = "NEW HOSTILE"
			enemy.sprite_frames = load("res://content/enemies/corporate_sprite_frames.tres")
			enemy.death_fx = load("res://content/fx/hostile_burst.tres")
			enemy.hit_fx = load("res://content/fx/impact_paper.tres")
			resource = enemy
		2:
			var fx := FxDefinition.new()
			fx.display_name = "NEW FX"
			resource = fx
		3:
			var surface := SurfaceDefinition.new()
			surface.display_name = "NEW SURFACE"
			var material := StandardMaterial3D.new()
			material.albedo_color = surface.palette_color
			surface.material = material
			resource = surface
	var folder: String = CATEGORY_FOLDERS[_category.selected]
	var stem: String = NEW_FILE_STEMS[_category.selected]
	var path := _unique_path(folder, stem)
	_save_new_resource(resource, path)

func _duplicate_current() -> void:
	if _current_resource == null:
		_status.text = "Select an asset to duplicate."
		return
	var duplicate := _current_resource.duplicate(false)
	duplicate.set("display_name", _display_name(_current_resource) + " COPY")
	var stem := _current_resource.resource_path.get_file().get_basename() + "_copy"
	var folder: String = CATEGORY_FOLDERS[_category.selected]
	var path := _unique_path(folder, stem)
	_save_new_resource(duplicate, path)

func _save_new_resource(resource: Resource, path: String) -> void:
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		_status.text = "CREATE FAILED: %s" % error_string(error)
		return
	_editor_interface.get_resource_filesystem().scan()
	_refresh_assets(path)
	_status.text = "Created %s" % path

func _unique_path(folder: String, stem: String) -> String:
	var candidate := folder + "/" + stem + ".tres"
	var number := 2
	while FileAccess.file_exists(candidate):
		candidate = folder + "/" + stem + "_%02d.tres" % number
		number += 1
	return candidate

func _open_in_inspector() -> void:
	if _current_resource:
		_editor_interface.edit_resource(_current_resource)

func _open_material_in_inspector() -> void:
	if _current_resource is SurfaceDefinition:
		var surface := _current_resource as SurfaceDefinition
		if surface.material:
			_editor_interface.edit_resource(surface.material)
