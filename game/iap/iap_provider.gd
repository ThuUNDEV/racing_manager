class_name IapProvider
extends RefCounted
## Hợp đồng giữa IapService và một nguồn thanh toán (mock, Horus SDK...). Design/28 §7.1.
## Provider chỉ thu tiền và báo đơn; không giao hàng. Mọi kết quả trả qua Callable (có thể trễ nhiều khung hình).
##
## Một đơn (purchase) là Dictionary: {"sku", "token", "order", "state": "purchased" | "pending", "test": bool}.

## Có mạng để mua không.
func is_online() -> bool:
	return true


## Giá store theo quốc gia; "" khi không có (dùng price_fallback trong data/iap.json).
func price(_sku: String) -> String:
	return ""


## Có nút "Khôi phục giao dịch" không (app có module billing).
func restorable() -> bool:
	return false


## Mua. done.call({"status": "ok" | "pending" | "cancel" | "owned" | "invalid" | "error",
##   "sku", "token", "order", "test": bool, "reason": String}).
func buy(sku: String, done: Callable) -> void:
	done.call({"status": "error", "sku": sku})


## Đơn store còn giữ mà game chưa finish. done.call(Array[Dictionary]).
func pending(done: Callable) -> void:
	done.call([])


## Báo đã giao hàng và lưu xong: store consume/acknowledge đơn.
## p = {"sku", "token", "order", "consumable": bool, "usd": float (bỏ khi đơn test)}.
func finish(_p: Dictionary) -> void:
	pass


## Đồng bộ tài khoản store (iOS). done.call(bool).
func restore(done: Callable) -> void:
	done.call(false)
