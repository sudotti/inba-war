extends Control

const UiFont = preload("res://scripts/ui_font.gd")

var _rows: VBoxContainer
var _note: Label
var _main_margin: MarginContainer


func _ready() -> void:
	_build()
	if not SaveStore.board_updated.is_connected(_on_board):
		SaveStore.board_updated.connect(_on_board)
	_note.text = "読み込み中"
	SaveStore.flush_pending()
	SaveStore.fetch_board()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	UiFont.full_rect(self)

	var background := ColorRect.new()
	background.color = UiFont.NIGHT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	UiFont.full_rect(background)

	_main_margin = MarginContainer.new()
	_main_margin.add_theme_constant_override("margin_left", 24)
	_main_margin.add_theme_constant_override("margin_right", 24)
	add_child(_main_margin)
	UiFont.full_rect(_main_margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 12)
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_margin.add_child(root)

	# Header
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	var title := UiFont.label("ランキング", 36, UiFont.PAPER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)

	var back := UiFont.button("戻る", 20)
	back.custom_minimum_size = Vector2(140, 54)
	back.pressed.connect(_back)
	header.add_child(back)

	# Content
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(content)

	_note = UiFont.label("みんなの自己ベスト", 22, UiFont.BRASS)
	content.add_child(_note)

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	heading.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(heading)

	# Column widths as ratios - will be calculated in _refresh
	_add_heading(heading, "順位")
	_add_heading(heading, "名前")
	_add_heading(heading, "キャラ")
	_add_heading(heading, "スコア")
	_add_heading(heading, "記録日")

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 3)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)


func _add_heading(row: HBoxContainer, text: String) -> void:
	var label := UiFont.label(text, 18, UiFont.BRASS)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(label)


func _on_board(ok: bool, entries: Array) -> void:
	if not is_inside_tree():
		return
	if not ok:
		_note.text = "つながらない。次に開くと再送する"
		_show([])
		if _rows.get_child_count() > 0:
			_rows.get_child(0).text = "通信できるまで空欄"
		return
	_note.text = "自己ベスト  %d人" % entries.size()
	_show(entries)


func _show(entries: Array) -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.free()

	if entries.is_empty():
		_rows.add_child(UiFont.label("まだ記録がない", 30, UiFont.PAPER))
		return

	var mine := str(SaveStore.data.player_id)
	for index in entries.size():
		var entry: Dictionary = entries[index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.custom_minimum_size.y = 54
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var mine_row := str(entry.get("player_id", "")) == mine
		var color := UiFont.BRASS if mine_row else (UiFont.YELLOW if index == 0 else UiFont.PAPER)
		var rank := int(entry.get("rank", index + 1))
		_add_cell(row, "%02d" % rank, color)
		_add_cell(row, str(entry.get("display_name", entry.get("name", "ななし"))), color)
		_add_cell(row, str(entry.get("character", "")), UiFont.CREAM)
		_add_cell(row, "%d" % int(entry.get("score", 0)), color)
		_add_cell(row, _short_date(str(entry.get("achieved_at", entry.get("date", "")))), UiFont.CREAM)

		_rows.add_child(row)

		var rule := ColorRect.new()
		rule.color = Color(1.0, 0.88, 0.66, 0.16)
		rule.custom_minimum_size.y = 1
		rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_rows.add_child(rule)


func _add_cell(row: HBoxContainer, text: String, color: Color) -> void:
	var label := UiFont.label(text, 20, color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)


func _short_date(value: String) -> String:
	return value.replace("T", " ").substr(0, 16) if value.length() >= 16 else value


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")