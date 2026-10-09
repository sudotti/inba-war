extends RefCounted
class_name BattleSim

const Balance = preload("res://scripts/balance.gd")

class Actor extends RefCounted:
	var id: int
	var kind: String
	var pos: Vector2
	var hp: int
	var max_hp: int
	var speed: float
	var touch: int
	var radius: float
	var stun: float
	var knockback_scale: float
	var base_speed: float
	var base_touch: int
	var empowered_left: float = 0.0
	var phase: float = 0.0
	var attack_timer: float = 0.0
	var support_timer: float = 0.0
	var attack_state: String = ""
	var state_left: float = 0.0
	var target_pos: Vector2 = Vector2.ZERO
	var dash_hit: bool = false


class Coin extends RefCounted:
	var id: int
	var pos: Vector2


class Cone extends RefCounted:
	var pos: Vector2
	var radius: float


class BossProjectile extends RefCounted:
	var kind: String
	var pos: Vector2
	var velocity: Vector2
	var radius: float
	var damage: int
	var life: float
	var age: float = 0.0
	var flight_seconds: float


class PoisonPool extends RefCounted:
	var pos: Vector2
	var radius: float
	var life: float
	var tick_left: float = 0.0


var boss_projectiles: Array[BossProjectile] = []
var poison_pools: Array[PoisonPool] = []
var boss_alert_serial: int = 0
var boss_alert_kind: String = ""
var enemy_seen_this_run: Dictionary = {}
var boss_spawn_time: float = 0.0
var boss_spawn_attempted: bool = false
var boss_damage_lock: float = 0.0


var character_id: String = Balance.CHAR_MASSA
var time: float = 0.0
var player_pos: Vector2 = Balance.START
var player_hp: int = 100
var player_max_hp: int = 100
var player_radius: float = 22.0
var base_speed: float = 155.0
var attack_interval: float = 1.0
var attack_radius: float = 136.0
var _base_interval: float = 1.0
var _base_radius: float = 136.0
var base_attack: int = 14
var base_knockback: float = 180.0
var damage_taken_scale: float = 1.0
var special_charge: float = 0.0
var special_active_left: float = 0.0
var special_motion_left: float = 0.0
var special_serial: int = 0
var special_pending: bool = false
var special_resolved: bool = false

var enemies: Array[Actor] = []
var coins: Array[Coin] = []
var cones: Array[Cone] = []

var levels: Dictionary = {}
var kills: int = 0
var kills_of: Dictionary = {
	Balance.KIND_NORMAL: 0,
	Balance.KIND_FAST: 0,
	Balance.KIND_TANK: 0,
	Balance.KIND_NIMOTON: 0,
	Balance.KIND_KASSEN: 0,
}
var score: int = 0
var coin_value: float = 0.0

var finished: bool = false
var outcome: String = ""
var build_open: bool = false
var current_choices: Array = []

var view_rect: Rect2 = Rect2()
var attacks_enabled: bool = true
var contact_enabled: bool = true
var spawns_enabled: bool = true
var regular_spawns_enabled: bool = true
var hurt_serial: int = 0
var pulse_serial: int = 0
var pulse_age: float = 10.0
var attack_serial: int = 0
var max_alive_seen: int = 0

var rng := RandomNumberGenerator.new()

var _next_id: int = 1
var _attack_acc: float = 0.0
var _puri_acc: float = 0.0
var _spawn_acc: float = 0.0
var _next_hurt: float = Balance.INVULN_SECONDS
var _next_build_index: int = 0
var _pending_offers: int = 0
var _kaiju_next: float = 75.0


