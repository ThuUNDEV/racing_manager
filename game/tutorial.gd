class_name Tutorial
extends RefCounted
const Catalog = preload("res://game/tutorial_catalog.gd")
## Hướng dẫn đầu game, Phần A (Design/23 §4): thứ tự bước, điều kiện tự qua và lời thoại.
## Chỉ là logic thuần để test được; hiển thị ở ui/tutorial_overlay.gd, tiến độ lưu trong GameState.tutorial.

## A5 (Ticket Marketing) đã bỏ (Design/31 §3.4b): chỉ hướng dẫn một ô nâng cấp. Giữ id A6/A7 để save cũ vẫn khớp.
const STEPS := ["A1_welcome", "A2_car", "A3_income", "A4_engine", "A6_result", "A7_race2"]
## Save cũ đang dừng ở bước đã bỏ: tiếp tục ở bước kế tiếp tương ứng.
const LEGACY_STEPS := {"A5_ticket": "A6_result"}
## Chờ chưa đủ tiền mua ô được chỉ quá số giây này: Linh nhắc một lần, không dừng game.
const MONEY_WAIT_SEC := 60.0
## Bước chỉ đọc: tự qua sau số giây này (thời gian thật) nếu người chơi không bấm Tiếp.
const AUTO_SEC := {"A2_car": 4.0}
## Câu phụ sau khi làm xong thao tác ở A4/A5 hoặc câu đầu A7: tự qua sau AFTER_SEC giây.
const AFTER_SEC := 3.0
const MENTOR := "Linh"


static func is_step(step: String) -> bool:
	return step in step_ids()


static func first_step() -> String:
	return String(step_ids()[0])


static func next_of(step: String) -> String:
	var order := step_ids()
	var i := order.find(step)
	return "" if i < 0 or i + 1 >= order.size() else String(order[i + 1])


## Có cần chạy hướng dẫn cho save này không: save mới chưa đua, hoặc đang dở (kể cả đã đua vài lượt).
static func should_run(gs: Node) -> bool:
	var state: String = gs.tutorial_state()
	return state == "active" or (state == "new" and int(gs.completed_races) == 0)


## Bước khởi động: tiếp tục bước đang lưu; bước không hợp lệ thì bắt đầu lại từ A1.
static func resume_step(gs: Node) -> String:
	var step: String = LEGACY_STEPS.get(gs.tutorial_step(), gs.tutorial_step())
	if gs.tutorial_state() != "active" or not is_step(step):
		return first_step()
	# A completed lesson may have been saved just before the scheduler advanced.
	while step != "" and gs.tutorial.get("lessons", {}).get(step, {}).get("status", "") == "done":
		step = next_of(step)
	return step


## Thao tác của bước đã đạt (kể cả khi người chơi làm trước khi được nhắc).
static func action_done(step: String, gs: Node) -> bool:
	var action: Dictionary = lesson(step).get("action", {})
	if action.get("metric", "") == "ticket_level_increase":
		return gs.level_of("ticket") > int(income_snapshot(gs).get("ticket_level", gs.level_of("ticket")))
	return action.get("metric", "") == "engine_level" and gs.level_of("engine") >= int(action.get("at_least", 1))


## A4 chưa hiện lời dẫn cho tới khi đủ tiền mua ô Động cơ (Design/31 §3.4): thu nhập chạy tiếp để người chơi kiếm đủ.
static func waits_for_money(step: String, sub: int, gs: Node) -> bool:
	if step == "A3_income":
		return sub == 2 and not action_done(step, gs) and gs.upgrade_state("ticket") != "ok"
	return step == "A4_engine" and sub == 0 and not action_done(step, gs) and gs.upgrade_state("engine") != "ok"


## Lời dẫn này dừng game (đua + thu nhập) cho tới khi người chơi thao tác.
## A4 chỉ hiện và dừng khi đủ tiền mua nâng cấp được chỉ — nếu thiếu, thu nhập phải chạy tiếp để người chơi kiếm đủ.
## A6 (bảng kết quả đã giữ vòng lặp) và câu phụ sau thao tác không dừng.
static func pauses_game(step: String, sub: int, gs: Node) -> bool:
	match step:
		"A1_welcome", "A2_car":
			return true
		"A3_income":
			return sub != 4 and not waits_for_money(step, sub, gs)
		"A4_engine":
			return sub == 0 and gs.upgrade_state("engine") == "ok"
		"A7_race2":
			return sub == 1  # câu giải thích Power: chờ bấm Tiếp
	return false


## Bước chờ sự kiện của vòng đua, không hiện callout cho tới khi sự kiện tới.
static func waits_for_race(step: String) -> bool:
	return step == "A6_result" or step == "A7_race2"


