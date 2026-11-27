extends PanelContainer
## Thẻ Xe Epic / Bộ sơn Epic trong Shop (Design/35 đợt E1, concept Design/Concepts/IAP_Epic_Garage_v1).
## mode "car": 5 xe Epic, mỗi hạng một xe. mode "paint": 5 bộ sơn Epic dùng cho mọi xe đã có. Hàng thẻ cuộn ngang.
## Chỉ vẽ; giá, điều kiện và quyền sở hữu do Iap/GameState quyết (view["items"][sku].reason).

signal buy_pressed(sku: String)

const Soft = preload("res://ui/soft_miniature.gd")
const ButtonSkin = preload("res://ui/button_skin.gd")
const INK := Color("0e2b5c")
const MUTED := Color("5f6f7a")
const CREAM := Color("fff4e4")
const CARD_W := 148.0
const CARD_GAP := 8.0
const STAGE_H := 128.0
const PREVIEW_CAR := "car_apex_tia_chop"
const STAT_ROOT := "res://assets/garage_soft_miniature_v2/"
const BAR_ORDER := ["S", "A", "H", "B"]
const BAR_ICONS := {"S": "stat_speed", "A": "stat_acceleration", "H": "stat_grip", "B": "stat_stability"}
const BAR_COLORS := {"S": Color("3a9be8"), "A": Color("f2b61e"), "H": Color("4cb84a"), "B": Color("9a52dc")}
const BAR_SEGMENTS := 5
const DOT_ON := Color("1a9be0")
const DOT_OFF := Color("c9c4bb")


## Cờ EPIC tím: thân chữ nhật, mép phải cắt chéo có khấc, bóng nhẹ phía dưới.
class Ribbon extends Control:
	var text := ""
	var font_size := 13

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var shade := PackedVector2Array([Vector2(2, 3), Vector2(w, 1), Vector2(w - 9, h * 0.5 + 2), Vector2(w - 1, h + 2), Vector2(2, h + 2)])
		draw_colored_polygon(shade, Color("5b2a86"))
		var body := PackedVector2Array([Vector2(0, 0), Vector2(w - 1, 0), Vector2(w - 10, h * 0.5), Vector2(w - 2, h), Vector2(0, h)])
		draw_colored_polygon(body, Color("a45be6"))
		var gloss := PackedVector2Array([Vector2(0, 0), Vector2(w - 1, 0), Vector2(w - 5, h * 0.3), Vector2(0, h * 0.3)])
		draw_colored_polygon(gloss, Color(1, 1, 1, 0.22))
		var font := HdUi.font()
		var extent := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var origin := Vector2((w - 8.0 - extent.x) * 0.5, (h + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
		draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("55208a"))
		draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


## Nền sân khấu tím: quầng sáng phía sau xe và vài ngôi sao lấp lánh.
class Glow extends Control:
	const SPARKS := [[0.18, 0.34, 7.0], [0.82, 0.22, 9.0], [0.66, 0.48, 4.5], [0.34, 0.16, 4.0]]
	var _halo: GradientTexture2D

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 0.93, 1, 0.85))
		gradient.set_color(1, Color(0.8, 0.6, 1, 0.0))
		_halo = GradientTexture2D.new()
		_halo.gradient = gradient
		_halo.fill = GradientTexture2D.FILL_RADIAL
		_halo.fill_from = Vector2(0.5, 0.5)
		_halo.fill_to = Vector2(1.0, 0.5)
		_halo.width = 128
		_halo.height = 128

	func _draw() -> void:
		var halo_size := Vector2(size.x * 1.15, size.y * 1.0)
		draw_texture_rect(_halo, Rect2(Vector2(size.x * 0.5 - halo_size.x * 0.5, size.y * 0.55 - halo_size.y * 0.5), halo_size), false)
		for spark: Array in SPARKS:
			_star(Vector2(size.x * float(spark[0]), size.y * float(spark[1])), float(spark[2]))

	func _star(center: Vector2, radius: float) -> void:
		var points := PackedVector2Array()
		for index in 8:
			var reach := radius if index % 2 == 0 else radius * 0.28
			var angle := -PI * 0.5 + index * PI * 0.25
			points.append(center + Vector2(cos(angle), sin(angle)) * reach)
		draw_colored_polygon(points, Color(1, 1, 1, 0.95))

var mode := ""
var buy_buttons: Dictionary = {}
var _scroll: ScrollContainer
var _row: HBoxContainer
var _dots: HBoxContainer
var _items: Dictionary = {}
var _busy := false
var _snap: Tween


