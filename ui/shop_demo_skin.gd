extends RefCounted
## Shop-only art direction. Other pages keep their current skin.
const ROOT := "res://assets/shop_blue_white/"
const INK := Color("102d60")
static var _source: Dictionary = {}

static func region_picture(region: Rect2) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ROOT + "demo_reference.png")
	atlas.region = region
	atlas.filter_clip = true
	var t := TextureRect.new()
	t.texture = atlas
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

## Atlas regions from the supplied demo; copy the original without resampling.
static func demo_picture(id: String, extent: Vector2) -> TextureRect:
	var regions := {
		"starter_1": Rect2(39, 274, 184, 186),
		"char_my": Rect2(40, 817, 155, 132),
		"char_lam": Rect2(40, 960, 155, 124),
		"driver_coupon": Rect2(326, 329, 59, 42),
		"gear_coupon": Rect2(402, 326, 59, 43),
		"elite_gear": Rect2(369, 865, 58, 52),
		"shard_my": Rect2(212, 860, 69, 62),
		"shard_lam": Rect2(212, 1004, 69, 62),
		"daily_gear": Rect2(641, 435, 108, 83),
		"daily_driver": Rect2(914, 434, 115, 82),
	}
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ROOT + "demo_reference.png")
	atlas.region = regions[id]
	atlas.filter_clip = true
	var t := TextureRect.new()
	t.texture = atlas
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = extent
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func surface(id: String, margin: float = 8.0) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(ROOT + id + ".svg")
	s.texture_margin_left = 16
	s.texture_margin_right = 16
	s.texture_margin_top = 16 if id in ["banner", "free", "tile"] else 12
	s.texture_margin_bottom = s.texture_margin_top
	s.set_content_margin_all(margin)
	return s

static func picture(id: String, extent: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(ROOT + "sprites/" + id + ".tres")
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = extent
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return t

static func portrait(sku: String, extent: Vector2) -> TextureRect:
	if _source.is_empty():
		_source = JSON.parse_string(FileAccess.get_file_as_string("res://assets/iap_offers/manifest.json"))
	var recipe: Dictionary = _source["recipes"].get(sku, {})
	var key := str(recipe["foreground"]) if recipe.get("foreground") != null else ""
	if key.is_empty():
		key = "my_welcome" if sku in ["char_my", "starter_3"] else "linh_present"
	var info: Dictionary = _source["textures"][key]
	var region: Array = info["rect"]
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://" + String(info["path"]))
	atlas.region = Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
	# Shop banners use a bust crop; the original full-body PNG stays unchanged.
	atlas.region.size.y *= 0.65
	atlas.filter_clip = true
	var t := TextureRect.new()
	t.texture = atlas
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.clip_contents = true
	t.custom_minimum_size = extent
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func style_button(b: Button, kind: String = "buy") -> void:
	b.clip_text = true
	b.add_theme_font_override("font", preload("res://assets/clean_modern/fonts/Roboto-Bold.ttf"))
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var style := surface("disabled" if state == "disabled" else kind, 3)
		if state in ["pressed", "hover_pressed"]:
			style.modulate_color = Color("d0e9f7")
		b.add_theme_stylebox_override(state, HdUi.ButtonSkin.rounded(style))
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(color, INK if kind == "tab" else Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("647f98"))
	b.add_theme_color_override("font_outline_color", Color("15437a") if kind == "action" else Color("247b00"))
	b.add_theme_constant_override("outline_size", 0 if kind == "tab" else 1)
	b.add_theme_constant_override("shadow_offset_x", 0)
	b.add_theme_constant_override("shadow_offset_y", 0)
	HdUi.ButtonSkin.apply(b)

static func price_text(b: Button, preferred_size: int = 18) -> void:
	# Fit the complete localized store price, including its outline, in narrow cards.
	var font := b.get_theme_font("font")
	var available := b.size.x - 10.0
	if b.icon != null:
		available -= 22.0
	var point_size := preferred_size
	if available > 0:
		while point_size > 12 and font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x > available:
			point_size -= 1
	b.add_theme_font_size_override("font_size", point_size)
	b.add_theme_color_override("font_outline_color", Color("174d19") if b.icon == null else Color("063d83"))
	b.add_theme_constant_override("outline_size", 2)
	if b.icon != null and b.size.x > 0:
		# Godot centers an icon over text when icon_alignment is CENTER. Instead,
		# center their shared content area, with the icon on its left edge.
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var text_width := font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x
		var inset := maxf(3.0, (b.size.x - text_width - 22.0) * 0.5)
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			var style := b.get_theme_stylebox(state)
			style.content_margin_left = inset
			style.content_margin_right = inset
