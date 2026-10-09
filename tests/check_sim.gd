extends SceneTree

const Balance = preload("res://scripts/balance.gd")
const BattleSim = preload("res://scripts/battle_sim.gd")
const SaveStore = preload("res://scripts/save_store.gd")
const UiFont = preload("res://scripts/ui_font.gd")

var fails := 0


func _initialize() -> void:
	_balance()
	_names()
	_font_glyphs()
	_combat()
	_specials()
	_spawn_and_round()
	_save()
	_shop()
	_kite()
	if fails == 0:
		print("ALL OK")
	else:
		print("FAILED %d" % fails)
	quit(fails)


func _balance() -> void:
	var thresholds: Array[int] = [6, 15, 27, 42, 60, 80, 102, 126, 150]
	for i in thresholds.size():
		_eq(Balance.build_threshold(i), thresholds[i], "threshold %d" % i)
	_eq(Balance.build_threshold(9), 174, "threshold 9")
	_eq(Balance.scaled_hp(12, 0.0), 12, "hp 0")
	_eq(Balance.scaled_hp(12, 90.0), 17, "hp 90")
	_eq(Balance.scaled_hp(12, 180.0), 22, "hp 180")
	_eq(Balance.scaled_hp(32, 180.0), 58, "boar hp 180")
	_eq(Balance.attack_damage(14, 0), 14, "atk 0")
	_eq(Balance.attack_damage(14, 1), 16, "atk 1")
	_eq(Balance.attack_damage(14, 2), 18, "atk 2")
	_eq(Balance.attack_damage(14, 3), 20, "atk 3")
	_eq(Balance.attack_damage(14, 4), 22, "atk 4")
	_eq(Balance.attack_damage(14, 5), 24, "atk 5")
	_near(Balance.puritora_interval(1), 8.0, "puri 1")
	_near(Balance.puritora_interval(2), 6.8, "puri 2")
	_near(Balance.puritora_interval(5), 3.2, "puri 5")
	_eq(Balance.megumi_heal(1), 4, "megumi 1")
	_eq(Balance.megumi_heal(5), 16, "megumi 5")
	_near(Balance.magnet_radius(0), 70.0, "magnet 0")
	_near(Balance.magnet_radius(5), 270.0, "magnet 5")
	_near(Balance.move_speed(155.0, 5), 217.0, "speed 5")
	_near(Balance.coin_gain(1, 1), 1.25, "coin gain")
	_eq(Balance.score_from_kills(1, 1, 1), 240, "score formula")
	_eq(Balance.apply_damage_scale(10, 0.8), 8, "kenny damage")
	_eq(Balance.apply_damage_scale(6, 1.0), 6, "massa damage")
	_true(Balance.kills_within_cap(350, 180, 6), "cap ok")
	_true(not Balance.kills_within_cap(351, 0, 0), "cap over")
	_eq(Balance.kind_for_roll(10.0, 0.0), Balance.KIND_NORMAL, "early kind")
	_eq(Balance.kind_for_roll(50.0, 0.19), Balance.KIND_FAST, "fast roll")
	_eq(Balance.kind_for_roll(50.0, 0.20), Balance.KIND_NORMAL, "normal roll")
	_near(float(Balance.spawn_profile(44.9).interval), 0.90, "interval 44")
	_near(float(Balance.spawn_profile(45.0).interval), 0.70, "interval 45")
	_near(float(Balance.spawn_profile(120.0).interval), 0.42, "interval 120")
	_near(float(Balance.spawn_profile(75.0).fast), 0.30, "fast 75")
	var massa: Dictionary = Balance.CHARACTERS[Balance.CHAR_MASSA]
	var boar: Dictionary = Balance.ENEMIES[Balance.KIND_FAST]
	var kenny: Dictionary = Balance.CHARACTERS[Balance.CHAR_KENNY]
	var take: Dictionary = Balance.CHARACTERS[Balance.CHAR_TAKETCHI]
	_true(float(massa.speed) < float(boar.speed), "massa slower than boar")
	_near(float(take.speed), float(boar.speed), "takechi matches boar")
	_true(float(kenny.speed) > float(boar.speed), "kenny faster than boar")
	_eq(Balance.CONE_POINTS.size(), 9, "9 cones")
	_eq(Balance.UPGRADES.size(), 9, "9 builds")
	_near(Balance.puritora_radius(1), 160.0, "puri radius 1")
	_near(Balance.puritora_radius(5), 304.0, "puri radius 5")


