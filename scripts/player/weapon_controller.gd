class_name WeaponController
extends Node3D

signal ammo_changed(in_magazine: int, reserve: int)
signal weapon_changed(definition: WeaponDefinition)
signal hit_confirmed(killed: bool)
signal reload_state_changed(is_reloading: bool)

const FX_BURST_SCENE := preload("res://scenes/fx/fx_burst.tscn")

@export var loadout: Array[WeaponDefinition] = []

var current_index := 0
var _magazines: Array[int] = []
var _reserves: Array[int] = []
var _shot_cooldown := 0.0
var _is_reloading := false
var _action_serial := 0
var _camera: Camera3D
var _player: CorporatePlayer
var _viewmodel: Node3D
var _muzzle: Marker3D
var _audio: AudioStreamPlayer
var _rest_position := Vector3(0.28, -0.28, -0.62)

func _ready() -> void:
	_camera = get_parent() as Camera3D
	_player = get_tree().get_first_node_in_group("player") as CorporatePlayer
	for weapon in loadout:
		_magazines.append(weapon.magazine_size)
		_reserves.append(weapon.starting_reserve)
	_audio = AudioStreamPlayer.new()
	add_child(_audio)
	if not loadout.is_empty():
		_equip(0)

func _process(delta: float) -> void:
	_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)
	if loadout.is_empty() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var weapon := loadout[current_index]
	var wants_fire := Input.is_action_pressed("fire") if weapon.trigger_mode == WeaponDefinition.TriggerMode.FULL_AUTO else Input.is_action_just_pressed("fire")
	if wants_fire and _shot_cooldown <= 0.0 and not _is_reloading:
		_fire()
	if Input.is_action_just_pressed("reload"):
		_reload()
	if Input.is_action_just_pressed("weapon_1"):
		_equip(0)
	elif Input.is_action_just_pressed("weapon_2"):
		_equip(1)
	elif Input.is_action_just_pressed("weapon_3"):
		_equip(2)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_equip(posmod(current_index - 1, loadout.size()))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_equip(posmod(current_index + 1, loadout.size()))

func _equip(index: int) -> void:
	if index < 0 or index >= loadout.size():
		return
	_action_serial += 1
	_is_reloading = false
	current_index = index
	_build_viewmodel(loadout[current_index])
	weapon_changed.emit(loadout[current_index])
	ammo_changed.emit(_magazines[current_index], _reserves[current_index])
	reload_state_changed.emit(false)

func _fire() -> void:
	var weapon := loadout[current_index]
	if _magazines[current_index] <= 0:
		_reload()
		return
	_magazines[current_index] -= 1
	_shot_cooldown = weapon.seconds_per_shot()
	ammo_changed.emit(_magazines[current_index], _reserves[current_index])
	if weapon.fire_sound:
		_audio.stream = weapon.fire_sound
		_audio.play()
	if _player:
		_player.add_recoil(weapon.recoil_degrees, weapon.camera_shake)
	_animate_kick(weapon.view_kick)
	_spawn_fx(weapon.muzzle_fx, _muzzle.global_position, -_camera.global_transform.basis.z)
	for pellet in weapon.pellets:
		_fire_ray(weapon)

func _fire_ray(weapon: WeaponDefinition) -> void:
	var basis := _camera.global_transform.basis
	var direction := -basis.z
	direction += basis.x * randf_range(-weapon.spread_radians, weapon.spread_radians)
	direction += basis.y * randf_range(-weapon.spread_radians, weapon.spread_radians)
	direction = direction.normalized()
	var origin := _camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * weapon.range_meters)
	query.collision_mask = 1 | 4
	if _player:
		query.exclude = [_player.get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return
	var collider: Object = result["collider"]
	var killed := false
	if collider.has_method("take_damage"):
		killed = bool(collider.call("take_damage", weapon.damage, origin, weapon.knockback))
		hit_confirmed.emit(killed)
	_spawn_fx(weapon.impact_fx, result["position"], result["normal"])

func _reload() -> void:
	if _is_reloading or loadout.is_empty():
		return
	var weapon := loadout[current_index]
	if _magazines[current_index] >= weapon.magazine_size or _reserves[current_index] <= 0:
		return
	_is_reloading = true
	_action_serial += 1
	var serial := _action_serial
	reload_state_changed.emit(true)
	if weapon.reload_sound:
		_audio.stream = weapon.reload_sound
		_audio.play()
	var tween := create_tween()
	tween.tween_property(_viewmodel, "rotation:z", 0.28, weapon.reload_seconds * 0.45)
	tween.tween_property(_viewmodel, "rotation:z", 0.0, weapon.reload_seconds * 0.55)
	await get_tree().create_timer(weapon.reload_seconds).timeout
	if serial != _action_serial:
		return
	var needed := weapon.magazine_size - _magazines[current_index]
	var loaded := mini(needed, _reserves[current_index])
	_magazines[current_index] += loaded
	_reserves[current_index] -= loaded
	_is_reloading = false
	ammo_changed.emit(_magazines[current_index], _reserves[current_index])
	reload_state_changed.emit(false)

func _animate_kick(amount: float) -> void:
	if not _viewmodel:
		return
	_viewmodel.position.z += amount
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_viewmodel, "position", _rest_position, maxf(_shot_cooldown * 0.75, 0.06))

func _spawn_fx(fx: FxDefinition, world_position: Vector3, surface_normal: Vector3) -> void:
	if fx == null:
		return
	var burst := FX_BURST_SCENE.instantiate() as FxBurst
	burst.configure(fx, surface_normal)
	get_tree().current_scene.add_child(burst)
	burst.global_position = world_position

func _build_viewmodel(weapon: WeaponDefinition) -> void:
	if _viewmodel:
		_viewmodel.queue_free()
	_viewmodel = Node3D.new()
	_viewmodel.name = "GeneratedViewmodel"
	_viewmodel.position = _rest_position
	add_child(_viewmodel)
	var body_size := Vector3(0.22, 0.18, 0.52)
	if weapon.viewmodel_shape == 1:
		body_size = Vector3(0.28, 0.22, 0.68)
	elif weapon.viewmodel_shape == 2:
		body_size = Vector3(0.18, 0.16, 0.74)
	_add_box(_viewmodel, body_size, Vector3.ZERO, weapon.viewmodel_color)
	_add_box(_viewmodel, Vector3(body_size.x * 0.55, 0.24, 0.16), Vector3(0.0, -0.17, 0.1), weapon.viewmodel_color.darkened(0.28))
	_add_box(_viewmodel, Vector3(body_size.x + 0.03, 0.045, body_size.z * 0.72), Vector3(0.0, body_size.y * 0.55, -0.03), weapon.accent_color, true)
	_muzzle = Marker3D.new()
	_muzzle.name = "Muzzle"
	_muzzle.position = Vector3(0.0, 0.02, -body_size.z * 0.62)
	_viewmodel.add_child(_muzzle)

func _add_box(parent: Node3D, size: Vector3, offset: Vector3, color: Color, emissive := false) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.62
	material.roughness = 0.26
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.8
	mesh.material = material
	mesh_instance.mesh = mesh
	mesh_instance.position = offset
	parent.add_child(mesh_instance)

func get_current_definition() -> WeaponDefinition:
	return loadout[current_index] if not loadout.is_empty() else null

