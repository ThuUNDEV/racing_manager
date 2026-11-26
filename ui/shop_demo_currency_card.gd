extends PanelContainer
signal buy_pressed
const DemoSkin = preload("res://ui/shop_demo_theme.gd")
var art_rect: TextureRect
var amount_label: Label
var price: Button
var bonus: PanelContainer

func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", DemoSkin.card(false, 5))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	add_child(box)
	var badge_space := Control.new()
	badge_space.custom_minimum_size.y = 16
	badge_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(badge_space)
	bonus = PanelContainer.new()
	bonus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge := DemoSkin.Soft.flat(Color("08a7e3"), 1, 7)
	badge.content_margin_left = 5; badge.content_margin_right = 5
	badge.set_border_width_all(0)
	bonus.add_theme_stylebox_override("panel", badge)
	badge_space.add_child(bonus)
	var caption := DemoSkin.label("", 9)
	caption.name = "BonusLabel"
	caption.add_theme_color_override("font_color", Color.WHITE)
	bonus.add_child(caption)
	art_rect = DemoSkin.picture(null, Vector2(0, 64))
	box.add_child(art_rect)
	amount_label = DemoSkin.label("", 21)
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(amount_label)
	price = Button.new()
	price.custom_minimum_size.y = 44
	price.expand_icon = true
	price.add_theme_constant_override("icon_max_width", 20)
	price.add_theme_constant_override("h_separation", 2)
	DemoSkin.action(price, "buy", 16)
	price.pressed.connect(buy_pressed.emit)
	price.resized.connect(func() -> void: preload("res://ui/shop_demo_skin.gd").center_icon(price))
	box.add_child(price)

func setup(art: Texture2D, amount: String, price_text: String, price_icon: Texture2D = null, bonus_text: String = "") -> void:
	art_rect.texture = art
	amount_label.text = amount
	price.text = price_text
	price.icon = price_icon
	(bonus.get_node("BonusLabel") as Label).text = bonus_text
	bonus.visible = not bonus_text.is_empty()
