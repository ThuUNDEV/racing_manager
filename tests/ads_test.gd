extends SceneTree

const BigNumber = preload("res://core/math/big_number.gd")
## Chạy: godot --headless --path . -s res://tests/ads_test.gd
## Quảng cáo thưởng (Design/25 §4): thưởng một lần dù callback lặp, hủy không thưởng, kết quả luôn báo đúng một lần,
## trần ngày/cooldown, "Đội tự do" nhận thẳng, đang xem quảng cáo không tính offline, lưu lỗi không phát thưởng.

var _fails := 0
var _gs: Node
var _ads: Node
var _mock: MockAdsProvider


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


## Gọi try_show_rewarded và chờ kết quả. Trả về {calls, last}.
func _show(placement: String) -> Dictionary:
	var got := {"calls": 0, "last": {}}
	_ads.try_show_rewarded(placement, func(r: Dictionary) -> void:
		got["calls"] = int(got["calls"]) + 1
		got["last"] = r)
	for i in 30:
		await process_frame
	return got


func _fresh() -> void:
	_gs.reset_progress()
	_gs.ad_state = {}
	_gs.offline_report = {}
	_gs.last_result = {}
	_mock.online = true
	_mock.ready = true
	_mock.outcome = "rewarded"
	_mock.double_fire = false
	_mock.delay_sec = 0.0
	_gs.simulate_write_failure = false


## Cấu hình riêng cho test lõi: các kiểu thưởng cũ (v1 không khai báo placement cho chúng nhưng lõi còn dùng được).
## Cấu hình thật của v1 được kiểm trong tests/ads_v1_test.gd.
const LEGACY_CFG := {
	"schema_version": 1, "daily_cap": 8,
	"placements": {
		"offline_double": {"reward": "offline_double", "daily_limit": 0, "cooldown_sec": 0, "unlock": ""},
		"race_bonus": {"reward": "race_bonus", "daily_limit": 0, "cooldown_sec": 0, "unlock": ""},
		"daily_double": {"reward": "daily_double", "daily_limit": 1, "cooldown_sec": 0, "unlock": "U4_shop"},
		"free_gems": {"reward": "gems", "amount": 5, "daily_limit": 2, "cooldown_sec": 43200, "unlock": "U4_shop"},
	},
}


