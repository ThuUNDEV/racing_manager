extends SceneTree
## Ưu đãi xoay tuần (Design/35 đợt C+D): dữ liệu Gói Giới hạn / Chọn Một, vòng xoay UTC, giới hạn tuần, loại trừ, quà, thẻ Shop.
## Chạy: RM_LANG=vi XDG_DATA_HOME=/tmp/rmx godot --headless --path . -s res://tests/timed_offer_test.gd
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


func set_tier(tier: int) -> void:
	state.business_tier = tier
	state.unlocked_tier = maxi(state.unlocked_tier, tier)


func buy(sku: String, at: float = -1.0) -> void:
	var stamp := Time.get_unix_time_from_system() if at < 0.0 else at
	(state.iap["buys"] as Array).append({"sku": sku, "token": "t_%s_%d" % [sku, (state.iap["buys"] as Array).size()], "order": "", "t": int(stamp)})


func other_rotation(kind: String) -> int:
	return iap.rotation_of(kind) % int(GameData.IAP_ROTATIONS[kind]) + 1


func run() -> void:
	PopupAnim.enabled = false
	state = root.get_node("GameState")
	iap = root.get_node("Iap")
	state.SAVE_PATH = "user://tests/timed_offer.json"
	state.BAK_PATH = "user://tests/timed_offer.bak"
	state.TMP_PATH = "user://tests/timed_offer.tmp"
	DirAccess.make_dir_recursive_absolute("user://tests")
	GameData.reload()
	state.set_process(false)

	check(GameData.validate().is_empty(), "validate() không lỗi: %s" % str(GameData.validate()))
	var limited := 0
	var choose := 0
	for p: Dictionary in GameData.iap_products():
		limited += 1 if String(p["kind"]) == "limited" else 0
		choose += 1 if String(p["kind"]) == "chooseone" else 0
	check(limited == 12 and choose == 12, "12 gói giới hạn (4 vòng x 3) và 12 gói chọn một (3 vòng x 4): %d/%d" % [limited, choose])
	var l13: Dictionary = GameData.iap_product("limited_1_3")
	check(is_equal_approx(float(l13["usd"]), 9.99) and int(l13["grant"]["gems"]) == 520 and int(l13["grant"]["driver_coupon"]["pro"]) == 20 and int(l13["grant"]["gear_coupon"]["standard"]) == 20, "limited_1_3 = $9,99, 520 gem, 20 vé tay đua, 20 vé gear (concept)")
	var l11: Dictionary = GameData.iap_product("limited_1_1")
	check(is_equal_approx(float(l11["usd"]), 2.99) and int(l11["grant"]["gems"]) == 100 and int(l11["grant"]["driver_coupon"]["pro"]) == 7 and not l11["grant"]["driver_coupon"].has("allstar"), "limited_1_1 = $2,99, 100 gem, 7 vé, không có vé All-Star")
	check(int(GameData.iap_product("limited_4_1")["week_cap"]) == 5 and int(GameData.iap_product("limited_1_1")["week_cap"]) == 1, "vòng 4 mua tối đa 5 lần, các vòng khác 1 lần")
	var m1: Dictionary = GameData.iap_product("chooseone_m_1")
	check(is_equal_approx(float(m1["usd"]), 4.99) and int(m1["grant"]["gems"]) == 150 and int(m1["grant"]["driver_shards_tier"]["elite"]) == 10 and int(m1["grant"]["driver_coupon"]["pro"]) == 8, "chooseone_m_1 = $4,99, 150 gem, 10 mảnh Elite, 8 vé (concept)")
	var all1: Dictionary = GameData.iap_product("chooseone_all_1")
	check(is_equal_approx(float(all1["usd"]), 9.99) and int(all1["grant"]["gems"]) == 520, "chooseone_all_1 = $9,99, 520 gem (50+150+320)")
	var sum := 0.0
	for size in ["s", "m", "l"]:
		sum += float(GameData.iap_product("chooseone_%s_1" % size)["usd"])
	check(is_equal_approx(sum, 14.97) and float(all1["usd"]) < sum, "Tất cả rẻ hơn S+M+L ($9,99 so với $14,97)")

	var week := 1
	check(iap.rotation_of("limited", week * 7 * 86400.0 - 3 * 86400.0) == 2 and iap.rotation_of("chooseone", week * 7 * 86400.0 - 3 * 86400.0) == 2, "tuần UTC 1 -> vòng 2")
	check(iap.rotation_of("limited", 4 * 7 * 86400.0 - 3 * 86400.0) == 1 and iap.rotation_of("chooseone", 3 * 7 * 86400.0 - 3 * 86400.0) == 1, "quay về vòng 1 sau đủ số vòng")
	var week_start := 7.0 * 86400.0 - 3 * 86400.0
	check(is_equal_approx(iap.rotation_ends_in(week_start + 3600.0), 7.0 * 86400.0 - 3600.0), "đếm ngược tới thứ Hai 00:00 UTC kế tiếp")

	fresh()
	set_tier(1)
	var cur: int = iap.rotation_of("limited")
	var cur_sku := "limited_%d_2" % cur
	check(iap.block_reason(cur_sku) == "locked" and not iap.timed_state("limited")["open"], "bậc 1: gói giới hạn khóa, mục ẩn")
	set_tier(2)
	check(iap.block_reason(cur_sku) == "" and iap.timed_state("limited")["open"], "bậc 2: ô thuộc vòng hiện tại bán được")
	var off_sku := "limited_%d_2" % other_rotation("limited")
	check(iap.block_reason(off_sku) == "rotation", "ô của vòng khác: rotation")
	var skus: Array = iap.timed_skus("limited")
	check(skus.size() == 3 and skus[0] == "limited_%d_1" % cur and skus[2] == "limited_%d_3" % cur, "thứ tự ô rẻ -> đắt")
	var chosen: Array = iap.timed_skus("chooseone")
	var cr: int = iap.rotation_of("chooseone")
	check(chosen == ["chooseone_s_%d" % cr, "chooseone_m_%d" % cr, "chooseone_l_%d" % cr, "chooseone_all_%d" % cr], "thứ tự S, M, L, Tất cả")
	buy(cur_sku)
	check(iap.block_reason(cur_sku) == "weekly" and iap.block_reason("limited_%d_1" % cur) == "", "mua xong ô 2: hết lượt tuần, ô khác vẫn bán")
	check(iap.bought_this_week(cur_sku) == 1 and iap.timed_state("limited")["bought"][cur_sku] == 1, "đếm đơn trong tuần")
	buy("limited_4_1", 1000000.0)
	buy("limited_4_1", 1000000.0)
	buy("limited_4_1", 1000000.0)
	check(iap.bought_this_week("limited_4_1", 1000000.0) == 3 and iap.bought_this_week("limited_4_1", 1000000.0 + 7 * 86400.0) == 0, "đếm theo tuần: tuần khác về 0")

	var size_s := "chooseone_s_%d" % cr
	var size_all := "chooseone_all_%d" % cr
	check(iap.block_reason(size_s) == "" and iap.block_reason(size_all) == "", "chưa mua gì: S và Tất cả đều bán")
	buy(size_s)
	check(iap.block_reason(size_s) == "weekly" and iap.block_reason(size_all) == "weekly", "mua S: S hết lượt và Tất cả bị khóa")
	check(iap.block_reason("chooseone_m_%d" % cr) == "", "mua S: M vẫn bán")
	fresh()
	set_tier(2)
	buy(size_all)
	check(iap.block_reason(size_all) == "weekly" and iap.block_reason(size_s) == "weekly", "mua Tất cả: khóa cả S, M, L")

	fresh()
	var gems_before: int = state.gems
	var pro_before := int(state.driver_coupons.get("pro", 0))
	var all_before := int(state.driver_coupons.get("allstar", 0))
	check(state.grant_iap("chooseone_m_1", "tok_m"), "giao chooseone_m_1")
	check(state.gems == gems_before + 150 and int(state.driver_coupons.get("pro", 0)) == pro_before + 8, "150 gem + 8 vé Pro")
	check(int(state.driver_coupons.get("allstar", 0)) == all_before + 1, "chưa có tay đua Elite: 10 mảnh đổi thành 1 vé All-Star")
	var elite := ""
	var elite_two := ""
	for d: Dictionary in GameData.drivers():
		if int(d["tier"]) == 2:
			if elite == "":
				elite = String(d["id"])
			elif elite_two == "":
				elite_two = String(d["id"])
	state.owned_drivers.append(elite)
	state.driver_progress[elite] = {"level": 0, "shards": 0}
	state.owned_drivers.append(elite_two)
	state.driver_progress[elite_two] = {"level": 1, "shards": 3}
	check(state.grant_iap("chooseone_m_2", "tok_m2"), "giao chooseone_m_2")
	check(state.driver_shards(elite_two) == 3 + 25 and state.driver_shards(elite) == 0, "25 mảnh Elite vào tay đua Elite level cao nhất chưa tối đa")
	check(state.grant_iap("limited_3_3", "tok_l33") and int(state.driver_coupons.get("allstar", 0)) >= all_before + 1 + 8, "gói giới hạn có Chọn 1 -> vé All-Star")
	check(state.grant_iap("chooseone_m_1", "tok_m") and state.driver_shards(elite_two) == 28, "giao lại cùng token không cộng thêm")

	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	fresh()
	set_tier(2)
	var main: Control = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main._select_tab(4)
	main._rebuild_shop()
	await settle()
	var limited_card := main.find_child("Timed_limited", true, false) as Control
	var choose_card := main.find_child("Timed_chooseone", true, false) as Control
	check(limited_card != null and limited_card.visible and choose_card != null and choose_card.visible, "Shop có hai thẻ ưu đãi xoay tuần")
	check(main.find_child("Section_Limited", true, false).visible and main.find_child("Section_ChooseOne", true, false).visible, "hai mục ƯU ĐÃI GIỚI HẠN / CHỌN MỘT hiện")
	for index in range(1, 4):
		check(limited_card.find_child("Slot_limited_%d_%d" % [cur, index], true, false) != null, "ô limited_%d_%d có thẻ" % [cur, index])
	var slot_button := limited_card.find_child("Iap_limited_%d_1" % cur, true, false) as Button
	check(slot_button != null and slot_button.text == iap.price("limited_%d_1" % cur) and not slot_button.disabled, "nút ô 1 dùng giá store")
	check(limited_card.find_child("BestValue", true, false) != null, "ô đắt nhất có nhãn GIÁ TRỊ NHẤT")
	check(choose_card.find_child("Tab_all", true, false) != null and choose_card.find_child("SaveBadge", true, false) != null, "tab Tất cả có nhãn tiết kiệm")
	var title := choose_card.find_child("ChooseTitle", true, false) as Label
	check(title != null and title.text == I18n.t("shop.tier_shards_title") % I18n.t("drivers.tier_elite"), "mặc định chọn M: mảnh Elite")
	(choose_card.find_child("Tab_l", true, false) as Button).pressed.emit()
	await settle()
	title = choose_card.find_child("ChooseTitle", true, false) as Label
	check(title != null and title.text == I18n.t("shop.tier_shards_title") % I18n.t("drivers.tier_legend"), "bấm tab L: mảnh Legend")
	state.iap["buys"].append({"sku": "limited_%d_1" % cur, "token": "ui_buy", "order": "", "t": int(Time.get_unix_time_from_system())})
	main._rebuild_shop()
	await settle()
	slot_button = limited_card.find_child("Iap_limited_%d_1" % cur, true, false) as Button
	check(slot_button != null and slot_button.disabled and slot_button.text == I18n.t("shop.timed_bought"), "ô đã mua hiện ĐÃ MUA và khóa")
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		check(limited_card.size.x <= width and choose_card.size.x <= width, "hai thẻ vừa bề ngang %d" % width)
		slot_button = limited_card.find_child("Iap_limited_%d_2" % cur, true, false) as Button
		check(slot_button != null and slot_button.size.y >= 36 and limited_card.get_global_rect().encloses(slot_button.get_global_rect()), "nút ô nằm trong thẻ ở %d" % width)
	root.size = Vector2i(390, 844)
	for detail_sku in ["limited_%d_2" % cur, "chooseone_m_%d" % cr]:
		main._show_iap_detail(detail_sku)
		await settle()
		check(main._overlay_box.find_child("Iap_" + detail_sku, true, false) != null or main._overlay_box.get_child_count() > 0, "popup chi tiết %s dựng được" % detail_sku)
		if "--timed-shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/timed_detail_%s_390.png" % detail_sku)
		main._close_overlay()
		await settle()
	if "--timed-shots" in OS.get_cmdline_user_args():
		root.size = Vector2i(390, 844)
		await settle()
		var scroll: ScrollContainer = main._shop_box.get_parent()
		var heading := main.find_child("Section_Limited", true, false) as Control
		scroll.scroll_vertical = int(heading.global_position.y - scroll.global_position.y - 6)
		await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/limited_chooseone_shop_390.png")
		var choose_heading := main.find_child("Section_ChooseOne", true, false) as Control
		scroll.scroll_vertical = int(choose_heading.global_position.y - scroll.global_position.y + scroll.scroll_vertical - 6)
		await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/limited_chooseone_shop_390_b.png")
	print("TIMED_OFFER_TEST failures=%d" % failures)
	quit(failures)
