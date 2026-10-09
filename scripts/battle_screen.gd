extends Node2D

const Balance = preload("res://scripts/balance.gd")
const BattleSim = preload("res://scripts/battle_sim.gd")
const UiFont = preload("res://scripts/ui_font.gd")
const Stick = preload("res://scripts/virtual_stick.gd")

const GRASS := Color("2c3b28")
const GRASS_DARK := Color("243222")
const GRASS_LIGHT := Color("3a4d34")
const DIRT := Color("c6a56e")
const TRACK := Color(1, 1, 1, 0.72)
const MASSA_COLOR := Color("f3ead2")
const COIN_COLOR := Color("ffc107")
const TREE_SPOTS: Array[Vector2] = [
	Vector2(680, 1000),
	Vector2(1710, 940),
	Vector2(980, 1140),
	Vector2(1560, 1100),
]

const ART_NORMAL := "res://assets/battle/enemy_normal.png"
const ART_FAST := "res://assets/battle/enemy_fast.png"
const ART_TANK := "res://assets/battle/enemy_tank.png"
const ART_CONE := "res://assets/battle/cone.png"

var sim
var camera: Camera2D
var stick
var art_normal: Texture2D
var art_fast: Texture2D
var art_tank: Texture2D
var art_cone: Texture2D

var time_label: Label
var hp_label: Label
var hp_fill: ColorRect
var score_label: Label
var coin_label: Label
var hint: Label
var build_line: Label
var _gain: Label
var _gain_left := 0.0

var build_root: Control
var card_row: HBoxContainer
var timer_label: Label
var timer_fill: ColorRect
var build_left := Balance.BUILD_SELECT_SECONDS
var build_shown := false

var _mouse_down := false
var _touch_count := 0
var _hurt_left := 0.0
var _seen_hurt := 0
var _seen_attack := 0
var _strike_age := 10.0
var _shake_left := 0.0
var _anim := 0.0
var _wish := Vector2.ZERO
var _player_face := 1.0
var _aim := Vector2(0, 1)
var _step := 0.0
var _frames: Dictionary = {}
var _who := Balance.CHAR_MASSA
var _left := false
var _watch: Dictionary = {}
var _born: Dictionary = {}
var _face: Dictionary = {}
var _flash: Dictionary = {}
var _bite: Dictionary = {}
var _puffs: Array[Dictionary] = []
var special_button: Button
var special_gauge: ProgressBar
var _special_cut_in: Control
var _special_face: TextureRect
var _special_name: Label
var _special_quote: Label
var _special_ring_left := 0.0
var _special_motion_left := 0.0
var _special_motion_duration := 0.0
var _special_tween: Tween


func _ready() -> void:
	_who = SaveStore.playable_character()
	sim = BattleSim.new(_who)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()
	_load_frames()
	art_normal = load(ART_NORMAL)
	art_fast = load(ART_FAST)
	art_tank = load(ART_TANK)
	art_cone = load(ART_CONE)
	_build_hud()
	_build_stick()
	_build_choice()
	_follow_camera()


func _process(dt: float) -> void:
	_special_ring_left = maxf(0.0, _special_ring_left - dt)
	_special_motion_left = maxf(0.0, _special_motion_left - dt)
	if sim.finished:
		_go_result()
		return
	if _gain_left > 0.0:
		_gain_left = maxf(0.0, _gain_left - dt)
		_gain.modulate.a = clampf(_gain_left / 0.35, 0.0, 1.0)
	if sim.build_open:
		if not build_shown:
			build_shown = true
			build_left = Balance.BUILD_SELECT_SECONDS
			_show_build()
		else:
			build_left -= dt
			_update_timer()
			if build_left <= 0.0:
				_pick(0)
				return
		_sync_hud()
		queue_redraw()
		return
	_follow_camera()
	sim.view_rect = _view_rect()
	_wish = _move_vector()
	sim.step(dt, _wish)
	_follow_camera()
	_note_fx(dt)
	if _shake_left > 0.0:
		var power := 7.0 * (_shake_left / 0.2)
		camera.global_position += Vector2(sin(_anim * 80.0), cos(_anim * 63.0)) * power
	_sync_hud()
	queue_redraw()
	if sim.finished:
		_go_result()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_count += 1
		else:
			_touch_count = maxi(0, _touch_count - 1)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _touch_count == 0:
			_mouse_down = event.pressed
	elif event is InputEventKey and event.pressed and not event.echo and sim != null:
		var key := int(event.physical_keycode)
		if key == KEY_SPACE and not sim.build_open:
			_activate_special()
		elif sim.build_open and (key == KEY_1 or key == KEY_KP_1):
			_pick(0)
		elif sim.build_open and (key == KEY_2 or key == KEY_KP_2):
			_pick(1)
		elif sim.build_open and (key == KEY_3 or key == KEY_KP_3):
			_pick(2)


func _move_vector() -> Vector2:
	var from_stick: Vector2 = stick.direction
	if from_stick.length() > 0.12:
		return from_stick
	var key := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		key.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		key.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		key.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		key.y += 1.0
	if key.length() > 0.0:
		return key.normalized()
	if _mouse_down and _touch_count == 0 and not sim.build_open:
		var center: Vector2 = get_viewport().get_visible_rect().size * 0.5
		var player_screen: Vector2 = center + (Vector2(sim.player_pos) - camera.global_position) * camera.zoom
		var delta: Vector2 = get_viewport().get_mouse_position() - player_screen
		if delta.length() > 36.0:
			return delta.normalized()
	return Vector2.ZERO


