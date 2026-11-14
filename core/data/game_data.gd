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
static var _override: Dictionary = {}
static var _cache_rev := -1  # I18n.revision của _cache (chữ trong data đã dịch theo ngôn ngữ)  # dùng cho lab/test: ghi đè theo tên tệp


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
	if _cache_rev != I18n.revision:
		_cache.clear()
		_cache_rev = I18n.revision
	if _cache.has(file_name):
		return _cache[file_name]
	var path := DIR + file_name + ".json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("Could not read data: " + path)
		parsed = {}
	parsed = I18n.translate_tree(parsed)  # chuỗi hiển thị theo ngôn ngữ đang chọn (i18n/<lang>.json)
	_cache[file_name] = parsed
	return parsed


static func sim() -> Dictionary:
	return _load("sim")


## Quảng cáo thưởng: trần ngày và cấu hình từng placement (data/ads.json, Design/25).
static func ads() -> Dictionary:
	return _load("ads")


## Hệ số của boost thu nhập xem quảng cáo (số nguyên >= 2; thiếu cấu hình thì 2).
static func ads_boost_multiplier() -> int:
	var p: Dictionary = (ads().get("placements", {}) as Dictionary).get("income_boost", {})
	return maxi(2, int(p.get("multiplier", 2)))


## Danh mục IAP (data/iap.json, Design/28).
static func iap() -> Dictionary:
	return _load("iap")


## Thưởng đăng nhập hằng ngày (data/daily_rewards.json, Design/30).
static func daily_rewards() -> Dictionary:
	return _load("daily_rewards")


static func iap_products() -> Array:
	return iap().get("products", [])


static func iap_product(sku: String) -> Dictionary:
	for p: Dictionary in iap_products():
		if String(p.get("sku", "")) == sku:
			return p
	return {}


static func economy() -> Dictionary:
	return _load("economy")


static func tracks() -> Array:
	return (_load("tracks") as Dictionary).get("tracks", [])


static func leagues() -> Array:
	return (_load("leagues") as Dictionary).get("leagues", [])


## Class đua (bộ môn, Design/22): danh sách theo thứ tự hiển thị.
static func race_classes() -> Array:
	return (_load("classes") as Dictionary).get("classes", [])


static func race_class(id: String) -> Dictionary:
	for c: Dictionary in race_classes():
		if c["id"] == id:
			return c
	return {}


static func default_class_id() -> String:
	return String((_load("classes") as Dictionary).get("default_class", "racing"))


## Hệ số giá mở cơ sở thứ 2, 3, … so với phí mở rộng giải hiện tại (cơ sở đầu miễn phí).
static func facility_price_mults() -> Array:
	return (_load("classes") as Dictionary).get("facility_price_mult", [])


