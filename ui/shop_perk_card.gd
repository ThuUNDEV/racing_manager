extends PanelContainer
## Approved Soft Miniature A layout. Containers grow for translations; no scaled text.
signal buy_pressed
const Soft = preload("res://ui/soft_miniature.gd")
const ButtonSkin = preload("res://ui/button_skin.gd")
const HERO_PATH := "res://assets/perk_cards_v1/heroes.png"
const SKUS := ["income_x2"]

var sku := ""
var price: Button
var title: Label
var benefit: Label
var permanent: Label
var _art_column: VBoxContainer
var _hero: Control
var _badge: PanelContainer
var _badge_label: Label


func setup(product: Dictionary) -> void:
	sku = String(product["sku"])
	name = "Offer_" + sku
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size.y = 176
	var surface := Soft.flat(Color("fff4e4"), 12, 20)
	surface.border_color = Color("e8d5bc")
	surface.set_border_width_all(2)
	surface.shadow_color = Color("79593633")
	surface.shadow_size = 4
	surface.shadow_offset = Vector2(0, 3)
	add_theme_stylebox_override("panel", surface)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	_art_column = VBoxContainer.new()
	_art_column.add_theme_constant_override("separation", 3)
	_art_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_art_column)
	_hero = Control.new()
	_hero.name = "OfferArt_" + sku
	_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.custom_minimum_size.y = 124
	_art_column.add_child(_hero)
	var art := TextureRect.new()
	art.name = "Hero"
	var sheet := load(HERO_PATH) as Texture2D
	var index := SKUS.find(sku)
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	var cell := sheet.get_size() / 2.0
	atlas.region = Rect2(Vector2(index % 2, index / 2) * cell, cell)
	atlas.filter_clip = true
	art.texture = atlas
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_badge = PanelContainer.new()
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_skin := Soft.flat(Color("237fc0") if sku == "income_x2" else Color("f5c34a"), 3, 24)
	badge_skin.border_color = Color("b9e7ff") if sku == "income_x2" else Color("ffe8a0")
	badge_skin.set_border_width_all(3)
	badge_skin.shadow_color = Color("79593644")
	badge_skin.shadow_size = 2
	_badge.add_theme_stylebox_override("panel", badge_skin)
	_hero.add_child(_badge)
	_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_badge.offset_left = -108 if sku == "income_x3_up" else -57
	_badge.offset_bottom = 40 if sku == "income_x3_up" else 51
	_badge_label = _label("×2 → ×3" if sku == "income_x3_up" else ("×2" if sku == "income_x2" else "×3"), 20 if sku == "income_x3_up" else 30)
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if sku == "income_x2":
		_badge_label.add_theme_color_override("font_color", Color.WHITE)
	_badge.add_child(_badge_label)
	var chip := PanelContainer.new()
	chip.name = "PermanentChip"
	chip.add_theme_stylebox_override("panel", Soft.flat(Color("d8ebcb"), 3, 10))
	_art_column.add_child(chip)
	permanent = _label(I18n.t("shop.permanent"), 13, Color("365c42"))
	permanent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(permanent)
	var copy := VBoxContainer.new()
	copy.name = "Copy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 6)
	row.add_child(copy)
	var multiplier := 2 if sku == "income_x2" else 3
	var title_text := I18n.t("shop.perk_income_title") % multiplier
	if sku == "income_x3_up": title_text = I18n.t("shop.perk_upgrade_title")
	if sku == "offline_plus": title_text = I18n.t("shop.perk_offline_title")
	title = _label(title_text, 22)
	title.name = "Title"
	copy.add_child(title)
	var benefit_text := I18n.t("shop.perk_income_benefit") % multiplier
	if sku == "offline_plus": benefit_text = I18n.t("shop.perk_offline_benefit")
	benefit = _label(benefit_text, 15, Color("465a60"))
	benefit.name = "Benefit"
	copy.add_child(benefit)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	copy.add_child(spacer)
	price = Button.new()
	price.name = "Iap_" + sku
	price.text = String(product.get("price_fallback", ""))
	price.custom_minimum_size = Vector2(0, 48)
	price.add_theme_font_override("font", HdUi.font())
	price.add_theme_font_size_override("font_size", 25)
	price.clip_text = true
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var disabled: bool = state == "disabled"
		var pressed: bool = state in ["pressed", "hover_pressed"]
		var top := Color("ecdcc8") if disabled else Color("ff9a35" if state == "hover" else "ff8b25")
		price.add_theme_stylebox_override(state, ButtonSkin.palette(top, Color("e6d4bc") if disabled else Color("f57612" if pressed else "ff7915"), Color("cbb79b") if disabled else Color("cb520f")))
		price.add_theme_color_override("font_" + state + "_color" if state != "normal" else "font_color", Color("657079") if disabled else Color.WHITE)
	var focus := Soft.flat(Color.TRANSPARENT, 0, 24)
	focus.border_color = Color("168cc2")
	focus.set_border_width_all(2)
	price.add_theme_stylebox_override("focus", focus)
	price.pressed.connect(buy_pressed.emit)
	copy.add_child(price)
	resized.connect(_adapt)
	price.resized.connect(_fit_price)
	_adapt()


func _label(value: String, font_size: int, color: Color = Soft.INK) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", HdUi.font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _adapt() -> void:
	_art_column.custom_minimum_size.x = clampf((size.x - 34) * 0.36, 90, 128)
	_fit_price()


func _fit_price() -> void:
	if price == null or price.size.x <= 0: return
	var font_size := 25
	var font := price.get_theme_font("font")
	while font_size > 12 and font.get_string_size(price.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > price.size.x - 20:
		font_size -= 1
	price.add_theme_font_size_override("font_size", font_size)


func update_price(value: String, busy: bool, reason: String) -> void:
	price.text = I18n.t("shop.processing") if busy else (I18n.t("common.owned_2") if reason == "owned" else value)
	price.disabled = busy or reason != ""
	_fit_price()
