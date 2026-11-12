class_name Pricing
extends RefCounted

const BigNumber = preload("res://core/math/big_number.gd")
## Economy v2. Every money result is BigNumber; levels/points remain int.
static var _cost_cache: Dictionary = {}

static func _e() -> Dictionary:
	return GameData.economy()

static func reset_cache() -> void:
	_cost_cache.clear()

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
		var raw := float(base) * pacing(tier) * float(e["duration_factor"]) * pow(g, level) / k
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

static func completion_reward(exposure: BigNumber) -> BigNumber:
	return exposure.multiply(BigNumber.parse_decimal(_e()["rewards"]["season_ratio"])).floor_number()

static func daily_gift(rate: BigNumber) -> BigNumber:
	return rate.multiply_ratio(int(_e()["rewards"]["daily_rate_seconds"]), 1).floor_number()

static func offline_reward(rate: BigNumber, seconds: float) -> BigNumber:
	return rate.multiply_ratio(roundi(maxf(0.0, seconds) * 1000000.0), 1000000).multiply(BigNumber.parse_decimal(_e()["offline"]["ratio"])).floor_number()

## Frozen historical price: exclusively for the pre-v3 training refund.
static func legacy_driver_refund(level: int) -> BigNumber:
	return BigNumber.parse_decimal("100").multiply(BigNumber.parse_decimal("1.18").pow_nonnegative_int(level)).ceil_number()

static func scout_points(season_points: int) -> int:
	return season_points + int(_e()["scout"]["sp_race_bonus"])

static func scout_sp_cost(recruit_index: int) -> int:
	return int(_e()["scout"]["sp_base"]) + int(_e()["scout"]["sp_step"]) * recruit_index

static func scout_coin_cost(id: String) -> BigNumber:
	var d := GameData.driver(id)
	return BigNumber.parse_decimal(d["coin_cost_base"]).multiply_ratio(pacing(int(d["entry_tier"])), 1).multiply(scale_of(int(d["entry_tier"])))
