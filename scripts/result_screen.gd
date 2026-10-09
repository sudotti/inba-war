extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")

var _fragment: Label
var _choice: HBoxContainer
var _back: Button
var _shop: Button
var _yen: Label
var _reward := 0


func _idle_path(who: String) -> String:
	return Balance.pose_path(who, "idle", SaveStore.costume_of(who) == "制服")


func _ready() -> void:
	UiFont.full_rect(self)
	var night := ColorRect.new()
	night.color = UiFont.NIGHT
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(night)
	add_child(night)

	var result_peek: Dictionary = SaveStore.last_result
	if not result_peek.is_empty():
		var who_now := str(result_peek.get("character", Balance.CHAR_MASSA))
		var stand := TextureRect.new()
		stand.texture = load(_idle_path(who_now))
		stand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stand.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiFont.place(stand, 0.02, 0.16, 0.18, 0.86)
		add_child(stand)

	var card := PanelContainer.new()
	UiFont.place(card, 0.20, 0.06, 0.84, 0.94)
	card.add_theme_stylebox_override("panel", UiFont.style(UiFont.CARD, UiFont.BRASS, 2, 16))
	add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)

	var result: Dictionary = SaveStore.last_result
	col.add_child(UiFont.label("結果", 26, UiFont.BRASS))
	if result.is_empty():
		col.add_child(UiFont.label("記録がない", 36, UiFont.PAPER))
	else:
		var outcome := "3分生き残った" if str(result.get("outcome", "")) == "clear" else "力尽きた"
		col.add_child(UiFont.label(outcome, 30, UiFont.PAPER))
		var who := str(result.get("character", Balance.CHAR_MASSA))
		col.add_child(UiFont.label(who, 22, UiFont.CREAM))
		col.add_child(UiFont.label("スコア  %d" % int(result.get("score", 0)), 52, UiFont.PAPER))
		if bool(result.get("best_updated", false)):
			col.add_child(UiFont.label("自己ベストを更新した", 26, UiFont.PINK))
		else:
			var best := int(result.get("best_score", 0))
			var when := str(result.get("best_datetime", ""))
			var line := "自己ベスト  まだない" if when == "" else "自己ベスト  %d" % best
			col.add_child(UiFont.label(line, 24, UiFont.PAPER))
		col.add_child(UiFont.label("獲得コイン  %d枚" % int(result.get("coins", 0)), 26, UiFont.YELLOW))
		_yen = UiFont.label("", 22, UiFont.CREAM)
		col.add_child(_yen)
		col.add_child(UiFont.label("撃破  %d    通常 %d / 高速 %d / 耐久 %d" % [
			int(result.get("kills", 0)),
			int(result.get("kills_normal", 0)),
			int(result.get("kills_fast", 0)),
			int(result.get("kills_tank", 0)),
		], 22, UiFont.PAPER))

	_fragment = UiFont.label("", 24, UiFont.YELLOW)
	_fragment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_fragment)
	_choice = HBoxContainer.new()
	_choice.add_theme_constant_override("separation", 12)
	_choice.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_choice)

	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(gap)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 16)
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(nav)
	_back = UiFont.button("タイトルへ", 26)
	_back.custom_minimum_size = Vector2(250, 64)
	_back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	)
	nav.add_child(_back)
	_shop = UiFont.button("なかむらショップ", 24)
	_shop.custom_minimum_size = Vector2(280, 64)
	_shop.pressed.connect(func() -> void:
		SaveStore.shop_return = "res://scenes/result.tscn"
		get_tree().change_scene_to_file("res://scenes/shop.tscn")
	)
	nav.add_child(_shop)
	_sync_yen()
	_resolve()


func _resolve() -> void:
	var result: Dictionary = SaveStore.last_result
	if bool(result.get("fragment_done", false)):
		_fragment.text = str(result.get("fragment_note", ""))
		_sync_yen()
		return
	if result.is_empty():
		_fragment.text = ""
		return
	_reward = SaveStore.reward_fragments(str(result.get("outcome", "")), int(result.get("kills", 0)))
	var locked := SaveStore.locked_friends()
	if _reward <= 0:
		_finish("今回はかけら無し")
	elif locked.is_empty():
		var yen := _reward * Balance.FRAGMENT_EXCHANGE
		SaveStore.add_yen(yen)
		_finish("余ったかけらを %dイェンにした" % yen)
	elif locked.size() == 1:
		var who := str(locked[0])
		var info := SaveStore.grant_fragments(who, _reward)
		_finish(_grant_line(who, info))
	else:
		_fragment.text = "かけら%dつ。誰に渡す" % _reward
		_set_nav(false)
		_choice.add_child(_pick_button(Balance.CHAR_TAKETCHI))
		_choice.add_child(_pick_button(Balance.CHAR_KENNY))


func _pick_button(who: String) -> Button:
	var button := UiFont.button("%sへ" % who, 26)
	button.custom_minimum_size = Vector2(220, 60)
	button.pressed.connect(func() -> void: _give(who))
	return button


func _give(who: String) -> void:
	if bool(SaveStore.last_result.get("fragment_done", false)):
		return
	var info := SaveStore.grant_fragments(who, _reward)
	for child in _choice.get_children():
		_choice.remove_child(child)
		child.free()
	_set_nav(true)
	_finish(_grant_line(who, info))


func _grant_line(who: String, info: Dictionary) -> String:
	var line := "%sのかけら +%d（%d/5）" % [who, int(info.applied), SaveStore.fragments_of(who)]
	if bool(info.unlocked):
		line += "  来た"
	if int(info.yen) > 0:
		line += "  余り %dイェン" % int(info.yen)
	return line


func _finish(note: String) -> void:
	_fragment.text = note
	SaveStore.last_result["fragment_done"] = true
	SaveStore.last_result["fragment_note"] = note
	_sync_yen()


func _set_nav(enabled: bool) -> void:
	_back.disabled = not enabled
	_shop.disabled = not enabled
	var fade := UiFont.style(Color("c8c2b4"), UiFont.INK, 4, 16)
	if not enabled:
		_back.add_theme_stylebox_override("disabled", fade)
		_shop.add_theme_stylebox_override("disabled", fade)
		_back.add_theme_color_override("font_disabled_color", Color("6e6a62"))
		_shop.add_theme_color_override("font_disabled_color", Color("6e6a62"))


func _sync_yen() -> void:
	if _yen != null:
		_yen.text = "所持  100イェン %d枚" % int(SaveStore.data.yen)
