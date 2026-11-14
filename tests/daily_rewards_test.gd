extends SceneTree

## Chạy: godot --headless --path . -s res://tests/daily_rewards_test.gd
## Thưởng đăng nhập hằng ngày (Design/30 §10, P0): dữ liệu hợp lệ, vòng 7 ngày, Grand xoay, mốc mỗi 10 ngày, bỏ ngày giữ tiến trình,
## một lần/ngày UTC, chống lùi giờ, mở khóa sau U5_drivers, x2 chỉ nhân gem, save/load, lỗi lưu hoàn tác, save cũ.

var _fails := 0
var _gs: Node
const D0 := 20000  # ngày UTC làm gốc cho test


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


## Đặt giờ máy vào ngày UTC `day`, lúc `sec` giây trong ngày.
func _at(day: int, sec: float = 3600.0) -> void:
	_gs.daily_device_unix = float(day) * 86400.0 + sec


func _fresh() -> void:
	_gs.init_new_game()
	_gs.simulate_write_failure = false
	_gs.save_blocked = false
	_gs.daily_server_unix = -1.0
	_at(D0)
	_gs.daily_reward_refresh()  # không gated: mở khóa ngay


func _sum_coupons(r: Dictionary, key: String) -> int:
	var n := 0
	for k in (r[key] as Dictionary):
		n += int(r[key][k])
	return n


