class_name WeaponDefinition
extends Resource

enum TriggerMode { SEMI_AUTO, FULL_AUTO }

@export_category("Identity")
@export var display_name := "New Weapon"
@export_multiline var designer_notes := ""
@export var inventory_icon: Texture2D

@export_category("Ballistics")
@export var trigger_mode := TriggerMode.SEMI_AUTO
@export_range(30.0, 1800.0, 1.0, "suffix:rpm") var rounds_per_minute := 420.0
@export_range(0.1, 500.0, 0.5) var damage := 20.0
@export_range(1, 24, 1) var pellets := 1
@export_range(0.0, 0.25, 0.001) var spread_radians := 0.008
@export_range(1.0, 500.0, 1.0, "suffix:m") var range_meters := 120.0
@export_range(0.0, 50.0, 0.5) var knockback := 4.0

@export_category("Magazine")
@export_range(1, 200, 1) var magazine_size := 12
@export_range(0, 999, 1) var starting_reserve := 72
@export_range(0.1, 5.0, 0.05, "suffix:s") var reload_seconds := 1.15

@export_category("Feel")
@export_range(0.0, 12.0, 0.05) var recoil_degrees := 1.4
@export_range(0.0, 0.2, 0.001) var camera_shake := 0.035
@export_range(0.0, 0.35, 0.005) var view_kick := 0.07
@export var viewmodel_color := Color("263a5e")
@export var accent_color := Color("65f4d5")
@export_range(0, 2, 1) var viewmodel_shape := 0

@export_category("Presentation")
@export var fire_sound: AudioStream
@export var reload_sound: AudioStream
@export var muzzle_fx: FxDefinition
@export var impact_fx: FxDefinition

func seconds_per_shot() -> float:
	return 60.0 / maxf(rounds_per_minute, 1.0)

