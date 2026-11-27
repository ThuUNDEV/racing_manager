extends Node
## Autoload "Iap": điểm gọi duy nhất của gameplay/UI cho mua hàng thật (Design/28 §7).
## UI hỏi price()/block_reason() và gọi buy(); hàng vào save ở GameState.grant_iap (một giao dịch save, chống giao trùng
## bằng token). Luật Horus: lưu xong mới finish; lưu lỗi thì KHÔNG finish, lần mở game sau deliver_pending() giao lại.
##
## Kết quả buy()/restore() trả qua on_finished đúng một lần:
##   {"status": "ok" | "pending" | "cancelled" | "invalid" | "error" | "failed" | "busy" | "blocked" | "no_network" | "unknown",
##    "sku": String, "why": String}
## "failed": đã trả tiền nhưng chưa lưu được hàng (đơn còn ở store, sẽ giao lại).

## Sự kiện analytics (tên theo Design/28 §7.4); params là Dictionary phẳng.
signal iap_event(name: String, params: Dictionary)
## Trạng thái đổi (đang bận, đã giao hàng): UI vẽ lại nút.
signal changed

const DROP_REASONS := ["hidden", "owned", "once", "maxed"]

var provider: IapProvider = null
var _busy := false
var _busy_sku := ""
var _startup_done := false
## Mốc bắt đầu phiên chơi: gói "auto_next_session" chỉ tự hiện khi đạt mốc từ phiên trước.
var session_start := 0.0


func _ready() -> void:
	session_start = _now()
	if provider == null:
		var mock := MockIapProvider.new()
		mock.tree = get_tree()
		mock.delay_sec = 0.5
		provider = mock


## Khi gameplay được bàn giao (save đã nạp), giao các đơn store còn giữ đúng một lần (Design/28 §7.3).
func _process(_delta: float) -> void:
	if not _startup_done and GameState.active:
		_startup_done = true
		deliver_pending()


func is_busy() -> bool:
	return _busy


func busy_sku() -> String:
	return _busy_sku


# ---------------------------------------------------------------- danh mục & giá

func products() -> Array:
	return GameData.iap_products()


func product(sku: String) -> Dictionary:
	return GameData.iap_product(sku)


## Giá hiển thị: giá store nếu có, không thì giá dự phòng trong data (Design/28 §1.6).
func price(sku: String) -> String:
	var s := provider.price(sku) if provider != null else ""
	return s if s != "" else String(product(sku).get("price_fallback", ""))


func restorable() -> bool:
	return provider != null and provider.restorable()


func _now() -> float:
	return Time.get_unix_time_from_system()


# ---------------------------------------------------------------- điều kiện bán

## Điều kiện mở khóa của SKU (đệ quy với "any"). Thiếu khóa = mở.
func _unlocked(u: Dictionary) -> bool:
	if u.is_empty():
		return true
	if u.has("any"):
		for sub in (u["any"] as Array):
			if _unlocked(sub):
				return true
		return false
	if u.has("tutorial") and not GameState.feature_unlocked(String(u["tutorial"])):
		return false
	if u.has("bought") and not GameState.iap_bought(String(u["bought"])):
		return false
	if u.has("tier") and GameState.business_tier < int(u["tier"]):
		return false
	if u.has("tier_before_driver"):
		return false  # chỉ dùng được cùng grant.driver, xử lý ở _driver_open
	if u.has("ad_breaks_today") and Ads.breaks_today() < int(u["ad_breaks_today"]):
		return false
	if u.has("races") and GameState.completed_races < int(u["races"]):
		return false
	return true


## Gói đã đạt mốc theo ngày một lần thì mở luôn (Design/28 §4.4: nằm trong Shop cho tới khi mua).
func _reached(sku: String) -> bool:
	return bool(((GameState.iap["offers"] as Dictionary).get(sku, {}) as Dictionary).get("unlocked", false))


