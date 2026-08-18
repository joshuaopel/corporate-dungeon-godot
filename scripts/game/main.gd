extends Node3D

@onready var hud: CorporateHUD = $HUD
@onready var player: CorporatePlayer = $Player

var _remaining_hostiles := 0

func _ready() -> void:
	await get_tree().process_frame
	var enemies := get_tree().get_nodes_in_group("enemies")
	_remaining_hostiles = enemies.size()
	hud.set_hostile_count(_remaining_hostiles)
	for enemy in enemies:
		if enemy is BillboardEnemy:
			enemy.died.connect(_on_enemy_died)
	player.died.connect(_on_player_died)

func _on_enemy_died(_enemy: BillboardEnemy, score_value: int) -> void:
	_remaining_hostiles = maxi(_remaining_hostiles - 1, 0)
	hud.set_hostile_count(_remaining_hostiles)
	hud.add_score(score_value)
	if _remaining_hostiles == 0:
		await get_tree().create_timer(0.65).timeout
		hud.show_mission_complete()

func _on_player_died() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)