func _init(who: String = Balance.CHAR_MASSA) -> void:
	character_id = who
	var stats: Dictionary = Balance.CHARACTERS[who]
	player_max_hp = int(stats.max_hp)
	player_hp = player_max_hp
	player_radius = float(stats.radius)
	base_speed = float(stats.speed)
	_base_interval = float(stats.attack_interval)
	_base_radius = float(stats.attack_radius)
	attack_interval = _base_interval
	attack_radius = _base_radius
	base_attack = int(stats.attack)
	base_knockback = float(stats.knockback)
	damage_taken_scale = float(stats.damage_taken_scale)
	player_pos = Balance.START
	for id in Balance.UPGRADES:
		levels[id] = 0
	for point in Balance.CONE_POINTS:
		var cone := Cone.new()
		cone.pos = point
		cone.radius = Balance.CONE_RADIUS
		cones.append(cone)
	view_rect = Rect2(player_pos - Vector2(640, 360), Vector2(1280, 720))
	rng.randomize()
	boss_spawn_time = rng.randf_range(35.0, 155.0)


func shown_coins() -> int:
	return int(floor(coin_value))


func speed_now() -> float:
	return Balance.move_speed(base_speed, int(levels[Balance.KENKYAKU]))


func attack_ratio() -> float:
	var interval := attack_interval_now()
	if interval <= 0.0:
		return 0.0
	return clampf(_attack_acc / interval, 0.0, 1.0)


func attack_interval_now() -> float:
	if special_active_left > 0.0:
		if character_id == Balance.CHAR_TAKETCHI:
			return maxf(0.2, attack_interval * Balance.SPECIAL_TAKETCHI_ATTACK_SCALE)
		if character_id == Balance.CHAR_KENNY:
			return Balance.SPECIAL_KENNY_ATTACK_INTERVAL
	return attack_interval


func attack_damage_now() -> int:
	var damage := Balance.attack_damage(base_attack, int(levels[Balance.BUTTO]))
	if special_active_left > 0.0 and character_id == Balance.CHAR_TAKETCHI:
		damage = floori(float(damage) * Balance.SPECIAL_TAKETCHI_DAMAGE_SCALE)
	return damage


func can_activate_special() -> bool:
	return (
		not finished
		and not build_open
		and not special_pending
		and special_charge >= Balance.SPECIAL_GAUGE_MAX
		and special_active_left <= 0.0
	)


func begin_special() -> bool:
	if not can_activate_special():
		return false
	special_charge = 0.0
	special_serial += 1
	special_pending = true
	special_resolved = false
	return true


func resolve_special() -> bool:
	if not special_pending or special_resolved or finished:
		return false
	special_resolved = true
	special_motion_left = Balance.special_motion_seconds(character_id)
	if character_id == Balance.CHAR_MASSA:
		_special_sweep()
	elif character_id == Balance.CHAR_TAKETCHI:
		special_active_left = Balance.SPECIAL_TAKETCHI_SECONDS
	else:
		special_active_left = Balance.SPECIAL_KENNY_SECONDS
	return true


func finish_special_motion() -> bool:
	if not special_pending or not special_resolved:
		return false
	special_pending = false
	special_resolved = false
	special_motion_left = 0.0
	return true


func activate_special() -> bool:
	if not begin_special():
		return false
	if not resolve_special():
		return false
	return finish_special_motion()


func step(dt: float, move_dir: Vector2) -> void:
	if finished or build_open or special_pending or dt <= 0.0:
		return
	var left := dt
	var guard := 0
	while left > 0.000001 and not finished and not build_open and guard < 8000:
		guard += 1
		var slice := minf(0.05, left)
		_step_slice(slice, move_dir)
		left -= slice


func _step_slice(dt: float, move_dir: Vector2) -> void:
	time += dt
	boss_damage_lock = maxf(0.0, boss_damage_lock - dt)
	_move_player(dt, move_dir)
	_move_enemies(dt)
	_move_boss_projectiles(dt)
	_update_poison_pools(dt)
	_move_coins(dt)
	_attacks(dt)
	special_active_left = maxf(0.0, special_active_left - dt)
	special_motion_left = maxf(0.0, special_motion_left - dt)
	if finished:
		return
	_puritora(dt)
	if finished:
		return
	_hurts()
	if finished:
		return
	_despawn_far()
	if _open_build_if_needed():
		return
	if spawns_enabled and regular_spawns_enabled:
		_update_spawns(dt)
	if spawns_enabled:
		_update_kaiju()
		_update_boss_raid()
	if _open_build_if_needed():
		return
	if time >= Balance.ROUND_SECONDS and not build_open:
		_end("clear")


