extends RefCounted
## Shop layout with the game's Soft Miniature ivory, blue and orange palette.
const Soft = preload("res://ui/soft_miniature.gd")
const ButtonSkin = preload("res://ui/button_skin.gd")
const BG := Color("fff8ee")
const FACE := HdUi.C_PANEL
const INK := Soft.INK
const GOLD := Color("d6b76c")
const BLUE := HdUi.C_BLUE
static var _rays: Texture2D

static func card(premium: bool = false, padding: float = 8.0) -> StyleBoxFlat:
	var skin := Soft.flat(Color("fff8ec") if premium else FACE, padding, 16)
	skin.border_color = GOLD if premium else Color("d6c8b5")
	skin.set_border_width_all(2 if premium else 1)
	skin.shadow_color = Color("584d3a26")
	skin.shadow_size = 2
	skin.shadow_offset = Vector2(0, 2)
	return skin

static func label(value: String, point_size: int = 16) -> Label:
	var text := Label.new()
	text.text = value
	text.add_theme_font_override("font", HdUi.font())
	text.add_theme_font_size_override("font_size", point_size)
	text.add_theme_color_override("font_color", INK)
	text.add_theme_constant_override("outline_size", 0)
	text.add_theme_constant_override("shadow_offset_x", 0)
	text.add_theme_constant_override("shadow_offset_y", 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return text

static func picture(texture: Texture2D, extent: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = extent
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

static func action(button: Button, kind: String = "buy", font_size: int = 20) -> void:
	button.set_meta("shop_demo_action", kind)
	button.add_theme_font_override("font", HdUi.font())
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_constant_override("outline_size", 0)
	button.set_meta("price_outline_color", Color.TRANSPARENT)
	button.clip_text = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size.y = maxf(44, button.custom_minimum_size.y)
	var secondary := kind in ["ad", "outline"]
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var disabled: bool = state == "disabled"
		var pressed: bool = state in ["pressed", "hover_pressed"]
		var top := Color("ff9a2e")
		var bottom := Color("ff831e")
		var edge := Color("d5570e")
		if kind == "free":
			top = Color("80ed37"); bottom = Color("39bb10"); edge = Color("30900e")
		elif secondary:
			top = Color("e0f7ff"); bottom = Color("b3e4f7"); edge = Color("95d1ed")
		if disabled:
			top = Color("c4c5cd"); bottom = Color("989ca7"); edge = Color("7c828c")
		elif pressed:
			top = top.darkened(0.1); bottom = bottom.darkened(0.1)
		elif state == "hover":
			top = top.lightened(0.1)
		var skin: StyleBox
		if kind == "outline":
			skin = Soft.flat(FACE, 6, 14)
			skin.border_color = edge
			skin.set_border_width_all(1)
		else:
			skin = ButtonSkin.palette(top, bottom, edge)
			skin.content_margin_left = 6
			skin.content_margin_right = 6
		button.add_theme_stylebox_override(state, skin)
		var font_color := HdUi.C_MUTED if disabled else (INK if secondary else Color.WHITE)
		button.add_theme_color_override("font_color" if state == "normal" else "font_" + state + "_color", font_color)
	var focus := Soft.flat(Color.TRANSPARENT, 0, 14)
	focus.border_color = Color("145b95")
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_focus_color", INK if secondary else Color.WHITE)
	ButtonSkin.apply(button)

static func rays() -> Texture2D:
	if _rays != null: return _rays
	var paths := ""
	for i in 12:
		var a := i * TAU / 12.0
		var b := a + 0.2
		paths += '<path d="M76 100L%.1f %.1fL%.1f %.1fZ"/>' % [76 + cos(a)*450, 100 + sin(a)*450, 76 + cos(b)*450, 100 + sin(b)*450]
	var image := Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="366" height="154"><defs><clipPath id="c"><rect width="366" height="154" rx="16"/></clipPath><radialGradient id="g" cx=".2" cy=".65" r=".65"><stop stop-color="#fff3cd" stop-opacity=".35"/><stop offset="1" stop-color="#fff3cd" stop-opacity="0"/></radialGradient></defs><g clip-path="url(#c)"><rect width="366" height="154" fill="url(#g)"/><g fill="#fff8e4" opacity=".16">%s</g></g></svg>' % paths, 2.0)
	_rays = ImageTexture.create_from_image(image)
	return _rays