func setup(card_mode: String) -> void:
	mode = card_mode
	name = "Epic_" + card_mode
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var surface := Soft.flat(CREAM, 8, 22)
	surface.border_color = Color("ecd9bd")
	surface.set_border_width_all(2)
	surface.content_margin_bottom = 10
	add_theme_stylebox_override("panel", surface)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	_scroll = ScrollContainer.new()
	_scroll.name = "EpicScroll"
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.get_h_scroll_bar().value_changed.connect(func(_value: float) -> void: _sync_dots())
	_scroll.scroll_ended.connect(_snap_to_card)
	column.add_child(_scroll)
	_row = HBoxContainer.new()
	_row.name = "EpicRow"
	_row.add_theme_constant_override("separation", int(CARD_GAP))
	_scroll.add_child(_row)
	_dots = HBoxContainer.new()
	_dots.name = "EpicDots"
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots.add_theme_constant_override("separation", 10)
	column.add_child(_dots)
	_rebuild()


func skus() -> Array:
	var out: Array = []
	for p: Dictionary in GameData.iap_products():
		if String(p.get("kind", "")) == "epic_" + mode:
			out.append(String(p["sku"]))
	return out


func update_view(items: Dictionary, busy: bool) -> void:
	_items = items
	_busy = busy
	var keep := _scroll.scroll_horizontal
	_rebuild()
	_scroll.set_deferred("scroll_horizontal", keep)


func page_count() -> int:
	return maxi(1, ceili(float(skus().size()) / 2.0))


func _rebuild() -> void:
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	buy_buttons.clear()
	for sku: String in skus():
		_row.add_child(_card(sku))
	for child in _dots.get_children():
		_dots.remove_child(child)
		child.queue_free()
	for index in page_count():
		var dot := Panel.new()
		dot.name = "Dot_%d" % index
		dot.custom_minimum_size = Vector2(12, 12)
		_dots.add_child(dot)
	_sync_dots()


func _sync_dots() -> void:
	var bar := _scroll.get_h_scroll_bar()
	var span := maxf(bar.max_value - bar.page, 1.0)
	var current := clampi(roundi(float(_scroll.scroll_horizontal) / span * float(page_count() - 1)), 0, page_count() - 1)
	for index in _dots.get_child_count():
		var dot := _dots.get_child(index) as Panel
		var skin := Soft.flat(DOT_ON if index == current else DOT_OFF, 0, 6)
		skin.set_border_width_all(0)
		dot.add_theme_stylebox_override("panel", skin)
	set_meta("page", current)


