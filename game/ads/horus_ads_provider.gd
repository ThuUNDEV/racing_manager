class_name HorusAdsProvider
extends AdsProvider
## Quảng cáo thật qua Horus SDK (MAX trong app, quảng cáo giả lập trên trình duyệt). Chỉ chạy trong bản Web
## có web/shell.html: gọi window.rmHorus qua JavaScriptBridge (Design/25 §7).

var _bridge: JavaScriptObject = null
var _show_cb: JavaScriptObject = null  # phải giữ tham chiếu tới khi JS gọi lại, nếu không callback bị giải phóng


func _init(bridge: JavaScriptObject = null) -> void:
	_bridge = bridge


## "rewarded" / "cancelled" / "error" (chuỗi JS gửi về) -> status của hợp đồng provider. Thiếu hoặc lạ = error.
static func map_status(args: Array) -> String:
	if args.is_empty() or typeof(args[0]) != TYPE_STRING:
		return "error"
	match String(args[0]):
		"rewarded":
			return "rewarded"
		"cancelled":
			return "cancelled"
	return "error"


func is_online() -> bool:
	return _bridge != null and bool(_bridge.online())


func is_ready(_placement: String) -> bool:
	return _bridge != null and bool(_bridge.rv)


func load_rewarded() -> void:
	if _bridge != null:
		_bridge.loadRewarded()


func show_rewarded(placement: String, done: Callable) -> void:
	if _bridge == null:
		done.call({"status": "error"})
		return
	_show_cb = JavaScriptBridge.create_callback(func(args: Array) -> void:
		done.call({"status": map_status(args)}))
	_bridge.showRewarded(placement, _show_cb)
