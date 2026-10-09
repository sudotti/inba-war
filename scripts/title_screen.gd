extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")

const POSTER := "res://assets/ui/title_trio.png"

var _lights: Array[Dictionary] = []
var _t := 0.0
var _portrait := false


func _ready() -> void:
	get_viewport().size_changed.connect(_on_resized)
	_portrait = UiFont.portrait(get_viewport_rect().size)
	_build()


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _on_resized() -> void:
	var portrait := UiFont.portrait(get_viewport_rect().size)
	if portrait != _portrait:
		_portrait = portrait
		_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	_seed_lights()
	_build_background()
	_build_fx()
	if _portrait:
		_build_title_portrait()
		_build_poster_portrait()
		_build_stats(0.575, 0.645)
		_build_menu_portrait()
	else:
		_build_poster_landscape()
		_build_title_landscape()
		_build_stats(0.245, 0.305)
		_build_menu_landscape()


func _seed_lights() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 46:
		_lights.append({
			"x": rng.randf(),
			"y": rng.randf(),
			"r": rng.randf_range(2.0, 7.0),
			"hz": rng.randf_range(0.4, 1.6),
			"phase": rng.randf_range(0.0, TAU),
		})


func _build_background() -> void:
	var grad := Gradient.new()
	grad.add_point(0.0, UiFont.ROYAL_DEEP)
	grad.add_point(0.45, UiFont.ROYAL)
	grad.add_point(1.0, UiFont.ROYAL_DEEP)
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	tex.width = 512
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(bg)
	add_child(bg)


func _build_fx() -> void:
	var fx := Sparkles.new()
	fx.lights = _lights
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(fx)
	add_child(fx)


func _build_poster_landscape() -> void:
	var poster := TextureRect.new()
	poster.texture = load(POSTER)
	poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(poster)
	add_child(poster)
	var scrim := TextureRect.new()
	scrim.texture = _scrim_texture()
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(scrim)
	add_child(scrim)


func _build_poster_portrait() -> void:
	var panel := GoldFrame.new()
	panel.fill = Color(0.04, 0.06, 0.18, 0.6)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(panel, 0.05, 0.17, 0.95, 0.55)
	add_child(panel)
	var poster := TextureRect.new()
	poster.texture = load(POSTER)
	poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(poster, 0.03, 0.03, 0.97, 0.97)
	panel.add_child(poster)


func _scrim_texture() -> GradientTexture1D:
	var grad := Gradient.new()
	grad.add_point(0.0, Color(0.03, 0.05, 0.16, 0.94))
	grad.add_point(0.22, Color(0.03, 0.05, 0.16, 0.62))
	grad.add_point(0.45, Color(0.03, 0.05, 0.16, 0.10))
	grad.add_point(0.68, Color(0.03, 0.05, 0.16, 0.42))
	grad.add_point(1.0, Color(0.03, 0.05, 0.16, 0.95))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	tex.width = 512
	return tex


func _build_title_landscape() -> void:
	var panel := GoldFrame.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(panel, 0.27, 0.05, 0.73, 0.21)
	add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(col)
	panel.add_child(col)
	var title := UiFont.label(Balance.TITLE, 58, UiFont.GOLD)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title)
	var subtitle := UiFont.label("校庭に、三分の決戦。", 21, UiFont.CREAM)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(subtitle)


func _build_title_portrait() -> void:
	var panel := GoldFrame.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(panel, 0.05, 0.035, 0.95, 0.15)
	add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(col)
	panel.add_child(col)
	var title := UiFont.label(Balance.TITLE, 40, UiFont.GOLD)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title)
	var subtitle := UiFont.label("校庭に、三分の決戦。", 16, UiFont.CREAM)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(subtitle)


func _build_stats(top: float, bottom: float) -> void:
	var band := GoldFrame.new()
	band.fill = Color(0.04, 0.06, 0.18, 0.78)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(band, 0.24 if not _portrait else 0.12, top, 0.76 if not _portrait else 0.88, bottom)
	add_child(band)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 48 if not _portrait else 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(row)
	band.add_child(row)
	var best := int(SaveStore.data.get("best_score", 0))
	var when := str(SaveStore.data.get("best_datetime", ""))
	var best_text := "自己ベスト  記録なし" if when == "" else "自己ベスト  %d" % best
	var size := 22 if not _portrait else 18
	row.add_child(UiFont.label(best_text, size, UiFont.PAPER))
	var yen := int(SaveStore.data.get("yen", 0))
	row.add_child(UiFont.label("所持金  %d イェン" % yen, size, UiFont.GOLD))


func _build_menu_landscape() -> void:
	var menu := HBoxContainer.new()
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", 18)
	UiFont.place(menu, 0.06, 0.875, 0.94, 0.985)
	add_child(menu)
	for item in _menu_items():
		var button := UiFont.royal_button(str(item[0]), 24, bool(item[1]))
		button.custom_minimum_size = Vector2(230, 64)
		button.pressed.connect(item[2])
		menu.add_child(button)


func _build_menu_portrait() -> void:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	UiFont.place(col, 0.08, 0.66, 0.92, 0.985)
	add_child(col)
	for item in _menu_items():
		var button := UiFont.royal_button(str(item[0]), 22, bool(item[1]))
		button.custom_minimum_size = Vector2(0, 58)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(item[2])
		col.add_child(button)


func _menu_items() -> Array:
	return [
		["出撃", true, _start],
		["ランキング", false, _open_ranking],
		["敵図鑑", false, _open_bestiary],
		["なかむら商店", false, _open_shop],
	]


func _start() -> void:
	get_tree().change_scene_to_file("res://scenes/select.tscn")


func _open_shop() -> void:
	SaveStore.shop_return = "res://scenes/title.tscn"
	get_tree().change_scene_to_file("res://scenes/shop.tscn")


func _open_ranking() -> void:
	get_tree().change_scene_to_file("res://scenes/ranking.tscn")


func _open_bestiary() -> void:
	get_tree().change_scene_to_file("res://scenes/bestiary.tscn")


class Sparkles extends Control:
	var lights: Array[Dictionary] = []
	var t := 0.0


	func _process(dt: float) -> void:
		t += dt
		queue_redraw()


	func _draw() -> void:
		for light in lights:
			var x: float = float(light.x) * size.x
			var y: float = float(light.y) * size.y
			var r: float = float(light.r)
			var tw := 0.5 + 0.5 * sin(t * float(light.hz) + float(light.phase))
			var c := Color(1.0, 0.82, 0.42, 0.05 + 0.20 * tw)
			draw_circle(Vector2(x, y), r * (0.75 + 0.5 * tw), c)


class GoldFrame extends Control:
	var fill: Color = Color(0.05, 0.07, 0.20, 0.86)
	var gold := UiFont.BRASS
	var gold_bright := UiFont.GOLD


	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, fill, true)
		draw_rect(r, gold, false, 3.0)
		var inner := r.grow(-9.0)
		draw_rect(inner, gold, false, 1.5)
		for corner in [Vector2.ZERO, Vector2(size.x, 0.0), Vector2(0.0, size.y), Vector2(size.x, size.y)]:
			var c := Vector2(
				clampf(corner.x, 12.0, size.x - 12.0),
				clampf(corner.y, 12.0, size.y - 12.0)
			)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0.0, -10.0),
				c + Vector2(10.0, 0.0),
				c + Vector2(0.0, 10.0),
				c + Vector2(-10.0, 0.0),
			]), gold_bright)