## Bộ ghi đè cho TrafficSim.setup(opts): {"tuning", "traffic_tuning"}. Racing (hệ số rỗng) trả về rỗng nên kết quả không đổi.
static func class_opts(id: String) -> Dictionary:
	var c := race_class(id)
	var out := {"tuning": {}, "traffic_tuning": {}}
	if c.is_empty():
		return out
	var sm := sim()
	for k: String in c.get("tuning_mult", {}):
		out["tuning"][k] = float(sm[k]) * float(c["tuning_mult"][k])
	for k: String in c.get("traffic_mult", {}):
		out["traffic_tuning"][k] = float(sm["traffic"][k]) * float(c["traffic_mult"][k])
	var form: Array = c.get("form", [])
	if form.size() == 2:
		out["tuning"]["form_min"] = float(form[0])
		out["tuning"]["form_max"] = float(form[1])
	return out


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
	push_error("Track not found: " + id)
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
		return ["sim.json: ai_cars must be an array"]
	var list := cars_cfg as Array
	if list.size() != (sm["ai_offsets"] as Array).size():
		errs.append("sim.json: ai_cars has %d bots, needs %d (the number of AI cars)" % [list.size(), (sm["ai_offsets"] as Array).size()])
	var names := {}
	var traits := sm["traits"] as Dictionary
	var slots := {}
	for i in list.size():
		var b: Variant = list[i]
		var tag := "ai_cars[%d]" % i
		if typeof(b) != TYPE_DICTIONARY:
			errs.append("sim.json: %s must be an object" % tag)
			continue
		var d := b as Dictionary
		var nm := String(d.get("name", ""))
		if nm == "":
			errs.append("sim.json: %s is missing name" % tag)
		elif names.has(nm):
			errs.append("sim.json: %s duplicates bot name %s" % [tag, nm])
		names[nm] = true
		tag = "ai_cars[%d] %s" % [i, nm]
		if d.has("offset") and (not _is_num(d["offset"]) or not is_finite(float(d["offset"]))):
			errs.append("sim.json: %s.offset must be a finite number" % tag)
		if d.has("stats"):
			if typeof(d["stats"]) != TYPE_DICTIONARY:
				errs.append("sim.json: %s.stats must be an object" % tag)
			else:
				for k in (d["stats"] as Dictionary).keys():
					if not SIM_STAT_KEYS.has(String(k)):
						errs.append("sim.json: %s.stats has unknown stat %s (only S,H,B,A,P,T,C,L,R,K,E)" % [tag, k])
					elif not _is_num(d["stats"][k]) or not is_finite(float(d["stats"][k])):
						errs.append("sim.json: %s.stats.%s must be a finite number" % [tag, k])
		if d.has("trait") and String(d["trait"]) != "" and (not traits.has(String(d["trait"])) or not TRAIT_IDS.has(String(d["trait"]))):
			errs.append("sim.json: %s.trait is invalid: %s" % [tag, d["trait"]])
		if d.has("style") and not STYLE_IDS.has(String(d["style"])):
			errs.append("sim.json: %s.style is invalid: %s" % [tag, d["style"]])
		if d.has("form") and (not _is_num(d["form"]) or float(d["form"]) < 0.8 or float(d["form"]) > 1.2):
			errs.append("sim.json: %s.form must be a number in [0.8, 1.2]" % tag)
		if d.has("grid_slot"):
			if not _is_num(d["grid_slot"]) or int(d["grid_slot"]) < 0 or int(d["grid_slot"]) > list.size():
				errs.append("sim.json: %s.grid_slot must be an integer in [0, %d]" % [tag, list.size()])
			elif slots.has(int(d["grid_slot"])):
				errs.append("sim.json: %s.grid_slot duplicates another bot (%d)" % [tag, int(d["grid_slot"])])
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
	for f in ["sim", "economy", "tracks", "leagues", "cars", "drivers", "garage_cosmetics", "gear", "driver_gacha", "classes", "trophy_upgrades", "ads", "iap", "daily_rewards"]:
		var d: Variant = _load(f)
		if typeof(d) != TYPE_DICTIONARY or (d as Dictionary).is_empty():
			errs.append("%s.json is empty or unreadable" % f)
		elif int((d as Dictionary).get("schema_version", 0)) < 1:
			errs.append("%s.json is missing schema_version" % f)
	if not errs.is_empty():
		return errs

	errs.append_array(_validate_economy(ec))
	errs.append_array(_validate_gear())
	errs.append_array(_validate_driver_gacha())
	errs.append_array(_validate_classes())
	errs.append_array(_validate_trophy_upgrades())
	errs.append_array(_validate_ads())
	errs.append_array(_validate_iap())
	errs.append_array(_validate_daily_rewards())
	if not errs.is_empty():
		return errs

	# Vòng lặp đua liên tục (Design/10 §4): báo rõ trường sai, không cho chạy với thời lượng ≤ 0.
	var rl: Variant = sm.get("race_loop")
	if typeof(rl) != TYPE_DICTIONARY:
		errs.append("sim.json: missing race_loop group")
	else:
		var rlaps: Variant = (rl as Dictionary).get("race_laps")
		if not _is_num(rlaps) or not is_finite(float(rlaps)) or float(rlaps) < 1.0:
			errs.append("sim.json: race_loop.race_laps must be a finite number >= 1")
		var rfac: Variant = (rl as Dictionary).get("race_time_factor")
		if not _is_num(rfac) or not is_finite(float(rfac)) or float(rfac) <= 0.0:
			errs.append("sim.json: race_loop.race_time_factor must be a finite number > 0")
		var spr: Variant = (rl as Dictionary).get("sprint_duration_seconds")
		if not _is_num(spr) or not is_finite(float(spr)) or float(spr) < 0.0:
			errs.append("sim.json: race_loop.sprint_duration_seconds must be a finite number >= 0")

	var lap: float = sm["lap_length"]
	var track_ids := {}
	for t: Dictionary in tracks():
		var id: String = t["id"]
		if track_ids.has(id):
			errs.append("Duplicate track id: " + id)
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
				errs.append("%s: unknown sector type %s" % [id, s["type"]])
		var t_lap: float = float(t.get("lap_length", lap))
		if not is_equal_approx(total, t_lap):
			errs.append("%s: sectors add up to %.1f, needs %.1f per lap" % [id, total, t_lap])
		if not has_zone:
			errs.append("%s: no straight to overtake on" % id)
		if absf(straight / t_lap * 100.0 - float(t["straight_pct"])) > 0.51:
			errs.append("%s: straight_pct does not match sectors" % id)
		for part in t.get("important", []):
			if not ["engine", "tyre", "chassis", "gearbox"].has(part):
				errs.append("%s: unknown important value %s" % [id, part])
		# Hình học và bề rộng (Design/08 §3): chỉ kiểm khi track khai báo.
		var turns := 0
		for s: Dictionary in t["sectors"]:
			if s.has("width") and float(s["width"]) < 3.0:
				errs.append("%s: sector width < 3 car widths" % id)
			if s.has("width_end") and float(s["width_end"]) < 3.0:
				errs.append("%s: sector end width < 3 car widths" % id)
			if s.has("turn"):
				turns += 1
		if turns > 0:
			var lay := TrackLayout.build(id)
			if not lay.valid:
				errs.append("%s: every corner sector needs a turn" % id)
			else:
				if lay.closure_error > 1.0:
					errs.append("%s: track is not closed (error %.2f units)" % [id, lay.closure_error])
				if absf(absf(lay.total_turn) - 360.0) > 0.5:
					errs.append("%s: total turn angle %.1f, needs ±360" % [id, lay.total_turn])
				var max_w := 0.0
				for w in lay.widths:
					max_w = maxf(max_w, w)
				var road: float = max_w * float(sm["car_width"])
				if lay.min_clearance() < road * 1.3:
					errs.append("%s: two track segments are too close together" % id)

	var ls := leagues()
	if ls.size() != 6:
		errs.append("Need 6 leagues, found %d" % ls.size())
	for i in ls.size():
		var l: Dictionary = ls[i]
		if int(l["index"]) != i:
			errs.append("league %s: index sai" % l["id"])
		if (l["schedule"] as Array).is_empty():
			errs.append("League %s: track schedule is empty" % l["id"])
		for tid in l["schedule"]:
			if not track_ids.has(tid):
				errs.append("League %s: track does not exist %s" % [l["id"], tid])
		if i > 0 and int(l["car_base"]) <= int((ls[i - 1] as Dictionary)["car_base"]):
			errs.append("League %s: car_base must be increasing" % l["id"])

	var cs := cars()
	if cs.size() != 15:
		errs.append("Need 15 cars, found %d" % cs.size())
	var car_ids := {}
	var per_class := {}
	var starters := 0
	for c: Dictionary in cs:
		if car_ids.has(c["id"]):
			errs.append("Duplicate car id: " + c["id"])
		car_ids[c["id"]] = true
		if typeof(c.get("price")) != TYPE_STRING or BigNumber.parse_decimal(c.get("price", "")) == null:
			errs.append("%s: price must be a BigNumber string" % c["id"])
			continue
		if int(c.get("entry_tier", -1)) < 0 or int(c.get("entry_tier", -1)) > 5:
			errs.append("%s: entry_tier is invalid" % c["id"])
		per_class[int(c["class"])] = int(per_class.get(int(c["class"]), 0)) + 1
		for k in PART_KEYS:
			if not (c["base"] as Dictionary).has(k):
				errs.append("%s is missing base.%s" % [c["id"], k])
		if bool(c.get("starter", false)):
			starters += 1
			if not BigNumber.parse_decimal(c["price"]).is_zero():
				errs.append("The starter car must be free")
	if starters != 1:
		errs.append("Need exactly 1 starter car, found %d" % starters)
	for k in range(1, 6):
		if int(per_class.get(k, 0)) != 3:
			errs.append("Tier %d needs 3 cars" % k)

	var ds := drivers()
	if ds.size() != 12:
		errs.append("Need 12 drivers, found %d" % ds.size())
	var drv_ids := {}
	var traits := sm["traits"] as Dictionary
	for d: Dictionary in ds:
		if drv_ids.has(d["id"]):
			errs.append("Duplicate driver id: " + d["id"])
		drv_ids[d["id"]] = true
		if typeof(d.get("coin_cost_base")) != TYPE_STRING or BigNumber.parse_decimal(d.get("coin_cost_base", "")) == null:
			errs.append("%s: coin_cost_base is invalid" % d["id"])
		if int(d.get("entry_tier", -1)) < 0 or int(d.get("entry_tier", -1)) > 5:
			errs.append("%s: entry_tier is invalid" % d["id"])
		var tr: String = d["trait"]
		if tr != "" and not traits.has(tr):
			errs.append("%s: trait is not in sim.json: %s" % [d["id"], tr])
		if tr != "" and not TRAIT_IDS.has(tr):
			errs.append("%s: trait is not supported by the simulation: %s" % [d["id"], tr])
		if int(d["tier"]) < 0 or int(d["tier"]) > 3:
			errs.append("%s: tier outside 0–3" % d["id"])
		if not STYLE_IDS.has(String(d.get("style", ""))):
			errs.append("%s: style is invalid: %s" % [d["id"], d.get("style", "")])
		for key in ["pace", "technique", "composure", "launch", "braking", "racecraft", "endurance"]:
			if not _is_num(d.get(key)) or float(d[key]) < 0.0 or float(d[key]) > 100.0:
				errs.append("%s: %s must be a number in [0, 100]" % [d["id"], key])
	var styles_cfg: Dictionary = sm.get("styles", {})
	for sid in styles_cfg.keys():
		if not STYLE_IDS.has(sid):
			errs.append("sim.json has an unsupported style: " + sid)
	for sid in STYLE_IDS:
		if not styles_cfg.has(sid):
			errs.append("sim.json is missing style: " + sid)
	for blk in ["driver_stats", "stamina"]:
		if not sm.has(blk):
			errs.append("sim.json is missing block " + blk)
	for tr in traits.keys():
		if not TRAIT_IDS.has(tr):
			errs.append("sim.json has an unsupported trait: " + tr)

	if (sm["ai_offsets"] as Array).size() != int(sm["ai_names"].size()):
		errs.append("ai_offsets and ai_names must have the same length")
	errs.append_array(_validate_ai_cars(sm))
	if (sm["ai_offsets"] as Array).size() + 1 != (ec["race_rewards"] as Array).size():
		errs.append("Car count (AI+1) must equal the number of race_rewards rows")
	var prev_pts := 1000
	for r in ec["race_rewards"]:
		if int(r[0]) >= prev_pts:
			errs.append("race_rewards must decrease by position")
		prev_pts = int(r[0])
	return errs


