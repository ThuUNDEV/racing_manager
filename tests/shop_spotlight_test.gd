extends SceneTree
## Native visual QA: -- --shop-spotlight-shots. Saves are isolated by the tests/ path.
var failures := 0
var purchases: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
	print("OK " if ok else "FAIL ", message)

func settle() -> void:
	for i in 10:
		await process_frame

func shot(path: String) -> void:
	if "--shop-fixed-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/" + path + ".png")


func check_offer(shop: Control, sku: String, lang: String, width: int) -> void:
	var card: Control = shop._offer_cards[sku]
	var buy: Button = shop._iap_buttons[sku]["button"]
	var rewards: Control = shop._iap_buttons[sku]["rewards"]
	var info: Button = card.find_child("Detail_" + sku, true, false)
	var title: Label = card.find_child("PackTitle", true, false)
	var bounds := card.get_global_rect()
	check(card.scale == Vector2.ONE, "UnitScale keeps card transform at one: " + sku)
	check(bounds.encloses(buy.get_global_rect()) and buy.size.y >= 44, "buy target fits %s %s %d" % [sku, lang, width])
	check(bounds.encloses(info.get_global_rect()) and info.size.x >= 44 and info.size.y >= 44, "info touch target fits: " + sku)
	check(not title.get_global_rect().intersects(info.get_global_rect()), "title clears info target: " + sku)
	check(buy.text == root.get_node("Iap").price(sku), "live price " + sku)
	check(rewards.get_global_rect().end.y <= buy.global_position.y, "rewards clear purchase: " + sku + " " + str(rewards.get_global_rect()) + " buy " + str(buy.get_global_rect()))
	var reward_grid := rewards.get_child(0) as GridContainer
	if reward_grid != null:
		check(reward_grid.get_child_count() == shop._offer_rewards(GameData.iap_product(sku), bool(shop._iap_buttons[sku]["owned"])).size(), "all catalog rewards shown: " + sku)
		for tile: Control in reward_grid.get_children():
			check(tile.get_child(0) is TextureRect and (tile.get_child(0) as TextureRect).texture != null, "reward has icon: " + sku)
			check(bounds.encloses(tile.get_global_rect()) and not tile.get_global_rect().intersects(buy.get_global_rect()), "reward tile remains inside card and above buy: " + sku)
			for label: Label in tile.find_children("*", "Label", true, false):
				check(label.get_line_count() <= label.get_visible_line_count(), "complete reward value: " + label.text)
	var pitch: Label = card.find_child("OfferPitch", true, false)
	check(not pitch.get_global_rect().intersects(info.get_global_rect()), "pitch clears info target: " + sku)
	check(pitch.get_line_count() <= pitch.get_visible_line_count(), "complete localized pitch: " + sku)


func run() -> void:
	var state := root.get_node("GameState")
	check(state.SAVE_PATH.contains("/tests/"), "save is isolated")
	GameData.reload()
	state.init_new_game()
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.business_tier = 4
	state.unlocked_tier = 4
	state.owned_cars["car_titan_tia_chop"] = true
	state.car_levels["car_titan_tia_chop"] = {"engine": 0, "tyre": 0, "chassis": 0, "gearbox": 0}
	state.active_car_id = "car_titan_tia_chop"
	state.completed_races = 30
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var previous_lang := I18n.lang()
	for lang in ["en", "vi"]:
		I18n.set_lang(lang)
		GameData.reload()
		var main = load("res://ui/main.gd").new()
		root.add_child(main)
		main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await settle()
		state.active = false
		main._select_tab(main.Tab.SHOP)
		main._rebuild_shop()
		await settle()
		var shop = main._shop_content
		var heading: Label = main._shop_shell.header.find_child("ShopTitle", true, false).get_child(1)
		check(heading.text == I18n.t("shop.shop") and heading.is_visible_in_tree(), "Shop title is localized: " + lang)
		var scroll: ScrollContainer = main._shop_box.get_parent()
		for width in [320, 390, 412]:
			root.size = Vector2i(width, 844)
			scroll.scroll_vertical = 0
			await settle()
			check(shop.size.x <= scroll.size.x + 1, "page fits %s %d" % [lang, width])
			for sku: String in shop._offer_cards:
				if shop._offer_cards[sku].is_visible_in_tree():
					check_offer(shop, sku, lang, width)
			var hero: Control = shop._offer_cards["starter_1"]
			check(hero.size.y > shop._offer_cards["income_x2"].size.y, "starter has visual priority")
			var prefix := "shop_fixed_%s_%d" % [lang, width]
			await shot(prefix)
			# Traverse every viewport down to the actual end, with overlap for visual QA.
			var offset := 0
			while true:
				scroll.scroll_vertical = offset
				await settle()
				await shot(prefix + "_scroll_%04d" % scroll.scroll_vertical)
				var last := maxi(0, int(scroll.get_v_scroll_bar().max_value - scroll.size.y))
				if scroll.scroll_vertical >= last - 1:
					check(scroll.scroll_vertical > 0, "reached final Shop section %s %d" % [lang, width])
					break
				offset = mini(last, scroll.scroll_vertical + int(scroll.size.y) - 24)
			for sku in ["starter_2", "starter_3"]:
				shop._starter_choice = sku
				shop._sync_sections()
				await settle()
				check_offer(shop, sku, lang, width)
				scroll.scroll_vertical = 0
				await settle()
				await shot(prefix + "_" + sku)
			shop._starter_choice = "starter_1"
			shop._sync_sections()
			scroll.scroll_vertical = 0
			await settle()
		var view: Dictionary = main._iap_view()
		view["busy"] = true
		shop.update_iap(view)
		check(shop._iap_buttons["starter_1"]["button"].disabled, "purchase disabled while busy")
		view["busy"] = false
		view["items"]["starter_1"]["reason"] = "once"
		shop.update_iap(view)
		await settle()
		check(not shop._offer_cards["starter_1"].visible and shop._offer_cards["starter_2"].visible, "purchased starter advances to next offer")
		for connection: Dictionary in shop.iap_requested.get_connections():
			shop.iap_requested.disconnect(connection["callable"])
		shop.iap_requested.connect(func(sku: String) -> void: purchases.append(sku))
		shop._iap_buttons["starter_2"]["button"].pressed.emit()
		check(purchases.back() == "starter_2", "new starter preserves purchase signal")
		shop.update_iap(main._iap_view())
		shop.details_requested.emit("starter_1")
		await settle()
		check(main._overlay.visible and shop._detail_buy.text == root.get_node("Iap").price("starter_1"), "details preserve live purchase price")
		main._overlay.hide()
		main.queue_free()
		await settle()
	I18n.set_lang(previous_lang)
	print("SHOP_SPOTLIGHT_TEST failures=", failures)
	quit(failures)