func _names() -> void:
	_eq(Balance.shown_display_name(""), "ななし", "blank name")
	_true(Balance.is_valid_display_name("印旛村戦線"), "kanji name")
	_true(Balance.is_valid_display_name("まっさー"), "long vowel")
	_true(Balance.is_valid_display_name("マサキ・A"), "middle dot")
	_true(Balance.is_valid_display_name("あいうえおかきくけこ"), "10 chars")
	_true(not Balance.is_valid_display_name("あいうえおかきくけこあ"), "11 chars")
	_true(not Balance.is_valid_display_name(""), "empty invalid")
	_true(not Balance.is_valid_display_name("massa!"), "symbol")
	_true(not Balance.is_valid_display_name("ま さ"), "space")
	_eq(Balance.SPECIAL_QUOTES[Balance.CHAR_MASSA], "印旛の未来は僕が守るっ！", "massa special quote")
	_eq(Balance.SPECIAL_QUOTES[Balance.CHAR_TAKETCHI], "こいつら蹴散らしたら、銭湯行かね？", "takechi special quote")
	_eq(Balance.SPECIAL_QUOTES[Balance.CHAR_KENNY], "私の勝利に、100ｲｪﾝ賭けます。", "kenny special quote")


func _font_glyphs() -> void:
	var font := UiFont.font()
	for quote in Balance.SPECIAL_QUOTES.values():
		var text := str(quote)
		for index in text.length():
			var codepoint := text.unicode_at(index)
			_true(font.has_char(codepoint), "special font glyph U+%04X" % codepoint)


func _specials() -> void:
	var sim = BattleSim.new()
	sim.spawns_enabled = false
	sim.contact_enabled = false
	sim.debug_count_kills(Balance.KIND_NORMAL, 5)
	_eq(sim.special_charge, 50.0, "special charge per kill")
	_true(not sim.activate_special(), "special requires full charge")
	sim.special_charge = Balance.SPECIAL_GAUGE_MAX
	var target = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos + Vector2(300, 0), 100, 0.0)
	_true(sim.begin_special(), "massa special begins")
	_true(sim.special_pending, "special waits through cut-in")
	sim.step(1.0, Vector2.RIGHT)
	_near(sim.time, 0.0, "special cut-in pauses battle")
	_eq(target.hp, 100, "special waits before hitting")
	_true(sim.resolve_special(), "massa special resolves")
	_eq(target.hp, 58, "massa wide sweep damage")
	_true(target.pos.distance_to(sim.player_pos) > 300.0, "massa special knockback")
	_eq(sim.special_charge, 0.0, "special consumes charge")
	_true(not sim.resolve_special(), "special resolves only once")
	_true(sim.special_motion_left > 0.0, "special motion starts")

	var build_sim = BattleSim.new()
	build_sim.spawns_enabled = false
	build_sim.contact_enabled = false
	for i in 6:
		build_sim.debug_place(Balance.KIND_NORMAL, build_sim.player_pos + Vector2(80.0 + float(i) * 24.0, 0.0), 1, 0.0)
	build_sim.special_charge = Balance.SPECIAL_GAUGE_MAX
	_true(build_sim.begin_special(), "build delay special begins")
	_true(build_sim.resolve_special(), "build delay special resolves")
	_true(not build_sim.build_open, "kill build waits during special motion")
	build_sim.step(0.5, Vector2.ZERO)
	_true(not build_sim.build_open, "kill build remains queued during motion")
	build_sim.step(Balance.SPECIAL_MASSA_MOTION_SECONDS, Vector2.ZERO)
	_true(build_sim.build_open, "kill build opens after special motion")

	sim = BattleSim.new()
	for _i in 20:
		sim._register_kill(Balance.KIND_NORMAL)
	_eq(sim.special_charge, Balance.SPECIAL_GAUGE_MAX, "special gauge is capped")

	sim = BattleSim.new(Balance.CHAR_TAKETCHI)
	sim.special_charge = Balance.SPECIAL_GAUGE_MAX
	_true(sim.activate_special(), "takechi special activates")
	_near(sim.attack_interval_now(), 0.31, "takechi special attack speed")
	_eq(sim.attack_damage_now(), 46, "takechi special attack damage")
	_near(sim.special_active_left, 8.0, "takechi special duration")

	sim = BattleSim.new(Balance.CHAR_KENNY)
	sim.special_charge = Balance.SPECIAL_GAUGE_MAX
	_true(sim.activate_special(), "kenny special activates")
	_near(sim.attack_interval_now(), 0.12, "kenny special attack count")
	_near(sim.special_active_left, 6.0, "kenny special duration")
	sim.spawns_enabled = false
	sim.contact_enabled = false
	sim.step(0.2, Vector2.ZERO)
	_near(sim.special_active_left, 5.8, "special timer ticks")


