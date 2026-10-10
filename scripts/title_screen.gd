extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")

const HERO := "res://assets/portraits/masaki.png"

var _name_panel: Control
var _name_edit: LineEdit
var _name_hint: Label
var _main_margin: MarginContainer


func _ready() -> void:
	_build()
	if SaveStore.shown_name() == "":
		_open_name_entry()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	_name_panel = null
	_name_edit = null
	_name_hint = null
	_main_margin = null

	_build_background()
	_build_content()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 1.0)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	UiFont.full_rect(bg)
	add_child(bg)

	# Hero image as full-screen background
	var hero_texture := load(HERO)
	var hero_image := TextureRect.new()
	hero_image.texture = hero_texture
	hero_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(hero_image)
	hero_image.modulate = Color(1, 1, 1, 0.35)
	add_child(hero_image)

	# Gradient fade at bottom
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
	UiFont.full_rect(fade)
	add_child(fade)


func _build_content() -> void:
	_main_margin = MarginContainer.new()
	_main_margin.anchors_preset = Control.PRESET_FULL_RECT
	UiFont.full_rect(_main_margin)
	_main_margin.add_theme_constant_override("margin_left", 24)
	_main_margin.add_theme_constant_override("margin_right", 24)
	add_child(_main_margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 12)
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.custom_minimum_size = Vector2(0, 400)
	_main_margin.add_child(root)

	var top_bar := HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_theme_constant_override("separation", 12)
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(top_bar)

	# Left: player name
	var name_pill := _make_pill(SaveStore.shown_name())
	name_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top_bar.add_child(name_pill)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# Right: yen
	var yen_pill := _make_pill("💰 " + str(int(SaveStore.data.get("yen", 0))) + "円")
	yen_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top_bar.add_child(yen_pill)

	# Spacer to push content to center
	var v_spacer_top := Control.new()
	v_spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(v_spacer_top)

	# Main sortie button
	var main_btn := _make_main_button()
	main_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_btn.custom_minimum_size = Vector2(0, 56)
	root.add_child(main_btn)

	# Sub menu grid
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(grid)

	var items = [
		["ランキング", "🏆", _open_ranking],
		["敵図鑑", "📖", _open_bestiary],
		["なかむら商店", "🏪", _open_shop],
		["設定", "⚙", _open_settings],
	]
	for item in items:
		var btn := _make_sub_button(item[0], item[1], item[2])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 56)
		grid.add_child(btn)

	# Bottom spacer
	var v_spacer_bottom := Control.new()
	v_spacer_bottom.custom_minimum_size = Vector2(0, 24)
	root.add_child(v_spacer_bottom)


func _make_pill(text: String) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.border_color = UiFont.GOLD
	style.set_border_width_all(1.5)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
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


func _make_main_button() -> Button:
	var btn := Button.new()
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

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
	container.anchors_preset = Control.PRESET_FULL_RECT
	btn.add_child(container)

	var icon := Label.new()
	icon.text = "⚔"
	icon.add_theme_font_override("font", UiFont.font())
	icon.add_theme_font_size_override("font_size", 28)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(icon)

	var label := UiFont.label("出撃", 24, UiFont.PAPER)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)

	btn.pressed.connect(_start)
	return btn


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
	container.anchors_preset = Control.PRESET_FULL_RECT
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
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.anchors_preset = Control.PRESET_FULL_RECT
	overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -160
	panel.offset_top = -140
	panel.offset_right = 160
	panel.offset_bottom = 140
	panel.add_theme_stylebox_override("panel", UiFont.style(Color(0.12, 0.1, 0.08, 0.95), UiFont.GOLD, 2, 16))
	overlay.add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.anchors_preset = Control.PRESET_FULL_RECT
	col.add_theme_constant_override("margin_left", 24)
	col.add_theme_constant_override("margin_right", 24)
	col.add_theme_constant_override("margin_top", 20)
	col.add_theme_constant_override("margin_bottom", 20)
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


func _open_settings() -> void:
	pass