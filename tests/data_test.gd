extends SceneTree

const BigNumber = preload("res://core/math/big_number.gd")
## Chạy: godot --headless --path . -s res://tests/data_test.gd
## Kiểm tra dữ liệu cấu hình và công thức kinh tế (khớp Design/05 §3).

var _fails := 0


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _initialize() -> void:
	print("== Dữ liệu hợp lệ ==")
	var errs := GameData.validate()
	for e in errs:
		print("  lỗi: ", e)
	_check(errs.is_empty(), "validate() không có lỗi (%d)" % errs.size())

	print("== Hằng số cấu trúc khớp sim.json ==")
	var sm := GameData.sim()
	_check(int(sm["laps"]) == Balance.LAPS, "laps")
	_check(is_equal_approx(float(sm["lap_length"]), Balance.LAP_LENGTH), "lap_length")
	_check(is_equal_approx(float(sm["lap_length"]) * int(sm["laps"]), Balance.RACE_LENGTH), "race_length")
	_check(is_equal_approx(float(sm["tick"]), Balance.TICK), "tick")
	_check(is_equal_approx(float(sm["grid_gap"]), Balance.GRID_GAP), "grid_gap")
	_check((sm["ai_offsets"] as Array).size() + 1 == Balance.CAR_COUNT, "số xe")

	print("== Dữ liệu cụ thể ==")
	_check(GameData.tracks().size() == 12, "12 track (10 theo lịch giải + Circuit A, B thử nghiệm, Design/08)")
	_check(GameData.leagues().size() == 6, "6 giải")
	_check(GameData.cars().size() == 15, "15 xe")
	_check(GameData.drivers().size() == 12, "12 tay đua")
	var starter := GameData.car(GameData.starter_car_id())
	_check(starter["name"] == "Pico Tia chớp" and int(starter["base"]["S"]) == 46 and int(starter["base"]["H"]) == 38, "xe khởi đầu Pico Tia chớp 46/38/38/38")
	_check(Pricing.car_price("car_nova_tia_chop").equals("4392000000000"), "giá Nova = 600 x Q x rate tham chiếu (4,392T)")
	_check(Pricing.car_price("car_zenith_ben_bi").equals("70270000000000000000000000000000"), "giá Zenith Bền bỉ BigNumber vượt int64")
	_check(int(GameData.league(3)["car_base"]) == 86 and int(GameData.league(3)["driver_base"]) == 56, "nền giải Quốc gia 86/56")
	_check(GameData.driver("driver_binh")["trait"] == "fast_start", "Bình có đặc tính xuất phát nhanh")

	print("== Economy v2 ==")
	var part0 := Pricing.part_cost(0, 0)
	_check(part0.compare(BigNumber.from_int(1)) > 0 and Pricing.part_cost(1, 0).compare(part0.shifted(12).multiply_ratio(4, 1)) <= 0 and Pricing.part_cost(1, 0).compare(part0.shifted(12).multiply_ratio(3, 1)) > 0, "giá bộ phận hạng 2 = S(1e12) x Q(4) x giá hạng 1 (sai số ceil)")
	_check(Pricing.part_cost(4, 0).compare(part0.shifted(30).multiply_ratio(32, 1)) <= 0 and Pricing.part_cost(4, 0).compare(part0.shifted(30).multiply_ratio(24, 1)) > 0, "giá bộ phận hạng 5 dùng bậc vào cố định")
	_check(Pricing.part_cost(0, 0, "engine").compare(Pricing.part_cost(0, 0, "tyre")) > 0 and Pricing.part_cost(0, 0, "chassis").compare(Pricing.part_cost(0, 0, "gearbox")) > 0, "mỗi bộ phận có giá gốc riêng: Động cơ > Lốp, Khung gầm > Hộp số")
	_check(Pricing.part_cost(0, 1).compare(part0) > 0 and Pricing.part_cost(0, 1).compare(part0.multiply_ratio(104, 100)) <= 0, "mỗi cấp tăng ~1,45^(1/10) ≈ 3,8%")
	_check(Pricing.revenue_rate({}).equals(8), "rate nền 8")
	_check(Pricing.revenue_gain("ticket", 0).is_zero() and Pricing.revenue_gain("ticket", 1).equals("0.25075"), "revenue_gain cấp 1 = 0,25 x 1,003")
	_check(Pricing.star_count(24) == 0 and Pricing.star_count(25) == 1 and Pricing.star_count(150) == 4, "mốc sao 25/50/100/150")
	var star_ok := Pricing.revenue_gain("ticket", 25).compare(Pricing.revenue_gain("ticket", 24).multiply(BigNumber.parse_decimal("1.1"))) > 0
	_check(star_ok, "đạt mốc sao làm tăng vọt lợi nhuận")
	var prev_rate := BigNumber.zero()
	var monotonic := true
	for lv in range(0, 201):
		var r := Pricing.revenue_rate({"ticket": lv, "celebration": lv, "parking": lv, "grandstands": lv})
		if r.compare(prev_rate) <= 0:
			monotonic = false
		prev_rate = r
	_check(monotonic, "rate tăng nghiêm ngặt theo cấp 0..200")
	var max_levels := {"ticket": Balance.max_level(), "celebration": Balance.max_level(), "parking": Balance.max_level(), "grandstands": Balance.max_level()}
	_check(Pricing.revenue_rate(max_levels, 5).equals(Pricing.revenue_rate(max_levels, 0).shifted(30)), "rate max b5 = rate max b0 x 1e30")
	_check(Pricing.expansion_cost(0).equals(Pricing.reference_rate(0).multiply_ratio(Pricing.pacing(0) * 300, 1)), "phí mở b1 = rate tham chiếu x Q x 300 giây")
	_check(Pricing.race_money(1, BigNumber.from_int(8), 60).equals(126), "P1 chu kỳ 63 giây = 126")
	_check(Pricing.race_money(8, BigNumber.from_int(8), 60).equals(50), "P8 vẫn nhận tiền")
	_check(Pricing.race_points(1) == 10 and Pricing.race_points(8) == 1, "điểm mùa giữ nguyên")
	_check(Pricing.daily_gift(BigNumber.from_int(8)).equals(4800), "quà ngày = 600 giây rate")
	_check(Pricing.scout_sp_cost(0) == 40 and Pricing.scout_sp_cost(10) == 240, "SP tuyển theo thứ tự")
	_check(Balance.fmt_money(BigNumber.parse_decimal("1e15")) == "1AA", "đơn vị sau T là AA")

	print("== Bắt lỗi dữ liệu xấu ==")
	var bad := GameData.tracks().duplicate(true)
	bad[0]["sectors"][0]["len"] = 149
	GameData.set_override("tracks", {"schema_version": 1, "tracks": bad})
	var errs2 := GameData.validate()
	_check(errs2.size() > 0, "sector không cộng đủ 400 bị phát hiện")
	GameData.reload()
	_check(GameData.validate().is_empty(), "khôi phục dữ liệu gốc sau khi ghi đè")

	print("== Bot kịch bản (ai_cars) ==")
	_check(GameData.sim().has("ai_cars") and (GameData.sim()["ai_cars"] as Array).size() == 7, "sim.json có 7 bot trong ai_cars")
	var base_cases := {
		"thiếu name": func(a: Array) -> void: a[0].erase("name"),
		"trùng tên": func(a: Array) -> void: a[1]["name"] = a[0]["name"],
		"chỉ số lạ": func(a: Array) -> void: a[0]["stats"] = {"X": 5},
		"chỉ số không phải số": func(a: Array) -> void: a[0]["stats"] = {"S": "cao"},
		"đặc tính không có": func(a: Array) -> void: a[0]["trait"] = "bay_len_troi",
		"form ngoài khoảng": func(a: Array) -> void: a[0]["form"] = 3.0,
		"grid_slot ngoài khoảng": func(a: Array) -> void: a[0]["grid_slot"] = 99,
		"grid_slot trùng": func(a: Array) -> void: a[0]["grid_slot"] = 2; a[1]["grid_slot"] = 2,
		"sai số lượng": func(a: Array) -> void: a.pop_back(),
	}
	for label: String in base_cases:
		var sm2: Dictionary = GameData.sim().duplicate(true)
		(base_cases[label] as Callable).call(sm2["ai_cars"])
		GameData.set_override("sim", sm2)
		_check(GameData.validate().size() > 0, "ai_cars %s bị phát hiện" % label)
		GameData.reload()
	var good: Dictionary = GameData.sim().duplicate(true)
	good["ai_cars"][0] = {"name": "Kiên", "offset": -4, "stats": {"S": 6, "H": -8}, "trait": "hunter", "form": 1.02, "grid_slot": 3}
	GameData.set_override("sim", good)
	_check(GameData.validate().is_empty(), "ai_cars đầy đủ trường hợp lệ được chấp nhận")
	GameData.reload()
	_check(GameData.validate().is_empty(), "khôi phục dữ liệu gốc sau khi ghi đè ai_cars")

	print("== Kết thúc: %d lỗi ==" % _fails)
	quit(1 if _fails > 0 else 0)
