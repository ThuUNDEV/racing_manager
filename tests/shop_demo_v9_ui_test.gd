extends SceneTree
## Actual Shop renders and native interaction/overflow checks for the approved v9.
## Run with isolated XDG_DATA_HOME; --headless checks layout, -- --shop-demo-shots renders.
const Big = preload("res://core/math/big_number.gd")
const OUT := "res://Design/Previews/Shop_Demo_v9"
var failures := 0
var main: Control
var shop: Control
var state: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func settle(frames: int = 12) -> void:
	for i in frames: await process_frame

func view(busy: bool = false) -> Dictionary:
	var items := {}
	for product: Dictionary in GameData.iap_products():
		var sku := String(product["sku"])
		items[sku] = {"reason": "" if sku in ["starter_1", "starter_2", "income_x2", "no_ads", "daily_gear", "daily_driver"] or sku.begins_with("gems_") else "locked", "price": String(product.get("price_fallback", "")), "first_bonus": sku.begins_with("gems_")}
	return {"busy": busy, "restorable": true, "items": items}

func seed_state() -> void:
	state.init_new_game()
	state.active = false
	state.set_process(false)
	state.tutorial = {"gated": false, "state": "done", "step": "", "tips_off": true}
	state.completed_races = 25
	state.coins = Big.from_int(1250000)
	state.gems = 1240

func build() -> void:
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._tutorial.set_process(false)
	main._overlay.hide()
	main._select_tab(main.Tab.SHOP)
	shop = main._shop_content
	shop.update_iap(view())
	shop.update_daily("", 5, true, false)
	var ads := {}
	for key in ["free_gems", "free_gear_coupon", "free_driver_coupon"]:
		ads[key] = {"state": "ready", "left": 5, "reward": ""}
	shop.update_ads(ads)
	await settle()

func capture(width: int, id: String, node: Control = null) -> void:
	var scroll: ScrollContainer = main._shop_box.get_parent()
	scroll.scroll_vertical = 0 if node == null else int(node.global_position.y - main._shop_box.global_position.y)
	await settle()
	if "--shop-demo-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%d_%s.png" % [OUT, width, id])

func run() -> void:
	state = root.get_node("GameState")
	check(OS.get_user_data_dir().begins_with("/tmp"), "Save phải được cô lập")
	GameData.reload()
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	DirAccess.make_dir_recursive_absolute(OUT)
	var geometry := {}
	var languages := ["vi"] if "--shop-demo-shots" in OS.get_cmdline_user_args() or "--shop-demo-interactions" in OS.get_cmdline_user_args() else I18n.codes()
	for language: String in languages:
		I18n.set_lang(language)
		GameData.reload()
		seed_state()
		root.size = Vector2i(390, 845)
		await build()
		for width in [320, 390, 412]:
			root.size = Vector2i(width, roundi(width * 845.0 / 390))
			await settle()
			var scroll: ScrollContainer = main._shop_box.get_parent()
			check(shop.size.x <= scroll.size.x + 1, "%s/%d: trang không tràn ngang" % [language, width])
			for sku: String in shop._offer_cards:
				var card: Control = shop._offer_cards[sku]
				if not card.visible: continue
				var button: Button = shop._iap_buttons[sku]["button"]
				check(button.size.y >= 44 and button.size.x >= 44, "%s/%d/%s: vùng chạm >=44" % [language, width, sku])
				check(card.get_global_rect().grow(1).encloses(button.get_global_rect()), "%s/%d/%s: nút nằm trong thẻ" % [language, width, sku])
				for label: Label in card.find_children("*", "Label", true, false):
					if label.is_visible_in_tree():
						check(label.get_global_rect().end.x <= card.get_global_rect().end.x + 1, "%s/%d/%s: chữ nằm trong thẻ: %s" % [language, width, sku, label.text])
			for grid in [shop._gem_grid, shop._cash_grid]:
				check(grid.columns == 3, "Lưới tiền giữ 3 cột")
				for card: Control in grid.get_children():
					check(card.get_global_rect().end.x <= scroll.get_global_rect().end.x + 1, "%s/%d: lưới không tràn" % [language, width])
			if language == "vi":
				var blocks := {}
				for node: Control in shop.get_children():
					if node.visible:
						blocks[String(node.name)] = [node.position.x, node.position.y, node.size.x, node.size.y]
				for sku: String in shop._offer_cards:
					var card: Control = shop._offer_cards[sku]
					if card.visible:
						blocks["Offer_" + sku] = [card.global_position.x - shop.global_position.x, card.global_position.y - shop.global_position.y, card.size.x, card.size.y]
				geometry[str(width)] = {"shop_width": shop.size.x, "scroll": str(scroll.get_global_rect()), "blocks": blocks}
			await capture(width, "special")
			await capture(width, "daily_packs", shop.get_node("Section_" + I18n.t("data.offers.starter_pack")))
			await capture(width, "currency", shop._gem_heading)
			var before := scroll.scroll_vertical
			shop.update_iap(view())
			await settle()
			check(scroll.scroll_vertical == before, "Đổi giá giữ vị trí cuộn")
		# Live catalog price/busy state, single native purchase signal, detail interaction.
		shop.iap_requested.disconnect(main._buy_iap)
		var requested: Array = []
		shop.iap_requested.connect(func(sku: String) -> void: requested.append(sku))
		var button: Button = shop._iap_buttons["starter_1"]["button"]
		if language == "vi":
			(main._shop_box.get_parent() as ScrollContainer).scroll_vertical = 0
			await settle()
			for down in [true, false]:
				var event := InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.pressed = down
				event.position = button.get_global_rect().get_center()
				root.push_input(event)
				await process_frame
		else:
			button.pressed.emit()
		check(requested == ["starter_1"], "Bấm mua phát đúng một SKU")
		if language == "vi":
			check(not main._overlay.visible, "Bấm mua không đồng thời mở chi tiết")
			main._close_overlay()
			var card: Control = shop._offer_cards["starter_1"].get_child(0)
			var motion := InputEventMouseMotion.new()
			motion.position = card.global_position + Vector2(16, 16)
			root.push_input(motion)
			await process_frame
			for down in [true, false]:
				var event := InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.pressed = down
				event.position = card.global_position + Vector2(16, 16)
				root.push_input(event)
				await process_frame
			await settle()
			check(not main._overlay.visible, "Bấm phần thân thẻ không mở popup chi tiết")
			check(requested == ["starter_1"], "Bấm phần thân thẻ không phát yêu cầu mua")
			main._close_overlay()
		shop.update_iap(view(true))
		check(button.disabled and button.text == I18n.t("shop.processing"), "Mua đang chờ phải khóa nút")
		shop.update_iap(view())
		var locked := view()
		locked["items"]["starter_1"]["reason"] = "once"
		shop.update_iap(locked)
		check(not shop._offer_cards["starter_1"].visible, "Gói mua một lần vẫn ẩn khi đã mua")
		main.queue_free()
		await settle()
	var geo_file := FileAccess.open(OUT + "/geometry.json", FileAccess.WRITE)
	geo_file.store_string(JSON.stringify(geometry, "  "))
	I18n.set_lang("vi")
	print("SHOP_DEMO_V9_TEST failures=", failures)
	quit(0 if failures == 0 else 1)
