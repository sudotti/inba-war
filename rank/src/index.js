// 印旛村戦線の共有ランキング。1人につき自己ベスト1件。
// 点数の式と上限は scripts/balance.gd と同じ。

const VERSION = "0.1.0";
const CHARS = new Set(["マッサ", "タケッチ", "ケニー"]);
const POINTS = { normal: 10, fast: 30, tank: 200, nimoton: 1800, kassen: 1600, teacher: 120 };
const CAP = { normal: 350, fast: 180, tank: 6, nimoton: 2, kassen: 2, teacher: 6 };

export default {
	async fetch(request, env) {
		if (request.method === "OPTIONS") {
			return cors(new Response(null, { status: 204 }));
		}
		const url = new URL(request.url);
		try {
			if (request.method === "GET" && url.pathname === "/board") {
				return cors(await board(env));
			}
			if (request.method === "POST" && url.pathname === "/score") {
				return cors(await submit(request, env));
			}
			return cors(json({ ok: false, reason: "not found" }, 404));
		} catch (err) {
			return cors(json({ ok: false, reason: "server" }, 500));
		}
	},
};

async function board(env) {
	const rows = await env.DB.prepare(
		`SELECT player_id, display_name, score, character_name, version, achieved_at
		 FROM scores
		 ORDER BY score DESC, achieved_at ASC
		 LIMIT 500`
	).all();
	const entries = (rows.results || []).map((row, index) => ({
		rank: index + 1,
		player_id: row.player_id,
		display_name: row.display_name,
		score: row.score,
		character: row.character_name,
		version: row.version,
		achieved_at: row.achieved_at,
	}));
	return json({ ok: true, entries });
}

async function submit(request, env) {
	let body;
	try {
		body = await request.json();
	} catch (_err) {
		return json({ ok: false, reason: "json" }, 400);
	}
	const checked = check(body);
	if (!checked.ok) {
		return json({ ok: false, reason: checked.reason }, 400);
	}
	const when = tokyoNow();
	await env.DB.prepare(
		`INSERT INTO scores (player_id, display_name, score, character_name, version, achieved_at)
		 VALUES (?1, ?2, ?3, ?4, ?5, ?6)
		 ON CONFLICT(player_id) DO UPDATE SET
		   display_name = excluded.display_name,
		   score = CASE WHEN excluded.score > scores.score THEN excluded.score ELSE scores.score END,
		   character_name = CASE WHEN excluded.score > scores.score THEN excluded.character_name ELSE scores.character_name END,
		   version = CASE WHEN excluded.score > scores.score THEN excluded.version ELSE scores.version END,
		   achieved_at = CASE WHEN excluded.score > scores.score THEN excluded.achieved_at ELSE scores.achieved_at END`
	).bind(
		checked.player_id,
		checked.display_name,
		checked.score,
		checked.character,
		checked.version,
		when
	).run();
	return json({ ok: true });
}

function check(body) {
	if (!body || typeof body !== "object") {
		return { ok: false, reason: "body" };
	}
	const player_id = String(body.player_id || "");
	if (!/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(player_id)) {
		return { ok: false, reason: "player" };
	}
	const display_name = String(body.display_name || "");
	if (display_name !== "ななし" && !validName(display_name)) {
		return { ok: false, reason: "name" };
	}
	const character = String(body.character || "");
	if (!CHARS.has(character)) {
		return { ok: false, reason: "character" };
	}
	const version = String(body.version || "");
	if (version !== VERSION) {
		return { ok: false, reason: "version" };
	}
	const kills = {
		normal: body.kills_normal,
		fast: body.kills_fast,
		tank: body.kills_tank,
		nimoton: body.kills_nimoton ?? 0,
		kassen: body.kills_kassen ?? 0,
		teacher: body.kills_teacher ?? 0,
	};
	for (const key of Object.keys(CAP)) {
		if (!Number.isInteger(kills[key]) || kills[key] < 0 || kills[key] > CAP[key]) {
			return { ok: false, reason: "kills" };
		}
	}
	const score = kills.normal * POINTS.normal
		+ kills.fast * POINTS.fast
		+ kills.tank * POINTS.tank
		+ kills.nimoton * POINTS.nimoton
		+ kills.kassen * POINTS.kassen
		+ kills.teacher * POINTS.teacher;
	if (!Number.isInteger(body.score) || body.score !== score) {
		return { ok: false, reason: "score" };
	}
	return { ok: true, player_id, display_name, score, character, version };
}

function validName(value) {
	const chars = Array.from(value);
	if (chars.length < 1 || chars.length > 10) {
		return false;
	}
	for (const ch of chars) {
		const c = ch.codePointAt(0);
		const digit = c >= 48 && c <= 57;
		const upper = c >= 65 && c <= 90;
		const lower = c >= 97 && c <= 122;
		const hira = c >= 0x3041 && c <= 0x3096;
		const kata = c >= 0x30a1 && c <= 0x30fa;
		const mark = c === 0x30fc || c === 0x30fb;
		const kanji = c >= 0x4e00 && c <= 0x9fff;
		if (!(digit || upper || lower || hira || kata || mark || kanji)) {
			return false;
		}
	}
	return true;
}

function tokyoNow() {
	const shifted = new Date(Date.now() + 9 * 60 * 60 * 1000);
	return shifted.toISOString().slice(0, 19);
}

function json(payload, status = 200) {
	return new Response(JSON.stringify(payload), {
		status,
		headers: { "content-type": "application/json; charset=utf-8" },
	});
}

function cors(response) {
	const headers = new Headers(response.headers);
	headers.set("access-control-allow-origin", "*");
	headers.set("access-control-allow-methods", "GET, POST, OPTIONS");
	headers.set("access-control-allow-headers", "Content-Type, Accept");
	return new Response(response.body, { status: response.status, headers });
}
