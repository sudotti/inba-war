extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")

const HERO := "res://assets/battle/massa.png"

var _lights: Array[Dictionary] = []
var _t := 0.0
var _portrait := false
var _name_panel: Control
var _name_edit: LineEdit
var _name_hint: Label

var _hero_image: TextureRect
var _menu_container: Control


func _ready() -> void:
	get_viewport().size_changed.connect(_on_resized)
	_portrait = UiFont.portrait(get_viewport_rect().size)
	_build()
	if SaveStore.shown_name() == "":
		_open_name_entry()


func _process(dt: float) -> void:
	_t += dt
	if _hero_image != null:
		_hero_image.queue_redraw()


func _on_resized() -> void:
	var portrait := UiFont.portrait(get_viewport_rect().size)
	if portrait != _portrait:
		_portrait = portrait
		_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	_name_panel = null
	_name_edit = null
	_name_hint = null
	_hero_image = null
	_menu_container = null

	_seed_lights()
	_build_background()
	_build_fx()
	_build_hero_fullscreen()
	_build_top_bar()
	_build_menu_bottom()
	_build_version_label()


func _seed_lights() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 46:
		_lights.append({
			"x": rng.randf(),
			"y": rng.randf(),
			"r": rng.randf_range(2.0, 7.0),
			"hz": rng.randf_range(0.4, 1.6),
			"phase": rng.randf_range(0.0, TAU),
		})


