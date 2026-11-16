extends RefCounted
## Resolution scaling for a subtree built in "design units".
##
## Instead of putting a `Control.scale` transform on a card (which resamples text and
## textures at fractional factors), the card is built once in design units and this helper
## writes real pixel sizes: minimum sizes, font sizes, container margins/separations and
## flat-style radii are multiplied by `unit`. The first value seen is remembered in node
## meta ("ub_*"), so repeated calls with different units never compound.
const ButtonSkin = preload("res://ui/button_skin.gd")
const CONSTANTS := ["separation", "h_separation", "v_separation", "margin_left", "margin_top",
	"margin_right", "margin_bottom", "outline_size", "shadow_offset_x", "shadow_offset_y"]
const BUTTON_STATES := ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]


## Mark a free-floating control (not inside a container) with a design-space rectangle.
static func place(c: Control, pos: Vector2, size: Vector2) -> void:
	c.set_meta("ub_rect", [pos, size])
	c.position = pos
	c.size = size


## Mark an anchored control with design-space offsets (left, top, right, bottom).
static func offsets(c: Control, l: float, t: float, r: float, b: float) -> void:
	c.set_meta("ub_off", [l, t, r, b])
	c.offset_left = l
	c.offset_top = t
	c.offset_right = r
	c.offset_bottom = b


static func unit_of(node: Node) -> float:
	var n := node
	while n != null:
		if n.has_meta("unit"):
			return float(n.get_meta("unit"))
		n = n.get_parent()
	return 1.0


static func apply(root: Node, unit: float) -> void:
	if unit <= 0.0:
		return
	_apply_node(root, unit)
	for child in root.get_children():
		apply(child, unit)


static func _apply_node(n: Node, u: float) -> void:
	if not n is Control:
		return
	var c := n as Control
	if not c.has_meta("ub_min"):
		c.set_meta("ub_min", c.custom_minimum_size)
	c.custom_minimum_size = (c.get_meta("ub_min") as Vector2) * u
	if c.has_meta("ub_floor"):
		# Touch targets never shrink below this many real pixels, whatever the unit.
		c.custom_minimum_size = c.custom_minimum_size.max(c.get_meta("ub_floor") as Vector2)
	if c.has_meta("ub_rect"):
		var rect: Array = c.get_meta("ub_rect")
		var wanted := (rect[1] as Vector2) * u
		var pos := (rect[0] as Vector2) * u
		if c.has_meta("ub_floor"):
			# Grow around the centre so a floored touch target stays where it was designed
			# (measured from the requested size: Control.size is already clamped by min size).
			var grown := wanted.max(c.get_meta("ub_floor") as Vector2)
			pos -= (grown - wanted) * 0.5
			wanted = grown
		c.position = pos
		c.size = wanted
	if c.has_meta("ub_off"):
		var o: Array = c.get_meta("ub_off")
		c.offset_left = o[0] * u
		c.offset_top = o[1] * u
		c.offset_right = o[2] * u
		c.offset_bottom = o[3] * u
		if c.has_meta("ub_floor"):
			# Grow toward the left/bottom so a top-right pinned target keeps its corner.
			var f: Vector2 = c.get_meta("ub_floor")
			if c.offset_right - c.offset_left < f.x:
				c.offset_left = c.offset_right - f.x
			if c.offset_bottom - c.offset_top < f.y:
				c.offset_bottom = c.offset_top + f.y
	if c.has_theme_font_size_override("font_size"):
		if not c.has_meta("ub_font"):
			c.set_meta("ub_font", c.get_theme_font_size("font_size"))
		var real_size := maxi(1, roundi(float(c.get_meta("ub_font")) * u))
		if c is Label and c.has_meta("ub_rect") and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF:
			# At a few real pixels the glyph advances round up, so text laid out in design units can
			# come out wider than its box; shrink until it fits the scaled rectangle again.
			var label := c as Label
			var font := label.get_theme_font("font")
			var limit := ((c.get_meta("ub_rect") as Array)[1] as Vector2).x * u
			while real_size > 6 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, real_size).x > limit:
				real_size -= 1
		c.add_theme_font_size_override("font_size", real_size)
		if c is Label and c.has_meta("ub_rect"):
			# The box was sized before the font changed and Label clamps to its old text width.
			c.update_minimum_size()
			c.size = ((c.get_meta("ub_rect") as Array)[1] as Vector2) * u
	for key: String in CONSTANTS:
		if c.has_theme_constant_override(key):
			var meta := "ub_c_" + key
			if not c.has_meta(meta):
				c.set_meta(meta, c.get_theme_constant(key))
			var base: int = c.get_meta(meta)
			c.add_theme_constant_override(key, maxi(1, roundi(base * u)) if base > 0 else base)
	if c is Button:
		_scale_button(c as Button, u)
	for state: String in ["panel", "normal", "focus"]:
		if c.has_theme_stylebox_override(state):
			var sb := c.get_theme_stylebox(state)
			if sb is StyleBoxFlat:
				_scale_flat(sb as StyleBoxFlat, u)
			elif sb is StyleBoxTexture and not sb.has_meta("rounded_button"):
				_scale_texture(sb as StyleBoxTexture, u)