static func _validate_economy(ec: Dictionary) -> Array:
	var errs: Array = []
	for key in ["business", "rewards", "revenue_upgrades", "offline", "scout"]:
		if typeof(ec.get(key)) != TYPE_DICTIONARY:
			errs.append("economy.json: missing group " + key)
	if not errs.is_empty():
		return errs
	var ml := int(ec.get("max_level", 0))
	var sub := int(ec.get("level_subdivision", 0))
	if int(ec.get("economy_version", 0)) != 2 or ml < 1 or ml > 1000:
		errs.append("economy.json: needs economy_version=2 and max_level in 1..1000")
	if sub < 1 or sub > 100:
		errs.append("economy.json: level_subdivision outside 1..100")
	for key in ["duration_factor", "part_stat_per_level"]:
		var v: Variant = ec.get(key)
		var n := BigNumber.parse_decimal(v) if typeof(v) == TYPE_STRING else null
		if n == null or n.is_zero() or absi(n.exponent) > 1000:
			errs.append("economy.json: %s must be a positive decimal string" % key)
	var by_part: Variant = ec.get("part_stat_per_level_by_part", {})
	if typeof(by_part) != TYPE_DICTIONARY:
		errs.append("economy.json: part_stat_per_level_by_part must be an object")
	else:
		for kind in by_part:
			var pv: Variant = (by_part as Dictionary)[kind]
			var pn := BigNumber.parse_decimal(pv) if typeof(pv) == TYPE_STRING else null
			if not kind in ["engine", "tyre", "chassis", "gearbox"] or pn == null or pn.is_zero() or absi(pn.exponent) > 1000:
				errs.append("economy.json: part_stat_per_level_by_part.%s is invalid" % kind)
	for key in ["start_coins", "base_rate", "upgrade_growth", "part_cost_base"]:
		if typeof(ec.get(key)) != TYPE_STRING or BigNumber.parse_decimal(ec.get(key, "")) == null:
			errs.append("economy.json: " + key + " must be a valid decimal string")
	if not errs.is_empty():
		return errs
	if BigNumber.parse_decimal(ec["upgrade_growth"]).compare(BigNumber.from_int(1)) <= 0:
		errs.append("economy.json: upgrade_growth must be > 1")
	if BigNumber.parse_decimal(ec["upgrade_growth"]).compare(BigNumber.from_int(10)) > 0:
		errs.append("economy.json: upgrade_growth must be <= 10")
	for key in ["start_coins", "base_rate", "part_cost_base"]:
		if absi(BigNumber.parse_decimal(ec[key]).exponent) > 1000:
			errs.append("economy.json: " + key + " is out of range")
	if BigNumber.parse_decimal(ec["base_rate"]).is_zero() or BigNumber.parse_decimal(ec["part_cost_base"]).is_zero():
		errs.append("economy.json: rate and base price must be > 0")
	var part_bases: Variant = ec.get("part_cost_bases", {})
	if typeof(part_bases) != TYPE_DICTIONARY:
		errs.append("economy.json: part_cost_bases must be an object")
	else:
		for kind in part_bases.keys():
			var pb: Variant = part_bases[kind]
			var pn := BigNumber.parse_decimal(pb) if typeof(pb) == TYPE_STRING else null
			if not Balance.PARTS.has(kind) or pn == null or pn.is_zero() or absi(pn.exponent) > 1000:
				errs.append("economy.json: part_cost_bases.%s is invalid" % kind)
	var business: Dictionary = ec["business"]
	for key in ["scale_exponents", "pacing"]:
		if typeof(business.get(key)) != TYPE_ARRAY or business[key].size() != 6:
			errs.append("economy.json: business." + key + " needs 6 elements")
	if not errs.is_empty():
		return errs
	var previous := -1
	for e in business["scale_exponents"]:
		if not _is_num(e) or float(e) != floor(float(e)) or int(e) <= previous or int(e) > 10000:
			errs.append("economy.json: scale_exponents must be increasing integers <= 10000")
		previous = int(e)
	for q in business["pacing"]:
		if not _is_num(q) or not is_finite(float(q)) or float(q) != floor(float(q)) or int(q) <= 0 or int(q) > 1000000:
			errs.append("economy.json: pacing must be a positive integer <= 1000000")
	for key in ["reference_revenue_level", "expansion_min_revenue_level"]:
		if not business.has(key) or int(business[key]) < 0 or int(business[key]) > ml:
			errs.append("economy.json: business." + key + " outside 0..max_level")
	for key in ["expansion_rate_seconds", "required_car_rate_seconds"]:
		if not business.has(key) or int(business[key]) <= 0 or int(business[key]) > 604800:
			errs.append("economy.json: business." + key + " is invalid")
	if typeof(business.get("opening_reserve_base")) != TYPE_STRING or BigNumber.parse_decimal(business.get("opening_reserve_base", "")) == null:
		errs.append("economy.json: opening_reserve_base is invalid")
	var stars: Variant = ec.get("revenue_stars", {})
	if typeof(stars) != TYPE_DICTIONARY:
		errs.append("economy.json: revenue_stars must be an object")
	else:
		var star_mult: Variant = stars.get("multiplier", "1")
		var sm := BigNumber.parse_decimal(star_mult) if typeof(star_mult) == TYPE_STRING else null
		if sm == null or sm.compare(BigNumber.from_int(1)) < 0 or sm.compare(BigNumber.from_int(10)) > 0:
			errs.append("economy.json: revenue_stars.multiplier must be within 1..10")
		for m in stars.get("levels", []):
			if int(m) < 1 or int(m) > ml:
				errs.append("economy.json: revenue_stars.levels outside 1..max_level")
	var revenue: Dictionary = ec["revenue_upgrades"]
	if revenue.size() != 4:
		errs.append("economy.json: needs exactly 4 revenue sources")
	for kind in ["ticket", "celebration", "parking", "grandstands"]:
		if typeof(revenue.get(kind)) != TYPE_DICTIONARY:
			errs.append("economy.json: missing source " + kind)
			continue
		if typeof(revenue[kind]) == TYPE_DICTIONARY and revenue[kind].has("growth"):
			var growth: Variant = revenue[kind]["growth"]
			var gn := BigNumber.parse_decimal(growth) if typeof(growth) == TYPE_STRING else null
			if gn == null or gn.compare(BigNumber.from_int(1)) < 0 or gn.compare(BigNumber.from_int(2)) > 0:
				errs.append("economy.json: revenue_upgrades.%s.growth must be within 1..2" % kind)
		for key in ["base", "per_level", "cost"]:
			var value: Variant = revenue[kind].get(key)
			var number := BigNumber.parse_decimal(value) if typeof(value) == TYPE_STRING else null
			if number == null or absi(number.exponent) > 1000 or (key != "base" and number.is_zero()) or (kind == "grandstands" and key == "base" and number.is_zero()):
				errs.append("economy.json: revenue_upgrades.%s.%s is invalid" % [kind, key])
	var rewards: Dictionary = ec["rewards"]
	for key in ["race_ratio", "participation_ratio"]:
		var value: Variant = rewards.get(key)
		var number := BigNumber.parse_decimal(value) if typeof(value) == TYPE_STRING else null
		if number == null or number.compare(BigNumber.from_int(1)) > 0:
			errs.append("economy.json: rewards." + key + " outside 0..1")
	if typeof(rewards.get("position_factors")) != TYPE_ARRAY or rewards["position_factors"].size() != 8:
		errs.append("economy.json: needs 8 position_factors")
	else:
		for value in rewards["position_factors"]:
			var number := BigNumber.parse_decimal(value) if typeof(value) == TYPE_STRING else null
			if number == null or number.is_zero() or number.compare(BigNumber.from_int(1)) > 0:
				errs.append("economy.json: position_factor outside (0..1]")
	for key in ["daily_rate_seconds", "daily_gems", "first_league_gems"]:
		if not rewards.has(key) or not _is_num(rewards[key]) or float(rewards[key]) != floor(float(rewards[key])) or int(rewards[key]) < 0 or int(rewards[key]) > 604800:
			errs.append("economy.json: rewards." + key + " is invalid")
	var offline: Dictionary = ec["offline"]
	var ratio := BigNumber.parse_decimal(offline.get("ratio", "")) if typeof(offline.get("ratio")) == TYPE_STRING else null
	if ratio == null or ratio.compare(BigNumber.from_int(1)) > 0:
		errs.append("economy.json: offline.ratio outside 0..1")
	if not _is_num(offline.get("cap_sec")) or float(offline["cap_sec"]) < 0 or float(offline["cap_sec"]) > 604800:
		errs.append("economy.json: offline.cap_sec is invalid")
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


