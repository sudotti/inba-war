extends Node

const MODES: Array[String] = ["title", "closet", "battle_hit"]

var index := 0
var stage := 0


func _ready() -> void:
	call_deferred("_arm")


func _arm() -> void:
	var root := get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	_go()


func _go() -> void:
	stage = 0
	var mode := MODES[index]
	if mode == "locked":
		SaveStore.data.takechi_unlocked = false
		SaveStore.data.kenny_unlocked = false
		SaveStore.data.takechi_fragments = 2
		SaveStore.data.kenny_fragments = 1
	var path := "res://scenes/title.tscn"
	if mode == "shop":
		path = "res://scenes/shop.tscn"
	elif mode == "select" or mode == "closet" or mode == "locked":
		path = "res://scenes/select.tscn"
	elif mode.begins_with("battle"):
		path = "res://scenes/battle.tscn"
	get_tree().change_scene_to_file(path)


func _process(_dt: float) -> void:
	stage += 1
	var mode := MODES[index]
	if stage < 4:
		return
	if stage == 4 and mode == "closet":
		get_tree().current_scene._open_closet("マッサ")
		return
	if stage == 4 and mode == "battle_hit":
		_pose_battle(true)
		return
	if stage == 4 and mode == "battle_walk":
		_pose_battle(false)
		return
	if stage < 6:
		return
	var image := get_viewport().get_texture().get_image()
	image.save_png("/tmp/inba_%s.png" % mode)
	print("SHOT ", mode)
	index += 1
	if index >= MODES.size():
		get_tree().quit()
		return
	_go()


func _pose_battle(hitting: bool) -> void:
	var battle := get_tree().current_scene
	battle.set_process(false)
	battle.sim.player_pos = Vector2(1200, 800)
	battle.sim.enemies.clear()
	battle.sim.debug_place("normal", Vector2(1330, 810), 80, 0.0)
	battle.sim.time = 8.0
	battle._wish = Vector2(-1, 0)
	if hitting:
		battle._strike_age = 0.0
		battle._update_aim(true)
	else:
		battle._strike_age = 10.0
		battle.sim._attack_acc = 0.05
		battle._update_aim(false)
	battle._follow_camera()
	battle.queue_redraw()
	print("FACE ", battle._player_face, " AIM ", battle._aim)
