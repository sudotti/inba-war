extends RefCounted
class_name Balance

# 企画書の初期値。戦闘の数値はここだけに置く。

const VERSION := "0.1.0"
const TITLE := "印旛村戦線"

const FIELD_W := 1600.0
const FIELD_H := 1100.0
const START := Vector2(800, 550)

const ROUND_SECONDS := 180.0
const BUILD_SELECT_SECONDS := 20.0
const HURT_INTERVAL := 0.5
const INVULN_SECONDS := 1.0
const SPECIAL_GAUGE_MAX := 100.0
const SPECIAL_CHARGE_PER_KILL := 10.0
const SPECIAL_TAKETCHI_SECONDS := 8.0
const SPECIAL_KENNY_SECONDS := 6.0
const SPECIAL_MASSA_RADIUS := 420.0
const SPECIAL_MASSA_DAMAGE_SCALE := 3.0
const SPECIAL_MASSA_KNOCKBACK := 480.0
const SPECIAL_MASSA_MOTION_SECONDS := 1.25
const SPECIAL_TAKETCHI_DAMAGE_SCALE := 1.8
const SPECIAL_TAKETCHI_ATTACK_SCALE := 0.5
const SPECIAL_TAKETCHI_MOTION_SECONDS := 0.95
const SPECIAL_KENNY_ATTACK_INTERVAL := 0.12
const SPECIAL_KENNY_MOTION_SECONDS := 0.85


const MAX_ALIVE := 60
const DESPAWN_DISTANCE := 860.0
const SPAWN_MAX_DISTANCE := 800.0
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

const KILL_CAP_NORMAL := 350
const KILL_CAP_FAST := 180
const KILL_CAP_TANK := 6

const KIND_NORMAL := "normal"
const KIND_FAST := "fast"
const KIND_TANK := "tank"
const KIND_NIMOTON := "boss_nimoton"
const KIND_KASSEN := "boss_kassen"
const KIND_TEACHER := "teacher"
const BOSS_KINDS: Array[String] = [KIND_NIMOTON, KIND_KASSEN]
const RAID_KINDS: Array[String] = [KIND_TEACHER]
const BOSS_SPAWN_CHANCE := 0.12
const BOSS_NAME := {
	KIND_NIMOTON: "ニーモトン",
	KIND_KASSEN: "カッセン",
}
const ENEMY_KINDS: Array[String] = [KIND_NORMAL, KIND_FAST, KIND_TANK, KIND_NIMOTON, KIND_KASSEN, KIND_TEACHER]
const ENEMY_KILL_SUMMARY := {
	KIND_NORMAL: "kills_normal",
	KIND_FAST: "kills_fast",
	KIND_TANK: "kills_tank",
	KIND_NIMOTON: "kills_nimoton",
	KIND_KASSEN: "kills_kassen",
	KIND_TEACHER: "kills_teacher",
}
const ENEMY_NAME := {
	KIND_NORMAL: "黒服の手下",
	KIND_FAST: "赤目のイノシシ",
	KIND_TANK: "印旛沼の怪獣",
	KIND_NIMOTON: "ニーモトン",
	KIND_KASSEN: "カッセン",
	KIND_TEACHER: "先生",
}
const ENEMY_DESCRIPTION := {
	KIND_NORMAL: "数で迫る黒服。囲まれる前に距離を取れ。",
	KIND_FAST: "一直線に突っ込む。進路を読んでかわす。",
	KIND_TANK: "巨体と一撃が脅威。吹き飛ばしにくい。",
	KIND_NIMOTON: "毒液で地面を侵し、手下を覚醒させる。",
	KIND_KASSEN: "バレーボール弾と強烈な蹴りで襲う。",
	KIND_TEACHER: "校庭に乱入。教鞭を振り回し、スライディングで突っ込む。",
}
const ENEMY_SPECIAL := {
	KIND_TEACHER: "スライディング突進",
}
const BOSS_POISON := "poison"
const BOSS_VOLLEY := "volley"
const BOSS_SPECIAL := {
	KIND_NIMOTON: "毒液シャワー",
	KIND_KASSEN: "バレーボール弾",
}
const RAID_SPAWN_FIRST := 60.0
const RAID_SPAWN_INTERVAL := 40.0
const TANK_SPAWN_FIRST := 75.0
const TANK_SPAWN_INTERVAL := 50.0

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
const SPECIAL_QUOTES := {
	CHAR_MASSA: "印旛の未来は僕が守るっ！",
	CHAR_TAKETCHI: "こいつら蹴散らしたら、銭湯行かね？",
	CHAR_KENNY: "私の勝利に、100ｲｪﾝ賭けます。",
}

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
		"speed": 120.0,
		"touch": 6,
		"radius": 16.0,
		"knockback_scale": 1.0,
	},
	KIND_FAST: {
		"hp": 32,
		"speed": 220.0,
		"touch": 10,
		"radius": 20.0,
		"knockback_scale": 1.0,
	},
	KIND_TANK: {
		"hp": 200,
		"speed": 85.0,
		"touch": 16,
		"radius": 48.0,
		"knockback_scale": 0.35,
	},
	KIND_NIMOTON: {
		"hp": 1280,
		"speed": 115.0,
		"touch": 32,
		"radius": 62.0,
		"knockback_scale": 0.08,
	},
	KIND_KASSEN: {
		"hp": 1040,
		"speed": 140.0,
		"touch": 38,
		"radius": 54.0,
		"knockback_scale": 0.12,
	},
	KIND_TEACHER: {
		"hp": 86,
		"speed": 165.0,
		"touch": 12,
		"radius": 26.0,
		"knockback_scale": 0.6,
	},
}

