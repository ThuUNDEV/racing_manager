extends PanelContainer
## Thẻ Chain Offer (Design/35 đợt B, concept Design/Concepts/IAP_Chain_Offer_v1): một thẻ cho mỗi chuỗi,
## hiện bước đang bán, dải bước đã mua / hiện tại / khóa, thưởng, giá và gói kế tiếp. Chỉ vẽ; giá, điều kiện và quà do Iap quyết.

signal buy_pressed(sku: String)

const Soft = preload("res://ui/soft_miniature.gd")
const ButtonSkin = preload("res://ui/button_skin.gd")
const RewardItems = preload("res://core/data/reward_items.gd")
const ART_DIR := "res://assets/iap_chain_v1/"
const INK := Color("0e2b5c")
const MUTED := Color("5f6f7a")
const CREAM := Color("fff4e4")
const BEHIND := 3
const AHEAD_FIRST := 3
const AHEAD_LATER := 2
const CHECK_SVG := """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M5 12.5 L10 17.5 L19 7" fill="none" stroke="#fff" stroke-width="3.6" stroke-linecap="round" stroke-linejoin="round"/></svg>"""
const LOCK_SVG := """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M8 11 V8.5 A4 4 0 0 1 16 8.5 V11" fill="none" stroke="#8d8174" stroke-width="2.4" stroke-linecap="round"/><rect x="5.5" y="10.5" width="13" height="9.5" rx="2.4" fill="#9a8e80"/><circle cx="12" cy="15" r="1.6" fill="#e9dfd1"/></svg>"""
static var _textures: Dictionary = {}

var chain_id := ""
var buy_button: Button
var _sku := ""
var _title: Label
var _steps: HBoxContainer
var _progress: Label
var _art: TextureRect
var _price: Label
var _rewards: VBoxContainer
var _next: Label


func setup(chain: String) -> void:
	chain_id = chain
	name = "Chain_" + chain
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var surface := Soft.flat(CREAM, 10, 20)
	surface.border_color = Color("e8d5bc")
	surface.set_border_width_all(2)
	surface.shadow_color = Color("79593633")
	surface.shadow_size = 4
	surface.shadow_offset = Vector2(0, 3)
	add_theme_stylebox_override("panel", surface)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	column.add_child(head)
	_title = _label((I18n.t("shop.chain_driver") if chain == "driver" else I18n.t("shop.chain_gear")).to_upper(), 24, INK)
	_title.name = "ChainTitle"
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.clip_text = true
	head.add_child(_title)
	var chip := PanelContainer.new()
	chip.name = "ChainChip"
	var chip_skin := Soft.flat(Color("d9f0ff"), 4, 14)
	chip_skin.border_color = Color("a9d6f2")
	chip_skin.content_margin_left = 12
	chip_skin.content_margin_right = 12
	chip.add_theme_stylebox_override("panel", chip_skin)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var chip_label := _label(I18n.t("shop.chain_sequential"), 14, Color("1b5f93"))
	chip_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	chip_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.add_child(chip_label)
	head.add_child(chip)
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 4)
	column.add_child(strip)
	_steps = HBoxContainer.new()
	_steps.name = "ChainSteps"
	_steps.add_theme_constant_override("separation", 4)
	_steps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_child(_steps)
	var progress_chip := PanelContainer.new()
	var progress_skin := Soft.flat(Color("d9f0ff"), 3, 13)
	progress_skin.border_color = Color("a9d6f2")
	progress_skin.content_margin_left = 10
	progress_skin.content_margin_right = 10
	progress_chip.add_theme_stylebox_override("panel", progress_skin)
	_progress = _label("", 15, Color("1b5f93"))
	_progress.name = "ChainProgress"
	_progress.autowrap_mode = TextServer.AUTOWRAP_OFF
	_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_chip.add_child(_progress)
	strip.add_child(progress_chip)
	var body := PanelContainer.new()
	body.name = "ChainBody"
	var body_skin := Soft.flat(Color("fffaf0"), 8, 18)
	body_skin.border_color = Color("efe2cd")
	body.add_theme_stylebox_override("panel", body_skin)
	column.add_child(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	body.add_child(row)
	var frame := PanelContainer.new()
	frame.name = "ChainArt"
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	frame.custom_minimum_size = Vector2(128, 128)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 0.9
	var frame_skin := StyleBoxFlat.new()
	frame_skin.bg_color = Color("cfeaff")
	frame_skin.set_corner_radius_all(22)
	frame.add_theme_stylebox_override("panel", frame_skin)
	_art = TextureRect.new()
	_art.texture = load(ART_DIR + "chain_%s.png" % chain) as Texture2D
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_art)
	row.add_child(frame)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_stretch_ratio = 1.1
	row.add_child(info)
	_price = _label("", 36, INK)
	_price.name = "ChainPrice"
	_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_price.autowrap_mode = TextServer.AUTOWRAP_OFF
	info.add_child(_price)
	_rewards = VBoxContainer.new()
	_rewards.name = "ChainRewards"
	_rewards.add_theme_constant_override("separation", 5)
	info.add_child(_rewards)
	buy_button = Button.new()
	buy_button.name = "Iap_chain_" + chain
	buy_button.custom_minimum_size = Vector2(0, 48)
	buy_button.add_theme_font_override("font", HdUi.font())
	buy_button.add_theme_font_size_override("font_size", 26)
	buy_button.clip_text = true
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var disabled: bool = state == "disabled"
		var pressed: bool = state in ["pressed", "hover_pressed"]
		var top := Color("ecdcc8") if disabled else Color("ffab4d" if state == "hover" else ("e8700f" if pressed else "ff9a2e"))
		buy_button.add_theme_stylebox_override(state, ButtonSkin.palette(top, Color("e6d4bc") if disabled else Color("e8700f" if pressed else "ff831e"), Color("cbb79b") if disabled else Color("a8420a" if pressed else "d5570e")))
		buy_button.add_theme_color_override("font_" + state + "_color" if state != "normal" else "font_color", Color("657079") if disabled else Color.WHITE)
	buy_button.add_theme_color_override("font_outline_color", Color("a2420a"))
	buy_button.add_theme_constant_override("outline_size", 4)
	var focus := Soft.flat(Color.TRANSPARENT, 0, 24)
	focus.border_color = Color("168cc2")
	focus.set_border_width_all(2)
	buy_button.add_theme_stylebox_override("focus", focus)
	buy_button.pressed.connect(func() -> void:
		if _sku != "":
			buy_pressed.emit(_sku))
	info.add_child(buy_button)
	column.add_child(HSeparator.new())
	_next = _label("", 16, MUTED)
	_next.name = "ChainNext"
	_next.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_next)
	visible = false


