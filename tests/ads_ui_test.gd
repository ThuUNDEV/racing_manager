extends SceneTree
## Chạy: godot --headless --path . -s res://tests/ads_ui_test.gd
## Điều khiển quảng cáo trên khung đua (ui/ads_race_controls.gd): chip ×2, lá cờ thưởng income, popup xem video.

var _fails := 0
var _gs: Node
var _ads: Node
var _mock: MockAdsProvider


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _fresh() -> void:
	GameData.reload()
	_gs.reset_progress()
	_gs.ad_state = {}
	_gs.income_boost_left = 0.0
	_gs.active = false
	_gs.simulate_write_failure = false
	_ads._flag_wait = -1.0
	_ads._flag_live = false
	_ads._pending = {}
	_mock.online = true
	_mock.ready = true
	_mock.outcome = "rewarded"
	_mock.delay_sec = 0.0


func _initialize() -> void:
	await process_frame
	_gs = root.get_node("GameState")
	_ads = root.get_node("Ads")
	_mock = MockAdsProvider.new()
	_mock.tree = self
	_ads.provider = _mock
	_fresh()

	var host := Control.new()
	host.size = Vector2(375, 294)
	root.add_child(host)
	var ctl := AdsRaceControls.new()
	host.add_child(ctl)
	await _frames(2)
	var chip: Button = ctl.get_node("BoostChip")
	var flag: Button = ctl.get_node("CashFlag")
	var popup: Control = ctl._popup

	print("== Chip ×2 ==")
	_check(chip.visible and not chip.disabled and "×2" in chip.text, "chip hiện, bấm được: '%s'" % chip.text.replace("\n", " "))
	_check(chip.position.x > host.size.x * 0.6 and chip.position.y < RaceView.HUD_H, "chip nằm góc phải trên (trong HUD)")
	_mock.ready = false
	await _frames(2)
	_check(chip.visible and chip.disabled, "quảng cáo chưa tải: chip xám, không bấm được")
	_mock.ready = true
	await _frames(2)
	chip.pressed.emit()
	_check(popup.visible, "bấm chip mở popup xác nhận")
	ctl._on_later()
	_check(not popup.visible and _gs.income_boost_left == 0.0, "Để sau: đóng popup, không có thưởng")
	chip.pressed.emit()
	ctl._on_watch()
	await _frames(40)
	_check(_gs.income_boost_left > 1700.0, "xem xong: boost bật (%d giây)" % int(_gs.income_boost_left))
	_check(not popup.visible, "popup tự đóng sau khi nhận")
	_check(chip.visible and chip.disabled and "×2" in chip.text and ":" in chip.text, "đang boost: chip là đồng hồ '%s'" % chip.text.replace("\n", " "))

	print("== Chip giữ vị trí và giải thích khi hết lượt / bị khóa ==")
	_fresh()
	_gs.ad_state = {"day": int(floor(Time.get_unix_time_from_system() / 86400.0)), "count": 12, "by": {}, "last": {}}
	await _frames(2)
	_check(chip.visible and chip.disabled and ctl._chip_time.text == "Hết lượt ngày", "hết trần ngày: giữ chip và báo lý do")
	_fresh()
	_gs.tutorial["gated"] = true
	_gs.completed_races = 0
	await _frames(2)
	_check(chip.visible and chip.disabled and ctl._chip_time.text == "Mở Shop", "chưa mở Shop: giữ chip và chỉ dẫn mở khóa")

	print("== Lá cờ ==")
	_fresh()
	await _frames(2)
	_check(not flag.visible, "chưa tới lúc: chưa có cờ")
	_ads._flag_wait = 0.0
	ctl.blocked = true
	await _frames(2)
	_check(not flag.visible, "UI bị chặn (bảng kết quả...): cờ không xuất hiện")
	ctl.blocked = false
	await _frames(2)
	_check(flag.visible and _ads._flag_live, "đến lúc và không bị chặn: cờ xuất hiện")
	var x0 := flag.position.x
	await _frames(10)
	_check(flag.position.x > x0, "cờ chạy từ trái sang phải")
	_check(flag.position.y >= RaceView.HUD_H and flag.position.y + flag.size.y <= RaceView.HUD_H + RaceView.STAND_H, "cờ chạy trong dải khán giả phía trên đường đua")
	ctl.blocked = true
	var xb := flag.position.x
	await _frames(5)
	_check(is_equal_approx(flag.position.x, xb), "bị chặn: cờ đứng yên")
	ctl.blocked = false
	var coins_before = _gs.coins
	flag.pressed.emit()
	_check(popup.visible, "chạm cờ mở popup")
	var xp := flag.position.x
	await _frames(5)
	_check(is_equal_approx(flag.position.x, xp), "popup mở: cờ đứng yên")
	ctl._on_watch()
	await _frames(40)
	_check(not popup.visible and not flag.visible and not _ads._flag_live, "xem xong: popup và cờ đều mất")
	_check(_gs.coins.compare(coins_before) > 0, "đã nhận tiền")
	_check(is_equal_approx(_gs.income_boost_left, 0.0), "cờ không bật boost")
	_check(_ads.flag_wait_left() >= 100.0, "đếm giờ lá cờ kế (%d giây)" % int(_ads.flag_wait_left()))

	print("== Cờ: đóng popup và để trôi ==")
	_fresh()
	_ads._flag_wait = 0.0
	await _frames(2)
	flag.pressed.emit()
	var c2 = _gs.coins
	ctl._on_later()
	_check(not popup.visible and not flag.visible and _gs.coins.compare(c2) == 0, "Đóng: cờ mất, không có tiền")
	_fresh()
	_ads._flag_wait = 0.0
	await _frames(2)
	_check(flag.visible, "cờ mới xuất hiện")
	ctl._flag_x = host.size.x + 1.0
	await _frames(2)
	_check(not flag.visible and not _ads._flag_live, "ra khỏi mép phải: cờ mất")
	_check(int(_gs.ad_state.get("flag_misses", 0)) == 1, "tính một lần bỏ lỡ")

	print("== Popup khi xem thất bại ==")
	_fresh()
	_ads._flag_wait = 0.0
	await _frames(2)
	flag.pressed.emit()
	_mock.outcome = "cancelled"
	ctl._on_watch()
	await _frames(40)
	_check(popup.visible and flag.visible, "xem dở: popup vẫn mở để thử lại hoặc đóng")
	_check(ctl._popup.visible and not (ctl._watch.disabled), "nút Xem video bấm lại được")
	ctl._on_later()

	print("== Kết thúc: %d lỗi ==" % _fails)
	quit(1 if _fails > 0 else 0)
