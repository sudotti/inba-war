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
	Vector2(453, 688),
	Vector2(1140, 646),
	Vector2(653, 784),
	Vector2(1040, 756),
]

const ART_NORMAL := "res://assets/battle/enemy_normal.png"
const ART_FAST := "res://assets/battle/enemy_fast.png"
const ART_TANK := "res://assets/battle/enemy_tank.png"
const ART_CONE := "res://assets/battle/cone.png"
const ART_NIMOTON := "res://assets/battle/boss_nimoton.png"
const ART_KASSEN := "res://assets/battle/boss_kassen.png"

var sim
var camera: Camera2D
var stick
var art_normal: Texture2D
var art_fast: Texture2D
var art_tank: Texture2D
var art_cone: Texture2D
var art_nimoton: Texture2D
var art_kassen: Texture2D

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
var _special_phase := ""
var _special_motion_left := 0.0
var _special_motion_duration := 0.0
var _special_tween: Tween
var _special_flash: ColorRect
var _special_flash_tween: Tween
var _boss_panel: PanelContainer
var _boss_name: Label
var _boss_hp: ProgressBar
var _boss_banner: PanelContainer
var _boss_banner_image: TextureRect
var _boss_banner_name: Label
var _boss_banner_action: Label
var _boss_banner_tween: Tween
var _seen_boss_alert := 0
var _compact_layout := false


func _ready() -> void:
	_who = SaveStore.playable_character()
	var viewport_size := get_viewport_rect().size
	_compact_layout = viewport_size.x < 1080.0 or viewport_size.y < 600.0
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
	art_nimoton = load(ART_NIMOTON)
	art_kassen = load(ART_KASSEN)
	_build_hud()
	_build_boss_hud()
	_build_stick()
	_build_choice()
	_follow_camera()


func _process(dt: float) -> void:
	_special_ring_left = maxf(0.0, _special_ring_left - dt)
	if _special_phase == "motion":
		_special_motion_left = maxf(0.0, _special_motion_left - dt)
		if _special_motion_left <= 0.0:
			_special_phase = ""
			sim.finish_special_motion()
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


func _draw_boss_telegraphs() -> void:
	for pool in sim.poison_pools:
		var fade := clampf(float(pool.life) / 0.8, 0.0, 1.0)
		var pulse := 0.8 + 0.2 * sin(_anim * 8.0)
		draw_circle(pool.pos, float(pool.radius), Color(0.37, 0.9, 0.12, 0.18 * fade))
		draw_arc(pool.pos, float(pool.radius) * pulse, 0.0, TAU, 48, Color(0.68, 1.0, 0.22, 0.72 * fade), 6.0, true)
	for projectile in sim.boss_projectiles:
		if projectile.kind == Balance.BOSS_VOLLEY:
			var flight := maxf(float(projectile.flight_seconds), 0.01)
			var progress := clampf(float(projectile.age) / flight, 0.0, 1.0)
			var height := sin(progress * PI) * 112.0
			var spot: Vector2 = projectile.pos + Vector2(0.0, -height)
			draw_set_transform(projectile.pos + Vector2(0.0, 8.0), 0.0, Vector2(1.0, 0.32))
			draw_circle(Vector2.ZERO, float(projectile.radius) * 1.25, Color(0.0, 0.0, 0.0, 0.3))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_circle(spot, float(projectile.radius), Color("f7f2dc"))
			draw_arc(spot, float(projectile.radius) * 0.72, _anim * 3.0, _anim * 3.0 + PI * 0.82, 24, Color("2389b8"), 5.0, true)
			draw_arc(spot, float(projectile.radius) * 0.48, _anim * 3.0 + PI, _anim * 3.0 + PI * 1.82, 24, Color("d64e45"), 4.0, true)
		else:
			var spot: Vector2 = projectile.pos + Vector2(0.0, sin(_anim * 15.0) * 5.0)
			draw_circle(spot, float(projectile.radius) * 1.6, Color(0.45, 1.0, 0.12, 0.22))
			draw_circle(spot, float(projectile.radius), Color("98ed38"))
			draw_circle(spot + Vector2(-5.0, -5.0), 5.0, Color("eaffab"))
	for actor in sim.enemies:
		if actor.kind == Balance.KIND_NIMOTON and actor.attack_state == "poison_windup":
			var target: Vector2 = actor.target_pos
			var pulse := 0.7 + 0.3 * sin(_anim * 18.0)
			draw_circle(target, 52.0 + pulse * 12.0, Color(0.4, 1.0, 0.08, 0.12))
			draw_arc(target, 68.0 + pulse * 14.0, 0.0, TAU, 48, Color(0.69, 1.0, 0.2, 0.88), 5.0, true)
			draw_line(actor.pos, target, Color(0.62, 1.0, 0.18, 0.38), 3.0, true)
		elif actor.kind == Balance.KIND_KASSEN and actor.attack_state == "volley_windup":
			var target: Vector2 = actor.target_pos
			draw_arc(target, 34.0 + sin(_anim * 16.0) * 8.0, 0.0, TAU, 40, Color(1.0, 0.78, 0.25, 0.9), 5.0, true)
			draw_line(actor.pos, target, Color(1.0, 0.9, 0.55, 0.68), 4.0, true)
		elif actor.kind == Balance.KIND_KASSEN and actor.attack_state == "kick_windup":
			var direction: Vector2 = (actor.target_pos - actor.pos).normalized()
			var side := direction.orthogonal() * 24.0
			for offset in [-1.0, 0.0, 1.0]:
				draw_line(actor.pos + side * offset, actor.target_pos + side * offset, Color(1.0, 0.4, 0.23, 0.72 - absf(offset) * 0.15), 8.0 - absf(offset) * 2.0, true)


