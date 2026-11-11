class_name GameData
extends RefCounted

const BigNumber = preload("res://core/math/big_number.gd")
## Nạp và kiểm tra dữ liệu cấu hình trong res://data/*.json.
## Mọi hằng số cân bằng nằm ở đây, không rải trong code hoặc scene (Design/07 §3).

const DIR := "res://data/"
const TRAIT_IDS := [
	"fast_start", "smooth_corners", "calm", "sprint", "hunter", "defender",
	"straight_line", "steady", "recovery", "golden", "discipline",
]
const STYLE_IDS := ["inside", "sweeper", "counter", "defender"]
const PART_KEYS := ["S", "H", "B", "A"]
const SIM_STAT_KEYS := ["S", "H", "B", "A", "P", "T", "C", "L", "R", "K", "E"]

static var _cache: Dictionary = {}
static var _override: Dictionary = {}  # dùng cho lab/test: ghi đè theo tên tệp


static func reload() -> void:
	_cache.clear()
	_override.clear()
	Pricing.reset_cache()


## Test/lab ghi đè dữ liệu trong bộ nhớ (không đụng tệp).
static func set_override(file_name: String, data: Variant) -> void:
	_override[file_name] = data
	Pricing.reset_cache()


static func _load(file_name: String) -> Variant:
	if _override.has(file_name):
		return _override[file_name]
	if _cache.has(file_name):
		return _cache[file_name]
	var path := DIR + file_name + ".json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("Không đọc được dữ liệu: " + path)
		parsed = {}
	_cache[file_name] = parsed
	return parsed


static func sim() -> Dictionary:
	return _load("sim")


static func economy() -> Dictionary:
	return _load("economy")


static func tracks() -> Array:
	return (_load("tracks") as Dictionary).get("tracks", [])


static func leagues() -> Array:
	return (_load("leagues") as Dictionary).get("leagues", [])


static func cars() -> Array:
	return (_load("cars") as Dictionary).get("cars", [])


## Danh mục ngoại hình Garage (data/garage_cosmetics.json): màu sơn + decal, miễn phí, không đổi chỉ số.
static func paints() -> Array:
	return (_load("garage_cosmetics") as Dictionary).get("paints", [])


static func decals() -> Array:
	return (_load("garage_cosmetics") as Dictionary).get("decals", [])


static func paint(id: String) -> Dictionary:
	for p: Dictionary in paints():
		if p["id"] == id:
			return p
	return {}


static func decal(id: String) -> Dictionary:
	for d: Dictionary in decals():
		if d["id"] == id:
			return d
	return {}


static func default_paint_id() -> String:
	return String((_load("garage_cosmetics") as Dictionary).get("default_paint", "orange"))


static func default_decal_id() -> String:
	return String((_load("garage_cosmetics") as Dictionary).get("default_decal", "none"))


static func drivers() -> Array:
	return (_load("drivers") as Dictionary).get("drivers", [])


static func track(id: String) -> Dictionary:
	for t: Dictionary in tracks():
		if t["id"] == id:
			return t
	push_error("Không có track: " + id)
	return {}


## Chiều dài một vòng của track: trường "lap_length" của track nếu có, ngược lại giá trị chung của sim.json.
static func lap_length_of(track_id: String) -> float:
	return float(track(track_id).get("lap_length", sim()["lap_length"]))


static func league(index: int) -> Dictionary:
	return leagues()[index]


static func car(id: String) -> Dictionary:
	for c: Dictionary in cars():
		if c["id"] == id:
			return c
	return {}


static func driver(id: String) -> Dictionary:
	for d: Dictionary in drivers():
		if d["id"] == id:
			return d
	return {}


static func starter_car_id() -> String:
	for c: Dictionary in cars():
		if bool(c.get("starter", false)):
			return c["id"]
	return ""


## Sector dạng [độ dài, là cua?, cho phép vượt?]; vùng vượt = đoạn thẳng.
static func sectors_of(track_id: String) -> Array:
	var out: Array = []
	for s: Dictionary in track(track_id).get("sectors", []):
		var corner: bool = s["type"] == "C"
		out.append([float(s["len"]), corner, not corner])
	return out


