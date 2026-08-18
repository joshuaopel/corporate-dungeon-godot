extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "Main scene loads")
	if packed == null:
		_finish()
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	_check(main.get_node_or_null("Player") is CorporatePlayer, "Player instantiates")
	_check(main.get_node_or_null("HUD") is CorporateHUD, "HUD instantiates")
	_check(get_nodes_in_group("enemies").size() == 5, "Five billboard enemies register")
	var weapon_controller := main.get_node_or_null("Player/Head/Camera3D/WeaponController") as WeaponController
	_check(weapon_controller != null, "Weapon controller instantiates")
	if weapon_controller:
		_check(weapon_controller.loadout.size() == 3, "Three weapon resources load")
		_check(weapon_controller.get_current_definition() != null, "Initial weapon equips")
	var blocks := main.find_children("*", "ForgeBlock3D", true, false)
	_check(blocks.size() >= 12, "Forge level blocks generate")
	main.queue_free()
	await process_frame
	_finish()

func _check(condition: bool, label: String) -> void:
	if condition:
		print("[PASS] ", label)
	else:
		push_error("[FAIL] " + label)
		_failures.append(label)

func _finish() -> void:
	if _failures.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
	else:
		print("SMOKE TEST FAILED: ", _failures)
		quit(1)

