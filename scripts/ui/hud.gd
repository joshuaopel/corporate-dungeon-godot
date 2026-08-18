class_name CorporateHUD
extends CanvasLayer

var _health_label: Label
var _health_bar: ProgressBar
var _ammo_label: Label
var _reserve_label: Label
var _weapon_label: Label
var _objective_label: Label
var _score_label: Label
var _reload_label: Label
var _reticle: CombatReticle
var _damage_overlay: ColorRect
var _announcement: Label
var _player: CorporatePlayer
var _weapons: WeaponController
var _score := 0

func _ready() -> void:
	_build_hud()
	call_deferred("_bind_runtime")

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var scanlines := ColorRect.new()
	scanlines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scan_shader := Shader.new()
	scan_shader.code = "shader_type canvas_item; void fragment(){ float line=step(0.54,fract(UV.y*360.0)); COLOR=vec4(0.02,0.12,0.14,line*0.045); }"
	var scan_material := ShaderMaterial.new()
	scan_material.shader = scan_shader
	scanlines.material = scan_material
	root.add_child(scanlines)

	var header := ColorRect.new()
	header.color = Color(0.02, 0.04, 0.07, 0.92)
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 58
	root.add_child(header)
	var brand := _make_label("MERIDIAN // INTERNAL SECURITY", 18, Color("65f4d5"))
	brand.position = Vector2(24, 10)
	header.add_child(brand)
	var subbrand := _make_label("HOSTILE TAKEOVER PROTOCOL", 11, Color(0.75, 0.8, 0.82))
	subbrand.position = Vector2(25, 33)
	header.add_child(subbrand)
	_objective_label = _make_label("NONCOMPLIANT ENTITIES: --", 16, Color.WHITE)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_objective_label.position = Vector2(-430, 12)
	_objective_label.size = Vector2(405, 26)
	header.add_child(_objective_label)

	var health_panel := _panel(Vector2(24, -126), Vector2(305, 98), Control.PRESET_BOTTOM_LEFT, Color(0.02, 0.04, 0.07, 0.92))
	root.add_child(health_panel)
	var health_caption := _make_label("EMPLOYEE WELLNESS", 12, Color(0.58, 0.66, 0.7))
	health_caption.position = Vector2(15, 10)
	health_panel.add_child(health_caption)
	_health_label = _make_label("100", 38, Color.WHITE)
	_health_label.position = Vector2(15, 27)
	health_panel.add_child(_health_label)
	_health_bar = ProgressBar.new()
	_health_bar.position = Vector2(87, 44)
	_health_bar.size = Vector2(198, 15)
	_health_bar.max_value = 100
	_health_bar.value = 100
	_health_bar.show_percentage = false
	var health_bg := StyleBoxFlat.new()
	health_bg.bg_color = Color("142031")
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color("65f4d5")
	_health_bar.add_theme_stylebox_override("background", health_bg)
	_health_bar.add_theme_stylebox_override("fill", health_fill)
	health_panel.add_child(_health_bar)
	_score_label = _make_label("LIABILITY SCORE  000000", 12, Color("d6a23d"))
	_score_label.position = Vector2(88, 68)
	health_panel.add_child(_score_label)

	var ammo_panel := _panel(Vector2(-355, -126), Vector2(331, 98), Control.PRESET_BOTTOM_RIGHT, Color(0.02, 0.04, 0.07, 0.92))
	root.add_child(ammo_panel)
	_weapon_label = _make_label("EXECUTIVE STAPLER", 15, Color("65f4d5"))
	_weapon_label.position = Vector2(16, 10)
	_weapon_label.size = Vector2(300, 25)
	_weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_panel.add_child(_weapon_label)
	_ammo_label = _make_label("14", 42, Color.WHITE)
	_ammo_label.position = Vector2(175, 33)
	_ammo_label.size = Vector2(75, 50)
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_panel.add_child(_ammo_label)
	_reserve_label = _make_label("/ 084", 18, Color(0.6, 0.67, 0.72))
	_reserve_label.position = Vector2(250, 55)
	ammo_panel.add_child(_reserve_label)
	_reload_label = _make_label("", 11, Color("ff315f"))
	_reload_label.position = Vector2(16, 63)
	ammo_panel.add_child(_reload_label)

	_reticle = CombatReticle.new()
	_reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_reticle)

	_damage_overlay = ColorRect.new()
	_damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_overlay.color = Color(0.8, 0.01, 0.08, 0.0)
	_damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_damage_overlay)

	_announcement = _make_label("", 32, Color.WHITE)
	_announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announcement.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_announcement.set_anchors_preset(Control.PRESET_CENTER)
	_announcement.position = Vector2(-340, -80)
	_announcement.size = Vector2(680, 160)
	_announcement.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.035, 0.95))
	_announcement.add_theme_constant_override("outline_size", 10)
	root.add_child(_announcement)

