extends Node
## Autoload "Ads": điểm gọi duy nhất của gameplay cho quảng cáo thưởng (Design/25 §4).
## UI chỉ hỏi can_offer() / offer_amount() và gọi try_show_rewarded(); thưởng phát ở đây trong một giao dịch save
## của GameState, chống nhận trùng bằng processed_rewards["ad/<placement>/<dịp>"].
##
## Kết quả trả về qua on_finished đúng một lần:
##   {"status": "rewarded" | "skipped_entitled" | "cancelled" | "unavailable" | "no_network" | "capped" | "busy" | "failed",
##    "placement": String, "reward_id": String, "amount": BigNumber | int}
## "failed": đã xem xong nhưng không lưu được (thưởng không phát, save giữ nguyên). Thưởng đó được giữ trong bộ nhớ
## (has_pending / retry_pending) để thử nhận lại mà không phải xem lại quảng cáo, tới khi clear_pending().
##
## Kiểu thưởng (data/ads.json): boost, income_seconds, gems, driver_coupon, gear_coupon; còn offline_double, race_bonus,
## daily_double (lõi giữ lại, v1 không khai báo placement).
##
## Lá cờ thưởng income (Design/26 §4): đồng hồ chạy ở đây (chỉ tính thời gian đang chơi); UI hỏi flag_due(), gọi
## flag_begin() khi bắt đầu cho cờ chạy và flag_end(tapped) khi cờ mất.

const BigNumber = preload("res://core/math/big_number.gd")

## Sự kiện analytics: rv_offer / rv_start / rv_done / rv_fail (tên theo horus-sdk/AGENTS.md).
signal ad_event(name: String, params: Dictionary)
## Trạng thái đổi (lượt còn lại, cooldown, đang bận): UI vẽ lại nút.
signal changed

var provider: AdsProvider = null
var _busy := false
var _pending: Dictionary = {}   # {placement, occasion, amount}: đã xem xong nhưng chưa lưu được thưởng
var _flag_wait := -1.0          # giây chơi còn lại tới lá cờ kế; < 0 = chưa bắt đầu đếm
var _flag_live := false         # có lá cờ đang chạy hoặc popup của nó đang mở
var _boost_was := false


func _ready() -> void:
	if provider == null:
		var mock := MockAdsProvider.new()
		mock.tree = get_tree()
		mock.delay_sec = 1.0
		provider = mock


func is_busy() -> bool:
	return _busy


func _process(delta: float) -> void:
	var boosting: bool = GameState.income_boost_left > 0.0
	if _boost_was and not boosting:
		ad_event.emit("boost_end", {})
		changed.emit()
	_boost_was = boosting
	if _flag_live or not _flag_clock_runs():
		return
	if _flag_wait < 0.0:
		_flag_wait = float(_cfg("flag_cash").get("first_after_sec", 60))
	_flag_wait = maxf(0.0, _flag_wait - delta)


## Đồng hồ lá cờ chỉ chạy khi đang chơi thật: không ra nền, không đang xem quảng cáo.
func _flag_clock_runs() -> bool:
	return GameState.active and not GameState.suspended and not GameState.ad_pause and not _busy


# ---------------------------------------------------------------- cấu hình & đếm lượt

func _cfg(placement: String) -> Dictionary:
	return (GameData.ads().get("placements", {}) as Dictionary).get(placement, {})


func _now() -> int:
	return int(Time.get_unix_time_from_system())


func _today() -> int:
	return int(floor(Time.get_unix_time_from_system() / 86400.0))


## Bản ghi lượt dùng của hôm nay (qua ngày UTC thì đếm lại; seq, free, last giữ nguyên).
func _state() -> Dictionary:
	var st: Dictionary = GameState.ad_state
	if int(st.get("day", -1)) != _today():
		st["day"] = _today()
		st["count"] = 0
		st["by"] = {}
	if typeof(st.get("by")) != TYPE_DICTIONARY:
		st["by"] = {}
	if typeof(st.get("last")) != TYPE_DICTIONARY:
		st["last"] = {}
	return st


## Gói "Đội tự do": nhận thưởng thẳng, không xem quảng cáo (05 §7.2). IAP đặt cờ này sau.
func entitled() -> bool:
	return bool(GameState.ad_state.get("free", false))