func _snap_to_card() -> void:
	var step := CARD_W + CARD_GAP
	var target := roundi(float(_scroll.scroll_horizontal) / step) * step
	var bar := _scroll.get_h_scroll_bar()
	target = clampf(target, 0.0, maxf(bar.max_value - bar.page, 0.0))
	if _snap != null and _snap.is_valid():
		_snap.kill()
	_snap = create_tween()
	_snap.tween_property(_scroll, "scroll_horizontal", int(target), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _card(sku: String) -> Control:
	var product := GameData.iap_product(sku)
	var grant: Dictionary = product["grant"]
	var card := PanelContainer.new()
	card.name = "EpicCard_" + sku
	card.custom_minimum_size.x = CARD_W
	var skin := Soft.flat(Color("fffaf0"), 7, 18)
	skin.border_color = Color("efe2cd")
	skin.set_border_width_all(2)
	card.add_theme_stylebox_override("panel", skin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	card.add_child(column)
	var stage := PanelContainer.new()
	stage.name = "EpicStage"
	var stage_skin := Soft.flat(Color("a07ce8"), 0, 16)
	stage_skin.border_color = Color("8a63d6")
	stage_skin.set_border_width_all(1)
	stage.add_theme_stylebox_override("panel", stage_skin)
	column.add_child(stage)
	var holder := Control.new()
	holder.name = "EpicStageArt"
	holder.custom_minimum_size.y = STAGE_H - 2.0
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(holder)
	var glow := Glow.new()
	glow.name = "EpicGlow"
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(glow)
	var preview := CarPreview.new()
	preview.name = "Preview"
	preview.show_floor = true
	preview.showroom_3d = true
	preview.pedestal_only = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := ""
	if mode == "car":
		var car := GameData.car(String(grant["car"]))
		preview.car_id = String(car["id"])
		preview.paint_id = String(car["default_paint"])
		title = String(car["name"])
	else:
		var paint := GameData.paint(String(grant["paint"]))
		preview.car_id = PREVIEW_CAR
		preview.paint_id = String(paint["id"])
		title = String(paint["name"])
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(preview)
	var ribbon := Ribbon.new()
	ribbon.name = "EpicRibbon"
	ribbon.text = I18n.t("shop.epic_ribbon")
	ribbon.size = Vector2(62, 24)
	ribbon.position = Vector2(-2, 6)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(ribbon)
	var name_label := _label(title.to_upper(), 18, INK)
	name_label.name = "EpicName"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	if mode == "car":
		column.add_child(_chip(I18n.t("shop.epic_tag")))
		column.add_child(_bars(GameData.car(String(grant["car"]))))
	else:
		var note := _label(I18n.t("shop.epic_for_all"), 12, INK)
		note.name = "EpicNote"
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(note)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	column.add_child(_buy_button(sku))
	return card


func _chip(text: String) -> Control:
	var chip := PanelContainer.new()
	var skin := Soft.flat(Color("d3ecfb"), 3, 14)
	skin.border_color = Color("a9d6f2")
	skin.set_border_width_all(2)
	chip.add_theme_stylebox_override("panel", skin)
	chip.size_flags_horizontal = Control.SIZE_FILL
	var label := _label(text, 12, Color("1b5f93"))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(label)
	return chip


## Bốn hàng chỉ số: biểu tượng + thanh 5 đoạn, so với xe Epic mạnh nhất (không hiện số).
func _bars(car: Dictionary) -> Control:
	var best := 1
	for c: Dictionary in GameData.epic_cars():
		for key in GameData.PART_KEYS:
			best = maxi(best, int((c["base"] as Dictionary)[key]))
	var box := VBoxContainer.new()
	box.name = "EpicBars"
	box.add_theme_constant_override("separation", 5)
	for key: String in BAR_ORDER:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 5)
		var icon := TextureRect.new()
		icon.texture = load(STAT_ROOT + String(BAR_ICONS[key]) + ".png")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(24, 22)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(icon)
		var ratio := float(int((car["base"] as Dictionary)[key])) / float(best)
		var filled := clampi(roundi(ratio * BAR_SEGMENTS), 1, BAR_SEGMENTS)
		var track := PanelContainer.new()
		track.name = "Bar_" + key
		track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		track.set_meta("filled", filled)
		var track_skin := Soft.flat(Color("e4ddd0"), 2, 6)
		track_skin.set_border_width_all(0)
		track.add_theme_stylebox_override("panel", track_skin)
		var segments := HBoxContainer.new()
		segments.add_theme_constant_override("separation", 2)
		track.add_child(segments)
		for index in BAR_SEGMENTS:
			var segment := Panel.new()
			segment.custom_minimum_size = Vector2(0, 9)
			segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var segment_skin := Soft.flat(BAR_COLORS[key] if index < filled else Color("e4ddd0"), 0, 4)
			segment_skin.set_border_width_all(0)
			segment.add_theme_stylebox_override("panel", segment_skin)
			segments.add_child(segment)
		line.add_child(track)
		box.add_child(line)
	return box


func _buy_button(sku: String) -> Button:
	var entry: Dictionary = _items.get(sku, {})
	var reason := String(entry.get("reason", ""))
	var price := String(entry.get("price", ""))
	if price == "":
		price = String(GameData.iap_product(sku).get("price_fallback", ""))
	var button := Button.new()
	button.name = "Iap_" + sku
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_override("font", HdUi.font())
	button.add_theme_font_size_override("font_size", 21)
	button.clip_text = true
	var bought := reason in ["once", "owned"]
	button.disabled = _busy or reason not in ["", "busy"]
	button.text = I18n.t("shop.processing") if _busy else (I18n.t("shop.timed_bought") if bought else price)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var disabled: bool = state == "disabled"
		var pressed: bool = state in ["pressed", "hover_pressed"]
		var top := Color("c9ced2") if disabled else Color("ff9a3a" if not pressed else "f07f20")
		button.add_theme_stylebox_override(state, ButtonSkin.palette(top, Color("b8bec3") if disabled else Color("e8700f" if pressed else "ff831e"), Color("9aa1a6") if disabled else Color("a8420a" if pressed else "d5570e")))
		button.add_theme_color_override("font_" + state + "_color" if state != "normal" else "font_color", Color("657079") if disabled else Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color("a2420a"))
	button.add_theme_constant_override("outline_size", 0 if button.disabled else 3)
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
