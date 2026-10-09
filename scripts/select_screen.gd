extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")

const ORDER: Array[String] = [Balance.CHAR_KENNY, Balance.CHAR_TAKETCHI, Balance.CHAR_MASSA]
const LOCK_ART := "res://assets/ui/lock.png"
const BLURB := {
	Balance.CHAR_MASSA: "鉄パイプ。振りが広い",
	Balance.CHAR_TAKETCHI: "拳。近いところを重く",
	Balance.CHAR_KENNY: "キック。足が速い",
}

var _pictures: Dictionary = {}
var _closet: Control
var _closet_name: Label
var _closet_list: VBoxContainer
var _closet_who := ""


func _ready() -> void:
	UiFont.full_rect(self)
	var night := ColorRect.new()
	night.color = UiFont.NIGHT
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(night)
	add_child(night)

	var title := UiFont.label("出撃", 40, UiFont.PAPER)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(title, 0.04, 0.03, 0.40, 0.12)
	add_child(title)
	var yen := UiFont.label("100イェン  %d枚" % int(SaveStore.data.yen), 26, UiFont.BRASS)
	yen.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	yen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(yen, 0.50, 0.03, 0.96, 0.12)
	add_child(yen)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	UiFont.place(row, 0.04, 0.14, 0.96, 0.84)
	add_child(row)
	for who in ORDER:
		row.add_child(_card(who))

	var back := UiFont.button("タイトルへ", 24)
	back.custom_minimum_size = Vector2(240, 64)
	UiFont.place(back, 0.04, 0.86, 0.28, 0.97)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	)
	add_child(back)
	var shop := UiFont.button("なかむらショップ", 24)
	shop.custom_minimum_size = Vector2(280, 64)
	UiFont.place(shop, 0.68, 0.86, 0.96, 0.97)
	shop.pressed.connect(_open_shop)
	add_child(shop)
	_build_closet()


func _open_shop() -> void:
	SaveStore.shop_return = "res://scenes/select.tscn"
	get_tree().change_scene_to_file("res://scenes/shop.tscn")


func _card(who: String) -> Control:
	var playable := SaveStore.is_playable(who)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border := UiFont.BRASS if who == SaveStore.playable_character() else Color("3a3228")
	panel.add_theme_stylebox_override("panel", UiFont.style(UiFont.CARD, border, 2, 16))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	margin.add_child(col)

	var picture := TextureRect.new()
	picture.texture = _portrait(who)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(0, 150)
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(picture)
	_pictures[who] = picture

	var name := UiFont.label(who, 30, UiFont.PAPER)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name)
	var stats: Dictionary = Balance.CHARACTERS[who]
	var numbers := UiFont.label("HP %d    速さ %d    攻撃 %d" % [int(stats.max_hp), int(stats.speed), int(stats.attack)], 16, UiFont.CREAM)
	numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(numbers)
	var blurb := UiFont.label(str(BLURB[who]), 16, UiFont.BRASS)
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(blurb)

	if playable:
		var wear := UiFont.button("クローゼット", 20)
		wear.custom_minimum_size = Vector2(0, 48)
		wear.pressed.connect(func() -> void: _open_closet(who))
		col.add_child(wear)
		var go := UiFont.button("出る", 24)
		go.custom_minimum_size = Vector2(0, 56)
		go.pressed.connect(func() -> void:
			SaveStore.set_selected(who)
			get_tree().change_scene_to_file("res://scenes/battle.tscn")
		)
		col.add_child(go)
	else:
		var locked := UiFont.label("かけら  %d/5" % SaveStore.fragments_of(who), 20, UiFont.EMBER)
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(locked)
		var go := UiFont.button("ショップへ", 22)
		go.custom_minimum_size = Vector2(0, 56)
		go.pressed.connect(_open_shop)
		col.add_child(go)
	return panel


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
	UiFont.place(panel, 0.32, 0.16, 0.68, 0.84)
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
	var heading := UiFont.label("クローゼット", 32, UiFont.PAPER)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)
	_closet_name = UiFont.label("", 22, UiFont.BRASS)
	_closet_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_closet_name)
	_closet_list = VBoxContainer.new()
	_closet_list.add_theme_constant_override("separation", 8)
	_closet_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_closet_list)
	var close := UiFont.button("閉じる", 24)
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
			caption += "    着てる"
		elif not owned:
			caption += "    未所持"
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