func remaining_today(placement: String) -> int:
	var st := _state()
	var cap := int(GameData.ads().get("daily_cap", 8)) - int(st["count"])
	var lim := int(_cfg(placement).get("daily_limit", 0))
	if lim > 0:
		cap = mini(cap, lim - int((st["by"] as Dictionary).get(placement, 0)))
	return maxi(cap, 0)


## Số giây còn phải chờ trước lượt kế của placement (0 = sẵn sàng).
func cooldown_left(placement: String) -> int:
	var cd := int(_cfg(placement).get("cooldown_sec", 0))
	if cd <= 0:
		return 0
	var last := int((_state()["last"] as Dictionary).get(placement, 0))
	return maxi(0, last + cd - _now())


# ---------------------------------------------------------------- dịp thưởng

## Dịp hiện tại của placement: {"ok", "occasion", "amount"}; ok = false khi không có gì để mời.
## occasion định danh một lần được nhận (mỗi lượt đua, mỗi lần quay lại, mỗi ngày...).
func _offer(placement: String) -> Dictionary:
	var none := {"ok": false, "occasion": "", "amount": null}
	var cfg := _cfg(placement)
	match String(cfg.get("reward", "")):
		"offline_double":
			var rep: Dictionary = GameState.offline_report
			if rep.is_empty() or not rep.has("reward"):
				return none
			var amt: BigNumber = rep["reward"]
			if amt.is_zero():
				return none
			# Mỗi lần quay lại sinh một báo cáo mới; đóng dấu một lần theo save_revision lúc đó.
			if not rep.has("ad_occasion"):
				rep["ad_occasion"] = "off/r%d" % GameState.save_revision
			return {"ok": true, "occasion": String(rep["ad_occasion"]), "amount": amt}
		"race_bonus":
			var res: Dictionary = GameState.last_result
			# Chỉ lượt vừa xong. Lưu xong, GameState tạo countdown lượt kế ngay (race_counter tăng 1) nhưng còn giữ lại trong lúc
			# hiện bảng kết quả: dịp còn hiệu lực tới khi lượt kế thật sự xuất phát (phase "racing"), Design/25 §3.
			if res.is_empty() or not res.has("money") or int(res.get("race", -1)) != GameState.race_counter - 1 					or GameState.phase == "racing":
				return none
			var money: BigNumber = res["money"]
			if money.is_zero():
				return none
			return {"ok": true, "occasion": "n%d" % int(res.get("race", 0)), "amount": money}
		"daily_double":
			if GameState.daily_available():  # chưa nhận quà ngày: phải nhận phần cơ bản trước
				return none
			return {"ok": true, "occasion": "d%d" % _today(), "amount": GameState.daily_gift_amount()}
		"gems":
			return {"ok": true, "occasion": "g%d" % (int(GameState.ad_state.get("seq", 0)) + 1), "amount": int(cfg.get("amount", 0))}
		"boost":
			if GameState.income_boost_left > 0.0:  # không cộng dồn thời gian (05 §7.1)
				return none
			if GameState.purchased_mult() >= GameData.ads_boost_multiplier():  # đã mua ×2 trở lên: ẩn nút tăng tốc (Design/28 §4.2)
				return none
			return {"ok": true, "occasion": "b%d" % (int(GameState.ad_state.get("seq", 0)) + 1),
				"amount": {"multiplier": GameData.ads_boost_multiplier(), "seconds": int(cfg.get("duration_sec", 1800))}}
		"income_seconds":
			# Thưởng = N giây thu nhập gốc (tổng các cơ sở). KHÔNG nhân hệ số boost ×2: đây là một lượng cash cố định.
			var amount: BigNumber = GameState.total_online_rate().multiply_ratio(int(cfg.get("seconds", 600)), 1).floor_number()
			if amount.is_zero():
				return none
			return {"ok": true, "occasion": "f%d" % (int(GameState.ad_state.get("seq", 0)) + 1), "amount": amount}
		"driver_coupon", "gear_coupon":
			var kind := String(cfg.get("kind", ""))
			var known: Array = GameData.driver_coupon_types() if String(cfg["reward"]) == "driver_coupon" else GameData.gear_coupon_types()
			if not known.has(kind):
				return none
			return {"ok": true, "occasion": "c%d" % _today(), "amount": {"kind": kind, "count": int(cfg.get("count", 1))}}
	return none