func _note_fx(dt: float) -> void:
	_anim += dt
	_strike_age += dt
	var body := _body()
	var interval := maxf(0.2, float(sim.attack_interval))
	var wind_at := 1.0 - clampf(float(body.wind) / interval, 0.05, 0.8)
	var busy := _strike_age < float(body.follow) or float(sim.attack_ratio()) > wind_at
	if _wish.length() > 0.12 and not busy:
		_step += dt * float(body.hz)
	_shake_left = maxf(0.0, _shake_left - dt)
	var just_hit: bool = sim.attack_serial != _seen_attack
	_update_aim(just_hit)
	var alive := {}
	for actor in sim.enemies:
		alive[int(actor.id)] = actor
	var gone: Array[int] = []
	for id in _watch.keys():
		var key := int(id)
		if not alive.has(key):
			gone.append(key)
	for id in gone:
		var info: Dictionary = _watch[id]
		var spot: Vector2 = info.pos
		if sim.player_pos.distance_to(spot) < Balance.DESPAWN_DISTANCE - 30.0:
			_burst(spot, str(info.kind))
		_watch.erase(id)
		_born.erase(id)
		_face.erase(id)
		_flash.erase(id)
		_bite.erase(id)
	for id in alive.keys():
		var key := int(id)
		var actor = alive[key]
		var prev_hp := int(actor.hp)
		var prev_pos: Vector2 = actor.pos
		if _watch.has(key):
			var info: Dictionary = _watch[key]
			prev_hp = int(info.hp)
			prev_pos = info.pos
			if int(actor.hp) < prev_hp:
				_flash[key] = 0.16
		else:
			_born[key] = sim.time
			_face[key] = 1.0
		var delta := Vector2(actor.pos) - prev_pos
		if absf(delta.x) > 0.4:
			_face[key] = -1.0 if delta.x < 0.0 else 1.0
		_watch[key] = {"hp": actor.hp, "pos": actor.pos, "kind": actor.kind}
	if just_hit:
		_seen_attack = sim.attack_serial
		_strike_age = 0.0
		_swing_dust()
	if sim.hurt_serial != _seen_hurt:
		_seen_hurt = sim.hurt_serial
		_hurt_left = 0.22
		_shake_left = 0.2
		for actor in sim.enemies:
			if actor.stun > 0.0:
				continue
			var reach: float = float(sim.player_radius) + float(actor.radius) + 8.0
			if sim.player_pos.distance_to(actor.pos) <= reach:
				_bite[int(actor.id)] = 0.2
	_hurt_left = maxf(0.0, _hurt_left - dt)
	for id in _flash.keys():
		_flash[id] = float(_flash[id]) - dt
	for id in _bite.keys():
		_bite[id] = float(_bite[id]) - dt
	var keep: Array[Dictionary] = []
	for puff in _puffs:
		puff.life = float(puff.life) - dt
		puff.pos = Vector2(puff.pos) + Vector2(puff.vel) * dt
		puff.vel = Vector2(puff.vel) * 0.9
		if float(puff.life) > 0.0:
			keep.append(puff)
	_puffs = keep


func _burst(spot: Vector2, kind: String) -> void:
	var color := Color("243048")
	if kind == Balance.KIND_FAST:
		color = Color("e23b2f")
	elif kind == Balance.KIND_TANK:
		color = Color("1a1a1a")
	for i in 8:
		var ang := float(i) / 8.0 * TAU + randf_range(-0.2, 0.2)
		_puffs.append({
			"pos": spot + Vector2(0, -20),
			"vel": Vector2(cos(ang), sin(ang)) * randf_range(90.0, 170.0),
			"life": 0.38,
			"max": 0.38,
			"color": color,
		})


func _draw() -> void:
	_draw_ground()
	_draw_special_aura()
	if _special_ring_left > 0.0:
		var progress := 1.0 - _special_ring_left / 0.58
		var start := -PI * 0.5 + progress * TAU
		var radius := lerpf(84.0, Balance.SPECIAL_MASSA_RADIUS, progress)
		draw_arc(sim.player_pos, radius, start, start + TAU * 0.82, 96, Color(1.0, 0.84, 0.3, 0.9 * (1.0 - progress * 0.45)), 14.0, true)
		draw_arc(sim.player_pos, radius - 12.0, start, start + TAU * 0.72, 80, Color(1.0, 0.97, 0.78, 0.7 * (1.0 - progress)), 4.0, true)
	var shadow_r := 32.0 if str(sim.character_id) == Balance.CHAR_TAKETCHI else 24.0
	_draw_shadow(sim.player_pos, shadow_r * (1.0 if _strike_age > 0.2 else 0.82))
	for cone in sim.cones:
		_draw_shadow(cone.pos, 18.0)
	for actor in sim.enemies:
		_draw_shadow(actor.pos, float(actor.radius) * 0.85)
	for coin in sim.coins:
		_draw_coin(coin)
	for puff in _puffs:
		_draw_puff(puff)
	var puri_level := int(sim.levels.get(Balance.PURITORA, 0))
	if puri_level > 0 and sim.pulse_age < 0.28:
		var alpha: float = 1.0 - float(sim.pulse_age) / 0.28
		var ring := Balance.puritora_radius(puri_level)
		draw_arc(sim.player_pos, ring, 0, TAU, 72, Color(1, 0.95, 0.55, 0.7 * alpha), 7.0, true)

	# 足元の位置で前後を決める。当たり判定の円はそのまま。
	var order: Array[Dictionary] = []
	for cone in sim.cones:
		order.append({"y": cone.pos.y, "kind": "cone", "pos": cone.pos})
	for actor in sim.enemies:
		order.append({"y": actor.pos.y, "kind": "enemy", "actor": actor})
	order.append({"y": sim.player_pos.y, "kind": "player"})
	order.append({"y": 612.0, "kind": "school"})
	for spot in TREE_SPOTS:
		order.append({"y": spot.y, "kind": "tree", "pos": spot})
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.y) < float(b.y)
	)
	for item in order:
		if str(item.kind) == "cone":
			_draw_still(art_cone, Vector2(item.pos), 76.0, 62.0)
		elif str(item.kind) == "school":
			_draw_school()
		elif str(item.kind) == "tree":
			_draw_tree(Vector2(item.pos))
		elif str(item.kind) == "player":
			var vis := _player_visual()
			var foot := Vector2(sim.player_pos) + Vector2(float(vis.sway), -float(vis.hop))
			var pose := {
				"hop": 0.0,
				"rot": float(vis.rot),
				"sx": float(vis.face) * float(vis.sx),
				"sy": float(vis.sy),
				"tint": vis.tint,
				"lunge": Vector2(vis.lunge),
				"flash": 0.0,
			}
			var tex: Texture2D = _frames[str(vis.frame)]
			_draw_posed(tex, foot + Vector2(vis.lunge), _sprite_h(), 480.0, pose)
		else:
			var actor = item.actor
			var pose := _enemy_pose(actor)
			var lunge: Vector2 = pose.lunge
			var foot := Vector2(actor.pos) + lunge + Vector2(0.0, -float(pose.hop))
			var tex: Texture2D = art_normal
			var max_h := 112.0
			var max_w := 74.0
			if actor.kind == Balance.KIND_FAST:
				tex = art_fast
				max_h = 84.0
				max_w = 118.0
			elif actor.kind == Balance.KIND_TANK:
				tex = art_tank
				max_h = 132.0
				max_w = 176.0
			var head := _draw_posed(tex, foot, max_h, max_w, pose)
			if actor.hp < actor.max_hp:
				_draw_hp_bar(foot, head, float(actor.hp) / float(maxi(actor.max_hp, 1)))
			if actor.stun > 0.0:
				_draw_stun_marks(Vector2(foot.x, head), int(actor.id))
			if float(pose.flash) > 0.0:
				var spark := float(pose.flash) / 0.16
				var mid := foot + Vector2(0.0, -max_h * 0.42)
				draw_line(mid + Vector2(-22, -16), mid + Vector2(22, 18), Color(1, 1, 1, spark), 6.0, true)
				draw_line(mid + Vector2(20, -18), mid + Vector2(-18, 16), Color(1, 1, 1, spark), 6.0, true)


func _load_frames() -> void:
	var uniform := SaveStore.costume_of(_who) == "制服"
	_frames = {}
	for pose in ["idle", "walk_a", "walk_b", "wind", "hit"]:
		_frames[pose] = load(Balance.pose_path(_who, pose, uniform))


func _body() -> Dictionary:
	# 歩数、沈み、体重、呼吸、予備動作の秒、当てた姿勢を残す秒。性質は企画書の3人。
	if _who == Balance.CHAR_TAKETCHI:
		return {"hz": 2.0, "bob": 1.3, "sway": 1.0, "breath": 0.5, "breath_hz": 0.28, "wind": 0.18, "follow": 0.14}
	if _who == Balance.CHAR_KENNY:
		return {"hz": 2.6, "bob": 2.4, "sway": 1.6, "breath": 0.8, "breath_hz": 0.42, "wind": 0.16, "follow": 0.10}
	return {"hz": 1.55, "bob": 2.0, "sway": 1.4, "breath": 0.9, "breath_hz": 0.26, "wind": 0.36, "follow": 0.22}


func _player_visual() -> Dictionary:
	var body := _body()
	var moving := _wish.length() > 0.12
	var ratio: float = float(sim.attack_ratio())
	var interval := maxf(0.2, float(sim.attack_interval))
	var wind_at := 1.0 - clampf(float(body.wind) / interval, 0.05, 0.8)
	var frame := "idle"
	var hop := sin(_anim * TAU * float(body.breath_hz)) * float(body.breath)
	var sway := 0.0
	var rot := 0.0
	var sx := 1.0
	var sy := 1.0
	var lunge := Vector2.ZERO
	if _strike_age < float(body.follow):
		frame = "hit"
		hop = 0.0
	elif ratio > wind_at:
		frame = "wind"
		hop = 0.0
	elif moving:
		var idx := int(floor(_step))
		var frac := _step - float(idx)
		frame = "walk_a" if idx % 2 == 0 else "walk_b"
		var lift := sin(frac * PI)
		hop = lift * float(body.bob)
		var side := 1.0 if idx % 2 == 0 else -1.0
		sway = lift * float(body.sway) * side
	if _special_motion_left > 0.0:
		var progress := 1.0 - _special_motion_left / _special_motion_duration
		var aim := _aim.normalized() if _aim.length() > 0.01 else Vector2.RIGHT
		frame = "hit"
		hop = 0.0
		sway = 0.0
		if _who == Balance.CHAR_MASSA:
			rot = TAU * 1.5 * progress
			hop = sin(progress * PI) * 15.0
			sx = 1.0 + sin(progress * PI) * 0.12
			sy = 1.0 - sin(progress * PI) * 0.08
		elif _who == Balance.CHAR_TAKETCHI:
			var strike := sin(progress * PI)
			rot = -0.08 + strike * 0.14
			lunge = aim * (18.0 + strike * 58.0)
			sx = 1.0 + strike * 0.09
			sy = 1.0 - strike * 0.1
		else:
			var beat := _anim * 30.0
			frame = "hit" if int(floor(beat)) % 2 == 0 else "wind"
			var kick := maxf(sin(beat * 0.5), 0.0)
			lunge = aim * (14.0 + kick * 54.0)
			rot = sin(beat) * 0.11
	var tint := Color.WHITE
	if _hurt_left > 0.0:
		tint = Color(1, 0.5, 0.46)
	elif float(sim.time) < Balance.INVULN_SECONDS:
		var pulse := 0.45 + 0.55 * sin(float(sim.time) * 18.0)
		tint = Color(0.78, 0.92, 1.0).lerp(Color.WHITE, pulse)
	return {"frame": frame, "hop": hop, "sway": sway, "face": _player_face, "tint": tint, "rot": rot, "sx": sx, "sy": sy, "lunge": lunge}


