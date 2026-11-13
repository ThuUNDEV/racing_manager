class_name Tutorial
extends RefCounted
## Hướng dẫn đầu game, Phần A (Design/23 §4): thứ tự bước, điều kiện tự qua và lời thoại.
## Chỉ là logic thuần để test được; hiển thị ở ui/tutorial_overlay.gd, tiến độ lưu trong GameState.tutorial.

const STEPS := ["A1_welcome", "A2_car", "A3_income", "A4_engine", "A5_ticket", "A6_result", "A7_race2"]
## Bước chỉ đọc: tự qua sau số giây này (thời gian thật) nếu người chơi không bấm Tiếp.
const AUTO_SEC := {"A2_car": 4.0, "A3_income": 3.0}
## Câu phụ sau khi làm xong thao tác ở A4/A5 hoặc câu đầu A7: tự qua sau AFTER_SEC giây.
const AFTER_SEC := 3.0
const MENTOR := "Linh"


static func is_step(step: String) -> bool:
	return step in STEPS


static func first_step() -> String:
	return STEPS[0]


static func next_of(step: String) -> String:
	var i := STEPS.find(step)
	return "" if i < 0 or i + 1 >= STEPS.size() else String(STEPS[i + 1])


## Có cần chạy hướng dẫn cho save này không: save mới chưa đua, hoặc đang dở (kể cả đã đua vài lượt).
static func should_run(gs: Node) -> bool:
	var state: String = gs.tutorial_state()
	return state == "active" or (state == "new" and int(gs.completed_races) == 0)


## Bước khởi động: tiếp tục bước đang lưu; bước không hợp lệ thì bắt đầu lại từ A1.
static func resume_step(gs: Node) -> String:
	var step: String = gs.tutorial_step()
	return step if gs.tutorial_state() == "active" and is_step(step) else first_step()


## Thao tác của bước đã đạt (kể cả khi người chơi làm trước khi được nhắc).
static func action_done(step: String, gs: Node) -> bool:
	match step:
		"A4_engine":
			return gs.level_of("engine") >= 1
		"A5_ticket":
			return gs.level_of("ticket") >= 1
	return false


## Bước chờ sự kiện của vòng đua, không hiện callout cho tới khi sự kiện tới.
static func waits_for_race(step: String) -> bool:
	return step == "A6_result" or step == "A7_race2"


## Lời thoại. `sub` là câu thứ mấy trong bước; `ctx` mang số liệu thật (giá, hạng, tiền...).
static func line(step: String, sub: int, ctx: Dictionary = {}) -> String:
	match step:
		"A1_welcome":
			return "Chào Sếp! Đội mình có một chiếc xe, một tay đua và %s tiền.\nXe tự đua — việc của Sếp là nâng cấp và kiếm tiền." % ctx.get("coins", "1.000")
		"A2_car":
			return "Chấm sáng có viền này là xe mình.\nTrên cùng là hạng hiện tại và thời gian còn lại."
		"A3_income":
			return "Khán giả trả %s tiền mỗi giây, kể cả khi không đua.\nĐó là doanh thu của đội." % ctx.get("rate", "8")
		"A4_engine":
			if sub == 0:
				return "Nâng Động cơ để xe chạy nhanh hơn.\nBấm vào nút giá %s tiền này!" % ctx.get("price", "")
			return "Xe đang chạy rồi nên nâng cấp được lắp vào xe từ lượt sau."
		"A5_ticket":
			if sub == 0:
				return "Giờ nâng Ticket Marketing để có thêm tiền mỗi giây.\nBấm nút giá %s tiền." % ctx.get("price", "")
			return "Doanh thu có hiệu lực ngay: tiền mỗi giây đã tăng!"
		"A6_result":
			if sub == 0:
				var pos := int(ctx.get("position", 8))
				if pos <= 3:
					return "Về P%d! %s tiền thưởng đã cộng thẳng vào ví." % [pos, ctx.get("money", "")]
				return "Về P%d. Lượt đầu ai cũng hồi hộp — có nâng cấp rồi, lượt sau sẽ khác!\n%s tiền thưởng đã vào ví." % [pos, ctx.get("money", "")]
			return "Về đích top 3 sẽ nhận cúp.\nDùng cúp nâng cấp xe ở tab Giải."
		"A7_race2":
			if sub == 0:
				return "Động cơ mới đã lắp vào xe. Power đội: %s → %s." % [ctx.get("before", ""), ctx.get("after", "")]
			return "Từ giờ Sếp tự quản lý nhé. Có gì mới tôi sẽ báo!"
	return ""


static func primary_text(step: String, sub: int) -> String:
	match step:
		"A1_welcome":
			return "Bắt đầu"
		"A4_engine", "A5_ticket":
			return "" if sub == 0 else "Tiếp"
		"A7_race2":
			return "Tiếp" if sub == 0 else "Rõ rồi!"
	return "Tiếp"


