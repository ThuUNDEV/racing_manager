extends PanelContainer
## Text, rewards and actions stay native; only the card/button skins are raster art.
const ART := "res://assets/free_gifts_v1/"
const Soft = preload("res://ui/soft_miniature.gd")
var amount_label: Label
var action: Button


func setup(caption: String, item_id: String, amount: String, kind: String) -> void:
	var daily := kind == "daily"
	name = "FreeGift_" + kind
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size.y = 112 if daily else 88
	var backgrounds := {"daily": "card_daily_gold", "starter": "card_gems_lavender", "perk": "card_gear_mint", "character": "card_driver_blue"}
	add_theme_stylebox_override("panel", load(ART + "styles/" + backgrounds[kind] + ".tres"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var picture := TextureRect.new()
	picture.name = "RewardIcon"
	# Reward identity stays catalog-driven, including different coupon tiers.
	var icons := {"gem": "icon_gem", "standard_gear_pack": "icon_gear_ticket", "standard_driver_pack": "icon_driver_ticket"}
	picture.texture = load(ART + icons[item_id] + ".png") if icons.has(item_id) else preload("res://core/data/reward_items.gd").icon(item_id)
	picture.custom_minimum_size = Vector2(64 if daily else 52, 64 if daily else 52)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	copy.add_theme_constant_override("separation", 4)
	row.add_child(copy)
	var title := Label.new()
	title.name = "GiftTitle"
	title.text = caption
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", HdUi.font())
	title.add_theme_font_size_override("font_size", 15 if daily else 14)
	title.add_theme_color_override("font_color", Color("0d2d50"))
	title.add_theme_constant_override("outline_size", 0)
	copy.add_child(title)
	var badge := PanelContainer.new()
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	badge.add_theme_stylebox_override("panel", load(ART + "styles/quantity_pill.tres"))
	copy.add_child(badge)
	var quantity := HBoxContainer.new()
	quantity.add_theme_constant_override("separation", 2)
	badge.add_child(quantity)
	var times := Label.new()
	times.text = "×"
	amount_label = Label.new()
	amount_label.name = "RewardAmount"
	amount_label.text = amount
	for label in [times, amount_label]:
		label.add_theme_font_override("font", HdUi.font())
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color("0d2d50"))
		label.add_theme_constant_override("outline_size", 0)
		quantity.add_child(label)
	action = Button.new()
	action.custom_minimum_size = Vector2(112, 44)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action.clip_text = true
	action.expand_icon = true
	action.add_theme_font_override("font", HdUi.font())
	action.add_theme_font_size_override("font_size", 14)
	action.add_theme_constant_override("icon_max_width", 16)
	action.add_theme_constant_override("h_separation", 4)
	action.set_meta("icon_edge_padding", 10.0)
	action.resized.connect(func() -> void: preload("res://ui/shop_demo_skin.gd").center_icon(action))
	row.add_child(action)


static func style_action(button: Button, daily: bool) -> void:
	var base := load(ART + "styles/" + ("button_claim_green" if daily else "button_video_blue") + ".tres") as StyleBoxTexture
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var skin := base.duplicate() as StyleBoxTexture
		if state == "hover":
			skin.modulate_color = Color(1.08, 1.08, 1.08)
		elif state in ["pressed", "hover_pressed"]:
			skin.modulate_color = Color("c2d8e8")
		button.add_theme_stylebox_override(state, skin)
	var disabled := Soft.flat(Color("deded9"), 8, 18)
	disabled.content_margin_left = 8
	disabled.content_margin_right = 8
	button.add_theme_stylebox_override("disabled", disabled)
	var focus := Soft.flat(Color.TRANSPARENT, 0, 18)
	focus.border_color = Color("0c4274")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_disabled_color", Color("5b6268"))