func _draw_special_aura() -> void:
	if _who == Balance.CHAR_TAKETCHI and sim.special_active_left > 0.0:
		var pulse := 0.5 + 0.5 * sin(_anim * 12.0)
		draw_arc(sim.player_pos, 54.0 + pulse * 10.0, 0.0, TAU, 56, Color(1.0, 0.72, 0.2, 0.48 + pulse * 0.2), 5.0, true)
		for i in 8:
			var angle := float(i) * TAU / 8.0 + _anim * 0.8
			var direction := Vector2.from_angle(angle)
			draw_line(sim.player_pos + direction * 66.0, sim.player_pos + direction * (78.0 + pulse * 12.0), Color(1.0, 0.9, 0.56, 0.62), 3.0, true)
	if _who == Balance.CHAR_KENNY and sim.special_active_left > 0.0:
		var tex: Texture2D = _frames["hit"]
		for i in range(3, 0, -1):
			var alpha := 0.22 - float(i) * 0.045
			var pose := {
				"hop": 0.0,
				"rot": 0.0,
				"sx": _player_face,
				"sy": 1.0,
				"tint": Color(0.44, 0.86, 1.0, alpha),
				"lunge": -_aim.normalized() * float(i) * 24.0,
				"flash": 0.0,
			}
			_draw_posed(tex, sim.player_pos + Vector2(0, -4), _sprite_h(), 480.0, pose)


func _enemy_pose(actor) -> Dictionary:
	var id := int(actor.id)
	var born := float(_born.get(id, sim.time))
	var intro := clampf((sim.time - born) / 0.16, 0.0, 1.0)
	var face := float(_face.get(id, 1.0))
	var stunned: bool = actor.stun > 0.0
	var rate := 7.0
	var amp := 6.0
	var squash := 0.04
	var lean := 0.06
	if actor.kind == Balance.KIND_FAST:
		rate = 13.0
		amp = 11.0
		squash = 0.07
		lean = 0.12
	elif actor.kind == Balance.KIND_TANK:
		rate = 3.0
		amp = 5.0
		squash = 0.06
		lean = 0.03
	var phase: float = float(sim.time) * rate + float(id) * 0.7
	var hop := 0.0 if stunned else absf(sin(phase)) * amp
	var sx := 1.0
	var sy := 1.0
	var rot := sin(sim.time * 16.0 + float(id)) * 0.14 if stunned else face * sin(phase) * lean
	if not stunned:
		sx += sin(phase) * squash
		sy -= sin(phase) * squash
		if actor.kind == Balance.KIND_TANK and sin(phase) < 0.0:
			hop *= 0.35
			sy += 0.1
	var lunge := Vector2.ZERO
	if actor.kind == Balance.KIND_FAST and not stunned:
		lunge = Vector2(face * 22.0 * maxf(sin(phase), 0.0), 4.0)
	var bite := float(_bite.get(id, 0.0))
	if bite > 0.0:
		var toward := Vector2(sim.player_pos) - Vector2(actor.pos)
		if toward.length() > 1.0:
			lunge += toward.normalized() * sin((bite / 0.2) * PI) * 18.0
		sx += 0.16 * (bite / 0.2)
	var flash := maxf(0.0, float(_flash.get(id, 0.0)))
	var tint := Color.WHITE
	if stunned:
		tint = Color(1.2, 1.08, 0.55)
	if flash > 0.0:
		var kick := flash / 0.16
		sx += 0.22 * kick
		sy -= 0.14 * kick
		tint = Color(2.2, 2.2, 2.2)
	var pop := lerpf(0.4, 1.0, intro)
	return {
		"hop": hop,
		"rot": rot,
		"sx": sx * face * pop,
		"sy": sy * pop,
		"tint": tint,
		"lunge": lunge,
		"flash": flash,
	}


func _sprite_h() -> float:
	if str(sim.character_id) == Balance.CHAR_TAKETCHI:
		return 196.0
	if str(sim.character_id) == Balance.CHAR_KENNY:
		return 172.0
	return 164.0


func _face_x(dir: Vector2) -> void:
	if absf(dir.x) > 0.08:
		_player_face = -1.0 if dir.x < 0.0 else 1.0


func _nearest_enemy_dir() -> Vector2:
	var best := 100000.0
	var dir := Vector2.ZERO
	for actor in sim.enemies:
		var delta := Vector2(actor.pos) - Vector2(sim.player_pos)
		var dist := delta.length()
		if dist < best and dist > 0.5:
			best = dist
			dir = delta
	if dir.length() > 0.5:
		return dir.normalized()
	return Vector2.ZERO


func _striking() -> bool:
	var body := _body()
	var interval := maxf(0.2, float(sim.attack_interval))
	var wind_at := 1.0 - clampf(float(body.wind) / interval, 0.05, 0.8)
	if _strike_age < float(body.follow):
		return true
	return float(sim.attack_ratio()) > wind_at


func _update_aim(force_enemy: bool = false) -> void:
	if _wish.length() > 0.12:
		_face_x(_wish)
	var striking := force_enemy or _striking()
	if striking:
		var toward := _nearest_enemy_dir()
		if toward.length() > 0.01:
			_aim = toward
			_face_x(toward)
		else:
			_aim = Vector2(_player_face, 0.0)
	elif _wish.length() > 0.12:
		_aim = _wish.normalized()
	else:
		var toward := _nearest_enemy_dir()
		if toward.length() > 0.01:
			_aim = toward
		elif _aim.length() < 0.01:
			_aim = Vector2(_player_face, 0.2)


func _swing_dust() -> void:
	var who := str(sim.character_id)
	var reach := float(sim.attack_radius) * 0.62
	var lift := -28.0
	var color := Color("e6d3ae")
	if who == Balance.CHAR_TAKETCHI:
		lift = -52.0
		color = Color("fff4ea")
	elif who == Balance.CHAR_KENNY:
		lift = -36.0
		color = Color("efe4d0")
	var spot := Vector2(sim.player_pos) + _aim * reach + Vector2(0.0, lift)
	for i in 5:
		var ang := float(i) / 5.0 * TAU
		_puffs.append({
			"pos": spot,
			"vel": Vector2(cos(ang), sin(ang)) * randf_range(36.0, 100.0),
			"life": 0.22,
			"max": 0.22,
			"color": color,
		})



