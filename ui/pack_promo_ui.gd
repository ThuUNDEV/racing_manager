extends RefCounted
## Soft Miniature pieces for the pack promo popup. Art is text-free (assets/pack_promo_v1); every word and number is a Label.
const PackUi = preload("res://ui/shop_pack_ui.gd")
const ROOT := "res://assets/pack_promo_v1/"
const CLOSE_ROOT := "res://assets/daily_gift_v3/skins/"
const INK := Color("12334c")
const MUTED := Color("52636c")
const CREAM := Color("fff4e4")
const EDGE := Color("e8d5bc")
const SAGE := Color("eaf0d6")
const BUTTON_ROOT := "res://assets/promotion_ui_v1/skins/"
const TICKETS := {
	"standard_driver_pack": "ticket_pro.png", "elite_driver_pack": "ticket_allstar.png",
	"standard_gear_pack": "ticket_standard.png", "elite_gear_pack": "ticket_elite.png",
}
static var _cache: Dictionary = {}


static func tex(file: String, root: String = ROOT) -> Texture2D:
	if not _cache.has(root + file):
		_cache[root + file] = load(root + file)
	return _cache[root + file]


## Scenic banner (opaque) or icon (transparent) for a SKU; "" when the SKU has no promo art.
static func art_file(sku: String, product: Dictionary) -> String:
	match String(product.get("kind", "")):
		"starter": return "hero_starter.webp"
		"weekly": return "hero_weekly.webp"
		"offer": return "hero_noads.webp" if sku == "offer_noads_bundle" else "hero_weekly.webp"
		"perk":
			if sku == "offline_plus":
				return "perk_offline.png"
			if sku.begins_with("income_"):
				return "perk_income.png"
	return ""


static func shell_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CREAM
	style.border_color = EDGE
	style.set_border_width_all(3)
	style.set_corner_radius_all(24)
	style.set_content_margin_all(12)
	style.shadow_color = Color("3a24108c")
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style


static func _outlined(label: Label, size: int, color: Color, outline: Color, outline_size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline)
	label.add_theme_constant_override("outline_size", outline_size)


## Chỗ trống trong popup cho dải ruy băng nhô lên trên mép thẻ (header đặt ngoài vùng cuộn).
static func header_space() -> Control:
	var space := Control.new()
	space.name = "PromoHeaderSpace"
	space.custom_minimum_size.y = 22
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return space


## Ruy băng tiêu đề dùng chung cho mọi popup Soft Miniature: nhô lên trên mép thẻ, căn giữa đúng tâm thẻ,
## hai lề bằng nhau; nút đóng >= 48x48 chồng lên mép phải. bleed = lề nội dung của thẻ (header phủ hết bề ngang thẻ).
static func header(title: String, on_close: Callable, bleed: float = 12.0, title_name: String = "PromoTitle", close_name: String = "PromoClose") -> Control:
	var root := Control.new()
	root.name = "PromoHeader"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.anchor_right = 1.0
	root.offset_left = -bleed
	root.offset_right = bleed
	root.offset_top = -56
	root.offset_bottom = 16
	var ribbon := TextureRect.new()
	ribbon.name = "PromoRibbon"
	ribbon.texture = tex("ribbon.png")
	ribbon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ribbon.stretch_mode = TextureRect.STRETCH_SCALE
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ribbon.offset_left = 44
	ribbon.offset_right = -44
	root.add_child(ribbon)
	var text := Label.new()
	text.name = title_name
	text.text = title
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.clip_text = true
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title_size := 26 if title.length() <= 9 else (23 if title.length() <= 12 else (21 if title.length() <= 17 else (17 if title.length() <= 22 else 14)))
	_outlined(text, title_size, Color.WHITE, Color("0f4f78"), 6)
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text.offset_left = 84
	text.offset_right = -84
	text.offset_top = -8
	text.offset_bottom = -6
	root.add_child(text)
	root.resized.connect(func() -> void:
		var font := text.get_theme_font("font")
		var room := root.size.x - 168.0
		var fitted := title_size
		while fitted > 12 and font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x + 12.0 > room:
			fitted -= 1
		text.add_theme_font_size_override("font_size", fitted))
	var close := TextureButton.new()
	close.name = close_name
	close.accessibility_name = I18n.t("common.close")
	close.texture_normal = tex("button_close.png", CLOSE_ROOT)
	close.texture_hover = tex("button_close_hover.png", CLOSE_ROOT)
	close.texture_pressed = tex("button_close_pressed.png", CLOSE_ROOT)
	close.ignore_texture_size = true
	close.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close.custom_minimum_size = Vector2(48, 48)
	close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -50
	close.offset_right = -2
	close.offset_top = -4
	close.offset_bottom = 44
	close.pressed.connect(on_close)
	root.add_child(close)
	return root


## Rosette with live text: big line + small caption.
static func badge(top: String, bottom: String = "", extent: float = 84.0) -> Control:
	var root := Control.new()
	root.name = "PromoBadge"
	root.custom_minimum_size = Vector2(extent, extent)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image := TextureRect.new()
	image.texture = tex("badge.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(image)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", -2)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_bottom = -extent * 0.21
	root.add_child(box)
	var unit := extent / 84.0
	for pair in [[top, 22 if top.length() <= 4 else 17], [bottom, 11]]:
		if String(pair[0]) == "":
			continue
		var line := Label.new()
		line.text = pair[0]
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.clip_text = true
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_font_size_override("font_size", roundi(float(pair[1]) * unit))
		line.add_theme_color_override("font_color", INK)
		box.add_child(line)
	return root