func _apply_build_stats() -> void:
	var maai := int(levels.get(Balance.MAAI, 0))
	var renda := int(levels.get(Balance.RENDA, 0))
	attack_radius = _base_radius * (1.0 + 0.14 * float(maai))
	attack_interval = maxf(0.34, _base_interval * (1.0 - 0.08 * float(renda)))


func choose(index: int) -> void:
	if not build_open or finished:
		return
	if current_choices.is_empty():
		build_open = false
		return
	if index < 0 or index >= current_choices.size():
		index = 0
	var id: String = current_choices[index]
	levels[id] = int(levels[id]) + 1
	_apply_build_stats()
	if id == Balance.ONIGIRI:
		player_max_hp += 20
		player_hp = mini(player_max_hp, player_hp + 20)
	if id == Balance.PURITORA and int(levels[id]) == 1:
		_puri_acc = 0.0
	build_open = false
	current_choices = []
	if _open_build_if_needed():
		return
	if time >= Balance.ROUND_SECONDS:
		_end("clear")


func make_summary() -> Dictionary:
	return {
		"score": score,
		"kills": kills,
		"kills_normal": int(kills_of[Balance.KIND_NORMAL]),
		"kills_fast": int(kills_of[Balance.KIND_FAST]),
		"kills_tank": int(kills_of[Balance.KIND_TANK]),
		"kills_nimoton": int(kills_of[Balance.KIND_NIMOTON]),
		"kills_kassen": int(kills_of[Balance.KIND_KASSEN]),
		"enemy_seen": enemy_seen_this_run.keys(),
		"coins": shown_coins(),
		"outcome": outcome,
		"character": character_id,
		"time": time,
	}


func debug_place(kind: String, pos: Vector2, hp: int, speed: float) -> Actor:
	var actor := _make_actor(kind, time)
	actor.pos = pos
	actor.hp = hp
	actor.max_hp = hp
	actor.speed = speed
	enemies.append(actor)
	max_alive_seen = maxi(max_alive_seen, enemies.size())
	return actor


func debug_count_kills(kind: String, count: int) -> void:
	for _i in count:
		_register_kill(kind)
	_open_build_if_needed()


func _move_player(dt: float, move_dir: Vector2) -> void:
	var direction := move_dir
	if direction.length() > 1.0:
		direction = direction.normalized()
	player_pos = _resolve(player_pos + direction * speed_now() * dt, player_radius)


func _move_enemies(dt: float) -> void:
	for actor in enemies:
		if actor.stun > 0.0:
			actor.stun = maxf(0.0, actor.stun - dt)
			continue
		if actor.empowered_left > 0.0:
			actor.empowered_left = maxf(0.0, actor.empowered_left - dt)
			if actor.empowered_left <= 0.0:
				actor.speed = actor.base_speed
				actor.touch = actor.base_touch
		if Balance.BOSS_KINDS.has(actor.kind):
			actor.phase += dt
			_move_boss(actor, dt)
			continue
		var toward := player_pos - actor.pos
		if toward.length() < 0.001:
			continue
		actor.pos = _resolve(actor.pos + toward.normalized() * actor.speed * dt, actor.radius)


func current_boss():
	for actor in enemies:
		if Balance.BOSS_KINDS.has(actor.kind):
			return actor
	return null