## state: Iap.chain_state(chain); items: {sku: {price, reason}} từ view Shop.
func update_view(state: Dictionary, items: Dictionary, busy: bool) -> void:
	_sku = String(state.get("sku", ""))
	visible = _sku != ""
	if _sku == "":
		return
	var product := GameData.iap_product(_sku)
	var step := int(state["step"])
	var total := int(state["total"])
	_progress.text = "%d / %d" % [step, total]
	_fill_steps(step, total)
	var entry: Dictionary = items.get(_sku, {})
	var price := String(entry.get("price", ""))
	if price.is_empty():
		price = String(product.get("price_fallback", ""))
	_price.text = price
	buy_button.text = I18n.t("shop.processing") if busy else price
	buy_button.disabled = busy or String(entry.get("reason", "")) not in ["", "busy"]
	buy_button.add_theme_constant_override("outline_size", 0 if buy_button.disabled else 4)
	_fill_rewards(product.get("grant", {}))
	var next_sku := String(state.get("next_sku", ""))
	if next_sku == "":
		_next.text = I18n.t("shop.chain_last")
	else:
		var next_entry: Dictionary = items.get(next_sku, {})
		var next_price := String(next_entry.get("price", ""))
		if next_price.is_empty():
			next_price = String(GameData.iap_product(next_sku).get("price_fallback", ""))
		_next.text = I18n.t("shop.chain_next") % next_price


func _fill_steps(step: int, total: int) -> void:
	for child in _steps.get_children():
		_steps.remove_child(child)
		child.queue_free()
	var past := mini(step - 1, BEHIND)
	var ahead := mini(total - step, AHEAD_LATER if past > 0 else AHEAD_FIRST)
	for number in range(step - past, step + ahead + 1):
		_steps.add_child(_badge(number, step))
	if step + ahead < total:
		var dots := _label("···", 20, Color("6d7b86"))
		dots.autowrap_mode = TextServer.AUTOWRAP_OFF
		dots.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		dots.custom_minimum_size.x = 18
		_steps.add_child(dots)


func _badge(number: int, step: int) -> Control:
	var badge := PanelContainer.new()
	badge.name = "Step_%d" % number
	badge.custom_minimum_size = Vector2(22, 30)
	badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var skin := Soft.flat(Color("fffaf0"), 0, 9)
	if number < step:
		skin.bg_color = Color("55c23b")
		skin.border_color = Color("3b9a2a")
		badge.add_child(_glyph("check", CHECK_SVG))
	elif number == step:
		skin.bg_color = Color("ff8a2a")
		skin.border_color = Color("d5570e")
		var label := _label(str(number), 20, Color.WHITE)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_outline_color", Color("a2420a"))
		label.add_theme_constant_override("outline_size", 3)
		badge.add_child(label)
	else:
		skin.bg_color = Color("efe4d3")
		skin.border_color = Color("d8c7ad")
		badge.add_child(_glyph("lock", LOCK_SVG))
	skin.set_border_width_all(2)
	badge.add_theme_stylebox_override("panel", skin)
	return badge


func _glyph(key: String, svg: String) -> TextureRect:
	var glyph := TextureRect.new()
	glyph.texture = _svg_texture(key, svg, 3.0)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.custom_minimum_size = Vector2(18, 18)
	return glyph


func _fill_rewards(grant: Dictionary) -> void:
	for child in _rewards.get_children():
		_rewards.remove_child(child)
		child.queue_free()
	_rewards.add_child(_reward_row("gem", I18n.t("shop.chain_gems") % int(grant.get("gems", 0))))
	if grant.has("driver_coupon"):
		_rewards.add_child(_reward_row("standard_driver_pack", I18n.t("shop.chain_driver_ticket") % int(grant["driver_coupon"].get("pro", 0))))
	if grant.has("gear_coupon"):
		_rewards.add_child(_reward_row("standard_gear_pack", I18n.t("shop.chain_gear_ticket") % int(grant["gear_coupon"].get("standard", 0))))


func _reward_row(item_id: String, text: String) -> Control:
	var pill := PanelContainer.new()
	pill.name = "Reward_" + item_id
	var skin := Soft.flat(Color("f7efe2"), 4, 16)
	skin.border_color = Color("eadfcb")
	skin.content_margin_left = 6
	skin.content_margin_right = 8
	pill.add_theme_stylebox_override("panel", skin)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	pill.add_child(box)
	var icon := TextureRect.new()
	icon.texture = RewardItems.icon(item_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(32, 32)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var label := _label(text, 17, INK)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(label)
	return pill


static func _svg_texture(key: String, svg: String, scale: float) -> ImageTexture:
	if not _textures.has(key):
		var image := Image.new()
		image.load_svg_from_string(svg, scale)
		_textures[key] = ImageTexture.create_from_image(image)
	return _textures[key]


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", HdUi.font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