func _build_background() -> void:
	var grad := Gradient.new()
	grad.add_point(0.0, Color(0.02, 0.02, 0.04, 1.0))
	grad.add_point(0.5, Color(0.05, 0.05, 0.08, 1.0))
	grad.add_point(1.0, Color(0.02, 0.02, 0.04, 1.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	tex.width = 512
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(bg)
	add_child(bg)


func _build_fx() -> void:
	var fx := Sparkles.new()
	fx.lights = _lights
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(fx)
	add_child(fx)


func _build_hero_fullscreen() -> void:
	var hero_frame := Control.new()
	hero_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(hero_frame, 0.0, 0.0, 1.0, 1.0)
	add_child(hero_frame)

	var hero_texture := load(HERO)
	_hero_image = TextureRect.new()
	_hero_image.texture = hero_texture
	_hero_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_hero_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(_hero_image)
	hero_frame.add_child(_hero_image)

	var vignette := ColorRect.new()
	vignette.color = Color(0, 0, 0, 0.0)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(vignette)
	hero_frame.add_child(vignette)

	var name_badge := Control.new()
	name_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_badge.anchor_left = 0.5
	name_badge.anchor_top = 0.0
	name_badge.anchor_right = 0.5
	name_badge.anchor_bottom = 0.0
	name_badge.offset_left = -180
	name_badge.offset_top = 60
	name_badge.offset_right = 180
	name_badge.offset_bottom = 110
	hero_frame.add_child(name_badge)

	var badge_bg := Panel.new()
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.02, 0.02, 0.04, 0.85)
	badge_style.border_color = UiFont.GOLD
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(28)
	badge_style.content_margin_left = 28
	badge_style.content_margin_right = 28
	badge_style.content_margin_top = 12
	badge_style.content_margin_bottom = 12
	badge_bg.add_theme_stylebox_override("panel", badge_style)
	badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(badge_bg)
	name_badge.add_child(badge_bg)

	var hero_name := UiFont.label("マッサ", 36, UiFont.GOLD)
	hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	hero_name.add_theme_constant_override("outline_size", 5)
	hero_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(hero_name)
	name_badge.add_child(hero_name)

	var hero_title := UiFont.label("印旛中最強の守護者", 16, UiFont.CREAM)
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(hero_title)
	name_badge.add_child(hero_title)

	_hero_image.draw_callback = _draw_hero_overlay.bind(_hero_image)


func _draw_hero_overlay(canvas: TextureRect) -> void:
	var t = _t
	var s = canvas.size

	var grad := Gradient.new()
	grad.add_point(0.0, Color(0.0, 0.0, 0.0, 0.65))
	grad.add_point(0.35, Color(0.0, 0.0, 0.0, 0.15))
	grad.add_point(0.65, Color(0.0, 0.0, 0.0, 0.15))
	grad.add_point(1.0, Color(0.0, 0.0, 0.0, 0.85))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	grad_tex.width = 512
	var rect := Rect2(Vector2.ZERO, s)
	canvas.draw_texture_rect(grad_tex, rect, false)

	var center_x = s.x * 0.5
	var center_y = s.y * 0.72
	var max_r = min(s.x, s.y) * 0.35
	for i in 4:
		var phase = t * 0.5 + i * 1.8
		var r = max_r * (0.55 + 0.45 * sin(phase))
		var alpha = 0.12 * (1.0 - i * 0.18) * (0.6 + 0.4 * sin(phase * 1.2))
		var c = Color(1.0, 0.88, 0.45, alpha)
		canvas.draw_circle(Vector2(center_x, center_y), r, c)

	var pulse = 0.5 + 0.5 * sin(t * 2.0)
	var ring_r = max_r * 0.9
	var ring_alpha = 0.08 + 0.12 * pulse
	canvas.draw_circle(Vector2(center_x, center_y), ring_r, Color(1.0, 0.9, 0.5, ring_alpha), false, 3.0)


func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.anchor_left = 0.0
	bar.anchor_top = 0.0
	bar.anchor_right = 1.0
	bar.anchor_bottom = 0.0
	bar.offset_left = 0
	bar.offset_top = 0
	bar.offset_right = 0
	bar.offset_bottom = 72
	add_child(bar)

	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_BEGIN
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 2)
	bar.add_child(left)

	var name_label := UiFont.label(SaveStore.shown_name(), 26, UiFont.GOLD)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	name_label.add_theme_constant_override("outline_size", 4)
	left.add_child(name_label)

	var right := HBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_END
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_theme_constant_override("separation", 8)
	bar.add_child(right)

	var yen_bg := Panel.new()
	var yen_style := StyleBoxFlat.new()
	yen_style.bg_color = Color(0.05, 0.04, 0.02, 0.9)
	yen_style.border_color = UiFont.GOLD
	yen_style.set_border_width_all(1.5)
	yen_style.set_corner_radius_all(14)
	yen_style.content_margin_left = 14
	yen_style.content_margin_right = 14
	yen_style.content_margin_top = 6
	yen_style.content_margin_bottom = 6
	yen_bg.add_theme_stylebox_override("panel", yen_style)
	yen_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(yen_bg)

	var yen_row := HBoxContainer.new()
	yen_row.alignment = BoxContainer.ALIGNMENT_CENTER
	yen_row.add_theme_constant_override("separation", 6)
	yen_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(yen_row)
	yen_bg.add_child(yen_row)

	var yen_icon := Label.new()
	yen_icon.text = "💰"
	yen_icon.add_theme_font_override("font", UiFont.font())
	yen_icon.add_theme_font_size_override("font_size", 20)
	yen_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	yen_row.add_child(yen_icon)

	var yen_label := UiFont.label(str(int(SaveStore.data.get("yen", 0))), 24, UiFont.GOLD)
	yen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	yen_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	yen_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	yen_label.add_theme_constant_override("outline_size", 3)
	yen_row.add_child(yen_label)


func _build_menu_bottom() -> void:
	_menu_container = Control.new()
	_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_container.anchor_left = 0.0
	_menu_container.anchor_top = 1.0
	_menu_container.anchor_right = 1.0
	_menu_container.anchor_bottom = 1.0
	_menu_container.offset_left = 24
	_menu_container.offset_top = -180
	_menu_container.offset_right = -24
	_menu_container.offset_bottom = -16
	add_child(_menu_container)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(col)
	_menu_container.add_child(col)

	var items := _menu_items()
	for i in items.size():
		var item: Array = items[i]
		var btn := _create_menu_button(item[0], item[1], item[2], item[3])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 56)
		col.add_child(btn)


