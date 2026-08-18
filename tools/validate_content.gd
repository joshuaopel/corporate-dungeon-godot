extends SceneTree

var _errors: Array[String] = []

func _initialize() -> void:
	_validate_folder("res://content/weapons", "tres", _validate_weapon)
	_validate_folder("res://content/enemies", "tres", _validate_enemy)
	_validate_folder("res://content/fx", "tres", _validate_fx)
	_validate_folder("res://content/surfaces", "tres", _validate_surface)
	if _errors.is_empty():
		print("CONTENT VALIDATION PASSED")
		quit(0)
	else:
		for error in _errors:
			push_error(error)
		quit(1)

func _validate_folder(folder: String, extension: String, validator: Callable) -> void:
	var directory := DirAccess.open(folder)
	if directory == null:
		_errors.append("Missing content folder: " + folder)
		return
	for file_name in directory.get_files():
		if file_name.get_extension() != extension:
			continue
		var path := folder + "/" + file_name
		var resource := load(path)
		if resource:
			validator.call(resource, path)

func _validate_weapon(resource: Resource, path: String) -> void:
	if not resource is WeaponDefinition:
		_errors.append(path + " is not a WeaponDefinition")
		return
	var weapon := resource as WeaponDefinition
	_require(not weapon.display_name.is_empty(), path, "display_name")
	_require(weapon.damage > 0.0, path, "positive damage")
	_require(weapon.magazine_size > 0, path, "positive magazine_size")
	_require(weapon.muzzle_fx != null, path, "muzzle_fx")
	_require(weapon.impact_fx != null, path, "impact_fx")

func _validate_enemy(resource: Resource, path: String) -> void:
	if resource is SpriteFrames:
		return
	if not resource is EnemyDefinition:
		_errors.append(path + " is not an EnemyDefinition")
		return
	var enemy := resource as EnemyDefinition
	_require(not enemy.display_name.is_empty(), path, "display_name")
	_require(enemy.sprite_frames != null, path, "sprite_frames")
	_require(enemy.max_health > 0.0, path, "positive max_health")
	if enemy.sprite_frames:
		for animation in [&"idle", &"move", &"attack", &"death"]:
			_require(enemy.sprite_frames.has_animation(animation), path, "animation " + animation)

func _validate_fx(resource: Resource, path: String) -> void:
	if not resource is FxDefinition:
		_errors.append(path + " is not an FxDefinition")
		return
	var fx := resource as FxDefinition
	_require(fx.particle_count > 0, path, "positive particle_count")
	_require(fx.lifetime > 0.0, path, "positive lifetime")
	_require(fx.max_speed >= fx.min_speed, path, "max_speed >= min_speed")

func _validate_surface(resource: Resource, path: String) -> void:
	if not resource is SurfaceDefinition:
		_errors.append(path + " is not a SurfaceDefinition")
		return
	var surface := resource as SurfaceDefinition
	_require(not surface.display_name.is_empty(), path, "display_name")
	_require(surface.material != null, path, "material")

func _require(condition: bool, path: String, requirement: String) -> void:
	if not condition:
		_errors.append(path + " requires " + requirement)

