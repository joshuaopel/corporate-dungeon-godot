@tool
class_name ForgeContentPreview
extends Control

var content_resource: Resource:
	set(value):
		content_resource = value
		_time = 0.0
		queue_redraw()

var _time := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(260, 170)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	if content_resource is EnemyDefinition or content_resource is FxDefinition:
		_time += delta
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07101b"), true)
	draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color("24364a"), false, 1.0)
	_draw_grid()
	if content_resource is WeaponDefinition:
		_draw_weapon(content_resource as WeaponDefinition)
	elif content_resource is EnemyDefinition:
		_draw_enemy(content_resource as EnemyDefinition)
	elif content_resource is FxDefinition:
		_draw_fx(content_resource as FxDefinition)
	elif content_resource is SurfaceDefinition:
		_draw_surface(content_resource as SurfaceDefinition)
	else:
		_draw_caption("SELECT AN ASSET", Color(0.45, 0.5, 0.55))

func _draw_grid() -> void:
	var grid_color := Color(0.15, 0.23, 0.3, 0.28)
	for x in range(0, int(size.x), 16):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
	for y in range(0, int(size.y), 16):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)

func _draw_weapon(weapon: WeaponDefinition) -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.5 + 4.0)
	var body_size := Vector2(132, 42)
	if weapon.viewmodel_shape == 1:
		body_size = Vector2(158, 50)
	elif weapon.viewmodel_shape == 2:
		body_size = Vector2(174, 34)
	var body_rect := Rect2(center - body_size * 0.5, body_size)
	draw_rect(body_rect.grow(4), Color(0.01, 0.02, 0.03, 0.8), true)
	draw_rect(body_rect, weapon.viewmodel_color, true)
	draw_rect(Rect2(body_rect.position + Vector2(12, -7), Vector2(body_rect.size.x * 0.7, 7)), weapon.accent_color, true)
	draw_rect(Rect2(center + Vector2(-25, body_size.y * 0.35), Vector2(32, 45)), weapon.viewmodel_color.darkened(0.32), true)
	draw_line(center + Vector2(body_size.x * 0.5, 0), center + Vector2(body_size.x * 0.5 + 22, 0), weapon.accent_color, 5.0)
	_draw_caption(weapon.display_name, weapon.accent_color)

func _draw_enemy(enemy: EnemyDefinition) -> void:
	if enemy.sprite_frames == null or not enemy.sprite_frames.has_animation(&"idle"):
		_draw_caption("MISSING IDLE FRAMES", Color("ff315f"))
		return
	var frame_count := enemy.sprite_frames.get_frame_count(&"idle")
	if frame_count <= 0:
		return
	var speed := maxf(enemy.sprite_frames.get_animation_speed(&"idle"), 1.0)
	var frame := int(_time * speed) % frame_count
	var texture := enemy.sprite_frames.get_frame_texture(&"idle", frame)
	if texture:
		var texture_size := Vector2(texture.get_size())
		var max_size := Vector2(size.x - 50, size.y - 38)
		var scale_factor := minf(max_size.x / maxf(texture_size.x, 1.0), max_size.y / maxf(texture_size.y, 1.0))
		var draw_size := texture_size * scale_factor
		var draw_rect := Rect2((size - draw_size) * 0.5 + Vector2(0, 4), draw_size)
		draw_texture_rect(texture, draw_rect, false, enemy.sprite_tint)
	_draw_caption(enemy.display_name, enemy.sprite_tint)

func _draw_fx(fx: FxDefinition) -> void:
	var center := size * 0.5
	var count := mini(fx.particle_count, 48)
	for index in count:
		var phase := float(index) * 2.39996
		var pulse := 0.45 + 0.55 * absf(sin(_time * 2.4 + float(index) * 0.31))
		var radius := (18.0 + float(index % 9) * 7.0) * pulse
		var point := center + Vector2(cos(phase), sin(phase)) * radius
		var color := fx.color.lerp(fx.secondary_color, float(index % 3) / 2.0)
		draw_circle(point, clampf(fx.particle_size * 70.0, 2.0, 9.0), color)
	draw_circle(center, 18.0 + sin(_time * 5.0) * 4.0, Color(fx.color, 0.35))
	_draw_caption(fx.display_name, fx.color)

func _draw_surface(surface: SurfaceDefinition) -> void:
	var swatch := Rect2(Vector2(34, 31), size - Vector2(68, 64))
	draw_rect(swatch.grow(5), Color(0, 0, 0, 0.65), true)
	draw_rect(swatch, surface.palette_color, true)
	for offset in range(-int(swatch.size.y), int(swatch.size.x), 18):
		draw_line(swatch.position + Vector2(offset, swatch.size.y), swatch.position + Vector2(offset + swatch.size.y, 0), Color(1, 1, 1, 0.08), 2.0)
	_draw_caption(surface.display_name, surface.palette_color.lightened(0.28))

func _draw_caption(caption: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(12, size.y - 10), caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, 13, color)

