extends RefCounted
## Procedural toy scenery. Built on resize and drawn only in RaceView's cached layer.
static var _styles: Dictionary = {}

static func rounded(ci: CanvasItem, rect: Rect2, color: Color, radius: float) -> void:
	var key := "%s/%d" % [color.to_html(), int(radius)]
	var style: StyleBoxFlat = _styles.get(key)
	if style == null:
		style = StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(int(radius))
		style.corner_detail = 6
		_styles[key] = style
	ci.draw_style_box(style, rect)


static func oval(ci: CanvasItem, center: Vector2, radius: Vector2, color: Color) -> void:
	var polygon := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		polygon.append(center + Vector2(cos(a), sin(a)) * radius)
	ci.draw_colored_polygon(polygon, color)


static func board(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_rect(rect.grow(10), Color("c6e7e7"))
	rounded(ci, Rect2(rect.position + Vector2(1, 5), rect.size), Color("9dc4c4"), 16)
	rounded(ci, Rect2(rect.position + Vector2(0, 3), rect.size), Color("a2c297"), 15)
	rounded(ci, rect, Color("b6daa5"), 15)
	var stripe_height := maxf(12.0, rect.size.y / 9.0)
	var y := rect.position.y + 11.0
	while y < rect.end.y - 8.0:
		ci.draw_rect(Rect2(rect.position.x + 5.0, y, rect.size.x - 10.0, minf(stripe_height, rect.end.y - 8.0 - y)), Color("bfdfb0"))
		y += stripe_height * 2.0


static func clearance(p: Vector2, mid: PackedVector2Array, left: PackedVector2Array) -> float:
	var best := INF
	for i in range(0, mid.size() - 1, 2):
		var next := mini(i + 2, mid.size() - 1)
		var nearest := Geometry2D.get_closest_point_to_segment(p, mid[i], mid[next])
		best = minf(best, p.distance_to(nearest) - mid[i].distance_to(left[i]))
	return best


static func build(mid: PackedVector2Array, left: PackedVector2Array, rect: Rect2, salt: int) -> Array:
	var props: Array = []
	var unit := clampf(minf(rect.size.x / 350.0, rect.size.y / 190.0), 0.65, 1.4)
	var candidates: Array = []
	var safe := rect.grow(-20.0 * unit)
	for row in 13:
		for col in 19:
			var p := safe.position + safe.size * Vector2(float(col) / 18.0, float(row) / 12.0)
			candidates.append({"p": p, "room": clearance(p, mid, left), "inside": Geometry2D.is_point_in_polygon(p, mid)})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.room) > float(b.room))
	for kind: String in ["garage", "pond"]:
		var radius := (24.0 if kind == "garage" else 17.0) * unit
		for candidate: Dictionary in candidates:
			if not candidate.inside or float(candidate.room) < radius:
				continue
			var clear := true
			for prop: Dictionary in props:
				if (candidate.p as Vector2).distance_to(prop.p) < radius + float(prop.radius) + 4.0:
					clear = false
			if clear:
				props.append({"kind": kind, "p": candidate.p, "u": unit, "radius": radius})
				break
	# Seeded placements avoid the track and each other on every circuit, at every width.
	var rng := RandomNumberGenerator.new()
	rng.seed = salt
	for attempt in 120:
		if props.size() >= 8:
			break
		var p := safe.position + safe.size * Vector2(rng.randf(), rng.randf())
		var radius := 16.0 * unit
		if clearance(p, mid, left) < radius:
			continue
		var clear := true
		for prop: Dictionary in props:
			if p.distance_to(prop.p) < radius + float(prop.radius):
				clear = false
		if clear:
			props.append({"kind": "pine" if attempt % 3 == 0 else "tree", "p": p, "u": unit * rng.randf_range(0.8, 1.1), "radius": radius})
	props.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a.p as Vector2).y < (b.p as Vector2).y)
	return props