func _draw_coin(coin) -> void:
	var bob := sin(sim.time * 7.0 + float(coin.id) * 1.3) * 4.0
	var spot := Vector2(coin.pos) + Vector2(0.0, bob)
	draw_circle(spot, 10.0, COIN_COLOR)
	draw_arc(spot, 10.0, 0, TAU, 16, Color("8a6200"), 2.0, true)
	draw_circle(spot + Vector2(-3.0, -3.0), 3.0, Color(1, 0.96, 0.75, 0.95))


func _draw_puff(puff: Dictionary) -> void:
	var life := float(puff.life)
	var max_life := float(puff.max)
	var fade := clampf(life / max_life, 0.0, 1.0)
	var col: Color = puff.color
	col.a = fade
	draw_circle(Vector2(puff.pos), 3.0 + (1.0 - fade) * 7.0, col)


func _draw_stun_marks(head: Vector2, salt: int) -> void:
	for i in 3:
		var ang: float = float(sim.time) * 7.0 + float(i) * TAU / 3.0 + float(salt)
		var spot := head + Vector2(cos(ang) * 18.0, sin(ang) * 7.0 - 10.0)
		draw_circle(spot, 3.0, Color(1, 0.92, 0.35, 0.95))


func _draw_still(tex: Texture2D, foot: Vector2, max_h: float, max_w: float) -> void:
	var pose := {"hop": 0.0, "rot": 0.0, "sx": 1.0, "sy": 1.0, "tint": Color.WHITE, "lunge": Vector2.ZERO, "flash": 0.0}
	_draw_posed(tex, foot, max_h, max_w, pose)


func _draw_posed(tex: Texture2D, foot: Vector2, max_h: float, max_w: float, pose: Dictionary) -> float:
	var aspect := float(tex.get_width()) / float(tex.get_height())
	var h := max_h
	var w := h * aspect
	if w > max_w:
		w = max_w
		h = w / aspect
	var sy := float(pose.sy)
	draw_set_transform(foot, float(pose.rot), Vector2(float(pose.sx), sy))
	draw_texture_rect(tex, Rect2(-w * 0.5, -h, w, h), false, pose.tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return foot.y - h * absf(sy)


func _draw_ground() -> void:
	draw_rect(Rect2(0, 0, Balance.FIELD_W, Balance.FIELD_H), GRASS, true)
	for i in 36:
		var px := fposmod(float(i) * 487.0, Balance.FIELD_W)
		var py := fposmod(float(i) * 269.0, Balance.FIELD_H)
		var rx := 70.0 + fposmod(float(i) * 53.0, 120.0)
		var patch := GRASS_LIGHT if i % 2 == 0 else GRASS_DARK
		patch.a = 0.38
		draw_set_transform(Vector2(px, py), 0.0, Vector2(1.0, 0.58))
		draw_circle(Vector2.ZERO, rx, patch)
	draw_set_transform(Vector2(1200, 1120), 0.0, Vector2(1.0, 0.48))
	draw_circle(Vector2.ZERO, 540.0, Color("3d5238"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var mow := Color(1, 1, 1, 0.045)
	var y := 20.0
	while y < Balance.FIELD_H:
		draw_line(Vector2(0, y), Vector2(Balance.FIELD_W, y), mow, 2.0)
		y += 48.0
	_draw_ellipse(Vector2(1200, 1120), 620.0, 300.0, TRACK, 4.0)
	_draw_ellipse(Vector2(1200, 1120), 470.0, 210.0, Color(1, 1, 1, 0.4), 2.0)
	var court := Rect2(900, 980, 600, 280)
	draw_rect(court, TRACK, false, 3.0)
	draw_line(Vector2(1200, 980), Vector2(1200, 1260), Color(1, 1, 1, 0.45), 2.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1178, 612),
		Vector2(1222, 612),
		Vector2(1260, 1560),
		Vector2(1140, 1560),
	]), DIRT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1190, 612),
		Vector2(1210, 612),
		Vector2(1232, 1560),
		Vector2(1168, 1560),
	]), Color("d8bc88"))
	_draw_bed(Vector2(900, 1000))
	_draw_bed(Vector2(1500, 980))
	var rim := Color("1e2a1c")
	draw_rect(Rect2(0, 0, Balance.FIELD_W, 26), rim, true)
	draw_rect(Rect2(0, Balance.FIELD_H - 26, Balance.FIELD_W, 26), rim, true)
	draw_rect(Rect2(0, 0, 26, Balance.FIELD_H), rim, true)
	draw_rect(Rect2(Balance.FIELD_W - 26, 0, 26, Balance.FIELD_H), rim, true)
	draw_rect(Rect2(780, 606, 840, 14), Color(0, 0, 0, 0.16), true)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color, width: float) -> void:
	var pts := PackedVector2Array()
	var count := 72
	for i in count + 1:
		var ang := float(i) / float(count) * TAU
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_polyline(pts, color, width, true)