## Ads Break gọi sau mỗi lần xem, trong cùng giao dịch save.
func note_ad_breaks(today: int) -> void:
	for p: Dictionary in products():
		var u: Dictionary = p.get("unlock", {})
		if u.has("ad_breaks_today") and today >= int(u["ad_breaks_today"]):
			var offers: Dictionary = GameState.iap["offers"]
			var o: Dictionary = offers.get(String(p["sku"]), {})
			o["unlocked"] = true
			offers[String(p["sku"])] = o


## Gói nhân vật mở khi business_tier >= unlock.league - 1 của tay đua (Design/28 §4.5).
func _driver_open(p: Dictionary) -> bool:
	var did := String((p.get("grant", {}) as Dictionary).get("driver", ""))
	var d := GameData.driver(did)
	var before := int((p.get("unlock", {}) as Dictionary).get("tier_before_driver", 0))
	if d.is_empty():
		return false
	var u: Dictionary = d.get("unlock", {})
	var league := int(u.get("league", 0)) if String(u.get("type", "")) == "league" else 0
	return GameState.business_tier >= league - before


## Lý do không bán được: "" (bán được), "none" (SKU lạ), "flag", "hidden" (đã có thứ thay thế), "locked", "owned",
## "once", "daily", "weekly", "rotation" (không thuộc vòng xoay tuần này), "requires", "pass_left", "maxed" (tay đua đã tối đa), "save", "busy".
func block_reason(sku: String) -> String:
	var p := product(sku)
	if p.is_empty():
		return "none"
	if p.has("flag") and not bool((GameData.iap().get("flags", {}) as Dictionary).get(String(p["flag"]), false)):
		return "flag"
	if GameState.phase == "save_error" or GameState.save_blocked:
		return "save"
	for h in (p.get("hide_if_owned", []) as Array):
		if GameState.iap_has(String(h)):
			return "hidden"
	var kind := String(p.get("kind", ""))
	var g: Dictionary = p.get("grant", {})
	if kind == "perk" or kind == "pass_growth":
		var perk := String(g.get("perk", "pass_growth"))
		if GameState.iap_has(perk):
			return "owned"
	for r in (p.get("requires", []) as Array):
		if not GameState.iap_has(String(r)):
			return "requires"
	if bool(p.get("once", false)) and GameState.iap_bought(sku):
		return "once"
	if kind == "character":
		if not _driver_open(p):
			return "locked"
		var did := String(g.get("driver", ""))
		if GameState.driver_has(did) and GameState.driver_level(did) >= GameState.driver_max_level(did):
			return "maxed"
	elif not _reached(sku) and not _unlocked(p.get("unlock", {})):
		return "locked"
	var now := _now()
	if p.has("daily_limit") and int((GameState.iap["daily"] as Dictionary).get(sku, -1)) == GameState.iap_day(now):
		return "daily"
	if p.has("weekly_limit") and int((GameState.iap["weekly"] as Dictionary).get(sku, -1)) == GameState.iap_week(now):
		return "weekly"
	if p.has("rotation") and rotation_of(kind, now) != int(p["rotation"]):
		return "rotation"
	if p.has("week_cap") and bought_this_week(sku, now) >= int(p["week_cap"]):
		return "weekly"
	for other in (p.get("week_conflict", []) as Array):
		if bought_this_week(String(other), now) > 0:
			return "weekly"
	if kind == "pass_month" and int((GameState.iap["pass_month"] as Dictionary).get("left_days", 0)) > int(p.get("rebuy_when_left_days", 5)):
		return "pass_left"
	if _busy:
		return "busy"
	return ""


## SKU của một chuỗi Chain Offer theo thứ tự bước (kind "chain", Design/35 đợt B).
func chain_skus(chain_id: String) -> Array:
	var rows: Array = []
	for p: Dictionary in products():
		if String(p.get("kind", "")) == "chain" and String(p.get("chain_id", "")) == chain_id:
			rows.append(p)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["chain_step"]) < int(b["chain_step"]))
	return rows.map(func(p: Dictionary) -> String: return String(p["sku"]))


