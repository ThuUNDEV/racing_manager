class_name AdsProvider
extends RefCounted
## Hợp đồng giữa AdsService và một nguồn quảng cáo (mock, Horus SDK...). Design/25 §4, §7.
## Provider chỉ hiện quảng cáo và báo kết quả; không phát thưởng, không biết placement nào cho gì.

## Có mạng để xin quảng cáo không.
func is_online() -> bool:
	return true


## Đã có rewarded tải sẵn cho placement này chưa.
func is_ready(_placement: String) -> bool:
	return false


## Xin tải trước (khi sắp mời xem). Không bắt buộc làm gì.
func load_rewarded() -> void:
	pass


## Hiện rewarded rồi gọi done.call({"status": "rewarded" | "cancelled" | "error"}).
## Provider có thể gọi done nhiều lần hoặc trễ; AdsService tự chống lặp.
func show_rewarded(_placement: String, done: Callable) -> void:
	done.call({"status": "error"})


## Đã có interstitial tải sẵn chưa (Ads Break, Design/26 §7).
func is_inter_ready() -> bool:
	return false


func load_interstitial() -> void:
	pass


## Hiện interstitial rồi gọi done.call({"shown": bool}). Có thể gọi trễ hoặc nhiều lần.
func show_interstitial(_placement: String, done: Callable) -> void:
	done.call({"shown": false})
