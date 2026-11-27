extends SceneTree
## Icon quảng cáo pack ở dải chặng: hiện/ẩn theo Iap.block_reason, chấm đỏ, bấm mở popup, vùng chạm. --capture ghi ảnh.
const BigNumber = preload("res://core/math/big_number.gd")
const PopupAnim = preload("res://ui/popup_anim.gd")
var failures := 0
var main: Control

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)

func settle() -> void:
	for i in 10:
		await process_frame

func capture(id: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://Design/Previews/pack_promo_strip")
		root.get_texture().get_image().save_png("res://Design/Previews/pack_promo_strip/" + id + ".png")

func shown(kind: String) -> bool:
	return (main._promo_ui[kind]["button"] as Button).visible

func click(button: BaseButton) -> void:
	var pos := button.get_global_rect().get_center()
	var hover := InputEventMouseMotion.new()
	hover.position = pos
	root.push_input(hover, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = pos
		event.global_position = pos
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()

func step(sku: String) -> Button:
	return main._overlay_box.find_child("Step_" + sku, true, false) as Button

func detail_buy(sku: String) -> Button:
	return main._overlay_box.find_child("DetailBuy_" + sku, true, false) as Button

func run() -> void:
	PopupAnim.enabled = false
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tests/pack_promo_strip.json"
	state.BAK_PATH = "user://tests/pack_promo_strip.bak"
	state.TMP_PATH = "user://tests/pack_promo_strip.tmp"
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.set_process(false)
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.coins = BigNumber.from_int(12500)
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)

	check(main._promo_ui.size() == 8, "tám icon pack: starter, offer, weekly, timed, epic, perk, daily, character")
	check(shown("perk") and main._promo_ui["perk"]["sku"] == "income_x2", "perk hiện income_x2 khi chưa sở hữu")
	check(shown("starter") and main._promo_ui["starter"]["sku"] == "starter_1", "starter_1 hiện đầu tiên")
	check(not shown("offer"), "offer_noads_bundle ẩn khi chưa đủ 3 lần Ads Break")
	check((main._promo_ui["starter"]["dot"] as Control).visible, "chấm đỏ hiện khi chưa bấm")
	check((main._promo_ui["perk"]["button"] as Button).get_index() < (main._promo_ui["starter"]["button"] as Button).get_index(), "perk (strip_prio 300) đứng trước starter (0)")
	check(main._strip_row.get_child(0).name == "BoostSlot", "ô tăng tốc luôn đứng đầu")

	state.ad_state["break"] = {"day": int(Time.get_unix_time_from_system() / 86400.0), "today": 3}
	main._refresh_pack_promos()
	check(shown("offer") and main._promo_ui["offer"]["sku"] == "offer_noads_bundle", "offer_noads_bundle hiện khi đủ 3 lần")

	check((main._promo_ui["perk"]["button"] as Button).get_index() < (main._promo_ui["offer"]["button"] as Button).get_index(), "offer vẫn sau perk khi hiện")
	state.iap["owned"].append("income_x2")
	main._refresh_pack_promos()
	check(main._promo_ui["perk"]["sku"] == "income_x3_up", "đã có income_x2 thì perk chuyển sang income_x3_up")
	state.iap["owned"].append("income_x3")
	main._refresh_pack_promos()
	check(main._promo_ui["perk"]["sku"] == "offline_plus", "đã có ×3 (no_ads nhường bundle đang bán) thì perk chuyển sang offline_plus")
	state.iap["owned"].append("offline_plus")
	main._refresh_pack_promos()
	check(not shown("perk"), "đã mua hết tiện ích thì icon perk ẩn")
	for sku in ["income_x2", "income_x3", "no_ads", "offline_plus"]:
		state.iap["owned"].erase(sku)
	main._refresh_pack_promos()

	# Đủ bảy ô: mở bậc 3 để có gói tuần và tay đua.
	state.business_tier = 3
	main._refresh_pack_promos()
	for kind in ["starter", "offer", "weekly", "timed", "perk", "daily", "character"]:
		check(shown(kind), "đủ điều kiện thì hiện icon " + kind)

	for dimensions: Vector2i in [Vector2i(320, 568), Vector2i(390, 778), Vector2i(412, 915)]:
		root.size = dimensions
		main._select_tab(0)
		await settle()
		var strip := main.find_child("ActionStrip", true, false) as Control
		var rects: Array[Rect2] = []
		var buttons: Array = [main._ads_controls._chip]
		buttons.append_array(main._promo_ui.values().map(func(e: Dictionary) -> Button: return e["button"]))
		for button: Button in buttons:
			if not button.is_visible_in_tree():
				continue
			var r := button.get_global_rect()
			# Tám ô trên màn 320 hẹp hơn 44 (đã chốt thu nhỏ thay vì cuộn); chiều cao vẫn giữ đủ.
			check(r.size.x >= 35.0 and r.size.y >= 44.0, "vùng chạm đủ ở %s: %s %s" % [dimensions, button.name, r.size])
			check(strip.get_global_rect().grow(1.0).encloses(r), "nằm trong ActionStrip ở %s: %s" % [dimensions, button.name])
			for other in rects:
				check(not other.intersects(r), "các ô không chồng nhau ở %s: %s" % [dimensions, button.name])
			rects.append(r)
		await capture("strip_%d" % dimensions.x)

	state.iap["buys"].append({"sku": "starter_1"})
	state.iap["buys"].append({"sku": "starter_2"})
	state.iap["buys"].append({"sku": "starter_3"})
	main._refresh_pack_promos()
	check(not shown("starter"), "starter ẩn khi đã mua cả ba")
	state.iap["buys"].clear()
	main._refresh_pack_promos()
	check(shown("starter"), "starter hiện lại khi chưa mua")

	root.size = Vector2i(390, 778)
	await settle()
	var button: Button = main._promo_ui["starter"]["button"]
	await click(button)
	check(not (main._promo_ui["starter"]["dot"] as Control).visible, "bấm xong tắt chấm đỏ")
	check(main._overlay.visible and main._overlay_box.find_child("DetailBuy_starter_1", true, false) != null, "bấm icon mở popup chi tiết pack")
	await capture("popup_starter_390")

	# Dải 1 · 2 · 3: bậc 3 nên cả ba gói đang mua được.
	check(step("starter_2") != null and not step("starter_2").disabled, "bước 2 bấm được")
	await click(step("starter_2"))
	check(detail_buy("starter_2") != null and detail_buy("starter_1") == null, "bấm 2 đổi sang starter_2")
	await click(step("starter_3"))
	check(detail_buy("starter_3") != null, "bấm 3 đổi sang starter_3")
	state.iap["buys"].append({"sku": "starter_1"})
	main._fill_iap_detail("starter_2")
	await settle()
	check(step("starter_1").disabled, "gói đã mua thì bước bị khóa")
	state.iap["buys"].clear()
	main._close_overlay()
	await settle()

	for dimensions: Vector2i in [Vector2i(320, 568), Vector2i(390, 778), Vector2i(412, 915)]:
		root.size = dimensions
		await settle()
		main._show_iap_detail("starter_2")
		await settle()
		var screen := main.get_global_rect()
		for sku in ["starter_1", "starter_2", "starter_3"]:
			var r: Rect2 = step(sku).get_global_rect()
			check(screen.encloses(r) and r.size.y >= 44.0, "bước %s nằm trong màn ở %s: %s" % [sku, dimensions, r])
		var scroll := main._overlay_box.get_parent() as ScrollContainer
		check(scroll.get_global_rect().grow(1.0).encloses(detail_buy("starter_2").get_global_rect()), "nút mua thấy được ngay, không phải cuộn, ở %s" % dimensions)
		await capture("steps_%d" % dimensions.x)
		main._close_overlay()
		await settle()

	print("PACK_PROMO_STRIP_TEST failures=", failures)
	quit(1 if failures > 0 else 0)
