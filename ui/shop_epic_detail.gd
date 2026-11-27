extends RefCounted
## Popup chi tiết Xe Epic / Bộ sơn Epic, dựng theo concept Design/Concepts/IAP_Epic_Garage_v1/epic_car_popup_v1.png.
## Bảng đối chiếu và toạ độ: Design/Previews/epic_popup_v2/plan.md. Sprite cắt từ concept: assets/epic_popup_v1/
## (tools/build_epic_popup_assets.py). Chỉ vẽ; giá, điều kiện mua và quà do Iap/GameState quyết.
## Nút mua và "Để sau" do ShopPage/Main nối tín hiệu.

const EpicCard = preload("res://ui/shop_epic_card.gd")
const BenefitUi = preload("res://ui/pack_benefit_ui.gd")
const Soft = preload("res://ui/soft_miniature.gd")
const ART := "res://assets/epic_popup_v1/"
const INK := Color("021650")
const CHIP_INK := Color("123a6e")
const LATER_INK := Color("6b6b6d")
const RIM := Color("f8e5d6")
const RIM_EDGE := Color("e2c6b1")
const CARD := Color("fcede2")
const CARD_EDGE := Color("e7cfbe")
const STAGE_H := 214.0
const PREVIEW_CAR := "car_apex_tia_chop"
## Ảnh sân khấu 2D cắt từ concept, theo xe được tặng. Xe/bộ sơn không có ảnh dùng sân khấu 3D. Bộ sơn: xe mẫu Apex đổi màu.
const STAGE_ART := {"car_pico_epic": "stage_pico", "car_nova_epic": "stage_nova", "car_apex_epic": "stage_apex", "car_titan_epic": "stage_titan", "car_zenith_epic": "stage_zenith",
	"epic_aurora": "stage_paint_aurora", "epic_solar": "stage_paint_solar", "epic_midnight": "stage_paint_midnight", "epic_sakura": "stage_paint_sakura", "epic_neon": "stage_paint_neon"}
## 9-slice cắt từ concept: [nắp trái, nắp phải] tính bằng pixel của texture (manifest.json của pack).
const SLICES := {"header_bar": [40, 129], "chip": [42, 42], "tile": [38, 38], "button": [85, 85]}
const TILE_ICONS := {"epic_car": ["@tile_speed", "@tile_collect", "@tile_flag"], "epic_paint": ["garage_with_car", "@tile_collect", "@tile_flag"]}
const TILE_TEXT := {
	"epic_car": ["shop.epic_perk_perf", "shop.epic_perk_collect", "shop.epic_perk_ready"],
	"epic_paint": ["shop.epic_perk_all_cars", "shop.epic_perk_paint_collect", "shop.epic_perk_ready"],
}
## Khung ngoài: viền kem dày, phần trên chừa chỗ cho thanh tiêu đề đè lên.
const SHELL_TOP := 20.0
const SHELL_SIDE := 7.0
const SHELL_BOTTOM := 7.0
## Bề rộng nội dung và lề màn hình tại 390 (khung ngoài 9..381 như concept).
const CONTENT_WIDTH := 358.0
const SCREEN_GUTTER := 18.0


static func is_epic(product: Dictionary) -> bool:
	return String(product.get("kind", "")) in ["epic_car", "epic_paint"]


## SKU kế bên cùng loại (vòng tròn) để đổi xe/sơn ngay trong popup. Trả "" nếu chỉ có một.
static func neighbor(sku: String, step: int) -> String:
	var kind := String(GameData.iap_product(sku).get("kind", ""))
	var list: Array = []
	for item: Dictionary in GameData.iap_products():
		if String(item.get("kind", "")) == kind:
			list.append(String(item["sku"]))
	var at := list.find(sku)
	if at < 0 or list.size() < 2:
		return ""
	return String(list[posmod(at + step, list.size())])


static func title(product: Dictionary) -> String:
	return I18n.t("shop.epic_car_popup_title" if String(product.get("kind", "")) == "epic_car" else "shop.epic_paint_popup_title")


static var _art := {}


## Giữ tham chiếu: texture chỉ dùng trong draw_* sẽ bị giải phóng ngay sau lần vẽ và hiện ô trắng.
static func art(file: String) -> Texture2D:
	if not _art.has(file):
		_art[file] = load(ART + file + ".png") as Texture2D
	return _art[file]


