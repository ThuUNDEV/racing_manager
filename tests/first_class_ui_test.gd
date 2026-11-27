extends SceneTree
## Chạy: godot --headless --path . -s res://tests/first_class_ui_test.gd
## Game mới: popup chọn class đầu tiên hiện trước tutorial, không đóng được, chọn xong mở vòng lặp theo trường đua của class.
var failures := 0


func check(ok: bool, message: String) -> void:
	print("OK " if ok else "FAIL ", message)
	if not ok:
		failures += 1


func settle() -> void:
	for i in 10:
		await process_frame


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	check(state.SAVE_PATH.contains("/tests/"), "Save isolation")
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	state.activate()
	main.activate()
	await settle()
	var page = main._class_page
	check(state.first_class_pending and state.gate_first_class, "Game mới: chờ chọn và tạm dừng vòng lặp")
	check(page.visible and not page._popup.visible, "Chỉ hiện popup chọn, không hiện danh sách cơ sở")
	var grid = page.find_child("PickerGrid", true, false)
	check(grid != null and grid.get_child_count() == GameData.race_classes().size(), "Popup liệt kê đủ mọi class kể cả Racing")
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		var panel: PanelContainer = page.find_child("PickerPanel", true, false)
		check(panel.get_global_rect().position.x >= 0 and panel.get_global_rect().end.x <= width, "Popup chọn class vừa màn hình %d" % width)
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	page._unhandled_key_input(cancel)
	check(page.visible and is_instance_valid(page._picker), "Escape không đóng popup chọn class")
	var dim = page.find_child("PickerDim", true, false)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	dim.gui_input.emit(click)
	check(page.visible and is_instance_valid(page._picker), "Bấm nền tối không đóng popup chọn class")
	var ok: Button = page.find_child("PickerOk", true, false)
	check(ok.disabled, "OK khóa tới khi chọn")
	(page.find_child("PickerOption_rally", true, false) as Button).pressed.emit()
	check(not ok.disabled, "Chọn Rally thì mở OK")
	ok.pressed.emit()
	await settle()
	check(not page.visible and not state.first_class_pending and not state.gate_first_class, "Chọn xong: đóng popup, mở lại vòng lặp")
	check(state.active_class == "rally" and state.class_owned == ["rally"], "Cơ sở đầu là Rally")
	print("Kết quả: ", "ĐẠT" if failures == 0 else "%d lỗi" % failures)
	quit(1 if failures > 0 else 0)
