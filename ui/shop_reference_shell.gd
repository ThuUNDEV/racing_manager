extends Control
## Shop chrome uses the supplied 600px reference coordinate system.
const ShopStyle = preload("res://ui/shop_demo_skin.gd")
var main: Control
var shop: Control
var scroll: ScrollContainer
var header: Control
var navigation: Control
var cash: Label
var gems: Label

func picture(region: Rect2, at: Rect2, parent: Control) -> TextureRect:
	var node := ShopStyle.region_picture(region)
	node.position = at.position
	node.size = at.size
	parent.add_child(node)
	return node

func hit(at: Rect2, callback: Callable, parent: Control, title: String) -> Button:
	var b := Button.new()
	b.position = at.position
	b.size = at.size
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func number(at: Rect2, parent: Control) -> Label:
	var l := Label.new()
	l.position = at.position
	l.size = at.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", preload("res://assets/clean_modern/fonts/Roboto-Bold.ttf"))
	l.add_theme_font_size_override("font_size", 27)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color("0a2858"))
	l.add_theme_constant_override("outline_size", 3)
	parent.add_child(l)
	return l

func setup(owner_main: Control, content: Control, viewport: ScrollContainer, chrome: Control) -> void:
	main = owner_main
	shop = content
	scroll = viewport
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_top = 64.0  # chừa chỗ cho top bar thật (avatar, tiền, gem, cài đặt) của main
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background := Panel.new()
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("eff9ff")
	skin.border_color = Color("9dcdf2")
	skin.set_border_width_all(2)
	skin.set_corner_radius_all(22)
	background.add_theme_stylebox_override("panel", skin)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	header = chrome
	header.reparent(self)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	for child in header.get_children(): child.hide()
	header.custom_minimum_size = Vector2.ZERO
	# The shell header has explicit design coordinates, independent of VBox sorting.
	var art := Control.new()
	header.add_child(art)
	art.size = Vector2(600, 61)
	# Thanh tài nguyên dùng chính top bar thật của main (shell chỉ phủ phần bên dưới); chỉ giữ ruy băng tiêu đề.
	picture(Rect2(108, 82, 404, 61), Rect2(108, 0, 404, 61), art)
	scroll.reparent(self)
	move_child(scroll, 1)
	navigation = Control.new()
	navigation.size = Vector2(600, 94)
	add_child(navigation)
	var nav_background := Panel.new()
	var nav_surface := StyleBoxFlat.new()
	nav_surface.bg_color = Color("eff9ff")
	nav_surface.border_color = Color("9dcdf2")
	nav_surface.set_border_width_all(1)
	nav_surface.set_corner_radius_all(22)
	nav_background.add_theme_stylebox_override("panel", nav_surface)
	nav_background.position = Vector2(14, 0)
	nav_background.size = Vector2(575, 89)
	navigation.add_child(nav_background)
	for i in 5:
		var button := Button.new()
		button.name = "ShopNav_%d" % i
		button.position = Vector2(23 + i * 111, 3)
		button.size = Vector2(108, 81)
		button.accessibility_name = I18n.t(main.TAB_NAMES[i])
		HdUi.style_button(button, "race" if i == main.Tab.SHOP else "cancel")
		if i != main.Tab.SHOP:
			for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
				button.add_theme_stylebox_override(state, HdUi.ButtonSkin.palette(Color("f8fcff"), Color("e7f4ff"), Color("b4d6ee"), 81.0 / 48.0))
		HdUi.ButtonSkin.apply(button)
		button.pressed.connect(main._select_tab.bind(i))
		navigation.add_child(button)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture = HdUi.tex("icons/%s.png" % main.TAB_ICONS[i])
		if i == main.Tab.BAG or i == main.Tab.TEAM:
			icon.texture = load("res://assets/clean_modern/icons/nav_bag.svg" if i == main.Tab.BAG else "res://assets/clean_modern/icons/nav_team.svg")
		icon.position = Vector2(30, 5)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2(48, 48)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		var caption := Label.new()
		caption.text = I18n.t(main.TAB_NAMES[i])
		caption.position = Vector2(0, 52)
		caption.size = Vector2(108, 26)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 21)
		caption.add_theme_color_override("font_color", Color.WHITE if i == main.Tab.SHOP else Color("102d60"))
		caption.add_theme_constant_override("outline_size", 0)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(caption)
	resized.connect(layout)
	layout()

func layout() -> void:
	if header == null: return
	var factor := size.x / 600.0
	header.position = Vector2.ZERO
	header.size = Vector2(size.x, 61 * factor)
	var art := header.get_child(header.get_child_count() - 1) as Control
	art.scale = Vector2.ONE * factor
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 29 * factor
	scroll.offset_right = -24 * factor
	scroll.offset_top = 73 * factor
	scroll.offset_bottom = -110 * factor
	navigation.scale = Vector2.ONE * factor
	navigation.position = Vector2(0, size.y - 101 * factor)

