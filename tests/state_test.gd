extends SceneTree

const BigNumber = preload("res://core/math/big_number.gd")
## Chạy: godot --headless --path . -s res://tests/state_test.gd
## Kiểm tra giao dịch, khóa nâng cấp khi đua, thưởng không phát trùng và chốt mùa.

var _fails := 0


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _initialize() -> void:
	await process_frame
	var gs: Node = root.get_node("GameState")
	gs.reset_progress()

	print("== Nâng cấp ==")
	_check(gs.coins.equals(1000), "khởi tạo 1.000 tiền")
	_check(gs.buy("engine"), "mua Động cơ lần 1")
	_check(gs.coins.equals(880) and gs.level_of("engine") == 1, "còn 880 tiền, động cơ cấp 1 (onboarding)")
	gs.coins = BigNumber.from_int(10)
	_check(not gs.buy("tyre") and gs.coins.equals(10), "thiếu tiền: không trừ, không tăng cấp")
	_check(gs.upgrade_state("tyre") == "short", "trạng thái 'short'")
	gs.coins = BigNumber.from_int(100000)
	var rate_before: BigNumber = gs.online_rate()
	_check(gs.buy("ticket") and gs.online_rate().equals("10.5"), "Ticket Marketing cấp 1 => 10,5/giây")
	_check(gs.online_rate().compare(rate_before) > 0, "rate tăng")

	print("== Vòng lặp tự chạy: countdown 3 giây ==")
	gs.activate()
	_check(gs.phase == "countdown" and is_equal_approx(gs.countdown_left, 3.0), "vào gameplay tự countdown 3 giây")
	var started := [0]
	gs.race_started.connect(func() -> void: started[0] += 1)
	for i in 29:
		gs.advance(0.1)
	_check(gs.phase == "countdown" and started[0] == 0, "2,9 giây: chưa xuất phát")
	var s0: float = gs.sim.cars[0].s
	gs.time_scale = 4.0  # tua nhanh không rút ngắn countdown
	gs.advance(0.1)
	_check(gs.phase == "racing" and started[0] == 1, "đủ 3 giây: xuất phát đúng một lần (x4 vẫn 3 giây)")
	_check(is_equal_approx(gs.sim.cars[0].s, s0) and gs.sim.time == 0.0, "đồng hồ đua bắt đầu từ 0 sau countdown")
	gs.time_scale = 1.0
	_check(is_equal_approx(gs.sim.duration, Balance.race_duration(GameState.PROTOTYPE_TRACK)), "lượt dài đúng cấu hình (%.0f giây)" % Balance.race_duration(GameState.PROTOTYPE_TRACK))

	print("== Nâng cấp trong lúc đua: snapshot, áp dụng lượt sau ==")
	var snap_before: float = gs.race_snapshot["stats"]["S"]
	gs.coins = BigNumber.from_int(100000)
	_check(gs.upgrade_state("engine") == "ok" and gs.applies_next_race("engine") and not gs.applies_next_race("ticket"), "nâng xe luôn được; chỉ áp dụng lượt sau")
	_check(gs.buy("engine"), "mua Động cơ giữa cuộc đua")
	_check(is_equal_approx(float(gs.race_snapshot["stats"]["S"]), snap_before), "snapshot lượt đang đua không đổi")

	print("== Hết giờ: chốt kết quả, thưởng một lần, countdown kế tiếp ==")
	var finished := [0]
	gs.race_finished.connect(func(_r: Dictionary) -> void: finished[0] += 1)
	var coins0: BigNumber = gs.coins
	var guard := 0
	while gs.phase == "racing" and guard < 2000:
		gs.advance(0.1)
		guard += 1
	_check(finished[0] == 1 and gs.phase == "countdown", "hết giờ => 1 kết quả, tự countdown lượt kế")
	_check(gs.stage_index == 1 and gs.season_results.size() == 1, "sang chặng 2")
	_check(gs.coins.equals(coins0.add(gs.last_result["money"])), "cộng đúng tiền thưởng chặng, một lần")
	_check(gs.last_result.has("distance") and gs.last_result["rows"].size() == 8, "kết quả có quãng đường, 8 hàng")
	_check(is_equal_approx(gs.countdown_left, 3.0), "countdown mới 3 giây")
	_check(gs.processed_rewards.has("race/s1/st1"), "đã ghi reward id chặng 1")
	var pre_preview: TrafficSim = gs.sim
	gs.coins = BigNumber.from_int(100000)
	gs.buy("tyre")
	_check(gs.sim != pre_preview, "nâng cấp trong countdown cập nhật grid xem trước")
	_check(gs.upgrade_state("engine") != "locked", "không còn khóa nâng cấp")

	print("== Lỗi lưu: giữ giao dịch, không phát thưởng lại, không tạo lượt mới ==")
	gs.simulate_write_failure = true
	var coins1: BigNumber = gs.coins
	var fin_before: int = finished[0]
	for i in 30:
		gs.advance(0.1)
	guard = 0
	while gs.phase == "racing" and guard < 2000:
		gs.advance(0.1)
		guard += 1
	_check(gs.phase == "save_error", "lưu thất bại => dừng ở save_error")
	var coins_after_fail: BigNumber = gs.coins
	var stage_after_fail: int = gs.stage_index
	for i in 100:
		gs.advance(0.1)  # tự thử lại nhưng vẫn lỗi
	_check(gs.phase == "save_error" and gs.coins.equals(coins_after_fail) and gs.stage_index == stage_after_fail, "thử lại khi còn lỗi: không đổi thưởng/chặng")
	_check(finished[0] == fin_before, "chưa publish kết quả khi save lỗi")
	gs.simulate_write_failure = false
	_check(gs.retry_save() and gs.phase == "countdown", "thử lại thành công => countdown")
	_check(gs.coins.compare(coins_after_fail) > 0 and gs.stage_index == stage_after_fail + 1, "commit đúng một lần sau khi thử lại")
	_check(gs.coins.compare(coins1) > 0, "thưởng chặng chỉ commit sau khi lưu được")

	print("== Chạy liên tục hai mùa không cần chạm UI ==")
	var res_count := [0]
	var comp := [0]
	var season0: int = gs.season_number
	gs.race_finished.connect(func(r: Dictionary) -> void:
		res_count[0] += 1
		if bool(r.get("season_done", false)):
			comp[0] += 1)
	var races_target := 10
	guard = 0
	while res_count[0] < races_target and guard < 100000:
		gs.advance(0.5)
		guard += 1
	_check(res_count[0] == 10 and comp[0] == 2, "10 kết quả, 2 thưởng hoàn tất mùa (%d, %d)" % [res_count[0], comp[0]])
	_check(gs.season_number >= season0 + 2 and gs.phase == "countdown", "tự chuyển mùa, không cần nút")
	_check(not gs.last_season.is_empty() and gs.last_season["completion_reward"].compare(BigNumber.zero()) > 0, "tổng kết mùa lưu để xem lại, thưởng hoàn tất theo exposure")
	var cnt := 0
	for k in gs.processed_rewards.keys():
		if String(k).begins_with("season/") and String(k).ends_with("/completion"):
			cnt += 1
	_check(cnt >= 2, "mỗi mùa đúng một thưởng hoàn tất")

	print("== Ra nền / checkpoint ==")
	gs.reset_progress()
	gs.begin_countdown()
	gs.advance(1.2)
	var left_before: float = gs.countdown_left
	gs.set_suspended(true)
	gs.advance(5.0)
	_check(is_equal_approx(gs.countdown_left, left_before) and gs.phase == "countdown", "ra nền: countdown không chạy")
	gs.set_suspended(false)
	gs.advance(1.5)
	_check(gs.phase == "countdown" and absf(gs.countdown_left - (left_before - 1.5)) < 0.001, "quay lại: tiếp tục phần còn lại")
	gs.advance(left_before - 1.5 + 0.01)
	_check(gs.phase == "racing", "hết countdown mới xuất phát")
	for i in 250:
		gs.advance(0.1)
	var tick_saved: int = gs.sim.tick_count
	var pos_saved: float = gs.sim.cars[3].s
	_check(gs.save_game(), "lưu checkpoint giữa đua")
	gs.init_new_game()
	gs.load_game()
	gs.active = false
	gs.activate()
	_check(gs.phase == "racing" and gs.sim.tick_count == tick_saved and is_equal_approx(gs.sim.cars[3].s, pos_saved), "khôi phục đua: cùng tick (%d) và cùng vị trí xe" % tick_saved)
	_check(gs.stage_index == 0, "không sinh kết quả/thưởng cho phần đua dở")
	gs.advance(0.1)

	print("== FPS khác nhau cho cùng kết quả ==")
	var runs: Array = []
	for step_dt in [1.0 / 60.0, 0.37, 0.05]:
		gs.reset_progress()
		gs.begin_countdown()
		var fin := [{}]
		var cb := func(r: Dictionary) -> void: fin[0] = r
		gs.race_finished.connect(cb)
		var g2 := 0
		while fin[0].is_empty() and g2 < 100000:
			gs.advance(step_dt)
			g2 += 1
		gs.race_finished.disconnect(cb)
		runs.append(fin[0])
	var same_fps := true
	for r in runs:
		for i in 8:
			if not is_equal_approx(float(r["rows"][i]["distance"]), float(runs[0]["rows"][i]["distance"])) or r["rows"][i]["id"] != runs[0]["rows"][i]["id"]:
				same_fps = false
	_check(same_fps, "cùng seed + snapshot + cấu hình => cùng kết quả ở 60 FPS / 2,7 FPS / 20 FPS")

	print("== Quà ngày ==")
	gs.last_daily_day = -1
	var c0: BigNumber = gs.coins
	_check(gs.claim_daily() and gs.coins.equals(c0.add(Pricing.daily_gift(gs.online_rate()))), "nhận quà theo 600 giây thu nhập")
	_check(not gs.claim_daily(), "không nhận lần hai trong ngày")

	print("== Offline ==")
	gs.coins = BigNumber.from_int(0)
	gs.saved_online_rate = BigNumber.from_int(8)
	gs.last_accrual_utc = Time.get_unix_time_from_system() - 3600.0
	gs.settle_offline()
	_check(gs.coins.compare(BigNumber.from_int(14400)) >= 0 and gs.coins.compare(BigNumber.from_int(14410)) <= 0, "vắng 1 giờ ở 8/giây => ≈14.400")
	gs.coins = BigNumber.from_int(0)
	gs.last_accrual_utc = Time.get_unix_time_from_system() - 8 * 3600.0
	gs.settle_offline()
	_check(gs.coins.compare(BigNumber.from_int(28800)) >= 0 and gs.coins.compare(BigNumber.from_int(28810)) <= 0, "vắng 8 giờ => trần 28.800")
	gs.coins = BigNumber.from_int(5)
	gs.last_accrual_utc = Time.get_unix_time_from_system() + 5000.0
	gs.settle_offline()
	_check(gs.coins.equals(5) and gs.offline_report.is_empty(), "giờ lùi => 0, không âm, không panel")

	gs.reset_progress()
	print("== Kết thúc: %d lỗi ==" % _fails)
	quit(1 if _fails > 0 else 0)
