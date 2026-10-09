extends Control

const UiFont = preload("res://scripts/ui_font.gd")
const SafeArea = preload("res://scripts/safe_area.gd")

var _rows: VBoxContainer
var _main_margin: MarginContainer


func _ready() -> void:
	get_viewport().size_changed.connect(_on_resized)
	_build()
	_refresh()


func _on_resized() -> void:
	_build()
	_refresh()


func _build() -> void:
	for child in get_children():
		child.queue_free()

	var background := ColorRect.new()
	background.color = UiFont.NIGHT
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_main_margin = MarginContainer.new()
	_main_margin.anchors_preset = Control.PRESET_FULL_RECT
	SafeArea.apply_safe_padding(_main_margin, get_viewport())
	add_child(_main_margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 12)
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

	content.add_child(UiFont.label("この端末の上位記録", 22, UiFont.BRASS))

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

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 3)
	_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_rows)


func _add_heading(row: HBoxContainer, text: String) -> void:
	var label := UiFont.label(text, 18, UiFont.BRASS)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(label)


func _refresh() -> void:
	var entries: Array = SaveStore.data.local_scores
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.free()

	if entries.is_empty():
		_rows.add_child(UiFont.label("まだ記録がない", 30, UiFont.PAPER))
		return

	for index in entries.size():
		var entry: Dictionary = entries[index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.custom_minimum_size.y = 54
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var color := UiFont.YELLOW if index == 0 else UiFont.PAPER
		_add_cell(row, "%02d" % (index + 1), color)
		_add_cell(row, str(entry.get("name", "ななし")), color)
		_add_cell(row, str(entry.get("character", "")), UiFont.CREAM)
		_add_cell(row, "%d" % int(entry.get("score", 0)), color)
		_add_cell(row, _short_date(str(entry.get("date", ""))), UiFont.CREAM)

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