## Sector đầy đủ cho TrafficSim (Design/08): độ dài, loại, vùng vượt, bề rộng (theo bề ngang xe)
## đầu/cuối sector, góc rẽ (độ, dương = trái) và hướng rẽ. Track chưa có hình học dùng mặc định.
static func sector_defs(track_id: String) -> Array:
	var tr: Dictionary = sim().get("traffic", {})
	var default_width := float(tr.get("default_width", 3.8))
	var out: Array = []
	for s: Dictionary in track(track_id).get("sectors", []):
		var corner: bool = s["type"] == "C"
		var w0 := float(s.get("width", default_width))
		var turn := float(s.get("turn", 0.0))
		out.append({
			"len": float(s["len"]), "corner": corner,
			"zone": bool(s.get("zone", not corner)),
			"w0": w0, "w1": float(s.get("width_end", w0)),
			"turn": turn, "has_turn": s.has("turn") or not corner,
			"dir": -1.0 if turn < 0.0 else 1.0,
		})
	return out


## Kiểm tra sim.json["ai_cars"] (bot của kịch bản; tùy chọn). Báo rõ bot và trường sai.
static func _validate_ai_cars(sm: Dictionary) -> Array:
	var errs: Array = []
	if not sm.has("ai_cars"):
		return errs
	var cars_cfg: Variant = sm["ai_cars"]
	if typeof(cars_cfg) != TYPE_ARRAY:
		return ["sim.json: ai_cars phải là mảng"]
	var list := cars_cfg as Array
	if list.size() != (sm["ai_offsets"] as Array).size():
		errs.append("sim.json: ai_cars có %d bot, cần %d (bằng số xe AI)" % [list.size(), (sm["ai_offsets"] as Array).size()])
	var names := {}
	var traits := sm["traits"] as Dictionary
	var slots := {}
	for i in list.size():
		var b: Variant = list[i]
		var tag := "ai_cars[%d]" % i
		if typeof(b) != TYPE_DICTIONARY:
			errs.append("sim.json: %s phải là đối tượng" % tag)
			continue
		var d := b as Dictionary
		var nm := String(d.get("name", ""))
		if nm == "":
			errs.append("sim.json: %s thiếu name" % tag)
		elif names.has(nm):
			errs.append("sim.json: %s trùng tên bot %s" % [tag, nm])
		names[nm] = true
		tag = "ai_cars[%d] %s" % [i, nm]
		if d.has("offset") and (not _is_num(d["offset"]) or not is_finite(float(d["offset"]))):
			errs.append("sim.json: %s.offset phải là số hữu hạn" % tag)
		if d.has("stats"):
			if typeof(d["stats"]) != TYPE_DICTIONARY:
				errs.append("sim.json: %s.stats phải là đối tượng" % tag)
			else:
				for k in (d["stats"] as Dictionary).keys():
					if not SIM_STAT_KEYS.has(String(k)):
						errs.append("sim.json: %s.stats có chỉ số lạ %s (chỉ S,H,B,A,P,T,C,L,R,K,E)" % [tag, k])
					elif not _is_num(d["stats"][k]) or not is_finite(float(d["stats"][k])):
						errs.append("sim.json: %s.stats.%s phải là số hữu hạn" % [tag, k])
		if d.has("trait") and String(d["trait"]) != "" and (not traits.has(String(d["trait"])) or not TRAIT_IDS.has(String(d["trait"]))):
			errs.append("sim.json: %s.trait không hợp lệ: %s" % [tag, d["trait"]])
		if d.has("style") and not STYLE_IDS.has(String(d["style"])):
			errs.append("sim.json: %s.style không hợp lệ: %s" % [tag, d["style"]])
		if d.has("form") and (not _is_num(d["form"]) or float(d["form"]) < 0.8 or float(d["form"]) > 1.2):
			errs.append("sim.json: %s.form phải là số trong [0,8; 1,2]" % tag)
		if d.has("grid_slot"):
			if not _is_num(d["grid_slot"]) or int(d["grid_slot"]) < 0 or int(d["grid_slot"]) > list.size():
				errs.append("sim.json: %s.grid_slot phải là số nguyên trong [0; %d]" % [tag, list.size()])
			elif slots.has(int(d["grid_slot"])):
				errs.append("sim.json: %s.grid_slot trùng bot khác (%d)" % [tag, int(d["grid_slot"])])
			else:
				slots[int(d["grid_slot"])] = true
	return errs


