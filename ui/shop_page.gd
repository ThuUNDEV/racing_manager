extends VBoxContainer
const CleanArt = preload("res://ui/clean_modern_art.gd")
## Illustrated Shop. Catalog, eligibility, prices and purchases come from the IAP view/service.
signal daily_requested
## Thưởng đăng nhập hằng ngày (Design/30): mở popup Quà mỗi ngày.
signal daily_rewards_requested
signal offer_requested(title: String, description: String)
## IAP: người chơi bấm mua một SKU (data/iap.json). Logic mua nằm ở autoload Iap; trang này chỉ vẽ và phát tín hiệu.
signal iap_requested(sku: String)
signal restore_requested
signal details_requested(sku: String)
signal odds_requested(sku: String)
## Quảng cáo rewarded: người chơi bấm thẻ miễn phí (placement trong data/ads.json). Main gọi Ads rồi báo kết quả.
signal ad_requested(placement: String)
## Mở gói tay đua ("driver") hoặc phụ kiện ("gear") x1/x10 ngay trong Shop; main xử lý như ở Túi/Tay đua.
signal pack_open_requested(kind: String, pack_id: String, count: int)
signal pack_info_requested(kind: String, pack_id: String)

const ART := "res://assets/workshop_gp/shop/"
const INK := Color("23394a")
const MUTED := Color("768ca0")
const PackUi = preload("res://ui/shop_pack_ui.gd")
const ShopSkin = preload("res://ui/shop_demo_skin.gd")
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
var _login_row: HBoxContainer
var _login_button: Button
var _login_description: Label
var _gem_grid: GridContainer
var _cash_grid: GridContainer
var _gem_heading: Control
var _cash_heading: Control
var _iap_buttons: Dictionary = {}   # sku -> {button: Button, status: Label}
var _restore_button: Button
var _ad_buttons: Dictionary = {}   # placement -> {button: Button, status: Label}
var _sections: Array = []
var _pack_box: VBoxContainer
var _pack_heading: Control
var _pack_sig := ""
var _last_iap_view: Dictionary = {}
var _starter_choice := ""
var _starter_steps: Dictionary = {}
var _detail_buy: Button
var _detail_status: Label
var _detail_sku := ""
var _eligibility: Dictionary = {}


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


func _heading(value: String) -> Label:
	var heading := _text(value, 16, Color.WHITE)
	heading.custom_minimum_size.y = 30
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_theme_stylebox_override("normal", ShopSkin.surface("section", 4))
	heading.add_theme_color_override("font_outline_color", Color("0751a7"))
	heading.add_theme_constant_override("outline_size", 1)
	add_child(heading)
	return heading


func _icon(id: String, extent: float = 64.0) -> TextureRect:
	var expansion_id := {"gear_card": "elite_gear_pack", "gear_crate": "standard_gear_pack", "driver_card": "elite_driver_pack", "driver_helmet": "standard_driver_pack"}
	if expansion_id.has(id):
		return ExpansionArt.icon(expansion_id[id], Vector2(extent, extent))
	if HD_ICONS.has(id):
		return HdUi.icon(HD_ICONS[id], Vector2(extent, extent))
	var icon := TextureRect.new()
	icon.texture = CleanArt.asset(ART + "icons/" + id + ".tres")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(extent, extent)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _panel(parent: Node, style: String = "card") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", ShopSkin.surface("free" if style == "pass" else "tile", 6))
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
	button.add_theme_font_size_override("font_size", 15)
	ShopSkin.style_button(button)
	return button


func _coming_button(value: String, title: String, description: String) -> Button:
	var button := _button(value)
	button.pressed.connect(func() -> void: offer_requested.emit(title, description))
	return button


func _build() -> void:
	add_theme_constant_override("separation", 8)
	var header := HBoxContainer.new()
	header.name = "ShopTitle"
	header.add_theme_constant_override("separation", 8)
	add_child(header)
	for side in range(3):
		if side == 1:
			var title := _text(I18n.t("shop.shop"), 27, ShopSkin.INK)
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			header.add_child(title)
		else:
			var flag := TextureRect.new()
			flag.texture = load("res://assets/shop_blue_white/flags.svg")
			flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			flag.custom_minimum_size = Vector2(34, 32)
			flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			header.add_child(flag)
	_offer_section(I18n.t("shop.special_packs"), ["starter", "perk", "offer"], ["starter_1", "starter_2", "starter_3", "income_x2", "no_ads", "offer_noads_bundle"])
	_offer_section(I18n.t("shop.recruit_drivers"), ["character"], ["char_my", "char_lam"])
	_build_daily_banner()
	_build_free_gem_banner()
	_pack_heading = _heading(I18n.t("shop.open_packs"))
	_pack_heading.name = "OpenPacksHeading"
	_pack_box = VBoxContainer.new()
	_pack_box.name = "OpenPacks"
	_pack_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_pack_box)
	update_packs()
	_offer_section(I18n.t("shop.daily_packs"), ["daily"])
	var gem_heading := _heading("GEM")
	_gem_heading = gem_heading
	_gem_grid = _grid(3)
	for product: Dictionary in GameData.iap_products():
		if String(product.get("kind", "")) == "gems":
			_gem_card(_gem_grid, String(product["sku"]), int(product["grant"]["gems"]), String(product.get("price_fallback", "")))
	_free_gem_card(_gem_grid)
	_sections.append({"heading": gem_heading, "content": _gem_grid, "group": "resources"})
	var cash_heading := _heading(I18n.t("shop.exchange_cash"))
	_cash_heading = cash_heading
	_cash_grid = _grid(3)
	for entry in [["cash_small", "4.08B", "10"], ["cash_medium", "16.3B", "30"], ["cash_large", "32.6B", "50"]]:
		_currency_card(_cash_grid, entry[0], entry[1], entry[2], I18n.t("shop.cash"))
	_sections.append({"heading": cash_heading, "content": _cash_grid, "group": "resources"})
	var free_heading := _heading(I18n.t("shop.free_tickets"))
	var free := _grid(2)
	_free_card(free, "gear_crate", I18n.t("shop.gear_tickets"), "free_gear_coupon")
	_free_card(free, "driver_helmet", I18n.t("shop.driver_tickets"), "free_driver_coupon")
	_sections.append({"heading": free_heading, "content": free, "group": "resources"})
	_offer_section(I18n.t("shop.more_perks"), ["perk"], ["income_x3", "income_x3_up", "offline_plus"])
	_offer_section(I18n.t("shop.breakthrough_combo"), ["offer"], ["offer_combo_1", "offer_combo_2"])
	_offer_section(I18n.t("shop.weekly_packs"), ["weekly"])
	_offer_section(I18n.t("shop.other_drivers"), ["character"], ["char_nhan", "char_phuong", "char_quang", "char_son"])
	_restore_button = _button(I18n.t("shop.restore_purchases"))
	_restore_button.name = "RestorePurchases"
	_restore_button.visible = false
	ShopSkin.style_button(_restore_button, "tab")
	_restore_button.pressed.connect(func() -> void: restore_requested.emit())
	add_child(_restore_button)
	add_child(_login_row)
	_sync_sections()