func _move_boss(actor: Actor, dt: float) -> void:
	if actor.attack_state == "kick_dash":
		var dash := actor.target_pos - actor.pos
		if dash.length() > 0.001:
			actor.pos = _resolve(actor.pos + dash.normalized() * 590.0 * dt, actor.radius)
		if not actor.dash_hit and actor.pos.distance_to(player_pos) <= actor.radius + player_radius + 34.0:
			actor.dash_hit = true
			_boss_hit_player(38)
			var away := player_pos - actor.pos
			if away.length() > 0.001:
				player_pos = _resolve(player_pos + away.normalized() * 86.0, player_radius)
		actor.state_left -= dt
		if actor.state_left <= 0.0:
			actor.attack_state = ""
			actor.attack_timer = 1.25
		return
	if actor.attack_state != "":
		actor.state_left -= dt
		if actor.state_left <= 0.0:
			_resolve_boss_action(actor)
		return
	actor.attack_timer -= dt
	var distance := actor.pos.distance_to(player_pos)
	if actor.kind == Balance.KIND_NIMOTON:
		actor.support_timer -= dt
		if actor.support_timer <= 0.0:
			actor.attack_state = "empower_windup"
			actor.state_left = 0.9
			return
		if actor.attack_timer <= 0.0:
			actor.attack_state = "poison_windup"
			actor.target_pos = player_pos
			actor.state_left = 0.72
			return
		_move_boss_range(actor, 250.0, dt)
		return
	if actor.attack_timer <= 0.0:
		actor.target_pos = player_pos
		if distance < 340.0 and rng.randf() < 0.58:
			actor.attack_state = "kick_windup"
			actor.state_left = 0.68
		else:
			actor.attack_state = "volley_windup"
			actor.state_left = 0.82
		return
	_move_boss_range(actor, 290.0, dt)


func _move_boss_range(actor: Actor, desired_range: float, dt: float) -> void:
	var toward := player_pos - actor.pos
	if toward.length() < 0.001:
		return
	var direction := toward.normalized()
	var distance := toward.length()
	var move := Vector2.ZERO
	if distance > desired_range + 28.0:
		move = direction
	elif distance < desired_range - 34.0:
		move = -direction
	else:
		move = direction.orthogonal() * signf(sin(actor.phase * 1.7))
	actor.pos = _resolve(actor.pos + move * actor.speed * dt, actor.radius)


func _resolve_boss_action(actor: Actor) -> void:
	match actor.attack_state:
		"poison_windup":
			_launch_boss_projectile(actor, Balance.BOSS_POISON, actor.target_pos, 20, 285.0)
			actor.attack_timer = 2.4
		"empower_windup":
			_empower_nearby(actor)
			actor.support_timer = 7.2
			actor.attack_timer = 1.4
		"volley_windup":
			_launch_boss_projectile(actor, Balance.BOSS_VOLLEY, actor.target_pos, 27, 365.0)
			actor.attack_timer = 2.7
		"kick_windup":
			actor.attack_state = "kick_dash"
			actor.state_left = 0.52
			actor.dash_hit = false
			return
	actor.attack_state = ""


func _empower_nearby(boss: Actor) -> void:
	for actor in enemies:
		if actor == boss or Balance.BOSS_KINDS.has(actor.kind):
			continue
		if actor.kind != Balance.KIND_NORMAL and actor.kind != Balance.KIND_FAST:
			continue
		if actor.pos.distance_to(boss.pos) > 560.0:
			continue
		if actor.empowered_left <= 0.0:
			actor.speed = actor.base_speed * 1.55
			actor.touch = ceili(float(actor.base_touch) * 1.5)
		actor.empowered_left = 8.0


func _launch_boss_projectile(boss: Actor, kind: String, target: Vector2, damage: int, speed: float) -> void:
	var projectile := BossProjectile.new()
	projectile.kind = kind
	projectile.pos = boss.pos + Vector2(0.0, -boss.radius * 0.35)
	projectile.radius = 20.0 if kind == Balance.BOSS_VOLLEY else 18.0
	projectile.damage = damage
	var direction := target - projectile.pos
	if direction.length() < 0.001:
		direction = Vector2.RIGHT
	projectile.velocity = direction.normalized() * speed
	projectile.flight_seconds = maxf(0.35, direction.length() / speed)
	projectile.life = projectile.flight_seconds + 0.16
	boss_projectiles.append(projectile)


