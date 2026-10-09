extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")
const SafeArea = preload("res://scripts/safe_area.gd")

const UNIFORM_THUMB := "res://assets/battle/uniform/massa_idle.png"

var _yen: Label
var _speech: Label
var _note: Label
var _goods: VBoxContainer
var _main_margin: MarginContainer
var _is_portrait := false


func _ready() -> void:
	_is_portrait = UiFont.portrait(get_viewport_rect().size)
	get_viewport().size_changed.connect(_on_resized)
	_build()


func _on_resized() -> void:
	var new_portrait = UiFont.portrait(get_viewport_rect().size)
	if new_portrait != _is_portrait:
		_is_portrait = new_portrait
		_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()

	var night := ColorRect.new()
	night.color = UiFont.NIGHT
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
	_main_margin.add_child(root)

	_build_header(root)
	_build_body(root)
	_refresh()


func _build_header(root: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(header)

	var title := UiFont.label("なかむら商店", 34, UiFont.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_yen = UiFont.label("", 24, UiFont.GOLD)
	_yen.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_yen)

	var back := UiFont.royal_button("戻る", 20)
	back.custom_minimum_size = Vector2(140, 54)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(SaveStore.shop_return)
	)
	header.add_child(back)


func _build_body(root: VBoxContainer) -> void:
	if _is_portrait:
		var body := VBoxContainer.new()
		body.add_theme_constant_override("separation", 12)
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		root.add_child(body)

		var stall := _stall_panel()
		stall.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stall.custom_minimum_size = Vector2(0, 280)
		body.add_child(stall)

		var goods := _goods_panel()
		goods.size_flags_vertical = Control.SIZE_EXPAND_FILL
		goods.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(goods)
	else:
		var body := HBoxContainer.new()
		body.add_theme_constant_override("separation", 16)
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		root.add_child(body)

		var stall := _stall_panel()
		stall.custom_minimum_size = Vector2(380, 0)
		stall.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.add_child(stall)

		var goods := _goods_panel()
		goods.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		goods.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.add_child(goods)


func _stall_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiFont.royal_panel(UiFont.ROYAL, UiFont.BRASS, 3, 16))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	_speech = UiFont.label("", 20, UiFont.PAPER)
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", UiFont.style(UiFont.PAPER, UiFont.BRASS, 2, 14))
	var bubble_margin := MarginContainer.new()
	bubble_margin.add_theme_constant_override("margin_left", 14)
	bubble_margin.add_theme_constant_override("margin_right", 14)
	bubble_margin.add_theme_constant_override("margin_top", 8)
	bubble_margin.add_theme_constant_override("margin_bottom", 8)
	bubble.add_child(bubble_margin)
	bubble_margin.add_child(_speech)
	_speech.add_theme_color_override("font_color", UiFont.INK)
	col.add_child(bubble)

	var art := StallArt.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(art)

	return panel


func _goods_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiFont.royal_panel(UiFont.ROYAL, UiFont.BRASS, 3, 16))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	col.add_child(UiFont.label("商品", 26, UiFont.PAPER))

	_note = UiFont.label(" ", 18, UiFont.BRASS)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_note)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_goods = VBoxContainer.new()
	_goods.add_theme_constant_override("separation", 12)
	_goods.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_goods)

	return panel


func _refresh() -> void:
	_yen.text = "所持金  %d イェン" % int(SaveStore.data.yen)
	var locked := SaveStore.locked_friends()
	var owns := bool(SaveStore.data.has_uniform)
	if owns and locked.is_empty():
		_speech.text = "全員加入済み。\n出撃準備完了だ。"
	elif locked.is_empty():
		_speech.text = "仲間は全員加入済み。\n制服はもう持っているな。"
	else:
		_speech.text = "制服と解放かけらを置いてある。\n遠慮なく買っていけ。"

	for child in _goods.get_children():
		_goods.remove_child(child)
		child.free()

	_goods.add_child(_uniform_card(owns))
	if locked.is_empty():
		_goods.add_child(_sold_out_card())
	else:
		for who in locked:
			_goods.add_child(_fragment_card(who))