## Lời thoại. `sub` là câu thứ mấy trong bước; `ctx` mang số liệu thật (giá, hạng, tiền...).
static func line(step: String, sub: int, ctx: Dictionary = {}) -> String:
	var values := {"coins": "1.000", "rate": "8", "price": "", "position": 8, "money": "", "before": "", "after": ""}
	values.merge(ctx, true)
	return Catalog.stage(step, sub, values)


static func primary_text(step: String, sub: int) -> String:
	match step:
		"A3_income":
			return "" if sub in [2, 4] else I18n.t("tutorial.next")
		"A1_welcome":
			return I18n.t("tutorial.start")
		"A4_engine":
			return "" if sub == 0 or sub == 2 else I18n.t("tutorial.next")
		"A7_race2":
			return I18n.t("tutorial.next") if sub < 2 else I18n.t("tutorial.got")
	return I18n.t("tutorial.next")


# ---------------------------------------------------------------- Phần B: mở khóa tính năng dần (Design/23 §5)
## Dữ liệu ở data/tutorial.json. Mở khóa tính theo số lượt đã hoàn tất (`completed_races`), nên không cần lưu danh sách
## đã mở: save, thử lưu lại và khôi phục đều cho cùng kết quả. Chỉ save bắt đầu ở chế độ "gated" mới bị khóa.

const DATA_PATH := "res://data/tutorial.json"
const COUPON_NAMES := {"standard": "Standard Gear", "elite": "Elite Gear", "pro": "Pro Pack", "allstar": "All-Star Pack"}



static func features() -> Array:
	return Catalog.group("features")


static func reload() -> void:
	Catalog.reload()


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
	return I18n.tn("tutorial.unlocks_after_race_races_left", left) % [int(f["races"]), left]


static func gift_text(f: Dictionary) -> String:
	var parts := PackedStringArray()
	var gift: Dictionary = f.get("gift", {})
	for group in ["gear_coupon", "driver_coupon"]:
		for kind in (gift.get(group, {}) as Dictionary):
			parts.append("%s ×%d" % [COUPON_NAMES.get(kind, kind), int(gift[group][kind])])
	return " · ".join(parts)


static func intro_lines(f: Dictionary) -> Array:
	var out: Array = []
	var stages: Dictionary = f.get("stages", {})
	for sub in range(stages.size()):
		out.append(stages.get(str(sub), {}).get("text", ""))
	return out


## Thao tác Linh dẫn đã làm xong (chỉ U3/U4/U5 có). Đạt thì hiện câu thứ hai rồi đóng.
static func intro_action_done(f: Dictionary, gs: Node) -> bool:
	if f.get("action", "") == "trophy_upgrade":
		var context: Dictionary = gs.tutorial.get("lessons", {}).get(f["id"], {}).get("context", {})
		return gs.trophy_level(String(f["upgrade_id"])) > int(context.get("trophy_level", gs.trophy_level(String(f["upgrade_id"]))))
	var metric := String(f.get("action_metric", ""))
	return not metric.is_empty() and int(gs.get(metric)) > 0


static func intro_seen(gs: Node, id: String) -> bool:
	var saved: Dictionary = gs.tutorial.get("lessons", {}).get(id, {})
	var f := feature(id)
	if int(f.get("script_version", 1)) > 1:
		if int(saved.get("script_version", 0)) >= int(f["script_version"]):
			return saved.get("status", "") == "done"
		# Existing players who already bought a trophy upgrade have learned the mechanic.
		return gs.trophy_levels.values().any(func(level: Variant) -> bool: return int(level) > 0)
	return saved.get("status", "") == "done" or id in (gs.tutorial.get("intro_seen", []) as Array)


## Chỉ đường tới tab khi tính năng mới mở (Design/31 §3.5): "none" | "soft" (nhắc, không chặn) | "force" (chặn chạm ngoài tab).
## Người đã bỏ qua hướng dẫn chỉ nhận chế độ nhẹ.
static func nav_hint(f: Dictionary, gs: Node) -> String:
	var hint := String(f.get("nav_hint", "none"))
	if hint == "force" and gs.tutorial_state() == "skipped":
		return "soft"
	return hint


static func nav_seen(gs: Node, id: String) -> bool:
	return id in (gs.tutorial.get("nav_seen", []) as Array)


## Kiểm tra dữ liệu: id/lượt hợp lệ, không hai tính năng cùng một lượt.
static func validate() -> PackedStringArray:
	var errs := Catalog.validate()
	var ids := {}
	var races := {}
	var last := 0
	for f: Dictionary in features():
		var id := String(f.get("id", ""))
		if id == "" or ids.has(id):
			errs.append("tutorial.json: id is empty or duplicated (%s)" % id)
		ids[id] = true
		var r := int(f.get("races", 0))
		if r < 1 or r <= last:
			errs.append("tutorial.json: %s: races must be ≥ 1 and increasing" % id)
		if races.has(r):
			errs.append("tutorial.json: %s: two features share race %d" % [id, r])
		races[r] = true
		last = r
		if intro_lines(f).is_empty():
			errs.append("tutorial.json: %s: missing guidance text" % id)
	if features().is_empty():
		errs.append("tutorial.json: could not read the feature list")
	return errs


