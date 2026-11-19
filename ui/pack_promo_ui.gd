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
const TIER_EDGE := {
	"gem": Color("9a52dc"), "cash": Color("5dbb4a"),
	"standard_driver_pack": Color("e8604f"), "elite_driver_pack": Color("f0b429"),
	"standard_gear_pack": Color("3e86d4"), "elite_gear_pack": Color("9a52dc"),
	"crown": Color("f0b429"), "energy": Color("f0b429"), "research": Color("3e86d4"),
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


## Title ribbon with a close button that stays >= 48x48 whatever the art looks like.
static func header(title: String, on_close: Callable) -> Control:
	var root := Control.new()
	root.name = "PromoHeader"
	root.custom_minimum_size.y = 64
	var ribbon_box := Control.new()
	ribbon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ribbon_box.offset_left = 8
	ribbon_box.offset_right = -56
	root.add_child(ribbon_box)
	var ribbon := TextureRect.new()
	ribbon.name = "PromoRibbon"
	ribbon.texture = tex("ribbon.png")
	ribbon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ribbon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ribbon_box.add_child(ribbon)
	var text := Label.new()
	text.name = "PromoTitle"
	text.text = title
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.clip_text = true
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title_size := 22 if title.length() <= 9 else (19 if title.length() <= 12 else (18 if title.length() <= 17 else (15 if title.length() <= 22 else 13)))
	_outlined(text, title_size, Color.WHITE, Color("0f4f78"), 5)
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text.anchor_left = 0.2
	text.anchor_right = 0.8
	text.offset_left = 0
	text.offset_right = 0
	ribbon_box.add_child(text)
	var close := TextureButton.new()
	close.name = "PromoClose"
	close.accessibility_name = I18n.t("common.close")
	close.texture_normal = tex("button_close.png", CLOSE_ROOT)
	close.texture_hover = tex("button_close_hover.png", CLOSE_ROOT)
	close.texture_pressed = tex("button_close_pressed.png", CLOSE_ROOT)
	close.ignore_texture_size = true
	close.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close.custom_minimum_size = Vector2(48, 48)
	close.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	close.offset_left = -48
	close.offset_right = 0
	close.offset_top = -24
	close.offset_bottom = 24
	close.pressed.connect(on_close)
	root.add_child(close)
	return root


## Rosette with live text: big line + small caption.
static func badge(top: String, bottom: String = "") -> Control:
	var root := Control.new()
	root.name = "PromoBadge"
	root.custom_minimum_size = Vector2(84, 84)
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
	box.offset_bottom = -18
	root.add_child(box)
	for pair in [[top, 22 if top.length() <= 4 else 17], [bottom, 11]]:
		if String(pair[0]) == "":
			continue
		var line := Label.new()
		line.text = pair[0]
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.clip_text = true
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_font_size_override("font_size", int(pair[1]))
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
	return frame


## CTA cam nổi khối (Design/Demos/PackPromoPopup): nền #FF831E, cạnh dưới #D5570E dày 4, chữ trắng.
static func style_cta(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		var disabled: bool = state == "disabled"
		style.bg_color = Color("c9c2b8") if disabled else (Color("ff9438") if state == "hover" else Color("ff831e"))
		style.border_color = Color("a89f94") if disabled else Color("d5570e")
		style.border_width_bottom = 2 if state in ["pressed", "hover_pressed"] else 4
		style.set_corner_radius_all(22)
		style.content_margin_top = 4 if state in ["pressed", "hover_pressed"] else 2
		button.add_theme_stylebox_override(state, style)
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(color, Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color("a2420a"))
	button.add_theme_constant_override("outline_size", 4)


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


static func _card(row: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "PromoReward"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fffbf3")
	style.border_color = TIER_EDGE.get(String(row["icon"]), Color("f0b429"))
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	var picture := PackUi.icon(String(row["icon"]), 44)
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(picture)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 0)
	var length := String(row["value"]).length()
	var value := PackUi.label(String(row["value"]), 24 if length <= 6 else (19 if length <= 12 else 16), INK)
	text.add_child(value)
	text.add_child(PackUi.label(String(row["label"]), 13, MUTED))
	line.add_child(text)
	card.add_child(line)
	return card


static func _wide(row: Dictionary) -> bool:
	return String(row["value"]).length() > 8 or String(row["label"]).length() > 16


## Two cards per row with rarity borders. A card with long text, or a lone last card, takes the full row.
static func reward_cards(rows: Array, narrow: bool = false) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.name = "PromoRewards"
	column.add_theme_constant_override("separation", 8)
	var pending: Array = []
	for row: Dictionary in rows:
		if narrow or _wide(row):
			if not pending.is_empty():
				column.add_child(_line(pending))
				pending = []
			column.add_child(_line([row]))
			continue
		pending.append(row)
		if pending.size() == 2:
			column.add_child(_line(pending))
			pending = []
	if not pending.is_empty():
		column.add_child(_line(pending))
	return column


static func _line(rows: Array) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	for row: Dictionary in rows:
		line.add_child(_card(row))
	return line