## Trạng thái chuỗi: {"total", "bought", "sku" (bước đang bán, "" nếu chuỗi chưa mở hoặc đã mua hết), "step", "next_sku"}.
## Bước đang bán là bước đầu tiên chưa mua; bước 1 chưa mở (chưa starter_3 hoặc bậc 2) thì không có sku.
func chain_state(chain_id: String) -> Dictionary:
	var skus := chain_skus(chain_id)
	var bought := 0
	var state := {"total": skus.size(), "bought": 0, "sku": "", "step": 0, "next_sku": ""}
	for index in skus.size():
		var sku: String = skus[index]
		if GameState.iap_bought(sku):
			bought += 1
			continue
		state["bought"] = bought
		if block_reason(sku) in ["", "busy", "save"]:
			state["sku"] = sku
			state["step"] = index + 1
			state["next_sku"] = String(skus[index + 1]) if index + 1 < skus.size() else ""
		return state
	state["bought"] = bought
	return state


## Vòng xoay tuần UTC hiện tại (1..N) của ưu đãi giới hạn / chọn một (GameData.IAP_ROTATIONS).
func rotation_of(kind: String, now: float = -1.0) -> int:
	if now < 0.0:
		now = _now()
	return GameState.iap_week(now) % int(GameData.IAP_ROTATIONS.get(kind, 1)) + 1


## Số giây tới lúc vòng xoay đổi (đầu tuần UTC kế tiếp, trùng GameState.iap_week).
func rotation_ends_in(now: float = -1.0) -> float:
	if now < 0.0:
		now = _now()
	return float((GameState.iap_week(now) + 1) * 7 - 3) * 86400.0 - now


## Số đơn của SKU trong tuần UTC chứa `now` (giới hạn mua của gói xoay tuần).
func bought_this_week(sku: String, now: float = -1.0) -> int:
	if now < 0.0:
		now = _now()
	var week := GameState.iap_week(now)
	var count := 0
	for b: Dictionary in (GameState.iap["buys"] as Array):
		if String(b.get("sku", "")) == sku and GameState.iap_week(float(b.get("t", 0))) == week:
			count += 1
	return count


## SKU của vòng xoay hiện tại theo thứ tự hiển thị (limited: ô 1..3 rẻ -> đắt; chooseone: S, M, L, Tất cả).
func timed_skus(kind: String, now: float = -1.0) -> Array:
	var rotation := rotation_of(kind, now)
	var rows: Array = []
	for p: Dictionary in products():
		if String(p.get("kind", "")) == kind and int(p.get("rotation", 0)) == rotation:
			rows.append(p)
	var key := "slot" if kind == "limited" else "size"
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if kind == "limited":
			return int(a[key]) < int(b[key])
		return GameData.IAP_CHOOSE_SIZES.find(String(a[key])) < GameData.IAP_CHOOSE_SIZES.find(String(b[key])))
	return rows.map(func(p: Dictionary) -> String: return String(p["sku"]))


## Trạng thái ưu đãi xoay tuần: {"rotation", "ends_in", "skus", "open", "bought"} ("open": có ô nào bán được/đã mua trong tuần, tức mục nên hiện).
func timed_state(kind: String, now: float = -1.0) -> Dictionary:
	var skus := timed_skus(kind, now)
	var open := false
	var bought := {}
	for sku: String in skus:
		bought[sku] = bought_this_week(sku, now)
		if block_reason(sku) not in ["locked", "flag", "hidden", "none"]:
			open = true
	return {"rotation": rotation_of(kind, now), "ends_in": rotation_ends_in(now), "skus": skus, "open": open, "bought": bought}


func can_buy(sku: String) -> bool:
	return block_reason(sku) == ""


