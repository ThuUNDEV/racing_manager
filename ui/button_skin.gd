extends RefCounted
## One rounded face for every button palette. Nine-slice caps never stretch horizontally.
const STATES := ["normal", "hover", "pressed", "hover_pressed", "disabled"]
static var _textures: Dictionary = {}
static var _palettes: Dictionary = {}


static func palette(top: Color, bottom: Color, edge: Color, scale: float = 1.0) -> StyleBoxTexture:
	var key := "%s/%s/%s/%.3f" % [top.to_html(), bottom.to_html(), edge.to_html(), scale]
	if not _textures.has(key):
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="216" height="48" viewBox="0 0 216 48"><defs><linearGradient id="face" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs><rect x="1" y="4" width="214" height="43" rx="21.5" fill="#%s"/><rect x="1" y="1" width="214" height="43" rx="21.5" fill="url(#face)" stroke="#%s" stroke-width="1.6"/><path d="M23 3H193" stroke="white" stroke-opacity=".65" stroke-width="1.3" stroke-linecap="round"/></svg>' % [top.to_html(false), bottom.to_html(false), edge.to_html(false), edge.to_html(false)]
		var image := Image.new()
		image.load_svg_from_string(svg, 2.0 * scale)
		image.resize(roundi(216 * scale), roundi(48 * scale), Image.INTERPOLATE_LANCZOS)
		_textures[key] = ImageTexture.create_from_image(image)
	var skin := StyleBoxTexture.new()
	skin.texture = _textures[key]
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		skin.set_texture_margin(side, 22 * scale)
		skin.set_content_margin(side, 10 * scale if side in [SIDE_LEFT, SIDE_RIGHT] else 4 * scale)
	skin.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	skin.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	skin.set_meta("rounded_button", true)
	skin.set_meta("rounded_scale", scale)
	skin.set_meta("rounded_palette", [top, bottom, edge])
	return skin


static func rounded(source: StyleBox, scale: float = 1.0) -> StyleBox:
	if source is StyleBoxEmpty or source.has_meta("rounded_button"):
		return source
	var top: Color
	var bottom: Color
	var edge: Color
	var tint := Color.WHITE
	if source is StyleBoxFlat:
		top = source.bg_color
		if top.a == 0.0:
			return source
		bottom = top
		edge = source.border_color if source.get_border_width(SIDE_BOTTOM) > 0 else top.darkened(0.22)
	elif source is StyleBoxTexture and source.texture != null:
		var texture_key: int = source.texture.get_instance_id()
		if not _palettes.has(texture_key):
			var pixels: Image = source.texture.get_image()
			if pixels.is_compressed():
				pixels.decompress()
			var x := pixels.get_width() / 2
			var first := 0
			var last := pixels.get_height() - 1
			while first < last and pixels.get_pixel(x, first).a < 0.9:
				first += 1
			while last > first and pixels.get_pixel(x, last).a < 0.9:
				last -= 1
			var height := last - first
			_palettes[texture_key] = [pixels.get_pixel(x, first + roundi(height * 0.2)), pixels.get_pixel(x, first + roundi(height * 0.75)), pixels.get_pixel(x, last)]
		var colors: Array = _palettes[texture_key]
		top = colors[0]
		bottom = colors[1]
		edge = colors[2]
		tint = source.modulate_color
	else:
		return source
	var skin := palette(top, bottom, edge, scale)
	skin.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		var padding := source.get_content_margin(side)
		if padding >= 0:
			skin.set_content_margin(side, padding)
	skin.expand_margin_left = source.get("expand_margin_left")
	skin.expand_margin_top = source.get("expand_margin_top")
	skin.expand_margin_right = source.get("expand_margin_right")
	skin.expand_margin_bottom = source.get("expand_margin_bottom")
	return skin


static func apply(button: Button, scale: float = 1.0) -> void:
	for state: String in STATES:
		var source := button.get_theme_stylebox("pressed" if state == "hover_pressed" and not button.has_theme_stylebox_override(state) else state)
		button.add_theme_stylebox_override(state, rounded(source, scale))
	if not button.has_meta("rounded_resize"):
		button.set_meta("rounded_resize", true)
		button.resized.connect(_fit.bind(weakref(button)))
	_fit(weakref(button))


static func _fit(reference: WeakRef) -> void:
	var button := reference.get_ref() as Button
	if button == null or button.size.y <= 0:
		return
	for state: String in STATES:
		if not button.has_theme_stylebox_override(state):
			continue
		var source := button.get_theme_stylebox(state) as StyleBoxTexture
		if source == null or not source.has_meta("rounded_palette"):
			continue
		var height := button.size.y + source.expand_margin_top + source.expand_margin_bottom
		var scale := maxf(0.25, height / 48.0)
		if absf(float(source.get_meta("rounded_scale")) - scale) < 0.005:
			continue
		var colors: Array = source.get_meta("rounded_palette")
		var skin := palette(colors[0], colors[1], colors[2], scale)
		skin.modulate_color = source.modulate_color
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			skin.set_content_margin(side, source.get_content_margin(side))
		skin.expand_margin_left = source.expand_margin_left
		skin.expand_margin_top = source.expand_margin_top
		skin.expand_margin_right = source.expand_margin_right
		skin.expand_margin_bottom = source.expand_margin_bottom
		button.add_theme_stylebox_override(state, skin)
