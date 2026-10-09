extends Control

const RADIUS_MIN := 72.0
const RADIUS_MAX := 112.0

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
	var radius := _radius()
	_pressing = true
	_origin = Vector2(
		clampf(pos.x, radius, maxf(radius, size.x - radius)),
		clampf(pos.y, radius, maxf(radius, size.y - radius))
	)
	_drag(pos)


func _drag(pos: Vector2) -> void:
	var delta := pos - _origin
	var radius := _radius()
	if delta.length() < radius * 0.135:
		direction = Vector2.ZERO
		return
	direction = delta / radius
	if direction.length() > 1.0:
		direction = direction.normalized()


func _end() -> void:
	_pressing = false
	direction = Vector2.ZERO


func _default_base() -> Vector2:
	var offset := _radius() * 1.62
	return Vector2(offset, maxf(offset, size.y - offset))


func _radius() -> float:
	var screen_width := size.x / 0.46
	var target := minf(size.y * 0.145, screen_width * 0.08125)
	return clampf(target, RADIUS_MIN, RADIUS_MAX)


func _draw() -> void:
	var radius := _radius()
	var knob_radius := radius * 0.4
	var base := _origin if _pressing else _default_base()
	var knob := base + direction * radius
	draw_circle(base, radius, Color(0, 0, 0, 0.34))
	draw_arc(base, radius, 0, TAU, 48, Color(1, 1, 1, 0.76), 4.0, true)
	draw_circle(knob, knob_radius, Color("f3ead2"))
	draw_arc(knob, knob_radius, 0, TAU, 32, Color("161616"), 4.0, true)