func _reference_canvas(parent: Node, design_size: Vector2) -> Control:
	var panel := Control.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var canvas := Control.new()
	canvas.size = design_size
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(canvas)
	var bg := Panel.new()
	bg.size = design_size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", ShopSkin.surface("banner", 0))
	canvas.add_child(bg)
	panel.resized.connect(func() -> void:
		var factor := panel.size.x / design_size.x
		canvas.scale = Vector2.ONE * factor
		panel.custom_minimum_size.y = design_size.y * factor
	)
	return canvas

func _build_daily_banner() -> void:
	var canvas := _reference_canvas(self, Vector2(550, 94))
	canvas.get_parent().name = "DailyGiftBanner"
	var gift := ShopSkin.region_picture(Rect2(62, 1104, 112, 94))
	gift.position = Vector2(28, 0)
	gift.size = Vector2(112, 94)
	canvas.add_child(gift)
	var title := _text(I18n.t("shop.today_gift"), 29, ShopSkin.INK)
	title.position = Vector2(180, 0)
	title.size = Vector2(235, 38)
	canvas.add_child(title)
	_daily_description = _text("", 19, ShopSkin.INK)
	_daily_description.position = Vector2(180, 47)
	_daily_description.size = Vector2(205, 30)
	canvas.add_child(_daily_description)
	_daily_button = _button(I18n.t("shop.claim"))
	_daily_button.name = "ClaimDaily"
	_daily_button.position = Vector2(398, 30)
	_daily_button.size = Vector2(138, 55)
	_daily_button.add_theme_font_size_override("font_size", 30)
	_daily_button.pressed.connect(func() -> void: daily_requested.emit())
	canvas.add_child(_daily_button)
	_daily_status = _text("", 12, MUTED)
	_daily_status.hide()
	canvas.add_child(_daily_status)
	_sections.append({"heading": canvas.get_parent(), "content": canvas, "group": "featured"})
	# Keep the separate login reward entry available after the reference catalog.
	_login_row = HBoxContainer.new()
	_login_row.hide()
	_login_description = _text("", 12, MUTED)
	_login_row.add_child(_login_description)
	_login_button = _button(I18n.t("shop.view"))
	_login_button.name = "OpenDailyRewards"
	_login_button.pressed.connect(func() -> void: daily_rewards_requested.emit())
	_login_row.add_child(_login_button)


const OFFER_TEXT := {
	"starter_1": ["shop.starter_pack_i", "shop.first_driver_resources"],
	"starter_2": ["shop.starter_pack_ii", "shop.next_boost"],
	"starter_3": ["shop.starter_pack_iii", "shop.biggest_starter_pack"],
	"offer_combo_1": ["shop.breakthrough_combo_i", "shop.gift_bundle_speed_up_team"],
	"offer_combo_2": ["shop.breakthrough_combo_ii", "shop.big_gift_bundle_team"],
	"offer_noads_bundle": ["shop.no_ads_combo", "shop.remove_ads_plus_gifts"],
	"no_ads": ["shop.remove_ads", "shop.get_ad_rewards_without_watching"],
	"income_x2": ["shop.income_x2", "shop.doubles_cash_you_earn"],
	"income_x3": ["shop.income_x3", "shop.triples_cash_you_earn"],
	"income_x3_up": ["shop.upgrade_x3", "shop.upgrade_x2_income_x3"],
	"offline_plus": ["OFFLINE X3", "shop.triple_offline_income_up_24"],
	"daily_gear": ["shop.daily_gear", "shop.one_pack_every_day"],
	"daily_driver": ["shop.daily_driver", "shop.one_pack_every_day"],
	"pass_month": ["shop.monthly_pass", "shop.gem_gifts_every_day_length"],
	"pass_growth": ["shop.growth_fund", "shop.unlock_rewards_at_growth_milestones"],
	"weekly_s": ["shop.weekly_pack", "shop.once_week"],
	"weekly_m": ["shop.weekly_pack_m", "shop.once_week"],
	"weekly_l": ["shop.weekly_pack_l", "shop.once_week"],
	"weekly_xl": ["shop.weekly_pack_xl", "shop.once_week"],
}
## Lý do khóa làm thẻ ẩn hẳn (chưa tới lúc bán / không còn bán).
const HIDDEN_REASONS := ["flag", "hidden", "locked", "requires", "maxed", "none"]
var _offer_cards: Dictionary = {}   # sku -> Control (thẻ, ẩn/hiện theo lý do bán)


func _offer_title(p: Dictionary) -> Array:
	var sku := String(p["sku"])
	var text: Array = (OFFER_TEXT.get(sku, [sku, ""]) as Array).map(func(k: String) -> String: return I18n.t(k) if I18n.has(k) else k)
	if String(p.get("kind", "")) == "character":
		var d := GameData.driver(String((p.get("grant", {}) as Dictionary).get("driver", "")))
		text[0] = String(d.get("name", sku)).to_upper()
		text[1] = I18n.t("shop.driver_plus_bonus_shards")
	return text


