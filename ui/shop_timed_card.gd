extends PanelContainer
## Thẻ ưu đãi xoay tuần (Design/35 đợt C+D, concept Design/Concepts/IAP_Limited_ChooseOne_v1).
## mode "limited": 3 ô giá rẻ -> đắt của vòng xoay hiện tại. mode "chooseone": thẻ S / M / L / Tất cả, mỗi lần xem một gói.
## Chỉ vẽ; giá, điều kiện, giới hạn tuần và vòng xoay do Iap quyết (view["timed"][mode]).

signal buy_pressed(sku: String)

const Soft = preload("res://ui/soft_miniature.gd")
const ButtonSkin = preload("res://ui/button_skin.gd")
const PackUi = preload("res://ui/shop_pack_ui.gd")
const ART_DIR := "res://assets/iap_timed_v1/"
const INK := Color("0e2b5c")
const MUTED := Color("5f6f7a")
const CREAM := Color("fff4e4")
const SIZE_LETTERS := {"s": "S", "m": "M", "l": "L"}
const TIER_OF_SIZE := {"s": "drivers.tier_pro", "m": "drivers.tier_elite", "l": "drivers.tier_legend"}

var mode := ""
var buy_buttons: Dictionary = {}   # sku -> Button
var _head_title: Label
var _refresh: Label
var _body: Control
var _note: Label
var _state: Dictionary = {}
var _items: Dictionary = {}
var _busy := false
var _picked := ""
var _tab_buttons: Dictionary = {}


func setup(card_mode: String) -> void:
	mode = card_mode
	name = "Timed_" + card_mode
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
	var head := HFlowContainer.new()
	head.add_theme_constant_override("h_separation", 8)
	head.add_theme_constant_override("v_separation", 4)
	column.add_child(head)
	_head_title = _label((I18n.t("shop.limited_pack") if mode == "limited" else I18n.t("shop.chooseone_pack")), 22, INK)
	_head_title.name = "TimedTitle"
	_head_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_head_title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	head.add_child(_head_title)
	var chip := PanelContainer.new()
	chip.name = "TimedChip"
	var chip_skin := Soft.flat(Color("d9f0ff"), 4, 14)
	chip_skin.border_color = Color("a9d6f2")
	chip_skin.content_margin_left = 10
	chip_skin.content_margin_right = 10
	chip.add_theme_stylebox_override("panel", chip_skin)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_refresh = _label("", 12, Color("1b5f93"))
	_refresh.autowrap_mode = TextServer.AUTOWRAP_OFF
	_refresh.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.add_child(_refresh)
	head.add_child(chip)
	_body = VBoxContainer.new()
	_body.name = "TimedBody"
	_body.add_theme_constant_override("separation", 8)
	column.add_child(_body)
	_note = _label("", 12, MUTED)
	_note.name = "TimedNote"
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_note)
	visible = false


## state: Iap.timed_state(mode); items: {sku: {price, reason}} từ view Shop.
func update_view(state: Dictionary, items: Dictionary, busy: bool) -> void:
	_state = state
	_items = items
	_busy = busy
	visible = bool(state.get("open", false))
	if not visible:
		return
	_refresh.text = _countdown(float(state.get("ends_in", 0.0)))
	_rebuild()


func _rebuild() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	buy_buttons.clear()
	_tab_buttons.clear()
	var skus: Array = _state.get("skus", [])
	if mode == "limited":
		var row := HBoxContainer.new()
		row.name = "LimitedSlots"
		row.add_theme_constant_override("separation", 6)
		_body.add_child(row)
		for sku: String in skus:
			row.add_child(_limited_slot(sku))
		_note.text = ""
		return
	if _picked == "" or not _picked in skus:
		_picked = _default_pick(skus)
	_body.add_child(_tabs(skus))
	_body.add_child(_choose_panel(_picked))
	var all_sku := _sku_of_size("all")
	var parts := ["s", "m", "l"].map(func(size: String) -> float: return float(GameData.iap_product(_sku_of_size(size)).get("usd", 0.0)))
	var sum := 0.0
	for usd: float in parts:
		sum += usd
	_note.text = I18n.t("shop.choose_all_note") % [_price_of(all_sku), "$%.2f" % sum]