func _uniform_card(owns: bool) -> Control:
	var thumb := TextureRect.new()
	thumb.texture = UiFont.cropped(UNIFORM_THUMB)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.custom_minimum_size = Vector2(88, 88)
	return _item_card(
		thumb,
		"印旛中学校制服",
		"三人共通の黒い詰襟。金ボタンが縦に五つ。衣装選択から着用できる。",
		"600 イェン" if not owns else "所持中",
		not owns and int(SaveStore.data.yen) >= Balance.UNIFORM_PRICE,
		func() -> void: _buy_uniform()
	)


func _fragment_card(who: String) -> Control:
	var thumb := ShardIcon.new()
	thumb.custom_minimum_size = Vector2(88, 88)
	var left := Balance.FRAGMENTS_TO_UNLOCK - SaveStore.fragments_of(who)
	return _item_card(
		thumb,
		"%sのかけら" % who,
		"五個で%sが仲間に加入する。あと %d 個。戦闘の報酬でも手に入る。" % [who, left],
		"400 イェン",
		int(SaveStore.data.yen) >= Balance.FRAGMENT_PRICE,
		func() -> void: _buy_fragment(who)
	)


func _sold_out_card() -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiFont.royal_panel(Color(0.10, 0.13, 0.26), UiFont.BRASS_DEEP, 2, 12))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	box.add_child(margin)
	var text := UiFont.label("未解放の仲間はいません。\n戦闘後の余剰かけらは、記録時に自動でイェンへ換金されます。", 18, UiFont.CREAM)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(text)
	return box


func _item_card(thumb: Control, name: String, desc: String, price: String, can_buy: bool, on_buy: Callable) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiFont.royal_panel(Color(0.08, 0.11, 0.24), UiFont.BRASS, 2, 12))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)
	row.add_child(thumb)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var name_label := UiFont.label(name, 22, UiFont.GOLD)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(name_label)
	var desc_label := UiFont.label(desc, 16, UiFont.CREAM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_label)
	var buy := UiFont.royal_button(price, 18, true)
	buy.custom_minimum_size = Vector2(150, 56)
	buy.disabled = not can_buy
	buy.pressed.connect(on_buy)
	row.add_child(buy)
	return card


func _buy_uniform() -> void:
	var result := SaveStore.buy_uniform()
	if result == "poor":
		_say("イェンが足りん。", true)
	elif result == "ok":
		_say("制服を買った。立派な詰襟だ。", false)
	_refresh()


func _buy_fragment(who: String) -> void:
	var result := SaveStore.buy_fragment(who)
	if result == "poor":
		_say("イェンが足りん。", true)
	elif result == "unlocked":
		_say("%sが仲間に加わった！" % who, false)
	elif result == "ok":
		_say("%sのかけら %d / %d。" % [who, SaveStore.fragments_of(who), Balance.FRAGMENTS_TO_UNLOCK], false)
	elif result == "none":
		_say("買えるかけらはない。", false)
	_refresh()


func _say(text: String, warn: bool) -> void:
	_note.text = text
	_note.add_theme_color_override("font_color", UiFont.EMBER if warn else UiFont.GOLD)


class ShardIcon extends Control:
	var gold := UiFont.GOLD
	var deep := UiFont.BRASS_DEEP


	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.30
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(0.0, -r),
			c + Vector2(r * 0.82, 0.0),
			c + Vector2(0.0, r),
			c + Vector2(-r * 0.82, 0.0),
		]), gold)
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(0.0, -r),
			c + Vector2(r * 0.82, 0.0),
			c + Vector2(0.0, -r * 0.25),
			c + Vector2(-r * 0.82, 0.0),
		]), Color(gold.r, gold.g, gold.b, 0.55))
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(0.0, -r * 0.45),
			c + Vector2(r * 0.36, 0.0),
			c + Vector2(0.0, r * 0.45),
			c + Vector2(-r * 0.36, 0.0),
		]), deep)


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