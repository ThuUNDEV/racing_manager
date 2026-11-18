extends RefCounted
## Separate empty skins, decorative icons, and live labels for the fixed race HUD.
const ROOT := "res://assets/soft_miniature_race_ui_v3/"
static var _textures: Dictionary = {}

static func texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(ROOT + path + ".png")
	return _textures[path]

static func skin(name: String) -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = texture("skins/" + name)
	# Corners stay intact while only the middle stretches.
	var margin := minf(result.texture.get_height() * 0.25, result.texture.get_width() * 0.24)
	result.texture_margin_left = margin
	result.texture_margin_right = margin
	result.texture_margin_top = margin
	result.texture_margin_bottom = margin
	result.set_content_margin_all(0)
	return result

static func image(parent: Node, path: String, rect: Rect2) -> TextureRect:
	var result := TextureRect.new()
	result.texture = texture(path)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	place(result, rect)
	return result

static func place(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size

static func button_skin(button: Button, name: String) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, skin(name))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