const SCORE := {
	KIND_NORMAL: 10,
	KIND_FAST: 30,
	KIND_TANK: 200,
	KIND_NIMOTON: 1800,
	KIND_KASSEN: 1600,
	KIND_TEACHER: 120,
}

const COIN_CHANCE := {
	KIND_NORMAL: 0.40,
	KIND_FAST: 0.70,
	KIND_TANK: 1.0,
	KIND_NIMOTON: 1.0,
	KIND_KASSEN: 1.0,
	KIND_TEACHER: 0.85,
}

const COIN_COUNT := {
	KIND_NORMAL: 1,
	KIND_FAST: 1,
	KIND_TANK: 3,
	KIND_NIMOTON: 10,
	KIND_KASSEN: 8,
	KIND_TEACHER: 2,
}

const KIND_LABEL := {
	KIND_NORMAL: "通常",
	KIND_FAST: "高速",
	KIND_TANK: "耐久",
	KIND_NIMOTON: "ニーモトン",
	KIND_KASSEN: "カッセン",
	KIND_TEACHER: "先生",
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


static func special_motion_seconds(who: String) -> float:
	if who == CHAR_TAKETCHI:
		return SPECIAL_TAKETCHI_MOTION_SECONDS
	if who == CHAR_KENNY:
		return SPECIAL_KENNY_MOTION_SECONDS
	return SPECIAL_MASSA_MOTION_SECONDS


static func score_from_kills(normal: int, fast: int, tank: int, nimoton: int = 0, kassen: int = 0, teacher: int = 0) -> int:
	return (
		normal * SCORE[KIND_NORMAL]
		+ fast * SCORE[KIND_FAST]
		+ tank * SCORE[KIND_TANK]
		+ nimoton * SCORE[KIND_NIMOTON]
		+ kassen * SCORE[KIND_KASSEN]
		+ teacher * SCORE[KIND_TEACHER]
	)


static func kills_within_cap(normal: int, fast: int, tank: int) -> bool:
	return (
		normal >= 0 and normal <= KILL_CAP_NORMAL
		and fast >= 0 and fast <= KILL_CAP_FAST
		and tank >= 0 and tank <= KILL_CAP_TANK
	)


static func spawn_profile(elapsed: float) -> Dictionary:
	if elapsed < 45.0:
		return {"interval": 0.60, "fast": 0.0}
	if elapsed < 75.0:
		return {"interval": 0.47, "fast": 0.20}
	if elapsed < 120.0:
		return {"interval": 0.37, "fast": 0.30}
	return {"interval": 0.28, "fast": 0.40}


static func kind_for_roll(elapsed: float, roll: float) -> String:
	if roll < float(spawn_profile(elapsed).fast):
		return KIND_FAST
	return KIND_NORMAL


static func upgrade_blurb(id: String, next_level: int) -> String:
	match id:
		BUTTO:
			return "攻撃力 +%d%% / 吹き飛ばし +%d%%" % [15 * next_level, 15 * next_level]
		ONIGIRI:
			return "最大HP +%d / 増加分を即時回復" % (20 * next_level)
		KENKYAKU:
			return "移動速度 +%d%%" % (8 * next_level)
		KANE:
			return "コイン回収範囲 +%d" % int(magnet_radius(next_level))
		PURITORA:
			return "周囲をスタン / %.1f秒間隔・半径 %d" % [puritora_interval(next_level), int(puritora_radius(next_level))]
		MEGUMI:
			return "10撃破ごとにHP %d回復" % megumi_heal(next_level)
		OKOZUKAI:
			return "獲得コイン +%d%%" % (25 * next_level)
		MAAI:
			return "自動攻撃範囲 +%d%%" % (14 * next_level)
		RENDA:
			return "攻撃間隔 -%d%%" % (8 * next_level)
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
