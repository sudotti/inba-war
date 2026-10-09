extends SceneTree

const PATHS := [
	"res://scenes/title.tscn",
	"res://scenes/select.tscn",
	"res://scenes/shop.tscn",
	"res://scenes/result.tscn",
	"res://scenes/ranking.tscn",
	"res://scenes/bestiary.tscn",
	"res://scenes/battle.tscn",
]

var SIZE := Vector2(390, 844)

var index := 0
var frames := 0
var current: Node = null
var fails := 0


func _initialize() -> void:
	var w := OS.get_environment("LAYOUT_W")
	var h := OS.get_environment("LAYOUT_H")
	if w != "" and h != "":
		SIZE = Vector2(float(w), float(h))
	root.size = SIZE
	print("viewport=", root.size, " visible=", root.get_visible_rect().size)
	_load_next()


func _process(_delta: float) -> bool:
	if current == null:
		return false
	frames += 1
	if frames < 10:
		return false
	_check_bounds(current, false)
	_load_next()
	return false


func _check_bounds(node: Node, in_scroll: bool) -> void:
	var bounds: Rect2 = root.get_visible_rect()
	if node is Control and node != current and not in_scroll:
		var r: Rect2 = node.get_global_rect()
		if r.position.x < -2.0 or r.position.y < -2.0 or r.end.x > bounds.size.x + 2.0 or r.end.y > bounds.size.y + 2.0:
			print("OVERFLOW %s: %s [%s]" % [node.name, r, PATHS[index - 1]])
			fails += 1
	var nested := in_scroll or node is ScrollContainer
	for child in node.get_children():
		_check_bounds(child, nested)


func _load_next() -> void:
	if current != null:
		current.free()
		current = null
	if index >= PATHS.size():
		if fails == 0:
			print("LAYOUT OK")
		else:
			print("LAYOUT FAILED %d" % fails)
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
