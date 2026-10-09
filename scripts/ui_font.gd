extends RefCounted
class_name UiFont

const FONT_PATH := "res://assets/fonts/NotoSansJP-Bold.ttf"

const INK := Color("1c1814")
const PAPER := Color("f4ecdf")
const CREAM := Color("d9ccb8")
const NIGHT := Color("14110e")
const CARD := Color("221c17")
const BRASS := Color("d7b072")
const BRASS_DEEP := Color("a68448")
const EMBER := Color("d4654a")
const PINK := EMBER
const CYAN := NIGHT
const GRASS := Color("2a241c")
const GRASS_DARK := Color("1a1612")
const YELLOW := BRASS
const NAVY := Color("14110e")

static var _font: Font


static func cropped(path: String) -> Texture2D:
	var tex: Texture2D = load(path)
	var image := tex.get_image()
	if image == null or image.is_empty():
		return tex
	var used: Rect2i = image.get_used_rect()
	if used.size.x < 8 or used.size.y < 8:
		return tex
	var grown := Rect2i(used.position - Vector2i(2, 2), used.size + Vector2i(4, 4))
	grown = grown.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if grown.size.x < 8 or grown.size.y < 8:
		return tex
	return ImageTexture.create_from_image(image.get_region(grown))


static func font() -> Font:
	if _font == null:
		var variation := FontVariation.new()
		variation.base_font = load(FONT_PATH)
		variation.variation_opentype = {&"wght": 700.0}
		_font = variation
	return _font


static func label(text: String, size: int, color: Color = PAPER) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", font())
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.78))
	node.add_theme_constant_override("outline_size", 0 if color == INK else 6)
	return node


static func style(fill: Color, border: Color, width: int = 4, radius: int = 18) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box


static func button(text: String, size: int = 28) -> Button:
	var node := Button.new()
	node.text = text
	node.add_theme_font_override("font", font())
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", INK)
	node.add_theme_color_override("font_hover_color", INK)
	node.add_theme_color_override("font_pressed_color", INK)
	node.add_theme_color_override("font_focus_color", INK)
	node.add_theme_color_override("font_disabled_color", Color("5c564c"))
	node.add_theme_stylebox_override("normal", style(PAPER, BRASS_DEEP, 2, 12))
	node.add_theme_stylebox_override("hover", style(BRASS, INK, 2, 12))
	node.add_theme_stylebox_override("pressed", style(Color("c9a56a"), INK, 2, 12))
	node.add_theme_stylebox_override("focus", style(PAPER, BRASS, 2, 12))
	node.add_theme_stylebox_override("disabled", style(Color("8a8174"), Color("3a342c"), 2, 12))
	node.custom_minimum_size = Vector2(280, 72)
	return node


static func full_rect(node: Control) -> void:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0


static func place(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.anchor_left = left
	node.anchor_top = top
	node.anchor_right = right
	node.anchor_bottom = bottom
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0
