extends SceneTree
## Run with -- --economy-test to isolate saves while capturing the live Shop.

func _initialize() -> void:
	call_deferred("capture")


func settle() -> void:
	for i in 12:
		await process_frame


func capture() -> void:
	if not "--economy-test" in OS.get_cmdline_user_args():
		push_error("Preview requires -- --economy-test to isolate saves")
		quit(1)
		return
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.tutorial["gated"] = false
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main := load("res://ui/main.gd").new() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._select_tab(main.Tab.SHOP)
	await settle()
	var shop: Control = main._shop_content
	var scroll: ScrollContainer = main._shop_box.get_parent()
	for lang in ["en", "vi"]:
		I18n.set_lang(lang)
		main._rebuild_shop()
		await settle()
		shop = main._shop_content
		var ads := {}
		for placement in ["free_gems", "free_gear_coupon", "free_driver_coupon"]:
			ads[placement] = {"state": "ready", "entitled": false, "reward": "+5", "left": 0}
		shop.update_ads(ads)
		shop.update_daily("", 5, true, false)
		for width in [320, 390, 412]:
			root.size = Vector2i(width, 844)
			await settle()
			scroll.scroll_vertical = 0
			await settle()
			for card in shop.get_node("FreeGrid").get_children():
				assert(card.get_global_rect().end.x <= scroll.get_global_rect().end.x + 1, "Free gift card overflow")
				assert(card.get_global_rect().encloses(card.action.get_global_rect()), "Free gift action overflow")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://output/free_gifts_%s_%d.png" % [lang, width])
		# The featured gem card reuses its action for videos after the free claim.
		shop.update_daily("", 5, false, false)
		await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/free_gifts_%s_video.png" % lang)
		ads["free_gems"] = {"state": "cooldown", "left": 3723}
		ads["free_gear_coupon"] = {"state": "capped"}
		ads["free_driver_coupon"] = {"state": "offline"}
		shop.update_ads(ads)
		shop.update_daily("", 5, false, false)
		await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/free_gifts_%s_states.png" % lang)
	print("FREE_GIFTS_PREVIEW: captured EN/VI at 320, 390, 412px; card and action bounds OK")
	main.queue_free()
	await settle()
	quit()
