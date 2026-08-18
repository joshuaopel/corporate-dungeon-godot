class_name BillboardEnemy
extends CharacterBody3D

signal died(enemy: BillboardEnemy, score_value: int)

const FX_BURST_SCENE := preload("res://scenes/fx/fx_burst.tscn")

@export var definition: EnemyDefinition

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

var health := 1.0
var _target: CorporatePlayer
var _attack_timer := 0.0
var _attacking := false
var _dead := false
var _stagger_timer := 0.0
var _base_modulate := Color.WHITE

func _ready() -> void:
	add_to_group("enemies")
	if definition == null:
		push_warning("BillboardEnemy has no EnemyDefinition")
		return
	health = definition.max_health
	sprite.sprite_frames = definition.sprite_frames
	sprite.modulate = definition.sprite_tint
	sprite.pixel_size = 0.008 * definition.sprite_scale
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_base_modulate = definition.sprite_tint
	_play_if_available(&"idle")
	_target = get_tree().get_first_node_in_group("player") as CorporatePlayer

func _physics_process(delta: float) -> void:
	if _dead or definition == null:
		return
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_stagger_timer = maxf(_stagger_timer - delta, 0.0)
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as CorporatePlayer
		return
	var offset := _target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	if distance > definition.awareness_range:
		velocity.x = move_toward(velocity.x, 0.0, delta * 8.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 8.0)
		_play_if_available(&"idle")
	elif distance > definition.preferred_range and not _attacking and _stagger_timer <= 0.0:
		var direction := offset.normalized()
		velocity.x = direction.x * definition.move_speed
		velocity.z = direction.z * definition.move_speed
		_play_if_available(&"move")
	elif not _attacking:
		velocity.x = move_toward(velocity.x, 0.0, delta * 18.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 18.0)
		if _attack_timer <= 0.0 and distance <= definition.preferred_range * 1.25:
			_attack()
		else:
			_play_if_available(&"idle")
	if not is_on_floor():
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity", 24.0)) * delta
	move_and_slide()

func _attack() -> void:
	_attacking = true
	_attack_timer = definition.attack_cooldown
	_play_if_available(&"attack", true)
	if definition.attack_sound:
		audio.stream = definition.attack_sound
		audio.play()
	await get_tree().create_timer(definition.attack_windup).timeout
	if _dead:
		return
	if is_instance_valid(_target) and global_position.distance_to(_target.global_position) <= definition.preferred_range * 1.45:
		_target.take_damage(definition.contact_damage, global_position)
	await get_tree().create_timer(0.18).timeout
	_attacking = false

func take_damage(amount: float, source_position := Vector3.ZERO, knockback := 0.0) -> bool:
	if _dead or definition == null:
		return false
	health -= amount
	if definition.hit_fx:
		_spawn_fx(definition.hit_fx, global_position + Vector3.UP * 1.0)
	var flash_tween := create_tween()
	sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	flash_tween.tween_property(sprite, "modulate", _base_modulate, 0.1)
	if amount >= definition.stagger_threshold:
		_stagger_timer = 0.18
	if source_position != Vector3.ZERO and knockback > 0.0:
		var away := global_position - source_position
		away.y = 0.0
		if away.length_squared() > 0.001:
			velocity += away.normalized() * knockback
	if health <= 0.0:
		_die()
		return true
	return false

func _die() -> void:
	_dead = true
	_attacking = false
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	_play_if_available(&"death", true)
	if definition.death_sound:
		audio.stream = definition.death_sound
		audio.play()
	_spawn_fx(definition.death_fx, global_position + Vector3.UP * 0.7)
	died.emit(self, definition.score_value)
	await get_tree().create_timer(1.6).timeout
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()

func _play_if_available(animation: StringName, restart := false) -> void:
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation):
		return
	if restart or sprite.animation != animation:
		sprite.play(animation)

func _spawn_fx(fx: FxDefinition, world_position: Vector3) -> void:
	if fx == null:
		return
	var burst := FX_BURST_SCENE.instantiate() as FxBurst
	burst.configure(fx, Vector3.UP)
	get_tree().current_scene.add_child(burst)
	burst.global_position = world_position