# ---------------------------------------------------------------- popup tự hiện (Design/28 §5b)
# Trạng thái: iap.offers[sku] = {open_t, popup_count, last_popup_day}; iap.popup = {last_t, day_utc, count_today}.
# Điều kiện màn hình (tutorial, overlay, hạng về đích) do ui/main.gd kiểm.

## Các gói đang chờ tự hiện, mốc đạt trước đứng trước (hòa: theo thứ tự trong data). Ghi mốc cho gói mới đủ điều kiện.
func sales_popup_queue(now: float = -1.0) -> Array:
	if now < 0.0:
		now = _now()
	var offers: Dictionary = GameState.iap["offers"]
	var waiting: Array = []
	var changed := false
	var index := 0
	for p: Dictionary in products():
		index += 1
		var sku := String(p["sku"])
		if not p.has("auto_popup"):
			continue
		var o: Dictionary = offers.get(sku, {})
		if bool(o.get("dropped", false)):
			continue
		var reason := block_reason(sku)
		if reason != "":
			if o.has("open_t") and int(o.get("popup_count", 0)) < int(p["auto_popup"]) and DROP_REASONS.has(reason):
				o["dropped"] = true
				offers[sku] = o
				changed = true
			continue
		if not _popup_ready(p):
			continue
		if not o.has("open_t"):
			o.merge({"open_t": now, "popup_count": 0, "last_popup_day": -1})
			offers[sku] = o
			changed = true
		if int(o.get("popup_count", 0)) < int(p["auto_popup"]):
			waiting.append([_popup_group_rank(p), -int(p.get("prio", 0)), float(o.get("open_t", now)), index, sku])
	if changed:
		GameState.save_game()  # lỗi ghi: giữ trong bộ nhớ, lần lưu sau ghi lại
	waiting.sort()
	return waiting.map(func(w: Array) -> String: return String(w[4]))


## Gói đã rời hàng đợi popup mà chưa tự hiện đủ lần (đã mua, bị gói khác thay, tay đua đã tối đa).
func popup_dropped(sku: String) -> bool:
	return bool(((GameState.iap["offers"] as Dictionary).get(sku, {}) as Dictionary).get("dropped", false))


## Thứ hạng nhóm popup (data popup.groups, nhóm đứng trước được xét trước); nhóm không khai báo xếp mặc định high_value.
func _popup_group_rank(p: Dictionary) -> int:
	var groups: Array = GameData.iap().get("popup", {}).get("groups", [])
	var at := groups.find(String(p.get("popup_group", "high_value")))
	return at if at >= 0 else groups.size()


## Điểm ưu tiên của icon gói ở dải chặng (OfferRotationConfig của game gốc: NoAds 400, IncomeX2 300, ...); mặc định 0.
func strip_prio(sku: String) -> int:
	return int(product(sku).get("strip_prio", 0))


## Điều kiện riêng của popup tự hiện, tách khỏi điều kiện mở thẻ trong Shop.
func _popup_ready(p: Dictionary) -> bool:
	if not _unlocked(p.get("popup_unlock", {})):
		return false
	for other in (p.get("popup_unless", []) as Array):
		if block_reason(String(other)) == "":
			return false
	return true