static func _is_num(v: Variant) -> bool:
	return typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT


## Kiểm tra toàn bộ dữ liệu. Trả về danh sách lỗi (rỗng = hợp lệ).
static func validate() -> Array:
	var errs: Array = []
	var sm := sim()
	var ec := economy()
	for f in ["sim", "economy", "tracks", "leagues", "cars", "drivers", "garage_cosmetics", "gear", "driver_gacha"]:
		var d: Variant = _load(f)
		if typeof(d) != TYPE_DICTIONARY or (d as Dictionary).is_empty():
			errs.append("%s.json rỗng hoặc không đọc được" % f)
		elif int((d as Dictionary).get("schema_version", 0)) < 1:
			errs.append("%s.json thiếu schema_version" % f)
	if not errs.is_empty():
		return errs

	errs.append_array(_validate_economy(ec))
	errs.append_array(_validate_gear())
	errs.append_array(_validate_driver_gacha())
	if not errs.is_empty():
		return errs

	# Vòng lặp đua liên tục (Design/10 §4): báo rõ trường sai, không cho chạy với thời lượng ≤ 0.
	var rl: Variant = sm.get("race_loop")
	if typeof(rl) != TYPE_DICTIONARY:
		errs.append("sim.json: thiếu nhóm race_loop")
	else:
		var rlaps: Variant = (rl as Dictionary).get("race_laps")
		if not _is_num(rlaps) or not is_finite(float(rlaps)) or float(rlaps) < 1.0:
			errs.append("sim.json: race_loop.race_laps phải là số hữu hạn >= 1")
		var rfac: Variant = (rl as Dictionary).get("race_time_factor")
		if not _is_num(rfac) or not is_finite(float(rfac)) or float(rfac) <= 0.0:
			errs.append("sim.json: race_loop.race_time_factor phải là số hữu hạn > 0")
		var spr: Variant = (rl as Dictionary).get("sprint_duration_seconds")
		if not _is_num(spr) or not is_finite(float(spr)) or float(spr) < 0.0:
			errs.append("sim.json: race_loop.sprint_duration_seconds phải là số hữu hạn >= 0")

	var lap: float = sm["lap_length"]
	var track_ids := {}
	for t: Dictionary in tracks():
		var id: String = t["id"]
		if track_ids.has(id):
			errs.append("track trùng id: " + id)
		track_ids[id] = true
		var total := 0.0
		var straight := 0.0
		var has_zone := false
		for s: Dictionary in t["sectors"]:
			total += float(s["len"])
			if s["type"] == "S":
				straight += float(s["len"])
				has_zone = true
			elif s["type"] != "C":
				errs.append("%s: sector type lạ %s" % [id, s["type"]])
		var t_lap: float = float(t.get("lap_length", lap))
		if not is_equal_approx(total, t_lap):
			errs.append("%s: sector cộng %.1f, cần %.1f mỗi vòng" % [id, total, t_lap])
		if not has_zone:
			errs.append("%s: không có đoạn thẳng nào để vượt" % id)
		if absf(straight / t_lap * 100.0 - float(t["straight_pct"])) > 0.51:
			errs.append("%s: straight_pct không khớp sector" % id)
		for part in t.get("important", []):
			if not ["engine", "tyre", "chassis", "gearbox"].has(part):
				errs.append("%s: important lạ %s" % [id, part])
		# Hình học và bề rộng (Design/08 §3): chỉ kiểm khi track khai báo.
		var turns := 0
		for s: Dictionary in t["sectors"]:
			if s.has("width") and float(s["width"]) < 3.0:
				errs.append("%s: bề rộng sector < 3 bề ngang xe" % id)
			if s.has("width_end") and float(s["width_end"]) < 3.0:
				errs.append("%s: bề rộng cuối sector < 3 bề ngang xe" % id)
			if s.has("turn"):
				turns += 1
		if turns > 0:
			var lay := TrackLayout.build(id)
			if not lay.valid:
				errs.append("%s: mọi sector cua phải có turn" % id)
			else:
				if lay.closure_error > 1.0:
					errs.append("%s: đường không khép kín (sai số %.2f đơn vị)" % [id, lay.closure_error])
				if absf(absf(lay.total_turn) - 360.0) > 0.5:
					errs.append("%s: tổng góc rẽ %.1f, cần ±360" % [id, lay.total_turn])
				var max_w := 0.0
				for w in lay.widths:
					max_w = maxf(max_w, w)
				var road: float = max_w * float(sm["car_width"])
				if lay.min_clearance() < road * 1.3:
					errs.append("%s: hai đoạn đường quá gần nhau" % id)

	var ls := leagues()
	if ls.size() != 6:
		errs.append("cần 6 giải, có %d" % ls.size())
	var stages: int = int(ec["stages"])
	for i in ls.size():
		var l: Dictionary = ls[i]
		if int(l["index"]) != i:
			errs.append("league %s: index sai" % l["id"])
		if (l["schedule"] as Array).size() != stages:
			errs.append("league %s: lịch cần %d chặng" % [l["id"], stages])
		for tid in l["schedule"]:
			if not track_ids.has(tid):
				errs.append("league %s: track không tồn tại %s" % [l["id"], tid])
		if i > 0 and int(l["car_base"]) <= int((ls[i - 1] as Dictionary)["car_base"]):
			errs.append("league %s: car_base phải tăng dần" % l["id"])

	var cs := cars()
	if cs.size() != 15:
		errs.append("cần 15 xe, có %d" % cs.size())
	var car_ids := {}
	var per_class := {}
	var starters := 0
	for c: Dictionary in cs:
		if car_ids.has(c["id"]):
			errs.append("xe trùng id: " + c["id"])
		car_ids[c["id"]] = true
		if typeof(c.get("price")) != TYPE_STRING or BigNumber.parse_decimal(c.get("price", "")) == null:
			errs.append("%s: price phải là chuỗi BigNumber" % c["id"])
			continue
		if int(c.get("entry_tier", -1)) < 0 or int(c.get("entry_tier", -1)) > 5:
			errs.append("%s: entry_tier không hợp lệ" % c["id"])
		per_class[int(c["class"])] = int(per_class.get(int(c["class"]), 0)) + 1
		for k in PART_KEYS:
			if not (c["base"] as Dictionary).has(k):
				errs.append("%s thiếu base.%s" % [c["id"], k])
		if bool(c.get("starter", false)):
			starters += 1
			if not BigNumber.parse_decimal(c["price"]).is_zero():
				errs.append("xe khởi đầu phải miễn phí")
	if starters != 1:
		errs.append("cần đúng 1 xe khởi đầu, có %d" % starters)
	for k in range(1, 6):
		if int(per_class.get(k, 0)) != 3:
			errs.append("hạng %d cần 3 xe" % k)

	var ds := drivers()
	if ds.size() != 12:
		errs.append("cần 12 tay đua, có %d" % ds.size())
	var drv_ids := {}
	var traits := sm["traits"] as Dictionary
	for d: Dictionary in ds:
		if drv_ids.has(d["id"]):
			errs.append("tay đua trùng id: " + d["id"])
		drv_ids[d["id"]] = true
		if typeof(d.get("coin_cost_base")) != TYPE_STRING or BigNumber.parse_decimal(d.get("coin_cost_base", "")) == null:
			errs.append("%s: coin_cost_base không hợp lệ" % d["id"])
		if int(d.get("entry_tier", -1)) < 0 or int(d.get("entry_tier", -1)) > 5:
			errs.append("%s: entry_tier không hợp lệ" % d["id"])
		var tr: String = d["trait"]
		if tr != "" and not traits.has(tr):
			errs.append("%s: đặc tính không có trong sim.json: %s" % [d["id"], tr])
		if tr != "" and not TRAIT_IDS.has(tr):
			errs.append("%s: đặc tính không được mô phỏng hỗ trợ: %s" % [d["id"], tr])
		if int(d["tier"]) < 0 or int(d["tier"]) > 3:
			errs.append("%s: tier ngoài 0–3" % d["id"])
		if not STYLE_IDS.has(String(d.get("style", ""))):
			errs.append("%s: style không hợp lệ: %s" % [d["id"], d.get("style", "")])
		for key in ["pace", "technique", "composure", "launch", "braking", "racecraft", "endurance"]:
			if not _is_num(d.get(key)) or float(d[key]) < 0.0 or float(d[key]) > 100.0:
				errs.append("%s: %s phải là số trong [0; 100]" % [d["id"], key])
	var styles_cfg: Dictionary = sm.get("styles", {})
	for sid in styles_cfg.keys():
		if not STYLE_IDS.has(sid):
			errs.append("sim.json có style chưa hỗ trợ: " + sid)
	for sid in STYLE_IDS:
		if not styles_cfg.has(sid):
			errs.append("sim.json thiếu style: " + sid)
	for blk in ["driver_stats", "stamina"]:
		if not sm.has(blk):
			errs.append("sim.json thiếu khối " + blk)
	for tr in traits.keys():
		if not TRAIT_IDS.has(tr):
			errs.append("sim.json có đặc tính chưa hỗ trợ: " + tr)

	if (sm["ai_offsets"] as Array).size() != int(sm["ai_names"].size()):
		errs.append("ai_offsets và ai_names phải cùng số lượng")
	errs.append_array(_validate_ai_cars(sm))
	if (sm["ai_offsets"] as Array).size() + 1 != (ec["race_rewards"] as Array).size():
		errs.append("số xe (AI+1) phải bằng số dòng race_rewards")
	var prev_pts := 1000
	for r in ec["race_rewards"]:
		if int(r[0]) >= prev_pts:
			errs.append("race_rewards phải giảm dần theo vị trí")
		prev_pts = int(r[0])
	return errs