func _combat() -> void:
	var sim = BattleSim.new()
	_eq(sim.cones.size(), 9, "cones placed")
	_near(sim.player_pos.x, 1200.0, "start x")
	_near(sim.player_pos.y, 800.0, "start y")

	sim.attacks_enabled = false
	sim.contact_enabled = false
	sim.spawns_enabled = false
	sim.player_pos = Vector2(400, 700)
	sim.step(2.0, Vector2.RIGHT)
	_true(sim.player_pos.distance_to(Vector2(520, 700)) >= 43.9, "player stopped by cone")
	_true(sim.player_pos.x < 520.0, "player did not pass cone")

	sim = BattleSim.new()
	sim.attacks_enabled = false
	sim.contact_enabled = false
	sim.spawns_enabled = false
	var walker = sim.debug_place(Balance.KIND_NORMAL, Vector2(400, 700), 12, 80.0)
	sim.player_pos = Vector2(700, 700)
	sim.step(3.0, Vector2.ZERO)
	_true(walker.pos.distance_to(Vector2(520, 700)) >= 37.8, "enemy stopped by cone")
	_true(walker.pos.x < 520.0, "enemy did not pass cone")

	sim = BattleSim.new()
	sim.contact_enabled = false
	sim.spawns_enabled = false
	sim.player_pos = Vector2(400, 700)
	var pushed = sim.debug_place(Balance.KIND_NORMAL, Vector2(470, 700), 100, 0.0)
	sim.step(1.0, Vector2.ZERO)
	_near(pushed.pos.x, 482.0, "knockback stops at cone")
	_near(pushed.pos.y, 700.0, "knockback y")

	sim = BattleSim.new()
	sim.contact_enabled = false
	sim.spawns_enabled = false
	var kaiju = sim.debug_place(Balance.KIND_TANK, sim.player_pos + Vector2(100, 0), 200, 0.0)
	sim.step(1.0, Vector2.ZERO)
	_near(kaiju.pos.distance_to(sim.player_pos), 163.0, "kaiju knockback 0.35")
	_eq(kaiju.hp, 186, "kaiju took one hit")

	sim = BattleSim.new()
	sim.contact_enabled = false
	sim.spawns_enabled = false
	sim.levels[Balance.BUTTO] = 1
	var blasted = sim.debug_place(Balance.KIND_TANK, sim.player_pos + Vector2(100, 0), 200, 0.0)
	sim.step(1.0, Vector2.ZERO)
	_near(blasted.pos.distance_to(sim.player_pos), 172.45, "butto knockback")
	sim.levels[Balance.MAAI] = 2
	sim.levels[Balance.RENDA] = 1
	sim._apply_build_stats()
	_near(sim.attack_radius, 136.0 * 1.28, "maai radius")
	_near(sim.attack_interval, 0.92, "renda interval")

	sim = BattleSim.new()
	sim.contact_enabled = false
	sim.spawns_enabled = false
	var inside = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos + Vector2(100, 0), 100, 0.0)
	var outside = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos + Vector2(150, 0), 100, 0.0)
	sim.step(1.0, Vector2.ZERO)
	_eq(inside.hp, 86, "in range damaged")
	_eq(outside.hp, 100, "out of range safe")

	var pile_a = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos + Vector2(40, 0), 10, 0.0)
	var pile_b = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos + Vector2(40, 0), 10, 0.0)
	sim.step(0.2, Vector2.ZERO)
	_true(sim.enemies.has(pile_a) and sim.enemies.has(pile_b), "enemies overlap")

	sim = BattleSim.new()
	sim.attacks_enabled = false
	sim.spawns_enabled = false
	var touches := [6, 10, 16, 6]
	for amount in touches:
		var actor = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos, 20, 0.0)
		actor.touch = amount
	sim.step(0.99, Vector2.ZERO)
	_eq(sim.player_hp, 100, "invuln holds")
	sim.step(0.02, Vector2.ZERO)
	_eq(sim.player_hp, 68, "top 3 contact")

	sim = BattleSim.new()
	sim.attacks_enabled = false
	sim.spawns_enabled = false
	var stunned = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos, 20, 0.0)
	stunned.stun = 5.0
	sim.step(1.05, Vector2.ZERO)
	_eq(sim.player_hp, 100, "stun deals no contact")

	sim = BattleSim.new(Balance.CHAR_KENNY)
	sim.attacks_enabled = false
	sim.spawns_enabled = false
	var biting = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos, 20, 0.0)
	biting.touch = 10
	sim.step(1.0, Vector2.ZERO)
	_eq(sim.player_hp, 92, "kenny takes 0.8")

	sim = BattleSim.new()
	sim.spawns_enabled = false
	sim.attacks_enabled = false
	sim.contact_enabled = false
	var far = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos + Vector2(950, 0), 12, 0.0)
	sim.step(0.05, Vector2.ZERO)
	_true(not sim.enemies.has(far), "despawn over 900")
	_eq(sim.kills, 0, "despawn is not a kill")
	var edge = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos + Vector2(900, 0), 12, 0.0)
	sim.step(0.05, Vector2.ZERO)
	_true(sim.enemies.has(edge), "900 stays")

	sim = BattleSim.new()
	sim.spawns_enabled = false
	sim.attacks_enabled = false
	sim.contact_enabled = false
	sim.levels[Balance.OKOZUKAI] = 1
	for _i in 4:
		sim._collect_coin()
	_eq(sim.shown_coins(), 5, "coin fraction")
	_near(sim.coin_value, 5.0, "coin internal")

	var coin = BattleSim.Coin.new()
	coin.pos = sim.player_pos + Vector2(20, 0)
	sim.coins.clear()
	sim.coins.append(coin)
	sim.step(0.05, Vector2.ZERO)
	_eq(sim.shown_coins(), 6, "pickup within 28")

	sim.levels[Balance.OKOZUKAI] = 0
	sim.coin_value = 0.0
	var distant = BattleSim.Coin.new()
	distant.pos = sim.player_pos + Vector2(60, 0)
	sim.coins.clear()
	sim.coins.append(distant)
	var before: float = distant.pos.distance_to(sim.player_pos)
	sim.step(0.01, Vector2.ZERO)
	_true(distant.pos.distance_to(sim.player_pos) < before, "magnet pulls")
	_eq(sim.shown_coins(), 0, "not collected yet")

	sim = BattleSim.new()
	sim.spawns_enabled = false
	sim.attacks_enabled = false
	sim.contact_enabled = false
	sim.levels[Balance.PURITORA] = 1
	var near = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos + Vector2(100, 0), 30, 0.0)
	var wide = sim.debug_place(Balance.KIND_NORMAL, sim.player_pos + Vector2(200, 0), 30, 0.0)
	var beast = sim.debug_place(Balance.KIND_TANK, sim.player_pos + Vector2(80, 0), 200, 0.0)
	sim.step(8.05, Vector2.ZERO)
	_near(near.stun, 1.2, "stun 1.2")
	_near(beast.stun, 0.6, "kaiju stun 0.6")
	_near(wide.stun, 0.0, "outside pulse")

	sim = BattleSim.new()
	sim.spawns_enabled = false
	sim.contact_enabled = false
	sim.levels[Balance.MEGUMI] = 2
	sim.player_hp = 50
	sim.debug_count_kills(Balance.KIND_NORMAL, 10)
	_eq(sim.player_hp, 57, "megumi at 10")
	sim.debug_count_kills(Balance.KIND_NORMAL, 9)
	_eq(sim.player_hp, 57, "no heal at 19")
	sim.debug_count_kills(Balance.KIND_NORMAL, 1)
	_eq(sim.player_hp, 64, "megumi at 20")

	sim = BattleSim.new()
	sim.spawns_enabled = false
	sim.debug_count_kills(Balance.KIND_NORMAL, 6)
	_eq(sim.player_hp, 100, "no megumi at level 0")
	_eq(sim.score, 60, "6 normals")
	_true(sim.build_open, "build at 6")
	var frozen: float = sim.time
	sim.step(3.0, Vector2.RIGHT)
	_near(sim.time, frozen, "timer pauses in build")
	_near(sim.player_pos.x, 1200.0, "no move in build")

	sim = BattleSim.new()
	sim.spawns_enabled = false
	for id in Balance.UPGRADES:
		if id != Balance.ONIGIRI:
			sim.levels[id] = 5
	sim.debug_count_kills(Balance.KIND_NORMAL, 10)
	_eq(sim.current_choices.size(), 1, "one card left")
	_eq(sim.current_choices[0], Balance.ONIGIRI, "left card is onigiri")
	sim.choose(0)
	_eq(sim.player_max_hp, 120, "onigiri max")
	_eq(sim.player_hp, 120, "onigiri heal")
	_eq(int(sim.levels[Balance.ONIGIRI]), 1, "onigiri level")

	sim = BattleSim.new()
	sim.spawns_enabled = false
	sim.debug_count_kills(Balance.KIND_NORMAL, 20)
	_true(sim.build_open, "first of two offers")
	sim.choose(0)
	_true(sim.build_open, "second offer queued")

	sim = BattleSim.new()
	sim.spawns_enabled = false
	for id in Balance.UPGRADES:
		sim.levels[id] = 5
	sim.debug_count_kills(Balance.KIND_NORMAL, 10)
	_true(not sim.build_open, "empty pool skips")
	sim.step(0.2, Vector2.ZERO)
	_true(sim.time > 0.1, "game continues")

	sim = BattleSim.new()
	sim.spawns_enabled = false
	sim.attacks_enabled = false
	sim.player_hp = 10
	var lethal = sim.debug_place(Balance.KIND_TANK, sim.player_pos, 200, 0.0)
	lethal.touch = 16
	sim.step(1.0, Vector2.ZERO)
	_true(sim.finished and sim.outcome == "down", "hp 0 ends")
	_eq(sim.player_hp, 0, "hp clamped")
	_eq(sim.score, 0, "death keeps score")

	sim = BattleSim.new()
	sim.attacks_enabled = false
	sim.contact_enabled = false
	sim.spawns_enabled = false
	sim.time = 179.0
	sim.debug_count_kills(Balance.KIND_NORMAL, 6)
	_true(sim.build_open, "build before the bell")
	sim.time = 180.0
	sim.choose(0)
	_true(sim.finished and sim.outcome == "clear", "clear after the last build")

	sim = BattleSim.new()
	sim.debug_count_kills(Balance.KIND_NORMAL, 2)
	sim.debug_count_kills(Balance.KIND_FAST, 1)
	sim.debug_count_kills(Balance.KIND_TANK, 1)
	_eq(sim.score, 250, "mixed score")
	_eq(sim.score, Balance.score_from_kills(2, 1, 1), "score matches formula")