func _draw_bed(center: Vector2) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, 54.0, Color("8d6240"))
	draw_circle(Vector2.ZERO, 48.0, Color("3d5c34"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(center + Vector2(-16, -6), 6.0, Color("a86858"))
	draw_circle(center + Vector2(8, 4), 6.0, Color("d7c49a"))
	draw_circle(center + Vector2(22, -8), 5.0, Color("f7f1e6"))


func _draw_school() -> void:
	var left := 760.0
	var right := 1640.0
	var wall := 536.0
	var base := 612.0
	draw_rect(Rect2(left, wall, right - left, base - wall), Color("efe3c8"), true)
	draw_rect(Rect2(left, wall, right - left, base - wall), Color("2a241c"), false, 4.0)
	var peak := Vector2((left + right) * 0.5, 516.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(left - 26, wall + 8),
		peak,
		Vector2(right + 26, wall + 8),
	]), Color("3c4d6e"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(left - 26, wall + 8),
		peak,
		peak + Vector2(0, 14),
		Vector2(left - 6, wall + 20),
	]), Color("2d3b56"))
	var frame := Color("2a241c")
	var glass := Color("9aada8")
	for x in [990.0, 1090.0, 1320.0, 1420.0, 1520.0]:
		draw_rect(Rect2(x, 552, 52, 36), frame, true)
		draw_rect(Rect2(x + 3, 555, 46, 30), glass, true)
		draw_line(Vector2(x + 26, 555), Vector2(x + 26, 585), frame, 2.0)
	draw_rect(Rect2(792, 552, 176, 32), Color("17324f"), true)
	draw_string(UiFont.font(), Vector2(814, 574), "印旛中学校", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f7f1e6"))
	draw_rect(Rect2(1172, 568, 56, 44), Color("6d3b2c"), true)
	draw_rect(Rect2(1172, 568, 56, 44), Color("2a241c"), false, 3.0)
	draw_circle(Vector2(1216, 592), 3.0, Color("e2b43a"))


func _draw_tree(foot: Vector2) -> void:
	draw_rect(Rect2(foot.x - 7, foot.y - 58, 14, 58), Color("6b4428"), true)
	draw_circle(foot + Vector2(0, -78), 30, Color("3e6240"))
	draw_circle(foot + Vector2(-18, -64), 20, Color("4e7348"))
	draw_circle(foot + Vector2(16, -66), 18, Color("345636"))


func _draw_shadow(foot: Vector2, rx: float) -> void:
	draw_set_transform(foot, 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2.ZERO, rx, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hp_bar(foot: Vector2, head: float, ratio: float) -> void:
	var width := 40.0
	var origin := Vector2(foot.x - width * 0.5, head - 9.0)
	draw_rect(Rect2(origin, Vector2(width, 5)), Color(0, 0, 0, 0.55), true)
	draw_rect(Rect2(origin, Vector2(width * clampf(ratio, 0.0, 1.0), 5)), MASSA_COLOR, true)


func _follow_camera() -> void:
	var shown := get_viewport().get_visible_rect().size / camera.zoom
	var pos: Vector2 = sim.player_pos
	if shown.x >= Balance.FIELD_W:
		pos.x = Balance.FIELD_W * 0.5
	else:
		pos.x = clampf(pos.x, shown.x * 0.5, Balance.FIELD_W - shown.x * 0.5)
	if shown.y >= Balance.FIELD_H:
		pos.y = Balance.FIELD_H * 0.5
	else:
		pos.y = clampf(pos.y, shown.y * 0.5, Balance.FIELD_H - shown.y * 0.5)
	camera.global_position = pos


func _view_rect() -> Rect2:
	var shown := get_viewport().get_visible_rect().size / camera.zoom
	return Rect2(camera.global_position - shown * 0.5, shown)


func _sync_hud() -> void:
	var remain := maxf(0.0, Balance.ROUND_SECONDS - sim.time)
	time_label.text = "残り  %s" % _clock(remain)
	hp_label.text = "HP  %d / %d" % [sim.player_hp, sim.player_max_hp]
	var ratio := 0.0 if sim.player_max_hp <= 0 else clampf(float(sim.player_hp) / float(sim.player_max_hp), 0.0, 1.0)
	hp_fill.anchor_right = ratio
	var healthy := Color("b7c4c2")
	if _who == Balance.CHAR_MASSA:
		healthy = Color("f3ead2")
	elif _who == Balance.CHAR_TAKETCHI:
		healthy = Color("e2b43a")
	hp_fill.color = UiFont.PINK if ratio < 0.35 else healthy
	score_label.text = "スコア  %d" % sim.score
	coin_label.text = "コイン  %d" % sim.shown_coins()
	build_line.text = _owned_builds()
	_update_special_hud()
	if sim.time > 5.0:
		hint.modulate.a = clampf(1.0 - (sim.time - 5.0) / 1.2, 0.0, 1.0)


func _clock(remain: float) -> String:
	var whole := int(floor(remain + 0.0001))
	var tenth := int(floor(fmod(remain, 1.0) * 10.0 + 0.0001))
	if tenth >= 10:
		tenth = 0
		whole += 1
	return "%d:%02d.%d" % [whole / 60, whole % 60, tenth]


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	UiFont.full_rect(root)

	var bar := PanelContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(bar, 0.02, 0.012, 0.98, 0.10)
	var hud_style := UiFont.style(Color(0.07, 0.08, 0.1, 0.94), Color(1, 0.95, 0.82, 0.7), 3, 18)
	hud_style.content_margin_top = 6
	hud_style.content_margin_bottom = 6
	hud_style.content_margin_left = 14
	hud_style.content_margin_right = 14
	bar.add_theme_stylebox_override("panel", hud_style)
	root.add_child(bar)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(row)

	var face := UiFont.cropped(_portrait_path(_who))
	var atlas := AtlasTexture.new()
	atlas.atlas = face
	var tw := face.get_width()
	var th := face.get_height()
	atlas.region = Rect2(tw * 0.12, 0, tw * 0.76, th * 0.4)
	var chip := TextureRect.new()
	chip.texture = atlas
	chip.custom_minimum_size = Vector2(48, 48)
	chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(chip)

	var who_label := UiFont.label(_who, 22, UiFont.YELLOW)
	who_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	who_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(who_label)

	time_label = UiFont.label("残り  3:00.0", 30, UiFont.PAPER)
	score_label = UiFont.label("スコア  0", 22, UiFont.PAPER)
	coin_label = UiFont.label("コイン  0", 22, UiFont.YELLOW)
	hp_label = UiFont.label("HP  100 / 100", 20, UiFont.PAPER)
	for node in [time_label, hp_label, score_label, coin_label]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var hp_box := VBoxContainer.new()
	hp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_box.custom_minimum_size = Vector2(240, 0)
	hp_box.add_child(hp_label)
	var track := Control.new()
	track.custom_minimum_size = Vector2(220, 12)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_box.add_child(track)
	var back := ColorRect.new()
	back.color = Color(0, 0, 0, 0.45)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(back)
	track.add_child(back)
	hp_fill = ColorRect.new()
	hp_fill.color = UiFont.CREAM
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_fill.anchor_left = 0
	hp_fill.anchor_top = 0
	hp_fill.anchor_bottom = 1
	hp_fill.anchor_right = 1
	track.add_child(hp_fill)

	row.add_child(hp_box)
	row.add_child(time_label)
	row.add_child(score_label)
	row.add_child(coin_label)

	var motion := "鉄パイプは距離に入ると振り下ろす。WASDで動く"
	if _who == Balance.CHAR_TAKETCHI:
		motion = "拳は近くで出る。WASDで動く"
	elif _who == Balance.CHAR_KENNY:
		motion = "キックは足が届くと出る。WASDで動く"
	hint = UiFont.label(motion, 18, Color(1, 1, 1, 0.94))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(hint, 0.26, 0.915, 0.74, 0.975)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)

	build_line = UiFont.label("", 18, UiFont.YELLOW)
	build_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiFont.place(build_line, 0.12, 0.855, 0.88, 0.91)
	root.add_child(build_line)

	_gain = UiFont.label("", 40, UiFont.YELLOW)
	_gain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gain.modulate.a = 0.0
	UiFont.place(_gain, 0.18, 0.40, 0.82, 0.52)
	root.add_child(_gain)

	var special_box := VBoxContainer.new()
	special_box.add_theme_constant_override("separation", 4)
	UiFont.place(special_box, 0.80, 0.72, 0.98, 0.91)
	root.add_child(special_box)
	special_gauge = ProgressBar.new()
	special_gauge.min_value = 0.0
	special_gauge.max_value = Balance.SPECIAL_GAUGE_MAX
	special_gauge.show_percentage = false
	special_gauge.custom_minimum_size = Vector2(0, 14)
	special_gauge.add_theme_stylebox_override("background", UiFont.style(Color(0.05, 0.05, 0.05, 0.88), Color("c8a456"), 2, 7))
	special_gauge.add_theme_stylebox_override("fill", UiFont.style(Color("d7b072"), Color("fff0c2"), 1, 6))
	special_box.add_child(special_gauge)
	special_button = UiFont.button("必殺技 0% [Space]", 18)
	special_button.custom_minimum_size = Vector2(0, 64)
	special_button.pressed.connect(_activate_special)
	special_box.add_child(special_button)
	_build_special_cut_in()


func _build_stick() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	UiFont.full_rect(root)
	stick = Stick.new()
	root.add_child(stick)
	UiFont.place(stick, 0.0, 0.0, 0.46, 1.0)


func _build_special_cut_in() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 16
	add_child(layer)
	_special_cut_in = Control.new()
	_special_cut_in.visible = false
	_special_cut_in.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(_special_cut_in)
	layer.add_child(_special_cut_in)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.42)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(dim)
	_special_cut_in.add_child(dim)
	var band := PanelContainer.new()
	UiFont.place(band, 0.035, 0.31, 0.965, 0.69)
	band.add_theme_stylebox_override("panel", UiFont.style(Color("17130f"), Color("e6bd62"), 5, 4))
	_special_cut_in.add_child(band)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	band.add_child(row)
	_special_face = TextureRect.new()
	_special_face.custom_minimum_size = Vector2(172, 0)
	_special_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_special_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_special_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_special_face)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 8)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	_special_name = UiFont.label("", 28, UiFont.BRASS)
	_special_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_special_name)
	_special_quote = UiFont.label("", 34, UiFont.PAPER)
	_special_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_special_quote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_special_quote)


