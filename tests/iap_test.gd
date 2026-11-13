extends SceneTree

const BigNumber = preload("res://core/math/big_number.gd")
## Chạy: godot --headless --path . -s res://tests/iap_test.gd
## IAP (Design/28 §9, bước I0–I1): dữ liệu khớp horus-game.json và shell.html; hàng giao đúng một lần; tắt app giữa
## chừng thì mở lại giao đúng một lần; pending không thưởng tới khi trả tiền xong; invalid không thưởng; lưu lỗi thì
## không finish; quyền vĩnh viễn khôi phục được; giới hạn ngày/tuần/một lần; save cũ không có khối iap vẫn nạp được.

var _fails := 0
var _gs: Node
var _iap: Node
var _mock: MockIapProvider


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _wait() -> void:
	for i in 12:
		await process_frame


## Gọi Iap.buy và chờ kết quả. Trả {calls, last}.
func _buy(sku: String) -> Dictionary:
	var got := {"calls": 0, "last": {}}
	_iap.buy(sku, func(r: Dictionary) -> void:
		got["calls"] = int(got["calls"]) + 1
		got["last"] = r)
	await _wait()
	return got


func _deliver() -> int:
	var got := [-1]
	_iap.deliver_pending(func(n: int) -> void: got[0] = n)
	await _wait()
	return int(got[0])


func _fresh() -> void:
	_gs.init_new_game()
	_gs.simulate_write_failure = false
	_gs.save_blocked = false
	_mock.online = true
	_mock.outcome = "ok"
	_mock.double_fire = false
	_mock.test_purchase = false
	_mock.delay_sec = 0.0
	_mock.store = []
	_mock.finished.clear()
	_mock.finished = []
	_mock.buys = 0