func _menu_items() -> Array:
	return [
		["出撃", "⚔", true, _start],
		["ランキング", "🏆", false, _open_ranking],
		["敵図鑑", "📖", false, _open_bestiary],
		["なかむら商店", "🏪", false, _open_shop],
	]


func _create_menu_button(label: String, icon: String, primary: bool, callback: Callable) -> Button:
	var container := HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 16)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_override("font", UiFont.font())
	icon_label.add_theme_font_size_override("font_size", 26)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_label.custom_minimum_size = Vector2(36, 36)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(icon_label)

	var text_label := UiFont.label(label, 22, UiFont.PAPER)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(text_label)

	var chevron := Label.new()
	chevron.text = "›"
	chevron.add_theme_font_override("font", UiFont.font())
	chevron.add_theme_font_size_override("font_size", 26)
	chevron.add_theme_color_override("font_color", UiFont.GOLD)
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chevron.custom_minimum_size = Vector2(28, 36)
	chevron.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(chevron)

	var btn := Button.new()
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg_style := StyleBoxFlat.new()
	if primary:
		bg_style.bg_color = Color(0.12, 0.09, 0.04, 0.98)
		bg_style.border_color = UiFont.GOLD
		bg_style.set_border_width_all(2.5)
	else:
		bg_style.bg_color = Color(0.06, 0.06, 0.08, 0.92)
		bg_style.border_color = Color(1.0, 0.88, 0.58, 0.3)
		bg_style.set_border_width_all(1.5)
	bg_style.set_corner_radius_all(14)
	bg_style.content_margin_left = 20
	bg_style.content_margin_right = 20
	bg_style.content_margin_top = 12
	bg_style.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", bg_style)

	var hover_style := bg_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.2, 0.15, 0.06, 1.0)
	hover_style.border_color = UiFont.GOLD
	hover_style.set_border_width_all(3.0)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := bg_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.05, 0.04, 0.02, 1.0)
	pressed_style.border_color = UiFont.BRASS
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var focus_style := bg_style.duplicate() as StyleBoxFlat
	focus_style.border_color = UiFont.GOLD
	focus_style.set_border_width_all(3.0)
	btn.add_theme_stylebox_override("focus", focus_style)

	btn.add_child(container)
	btn.pressed.connect(callback)
	return btn


func _build_version_label() -> void:
	var ver := Label.new()
	ver.text = "v1.0.0"
	ver.add_theme_font_override("font", UiFont.font())
	ver.add_theme_font_size_override("font_size", 11)
	ver.add_theme_color_override("font_color", Color(0.45, 0.4, 0.3, 0.6))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ver.anchor_left = 0.5
	ver.anchor_top = 1.0
	ver.anchor_right = 0.5
	ver.anchor_bottom = 1.0
	ver.offset_left = -50
	ver.offset_top = -28
	ver.offset_right = 50
	ver.offset_bottom = -6
	add_child(ver)


func _name_button() -> Button:
	var node := Button.new()
	node.text = "プレイヤー  %s" % SaveStore.shown_name()
	node.add_theme_font_override("font", UiFont.font())
	node.add_theme_font_size_override("font_size", 18 if _portrait else 20)
	node.add_theme_color_override("font_color", UiFont.CREAM)
	node.add_theme_color_override("font_hover_color", UiFont.GOLD)
	node.add_theme_color_override("font_pressed_color", UiFont.GOLD)
	node.add_theme_color_override("font_focus_color", UiFont.CREAM)
	node.add_theme_color_override("font_disabled_color", UiFont.CREAM)
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		node.add_theme_stylebox_override(state, empty)
	node.alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	node.pressed.connect(_open_name_entry)
	return node


