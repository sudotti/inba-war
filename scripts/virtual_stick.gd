extends Control

const RADIUS := 104.0
const KNOB := 42.0
const DEAD := 14.0

var direction := Vector2.ZERO

var _pressing := false
var _origin := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_dt: float) -> void:
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin(event.position)
		else:
			_end()
		accept_event()
	elif event is InputEventScreenDrag and _pressing:
		_drag(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin(event.position)
		else:
			_end()
		accept_event()
	elif event is InputEventMouseMotion and _pressing and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_drag(event.position)
		accept_event()


func _begin(pos: Vector2) -> void:
	_pressing = true
	_origin = Vector2(
		clampf(pos.x, RADIUS, maxf(RADIUS, size.x - RADIUS)),
		clampf(pos.y, RADIUS, maxf(RADIUS, size.y - RADIUS))
	)
	_drag(pos)


func _drag(pos: Vector2) -> void:
	var delta := pos - _origin
	if delta.length() < DEAD:
		direction = Vector2.ZERO
		return
	direction = delta / RADIUS
	if direction.length() > 1.0:
		direction = direction.normalized()


func _end() -> void:
	_pressing = false
	direction = Vector2.ZERO


func _default_base() -> Vector2:
	return Vector2(168, maxf(168, size.y - 168))


func _draw() -> void:
	var base := _origin if _pressing else _default_base()
	var knob := base + direction * RADIUS
	draw_circle(base, RADIUS, Color(0, 0, 0, 0.28))
	draw_arc(base, RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.7), 4.0, true)
	draw_circle(knob, KNOB, Color("f3ead2"))
	draw_arc(knob, KNOB, 0, TAU, 32, Color("161616"), 4.0, true)
