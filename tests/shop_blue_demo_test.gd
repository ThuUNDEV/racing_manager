extends SceneTree
## Shop-only runtime/visual validation; tests/ keeps the real player save isolated.
var failures := 0
var requested := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	print("OK " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func settle() -> void:
	for i in 10:
		await process_frame

func touch(at: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = down
	Input.parse_input_event(event)

func swipe(at: Vector2) -> void:
	touch(at, true)
	await process_frame
	for i in 8:
		var event := InputEventScreenDrag.new()
		event.index = 0
		event.position = at + Vector2(0, -12 * (i + 1))
		event.relative = Vector2(0, -12)
		event.velocity = Vector2(0, -240)
		Input.parse_input_event(event)
		await process_frame
	touch(at + Vector2(0, -96), false)
	await settle()

func shot(id: String) -> void:
	if "--shop-blue-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/shop_blue_%d_%s.png" % [root.size.x, id])

func run() -> void:
	var state := root.get_node("GameState")
	check(state.SAVE_PATH.contains("/tests/"), "save isolated")
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
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	state.active = false
	main._select_tab(main.Tab.SHOP)
	main._rebuild_shop()
	await settle()
	var shop = main._shop_content
	shop.iap_requested.connect(func(_sku: String) -> void: requested += 1)
	var scroll: ScrollContainer = main._shop_box.get_parent()
	for i in 5:
		var art: TextureRect = shop.find_child("GemArt_gems_pack_%d" % (i + 1), true, false)
		var atlas := art.texture as AtlasTexture
		check(atlas != null and atlas.atlas.resource_path == "res://assets/shop_blue_white/items.png" and atlas.region.size.x >= 220 and atlas.region.size.y >= 220, "gem icon uses the complete high resolution source %d" % (i + 1))
		var buy: Button = shop._iap_buttons["gems_pack_%d" % (i + 1)]["button"]
		check(art.position.y + art.size.y < buy.position.y, "gem art stays clear of its price button %d" % (i + 1))
	check(main._shop_chrome.get_node("ShopTitle") != null and main.find_child("ShopFilters", true, false) == null, "Shop has a fixed title and no category tabs")
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		scroll.scroll_vertical = 0
		await settle()
		check(shop.size.x <= scroll.size.x + 1, "page fits %d" % width)
		check(not shop._starter_steps["starter_1"].is_visible_in_tree(), "demo has one starter banner without an extra tabs row")
		check(shop._offer_cards["starter_1"].is_visible_in_tree() and shop._gem_grid.is_visible_in_tree() and shop._cash_grid.is_visible_in_tree(), "offers and currencies share one visible list")
		check(absf(scroll.position.y - width * 155.0 / 600.0) < 1, "removed tabs leave no empty row")
		var chrome_at: Vector2 = main._shop_chrome.global_position
		for sku: String in shop._offer_cards:
			var card: Control = shop._offer_cards[sku]
			if card.is_visible_in_tree():
				check(card.get_global_rect().end.x <= scroll.get_global_rect().end.x + 1, "banner fits %s %d" % [sku, width])
				var buy: Button = shop._iap_buttons[sku]["button"]
				check(buy.size.y >= 44 and card.get_global_rect().encloses(buy.get_global_rect()), "purchase target inside %s" % sku)
		await shot("top")
		var buy: Button = shop._iap_buttons["starter_1"]["button"]
		scroll.ensure_control_visible(buy)
		await settle()
		var before := scroll.scroll_vertical
		await swipe(buy.get_global_rect().get_center())
		check(scroll.scroll_vertical > before + 24, "finger swipe over buy scrolls %d" % width)
		check(requested == 0 and not main._overlay.visible, "swipe does not buy/open %d" % width)
		# Touch the actual info target rather than emitting its signal directly.
		scroll._stop_scroll()
		var info: Button = shop.find_child("Detail_starter_1", true, false)
		scroll.ensure_control_visible(info)
		await settle()
		var info_at := info.get_global_rect().get_center()
		touch(info_at, true)
		await process_frame
		touch(info_at, false)
		await settle()
		check(main._overlay.visible, "short finger tap opens info %d" % width)
		main._overlay.hide()
		scroll.ensure_control_visible(shop._offer_cards["char_my"])
		await settle()
		await shot("drivers")
		scroll.ensure_control_visible(shop.find_child("FreeGemBanner", true, false))
		await settle()
		await shot("resources")
		scroll.ensure_control_visible(shop._gem_grid)
		await settle()
		check(shop._gem_grid.columns == 3 and shop._cash_grid.columns == 3, "three columns %d" % width)
		for card: Control in shop._gem_grid.get_children():
			check(card.get_global_rect().end.x <= scroll.get_global_rect().end.x + 1, "gem card fits %d" % width)
		await shot("gems")
		scroll.ensure_control_visible(shop._cash_grid)
		await settle()
		await shot("cash")
		check(main._shop_chrome.global_position == chrome_at and main._shop_chrome.is_visible_in_tree(), "title stays fixed while scrolling %d" % width)
		shop.details_requested.emit("starter_1")
		await settle()
		check(main._overlay.visible and shop._detail_buy.text == root.get_node("Iap").price("starter_1"), "details preserve live price")
		await shot("detail")
		main._overlay.hide()
	# One actual touch purchase through the existing mock store proves hit routing.
	var iap: Node = root.get_node("Iap")
	var mock := MockIapProvider.new()
	mock.tree = self
	iap.provider = mock
	var gem_buy: Button = shop._iap_buttons["gems_pack_1"]["button"]
	scroll._stop_scroll()
	scroll.ensure_control_visible(gem_buy)
	await settle()
	var before_gems: int = state.gems
	var before_requested := requested
	var first := bool(main._iap_view()["items"]["gems_pack_1"].get("first_bonus", false))
	var buy_at := gem_buy.get_global_rect().get_center()
	touch(buy_at, true)
	await process_frame
	touch(buy_at, false)
	await create_timer(0.5).timeout
	await settle()
	check(requested == before_requested + 1, "one finger tap requests exactly one purchase")
	check(state.gems == before_gems + (100 if first else 50), "touch purchase grants configured first bonus")
	main._select_tab(main.Tab.RACE)
	check(not main._shop_chrome.visible, "Shop title hides on other pages")
	check(main.get_node("HeaderScenery").visible, "other tabs retain their scenery")
	main._select_tab(main.Tab.SHOP)
	check(not main.get_node("HeaderScenery").visible, "Shop has the approved plain blue-white header")
	main.queue_free()
	await process_frame
	print("SHOP_BLUE_DEMO_TEST failures=", failures)
	quit(failures)
