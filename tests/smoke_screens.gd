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
	_load_next()
	return false


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