func _open_name_entry() -> void:
	if _name_panel != null:
		_name_panel.visible = true
		return
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(overlay)
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	UiFont.full_rect(dim)
	overlay.add_child(dim)
	var panel := GoldFrame.new()
	UiFont.place(panel, 0.08, 0.28, 0.92, 0.64)
	overlay.add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(col)
	panel.add_child(col)
	var heading := UiFont.label("名前を決めてね", 30 if not _portrait else 26, UiFont.GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(heading)
	var note := UiFont.label("戦績はこの端末に保存されるよ", 16, UiFont.CREAM)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(note)
	var edit := LineEdit.new()
	edit.max_length = 10
	edit.placeholder_text = "例： なつき"
	edit.add_theme_font_override("font", UiFont.font())
	edit.add_theme_font_size_override("font_size", 26)
	edit.add_theme_color_override("font_color", UiFont.INK)
	edit.add_theme_color_override("font_placeholder_color", Color("8a8174"))
	edit.add_theme_color_override("font_focus_color", UiFont.INK)
	edit.add_theme_color_override("font_selection_color", Color("f0c75e"))
	edit.add_theme_stylebox_override("normal", UiFont.style(UiFont.PAPER, UiFont.BRASS, 2, 12))
	edit.add_theme_stylebox_override("focus", UiFont.style(UiFont.PAPER, UiFont.BRASS, 2, 12))
	edit.custom_minimum_size = Vector2(0, 64)
	edit.text_submitted.connect(_submit_name)
	col.add_child(edit)
	_name_hint = UiFont.label("", 16, UiFont.EMBER)
	_name_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_name_hint)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(actions)
	var submit := UiFont.royal_button("決める", 24, true)
	submit.custom_minimum_size = Vector2(160, 60)
	submit.pressed.connect(func() -> void: _submit_name(edit.text))
	actions.add_child(submit)
	var skip := UiFont.royal_button("スキップ", 24, false)
	skip.custom_minimum_size = Vector2(160, 60)
	skip.pressed.connect(_close_name_entry)
	actions.add_child(skip)
	_name_edit = edit
	_name_panel = overlay


func _submit_name(raw: String) -> void:
	var text := raw.strip_edges()
	if SaveStore.set_display_name(text):
		_build()
		return
	if _name_hint != null:
		_name_hint.text = "1〜10文字で入力してね"


func _close_name_entry() -> void:
	if _name_panel != null:
		_name_panel.visible = false


func _start() -> void:
	get_tree().change_scene_to_file("res://scenes/select.tscn")


func _open_shop() -> void:
	SaveStore.shop_return = "res://scenes/title.tscn"
	get_tree().change_scene_to_file("res://scenes/shop.tscn")


func _open_ranking() -> void:
	get_tree().change_scene_to_file("res://scenes/ranking.tscn")


func _open_bestiary() -> void:
	get_tree().change_scene_to_file("res://scenes/bestiary.tscn")


class Sparkles extends Control:
	var lights: Array[Dictionary] = []
	var t := 0.0

	func _process(dt: float) -> void:
		t += dt
		queue_redraw()

	func _draw() -> void:
		for light in lights:
			var x: float = float(light.x) * size.x
			var y: float = float(light.y) * size.y
			var r: float = float(light.r)
			var tw := 0.5 + 0.5 * sin(t * float(light.hz) + float(light.phase))
			var c := Color(1.0, 0.82, 0.42, 0.05 + 0.20 * tw)
			draw_circle(Vector2(x, y), r * (0.75 + 0.5 * tw), c)


class GoldFrame extends Control:
	var fill: Color = Color(0.08, 0.08, 0.12, 0.48)
	var gold := Color(1.0, 0.88, 0.58, 0.9)
	var gold_bright := Color(1.0, 0.92, 0.66, 1.0)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, fill, true)
		draw_rect(r, gold, false, 1.5)
		var inner := r.grow(-6.0)
		draw_rect(inner, Color(1.0, 0.9, 0.6, 0.25), false, 0.5)
		for corner in [Vector2.ZERO, Vector2(size.x, 0.0), Vector2(0.0, size.y), Vector2(size.x, size.y)]:
			var c := Vector2(
				clampf(corner.x, 8.0, size.x - 8.0),
				clampf(corner.y, 8.0, size.y - 8.0)
			)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0.0, -6.0),
				c + Vector2(6.0, 0.0),
				c + Vector2(0.0, 6.0),
				c + Vector2(-6.0, 0.0)
			]), gold_bright)