## Vẽ 9-slice ngang: hai nắp giữ tỷ lệ theo chiều cao, giữa kéo giãn. Giữ nguyên độ phân giải texture.
static func draw_slice(item: CanvasItem, file: String, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var tex := art(file)
	var caps: Array = SLICES[file]
	var h := float(tex.get_height())
	var k := rect.size.y / h
	var left := minf(float(caps[0]) * k, rect.size.x * 0.5)
	var right := minf(float(caps[1]) * k, rect.size.x - left)
	item.draw_texture_rect_region(tex, Rect2(rect.position, Vector2(left, rect.size.y)), Rect2(0, 0, caps[0], h), tint)
	var middle := Rect2(float(caps[0]) + 1.0, 0, tex.get_width() - float(caps[0]) - float(caps[1]) - 2.0, h)
	item.draw_texture_rect_region(tex, Rect2(rect.position + Vector2(left, 0), Vector2(maxf(0.0, rect.size.x - left - right), rect.size.y)), middle, tint)
	item.draw_texture_rect_region(tex, Rect2(rect.position + Vector2(rect.size.x - right, 0), Vector2(right, rect.size.y)), Rect2(tex.get_width() - float(caps[1]), 0, caps[1], h), tint)


## Khung popup (thay BenefitUi.shell cho popup Epic).
static func shell() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = RIM
	style.border_color = RIM_EDGE
	style.set_border_width_all(1)
	style.border_width_bottom = 3
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.12, 0.06, 0.18, 0.28)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	style.content_margin_left = SHELL_SIDE
	style.content_margin_right = SHELL_SIDE
	style.content_margin_top = SHELL_TOP
	style.content_margin_bottom = SHELL_BOTTOM
	return style


## Thanh tiêu đề xanh rộng hết khung, hộp quà bên trái, nút đóng tròn đè đầu phải. Gắn vào holder phủ vùng nội dung của khung.
static func header(text: String, on_close: Callable) -> Control:
	var root := Control.new()
	root.name = "EpicHeader"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.anchor_right = 1.0
	root.offset_left = -3
	root.offset_right = 2
	root.offset_top = -55
	root.offset_bottom = -3
	root.draw.connect(func() -> void: draw_slice(root, "header_bar", Rect2(Vector2.ZERO, root.size)))
	var gift := TextureRect.new()
	gift.name = "EpicHeaderGift"
	gift.texture = art("header_gift")
	gift.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gift.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gift.position = Vector2(13, -17)
	gift.size = Vector2(64, 68)
	root.add_child(gift)
	var label := Label.new()
	label.name = "PromoTitle"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", HdUi.font())
	label.add_theme_font_size_override("font_size", 23)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color("0a3a8c"))
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.16, 0.45, 0.6))
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 77
	label.offset_right = -50
	label.offset_top = -1
	label.offset_bottom = -2
	root.add_child(label)
	label.resized.connect(func() -> void: HdUi.fit_font(label, 23, 13))
	var close := TextureButton.new()
	close.name = "PromoClose"
	close.accessibility_name = I18n.t("common.close")
	close.texture_normal = art("close_round")
	close.ignore_texture_size = true
	close.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close.custom_minimum_size = Vector2(45, 45)
	close.anchor_left = 1.0
	close.anchor_right = 1.0
	close.offset_left = -47
	close.offset_right = -2
	close.offset_top = -17
	close.offset_bottom = 28
	close.button_down.connect(func() -> void: close.modulate = Color(0.85, 0.85, 0.85))
	close.button_up.connect(func() -> void: close.modulate = Color.WHITE)
	close.pressed.connect(on_close)
	root.add_child(close)
	return root


