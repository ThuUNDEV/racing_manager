extends SceneTree
## Xe Epic và Bộ sơn Epic (Design/35 đợt E1): dữ liệu, quà, sở hữu sơn, popup, thẻ Shop, Garage.
## Chạy: RM_LANG=vi XDG_DATA_HOME=/tmp/rmx godot --headless --path . -s res://tests/epic_garage_test.gd
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


func run() -> void:
	PopupAnim.enabled = false
	state = root.get_node("GameState")
	iap = root.get_node("Iap")
	state.SAVE_PATH = "user://tests/epic_garage.json"
	state.BAK_PATH = "user://tests/epic_garage.bak"
	state.TMP_PATH = "user://tests/epic_garage.tmp"
	DirAccess.make_dir_recursive_absolute("user://tests")
	GameData.reload()
	state.set_process(false)

	check(GameData.validate().is_empty(), "validate() không lỗi: %s" % str(GameData.validate()))
	check(GameData.cars().size() == 15 and GameData.epic_cars().size() == 5, "15 xe thường + 5 xe Epic")
	for c: Dictionary in GameData.epic_cars():
		var top := 0
		for variant: Dictionary in GameData.cars():
			if int(variant["class"]) == int(c["class"]):
				for key in GameData.PART_KEYS:
					top = maxi(top, int(variant["base"][key]))
		for key in GameData.PART_KEYS:
			check(int(c["base"][key]) > int(top * 1.0) - 6 and int(c["base"][key]) <= int(ceil(top * 1.1)), "%s.%s trong khoảng +9%% của xe tốt nhất hạng" % [c["id"], key])
		check(not GameData.car(String(c["id"])).is_empty() and not state.buy_car(String(c["id"])), "%s không mua được bằng tiền" % c["id"])
	var kinds := {"epic_car": 0, "epic_paint": 0}
	for p: Dictionary in GameData.iap_products():
		var kind := String(p.get("kind", ""))
		if kinds.has(kind):
			kinds[kind] += 1
			check(is_equal_approx(float(p["usd"]), 9.99) and bool(p["once"]) and not bool(p["consumable"]), "%s 9,99 USD, mua một lần, khôi phục được" % p["sku"])
	check(kinds["epic_car"] == 5 and kinds["epic_paint"] == 5, "5 SKU xe + 5 SKU bộ sơn")

	print("== Sơn Epic chưa mua ==")
	fresh()
	var car_a: String = state.active_car_id
	check(not state.paint_owned("epic_aurora") and not state.paint_owned("epic_amethyst") and state.paint_owned("red"), "sơn Epic chưa mua bị khóa, sơn thường mở")
	check(not state.set_cosmetics(car_a, "epic_aurora", "none") and state.set_cosmetics(car_a, "red", "none"), "không chọn được sơn chưa mua")

	print("== Mua bộ sơn ==")
	state.gems = 0
	check(state.grant_iap("epic_paint_aurora", "tok_paint_1"), "giao bộ sơn Aurora")
	check(state.paint_owned("epic_aurora") and not state.paint_owned("epic_solar"), "chỉ Aurora mở")
	check(state.set_cosmetics(car_a, "epic_aurora", "lightning") and state.cosmetics_of(car_a)["paint_id"] == "epic_aurora", "chọn được sơn đã mua")
	check(iap.block_reason("epic_paint_aurora") == "once", "bộ sơn đã mua thì khóa mua lại")
	check(state.grant_iap("epic_paint_aurora", "tok_paint_1"), "đơn trùng token giao lại không lỗi")
	check(state.save_game(), "lưu được save sau khi mua")

	print("== Mua xe Epic ==")
	check(not state.owned_cars.has("car_nova_epic") and state.grant_iap("epic_car_nova", "tok_car_1"), "giao xe Nova Epic")
	check(state.owned_cars.has("car_nova_epic") and state.car_levels.has("car_nova_epic"), "xe vào garage kèm cấp phụ tùng")
	check(state.paint_owned("epic_jade") and not state.paint_owned("epic_ruby") and state.cosmetics_of("car_nova_epic")["paint_id"] == "epic_jade", "xe Nova Epic dùng sơn Jade riêng, không mở sơn xe khác")
	check(String(GameData.car("car_pico_epic")["default_paint"]) != String(GameData.car("car_nova_epic")["default_paint"]), "mỗi xe Epic một màu sơn riêng")
	check(iap.block_reason("epic_car_nova") == "once", "xe đã mua thì khóa mua lại")
	check(state.select_car("car_nova_epic") == (int(GameData.car("car_nova_epic")["class"]) >= int(GameData.league(state.business_tier)["min_car_class"])), "chọn xe Epic theo luật hạng tối thiểu")
	state.save_game()
	var reloaded: Dictionary = state._save_data()
	check((reloaded["owned_cars"] as Dictionary).has("car_nova_epic"), "save giữ xe Epic")

	print("== Popup tự hiện ==")
	fresh()
	state.completed_races = 12
	set_tier(0)
	var queue: Array = iap.sales_popup_queue()
	check("epic_car_pico" in queue and not "epic_car_nova" in queue, "chỉ xe hạng đang mở hiện popup (có %s)" % str(queue))
	check(not "epic_paint_aurora" in queue, "bộ sơn chưa tới mốc 20 trận/hạng 1")
	state.completed_races = 25
	set_tier(1)
	queue = iap.sales_popup_queue()
	check("epic_car_nova" in queue and "epic_paint_aurora" in queue, "đủ mốc: xe hạng 2 và bộ sơn tier 1 vào hàng chờ (có %s)" % str(queue))
	state.completed_races = 5
	check(not "epic_car_pico" in iap.sales_popup_queue(), "dưới 10 trận không popup")
	state.completed_races = 12
	state.grant_iap("epic_car_pico", "tok_pico")
	check(not "epic_car_pico" in iap.sales_popup_queue(), "đã mua thì rời hàng chờ popup")

	print("== Thẻ Shop ==")
	var Card = load("res://ui/shop_epic_card.gd")
	var card_car: PanelContainer = Card.new()
	root.add_child(card_car)
	card_car.setup("car")
	await settle()
	check(card_car.buy_buttons.size() == 5 and card_car.find_child("EpicCard_epic_car_zenith", true, false) != null, "5 thẻ xe Epic")
	var card_paint: PanelContainer = Card.new()
	root.add_child(card_paint)
	card_paint.setup("paint")
	card_paint.update_view({"epic_paint_aurora": {"price": "$9.99", "reason": "once"}}, false)
	await settle()
	check(card_paint.buy_buttons.size() == 5 and (card_paint.buy_buttons["epic_paint_aurora"] as Button).disabled, "5 thẻ bộ sơn, Aurora đã mua bị khóa")
	check((card_paint.buy_buttons["epic_paint_aurora"] as Button).text == I18n.t("shop.timed_bought"), "nút hiện ĐÃ MUA")
	var pressed := []
	card_paint.buy_pressed.connect(func(sku: String) -> void: pressed.append(sku))
	(card_paint.buy_buttons["epic_paint_solar"] as Button).pressed.emit()
	check(pressed == ["epic_paint_solar"], "bấm mua phát đúng SKU")
	card_car.queue_free()
	card_paint.queue_free()

	print("== Garage ==")
	fresh()
	state.grant_iap("epic_paint_neon", "tok_neon")
	var garage: Control = load("res://ui/garage_page.gd").new()
	root.add_child(garage)
	garage.size = Vector2(390, 700)
	garage.refresh()
	garage.debug_show("2")
	await settle()
	check(garage.find_child("Paint_epic_neon", true, false) != null and garage.find_child("PaintLock_epic_neon", true, false) == null, "Neon đã mua: không khóa")
	check(garage.find_child("PaintLock_epic_solar", true, false) != null, "Solar chưa mua: có khóa")
	check(garage.find_child("Paint_epic_amethyst", true, false) == null and garage.find_child("Paint_epic_jade", true, false) == null, "sơn xe Epic ẩn khi chưa có xe đó")
	garage.queue_free()

	print("EPIC_GARAGE_TEST failures=%d" % failures)
	quit(1 if failures > 0 else 0)
