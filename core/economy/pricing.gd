class_name Pricing
extends RefCounted

const BigNumber = preload("res://core/math/big_number.gd")
## Economy v2. Every money result is BigNumber; levels/points remain int.
static var _cost_cache: Dictionary = {}
## Hàm thuần theo dữ liệu kinh tế: cache để UI gọi mỗi 0,2 giây không phải tính lại BigNumber (P0b, Design/25 §7.5).
static var _gain_cache: Dictionary = {}
static var _rate_cache: Dictionary = {}

static func _e() -> Dictionary:
	return GameData.economy()

static var _curve_cache: Array = [1.0]

## Hệ số giá tích lũy P(L) = Π r(n), r(n) = r_inf + (r0 − r_inf)·e^(−n/τ) (kiểu Race Star:
## dốc ở cấp đầu rồi hội tụ). Thiếu `upgrade_curve` thì quay về g^L với g = upgrade_growth^(1/sub).
static func _curve(level: int) -> float:
	var e := _e()
	var c: Variant = e.get("upgrade_curve", null)
	if c == null:
		return pow(pow(float(e["upgrade_growth"]), 1.0 / int(e["level_subdivision"])), level)
	var r0 := float(c["r0"])
	var r_inf := float(c["r_inf"])
	var tau := float(c["tau"])
	while _curve_cache.size() <= level:
		var n := _curve_cache.size()
		_curve_cache.append(float(_curve_cache[n - 1]) * (r_inf + (r0 - r_inf) * exp(-n / tau)))
	return _curve_cache[level]

static func reset_cache() -> void:
	_curve_cache = [1.0]
	_cost_cache.clear()
	_gain_cache.clear()
	_rate_cache.clear()

static func max_level() -> int:
	return int(_e()["max_level"])

static func level_subdivision() -> int:
	return int(_e()["level_subdivision"])

static func scale_of(tier: int) -> BigNumber:
	return BigNumber.from_int(1).shifted(int(_e()["business"]["scale_exponents"][tier]))

static func pacing(tier: int) -> int:
	return int(_e()["business"]["pacing"][tier])

static func _cost(base: String, tier: int, level: int) -> BigNumber:
	var key := "%s/%d/%d" % [base, tier, level]
	if not _cost_cache.has(key):
		# Design/13: cost = S × ceil(base × Q × D × g^m / K), g = growth^(1/sub), K = Σ g^j (j<sub).
		var e := _e()
		var sub := int(e["level_subdivision"])
		var g := pow(float(e["upgrade_growth"]), 1.0 / sub)
		var k := 0.0
		for j in sub:
			k += pow(g, j)
		var raw := float(base) * pacing(tier) * float(e["duration_factor"]) * _curve(level) / k  # K theo upgrade_growth cũ: giữ giá cấp 0
		_cost_cache[key] = BigNumber.from_int(int(ceil(raw - 1e-9))).multiply(scale_of(tier))
	return _cost_cache[key]

## Chỉ số cộng thêm cho mỗi cấp bộ phận xe. Có `kind` thì ưu tiên hệ số riêng trong
## `part_stat_per_level_by_part`; thiếu thì dùng mặc định `part_stat_per_level`.
static func part_stat_per_level(kind: String = "") -> float:
	var e := _e()
	var by_part: Dictionary = e.get("part_stat_per_level_by_part", {})
	if kind != "" and by_part.has(kind):
		return float(by_part[kind])
	return float(e["part_stat_per_level"])

## Giá gốc của từng bộ phận: part_cost_bases[kind] nếu có, không thì part_cost_base chung.
static func part_base(kind: String) -> String:
	var per_kind: Dictionary = _e().get("part_cost_bases", {})
	return String(per_kind.get(kind, _e()["part_cost_base"]))

static func part_cost(class_index: int, level: int, kind: String = "") -> BigNumber:
	var tier := 0 if class_index == 0 else class_index + 1
	return _cost(part_base(kind) if kind != "" else String(_e()["part_cost_base"]), tier, level)

static func revenue_cost(kind: String, level: int, tier: int = 0) -> BigNumber:
	return _cost(String(_e()["revenue_upgrades"][kind]["cost"]), tier, level)

## Số mốc sao đã đạt ở cấp `level` (Design/19: airport_empire star multiply).
static func star_count(level: int) -> int:
	var n := 0
	for m in _e().get("revenue_stars", {}).get("levels", []):
		if level >= int(m):
			n += 1
	return n

## Phần tăng thêm của một nguồn doanh thu ở cấp `level`:
## per_level × L × Kp^L × StarMult^sao. Không khai báo growth/revenue_stars thì quay về tuyến tính.
static func revenue_gain(kind: String, level: int) -> BigNumber:
	if level <= 0:
		return BigNumber.zero()
	var key := "%s/%d" % [kind, level]
	if not _gain_cache.has(key):
		_gain_cache[key] = _revenue_gain_uncached(kind, level)
	return _gain_cache[key]