## Gói được tự hiện lúc này: {"sku", "why"}. sku rỗng thì why: "" (không có gì chờ), "tutorial", "gap", "day_cap", "session".
func next_sales_popup(now: float = -1.0) -> Dictionary:
	if now < 0.0:
		now = _now()
	var queue := sales_popup_queue(now)
	if queue.is_empty():
		return {"sku": "", "why": ""}
	var cfg: Dictionary = GameData.iap().get("popup", {})
	var first := String(cfg.get("first_after_tutorial", ""))
	if first != "" and not GameState.feature_unlocked(first):
		return {"sku": "", "why": "tutorial"}
	var state: Dictionary = GameState.iap["popup"]
	var today := GameState.iap_day(now)
	if int(state.get("day_utc", -1)) == today and int(state.get("count_today", 0)) >= int(cfg.get("per_day", 1)):
		return {"sku": "", "why": "day_cap"}
	for sku: String in queue:
		var first_o: Dictionary = GameState.iap["offers"][sku]
		if bool(product(sku).get("high_priority", false)) and not bool(first_o.get("high_used", false)) \
				and int(first_o.get("last_popup_day", -1)) != today:
			return {"sku": sku, "why": ""}
	var last := float(state.get("last_t", -1.0))
	var since := now - last if last >= 0.0 else INF
	if since >= 0.0 and since < float(cfg.get("gap_sec", 0)):
		return {"sku": "", "why": "gap"}
	var why := ""
	for sku: String in queue:
		var o: Dictionary = GameState.iap["offers"][sku]
		if int(o.get("last_popup_day", -1)) == today:
			why = "day_cap"
		elif bool(product(sku).get("auto_next_session", false)) and float(o.get("open_t", now)) >= session_start:
			why = "session"
		elif bool(product(sku).get("auto_next_session", false)) and since >= 0.0 and since < float(cfg.get("next_gap_hours", 0)) * 3600.0:
			why = "gap"
		else:
			return {"sku": sku, "why": ""}
	return {"sku": "", "why": why}


## Ghi nhận một popup vừa hiện và lưu.
func note_sales_popup(sku: String, now: float = -1.0) -> void:
	if now < 0.0:
		now = _now()
	var today := GameState.iap_day(now)
	var o: Dictionary = (GameState.iap["offers"] as Dictionary).get(sku, {"open_t": now})
	o["popup_count"] = int(o.get("popup_count", 0)) + 1
	o["last_popup_day"] = today
	if bool(product(sku).get("high_priority", false)):
		o["high_used"] = true
	GameState.iap["offers"][sku] = o
	var state: Dictionary = GameState.iap["popup"]
	state["count_today"] = int(state.get("count_today", 0)) + 1 if int(state.get("day_utc", -1)) == today else 1
	state["day_utc"] = today
	state["last_t"] = now
	GameState.save_game()
	iap_event.emit("offer_show", {"sku": sku, "why": "milestone"})


func note_popup_skip(why: String) -> void:
	iap_event.emit("popup_skip", {"why": why})


# ---------------------------------------------------------------- mua

func buy(sku: String, on_finished: Callable = Callable()) -> void:
	var base := {"sku": sku, "why": ""}
	if _busy:
		_finish(on_finished, base, "busy")
		return
	var reason := block_reason(sku)
	if reason != "":
		base["why"] = reason
		_finish(on_finished, base, "unknown" if reason == "none" else "blocked")
		return
	if provider == null or not provider.is_online():
		_finish(on_finished, base, "no_network")
		return
	if not GameState.iap_stash_ctx(sku):
		base["why"] = "save"
		_finish(on_finished, base, "failed")
		return
	_busy = true
	_busy_sku = sku
	changed.emit()
	iap_event.emit("iap_started", {"sku": sku})
	var done := [false]
	provider.buy(sku, func(r: Dictionary) -> void:
		if done[0]:
			return
		done[0] = true
		_on_buy_result(sku, r, on_finished, base))


func _on_buy_result(sku: String, r: Dictionary, on_finished: Callable, base: Dictionary) -> void:
	var status := String(r.get("status", "error"))
	match status:
		"ok":
			var ok := _deliver(r)
			_release()
			_finish(on_finished, base, "ok" if ok else "failed")
		"pending":
			_release()
			iap_event.emit("iap_pending", {"sku": sku})
			_finish(on_finished, base, "pending")
		"cancel":
			_release()
			GameState.iap_clear_ctx(sku)
			iap_event.emit("iap_cancel", {"sku": sku})
			_finish(on_finished, base, "cancelled")
		"owned":
			# Store báo đã sở hữu: giao lại từ danh sách đơn còn giữ.
			deliver_pending(func(n: int) -> void:
				_release()
				_finish(on_finished, base, "ok" if n > 0 else "error"))
		"invalid":
			_release()
			GameState.iap_clear_ctx(sku)
			base["why"] = String(r.get("reason", ""))
			iap_event.emit("iap_fail", {"sku": sku, "reason": "invalid"})
			_finish(on_finished, base, "invalid")
		_:
			_release()
			GameState.iap_clear_ctx(sku)
			iap_event.emit("iap_fail", {"sku": sku, "reason": "error"})
			_finish(on_finished, base, "error")


