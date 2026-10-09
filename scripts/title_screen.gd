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


func _ready() -> void:
	get_viewport().size_changed.connect(_on_resized)
	_portrait = UiFont.portrait(get_viewport_rect().size)
	_build()
	if SaveStore.shown_name() == "":
		_open_name_entry()


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


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
	_seed_lights()
	_build_background()
	_build_fx()
	_build_title_portrait()
	_build_hero()
	_build_menu_vertical(0.56, 0.98)


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


func _scrim_texture() -> GradientTexture1D:
	var grad := Gradient.new()
	grad.add_point(0.0, Color(0.03, 0.05, 0.16, 0.94))
	grad.add_point(0.22, Color(0.03, 0.05, 0.16, 0.62))
	grad.add_point(0.45, Color(0.03, 0.05, 0.16, 0.10))
	grad.add_point(0.68, Color(0.03, 0.05, 0.16, 0.42))
	grad.add_point(1.0, Color(0.03, 0.05, 0.16, 0.95))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	tex.width = 512
	return tex


func _build_title_portrait() -> void:
	var panel := GoldFrame.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(panel, 0.05, 0.035, 0.95, 0.15)
	add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(col)
	panel.add_child(col)
	var title := UiFont.label(Balance.TITLE, 40, UiFont.GOLD)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var subtitle := UiFont.label("迫り来る敵の魔の手から、印旛中を守れ！", 16, UiFont.CREAM)
  subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
  subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  col.add_child(subtitle)





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








func _build_menu_vertical(top: float, bottom: float) -> void:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	UiFont.place(col, 0.08, top, 0.92, bottom)
	add_child(col)
	for item in _menu_items():
		var btn := UiFont.royal_button(str(item[0]), 22, bool(item[1]))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 56)
		btn.pressed.connect(item[2])
		col.add_child(btn)

func _menu_items() -> Array:
	return [
		["出撃", true, _start],
		["ランキング", false, _open_ranking],
		["敵図鑑", false, _open_bestiary],
		["なかむら商店", false, _open_shop],
	]


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