## Trả về {column, buy, later}. column là thẻ kem bên trong khung: sân khấu, tên, chip, ba ô lợi ích, nút mua, "Để sau".
static func build(product: Dictionary, scale: float) -> Dictionary:
	# Thẻ không rộng quá CONTENT_WIDTH, nên chữ/ô không phóng to quá cỡ concept ở màn rộng.
	scale = minf(scale, 1.0)
	var kind := String(product["kind"])
	var grant: Dictionary = product["grant"]
	var car: Dictionary = GameData.car(String(grant["car"])) if kind == "epic_car" else {}
	var paint: Dictionary = GameData.paint(String(grant["paint"])) if kind == "epic_paint" else {}
	var column := VBoxContainer.new()
	column.name = "EpicDetail"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)
	var card := StyleBoxFlat.new()
	card.bg_color = CARD
	card.border_color = CARD_EDGE
	card.set_border_width_all(1)
	card.set_corner_radius_all(18)
	column.draw.connect(func() -> void: column.draw_style_box(card, Rect2(Vector2(0, -8), column.size + Vector2(0, 8))))
	var stage_art := String(STAGE_ART.get(String(car.get("id", paint.get("id", ""))), ""))
	if stage_art != "":
		# Ảnh cắt rộng 354 trên thẻ 358 như concept: lề 2 hai bên, cách mép trên 3.
		column.add_child(_spacer(3 * scale))
		column.add_child(_padded(_stage_art(stage_art), 2 * scale))
	else:
		column.add_child(_spacer(6 * scale))
		column.add_child(_padded(_stage(car, paint, scale), 9 * scale))
	if neighbor(String(product["sku"]), 1) != "":
		var stage_node := column.find_child("EpicDetailStage", true, false) as Control
		stage_node.add_child(_arrow("EpicPrev", "‹", true, scale))
		stage_node.add_child(_arrow("EpicNext", "›", false, scale))
	column.add_child(_spacer((0.0 if stage_art != "" else 4.0) * scale))
	var name_label := _label(String(car.get("name", paint.get("name", ""))).to_upper(), roundi(40 * scale), INK)
	name_label.name = "EpicDetailName"
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	name_label.resized.connect(func() -> void: HdUi.fit_font(name_label, roundi(40 * scale), roundi(20 * scale)))
	# Dòng chữ Nunito cao hơn concept: giữ ô 38 và để chữ tràn đều trên dưới cho khoảng cách khớp ảnh.
	var name_slot := Control.new()
	name_slot.custom_minimum_size.y = 38 * scale
	name_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_label.offset_top = -8 * scale
	name_label.offset_bottom = 8 * scale
	name_slot.add_child(name_label)
	column.add_child(_padded(name_slot, 12 * scale))
	column.add_child(_spacer(2 * scale))
	var chip_text := I18n.t("shop.epic_car_chip") % String(car.get("class_name", "")) if kind == "epic_car" else I18n.t("shop.epic_paint_chip")
	column.add_child(_chip(chip_text, scale))
	column.add_child(_spacer(11 * scale))
	column.add_child(_padded(_tiles(kind, scale), 9 * scale))
	column.add_child(_spacer(10 * scale))
	var buy := Button.new()
	buy.custom_minimum_size.y = maxf(44.0, 65.0 * scale)
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_buy(buy, scale)
	column.add_child(_padded(buy, 7 * scale))
	column.add_child(_spacer(2 * scale))
	var later := _later_button(I18n.t("ads.later"), scale)
	later.name = "EpicLater"
	column.add_child(later)
	return {"column": column, "buy": buy, "later": later}


static func _spacer(height: float) -> Control:
	var space := Control.new()
	space.custom_minimum_size.y = height
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return space


static func _padded(child: Control, side: float) -> MarginContainer:
	var box := MarginContainer.new()
	box.add_theme_constant_override("margin_left", roundi(side))
	box.add_theme_constant_override("margin_right", roundi(side))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(child)
	return box


## Sân khấu 2D: ảnh cắt từ concept (ruy băng EPIC, ánh tím, xe, bệ ca rô), viền đã hoà vào màu thẻ.
static func _stage_art(file: String) -> Control:
	var stage := TextureRect.new()
	stage.name = "EpicDetailStage"
	stage.texture = art(file)
	stage.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	stage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return stage


## Sân khấu 3D cho sản phẩm chưa có ảnh 2D (Bộ sơn Epic).
static func _stage(car: Dictionary, paint: Dictionary, scale: float) -> Control:
	var stage := PanelContainer.new()
	stage.name = "EpicDetailStage"
	var skin := Soft.flat(Color("a07ce8"), 0, 22)
	skin.border_color = Color("8a63d6")
	skin.set_border_width_all(2)
	stage.add_theme_stylebox_override("panel", skin)
	var holder := Control.new()
	holder.custom_minimum_size.y = STAGE_H * scale
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(holder)
	var glow := EpicCard.Glow.new()
	glow.name = "EpicGlow"
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(glow)
	var preview := CarPreview.new()
	preview.name = "Preview"
	preview.show_floor = true
	preview.showroom_3d = true
	preview.pedestal_only = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if car.is_empty():
		preview.car_id = PREVIEW_CAR
		preview.paint_id = String(paint["id"])
	else:
		preview.car_id = String(car["id"])
		preview.paint_id = String(car["default_paint"])
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(preview)
	var ribbon := EpicCard.Ribbon.new()
	ribbon.name = "EpicRibbon"
	ribbon.text = I18n.t("shop.epic_ribbon")
	ribbon.font_size = roundi(20 * scale)
	ribbon.size = Vector2(96, 34) * scale
	ribbon.position = Vector2(-2, 10)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(ribbon)
	return stage


static func _sliced_panel(file: String, padding: Vector4) -> PanelContainer:
	var panel := PanelContainer.new()
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = padding.x
	empty.content_margin_top = padding.y
	empty.content_margin_right = padding.z
	empty.content_margin_bottom = padding.w
	panel.add_theme_stylebox_override("panel", empty)
	panel.draw.connect(func() -> void: draw_slice(panel, file, Rect2(Vector2.ZERO, panel.size)))
	return panel


