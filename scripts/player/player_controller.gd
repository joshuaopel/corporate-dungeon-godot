class_name CorporatePlayer
extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal damage_taken(amount: float)
signal died

@export_category("Movement")
@export_range(1.0, 20.0, 0.1) var walk_speed := 7.5
@export_range(1.0, 30.0, 0.1) var sprint_speed := 11.5
@export_range(1.0, 30.0, 0.1) var ground_acceleration := 18.0
@export_range(1.0, 30.0, 0.1) var air_acceleration := 5.0
@export_range(1.0, 15.0, 0.1) var jump_velocity := 7.8
@export_range(0.0001, 0.02, 0.0001) var mouse_sensitivity := 0.0022

@export_category("Vitals")
@export var max_health := 100.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var health := 100.0
var _pitch := 0.0
var _bob_time := 0.0
var _shake_strength := 0.0
var _head_rest_y := 1.55

func _ready() -> void:
	add_to_group("player")
	health = max_health
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_changed.emit(health, max_health)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-88.0), deg_to_rad(88.0))
	if event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity", 24.0)) * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_velocity := wish_direction * target_speed
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	move_and_slide()
	_update_camera(delta, input.length())

func _update_camera(delta: float, input_amount: float) -> void:
	_pitch = lerpf(_pitch, _pitch, 1.0)
	head.rotation.x = _pitch
	if is_on_floor() and input_amount > 0.05:
		_bob_time += delta * (13.0 if Input.is_action_pressed("sprint") else 9.0)
	else:
		_bob_time = lerpf(_bob_time, 0.0, delta * 2.0)
	var bob := Vector3(cos(_bob_time * 0.5) * 0.025, abs(sin(_bob_time)) * 0.035, 0.0) * input_amount
	head.position = head.position.lerp(Vector3(bob.x, _head_rest_y + bob.y, 0.0), minf(delta * 12.0, 1.0))
	if _shake_strength > 0.0001:
		camera.position = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * _shake_strength
		_shake_strength = move_toward(_shake_strength, 0.0, delta * 0.7)
	else:
		camera.position = camera.position.lerp(Vector3.ZERO, minf(delta * 20.0, 1.0))

func add_recoil(degrees: float, shake: float) -> void:
	_pitch = clampf(_pitch - deg_to_rad(degrees), deg_to_rad(-88.0), deg_to_rad(88.0))
	_shake_strength = maxf(_shake_strength, shake)

func take_damage(amount: float, source_position := Vector3.ZERO) -> bool:
	if health <= 0.0:
		return false
	health = maxf(health - amount, 0.0)
	damage_taken.emit(amount)
	health_changed.emit(health, max_health)
	_shake_strength = maxf(_shake_strength, 0.08)
	if source_position != Vector3.ZERO:
		var away := global_position - source_position
		away.y = 0.0
		if away.length_squared() > 0.01:
			velocity += away.normalized() * 2.0
	if health <= 0.0:
		died.emit()
		set_physics_process(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return health <= 0.0

