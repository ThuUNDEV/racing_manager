extends RefCounted
## Runtime access to the approved cut-out asset kit. No gameplay or save state.
const ROOT := "res://assets/soft_miniature_ui_v1/"
const BG := Color("fff7e9")
const INK := Color("0e2b5c")
const MUTED := Color("5f7391")
const EDGE := Color("d8d7ca")
const ICON_ALIASES := {
	"cash": "currency_cash", "coins": "currency_coin", "gem": "currency_gem",
	"settings": "settings", "flag": "nav_race", "bag": "nav_bag", "team": "nav_team",
	"trophy": "nav_league", "shop": "nav_shop", "gift": "gift_red", "ticket": "ticket",
	"star": "star_gold", "star_locked": "star_locked", "avatar": "avatar_portrait",
	"garage": "facility_garage", "engine": "engine", "tyre": "tyre",
	"chassis": "chassis", "gearbox": "gearbox", "spoiler": "spoiler", "brake": "brake",
	"speed": "speedometer", "acceleration": "rocket_acceleration", "stability": "stability_scales"
}
static var _entries: Dictionary = {}
static var _textures: Dictionary = {}
static var _styles: Dictionary = {}
static var _button_textures: Dictionary = {}
static var _gloss_styles: Dictionary = {}

const GLOSS_PALETTES := {
	"section": ["e0f7ff", "b3e4f7", "95d1ed"],
	"level": ["58b9f5", "2265b7", "184386"],
	"xp_track": ["15375f", "285c96", "5699c9"],
	"xp_fill": ["fff19a", "ffae22", "e46d13"],
	"income": ["91e450", "309a49", "177136"],
}

static func texture(id: String) -> Texture2D:
	if _entries.is_empty():
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))
		_entries = manifest["assets"]
	if not _entries.has(id):
		return null
	if not _textures.has(id):
		var original := load(ROOT + String(_entries[id]["png_2x"])) as Texture2D
		if _entries[id].has("visible_region_xywh"):
			var region: Array = _entries[id]["visible_region_xywh"]
			var atlas := AtlasTexture.new()
			atlas.atlas = original
			atlas.region = Rect2(region[0], region[1], region[2], region[3])
			atlas.filter_clip = true
			_textures[id] = atlas
		else:
			_textures[id] = original
	return _textures[id] as Texture2D

static func icon(id: String) -> Texture2D:
	return texture(String(ICON_ALIASES.get(id, id)))

static func expansion(id: String) -> Texture2D:
	if id.begins_with("driver_"):
		return texture(id)
	if id == "car_pico_showroom":
		return texture("car_showroom")
	var aliases := {"celebration": "nav_league", "parking": "currency_coins", "grandstands": "inventory_crate",
		"standard_driver_pack": "ticket", "elite_driver_pack": "nav_team",
		"standard_gear_pack": "inventory_crate", "elite_gear_pack": "gift_red"}
	if aliases.has(id):
		return texture(aliases[id])
	for part: String in ["engine", "tyre", "gearbox", "chassis", "spoiler", "brake"]:
		if id == part or id.begins_with("gear_" + part + "_"):
			return texture(part)
	return null

static func surface(kind: String = "panel", padding: Vector4 = Vector4(10, 8, 10, 10)) -> StyleBoxTexture:
	if kind == "section":
		return gloss(kind, padding)
	var key := "panel_upgrade"
	match kind:
		"blue": key = "section_blue"
		"nav": key = "navigation_tray"
		"hud": key = "hud_resource"
		"orange", "upgrade", "race", "amber", "buy", "action": key = "button_orange"
		"tab_on", "menu_on": key = "nav_tab_selected"
		"claim", "reward": key = "badge_mint"
		"selected": key = "panel_inventory_selected"
		"disabled", "locked": key = "button_disabled"
		"cancel", "menu", "tab", "info": key = "button_blue"
		"trough": key = "badge_blue"
		"inventory": key = "panel_inventory"
	if not _styles.has(key):
		_styles[key] = load(ROOT + "godot_styles/" + key + ".tres")
	var skin := (_styles[key] as StyleBoxTexture).duplicate() as StyleBoxTexture
	skin.content_margin_left = padding.x
	skin.content_margin_top = padding.y
	skin.content_margin_right = padding.z
	skin.content_margin_bottom = padding.w
	# Preserve the approved texture. The old generic button pass must not replace it.
	skin.set_meta("rounded_button", true)
	skin.set_meta("soft_skin", key)
	return skin