# ---------------------------------------------------------------- Phần C: mẹo theo tình huống (Design/23 §6)
## Mỗi mẹo hiện một lần, tối đa một mẹo mới mỗi lượt, tắt được trong Cài đặt. Danh sách và tab ở data/tutorial.json;
## điều kiện và lời thoại tính từ trạng thái thật nên tip_info() trả {} khi tình huống không còn đúng.
## C3 (thanh thăng giải chậm) đã bỏ cùng thanh thăng giải; C2 đổi sang cúp.

const TIP_TABS := ["any", "race", "bag", "team"]


static func tips() -> Array:
	return Catalog.group("tips")


static func tip(id: String) -> Dictionary:
	for t: Dictionary in tips():
		if t["id"] == id:
			return t
	return {}


static func tip_seen(gs: Node, id: String) -> bool:
	return gs.tutorial.get("lessons", {}).get(id, {}).get("status", "") == "done" or id in (gs.tutorial.get("tips_seen", []) as Array)


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
			return {"text": Catalog.stage(id, 0) % [
				roundi(float(off["ratio"]) * 100.0), roundi(float(off["cap_sec"]) / 3600.0)], "target": ""}
		"C2_trophy":
			if not gs.feature_unlocked("U2_league") or int(gs.trophies) <= 0:
				return {}
			for u: Dictionary in GameData.trophy_upgrades():
				var cost: int = gs.trophy_cost(u["id"])
				if gs.trophy_unlocked(u["id"]) and cost > 0 and int(gs.trophies) >= cost:
					return {"text": Catalog.stage(id, 0) % int(gs.trophies), "target": ""}
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
			return {"text": Catalog.stage(id, 0) % _name_of(GameData.drivers(), best), "target": ""}
		"C5_shards":
			if not gs.feature_unlocked("U3_bag"):
				return {}
			for gid in gs.gear_owned.keys():
				var need: int = gs.gear_upgrade_cost(gid)
				if need > 0 and gs.gear_shards(gid) >= need:
					return {"text": Catalog.stage(id, 0) % String(GameData.gear_item(gid).get("name", gid)), "target": "node:Upgrade_%s" % gid}
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
			var mult := String(stars.get("multiplier", "1")).replace(".", I18n.dec())
			return {"text": Catalog.stage(id, 0) % [
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
			errs.append("tutorial.json: tip is empty/duplicated id (%s)" % id)
		ids[id] = true
		if not String(t.get("tab", "")) in TIP_TABS:
			errs.append("tutorial.json: %s: tip tab is invalid" % id)
	return errs


static func lesson(id: String) -> Dictionary:
	return Catalog.lesson(id)


static func lesson_progress(id: String, gs: Node) -> Dictionary:
	var saved: Dictionary = gs.tutorial.get("lessons", {}).get(id, {})
	if not saved.is_empty():
		return saved
	# Existing saves keep their current tutorial position and seen flags.
	var complete := false
	if id in step_ids():
		complete = gs.tutorial_state() in ["done", "skipped"] or (gs.tutorial_state() == "active" and step_ids().find(id) < step_ids().find(resume_step(gs)))
	elif not feature(id).is_empty():
		complete = intro_seen(gs, id)
	else:
		complete = tip_seen(gs, id)
	return {"status": "done" if complete else "new", "sub": 0, "page": 0}


static func step_ids() -> Array:
	var ids: Array = []
	for item: Dictionary in Catalog.group("onboarding"):
		ids.append(item["id"])
	return ids


static func income_snapshot(gs: Node) -> Dictionary:
	return gs.tutorial.get("lessons", {}).get("A3_income", {}).get("context", {})


static func intro_ready(f: Dictionary, gs: Node) -> bool:
	if f.get("action", "") != "trophy_upgrade":
		return true
	if intro_action_done(f, gs):
		return true
	var id := String(f["upgrade_id"])
	return gs.trophy_unlocked(id) and gs.trophy_cost(id) >= 0 and gs.trophies >= gs.trophy_cost(id)


static func intro_line(f: Dictionary, sub: int, gs: Node) -> String:
	if f.get("action", "") == "trophy_upgrade":
		var id := String(f["upgrade_id"])
		var context: Dictionary = gs.tutorial.get("lessons", {}).get(f["id"], {}).get("context", {})
		return Catalog.stage(String(f["id"]), sub, {"cost": gs.trophy_cost(id), "before": int(context.get("trophy_effect_before", 0)), "after": int(gs.trophy_effect_at(id, gs.trophy_level(id)).get("S", 0))})
	return Catalog.stage(String(f["id"]), sub)
