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
	elif scene == "res://scenes/bestiary.tscn":
		_check_bestiary()
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
	if _find_scroll(current) != null:
		print("SHOP still scrolls its goods")
		fails += 1
	if not _label_text(current, "印旛中学校制服"):
		print("SHOP uniform name missing")
		fails += 1
	var goods := _meta_nodes(current, "shop_good")
	if goods.is_empty():
		print("SHOP goods missing")
		fails += 1
	for good in goods:
		var rect: Rect2 = (good as Control).get_global_rect()
		if rect.position.y > 640.0 or rect.end.y > 980.0 or rect.size.y < 40.0:
			print("SHOP good off the top half ", rect)
			fails += 1


func _check_bestiary() -> void:
	if current is Control and (current as Control).size.y < 400.0:
		print("BESTIARY root collapsed")
		fails += 1
	if _find_scroll(current) != null:
		print("BESTIARY still scrolls its list")
		fails += 1
	var entries := _meta_nodes(current, "bestiary_entry")
	if entries.size() != Balance.ENEMY_KINDS.size():
		print("BESTIARY entries missing ", entries.size())
		fails += 1
	for entry in entries:
		var button := entry as Button
		var rect: Rect2 = button.get_global_rect()
		if button.text != "":
			print("BESTIARY entry uses Button.text")
			fails += 1
		if rect.position.y > 640.0 or rect.size.y < 48.0:
			print("BESTIARY entry off the top half ", rect)
			fails += 1
		var caption := ""
		for child in button.get_children():
			if child is Label:
				caption = (child as Label).text
		if caption == "":
			print("BESTIARY entry caption blank")
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


func _meta_nodes(node: Node, key: String) -> Array:
	var found: Array = []
	if node.has_meta(key):
		found.append(node)
	for child in node.get_children():
		found.append_array(_meta_nodes(child, key))
	return found


func _find_scroll(node: Node) -> ScrollContainer:
	if node is ScrollContainer:
		return node
	for child in node.get_children():
		var found := _find_scroll(child)
		if found != null:
			return found
	return null


func _label_text(node: Node, text: String) -> bool:
	if node is Label and (node as Label).text == text:
		return true
	for child in node.get_children():
		if _label_text(child, text):
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
