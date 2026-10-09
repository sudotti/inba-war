extends Control

const UiFont = preload("res://scripts/ui_font.gd")

var _rows: VBoxContainer
var _col_rank := 90.0
var _col_name := 250.0
var _col_char := 220.0
var _col_score := 200.0
var _col_date := 220.0


func _ready() -> void:
	var view := get_viewport_rect().size
	var total := view.x * 0.88
	_col_rank = total * 0.08
	_col_name = total * 0.30
	_col_char = total * 0.20
	_col_score = total * 0.18
	_col_date = total * 0.24
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
	_add_heading(heading, "順位", _col_rank)
	_add_heading(heading, "名前", _col_name)
	_add_heading(heading, "キャラ", _col_char)
	_add_heading(heading, "スコア", _col_score)
	_add_heading(heading, "記録日", _col_date)
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
		_add_cell(row, "%02d" % (index + 1), _col_rank, color)
		_add_cell(row, str(entry.get("name", "ななし")), _col_name, color)
		_add_cell(row, str(entry.get("character", "")), _col_char, UiFont.CREAM)
		_add_cell(row, "%d" % int(entry.get("score", 0)), _col_score, color)
		_add_cell(row, _short_date(str(entry.get("date", ""))), _col_date, UiFont.CREAM)
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