static func _revenue_gain_uncached(kind: String, level: int) -> BigNumber:
	var e := _e()
	var c: Dictionary = e["revenue_upgrades"][kind]
	var kp := BigNumber.parse_decimal(str(c.get("growth", "1")))
	var star_mult := BigNumber.parse_decimal(str(e.get("revenue_stars", {}).get("multiplier", "1")))
	return BigNumber.parse_decimal(c["per_level"]).multiply_ratio(level, 1).multiply(kp.pow_nonnegative_int(level)).multiply(star_mult.pow_nonnegative_int(star_count(level)))

## Giá trị hiển thị (ví dụ số chỗ Grandstands); BigNumber vì có thể tăng hình học.
static func revenue_value(kind: String, level: int) -> BigNumber:
	var c: Dictionary = _e()["revenue_upgrades"][kind]
	return BigNumber.parse_decimal(c["base"]).add(revenue_gain(kind, level))

static func revenue_rate(levels: Dictionary, tier: int = 0) -> BigNumber:
	var key := "%d/%d/%d/%d/%d" % [tier, int(levels.get("ticket", 0)), int(levels.get("celebration", 0)),
		int(levels.get("parking", 0)), int(levels.get("grandstands", 0))]
	if not _rate_cache.has(key):
		_rate_cache[key] = _revenue_rate_uncached(levels, tier)
	return _rate_cache[key]

static func _revenue_rate_uncached(levels: Dictionary, tier: int) -> BigNumber:
	var rate := BigNumber.zero()
	for kind in ["ticket", "celebration", "parking"]:
		var c: Dictionary = _e()["revenue_upgrades"][kind]
		rate = rate.add(BigNumber.parse_decimal(c["base"]).add(revenue_gain(kind, int(levels.get(kind, 0)))))
	var g: Dictionary = _e()["revenue_upgrades"]["grandstands"]
	var capacity := BigNumber.parse_decimal(g["base"]).add(revenue_gain("grandstands", int(levels.get("grandstands", 0))))
	return rate.multiply(capacity).divide(BigNumber.parse_decimal(g["base"])).multiply(scale_of(tier))

static func reference_rate(tier: int) -> BigNumber:
	var levels := {}
	for kind in Balance.REVENUE:
		levels[kind] = int(_e()["business"]["reference_revenue_level"])
	return revenue_rate(levels, tier)

static func expansion_cost(tier: int) -> BigNumber:
	return reference_rate(tier).multiply_ratio(pacing(tier) * int(_e()["business"]["expansion_rate_seconds"]), 1)

static func opening_reserve(tier: int) -> BigNumber:
	return BigNumber.parse_decimal(_e()["business"]["opening_reserve_base"]).multiply_ratio(pacing(tier), 1).multiply(scale_of(tier))

static func car_price(id: String) -> BigNumber:
	return BigNumber.parse_decimal(GameData.car(id)["price"])

static func race_points(position: int) -> int:
	return int((_e()["race_rewards"] as Array)[position - 1][0])

static func race_exposure(rate: BigNumber, duration: float) -> BigNumber:
	return rate.multiply_ratio(roundi((duration + Balance.COUNTDOWN_SECONDS) * 1000000.0), 1000000)

static func race_money(position: int, rate: BigNumber, duration: float) -> BigNumber:
	var rewards: Dictionary = _e()["rewards"]
	return race_exposure(rate, duration).multiply(BigNumber.parse_decimal(rewards["race_ratio"])).multiply(BigNumber.parse_decimal(rewards["position_factors"][position - 1])).floor_number()

## Thưởng tham gia mỗi lượt, không phụ thuộc hạng: thay thưởng hoàn tất mùa cũ (cùng tỉ lệ trên exposure nên tổng tiền giữ nguyên).
static func participation_reward(exposure: BigNumber) -> BigNumber:
	return exposure.multiply(BigNumber.parse_decimal(_e()["rewards"]["participation_ratio"])).floor_number()

## Tổng tiền một lượt = thưởng theo hạng + thưởng tham gia.
static func race_total(position: int, rate: BigNumber, duration: float) -> BigNumber:
	return race_money(position, rate, duration).add(participation_reward(race_exposure(rate, duration)))

static func daily_gift(rate: BigNumber) -> BigNumber:
	return rate.multiply_ratio(int(_e()["rewards"]["daily_rate_seconds"]), 1).floor_number()

static func offline_reward(rate: BigNumber, seconds: float) -> BigNumber:
	return rate.multiply_ratio(roundi(maxf(0.0, seconds) * 1000000.0), 1000000).multiply(BigNumber.parse_decimal(_e()["offline"]["ratio"])).floor_number()

## Frozen historical price: exclusively for the pre-v3 training refund.
static func legacy_driver_refund(level: int) -> BigNumber:
	return BigNumber.parse_decimal("100").multiply(BigNumber.parse_decimal("1.18").pow_nonnegative_int(level)).ceil_number()

static func scout_points(race_points_won: int) -> int:
	return race_points_won + int(_e()["scout"]["sp_race_bonus"])

static func scout_sp_cost(recruit_index: int) -> int:
	return int(_e()["scout"]["sp_base"]) + int(_e()["scout"]["sp_step"]) * recruit_index

static func scout_coin_cost(id: String) -> BigNumber:
	var d := GameData.driver(id)
	return BigNumber.parse_decimal(d["coin_cost_base"]).multiply_ratio(pacing(int(d["entry_tier"])), 1).multiply(scale_of(int(d["entry_tier"])))
