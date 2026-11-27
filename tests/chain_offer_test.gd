extends SceneTree
## Chain Offer (Design/35 đợt B): dữ liệu 2 × 28 bước, mở theo starter_3/bậc 2, mua tuần tự, thẻ Shop.
## Chạy: RM_LANG=vi godot --headless --path . -s res://tests/chain_offer_test.gd
const PopupAnim = preload("res://ui/popup_anim.gd")
var failures := 0
var state: Node
var iap: Node


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL ", message)


func settle() -> void:
	for i in 10:
		await process_frame


func fresh() -> void:
	state.init_new_game()
	state.active = false
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"


func buy(sku: String) -> void:
	(state.iap["buys"] as Array).append({"sku": sku, "token": "t_" + sku, "order": "", "t": 0})


func run() -> void:
	PopupAnim.enabled = false
	state = root.get_node("GameState")
	iap = root.get_node("Iap")
	state.SAVE_PATH = "user://tests/chain_offer.json"
	state.BAK_PATH = "user://tests/chain_offer.bak"
	state.TMP_PATH = "user://tests/chain_offer.tmp"
	DirAccess.make_dir_recursive_absolute("user://tests")
	GameData.reload()
	state.set_process(false)

	check(GameData.validate().is_empty(), "validate() không lỗi: %s" % str(GameData.validate()))
	for chain in ["driver", "gear"]:
		var skus: Array = iap.chain_skus(chain)
		check(skus.size() == 28, "%s: 28 bước" % chain)
		var prev_usd := 0.0
		var ordered := true
		for sku: String in skus:
			var usd := float(GameData.iap_product(sku)["usd"])
			ordered = ordered and usd >= prev_usd
			prev_usd = usd
		check(ordered, "%s: giá không giảm theo bước" % chain)
	var step4: Dictionary = GameData.iap_product("chain_driver_04")
	check(is_equal_approx(float(step4["usd"]), 4.99) and int(step4["grant"]["gems"]) == 255 and int(step4["grant"]["driver_coupon"]["pro"]) == 10, "chain_driver_04 = $4,99, 255 gem, 10 vé (APK)")
	var gear1: Dictionary = GameData.iap_product("chain_gear_01")
	check(is_equal_approx(float(gear1["usd"]), 0.99) and int(gear1["grant"]["gems"]) == 50 and int(gear1["grant"]["gear_coupon"]["standard"]) == 5, "chain_gear_01 = $0,99, 50 gem, 5 vé (APK)")
	var last: Dictionary = GameData.iap_product("chain_driver_28")
	check(is_equal_approx(float(last["usd"]), 99.99) and int(last["grant"]["gems"]) == 5500 and int(last["grant"]["driver_coupon"]["pro"]) == 165, "bước 28 = $99,99, 5.500 gem, 165 vé (APK)")

	fresh()
	state.business_tier = 1
	check(iap.chain_state("driver")["sku"] == "" and iap.block_reason("chain_driver_01") == "locked", "chưa mua starter_3 và bậc 1: chuỗi chưa mở")
	state.business_tier = 2
	var opened: Dictionary = iap.chain_state("driver")
	check(opened["sku"] == "chain_driver_01" and opened["step"] == 1 and opened["bought"] == 0 and opened["next_sku"] == "chain_driver_02", "bậc 2: mở bước 1")
	check(iap.block_reason("chain_driver_02") == "locked", "bước 2 khóa tới khi mua bước 1")
	state.business_tier = 1
	buy("starter_3")
	check(iap.chain_state("gear")["sku"] == "chain_gear_01", "mua starter_3 cũng mở chuỗi")
	buy("chain_driver_01")
	buy("chain_driver_02")
	var mid: Dictionary = iap.chain_state("driver")
	check(mid["sku"] == "chain_driver_03" and mid["step"] == 3 and mid["bought"] == 2, "mua tuần tự: tới bước 3")
	check(iap.block_reason("chain_driver_01") == "once" and iap.chain_state("gear")["step"] == 1, "bước đã mua không bán lại; chuỗi gear độc lập")
	for index in range(3, 29):
		buy("chain_driver_%02d" % index)
	var done: Dictionary = iap.chain_state("driver")
	check(done["sku"] == "" and done["bought"] == 28, "mua hết 28 bước: chuỗi kết thúc")

	fresh()
	buy("starter_3")
	var gems_before: int = state.gems
	var coupons_before: int = int(state.driver_coupons.get("pro", 0))
	check(state.grant_iap("chain_driver_01", "tok_chain_1"), "giao chain_driver_01")
	check(state.gems == gems_before + 50 and int(state.driver_coupons.get("pro", 0)) == coupons_before + 5, "thưởng 50 gem + 5 vé Pro")
	check(iap.chain_state("driver")["step"] == 2, "grant_iap ghi nhận mua: sang bước 2")
	check(state.grant_iap("chain_driver_01", "tok_chain_1") and state.gems == gems_before + 50, "giao lại cùng token không cộng thêm")

	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	fresh()
	state.business_tier = 2
	for index in range(1, 4):
		buy("chain_driver_%02d" % index)
	var main: Control = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main._select_tab(4)
	main._rebuild_shop()
	await settle()
	var driver_card := main.find_child("Chain_driver", true, false) as Control
	var gear_card := main.find_child("Chain_gear", true, false) as Control
	check(driver_card != null and driver_card.visible and gear_card != null and gear_card.visible, "Shop có hai thẻ chuỗi khi đã mở")
	check(main.find_child("Section_Chains", true, false) != null and main.find_child("Section_Chains", true, false).visible, "mục CHUỖI ƯU ĐÃI hiện")
	var progress := driver_card.find_child("ChainProgress", true, false) as Label
	check(progress != null and progress.text == "4 / 28", "thẻ tay đua ở bước 4/28: %s" % (progress.text if progress != null else "?"))
	var steps := driver_card.find_child("ChainSteps", true, false)
	var bought := 0
	for child in steps.get_children():
		if String(child.name).begins_with("Step_"):
			bought += 1
	check(steps.get_child_count() == 7 and steps.get_child(3).name == "Step_4", "dải bước: 3 đã mua + hiện tại + 2 khóa + dấu ···")
	var gear_steps := gear_card.find_child("ChainSteps", true, false)
	check(gear_steps.get_child_count() == 5 and gear_steps.get_child(0).name == "Step_1", "thẻ gear bước 1: 1 hiện tại + 3 khóa + dấu ···")
	var button := driver_card.find_child("Iap_chain_driver", true, false) as Button
	check(button != null and button.text == iap.price("chain_driver_04") and not button.disabled, "nút mua dùng giá chain_driver_04")
	var next_line := driver_card.find_child("ChainNext", true, false) as Label
	check(next_line != null and next_line.text.contains(iap.price("chain_driver_05")), "dòng gói kế tiếp ghi giá bước 5")
	var title := driver_card.find_child("ChainTitle", true, false) as Label
	check(title != null and title.text == I18n.t("shop.chain_driver").to_upper(), "tiêu đề thẻ tay đua")
	check(driver_card.get_global_rect().size.x <= root.size.x, "thẻ vừa bề ngang 390")
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		check(driver_card.size.x <= width and button.size.y >= 44 and driver_card.get_global_rect().encloses(button.get_global_rect()), "thẻ chuỗi vừa khung và nút đủ chạm ở %d (card %s, nút %s)" % [width, driver_card.get_global_rect(), button.get_global_rect()])
	if "--chain-shots" in OS.get_cmdline_user_args():
		root.size = Vector2i(390, 844)
		await settle()
		var scroll: ScrollContainer = main._shop_box.get_parent()
		scroll.scroll_vertical = 0
		await settle()
		var heading := main.find_child("Section_Chains", true, false) as Control
		scroll.scroll_vertical = int(heading.global_position.y - scroll.global_position.y - 6)
		await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/chain_offer_shop_390.png")
	print("CHAIN_OFFER_TEST failures=%d" % failures)
	quit(failures)