func _activate_special() -> void:
	if sim == null or not sim.begin_special():
		return
	_special_face.texture = _face_texture()
	_special_name.text = "%s  必殺技" % _who
	_special_quote.text = str(Balance.SPECIAL_QUOTES[_who])
	_special_cut_in.visible = true
	_special_cut_in.modulate.a = 0.0
	_special_cut_in.scale = Vector2(0.94, 0.94)
	_special_cut_in.pivot_offset = get_viewport_rect().size * 0.5
	if _special_tween != null and _special_tween.is_running():
		_special_tween.kill()
	_special_tween = create_tween()
	_special_tween.tween_property(_special_cut_in, "modulate:a", 1.0, 0.14)
	_special_tween.parallel().tween_property(_special_cut_in, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_special_tween.tween_interval(0.62)
	_special_tween.tween_callback(_resolve_special)
	_special_tween.tween_interval(0.42)
	_special_tween.tween_property(_special_cut_in, "modulate:a", 0.0, 0.24)
	_special_tween.tween_callback(func() -> void: _special_cut_in.visible = false)
	_update_special_hud()
	queue_redraw()


func _resolve_special() -> void:
	if not sim.resolve_special():
		return
	if _who == Balance.CHAR_MASSA:
		_special_motion_duration = 0.82
		_special_ring_left = _special_motion_duration
		_shake_left = 0.34
	elif _who == Balance.CHAR_TAKETCHI:
		_special_motion_duration = 0.72
		_shake_left = 0.2
	else:
		_special_motion_duration = 0.68
	_special_motion_left = _special_motion_duration
	_update_special_hud()
	queue_redraw()


func _update_special_hud() -> void:
	if sim == null or special_button == null:
		return
	special_gauge.value = sim.special_charge
	var percent := int(roundf(sim.special_charge))
	if sim.special_active_left > 0.0:
		special_button.text = "必殺技  %.1f秒" % sim.special_active_left
	elif sim.special_charge >= Balance.SPECIAL_GAUGE_MAX:
		special_button.text = "必殺技 発動 [Space]"
	else:
		special_button.text = "必殺技 %d%% [Space]" % percent
	special_button.disabled = not sim.can_activate_special()
	if special_button.disabled:
		special_button.modulate = Color(0.72, 0.72, 0.72, 0.88)
	else:
		special_button.modulate = Color.WHITE


func _face_texture() -> Texture2D:
	var portrait := UiFont.cropped(_portrait_path(_who))
	var face := AtlasTexture.new()
	face.atlas = portrait
	face.region = Rect2(portrait.get_width() * 0.12, 0.0, portrait.get_width() * 0.76, portrait.get_height() * 0.4)
	return face


func _build_choice() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	build_root = Control.new()
	build_root.visible = false
	build_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(build_root)
	UiFont.full_rect(build_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	UiFont.full_rect(dim)
	build_root.add_child(dim)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(col, 0.06, 0.12, 0.94, 0.90)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 16)
	build_root.add_child(col)

	var heading := UiFont.label("%s、どれを取る" % _who, 40, UiFont.PAPER)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(heading)
	var note := UiFont.label("時間切れは左", 22, UiFont.BRASS)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(note)

	card_row = HBoxContainer.new()
	card_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 22)
	card_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(card_row)

	timer_label = UiFont.label("20.0", 24, UiFont.PAPER)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(timer_label)
	var track := Control.new()
	track.custom_minimum_size = Vector2(0, 16)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(track)
	var back := ColorRect.new()
	back.color = Color(1, 1, 1, 0.2)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(back)
	track.add_child(back)
	timer_fill = ColorRect.new()
	timer_fill.color = UiFont.PINK
	timer_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_fill.anchor_left = 0
	timer_fill.anchor_top = 0
	timer_fill.anchor_bottom = 1
	timer_fill.anchor_right = 1
	track.add_child(timer_fill)


