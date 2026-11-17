extends RefCounted
## Shop-only art direction. Other pages keep their current skin.
const ROOT := "res://assets/shop_blue_white/"
const LEGACY_INK := Color("23394a")
const MUTED := Color("768ca0")
const LIMIT_INK := Color("3e6b9b")
const PACK_BLUE := Color("087ee6")
const PACK_PALE := Color("e4f3ff")
const PACK_EDGE := Color("0665bd")
const PACK_PALE_EDGE := Color("85bde9")
const DISABLED_BG := Color("e7edf3")
const DISABLED_EDGE := Color("b7c9d9")
const FOCUS := Color("ffca51")
const PACK_INK := Color("12538b")
const DISABLED_INK := Color("62798e")
const LINK := Color("2468b7")
const MULTIPLIER_INK := Color("d78d00")
const DETAIL_BG := Color("dfedff")
const DETAIL_EDGE := Color("b6d8fb")
const CONVERSION_INK := Color("7652aa")
const DETAIL_INK := Color("476991")
const INK := Color("102d60")
const UnitScale = preload("res://ui/unit_scale.gd")
static var _source: Dictionary = {}

const FONT = preload("res://assets/clean_modern/fonts/Roboto-Bold.ttf")
const SECTION_OUTLINE := Color("0751a7")
const NUMBER_OUTLINE := Color("091326")
static var _surfaces: Dictionary = {}

static func match_picture(id: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(ROOT + "match/" + id + ".png")
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func outlined_number(label: Label) -> void:
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", NUMBER_OUTLINE)
	label.add_theme_constant_override("outline_size", 9)
	label.set_meta("ub_c_outline_size", 9)

static func gem_slot() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ffffff70")
	style.border_color = Color.WHITE
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style

static func video_icon() -> Texture2D:
	var image := Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="34" height="26"><rect x="1" y="1" width="32" height="24" rx="3" fill="white" stroke="#09285a" stroke-width="2"/><path d="M14 6l11 7-11 7z" fill="#102d60"/></svg>')
	return ImageTexture.create_from_image(image)

static func reference_surface(extent: Vector2, cyan: bool = false) -> StyleBoxTexture:
	var key := str(extent) + str(cyan)
	if not _surfaces.has(key):
		var w := int(extent.x)
		var h := int(extent.y)
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d"><defs><linearGradient id="g" x1="0" y1="1" x2="1" y2="0"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient><clipPath id="c"><rect x="4" y="3" width="%d" height="%d" rx="16"/></clipPath></defs><rect x="1" y="5" width="%d" height="%d" rx="18" fill="#add4f3"/><rect x="1.5" y="1.5" width="%d" height="%d" rx="17" fill="url(#g)" stroke="%s" stroke-width="2.5"/><g clip-path="url(#c)" fill="white" opacity=".22"><path d="M90 0h48L-62 %dh-48zM320 0h38L168 %dh-38zM420 0h20L268 %dh-20z"/></g><rect x="4" y="4" width="%d" height="%d" rx="15" fill="none" stroke="white" stroke-width="2"/></svg>' % [w,h,"#a1e4f9" if cyan else "#ceeafb","#c8effc" if cyan else "#ffffff",w-8,h-10,w-2,h-6,w-3,h-8,"#1fa8e9" if cyan else "#6db4ef",h,h,h,w-8,h-13]
		var image := Image.new()
		image.load_svg_from_string(svg)
		_surfaces[key] = ImageTexture.create_from_image(image)
	var style := StyleBoxTexture.new()
	style.texture = _surfaces[key]
	style.texture_margin_left = 0
	style.texture_margin_right = 0
	style.texture_margin_top = 0
	style.texture_margin_bottom = 0
	style.set_content_margin_all(0)
	return style

## Standalone artwork from assets/shop_blue_white/crops (see tools/export_shop_crops.py).
static func sprite(name: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(ROOT + "crops/" + name + ".png")
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Same files, but kept proportional inside whatever box the caller gives it.
static func demo_picture(id: String, extent: Vector2) -> TextureRect:
	var t := sprite(id)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = extent
	return t


## 44px round info icon (transparent PNG) used by every offer card.
static func info_button(sku: String, square: bool = false) -> Button:
	var info := Button.new()
	info.name = "Detail_" + sku
	info.flat = true
	info.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		info.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var icon := TextureRect.new()
	icon.texture = load(ROOT + ("info_button.svg" if square else "info_icon.png"))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(icon)
	# Touch target never drops under 44px; the drawn icon still follows the card's scale.
	info.set_meta("ub_floor", Vector2(44, 44))
	icon.anchor_left = 0.5
	icon.anchor_right = 0.5
	icon.anchor_top = 0.5
	icon.anchor_bottom = 0.5
	UnitScale.offsets(icon, -22.0, -22.0, 22.0, 22.0)
	return info

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

static func style_reference_button(b: Button, kind: String = "buy") -> void:
	b.clip_text = true
	b.add_theme_font_override("font", FONT)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var style := surface("disabled" if state == "disabled" else kind + "_match", 3)
		style.texture_margin_left = 0
		style.texture_margin_right = 0
		style.texture_margin_top = 0
		style.texture_margin_bottom = 0
		b.add_theme_stylebox_override(state, style)
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(color, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("647f98"))
	b.add_theme_color_override("font_outline_color", Color("063d83") if kind == "action" else Color("174d19"))
	b.add_theme_constant_override("outline_size", 6)
	b.add_theme_constant_override("shadow_offset_x", 0)
	b.add_theme_constant_override("shadow_offset_y", 0)


static func price_text(b: Button, preferred_size: int = 18, unit: float = 1.0) -> void:
	# Fit the complete localized store price, including its outline, in narrow cards.
	var font := b.get_theme_font("font")
	var reference := bool(b.get_meta("reference_face", false))
	var fitted_text := b.text.trim_prefix("▶ ") if reference and b.icon != null else b.text
	var available := ((b.get_meta("ub_rect") as Array)[1] as Vector2).x - 10.0 if reference and b.has_meta("ub_rect") else b.size.x / unit - 10.0
	if b.icon != null:
		available -= 37.0 if reference else 22.0
	var point_size := preferred_size
	if available > 0:
		while point_size > 12 and font.get_string_size(fitted_text, HORIZONTAL_ALIGNMENT_LEFT, -1, point_size).x > available:
			point_size -= 1
	b.add_theme_font_size_override("font_size", roundi(point_size * unit))
	b.set_meta("ub_font", point_size)
	b.add_theme_color_override("font_outline_color", Color("174d19") if b.icon == null else Color("063d83"))
	var outline := 6 if reference else 3
	b.add_theme_constant_override("outline_size", maxi(1, roundi(outline * unit)))
	b.set_meta("ub_c_outline_size", outline)
	if b.icon != null and b.size.x > 0 and not reference:
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
