extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")
const SafeArea = preload("res://scripts/safe_area.gd")

const ORDER: Array[String] = [Balance.CHAR_MASSA, Balance.CHAR_TAKETCHI, Balance.CHAR_KENNY]
const LOCK_ART := "res://assets/ui/lock.png"
const SPECIAL_NAMES := {
	Balance.CHAR_MASSA: "たけだの鉄パイプ",
	Balance.CHAR_TAKETCHI: "エニタイム",
	Balance.CHAR_KENNY: "理学療法連脚",
}
const BLURB := {
	Balance.CHAR_MASSA: "広い射程と強い吹き飛ばし",
	Balance.CHAR_TAKETCHI: "近距離を高威力で制圧",
	Balance.CHAR_KENNY: "高速移動 / 被ダメージ軽減",
}

var _pictures: Dictionary = {}
var _closet: Control
var _closet_name: Label
var _closet_list: VBoxContainer
var _closet_who := ""
var _is_portrait := false
var _main_margin: MarginContainer


func _ready() -> void:
	_is_portrait = UiFont.portrait(get_viewport_rect().size)
	get_viewport().size_changed.connect(_on_resized)
	_build()
	_build_closet()


func _on_resized() -> void:
	var new_portrait = UiFont.portrait(get_viewport_rect().size)
	if new_portrait != _is_portrait:
		_is_portrait = new_portrait
		_build()


func _build() -> void:
	for child in get_children():
		if child != _closet:
			child.queue_free()
	_main_margin = null

	var night := ColorRect.new()
	night.color = Color(0.05, 0.04, 0.08, 1.0)
	night.anchors_preset = Control.PRESET_FULL_RECT
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(night)

	_main_margin = MarginContainer.new()
	_main_margin.anchors_preset = Control.PRESET_FULL_RECT
	SafeArea.apply_safe_padding(_main_margin, get_viewport())
	add_child(_main_margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 12)
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_margin.add_child(root)

	# Title
	var title := UiFont.label("キャラクター選択", 32, UiFont.PAPER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(title)

	# Character list
	if _is_portrait:
		var scroll := ScrollContainer.new()
		scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		root.add_child(scroll)

		var content := VBoxContainer.new()
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 12)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(content)

		for who in ORDER:
			var card = _card(who)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			content.add_child(card)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 100)
		content.add_child(spacer)
	else:
		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		root.add_child(center)

		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		center.add_child(row)

		for who in ORDER:
			var card = _card(who)
			card.custom_minimum_size = Vector2(280, 0)
			row.add_child(card)

	# Back button
	var back := UiFont.royal_button("戻る", 22, false)
	back.custom_minimum_size = Vector2(0, 48)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	)
	root.add_child(back)


func _card(who: String) -> Control:
	var playable := SaveStore.is_playable(who)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(300, 0)
	panel.add_theme_stylebox_override("panel", UiFont.style(Color(0.2, 0.16, 0.12, 0.95), UiFont.glass_border(1.0), 2, 16))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	if _is_portrait:
		var picture := _portrait_picture(who)
		picture.custom_minimum_size = Vector2(0, 200)
		picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(picture)
	else:
		var picture := TextureRect.new()
		picture.texture = _portrait(who)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size = Vector2(0, 150)
		picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
		picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(picture)
		_pictures[who] = picture

	_add_card_text(col, who)
	_add_card_special(col, who)

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(actions)

	_add_card_actions(actions, who)
	return panel


func _add_card_special(target: Control, who: String) -> void:
	var caption := UiFont.label("必殺技", 16, UiFont.BRASS)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(caption)
	var quote := UiFont.label("「%s」" % str(SPECIAL_NAMES[who]), 18, UiFont.GOLD)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(quote)


func _portrait_picture(who: String) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = _portrait(who)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(140, 140)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pictures[who] = picture
	return picture


func _add_card_text(target: Control, who: String) -> void:
	var name := UiFont.label(who, 28, UiFont.PAPER)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target.add_child(name)
	var stats: Dictionary = Balance.CHARACTERS[who]
	var numbers := UiFont.label("体力 %d    移動 %d    攻撃 %d" % [int(stats.max_hp), int(stats.speed), int(stats.attack)], 16, UiFont.CREAM)
	numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target.add_child(numbers)
	var blurb := UiFont.label(str(BLURB[who]), 15, UiFont.BRASS)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target.add_child(blurb)