## Hệ số đổi điểm kiếm+khiên thành Power cộng cho mỗi chỉ số đội.
static func gear_power_per_point() -> float:
	return float((_load("gear") as Dictionary).get("power_per_point", 0.0))


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


# ---------- Nâng cấp bằng cúp (data/trophy_upgrades.json) ----------

const TROPHY_EFFECT_KEYS := ["S", "H", "B", "A", "race_bonus_seconds", "daily_bonus_seconds"]


static func trophy_upgrades() -> Array:
	return (_load("trophy_upgrades") as Dictionary).get("upgrades", [])


static func trophy_upgrade(id: String) -> Dictionary:
	for u: Dictionary in trophy_upgrades():
		if u["id"] == id:
			return u
	return {}


static func trophy_groups() -> Array:
	return (_load("trophy_upgrades") as Dictionary).get("groups", [])


## Nhãn và đơn vị hiển thị của từng khóa hiệu ứng (S/A/H/B, giây thu nhập).
static func trophy_effect_labels() -> Dictionary:
	return (_load("trophy_upgrades") as Dictionary).get("effect_labels", {})


static func trophy_effect_units() -> Dictionary:
	return (_load("trophy_upgrades") as Dictionary).get("effect_units", {})


## Trần tổng cúp được kiếm khi chưa có phần nâng thêm (cơ chế nâng trần sẽ cộng vào GameState).
static func trophy_cap_base() -> int:
	return int(((_load("trophy_upgrades") as Dictionary).get("cap", {}) as Dictionary).get("base", 0))


