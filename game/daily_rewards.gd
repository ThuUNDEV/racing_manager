class_name DailyRewards
extends RefCounted
## Thưởng đăng nhập hằng ngày (Design/30). Logic thuần để test được: không đụng GameState, không đọc giờ hệ thống.
## Trạng thái là một Dictionary (lưu trong GameState.daily_rewards); mọi hàm nhận `today` (số ngày UTC) từ ngoài.
##
## state: {unlocked_day, last_claim_day, cycle_day 0-6, grand_ordinal 0-6, total_days, claimed_milestones, popup_shown_day, max_seen_day}
## reward: {gems:int, driver_coupon:{pro,allstar}, gear_coupon:{standard,elite}, slot:int (0-6), grand:bool, milestone:int (số mốc k vừa chạm, 0 = không)}

const CYCLE_DAYS := 7
const GRAND_SLOT := 6
const VISIBLE_MILESTONES := 4
const DAY_SEC := 86400.0
const INT_KEYS := ["unlocked_day", "last_claim_day", "cycle_day", "grand_ordinal", "total_days", "claimed_milestones", "popup_shown_day", "max_seen_day"]
const MAX_DAY := 1000000


static func default_state() -> Dictionary:
	return {
		"unlocked_day": 0, "last_claim_day": -1, "cycle_day": 0, "grand_ordinal": 0,
		"total_days": 0, "claimed_milestones": 0, "popup_shown_day": -1, "max_seen_day": 0,
	}


