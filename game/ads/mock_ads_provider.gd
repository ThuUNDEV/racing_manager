class_name MockAdsProvider
extends AdsProvider
## Quảng cáo giả cho desktop, editor và test headless (Design/25 §4). Không hiện gì: chờ `delay_sec` rồi báo kết quả.

var online: bool = true
var ready: bool = true
## Kết quả lần xem: "rewarded" (xem hết), "cancelled" (đóng sớm), "error" (lỗi hiển thị).
var outcome: String = "rewarded"
var delay_sec: float = 0.0
## Test: báo kết quả hai lần (giả lập SDK bắn rewarded rồi closed, hoặc closed lặp).
var double_fire: bool = false
var shows: int = 0
var loads: int = 0
var tree: SceneTree = null


func is_online() -> bool:
	return online


func is_ready(_placement: String) -> bool:
	return ready


func load_rewarded() -> void:
	loads += 1


func show_rewarded(_placement: String, done: Callable) -> void:
	shows += 1
	var result := {"status": outcome}
	if delay_sec > 0.0 and tree != null:
		await tree.create_timer(delay_sec, true, false, true).timeout
	else:
		await Engine.get_main_loop().process_frame
	done.call(result)
	if double_fire:
		done.call(result.duplicate())