func _move_boss_projectiles(dt: float) -> void:
	var keep: Array[BossProjectile] = []
	for projectile in boss_projectiles:
		projectile.age += dt
		projectile.life -= dt
		projectile.pos += projectile.velocity * dt
		var hit := projectile.pos.distance_to(player_pos) <= projectile.radius + player_radius
		if hit:
			_boss_hit_player(projectile.damage)
			if projectile.kind == Balance.BOSS_POISON:
				_add_poison_pool(projectile.pos)
		elif projectile.life <= 0.0 and projectile.kind == Balance.BOSS_POISON:
			_add_poison_pool(projectile.pos)
		if not hit and projectile.life > 0.0:
			keep.append(projectile)
	boss_projectiles = keep


func _add_poison_pool(pos: Vector2) -> void:
	var pool := PoisonPool.new()
	pool.pos = Vector2(pos)
	pool.radius = 86.0
	pool.life = 5.5
	pool.tick_left = 0.2
	poison_pools.append(pool)


func _update_poison_pools(dt: float) -> void:
	var keep: Array[PoisonPool] = []
	for pool in poison_pools:
		pool.life -= dt
		pool.tick_left -= dt
		if pool.life > 0.0 and player_pos.distance_to(pool.pos) <= pool.radius + player_radius and pool.tick_left <= 0.0:
			_boss_hit_player(4)
			pool.tick_left = 0.7
		if pool.life > 0.0:
			keep.append(pool)
	poison_pools = keep


func _boss_hit_player(raw_damage: int) -> void:
	if not contact_enabled or time < Balance.INVULN_SECONDS or boss_damage_lock > 0.0 or finished:
		return
	boss_damage_lock = 0.42
	var damage := Balance.apply_damage_scale(raw_damage, damage_taken_scale)
	player_hp -= damage
	hurt_serial += 1
	if player_hp <= 0:
		player_hp = 0
		_pending_offers = 0
		build_open = false
		current_choices = []
		_end("down")


func _move_coins(dt: float) -> void:
	var magnet := Balance.magnet_radius(int(levels[Balance.KANE]))
	var keep: Array[Coin] = []
	for coin in coins:
		var toward := player_pos - coin.pos
		var dist := toward.length()
		if dist <= Balance.PICKUP_RADIUS:
			_collect_coin()
			continue
		if dist <= magnet and dist > 0.001:
			var step_len := Balance.COIN_PULL_SPEED * dt
			if step_len >= dist - Balance.PICKUP_RADIUS:
				_collect_coin()
				continue
			coin.pos += toward / dist * step_len
		keep.append(coin)
	coins = keep


func _collect_coin() -> void:
	coin_value += Balance.coin_gain(1, int(levels[Balance.OKOZUKAI]))


func _attacks(dt: float) -> void:
	_attack_acc += dt
	var guard := 0
	while _attack_acc >= attack_interval_now() and not finished and guard < 32:
		guard += 1
		_attack_acc -= attack_interval_now()
		if attacks_enabled:
			_attack()


func _attack() -> void:
	attack_serial += 1
	var damage := attack_damage_now()
	var blast := base_knockback * (1.0 + 0.15 * float(levels[Balance.BUTTO]))
	var reached: Array[Actor] = []
	for actor in enemies:
		# 射程の円の中は、敵の中心までの距離。
		if player_pos.distance_to(actor.pos) <= attack_radius:
			reached.append(actor)
	var dead: Array[Actor] = []
	for actor in reached:
		actor.hp -= damage
		if actor.hp <= 0:
			dead.append(actor)
		elif actor.stun <= 0.0:
			_knockback(actor, blast)
	for actor in dead:
		_kill(actor)


func _special_sweep() -> void:
	var damage := floori(float(attack_damage_now()) * Balance.SPECIAL_MASSA_DAMAGE_SCALE)
	var reached: Array[Actor] = []
	for actor in enemies:
		if player_pos.distance_to(actor.pos) <= Balance.SPECIAL_MASSA_RADIUS:
			reached.append(actor)
	var dead: Array[Actor] = []
	for actor in reached:
		actor.hp -= damage
		if actor.hp <= 0:
			dead.append(actor)
		elif actor.stun <= 0.0:
			_knockback(actor, Balance.SPECIAL_MASSA_KNOCKBACK)
	for actor in dead:
		_kill(actor)


