class_name CombatReticle
extends Control

var _hit_time := 0.0
var _kill_confirm := false
var _spread := 7.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func confirm_hit(killed: bool) -> void:
	_hit_time = 0.16 if not killed else 0.3
	_kill_confirm = killed
	queue_redraw()

func set_dynamic_spread(value: float) -> void:
	_spread = lerpf(_spread, value, 0.25)
	queue_redraw()

func _process(delta: float) -> void:
	if _hit_time > 0.0:
		_hit_time -= delta
		queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var accent := Color("65f4d5")
	var length := 6.0
	var width := 2.0
	draw_line(center + Vector2(-_spread - length, 0), center + Vector2(-_spread, 0), accent, width)
	draw_line(center + Vector2(_spread, 0), center + Vector2(_spread + length, 0), accent, width)
	draw_line(center + Vector2(0, -_spread - length), center + Vector2(0, -_spread), accent, width)
	draw_line(center + Vector2(0, _spread), center + Vector2(0, _spread + length), accent, width)
	draw_circle(center, 1.5, Color.WHITE)
	if _hit_time > 0.0:
		var hit_color := Color("ff315f") if _kill_confirm else Color.WHITE
		var radius := 10.0 if _kill_confirm else 8.0
		for x in [-1.0, 1.0]:
			for y in [-1.0, 1.0]:
				draw_line(center + Vector2(x, y) * (radius - 4.0), center + Vector2(x, y) * radius, hit_color, 2.5)

