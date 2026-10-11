extends Control

const RADIUS_MIN := 96.0
const RADIUS_MAX := 144.0

var direction := Vector2.ZERO

var _pressing := false
var _origin := Vector2.ZERO
var _finger := -1
var _mouse_up_pending := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_finger = -1
		_mouse_up_pending = false
		_end()


func _process(_dt: float) -> void:
	# マウスの離すは、同じフレームのタッチより先に来ることがある。フレーム末で指が残っていれば維持する。
	if _mouse_up_pending:
		_mouse_up_pending = false
		if _finger < 0:
			_end()
	if _finger < 0 and _pressing and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_end()
	queue_redraw()


func _input(event: InputEvent) -> void:
	# HUD の全面パネルが _gui_input を先に止める。指の開始はここで受ける。
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _finger >= 0 or _over_button(event.position):
				return
			_finger = event.index
			_mouse_up_pending = false
			_begin(_to_local(event.position))
			get_viewport().set_input_as_handled()
		elif event.index == _finger:
			_finger = -1
			_end()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _finger:
		_drag(_to_local(event.position))
		get_viewport().set_input_as_handled()
	elif _finger >= 0 and (event is InputEventMouseButton or event is InputEventMouseMotion):
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _finger < 0 and not _over_button(event.position):
				_finger = event.index
				_mouse_up_pending = false
				_begin(event.position)
		elif event.index == _finger:
			_finger = -1
			_end()
		accept_event()
	elif event is InputEventScreenDrag and event.index == _finger:
		_drag(event.position)
		accept_event()
	elif _finger >= 0:
		if event is InputEventMouseButton or event is InputEventMouseMotion:
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_up_pending = false
			_begin(event.position)
		else:
			_mouse_up_pending = true
		accept_event()
	elif event is InputEventMouseMotion and _pressing and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_drag(event.position)
		accept_event()


func _to_local(viewport_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_pos


func _over_button(viewport_pos: Vector2) -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	return _button_at(tree.root, viewport_pos)


func _button_at(node: Node, viewport_pos: Vector2) -> bool:
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return false
	if node is Button:
		var button := node as Button
		if button != self and button.mouse_filter != Control.MOUSE_FILTER_IGNORE and button.get_global_rect().has_point(viewport_pos):
			return true
	for child in node.get_children():
		if _button_at(child, viewport_pos):
			return true
	return false


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
	var screen_width := size.x
	var target := minf(size.y * 0.145, screen_width * 0.105)
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
