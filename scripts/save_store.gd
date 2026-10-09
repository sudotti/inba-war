extends Node

const Balance = preload("res://scripts/balance.gd")
const DEFAULT_PATH := "user://inba_save.json"

var data: Dictionary = {}
var last_result: Dictionary = {}
var path: String = DEFAULT_PATH
var shop_return: String = "res://scenes/title.tscn"


func _ready() -> void:
	load_from(DEFAULT_PATH)


func load_from(file_path: String) -> void:
	path = file_path
	if not FileAccess.file_exists(path):
		data = _fresh()
		_write()
		return
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_park_corrupt()
		data = _fresh()
		_write()
		return
	data = _coerce(parsed)
	_write()


func shown_name() -> String:
	return Balance.shown_display_name(str(data.get("display_name", "")))


func set_display_name(raw: String) -> bool:
	if raw == "":
		data.display_name = ""
		_write()
		return true
	if not Balance.is_valid_display_name(raw):
		return false
	data.display_name = raw
	_write()
	return true


func commit_run(summary: Dictionary) -> Dictionary:
	var coins := int(summary.get("coins", 0))
	if coins > 0:
		data.yen = int(data.yen) + coins
	var updated := false
	var score := int(summary.get("score", 0))
	if score > int(data.best_score):
		updated = true
		var when := _now()
		data.best_score = score
		data.best_character = str(summary.get("character", Balance.CHAR_MASSA))
		data.best_datetime = when
		data.pending_score = {
			"player_id": str(data.player_id),
			"display_name": shown_name(),
			"score": score,
			"kills_normal": int(summary.get("kills_normal", 0)),
			"kills_fast": int(summary.get("kills_fast", 0)),
			"kills_tank": int(summary.get("kills_tank", 0)),
			"character": str(summary.get("character", Balance.CHAR_MASSA)),
			"version": Balance.VERSION,
			"datetime": when,
		}
	_write()
	var out := summary.duplicate(true)
	out.best_updated = updated
	out.best_score = int(data.best_score)
	out.best_datetime = str(data.best_datetime)
	out.yen = int(data.yen)
	last_result = out
	return out


func reward_fragments(outcome: String, kills: int) -> int:
	if outcome == "clear":
		return 2
	if kills >= 30:
		return 1
	return 0


func locked_friends() -> Array[String]:
	var out: Array[String] = []
	if not bool(data.takechi_unlocked):
		out.append(Balance.CHAR_TAKETCHI)
	if not bool(data.kenny_unlocked):
		out.append(Balance.CHAR_KENNY)
	return out


func is_playable(who: String) -> bool:
	if who == Balance.CHAR_MASSA:
		return true
	if who == Balance.CHAR_TAKETCHI:
		return bool(data.takechi_unlocked)
	if who == Balance.CHAR_KENNY:
		return bool(data.kenny_unlocked)
	return false


func playable_character() -> String:
	var who := str(data.get("selected", Balance.CHAR_MASSA))
	if is_playable(who):
		return who
	return Balance.CHAR_MASSA


func set_selected(who: String) -> bool:
	if not is_playable(who):
		return false
	data.selected = who
	_write()
	return true


func fragments_of(who: String) -> int:
	if who == Balance.CHAR_TAKETCHI:
		return int(data.takechi_fragments)
	if who == Balance.CHAR_KENNY:
		return int(data.kenny_fragments)
	return 0


func costume_of(who: String) -> String:
	var costume: Dictionary = data.costume
	return str(costume.get(who, "私服"))


func owns_look(look: String) -> bool:
	if look == "私服":
		return true
	if look == "制服":
		return bool(data.has_uniform)
	return false


func set_costume(who: String, look: String) -> bool:
	var costume: Dictionary = data.costume
	if not costume.has(who):
		return false
	if not owns_look(look):
		return false
	var stored := "私服"
	if look == "制服":
		stored = "制服"
	costume[who] = stored
	data.costume = costume
	_write()
	return true


func add_yen(amount: int) -> void:
	if amount == 0:
		return
	data.yen = maxi(0, int(data.yen) + amount)
	_write()


func buy_uniform() -> String:
	if bool(data.has_uniform):
		return "owned"
	if int(data.yen) < Balance.UNIFORM_PRICE:
		return "poor"
	data.yen = int(data.yen) - Balance.UNIFORM_PRICE
	data.has_uniform = true
	_write()
	return "ok"


func buy_fragment(who: String) -> String:
	var locked := locked_friends()
	if locked.is_empty():
		return "none"
	var target := who
	if locked.size() == 1:
		target = str(locked[0])
	elif not locked.has(who):
		return "pick"
	if int(data.yen) < Balance.FRAGMENT_PRICE:
		return "poor"
	data.yen = int(data.yen) - Balance.FRAGMENT_PRICE
	var unlocked := _add_one(target)
	_write()
	return "unlocked" if unlocked else "ok"


