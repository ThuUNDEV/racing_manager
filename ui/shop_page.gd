extends VBoxContainer
## Shop presentation; only the daily gift is currently available in gameplay.
signal daily_requested
signal offer_requested(title: String, description: String)
signal gem_pack_requested(index: int)

const ART := "res://assets/workshop_gp/shop/"
const INK := Color("16355c")
const MUTED := Color("5a7294")
## Icon gói cũ -> icon gói racing_ui_hd (đường dẫn trong assets/racing_ui_hd/).
const HD_ICONS := {
	"daily_reward": "icons/gift.png", "season_pass": "icons/trophy.png", "monthly_pass": "icons/event.png",
	"gem": "icons/gem.png", "no_ads": "icons/crown.png", "income_boost_small": "icons/energy.png",
	"income_boost_large": "controls/chevrons.png", "offline_boost": "icons/research.png",
	"gear_card": "icons/gear.png", "gear_crate": "icons/tools.png", "driver_card": "icons/staff.png",
	"driver_helmet": "icons/avatar.png", "cash_small": "icons/cash.png", "cash_medium": "icons/cash.png",
	"cash_large": "icons/cash.png", "offer_combo": "icons/gift.png", "offer_starter": "icons/crown.png",
}
var _daily_button: Button
var _daily_description: Label
var _daily_status: Label
var _gem_grid: GridContainer
var _cash_grid: GridContainer


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	_build()
	resized.connect(_adapt_grids)
	_adapt_grids()


func _text(value: String, font_size: int = 14, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _heading(value: String) -> void:
	var heading := _text(value, 17)
	heading.custom_minimum_size.y = 32
	heading.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	heading.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.95))  # đọc được trên ảnh nền sân đua
	heading.add_theme_constant_override("outline_size", 5)
	add_child(heading)


func _icon(id: String, extent: float = 64.0) -> TextureRect:
	var expansion_id := {"gear_card": "elite_gear_pack", "gear_crate": "standard_gear_pack", "driver_card": "elite_driver_pack", "driver_helmet": "standard_driver_pack"}
	if expansion_id.has(id):
		return ExpansionArt.icon(expansion_id[id], Vector2(extent, extent))
	if HD_ICONS.has(id):
		return HdUi.icon(HD_ICONS[id], Vector2(extent, extent))
	var icon := TextureRect.new()
	icon.texture = load(ART + "icons/" + id + ".tres")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(extent, extent)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _panel(parent: Node, style: String = "card") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# PanelContainer mặc định chặn (STOP) sự kiện chuột/chạm nên ScrollContainer không nhận được thao tác kéo.
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var frame := HdUi.card_style(style).duplicate() as StyleBoxTexture
	frame.content_margin_left = 12
	frame.content_margin_right = 12
	panel.add_theme_stylebox_override("panel", frame)
	parent.add_child(panel)
	return panel


func _column(parent: Node) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	parent.add_child(column)
	return column


func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 14)
	HdUi.style_button(button, "upgrade")
	return button


func _coming_button(value: String, title: String, description: String) -> Button:
	var button := _button(value)
	button.tooltip_text = "Sắp có · " + title
	button.pressed.connect(func() -> void: offer_requested.emit(title, description))
	return button