static func _validate_economy(ec: Dictionary) -> Array:
	var errs: Array = []
	for key in ["business", "rewards", "revenue_upgrades", "offline", "scout"]:
		if typeof(ec.get(key)) != TYPE_DICTIONARY:
			errs.append("economy.json: thiếu nhóm " + key)
	if not errs.is_empty():
		return errs
	var ml := int(ec.get("max_level", 0))
	var sub := int(ec.get("level_subdivision", 0))
	if int(ec.get("economy_version", 0)) != 2 or ml < 1 or ml > 1000:
		errs.append("economy.json: cần economy_version=2, max_level trong 1..1000")
	if sub < 1 or sub > 100:
		errs.append("economy.json: level_subdivision ngoài 1..100")
	for key in ["duration_factor", "part_stat_per_level"]:
		var v: Variant = ec.get(key)
		var n := BigNumber.parse_decimal(v) if typeof(v) == TYPE_STRING else null
		if n == null or n.is_zero() or absi(n.exponent) > 1000:
			errs.append("economy.json: %s phải là chuỗi decimal dương" % key)
	for key in ["start_coins", "base_rate", "upgrade_growth", "part_cost_base"]:
		if typeof(ec.get(key)) != TYPE_STRING or BigNumber.parse_decimal(ec.get(key, "")) == null:
			errs.append("economy.json: " + key + " phải là chuỗi decimal hợp lệ")
	if not errs.is_empty():
		return errs
	if BigNumber.parse_decimal(ec["upgrade_growth"]).compare(BigNumber.from_int(1)) <= 0:
		errs.append("economy.json: upgrade_growth phải >1")
	if BigNumber.parse_decimal(ec["upgrade_growth"]).compare(BigNumber.from_int(10)) > 0:
		errs.append("economy.json: upgrade_growth phải <=10")
	for key in ["start_coins", "base_rate", "part_cost_base"]:
		if absi(BigNumber.parse_decimal(ec[key]).exponent) > 1000:
			errs.append("economy.json: " + key + " vượt miền cấu hình")
	if BigNumber.parse_decimal(ec["base_rate"]).is_zero() or BigNumber.parse_decimal(ec["part_cost_base"]).is_zero():
		errs.append("economy.json: rate và giá cơ bản phải >0")
	var business: Dictionary = ec["business"]
	for key in ["scale_exponents", "pacing"]:
		if typeof(business.get(key)) != TYPE_ARRAY or business[key].size() != 6:
			errs.append("economy.json: business." + key + " cần 6 phần tử")
	if not errs.is_empty():
		return errs
	var previous := -1
	for e in business["scale_exponents"]:
		if not _is_num(e) or float(e) != floor(float(e)) or int(e) <= previous or int(e) > 10000:
			errs.append("economy.json: scale_exponents phải là số nguyên tăng dần <=10000")
		previous = int(e)
	for q in business["pacing"]:
		if not _is_num(q) or not is_finite(float(q)) or float(q) != floor(float(q)) or int(q) <= 0 or int(q) > 1000000:
			errs.append("economy.json: pacing phải là số nguyên dương <=1000000")
	for key in ["reference_revenue_level", "expansion_min_revenue_level"]:
		if not business.has(key) or int(business[key]) < 0 or int(business[key]) > ml:
			errs.append("economy.json: business." + key + " ngoài 0..max_level")
	for key in ["expansion_rate_seconds", "required_car_rate_seconds"]:
		if not business.has(key) or int(business[key]) <= 0 or int(business[key]) > 604800:
			errs.append("economy.json: business." + key + " không hợp lệ")
	if typeof(business.get("opening_reserve_base")) != TYPE_STRING or BigNumber.parse_decimal(business.get("opening_reserve_base", "")) == null:
		errs.append("economy.json: opening_reserve_base không hợp lệ")
	var revenue: Dictionary = ec["revenue_upgrades"]
	if revenue.size() != 4:
		errs.append("economy.json: cần đúng 4 nguồn doanh thu")
	for kind in ["ticket", "celebration", "parking", "grandstands"]:
		if typeof(revenue.get(kind)) != TYPE_DICTIONARY:
			errs.append("economy.json: thiếu nguồn " + kind)
			continue
		for key in ["base", "per_level", "cost"]:
			var value: Variant = revenue[kind].get(key)
			var number := BigNumber.parse_decimal(value) if typeof(value) == TYPE_STRING else null
			if number == null or absi(number.exponent) > 1000 or (key != "base" and number.is_zero()) or (kind == "grandstands" and key == "base" and number.is_zero()):
				errs.append("economy.json: revenue_upgrades.%s.%s không hợp lệ" % [kind, key])
	var rewards: Dictionary = ec["rewards"]
	for key in ["race_ratio", "season_ratio"]:
		var value: Variant = rewards.get(key)
		var number := BigNumber.parse_decimal(value) if typeof(value) == TYPE_STRING else null
		if number == null or number.compare(BigNumber.from_int(1)) > 0:
			errs.append("economy.json: rewards." + key + " ngoài 0..1")
	if typeof(rewards.get("position_factors")) != TYPE_ARRAY or rewards["position_factors"].size() != 8:
		errs.append("economy.json: cần 8 position_factors")
	else:
		for value in rewards["position_factors"]:
			var number := BigNumber.parse_decimal(value) if typeof(value) == TYPE_STRING else null
			if number == null or number.is_zero() or number.compare(BigNumber.from_int(1)) > 0:
				errs.append("economy.json: position_factor ngoài (0..1]")
	for key in ["daily_rate_seconds", "daily_gems", "first_season_gems", "first_league_gems"]:
		if not rewards.has(key) or not _is_num(rewards[key]) or float(rewards[key]) != floor(float(rewards[key])) or int(rewards[key]) < 0 or int(rewards[key]) > 604800:
			errs.append("economy.json: rewards." + key + " không hợp lệ")
	var offline: Dictionary = ec["offline"]
	var ratio := BigNumber.parse_decimal(offline.get("ratio", "")) if typeof(offline.get("ratio")) == TYPE_STRING else null
	if ratio == null or ratio.compare(BigNumber.from_int(1)) > 0:
		errs.append("economy.json: offline.ratio ngoài 0..1")
	if not _is_num(offline.get("cap_sec")) or float(offline["cap_sec"]) < 0 or float(offline["cap_sec"]) > 604800:
		errs.append("economy.json: offline.cap_sec không hợp lệ")
	return errs


