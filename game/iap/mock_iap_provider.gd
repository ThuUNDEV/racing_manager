class_name MockIapProvider
extends IapProvider
## Store giả cho desktop, editor và test headless (Design/28 §7.1). Giữ "kho đơn" như store thật:
## đơn chưa finish vẫn còn trong pending() -> mô phỏng tắt app giữa lúc mua và lúc giao hàng.

var online: bool = true
## Kết quả lần mua kế: "ok" | "pending" | "cancel" | "owned" | "invalid" | "error".
var outcome: String = "ok"
var is_restorable: bool = true
var restore_ok: bool = true
var delay_sec: float = 0.0
## Test: báo kết quả hai lần (SDK bắn trùng).
var double_fire: bool = false
var test_purchase: bool = false
var prices: Dictionary = {}          # sku -> chuỗi giá
var tree: SceneTree = null
var store: Array = []                # kho đơn: [{sku, token, order, state, test}]
var buys: int = 0
var finished: Array = []             # các đơn đã finish (thứ tự gọi)
var _seq: int = 0


func is_online() -> bool:
	return online


func price(sku: String) -> String:
	return String(prices.get(sku, ""))


func restorable() -> bool:
	return is_restorable


func buy(sku: String, done: Callable) -> void:
	buys += 1
	if delay_sec > 0.0 and tree != null:
		await tree.create_timer(delay_sec, true, false, true).timeout
	else:
		await Engine.get_main_loop().process_frame
	var r := {"status": outcome, "sku": sku}
	match outcome:
		"ok", "pending":
			_seq += 1
			var purchase := {"sku": sku, "token": "mock-token-%d" % _seq, "order": "mock-order-%d" % _seq,
				"state": "purchased" if outcome == "ok" else "pending", "test": test_purchase}
			store.append(purchase)
			r["token"] = purchase["token"]
			r["order"] = purchase["order"]
			r["test"] = test_purchase
		"invalid":
			r["reason"] = "signature"
	done.call(r)
	if double_fire:
		done.call(r)


func pending(done: Callable) -> void:
	await Engine.get_main_loop().process_frame
	done.call(store.duplicate(true))


func finish(p: Dictionary) -> void:
	finished.append(p.duplicate(true))
	for i in range(store.size() - 1, -1, -1):
		if String((store[i] as Dictionary)["token"]) == String(p.get("token", "")):
			store.remove_at(i)


func restore(done: Callable) -> void:
	await Engine.get_main_loop().process_frame
	done.call(restore_ok)


## Test: thanh toán của đơn pending đã xong -> chuyển sang purchased (xuất hiện ở pending() như đơn đã trả tiền).
func settle_pending() -> void:
	for e in store:
		if String((e as Dictionary)["state"]) == "pending":
			e["state"] = "purchased"


## Test: thêm đơn có sẵn trong kho (ví dụ non-consumable còn lại sau khi cài lại).
func add_to_store(sku: String, token: String) -> void:
	store.append({"sku": sku, "token": token, "order": "order-" + token, "state": "purchased", "test": false})
