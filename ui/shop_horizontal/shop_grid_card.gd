class_name ShopGridCard
extends PanelContainer

signal buy_pressed

const DESIGN_SIZE := Vector2(276, 316)
const ShopSkin = preload("res://ui/shop_demo_skin.gd")
const NAVY := Color(0.05, 0.14, 0.38, 1)

var art_rect: TextureRect
var amount_label: Label
var price: Button
var bonus: PanelContainer


func _init() -> void:
	theme_type_variation = &"ShopCard"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)

	var art_margin := MarginContainer.new()
	art_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_margin.add_theme_constant_override("margin_top", 16)
	art_margin.add_theme_constant_override("margin_left", 8)
	art_margin.add_theme_constant_override("margin_right", 8)
	box.add_child(art_margin)
	art_rect = TextureRect.new()
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_margin.add_child(art_rect)

	amount_label = Label.new()
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.add_theme_font_size_override("font_size", 46)
	amount_label.add_theme_color_override("font_color", NAVY)
	box.add_child(amount_label)

	var button_margin := MarginContainer.new()
	button_margin.add_theme_constant_override("margin_left", 10)
	button_margin.add_theme_constant_override("margin_right", 10)
	button_margin.add_theme_constant_override("margin_bottom", 12)
	box.add_child(button_margin)
	price = Button.new()
	price.custom_minimum_size = Vector2(0, 72)
	price.expand_icon = true
	price.add_theme_constant_override("icon_max_width", 40)
	ShopSkin.set_kind(price, "gem")
	price.resized.connect(func() -> void: ShopSkin.center_icon(price))
	price.pressed.connect(buy_pressed.emit)
	button_margin.add_child(price)

	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	bonus = PanelContainer.new()
	bonus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bonus.position = Vector2(-4, -2)
	bonus.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.45, 0.82, 1)
	style.set_border_width_all(2)
	style.border_color = Color.WHITE
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	bonus.add_theme_stylebox_override("panel", style)
	var bonus_label := Label.new()
	bonus_label.name = "BonusLabel"
	bonus_label.add_theme_font_size_override("font_size", 20)
	bonus_label.add_theme_color_override("font_color", Color.WHITE)
	bonus.add_child(bonus_label)
	overlay.add_child(bonus)


func setup(art: Texture2D, amount: String, price_text: String, price_icon: Texture2D = null, bonus_text: String = "") -> void:
	art_rect.texture = art
	amount_label.text = amount
	price.text = price_text
	price.icon = price_icon
	(bonus.get_node("BonusLabel") as Label).text = bonus_text
	bonus.visible = bonus_text != ""
