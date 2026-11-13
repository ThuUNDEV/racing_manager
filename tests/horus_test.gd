extends SceneTree
## Chạy: godot --headless --path . -s res://tests/horus_test.gd
## Phần logic thuần của nối Horus SDK (Design/25 §7): ánh xạ kết quả quảng cáo, vòng đời app, khôi phục save từ bản sao,
## và trên desktop thì autoload Horus không đụng gì. Phần JavaScriptBridge chỉ kiểm tra được trên trình duyệt.

var _fails := 0
const DIR := "user://tests/horus_test/"


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _clean() -> void:
	for f in ["save.json", "save.bak"]:
		if FileAccess.file_exists(DIR + f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR + f))


func _initialize() -> void:
	await process_frame

	print("== Kết quả quảng cáo từ JS ==")
	_check(HorusAdsProvider.map_status(["rewarded"]) == "rewarded", "rewarded")
	_check(HorusAdsProvider.map_status(["cancelled"]) == "cancelled", "cancelled")
	_check(HorusAdsProvider.map_status(["error"]) == "error", "error")
	_check(HorusAdsProvider.map_status([]) == "error", "thiếu đối số: error")
	_check(HorusAdsProvider.map_status(["gì đó lạ"]) == "error", "chuỗi lạ: error (không bao giờ thưởng)")
	_check(HorusAdsProvider.map_status([null]) == "error", "null: error")

	print("== Vòng đời app ==")
	var p := HorusPlatform.lifecycle_action("pause", "ad")
	_check(p["mute"] and not p["suspend"] and not p["resume"], "pause do quảng cáo: tắt tiếng, không suspend")
	p = HorusPlatform.lifecycle_action("pause", "bg")
	_check(p["mute"] and p["suspend"], "pause ra nền: tắt tiếng + suspend")
	p = HorusPlatform.lifecycle_action("pause", "")
	_check(p["suspend"], "pause không rõ lý do: coi như ra nền")
	p = HorusPlatform.lifecycle_action("resume", "")
	_check(not p["mute"] and p["resume"] and not p["suspend"], "resume: bật tiếng, tiếp tục")
	p = HorusPlatform.lifecycle_action("???", "bg")
	_check(not p["mute"] and not p["suspend"] and not p["resume"], "sự kiện lạ: không làm gì")

	print("== Khôi phục save từ bản sao của app ==")
	var sp := DIR + "save.json"
	var bp := DIR + "save.bak"
	var backup := '{"schema_version": 1, "gems": 42}'
	_clean()
	_check(not HorusPlatform.restore_backup(sp, bp, ""), "không có bản sao: không ghi")
	_check(not HorusPlatform.restore_backup(sp, bp, "không phải json"), "bản sao hỏng: không ghi")
	_check(not HorusPlatform.restore_backup(sp, bp, "[1,2]"), "bản sao không phải object: không ghi")
	_check(not FileAccess.file_exists(sp), "chưa có file nào được tạo")
	_check(HorusPlatform.restore_backup(sp, bp, backup), "máy trống: ghi bản sao")
	_check(FileAccess.get_file_as_string(sp) == backup, "nội dung giữ nguyên từng ký tự")
	_check(not HorusPlatform.restore_backup(sp, bp, '{"gems": 1}') and FileAccess.get_file_as_string(sp) == backup, "đã có save: không ghi đè")
	_clean()
	var f := FileAccess.open(bp, FileAccess.WRITE)
	f.store_string("{}")
	f.close()
	_check(not HorusPlatform.restore_backup(sp, bp, backup) and not FileAccess.file_exists(sp), "còn bản .bak: để load_game tự khôi phục, không ghi đè")
	_clean()

	print("== Desktop: Horus không đụng gì ==")
	var ads: Node = root.get_node("Ads")
	_check(root.has_node("Horus"), "autoload Horus có mặt")
	_check(ads.provider is MockAdsProvider, "desktop vẫn dùng MockAdsProvider")
	_check(HorusPlatform.web_bridge() == null, "không có bridge ngoài bản Web")

	print("")
	print("THẤT BẠI: %d" % _fails if _fails > 0 else "TẤT CẢ ĐẠT")
	quit(1 if _fails > 0 else 0)
