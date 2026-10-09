extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")
const LOCK_ART := "res://assets/ui/lock.png"

var _entries: VBoxContainer
var _portrait: TextureRect
var _name: Label
var _role: Label
var _stats: Label
var _description: Label
var _record: Label
var _selected := ""


func _ready() -> void:
	UiFont.full_rect(self)
	var background := ColorRect.new()
	background.color = UiFont.NIGHT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(background)
	add_child(background)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	UiFont.place(header, 0.04, 0.035, 0.96, 0.13)
	add_child(header)
	var title := UiFont.label("敵図鑑", 40, UiFont.PAPER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var count: int = SaveStore.data.enemy_seen.size()
	header.add_child(UiFont.label("遭遇 %d / %d" % [count, Balance.ENEMY_KINDS.size()], 20, UiFont.BRASS))
	var back := UiFont.button("戻る", 20)
	back.custom_minimum_size = Vector2(150, 56)
	back.pressed.connect(_back)
	header.add_child(back)

	var portrait := UiFont.portrait(get_viewport_rect().size)
	var body := BoxContainer.new()
	if portrait:
		body = VBoxContainer.new()
		body.add_theme_constant_override("separation", 12)
	else:
		body = HBoxContainer.new()
		body.add_theme_constant_override("separation", 18)
	UiFont.place(body, 0.04, 0.16, 0.96, 0.94)
	add_child(body)
	var list := PanelContainer.new()
	if portrait:
		list.custom_minimum_size = Vector2(0, 250)
	else:
		list.custom_minimum_size = Vector2(290, 0)
	list.add_theme_stylebox_override("panel", UiFont.style(UiFont.CARD, UiFont.BRASS_DEEP, 2, 4))
	body.add_child(list)
	var list_margin := MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 12)
	list_margin.add_theme_constant_override("margin_right", 12)
	list_margin.add_theme_constant_override("margin_top", 14)
	list_margin.add_theme_constant_override("margin_bottom", 14)
	list.add_child(list_margin)
	var list_col := VBoxContainer.new()
	list_col.add_theme_constant_override("separation", 8)
	list_margin.add_child(list_col)
	list_col.add_child(UiFont.label("遭遇した敵", 22, UiFont.BRASS))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_col.add_child(scroll)
	_entries = VBoxContainer.new()
	_entries.add_theme_constant_override("separation", 6)
	_entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_entries)

	var detail := BoxContainer.new()
	if portrait:
		detail = VBoxContainer.new()
		detail.alignment = BoxContainer.ALIGNMENT_CENTER
		detail.add_theme_constant_override("separation", 10)
	else:
		detail = HBoxContainer.new()
		detail.add_theme_constant_override("separation", 26)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not portrait:
		detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail)
	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(360 if not portrait else 0, 0 if not portrait else 300)
	portrait_panel.add_theme_stylebox_override("panel", UiFont.style(Color("201b18"), UiFont.BRASS_DEEP, 2, 4))
	detail.add_child(portrait_panel)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(340, 360 if not portrait else 280)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait_panel.add_child(_portrait)

	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 12)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_child(copy)
	_name = UiFont.label("", 38, UiFont.PAPER)
	copy.add_child(_name)
	_role = UiFont.label("", 20, UiFont.BRASS)
	copy.add_child(_role)
	_stats = UiFont.label("", 22, UiFont.CREAM)
	copy.add_child(_stats)
	_description = UiFont.label("", 22, UiFont.PAPER)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(_description)
	_record = UiFont.label("", 20, UiFont.YELLOW)
	copy.add_child(_record)

	_selected = Balance.ENEMY_KINDS[0]
	_refresh()


func _refresh() -> void:
	for child in _entries.get_children():
		_entries.remove_child(child)
		child.free()
	for kind in Balance.ENEMY_KINDS:
		var seen: bool = SaveStore.data.enemy_seen.has(kind)
		var caption := str(Balance.ENEMY_NAME[kind]) if seen else "？？？？？"
		var kills := int(SaveStore.data.enemy_kills.get(kind, 0))
		var button := UiFont.button("%s   %02d" % [caption, kills], 18)
		button.custom_minimum_size = Vector2(0, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("normal", UiFont.style(UiFont.BRASS if kind == _selected else UiFont.CARD, UiFont.BRASS_DEEP, 1, 4))
		button.add_theme_color_override("font_color", UiFont.INK if kind == _selected else UiFont.PAPER)
		button.pressed.connect(_select.bind(kind))
		_entries.add_child(button)
	_show_entry(_selected)


func _select(kind: String) -> void:
	_selected = kind
	_refresh()


func _show_entry(kind: String) -> void:
	var seen: bool = SaveStore.data.enemy_seen.has(kind)
	var kills := int(SaveStore.data.enemy_kills.get(kind, 0))
	if not seen:
		_portrait.texture = UiFont.cropped(LOCK_ART)
		_name.text = "未遭遇"
		_role.text = "UNKNOWN"
		_stats.text = ""
		_description.text = "戦場で出会うと記録される。"
		_record.text = "撃破  ―"
		return
	_portrait.texture = _portrait_texture(kind)
	_name.text = str(Balance.ENEMY_NAME[kind])
	_role.text = "乱入ボス" if Balance.BOSS_KINDS.has(kind) else "校庭の敵"
	var stats: Dictionary = Balance.ENEMIES[kind]
	_stats.text = "HP %d   速 %d   接触 %d" % [int(stats.hp), int(stats.speed), int(stats.touch)]
	_description.text = str(Balance.ENEMY_DESCRIPTION[kind])
	_record.text = "撃破  %d" % kills


func _portrait_path(kind: String) -> String:
	match kind:
		Balance.KIND_NORMAL:
			return "res://assets/battle/enemy_normal.png"
		Balance.KIND_FAST:
			return "res://assets/battle/enemy_fast.png"
		Balance.KIND_TANK:
			return "res://assets/battle/enemy_tank.png"
		Balance.KIND_NIMOTON:
			return "res://assets/battle/boss_nimoton.png"
		_:
			return "res://assets/battle/boss_kassen.png"


func _portrait_texture(kind: String) -> Texture2D:
	if kind == Balance.KIND_KASSEN:
		var atlas := AtlasTexture.new()
		atlas.atlas = load(_portrait_path(kind))
		atlas.region = Rect2(286.0, 190.0, 452.0, 640.0)
		return atlas
	if kind == Balance.KIND_NIMOTON:
		return UiFont.cropped(_portrait_path(kind))
	return load(_portrait_path(kind))


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")