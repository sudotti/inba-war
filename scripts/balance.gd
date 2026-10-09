extends RefCounted
class_name Balance

# 企画書の初期値。戦闘の数値はここだけに置く。

const VERSION := "0.1.0"
const TITLE := "印旛村戦線"

const FIELD_W := 2400.0
const FIELD_H := 1600.0
const START := Vector2(1200, 800)

const ROUND_SECONDS := 180.0
const BUILD_SELECT_SECONDS := 20.0
const HURT_INTERVAL := 0.5
const INVULN_SECONDS := 1.0

const MAX_ALIVE := 60
const DESPAWN_DISTANCE := 900.0
const SPAWN_MAX_DISTANCE := 860.0
const SPAWN_OUTSIDE_MARGIN := 28.0

const PICKUP_RADIUS := 28.0
const MAGNET_BASE := 70.0
const MAGNET_PER_LEVEL := 40.0
# 吸い込みの速さは企画書に無い。70pxを一瞬で回収する速さ。
const COIN_PULL_SPEED := 900.0

const UNIFORM_PRICE := 600
const FRAGMENT_PRICE := 400
const FRAGMENT_EXCHANGE := 300
const FRAGMENTS_TO_UNLOCK := 5

# 衣装はここに足す。所持判定は SaveStore.owns_look。
const LOOKS: Array[Dictionary] = [
	{"id": "私服", "label": "私服"},
	{"id": "制服", "label": "制服"},
]

const PURITORA_RADIUS := 160.0
const STUN_SECONDS := 1.2
const STUN_TANK_SECONDS := 0.6

const UPGRADE_MAX := 5
const CONE_RADIUS := 22.0

const KILL_CAP_NORMAL := 350
const KILL_CAP_FAST := 180
const KILL_CAP_TANK := 6

const KIND_NORMAL := "normal"
const KIND_FAST := "fast"
const KIND_TANK := "tank"

const BUTTO := "buttobashi"
const ONIGIRI := "onigiri"
const KENKYAKU := "kenkyaku"
const KANE := "kane"
const PURITORA := "puritora"
const MEGUMI := "megumi"
const OKOZUKAI := "okozukai"
const MAAI := "maai"
const RENDA := "renda"

const UPGRADES: Array[String] = [
	BUTTO, ONIGIRI, KENKYAKU, KANE, PURITORA, MEGUMI, OKOZUKAI, MAAI, RENDA,
]

const CHAR_MASSA := "マッサ"
const CHAR_TAKETCHI := "タケッチ"
const CHAR_KENNY := "ケニー"

const CHARACTERS := {
	CHAR_MASSA: {
		"max_hp": 100,
		"speed": 155.0,
		"radius": 22.0,
		"attack_interval": 1.0,
		"attack_radius": 136.0,
		"attack": 14,
		"knockback": 180.0,
		"damage_taken_scale": 1.0,
	},
	CHAR_TAKETCHI: {
		"max_hp": 120,
		"speed": 175.0,
		"radius": 26.0,
		"attack_interval": 0.62,
		"attack_radius": 90.0,
		"attack": 26,
		"knockback": 40.0,
		"damage_taken_scale": 1.0,
	},
	CHAR_KENNY: {
		"max_hp": 100,
		"speed": 230.0,
		"radius": 22.0,
		"attack_interval": 0.75,
		"attack_radius": 100.0,
		"attack": 16,
		"knockback": 90.0,
		"damage_taken_scale": 0.80,
	},
}

const ENEMIES := {
	KIND_NORMAL: {
		"hp": 12,
		"speed": 80.0,
		"touch": 6,
		"radius": 16.0,
		"knockback_scale": 1.0,
	},
	KIND_FAST: {
		"hp": 32,
		"speed": 175.0,
		"touch": 10,
		"radius": 20.0,
		"knockback_scale": 1.0,
	},
	KIND_TANK: {
		"hp": 200,
		"speed": 55.0,
		"touch": 16,
		"radius": 48.0,
		"knockback_scale": 0.35,
	},
}

const SCORE := {
	KIND_NORMAL: 10,
	KIND_FAST: 30,
	KIND_TANK: 200,
}

const COIN_CHANCE := {
	KIND_NORMAL: 0.40,
	KIND_FAST: 0.70,
	KIND_TANK: 1.0,
}

const COIN_COUNT := {
	KIND_NORMAL: 1,
	KIND_FAST: 1,
	KIND_TANK: 3,
}

const KIND_LABEL := {
	KIND_NORMAL: "通常",
	KIND_FAST: "高速",
	KIND_TANK: "耐久",
}

const UPGRADE_NAME := {
	BUTTO: "ぶっ飛ばすよ?",
	ONIGIRI: "ばあちゃんのおにぎり",
	KENKYAKU: "田舎の健脚",
	KANE: "金欲しくね",
	PURITORA: "プリとらね?",
	MEGUMI: "印旛沼の恵み",
	OKOZUKAI: "お小遣い",
	MAAI: "間合い",
	RENDA: "連打",
}

const UPGRADE_SHORT := {
	BUTTO: "ぶっ飛ばす",
	ONIGIRI: "おにぎり",
	KENKYAKU: "健脚",
	KANE: "金",
	PURITORA: "プリとら",
	MEGUMI: "恵み",
	OKOZUKAI: "お小遣い",
	MAAI: "間合い",
	RENDA: "連打",
}