func _reward_id(placement: String, occasion: String) -> String:
	return "ad/%s/%s" % [placement, occasion]


## Lý do không mời được: "" (mời được), "locked", "none", "claimed", "capped", "cooldown", "save".
func block_reason(placement: String) -> String:
	var cfg := _cfg(placement)
	if cfg.is_empty():
		return "none"
	var unlock := String(cfg.get("unlock", ""))
	if unlock != "" and not GameState.feature_unlocked(unlock):
		return "locked"
	if GameState.phase == "save_error" or GameState.save_blocked:
		return "save"
	var o := _offer(placement)
	if not o["ok"]:
		return "none"
	if GameState.processed_rewards.has(_reward_id(placement, String(o["occasion"]))):
		return "claimed"
	if remaining_today(placement) <= 0:
		return "capped"
	if cooldown_left(placement) > 0:
		return "cooldown"
	return ""


## Có nên hiện nút mời xem không (đủ điều kiện và có quảng cáo hoặc được nhận thẳng).
func can_offer(placement: String) -> bool:
	if _busy or block_reason(placement) != "":
		return false
	return entitled() or (provider != null and provider.is_online() and provider.is_ready(placement))


## Phần thưởng sẽ nhận nếu xem bây giờ: BigNumber (tiền), int (gem) hoặc Dictionary (boost {multiplier, seconds},
## coupon {kind, count}); null khi không có dịp.
func offer_amount(placement: String) -> Variant:
	return _offer(placement)["amount"]


## UI gọi mỗi lần nút mời hiện ra (analytics rv_offer) và để provider tải trước.
func note_offer(placement: String) -> void:
	ad_event.emit("rv_offer", {"pl": placement})
	if provider != null and not provider.is_ready(placement):
		provider.load_rewarded()


## Trạng thái một thẻ quảng cáo trong Shop (thẻ luôn hiện, Design/26 §9): {"state", "left"}.
## state: ready, loading, offline, busy, cooldown (left = giây), capped (hết lượt hôm nay), pending (xem xong chưa lưu được),
## locked, save, none (không có dịp).
func card_state(placement: String) -> Dictionary:
	var out := {"state": "none", "left": 0}
	if _cfg(placement).is_empty():
		return out
	if has_pending(placement):
		out["state"] = "pending"
		return out
	if _busy:
		out["state"] = "busy"
		return out
	match block_reason(placement):
		"":
			pass
		"locked", "save":
			out["state"] = block_reason(placement)
			return out
		"cooldown":
			out["state"] = "cooldown"
			out["left"] = cooldown_left(placement)
			return out
		_:
			out["state"] = "capped"
			return out
	if entitled():
		out["state"] = "ready"
	elif provider == null or not provider.is_online():
		out["state"] = "offline"
	elif not provider.is_ready(placement):
		out["state"] = "loading"
	else:
		out["state"] = "ready"
	return out


## Có thẻ miễn phí nào trong Shop nhận được ngay (cho chấm đỏ trên tab Shop).
func shop_ready() -> bool:
	for pl in ["free_gems", "free_driver_coupon", "free_gear_coupon"]:
		var st := String(card_state(pl)["state"])
		if st == "ready" or st == "pending":
			return true
	return false


## Câu báo khi xem không ra thưởng (status của try_show_rewarded).
func status_text(status: String) -> String:
	match status:
		"cancelled": return I18n.t("ads.video_was_not_finished_so")
		"no_network": return I18n.t("ads.no_network_connection")
		"capped": return I18n.t("ads.no_more_attempts_today")
		"busy": return I18n.t("ads.busy_try_again_later")
		_: return I18n.t("ads.no_video_available_try_again")


# ---------------------------------------------------------------- lá cờ thưởng income (Design/26 §4)

## Giây chơi còn lại tới lá cờ kế (0 = đến lúc; < 0 = chưa bắt đầu đếm).
func flag_wait_left() -> float:
	return _flag_wait