func _bind_runtime() -> void:
	_player = get_tree().get_first_node_in_group("player") as CorporatePlayer
	if _player:
		_player.health_changed.connect(_on_health_changed)
		_player.damage_taken.connect(_on_damage_taken)
		_player.died.connect(show_failure)
		_on_health_changed(_player.health, _player.max_health)
		_weapons = _player.get_node("Head/Camera3D/WeaponController") as WeaponController
	if _weapons:
		_weapons.ammo_changed.connect(_on_ammo_changed)
		_weapons.weapon_changed.connect(_on_weapon_changed)
		_weapons.hit_confirmed.connect(_reticle.confirm_hit)
		_weapons.reload_state_changed.connect(_on_reload_changed)
		_on_weapon_changed(_weapons.get_current_definition())

func set_hostile_count(count: int) -> void:
	_objective_label.text = "NONCOMPLIANT ENTITIES: %02d" % count

func add_score(value: int) -> void:
	_score += value
	_score_label.text = "LIABILITY SCORE  %06d" % _score

func show_mission_complete() -> void:
	_announcement.text = "FLOOR SECURED\nQUARTERLY TARGET EXCEEDED"
	_announcement.modulate = Color("65f4d5")
	var tween := create_tween().set_loops()
	tween.tween_property(_announcement, "modulate:a", 0.58, 0.7)
	tween.tween_property(_announcement, "modulate:a", 1.0, 0.7)

func show_failure() -> void:
	_announcement.text = "EMPLOYMENT TERMINATED\nPRESS F6 TO RESTART"
	_announcement.modulate = Color("ff315f")

func _on_health_changed(current: float, maximum: float) -> void:
	_health_label.text = "%03d" % ceili(current)
	_health_bar.max_value = maximum
	_health_bar.value = current
	var ratio := current / maximum
	_health_label.modulate = Color("ff315f") if ratio <= 0.3 else Color.WHITE

func _on_damage_taken(_amount: float) -> void:
	_damage_overlay.color.a = 0.2
	var tween := create_tween()
	tween.tween_property(_damage_overlay, "color:a", 0.0, 0.35)

func _on_ammo_changed(in_magazine: int, reserve: int) -> void:
	_ammo_label.text = "%02d" % in_magazine
	_reserve_label.text = "/ %03d" % reserve
	_ammo_label.modulate = Color("ff315f") if in_magazine <= 2 else Color.WHITE

func _on_weapon_changed(definition: WeaponDefinition) -> void:
	if definition:
		_weapon_label.text = definition.display_name
		_weapon_label.modulate = definition.accent_color

func _on_reload_changed(is_reloading: bool) -> void:
	_reload_label.text = "PROCESSING..." if is_reloading else ""

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _panel(panel_position: Vector2, panel_size: Vector2, preset: Control.LayoutPreset, color: Color) -> ColorRect:
	var panel := ColorRect.new()
	panel.color = color
	panel.set_anchors_preset(preset)
	panel.position = panel_position
	panel.size = panel_size
	return panel
