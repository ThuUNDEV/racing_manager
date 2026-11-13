class_name HorusIapProvider
extends IapProvider
## Thanh toán thật qua Horus SDK (platform.iap.*). Chỉ chạy trong bản Web có web/shell.html: gọi window.rmHorus qua
## JavaScriptBridge như HorusAdsProvider. Callback JS được giữ trong _cbs tới khi gọi xong (nếu không bị giải phóng).

var _bridge: JavaScriptObject = null
var _cbs: Array = []


func _init(bridge: JavaScriptObject = null) -> void:
	_bridge = bridge


## Chuỗi JSON đơn từ JS -> Dictionary đơn của hợp đồng. Thiếu/lạ = {}.
static func parse_purchase(json: String) -> Dictionary:
	var v: Variant = JSON.parse_string(json)
	if typeof(v) != TYPE_DICTIONARY:
		return {}
	return {"sku": String(v.get("sku", "")), "token": String(v.get("token", "")), "order": String(v.get("orderId", "")),
		"state": String(v.get("state", "purchased")), "test": bool(v.get("test", false)), "reason": String(v.get("reason", ""))}


## Kết quả mua từ JS (JSON {"status","sku","token","orderId","reason","test"}) -> status hợp đồng. Lạ = error.
static func parse_buy(json: String) -> Dictionary:
	var v: Variant = JSON.parse_string(json)
	if typeof(v) != TYPE_DICTIONARY or not String(v.get("status", "")) in ["ok", "pending", "cancel", "owned", "invalid", "error"]:
		return {"status": "error"}
	return {"status": String(v["status"]), "sku": String(v.get("sku", "")), "token": String(v.get("token", "")),
		"order": String(v.get("orderId", "")), "reason": String(v.get("reason", "")), "test": bool(v.get("test", false))}


func is_online() -> bool:
	return _bridge != null and bool(_bridge.online())


func price(sku: String) -> String:
	if _bridge == null:
		return ""
	var v: Variant = _bridge.iapPrice(sku)
	return String(v) if v != null else ""


func restorable() -> bool:
	return _bridge != null and bool(_bridge.iapRestorable())


func buy(sku: String, done: Callable) -> void:
	if _bridge == null:
		done.call({"status": "error", "sku": sku})
		return
	var cb := JavaScriptBridge.create_callback(func(args: Array) -> void:
		done.call(parse_buy(String(args[0]) if args.size() > 0 else "")))
	_cbs.append(cb)
	_bridge.iapBuy(sku, cb)


func pending(done: Callable) -> void:
	if _bridge == null:
		done.call([])
		return
	var cb := JavaScriptBridge.create_callback(func(args: Array) -> void:
		var out: Array = []
		var arr: Variant = JSON.parse_string(String(args[0]) if args.size() > 0 else "[]")
		if typeof(arr) == TYPE_ARRAY:
			for e in arr:
				var p := parse_purchase(JSON.stringify(e))
				if not p.is_empty():
					out.append(p)
		done.call(out))
	_cbs.append(cb)
	_bridge.iapPending(cb)


func finish(p: Dictionary) -> void:
	if _bridge != null:
		_bridge.iapFinish(JSON.stringify(p))


func restore(done: Callable) -> void:
	if _bridge == null:
		done.call(false)
		return
	var cb := JavaScriptBridge.create_callback(func(args: Array) -> void:
		done.call(args.size() > 0 and bool(args[0])))
	_cbs.append(cb)
	_bridge.iapRestore(cb)