# ---------------------------------------------------------------- Phần B: mở khóa tính năng dần (Design/23 §5)
## Dữ liệu ở data/tutorial.json. Mở khóa tính theo số lượt đã hoàn tất (`completed_races`), nên không cần lưu danh sách
## đã mở: save, thử lưu lại và khôi phục đều cho cùng kết quả. Chỉ save bắt đầu ở chế độ "gated" mới bị khóa.

const DATA_PATH := "res://data/tutorial.json"
const COUPON_NAMES := {"standard": "Standard Gear", "elite": "Elite Gear", "pro": "Pro Pack", "allstar": "All-Star Pack"}

static var _features: Array = []
static var _loaded := false


static func features() -> Array:
	if not _loaded:
		_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if typeof(parsed) == TYPE_DICTIONARY and typeof((parsed as Dictionary).get("features")) == TYPE_ARRAY:
			_features = (parsed as Dictionary)["features"]
	return _features


static func reload() -> void:
	_loaded = false
	_features = []


static func feature(id: String) -> Dictionary:
	for f: Dictionary in features():
		if f["id"] == id:
			return f
	return {}



## Tính năng mở ngay sau khi hoàn tất lượt thứ `completed` (mỗi lượt tối đa một tính năng, kiểm bằng validate()).
static func unlocked_at(completed: int) -> Array:
	var out: Array = []
	for f: Dictionary in features():
		if int(f["races"]) == completed:
			out.append(f)
	return out


## Tính năng chưa mở gần nhất, {} nếu đã mở hết.
static func next_feature(completed: int) -> Dictionary:
	var best := {}
	for f: Dictionary in features():
		if int(f["races"]) > completed and (best.is_empty() or int(f["races"]) < int(best["races"])):
			best = f
	return best


static func lock_text(f: Dictionary, completed: int) -> String:
	var left := maxi(1, int(f["races"]) - completed)
	return "Mở sau lượt %d · còn %d lượt" % [int(f["races"]), left]


static func gift_text(f: Dictionary) -> String:
	var parts := PackedStringArray()
	var gift: Dictionary = f.get("gift", {})
	for group in ["gear_coupon", "driver_coupon"]:
		for kind in (gift.get(group, {}) as Dictionary):
			parts.append("%s ×%d" % [COUPON_NAMES.get(kind, kind), int(gift[group][kind])])
	return " · ".join(parts)


static func intro_lines(f: Dictionary) -> Array:
	return f.get("intro", [])


## Thao tác Linh dẫn đã làm xong (chỉ U3/U4/U5 có). Đạt thì hiện câu thứ hai rồi đóng.
static func intro_action_done(f: Dictionary, gs: Node) -> bool:
	match String(f.get("action", "")):
		"gear_pack":
			return int(gs.gear_open_count) > 0
		"daily":
			return not gs.daily_available()
		"driver_pack":
			return int(gs.driver_open_count) > 0
	return false


static func intro_seen(gs: Node, id: String) -> bool:
	return id in (gs.tutorial.get("intro_seen", []) as Array)


## Kiểm tra dữ liệu: id/lượt hợp lệ, không hai tính năng cùng một lượt.
static func validate() -> PackedStringArray:
	var errs := PackedStringArray()
	var ids := {}
	var races := {}
	var last := 0
	for f: Dictionary in features():
		var id := String(f.get("id", ""))
		if id == "" or ids.has(id):
			errs.append("tutorial.json: id trống hoặc trùng (%s)" % id)
		ids[id] = true
		var r := int(f.get("races", 0))
		if r < 1 or r <= last:
			errs.append("tutorial.json: %s: races phải ≥ 1 và tăng dần" % id)
		if races.has(r):
			errs.append("tutorial.json: %s: hai tính năng cùng lượt %d" % [id, r])
		races[r] = true
		last = r
		if (f.get("intro", []) as Array).is_empty():
			errs.append("tutorial.json: %s: thiếu lời hướng dẫn" % id)
	if features().is_empty():
		errs.append("tutorial.json: không đọc được danh sách tính năng")
	return errs


# ---------------------------------------------------------------- Phần C: mẹo theo tình huống (Design/23 §6)
## Mỗi mẹo hiện một lần, tối đa một mẹo mới mỗi lượt, tắt được trong Cài đặt. Danh sách và tab ở data/tutorial.json;
## điều kiện và lời thoại tính từ trạng thái thật nên tip_info() trả {} khi tình huống không còn đúng.
## C3 (thanh thăng giải chậm) đã bỏ cùng thanh thăng giải; C2 đổi sang cúp.

const TIP_TABS := ["any", "race", "bag", "team"]


static func tips() -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) == TYPE_DICTIONARY and typeof((parsed as Dictionary).get("tips")) == TYPE_ARRAY:
		return (parsed as Dictionary)["tips"]
	return []


static func tip(id: String) -> Dictionary:
	for t: Dictionary in tips():
		if t["id"] == id:
			return t
	return {}


static func tip_seen(gs: Node, id: String) -> bool:
	return id in (gs.tutorial.get("tips_seen", []) as Array)


