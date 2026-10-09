extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")

var _yen: Label
var _friends: Label
var _speech: Label
var _note: Label
var _goods: VBoxContainer


func _ready() -> void:
	UiFont.full_rect(self)
	var night := ColorRect.new()
	night.color = UiFont.NIGHT
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(night)
	add_child(night)

	var stall := StallArt.new()
	stall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(stall, 0.02, 0.16, 0.42, 0.98)
	add_child(stall)

	_speech = UiFont.label("", 24, UiFont.PAPER)
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFont.place(_speech, 0.03, 0.03, 0.41, 0.16)
	add_child(_speech)

	var card := PanelContainer.new()
	UiFont.place(card, 0.44, 0.05, 0.97, 0.95)
	card.add_theme_stylebox_override("panel", UiFont.style(UiFont.CARD, UiFont.BRASS, 2, 16))
	add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	col.add_child(UiFont.label("なかむらショップ", 36, UiFont.PAPER))
	_yen = UiFont.label("", 26, UiFont.BRASS)
	col.add_child(_yen)
	_friends = UiFont.label("", 20, UiFont.CREAM)
	col.add_child(_friends)
	_note = UiFont.label(" ", 22, UiFont.BRASS)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_note)
	_goods = VBoxContainer.new()
	_goods.add_theme_constant_override("separation", 12)
	_goods.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_goods)

	var back := UiFont.button("戻る", 26)
	back.custom_minimum_size = Vector2(0, 64)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(SaveStore.shop_return)
	)
	col.add_child(back)
	_refresh()


func _refresh() -> void:
	_yen.text = "100イェン  %d枚" % int(SaveStore.data.yen)
	_friends.text = "タケッチ  %d/5    ケニー  %d/5" % [SaveStore.fragments_of(Balance.CHAR_TAKETCHI), SaveStore.fragments_of(Balance.CHAR_KENNY)]
	var locked := SaveStore.locked_friends()
	var owns := bool(SaveStore.data.has_uniform)
	if owns and locked.is_empty():
		_speech.text = "そろってる。\n校庭で待ってる"
	elif locked.is_empty():
		_speech.text = "二人は来てる。\n制服はまだある"
	else:
		_speech.text = "制服と、かけらを置いてある"
	for child in _goods.get_children():
		_goods.remove_child(child)
		child.free()
	_goods.add_child(_uniform_block(owns))
	_goods.add_child(_fragment_block(locked))


func _uniform_block(owns: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_ink("印旛中学校の制服", 26))
	if owns:
		box.add_child(_ink("持ってる。クローゼットで着られる", 20))
	else:
		box.add_child(_ink("黒い詰襟。三人とも着られる", 20))
		var buy := UiFont.button("600イェン", 26)
		buy.custom_minimum_size = Vector2(0, 64)
		buy.pressed.connect(_buy_uniform)
		box.add_child(buy)
	return box


func _fragment_block(locked: Array[String]) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_ink("ともだちのかけら", 26))
	if locked.is_empty():
		box.add_child(_ink("棚は空。余りは300イェンになる", 20))
		return box
	box.add_child(_ink("五つで加わる。戦闘のあとにも渡せる", 20))
	if locked.size() == 1:
		var who := str(locked[0])
		var buy := UiFont.button("%s  400イェン" % who, 26)
		buy.custom_minimum_size = Vector2(0, 64)
		buy.pressed.connect(_buy_fragment.bind(who))
		box.add_child(buy)
	else:
		box.add_child(_ink("400イェン。渡す相手を選ぶ", 20))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(_target_button(Balance.CHAR_TAKETCHI))
		row.add_child(_target_button(Balance.CHAR_KENNY))
		box.add_child(row)
	return box


func _target_button(who: String) -> Button:
	var buy := UiFont.button(who, 24)
	buy.custom_minimum_size = Vector2(220, 60)
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.pressed.connect(_buy_fragment.bind(who))
	return buy


func _ink(text: String, size: int) -> Label:
	var node := UiFont.label(text, size, UiFont.PAPER)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node


func _buy_uniform() -> void:
	var result := SaveStore.buy_uniform()
	if result == "poor":
		_say("足りない", true)
	elif result == "ok":
		_say("制服が届いた", false)
	_refresh()


func _buy_fragment(who: String) -> void:
	var result := SaveStore.buy_fragment(who)
	if result == "poor":
		_say("足りない", true)
	elif result == "unlocked":
		_say("%sが来た" % who, false)
	elif result == "ok":
		var target := who
		var locked := SaveStore.locked_friends()
		if locked.size() == 1:
			target = str(locked[0])
		_say("%s  %d/5" % [target, SaveStore.fragments_of(target)], false)
	elif result == "none":
		_say("かけらは無い", false)
	_refresh()


func _say(text: String, warn: bool) -> void:
	_note.text = text
	_note.add_theme_color_override("font_color", UiFont.EMBER if warn else UiFont.BRASS)


class StallArt extends Control:
	var keeper: Texture2D = preload("res://assets/battle/nakamura.png")

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w < 40.0 or h < 40.0 or keeper == null:
			return
		var aspect := float(keeper.get_width()) / float(maxi(keeper.get_height(), 1))
		var kh := h
		var kw := kh * aspect
		if kw > w:
			kw = w
			kh = kw / aspect
		draw_texture_rect(keeper, Rect2((w - kw) * 0.5, h - kh, kw, kh), false)
