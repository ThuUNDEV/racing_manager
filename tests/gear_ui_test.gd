extends SceneTree
## Tab Túi (Design/14 §9): hai gói, kho ba cột, bảng tỉ lệ không tiêu tài nguyên, không tràn ngang.
## Dùng -- --gear-shots để lưu ảnh (cần renderer có cửa sổ).
var failures := 0


func check(value: bool, message: String) -> void:
	print("  ", "OK " if value else "FAIL ", message)
	if not value:
		failures += 1


func _initialize() -> void:
	call_deferred("run")


func settle() -> void:
	for i in range(5):
		await process_frame


func run() -> void:
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	state.SAVE_PATH = "user://gear_ui_test_save.json"
	state.BAK_PATH = "user://gear_ui_test_save.bak"
	state.TMP_PATH = "user://gear_ui_test_save.tmp"
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	state.gems = 500
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main._select_tab(1)  # Tab.BAG
	await settle()
	var gear = main._gear
	var scroll: ScrollContainer = gear.find_child("InventoryScroll", true, false)
	check(main._nav.size() == 5 and main._pages[1].visible, "tab Túi là tab thứ hai và hiển thị")
	check(gear.find_child("Open_standard_x1", true, false) != null and gear.find_child("Open_elite_x10", true, false) != null, "đủ bốn nút mở gói")
	var grid: GridContainer = scroll.get_child(0)
	check(grid != null and grid.columns == 3 and grid.get_child_count() == 30, "kho ba cột đủ 30 ô")

	# Bảng tỉ lệ: không đổi tài nguyên.
	var gems_before: int = state.gems
	gear.info_requested.emit("standard")
	await settle()
	check(main._overlay.visible and state.gems == gems_before and state.gear_open_count == 0, "xem tỉ lệ không tiêu gem, không mở gói")
	main._overlay.hide()

	# Mở gói bằng nút.
	(gear.find_child("Open_standard_x1", true, false) as Button).pressed.emit()
	await settle()
	check(state.gems == gems_before - 10 and state.gear_owned_count() == 1, "Open x1 trừ 10 gem, nhận một phụ kiện mới")
	check(main._overlay.visible, "hiện bảng kết quả")
	main._overlay.hide()
	var owned_id: String = state.gear_owned.keys()[0]
	check(gear.find_child("Upgrade_" + owned_id, true, false) == null, "chưa đủ mảnh: không có nút Nâng cấp")
	state.gear_owned[owned_id]["shards"] = 1000
	gear.refresh()
	await settle()
	var up := gear.find_child("Upgrade_" + owned_id, true, false) as Button
	check(up != null, "đủ mảnh: có nút Nâng cấp")
	up.pressed.emit()
	await settle()
	check(state.gear_level(owned_id) == 1, "bấm Nâng cấp tăng level")

	# Nút bị khóa khi thiếu gem.
	state.gems = 0
	gear.refresh()
	await settle()
	check((gear.find_child("Open_standard_x1", true, false) as Button).disabled, "thiếu gem: nút Open khóa")
	state.grant_gear_coupons("standard", 1)
	gear.refresh()
	await settle()
	var b1 := gear.find_child("Open_standard_x1", true, false) as Button
	check(not b1.disabled and b1.text.contains("coupon"), "có coupon: nút hiển thị coupon và mở được")

	for width in [320, 360, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		scroll = gear.find_child("InventoryScroll", true, false)
		grid = scroll.get_child(0)
		check(gear.size.x <= scroll.size.x + 1, "tab Túi vừa khung %d, không tràn ngang" % width)
		for card in grid.get_children():
			if card.get_global_rect().end.x > scroll.get_global_rect().end.x + 1:
				check(false, "ô kho tràn ở %d" % width)
				break
		if "--gear-shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/gear_%d.png" % width)

	state.active = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://gear_ui_test_save.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://gear_ui_test_save.bak"))
	print("GEAR_UI_TEST failures=", failures)
	quit(1 if failures > 0 else 0)
