extends RefCounted
class_name UiFont

const FONT_PATH := "res://assets/fonts/NotoSerifJP-Light.ttf"

const INK := Color("1c1814")
const PAPER := Color("f4ecdf")
const CREAM := Color("d9ccb8")
const NIGHT := Color("0b0b0f")
const CARD := Color("141414")
const BRASS := Color("d8b26c")
const BRASS_DEEP := Color("a68448")
const EMBER := Color("d4654a")
const PINK := EMBER
const CYAN := NIGHT
const GRASS := Color("181818")
const GRASS_DARK := Color("0f0f0f")
const YELLOW := BRASS
const NAVY := Color("0f0f12")
const ROYAL := Color("1a1a22")
const ROYAL_DEEP := Color("050505")
const GOLD := Color("f0d28a")

static var _font: Font


static func glass_fill(alpha: float = 0.22) -> Color:
	return Color(0.12, 0.12, 0.16, alpha)


static func glass_border(alpha: float = 0.85) -> Color:
	return Color(1.0, 0.87, 0.55, alpha)


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
		_font = load(FONT_PATH)
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
	node.add_theme_stylebox_override("normal", style(PAPER, BRASS, 2, 12))
	node.add_theme_stylebox_override("hover", style(GOLD, BRASS, 2, 12))
	node.add_theme_stylebox_override("pressed", style(Color("e2b45a"), BRASS, 2, 12))
	node.add_theme_stylebox_override("focus", style(PAPER, BRASS, 2, 12))
	node.add_theme_stylebox_override("disabled", style(Color("8a8174"), Color("3a342c"), 2, 12))
	node.custom_minimum_size = Vector2(280, 72)
	return node


static func royal_button(text: String, size: int = 24, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.add_theme_font_override("font", font())
	node.add_theme_font_size_override("font_size", size)
	var text_color := PAPER if not primary else Color("1c1814")
	node.add_theme_color_override("font_color", text_color)
	node.add_theme_color_override("font_hover_color", text_color)
	node.add_theme_color_override("font_pressed_color", text_color)
	node.add_theme_color_override("font_focus_color", text_color)
	node.add_theme_color_override("font_disabled_color", Color("5c564c"))
	if primary:
		node.add_theme_stylebox_override("normal", style(glass_fill(0.32), glass_border(0.95), 1, 12))
		node.add_theme_stylebox_override("hover", style(glass_fill(0.48), Color("fff0c2"), 1, 12))
		node.add_theme_stylebox_override("pressed", style(glass_fill(0.18), glass_border(0.7), 1, 12))
		node.add_theme_stylebox_override("focus", style(glass_fill(0.32), glass_border(0.95), 1, 12))
	else:
		node.add_theme_stylebox_override("normal", style(glass_fill(0.18), glass_border(0.8), 1, 12))
		node.add_theme_stylebox_override("hover", style(glass_fill(0.32), Color("fff0c2"), 1, 12))
		node.add_theme_stylebox_override("pressed", style(glass_fill(0.1), glass_border(0.6), 1, 12))
		node.add_theme_stylebox_override("focus", style(glass_fill(0.18), glass_border(0.8), 1, 12))
	node.add_theme_stylebox_override("disabled", style(Color("151515"), Color("333333"), 1, 12))
	node.custom_minimum_size = Vector2(240, 64)
	return node


static func royal_panel(fill: Color = ROYAL, border: Color = BRASS, width: int = 3, radius: int = 16) -> StyleBoxFlat:
	return style(fill, border, width, radius)


static func portrait(size: Vector2) -> bool:
	return size.y > size.x


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