func _offer_section(title: String, kinds: Array, only_skus: Array = []) -> void:
	var heading := _heading(title)
	var group := "drivers" if "character" in kinds else ("perks" if "perk" in kinds or "pass_month" in kinds else "resources")
	var mixed := "starter" in kinds
	if mixed or "offer" in kinds:
		group = "featured"
	var steps: HBoxContainer
	if "starter" in kinds:
		steps = HBoxContainer.new()
		steps.add_theme_constant_override("separation", 4)
		add_child(steps)
	var grid := _grid(2 if "daily" in kinds else 1)
	var candidates: Array = []
	if only_skus.is_empty():
		candidates = GameData.iap_products()
	else:
		for sku: String in only_skus:
			candidates.append(GameData.iap_product(sku))
	for product: Dictionary in candidates:
		if not String(product.get("kind", "")) in kinds:
			continue
		_offer_card(grid, product)
		if steps != null and String(product.get("kind", "")) == "starter":
			var sku := String(product["sku"])
			var step := _button({"starter_1": I18n.t("common.rookie"), "starter_2": I18n.t("shop.starter"), "starter_3": I18n.t("common.professional")}[sku])
			step.add_theme_font_size_override("font_size", 11)
			step.toggle_mode = true
			step.pressed.connect(func() -> void: _starter_choice = sku; _sync_sections())
			steps.add_child(step)
			_starter_steps[sku] = step
	_sections.append({"heading": heading, "content": grid, "group": group, "steps": steps, "mixed": mixed})


func _offer_card(parent: Node, p: Dictionary) -> void:
	var sku := String(p["sku"])
	var kind := String(p.get("kind", ""))
	if kind in ["starter", "character", "daily"] or sku in ["income_x2", "no_ads", "offer_noads_bundle"]:
		_demo_offer_card(parent, p)
		return
	var panel := _panel(parent)
	panel.name = "Offer_" + sku
	panel.add_theme_stylebox_override("panel", ShopSkin.surface("banner", 7))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	var portrait: TextureRect
	if kind != "daily":
		if kind in ["starter", "character"]:
			portrait = ShopSkin.portrait(sku, Vector2(78, 105))
		else:
			var id := "income" if sku.begins_with("income") else ("no_ads" if sku in ["no_ads", "offer_noads_bundle"] else ("offline" if sku == "offline_plus" else "gift"))
			portrait = ShopSkin.picture(id, Vector2(78, 86))
		portrait.name = "OfferArt_" + sku
		row.add_child(portrait)
	var column := _column(row)
	column.add_theme_constant_override("separation", 3)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := _text(PackUi.title(p), 16 if kind == "daily" else 18, ShopSkin.INK)
	title.name = "PackTitle"
	title_row.add_child(title)
	var space := Control.new()
	space.custom_minimum_size.x = 25
	title_row.add_child(space)
	var rewards := VBoxContainer.new()
	rewards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards.name = "PackRewards_" + sku
	column.add_child(rewards)
	_render_rewards(rewards, p, false, false)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 3)
	column.add_child(footer)
	if kind != "daily":
		var limit := _text(PackUi.limit(p), 10, Color("3e6b9b"))
		limit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		footer.add_child(limit)
	var button := _button(String(p.get("price_fallback", "")))
	button.name = "Iap_" + sku
	button.custom_minimum_size.x = 108 if kind != "daily" else 0
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(func() -> void: iap_requested.emit(sku))
	footer.add_child(button)
	var status := _text("", 10, MUTED)
	column.add_child(status)
	status.visible = false
	# A 44px info target overlays the quiet top-right corner without adding a tall links row.
	var info_layer := Control.new()
	info_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(info_layer)
	var details := _link("ⓘ")
	details.name = "Detail_" + sku
	details.add_theme_font_size_override("font_size", 23)
	details.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	details.offset_left = -35
	details.offset_right = 9
	details.offset_top = -9
	details.offset_bottom = 35
	details.pressed.connect(func() -> void: details_requested.emit(sku))
	info_layer.add_child(details)
	_iap_buttons[sku] = {"button": button, "status": status, "rewards": rewards, "full": false, "owned": false, "portrait": portrait}
	_offer_cards[sku] = panel


