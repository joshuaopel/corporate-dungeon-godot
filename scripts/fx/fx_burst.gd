class_name FxBurst
extends Node3D

@export var definition: FxDefinition
@export var normal := Vector3.UP

var _particles: CPUParticles3D
var _light: OmniLight3D

func _ready() -> void:
	if definition == null:
		queue_free()
		return
	_build_particles()
	_build_light()
	if definition.sound:
		var audio := AudioStreamPlayer3D.new()
		audio.stream = definition.sound
		add_child(audio)
		audio.play()
	_particles.emitting = true
	var cleanup_time := maxf(definition.lifetime * 1.6, 0.2)
	get_tree().create_timer(cleanup_time).timeout.connect(queue_free)

func configure(fx: FxDefinition, surface_normal := Vector3.UP) -> void:
	definition = fx
	normal = surface_normal.normalized()

func _build_particles() -> void:
	_particles = CPUParticles3D.new()
	_particles.one_shot = true
	_particles.explosiveness = 1.0
	_particles.amount = definition.particle_count
	_particles.lifetime = definition.lifetime
	_particles.direction = normal
	_particles.spread = 180.0
	_particles.initial_velocity_min = definition.min_speed
	_particles.initial_velocity_max = definition.max_speed
	_particles.gravity = Vector3(0.0, -8.0, 0.0)
	_particles.color = definition.color
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * definition.particle_size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = definition.color
	material.emission_enabled = true
	material.emission = definition.secondary_color
	material.emission_energy_multiplier = 2.0
	quad.material = material
	_particles.mesh = quad
	add_child(_particles)

func _build_light() -> void:
	if definition.light_energy <= 0.0:
		return
	_light = OmniLight3D.new()
	_light.light_color = definition.color
	_light.light_energy = definition.light_energy
	_light.omni_range = definition.light_range
	_light.shadow_enabled = false
	add_child(_light)
	var tween := create_tween()
	tween.tween_property(_light, "light_energy", 0.0, definition.lifetime)

