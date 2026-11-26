extends PanelContainer
## Native offer card matching shop_recolor_v9; no baked text, price or rewards.
signal buy_pressed
const DemoSkin = preload("res://ui/shop_demo_theme.gd")
const RewardItems = preload("res://core/data/reward_items.gd")
const PackUi = preload("res://ui/shop_pack_ui.gd")
const PromoUi = preload("res://ui/pack_promo_ui.gd")
const SKUS := ["income_x2"]
const ROOT := "res://assets/shop_horizontal_v1/"
var price: Button
var title: Label
var sku := ""
var _hero: Control
var _amount: Label
var _labels: Array[Label] = []

func setup(product: Dictionary) -> void:
	build(product, {})

func setup_pack(product: Dictionary, opts: Dictionary) -> void:
	build(product, opts)

func build(product: Dictionary, opts: Dictionary) -> void:
	sku = String(product["sku"])
	name = "Offer_" + sku
	var kind := String(product.get("kind", ""))
	var premium := kind in ["starter", "perk", "offer", "weekly"]
	var income := sku.begins_with("income_")
	var noads := sku in ["no_ads", "offer_noads_bundle"]
	var daily := kind == "daily"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", DemoSkin.card(premium, 6))
	if premium:
		var rays := DemoSkin.picture(DemoSkin.rays(), Vector2.ZERO)
		rays.name = "PremiumRays"
		rays.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(rays)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	add_child(box)
	var title_text := String(opts.get("title", PackUi.title(product)))
	if income: title_text = I18n.t("shop.perk_income_title") % 2
	title = DemoSkin.label(title_text, 18)
	title.name = "Title"
	title.visible = sku != "starter_2"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	_hero = Control.new()
	_hero.name = "OfferArt_" + sku
	_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.custom_minimum_size = Vector2(104, 62 if daily else (76 if income or noads else 110))
	_hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_hero)
	var texture: Texture2D = opts.get("art")
	if kind == "starter":
		texture = load("res://assets/pack_benefit_v2/mechanic.png")
	elif income:
		texture = load("res://assets/pack_benefit_v2/income.png")
	elif noads:
		texture = load("res://assets/pack_benefit_v2/no_ads.png")
	elif daily:
		texture = load("res://assets/shop_demo_v9/daily_gear.png") if sku == "daily_gear" else load(ROOT + "pack_driver_pro.png")
	var art := DemoSkin.picture(texture, Vector2.ZERO)
	_hero.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if kind == "starter":
		art.offset_top = 12
		var gem := DemoSkin.picture(load(ROOT + "gems_275.png"), Vector2.ZERO)
		_hero.add_child(gem)
		gem.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		gem.offset_top = -42; gem.offset_right = 52
	if premium and (income or product.has("value_x")):
		var value := "×2" if income else (str(product["value_x"]).replace(".", I18n.dec()) + "×")
		var badge := PromoUi.badge(value, "", 48)
		badge.name = "ValueBadge"
		_hero.add_child(badge)
		badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -42; badge.offset_right = 6
		badge.offset_top = -2; badge.offset_bottom = 46
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	row.add_child(copy)
	var grant: Dictionary = product.get("grant", {})
	var primary: HBoxContainer
	if income:
		for data in [["income_online", "shop.online_income"], ["race_reward", "shop.race_rewards"]]:
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 4)
			copy.add_child(line)
			line.add_child(DemoSkin.picture(RewardItems.icon(data[0]), Vector2(18, 18)))
			var text := DemoSkin.label(I18n.t(data[1]) + " ×2", 12)
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text.clip_text = true
			text.tooltip_text = text.text
			line.add_child(text)
			_labels.append(text)
	else:
		primary = HBoxContainer.new()
		primary.add_theme_constant_override("separation", 5)
		primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_child(primary)
		var driver_id := String(grant.get("driver", ""))
		if driver_id != "" and kind != "character":
			var portrait := VBoxContainer.new()
			portrait.add_theme_constant_override("separation", 0)
			primary.add_child(portrait)
			portrait.add_child(DemoSkin.picture(ExpansionArt.texture(driver_id), Vector2(28, 28)))
			var driver_name := DemoSkin.label(String(GameData.driver(driver_id).get("name", "")), 11)
			driver_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			portrait.add_child(driver_name)
		if grant.has("gems"):
			primary.add_child(DemoSkin.picture(RewardItems.icon("gem"), Vector2(32, 32)))
			_amount = DemoSkin.label(str(int(grant["gems"])), 32 if not daily else 24)
			_amount.name = "PrimaryAmount"
			_amount.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			primary.add_child(_amount)
			if kind == "starter":
				var caption := DemoSkin.label(RewardItems.item_name("gem"), 14)
				caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				primary.add_child(caption)
		var rewards := primary if daily else HBoxContainer.new()
		rewards.name = "SecondaryRewards"
		rewards.add_theme_constant_override("separation", 4)
		if not daily: copy.add_child(rewards)
		for reward: Dictionary in PackUi.rewards(product):
			var id := String(reward["icon"])
			if id == "gem" or id.begins_with("driver_") or id == "crown": continue
			var entry := HBoxContainer.new()
			entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			entry.add_theme_constant_override("separation", 1)
			rewards.add_child(entry)
			var icon: Texture2D = load(PromoUi.ROOT + String(PromoUi.TICKETS[id])) if PromoUi.TICKETS.has(id) else RewardItems.icon(id)
			if id == "cash": icon = load("res://assets/pack_benefit_v2/cash_clock.png")
			entry.add_child(DemoSkin.picture(icon, Vector2(24, 24)))
			var text := DemoSkin.label(String(reward["value"]), 13)
			text.tooltip_text = String(reward["label"])
			text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			entry.add_child(text)
			_labels.append(text)

	var space := Control.new()
	space.custom_minimum_size.y = 1
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(space)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 4)
	copy.add_child(footer)
	if income or noads or daily:
		var chip := PanelContainer.new()
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var surface := DemoSkin.Soft.flat(Color("e4f3f1") if not daily else Color("ddedae"), 2, 9)
		surface.border_color = DemoSkin.GOLD if premium else Color("ddedae")
		chip.add_theme_stylebox_override("panel", surface)
		var note := DemoSkin.label(I18n.t("shop.permanent") if not daily else PackUi.limit(product), 10)
		note.name = "LimitLabel"
		chip.add_child(note)
		if noads:
			primary.add_child(chip)
		else:
			footer.add_child(chip)
	if noads:
		var benefit := DemoSkin.label(I18n.t("shop.remove_ads_2"), 11)
		benefit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		benefit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		benefit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		footer.add_child(benefit)
	var push := Control.new()
	push.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	push.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(push)
	price = Button.new()
	price.name = "Iap_" + sku
	price.text = String(product.get("price_fallback", ""))
	price.custom_minimum_size = Vector2(112, 44)
	price.pressed.connect(buy_pressed.emit)
	DemoSkin.action(price)
	footer.add_child(price)
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_adapt)
	_adapt()

func _adapt() -> void:
	if _hero == null: return
	_hero.custom_minimum_size.x = clampf(size.x * 0.29, 72, 110)
	var small := size.x > 0 and size.x < 335
	if _amount != null:
		_amount.add_theme_font_size_override("font_size", (22 if small else 24) if sku.begins_with("daily_") or sku in ["no_ads", "offer_noads_bundle"] else (24 if small else 28))
	for text: Label in _labels:
		text.add_theme_font_size_override("font_size", 10 if small else 12)
	price.custom_minimum_size.x = 92 if small else 112
	_fit_price()

func _fit_price() -> void:
	if price == null: return
	var font := price.get_theme_font("font")
	var points := 20
	while points > 12 and font.get_string_size(price.text, HORIZONTAL_ALIGNMENT_LEFT, -1, points).x > price.size.x - 12:
		points -= 1
	price.add_theme_font_size_override("font_size", points)

func update_price(value: String, busy: bool, reason: String) -> void:
	price.text = I18n.t("shop.processing") if busy else (I18n.t("common.owned_2") if reason == "owned" else value)
	price.disabled = busy or reason != ""
	_fit_price()

