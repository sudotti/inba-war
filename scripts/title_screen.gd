extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")

const POSTER := "res://assets/ui/title_trio.png"


func _ready() -> void:
	UiFont.full_rect(self)
	var poster := TextureRect.new()
	poster.texture = load(POSTER)
	poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(poster)
	add_child(poster)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.04, 0.06, 0.18)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(shade)
	add_child(shade)

	var title := UiFont.label(Balance.TITLE, 58, UiFont.PAPER)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(title, 0.035, 0.035, 0.62, 0.15)
	add_child(title)
	var subtitle := UiFont.label("校庭に、三分の決戦。", 20, UiFont.BRASS)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(subtitle, 0.04, 0.15, 0.50, 0.21)
	add_child(subtitle)

	var menu_band := ColorRect.new()
	menu_band.color = Color("15120f")
	menu_band.modulate.a = 0.94
	menu_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(menu_band, 0.0, 0.76, 1.0, 1.0)
	add_child(menu_band)

	var menu := HBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	UiFont.place(menu, 0.025, 0.79, 0.975, 0.97)
	add_child(menu)
	var stats := VBoxContainer.new()
	stats.custom_minimum_size = Vector2(270, 0)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_theme_constant_override("separation", 3)
	menu.add_child(stats)
	var best := int(SaveStore.data.get("best_score", 0))
	var when := str(SaveStore.data.get("best_datetime", ""))
	var best_text := "自己ベスト  記録なし" if when == "" else "自己ベスト  %d" % best
	stats.add_child(UiFont.label(best_text, 22, UiFont.PAPER))
	var yen := int(SaveStore.data.get("yen", 0))
	stats.add_child(UiFont.label("所持金  %d イェン" % yen, 18, UiFont.BRASS))
	menu.add_child(_menu_button("出撃", 210, true, _start))
	menu.add_child(_menu_button("ランキング", 190, false, _open_ranking))
	menu.add_child(_menu_button("敵図鑑", 170, false, _open_bestiary))
	menu.add_child(_menu_button("なかむら商店", 210, false, _open_shop))


func _menu_button(text: String, width: float, primary: bool, action: Callable) -> Button:
	var button := UiFont.button(text, 22)
	button.custom_minimum_size = Vector2(width, 68)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var fill := UiFont.BRASS if primary else Color("211c19")
	var text_color := UiFont.INK if primary else UiFont.PAPER
	button.add_theme_stylebox_override("normal", UiFont.style(fill, UiFont.BRASS, 2, 5))
	button.add_theme_stylebox_override("hover", UiFont.style(Color("e76f45"), UiFont.PAPER, 2, 5))
	button.add_theme_stylebox_override("pressed", UiFont.style(Color("b94c36"), UiFont.PAPER, 2, 5))
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", UiFont.PAPER)
	button.add_theme_color_override("font_pressed_color", UiFont.PAPER)
	button.pressed.connect(action)
	return button


func _start() -> void:
	get_tree().change_scene_to_file("res://scenes/select.tscn")


func _open_shop() -> void:
	SaveStore.shop_return = "res://scenes/title.tscn"
	get_tree().change_scene_to_file("res://scenes/shop.tscn")


func _open_ranking() -> void:
	get_tree().change_scene_to_file("res://scenes/ranking.tscn")


func _open_bestiary() -> void:
	get_tree().change_scene_to_file("res://scenes/bestiary.tscn")