static func draw_props(ci: CanvasItem, props: Array) -> void:
	for prop: Dictionary in props:
		var p: Vector2 = prop.p
		var u: float = prop.u
		match String(prop.kind):
			"garage":
				var garage := HdUi.Soft.icon("garage")
				if garage != null:
					ci.draw_texture_rect(garage, Rect2(p + Vector2(-25, -28) * u, Vector2(50, 44) * u), false)
					continue
				oval(ci, p + Vector2(4, 6) * u, Vector2(23, 7) * u, Color("709b65"))
				rounded(ci, Rect2(p + Vector2(-17, -7) * u, Vector2(36, 19) * u), Color("c9bd9a"), 2)
				rounded(ci, Rect2(p + Vector2(-19, -9) * u, Vector2(36, 18) * u), Color("ffedc8"), 2)
				for i in 3:
					rounded(ci, Rect2(p + Vector2(-16 + i * 11, -3) * u, Vector2(8, 12) * u), Color("39535c"), 1)
				rounded(ci, Rect2(p + Vector2(-22, -15) * u, Vector2(44, 7) * u), Color("ba5d48"), 2)
				rounded(ci, Rect2(p + Vector2(-23, -17) * u, Vector2(44, 5) * u), Color("ee9570"), 2)
				ci.draw_line(p + Vector2(-20, -14) * u, p + Vector2(18, -14) * u, Color("ffbd91"), u)
			"pond":
				oval(ci, p + Vector2(2, 3) * u, Vector2(16, 10) * u, Color("719c65"))
				oval(ci, p, Vector2(16, 10) * u, Color("d8d9b2"))
				oval(ci, p + Vector2(0, -1) * u, Vector2(13, 7) * u, Color("67b4b0"))
				oval(ci, p + Vector2(-3, -3) * u, Vector2(8, 3) * u, Color("97d2bd"))
				ci.draw_line(p + Vector2(-7, 0) * u, p + Vector2(2, 0) * u, Color("e0ecce"), u)
			_:
				oval(ci, p + Vector2(4, 3) * u, Vector2(9, 4) * u, Color("729b64"))
				ci.draw_line(p, p + Vector2(0, -12) * u, Color("8c714e"), 3 * u)
				if String(prop.kind) == "pine":
					for i in 3:
						var y := -25.0 + float(i) * 6.0
						ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, y) * u, p + Vector2(8 - i, y + 15) * u, p + Vector2(-8 + i, y + 15) * u]), [Color("6cae83"), Color("84bf94"), Color("a4d2a5")][i])
				else:
					ci.draw_circle(p + Vector2(2, -9) * u, 9 * u, Color("77b88d"))
					ci.draw_circle(p + Vector2(-3, -13) * u, 8 * u, Color("96c99d"))
					ci.draw_circle(p + Vector2(0, -17) * u, 7 * u, Color("b0d7aa"))
					ci.draw_circle(p + Vector2(-2, -20) * u, 3 * u, Color("c7e6bb"))


static func start_flag(ci: CanvasItem, p: Vector2, u: float) -> void:
	oval(ci, p + Vector2(2, 1) * u, Vector2(4, 2) * u, Color("779d68"))
	ci.draw_line(p, p + Vector2(0, -15) * u, Color("526b69"), 1.5 * u)
	for row in 3:
		for column in 4:
			ci.draw_rect(Rect2(p + Vector2(column * 2, -15 + row * 2) * u, Vector2.ONE * 2.0 * u), Color("fff0d0") if (row + column) % 2 == 0 else Color("354d55"))


static func car(ci: CanvasItem, p: Vector2, heading: float, half_length: float, color: Color, decal: String, contrast: Color) -> void:
	var u := half_length / 8.0
	ci.draw_set_transform(p + Vector2(1, 2), heading, Vector2.ONE * u)
	oval(ci, Vector2.ZERO, Vector2(9, 4.7), Color(0.12, 0.22, 0.25, 0.25))
	ci.draw_set_transform(p, heading, Vector2.ONE * u)
	for x: float in [-5.0, 4.5]:
		for y: float in [-4.5, 3.0]:
			rounded(ci, Rect2(x, y, 3.5, 2.0), Color("263a40"), 1)
	rounded(ci, Rect2(-8, -4.0, 16, 8), Color("30434a"), 3)
	rounded(ci, Rect2(-7.5, -4.5, 15, 7.5), color, 3)
	rounded(ci, Rect2(-6, -4, 11, 1.5), color.lightened(0.35), 1)
	match decal:
		"double_stripe":
			for y: float in [-1.8, 0.8]:
				ci.draw_rect(Rect2(-6, y, 12, 1), contrast)
		"lightning":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-5, 1), Vector2(1, -3), Vector2(0, -0.5), Vector2(5, -1), Vector2(-1, 3), Vector2(0, 0.5)]), contrast)
		"checker":
			for x in 3:
				for y in 2:
					if (x + y) % 2 == 0:
						ci.draw_rect(Rect2(3 + x, -1 + y, 1, 1), contrast)
	rounded(ci, Rect2(-2, -3, 5, 5), Color("2c4b59"), 1)
	ci.draw_line(Vector2(0, -2.5), Vector2(2, -2.5), Color("a7d5d2"), 1)
	ci.draw_line(Vector2(5.5, -2), Vector2(6.5, -2), Color("fff2c4"), 1)
	ci.draw_line(Vector2(5.5, 1), Vector2(6.5, 1), Color("fff2c4"), 1)
	ci.draw_line(Vector2(-7, -4), Vector2(-7, 3), color.darkened(0.25), 1)
	ci.draw_set_transform(Vector2.ZERO)
