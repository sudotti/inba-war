extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")

const HERO := "res://assets/portraits/masaki.png"
const W := 390
const H := 844

var _name_panel: Control
var _name_edit: LineEdit
var _name_hint: Label


func _ready() -> void:
	get_viewport().size_changed.connect(_on_resized)
	_build()
	if SaveStore.shown_name() == "":
		_open_name_entry()


func _on_resized() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	_name_panel = null
	_name_edit = null
	_name_hint = null

	_build_background()
	_build_top_bar()
	_build_hero()
	_build_main_button()
	_build_sub_menu()
	_build_version()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 1.0)
	_set_full_rect(bg)
	add_child(bg)


func _build_top_bar() -> void:
	var bar := HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_anchors(bar, 0, 16, W, 52)
	add_child(bar)

	var left := Control.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(left)

	var name_pill := _make_pill(SaveStore.shown_name(), 160)
	name_pill.anchor_left = 0.0
	name_pill.anchor_top = 0.5
	name_pill.anchor_right = 0.0
	name_pill.anchor_bottom = 0.5
	name_pill.offset_left = 16
	name_pill.offset_top = -18
	name_pill.offset_right = 176
	name_pill.offset_bottom = 18
	left.add_child(name_pill)

	var right := Control.new()
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(right)

	var yen_pill := _make_pill("💰 " + str(int(SaveStore.data.get("yen", 0))), 136)
	yen_pill.anchor_left = 1.0
	yen_pill.anchor_top = 0.5
	yen_pill.anchor_right = 1.0
	yen_pill.anchor_bottom = 0.5
	yen_pill.offset_left = -152
	yen_pill.offset_top = -18
	yen_pill.offset_right = -16
	yen_pill.offset_bottom = 18
	right.add_child(yen_pill)


func _make_pill(text: String, width: float) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.border_color = UiFont.GOLD
	style.set_border_width_all(1.5)
	style.set_corner_radius_all(16)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := UiFont.label(text, 16, UiFont.GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 2)
	panel.add_child(label)

	return panel


func _set_full_rect(node: Control) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0


func _set_anchors(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.anchor_left = left / W
	node.anchor_top = top / H
	node.anchor_right = right / W
	node.anchor_bottom = bottom / H
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0


func _build_hero() -> void:
	var hero_frame := Control.new()
	hero_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_anchors(hero_frame, 0, 64, W, 500)
	add_child(hero_frame)

	var hero_texture := load(HERO)
	var hero_image := TextureRect.new()
	hero_image.texture = hero_texture
	hero_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(hero_image)
	hero_frame.add_child(hero_image)

	var grad := Gradient.new()
	grad.add_point(0.0, Color(0, 0, 0, 0.0))
	grad.add_point(0.55, Color(0, 0, 0, 0.0))
	grad.add_point(0.75, Color(0, 0, 0, 0.25))
	grad.add_point(1.0, Color(0, 0, 0, 0.95))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	grad_tex.width = 512
	var fade := TextureRect.new()
	fade.texture = grad_tex
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(fade)
	hero_frame.add_child(fade)


func _build_main_button() -> void:
	var btn := Button.new()
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_anchors(btn, 20, 520, 370, 604)
	add_child(btn)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.04, 0.95)
	style.border_color = UiFont.GOLD
	style.set_border_width_all(2.5)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.15, 0.06, 1.0)
	hover.border_color = UiFont.GOLD
	hover.set_border_width_all(3.0)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.05, 0.04, 0.02, 1.0)
	pressed.border_color = UiFont.BRASS
	btn.add_theme_stylebox_override("pressed", pressed)

	var focus := style.duplicate() as StyleBoxFlat
	focus.border_color = UiFont.GOLD
	focus.set_border_width_all(3.0)
	btn.add_theme_stylebox_override("focus", focus)

	var container := HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 10)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(container)
	btn.add_child(container)

	var icon := Label.new()
	icon.text = "⚔"
	icon.add_theme_font_override("font", UiFont.font())
	icon.add_theme_font_size_override("font_size", 32)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(icon)

	var label := UiFont.label("出撃", 28, UiFont.PAPER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)

	btn.pressed.connect(_start)