func _limited_slot(sku: String) -> Control:
	var product := GameData.iap_product(sku)
	var slot := PanelContainer.new()
	slot.name = "Slot_" + sku
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var skin := Soft.flat(Color("fffaf0"), 5, 16)
	skin.border_color = Color("efe2cd")
	slot.add_theme_stylebox_override("panel", skin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	slot.add_child(column)
	column.add_child(_price_chip(_price_of(sku)))
	var frame := _art_frame("limited_%d.png" % int(product["slot"]), Vector2(0, 62))
	column.add_child(frame)
	if bool(product.get("best_value", false)):
		var badge := _label(I18n.t("shop.limited_best"), 9, Color.WHITE)
		badge.name = "BestValue"
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.autowrap_mode = TextServer.AUTOWRAP_OFF
		var badge_skin := Soft.flat(Color("ff7a1a"), 2, 10)
		badge.add_theme_stylebox_override("normal", badge_skin)
		column.add_child(badge)
	for reward: Dictionary in PackUi.rewards(product):
		column.add_child(_reward_pill(reward, 11))
	var cap := int(product.get("week_cap", 1))
	var bought := int((_state.get("bought", {}) as Dictionary).get(sku, 0))
	var limit := _label(I18n.t("shop.limit_once") if cap == 1 else I18n.t("shop.limit_left") % [maxi(0, cap - bought), cap], 10, MUTED)
	limit.name = "Limit"
	limit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(limit)
	column.add_child(_buy_button(sku, 18))
	return slot


func _tabs(skus: Array) -> Control:
	var row := HBoxContainer.new()
	row.name = "ChooseTabs"
	row.add_theme_constant_override("separation", 4)
	for sku: String in skus:
		var size := String(GameData.iap_product(sku)["size"])
		var tab := Button.new()
		tab.name = "Tab_" + size
		tab.toggle_mode = true
		tab.button_pressed = sku == _picked
		tab.custom_minimum_size = Vector2(0, 56)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := I18n.t("shop.choose_all") if size == "all" else String(SIZE_LETTERS[size])
		tab.text = "%s\n%s" % [title, _price_of(sku)]
		tab.add_theme_font_override("font", HdUi.font())
		tab.add_theme_font_size_override("font_size", 14)
		var on := sku == _picked
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			var fill := Color("ff8a2a") if on else Color("f7efe2")
			var box := Soft.flat(fill, 4, 14)
			box.border_color = Color("d5570e") if on else Color("eadfcb")
			box.set_border_width_all(2)
			tab.add_theme_stylebox_override(state, box)
		var ink := Color.WHITE if on else INK
		for color_key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			tab.add_theme_color_override(color_key, ink)
		tab.pressed.connect(func() -> void:
			_picked = sku
			_rebuild())
		row.add_child(tab)
		_tab_buttons[sku] = tab
		if size == "all":
			var save := _label(I18n.t("shop.choose_save") % _save_percent(), 10, Color.WHITE)
			save.name = "SaveBadge"
			save.autowrap_mode = TextServer.AUTOWRAP_OFF
			save.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var save_skin := Soft.flat(Color("ffb41f"), 2, 8)
			save.add_theme_stylebox_override("normal", save_skin)
			tab.add_child(save)
			save.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
			save.offset_top = -10
			save.offset_bottom = 6
	return row


func _choose_panel(sku: String) -> Control:
	var product := GameData.iap_product(sku)
	var size := String(product["size"])
	var panel := PanelContainer.new()
	panel.name = "ChoosePanel"
	var skin := Soft.flat(Color("fffaf0"), 8, 18)
	skin.border_color = Color("efe2cd")
	panel.add_theme_stylebox_override("panel", skin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var title_text := I18n.t("shop.choose_all_title") if size == "all" else I18n.t("shop.tier_shards_title") % I18n.t(String(TIER_OF_SIZE[size]))
	var head := HBoxContainer.new()
	column.add_child(head)
	var title := _label(title_text, 18, INK)
	title.name = "ChooseTitle"
	head.add_child(title)
	var price := _label(_price_of(sku), 26, INK)
	price.autowrap_mode = TextServer.AUTOWRAP_OFF
	price.size_flags_horizontal = Control.SIZE_SHRINK_END
	head.add_child(price)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	var art := _art_frame("chooseone.png", Vector2(120, 100))
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_stretch_ratio = 0.9
	row.add_child(art)
	var rewards := VBoxContainer.new()
	rewards.name = "ChooseRewards"
	rewards.add_theme_constant_override("separation", 4)
	rewards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards.size_flags_stretch_ratio = 1.1
	row.add_child(rewards)
	for reward: Dictionary in PackUi.rewards(product):
		rewards.add_child(_reward_pill(reward, 13))
	column.add_child(_buy_button(sku, 24))
	return panel


func _default_pick(skus: Array) -> String:
	for sku: String in skus:
		if String(GameData.iap_product(sku)["size"]) == "m":
			return sku
	return String(skus[0]) if not skus.is_empty() else ""


func _sku_of_size(size: String) -> String:
	for sku: String in (_state.get("skus", []) as Array):
		if String(GameData.iap_product(sku).get("size", "")) == size:
			return sku
	return ""


func _save_percent() -> int:
	var sum := 0.0
	for size in ["s", "m", "l"]:
		sum += float(GameData.iap_product(_sku_of_size(size)).get("usd", 0.0))
	var all := float(GameData.iap_product(_sku_of_size("all")).get("usd", 0.0))
	return int(round((1.0 - all / sum) * 100.0)) if sum > 0.0 else 0


func _price_of(sku: String) -> String:
	var price := String((_items.get(sku, {}) as Dictionary).get("price", ""))
	return price if price != "" else String(GameData.iap_product(sku).get("price_fallback", ""))


func _countdown(seconds: float) -> String:
	var minutes := int(seconds / 60.0)
	var days := minutes / 1440
	var hours := (minutes % 1440) / 60
	if days > 0:
		return I18n.t("shop.timed_in_days") % [days, hours]
	return I18n.t("shop.timed_in_hours") % [hours, minutes % 60]


func _price_chip(text: String) -> Control:
	var chip := PanelContainer.new()
	var skin := Soft.flat(Color("d9f0ff"), 2, 12)
	skin.border_color = Color("a9d6f2")
	chip.add_theme_stylebox_override("panel", skin)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var label := _label(text, 15, INK)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(label)
	return chip


func _art_frame(file: String, minimum: Vector2) -> Control:
	var frame := PanelContainer.new()
	frame.name = "TimedArt"
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	frame.custom_minimum_size = minimum
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("cfeaff")
	skin.set_corner_radius_all(16)
	frame.add_theme_stylebox_override("panel", skin)
	var texture := TextureRect.new()
	texture.texture = load(ART_DIR + file) as Texture2D
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(texture)
	return frame


func _reward_pill(reward: Dictionary, font_size: int) -> Control:
	var pill := PanelContainer.new()
	pill.name = "Reward_" + String(reward["icon"])
	var skin := Soft.flat(Color("f7efe2"), 3, 12)
	skin.border_color = Color("eadfcb")
	skin.content_margin_left = 4
	skin.content_margin_right = 4
	pill.add_theme_stylebox_override("panel", skin)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	pill.add_child(box)
	box.add_child(PackUi.icon(String(reward["icon"]), 24))
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", -2)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(texts)
	texts.add_child(_label(String(reward["value"]), font_size + 2, INK))
	if String(reward["label"]) != "Gem":
		texts.add_child(_label(String(reward["label"]), maxi(9, font_size - 2), MUTED))
	return pill


func _buy_button(sku: String, font_size: int) -> Button:
	var entry: Dictionary = _items.get(sku, {})
	var reason := String(entry.get("reason", ""))
	var button := Button.new()
	button.name = "Iap_" + sku
	button.custom_minimum_size = Vector2(0, 40)
	button.add_theme_font_override("font", HdUi.font())
	button.add_theme_font_size_override("font_size", font_size)
	button.clip_text = true
	var sold_out := reason == "weekly" or reason == "once"
	button.disabled = _busy or reason not in ["", "busy"]
	button.text = I18n.t("shop.processing") if _busy else (I18n.t("shop.timed_bought") if sold_out else _price_of(sku))
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var disabled: bool = state == "disabled"
		var pressed: bool = state in ["pressed", "hover_pressed"]
		var top := Color("c9ced2") if disabled else Color("ffab4d" if state == "hover" else ("e8700f" if pressed else "ff9a2e"))
		button.add_theme_stylebox_override(state, ButtonSkin.palette(top, Color("b8bec3") if disabled else Color("e8700f" if pressed else "ff831e"), Color("9aa1a6") if disabled else Color("a8420a" if pressed else "d5570e")))
		button.add_theme_color_override("font_" + state + "_color" if state != "normal" else "font_color", Color("657079") if disabled else Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color("a2420a"))
	button.add_theme_constant_override("outline_size", 0 if button.disabled else 3)
	var focus := Soft.flat(Color.TRANSPARENT, 0, 24)
	focus.border_color = Color("168cc2")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(func() -> void: buy_pressed.emit(sku))
	buy_buttons[sku] = button
	return button


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", HdUi.font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
