extends SceneTree

const BigNumber = preload("res://core/math/big_number.gd")
## Chạy: godot --headless --path . -s res://tests/ads_v1_test.gd
## Cấu hình quảng cáo thật của v1 (data/ads.json, Design/26): kiểm tra dữ liệu, boost thu nhập ×2, lá cờ thưởng income,
## coupon tay đua/gear miễn phí, mở khóa theo tutorial, thưởng chờ nhận khi lưu lỗi. Lõi các kiểu thưởng cũ ở ads_test.gd.

var _fails := 0
var _gs: Node
var _ads: Node
var _mock: MockAdsProvider


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _show(placement: String) -> Dictionary:
	var got := {"calls": 0, "last": {}}
	_ads.try_show_rewarded(placement, func(r: Dictionary) -> void:
		got["calls"] = int(got["calls"]) + 1
		got["last"] = r)
	for i in 30:
		await process_frame
	return got


func _fresh() -> void:
	GameData.reload()
	_gs.reset_progress()
	_gs.ad_state = {}
	_gs.income_boost_left = 0.0
	_gs.active = false
	_gs.simulate_write_failure = false
	_ads._flag_wait = -1.0
	_ads._flag_live = false
	_ads._pending = {}
	_mock.online = true
	_mock.ready = true
	_mock.outcome = "rewarded"
	_mock.double_fire = false
	_mock.delay_sec = 0.0


## Cho đồng hồ lá cờ chạy `sec` giây chơi mà không để GameState._process chen vào (không await giữa chừng).
func _play(sec: float) -> void:
	_gs.active = true
	_ads._process(sec)
	_gs.active = false


func _bn(v: Variant) -> BigNumber:
	return v as BigNumber


