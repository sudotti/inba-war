extends RefCounted
class_name SafeArea

static func get_safe_margins(viewport: Viewport) -> Rect2:
	var safe_area := DisplayServer.get_display_safe_area()
	if safe_area == Rect2i(0, 0, 0, 0):
		return Rect2(0, 0, 0, 0)
	var view_rect := viewport.get_visible_rect()
	var left := maxi(0, safe_area.position.x - view_rect.position.x)
	var top := maxi(0, safe_area.position.y - view_rect.position.y)
	var right := maxi(0, view_rect.position.x + view_rect.size.x - (safe_area.position.x + safe_area.size.x))
	var bottom := maxi(0, view_rect.position.y + view_rect.size.y - (safe_area.position.y + safe_area.size.y))
	return Rect2(left, top, right, bottom)

static func apply_safe_padding(node: MarginContainer, viewport: Viewport) -> void:
	var margins := get_safe_margins(viewport)
	node.add_theme_constant_override("margin_left", margins.position.x)
	node.add_theme_constant_override("margin_top", margins.position.y)
	node.add_theme_constant_override("margin_right", margins.size.x)
	node.add_theme_constant_override("margin_bottom", margins.size.y)