extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")

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


func _ready() -> void:
	_is_portrait = UiFont.portrait(get_viewport_rect().size)
	UiFont.full_rect(self)
	var night := ColorRect.new()
	night.color = Color(0.05, 0.04, 0.08, 1.0)
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(night)
	add_child(night)

	var title := UiFont.label("キャラクター選択", 36, UiFont.PAPER)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(title, 0.04, 0.03, 0.96, 0.12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	if _is_portrait:
		var scroll := ScrollContainer.new()
		scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		UiFont.place(scroll, 0.04, 0.14, 0.96, 0.84)
		add_child(scroll)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 10)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.custom_minimum_size = Vector2(0, 1)
		scroll.add_child(content)
		for who in ORDER:
			var card = _card(who)
			content.add_child(card)
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 100)
		content.add_child(spacer)
	else:
		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiFont.place(center, 0.04, 0.14, 0.96, 0.84)
		add_child(center)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		center.add_child(row)
		for who in ORDER:
			row.add_child(_card(who))

	var back := UiFont.royal_button("戻る", 24, false)
	back.custom_minimum_size = Vector2(240, 64)
	UiFont.place(back, 0.04, 0.86, 0.44 if _is_portrait else 0.28, 0.97)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	)
	add_child(back)
	_build_closet()





func _card(who: String) -> Control:
	var playable := SaveStore.is_playable(who)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(300, 0)
	var border := UiFont.BRASS if who == SaveStore.playable_character() else Color("3a3228")
	panel.add_theme_stylebox_override("panel", UiFont.style(Color(0.2, 0.16, 0.12, 0.95), UiFont.glass_border(1.0), 2, 16))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12 if not _is_portrait else 8)
	margin.add_theme_constant_override("margin_bottom", 12 if not _is_portrait else 8)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	margin.add_child(col)
	if _is_portrait:
		var picture := _portrait_picture(who)
		picture.custom_minimum_size = Vector2(0, 190)
		picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(picture)
		_add_card_text(col, who)
		_add_card_special(col, who)
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(actions)
		_add_card_actions(actions, who)
		return panel
	var picture := TextureRect.new()
	picture.texture = _portrait(who)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(0, 150)
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(picture)
	_pictures[who] = picture
	_add_card_text(col, who)
	_add_card_special(col, who)
	_add_card_actions(col, who)
	return panel


func _add_card_special(target: Control, who: String) -> void:
	var caption := UiFont.label("必殺技", 15 if _is_portrait else 16, UiFont.BRASS)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(caption)
	var quote := UiFont.label("「%s」" % str(SPECIAL_NAMES[who]), 17 if _is_portrait else 20, UiFont.GOLD)
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
	var name := UiFont.label(who, 30 if not _is_portrait else 26, UiFont.PAPER)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target.add_child(name)
	var stats: Dictionary = Balance.CHARACTERS[who]
	var numbers := UiFont.label("体力 %d    移動 %d    攻撃 %d" % [int(stats.max_hp), int(stats.speed), int(stats.attack)], 18 if not _is_portrait else 16, UiFont.CREAM)
	numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target.add_child(numbers)
	var blurb := UiFont.label(str(BLURB[who]), 16 if not _is_portrait else 15, UiFont.BRASS)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target.add_child(blurb)


func _add_card_actions(target: Control, who: String) -> void:
	if SaveStore.is_playable(who):
		var wear := _costume_button()
		wear.pressed.connect(func() -> void: _open_closet(who))
		target.add_child(wear)
		var go := UiFont.button("出撃する", 24)
		go.custom_minimum_size = Vector2(0, 56)
		go.pressed.connect(func() -> void:
			SaveStore.set_selected(who)
			get_tree().change_scene_to_file("res://scenes/battle.tscn")
		)
		target.add_child(go)
	else:
		var locked := UiFont.label("封印  かけら %d / 5" % SaveStore.fragments_of(who), 20, UiFont.EMBER)
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		target.add_child(locked)
		var go := UiFont.button("かけらを集める", 22)
		go.custom_minimum_size = Vector2(0, 56)
		go.pressed.connect(func() -> void:
			pass
		)
		target.add_child(go)


func _costume_button() -> Button:
	var node := Button.new()
	node.custom_minimum_size = Vector2(48, 48)
	
	# Remove all style padding for perfect centering
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
	UiFont.full_rect(_closet)
	add_child(_closet)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	UiFont.full_rect(dim)
	_closet.add_child(dim)
	var panel := PanelContainer.new()
	UiFont.place(panel, 0.08 if _is_portrait else 0.32, 0.08 if _is_portrait else 0.16, 0.92 if _is_portrait else 0.68, 0.92 if _is_portrait else 0.84)
	panel.add_theme_stylebox_override("panel", UiFont.style(UiFont.CARD, UiFont.BRASS, 2, 16))
	_closet.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)
	var heading := UiFont.label("衣装選択", 32, UiFont.PAPER)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)
	_closet_name = UiFont.label("", 22, UiFont.BRASS)
	_closet_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_closet_name)
	_closet_list = VBoxContainer.new()
	_closet_list.add_theme_constant_override("separation", 8)
	_closet_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_closet_list)
	var close := UiFont.button("戻る", 24)
	close.custom_minimum_size = Vector2(0, 60)
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
		var choice := UiFont.button(caption, 22)
		choice.custom_minimum_size = Vector2(0, 60)
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
			Vector2(cx + 10.0 * u, cy - 5.0 * u),
			Vector2(cx + 7.0 * u, cy - 9.0 * u),
			Vector2(cx + 3.0 * u, cy - 11.0 * u),
			Vector2(cx, cy - 8.0 * u),
			Vector2(cx - 3.0 * u, cy - 11.0 * u),
		])
		draw_colored_polygon(pts, UiFont.BRASS)