func _initialize() -> void:
	await process_frame
	_gs = root.get_node("GameState")
	_ads = root.get_node("Ads")
	_mock = MockAdsProvider.new()
	_mock.tree = self
	_ads.provider = _mock
	_fresh()

	print("== Dữ liệu data/ads.json ==")
	_check(GameData.validate().is_empty(), "validate() không lỗi: %s" % str(GameData.validate()))
	_check(int(GameData.ads()["daily_cap"]) == 12, "trần 12 rewarded/ngày")
	for id in ["income_boost", "flag_cash", "free_gems", "free_driver_coupon", "free_gear_coupon"]:
		_check((GameData.ads()["placements"] as Dictionary).has(id), "có placement " + id)
	var bad: Dictionary = (GameData.ads() as Dictionary).duplicate(true)
	bad["placements"]["income_boost"]["multiplier"] = 1
	bad["placements"]["flag_cash"]["reward"] = "tiền_từ_trên_trời"
	bad["placements"]["free_gems"]["unlock"] = "U99_khong_co"
	bad["placements"]["free_driver_coupon"]["kind"] = "khong_co"
	bad["placements"]["flag_cash"]["miss_gap_max_sec"] = 10
	GameData.set_override("ads", bad)
	var errs: Array = GameData.validate()
	var joined := " | ".join(errs)
	_check(joined.contains("multiplier") and joined.contains("reward lạ") and joined.contains("U99_khong_co")
		and joined.contains("không phải loại coupon") and joined.contains("miss_gap_max_sec"), "dữ liệu sai bị báo đúng chỗ (%d lỗi)" % errs.size())
	GameData.reload()

	print("== Boost ×2 (income_boost) ==")
	_fresh()
	_check(_gs.income_multiplier() == 1, "chưa boost: hệ số 1")
	var off: Dictionary = _ads.offer_amount("income_boost")
	_check(_ads.can_offer("income_boost") and int(off["multiplier"]) == 2 and int(off["seconds"]) == 1800, "mời ×2 trong 1800 giây")
	var r := await _show("income_boost")
	_check(r["last"]["status"] == "rewarded" and is_equal_approx(_gs.income_boost_left, 1800.0) and _gs.income_multiplier() == 2, "xem xong: boost 30 phút, hệ số 2")
	_check(_gs.processed_rewards.has("ad/income_boost/b1"), "ghi ID thưởng ad/income_boost/b1")
	_check(_ads.block_reason("income_boost") == "none" and not _ads.can_offer("income_boost"), "đang chạy: không mời lần nữa (không cộng dồn)")
	var rate: BigNumber = _gs.total_online_rate()
	var c0: BigNumber = _gs.coins
	_gs.tick_income(10.0)
	_check(_gs.coins.equals(c0.add(rate.multiply_ratio(20, 1))), "10 giây có boost = 20 giây thu nhập")
	_check(is_equal_approx(_gs.income_boost_left, 1790.0), "boost còn 1790 giây")
	_gs.income_boost_left = 5.0
	c0 = _gs.coins
	_gs.tick_income(10.0)
	_check(_gs.coins.equals(c0.add(rate.multiply_ratio(15, 1))), "ranh giới: 5 giây ×2 + 5 giây ×1 = 15 giây thu nhập")
	_check(_gs.income_boost_left == 0.0 and _gs.income_multiplier() == 1, "hết boost: hệ số về 1")
	_check(_gs.online_rate().equals(rate) and _gs.saved_online_rate.compare(rate.multiply_ratio(2, 1)) < 0, "rate gốc và rate offline không bị nhân")
	_gs.income_boost_left = 100.0
	_gs.ad_pause = true
	_gs.active = true
	_gs._process(5.0)
	_gs.active = false
	_gs.ad_pause = false
	_check(is_equal_approx(_gs.income_boost_left, 100.0), "đang xem quảng cáo: boost không tụt")
	_gs.income_boost_left = 0.0
	var ended: Array = []
	_ads.ad_event.connect(func(n: String, _p: Dictionary) -> void: ended.append(n))
	_gs.income_boost_left = 0.5
	_ads._process(0.01)
	_gs.income_boost_left = 0.0
	_ads._process(0.01)
	_check(ended.has("boost_end"), "analytics boost_end khi hết boost")
	_fresh()
	for i in 3:
		_gs.income_boost_left = 0.0
		r = await _show("income_boost")
		_check(r["last"]["status"] == "rewarded", "lần %d trong ngày" % (i + 1))
	_gs.income_boost_left = 0.0
	_check(_ads.block_reason("income_boost") == "capped", "đủ 3 lần/ngày: capped")

	print("== Boost: lưu, nạp, lỗi lưu ==")
	_fresh()
	_gs.income_boost_left = 123.5
	_check(_gs.save_game(), "lưu có boost")
	_gs.income_boost_left = 0.0
	_check(_gs.load_game() == "ok" and is_equal_approx(_gs.income_boost_left, 123.5), "nạp lại: boost còn 123,5 giây")
	_gs._apply({"schema_version": 5, "income_boost_left": -5.0})
	_check(_gs.income_boost_left == 0.0, "save sửa tay âm: về 0")
	_gs._apply({"schema_version": 5, "income_boost_left": 1.0e12})
	_check(_gs.income_boost_left == 86400.0, "save sửa tay quá lớn: chặn 86400")
	_gs._apply({"schema_version": 5, "income_boost_left": NAN})
	_check(_gs.income_boost_left == 0.0, "NaN: về 0")
	_fresh()
	_gs.simulate_write_failure = true
	r = await _show("income_boost")
	_check(r["last"]["status"] == "failed" and _gs.income_boost_left == 0.0 and not _gs.processed_rewards.has("ad/income_boost/b1"), "lưu lỗi: không boost, không ghi ID")
	_check(_ads.has_pending("income_boost"), "giữ thưởng chờ nhận để thử lại")
	_gs.simulate_write_failure = false
	var retry := {"n": 0, "last": {}}
	_ads.retry_pending("income_boost", func(x: Dictionary) -> void:
		retry["n"] = int(retry["n"]) + 1
		retry["last"] = x)
	_check(retry["n"] == 1 and retry["last"]["status"] == "rewarded" and is_equal_approx(_gs.income_boost_left, 1800.0), "thử nhận lại không phải xem lại: được boost")
	_check(not _ads.has_pending("income_boost"), "thưởng chờ đã xoá")
	_ads.retry_pending("income_boost", func(x: Dictionary) -> void: retry["last"] = x)
	_check(retry["last"]["status"] == "unavailable" and int(_gs.ad_state["count"]) == 1, "thử lần hai: không nhận trùng")

	print("== Thưởng đua có boost ==")
	_fresh()
	_gs.activate()
	_gs.time_scale = 10.0
	_gs.income_boost_left = 600.0
	var guard := 0
	while _gs.phase != "racing" and guard < 100:
		_gs.advance(0.5)
		guard += 1
	_check(_gs.phase == "racing" and _bn(_gs.race_snapshot["reward_rate"]).equals(_gs.online_rate().multiply_ratio(2, 1)), "lượt xuất phát khi đang boost: rate tính thưởng ×2")
	_gs.active = false
	_gs.time_scale = 1.0
	_fresh()
	_gs.activate()
	_gs.time_scale = 10.0
	guard = 0
	while _gs.phase != "racing" and guard < 100:
		_gs.advance(0.5)
		guard += 1
	_check(_bn(_gs.race_snapshot["reward_rate"]).equals(_gs.online_rate()), "không boost: rate thưởng giữ nguyên")
	_gs.active = false
	_gs.time_scale = 1.0

	print("== Lá cờ thưởng income (flag_cash) ==")
	_fresh()
	_check(_ads.flag_wait_left() < 0.0 and not _ads.flag_due(), "chưa đếm: chưa có cờ")
	_gs.ad_pause = true
	_play(100.0)
	_gs.ad_pause = false
	_gs.suspended = true
	_play(100.0)
	_gs.suspended = false
	_check(_ads.flag_wait_left() < 0.0, "ra nền/đang xem quảng cáo: đồng hồ không chạy")
	_play(30.0)
	_check(is_equal_approx(_ads.flag_wait_left(), 30.0) and not _ads.flag_due(), "30 giây chơi: còn 30 giây")
	_play(30.0)
	_check(_ads.flag_wait_left() == 0.0 and _ads.flag_due(), "đủ 60 giây: đến lúc")
	_check(not _ads.flag_due(true), "giao diện đang bận: không tạo cờ")
	_mock.ready = false
	_check(not _ads.flag_due(), "quảng cáo chưa tải: không tạo cờ")
	_gs.ad_state["free"] = true
	_check(_ads.flag_due(), "Đội tự do: vẫn tạo cờ dù chưa có quảng cáo")
	_gs.ad_state.erase("free")
	_mock.ready = true
	_check(_ads.flag_begin() and not _ads.flag_due() and not _ads.flag_begin(), "bắt đầu cờ: không tạo cờ thứ hai")
	_play(500.0)
	_check(_ads.flag_wait_left() == 0.0, "cờ đang chạy: đồng hồ đứng")
	_ads.flag_end(false)
	_check(int(_gs.ad_state["flag_misses"]) == 1 and is_equal_approx(_ads.flag_wait_left(), 120.0), "bỏ lỡ lá 1: chờ 120 giây")
	_play(119.0)
	_check(not _ads.flag_due(), "119 giây: chưa tới")
	_play(1.0)
	_check(_ads.flag_due(), "120 giây: tới")
	var waits: Array = []
	for i in 4:
		_check(_ads.flag_begin(), "tạo cờ lần %d" % (i + 2))
		_ads.flag_end(false)
		waits.append(_ads.flag_wait_left())
		_play(_ads.flag_wait_left())
	_check(waits == [120.0, 240.0, 480.0, 480.0], "bỏ lỡ liên tiếp: 120, 240, 480, 480 (trần) - thực tế %s" % str(waits))
	_check(_ads.flag_begin(), "tạo cờ")
	_ads.flag_end(true)
	_check(int(_gs.ad_state["flag_misses"]) == 0 and is_equal_approx(_ads.flag_wait_left(), 120.0), "chạm cờ: bỏ lỡ về 0, chờ 120 giây")
	_check(not _ads.flag_intro_seen(), "chưa hiện gợi ý lần đầu")
	_ads.flag_mark_intro_seen()
	_check(_ads.flag_intro_seen() and bool(_gs.ad_state["flag_intro"]), "đã đánh dấu gợi ý (nằm trong save)")

	print("== Lá cờ: thưởng ==")
	_fresh()
	rate = _gs.total_online_rate()
	var amount: BigNumber = _ads.offer_amount("flag_cash")
	_check(amount.equals(rate.multiply_ratio(600, 1).floor_number()), "thưởng = 600 giây thu nhập")
	_gs.income_boost_left = 100.0
	_check((_ads.offer_amount("flag_cash") as BigNumber).equals(amount), "đang boost ×2: thưởng lá cờ KHÔNG nhân (vẫn 600 giây thu nhập gốc)")
	_gs.income_boost_left = 0.0
	c0 = _gs.coins
	r = await _show("flag_cash")
	_check(r["last"]["status"] == "rewarded" and _gs.coins.equals(c0.add(amount)), "xem xong: cộng đúng")
	_check(_gs.processed_rewards.has("ad/flag_cash/f1") and _ads.can_offer("flag_cash"), "ID f1; dịp kế f2 mời được")
	_mock.outcome = "cancelled"
	c0 = _gs.coins
	r = await _show("flag_cash")
	_check(r["last"]["status"] == "cancelled" and _gs.coins.equals(c0) and int(_gs.ad_state["by"]["flag_cash"]) == 1, "đóng sớm: không thưởng, không tính lượt")
	_mock.outcome = "rewarded"
	_gs.ad_state["by"]["flag_cash"] = 5
	_check(_ads.block_reason("flag_cash") == "capped" and not _ads.flag_due(), "đủ 5 lần/ngày: không còn cờ")
	_fresh()
	_gs.simulate_write_failure = true
	c0 = _gs.coins
	r = await _show("flag_cash")
	_check(r["last"]["status"] == "failed" and _gs.coins.equals(c0) and _ads.has_pending("flag_cash"), "lưu lỗi: không cộng, giữ thưởng chờ")
	_gs.simulate_write_failure = false
	retry = {"n": 0, "last": {}}
	_ads.retry_pending("flag_cash", func(x: Dictionary) -> void:
		retry["n"] = int(retry["n"]) + 1
		retry["last"] = x)
	_check(retry["last"]["status"] == "rewarded" and _gs.coins.equals(c0.add(amount)), "thử nhận lại: cộng đúng, không xem lại")
	_ads.retry_pending("flag_cash", func(x: Dictionary) -> void: retry["last"] = x)
	_check(_gs.coins.equals(c0.add(amount)), "thử lần hai: không cộng trùng")
	_fresh()
	_gs.simulate_write_failure = true
	r = await _show("flag_cash")
	_ads.clear_pending()
	_gs.simulate_write_failure = false
	_check(not _ads.has_pending("flag_cash"), "đóng popup: bỏ thưởng chờ")

	print("== Coupon miễn phí: tay đua và gear ==")
	_fresh()
	var pity: Dictionary = _gs.driver_pity.duplicate()
	var d0: int = int(_gs.driver_coupons.get("pro", 0))
	var g0: int = int(_gs.gear_coupons.get("standard", 0))
	var da: Dictionary = _ads.offer_amount("free_driver_coupon")
	_check(String(da["kind"]) == "pro" and int(da["count"]) == 1, "tay đua: 1 coupon Pro")
	r = await _show("free_driver_coupon")
	_check(r["last"]["status"] == "rewarded" and int(_gs.driver_coupons["pro"]) == d0 + 1, "nhận 1 coupon Pro")
	_check(_gs.driver_pity == pity, "không đổi bộ đếm bảo đảm")
	_check(_ads.remaining_today("free_driver_coupon") == 0 and not _ads.can_offer("free_driver_coupon"), "1 lần/ngày")
	r = await _show("free_gear_coupon")
	_check(r["last"]["status"] == "rewarded" and int(_gs.gear_coupons["standard"]) == g0 + 1, "gear: nhận 1 coupon Standard")
	_check(int(_gs.gear_coupons.get("elite", 0)) == 0 and int(_gs.driver_coupons.get("allstar", 0)) == 0, "không có coupon gói cao")
	var bad2: Dictionary = (GameData.ads() as Dictionary).duplicate(true)
	bad2["placements"]["free_gear_coupon"]["kind"] = "khong_co"
	GameData.set_override("ads", bad2)
	_check(_ads.block_reason("free_gear_coupon") == "none", "loại coupon lạ: không mời")
	GameData.reload()

	print("== Mở khóa theo tutorial ==")
	_fresh()
	_gs.tutorial["gated"] = true
	var pairs := {"income_boost": "U4_shop", "flag_cash": "U4_shop", "free_gems": "U4_shop", "free_driver_coupon": "U5_drivers", "free_gear_coupon": "U3_bag"}
	var consistent := true
	var ever_locked := false
	var ever_open := false
	for n in 13:
		_gs.completed_races = n
		for pl: String in pairs:
			var locked: bool = _ads.block_reason(pl) == "locked"
			ever_locked = ever_locked or locked
			ever_open = ever_open or not locked
			if locked == _gs.feature_unlocked(pairs[pl]):
				consistent = false
	_check(consistent and ever_locked and ever_open, "chỉ hiện khi tính năng chứa nó đã mở (0..12 lượt)")
	_gs.completed_races = 0
	_check(_ads.block_reason("free_gears" if false else "free_gear_coupon") == "locked", "chưa mở Túi: coupon gear bị khóa")

	print("== Trần ngày ==")
	_fresh()
	_gs.ad_state = {"day": int(floor(Time.get_unix_time_from_system() / 86400.0)), "count": 12, "by": {}, "last": {}}
	_check(_ads.block_reason("free_gems") == "capped" and _ads.block_reason("income_boost") == "capped", "đủ 12 lượt/ngày: mọi placement bị chặn")
	_gs.ad_state["count"] = 11
	_check(_ads.block_reason("free_gems") == "", "còn 1 lượt: mời được")

	_gs.reset_progress()
	_gs.active = false
	print("")
	print("THẤT BẠI: %d" % _fails if _fails > 0 else "TẤT CẢ ĐẠT")
	quit(1 if _fails > 0 else 0)