# ---------- Trang bị / phụ kiện (data/gear.json, Design/14) ----------

static func gear_packs() -> Array:
	return (_load("gear") as Dictionary).get("packs", [])


static func gear_pack(id: String) -> Dictionary:
	for p: Dictionary in gear_packs():
		if p["id"] == id:
			return p
	return {}


static func gear_items() -> Array:
	return (_load("gear") as Dictionary).get("items", [])


static func gear_item(id: String) -> Dictionary:
	for g: Dictionary in gear_items():
		if g["id"] == id:
			return g
	return {}


static func gear_coupon_types() -> Array:
	return (_load("gear") as Dictionary).get("coupon_types", [])


## Cấu hình level/mảnh hiệu lực của một phụ kiện: mặc định theo độ hiếm, ghi đè bằng khóa `config` của món.
static func gear_config(id: String) -> Dictionary:
	var item := gear_item(id)
	if item.is_empty():
		return {}
	var defaults: Dictionary = (_load("gear") as Dictionary).get("rarity_defaults", {})
	var out: Dictionary = (defaults.get(item["rarity"], {}) as Dictionary).duplicate(true)
	out.merge(item.get("config", {}), true)
	return out


# ---------- Gacha tay đua (data/driver_gacha.json) ----------

static func driver_tier_ids() -> Array:
	return (_load("driver_gacha") as Dictionary).get("tier_ids", [])