## Có nên cho lá cờ chạy ngay bây giờ không. ui_blocked: giao diện đang có bảng kết quả/offline/popup/tutorial giữ màn hình.
## Chỉ khi quảng cáo dùng được (đã tải sẵn, hoặc "Đội tự do") để không mời người chơi vào popup không có quảng cáo.
func flag_due(ui_blocked: bool = false) -> bool:
	if ui_blocked or _flag_live or _busy or _flag_wait != 0.0:
		return false
	return can_offer("flag_cash")


## UI gọi khi bắt đầu cho lá cờ chạy. false nếu chưa đến lúc (UI không được tạo cờ).
func flag_begin() -> bool:
	if not flag_due():
		return false
	_flag_live = true
	note_offer("flag_cash")
	changed.emit()
	return true


## UI gọi khi lá cờ mất: tapped = người chơi đã chạm (xem hay tắt popup đều tính). Chạm thì đếm bỏ lỡ về 0 và chờ gap_sec;
## ra khỏi mép phải mà không chạm thì tăng bỏ lỡ, từ miss_limit lá trở đi khoảng chờ nhân đôi mỗi lá, tối đa miss_gap_max_sec.
func flag_end(tapped: bool) -> void:
	_flag_live = false
	var cfg := _cfg("flag_cash")
	var st: Dictionary = GameState.ad_state
	var misses := 0 if tapped else int(st.get("flag_misses", 0)) + 1
	st["flag_misses"] = misses
	var gap := float(cfg.get("gap_sec", 120))
	var limit := int(cfg.get("miss_limit", 3))
	if misses >= limit:
		gap = minf(gap * pow(2.0, float(misses - limit + 1)), float(cfg.get("miss_gap_max_sec", 480)))
	_flag_wait = gap
	changed.emit()


## Đã hiện dòng gợi ý "Chạm vào cờ để nhận thưởng" lần đầu chưa (lưu trong save).
func flag_intro_seen() -> bool:
	return bool(GameState.ad_state.get("flag_intro", false))


func flag_mark_intro_seen() -> void:
	GameState.ad_state["flag_intro"] = true


# ---------------------------------------------------------------- xem & nhận

func try_show_rewarded(placement: String, on_finished: Callable = Callable()) -> void:
	var base := {"placement": placement, "reward_id": "", "amount": null}
	if _busy:
		_finish(on_finished, base, "busy")
		return
	var reason := block_reason(placement)
	if reason != "":
		_finish(on_finished, base, "capped" if reason in ["capped", "cooldown"] else "unavailable")
		return
	if _pending.get("placement", "") == placement:
		_pending = {}  # xem mới thì bỏ thưởng chờ cũ của chính placement này
	var o := _offer(placement)
	var occasion := String(o["occasion"])
	base["reward_id"] = _reward_id(placement, occasion)
	base["amount"] = o["amount"]
	if entitled():
		_finish(on_finished, base, "skipped_entitled" if _claim(placement, occasion) else "failed")
		return
	if provider == null or not provider.is_online():
		_finish(on_finished, base, "no_network")
		return
	if not provider.is_ready(placement):
		provider.load_rewarded()
		_finish(on_finished, base, "unavailable")
		return
	_busy = true
	GameState.ad_pause = true
	changed.emit()
	ad_event.emit("rv_start", {"pl": placement})
	var done := [false]
	provider.show_rewarded(placement, func(r: Dictionary) -> void:
		if done[0]:
			return
		done[0] = true
		_busy = false
		GameState.ad_pause = false
		var status := "cancelled"
		match String(r.get("status", "error")):
			"rewarded":
				if _claim(placement, occasion):
					status = "rewarded"
				else:
					status = "failed"
					_pending = {"placement": placement, "occasion": occasion, "amount": o["amount"]}
			"cancelled":
				status = "cancelled"
			_:
				status = "unavailable"
				provider.load_rewarded()
		_finish(on_finished, base, status))


## Có thưởng đã xem xong nhưng chưa lưu được (UI hiện nút "Thử nhận lại").
func has_pending(placement: String) -> bool:
	return not _pending.is_empty() and String(_pending["placement"]) == placement


