class_name FxDefinition
extends Resource

@export var display_name := "New FX"
@export var color := Color("65f4d5")
@export var secondary_color := Color("ffffff")
@export_range(1, 128, 1) var particle_count := 16
@export_range(0.05, 5.0, 0.05, "suffix:s") var lifetime := 0.38
@export_range(0.0, 30.0, 0.1) var min_speed := 2.0
@export_range(0.0, 30.0, 0.1) var max_speed := 8.0
@export_range(0.005, 1.0, 0.005) var particle_size := 0.045
@export_range(0.0, 8.0, 0.1) var light_energy := 1.8
@export_range(0.0, 8.0, 0.1) var light_range := 3.0
@export var sound: AudioStream