func _spawn_and_round() -> void:
	var sim = BattleSim.new()
	sim.rng.seed = 1
	sim.attacks_enabled = false
	sim.contact_enabled = false
	sim.step(0.89, Vector2.ZERO)
	_eq(sim.enemies.size(), 0, "quiet before 0.9")
	sim.step(0.02, Vector2.ZERO)
	_eq(sim.enemies.size(), 1, "first spawn")
	if sim.enemies.size() == 1:
		var born = sim.enemies[0]
		_eq(born.kind, Balance.KIND_NORMAL, "first is normal")
		_eq(born.max_hp, 13, "scaled hp at 0.9")
		_true(born.pos.distance_to(sim.player_pos) <= 860.0, "spawn within 860")
		_true(born.pos.distance_to(sim.player_pos) > 100.0, "spawn off the player")
		_true(not sim.view_rect.grow(Balance.SPAWN_OUTSIDE_MARGIN).has_point(born.pos), "spawn outside camera")

	sim = BattleSim.new()
	sim.rng.seed = 2
	sim.attacks_enabled = false
	sim.contact_enabled = false
	sim.regular_spawns_enabled = false
	sim.step(74.9, Vector2.ZERO)
	_eq(_count_kind(sim, Balance.KIND_TANK), 0, "no kaiju before 75")
	sim.step(0.2, Vector2.ZERO)
	_eq(_count_kind(sim, Balance.KIND_TANK), 1, "kaiju at 75")
	if _count_kind(sim, Balance.KIND_TANK) == 1:
		_eq(_first_kind(sim, Balance.KIND_TANK).max_hp, 200, "kaiju hp stays 200")
	sim.step(30.0, Vector2.ZERO)
	_eq(_count_kind(sim, Balance.KIND_TANK), 1, "second kaiju waits")

	sim = BattleSim.new()
	sim.attacks_enabled = false
	sim.contact_enabled = false
	sim.regular_spawns_enabled = false
	sim.spawns_enabled = false
	for _i in 60:
		sim.debug_place(Balance.KIND_NORMAL, sim.player_pos + Vector2(30, 0), 12, 0.0)
	sim.spawns_enabled = true
	sim.regular_spawns_enabled = true
	sim.step(3.0, Vector2.ZERO)
	_true(sim.enemies.size() <= 60, "cap 60")
	_true(sim.max_alive_seen <= 60, "cap never exceeded")

	sim = BattleSim.new()
	sim.attacks_enabled = false
	sim.contact_enabled = false
	sim.step(180.0, Vector2.ZERO)
	if not sim.finished:
		sim.step(0.1, Vector2.ZERO)
	_true(sim.finished and sim.outcome == "clear", "3 minutes clear")
	_true(sim.time >= 179.99 and sim.time < 181.0, "clock stops at 3 minutes")
	_true(sim.max_alive_seen <= 60, "cap across the round")
	for actor in sim.enemies:
		_true(sim.player_pos.distance_to(actor.pos) <= 900.0, "no leftover beyond 900")