## Draw text-free faces once. The section's right slice keeps the checker pattern
## anchored to the trailing edge at every width.
static func gloss(kind: String, padding: Vector4) -> StyleBoxTexture:
	if not _gloss_styles.has(kind):
		var colors: Array = GLOSS_PALETTES[kind]
		var light := Color(colors[0])
		var face := Color(colors[1])
		var edge := Color(colors[2])
		var height := 24
		if kind.begins_with("xp_"):
			height = 10
		elif kind == "section" or kind == "income":
			height = 34
		var radius := mini(12, floori(height * 0.5))
		var pattern_width := 64 if kind == "section" else 0
		var width := radius * 2 + pattern_width + 4
		var pixels := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
		for y in height:
			var v := (y + 0.5) / height
			var row_color := light.lerp(face, smoothstep(0.0, 0.62, v)).lerp(edge, smoothstep(0.65, 1.0, v))
			for x in width:
				var point := Vector2(x + 0.5, y + 0.5)
				var center := point.clamp(Vector2(radius, radius), Vector2(width - radius, height - radius))
				var inset := radius - point.distance_to(center)
				var color := row_color
				if pattern_width > 0 and x >= width - pattern_width:
					var column := floori((x + y * 0.32) / 11.0)
					if (column + floori(y / 11.0)) % 2 == 0:
						color = color.lerp(Color.WHITE, 0.65 * smoothstep(width - pattern_width, width - 8, x))
				if inset < 1.5:
					color = color.lerp(light.lerp(Color.WHITE, 0.55) if v < 0.5 else edge, 0.85)
				color.a = clampf(inset + 0.25, 0.0, 1.0)
				pixels.set_pixel(x, y, color)
		var style := StyleBoxTexture.new()
		style.texture = ImageTexture.create_from_image(pixels)
		for side in 4:
			style.set_texture_margin(side, radius)
		style.texture_margin_right = maxi(radius, pattern_width)
		_gloss_styles[kind] = style
	var skin := (_gloss_styles[kind] as StyleBoxTexture).duplicate() as StyleBoxTexture
	skin.content_margin_left = padding.x
	skin.content_margin_top = padding.y
	skin.content_margin_right = padding.z
	skin.content_margin_bottom = padding.w
	return skin


static func flat(fill: Color, padding: float = 10.0, radius: int = 14) -> StyleBoxFlat:
	var skin := StyleBoxFlat.new()
	skin.bg_color = fill
	skin.border_color = EDGE
	skin.set_border_width_all(1)
	skin.set_corner_radius_all(radius)
	skin.set_content_margin_all(padding)
	return skin

## Resize the complete face before slicing so small buttons retain circular caps.
static func fit_button(source: StyleBoxTexture, size: Vector2) -> StyleBoxTexture:
	if source.get_meta("soft_fit_size", Vector2.ZERO).is_equal_approx(size):
		return source
	var key := String(source.get_meta("soft_skin"))
	var original := _styles[key] as StyleBoxTexture
	var factor := minf(1.0, minf(size.y / original.texture.get_height(), size.x / maxf(1.0, original.texture_margin_left + original.texture_margin_right)))
	var height := maxi(1, floori(original.texture.get_height() * factor))
	var cache_key := key + "/" + str(height)
	if not _button_textures.has(cache_key):
		var pixels := original.texture.get_image()
		if pixels.is_compressed(): pixels.decompress()
		pixels.resize(maxi(1, roundi(original.texture.get_width() * factor)), height, Image.INTERPOLATE_LANCZOS)
		_button_textures[cache_key] = ImageTexture.create_from_image(pixels)
	var skin := source.duplicate() as StyleBoxTexture
	skin.texture = _button_textures[cache_key]
	var actual_factor := float(height) / original.texture.get_height()
	for side in 4:
		skin.set_texture_margin(side, original.get_texture_margin(side) * actual_factor)
	skin.set_meta("soft_fit_size", size)
	return skin

## Các khối trình bày dùng cùng tỷ lệ với bản duyệt; không chứa trạng thái game.
static func art(id: String, extent: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture(id)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = extent
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func title_label(text: String, font_size: int = 20) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

static func heading(text: String, id: String, height: float = 42) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = height
	panel.add_theme_stylebox_override("panel", surface("section", Vector4(6, 2, 6, 3)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	panel.add_child(row)
	row.add_child(art(id, Vector2(height, height - 4)))
	var label := title_label(text, 22)
	label.add_theme_font_override("font", HdUi.font())
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	return panel

static func pill(text: String, fill: Color = Color("d3f2c6"), font_size: int = 15) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", flat(fill, 3, 9))
	var label := title_label(text, font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel
