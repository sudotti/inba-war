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
	var title := current
	if _count_buttons(title) < 4:
		print("TITLE portrait buttons < 4")
		fails += 1
	if not _has_menu(title, true):
		print("TITLE portrait menu not vertical")
		fails += 1
	_clear_children(title)
	title._portrait = false
	title._build()
	if _count_buttons(title) < 4:
		print("TITLE landscape buttons < 4")
		fails += 1
	if not _has_menu(title, false):
		print("TITLE landscape menu not horizontal")
		fails += 1


func _check_select() -> void:
	var select := current
	select._is_portrait = true
	var card: Control = select._card(Balance.CHAR_KENNY)
	if card == null or card.get_child_count() == 0:
		print("SELECT portrait card failed")
		fails += 1
	select._is_portrait = false
	var wide: Control = select._card(Balance.CHAR_TAKETCHI)
	if wide == null or wide.get_child_count() == 0:
		print("SELECT landscape card failed")
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
	battle._stacked_cards = false
	battle._compact_layout = false
	_rebuild_choice(battle)
	if battle.card_row is not HBoxContainer:
		print("BATTLE landscape card_row not HBox")
		fails += 1
	battle._stacked_cards = true
	battle._compact_layout = true
	_rebuild_choice(battle)
	if battle.card_row is not VBoxContainer:
		print("BATTLE portrait card_row not VBox")
		fails += 1
	var stacked_card: Control = battle._card(0, Balance.UPGRADES[0])
	if stacked_card == null or stacked_card.get_child_count() == 0:
		print("BATTLE stacked card failed")
		fails += 1


func _rebuild_choice(battle: Node) -> void:
	if battle.build_root != null and battle.build_root.get_parent() != null:
		battle.build_root.get_parent().free()
	battle._build_choice()


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.free()


func _has_menu(node: Node, want_vertical: bool) -> bool:
	if node is BoxContainer:
		var buttons := 0
		for child in node.get_children():
			if child is Button:
				buttons += 1
		if buttons == 4:
			var is_vertical := node is VBoxContainer
			return is_vertical == want_vertical
	for child in node.get_children():
		if _has_menu(child, want_vertical):
			return true
	return false


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