func _puritora(dt: float) -> void:
	pulse_age += dt
	var level := int(levels[Balance.PURITORA])
	if level <= 0:
		return
	_puri_acc += dt
	var interval := Balance.puritora_interval(level)
	var guard := 0
	while _puri_acc >= interval and guard < 32:
		guard += 1
		_puri_acc -= interval
		_pulse()


func _pulse() -> void:
	pulse_serial += 1
	pulse_age = 0.0
	var radius := Balance.puritora_radius(int(levels[Balance.PURITORA]))
	for actor in enemies:
		if player_pos.distance_to(actor.pos) > radius:
			continue
		if Balance.BOSS_KINDS.has(actor.kind):
			actor.stun = 0.35
		elif actor.kind == Balance.KIND_TANK:
			actor.stun = Balance.STUN_TANK_SECONDS
		else:
			actor.stun = Balance.STUN_SECONDS


func _hurts() -> void:
	var guard := 0
	while time >= _next_hurt and not finished and guard < 64:
		guard += 1
		if not contact_enabled:
			_next_hurt += Balance.HURT_INTERVAL
			continue
		_contact()


func _contact() -> void:
	var raw := _contact_raw()
	var dealt := Balance.apply_damage_scale(raw, damage_taken_scale)
	_next_hurt += Balance.HURT_INTERVAL
	if dealt <= 0:
		return
	hurt_serial += 1
	player_hp -= dealt
	if player_hp <= 0:
		player_hp = 0
		_pending_offers = 0
		build_open = false
		current_choices = []
		_end("down")


func _contact_raw() -> int:
	var amounts: Array[int] = []
	for actor in enemies:
		if actor.stun > 0.0:
			continue
		var reach := player_radius + actor.radius
		if player_pos.distance_to(actor.pos) <= reach:
			amounts.append(actor.touch)
	amounts.sort()
	var total := 0
	var n := mini(3, amounts.size())
	for i in n:
		total += amounts[amounts.size() - 1 - i]
	return total


func _despawn_far() -> void:
	var keep: Array[Actor] = []
	for actor in enemies:
		if player_pos.distance_to(actor.pos) > Balance.DESPAWN_DISTANCE:
			continue
		keep.append(actor)
	enemies = keep


func _update_spawns(dt: float) -> void:
	var t := time - dt
	var acc := _spawn_acc
	var spins := 0
	while t < time and spins < 10000:
		spins += 1
		if t >= Balance.ROUND_SECONDS:
			break
		var interval: float = float(Balance.spawn_profile(t).interval)
		if acc >= interval:
			acc = 0.0
			_spawn_scheduled(t)
			continue
		var need := interval - acc
		var room := time - t
		if need > room:
			acc += room
			t = time
			break
		t += need
		acc = 0.0
		if t <= Balance.ROUND_SECONDS:
			_spawn_scheduled(t)
	_spawn_acc = acc


func _spawn_scheduled(elapsed: float) -> void:
	if enemies.size() >= Balance.MAX_ALIVE:
		return
	if elapsed >= Balance.ROUND_SECONDS:
		return
	var roll := rng.randf()
	var kind := Balance.kind_for_roll(elapsed, roll)
	_spawn_kind(kind, elapsed)


func _update_kaiju() -> void:
	while _kaiju_next <= time and _kaiju_next <= Balance.ROUND_SECONDS:
		var when := _kaiju_next
		_kaiju_next += 30.0
		if enemies.size() >= Balance.MAX_ALIVE:
			continue
		if _kaiju_alive():
			continue
		_spawn_kind(Balance.KIND_TANK, when)