func _initialize() -> void:
	await process_frame
	GameData.reload()
	_gs = root.get_node("GameState")
	_iap = root.get_node("Iap")
	_gs.SAVE_PATH = "user://iap_test_save.json"  # không đụng save thật
	_gs.BAK_PATH = "user://iap_test_save.bak"
	_gs.TMP_PATH = "user://iap_test_save.tmp"
	_mock = MockIapProvider.new()
	_mock.tree = self
	_iap.provider = _mock
	_fresh()

	print("== Dữ liệu ==")
	_check(GameData.validate().is_empty(), "validate() không lỗi: %s" % str(GameData.validate()))
	var prods := GameData.iap_products()
	_check(prods.size() == 30, "30 SKU (có %d)" % prods.size())
	var horus: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://horus-game.json"))
	var hp := {}
	for e: Dictionary in horus.get("products", []):
		hp[String(e["sku"])] = e
	var match_ok := hp.size() == prods.size()
	for p: Dictionary in prods:
		var h: Dictionary = hp.get(String(p["sku"]), {})
		if h.is_empty() or not is_equal_approx(float(h["usd"]), float(p["usd"])) or bool(h["consumable"]) != bool(p["consumable"]):
			match_ok = false
			print("    lệch horus-game.json: ", p["sku"])
	_check(match_ok, "horus-game.json → products khớp sku/usd/consumable")
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	var all_in_shell := true
	for p: Dictionary in prods:
		if not shell.contains('"%s"' % String(p["sku"])):
			all_in_shell = false
			print("    thiếu trong shell.html: ", p["sku"])
	_check(all_in_shell, "web/shell.html IAP_SKUS có đủ mọi SKU")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/iap.json"))
	var bad := raw.duplicate(true)
	bad["products"][1]["sku"] = bad["products"][0]["sku"]
	GameData.set_override("iap", bad)
	_check(not GameData.validate().is_empty(), "SKU trùng bị từ chối")
	bad = raw.duplicate(true)
	bad["products"][0]["grant"]["driver_coupon"] = {"vang": 1}
	GameData.set_override("iap", bad)
	_check(not GameData.validate().is_empty(), "loại coupon lạ bị từ chối")
	bad = raw.duplicate(true)
	bad["products"][5]["consumable"] = true  # no_ads phải là non-consumable
	GameData.set_override("iap", bad)
	_check(not GameData.validate().is_empty(), "perk consumable bị từ chối")
	GameData.reload()
	_check(GameData.validate().is_empty(), "dữ liệu thật hợp lệ sau khi gỡ ghi đè")

	print("== Mua gói gem: giao đúng một lần ==")
	var g0: int = _gs.gems
	var r := await _buy("gems_pack_1")
	_check(r["calls"] == 1 and r["last"]["status"] == "ok", "mua xong báo ok đúng một lần")
	_check(_gs.gems == g0 + 100, "lần đầu ×2: +100 gem (có %d)" % (_gs.gems - g0))
	_check(_mock.finished.size() == 1 and _mock.store.is_empty(), "đã finish và kho store trống")
	var f0: Dictionary = _mock.finished[0]
	_check(f0["consumable"] == true and is_equal_approx(float(f0["usd"]), 0.99), "finish kèm consumable và usd")
	g0 = _gs.gems
	r = await _buy("gems_pack_1")
	_check(_gs.gems == g0 + 50, "lần sau không còn ×2: +50 gem")
	_check(_gs.iap["first_bonus_used"].size() == 1, "first_bonus_used ghi một lần")
	_mock.double_fire = true
	g0 = _gs.gems
	r = await _buy("gems_pack_2")
	_check(r["calls"] == 1 and _gs.gems == g0 + 550, "SDK bắn kết quả hai lần: giao một lần (lần đầu ×2 = 550)")
	_mock.double_fire = false

	print("== Token trùng ==")
	_fresh()
	g0 = _gs.gems
	_check(_gs.grant_iap("gems_pack_3", "tok-A") and _gs.gems == g0 + 1200, "grant_iap lần 1")
	_check(_gs.grant_iap("gems_pack_3", "tok-A") and _gs.gems == g0 + 1200, "cùng token: báo true nhưng không cộng thêm")
	_check(not _gs.grant_iap("khong_co_sku", "tok-B"), "SKU lạ bị từ chối")
	_check(not _gs.grant_iap("gems_pack_1", ""), "token rỗng bị từ chối")

	print("== Lưu lỗi: không finish, mở lại giao đúng một lần ==")
	_fresh()
	g0 = _gs.gems
	_gs.simulate_write_failure = true
	r = await _buy("gems_pack_1")
	_check(r["last"]["status"] == "failed", "lưu lỗi báo failed")
	_check(_mock.finished.is_empty() and _mock.store.size() == 1, "KHÔNG finish, đơn còn trong store")
	_check(_gs.gems == g0 and _gs.iap["buys"].is_empty() and _gs.iap["first_bonus_used"].is_empty(), "save giữ nguyên như cũ (hoàn tác trọn vẹn)")
	_check(not _iap.is_busy(), "nút IAP được mở khóa lại")
	_gs.simulate_write_failure = false
	var n := await _deliver()  # = lần mở game sau
	_check(n == 1 and _gs.gems == g0 + 100, "mở lại: giao đúng một lần (+100)")
	_check(_mock.finished.size() == 1 and _mock.store.is_empty(), "lúc này mới finish")
	n = await _deliver()
	_check(n == 0 and _gs.gems == g0 + 100, "giao lại lần nữa: không có gì thêm")

	print("== Tắt app sau khi lưu, trước finish ==")
	_fresh()
	g0 = _gs.gems
	_mock.add_to_store("gems_pack_4", "tok-crash")  # store vẫn giữ đơn
	_gs.grant_iap("gems_pack_4", "tok-crash")      # lần chạy trước đã lưu hàng nhưng chưa kịp finish
	_gs.load_game()                                  # mở lại game
	_check(_gs.iap_token_seen("tok-crash"), "token còn trong save sau khi nạp lại")
	var gems_after: int = _gs.gems
	n = await _deliver()
	_check(n == 1 and _gs.gems == gems_after, "store giao lại đơn cũ: chỉ finish, không cộng gem lần hai")
	_check(_mock.store.is_empty() and _mock.finished.size() == 1, "đơn được finish")

	print("== Pending / invalid / cancel / error ==")
	_fresh()
	g0 = _gs.gems
	_mock.outcome = "pending"
	r = await _buy("gems_pack_1")
	_check(r["last"]["status"] == "pending" and _gs.gems == g0, "pending: không thưởng")
	n = await _deliver()
	_check(n == 0 and _gs.gems == g0 and _mock.finished.is_empty(), "chưa thanh toán xong: pending() không thưởng, không finish")
	_mock.settle_pending()
	n = await _deliver()
	_check(n == 1 and _gs.gems == g0 + 100 and _mock.finished.size() == 1, "thanh toán xong: giao đúng một lần")
	_fresh()
	g0 = _gs.gems
	_mock.outcome = "invalid"
	r = await _buy("gems_pack_1")
	_check(r["last"]["status"] == "invalid" and _gs.gems == g0 and _mock.finished.is_empty(), "invalid: không thưởng, không finish")
	_mock.outcome = "cancel"
	r = await _buy("gems_pack_1")
	_check(r["last"]["status"] == "cancelled" and _gs.gems == g0, "cancel: không thưởng")
	_mock.outcome = "error"
	r = await _buy("gems_pack_1")
	_check(r["last"]["status"] == "error" and _gs.gems == g0, "error: không thưởng")
	_mock.online = false
	_mock.outcome = "ok"
	r = await _buy("gems_pack_1")
	_check(r["last"]["status"] == "no_network" and _mock.buys == 3, "mất mạng: không gọi store")
	_mock.online = true
	r = await _buy("khong_co_sku")
	_check(r["last"]["status"] == "unknown", "SKU lạ báo unknown")

	print("== Đơn test không gửi usd ==")
	_fresh()
	_mock.test_purchase = true
	await _buy("gems_pack_1")
	_check(_mock.finished.size() == 1 and not (_mock.finished[0] as Dictionary).has("usd"), "đơn test: vẫn giao, finish không có usd")

	print("== Quyền vĩnh viễn ==")
	_fresh()
	g0 = _gs.gems
	_check(_iap.block_reason("income_x3_up") == "requires", "income_x3_up ẩn khi chưa có ×2")
	await _buy("no_ads")
	_check(_gs.iap_has("no_ads") and bool(_gs.ad_state.get("free", false)), "no_ads: owned và ad_state.free = true")
	_check(_gs.gems == g0 + 100, "no_ads tặng 100 gem")
	_check(_iap.block_reason("no_ads") == "owned", "no_ads đã sở hữu thì không bán lại")
	_check(_iap.block_reason("offer_noads_bundle") == "hidden", "bundle ẩn khi đã có no_ads")
	await _buy("income_x2")
	_check(_gs.purchased_mult() == 2, "income_x2 → hệ số 2")
	_check(_iap.block_reason("income_x3") == "hidden" and _iap.block_reason("income_x3_up") == "", "đã có ×2: ẩn x3 thẳng, mở x3_up")
	await _buy("income_x3_up")
	_check(_gs.purchased_mult() == 3 and _iap.block_reason("income_x2") == "hidden", "nâng lên ×3")
	_gs.ad_state = {}
	_gs.load_game()
	_check(_gs.purchased_mult() == 3 and bool(_gs.ad_state.get("free", false)), "nạp lại save: hệ số và ad_state.free suy ra từ owned")
	_gs.init_new_game()  # mô phỏng cài lại app: save sạch
	_check(not _gs.iap_has("no_ads") and _gs.purchased_mult() == 1, "save sạch: mất quyền lợi")
	_mock.store = []
	_mock.finished.clear()
	_mock.add_to_store("no_ads", "tok-restore")
	_mock.add_to_store("income_x2", "tok-restore2")
	_mock.add_to_store("khong_co_sku", "tok-unknown")
	var rr := {"s": ""}
	_iap.restore(func(x: Dictionary) -> void: rr["s"] = String(x["status"]))
	await _wait()
	_check(rr["s"] == "ok" and _gs.iap_has("no_ads") and _gs.purchased_mult() == 2, "Khôi phục: giao lại no_ads và income_x2")
	_check(_mock.store.size() == 1 and _mock.finished.size() == 2, "SKU lạ không bị finish (còn trong store)")

	print("== Phút thu nhập chốt lúc bấm mua ==")
	_fresh()
	var expect: BigNumber = _gs.iap_income_value(60)
	_check(not expect.is_zero(), "rate > 0 → 60 phút thu nhập > 0")
	var c0: BigNumber = _gs.coins
	await _buy("starter_1")
	var delta: BigNumber = _gs.coins.subtract_checked(c0)
	_check(delta.equals(expect), "starter_1: +60 phút thu nhập theo rate lúc bấm")
	_check(_gs.iap["pending_ctx"].is_empty(), "pending_ctx dọn sau khi giao")
	_check(_gs.gems >= 150 and _gs.driver_coupons["pro"] == 3 and _gs.gear_coupons["standard"] == 3, "starter_1: gem và coupon")
	_check(_iap.block_reason("starter_1") == "once", "starter_1 chỉ mua một lần")
	_fresh()
	_check(_gs.iap_stash_ctx("starter_1"), "chốt ngữ cảnh")
	_gs.iap["pending_ctx"]["starter_1"]["income_value"] = BigNumber.from_int(12345)
	_gs.save_game()
	_gs.load_game()
	var v: Variant = _gs.iap["pending_ctx"].get("starter_1", {}).get("income_value")
	_check(v is BigNumber and (v as BigNumber).equals(BigNumber.from_int(12345)), "ngữ cảnh sống sót qua save/load")
	c0 = _gs.coins
	_gs.grant_iap("starter_1", "tok-ctx")
	_check(_gs.coins.subtract_checked(c0).equals(BigNumber.from_int(12345)), "đơn giao lại dùng giá trị đã chốt, không tính lại")

	print("== Tay đua trong gói ==")
	_fresh()
	var new_before: int = _gs.driver_pack_new
	_gs.grant_iap("starter_2", "tok-ha")
	_check(_gs.driver_has("driver_ha") and _gs.driver_shards("driver_ha") == 0, "starter_2 tặng Hà (mới, 0 mảnh)")
	_check(_gs.driver_pack_new == new_before + 1, "tính vào driver_pack_new (không đẩy giá tuyển SP)")
	_gs.grant_iap("char_lam", "tok-lam1")
	_check(_gs.driver_has("driver_lam") and _gs.driver_shards("driver_lam") == 30, "char_lam: tay đua mới + 30 mảnh")
	_gs.grant_iap("char_lam", "tok-lam2")
	_check(_gs.driver_shards("driver_lam") == 100, "đã có Lâm: 40 mảnh đổi + 30 mảnh kèm = +70")
	_check(_iap.block_reason("char_lam") != "", "char_lam không bán lại (once / chưa đủ bậc)")

	print("== Giới hạn ngày / tuần / pass ==")
	_fresh()
	_check(_iap.block_reason("daily_gear") == "", "gói ngày sẵn sàng")
	await _buy("daily_gear")
	_check(_iap.block_reason("daily_gear") == "daily", "mua rồi: hết lượt hôm nay")
	_gs.iap["daily"]["daily_gear"] = int(_gs.iap["daily"]["daily_gear"]) - 1
	_check(_iap.block_reason("daily_gear") == "", "sang ngày UTC mới: bán lại được")
	_gs.business_tier = 3  # chỉ đổi trong bộ nhớ để kiểm điều kiện, không lưu
	_check(_iap.block_reason("weekly_s") == "", "weekly_s mở ở business_tier 3")
	_check(_iap.block_reason("weekly_xl") == "flag", "weekly_xl tắt theo cờ")
	_gs.business_tier = 0
	_check(_iap.block_reason("weekly_s") == "locked", "weekly_s khóa khi business_tier < 3")
	_gs.grant_iap("weekly_s", "tok-w1")
	_gs.business_tier = 3
	_check(_iap.block_reason("weekly_s") == "weekly", "đã mua tuần này: khóa tới thứ Hai")
	_gs.iap["weekly"]["weekly_s"] = int(_gs.iap["weekly"]["weekly_s"]) - 1
	_check(_iap.block_reason("weekly_s") == "", "sang tuần mới: bán lại được")
	_gs.business_tier = 0
	_check(_gs.iap_week(345600.0) == 1 and _gs.iap_week(345599.0) == 0, "tuần UTC đổi vào thứ Hai 00:00 (epoch ngày 4)")
	_gs.grant_iap("pass_month", "tok-p1")
	_check(int(_gs.iap["pass_month"]["left_days"]) == 30, "pass_month: +30 ngày")
	_check(_iap.block_reason("pass_month") == "pass_left", "còn > 5 ngày: không bán lại")
	_gs.iap["pass_month"]["left_days"] = 5
	_check(_iap.block_reason("pass_month") == "", "còn ≤ 5 ngày: bán lại được")
	_gs.iap["pass_month"]["left_days"] = 50
	_gs.grant_iap("pass_month", "tok-p2")
	_check(int(_gs.iap["pass_month"]["left_days"]) == 60, "trần 60 ngày")

	print("== Hệ số thu nhập và offline ==")
	_fresh()
	var ads: Node = root.get_node("Ads")
	var base: BigNumber = _gs.coins
	_gs.tick_income(10.0)
	var d1: BigNumber = _gs.coins.subtract_checked(base)
	_check(_gs.income_multiplier() == 1 and ads.block_reason("income_boost") != "none", "chưa mua: hệ số 1, nút boost quảng cáo còn")
	await _buy("income_x2")
	_check(_gs.income_multiplier() == 2 and ads.block_reason("income_boost") == "none", "mua ×2: hệ số 2, ẩn boost quảng cáo")
	base = _gs.coins
	_gs.tick_income(10.0)
	var d2: BigNumber = _gs.coins.subtract_checked(base)
	_check(d2.compare(d1.multiply_ratio(2, 1).subtract_checked(BigNumber.from_int(1))) >= 0 and d2.compare(d1.multiply_ratio(2, 1).add(BigNumber.from_int(1))) <= 0, "thu nhập online ×2 (±1 làm tròn)")
	_gs.income_boost_left = 1800.0
	_check(_gs.income_multiplier() == 2, "boost ×2 chồng lên ×2 mua: vẫn 2 (không nhân chồng)")
	_gs.income_boost_left = 0.0
	await _buy("income_x3_up")
	_check(_gs.income_multiplier() == 3, "nâng ×3")
	_fresh()
	var now := Time.get_unix_time_from_system()
	_gs.last_accrual_utc = now - 100000.0
	_gs.settle_offline()
	var rep1: Dictionary = _gs.offline_report
	_check(is_equal_approx(float(rep1["eligible"]), Balance.offline_cap_sec()) and bool(rep1["capped"]), "offline gốc: chặn ở trần mặc định")
	_fresh()
	await _buy("offline_plus")
	_gs.last_accrual_utc = now - 100000.0
	_gs.settle_offline()
	var rep2: Dictionary = _gs.offline_report
	_check(is_equal_approx(float(rep2["eligible"]), 86400.0), "offline_plus: trần 24 giờ")
	_check((rep2["reward"] as BigNumber).compare(rep1["reward"]) > 0 and is_equal_approx(float(rep2["ratio"]), Balance.offline_ratio() * 3.0), "offline_plus: thưởng lớn hơn, tỉ lệ ×3")
	_fresh()
	_gs.grant_iap("pass_month", "tok-pm")
	_check(is_equal_approx(_gs.offline_cap_sec_now(), Balance.offline_cap_sec() + 7200.0), "Pass tháng còn hạn: +2 giờ trần offline")

	print("== Save ==")
	_fresh()
	_check(int(_gs._save_data()["schema_version"]) == _gs.SAVE_VERSION and _gs.SAVE_VERSION >= 12, "schema_version >= 12")
	var data: Dictionary = _gs._save_data()
	data["iap"] = 5
	_check(not _gs._valid_save(MoneyCodec.encode(data)), "iap sai kiểu bị từ chối")
	data = _gs._save_data()
	data["iap"]["buys"] = {}
	_check(not _gs._valid_save(MoneyCodec.encode(data)), "iap.buys sai kiểu bị từ chối")
	data = _gs._save_data()
	data.erase("iap")
	data["schema_version"] = 11
	_gs._apply(MoneyCodec.encode(data))
	_check(_gs.iap["buys"].is_empty() and _gs.purchased_mult() == 1, "save cũ không có iap: nạp với mặc định")
	_gs.grant_iap("gems_pack_1", "tok-keep")
	var snapshot: Array = _gs.iap["buys"].duplicate(true)
	_gs.load_game()
	_check(_gs.iap["buys"] == snapshot, "đơn đã mua sống sót qua save/load")

	print("")
	if _fails == 0:
		print("IAP TEST: ĐẠT")
	else:
		print("IAP TEST: %d lỗi" % _fails)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://iap_test_save.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://iap_test_save.bak"))
	quit(1 if _fails > 0 else 0)