func _save() -> void:
	var path := "/tmp/inba_war_save_test.json"
	_wipe(path)
	var store = SaveStore.new()
	store.load_from(path)
	var player_id := str(store.data.player_id)
	_true(_uuid_ok(player_id), "uuid")
	_eq(store.shown_name(), "ななし", "default shown name")
	_true(not store.set_display_name("massa!"), "reject symbol name")
	_true(store.set_display_name("印旛のマサ"), "accept name")
	_eq(store.shown_name(), "印旛のマサ", "stored name")
	_true(store.set_display_name(""), "clear name")
	_eq(int(store.data.yen), 0, "yen starts 0")
	_eq(int(store.data.takechi_fragments), 0, "no fragments yet")
	_true(not bool(store.data.takechi_unlocked), "taketchi locked")

	var summary := {
		"score": 40,
		"kills": 4,
		"kills_normal": 4,
		"kills_fast": 0,
		"kills_tank": 0,
		"coins": 3,
		"outcome": "down",
		"character": Balance.CHAR_MASSA,
		"time": 12.0,
	}
	var first: Dictionary = store.commit_run(summary)
	_true(bool(first.best_updated), "first best")
	_eq(int(first.yen), 3, "yen gained")
	_eq(int(store.data.pending_score.score), 40, "pending score")
	_eq(str(store.data.pending_score.display_name), "ななし", "pending blank name")
	_eq(str(store.data.pending_score.version), "0.1.0", "pending version")
	_eq(str(store.data.pending_score.character), Balance.CHAR_MASSA, "pending character")
	var when := str(store.data.best_datetime)
	var again: Dictionary = store.commit_run(summary)
	_true(not bool(again.best_updated), "tie does not replace")
	_eq(str(store.data.best_datetime), when, "earlier record stays")
	_eq(int(store.data.yen), 6, "yen stacks")
	summary.score = 39
	summary.coins = 1
	var lower: Dictionary = store.commit_run(summary)
	_true(not bool(lower.best_updated), "lower score stays")
	_eq(int(store.data.best_score), 40, "best remains 40")
	summary.score = 50
	summary.coins = 0
	summary.kills_fast = 1
	summary.kills_normal = 2
	var higher: Dictionary = store.commit_run(summary)
	_true(bool(higher.best_updated), "higher replaces")
	_eq(int(store.data.pending_score.score), 50, "pending replaced")
	_eq(int(store.data.yen), 7, "yen after zero coin run")

	var loaded = SaveStore.new()
	loaded.load_from(path)
	_eq(str(loaded.data.player_id), player_id, "id persists")
	_eq(int(loaded.data.best_score), 50, "best persists")
	_eq(int(loaded.data.yen), 7, "yen persists")
	_eq(str(loaded.data.costume[Balance.CHAR_MASSA]), "私服", "costume default")

	var bad := "/tmp/inba_war_save_bad.json"
	_wipe(bad)
	var file := FileAccess.open(bad, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	var recovered = SaveStore.new()
	recovered.load_from(bad)
	_true(_uuid_ok(str(recovered.data.player_id)), "fresh id after corrupt")
	_true(FileAccess.file_exists(bad + ".bak"), "corrupt file kept")
	_wipe(path)
	_wipe(bad)
	_wipe(bad + ".bak")
	store.free()
	loaded.free()
	recovered.free()


func _shop() -> void:
	var path := "/tmp/inba_war_shop_test.json"
	_wipe(path)
	var store = SaveStore.new()
	store.load_from(path)
	_eq(store.reward_fragments("clear", 0), 2, "clear fragments")
	_eq(store.reward_fragments("down", 30), 1, "down 30 fragments")
	_eq(store.reward_fragments("down", 29), 0, "down 29 fragments")
	_eq(store.playable_character(), Balance.CHAR_MASSA, "starts as massa")
	_true(not store.set_selected(Balance.CHAR_KENNY), "locked kenny stays benched")
	_eq(store.buy_uniform(), "poor", "uniform needs yen")
	_eq(store.buy_fragment(Balance.CHAR_TAKETCHI), "poor", "fragment needs yen")
	store.add_yen(5000)
	_eq(int(store.data.yen), 5000, "yen added")
	_true(not store.set_costume(Balance.CHAR_MASSA, "制服"), "no uniform yet")
	_eq(store.buy_uniform(), "ok", "buy uniform")
	_eq(int(store.data.yen), 4400, "uniform price 600")
	_eq(store.buy_uniform(), "owned", "uniform once")
	_eq(int(store.data.yen), 4400, "second uniform is free of charge")
	_true(store.set_costume(Balance.CHAR_KENNY, "制服"), "costume unlocks with the uniform")
	_eq(store.costume_of(Balance.CHAR_KENNY), "制服", "kenny wears it")
	_true(store.set_costume(Balance.CHAR_KENNY, "私服"), "back to street clothes")
	for _i in 4:
		_eq(store.buy_fragment(Balance.CHAR_TAKETCHI), "ok", "fragment toward takechi")
	_eq(int(store.fragments_of(Balance.CHAR_TAKETCHI)), 4, "four fragments")
	_eq(store.buy_fragment(Balance.CHAR_TAKETCHI), "unlocked", "fifth unlocks")
	_true(store.is_playable(Balance.CHAR_TAKETCHI), "takechi playable")
	_eq(store.buy_fragment(Balance.CHAR_TAKETCHI), "ok", "lone friend receives it")
	_eq(store.fragments_of(Balance.CHAR_KENNY), 1, "auto to kenny")
	store.data.kenny_fragments = 4
	store.data.kenny_unlocked = false
	var info: Dictionary = store.grant_fragments(Balance.CHAR_KENNY, 2)
	_eq(int(info.applied), 1, "fifth fragment applies")
	_eq(int(info.yen), 300, "sixth becomes yen")
	_true(bool(info.unlocked), "grant unlocks kenny")
	_true(store.is_playable(Balance.CHAR_KENNY), "kenny playable")
	var before := int(store.data.yen)
	_eq(store.buy_fragment(Balance.CHAR_KENNY), "none", "shelf empty when both are in")
	_eq(int(store.data.yen), before, "empty shelf costs nothing")
	var cashed: Dictionary = store.grant_fragments(Balance.CHAR_KENNY, 2)
	_eq(int(cashed.applied), 0, "no fragment slot left")
	_eq(int(cashed.yen), 600, "two fragments cash out")
	_true(store.set_selected(Balance.CHAR_KENNY), "select kenny")
	_eq(store.playable_character(), Balance.CHAR_KENNY, "kenny is up")
	var fragments_before := int(store.fragments_of(Balance.CHAR_TAKETCHI))
	var summary := {
		"score": 10,
		"kills": 80,
		"kills_normal": 80,
		"kills_fast": 0,
		"kills_tank": 0,
		"coins": 4,
		"outcome": "clear",
		"character": Balance.CHAR_KENNY,
		"time": 180.0,
	}
	store.commit_run(summary)
	_eq(store.fragments_of(Balance.CHAR_TAKETCHI), fragments_before, "commit does not grant fragments")
	_eq(int(store.data.yen), before + 600 + 4, "commit adds coins only")
	var loaded = SaveStore.new()
	loaded.load_from(path)
	_eq(loaded.playable_character(), Balance.CHAR_KENNY, "selected persists")
	_true(bool(loaded.data.has_uniform), "uniform persists")
	_true(loaded.is_playable(Balance.CHAR_TAKETCHI), "takechi persists")
	_wipe(path)
	store.free()
	loaded.free()


func _kite() -> void:
	var sim = BattleSim.new()
	sim.rng.seed = 7
	var guard := 0
	while not sim.finished and guard < 20000:
		guard += 1
		if sim.build_open:
			sim.choose(0)
		else:
			sim.step(0.05, _kite_dir(sim))
	_true(sim.finished, "kite run ends")
	_eq(sim.score, Balance.score_from_kills(
		int(sim.kills_of[Balance.KIND_NORMAL]),
		int(sim.kills_of[Balance.KIND_FAST]),
		int(sim.kills_of[Balance.KIND_TANK])
	), "kite score")
	_true(sim.max_alive_seen <= 60, "kite cap")
	_true(sim.player_pos.x >= sim.player_radius - 0.1, "player in field")
	_true(sim.player_pos.x <= Balance.FIELD_W - sim.player_radius + 0.1, "player in field x")
	_true(sim.shown_coins() == int(floor(sim.coin_value)), "shown coins")
	if sim.outcome == "clear":
		_true(sim.time >= 179.99, "clear reaches 3 minutes")
	else:
		_eq(sim.player_hp, 0, "down means hp 0")
		_true(sim.time < 180.1, "down is inside the round")
	print("kite outcome=%s time=%.2f score=%d kills=%d coins=%d hp=%d builds=%d" % [
		sim.outcome, sim.time, sim.score, sim.kills, sim.shown_coins(), sim.player_hp, _levels(sim)
	])


func _kite_dir(sim) -> Vector2:
	var nearest = null
	var best := 99999.0
	for actor in sim.enemies:
		var dist: float = sim.player_pos.distance_to(actor.pos)
		if dist < best:
			best = dist
			nearest = actor
	var to_center := Vector2(Balance.START) - Vector2(sim.player_pos)
	if nearest == null:
		return Vector2.RIGHT if to_center.length() < 40.0 else to_center.normalized()
	var away := Vector2(sim.player_pos) - Vector2(nearest.pos)
	if away.length() < 0.001:
		away = Vector2.RIGHT
	var mixed := away.normalized() * 1.3
	if to_center.length() > 80.0:
		mixed += to_center.normalized() * 0.45
	return mixed.normalized()


func _levels(sim) -> int:
	var total := 0
	for id in Balance.UPGRADES:
		total += int(sim.levels[id])
	return total


func _count_kind(sim, kind: String) -> int:
	var n := 0
	for actor in sim.enemies:
		if actor.kind == kind:
			n += 1
	return n


func _first_kind(sim, kind: String):
	for actor in sim.enemies:
		if actor.kind == kind:
			return actor
	return null


func _uuid_ok(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
	return regex.search(value) != null


func _wipe(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _eq(got, want, label: String) -> void:
	if got != want:
		fails += 1
		print("FAIL %s got=%s want=%s" % [label, str(got), str(want)])


func _near(got: float, want: float, label: String) -> void:
	if absf(got - want) > 0.05:
		fails += 1
		print("FAIL %s got=%s want=%s" % [label, str(got), str(want)])


func _true(ok: bool, label: String) -> void:
	if not ok:
		fails += 1
		print("FAIL %s" % label)