func grant_fragments(who: String, count: int) -> Dictionary:
	var applied := 0
	var yen := 0
	var unlocked := false
	for _i in maxi(0, count):
		if _accepts_fragment(who):
			applied += 1
			if _add_one(who):
				unlocked = true
		else:
			yen += Balance.FRAGMENT_EXCHANGE
	if yen > 0:
		data.yen = int(data.yen) + yen
	if count > 0:
		_write()
	return {"applied": applied, "yen": yen, "unlocked": unlocked}


func _accepts_fragment(who: String) -> bool:
	if who == Balance.CHAR_TAKETCHI:
		return not bool(data.takechi_unlocked)
	if who == Balance.CHAR_KENNY:
		return not bool(data.kenny_unlocked)
	return false


func _add_one(who: String) -> bool:
	if who == Balance.CHAR_TAKETCHI:
		data.takechi_fragments = int(data.takechi_fragments) + 1
		if int(data.takechi_fragments) >= Balance.FRAGMENTS_TO_UNLOCK:
			data.takechi_fragments = Balance.FRAGMENTS_TO_UNLOCK
			data.takechi_unlocked = true
			return true
		return false
	if who == Balance.CHAR_KENNY:
		data.kenny_fragments = int(data.kenny_fragments) + 1
		if int(data.kenny_fragments) >= Balance.FRAGMENTS_TO_UNLOCK:
			data.kenny_fragments = Balance.FRAGMENTS_TO_UNLOCK
			data.kenny_unlocked = true
			return true
		return false
	return false


func _fresh() -> Dictionary:
	return {
		"schema": 1,
		"player_id": _uuid(),
		"display_name": "",
		"yen": 0,
		"takechi_fragments": 0,
		"kenny_fragments": 0,
		"takechi_unlocked": false,
		"kenny_unlocked": false,
		"has_uniform": false,
		"costume": {
			Balance.CHAR_MASSA: "私服",
			Balance.CHAR_TAKETCHI: "私服",
			Balance.CHAR_KENNY: "私服",
		},
		"best_score": 0,
		"best_character": "",
		"best_datetime": "",
		"pending_score": null,
		"selected": Balance.CHAR_MASSA,
	}


func _coerce(parsed: Dictionary) -> Dictionary:
	var base := _fresh()
	base.player_id = str(parsed.get("player_id", base.player_id))
	if base.player_id.length() < 8:
		base.player_id = _uuid()
	base.display_name = str(parsed.get("display_name", ""))
	if base.display_name != "" and not Balance.is_valid_display_name(base.display_name):
		base.display_name = ""
	base.yen = maxi(0, int(parsed.get("yen", 0)))
	base.takechi_fragments = mini(Balance.FRAGMENTS_TO_UNLOCK, maxi(0, int(parsed.get("takechi_fragments", 0))))
	base.kenny_fragments = mini(Balance.FRAGMENTS_TO_UNLOCK, maxi(0, int(parsed.get("kenny_fragments", 0))))
	base.takechi_unlocked = bool(parsed.get("takechi_unlocked", false)) or base.takechi_fragments >= Balance.FRAGMENTS_TO_UNLOCK
	base.kenny_unlocked = bool(parsed.get("kenny_unlocked", false)) or base.kenny_fragments >= Balance.FRAGMENTS_TO_UNLOCK
	if base.takechi_unlocked:
		base.takechi_fragments = Balance.FRAGMENTS_TO_UNLOCK
	if base.kenny_unlocked:
		base.kenny_fragments = Balance.FRAGMENTS_TO_UNLOCK
	var selected := str(parsed.get("selected", Balance.CHAR_MASSA))
	if selected != Balance.CHAR_MASSA and selected != Balance.CHAR_TAKETCHI and selected != Balance.CHAR_KENNY:
		selected = Balance.CHAR_MASSA
	base.selected = selected
	base.has_uniform = bool(parsed.get("has_uniform", false))
	var costume = parsed.get("costume", {})
	if typeof(costume) == TYPE_DICTIONARY:
		for key in base.costume.keys():
			var look := str(costume.get(key, "私服"))
			base.costume[key] = "制服" if look == "制服" else "私服"
	base.best_score = maxi(0, int(parsed.get("best_score", 0)))
	base.best_character = str(parsed.get("best_character", ""))
	base.best_datetime = str(parsed.get("best_datetime", ""))
	var pending = parsed.get("pending_score", null)
	base.pending_score = pending if typeof(pending) == TYPE_DICTIONARY else null
	return base


func _write() -> void:
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("セーブを書けません: %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))


func _park_corrupt() -> void:
	var src := ProjectSettings.globalize_path(path)
	var bak := ProjectSettings.globalize_path(path + ".bak")
	if FileAccess.file_exists(bak):
		DirAccess.remove_absolute(bak)
	DirAccess.rename_absolute(src, bak)


func _now() -> String:
	return Time.get_datetime_string_from_system(false, false)


func _uuid() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var bytes: PackedByteArray = []
	bytes.resize(16)
	for i in 16:
		bytes[i] = rng.randi() % 256
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex := "0123456789abcdef"
	var out := ""
	for i in 16:
		out += hex[bytes[i] >> 4]
		out += hex[bytes[i] & 15]
		if i == 3 or i == 5 or i == 7 or i == 9:
			out += "-"
	return out