func _build() -> void:
	_heading("QUÀ HẰNG NGÀY")
	var daily := _column(_panel(self, "pass"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	daily.add_child(row)
	row.add_child(_icon("daily_reward", 76))
	var copy := _column(row)
	copy.add_child(_text("QUÀ HẰNG NGÀY", 17))
	_daily_description = _text("", 12, MUTED)
	copy.add_child(_daily_description)
	_daily_button = _button("Nhận quà miễn phí")
	_daily_button.name = "ClaimDaily"
	HdUi.style_button(_daily_button, "claim")
	_daily_button.pressed.connect(func() -> void: daily_requested.emit())
	daily.add_child(_daily_button)
	_daily_status = _text("", 12, MUTED)
	daily.add_child(_daily_status)
	_heading("PASS")
	add_child(_text("Pass và các gói bên dưới sắp có. Nội dung, giá là dự kiến.", 12, MUTED))
	_pass("season_pass", "PASS MÙA GIẢI", "Tích lũy tiến độ qua các chặng đua.")
	_pass("monthly_pass", "PASS THÁNG", "Nhận quà mỗi ngày trong thời hạn pass.")
	_pass("gem", "QUỸ GEM", "Mở thưởng gem theo các mốc phát triển.")
	_heading("ƯU ĐÃI GIỚI HẠN")
	_banner("offer_combo", "COMBO BỨT PHÁ", "Bộ phần thưởng giúp tăng tốc đội đua.")
	_banner("offer_starter", "GÓI KHỞI ĐỘNG", "Khởi đầu cùng tay đua và tài nguyên.")
	_heading("ƯU ĐÃI ĐẶC BIỆT")
	_special("no_ads", "BỎ QUẢNG CÁO", "Nhận thưởng mà không cần xem quảng cáo.", "263.000đ")
	_special("income_boost_small", "THU NHẬP X2", "Tăng gấp 2 lần tiền nhận được.", "131.000đ")
	_special("income_boost_large", "THU NHẬP X3", "Tăng gấp 3 lần tiền nhận được.", "263.000đ")
	_special("offline_boost", "OFFLINE X3", "Gấp 3 thu nhập offline, lưu tối đa 24 giờ.", "131.000đ")
	_heading("TRANG BỊ & TAY ĐUA")
	var bundles := _grid(2)
	_bundle(bundles, "gear_card", "GÓI TRANG BỊ")
	_bundle(bundles, "driver_card", "GÓI TAY ĐUA")
	var free := _grid(2)
	_free_card(free, "gear_crate", "TRANG BỊ MIỄN PHÍ")
	_free_card(free, "driver_helmet", "TAY ĐUA MIỄN PHÍ")
	_heading("GEM")
	_gem_grid = _grid(3)
	var packs: Array = GameData.economy().get("mock_gem_packs", [])
	for i in packs.size():
		_gem_card(_gem_grid, i, int(packs[i]["gems"]), str(packs[i]["price"]))
	_heading("TIỀN")
	_cash_grid = _grid(3)
	for entry in [["cash_small", "4.08B", "10"], ["cash_medium", "16.3B", "30"], ["cash_large", "32.6B", "50"]]:
		_currency_card(_cash_grid, entry[0], entry[1], entry[2], "TIỀN")


func _pass(icon: String, title: String, description: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_panel(self, "pass").add_child(row)
	row.add_child(_icon(icon, 58))
	var copy := _column(row)
	copy.add_child(_text(title, 15))
	copy.add_child(_text("Sắp có", 12, MUTED))
	var open := _coming_button("»", title, description)
	HdUi.style_button(open, "menu")
	open.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	open.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	open.custom_minimum_size.x = 44
	open.accessibility_name = "Xem " + title
	row.add_child(open)


## Ưu đãi giới hạn: thẻ cam (biến thể "pass") với tiêu đề, mô tả, nút "Sắp có" và icon lớn bên phải.
func _banner(id: String, title: String, description: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_panel(self, "pass").add_child(row)
	var copy := _column(row)
	copy.add_child(_text(title, 16))
	copy.add_child(_text(description, 11, MUTED))
	var button := _coming_button("Sắp có", title, description)
	button.add_theme_font_size_override("font_size", 13)
	copy.add_child(button)
	row.add_child(_icon(id, 84))


func _special(icon: String, title: String, description: String, price: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_panel(self).add_child(row)
	row.add_child(_icon(icon, 46))
	var copy := _column(row)
	copy.add_child(_text(title, 14))
	copy.add_child(_text(description, 11, MUTED))
	var price_column := _column(row)
	price_column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	price_column.add_child(_coming_button(price, title, description))
	var status := _text("Sắp có", 11, MUTED)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_column.add_child(status)


func _grid(columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)
	return grid


func _bundle(parent: Node, icon: String, title: String) -> void:
	var column := _column(_panel(parent))
	column.add_child(_text(title, 13))
	var row := HBoxContainer.new()
	column.add_child(row)
	for entry in [[icon, "x2"], ["gem", "x50"]]:
		var reward := _column(row)
		reward.add_child(_icon(entry[0], 44))
		var amount := _text(entry[1], 13)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward.add_child(amount)
	column.add_child(_coming_button("26.000đ", title, "Gói gồm 2 thẻ và 50 gem."))
	column.add_child(_text("Sắp có", 11, MUTED))


func _free_card(parent: Node, icon: String, title: String) -> void:
	var column := _column(_panel(parent))
	column.add_child(_text(title, 13))
	column.add_child(_icon(icon, 70))
	column.add_child(_coming_button("Xem video", title, "Xem video để nhận phần thưởng."))
	column.add_child(_text("Sắp có", 11, MUTED))


func _currency_card(parent: Node, icon: String, amount: String, price: String, category: String) -> void:
	var column := _column(_panel(parent))
	column.add_child(_icon(icon, 64))
	var count := _text(amount, 20)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(count)
	var button := _coming_button(price, amount + " " + category, "Gói " + amount + " " + category.to_lower() + ".")
	button.add_theme_font_size_override("font_size", 12)
	if category == "TIỀN":
		button.icon = HdUi.scaled("icons/gem.png", 0.07)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		button.add_theme_constant_override("icon_max_width", 18)
	column.add_child(button)
	var status := _text("Sắp có", 11, MUTED)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)


## Thẻ gói gem: bấm là mua giả lập (cộng gem ngay), chưa qua IAP thật.
func _gem_card(parent: Node, index: int, amount: int, price: String) -> void:
	var column := _column(_panel(parent))
	column.add_child(_icon("gem", 64))
	var count := _text(str(amount), 20)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(count)
	var button := _button(price)
	button.name = "GemPack%d" % index
	button.add_theme_font_size_override("font_size", 12)
	HdUi.style_button(button, "claim")
	button.tooltip_text = "Mua giả lập · %d gem" % amount
	button.pressed.connect(func() -> void: gem_pack_requested.emit(index))
	column.add_child(button)
	var status := _text("Giả lập", 11, MUTED)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)


func _adapt_grids() -> void:
	# Allow for the page margins and scrollbar; compact phones use two.
	if is_instance_valid(_gem_grid):
		_gem_grid.columns = 3 if size.x >= 345 else 2
	if is_instance_valid(_cash_grid):
		_cash_grid.columns = 3 if size.x >= 345 else 2


func update_daily(amount: String, gems: int, available: bool, blocked: bool) -> void:
	_daily_description.text = "%s tiền + %d gem" % [amount, gems]
	_daily_button.disabled = not available or blocked
	_daily_button.text = "Đã nhận hôm nay" if not available else ("Chờ lưu lại" if blocked else "Nhận quà miễn phí")
	_daily_status.text = "Làm mới 00:00 UTC · mỗi ngày một lần"