static func driver_packs() -> Array:
	return (_load("driver_gacha") as Dictionary).get("packs", [])


static func driver_pack(id: String) -> Dictionary:
	for p: Dictionary in driver_packs():
		if p["id"] == id:
			return p
	return {}


static func driver_coupon_types() -> Array:
	return (_load("driver_gacha") as Dictionary).get("coupon_types", [])


## Cấu hình level/mảnh hiệu lực của một tay đua, theo bậc (tier) trong drivers.json.
static func driver_gacha_config(driver_id: String) -> Dictionary:
	var d := driver(driver_id)
	var ids := driver_tier_ids()
	if d.is_empty() or int(d["tier"]) < 0 or int(d["tier"]) >= ids.size():
		return {}
	var defaults: Dictionary = (_load("driver_gacha") as Dictionary).get("tier_defaults", {})
	return (defaults.get(String(ids[int(d["tier"])]), {}) as Dictionary).duplicate(true)


static func _validate_driver_gacha() -> Array:
	var errs: Array = []
	var g: Variant = _load("driver_gacha")
	if typeof(g) != TYPE_DICTIONARY or (g as Dictionary).is_empty():
		return errs  # đã báo ở bước đọc tệp
	var ids := driver_tier_ids()
	var coupons := driver_coupon_types()
	var defaults: Dictionary = (g as Dictionary).get("tier_defaults", {})
	for tier_id in ids:
		var c: Variant = defaults.get(tier_id)
		if typeof(c) != TYPE_DICTIONARY:
			errs.append("driver_gacha.json: thiếu tier_defaults.%s" % tier_id)
			continue
		var maxl := int(c.get("max_level", -1))
		var table: Array = c.get("level_up_shards", [])
		if maxl < 0 or table.size() != maxl:
			errs.append("driver_gacha.json: %s.level_up_shards phải có đúng max_level mục" % tier_id)
		for n in table:
			if not _is_num(n) or int(n) <= 0:
				errs.append("driver_gacha.json: %s.level_up_shards phải là số nguyên dương" % tier_id)
		if not _is_num(c.get("duplicate_shards")) or int(c["duplicate_shards"]) <= 0:
			errs.append("driver_gacha.json: %s.duplicate_shards không hợp lệ" % tier_id)
	for d: Dictionary in drivers():
		if int(d["tier"]) < 0 or int(d["tier"]) >= ids.size():
			errs.append("driver_gacha.json: tay đua %s có tier ngoài tier_ids" % d["id"])
	for p: Dictionary in driver_packs():
		var pid := String(p.get("id", ""))
		if not coupons.has(p.get("coupon")):
			errs.append("driver_gacha.json: pack %s coupon lạ" % pid)
		for key in ["price_x1", "price_x10", "pity_draws"]:
			if not _is_num(p.get(key)) or int(p[key]) <= 0:
				errs.append("driver_gacha.json: pack %s.%s phải là số nguyên dương" % [pid, key])
		if not ids.has(p.get("pity_tier")):
			errs.append("driver_gacha.json: pack %s pity_tier lạ" % pid)
		var tiers: Variant = p.get("tiers")
		if typeof(tiers) != TYPE_DICTIONARY or (tiers as Dictionary).is_empty():
			errs.append("driver_gacha.json: pack %s thiếu tiers" % pid)
			continue
		var sum := 0.0
		for r in tiers:
			if not ids.has(r) or not _is_num(tiers[r]) or float(tiers[r]) <= 0.0:
				errs.append("driver_gacha.json: pack %s tier %s không hợp lệ" % [pid, r])
				continue
			sum += float(tiers[r])
			var has_driver := false
			for d: Dictionary in drivers():
				if int(d["tier"]) == ids.find(r):
					has_driver = true
			if not has_driver:
				errs.append("driver_gacha.json: pack %s tier %s không có tay đua nào" % [pid, r])
		if absf(sum - 100.0) > 0.001:
			errs.append("driver_gacha.json: pack %s tỉ lệ phải cộng đủ 100%%" % pid)
		if (tiers as Dictionary).has(p.get("pity_tier")) == false:
			errs.append("driver_gacha.json: pack %s pity_tier phải nằm trong tiers" % pid)
	return errs


