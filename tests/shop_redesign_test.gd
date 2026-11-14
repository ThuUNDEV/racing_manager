extends SceneTree
## -- --shop-redesign-shots enables native screenshots; the tests/ path isolates saves.
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	print("  ", "OK " if ok else "FAIL ", message)
	if not ok:
		failures += 1


func settle() -> void:
	for i in 8:
		await process_frame


func shot(path: String) -> void:
	if "--shop-redesign-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/" + path)


func run() -> void:
	var state := root.get_node("GameState")
	check(state.SAVE_PATH.contains("/tests/"), "save is isolated")
	GameData.reload()
	state.init_new_game()
	state.tutorial["gated"] = false
	# A valid late-game fixture keeps save refreshes from blocking the Shop.
	state.business_tier = 4
	state.unlocked_tier = 4
	state.owned_cars["car_titan_tia_chop"] = true
	state.car_levels["car_titan_tia_chop"] = {"engine": 0, "tyre": 0, "chassis": 0, "gearbox": 0}
	state.active_car_id = "car_titan_tia_chop"
	state.completed_races = 30
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main := load("res://ui/main.gd").new() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	state.active = false
	main._select_tab(main.Tab.SHOP)
	main._rebuild_shop()
	await settle()
	var shop = main._shop_content
	check(shop._offer_cards["starter_1"].visible and not shop._offer_cards["starter_2"].visible, "one Starter card shown")
	(shop._starter_steps["starter_2"] as Button).pressed.emit()
	check(shop._offer_cards["starter_2"].visible and not shop._offer_cards["starter_1"].visible, "Starter step switches eligible pack")
	check(not shop._offer_cards["weekly_xl"].visible, "XL flag respected")
	check(shop._gem_grid.is_visible_in_tree() and shop._offer_cards["char_my"].is_visible_in_tree(), "drivers and resources share one list")
	shop._starter_choice = "starter_1"
	shop._sync_sections()
	var scroll: ScrollContainer = main._shop_box.get_parent()
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		check(shop.size.x <= scroll.size.x + 1, "page width fits %d" % width)
		for sku: String in shop._offer_cards:
			var card: Control = shop._offer_cards[sku]
			if card.is_visible_in_tree():
				check(card.size.x <= scroll.size.x + 1, "offer fits %d: %s" % [width, sku])
				var art := card.find_child("OfferArt_" + sku, true, false) as Control
				if String(GameData.iap_product(sku).get("kind", "")) != "daily":
					check(art != null and art.size.y >= 60, "illustration has a visible layout height")
				var button: Button = shop._iap_buttons[sku]["button"]
				check(button.size.y >= 44 and card.get_global_rect().encloses(button.get_global_rect()), "touch target inside card")
		scroll.scroll_vertical = 0
		await settle()
		await shot("shop_redesign_%d_top.png" % width)
		(shop.find_child("Detail_starter_1", true, false) as Button).pressed.emit()
		await settle()
		check(main._overlay.visible and shop._detail_buy != null, "detail opens")
		check(shop._detail_buy.text == root.get_node("Iap").price("starter_1"), "detail uses store price")
		await shot("shop_redesign_%d_detail.png" % width)
		main._overlay.hide()
		shop.odds_requested.emit("starter_1")
		await settle()
		var text := ""
		for label: Label in main._overlay_box.find_children("*", "Label", true, false):
			text += label.text + "\n"
		check("PRO PACK" in text and "STANDARD GEAR" in text, "both coupon probability tables shown")
		main._overlay.hide()
	var view: Dictionary = main._iap_view()
	view["items"]["char_my"]["driver_owned"] = true
	shop.update_iap(view)
	var summary := ""
	for label: Label in shop._iap_buttons["char_my"]["rewards"].find_children("*", "Label", true, false):
		summary += label.text
	check("70 mảnh" in summary, "owned character reward converts to total shards")
	view["items"]["starter_1"]["reason"] = "once"
	shop.update_iap(view)
	check(not shop._offer_cards["starter_1"].visible and shop._starter_choice == "starter_2", "bought Starter removed, next step selected")
	view["busy"] = true
	shop.update_iap(view)
	check(shop._iap_buttons["starter_2"]["button"].disabled, "global purchase lock applied")
	view["busy"] = false
	shop.update_iap(view)
	root.size = Vector2i(390, 844)
	scroll.ensure_control_visible(shop._offer_cards["char_my"])
	scroll.scroll_vertical = 0
	await settle()
	await shot("shop_redesign_390_drivers.png")
	scroll.ensure_control_visible(shop._offer_cards["income_x2"])
	scroll.scroll_vertical = 0
	await settle()
	await shot("shop_redesign_390_perks.png")
	scroll.ensure_control_visible(shop._gem_grid)
	scroll.scroll_vertical = 0
	await settle()
	await shot("shop_redesign_390_resources.png")
	main.queue_free()
	await settle()
	print("SHOP_REDESIGN_TEST failures=", failures)
	quit(failures)
