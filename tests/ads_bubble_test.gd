extends SceneTree
## Chạy: godot --headless --path . -s res://tests/ads_bubble_test.gd
## Bong bóng thưởng income bám theo mái khán đài 3D (Design/26 §4): xuất hiện, đứng yên, đi theo khi xoay, chạm, hết giờ.

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

	var view := RaceView.new()
	view.size = Vector2(390, 320)
	root.add_child(view)
	view.set_track(GameData.class_track(GameData.default_class_id()))
	var ctl := AdsRaceControls.new()
	view.add_child(ctl)
	await _frames(3)
	var bubble: Button = ctl.get_node("CashBubble")
	var flag: Button = ctl.get_node("CashFlag")

	print("== Khán đài 3D có mỏ neo ==")
	_check(view.grandstand_screen_point() != null, "track 3D mặc định luôn có khán đài")
	_check(view._world_3d.view_rect.grow(1.0).has_point(view.grandstand_screen_point()), "mỏ neo nằm trong khung bản đồ")

	print("== Bong bóng xuất hiện ==")
	_check(not bubble.visible, "chưa tới lúc: chưa có bong bóng")
	_ads._flag_wait = 0.0
	ctl.blocked = true
	await _frames(2)
	_check(not bubble.visible, "UI bị chặn: không xuất hiện")
	ctl.blocked = false
	await _frames(2)
	_check(bubble.visible and _ads._flag_live and not flag.visible, "đến lúc: bong bóng hiện, lá cờ cũ không hiện")
	_check(bubble.size.x >= 48 and bubble.size.y >= 44, "vùng chạm >= 48x44")
	await _frames(25)
	var anchor: Vector2 = view.grandstand_screen_point()
	var center := bubble.position + bubble.size * 0.5
	_check(center.y < anchor.y and absf(center.x - anchor.x) < 2.0, "bong bóng nằm ngay trên mái khán đài")

	print("== Xoay bản đồ: bong bóng đi theo ==")
	var p0 := bubble.position
	view.rotate_circuit_view(60.0)
	var a1: Vector2 = view.grandstand_screen_point()
	_check(not a1.is_equal_approx(anchor), "xoay làm mỏ neo đổi vị trí")
	var c1 := bubble.position + bubble.size * 0.5
	_check(absf(c1.x - a1.x) < 2.0 or not ctl._bubble_tail, "bong bóng đi theo ngay trong khung xoay")
	_check(not bubble.position.is_equal_approx(p0), "vị trí bong bóng đổi sau khi xoay")
	var area: Rect2 = view.grandstand_view_rect().grow(1.0)
	for step in 12:
		view.rotate_circuit_view(40.0)
		_check(area.has_point(bubble.position + bubble.size * 0.5), "bong bóng luôn trong khung bản đồ (bước %d)" % step)
	view.reset_circuit_view()

	print("== Đứng yên theo thời gian, bị chặn thì dừng đồng hồ ==")
	var age0: float = ctl._bubble_age
	ctl.blocked = true
	await _frames(10)
	_check(is_equal_approx(ctl._bubble_age, age0), "bị chặn: đồng hồ bong bóng dừng")
	ctl.blocked = false

	print("== Chạm mở popup, xem xong thì mất ==")
	var coins_before = _gs.coins
	bubble.pressed.emit()
	_check(ctl._popup.visible and ctl._popup_pl == "flag_cash", "chạm bong bóng mở popup")
	await _frames(25)
	_check(not bubble.visible or bubble.disabled, "bong bóng vỡ sau khi chạm")
	ctl._on_watch()
	await _frames(40)
	_check(not ctl._popup.visible and not ctl._bubble_on and not _ads._flag_live, "xem xong: popup đóng, bong bóng mất")
	await _frames(20)
	_check(not bubble.visible, "bong bóng đã ẩn hẳn")
	_check(_gs.coins.compare(coins_before) > 0, "đã nhận tiền")

	print("== Hết stay_sec thì mất, không tính lượt ==")
	_fresh()
	_ads._flag_wait = 0.0
	await _frames(3)
	_check(bubble.visible and ctl._bubble_on, "bong bóng mới xuất hiện")
	ctl._bubble_age = float(GameData.ads()["placements"]["flag_cash"]["stay_sec"]) - 0.01
	await _frames(3)
	_check(not ctl._bubble_on and not _ads._flag_live, "hết giờ: bong bóng mất")
	await _frames(25)
	_check(not bubble.visible, "bong bóng ẩn sau hiệu ứng vỡ")

	print("== Vuốt trên bong bóng: huỷ chạm, xoay bản đồ ==")
	_fresh()
	_ads._flag_wait = 0.0
	await _frames(3)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(10, 10)
	ctl._on_bubble_gui_input(press)
	var drag := InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag.position = Vector2(40, 10)
	drag.relative = Vector2(30, 0)
	var yaw0: float = view._world_3d.camera_yaw
	ctl._on_bubble_gui_input(drag)
	_check(not is_equal_approx(view._world_3d.camera_yaw, yaw0), "vuốt trên bong bóng xoay bản đồ")
	bubble.pressed.emit()
	_check(not ctl._popup.visible, "đã vuốt thì không mở popup")

	print("fails: %d" % _fails)
	quit(1 if _fails > 0 else 0)