func _show_build() -> void:
	build_root.visible = true
	build_root.mouse_filter = Control.MOUSE_FILTER_STOP
	hint.visible = false
	stick.visible = false
	for child in card_row.get_children():
		child.queue_free()
	for index in sim.current_choices.size():
		card_row.add_child(_card(index, sim.current_choices[index]))
	_update_timer()


func _hide_build() -> void:
	build_shown = false
	build_root.visible = false
	build_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.visible = true
	stick.visible = true


func _card(index: int, id: String) -> Control:
	var current := int(sim.levels[id])
	var nxt := current + 1
	var accents: Array[Color] = [Color("2a241c"), Color("8c6840"), Color("6a4030")]
	var accent: Color = accents[index % accents.size()]
	var button := Button.new()
	button.custom_minimum_size = Vector2(360, 280)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", UiFont.style(UiFont.PAPER, accent, 5, 18))
	button.add_theme_stylebox_override("hover", UiFont.style(UiFont.YELLOW, accent, 5, 18))
	button.add_theme_stylebox_override("pressed", UiFont.style(Color("e6d3a8"), accent, 5, 18))
	button.add_theme_stylebox_override("focus", UiFont.style(UiFont.PAPER, accent, 5, 18))
	button.pressed.connect(func() -> void: _pick(index))

	var band := ColorRect.new()
	band.color = accent
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.anchor_right = 1.0
	band.offset_left = 8.0
	band.offset_top = 8.0
	band.offset_right = -8.0
	band.offset_bottom = 52.0
	button.add_child(band)
	var key := UiFont.label("%d" % (index + 1), 26, UiFont.PAPER)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key.position = Vector2(22, 14)
	button.add_child(key)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_top = 64
	box.offset_right = -18
	box.offset_bottom = -16
	box.add_theme_constant_override("separation", 10)
	button.add_child(box)

	var name := UiFont.label(Balance.UPGRADE_NAME[id], 28, UiFont.INK)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name.add_theme_constant_override("outline_size", 0)
	box.add_child(name)
	var level := UiFont.label("Lv %d  →  %d" % [current, nxt], 24, UiFont.PINK)
	level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level.add_theme_constant_override("outline_size", 0)
	box.add_child(level)
	var body := UiFont.label(Balance.upgrade_blurb(id, nxt), 22, UiFont.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("outline_size", 0)
	box.add_child(body)
	if index == 0:
		var mark := UiFont.label("時間切れ", 18, UiFont.NAVY)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.add_theme_constant_override("outline_size", 0)
		box.add_child(mark)
	return button


func _update_timer() -> void:
	var left := maxf(0.0, build_left)
	timer_label.text = "%.1f" % left
	timer_fill.anchor_right = clampf(left / Balance.BUILD_SELECT_SECONDS, 0.0, 1.0)


func _owned_builds() -> String:
	var line := ""
	for id in Balance.UPGRADES:
		var lv := int(sim.levels.get(id, 0))
		if lv <= 0:
			continue
		if line != "":
			line += "  "
		line += "%s %d" % [str(Balance.UPGRADE_SHORT[id]), lv]
	return line


func _pick(index: int) -> void:
	if sim == null or not sim.build_open:
		return
	var picked := ""
	if index >= 0 and index < sim.current_choices.size():
		picked = str(sim.current_choices[index])
	sim.choose(index)
	if picked != "" and _gain != null:
		_gain.text = str(Balance.UPGRADE_NAME[picked])
		_gain_left = 1.15
		_gain.modulate.a = 1.0
	if sim.finished:
		_go_result()
		return
	if sim.build_open:
		build_left = Balance.BUILD_SELECT_SECONDS
		_show_build()
	else:
		_hide_build()


func _portrait_path(who: String) -> String:
	if who == Balance.CHAR_TAKETCHI:
		return "res://assets/portraits/taketchi.png"
	if who == Balance.CHAR_KENNY:
		return "res://assets/portraits/kenny.png"
	return "res://assets/portraits/massa.png"


func _go_result() -> void:
	if _left:
		return
	_left = true
	SaveStore.commit_run(sim.make_summary())
	get_tree().change_scene_to_file("res://scenes/result.tscn")
