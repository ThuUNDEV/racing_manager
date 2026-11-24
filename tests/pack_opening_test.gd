extends SceneTree

const Opening = preload("res://ui/pack_opening.gd")
var failures := 0
var signals_received := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)

func settle() -> void:
	for i in 8:
		await process_frame

func run() -> void:
	var state := root.get_node("GameState")
	check(state.SAVE_PATH.contains("/tests/"), "Dùng save thử nghiệm")
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.gems = 100000
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	for kind in ["gear", "driver"]:
		for count in [1, 10]:
			var before: int = state.gear_open_count if kind == "gear" else state.driver_open_count
			if kind == "gear":
				main._on_gear_open("standard", count)
			else:
				main._on_driver_open("pro", count)
			var gems_after: int = state.gems
			main._on_gear_open("standard", 1)
			check(state.gems == gems_after, "Bấm liên tiếp khi đang mở không trừ thêm gem")
			var after: int = state.gear_open_count if kind == "gear" else state.driver_open_count
			check(after - before == count, "Ghi nhận đúng số phần thưởng %s x%d" % [kind, count])
			await settle()
			var results := main._overlay_box.get_node("PackResultContent") as Control
			check(results.visible, "Headless hiện ngay kết quả")
			check(results.get_child_count() == count + 3, "Hiện đầy đủ phần thưởng và nút Xong")
			main._close_overlay()
	# Exercise the real animation timeline even in a headless test.
	for width in [320, 390, 412]:
		root.size.x = width
		var opening := Opening.new()
		opening.motion_enabled = true
		opening.setup(load("res://assets/shop_horizontal_v1/pack_gear_standard.png"), "Gói trang bị ×10", false)
		opening.finished.connect(func() -> void: signals_received += 1)
		root.add_child(opening)
		opening.size.x = width - 64
		await settle()
		opening.set_process(false)
		check(not opening.completed, "Kết quả chờ hoạt ảnh")
		var skip := opening.get_node("SkipOpening") as Button
		check(skip.size.y >= 44 and skip.size.x <= width, "Nút bỏ qua đủ lớn và vừa màn hình")
		if width == 320:
			skip.pressed.emit()
		else:
			opening._process(Opening.DURATION)
		opening.finish()
		check(opening.completed and not opening.visible, "Bỏ qua hoặc hết thời gian đều kết thúc")
		opening.queue_free()
		await settle()
	check(signals_received == 3, "Mỗi hoạt ảnh chỉ kết thúc một lần")
	main.queue_free()
	await settle()
	print("pack_opening_test: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(1 if failures else 0)
