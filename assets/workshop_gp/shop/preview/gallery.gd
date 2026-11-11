extends SceneTree
## Standalone asset QA. No gameplay/autoload dependency.

const BASE = "res://assets/workshop_gp/shop/"
var failures := 0

func label_at(parent: Node, value: String, rect: Rect2, font_size: int = 18) -> void:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_color_override("font_color", Color("332e29"))
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func texture_at(parent: Node, path: String, rect: Rect2) -> void:
	var texture = load(BASE + path)
	if not texture is Texture2D:
		push_error("Invalid texture: " + path)
		failures += 1
		return
	var view := TextureRect.new()
	view.texture = texture
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.position = rect.position
	view.size = rect.size
	parent.add_child(view)

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE + "manifest.json"))
	var canvas := ColorRect.new()
	canvas.color = Color("f3ece2")
	canvas.size = Vector2(1440, 1100)
	root.add_child(canvas)
	label_at(canvas, "WORKSHOP GP / SHOP ASSET PACK", Rect2(28, 12, 1380, 48), 32)
	for i in range(manifest.icons.size()):
		var entry: Dictionary = manifest.icons[i]
		var x := 24 + (i % 8) * 176
		var y := 68 + (i / 8) * 196
		texture_at(canvas, entry.resource, Rect2(x, y, 164, 156))
		label_at(canvas, entry.id, Rect2(x, y + 154, 176, 32), 16)
	texture_at(canvas, "textures/offer_combo.png", Rect2(24, 474, 686, 230))
	texture_at(canvas, "textures/offer_starter.png", Rect2(730, 474, 686, 230))
	label_at(canvas, "COMBO / artwork only", Rect2(24, 706, 680, 30))
	label_at(canvas, "STARTER / artwork only", Rect2(730, 706, 680, 30))
	for i in range(manifest.styles.size()):
		var path: String = manifest.styles[i]
		var style = load(BASE + path)
		if not style is StyleBoxTexture:
			failures += 1
			continue
		var panel := Panel.new()
		panel.add_theme_stylebox_override("panel", style)
		panel.position = Vector2(24 + (i % 4) * 352, 768 + (i / 4) * 132)
		panel.size = Vector2(332, 104)
		canvas.add_child(panel)
		label_at(panel, path.get_file().get_basename(), Rect2(22, 30, 300, 40))
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var output := OS.get_environment("SHOP_PREVIEW_OUTPUT")
		if not output.is_empty():
			var error := root.get_texture().get_image().save_png(output)
			if error != OK:
				failures += 1
	print("SHOP_ASSET_QA failures=", failures, " icons=", manifest.icons.size(), " styles=", manifest.styles.size())
	quit(failures)