const CONE_POINTS: Array[Vector2] = [
	Vector2(520, 700), Vector2(600, 780), Vector2(540, 880),
	Vector2(1800, 980), Vector2(1900, 900), Vector2(1760, 1100),
	Vector2(1200, 360), Vector2(1320, 420), Vector2(1080, 440),
]

# 遊んだあとの間隔。6体で最初、そのあと差が少しずつ開く。
const BUILD_PRESET: Array[int] = [6, 15, 27, 42, 60, 80, 102]


static func build_threshold(index: int) -> int:
	if index < BUILD_PRESET.size():
		return BUILD_PRESET[index]
	return 102 + (index - 6) * 24


static func scaled_hp(base_hp: int, elapsed: float) -> int:
	var t := clampf(elapsed, 0.0, ROUND_SECONDS)
	var mul := 1.0 + t / ROUND_SECONDS * 0.8
	return ceili(float(base_hp) * mul)


static func attack_damage(base_atk: int, butto_level: int) -> int:
	return floori(float(base_atk) * (1.0 + 0.15 * float(butto_level)))


static func move_speed(base_speed: float, kenkyaku_level: int) -> float:
	return base_speed * (1.0 + 0.08 * float(kenkyaku_level))


static func magnet_radius(kane_level: int) -> float:
	return maxf(PICKUP_RADIUS, MAGNET_BASE + MAGNET_PER_LEVEL * float(kane_level))


static func coin_gain(raw_coins: int, okozukai_level: int) -> float:
	return float(raw_coins) * (1.0 + 0.25 * float(okozukai_level))


static func puritora_interval(level: int) -> float:
	return 8.0 - float(level - 1) * 1.2


static func puritora_radius(level: int) -> float:
	return PURITORA_RADIUS + float(maxi(level - 1, 0)) * 36.0


static func pose_path(who: String, pose: String, uniform: bool) -> String:
	var id := "massa"
	if who == CHAR_TAKETCHI:
		id = "taketchi"
	elif who == CHAR_KENNY:
		id = "kenny"
	if uniform:
		return "res://assets/battle/uniform/%s_%s.png" % [id, pose]
	return "res://assets/battle/%s_%s.png" % [id, pose]


static func megumi_heal(level: int) -> int:
	return 4 + (level - 1) * 3


static func apply_damage_scale(raw: int, scale: float) -> int:
	return floori(float(raw) * scale)


static func score_from_kills(normal: int, fast: int, tank: int) -> int:
	return normal * SCORE[KIND_NORMAL] + fast * SCORE[KIND_FAST] + tank * SCORE[KIND_TANK]


static func kills_within_cap(normal: int, fast: int, tank: int) -> bool:
	return (
		normal >= 0 and normal <= KILL_CAP_NORMAL
		and fast >= 0 and fast <= KILL_CAP_FAST
		and tank >= 0 and tank <= KILL_CAP_TANK
	)


static func spawn_profile(elapsed: float) -> Dictionary:
	if elapsed < 45.0:
		return {"interval": 0.90, "fast": 0.0}
	if elapsed < 75.0:
		return {"interval": 0.70, "fast": 0.20}
	if elapsed < 120.0:
		return {"interval": 0.55, "fast": 0.30}
	return {"interval": 0.42, "fast": 0.40}


static func kind_for_roll(elapsed: float, roll: float) -> String:
	if roll < float(spawn_profile(elapsed).fast):
		return KIND_FAST
	return KIND_NORMAL


static func upgrade_blurb(id: String, next_level: int) -> String:
	match id:
		BUTTO:
			return "重く飛ばす。攻撃 +%d%%、吹き飛ばし +%d%%" % [15 * next_level, 15 * next_level]
		ONIGIRI:
			return "その場で 20 回復。最大HP +%d" % (20 * next_level)
		KENKYAKU:
			return "足が速くなる。移動 +%d%%" % (8 * next_level)
		KANE:
			return "コインが寄ってくる。半径 %d" % int(magnet_radius(next_level))
		PURITORA:
			return "周りを止める。%.1f秒ごと、半径 %d" % [puritora_interval(next_level), int(puritora_radius(next_level))]
		MEGUMI:
			return "10体倒すごとに %d 回復" % megumi_heal(next_level)
		OKOZUKAI:
			return "コインが増える。+%d%%" % (25 * next_level)
		MAAI:
			return "攻撃が遠くまで届く。範囲 +%d%%" % (14 * next_level)
		RENDA:
			return "攻撃が早く出る。間隔 -%d%%" % (8 * next_level)
	return ""


static func is_valid_display_name(s: String) -> bool:
	var n := s.length()
	if n < 1 or n > 10:
		return false
	for i in n:
		if not _is_name_char(s.unicode_at(i)):
			return false
	return true


static func shown_display_name(stored: String) -> String:
	if stored == "":
		return "ななし"
	return stored


static func _is_name_char(c: int) -> bool:
	if c >= 48 and c <= 57:
		return true
	if c >= 65 and c <= 90:
		return true
	if c >= 97 and c <= 122:
		return true
	if c >= 0x3041 and c <= 0x3096:
		return true
	if c >= 0x30A1 and c <= 0x30FA:
		return true
	if c == 0x30FC or c == 0x30FB:
		return true
	if c >= 0x4E00 and c <= 0x9FFF:
		return true
	return false
