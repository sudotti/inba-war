extends Control

const UiFont = preload("res://scripts/ui_font.gd")

var _rows: VBoxContainer


func _ready() -> void:
	UiFont.full_rect(self)
	var background := ColorRect.new()
	background.color = UiFont.NIGHT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(background)
	add_child(background)

	var header := HBoxContainer.new()
	UiFont.place(header, 0.05, 0.035, 0.95, 0.13)
	add_child(header)
	var title := UiFont.label("ランキング", 40, UiFont.PAPER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := UiFont.button("戻る", 20)
	back.custom_minimum_size = Vector2(150, 56)
	back.pressed.connect(_back)
	header.add_child(back)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	UiFont.place(content, 0.06, 0.17, 0.94, 0.93)
	add_child(content)
	content.add_child(UiFont.label("この端末の上位記録", 22, UiFont.BRASS))
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 16)
	content.add_child(heading)
	_add_heading(heading, "順位", 90)
	_add_heading(heading, "名前", 250)
	_add_heading(heading, "キャラ", 220)
	_add_heading(heading, "スコア", 200)
	_add_heading(heading, "記録日", 220)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 3)
	_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_rows)
	_refresh()


func _add_heading(row: HBoxContainer, text: String, width: float) -> void:
	var label := UiFont.label(text, 18, UiFont.BRASS)
	label.custom_minimum_size.x = width
	row.add_child(label)


func _refresh() -> void:
	var entries: Array = SaveStore.data.local_scores
	if entries.is_empty():
		_rows.add_child(UiFont.label("まだ記録がない", 30, UiFont.PAPER))
		return
	for index in entries.size():
		var entry: Dictionary = entries[index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		row.custom_minimum_size.y = 54
		var color := UiFont.YELLOW if index == 0 else UiFont.PAPER
		_add_cell(row, "%02d" % (index + 1), 90, color)
		_add_cell(row, str(entry.get("name", "ななし")), 250, color)
		_add_cell(row, str(entry.get("character", "")), 220, UiFont.CREAM)
		_add_cell(row, "%d" % int(entry.get("score", 0)), 200, color)
		_add_cell(row, _short_date(str(entry.get("date", ""))), 220, UiFont.CREAM)
		_rows.add_child(row)
		var rule := ColorRect.new()
		rule.color = Color(1.0, 0.88, 0.66, 0.16)
		rule.custom_minimum_size.y = 1
		_rows.add_child(rule)


func _add_cell(row: HBoxContainer, text: String, width: float, color: Color) -> void:
	var label := UiFont.label(text, 22, color)
	label.custom_minimum_size.x = width
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)


func _short_date(value: String) -> String:
	return value.replace("T", " ").substr(0, 16) if value.length() >= 16 else value


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")