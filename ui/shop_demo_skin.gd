extends RefCounted
## Shop-only art direction. Other pages keep their current skin.
const ROOT := "res://assets/shop_blue_white/"
const LEGACY_INK := HdUi.C_TEXT
const MUTED := HdUi.C_MUTED
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
const INK := HdUi.C_TEXT
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

static func reference_surface(_extent: Vector2, cyan: bool = false) -> StyleBoxTexture:
	return HdUi.Soft.surface("selected" if cyan else "panel", Vector4.ZERO)

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
	var kind := "panel"
	if id.begins_with("section"): kind = "section"
	elif id.begins_with("disabled"): kind = "disabled"
	elif id.begins_with("buy") or id.begins_with("action"): kind = "cancel"
	elif id.begins_with("tab"): kind = "cancel"
	elif id == "free": kind = "reward"
	return HdUi.Soft.surface(kind, Vector4.ONE * margin)

static func picture(id: String, extent: Vector2) -> TextureRect:
	var key: String = {"gem_single": "currency_gem", "cash_small": "currency_cash", "cash_medium": "currency_cash", "cash_large": "currency_cash", "gift": "gift_red", "income": "currency_cash", "no_ads": "shop_no_ads", "offline": "garage_with_car"}.get(id, "")
	var texture: Texture2D = HdUi.Soft.texture(key) if key != "" else load(ROOT + "sprites/" + id + ".tres") as Texture2D
	return _texture_rect(texture, extent)

static func _texture_rect(texture: Texture2D, extent: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = extent
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

static func offer_art(sku: String, kind: String, extent: Vector2) -> TextureRect:
	var key: String = {"starter_1": "shop_starter", "income_x2": "shop_income_x2", "no_ads": "shop_no_ads", "offer_noads_bundle": "shop_combo", "offer_combo_1": "shop_combo", "offer_combo_2": "shop_combo"}.get(sku, "")
	if key != "": return _texture_rect(HdUi.Soft.texture(key), extent)
	if kind in ["character", "starter"]: return portrait(sku, extent)
	return _texture_rect(HdUi.Soft.icon("gift"), extent)

static func portrait(sku: String, extent: Vector2) -> TextureRect:
	var did := String(GameData.iap_product(sku).get("grant", {}).get("driver", ""))
	var clay := HdUi.Soft.texture("driver_lam_shop" if did == "driver_lam" else did)
	if clay != null:
		return _texture_rect(clay, extent)
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
		elif state == "hover":
			style.modulate_color = Color(1.08, 1.08, 1.08)
		b.add_theme_stylebox_override(state, HdUi.ButtonSkin.rounded(style))
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(color, INK)
	b.add_theme_color_override("font_disabled_color", Color("647f98"))
	b.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	b.add_theme_constant_override("outline_size", 0)
	b.add_theme_constant_override("shadow_offset_x", 0)
	b.add_theme_constant_override("shadow_offset_y", 0)
	HdUi.ButtonSkin.apply(b)

static func style_reference_button(b: Button, kind: String = "buy") -> void:
	style_button(b, kind)


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
	var buy := b.theme_type_variation == &"BuyButton" and not b.disabled
	b.add_theme_color_override("font_outline_color", Color(0.1, 0.4, 0.1) if buy else Color.TRANSPARENT)
	var outline := 4 if buy else 0
	b.add_theme_constant_override("outline_size", roundi(outline * unit))
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