func _initialize() -> void:
	await process_frame
	GameData.reload()
	_gs = root.get_node("GameState")
	_gs.SAVE_PATH = "user://daily_rewards_test_save.json"  # không đụng save thật
	_gs.BAK_PATH = "user://daily_rewards_test_save.bak"
	_gs.TMP_PATH = "user://daily_rewards_test_save.tmp"
	_fresh()

	print("== Dữ liệu ==")
	_check(GameData.validate().is_empty(), "validate() không lỗi: %s" % str(GameData.validate()))
	var c := GameData.daily_rewards()
	_check((c["cycle"] as Array).size() == 6 and (c["grand"] as Array).size() == 7 and (c["milestones"] as Array).size() == 3, "6 ô thường, 7 vòng Grand, 3 bậc mốc")
	_check(int(c["milestone_interval"]) == 10 and String(c["unlock"]) == "U5_drivers", "mốc mỗi 10 ngày, mở khóa U5_drivers")
	for bad: Dictionary in [
		{"cycle": [{"gems": 0}]}, {"cycle": [{"driver_coupon": {"ghost": 1}}]}, {"cycle": [{}]}, {"cycle": [{"lol": 1}]},
		{"milestone_interval": 0}, {"gem_scale": 0}, {"unlock": "U99_x"}, {"grand": [{"gems": 5}]},
	]:
		var broken: Dictionary = c.duplicate(true)
		for k in bad:
			broken[k] = bad[k]
		GameData.set_override("daily_rewards", broken)
		_check(not GameData._validate_daily_rewards().is_empty(), "data lỗi bị bắt: %s" % str(bad))
	GameData.reload()

	print("== Bảng thưởng (Design/30 §3, §4) ==")
	var s := DailyRewards.default_state()
	var expect_gems := [0, 0, 15, 0, 0, 20]
	for i in 6:
		var r := DailyRewards.slot_reward(i, 0)
		_check(int(r["gems"]) == expect_gems[i] and not r["grand"], "ô ngày %d: %d gem" % [i + 1, expect_gems[i]])
	_check(DailyRewards.slot_reward(0, 0)["driver_coupon"] == {"pro": 2} and DailyRewards.slot_reward(1, 0)["gear_coupon"] == {"standard": 2}, "ngày 1 = 2 Pro, ngày 2 = 2 Standard")
	_check(DailyRewards.slot_reward(3, 0)["driver_coupon"] == {"allstar": 1} and DailyRewards.slot_reward(4, 0)["gear_coupon"] == {"elite": 1}, "ngày 4 = 1 All-Star, ngày 5 = 1 Elite")
	var g6 := DailyRewards.slot_reward(6, 6)
	_check(g6["grand"] and int(g6["gems"]) == 50 and g6["driver_coupon"] == {"allstar": 4} and g6["gear_coupon"] == {"elite": 2}, "Grand vòng 6 = 4 All-Star + 2 Elite + 50 gem")
	_check(DailyRewards.slot_reward(6, 7) == DailyRewards.slot_reward(6, 0), "ordinal 7 quay lại vòng 0")
	_check(int(DailyRewards.milestone_reward(1)["gems"]) == 40 and DailyRewards.milestone_reward(2)["driver_coupon"] == {"allstar": 2}, "mốc 1 = 40 gem, mốc 2 = 2 All-Star")
	_check(int(DailyRewards.milestone_reward(3)["gems"]) == 80 and DailyRewards.milestone_reward(3)["driver_coupon"] == {"allstar": 2}, "mốc 3 = 80 gem + 2 All-Star")
	_check(DailyRewards.milestone_reward(4) == DailyRewards.milestone_reward(1), "mốc 4 quay lại bậc 1")

	print("== Vòng lặp thuần ==")
	var st := DailyRewards.unlock(s, D0)
	var seen: Array = []
	var day := D0
	for i in 14:
		_check(DailyRewards.can_claim(st, day), "ngày %d: nhận được" % (i + 1))
		seen.append(DailyRewards.next_reward(st))
		st = DailyRewards.apply_claim(st, day)
		_check(not DailyRewards.can_claim(st, day), "ngày %d: nhận xong thì hết nhận trong ngày" % (i + 1))
		day += 1
	_check(int(st["total_days"]) == 14 and int(st["cycle_day"]) == 0 and int(st["grand_ordinal"]) == 2, "sau 14 ngày: cycle_day 0, grand_ordinal 2")
	_check(seen[6]["grand"] and seen[13]["grand"] and not seen[5]["grand"], "ngày 7 và 14 là Grand")
	_check(seen[13]["gear_coupon"] == {"elite": 2} and seen[6]["driver_coupon"] == {"allstar": 2}, "vòng 0 = 2 All-Star + 30, vòng 1 = 2 Elite + 30")

	print("== Mốc ==")
	var m := DailyRewards.unlock(DailyRewards.default_state(), D0)
	var d2 := D0
	var milestone_days: Array = []
	for i in 31:
		var r2 := DailyRewards.next_reward(m)
		if int(r2["milestone"]) > 0:
			milestone_days.append(int(m["total_days"]) + 1)
		m = DailyRewards.apply_claim(m, d2)
		d2 += 1
	_check(milestone_days == [10, 20, 30], "mốc chạm ở ngày nhận 10, 20, 30: %s" % str(milestone_days))
	_check(int(m["claimed_milestones"]) == 3, "claimed_milestones = 3")
	var win := DailyRewards.milestone_window(DailyRewards.default_state())
	_check(win.size() == 4 and win[0]["state"] == "next" and win[3]["day"] == 40, "cửa sổ khi chưa nhận: 4 mốc 10..40, mốc đầu là 'next'")
	win = DailyRewards.milestone_window(m)
	_check(win.size() == 4 and win[0]["state"] == "claimed" and win[0]["day"] == 30 and win[1]["state"] == "next" and win[2]["state"] == "locked", "sau mốc 3: giữ mốc 30 đã nhận, mốc 40 'next', 50, 60 khóa")
	_check(DailyRewards.days_to_next_milestone(DailyRewards.default_state()) == 10 and DailyRewards.days_to_next_milestone(m) == 9, "đếm ngược tới mốc kế")
	var ten := DailyRewards.next_reward({"cycle_day": 2, "grand_ordinal": 0, "total_days": 9})
	_check(int(ten["gems"]) == 15 + 40 and int(ten["milestone"]) == 1, "ô thường trùng mốc: cộng cả hai (15 + 40 gem)")

	print("== Trên GameState: nhận cơ bản ==")
	_fresh()
	_check(_gs.daily_rewards["unlocked_day"] == D0 and _gs.daily_reward_available(), "mới chơi (không gated): mở khóa ngày D0, nhận được")
	var gems0: int = _gs.gems
	var pro0: int = int(_gs.driver_coupons["pro"])
	_check(_gs.claim_daily_reward(), "nhận ngày 1")
	_check(int(_gs.driver_coupons["pro"]) == pro0 + 2 and _gs.gems == gems0, "ngày 1 = +2 Pro, gem không đổi")
	_check(not _gs.claim_daily_reward() and not _gs.daily_reward_available(), "nhận lần hai cùng ngày bị từ chối")
	_at(D0, 86399.0)
	_check(not _gs.daily_reward_available(), "23:59:59 UTC vẫn cùng ngày")
	_at(D0 + 1, 0.0)
	_check(_gs.daily_reward_available(), "00:00:00 UTC ngày sau: nhận lại được")
	var gear0: int = int(_gs.gear_coupons["standard"])
	_check(_gs.claim_daily_reward() and int(_gs.gear_coupons["standard"]) == gear0 + 2, "ngày 2 = +2 Standard Gear")
	_check(_gs.last_daily_reward["slot"] == 1 and not _gs.last_daily_reward["x2"], "last_daily_reward ghi ô vừa nhận")

	print("== Bỏ lỡ ngày giữ tiến trình (R1) ==")
	_fresh()
	_gs.claim_daily_reward()
	_at(D0 + 40)
	_check(_gs.daily_reward_available() and int(_gs.daily_rewards["cycle_day"]) == 1, "bỏ 39 ngày: vẫn ô ngày 2")
	var gear1: int = int(_gs.gear_coupons["standard"])
	_gs.claim_daily_reward()
	_check(int(_gs.gear_coupons["standard"]) == gear1 + 2 and int(_gs.daily_rewards["total_days"]) == 2, "nhận ô ngày 2, không nhận bù, total_days = 2")
	_check(not _gs.claim_daily_reward(), "không nhận hai ô trong cùng một ngày sau khi bỏ lỡ")

	print("== Gem, x2 ==")
	_fresh()
	_gs.daily_rewards["cycle_day"] = 2
	var gem2: int = _gs.gems
	_check(_gs.claim_daily_reward(true) and _gs.gems == gem2 + 30 and _gs.last_daily_reward["x2"], "x2 ở ngày 3: 15 gem thành 30")
	_at(D0 + 1)
	_gs.daily_rewards["cycle_day"] = 0
	var pro1: int = int(_gs.driver_coupons["pro"])
	var gem3: int = _gs.gems
	_check(_gs.claim_daily_reward(true) and int(_gs.driver_coupons["pro"]) == pro1 + 2 and _gs.gems == gem3 and not _gs.last_daily_reward["x2"], "x2 ở ô coupon: không nhân coupon, không tính x2")
	GameData.set_override("daily_rewards", _with_flag(false))
	_at(D0 + 2)
	_gs.daily_rewards["cycle_day"] = 2
	var gem4: int = _gs.gems
	_check(_gs.claim_daily_reward(true) and _gs.gems == gem4 + 15 and not _gs.last_daily_reward["x2"], "cờ x2_enabled tắt: chỉ nhận thường")
	var scaled: Dictionary = GameData.daily_rewards().duplicate(true)
	scaled["gem_scale"] = 2.0
	GameData.set_override("daily_rewards", scaled)
	_check(int(DailyRewards.slot_reward(2, 0)["gems"]) == 30 and int(DailyRewards.slot_reward(0, 0)["gems"]) == 0, "gem_scale 2.0 nhân phần gem, không đụng coupon")
	scaled["gem_scale"] = 0.01
	GameData.set_override("daily_rewards", scaled)
	_check(int(DailyRewards.slot_reward(2, 0)["gems"]) == 1, "gem_scale nhỏ: thưởng gem không về 0")
	var off: Dictionary = GameData.daily_rewards().duplicate(true)
	off["flags"] = {"enabled": false}
	GameData.set_override("daily_rewards", off)
	_at(D0 + 3)
	_check(not _gs.daily_reward_available() and not _gs.claim_daily_reward(), "cờ enabled tắt: không nhận")
	GameData.reload()

	print("== Chống lùi giờ ==")
	_fresh()
	_gs.claim_daily_reward()
	_at(D0 + 5)
	_gs.daily_reward_refresh()
	_at(D0 - 10)
	_check(_gs.daily_reward_today() == D0 + 5, "giờ máy lùi: ngày không lùi (max_seen_day)")
	_check(_gs.daily_reward_available(), "lùi giờ không làm mất quyền nhận ở ngày đã thấy")
	_gs.claim_daily_reward()
	_check(not _gs.claim_daily_reward(), "lùi giờ không cho nhận lần hai")
	_gs.daily_server_unix = float(D0 + 8) * 86400.0 + 5.0
	_check(_gs.daily_reward_today() == D0 + 8, "có giờ server: lấy ngày lớn nhất")
	_gs.daily_server_unix = float(D0) * 86400.0
	_check(_gs.daily_reward_today() == D0 + 5, "server cũ hơn máy: không lùi")
	_gs.daily_server_unix = -1.0
	_check(is_equal_approx(DailyRewards.seconds_until_reset(float(D0) * 86400.0 + 3600.0), 82800.0), "đếm ngược 01:00 UTC còn 23 giờ")
	_check(is_equal_approx(DailyRewards.seconds_until_reset(float(D0) * 86400.0), 86400.0), "đúng 00:00 UTC còn 24 giờ")

	print("== Mở khóa sau U5_drivers ==")
	_gs.init_new_game()
	_gs.tutorial["gated"] = true
	_gs.completed_races = 4
	_at(D0)
	_gs.daily_reward_refresh()
	_check(not DailyRewards.is_unlocked(_gs.daily_rewards), "trước lượt 5: chưa mở khóa")
	_check(not _gs.daily_reward_available() and not _gs.claim_daily_reward(), "trước lượt 5: không nhận được")
	_gs.completed_races = 5
	_at(D0 + 3)
	_check(_gs.daily_reward_refresh() and _gs.daily_rewards["unlocked_day"] == D0 + 3, "đủ 5 lượt: mở khóa tại ngày hiện tại")
	_check(_gs.daily_reward_available() and int(_gs.daily_rewards["cycle_day"]) == 0, "ngày mở khóa là ngày 1, nhận được ngay")
	_gs.claim_daily_reward()
	_at(D0 + 20)
	_gs.daily_reward_refresh()
	_check(_gs.daily_rewards["unlocked_day"] == D0 + 3, "mở khóa chỉ ghi một lần")

	print("== Popup tự bật (R4) ==")
	_fresh()
	var td: int = _gs.daily_reward_today()
	_check(DailyRewards.should_auto_popup(_gs.daily_rewards, td), "còn thưởng, chưa bật hôm nay: bật")
	_gs.daily_reward_popup_shown()
	_check(not DailyRewards.should_auto_popup(_gs.daily_rewards, td), "đã bật hôm nay: không bật lại dù chưa nhận")
	_check(_gs.daily_reward_available(), "đóng popup không làm mất quyền nhận")
	_at(D0 + 1)
	_check(DailyRewards.should_auto_popup(_gs.daily_rewards, _gs.daily_reward_today()), "ngày sau: bật lại")
	_gs.claim_daily_reward()
	_check(not DailyRewards.should_auto_popup(_gs.daily_rewards, _gs.daily_reward_today()), "đã nhận: không bật")

	print("== Save/load ==")
	_fresh()
	for i in 10:
		_at(D0 + i)
		_gs.claim_daily_reward()
	var snap: Dictionary = _gs.daily_rewards.duplicate(true)
	_check(int(snap["total_days"]) == 10 and int(snap["claimed_milestones"]) == 1 and int(snap["cycle_day"]) == 3, "10 ngày: total 10, mốc 1, cycle_day 3")
	_check(_gs.load_game() == "ok" and _gs.daily_rewards == snap, "state sống sót qua save/load")
	_check(int(_gs._save_data()["schema_version"]) == _gs.SAVE_VERSION and _gs.SAVE_VERSION >= 13, "schema_version >= 13")
	var data: Dictionary = _gs._save_data()
	data.erase("daily_rewards")
	_gs._apply(MoneyCodec.encode(data))
	_check(_gs.daily_rewards == DailyRewards.default_state(), "save cũ không có khối daily_rewards: mặc định")
	var junk := {"unlocked_day": "x", "last_claim_day": 1.0e30, "cycle_day": 99, "grand_ordinal": -4, "total_days": -5, "claimed_milestones": 50, "popup_shown_day": null, "max_seen_day": [1]}
	var clean := DailyRewards.sanitize(junk)
	_check(clean["cycle_day"] == 6 and clean["grand_ordinal"] == 0 and clean["total_days"] == 0 and clean["claimed_milestones"] == 0 and clean["unlocked_day"] == 0 and clean["max_seen_day"] == 0, "sanitize chặn giá trị sai kiểu/ngoài biên")
	_check(DailyRewards.sanitize("rác") == DailyRewards.default_state() and DailyRewards.sanitize(null) == DailyRewards.default_state(), "sanitize không phải object: mặc định")
	var bad_save: Dictionary = _gs._save_data()
	bad_save["daily_rewards"] = "oops"
	_check(not _gs._valid_save(MoneyCodec.encode(bad_save)), "save có daily_rewards sai kiểu bị từ chối")

	print("== Lỗi lưu hoàn tác ==")
	_fresh()
	var before_state: Dictionary = _gs.daily_rewards.duplicate(true)
	var before_gems: int = _gs.gems
	var before_pro: int = int(_gs.driver_coupons["pro"])
	_gs.simulate_write_failure = true
	_check(not _gs.claim_daily_reward(), "ghi lỗi: nhận thất bại")
	_gs.simulate_write_failure = false
	_check(_gs.daily_rewards == before_state and _gs.gems == before_gems and int(_gs.driver_coupons["pro"]) == before_pro, "ghi lỗi: không mất ngày, không cộng thưởng")
	_check(_gs.claim_daily_reward(), "ghi lại được sau khi hết lỗi")
	_gs.save_blocked = true
	_at(D0 + 1)
	_check(not _gs.claim_daily_reward() and not _gs.daily_reward_refresh(), "save bị khóa: không nhận, không đổi state")
	_gs.save_blocked = false

	print("== Vòng đầy đủ 49 ngày trên GameState ==")
	_fresh()
	var total_gems := 0
	var total_all := 0
	for i in 49:
		_at(D0 + i)
		var gb: int = _gs.gems
		var ab: int = int(_gs.driver_coupons["allstar"])
		var ok: bool = _gs.claim_daily_reward()
		if not ok:
			_check(false, "ngày %d nhận được" % (i + 1))
		total_gems += _gs.gems - gb
		total_all += int(_gs.driver_coupons["allstar"]) - ab
	_check(int(_gs.daily_rewards["total_days"]) == 49 and int(_gs.daily_rewards["grand_ordinal"]) == 0 and int(_gs.daily_rewards["cycle_day"]) == 0, "49 ngày = 7 vòng: ordinal quay về 0")
	_check(int(_gs.daily_rewards["claimed_milestones"]) == 4, "49 ngày: 4 mốc (10, 20, 30, 40)")
	var expect_g := 7 * 35 + (30 + 30 + 80 + 0 + 0 + 0 + 50) + (40 + 0 + 80 + 40)
	_check(total_gems == expect_g, "tổng gem 49 ngày = %d (có %d)" % [expect_g, total_gems])

	print("")
	if _fails == 0:
		print("DAILY REWARDS TEST: ĐẠT")
	else:
		print("DAILY REWARDS TEST: %d lỗi" % _fails)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://daily_rewards_test_save.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://daily_rewards_test_save.bak"))
	quit(1 if _fails > 0 else 0)


func _with_flag(x2: bool) -> Dictionary:
	var d: Dictionary = GameData.daily_rewards().duplicate(true)
	d["flags"] = {"enabled": true, "x2_enabled": x2}
	return d