func _release() -> void:
	_busy = false
	_busy_sku = ""
	changed.emit()


## Giao hàng một đơn đã trả tiền rồi finish. true = hàng đã nằm trong save (an toàn đã finish).
## SKU lạ (đã bị gỡ khỏi data) hay lỗi lưu: không finish, đơn còn ở store để giao lại sau.
func _deliver(purchase: Dictionary) -> bool:
	var sku := String(purchase.get("sku", ""))
	var token := String(purchase.get("token", ""))
	var p := product(sku)
	if p.is_empty():
		iap_event.emit("iap_fail", {"sku": sku, "reason": "unknown_sku"})
		return false
	var test := bool(purchase.get("test", false))
	if not GameState.grant_iap(sku, token, {"order": String(purchase.get("order", ""))}):
		iap_event.emit("iap_fail", {"sku": sku, "reason": "save"})
		return false
	var fin := {"sku": sku, "token": token, "orderId": String(purchase.get("order", "")), "consumable": bool(p.get("consumable", true))}
	if not test:
		fin["usd"] = float(p.get("usd", 0.0))
	provider.finish(fin)
	var g: Dictionary = GameState.last_iap_grant
	var ev := {"sku": sku, "usd": 0.0 if test else float(p.get("usd", 0.0)), "test": test}
	if String(g.get("sku", "")) == sku:
		ev["first"] = bool(g.get("first", false))
		ev["gems"] = int(g.get("gems", 0))
	iap_event.emit("iap_completed", ev)
	return true


## Giao mọi đơn store còn giữ (khởi động, resume, sau Khôi phục). on_done.call(số đơn đã giao hàng).
func deliver_pending(on_done: Callable = Callable()) -> void:
	if provider == null:
		if on_done.is_valid():
			on_done.call(0)
		return
	var done := [false]
	provider.pending(func(list: Array) -> void:
		if done[0]:
			return
		done[0] = true
		var n := 0
		for e in list:
			var d: Dictionary = e
			if String(d.get("state", "purchased")) != "purchased":
				continue  # chưa thanh toán xong: không thưởng
			if _deliver(d):
				n += 1
		if n > 0:
			changed.emit()
		if on_done.is_valid():
			on_done.call(n))


## Nút "Khôi phục giao dịch": đồng bộ store rồi giao lại. Chỉ có tác dụng với quyền lợi vĩnh viễn còn trong store.
func restore(on_finished: Callable = Callable()) -> void:
	var base := {"sku": "", "why": ""}
	if _busy:
		_finish(on_finished, base, "busy")
		return
	if provider == null or not provider.is_online():
		_finish(on_finished, base, "no_network")
		return
	_busy = true
	_busy_sku = "restore"
	changed.emit()
	provider.restore(func(synced: bool) -> void:
		iap_event.emit("iap_restore", {"ok": synced})
		deliver_pending(func(n: int) -> void:
			_release()
			base["why"] = str(n)
			_finish(on_finished, base, "ok" if synced else "error")))


func _finish(on_finished: Callable, base: Dictionary, status: String) -> void:
	var r := base.duplicate()
	r["status"] = status
	if status in ["failed", "no_network"]:
		iap_event.emit("iap_fail", {"sku": String(base.get("sku", "")), "reason": status})
	changed.emit()
	if on_finished.is_valid():
		on_finished.call(r)