func _demo_offer_card(parent: Node, p: Dictionary) -> void:
	var sku := String(p["sku"])
	var kind := String(p["kind"])
	var starter := kind == "starter"
	var character := kind == "character"
	var daily := kind == "daily"
	var height := 190.0 if starter else (140.0 if sku == "income_x2" else (118.0 if sku == "no_ads" else (128.0 if character else 142.0)))
	var width := 264.0 if daily else 550.0
	var panel := Control.new()
	panel.name = "Offer_" + sku
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var canvas := Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.size = Vector2(width, height)
	panel.add_child(canvas)
	var bg := Panel.new()
	bg.add_theme_stylebox_override("panel", ShopSkin.surface("banner", 0))
	bg.size = canvas.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)
	var art: TextureRect
	if sku in ["starter_1", "char_my", "char_lam", "daily_gear", "daily_driver"]:
		art = ShopSkin.demo_picture(sku, Vector2.ZERO)
	elif starter or character:
		art = ShopSkin.portrait(sku, Vector2.ZERO)
	else:
		art = ShopSkin.region_picture(Rect2(50, 484, 177, 125) if sku == "income_x2" else Rect2(65, 643, 133, 101))
	art.name = "OfferArt_" + sku
	canvas.add_child(art)
	art.position = Vector2(10, -3) if starter or character else Vector2(16, 8)
	art.size = Vector2(184, 190) if starter else (Vector2(155, 132) if character else Vector2(177, 125))
	if sku == "no_ads":
		art.position = Vector2(34, 10)
		art.size = Vector2(133, 101)
	if daily:
		art.position = Vector2(14, 38)
		art.size = Vector2(108, 83)
	var title := _text(I18n.t("common.gear") if sku == "daily_gear" else (I18n.t("common.drivers") if daily else PackUi.title(p)), 30, ShopSkin.INK)
	title.name = "PackTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.position = Vector2(200, 2) if starter else Vector2(177 if character else 207, 2)
	if daily: title.position = Vector2(20, 0)
	title.size = Vector2(width - title.position.x - 38, 40)
	canvas.add_child(title)
	var rewards := VBoxContainer.new()
	rewards.name = "PackRewards_" + sku
	rewards.position = Vector2(202, 50) if starter else (Vector2(178, 39) if character else Vector2(200, 48))
	rewards.size = Vector2(334, 72) if starter else Vector2(230 if character else 165, 73)
	if daily:
		rewards.position = Vector2(150, 42)
		rewards.size = Vector2(105, 40)
	canvas.add_child(rewards)
	_render_rewards(rewards, p, false, false)
	if sku == "income_x2":
		rewards.hide()
		var multiplier := ShopSkin.region_picture(Rect2(233, 520, 152, 87))
		multiplier.position = Vector2(204, 44)
		multiplier.size = Vector2(152, 87)
		canvas.add_child(multiplier)
	var buy := _button(String(p.get("price_fallback", "")))
	buy.name = "Iap_" + sku
	buy.custom_minimum_size = Vector2.ZERO
	buy.position = Vector2(358, 125) if starter else (Vector2(414, 73) if character else Vector2(366, height - 67))
	buy.size = Vector2(177, 54) if starter else (Vector2(124, 49) if character else Vector2(168, 55))
	if daily:
		buy.position = Vector2(132, 90)
		buy.size = Vector2(121, 46)
	buy.pressed.connect(func() -> void: iap_requested.emit(sku))
	canvas.add_child(buy)
	ShopSkin.price_text(buy, 29 if not character and not daily else 23)
	var status := _text("", 16, MUTED)
	status.visible = false
	status.position = Vector2(205, height - 25)
	status.size = Vector2(width - 215, 25)
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	canvas.add_child(status)
	var info := Button.new()
	info.name = "Detail_" + sku
	info.flat = true
	info.position = Vector2(width - 51, 1)
	info.size = Vector2(44, 44)
	info.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	info.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	info.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	var info_art := ShopSkin.region_picture(Rect2(529, 280, 34, 34))
	info_art.position = Vector2(5, 5)
	info_art.size = Vector2(34, 34)
	info.add_child(info_art)
	info.pressed.connect(func() -> void: details_requested.emit(sku))
	canvas.add_child(info)
	if starter:
		var badge := ShopSkin.region_picture(Rect2(22, 262, 82, 76))
		badge.position = Vector2(-7, -12)
		badge.size = Vector2(82, 76)
		canvas.add_child(badge)
	panel.resized.connect(func() -> void:
		var factor := panel.size.x / width
		canvas.scale = Vector2.ONE * factor
		panel.custom_minimum_size.y = height * factor
	)
	_iap_buttons[sku] = {"button": buy, "status": status, "rewards": rewards, "full": false, "owned": false, "reference": true}
	_offer_cards[sku] = panel