## Mẹo được phép hiện lúc này (cài đặt, đã xong hướng dẫn, mỗi lượt một mẹo).
static func tips_allowed(gs: Node) -> bool:
	if bool(gs.tutorial.get("tips_off", false)):
		return false
	if not String(gs.tutorial_state()) in ["done", "skipped"]:
		return false
	return int(gs.completed_races) > int(gs.tutorial.get("tips_last", -1))


static func _name_of(list: Array, id: String) -> String:
	for e: Dictionary in list:
		if e.get("id", "") == id:
			return String(e.get("name", id))
	return id


## {"text": String, "target": String} nếu mẹo `id` đang đúng tình huống, {} nếu không.
static func tip_info(id: String, gs: Node) -> Dictionary:
	match id:
		"C1_offline":
			if not bool(gs.tutorial.get("offline_shown", false)):
				return {}
			var off: Dictionary = GameData.economy()["offline"]
			return {"text": "Lúc Sếp vắng, đội vẫn thu %d%% doanh thu, tối đa %d giờ.\nNhớ quay lại nhận nhé!" % [
				roundi(float(off["ratio"]) * 100.0), roundi(float(off["cap_sec"]) / 3600.0)], "target": ""}
		"C2_trophy":
			if not gs.feature_unlocked("U2_league") or int(gs.trophies) <= 0:
				return {}
			for u: Dictionary in GameData.trophy_upgrades():
				var cost: int = gs.trophy_cost(u["id"])
				if gs.trophy_unlocked(u["id"]) and cost > 0 and int(gs.trophies) >= cost:
					return {"text": "Sếp có %d cúp — đủ nâng cấp ở tab Giải rồi!\nCúp chỉ nhận khi về top 3." % int(gs.trophies), "target": ""}
			return {}
		"C6_weaker":
			if gs.owned_drivers.size() < 2 or not gs.feature_unlocked("U5_drivers"):
				return {}
			var best := ""
			var best_score: float = _driver_score(gs, gs.active_driver_id) + 0.5
			for d in gs.owned_drivers:
				if _driver_score(gs, d) > best_score:
					best = d
					best_score = _driver_score(gs, d)
			if best == "":
				return {}
			return {"text": "%s mạnh hơn tay đua đang dùng.\nChọn lại cho lượt sau nếu Sếp muốn nhé!" % _name_of(GameData.drivers(), best), "target": ""}
		"C5_shards":
			if not gs.feature_unlocked("U3_bag"):
				return {}
			for gid in gs.gear_owned.keys():
				var need: int = gs.gear_upgrade_cost(gid)
				if need > 0 and gs.gear_shards(gid) >= need:
					return {"text": "%s đã đủ mảnh để nâng cấp!" % String(GameData.gear_item(gid).get("name", gid)), "target": "node:Upgrade_%s" % gid}
			return {}
		"C4_star":
			var stars: Dictionary = GameData.economy().get("revenue_stars", {})
			var best_kind := ""
			var best_gap := 99
			var best_level := 0
			for kind in Balance.REVENUE:
				var lv: int = gs.level_of(kind)
				for m in stars.get("levels", []):
					var gap := int(m) - lv
					if lv > 0 and gap >= 1 and gap <= 3 and gap < best_gap:
						best_kind = kind
						best_gap = gap
						best_level = int(m)
					if int(m) > lv:
						break
			if best_kind == "":
				return {}
			var mult := String(stars.get("multiplier", "1")).replace(".", ",")
			return {"text": "%s còn %d cấp nữa là tới cấp %d: được sao, doanh thu mục này ×%s!" % [
				String(GameData.economy()["revenue_upgrades"][best_kind]["name"]), best_gap, best_level, mult], "target": "tile:" + best_kind}
	return {}


## Tổng chỉ số tay đua kèm thưởng level (so sánh khi gợi ý đổi tay đua).
static func _driver_score(gs: Node, id: String) -> float:
	var d := GameData.driver(id)
	if d.is_empty():
		return 0.0
	var sum := 0.0
	for k in ["pace", "technique", "composure", "launch", "braking", "racecraft", "endurance"]:
		sum += float(int(d[k]))
	return sum + 7.0 * float(gs.driver_level_bonus(id))


## Mẹo đầu tiên đang đúng tình huống và tab hiện tại (`tab` = "race"/"bag"/"team"); {} nếu không có.
## Trả {"id", "text", "target"}.
static func next_tip(gs: Node, tab: String) -> Dictionary:
	if not tips_allowed(gs):
		return {}
	for t: Dictionary in tips():
		var id: String = t["id"]
		if tip_seen(gs, id) or not (t["tab"] == "any" or t["tab"] == tab):
			continue
		var info := tip_info(id, gs)
		if not info.is_empty():
			info["id"] = id
			return info
	return {}


static func validate_tips() -> PackedStringArray:
	var errs := PackedStringArray()
	var ids := {}
	for t: Dictionary in tips():
		var id := String(t.get("id", ""))
		if id == "" or ids.has(id):
			errs.append("tutorial.json: mẹo trống/trùng id (%s)" % id)
		ids[id] = true
		if not String(t.get("tab", "")) in TIP_TABS:
			errs.append("tutorial.json: %s: tab mẹo không hợp lệ" % id)
	return errs