## Nine-slice caps only shrink (never grow) so a small tag keeps its caps inside the box.
static func _scale_texture(sb: StyleBoxTexture, u: float) -> void:
	if not sb.has_meta("ub_tex"):
		var m := []
		for side in 4:
			m.append(sb.get_texture_margin(side))
		var cm := []
		for side in 4:
			cm.append(sb.get_content_margin(side))
		sb.set_meta("ub_tex", [m, cm])
	var base: Array = sb.get_meta("ub_tex")
	for side in 4:
		sb.set_texture_margin(side, (base[0] as Array)[side] * minf(u, 1.0))
		if (base[1] as Array)[side] >= 0.0:
			sb.set_content_margin(side, (base[1] as Array)[side] * u)


static func _scale_flat(sb: StyleBoxFlat, u: float) -> void:
	if not sb.has_meta("ub_flat"):
		var corners := [sb.corner_radius_top_left, sb.corner_radius_top_right, sb.corner_radius_bottom_right, sb.corner_radius_bottom_left]
		var borders := [sb.border_width_left, sb.border_width_top, sb.border_width_right, sb.border_width_bottom]
		var margins := [sb.content_margin_left, sb.content_margin_top, sb.content_margin_right, sb.content_margin_bottom]
		sb.set_meta("ub_flat", [corners, borders, margins])
	var base: Array = sb.get_meta("ub_flat")
	var corners: Array = base[0]
	sb.corner_radius_top_left = roundi(corners[0] * u)
	sb.corner_radius_top_right = roundi(corners[1] * u)
	sb.corner_radius_bottom_right = roundi(corners[2] * u)
	sb.corner_radius_bottom_left = roundi(corners[3] * u)
	var borders: Array = base[1]
	sb.border_width_left = roundi(borders[0] * u)
	sb.border_width_top = roundi(borders[1] * u)
	sb.border_width_right = roundi(borders[2] * u)
	sb.border_width_bottom = roundi(borders[3] * u)
	var margins: Array = base[2]
	for i in 4:
		if margins[i] >= 0.0:
			sb.set_content_margin(i, margins[i] * u)


## The pill button face is a nine-slice texture whose caps cannot be scaled independently of
## the artwork, so it is regenerated at the requested scale (quantised to limit cached textures).
static func _scale_button(b: Button, u: float) -> void:
	var q := clampf(snappedf(u, 0.05), 0.3, 4.0)
	if is_equal_approx(float(b.get_meta("ub_q", -1.0)), q):
		return
	if not b.has_meta("ub_cm"):
		b.set_meta("ub_cm", {})
	var bases: Dictionary = b.get_meta("ub_cm")
	for state: String in BUTTON_STATES:
		if not b.has_theme_stylebox_override(state):
			continue
		var sb := b.get_theme_stylebox(state)
		if not sb.has_meta("rounded_button") or not sb.has_meta("rounded_palette"):
			continue
		if not bases.has(state):
			# First sight of this face: remember its own scale and padding (design units).
			bases[state] = {"scale": float(sb.get_meta("rounded_scale", 1.0)),
				"cm": [sb.content_margin_left, sb.content_margin_top, sb.content_margin_right, sb.content_margin_bottom]}
		var pal: Array = sb.get_meta("rounded_palette")
		var base: Dictionary = bases[state]
		var skin := ButtonSkin.palette(pal[0], pal[1], pal[2], float(base["scale"]) * q)
		skin.modulate_color = (sb as StyleBoxTexture).modulate_color
		var cm: Array = base["cm"]
		for i in 4:
			if cm[i] >= 0.0:
				skin.set_content_margin(i, cm[i] * u)
		b.add_theme_stylebox_override(state, skin)
	b.set_meta("ub_q", q)
