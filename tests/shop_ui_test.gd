extends SceneTree
## Use -- --shop-shots to save real Shop screenshots with a window renderer.
var failures := 0

func check(value: bool, message: String) -> void:
	print("  ", "OK " if value else "FAIL ", message)
	if not value:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in range(5):
		await process_frame

func run() -> void:
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main._select_tab(main.Tab.SHOP)
	await settle()
	var shop = main._shop_content
	var scroll: ScrollContainer = main._shop_box.get_parent()
	check(main._shop_box.get_child_count() == 1, "Audio controls removed from Shop")
	var settings_button := main.find_child("SettingsButton", true, false) as Button
	settings_button.pressed.emit()
	await settle()
	var toggles: Array = main._overlay_box.find_children("*", "CheckButton", true, false)
	check(main._overlay.visible and toggles.size() == 3, "Settings button opens audio and tips controls")
	toggles[0].button_pressed = false
	toggles[1].button_pressed = false
	check(not main._music_on and not main._sfx_on, "Settings controls disable music and sound effects")
	main._overlay.hide()
	settings_button.pressed.emit()
	await settle()
	toggles = main._overlay_box.find_children("*", "CheckButton", true, false)
	check(not toggles[0].button_pressed and not toggles[1].button_pressed, "Audio settings retained when reopened")
	if "--shop-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/settings_audio.png")
	main._overlay.hide()
	check(shop.get_child_count() > 15, "All Shop sections are present")
	check(not shop._daily_button.disabled, "Daily gift initially available")
	state.save_blocked = true
	main._refresh()
	check(shop._daily_button.disabled, "Daily gift disabled while saving is blocked")
	state.save_blocked = false
	main._refresh()
	var gems_before: int = state.gems
	shop._daily_button.pressed.emit()
	await settle()
	check(state.gems == gems_before + int(GameData.economy()["rewards"]["daily_gems"]), "Daily button awards configured gems")
	check(shop._daily_button.disabled, "Claimed daily gift is disabled")
	check(not state.claim_daily(), "Daily gift cannot be claimed twice")
	# Let the one-shot reward effect finish before screenshots/cleanup.
	await create_timer(1.5).timeout
	var coins_before = state.coins.to_save()
	var gems_after: int = state.gems
	shop.offer_requested.emit("PASS THÁNG", "Nhận thưởng mỗi ngày.")
	await settle()
	check(main._overlay.visible, "Upcoming offer opens details")
	check(state.gems == gems_after and state.coins.to_save() == coins_before, "Upcoming offer does not change wallets")
	main._overlay.hide()
	check(shop._gem_grid.get_child_count() == 6, "Free gem card + five real IAP gem packs shown")
	var iap: Node = root.get_node("Iap")
	var mock := MockIapProvider.new()
	mock.tree = self
	iap.provider = mock
	var gem_button := shop.find_child("Iap_gems_pack_2", true, false) as Button
	check(gem_button != null and gem_button.text != "", "Gem pack button shows a price")
	var gems_mock: int = state.gems
	gem_button.pressed.emit()
	await create_timer(0.5).timeout
	await settle()
	check(state.gems == gems_mock + 550, "Real gem pack (first purchase x2) awards its gems")
	check(state.coins.to_save() == coins_before, "Gem pack does not change coins")
	check(mock.finished.size() == 1, "Purchase was finished after saving")
	var again: int = state.gems
	gem_button.pressed.emit()
	await create_timer(0.5).timeout
	await settle()
	check(state.gems == again + 275, "Second purchase has no first-purchase bonus")
	state.save_blocked = true
	var gems_blocked: int = state.gems
	check(not state.grant_iap("gems_pack_1", "blocked-token") and state.gems == gems_blocked, "IAP grant refused while saving is blocked")
	state.save_blocked = false
	check(not state.grant_iap("no_such_sku", "x") and state.gems == gems_blocked, "Unknown SKU rejected")
	check((shop.find_child("RestorePurchases", true, false) as Button).visible, "Restore button visible when the store supports it")
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		check(shop.size.x <= scroll.size.x + 1, "Shop fits viewport %d without horizontal overflow" % width)
		for grid in [shop._gem_grid, shop._cash_grid]:
			for card in grid.get_children():
				check(card.get_global_rect().end.x <= scroll.get_global_rect().end.x + 1, "Currency card fits at %d" % width)
		check(shop._gem_grid.columns == 3, "Demo currency grid keeps three columns at %d" % width)
		if "--shop-shots" in OS.get_cmdline_user_args():
			for section in ["top", "offers", "rewards", "currency"]:
				var position := 0
				var heading := {"offers": "ƯU ĐÃI GIỚI HẠN", "rewards": "TRANG BỊ & TAY ĐUA", "currency": "GEM"}
				for child in shop.get_children():
					if child is Label and child.text == heading.get(section, ""):
						position = int(child.position.y)
				scroll.scroll_vertical = position
				await settle()
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://Design/Previews/shop_%d_%s.png" % [width, section])
		scroll.scroll_vertical = 500
		await settle()
		var scroll_before := scroll.scroll_vertical
		main._refresh()
		await settle()
		check(scroll.scroll_vertical == scroll_before, "Refresh preserves scroll at %d" % width)
	state.active = false
	print("SHOP_UI_TEST failures=", failures)
	main.queue_free()
	await process_frame
	quit(failures)