## Trần cúp theo giải (cap.by_league); thiếu bảng thì dùng trần gốc. Giải ngoài bảng lấy mục cuối.
static func trophy_cap_for_league(league: int) -> int:
	var by_league: Array = ((_load("trophy_upgrades") as Dictionary).get("cap", {}) as Dictionary).get("by_league", [])
	if by_league.is_empty():
		return trophy_cap_base()
	return int(by_league[clampi(league, 0, by_league.size() - 1)])


## Cúp nhận được ở một vị trí (1..8) tại một giải; từ P4 trở xuống là 0.
static func trophy_reward(position: int, league: int) -> int:
	var earn: Dictionary = (_load("trophy_upgrades") as Dictionary).get("earn", {})
	var by_pos: Array = earn.get("by_position", [])
	var mult: Array = earn.get("league_multiplier", [])
	if position < 1 or position > by_pos.size() or league < 0 or league >= mult.size():
		return 0
	return int(by_pos[position - 1]) * int(mult[league])


const AD_REWARD_KINDS := ["", "boost", "income_seconds", "gems", "driver_coupon", "gear_coupon", "offline_double", "race_bonus", "daily_double"]


## data/ads.json: loại thưởng hợp lệ, số dương, coupon/tính năng mở khóa phải tồn tại (Design/26).
const IAP_KINDS := ["gems", "perk", "starter", "offer", "character", "daily", "weekly", "pass_month", "pass_growth"]
const IAP_PERKS := ["no_ads", "income_x2", "income_x3", "offline_plus"]


## Kiểm tra data/daily_rewards.json (Design/30 §3, §4): 6 ô thường, 7 vòng Grand, >= 1 mốc, coupon hợp lệ, số dương.
static func _validate_daily_rewards() -> Array:
	var errs: Array = []
	var d := daily_rewards()
	if int(d.get("milestone_interval", 0)) < 1:
		errs.append("daily_rewards.json: milestone_interval must be >= 1")
	var sc: Variant = d.get("gem_scale", 1.0)
	if (typeof(sc) != TYPE_FLOAT and typeof(sc) != TYPE_INT) or float(sc) <= 0.0:
		errs.append("daily_rewards.json: gem_scale must be > 0")
	if Tutorial.feature(String(d.get("unlock", ""))).is_empty():
		errs.append("daily_rewards.json: unlock '%s' is not a feature in tutorial.json" % String(d.get("unlock", "")))
	var sizes := {"cycle": 6, "grand": 7}
	for key in ["cycle", "grand", "milestones"]:
		var arr: Variant = d.get(key)
		if typeof(arr) != TYPE_ARRAY or (arr as Array).is_empty():
			errs.append("daily_rewards.json: %s must be a non-empty array" % key)
			continue
		if sizes.has(key) and (arr as Array).size() != int(sizes[key]):
			errs.append("daily_rewards.json: %s must have exactly %d entries" % [key, int(sizes[key])])
		for i in (arr as Array).size():
			errs.append_array(_validate_daily_reward("daily_rewards.json %s[%d]: " % [key, i], arr[i]))
	return errs


static func _validate_daily_reward(where: String, r: Variant) -> Array:
	var errs: Array = []
	if typeof(r) != TYPE_DICTIONARY:
		return [where + "must be an object"]
	var total := 0
	for key in r:
		match String(key):
			"gems":
				if not _is_pos_int(r[key]):
					errs.append(where + "gems must be an integer > 0")
				total += 1
			"driver_coupon", "gear_coupon":
				var types: Array = driver_coupon_types() if String(key) == "driver_coupon" else gear_coupon_types()
				if typeof(r[key]) != TYPE_DICTIONARY or (r[key] as Dictionary).is_empty():
					errs.append(where + "%s must be a non-empty object" % key)
					continue
				for kind in (r[key] as Dictionary):
					if not String(kind) in types:
						errs.append(where + "%s: type '%s' does not exist" % [key, kind])
					if not _is_pos_int(r[key][kind]):
						errs.append(where + "%s.%s must be an integer > 0" % [key, kind])
				total += 1
			_:
				errs.append(where + "unknown key '%s'" % key)
	if total == 0:
		errs.append(where + "no reward")
	return errs


