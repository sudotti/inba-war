extends SceneTree

# 乱入キャラ「先生」のスプライトを生成する。頭・スーツ・教鞭をベクター描画。

const W := 640
const H := 640

var img := Image.create(W, H, false, Image.FORMAT_RGBA8)


func _initialize() -> void:
	img.fill(Color(0, 0, 0, 0))
	_draw_teacher()
	var ok := img.save_png("res://assets/battle/teacher.png")
	print("saved teacher.png: ", ok)
	quit(0)


func _draw_teacher() -> void:
	var skin := Color("f2c9a0")
	var skin_shade := Color("d9a97c")
	var suit := Color("232a3d")
	var suit_dark := Color("181d2c")
	var shirt := Color("f4f1e6")
	var tie := Color("c23b3b")
	var hair := Color("3a3128")
	var shoe := Color("241d16")
	var stick := Color("d8a54a")
	var brow := Color("2a2119")

	# 影（足元）
	_ellipse(Vector2(320, 600), 150, 34, Color(0, 0, 0, 0.30))

	# 脚
	rect(Vector2(268, 470), 56, 108, suit_dark)
	rect(Vector2(316, 470), 56, 108, suit_dark)
	# 靴
	rect(Vector2(252, 566), 76, 34, shoe)
	rect(Vector2(312, 566), 76, 34, shoe)

	# スーツの胴
	rect(Vector2(238, 300), 164, 190, suit)
	# シャツの V
	poly(PackedVector2Array([Vector2(320, 312), Vector2(272, 336), Vector2(368, 336)]), shirt)
	# ネクタイ
	poly(PackedVector2Array([Vector2(320, 330), Vector2(306, 344), Vector2(320, 420), Vector2(334, 344)]), tie)
	# 襟
	poly(PackedVector2Array([Vector2(320, 312), Vector2(272, 336), Vector2(292, 342)]), shirt)
	poly(PackedVector2Array([Vector2(320, 312), Vector2(368, 336), Vector2(348, 342)]), shirt)

	# 左腕（体側）
	rect(Vector2(214, 316), 40, 128, suit)
	circle(Vector2(234, 452), 24, skin)
	# 右腕（上げて教鞭を持つ）
	var arm := PackedVector2Array([Vector2(382, 320), Vector2(436, 268), Vector2(462, 292), Vector2(408, 344)])
	poly(arm, suit)
	circle(Vector2(452, 282), 26, skin)
	# 教鞭
	var p1 := Vector2(462, 262)
	var p2 := Vector2(560, 140)
	draw_line_thick(p1, p2, 12, stick)
	circle(p2, 9, Color("fff3d0"))

	# 頭
	circle(Vector2(320, 218), 92, skin)
	# 髪（後ろと横）
	circle(Vector2(320, 196), 94, hair)
	rect(Vector2(228, 196), 184, 40, hair)
	# 額を少し出す
	rect(Vector2(236, 214), 168, 26, skin)
	# 耳
	circle(Vector2(228, 224), 16, skin)
	circle(Vector2(412, 224), 16, skin)
	# メガネ（先生らしさ）は目の下に敷く
	var glass := Color(1, 1, 1, 0.22)
	circle(Vector2(284, 232), 25, glass)
	circle(Vector2(356, 232), 25, glass)
	# 怒り眉
	poly(PackedVector2Array([Vector2(262, 196), Vector2(306, 208), Vector2(306, 220), Vector2(262, 210)]), brow)
	poly(PackedVector2Array([Vector2(378, 196), Vector2(334, 208), Vector2(334, 220), Vector2(378, 210)]), brow)
	# 目
	circle(Vector2(284, 232), 11, Color("241a12"))
	circle(Vector2(356, 232), 11, Color("241a12"))
	circle(Vector2(287, 228), 3, Color("ffffff"))
	circle(Vector2(359, 228), 3, Color("ffffff"))
	# 鼻
	poly(PackedVector2Array([Vector2(320, 240), Vector2(310, 262), Vector2(330, 262)]), skin_shade)
	# 口（怒り）
	rect(Vector2(296, 282), 48, 10, brow)
	# 口端
	poly(PackedVector2Array([Vector2(296, 282), Vector2(288, 276), Vector2(296, 292)]), brow)
	poly(PackedVector2Array([Vector2(344, 282), Vector2(352, 276), Vector2(344, 292)]), brow)
	# メガネの枠
	draw_line_thick(Vector2(309, 232), Vector2(331, 232), 5, brow)
	draw_circle_outline(Vector2(284, 232), 25, brow)
	draw_circle_outline(Vector2(356, 232), 25, brow)
	draw_line_thick(Vector2(260, 230), Vector2(228, 222), 5, brow)
	draw_line_thick(Vector2(380, 230), Vector2(412, 222), 5, brow)


func rect(p: Vector2, w: float, h: float, c: Color) -> void:
	for y in int(h):
		for x in int(w):
			var px := int(p.x) + x
			var py := int(p.y) + y
			if px >= 0 and px < W and py >= 0 and py < H:
				img.set_pixel(px, py, c)


func circle(c: Vector2, r: float, col: Color) -> void:
	for y in range(int(-r) - 1, int(r) + 2):
		for x in range(int(-r) - 1, int(r) + 2):
			if x * x + y * y <= r * r:
				var px := int(c.x) + x
				var py := int(c.y) + y
				if px >= 0 and px < W and py >= 0 and py < H:
					img.set_pixel(px, py, col)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	for y in range(int(-ry) - 1, int(ry) + 2):
		for x in range(int(-rx) - 1, int(rx) + 2):
			if (x * x) / (rx * rx) + (y * y) / (ry * ry) <= 1.0:
				var px := int(c.x) + x
				var py := int(c.y) + y
				if px >= 0 and px < W and py >= 0 and py < H:
					img.set_pixel(px, py, col)


func poly(points: PackedVector2Array, col: Color) -> void:
	# 単純なスキャンライン塗りつぶし（凸多角形対応）
	var min_y := 1e9
	var max_y := -1e9
	for p in points:
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	for y in range(int(floor(min_y)), int(ceil(max_y)) + 1):
		var xs: Array = []
		for i in points.size():
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
				var t := (y - a.y) / (b.y - a.y)
				xs.append(a.x + t * (b.x - a.x))
		xs.sort()
		for i in range(0, xs.size() - 1, 2):
			var x0 := int(xs[i])
			var x1 := int(xs[i + 1])
			for x in range(x0, x1 + 1):
				if x >= 0 and x < W and y >= 0 and y < H:
					img.set_pixel(x, y, col)


func draw_circle_outline(c: Vector2, r: float, col: Color) -> void:
	var steps := 72
	for i in steps:
		var ang := float(i) / float(steps) * TAU
		circle(c + Vector2(cos(ang) * r, sin(ang) * r), 3.0, col)


func draw_line_thick(a: Vector2, b: Vector2, width: float, col: Color) -> void:
	var steps := int(a.distance_to(b) * 2.0)
	for i in steps + 1:
		var t := float(i) / float(steps)
		var p := a.lerp(b, t)
		circle(p, width * 0.5, col)
