extends SceneTree
## Chạy: godot --headless --path . -s res://tests/ads_shop_test.gd
## Thẻ quảng cáo miễn phí trong Shop (Design/26 §5–§6, §9): trạng thái thẻ (Ads.card_state), chấm đỏ (shop_ready) và trang Shop.

var _fails := 0
var _gs: Node
var _ads: Node
var _mock: MockAdsProvider
var _clock := 1_800_000_000


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _fresh() -> void:
	GameData.reload()
	_gs.reset_progress()
	_gs.ad_state = {}
	_gs.active = false
	_gs.simulate_write_failure = false
	_ads._pending = {}
	_ads._flag_live = false
	_mock.online = true
	_mock.ready = true
	_mock.outcome = "rewarded"
	_mock.delay_sec = 0.0


func _state(pl: String) -> String:
	return String(_ads.card_state(pl)["state"])


func _watch(pl: String) -> Dictionary:
	var got := {}
	_ads.try_show_rewarded(pl, func(r: Dictionary) -> void: got.merge(r, true))
	for i in 30:
		await process_frame
	return got


func _initialize() -> void:
	await process_frame
	_gs = root.get_node("GameState")
	_ads = root.get_node("Ads")
	_mock = MockAdsProvider.new()
	_mock.tree = self
	_ads.provider = _mock
	_fresh()

	print("== Trạng thái thẻ ==")
	_check(_state("free_gems") == "ready", "mới vào: sẵn sàng")
	_mock.ready = false
	_check(_state("free_gems") == "loading", "chưa tải xong: đang tải")
	_mock.online = false
	_check(_state("free_gems") == "offline", "mất mạng: cần Internet")
	_mock.online = true
	_mock.ready = true
	_check(_state("nope") == "none", "placement lạ: none")

	print("== Gem miễn phí: 2 lần/ngày, cách 12 giờ ==")
	var gems0: int = _gs.gems
	var r1 := await _watch("free_gems")
	_check(String(r1.get("status", "")) == "rewarded" and _gs.gems == gems0 + 5, "lần 1: +5 gem")
	var st: Dictionary = _ads.card_state("free_gems")
	_check(String(st["state"]) == "cooldown" and int(st["left"]) > 43000 and int(st["left"]) <= 43200, "sau lần 1: đếm ngược ~12 giờ (%d giây)" % int(st["left"]))
	_check(not _ads.shop_ready() or _state("free_driver_coupon") == "ready" or _state("free_gear_coupon") == "ready", "thẻ đang chờ không tính vào chấm đỏ")
	# Giả lập đã qua 12 giờ: lùi mốc lần xem trước.
	(_gs.ad_state["last"] as Dictionary)["free_gems"] = int(Time.get_unix_time_from_system()) - 43201
	_check(_state("free_gems") == "ready", "qua 12 giờ: sẵn sàng lần 2")
	var r2 := await _watch("free_gems")
	_check(String(r2.get("status", "")) == "rewarded" and _gs.gems == gems0 + 10, "lần 2: +5 gem nữa")
	(_gs.ad_state["last"] as Dictionary)["free_gems"] = int(Time.get_unix_time_from_system()) - 43201
	_check(_state("free_gems") == "capped", "hết 2 lần: Mai nhận tiếp")

	print("== Coupon miễn phí ==")
	var pro_before := int(_gs.driver_coupons.get("pro", 0))
	_check(_state("free_driver_coupon") == "ready", "coupon tay đua sẵn sàng")
	var r3 := await _watch("free_driver_coupon")
	_check(String(r3.get("status", "")) == "rewarded" and int(_gs.driver_coupons.get("pro", 0)) == pro_before + 1, "+1 coupon pro")
	_check(_state("free_driver_coupon") == "capped", "1 lần/ngày: hết lượt")
	var std_before := int(_gs.gear_coupons.get("standard", 0))
	var r4 := await _watch("free_gear_coupon")
	_check(String(r4.get("status", "")) == "rewarded" and int(_gs.gear_coupons.get("standard", 0)) == std_before + 1, "+1 coupon gear standard")

	print("== Chấm đỏ, khóa, thưởng chờ ==")
	_fresh()
	_check(_ads.shop_ready(), "có thẻ sẵn sàng: chấm đỏ")
	_gs.tutorial["gated"] = true
	_gs.completed_races = 0
	_check(_state("free_gems") == "locked" and not _ads.shop_ready(), "chưa mở Shop: khóa, không chấm đỏ")
	_fresh()
	_gs.simulate_write_failure = true
	var r5 := await _watch("free_gems")
	_gs.simulate_write_failure = false
	_check(String(r5.get("status", "")) == "failed" and _state("free_gems") == "pending", "xem xong lưu lỗi: thẻ 'pending'")
	_check(_ads.shop_ready(), "thưởng chờ vẫn bật chấm đỏ")
	var gems1: int = _gs.gems
	var rr := {}
	_ads.retry_pending("free_gems", func(r: Dictionary) -> void: rr.merge(r, true))
	_check(String(rr.get("status", "")) == "rewarded" and _gs.gems == gems1 + 5, "thử nhận lại: được +5 gem, không xem lại")
	_fresh()
	_gs.ad_state["free"] = true
	_mock.online = false
	_check(_state("free_gems") == "ready", "Đội tự do: nhận thẳng dù không mạng")

	print("== Trang Shop ==")
	_fresh()
	var page: VBoxContainer = (load("res://ui/shop_page.gd") as GDScript).new()
	root.add_child(page)
	await process_frame
	var view := {}
	for pl in ["free_gems", "free_driver_coupon", "free_gear_coupon"]:
		view[pl] = {"state": "ready", "left": 0, "reward": "+1 X", "entitled": false}
	page.update_ads(view)
	var b: Button = page.find_child("Ad_free_gems", true, false)
	_check(b != null and not b.disabled and b.text == "▶ +1 X", "thẻ gem: nút '%s' bấm được" % (b.text if b else "?"))
	var got := []
	page.ad_requested.connect(func(pl: String) -> void: got.append(pl))
	b.pressed.emit()
	(page.find_child("Ad_free_gear_coupon", true, false) as Button).pressed.emit()
	(page.find_child("Ad_free_driver_coupon", true, false) as Button).pressed.emit()
	_check(got == ["free_gems", "free_gear_coupon", "free_driver_coupon"], "bấm 3 thẻ phát đúng placement")
	view["free_gems"] = {"state": "cooldown", "left": 3723, "reward": "+5 gem", "entitled": false}
	view["free_gear_coupon"] = {"state": "capped", "left": 0, "reward": "+1 Coupon Gear", "entitled": false}
	view["free_driver_coupon"] = {"state": "pending", "left": 0, "reward": "+1 Coupon Pro", "entitled": false}
	page.update_ads(view)
	_check(b.disabled and b.text == "Còn 01:02:03", "đang chờ: '%s'" % b.text)
	_check((page.find_child("Ad_free_gear_coupon", true, false) as Button).text == "Mai nhận tiếp", "hết lượt: Mai nhận tiếp")
	var pend: Button = page.find_child("Ad_free_driver_coupon", true, false)
	_check(not pend.disabled and pend.text == "Thử nhận lại", "pending: Thử nhận lại, bấm được")
	view["free_gems"] = {"state": "ready", "left": 0, "reward": "+5 gem", "entitled": true}
	page.update_ads(view)
	_check(b.text == "Nhận +5 gem", "Đội tự do: chữ 'Nhận', không có biểu tượng video")

	print("== Kết thúc: %d lỗi ==" % _fails)
	quit(1 if _fails > 0 else 0)