func _update_boss_raid() -> void:
	if boss_spawn_attempted or time < boss_spawn_time:
		return
	if enemies.size() >= Balance.MAX_ALIVE:
		boss_spawn_time = time + 5.0
		return
	boss_spawn_attempted = true
	if rng.randf() >= Balance.BOSS_SPAWN_CHANCE:
		return
	var kind := Balance.KIND_NIMOTON if rng.randf() < 0.5 else Balance.KIND_KASSEN
	_spawn_kind(kind, time)


func _spawn_kind(kind: String, elapsed: float) -> bool:
	if enemies.size() >= Balance.MAX_ALIVE:
		return false
	var stats: Dictionary = Balance.ENEMIES[kind]
	var found: Array = _find_spawn(float(stats.radius))
	if found.is_empty():
		return false
	var actor := _make_actor(kind, elapsed)
	actor.pos = found[0]
	enemies.append(actor)
	enemy_seen_this_run[kind] = true
	if Balance.BOSS_KINDS.has(kind):
		boss_alert_kind = kind
		boss_alert_serial += 1
	max_alive_seen = maxi(max_alive_seen, enemies.size())
	return true


func _make_actor(kind: String, elapsed: float) -> Actor:
	var stats: Dictionary = Balance.ENEMIES[kind]
	var actor := Actor.new()
	actor.id = _next_id
	_next_id += 1
	actor.kind = kind
	actor.speed = float(stats.speed)
	actor.base_speed = actor.speed
	actor.touch = int(stats.touch)
	actor.base_touch = actor.touch
	actor.radius = float(stats.radius)
	actor.knockback_scale = float(stats.knockback_scale)
	actor.stun = 0.0
	if kind == Balance.KIND_TANK:
		actor.max_hp = int(stats.hp)
	elif Balance.BOSS_KINDS.has(kind):
		actor.max_hp = ceili(float(stats.hp) * (1.0 + clampf(elapsed / Balance.ROUND_SECONDS, 0.0, 1.0) * 0.35))
		actor.attack_timer = 2.0 if kind == Balance.KIND_NIMOTON else 2.8
		actor.support_timer = 4.6
	else:
		actor.max_hp = Balance.scaled_hp(int(stats.hp), elapsed)
	actor.hp = actor.max_hp
	return actor


func _find_spawn(radius: float) -> Array:
	var inner := Rect2(
		Vector2(radius, radius),
		Vector2(Balance.FIELD_W - radius * 2.0, Balance.FIELD_H - radius * 2.0)
	)
	var blocked := view_rect.grow(Balance.SPAWN_OUTSIDE_MARGIN)
	var bands: Array[Rect2] = []
	if blocked.position.x > inner.position.x:
		bands.append(Rect2(inner.position.x, inner.position.y, blocked.position.x - inner.position.x, inner.size.y))
	if blocked.end.x < inner.end.x:
		bands.append(Rect2(blocked.end.x, inner.position.y, inner.end.x - blocked.end.x, inner.size.y))
	if blocked.position.y > inner.position.y:
		bands.append(Rect2(inner.position.x, inner.position.y, inner.size.x, blocked.position.y - inner.position.y))
	if blocked.end.y < inner.end.y:
		bands.append(Rect2(inner.position.x, blocked.end.y, inner.size.x, inner.end.y - blocked.end.y))
	if bands.is_empty():
		return []
	for _i in 40:
		var band: Rect2 = bands[rng.randi() % bands.size()]
		if band.size.x <= 1.0 or band.size.y <= 1.0:
			continue
		var pos := Vector2(
			rng.randf_range(band.position.x, band.end.x),
			rng.randf_range(band.position.y, band.end.y)
		)
		if pos.distance_to(player_pos) > Balance.SPAWN_MAX_DISTANCE:
			continue
		if _hits_cone(pos, radius):
			continue
		if blocked.has_point(pos):
			continue
		return [pos]
	return []


func _kill(actor: Actor) -> void:
	var index := enemies.find(actor)
	if index >= 0:
		enemies.remove_at(index)
	_register_kill(actor.kind)
	_drop_coins(actor)