static func _validate_gear() -> Array:
	var errs: Array = []
	var g: Variant = _load("gear")
	if typeof(g) != TYPE_DICTIONARY or (g as Dictionary).is_empty():
		return errs  # đã báo ở bước đọc tệp
	var rarities: Dictionary = (g as Dictionary).get("rarity_defaults", {})
	var coupons: Array = gear_coupon_types()
	for p: Dictionary in gear_packs():
		var pid := String(p.get("id", ""))
		if not coupons.has(p.get("coupon")):
			errs.append("gear.json: pack %s coupon lạ" % pid)
		for key in ["price_x1", "price_x10"]:
			if not _is_num(p.get(key)) or float(p[key]) != floor(float(p[key])) or int(p[key]) <= 0:
				errs.append("gear.json: pack %s.%s phải là số nguyên dương" % [pid, key])
		var tiers: Variant = p.get("tiers")
		var sum := 0.0
		if typeof(tiers) != TYPE_DICTIONARY or (tiers as Dictionary).is_empty():
			errs.append("gear.json: pack %s thiếu tiers" % pid)
			continue
		for r in tiers:
			if not rarities.has(r) or not _is_num(tiers[r]) or float(tiers[r]) <= 0.0:
				errs.append("gear.json: pack %s tier %s không hợp lệ" % [pid, r])
			else:
				sum += float(tiers[r])
				var has_item := false
				for it: Dictionary in gear_items():
					if it["rarity"] == r:
						has_item = true
				if not has_item:
					errs.append("gear.json: pack %s tier %s không có phụ kiện" % [pid, r])
		if not is_equal_approx(sum, 100.0):
			errs.append("gear.json: pack %s tỉ lệ cộng %.2f, cần 100" % [pid, sum])
	var seen := {}
	for it: Dictionary in gear_items():
		var id := String(it.get("id", ""))
		if id == "" or seen.has(id):
			errs.append("gear.json: id phụ kiện rỗng/trùng: " + id)
		seen[id] = true
		if not rarities.has(it.get("rarity")):
			errs.append("gear.json: %s độ hiếm lạ" % id)
			continue
		var c := gear_config(id)
		var maxl: Variant = c.get("max_level")
		var initl: Variant = c.get("initial_level")
		if not _is_num(maxl) or not _is_num(initl) or int(initl) < 0 or int(maxl) < int(initl) or float(maxl) != floor(float(maxl)):
			errs.append("gear.json: %s initial_level/max_level không hợp lệ" % id)
			continue
		var table: Variant = c.get("level_up_shards")
		var stats: Variant = c.get("stats_by_level")
		if typeof(table) != TYPE_ARRAY or (table as Array).size() < int(maxl):
			errs.append("gear.json: %s level_up_shards thiếu mốc tới max_level" % id)
		else:
			for lv in range(int(initl), int(maxl)):
				var need: Variant = table[lv]
				if not _is_num(need) or float(need) != floor(float(need)) or int(need) <= 0:
					errs.append("gear.json: %s level_up_shards[%d] phải là số nguyên dương" % [id, lv])
		if typeof(stats) != TYPE_ARRAY or (stats as Array).size() < int(maxl) + 1:
			errs.append("gear.json: %s stats_by_level thiếu level" % id)
		else:
			for lv in range(int(initl), int(maxl) + 1):
				var st: Variant = stats[lv]
				if typeof(st) != TYPE_DICTIONARY or not _is_num(st.get("attack")) or not _is_num(st.get("defense")):
					errs.append("gear.json: %s stats_by_level[%d] thiếu attack/defense" % [id, lv])
		var dup: Variant = c.get("duplicate_shards")
		if not _is_num(dup) or float(dup) != floor(float(dup)) or int(dup) < 0:
			errs.append("gear.json: %s duplicate_shards không hợp lệ" % id)
	return errs