func _initialize() -> void:
	await process_frame
	GameData.set_override("ads", LEGACY_CFG)
	_gs = root.get_node("GameState")
	_ads = root.get_node("Ads")
	_mock = MockAdsProvider.new()
	_mock.tree = self
	_ads.provider = _mock
	_fresh()

	print("== Thưởng sau lượt đua ==")
	var c0: BigNumber = _gs.coins
	_check(_ads.block_reason("race_bonus") == "none", "chưa có lượt nào: không mời")
	_gs.last_result = {"race": _gs.race_counter - 1, "money": BigNumber.from_int(500)}
	_check(_ads.can_offer("race_bonus"), "có kết quả lượt vừa xong: mời được")
	_check((_ads.offer_amount("race_bonus") as BigNumber).equals(500), "số tiền mời = tiền cơ bản của lượt")
	var r := await _show("race_bonus")
	_check(r["calls"] == 1 and r["last"]["status"] == "rewarded", "xem xong: báo rewarded đúng một lần")
	_check(_gs.coins.equals(c0.add(BigNumber.from_int(500))), "cộng đúng +500")
	_check(_gs.processed_rewards.has("ad/race_bonus/n%d" % (_gs.race_counter - 1)), "ghi ID thưởng ad/race_bonus/n<lượt vừa xong>")
	_check(not _gs.ad_pause and not _ads.is_busy(), "xem xong thì bỏ tạm dừng")
	r = await _show("race_bonus")
	_check(r["last"]["status"] == "unavailable" and _ads.block_reason("race_bonus") == "claimed", "cùng lượt: không nhận lần hai")
	_check(_gs.coins.equals(c0.add(BigNumber.from_int(500))), "tiền không đổi khi bị chặn")
	_check(_ads.block_reason("race_bonus") == "claimed", "lượt kế đang đếm ngược/chờ bảng kết quả: vẫn là dịp cũ, đã nhận")
	_gs.phase = "racing"
	_check(_ads.block_reason("race_bonus") == "none", "lượt kế xuất phát: dịp cũ hết hạn")
	_gs.phase = "idle"
	_gs.race_counter += 1
	_check(_ads.block_reason("race_bonus") == "none", "đã qua thêm một lượt: kết quả cũ không còn là lượt vừa xong")
	_gs.race_counter -= 1

	print("== Lượt đua thật (không tự dựng last_result) ==")
	_fresh()
	_gs.activate()
	_gs.time_scale = 10.0
	_check(_ads.block_reason("race_bonus") == "none", "vừa vào game, chưa có lượt nào: không mời")
	var raced := 0
	while _gs.phase != "racing" and raced < 100:
		_gs.advance(0.5)
		raced += 1
	_check(_gs.phase == "racing", "xuất phát")
	_check(_ads.block_reason("race_bonus") == "none", "đang đua: không mời")
	var guard := 0
	while _gs.phase == "racing" and guard < 20000:
		_gs.advance(0.5)
		guard += 1
	var res_money: BigNumber = _gs.last_result.get("money", BigNumber.zero())
	_check(_gs.phase == "countdown" and not res_money.is_zero(), "đua xong, lưu xong, countdown lượt kế đã tạo (phase=%s)" % _gs.phase)
	_check(_ads.block_reason("race_bonus") == "", "ngay sau lượt đua thật: mời được (%s)" % _ads.block_reason("race_bonus"))
	_check((_ads.offer_amount("race_bonus") as BigNumber).equals(res_money), "số tiền mời = tiền cơ bản của lượt vừa xong")
	_gs.active = false  # không để _process cộng thu nhập theo thời gian thật trong lúc đo
	c0 = _gs.coins
	r = await _show("race_bonus")
	_check(r["last"]["status"] == "rewarded" and _gs.coins.equals(c0.add(res_money)), "xem xong: cộng đúng tiền cơ bản của lượt")
	_check(_ads.block_reason("race_bonus") == "claimed", "cùng lượt: không nhận lại")
	_gs.result_hold = false
	var t := 0
	while _gs.phase != "racing" and t < 100:
		_gs.advance(0.5)
		t += 1
	_check(_gs.phase == "racing" and _ads.block_reason("race_bonus") == "none", "lượt kế xuất phát: dịp cũ hết hạn")
	_gs.active = false
	_gs.time_scale = 1.0

	print("== Callback lặp, hủy, lỗi, mất mạng ==")
	_fresh()
	_gs.last_result = {"race": _gs.race_counter - 1, "money": BigNumber.from_int(100)}
	c0 = _gs.coins
	_mock.double_fire = true
	r = await _show("race_bonus")
	_check(r["calls"] == 1, "SDK báo kết quả hai lần: game chỉ báo một lần")
	_check(_gs.coins.equals(c0.add(BigNumber.from_int(100))), "và chỉ cộng một lần")
	_fresh()
	_gs.last_result = {"race": _gs.race_counter - 1, "money": BigNumber.from_int(100)}
	c0 = _gs.coins
	_mock.outcome = "cancelled"
	r = await _show("race_bonus")
	_check(r["calls"] == 1 and r["last"]["status"] == "cancelled", "đóng sớm: báo cancelled")
	_check(_gs.coins.equals(c0) and _ads.can_offer("race_bonus"), "không thưởng, vẫn mời lại được")
	_mock.outcome = "error"
	var loads_before := _mock.loads
	r = await _show("race_bonus")
	_check(r["last"]["status"] == "unavailable" and _mock.loads > loads_before, "lỗi hiển thị: unavailable và xin tải lại")
	_mock.outcome = "rewarded"
	_mock.ready = false
	_check(not _ads.can_offer("race_bonus"), "chưa tải xong: không hiện nút")
	var shows := _mock.shows
	r = await _show("race_bonus")
	_check(r["calls"] == 1 and r["last"]["status"] == "unavailable" and _mock.shows == shows, "chưa tải: báo unavailable, không mở quảng cáo")
	_mock.ready = true
	_mock.online = false
	r = await _show("race_bonus")
	_check(r["last"]["status"] == "no_network" and _gs.coins.equals(c0), "mất mạng: no_network, không thưởng")

	print("== Quay lại: gấp đôi offline ==")
	_fresh()
	c0 = _gs.coins
	_gs.offline_report = {"elapsed": 900.0, "reward": BigNumber.from_int(300)}
	_check(_ads.can_offer("offline_double"), "có báo cáo offline: mời được")
	r = await _show("offline_double")
	_check(r["last"]["status"] == "rewarded" and _gs.coins.equals(c0.add(BigNumber.from_int(300))), "cộng thêm đúng phần offline")
	_check(_ads.block_reason("offline_double") == "claimed", "cùng lần quay lại: không nhận lần hai")
	_gs.offline_report = {"elapsed": 900.0, "reward": BigNumber.zero()}
	_check(_ads.block_reason("offline_double") == "none", "offline 0: không mời")

	print("== Quà ngày ×2 ==")
	_fresh()
	_check(_ads.block_reason("daily_double") == "none", "chưa nhận quà ngày: không mời (phần cơ bản trước)")
	_check(_gs.claim_daily(), "nhận quà ngày cơ bản")
	c0 = _gs.coins
	var gift: BigNumber = _gs.daily_gift_amount()
	r = await _show("daily_double")
	_check(r["last"]["status"] == "rewarded" and _gs.coins.equals(c0.add(gift)), "cộng thêm đúng một phần quà ngày")
	_check(_ads.block_reason("daily_double") == "claimed", "mỗi ngày một lần")

	print("== Gem miễn phí: cooldown, giới hạn, trần ngày ==")
	_fresh()
	var g0: int = _gs.gems
	r = await _show("free_gems")
	_check(r["last"]["status"] == "rewarded" and _gs.gems == g0 + 5, "cộng 5 gem")
	_check(_ads.block_reason("free_gems") == "cooldown" and _ads.cooldown_left("free_gems") > 43000, "sau đó chờ 12 giờ")
	r = await _show("free_gems")
	_check(r["last"]["status"] == "capped" and _gs.gems == g0 + 5, "đang cooldown: capped, không cộng")
	(_gs.ad_state["last"] as Dictionary)["free_gems"] = 0
	r = await _show("free_gems")
	_check(r["last"]["status"] == "rewarded" and _ads.remaining_today("free_gems") == 0, "lượt 2/2 trong ngày")
	(_gs.ad_state["last"] as Dictionary)["free_gems"] = 0
	_check(_ads.block_reason("free_gems") == "capped", "hết giới hạn ngày của placement")
	_fresh()
	_gs.ad_state = {"day": int(floor(Time.get_unix_time_from_system() / 86400.0)), "count": 8, "by": {}, "last": {}}
	_gs.last_result = {"race": _gs.race_counter - 1, "money": BigNumber.from_int(100)}
	_check(_ads.block_reason("race_bonus") == "capped", "đủ 8 quảng cáo/ngày: mọi placement bị chặn")
	_gs.ad_state["day"] = int(_gs.ad_state["day"]) - 1
	_check(_ads.block_reason("race_bonus") == "", "qua ngày UTC: đếm lại")

	print("== Đội tự do: nhận thẳng ==")
	_fresh()
	_gs.ad_state = {"free": true}
	_gs.last_result = {"race": _gs.race_counter - 1, "money": BigNumber.from_int(200)}
	c0 = _gs.coins
	_mock.ready = false
	shows = _mock.shows
	_check(_ads.can_offer("race_bonus"), "không có quảng cáo vẫn mời được")
	r = await _show("race_bonus")
	_check(r["last"]["status"] == "skipped_entitled" and _mock.shows == shows, "nhận thẳng, không mở quảng cáo")
	_check(_gs.coins.equals(c0.add(BigNumber.from_int(200))), "thưởng như khi xem")

	print("== Đang xem quảng cáo: không tính offline ==")
	_fresh()
	_gs.last_result = {"race": _gs.race_counter - 1, "money": BigNumber.from_int(100)}
	_mock.delay_sec = 3.0  # đủ dài để không phụ thuộc tốc độ khung hình khi máy đang tải
	var got := {"calls": 0}
	_ads.try_show_rewarded("race_bonus", func(_r: Dictionary) -> void: got["calls"] = int(got["calls"]) + 1)
	await process_frame
	_check(_gs.ad_pause and _ads.is_busy(), "đang hiện quảng cáo: GameState tạm dừng")
	var busy := await _show("race_bonus")
	_check(busy["last"]["status"] == "busy", "yêu cầu thứ hai khi đang bận: busy")
	_gs.set_suspended(true)
	_check(not _gs.suspended, "ra nền vì quảng cáo: không chuyển sang suspended")
	_gs.offline_report = {}
	_gs.set_suspended(false)
	_check(_gs.offline_report.is_empty(), "vào lại: không chạy settle_offline")
	await create_timer(4.0).timeout
	_check(got["calls"] == 1 and not _gs.ad_pause, "quảng cáo đóng: bỏ tạm dừng")

	print("== Lưu lỗi, lưu/nạp ==")
	_fresh()
	_gs.last_result = {"race": _gs.race_counter - 1, "money": BigNumber.from_int(100)}
	c0 = _gs.coins
	_gs.simulate_write_failure = true
	r = await _show("race_bonus")
	_check(r["last"]["status"] == "failed" and _gs.coins.equals(c0), "không lưu được: failed, không cộng tiền")
	_check(not _gs.processed_rewards.has(r["last"]["reward_id"]) and int(_gs.ad_state.get("count", 0)) == 0, "không ghi ID, không trừ lượt")
	_gs.simulate_write_failure = false
	r = await _show("race_bonus")
	_check(r["last"]["status"] == "rewarded", "lưu được lại thì nhận bình thường")
	var count: int = int(_gs.ad_state["count"])
	var rid: String = r["last"]["reward_id"]
	_gs.ad_state = {}
	_gs.processed_rewards = {}
	var err: String = _gs.load_game()
	_check(err == "ok", "nạp lại save không lỗi (%s)" % err)
	_check(count == 1 and int(_gs.ad_state.get("count", -1)) == count and _gs.processed_rewards.has(rid), "lượt đã dùng và ID thưởng còn sau khi nạp")
	_gs.last_result = {"race": _gs.race_counter - 1, "money": BigNumber.from_int(100)}
	_check(_ads.block_reason("race_bonus") == "claimed", "sau khi nạp vẫn không nhận lại cùng lượt")

	_gs.reset_progress()
	print("")
	print("THẤT BẠI: %d" % _fails if _fails > 0 else "TẤT CẢ ĐẠT")
	quit(1 if _fails > 0 else 0)