static func value_text(product: Dictionary) -> String:
	if not product.has("value_x"):
		return ""
	return ("%.1f" % float(product["value_x"])).replace(".", I18n.dec()) + "x"


## Hero frame: rounded scene or icon on sage, with the value / multiplier badge at the top right. Null when no promo art.
static func hero(sku: String, product: Dictionary, height: float) -> Control:
	var file := art_file(sku, product)
	if file == "":
		return null
	var frame := Control.new()
	frame.name = "OfferArt_" + sku
	frame.custom_minimum_size.y = height
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var clip := Panel.new()
	clip.name = "PromoHeroClip"
	clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = SAGE
	style.border_color = EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	clip.add_theme_stylebox_override("panel", style)
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(clip)
	var picture := TextureRect.new()
	picture.texture = tex(file)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var scenic := file.ends_with(".webp")
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if scenic else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not scenic:
		picture.offset_top = 6
		picture.offset_bottom = -6
	clip.add_child(picture)
	var top := ""
	var caption := ""
	if product.has("value_x"):
		top = value_text(product)
		caption = I18n.t("shop.value_badge")
	elif sku.begins_with("income_"):
		top = "×2" if sku == "income_x2" else "×3"
	elif sku == "offline_plus":
		top = "×3"
	if top != "":
		var rosette := badge(top, caption)
		rosette.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		rosette.offset_left = -92
		rosette.offset_right = -6
		var perk := String(product.get("kind", "")) == "perk"
		rosette.offset_top = 34 if perk else 6
		rosette.offset_bottom = rosette.offset_top + 84
		frame.add_child(rosette)
		if perk:
			frame.add_child(_permanent_chip())
	var grant: Dictionary = product.get("grant", {})
	if String(product.get("kind", "")) == "offer" and String(grant.get("perk", "")) == "no_ads":
		frame.add_child(_permanent_pill())
	return frame


## CTA cam nổi khối có gradient (Design/Demos/PackPromoPopup): skin chung với nút Thăng hạng, chữ trắng viền cam đậm.
static func style_cta(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = load(BUTTON_ROOT + ("button_disabled.svg" if state == "disabled" else "button_normal.svg"))
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_texture_margin(side, 25)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 8 if state in ["pressed", "hover_pressed"] else 6
		style.content_margin_bottom = 6 if state in ["pressed", "hover_pressed"] else 8
		if state == "hover":
			style.modulate_color = Color(1.06, 1.06, 1.06)
		elif state in ["pressed", "hover_pressed"]:
			style.modulate_color = Color(0.94, 0.94, 0.94)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(color, Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("f5f5ef"))
	button.add_theme_color_override("font_outline_color", Color("a2420a"))
	button.add_theme_constant_override("outline_size", 5)


## Pill vàng "PERMANENT" ở góc phải hero của perk vĩnh viễn.
static func _permanent_chip() -> Control:
	var chip := PanelContainer.new()
	chip.name = "PermanentChip"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f5bd42")
	style.border_color = Color("d99a1f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = I18n.t("shop.permanent").to_upper()
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(label)
	chip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE)
	chip.offset_right = -8
	chip.offset_left = chip.offset_right - 110
	chip.offset_top = 6
	return chip


static func _reward_icon(id: String, extent: float) -> Control:
	if TICKETS.has(id):
		var picture := TextureRect.new()
		picture.texture = tex(String(TICKETS[id]))
		picture.custom_minimum_size = Vector2(extent, extent)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return picture
	var icon := PackUi.icon(id, extent)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon


## Pill xanh navy viền vàng "PERMANENT" ở đáy hero của gói có perk vĩnh viễn (No Ads Bundle).
static func _permanent_pill() -> Control:
	var pill := PanelContainer.new()
	pill.name = "PermanentPill"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b5fae")
	style.border_color = Color("f5bd42")
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 2
	style.content_margin_bottom = 3
	pill.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = I18n.t("shop.permanent").to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outlined(label, 15, Color.WHITE, Color("0f3c78"), 3)
	pill.add_child(label)
	pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
	pill.offset_bottom = -6
	pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	return pill


static func _tile(row: Dictionary, narrow: bool) -> VBoxContainer:
	var id := String(row["icon"])
	var shown := String(row["value"])
	if TICKETS.has(id):
		shown = shown.trim_prefix("×")
	var tile := VBoxContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.alignment = BoxContainer.ALIGNMENT_CENTER
	tile.add_theme_constant_override("separation", 0)
	var picture := _reward_icon(id, 48 if narrow else 56)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.add_child(picture)
	var number := PackUi.label(shown, 28 if shown.length() <= 6 else (21 if shown.length() <= 8 else 18), INK)
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_child(number)
	var caption := PackUi.label(String(row["label"]), 13, MUTED)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_child(caption)
	return tile


## Một khung kem mờ chứa lưới icon + số bên dưới, giống khối thưởng trên thẻ Shop.
static func reward_panel(rows: Array, narrow: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "PromoRewards"
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ffffffb8")
	style.border_color = EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	var grid := GridContainer.new()
	grid.name = "PromoRewardGrid"
	grid.columns = 2 if rows.size() in [2, 4] else mini(3, maxi(1, rows.size()))
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for row: Dictionary in rows:
		grid.add_child(_tile(row, narrow))
	panel.add_child(grid)
	return panel