func _draw() -> void:
	_draw_ground()
	_draw_special_aura()
	_draw_boss_telegraphs()
	if _special_ring_left > 0.0:
		var progress := 1.0 - _special_ring_left / Balance.SPECIAL_MASSA_MOTION_SECONDS
		var start := -PI * 0.5 + progress * TAU
		var radius := lerpf(84.0, Balance.SPECIAL_MASSA_RADIUS, progress)
		draw_arc(sim.player_pos, radius, start, start + TAU * 0.96, 112, Color(1.0, 0.84, 0.3, 0.94 * (1.0 - progress * 0.38)), 20.0, true)
		draw_arc(sim.player_pos, radius - 18.0, start + 0.7, start + TAU * 0.78, 96, Color(1.0, 0.97, 0.78, 0.78 * (1.0 - progress)), 7.0, true)
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
	order.append({"y": 421.0, "kind": "school"})
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
			elif actor.kind == Balance.KIND_NIMOTON:
				tex = art_nimoton
				max_h = 320.0
				max_w = 420.0
			elif actor.kind == Balance.KIND_KASSEN:
				tex = art_tank
				max_h = 232.0
				max_w = 250.0
			var head := _draw_posed(tex, foot, max_h, max_w, pose)
			if Balance.BOSS_KINDS.has(actor.kind):
				var boss_color := Color("baf05c") if actor.kind == Balance.KIND_NIMOTON else Color("ffd05d")
				draw_string_outline(UiFont.font(), Vector2(foot.x - 110.0, head - 12.0), str(Balance.BOSS_NAME[actor.kind]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 24, 5, Color(0, 0, 0, 0.95))
				draw_string(UiFont.font(), Vector2(foot.x - 110.0, head - 12.0), str(Balance.BOSS_NAME[actor.kind]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 24, boss_color)
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
	if _special_phase == "motion" and _special_motion_left > 0.0:
		var progress := 1.0 - _special_motion_left / _special_motion_duration
		var aim := _aim.normalized() if _aim.length() > 0.01 else Vector2.RIGHT
		frame = "hit"
		hop = 0.0
		sway = 0.0
		if _who == Balance.CHAR_MASSA:
			rot = TAU * 2.0 * progress
			hop = sin(progress * PI) * 24.0
			sx = 1.0 + sin(progress * PI) * 0.2
			sy = 1.0 - sin(progress * PI) * 0.14
		elif _who == Balance.CHAR_TAKETCHI:
			var strike := sin(progress * PI)
			rot = -0.16 + strike * 0.25
			lunge = aim * (8.0 + strike * 108.0)
			sx = 1.0 + strike * 0.16
			sy = 1.0 - strike * 0.13
		else:
			var beat := _anim * 42.0
			frame = "hit" if int(floor(beat)) % 2 == 0 else "wind"
			var kick := maxf(sin(beat * 0.5), 0.0)
			lunge = aim * (14.0 + kick * 76.0)
			rot = sin(beat) * 0.16
	var tint := Color.WHITE
	if _hurt_left > 0.0:
		tint = Color(1, 0.5, 0.46)
	elif float(sim.time) < Balance.INVULN_SECONDS:
		var pulse := 0.45 + 0.55 * sin(float(sim.time) * 18.0)
		tint = Color(0.78, 0.92, 1.0).lerp(Color.WHITE, pulse)
	return {"frame": frame, "hop": hop, "sway": sway, "face": _player_face, "tint": tint, "rot": rot, "sx": sx, "sy": sy, "lunge": lunge}


func _draw_special_aura() -> void:
	if _special_phase == "motion" and _special_motion_left > 0.0:
		var progress := 1.0 - _special_motion_left / _special_motion_duration
		var aim := _aim.normalized() if _aim.length() > 0.01 else Vector2.RIGHT
		if _who == Balance.CHAR_MASSA:
			for i in 3:
				var angle := _anim * 18.0 + float(i) * TAU / 3.0
				var radius := 86.0 + float(i) * 28.0 + progress * 116.0
				draw_arc(sim.player_pos, radius, angle, angle + PI * 0.82, 48, Color(1.0, 0.78 + float(i) * 0.06, 0.35, 0.9 - progress * 0.42), 13.0 - float(i) * 2.0, true)
		elif _who == Balance.CHAR_TAKETCHI:
			var radius := 48.0 + progress * 260.0
			draw_arc(sim.player_pos, radius, -0.25, TAU * 0.78, 72, Color(1.0, 0.72, 0.2, 0.8 * (1.0 - progress * 0.4)), 12.0, true)
			for i in 4:
				var offset := (float(i) - 1.5) * 15.0
				var side := aim.orthogonal() * offset
				draw_line(sim.player_pos + side + aim * 30.0, sim.player_pos + side + aim * (130.0 + progress * 180.0), Color(1.0, 0.91, 0.62, 0.75), 7.0 - float(i), true)
		else:
			var beat := _anim * 42.0
			for i in 6:
				var angle := beat * 0.62 + float(i) * TAU / 6.0
				var direction := aim.rotated(angle) * (55.0 + fposmod(float(i) * 37.0, 72.0))
				draw_line(sim.player_pos + direction, sim.player_pos + direction + direction.normalized() * 76.0, Color(0.55, 0.9, 1.0, 0.8), 5.0, true)
	if _who == Balance.CHAR_TAKETCHI and sim.special_active_left > 0.0:
		var pulse := 0.5 + 0.5 * sin(_anim * 12.0)
		draw_arc(sim.player_pos, 54.0 + pulse * 10.0, 0.0, TAU, 56, Color(1.0, 0.72, 0.2, 0.48 + pulse * 0.2), 5.0, true)
		for i in 8:
			var angle := float(i) * TAU / 8.0 + _anim * 0.8
			var direction := Vector2.from_angle(angle)
			draw_line(sim.player_pos + direction * 66.0, sim.player_pos + direction * (78.0 + pulse * 12.0), Color(1.0, 0.9, 0.56, 0.62), 3.0, true)
	if _who == Balance.CHAR_KENNY and sim.special_active_left > 0.0:
		var tex: Texture2D = _frames["hit"]
		for i in range(5, 0, -1):
			var alpha := 0.3 - float(i) * 0.045
			var pose := {
				"hop": 0.0,
				"rot": 0.0,
				"sx": _player_face,
				"sy": 1.0,
				"tint": Color(0.44, 0.86, 1.0, alpha),
				"lunge": -_aim.normalized() * float(i) * 32.0 + Vector2(0.0, sin(_anim * 24.0 - float(i)) * 10.0),
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
	elif actor.kind == Balance.KIND_NIMOTON:
		rate = 5.2
		amp = 13.0
		squash = 0.12
		lean = 0.08
	elif actor.kind == Balance.KIND_KASSEN:
		rate = 9.5
		amp = 18.0
		squash = 0.1
		lean = 0.16
	elif actor.kind == Balance.KIND_NIMOTON:
		rate = 5.2
		amp = 13.0
		squash = 0.12
		lean = 0.08
	elif actor.kind == Balance.KIND_KASSEN:
		rate = 9.5
		amp = 18.0
		squash = 0.1
		lean = 0.16
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
	if actor.kind == Balance.KIND_NIMOTON and actor.attack_state == "poison_windup":
		var charge := 0.5 + 0.5 * sin(float(actor.state_left) * 18.0)
		hop = 8.0 + charge * 15.0
		sx += charge * 0.16
	elif actor.kind == Balance.KIND_NIMOTON and actor.attack_state == "empower_windup":
		var pulse := 0.5 + 0.5 * sin(float(actor.state_left) * 16.0)
		sx += pulse * 0.18
		sy -= pulse * 0.12
	elif actor.kind == Balance.KIND_KASSEN and actor.attack_state == "volley_windup":
		hop = 16.0 + absf(sin(float(actor.state_left) * 11.0)) * 18.0
		rot = face * -0.18
	elif actor.kind == Balance.KIND_KASSEN and actor.attack_state == "kick_windup":
		var crouch := clampf(1.0 - float(actor.state_left) / 0.68, 0.0, 1.0)
		hop = 0.0
		sy += crouch * 0.18
		rot = face * (-0.12 - crouch * 0.2)
	elif actor.kind == Balance.KIND_KASSEN and actor.attack_state == "kick_dash":
		var dash: Vector2 = actor.target_pos - actor.pos
		if dash.length() > 0.01:
			lunge = dash.normalized() * 68.0
			rot = dash.angle() * 0.16
	if actor.kind == Balance.KIND_NIMOTON and actor.attack_state == "poison_windup":
		var charge := 0.5 + 0.5 * sin(float(actor.state_left) * 18.0)
		hop = 8.0 + charge * 15.0
		sx += charge * 0.16
	elif actor.kind == Balance.KIND_NIMOTON and actor.attack_state == "empower_windup":
		var pulse := 0.5 + 0.5 * sin(float(actor.state_left) * 16.0)
		sx += pulse * 0.18
		sy -= pulse * 0.12
	elif actor.kind == Balance.KIND_KASSEN and actor.attack_state == "volley_windup":
		hop = 16.0 + absf(sin(float(actor.state_left) * 11.0)) * 18.0
		rot = face * -0.18
	elif actor.kind == Balance.KIND_KASSEN and actor.attack_state == "kick_windup":
		var crouch := clampf(1.0 - float(actor.state_left) / 0.68, 0.0, 1.0)
		hop = 0.0
		sy += crouch * 0.18
		rot = face * (-0.12 - crouch * 0.2)
	elif actor.kind == Balance.KIND_KASSEN and actor.attack_state == "kick_dash":
		var dash: Vector2 = actor.target_pos - actor.pos
		if dash.length() > 0.01:
			lunge = dash.normalized() * 68.0
			rot = dash.angle() * 0.16
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
	elif float(actor.empowered_left) > 0.0:
		tint = Color(1.35, 1.18, 0.55)
	elif float(actor.empowered_left) > 0.0:
		tint = Color(1.35, 1.18, 0.55)
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
	var radius := float(puff.get("size", 3.0)) * (0.65 + (1.0 - fade) * 0.65)
	var spot := Vector2(puff.pos)
	var velocity: Vector2 = puff.vel
	if velocity.length() > 1.0:
		draw_line(spot, spot - velocity.normalized() * radius * 3.0, col, maxf(2.0, radius * 0.8), true)
	draw_circle(spot, radius, col)


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
	draw_set_transform(Vector2(800, 770), 0.0, Vector2(1.0, 0.48))
	draw_circle(Vector2.ZERO, 370.0, Color("3d5238"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var mow := Color(1, 1, 1, 0.045)
	var y := 20.0
	while y < Balance.FIELD_H:
		draw_line(Vector2(0, y), Vector2(Balance.FIELD_W, y), mow, 2.0)
		y += 48.0
	_draw_ellipse(Vector2(800, 770), 413.0, 206.0, TRACK, 4.0)
	_draw_ellipse(Vector2(800, 770), 313.0, 144.0, Color(1, 1, 1, 0.4), 2.0)
	var court := Rect2(600, 674, 400, 192)
	draw_rect(court, TRACK, false, 3.0)
	draw_line(Vector2(800, 674), Vector2(800, 866), Color(1, 1, 1, 0.45), 2.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(785, 421),
		Vector2(815, 421),
		Vector2(840, 1073),
		Vector2(760, 1073),
	]), DIRT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(793, 421),
		Vector2(807, 421),
		Vector2(821, 1073),
		Vector2(779, 1073),
	]), Color("d8bc88"))
	_draw_bed(Vector2(600, 688))
	_draw_bed(Vector2(1000, 674))
	var rim := Color("1e2a1c")
	draw_rect(Rect2(0, 0, Balance.FIELD_W, 26), rim, true)
	draw_rect(Rect2(0, Balance.FIELD_H - 26, Balance.FIELD_W, 26), rim, true)
	draw_rect(Rect2(0, 0, 26, Balance.FIELD_H), rim, true)
	draw_rect(Rect2(Balance.FIELD_W - 26, 0, 26, Balance.FIELD_H), rim, true)
	draw_rect(Rect2(520, 417, 560, 10), Color(0, 0, 0, 0.16), true)


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
	var left := 507.0
	var right := 1093.0
	var wall := 369.0
	var base := 421.0
	draw_rect(Rect2(left, wall, right - left, base - wall), Color("efe3c8"), true)
	draw_rect(Rect2(left, wall, right - left, base - wall), Color("2a241c"), false, 4.0)
	var peak := Vector2((left + right) * 0.5, 355.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(left - 26, wall + 8),
		peak,
		Vector2(right + 26, wall + 8),
	]), Color("3c4d6e"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(left - 26, wall + 8),
		peak,
		peak + Vector2(0, 10),
		Vector2(left - 6, wall + 13),
	]), Color("2d3b56"))
	var frame := Color("2a241c")
	var glass := Color("9aada8")
	for x in [660.0, 727.0, 880.0, 947.0, 1013.0]:
		draw_rect(Rect2(x, 381, 35, 25), frame, true)
		draw_rect(Rect2(x + 2, 383, 31, 20), glass, true)
		draw_line(Vector2(x + 17, 383), Vector2(x + 17, 402), frame, 2.0)
	draw_rect(Rect2(528, 381, 117, 22), Color("17324f"), true)
	draw_string(UiFont.font(), Vector2(543, 397), "印旛中学校", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f7f1e6"))
	draw_rect(Rect2(781, 391, 37, 30), Color("6d3b2c"), true)
	draw_rect(Rect2(781, 391, 37, 30), Color("2a241c"), false, 3.0)
	draw_circle(Vector2(811, 407), 2.0, Color("e2b43a"))


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
	hp_label.text = "体力  %d / %d" % [sim.player_hp, sim.player_max_hp]
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
	_sync_boss_hud()
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
	row.add_theme_constant_override("separation", 8 if _compact_layout else 18)
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
	chip.custom_minimum_size = Vector2(40, 40) if _compact_layout else Vector2(48, 48)
	chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(chip)

	var who_label := UiFont.label(_who, 18 if _compact_layout else 22, UiFont.YELLOW)
	who_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	who_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(who_label)

	time_label = UiFont.label("残り  3:00", 22 if _compact_layout else 30, UiFont.PAPER)
	score_label = UiFont.label("得点  0", 18 if _compact_layout else 22, UiFont.PAPER)
	coin_label = UiFont.label("コイン  0", 18 if _compact_layout else 22, UiFont.YELLOW)
	hp_label = UiFont.label("体力  100 / 100", 17 if _compact_layout else 20, UiFont.PAPER)
	for node in [time_label, hp_label, score_label, coin_label]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var hp_box := VBoxContainer.new()
	hp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_box.custom_minimum_size = Vector2(176, 0) if _compact_layout else Vector2(240, 0)
	hp_box.add_child(hp_label)
	var track := Control.new()
	track.custom_minimum_size = Vector2(160, 10) if _compact_layout else Vector2(220, 12)
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

	var motion := "鉄パイプ  広範囲攻撃"
	if _who == Balance.CHAR_TAKETCHI:
		motion = "拳  近距離・高威力"
	elif _who == Balance.CHAR_KENNY:
		motion = "キック  高速移動"
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
	UiFont.place(special_box, 0.76 if _compact_layout else 0.80, 0.70 if _compact_layout else 0.72, 0.98, 0.94 if _compact_layout else 0.91)
	root.add_child(special_box)
	special_gauge = ProgressBar.new()
	special_gauge.min_value = 0.0
	special_gauge.max_value = Balance.SPECIAL_GAUGE_MAX
	special_gauge.show_percentage = false
	special_gauge.custom_minimum_size = Vector2(0, 14)
	special_gauge.add_theme_stylebox_override("background", UiFont.style(Color(0.05, 0.05, 0.05, 0.88), Color("c8a456"), 2, 7))
	special_gauge.add_theme_stylebox_override("fill", UiFont.style(Color("d7b072"), Color("fff0c2"), 1, 6))
	special_box.add_child(special_gauge)
	special_button = UiFont.button("必殺技 0%", 16 if _compact_layout else 18)
	special_button.custom_minimum_size = Vector2(0, 54) if _compact_layout else Vector2(0, 64)
	special_button.pressed.connect(_activate_special)
	special_button.add_theme_stylebox_override("disabled", UiFont.style(Color("24201b"), Color("68583b"), 2, 12))
	special_button.add_theme_color_override("font_disabled_color", Color("c7b991"))
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
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 17
	add_child(flash_layer)
	_special_flash = ColorRect.new()
	_special_flash.color = Color.WHITE
	_special_flash.modulate.a = 0.0
	_special_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.full_rect(_special_flash)
	flash_layer.add_child(_special_flash)
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
	_special_phase = "intro"
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
	_special_tween.tween_interval(0.48)
	_special_tween.tween_property(_special_cut_in, "modulate:a", 0.0, 0.2)
	_special_tween.tween_callback(func() -> void: _special_cut_in.visible = false)
	_special_tween.tween_callback(_resolve_special)
	_update_special_hud()
	queue_redraw()


func _resolve_special() -> void:
	if not sim.resolve_special():
		return
	var motion_duration := Balance.special_motion_seconds(_who)
	_special_phase = "motion"
	_special_motion_duration = motion_duration
	_special_motion_left = motion_duration
	var primary := Color("f4c45a")
	if _who == Balance.CHAR_MASSA:
		_special_ring_left = motion_duration
		_shake_left = 0.46
		_special_burst(Color("fff0a8"), Color("f08a36"), 48, 160.0, 520.0)
	elif _who == Balance.CHAR_TAKETCHI:
		primary = Color("ffd15a")
		_shake_left = 0.34
		_special_burst(Color("fff1a8"), Color("e77a32"), 36, 90.0, 360.0)
	else:
		primary = Color("68dcff")
		_shake_left = 0.18
		_special_burst(Color("e4faff"), Color("58cfff"), 42, 120.0, 460.0)
	_special_flash.color = primary
	_special_flash.modulate.a = 0.42
	if _special_flash_tween != null and _special_flash_tween.is_running():
		_special_flash_tween.kill()
	_special_flash_tween = create_tween()
	_special_flash_tween.tween_property(_special_flash, "modulate:a", 0.0, 0.18)
	_update_special_hud()
	queue_redraw()


func _special_burst(near_color: Color, far_color: Color, count: int, min_speed: float, max_speed: float) -> void:
	for i in count:
		var angle := float(i) / float(count) * TAU + randf_range(-0.08, 0.08)
		var life := randf_range(0.34, 0.72)
		_puffs.append({
			"pos": sim.player_pos + Vector2(0.0, -28.0),
			"vel": Vector2.from_angle(angle) * randf_range(min_speed, max_speed),
			"life": life,
			"max": life,
			"color": near_color.lerp(far_color, randf()),
			"size": randf_range(4.0, 10.0),
		})


func _update_special_hud() -> void:
	if sim == null or special_button == null:
		return
	special_gauge.value = sim.special_charge
	var percent := int(roundf(sim.special_charge))
	if sim.special_active_left > 0.0:
		special_button.text = "必殺技  %.1f秒" % sim.special_active_left
	elif sim.special_charge >= Balance.SPECIAL_GAUGE_MAX:
		special_button.text = "必殺技 発動" if _compact_layout else "必殺技 発動 [Space]"
	else:
		special_button.text = "必殺技 %d%%" % percent if _compact_layout else "必殺技 %d%% [Space]" % percent
	special_button.disabled = not sim.can_activate_special()
	special_button.modulate = Color.WHITE


func _build_boss_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	UiFont.full_rect(root)
	_boss_panel = PanelContainer.new()
	_boss_panel.visible = false
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiFont.place(_boss_panel, 0.31, 0.105, 0.69, 0.19)
	_boss_panel.add_theme_stylebox_override("panel", UiFont.style(Color("17130f"), Color("dc5946"), 3, 5))
	root.add_child(_boss_panel)
	var boss_col := VBoxContainer.new()
	boss_col.add_theme_constant_override("separation", 3)
	_boss_panel.add_child(boss_col)
	_boss_name = UiFont.label("", 18, UiFont.PAPER)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_col.add_child(_boss_name)
	_boss_hp = ProgressBar.new()
	_boss_hp.min_value = 0.0
	_boss_hp.max_value = 100.0
	_boss_hp.show_percentage = false
	_boss_hp.custom_minimum_size = Vector2(0, 12)
	_boss_hp.add_theme_stylebox_override("background", UiFont.style(Color("28201d"), Color("754339"), 1, 4))
	_boss_hp.add_theme_stylebox_override("fill", UiFont.style(Color("e34c39"), Color("ffb55a"), 1, 3))
	boss_col.add_child(_boss_hp)
	_boss_banner = PanelContainer.new()
	_boss_banner.visible = false
	_boss_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_banner.pivot_offset = Vector2(640, 180)
	UiFont.place(_boss_banner, 0.22, 0.2, 0.78, 0.52)
	_boss_banner.add_theme_stylebox_override("panel", UiFont.style(Color("15120f"), Color("e0a448"), 5, 6))
	root.add_child(_boss_banner)
	var banner_row := HBoxContainer.new()
	banner_row.add_theme_constant_override("separation", 20)
	_boss_banner.add_child(banner_row)
	_boss_banner_image = TextureRect.new()
	_boss_banner_image.custom_minimum_size = Vector2(150, 150)
	_boss_banner_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_boss_banner_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_boss_banner_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_row.add_child(_boss_banner_image)
	var banner_copy := VBoxContainer.new()
	banner_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_copy.add_theme_constant_override("separation", 8)
	banner_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner_row.add_child(banner_copy)
	_boss_banner_name = UiFont.label("", 34, UiFont.PAPER)
	banner_copy.add_child(_boss_banner_name)
	_boss_banner_action = UiFont.label("", 22, UiFont.BRASS)
	_boss_banner_action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_copy.add_child(_boss_banner_action)
	_seen_boss_alert = sim.boss_alert_serial


func _sync_boss_hud() -> void:
	var boss = sim.current_boss()
	_boss_panel.visible = boss != null
	if boss != null:
		var name := str(Balance.BOSS_NAME[boss.kind])
		_boss_name.text = "ボス  %s" % name
		_boss_hp.value = 100.0 * float(boss.hp) / float(maxi(boss.max_hp, 1))
	if sim.boss_alert_serial == _seen_boss_alert:
		return
	_seen_boss_alert = sim.boss_alert_serial
	_show_boss_banner(sim.boss_alert_kind)


func _show_boss_banner(kind: String) -> void:
	var nimoton := kind == Balance.KIND_NIMOTON
	_boss_banner_image.texture = UiFont.cropped(ART_NIMOTON) if nimoton else _kassen_portrait()
	_boss_banner_name.text = "%s、乱入" % str(Balance.BOSS_NAME[kind])
	_boss_banner_action.text = "毒液 / 群れを強化" if nimoton else "バレーアタック / 強烈な蹴り"
	var edge := Color("a9eb4b") if nimoton else Color("f3ba47")
	_boss_banner.add_theme_stylebox_override("panel", UiFont.style(Color("15120f"), edge, 5, 6))
	_boss_banner.visible = true
	_boss_banner.modulate.a = 0.0
	_boss_banner.scale = Vector2(0.88, 0.88)
	if _boss_banner_tween != null and _boss_banner_tween.is_running():
		_boss_banner_tween.kill()
	_boss_banner_tween = create_tween()
	_boss_banner_tween.tween_property(_boss_banner, "modulate:a", 1.0, 0.16)
	_boss_banner_tween.parallel().tween_property(_boss_banner, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_boss_banner_tween.tween_interval(1.8)
	_boss_banner_tween.tween_property(_boss_banner, "modulate:a", 0.0, 0.25)
	_boss_banner_tween.tween_callback(func() -> void: _boss_banner.visible = false)


func _kassen_portrait() -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = art_kassen
	atlas.region = Rect2(286.0, 190.0, 452.0, 640.0)
	return atlas


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

	var heading := UiFont.label("強化選択", 32 if _compact_layout else 40, UiFont.PAPER)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(heading)
	var note := UiFont.label("時間内に選択 / 期限後は左端", 18 if _compact_layout else 22, UiFont.BRASS)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(note)

	card_row = HBoxContainer.new()
	card_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 8 if _compact_layout else 22)
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
	var viewport_size := get_viewport_rect().size
	var card_width := 360.0
	var card_height := 280.0
	if _compact_layout:
		card_width = maxf(150.0, minf(240.0, (viewport_size.x * 0.82 - 16.0) / 3.0))
		card_height = clampf(viewport_size.y * 0.52, 200.0, 260.0)
	button.custom_minimum_size = Vector2(card_width, card_height)
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

	var name := UiFont.label(Balance.UPGRADE_NAME[id], 23 if _compact_layout else 28, UiFont.INK)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name.add_theme_constant_override("outline_size", 0)
	box.add_child(name)
	var level := UiFont.label("レベル %d  →  %d" % [current, nxt], 19 if _compact_layout else 24, UiFont.PINK)
	level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level.add_theme_constant_override("outline_size", 0)
	box.add_child(level)
	var body := UiFont.label(Balance.upgrade_blurb(id, nxt), 17 if _compact_layout else 22, UiFont.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("outline_size", 0)
	box.add_child(body)
	if index == 0:
		var mark := UiFont.label("自動選択", 18, UiFont.NAVY)
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