func _build_sub_menu() -> void:
	var items = [
		["ランキング", "🏆", _open_ranking],
		["敵図鑑", "📖", _open_bestiary],
		["なかむら商店", "🏪", _open_shop],
		["設定", "⚙", _open_settings],
	]

	var positions = [
		Vector2(20, 620),
		Vector2(203, 620),
		Vector2(20, 708),
		Vector2(203, 708),
	]

	for i in items.size():
		var item = items[i]
		var pos = positions[i]
		var btn := _make_sub_button(item[0], item[1], item[2])
		_set_anchors(btn, pos.x, pos.y, pos.x + 167, pos.y + 72)
		add_child(btn)


func _make_sub_button(label: String, icon: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08, 0.92)
	style.border_color = Color(1.0, 0.88, 0.58, 0.3)
	style.set_border_width_all(1.5)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.12, 0.10, 0.06, 0.98)
	hover.border_color = UiFont.GOLD
	hover.set_border_width_all(2.0)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.04, 0.04, 0.05, 1.0)
	pressed.border_color = UiFont.BRASS
	btn.add_theme_stylebox_override("pressed", pressed)

	var focus := style.duplicate() as StyleBoxFlat
	focus.border_color = UiFont.GOLD
	focus.set_border_width_all(2.0)
	btn.add_theme_stylebox_override("focus", focus)

	var container := HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 8)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(container)
	btn.add_child(container)

	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_override("font", UiFont.font())
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(28, 28)
	container.add_child(icon_label)

	var text_label := UiFont.label(label, 18, UiFont.PAPER)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(text_label)

	btn.pressed.connect(callback)
	return btn


func _open_settings() -> void:
	pass


func _build_version() -> void:
	var label := UiFont.label("v0.1.0", 12, Color(0.4, 0.35, 0.25, 0.6))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.anchor_left = 0.5
	label.anchor_top = 810.0 / H
	label.anchor_right = 0.5
	label.anchor_bottom = 810.0 / H
	label.offset_left = -50
	label.offset_top = -8
	label.offset_right = 50
	label.offset_bottom = 8
	add_child(label)


func _name_button() -> Button:
	var node := Button.new()
	node.text = "プレイヤー  %s" % SaveStore.shown_name()
	node.add_theme_font_override("font", UiFont.font())
	node.add_theme_font_size_override("font_size", 20)
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
	_set_full_rect(overlay)
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_full_rect(dim)
	overlay.add_child(dim)
	var panel := _make_pill("", 300)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -150
	panel.offset_top = -120
	panel.offset_right = 150
	panel.offset_bottom = 120
	overlay.add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_full_rect(col)
	panel.add_child(col)
	var heading := UiFont.label("名前を決めてね", 26, UiFont.GOLD)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(heading)
	var note := UiFont.label("戦績はこの端末に保存されるよ", 14, UiFont.CREAM)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(note)
	var edit := LineEdit.new()
	edit.max_length = 10
	edit.placeholder_text = "例： なつき"
	edit.add_theme_font_override("font", UiFont.font())
	edit.add_theme_font_size_override("font_size", 24)
	edit.add_theme_color_override("font_color", UiFont.INK)
	edit.add_theme_color_override("font_placeholder_color", Color("8a8174"))
	edit.add_theme_color_override("font_focus_color", UiFont.INK)
	edit.add_theme_color_override("font_selection_color", Color("f0c75e"))
	edit.add_theme_stylebox_override("normal", UiFont.style(UiFont.PAPER, UiFont.BRASS, 2, 12))
	edit.add_theme_stylebox_override("focus", UiFont.style(UiFont.PAPER, UiFont.BRASS, 2, 12))
	edit.custom_minimum_size = Vector2(0, 56)
	edit.text_submitted.connect(_submit_name)
	col.add_child(edit)
	_name_hint = UiFont.label("", 14, UiFont.EMBER)
	_name_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_name_hint)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(actions)
	var submit := UiFont.royal_button("決める", 22, true)
	submit.custom_minimum_size = Vector2(140, 52)
	submit.pressed.connect(func() -> void: _submit_name(edit.text))
	actions.add_child(submit)
	var skip := UiFont.royal_button("スキップ", 22, false)
	skip.custom_minimum_size = Vector2(140, 52)
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