## Làm sạch dữ liệu từ save: kiểu sai/thiếu về mặc định, số ngoài biên bị chặn.
static func sanitize(raw: Variant) -> Dictionary:
	var out := default_state()
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	var r: Dictionary = raw
	for key in INT_KEYS:
		var v: Variant = r.get(key)
		if (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(float(v)):
			out[key] = clampi(int(v), -1, MAX_DAY * 365)
	out["cycle_day"] = clampi(int(out["cycle_day"]), 0, CYCLE_DAYS - 1)
	out["grand_ordinal"] = clampi(int(out["grand_ordinal"]), 0, CYCLE_DAYS - 1)
	out["total_days"] = maxi(0, int(out["total_days"]))
	out["claimed_milestones"] = clampi(int(out["claimed_milestones"]), 0, int(out["total_days"]) / _interval())
	out["unlocked_day"] = maxi(0, int(out["unlocked_day"]))
	out["max_seen_day"] = maxi(0, int(out["max_seen_day"]))
	return out


static func cfg() -> Dictionary:
	return GameData.daily_rewards()


static func _interval() -> int:
	return maxi(1, int(cfg().get("milestone_interval", 10)))


static func enabled() -> bool:
	return bool((cfg().get("flags", {}) as Dictionary).get("enabled", true))


static func x2_enabled() -> bool:
	return bool((cfg().get("flags", {}) as Dictionary).get("x2_enabled", true))


## Số ngày UTC của một mốc thời gian unix.
static func day_of(unix: float) -> int:
	return int(floor(unix / DAY_SEC))


## Ngày hiện tại dùng để tính: lớn nhất của giờ server (nếu có, <= 0 là không có), giờ máy và ngày đã từng thấy.
## Giờ máy chỉnh lùi không làm ngày lùi theo (Design/30 §7).
static func today(state: Dictionary, device_unix: float, server_unix: float = -1.0) -> int:
	var d := day_of(device_unix)
	if server_unix > 0.0:
		d = maxi(d, day_of(server_unix))
	return maxi(d, int(state.get("max_seen_day", 0)))


## Ghi nhận ngày hiện tại vào `max_seen_day`. Trả state mới (không sửa bản vào).
static func observe(state: Dictionary, today_day: int) -> Dictionary:
	var s := state.duplicate(true)
	s["max_seen_day"] = maxi(int(s.get("max_seen_day", 0)), today_day)
	return s


static func seconds_until_reset(unix: float) -> float:
	return DAY_SEC - fposmod(unix, DAY_SEC)


static func is_unlocked(state: Dictionary) -> bool:
	return int(state.get("unlocked_day", 0)) > 0


## Mở khóa ở ngày `today_day` (gọi một lần khi tính năng `unlock` mở). Đã mở thì giữ nguyên. Ngày mở khóa là ngày 1.
static func unlock(state: Dictionary, today_day: int) -> Dictionary:
	var s := state.duplicate(true)
	if int(s.get("unlocked_day", 0)) <= 0 and today_day > 0:
		s["unlocked_day"] = today_day
		s["max_seen_day"] = maxi(int(s.get("max_seen_day", 0)), today_day)
	return s


## Nhận được hôm nay: đã mở khóa, tính năng bật, và chưa nhận trong ngày UTC này.
static func can_claim(state: Dictionary, today_day: int) -> bool:
	return enabled() and is_unlocked(state) and today_day > int(state.get("last_claim_day", -1)) and today_day >= int(state.get("unlocked_day", 0))


## Popup tự bật: còn thưởng chưa nhận và hôm nay chưa bật (Design/30 R4).
static func should_auto_popup(state: Dictionary, today_day: int) -> bool:
	return can_claim(state, today_day) and int(state.get("popup_shown_day", -1)) != today_day


static func mark_popup_shown(state: Dictionary, today_day: int) -> Dictionary:
	var s := state.duplicate(true)
	s["popup_shown_day"] = today_day
	return s


static func _scaled_gems(gems: int) -> int:
	if gems <= 0:
		return 0
	var scale := float(cfg().get("gem_scale", 1.0))
	if not is_finite(scale) or scale <= 0.0:
		scale = 1.0
	return maxi(1, int(round(float(gems) * scale)))


static func _blank_reward() -> Dictionary:
	return {"gems": 0, "driver_coupon": {}, "gear_coupon": {}, "slot": 0, "grand": false, "milestone": 0}


static func _merge(into: Dictionary, part: Dictionary) -> void:
	into["gems"] = int(into["gems"]) + _scaled_gems(int(part.get("gems", 0)))
	for key in ["driver_coupon", "gear_coupon"]:
		var dst: Dictionary = into[key]
		for kind in (part.get(key, {}) as Dictionary):
			dst[String(kind)] = int(dst.get(String(kind), 0)) + int(part[key][kind])


## Thưởng của ô `slot` (0-6) ở vòng Grand `ordinal`, chưa kể mốc.
static func slot_reward(slot: int, ordinal: int) -> Dictionary:
	var out := _blank_reward()
	var c := cfg()
	var s := clampi(slot, 0, CYCLE_DAYS - 1)
	out["slot"] = s
	if s == GRAND_SLOT:
		var grand: Array = c.get("grand", [])
		if not grand.is_empty():
			_merge(out, grand[posmod(ordinal, grand.size())])
		out["grand"] = true
	else:
		var cycle: Array = c.get("cycle", [])
		if s < cycle.size():
			_merge(out, cycle[s])
	return out


## Thưởng mốc thứ k (k >= 1, mốc ở ngày k × interval). Xoay vòng theo bảng milestones.
static func milestone_reward(k: int) -> Dictionary:
	var out := _blank_reward()
	var ms: Array = cfg().get("milestones", [])
	if k >= 1 and not ms.is_empty():
		_merge(out, ms[(k - 1) % ms.size()])
	return out


## Thưởng của lần nhận kế tiếp: ô hiện tại + mốc nếu lần nhận này đưa total_days chạm bội số interval.
static func next_reward(state: Dictionary) -> Dictionary:
	var out := slot_reward(int(state.get("cycle_day", 0)), int(state.get("grand_ordinal", 0)))
	var days_after := int(state.get("total_days", 0)) + 1
	if days_after % _interval() == 0:
		var k := days_after / _interval()
		_merge(out, milestone_reward(k))
		out["milestone"] = k
	return out


## Nhân phần gem (video x2). Coupon giữ nguyên. Trả bản mới.
static func with_gem_multiplier(reward: Dictionary, mult: int) -> Dictionary:
	var out := reward.duplicate(true)
	out["gems"] = int(out.get("gems", 0)) * maxi(1, mult)
	return out


static func has_gems(reward: Dictionary) -> bool:
	return int(reward.get("gems", 0)) > 0


## Tiến trạng thái sau một lần nhận. Không cấp thưởng. Gọi sau khi `can_claim` đúng.
static func apply_claim(state: Dictionary, today_day: int) -> Dictionary:
	var s := state.duplicate(true)
	var r := next_reward(s)
	s["last_claim_day"] = today_day
	s["total_days"] = int(s["total_days"]) + 1
	s["max_seen_day"] = maxi(int(s.get("max_seen_day", 0)), today_day)
	if int(r["milestone"]) > 0:
		s["claimed_milestones"] = int(r["milestone"])
	if int(s["cycle_day"]) >= GRAND_SLOT:
		s["cycle_day"] = 0
		s["grand_ordinal"] = (int(s["grand_ordinal"]) + 1) % maxi(1, (cfg().get("grand", []) as Array).size())
	else:
		s["cycle_day"] = int(s["cycle_day"]) + 1
	return s


## Cửa sổ mốc hiển thị: tối đa 4 mốc, bắt đầu từ mốc đã nhận gần nhất (nếu có) rồi các mốc kế.
## Mỗi mục {k, day, state: "claimed" | "next" | "locked", reward}.
static func milestone_window(state: Dictionary) -> Array:
	var claimed := int(state.get("claimed_milestones", 0))
	var start := maxi(1, claimed)
	var out: Array = []
	for i in VISIBLE_MILESTONES:
		var k := start + i
		var st := "claimed" if k <= claimed else ("next" if k == claimed + 1 else "locked")
		out.append({"k": k, "day": k * _interval(), "state": st, "reward": milestone_reward(k)})
	return out


## Số ngày còn lại tới mốc kế tiếp (tính cả lần nhận hôm nay).
static func days_to_next_milestone(state: Dictionary) -> int:
	var iv := _interval()
	var total := int(state.get("total_days", 0))
	return iv - (total % iv)