func _demo_badge(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color.WHITE
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(2)
	return style


func _build_free_gem_banner() -> void:
	var canvas := _reference_canvas(self, Vector2(550, 110))
	canvas.get_parent().name = "FreeGemBanner"
	var art := ShopSkin.region_picture(Rect2(621, 211, 180, 112))
	art.position = Vector2(-3, -7)
	art.size = Vector2(180, 112)
	canvas.add_child(art)
	var title := _text(I18n.t("shop.free_gems"), 26, ShopSkin.INK)
	title.position = Vector2(188, 35)
	title.size = Vector2(180, 40)
	canvas.add_child(title)
	var action := VBoxContainer.new()
	action.position = Vector2(366, 35)
	action.size = Vector2(170, 54)
	canvas.add_child(action)
	_ad_button(action, "free_gems_banner")
	_ad_buttons["free_gems_banner"]["button"].add_theme_font_size_override("font_size", 23)
	_ad_buttons["free_gems_banner"]["button"].custom_minimum_size.y = 54
	_sections.append({"heading": canvas.get_parent(), "content": canvas, "group": "resources"})


func _pass(icon: String, title: String, description: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_panel(self, "pass").add_child(row)
	row.add_child(_icon(icon, 58))
	var copy := _column(row)
	copy.add_child(_text(title, 15))
	copy.add_child(_text(I18n.t("shop.coming_soon"), 12, MUTED))
	var open := _coming_button("»", title, description)
	HdUi.style_button(open, "menu")
	open.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	open.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	open.custom_minimum_size.x = 44
	open.accessibility_name = I18n.t("shop.view_2") + title
	row.add_child(open)


## Ưu đãi giới hạn: thẻ cam (biến thể "pass") với tiêu đề, mô tả, nút "Sắp có" và icon lớn bên phải.
func _banner(id: String, title: String, description: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_panel(self, "pass").add_child(row)
	var copy := _column(row)
	copy.add_child(_text(title, 16))
	copy.add_child(_text(description, 11, MUTED))
	var button := _coming_button(I18n.t("shop.coming_soon"), title, description)
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
	var status := _text(I18n.t("shop.coming_soon"), 11, MUTED)
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


## Dựng lại bốn thẻ gói (2 tay đua + 2 phụ kiện) khi coupon/gem/bảo đảm/khóa tính năng đổi.
func update_packs() -> void:
	if _pack_box == null:
		return
	var parts: Array = [GameState.gems, GameState.gear_coupons.duplicate(), GameState.driver_coupons.duplicate(),
		GameState.driver_pity.duplicate(), GameState.save_blocked, GameState.phase == "save_error",
		GameState.feature_unlocked("U3_bag"), GameState.feature_unlocked("U5_drivers")]
	var sig := str(parts)
	if sig == _pack_sig and _pack_box.get_child_count() > 0:
		return
	_pack_sig = sig
	for c in _pack_box.get_children():
		_pack_box.remove_child(c)
		c.queue_free()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_pack_box.add_child(grid)
	for pack: Dictionary in GameData.driver_packs():
		_pack_card(grid, "driver", pack)
	for pack: Dictionary in GameData.gear_packs():
		_pack_card(grid, "gear", pack)


func _pack_card(parent: Node, kind: String, pack: Dictionary) -> void:
	var id := String(pack["id"])
	var column := _column(_panel(parent))
	var title := _text(String(pack["name"]), 13)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var icon_id := ("standard_driver_pack" if id == "pro" else "elite_driver_pack") if kind == "driver" else id + "_gear_pack"
	var art := ExpansionArt.icon(icon_id, Vector2(0, 64))
	column.add_child(art)
	var coupons: Dictionary = GameState.driver_coupons if kind == "driver" else GameState.gear_coupons
	var coupon_kind := String(pack["coupon"])
	var coupon := _text("Coupon: %d" % int(coupons.get(coupon_kind, 0)), 12, MUTED)
	coupon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(coupon)
	var info := _button("i")
	info.name = "ShopPackInfo_%s_%s" % [kind, id]
	info.custom_minimum_size.y = 30
	info.add_theme_font_size_override("font_size", 12)
	ShopSkin.style_button(info, "tab")
	info.pressed.connect(func() -> void: pack_info_requested.emit(kind, id))
	column.add_child(info)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	column.add_child(actions)
	for n in [1, 10]:
		var pay: Dictionary = GameState.driver_payment(id, n) if kind == "driver" else GameState.gear_payment(id, n)
		var affordable: bool = GameState.driver_can_afford(id, n) if kind == "driver" else GameState.gear_can_afford(id, n)
		var cost := "—"
		if not pay.is_empty():
			cost = ("%d coupon" if pay["method"] == "coupon" else "%d gem") % int(pay["amount"])
		var b := _button("×%d
%s" % [n, cost])
		b.name = "ShopOpen_%s_%s_x%d" % [kind, id, n]
		b.custom_minimum_size.y = 52
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = not affordable
		b.pressed.connect(func() -> void: pack_open_requested.emit(kind, id, n))
		actions.add_child(b)


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
	column.add_child(_coming_button("$0.99", title, I18n.t("shop.pack_includes_2_tickets_50")))
	column.add_child(_text(I18n.t("shop.coming_soon"), 11, MUTED))


func _free_card(parent: Node, icon: String, title: String, placement: String) -> void:
	var column := _column(_panel(parent))
	column.add_child(_text(title, 13))
	column.add_child(_icon(icon, 70))
	_ad_button(column, placement)


## Thẻ đầu tiên của mục GEM: gem miễn phí mỗi ngày (xem video).
func _free_gem_card(parent: Node) -> void:
	var canvas := _reference_canvas(parent, Vector2(175, 180))
	var art := ShopSkin.picture("gem_cluster", Vector2.ZERO)
	art.name = "GemArt_free"
	art.position = Vector2(16, 25)
	art.size = Vector2(143, 80)
	canvas.add_child(art)
	var amount := _text("5", 30, Color.WHITE)
	amount.position = Vector2(0, 99)
	amount.size = Vector2(175, 36)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.add_theme_font_override("font", preload("res://assets/clean_modern/fonts/Roboto-Bold.ttf"))
	amount.add_theme_color_override("font_outline_color", Color("091326"))
	amount.add_theme_constant_override("outline_size", 4)
	canvas.add_child(amount)
	var action := VBoxContainer.new()
	action.position = Vector2(11, 133)
	action.size = Vector2(153, 44)
	canvas.add_child(action)
	_ad_button(action, "free_gems")
	_ad_buttons["free_gems"]["button"].add_theme_font_size_override("font_size", 23)


func _ad_button(column: VBoxContainer, placement: String) -> void:
	var button := _button("")
	button.name = "Ad_" + placement
	button.add_theme_font_size_override("font_size", 13)
	ShopSkin.style_button(button, "action")
	button.pressed.connect(func() -> void: ad_requested.emit("free_gems" if placement == "free_gems_banner" else placement))
	column.add_child(button)
	var status := _text("", 11, MUTED)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)
	_ad_buttons[placement] = {"button": button, "status": status}


## Vẽ trạng thái các thẻ quảng cáo. view = {placement: {state, left, reward}} (xem Main._ads_view).
func update_ads(view: Dictionary) -> void:
	for pl: String in _ad_buttons:
		var entry: Dictionary = view.get("free_gems" if pl == "free_gems_banner" else pl, {})
		var button: Button = _ad_buttons[pl]["button"]
		var status: Label = _ad_buttons[pl]["status"]
		var reward := String(entry.get("reward", ""))
		var free := bool(entry.get("entitled", false))
		var left := int(entry.get("left", 0))
		button.disabled = true
		status.text = ""
		match String(entry.get("state", "none")):
			"ready":
				button.disabled = false
				button.text = I18n.t("common.claimed") + reward if free else (I18n.t("shop.watch_video") if pl.begins_with("free_gems") else "▶ " + reward)
			"pending":
				button.disabled = false
				button.text = I18n.t("common.try_claiming_again")
				status.text = I18n.t("shop.watched_but_reward_could_not")
			"loading":
				button.text = I18n.t("common.loading")
			"offline":
				button.text = I18n.t("shop.internet_required")
			"busy":
				button.text = I18n.t("shop.watching")
			"cooldown":
				button.text = I18n.t("shop.left") % [left / 3600, (left / 60) % 60, left % 60]
				status.text = reward
			"capped":
				button.text = I18n.t("shop.claim_again_tomorrow")
				status.text = reward
			"locked":
				button.text = I18n.t("shop.locked")
			"save":
				button.text = I18n.t("shop.waiting_save")
			_:
				button.text = I18n.t("shop.none_yet")
		status.visible = not status.text.is_empty()


func _currency_card(parent: Node, icon: String, amount: String, price: String, category: String) -> void:
	var canvas := _reference_canvas(parent, Vector2(175, 170))
	var art := ShopSkin.picture(icon, Vector2.ZERO)
	art.position = Vector2(30, 20)
	art.size = Vector2(115, 60)
	canvas.add_child(art)
	var count := _text(amount.replace(".", ","), 31, ShopSkin.INK)
	count.position = Vector2(0, 75)
	count.size = Vector2(175, 37)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(count)
	var ribbon := ShopSkin.region_picture(Rect2(625, 987, 95, 49))
	ribbon.position = Vector2(0, -7)
	ribbon.size = Vector2(95, 49)
	canvas.add_child(ribbon)
	var button := _coming_button(price, amount + " " + category, I18n.t("shop.coming_soon_exchange_gems_cash"))
	ShopSkin.style_button(button, "action")
	button.icon = ShopSkin.picture("gem_single", Vector2.ZERO).texture
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 34)
	button.add_theme_constant_override("h_separation", 8)
	button.position = Vector2(11, 113)
	button.size = Vector2(153, 46)
	button.add_theme_font_size_override("font_size", 30)
	canvas.add_child(button)


func _gem_card(parent: Node, sku: String, amount: int, price: String) -> void:
	var index := int(sku.right(1)) - 1
	var canvas := _reference_canvas(parent, Vector2(175, 180))
	var status := _text("", 16, Color.WHITE)
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.position = Vector2(0, -5)
	status.size = Vector2(126, 32)
	status.add_theme_stylebox_override("normal", ShopSkin.surface("action", 1))
	canvas.add_child(status)
	# Use complete transparent source sprites, not rectangles from the demo UI.
	var art := ShopSkin.picture(["gem_single", "gem_cluster", "gem_bag", "gem_chest", "gem_vault"][index], Vector2.ZERO)
	art.name = "GemArt_" + sku
	art.position = Vector2(16, 25)
	art.size = Vector2(143, 80)
	canvas.add_child(art)
	var count := _text("%d.%03d" % [amount / 1000, amount % 1000] if amount >= 1000 else str(amount), 30, Color.WHITE)
	count.position = Vector2(0, 99)
	count.size = Vector2(175, 36)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_font_override("font", preload("res://assets/clean_modern/fonts/Roboto-Bold.ttf"))
	count.add_theme_color_override("font_outline_color", Color("091326"))
	count.add_theme_constant_override("outline_size", 5)
	canvas.add_child(count)
	var button := _button(price)
	button.name = "Iap_" + sku
	button.position = Vector2(11, 133)
	button.size = Vector2(153, 44)
	button.pressed.connect(func() -> void: iap_requested.emit(sku))
	canvas.add_child(button)
	_iap_buttons[sku] = {"button": button, "status": status, "reference": true}


func _resource_art(parent: Control, id: String, amount: String) -> void:
	var frame := Control.new()
	frame.custom_minimum_size.y = 62
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	var art := ShopSkin.picture(id, Vector2.ZERO)
	frame.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_bottom = -8
	var count := _text(amount, 22, Color.WHITE)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_font_override("font", preload("res://assets/clean_modern/fonts/Roboto-Bold.ttf"))
	count.add_theme_color_override("font_outline_color", Color("0b1738"))
	count.add_theme_constant_override("outline_size", 4)
	frame.add_child(count)
	count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	count.offset_top = -27


func update_iap(view: Dictionary) -> void:
	_last_iap_view = view
	var items: Dictionary = view.get("items", {})
	var busy := bool(view.get("busy", false))
	for sku: String in _iap_buttons:
		var entry: Dictionary = items.get(sku, {})
		var button: Button = _iap_buttons[sku]["button"]
		var status: Label = _iap_buttons[sku]["status"]
		var reason := String(entry.get("reason", "none"))
		button.text = I18n.t("shop.processing") if busy else String(entry.get("price", ""))
		ShopSkin.price_text(button, 29 if bool(_iap_buttons[sku].get("reference", false)) else 18)
		button.disabled = busy or reason != ""
		status.text = I18n.t("shop.first_time_x_2") if bool(entry.get("first_bonus", false)) and reason == "" else _reason_text(reason)
		status.visible = not status.text.is_empty()
		if reason not in ["save", "busy"]:
			_eligibility[sku] = reason
		if _offer_cards.has(sku):
			var owned := bool(entry.get("driver_owned", false))
			if owned != bool(_iap_buttons[sku].get("owned", false)):
				_render_rewards(_iap_buttons[sku]["rewards"], GameData.iap_product(sku), bool(_iap_buttons[sku]["full"]), owned)
				_iap_buttons[sku]["owned"] = owned
	if is_instance_valid(_restore_button):
		_restore_button.visible = bool(view.get("restorable", false))
		_restore_button.disabled = busy
	_sync_sections()
	_refresh_detail()


static func _reason_text(reason: String) -> String:
	match reason:
		"owned":
			return I18n.t("common.owned_2")
		"once", "hidden":
			return I18n.t("shop.purchased")
		"daily":
			return I18n.t("shop.reopens_tomorrow")
		"weekly":
			return I18n.t("shop.reopens_next_week")
		"save":
			return I18n.t("shop.waiting_save")
		"pass_left":
			return I18n.t("shop.pass_still_active")
		"busy":
			return I18n.t("shop.processing")
	return ""


func _adapt_grids() -> void:
	var factor := size.x / 550.0
	add_theme_constant_override("separation", roundi(12 * factor))
	for entry: Dictionary in _sections:
		var heading = entry["heading"]
		if heading is Label:
			heading.custom_minimum_size.y = 44 * factor
			heading.add_theme_font_size_override("font_size", roundi(30 * factor))
		var grid = entry["content"]
		if grid is GridContainer:
			grid.add_theme_constant_override("h_separation", roundi(12 * factor))
			grid.add_theme_constant_override("v_separation", roundi(12 * factor))
	for grid in [_gem_grid, _cash_grid]:
		if is_instance_valid(grid):
			grid.columns = 3
	for sku: String in _iap_buttons:
		var button: Button = _iap_buttons[sku]["button"]
		ShopSkin.price_text(button, 29 if bool(_iap_buttons[sku].get("reference", false)) else 18)
		var portrait = _iap_buttons[sku].get("portrait")
		if is_instance_valid(portrait):
			portrait.custom_minimum_size.x = 66 if size.x < 335 else 82


func update_daily(amount: String, gems: int, available: bool, blocked: bool) -> void:
	_daily_description.text = I18n.t("shop.cash_plus_gems_2") % gems
	_daily_button.disabled = not available or blocked
	_daily_button.text = I18n.t("shop.claimed") if not available else (I18n.t("common.saving") if blocked else I18n.t("shop.claim"))
	_daily_status.text = I18n.t("shop.free_refreshes_every_day")


## Dòng thưởng đăng nhập: ẩn khi chưa mở khóa; có thể nhận thì nút "Nhận quà", đã nhận thì "Xem".
func update_login_rewards(unlocked: bool, available: bool, total_days: int, preview: String) -> void:
	_login_row.visible = unlocked
	if not unlocked:
		return
	_login_description.text = (I18n.t("shop.today") + preview) if available else (I18n.tn("shop.claimed_days_come_back_tomorrow", total_days) % total_days)
	_login_button.text = I18n.t("common.claim_reward") if available else "Xem"


func _link(text: String) -> Button:
	var link := Button.new()
	link.text = text
	link.flat = false
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var blank := StyleBoxEmpty.new()
		blank.set_content_margin_all(2)
		link.add_theme_stylebox_override(state, blank)
	link.custom_minimum_size.y = 44
	link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	link.add_theme_font_size_override("font_size", 13)
	link.add_theme_color_override("font_color", Color("2468b7"))
	HdUi.style_button(link, "cancel")
	link.add_theme_color_override("font_color", Color("2468b7"))
	HdUi.text_depth(link)
	return link


static func _has_coupons(p: Dictionary) -> bool:
	var grant: Dictionary = p.get("grant", {})
	return grant.has("driver_coupon") or grant.has("gear_coupon")


func _render_rewards(container: VBoxContainer, product: Dictionary, full: bool, owned: bool) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	if full:
		container.add_child(PackUi.reward_strip(product, owned))
		return
	var sku := String(product["sku"])
	if sku.begins_with("income"):
		var multiplier := "×2" if sku == "income_x2" else ("×2 → ×3" if sku == "income_x3_up" else "×3")
		container.add_child(_text(multiplier, 30, Color("d78d00")))
		return
	if sku == "offline_plus":
		container.add_child(_text(I18n.t("shop.x_3_up_24_hours"), 16, ShopSkin.INK))
		return
	if sku == "pass_month":
		container.add_child(_text(I18n.t("shop.gems_now_gems_day_days") % [int(product["grant"].get("gems", 0)), int(product.get("daily_gems", 0)), int(product.get("days", 0)), str(float(product.get("offline_bonus_sec", 0)) / 3600.0)], 12, ShopSkin.INK))
		return
	if sku == "pass_growth":
		var milestone_gems := 0
		var milestones: Array = product.get("milestones", [])
		for milestone: Array in milestones:
			milestone_gems += int(milestone[1])
		container.add_child(_text(I18n.t("shop.gems_now_gems_over_milestones") % [int(product["grant"].get("gems", 0)), milestone_gems, milestones.size()], 13, ShopSkin.INK))
		return
	var rows := PackUi.rewards(product, owned)
	if sku == "no_ads":
		var gem_row := HBoxContainer.new()
		gem_row.add_child(ShopSkin.picture("gem_single", Vector2(57, 48)))
		gem_row.add_child(_text(str(int(product["grant"].get("gems", 0))), 34, ShopSkin.INK))
		container.add_child(gem_row)
		return
	if String(product.get("kind", "")) == "daily":
		var gem_row := HBoxContainer.new()
		gem_row.add_theme_constant_override("separation", 3)
		gem_row.add_child(ShopSkin.picture("gem_single", Vector2(40, 34)))
		gem_row.add_child(_text(str(int(product["grant"].get("gems", 0))), 27, ShopSkin.INK))
		container.add_child(gem_row)
		return
	if String(product.get("kind", "")) == "character" and not owned:
		rows.pop_front() # Guaranteed driver is already shown in the portrait and title.
	if sku in ["no_ads", "offer_noads_bundle"]:
		rows.pop_front() # The large no-ads illustration carries the permanent benefit.
	var grid := GridContainer.new()
	grid.columns = mini(4, maxi(1, rows.size()))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 3)
	for reward: Dictionary in rows:
		var tile := VBoxContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_constant_override("separation", 0)
		var id := String(reward["icon"])
		var picture: TextureRect
		if id in ["standard_driver_pack", "elite_driver_pack", "standard_gear_pack", "elite_gear_pack"]:
			picture = ShopSkin.demo_picture("driver_coupon" if "driver" in id else ("elite_gear" if id == "elite_gear_pack" else "gear_coupon"), Vector2(52, 48))
		elif id in ["driver_my", "driver_lam"]:
			picture = ShopSkin.demo_picture("shard_my" if id == "driver_my" else "shard_lam", Vector2(52, 48))
		elif id in ["gem", "cash"]:
			picture = ShopSkin.picture("gem_single" if id == "gem" else "cash_small", Vector2(52, 48))
		else:
			picture = PackUi.icon(id, 48)
		picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tile.add_child(picture)
		var value := _text(String(reward["value"]), 22, ShopSkin.INK)
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.clip_text = true
		if bool(reward.get("shards", false)):
			value.add_theme_font_size_override("font_size", 18)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(value)
		grid.add_child(tile)
	container.add_child(grid)


## Cuộn trang Shop tới mục "gem" hoặc "cash". Gọi sau khi tab Shop đã hiện.
func scroll_to_section(kind: String) -> void:
	var target: Control = _pack_heading if kind == "packs" else (_gem_heading if kind == "gem" else _cash_heading)
	var scroll := get_parent().get_parent() as ScrollContainer
	if target == null or scroll == null:
		return
	# Chờ bố cục xong sau khi mở Shop rồi mới đo vị trí.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(target) or not is_instance_valid(scroll):
		return
	var content := get_parent() as Control
	var y := int(target.global_position.y - content.global_position.y) - 8
	var tween := create_tween()
	tween.tween_property(scroll, "scroll_vertical", maxi(y, 0), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _available_card(sku: String) -> bool:
	var reason := String(_eligibility.get(sku, "none"))
	return reason not in HIDDEN_REASONS and reason != "once"


func _sync_sections() -> void:
	if not _available_card(_starter_choice):
		_starter_choice = ""
		for sku: String in _starter_steps:
			if _available_card(sku):
				_starter_choice = sku
				break
	var noads_bundle := _available_card("offer_noads_bundle")
	for sku: String in _offer_cards:
		var show_card := _available_card(sku)
		if _starter_steps.has(sku):
			show_card = show_card and sku == _starter_choice
		if sku == "no_ads" and noads_bundle:
			show_card = false
		(_offer_cards[sku] as Control).visible = show_card
	for sku: String in _starter_steps:
		var step: Button = _starter_steps[sku]
		step.disabled = not _available_card(sku)
		step.set_pressed_no_signal(sku == _starter_choice)
		ShopSkin.style_button(step, "action" if sku == _starter_choice else "tab")
	for entry: Dictionary in _sections:
		var content: Control = entry["content"]
		var has_cards := false
		for card in content.get_children():
			if card.visible:
				has_cards = true
				break
		var show_section := has_cards
		content.visible = show_section
		(entry["heading"] as Control).visible = show_section
		if is_instance_valid(entry.get("steps")):
			(entry["steps"] as Control).visible = false


## Content for Main's existing modal: no second confirmation step before store checkout.
func build_detail(sku: String) -> VBoxContainer:
	var p := GameData.iap_product(sku)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	var subtitle := String(_offer_title(p)[1])
	if sku == "starter_1":
		subtitle = I18n.t("shop.ready_first_race")
	elif String(p.get("kind", "")) == "character":
		var driver := GameData.driver(String(p["grant"]["driver"]))
		subtitle = I18n.t("shop.get_driver_guaranteed") % String(driver.get("name", ""))
	elif sku in ["income_x2", "income_x3", "income_x3_up"]:
		subtitle = I18n.t("shop.online_income_race_rewards")
	var banner := PanelContainer.new()
	var banner_skin := StyleBoxFlat.new()
	banner_skin.bg_color = Color("dfedff")
	banner_skin.border_color = Color("b6d8fb")
	banner_skin.set_border_width_all(1)
	banner_skin.set_corner_radius_all(16)
	banner_skin.content_margin_left = 8
	banner_skin.content_margin_right = 8
	banner_skin.content_margin_top = 6
	banner_skin.content_margin_bottom = 6
	banner.add_theme_stylebox_override("panel", banner_skin)
	var subtitle_label := _text(subtitle, 14, Color("102d60"))
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(subtitle_label)
	column.add_child(banner)
	# Fixed layout height avoids resize/minimum-size feedback inside the modal.
	column.add_child(PackUi.art(sku, clampf((get_viewport_rect().size.x - 64) * 2.0 / 3.0, 168, 232), true))
	var entry: Dictionary = (_last_iap_view.get("items", {}) as Dictionary).get(sku, {})
	if sku in ["income_x2", "income_x3", "income_x3_up"]:
		var benefit := PanelContainer.new()
		benefit.name = "PermanentIncomeBenefit"
		benefit.add_theme_stylebox_override("panel", banner_skin)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(PackUi.icon("cash", 48))
		var multiplier := I18n.t("shop.permanent_doubling") if sku == "income_x2" else I18n.t("shop.permanent_tripling")
		var copy := _text(multiplier, 18, Color("102d60"))
		copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(copy)
		benefit.add_child(row)
		column.add_child(benefit)
	else:
		column.add_child(PackUi.reward_strip(p, bool(entry.get("driver_owned", false))))
	if String(p.get("kind", "")) == "character" and bool(entry.get("driver_owned", false)):
		var conversion := _text(I18n.t("shop.you_already_own_this_driver"), 12, Color("7652aa"))
		conversion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(conversion)
	var note := PackUi.note(p)
	if note != "":
		var note_label := _text(note, 12, Color("476991"))
		note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(note_label)
	_detail_sku = sku
	_detail_buy = _button("")
	_detail_buy.name = "DetailBuy_" + sku
	_detail_buy.custom_minimum_size.y = 48
	_detail_buy.add_theme_font_size_override("font_size", 23)
	_detail_buy.pressed.connect(func() -> void: iap_requested.emit(sku))
	column.add_child(_detail_buy)
	_detail_status = _text("", 12, MUTED)
	column.add_child(_detail_status)
	var footer := HBoxContainer.new()
	var limit := _text(PackUi.limit(p), 13, Color("476991"))
	limit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(limit)
	if _has_coupons(p):
		var odds := _link(I18n.t("shop.view_rates"))
		odds.pressed.connect(func() -> void: odds_requested.emit(sku))
		footer.add_child(odds)
	column.add_child(footer)
	_refresh_detail()
	return column


func _refresh_detail() -> void:
	if not is_instance_valid(_detail_buy):
		return
	var entry: Dictionary = (_last_iap_view.get("items", {}) as Dictionary).get(_detail_sku, {})
	var reason := String(entry.get("reason", "none"))
	var busy := bool(_last_iap_view.get("busy", false))
	_detail_buy.text = I18n.t("shop.processing") if busy else String(entry.get("price", ""))
	_detail_buy.disabled = busy or reason != ""
	_detail_status.text = _reason_text(reason)
	_detail_status.visible = not _detail_status.text.is_empty()
