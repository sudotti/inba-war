extends Control

## 左下に台を固定するスティック。ノブだけ動かし、指を離すと中央に戻す。

var direction := Vector2.ZERO

var _holding := false
var _finger := -1
var _ignore_finger := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		release()


func release() -> void:
	# メニューが開いた指は、離すまで掴み直さない。
	if _finger >= 0:
		_ignore_finger = _finger
	_drop()


func _drop() -> void:
	_holding = false
	_finger = -1
	direction = Vector2.ZERO
	queue_redraw()


func echoing_touch() -> bool:
	return false


func guard_mouse_echo() -> void:
	release()


func place_bottom_left(screen: Vector2) -> void:
	var side := 320.0
	position = Vector2(16.0, screen.y - side - 28.0)
	size = Vector2(side, side)
	custom_minimum_size = size


func _input(event: InputEvent) -> void:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if not event.pressed and event.index == _ignore_finger:
			_ignore_finger = -1
		if event.pressed:
			if event.index == _ignore_finger or not _inside(event.position):
				return
			_finger = event.index
			_holding = true
			_apply(_to_local(event.position))
			get_viewport().set_input_as_handled()
		elif _finger < 0 or event.index == _finger or event.canceled:
			_drop()
	elif event is InputEventScreenDrag and _holding and event.index == _finger:
		_apply(_to_local(event.position))
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	# スマホはタッチのあとにマウスが遅れて届き、ノブを押した位置へ戻してしまう。
	if DisplayServer.is_touchscreen_available() or _finger >= 0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_holding = true
			_apply(event.position)
		else:
			_drop()
		accept_event()
	elif event is InputEventMouseMotion and _holding:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			release()
			return
		_apply(event.position)
		accept_event()


func _inside(viewport_pos: Vector2) -> bool:
	return get_global_rect().has_point(viewport_pos)


func _to_local(viewport_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_pos


func _apply(pos: Vector2) -> void:
	var delta := pos - size * 0.5
	var radius := _radius()
	if delta.length() < radius * 0.2:
		direction = Vector2.ZERO
	else:
		direction = delta / radius
		if direction.length() > 1.0:
			direction = direction.normalized()
	queue_redraw()


func _radius() -> float:
	return minf(size.x, size.y) * 0.36


func _draw() -> void:
	var radius := _radius()
	var center := size * 0.5
	var knob := center + direction * radius
	var knob_radius := radius * 0.42
	draw_circle(center, radius, Color(0, 0, 0, 0.34))
	draw_arc(center, radius, 0, TAU, 48, Color(1, 1, 1, 0.76), 4.0, true)
	draw_circle(knob, knob_radius, Color("f3ead2"))
	draw_arc(knob, knob_radius, 0, TAU, 32, Color("161616"), 4.0, true)
