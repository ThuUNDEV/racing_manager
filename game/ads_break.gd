extends RefCounted
## Ads Break: interstitial xen giữa hai lượt đua (Design/26 §7 và §17). Do AdsService giữ (Ads.break_ctl).
## UI gọi begin() sau bảng kết quả rồi tick() mỗi khung cho tới khi active() = false; ở đây không có node nào.
## Bộ đếm nằm trong GameState.ad_state: "play_sec", "break" = {last_race, last_t, times, day, today}.

const BigNumber = preload("res://core/math/big_number.gd")

enum Step { IDLE, WAITING_TOUCH, CARD, SHOWING }

const PLACEMENT := "ad_break"
const QUIET_SEC := 1.2          # không chạm đủ lâu mới hiện thẻ, tránh bấm nhầm vào quảng cáo
const TOUCH_WAIT_SEC := 3.0
const CARD_SEC := 1.5
const SHOW_TIMEOUT_SEC := 90.0

## Đã xem xong và tiền đã vào save.
signal finished(amount: BigNumber)

var ads: Node = null
var step: Step = Step.IDLE
## Tiền đền bù của break đang chạy, chốt trước khi hiện thẻ.
var amount: BigNumber = null
## Mốc unix bắt đầu tính "sessionWarmup": mở app, hoặc trở lại từ nền.
var warm_from := 0.0

var _timer := 0.0
var _since_touch := INF
var _token := 0
var _race := 0
var _pending: Dictionary = {}   # {rid, amount}: đã xem nhưng chưa lưu được tiền
var _was_muted := false


func _init(service: Node) -> void:
	ads = service
	warm_from = _now()


func active() -> bool:
	return step != Step.IDLE


## Bỏ mọi thứ đang dở (test, chơi lại từ đầu).
func reset() -> void:
	if step == Step.SHOWING:
		_leave_ad()
	step = Step.IDLE
	_token += 1
	_pending = {}
	amount = null
	_since_touch = INF


func note_touch() -> void:
	_since_touch = 0.0


static func _cfg(key: String) -> float:
	return float((GameData.ads().get("break", {}) as Dictionary).get(key, 0))


func _now() -> float:
	return Time.get_unix_time_from_system()


func _record() -> Dictionary:
	var st: Dictionary = GameState.ad_state
	if typeof(st.get("break")) != TYPE_DICTIONARY:
		st["break"] = {}
	return st["break"]


## Số Ads Break đã xem trong ngày UTC hiện tại.
func today_count(now: float = -1.0) -> int:
	if now < 0.0:
		now = _now()
	var raw: Variant = GameState.ad_state.get("break")
	if typeof(raw) != TYPE_DICTIONARY or int((raw as Dictionary).get("day", -1)) != GameState.iap_day(now):
		return 0
	return int((raw as Dictionary).get("today", 0))


## Tiền đền bù: N giây thu nhập gốc, cùng cách tính với lá cờ (không nhân boost).
func bonus() -> BigNumber:
	return GameState.total_online_rate().multiply_ratio(int(_cfg("bonusIncomeSec")), 1).floor_number()


## {"due", "why"}. why theo InterWhy của Horus SDK: no_ads, early, warmup, every, cooldown, rewarded, blocked.
func due(now: float = -1.0) -> Dictionary:
	if now < 0.0:
		now = _now()
	var why := _why_not(now)
	return {"due": why == "", "why": why}


func _why_not(now: float) -> String:
	if ads.entitled():
		return "no_ads"
	if not GameState.tutorial_state() in ["done", "skipped"] or GameState.completed_races < int(_cfg("interFromRun")) \
			or float(GameState.ad_state.get("play_sec", 0.0)) < _cfg("firstPlayMin") * 60.0:
		return "early"
	if now - warm_from < _cfg("sessionWarmup"):
		return "warmup"
	var rec := _record()
	if rec.has("last_race") and GameState.completed_races - int(rec["last_race"]) < int(_cfg("interEvery")):
		return "every"
	if rec.has("last_t") and now - float(rec["last_t"]) < _cfg("interCooldown"):
		return "cooldown"
	if _recent(rec, now).size() >= int(_cfg("maxPerHour")):
		return "cooldown"
	var last_rewarded := -INF
	for t: Variant in (GameState.ad_state.get("last", {}) as Dictionary).values():
		last_rewarded = maxf(last_rewarded, float(t))
	if now - last_rewarded < _cfg("rewardedGrace"):
		return "rewarded"
	if GameState.save_blocked or GameState.phase == "save_error" or bonus().is_zero():
		return "blocked"
	if ads.provider == null or not ads.provider.is_online():
		return "blocked"
	if not ads.provider.is_inter_ready():
		ads.provider.load_interstitial()
		return "blocked"
	return ""