static func _arrow(node_name: String, glyph: String, left: bool, scale: float) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = glyph
	button.focus_mode = Control.FOCUS_NONE
	var extent := maxf(44.0, 44.0 * scale)
	button.custom_minimum_size = Vector2(extent, extent)
	button.anchor_left = 0.0 if left else 1.0
	button.anchor_right = button.anchor_left
	button.anchor_top = 0.5
	button.anchor_bottom = 0.5
	button.offset_left = 4.0 if left else -extent - 4.0
	button.offset_right = button.offset_left + extent
	button.offset_top = -extent * 0.5
	button.offset_bottom = extent * 0.5
	var skin := Soft.flat(Color(1, 1, 1, 0.55), 0, 22)
	skin.set_border_width_all(0)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		button.add_theme_stylebox_override(state, skin)
	button.add_theme_font_override("font", HdUi.font())
	button.add_theme_font_size_override("font_size", 34)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color("5b2a86"))
	return button


static func _chip(text: String, scale: float) -> Control:
	var chip := _sliced_panel("chip", Vector4(13, 0, 13, 0) * scale)
	chip.name = "EpicDetailChip"
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.custom_minimum_size.y = 31 * scale
	var caption := _label(text, roundi(16 * scale), CHIP_INK)
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip.add_child(caption)
	return chip


static func _tiles(kind: String, scale: float) -> Control:
	var row := HBoxContainer.new()
	row.name = "EpicDetailTiles"
	row.add_theme_constant_override("separation", roundi(5 * scale))
	for index in 3:
		var tile := _sliced_panel("tile", Vector4(3, 2, 3, 1) * scale)
		tile.name = "EpicTile_%d" % index
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.size_flags_stretch_ratio = 1.0
		tile.custom_minimum_size.y = 91 * scale
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		tile.add_child(box)
		var id := String(TILE_ICONS[kind][index])
		var texture := art(id.substr(1)) if id.begins_with("@") else Soft.icon(id)
		var icon := BenefitUi.picture(texture, Vector2(0, 48 * scale))
		box.add_child(icon)
		var caption := _label(I18n.t(String(TILE_TEXT[kind][index])), roundi(16 * scale), INK)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.custom_minimum_size.x = 0
		caption.size_flags_vertical = Control.SIZE_EXPAND_FILL
		caption.add_theme_constant_override("line_spacing", -6)
		# Cột chữ hẹp như concept để nhãn hai từ xuống dòng giống ảnh.
		box.add_child(_padded(caption, 9 * scale))
		row.add_child(tile)
	return row


## Nút giá: viên thuốc cam cắt từ concept, chữ trắng to có bóng.
static func _style_buy(button: Button, scale: float) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var face := Control.new()
	face.name = "EpicBuyFace"
	face.show_behind_parent = true
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.draw.connect(func() -> void:
		var tint := Color.WHITE
		if button.disabled:
			tint = Color(0.78, 0.74, 0.72)
		elif button.button_pressed or button.is_pressed():
			tint = Color(0.9, 0.86, 0.82)
		draw_slice(face, "button", Rect2(Vector2.ZERO, face.size), tint))
	button.add_child(face)
	for signal_name in ["button_down", "button_up", "mouse_exited"]:
		button.connect(signal_name, face.queue_redraw)
	button.add_theme_font_override("font", HdUi.font())
	button.add_theme_font_size_override("font_size", roundi(46 * scale))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("f5f0e8"))
	button.add_theme_color_override("font_outline_color", Color("c4400a"))
	button.add_theme_constant_override("outline_size", 3)


static func _later_button(text: String, scale: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", HdUi.font())
	button.add_theme_font_size_override("font_size", roundi(18 * scale))
	# Vùng chạm vẫn 44; chữ nằm cao hơn tâm 6 như concept (sát nút giá hơn).
	var lifted := StyleBoxEmpty.new()
	lifted.content_margin_bottom = 12
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		button.add_theme_stylebox_override(state, lifted)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, LATER_INK)
	button.draw.connect(func() -> void:
		var font := button.get_theme_font("font")
		var font_size := button.get_theme_font_size("font_size")
		var extent := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var x := (button.size.x - extent.x) * 0.5
		var y := (button.size.y - 12.0 - extent.y) * 0.5 + font.get_ascent(font_size) + 4
		button.draw_line(Vector2(x - 2, y), Vector2(x + extent.x + 2, y), LATER_INK, 2.0))
	return button


static func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", HdUi.font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
