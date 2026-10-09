extends Control

const Balance = preload("res://scripts/balance.gd")
const UiFont = preload("res://scripts/ui_font.gd")

const POSTER := "res://assets/ui/title_trio.png"


func _ready() -> void:
	UiFont.full_rect(self)
	var night := ColorRect.new()
	night.color = UiFont.NIGHT
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(night)
	add_child(night)

	var poster := TextureRect.new()
	poster.texture = load(POSTER)
	poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(poster)
	add_child(poster)

	var title := UiFont.label(Balance.TITLE, 52, UiFont.PAPER)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(title, 0.04, 0.03, 0.58, 0.14)
	add_child(title)

	var start := UiFont.button("はじめる", 32)
	start.custom_minimum_size = Vector2(0, 72)
	UiFont.place(start, 0.66, 0.045, 0.96, 0.16)
	start.pressed.connect(_start)
	add_child(start)

	var meta := VBoxContainer.new()
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta.add_theme_constant_override("separation", 2)
	UiFont.place(meta, 0.04, 0.14, 0.40, 0.30)
	add_child(meta)
	var best := int(SaveStore.data.get("best_score", 0))
	var when := str(SaveStore.data.get("best_datetime", ""))
	var best_text := "自己ベスト  まだない" if when == "" else "自己ベスト  %d" % best
	meta.add_child(UiFont.label(best_text, 22, UiFont.PAPER))
	var yen := int(SaveStore.data.get("yen", 0))
	meta.add_child(UiFont.label("100イェン  %d枚" % yen, 22, UiFont.BRASS))
	meta.add_child(UiFont.label(Balance.VERSION, 16, Color("c8beb0")))

	var shop := UiFont.button("なかむらショップ", 24)
	shop.custom_minimum_size = Vector2(0, 64)
	UiFont.place(shop, 0.66, 0.84, 0.96, 0.95)
	shop.pressed.connect(_open_shop)
	add_child(shop)


func _start() -> void:
	get_tree().change_scene_to_file("res://scenes/select.tscn")


func _open_shop() -> void:
	SaveStore.shop_return = "res://scenes/title.tscn"
	get_tree().change_scene_to_file("res://scenes/shop.tscn")
