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

var provider: IapProvider = null
var _busy := false
var _busy_sku := ""
var _startup_done := false


func _ready() -> void:
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
	if u.has("ad_breaks_today") and int(GameState.ad_state.get("breaks_today", 0)) < int(u["ad_breaks_today"]):
		return false
	return true


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
## "once", "daily", "weekly", "requires", "pass_left", "maxed" (tay đua đã tối đa), "save", "busy".
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
	elif not _unlocked(p.get("unlock", {})):
		return "locked"
	var now := _now()
	if p.has("daily_limit") and int((GameState.iap["daily"] as Dictionary).get(sku, -1)) == GameState.iap_day(now):
		return "daily"
	if p.has("weekly_limit") and int((GameState.iap["weekly"] as Dictionary).get(sku, -1)) == GameState.iap_week(now):
		return "weekly"
	if kind == "pass_month" and int((GameState.iap["pass_month"] as Dictionary).get("left_days", 0)) > int(p.get("rebuy_when_left_days", 5)):
		return "pass_left"
	if _busy:
		return "busy"
	return ""


func can_buy(sku: String) -> bool:
	return block_reason(sku) == ""


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
