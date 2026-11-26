extends PanelContainer
## Text, rewards and actions stay native; only the card/button skins are raster art.
const ART := "res://assets/free_gifts_v1/"
const DemoSkin = preload("res://ui/shop_demo_theme.gd")
const Soft = preload("res://ui/soft_miniature.gd")
var amount_label: Label
var action: Button


func setup(caption: String, item_id: String, amount: String, kind: String) -> void:
	var daily := kind == "daily"
	name = "FreeGift_" + kind
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size.y = 84 if daily else 54
	add_theme_stylebox_override("panel", DemoSkin.card(false, 7 if daily else 5))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var picture := TextureRect.new()
	picture.name = "RewardIcon"
	# Reward identity stays catalog-driven, including different coupon tiers.
	var icons := {"gem": "icon_gem", "standard_gear_pack": "icon_gear_ticket", "standard_driver_pack": "icon_driver_ticket"}
	picture.texture = load(ART + icons[item_id] + ".png") if icons.has(item_id) else preload("res://core/data/reward_items.gd").icon(item_id)
	picture.custom_minimum_size = Vector2(64 if daily else 40, 64 if daily else 40)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	copy.add_theme_constant_override("separation", 4 if daily else 0)
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
	badge.add_theme_stylebox_override("panel", Soft.flat(Color("f2e8d6"), 2, 10))
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
		label.add_theme_font_size_override("font_size", 16 if daily else 14)
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
	DemoSkin.action(button, "free" if daily else "ad", 20 if daily else 13)