static func _is_pos_int(v: Variant) -> bool:
	return (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(float(v)) and float(v) == floor(float(v)) and float(v) > 0.0


## Kiểm tra data/iap.json (Design/28 §6). SKU/usd/consumable phải khớp horus-game.json (kiểm ở tests/iap_test.gd).
static func _validate_iap() -> Array:
	var errs: Array = []
	var d := iap()
	var feature_ids: Array = []
	for f: Dictionary in (_load("tutorial") as Dictionary).get("features", []):
		feature_ids.append(String(f.get("id", "")))
	var pop: Variant = d.get("popup")
	if typeof(pop) != TYPE_DICTIONARY or not _is_num((pop as Dictionary).get("gap_sec")) or float((pop as Dictionary)["gap_sec"]) <= 0.0 \
			or not _is_num((pop as Dictionary).get("per_day")) or int((pop as Dictionary)["per_day"]) < 1:
		errs.append("iap.json: popup.gap_sec must be > 0 and popup.per_day >= 1")
	var flags: Variant = d.get("flags", {})
	if typeof(flags) != TYPE_DICTIONARY:
		errs.append("iap.json: flags must be an object")
		flags = {}
	if not _is_num(d.get("owned_driver_shards")) or int(d["owned_driver_shards"]) < 0:
		errs.append("iap.json: owned_driver_shards must be a number >= 0")
	var products := iap_products()
	if products.is_empty():
		errs.append("iap.json: missing products")
		return errs
	var skus := {}
	for p: Dictionary in products:
		skus[String(p.get("sku", ""))] = p
	var perks := {}
	for p: Dictionary in products:
		var g: Variant = p.get("grant", {})
		if typeof(g) == TYPE_DICTIONARY and (g as Dictionary).has("perk"):
			perks[String((g as Dictionary)["perk"])] = true
	var seen := {}
	for p: Dictionary in products:
		var sku := String(p.get("sku", ""))
		var where := "iap.json %s: " % sku
		if sku == "" or seen.has(sku):
			errs.append(where + "SKU is empty or duplicated")
		seen[sku] = true
		var kind := String(p.get("kind", ""))
		if not IAP_KINDS.has(kind):
			errs.append(where + "unknown kind '%s'" % kind)
		if not _is_num(p.get("usd")) or float(p["usd"]) <= 0.0:
			errs.append(where + "usd must be > 0")
		if typeof(p.get("consumable")) != TYPE_BOOL:
			errs.append(where + "consumable must be a bool")
		var g: Variant = p.get("grant")
		if typeof(g) != TYPE_DICTIONARY or (g as Dictionary).is_empty():
			errs.append(where + "missing grant")
			continue
		var grant: Dictionary = g
		if grant.has("gems") and (not _is_num(grant["gems"]) or int(grant["gems"]) < 1):
			errs.append(where + "grant.gems must be >= 1")
		if grant.has("income_min") and (not _is_num(grant["income_min"]) or int(grant["income_min"]) < 1):
			errs.append(where + "grant.income_min must be >= 1")
		if grant.has("perk") and not IAP_PERKS.has(String(grant["perk"])):
			errs.append(where + "unknown perk '%s'" % String(grant["perk"]))
		if grant.has("driver") and driver(String(grant["driver"])).is_empty():
			errs.append(where + "driver '%s' is not in drivers.json" % String(grant["driver"]))
		if grant.has("driver_shards") and (not _is_num(grant["driver_shards"]) or int(grant["driver_shards"]) < 1):
			errs.append(where + "grant.driver_shards must be >= 1")
		for key in ["driver_coupon", "gear_coupon"]:
			if not grant.has(key):
				continue
			var types: Array = driver_coupon_types() if key == "driver_coupon" else gear_coupon_types()
			if typeof(grant[key]) != TYPE_DICTIONARY:
				errs.append(where + "%s must be an object" % key)
				continue
			for ct in (grant[key] as Dictionary):
				if not types.has(String(ct)):
					errs.append(where + "%s: unknown coupon type '%s'" % [key, String(ct)])
				elif not _is_num(grant[key][ct]) or int(grant[key][ct]) < 1:
					errs.append(where + "%s.%s must be >= 1" % [key, String(ct)])
		for ref_key in ["requires", "hide_if_owned"]:
			for ref in (p.get(ref_key, []) as Array):
				if not skus.has(String(ref)) and not perks.has(String(ref)):
					errs.append(where + "%s points to '%s' which does not exist" % [ref_key, String(ref)])
		errs.append_array(_validate_iap_unlock(where, p.get("unlock", {}), feature_ids, skus))
		if p.has("flag") and not (flags as Dictionary).has(String(p["flag"])):
			errs.append(where + "flag '%s' is not in flags" % String(p["flag"]))
		match kind:
			"weekly":
				if not _is_num(p.get("weekly_limit")) or int(p["weekly_limit"]) < 1:
					errs.append(where + "weekly needs weekly_limit >= 1")
				if typeof(p.get("unlock")) != TYPE_DICTIONARY or not (p["unlock"] as Dictionary).has("tier"):
					errs.append(where + "weekly needs unlock.tier")
			"daily":
				if not _is_num(p.get("daily_limit")) or int(p["daily_limit"]) < 1:
					errs.append(where + "daily needs daily_limit >= 1")
			"character":
				if not grant.has("driver"):
					errs.append(where + "character needs grant.driver")
			"perk":
				if not grant.has("perk"):
					errs.append(where + "perk needs grant.perk")
				if bool(p.get("consumable", true)):
					errs.append(where + "perk must have consumable=false (restorable)")
			"pass_month":
				for key in ["days", "daily_gems", "max_days", "rebuy_when_left_days"]:
					if not _is_num(p.get(key)) or int(p[key]) < 1:
						errs.append(where + "pass_month needs %s >= 1" % key)
			"pass_growth":
				var last := 0
				var ms: Array = p.get("milestones", [])
				if ms.is_empty() or bool(p.get("consumable", true)):
					errs.append(where + "pass_growth needs milestones and consumable=false")
				for m in ms:
					if typeof(m) != TYPE_ARRAY or (m as Array).size() != 2 or int(m[0]) <= last or int(m[0]) > 5 or int(m[1]) < 1:
						errs.append(where + "milestones must increase with business_tier (<= 5), each milestone is [tier, gem]")
						break
					last = int(m[0])
	for sku2 in (d.get("feature_rotation", []) as Array):
		if not skus.has(String(sku2)) or String((skus[String(sku2)] as Dictionary).get("kind", "")) != "character":
			errs.append("iap.json: feature_rotation '%s' is not a character SKU" % String(sku2))
	return errs


static func _validate_iap_unlock(where: String, u: Variant, feature_ids: Array, skus: Dictionary) -> Array:
	var errs: Array = []
	if typeof(u) != TYPE_DICTIONARY:
		return [where + "unlock must be an object"]
	var ud: Dictionary = u
	if ud.has("tutorial") and not feature_ids.has(String(ud["tutorial"])):
		errs.append(where + "unlock.tutorial '%s' is not in tutorial.json" % String(ud["tutorial"]))
	if ud.has("bought") and not skus.has(String(ud["bought"])):
		errs.append(where + "unlock.bought '%s' does not exist" % String(ud["bought"]))
	for key in ["tier", "tier_before_driver", "ad_breaks_today"]:
		if ud.has(key) and (not _is_num(ud[key]) or int(ud[key]) < 0):
			errs.append(where + "unlock.%s must be >= 0" % key)
	if ud.has("any"):
		if typeof(ud["any"]) != TYPE_ARRAY or (ud["any"] as Array).is_empty():
			errs.append(where + "unlock.any must be a non-empty array")
		else:
			for sub in (ud["any"] as Array):
				errs.append_array(_validate_iap_unlock(where, sub, feature_ids, skus))
	return errs


static func _validate_ads() -> Array:
	var errs: Array = []
	var a := ads()
	if not _is_num(a.get("daily_cap")) or int(a["daily_cap"]) < 1:
		errs.append("ads.json: daily_cap must be a number >= 1")
	var places: Variant = a.get("placements")
	if typeof(places) != TYPE_DICTIONARY or (places as Dictionary).is_empty():
		errs.append("ads.json: missing placements")
		return errs
	var feature_ids: Array = []
	for f: Dictionary in (_load("tutorial") as Dictionary).get("features", []):
		feature_ids.append(String(f.get("id", "")))
	for id: String in places:
		var p: Dictionary = places[id]
		var where := "ads.json %s: " % id
		var kind := String(p.get("reward", ""))
		if not AD_REWARD_KINDS.has(kind):
			errs.append(where + "unknown reward '%s'" % kind)
		for key in ["daily_limit", "cooldown_sec"]:
			if not _is_num(p.get(key, 0)) or float(p.get(key, 0)) < 0.0:
				errs.append(where + "%s must be a number >= 0" % key)
		var unlock := String(p.get("unlock", ""))
		if unlock != "" and not feature_ids.has(unlock):
			errs.append(where + "unlock '%s' is not in tutorial.json" % unlock)
		match kind:
			"boost":
				if not _is_num(p.get("multiplier")) or int(p["multiplier"]) < 2 or float(p["multiplier"]) != float(int(p["multiplier"])):
					errs.append(where + "multiplier must be an integer >= 2")
				if not _is_num(p.get("duration_sec")) or float(p["duration_sec"]) <= 0.0:
					errs.append(where + "duration_sec must be > 0")
			"income_seconds":
				if not _is_num(p.get("seconds")) or float(p["seconds"]) <= 0.0:
					errs.append(where + "seconds must be > 0")
			"gems":
				if not _is_num(p.get("amount")) or int(p["amount"]) < 1:
					errs.append(where + "amount must be >= 1")
			"driver_coupon", "gear_coupon":
				var types: Array = driver_coupon_types() if kind == "driver_coupon" else gear_coupon_types()
				if not types.has(String(p.get("kind", ""))):
					errs.append(where + "kind '%s' is not a coupon type" % String(p.get("kind", "")))
				if not _is_num(p.get("count")) or int(p["count"]) < 1:
					errs.append(where + "count must be >= 1")
		if p.has("first_after_sec"):  # lịch lá cờ (Design/26 §4)
			for key in ["first_after_sec", "gap_sec", "cross_sec", "miss_limit", "miss_gap_max_sec"]:
				if not _is_num(p.get(key)) or float(p[key]) <= 0.0 and key != "first_after_sec":
					errs.append(where + "%s must be a number > 0" % key)
			if _is_num(p.get("gap_sec")) and _is_num(p.get("miss_gap_max_sec")) and float(p["miss_gap_max_sec"]) < float(p["gap_sec"]):
				errs.append(where + "miss_gap_max_sec must be >= gap_sec")
	var br: Variant = a.get("break")
	if typeof(br) == TYPE_DICTIONARY:
		for key in ["interFromRun", "sessionWarmup", "interEvery", "interCooldown", "rewardedGrace", "maxPerHour", "firstPlayMin", "bonusIncomeSec"]:
			if not _is_num((br as Dictionary).get(key)) or float((br as Dictionary)[key]) < 0.0:
				errs.append("ads.json break.%s must be a number >= 0" % key)
	return errs


static func _validate_trophy_upgrades() -> Array:
	var errs: Array = []
	var t: Variant = _load("trophy_upgrades")
	if typeof(t) != TYPE_DICTIONARY or (t as Dictionary).is_empty():
		return errs  # đã báo ở bước đọc tệp
	var earn: Dictionary = t.get("earn", {})
	var by_pos: Array = earn.get("by_position", [])
	if by_pos.size() != 8:
		errs.append("trophy_upgrades.json: earn.by_position needs 8 entries")
	for v in by_pos:
		if not _is_num(v) or float(v) < 0 or float(v) != floor(float(v)):
			errs.append("trophy_upgrades.json: earn.by_position must be an integer >= 0")
	var mult: Array = earn.get("league_multiplier", [])
	if mult.size() != leagues().size():
		errs.append("trophy_upgrades.json: earn.league_multiplier needs all %d leagues" % leagues().size())
	for v in mult:
		if not _is_num(v) or int(v) < 1:
			errs.append("trophy_upgrades.json: league_multiplier must be >= 1")
	if not _is_num((t.get("cap", {}) as Dictionary).get("base")) or trophy_cap_base() < 0:
		errs.append("trophy_upgrades.json: cap.base is invalid")
	var cap_by_league: Array = (t.get("cap", {}) as Dictionary).get("by_league", [])
	if not cap_by_league.is_empty():
		if cap_by_league.size() != leagues().size():
			errs.append("trophy_upgrades.json: cap.by_league needs all %d leagues" % leagues().size())
		var prev := 0
		for v in cap_by_league:
			if not _is_num(v) or int(v) < prev:
				errs.append("trophy_upgrades.json: cap.by_league must be non-decreasing numbers >= 0")
				break
			prev = int(v)
	var group_ids: Array = []
	for g: Dictionary in trophy_groups():
		group_ids.append(String(g.get("id", "")))
	var ids: Array = []
	for u: Dictionary in trophy_upgrades():
		var id := String(u.get("id", ""))
		if id == "" or ids.has(id):
			errs.append("trophy_upgrades.json: id is empty or duplicated: " + id)
		ids.append(id)
		if not group_ids.has(String(u.get("group", ""))):
			errs.append("trophy_upgrades.json: %s has an unknown group" % id)
		var n := int(u.get("max_level", 0))
		var costs: Array = u.get("cost_by_level", [])
		var effects: Array = u.get("effect_by_level", [])
		if n < 1 or costs.size() != n or effects.size() != n + 1:
			errs.append("trophy_upgrades.json: %s cost_by_level/effect_by_level do not match max_level" % id)
			continue
		var unlock := int(u.get("unlock_league", -1))
		if unlock < 0 or unlock >= leagues().size():
			errs.append("trophy_upgrades.json: %s unlock_league is out of range" % id)
		for c in costs:
			if not _is_num(c) or int(c) < 1:
				errs.append("trophy_upgrades.json: %s price must be a positive integer" % id)
		for lv in effects.size():
			if typeof(effects[lv]) != TYPE_DICTIONARY or (effects[lv] as Dictionary).is_empty():
				errs.append("trophy_upgrades.json: %s effect_by_level[%d] is invalid" % [id, lv])
				continue
			for k: String in effects[lv]:
				if not TROPHY_EFFECT_KEYS.has(k) or not _is_num(effects[lv][k]) or float(effects[lv][k]) < 0:
					errs.append("trophy_upgrades.json: %s effect[%d].%s is invalid" % [id, lv, k])
	return errs


static func _validate_classes() -> Array:
	var errs: Array = []
	var ids: Array = []
	var sm := sim()
	for c: Dictionary in race_classes():
		var id := String(c.get("id", ""))
		if id == "" or ids.has(id):
			errs.append("classes.json: id is empty or duplicated: " + id)
		ids.append(id)
		for k: String in c.get("tuning_mult", {}):
			if not sm.has(k) or float(c["tuning_mult"][k]) <= 0.0:
				errs.append("classes.json: %s tuning_mult.%s is invalid" % [id, k])
		for k: String in c.get("traffic_mult", {}):
			if not (sm.get("traffic", {}) as Dictionary).has(k) or float(c["traffic_mult"][k]) < 0.0:
				errs.append("classes.json: %s traffic_mult.%s is invalid" % [id, k])
		var form: Array = c.get("form", [])
		if not form.is_empty() and (form.size() != 2 or float(form[0]) > float(form[1]) or float(form[0]) <= 0.0):
			errs.append("classes.json: %s form is invalid" % id)
	if race_class(default_class_id()).is_empty():
		errs.append("classes.json: default_class does not exist")
	var fm := facility_price_mults()
	if fm.size() != race_classes().size() - 1:
		errs.append("classes.json: facility_price_mult needs %d entries (from the 2nd facility on)" % (race_classes().size() - 1))
	for v in fm:
		if float(v) <= 0.0:
			errs.append("classes.json: facility_price_mult must be > 0")
	return errs


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
			errs.append("driver_gacha.json: missing tier_defaults.%s" % tier_id)
			continue
		var maxl := int(c.get("max_level", -1))
		var table: Array = c.get("level_up_shards", [])
		if maxl < 0 or table.size() != maxl:
			errs.append("driver_gacha.json: %s.level_up_shards must have exactly max_level entries" % tier_id)
		for n in table:
			if not _is_num(n) or int(n) <= 0:
				errs.append("driver_gacha.json: %s.level_up_shards must be a positive integer" % tier_id)
		if not _is_num(c.get("duplicate_shards")) or int(c["duplicate_shards"]) <= 0:
			errs.append("driver_gacha.json: %s.duplicate_shards is invalid" % tier_id)
	for d: Dictionary in drivers():
		if int(d["tier"]) < 0 or int(d["tier"]) >= ids.size():
			errs.append("driver_gacha.json: driver %s has a tier outside tier_ids" % d["id"])
	for p: Dictionary in driver_packs():
		var pid := String(p.get("id", ""))
		if not coupons.has(p.get("coupon")):
			errs.append("driver_gacha.json: pack %s has an unknown coupon" % pid)
		for key in ["price_x1", "price_x10", "pity_draws"]:
			if not _is_num(p.get(key)) or int(p[key]) <= 0:
				errs.append("driver_gacha.json: pack %s.%s must be a positive integer" % [pid, key])
		if not ids.has(p.get("pity_tier")):
			errs.append("driver_gacha.json: pack %s has an unknown pity_tier" % pid)
		var tiers: Variant = p.get("tiers")
		if typeof(tiers) != TYPE_DICTIONARY or (tiers as Dictionary).is_empty():
			errs.append("driver_gacha.json: pack %s is missing tiers" % pid)
			continue
		var sum := 0.0
		for r in tiers:
			if not ids.has(r) or not _is_num(tiers[r]) or float(tiers[r]) <= 0.0:
				errs.append("driver_gacha.json: pack %s tier %s is invalid" % [pid, r])
				continue
			sum += float(tiers[r])
			var has_driver := false
			for d: Dictionary in drivers():
				if int(d["tier"]) == ids.find(r):
					has_driver = true
			if not has_driver:
				errs.append("driver_gacha.json: pack %s tier %s has no drivers" % [pid, r])
		if absf(sum - 100.0) > 0.001:
			errs.append("driver_gacha.json: pack %s rates must add up to 100%%" % pid)
		if (tiers as Dictionary).has(p.get("pity_tier")) == false:
			errs.append("driver_gacha.json: pack %s pity_tier must be one of its tiers" % pid)
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
			errs.append("gear.json: pack %s has an unknown coupon" % pid)
		for key in ["price_x1", "price_x10"]:
			if not _is_num(p.get(key)) or float(p[key]) != floor(float(p[key])) or int(p[key]) <= 0:
				errs.append("gear.json: pack %s.%s must be a positive integer" % [pid, key])
		var tiers: Variant = p.get("tiers")
		var sum := 0.0
		if typeof(tiers) != TYPE_DICTIONARY or (tiers as Dictionary).is_empty():
			errs.append("gear.json: pack %s is missing tiers" % pid)
			continue
		for r in tiers:
			if not rarities.has(r) or not _is_num(tiers[r]) or float(tiers[r]) <= 0.0:
				errs.append("gear.json: pack %s tier %s is invalid" % [pid, r])
			else:
				sum += float(tiers[r])
				var has_item := false
				for it: Dictionary in gear_items():
					if it["rarity"] == r:
						has_item = true
				if not has_item:
					errs.append("gear.json: pack %s tier %s has no gear" % [pid, r])
		if not is_equal_approx(sum, 100.0):
			errs.append("gear.json: pack %s rates add up to %.2f, needs 100" % [pid, sum])
	var seen := {}
	for it: Dictionary in gear_items():
		var id := String(it.get("id", ""))
		if id == "" or seen.has(id):
			errs.append("gear.json: gear id is empty/duplicated: " + id)
		seen[id] = true
		if not rarities.has(it.get("rarity")):
			errs.append("gear.json: %s has an unknown rarity" % id)
			continue
		var c := gear_config(id)
		var maxl: Variant = c.get("max_level")
		var initl: Variant = c.get("initial_level")
		if not _is_num(maxl) or not _is_num(initl) or int(initl) < 0 or int(maxl) < int(initl) or float(maxl) != floor(float(maxl)):
			errs.append("gear.json: %s initial_level/max_level is invalid" % id)
			continue
		var table: Variant = c.get("level_up_shards")
		var stats: Variant = c.get("stats_by_level")
		if typeof(table) != TYPE_ARRAY or (table as Array).size() < int(maxl):
			errs.append("gear.json: %s level_up_shards is missing a step up to max_level" % id)
		else:
			for lv in range(int(initl), int(maxl)):
				var need: Variant = table[lv]
				if not _is_num(need) or float(need) != floor(float(need)) or int(need) <= 0:
					errs.append("gear.json: %s level_up_shards[%d] must be a positive integer" % [id, lv])
		if typeof(stats) != TYPE_ARRAY or (stats as Array).size() < int(maxl) + 1:
			errs.append("gear.json: %s stats_by_level is missing a level" % id)
		else:
			for lv in range(int(initl), int(maxl) + 1):
				var st: Variant = stats[lv]
				if typeof(st) != TYPE_DICTIONARY or not _is_num(st.get("attack")) or not _is_num(st.get("defense")):
					errs.append("gear.json: %s stats_by_level[%d] is missing attack/defense" % [id, lv])
		var dup: Variant = c.get("duplicate_shards")
		if not _is_num(dup) or float(dup) != floor(float(dup)) or int(dup) < 0:
			errs.append("gear.json: %s duplicate_shards is invalid" % id)
	return errs