func _add_card_actions(target: Control, who: String) -> void:
	if SaveStore.is_playable(who):
		var wear := _costume_button()
		wear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wear.custom_minimum_size = Vector2(0, 48)
		wear.pressed.connect(func() -> void: _open_closet(who))
		target.add_child(wear)
		var go := UiFont.button("出撃する", 22)
		go.custom_minimum_size = Vector2(0, 56)
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		go.pressed.connect(func() -> void:
			SaveStore.set_selected(who)
			get_tree().change_scene_to_file("res://scenes/battle.tscn")
		)
		target.add_child(go)
	else:
		var locked := UiFont.label("封印  かけら %d / 5" % SaveStore.fragments_of(who), 18, UiFont.EMBER)
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		target.add_child(locked)
		var go := UiFont.button("かけらを集める", 20)
		go.custom_minimum_size = Vector2(0, 56)
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		go.pressed.connect(func() -> void:
			pass
		)
		target.add_child(go)


func _costume_button() -> Button:
	var node := Button.new()
	node.custom_minimum_size = Vector2(48, 48)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		node.add_theme_stylebox_override(state, style.duplicate())

	var icon := CostumeIcon.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(icon)
	return node


func _portrait(who: String) -> Texture2D:
	if not SaveStore.is_playable(who):
		return UiFont.cropped(LOCK_ART)
	return UiFont.cropped(Balance.pose_path(who, "idle", SaveStore.costume_of(who) == "制服"))


func _refresh_picture(who: String) -> void:
	if _pictures.has(who):
		(_pictures[who] as TextureRect).texture = _portrait(who)


func _build_closet() -> void:
	_closet = Control.new()
	_closet.visible = false
	_closet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_closet.anchors_preset = Control.PRESET_FULL_RECT
	add_child(_closet)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.anchors_preset = Control.PRESET_FULL_RECT
	_closet.add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -180
	panel.offset_top = -200
	panel.offset_right = 180
	panel.offset_bottom = 200
	panel.add_theme_stylebox_override("panel", UiFont.style(UiFont.CARD, UiFont.BRASS, 2, 16))
	_closet.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	var heading := UiFont.label("衣装選択", 30, UiFont.PAPER)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)

	_closet_name = UiFont.label("", 20, UiFont.BRASS)
	_closet_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_closet_name)

	_closet_list = VBoxContainer.new()
	_closet_list.add_theme_constant_override("separation", 8)
	_closet_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_closet_list)

	var close := UiFont.button("戻る", 22)
	close.custom_minimum_size = Vector2(0, 56)
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(_close_closet)
	col.add_child(close)


func _open_closet(who: String) -> void:
	_closet_who = who
	_closet_name.text = who
	for child in _closet_list.get_children():
		_closet_list.remove_child(child)
		child.free()
	var wearing := SaveStore.costume_of(who)
	for entry in Balance.LOOKS:
		var look_id := str(entry["id"])
		var owned := SaveStore.owns_look(look_id)
		var caption := str(entry["label"])
		if wearing == look_id:
			caption += "    着用中"
		elif not owned:
			caption += "    未入手"
		var choice := UiFont.button(caption, 20)
		choice.custom_minimum_size = Vector2(0, 56)
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.disabled = not owned
		if wearing == look_id:
			choice.add_theme_stylebox_override("normal", UiFont.style(UiFont.BRASS, UiFont.INK, 2, 12))
			choice.add_theme_stylebox_override("hover", UiFont.style(UiFont.BRASS, UiFont.INK, 2, 12))
		choice.pressed.connect(_choose_look.bind(look_id))
		_closet_list.add_child(choice)
	_closet.visible = true
	_closet.mouse_filter = Control.MOUSE_FILTER_STOP


func _choose_look(look_id: String) -> void:
	if SaveStore.costume_of(_closet_who) == look_id:
		_close_closet()
		return
	if not SaveStore.set_costume(_closet_who, look_id):
		return
	_refresh_picture(_closet_who)
	_close_closet()


func _close_closet() -> void:
	_closet.visible = false
	_closet.mouse_filter = Control.MOUSE_FILTER_IGNORE


class CostumeIcon extends Control:
	func _draw() -> void:
		var s := minf(size.x, size.y)
		var cx := size.x * 0.5
		var cy := size.y * 0.5
		var u := s / 24.0
		var pts := PackedVector2Array([
			Vector2(cx - 7.0 * u, cy - 9.0 * u),
			Vector2(cx - 10.0 * u, cy - 5.0 * u),
			Vector2(cx - 6.0 * u, cy - 1.0 * u),
			Vector2(cx - 4.0 * u, cy - 3.0 * u),
			Vector2(cx - 4.0 * u, cy + 9.0 * u),
			Vector2(cx + 4.0 * u, cy + 9.0 * u),
			Vector2(cx + 4.0 * u, cy - 3.0 * u),
			Vector2(cx + 6.0 * u, cy - 1.0 * u),
			Vector2(cx + 10.0 * u, cy - 5.0 *u),
			Vector2(cx + 7.0 * u, cy - 9.0 * u),
			Vector2(cx + 3.0 * u, cy - 11.0 * u),
			Vector2(cx, cy - 8.0 * u),
			Vector2(cx - 3.0 * u, cy - 11.0 * u),
		])
		draw_colored_polygon(pts, UiFont.BRASS)