func _register_kill(kind: String) -> void:
	kills += 1
	special_charge = minf(
		Balance.SPECIAL_GAUGE_MAX,
		special_charge + Balance.SPECIAL_CHARGE_PER_KILL
	)
	kills_of[kind] = int(kills_of[kind]) + 1
	score += int(Balance.SCORE[kind])
	var megumi_level := int(levels[Balance.MEGUMI])
	if megumi_level > 0 and kills % 10 == 0:
		player_hp = mini(player_max_hp, player_hp + Balance.megumi_heal(megumi_level))
	while kills >= Balance.build_threshold(_next_build_index):
		_pending_offers += 1
		_next_build_index += 1


func _drop_coins(actor: Actor) -> void:
	var chance := float(Balance.COIN_CHANCE[actor.kind])
	if rng.randf() >= chance:
		return
	var count := int(Balance.COIN_COUNT[actor.kind])
	for i in count:
		var coin := Coin.new()
		coin.id = _next_id
		_next_id += 1
		var angle := float(i) / float(count) * TAU + rng.randf() * 0.4
		var spot := actor.pos + Vector2.from_angle(angle) * 14.0
		spot.x = clampf(spot.x, 8.0, Balance.FIELD_W - 8.0)
		spot.y = clampf(spot.y, 8.0, Balance.FIELD_H - 8.0)
		coin.pos = spot
		coins.append(coin)


func _knockback(actor: Actor, distance: float) -> void:
	var away := actor.pos - player_pos
	if away.length() < 0.001:
		away = Vector2.RIGHT
	else:
		away = away.normalized()
	var left := distance * actor.knockback_scale
	var step_len := 4.0
	while left > 0.0:
		var d := minf(step_len, left)
		var nxt := actor.pos + away * d
		# コーンと校庭の端では、滑らずに止まる。
		if _hits_cone(nxt, actor.radius) or _out_of_field(nxt, actor.radius):
			break
		actor.pos = nxt
		left -= d


func _open_build_if_needed() -> bool:
	if build_open:
		return true
	if special_motion_left > 0.0:
		return false
	while _pending_offers > 0:
		_pending_offers -= 1
		var choices := _roll_choices()
		if choices.is_empty():
			continue
		build_open = true
		current_choices = choices
		return true
	return false


func _roll_choices() -> Array:
	var pool: Array = []
	for id in Balance.UPGRADES:
		if int(levels[id]) < Balance.UPGRADE_MAX:
			pool.append(id)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	return pool.slice(0, mini(3, pool.size()))


func _kaiju_alive() -> bool:
	for actor in enemies:
		if actor.kind == Balance.KIND_TANK:
			return true
	return false


func _hits_cone(pos: Vector2, radius: float) -> bool:
	for cone in cones:
		if pos.distance_to(cone.pos) < radius + cone.radius:
			return true
	return false


func _out_of_field(pos: Vector2, radius: float) -> bool:
	return (
		pos.x < radius
		or pos.y < radius
		or pos.x > Balance.FIELD_W - radius
		or pos.y > Balance.FIELD_H - radius
	)


func _resolve(pos: Vector2, radius: float) -> Vector2:
	var p := _clamp_field(pos, radius)
	for _i in 6:
		var hit := false
		for cone in cones:
			var diff := p - cone.pos
			var min_d := radius + cone.radius
			var dist := diff.length()
			if dist < min_d:
				var normal := Vector2.RIGHT if dist < 0.0001 else diff / dist
				p = cone.pos + normal * min_d
				hit = true
		p = _clamp_field(p, radius)
		if not hit:
			break
	return p


func _clamp_field(pos: Vector2, radius: float) -> Vector2:
	return Vector2(
		clampf(pos.x, radius, Balance.FIELD_W - radius),
		clampf(pos.y, radius, Balance.FIELD_H - radius)
	)


func _end(kind: String) -> void:
	if finished:
		return
	finished = true
	outcome = kind
	build_open = false
	current_choices = []
