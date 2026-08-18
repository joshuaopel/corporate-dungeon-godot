class_name EnemyDefinition
extends Resource

@export_category("Identity")
@export var display_name := "New Hostile"
@export_multiline var designer_notes := ""
@export var sprite_frames: SpriteFrames
@export var sprite_tint := Color.WHITE
@export_range(0.25, 4.0, 0.05) var sprite_scale := 1.25

@export_category("Vitals")
@export_range(1.0, 1000.0, 1.0) var max_health := 70.0
@export_range(0.0, 50.0, 0.5) var stagger_threshold := 18.0
@export_range(0, 1000, 5) var score_value := 100

@export_category("Movement")
@export_range(0.0, 20.0, 0.1, "suffix:m/s") var move_speed := 3.2
@export_range(1.0, 50.0, 0.5, "suffix:m") var awareness_range := 22.0
@export_range(0.25, 8.0, 0.05, "suffix:m") var preferred_range := 2.2

@export_category("Attack")
@export_range(0.0, 100.0, 0.5) var contact_damage := 12.0
@export_range(0.1, 10.0, 0.05, "suffix:s") var attack_cooldown := 1.1
@export_range(0.0, 2.0, 0.05, "suffix:s") var attack_windup := 0.3

@export_category("Feedback")
@export var death_fx: FxDefinition
@export var hit_fx: FxDefinition
@export var attack_sound: AudioStream
@export var death_sound: AudioStream

