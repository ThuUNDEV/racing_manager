extends SceneTree
## Real theme, shop modal and loading contrast checks with an isolated test save.
const Art = preload("res://ui/clean_modern_art.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
	print("OK " if ok else "FAIL ", message)

func settle() -> void:
	for i in 8:
		await process_frame

func run() -> void:
	var state := root.get_node("GameState")
	check(state.SAVE_PATH.contains("/tests/"), "save is isolated")
	state.init_new_game()
	state.active = false
	state.set_process(false)
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/clean_modern/manifest.json"))
	for entry: Dictionary in manifest["replacements"] + manifest["atlas_resources"]:
		var texture := Art.asset("res://" + entry["source"]) as Texture2D
		check(texture != null and texture.resource_path == "res://" + entry["replacement"], "routes " + String(entry["source"]))
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		for product: Dictionary in root.get_node("Iap").products():
			var sku := String(product["sku"])
			# Reopen every illustration, including composite character scenes.
			for repeat in 2:
				main._show_iap_detail(sku)
				await settle()
				var art := main._overlay_box.find_child("OfferArt_" + sku, true, false) as Control
				check(main._overlay.visible and is_instance_valid(art) and art.size.y >= 144, "detail art %s at %d (%d)" % [sku, width, repeat])
				var panel: Control = main._overlay_box.get_parent().get_parent()
				check(panel.position.x >= 0 and panel.get_global_rect().end.x <= width + 1, "detail fits width")
				check(main._shop_content._detail_buy.text != "", "store price present")
				if repeat == 0 and sku in ["starter_1", "char_my", "income_x2", "char_lam", "pass_growth"] and "--clean-shots" in OS.get_cmdline_user_args():
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://Design/Previews/clean_modern_%s_%d.png" % [sku, width])
				main._overlay.hide()
		# Replace content before the previous deferred measurement has completed.
		main._show_iap_detail("starter_1")
		main._show_iap_odds("starter_1")
		main._show_iap_detail("char_my")
		await settle()
		check(main._overlay_box.find_child("OfferArt_char_my", true, false) != null, "rapid replacement keeps latest detail")
		main._overlay.hide()
	main.queue_free()
	await settle()
	print("CLEAN_MODERN_UI_TEST failures=", failures)
	quit(1 if failures else 0)