static func _recent(rec: Dictionary, now: float) -> Array:
	return (rec.get("times", []) as Array).filter(func(t: Variant) -> bool: return now - float(t) < 3600.0)


## Xét sau bảng kết quả. true = đã bắt đầu, UI phải giữ vòng đua tới khi active() = false.
func begin() -> bool:
	if active():
		return true
	_retry_reward()
	var check := due()
	if not check["due"]:
		skip(String(check["why"]))
		return false
	step = Step.WAITING_TOUCH
	_timer = 0.0
	return true


## Ghi nhận một lần không phát (cả khi UI chặn).
func skip(why: String) -> void:
	ads.ad_event.emit("inter_skip", {"pl": PLACEMENT, "why": why})


## ui_blocked: có thứ khác đang chiếm màn hình. Khi quảng cáo đã hiện thì không còn tác dụng.
func tick(delta: float, ui_blocked: bool = false) -> void:
	_since_touch += delta
	if step == Step.IDLE:
		return
	_timer += delta
	if ui_blocked and step != Step.SHOWING:
		_abort("blocked")
		return
	match step:
		Step.WAITING_TOUCH:
			if _since_touch >= QUIET_SEC:
				amount = bonus()
				step = Step.CARD
				_timer = 0.0
				ads.changed.emit()
			elif _timer >= TOUCH_WAIT_SEC:
				_abort("blocked")
		Step.CARD:
			if _timer >= CARD_SEC:
				var check := due()
				if check["due"]:
					_show()
				else:
					_abort(String(check["why"]))
		Step.SHOWING:
			if _timer >= SHOW_TIMEOUT_SEC:
				_leave_ad()
				_token += 1  # callback đến muộn bị bỏ qua
				_abort("blocked")


func _abort(why: String) -> void:
	step = Step.IDLE
	skip(why)
	ads.changed.emit()


func _show() -> void:
	step = Step.SHOWING
	_timer = 0.0
	_token += 1
	_race = GameState.completed_races
	GameState.ad_pause = true
	_was_muted = AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, true)
	ads.changed.emit()
	var token := _token
	ads.provider.show_interstitial(PLACEMENT, func(r: Dictionary) -> void:
		if token != _token or step != Step.SHOWING:
			return
		_leave_ad()
		step = Step.IDLE
		if bool(r.get("shown", false)):
			ads.ad_event.emit("inter_show", {"pl": PLACEMENT})
			_grant()
		else:
			skip("blocked")
		ads.changed.emit())


func _leave_ad() -> void:
	GameState.ad_pause = false
	AudioServer.set_bus_mute(0, _was_muted)


## Tiền, bộ đếm break và mở gói theo mốc trong MỘT giao dịch save.
func _grant() -> void:
	var now := _now()
	var rid := "ad/break/n%d" % _race
	var before: Dictionary = GameState._save_data()
	_count(now)
	var paid := _pay(rid, amount)
	if GameState.save_game():
		if paid:
			GameState.changed.emit()
			finished.emit(amount)
		return
	GameState._restore_transaction(before)
	_count(now)  # người chơi đã xem: cooldown và bộ đếm vẫn tính, chỉ tiền chờ lưu lại
	_pending = {"rid": rid, "amount": amount}


func _count(now: float) -> void:
	var rec := _record()
	var count := today_count(now) + 1
	rec["day"] = GameState.iap_day(now)
	rec["today"] = count
	rec["last_race"] = _race
	rec["last_t"] = now
	var times := _recent(rec, now)
	times.append(now)
	rec["times"] = times
	Iap.note_ad_breaks(count)


func _pay(rid: String, value: BigNumber) -> bool:
	if GameState.processed_rewards.has(rid):
		return false
	GameState.coins = GameState.coins.add(value)
	GameState.processed_rewards[rid] = true
	return true


func _retry_reward() -> void:
	if _pending.is_empty() or GameState.save_blocked or GameState.phase == "save_error":
		return
	var before: Dictionary = GameState._save_data()
	var value: BigNumber = _pending["amount"]
	var paid := _pay(String(_pending["rid"]), value)
	if not GameState.save_game():
		GameState._restore_transaction(before)
		return
	_pending = {}
	if paid:
		GameState.changed.emit()
		finished.emit(value)