## Thử nhận lại thưởng chờ, không phải xem lại quảng cáo. Kết quả "rewarded" hoặc "failed" qua on_finished.
func retry_pending(placement: String, on_finished: Callable = Callable()) -> void:
	var base := {"placement": placement, "reward_id": "", "amount": null}
	if not has_pending(placement) or _busy:
		_finish(on_finished, base, "unavailable")
		return
	var occasion := String(_pending["occasion"])
	base["reward_id"] = _reward_id(placement, occasion)
	base["amount"] = _pending["amount"]
	if _claim(placement, occasion):
		_pending = {}
		_finish(on_finished, base, "rewarded")
	else:
		_finish(on_finished, base, "failed")


## UI đóng popup: bỏ thưởng chờ (không thử nhận lại nữa).
func clear_pending() -> void:
	_pending = {}


## Phát thưởng trong một giao dịch save. Dịp phải còn hiệu lực và chưa nhận; lưu lỗi thì khôi phục như cũ.
func _claim(placement: String, occasion: String) -> bool:
	var o := _offer(placement)
	if not o["ok"] or String(o["occasion"]) != occasion:
		_trace("claim %s: the occasion is no longer valid (ok=%s, occasion now=%s, occasion at view=%s, phase=%s)" % [placement, o["ok"], o["occasion"], occasion, GameState.phase])
		return false
	var rid := _reward_id(placement, occasion)
	if GameState.processed_rewards.has(rid) or GameState.save_blocked or GameState.phase == "save_error":
		_trace("claim %s: blocked (claimed=%s, save_blocked=%s, phase=%s)" % [placement, GameState.processed_rewards.has(rid), GameState.save_blocked, GameState.phase])
		return false
	var before: Dictionary = GameState._save_data()
	match String(_cfg(placement).get("reward", "")):
		"offline_double", "race_bonus", "daily_double":
			GameState.coins = GameState.coins.add(o["amount"] as BigNumber)
		"gems":
			GameState.gems += int(o["amount"])
		"income_seconds":
			GameState.coins = GameState.coins.add(o["amount"] as BigNumber)
		"boost":
			GameState.income_boost_left = float((o["amount"] as Dictionary)["seconds"])
		"driver_coupon":
			var da: Dictionary = o["amount"]
			GameState.driver_coupons[da["kind"]] = int(GameState.driver_coupons.get(da["kind"], 0)) + int(da["count"])
		"gear_coupon":
			var ga: Dictionary = o["amount"]
			GameState.gear_coupons[ga["kind"]] = int(GameState.gear_coupons.get(ga["kind"], 0)) + int(ga["count"])
		_:
			return false
	GameState.processed_rewards[rid] = true
	var st := _state()
	st["count"] = int(st["count"]) + 1
	(st["by"] as Dictionary)[placement] = int((st["by"] as Dictionary).get(placement, 0)) + 1
	(st["last"] as Dictionary)[placement] = _now()
	st["seq"] = int(st.get("seq", 0)) + 1
	if not GameState.save_game():
		_trace("claim %s: save_game failed, rolled back (revision=%d)" % [placement, GameState.save_revision])
		GameState._restore_transaction(before)
		return false
	GameState.changed.emit()
	if String(_cfg(placement).get("reward", "")) == "boost":
		_boost_was = true
		var ba: Dictionary = o["amount"]
		ad_event.emit("boost_start", {"sec": int(ba["seconds"]), "mult": int(ba["multiplier"])})
	return true


## Chẩn đoán: chỉ in ở bản debug.
func _trace(msg: String) -> void:
	if OS.is_debug_build():
		print("[Ads] ", msg)


func _finish(on_finished: Callable, base: Dictionary, status: String) -> void:
	var r := base.duplicate()
	r["status"] = status
	if status in ["rewarded", "skipped_entitled"]:
		ad_event.emit("rv_done", {"pl": base["placement"], "via": "ad" if status == "rewarded" else "entitled"})
	elif status in ["cancelled", "unavailable", "no_network", "failed"]:
		ad_event.emit("rv_fail", {"pl": base["placement"], "reason": status})
	changed.emit()
	if on_finished.is_valid():
		on_finished.call(r)
