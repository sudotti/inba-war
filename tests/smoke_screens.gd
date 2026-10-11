extends SceneTree

const Balance = preload("res://scripts/balance.gd")

const PATHS := [
	"res://scenes/title.tscn",
	"res://scenes/select.tscn",
	"res://scenes/shop.tscn",
	"res://scenes/result.tscn",
	"res://scenes/ranking.tscn",
	"res://scenes/bestiary.tscn",
	"res://scenes/battle.tscn",
]

var index := 0
var fails := 0
var frames := 0
var current: Node = null


func _initialize() -> void:
	_load_next()


func _process(_delta: float) -> bool:
	if current == null:
		return false
	frames += 1
	if frames < 3:
		return false
	if current.get_child_count() == 0:
		print("EMPTY SCENE ", PATHS[index - 1])
		fails += 1
	_check_layout()
	_load_next()
	return false


func _check_layout() -> void:
	var scene: String = PATHS[index - 1]
	if scene == "res://scenes/title.tscn":
		_check_title()
	elif scene == "res://scenes/select.tscn":
		_check_select()
	elif scene == "res://scenes/shop.tscn":
		_check_shop()
	elif scene == "res://scenes/battle.tscn":
		_check_battle()


func _check_title() -> void:
	if _count_buttons(current) < 5:
		print("TITLE buttons < 5")
		fails += 1


func _check_select() -> void:
	var select := current
	var card: Control = select._card(Balance.CHAR_KENNY)
	if card == null or card.get_child_count() == 0:
		print("SELECT card failed")
		fails += 1
	var other: Control = select._card(Balance.CHAR_TAKETCHI)
	if other == null or other.get_child_count() == 0:
		print("SELECT second card failed")
		fails += 1


func _check_shop() -> void:
	if _count_buttons(current) < 1:
		print("SHOP has no buy buttons")
		fails += 1
	if not _has_buy_card(current):
		print("SHOP missing item card")
		fails += 1


func _check_battle() -> void:
	var battle := current
	if battle.card_row == null or not battle.card_row is VBoxContainer:
		print("BATTLE card row missing")
		fails += 1
	if battle.hp_fill == null:
		print("BATTLE hp bar missing")
		fails += 1
	if battle.timer_fill == null:
		print("BATTLE timer bar missing")
		fails += 1
	if battle._gain == null:
		print("BATTLE gain label missing")
		fails += 1
	var stacked_card: Control = battle._card(0, Balance.UPGRADES[0])
	if stacked_card == null or stacked_card.get_child_count() == 0:
		print("BATTLE stacked card failed")
		fails += 1
	var button: Button = battle.special_button
	var vp_h: float = battle.get_viewport_rect().size.y
	var round_box := button.get_theme_stylebox("disabled") as StyleBoxFlat if button != null else null
	if button == null or button.size.x < 120.0 or absf(button.size.x - button.size.y) > 1.0:
		print("BATTLE special button is not a large disk")
		fails += 1
	elif button.position.y > vp_h - 180.0:
		print("BATTLE special button sits too low")
		fails += 1
	elif round_box == null or round_box.get_corner_radius(CORNER_TOP_LEFT) < 60:
		print("BATTLE special button is not round")
		fails += 1


func _count_buttons(node: Node) -> int:
	var count := 0
	if node is Button:
		count += 1
	for child in node.get_children():
		count += _count_buttons(child)
	return count


func _has_buy_card(node: Node) -> bool:
	if node is PanelContainer:
		var labels := 0
		for child in node.get_children():
			labels += _count_labels(child)
		if labels >= 2:
			return true
	for child in node.get_children():
		if _has_buy_card(child):
			return true
	return false


func _count_labels(node: Node) -> int:
	var count := 0
	if node is Label:
		count += 1
	for child in node.get_children():
		count += _count_labels(child)
	return count


func _load_next() -> void:
	if current != null:
		current.free()
		current = null
	if index >= PATHS.size():
		if fails == 0:
			print("SMOKE OK")
		else:
			print("SMOKE FAILED %d" % fails)
		quit(fails)
		return
	var p: String = PATHS[index]
	index += 1
	var packed: PackedScene = load(p)
	if packed == null:
		print("LOAD FAIL ", p)
		fails += 1
		_load_next()
		return
	current = packed.instantiate()
	root.add_child(current)
	frames = 0
