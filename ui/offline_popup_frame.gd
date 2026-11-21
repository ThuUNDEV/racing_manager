extends VBoxContainer
## The title occupies the first row and overlaps the body by half its height.
## Drawing the body below it keeps the plaque inside the scrollable layout.

static var _faces: Dictionary = {}


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	resized.connect(queue_redraw)


func _draw() -> void:
	var outer := face("39baf5", "0876c8", "0969b3", 26)
	draw_style_box(outer, Rect2(Vector2(0, 22), Vector2(size.x, maxf(0, size.y - 22))))
	var inner := face("fff9ef", "f5e3cc", "e8ceb0", 22)
	draw_style_box(inner, Rect2(Vector2(8, 30), Vector2(size.x - 16, maxf(0, size.y - 38))))


## Separate nine-slice faces keep the concept's bevel and highlights at phone size.
static func face(top: String, bottom: String, edge: String, radius: int = 22, padding: float = 8.0) -> StyleBoxTexture:
	var key := "%s/%s/%s/%d/%s" % [top, bottom, edge, radius, padding]
	if _faces.has(key):
		return _faces[key].duplicate() as StyleBoxTexture
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="180" height="64" viewBox="0 0 180 64"><defs><linearGradient id="g" x1="0%%" y1="0%%" x2="0%%" y2="100%%"><stop stop-color="#%s"/><stop offset=".45" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs><rect x="2" y="5" width="176" height="58" rx="%d" fill="#735138" opacity=".18"/><rect x="2" y="2" width="176" height="58" rx="%d" fill="url(#g)" stroke="#%s" stroke-width="2"/><rect x="4" y="4" width="172" height="53" rx="%d" fill="none" stroke="#fff9e9" stroke-opacity=".8" stroke-width="1.6"/></svg>' % [top, top, bottom, radius, radius, edge, radius - 2]
	var pixels := Image.new()
	pixels.load_svg_from_string(svg, 1.0)
	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(pixels)
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	for side in 4:
		style.set_texture_margin(side, radius + 3)
		style.set_content_margin(side, padding)
	style.texture_margin_top = radius + 3
	style.texture_margin_bottom = radius + 3
	_faces[key] = style
	return style


static func speed_marks() -> TextureRect:
	var pixels := Image.new()
	pixels.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="36" height="30"><path d="M1 25L15 4H23L9 25Z M14 25L28 4H36L22 25Z" fill="#ffbd30" stroke="#ea9313" stroke-width=".7"/></svg>', 2.0)
	var icon := TextureRect.new()
	icon.texture = ImageTexture.create_from_image(pixels)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(23, 26)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon
