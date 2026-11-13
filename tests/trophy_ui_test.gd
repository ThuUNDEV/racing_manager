extends SceneTree
## Bảng nâng cấp cúp ở tab Giải: hiển thị số cúp/trần, nút mua theo số cúp, bấm mua thật, không tràn ngang.
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


func _texts(node: Node, out: Array) -> void:
	if node is Label:
		out.append((node as Label).text)
	if node is Button:
		out.append((node as Button).text)
	for ch in node.get_children():
		_texts(ch, out)


func _buttons(node: Node, out: Array) -> void:
	if node is Button:
		out.append(node)
	for ch in node.get_children():
		_buttons(ch, out)


func _find_scroll(node: Node) -> Node:
	var n := node
	while n != null:
		if n is ScrollContainer:
			return n
		n = n.get_parent()
	return null


func run() -> void:
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	state.SAVE_PATH = "user://trophy_ui_test_save.json"
	state.BAK_PATH = "user://trophy_ui_test_save.bak"
	state.TMP_PATH = "user://trophy_ui_test_save.tmp"
	state.save_blocked = false
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main._select_tab(3)  # Tab.LEAGUE
	await settle()

	print("== Bảng cúp khi chưa có cúp ==")
	var box: Control = main._league_box
	var banner: Node = box.find_child("TrophyBanner", true, false)
	check(banner != null, "có banner cúp")
	check(box.find_child("TrophyCount", true, false).text == "0", "banner hiện số cúp")
	check(box.find_child("TrophyEarned", true, false).text == "0 / 100", "banner hiện tổng đã kiếm / trần")
	var info: Button = box.find_child("TrophyInfo", true, false)
	var cap_info: Label = box.find_child("TrophyCapInfo", true, false)
	check(not cap_info.visible, "giải thích giới hạn cúp mặc định thu gọn")
	info.button_pressed = true
	check(cap_info.visible, "bấm i mở giải thích giới hạn")
	info.button_pressed = false
	var texts: Array = []
	_texts(box, texts)
	var joined := "
".join(texts)
	check(joined.contains("Thưởng top 3") and joined.contains("P1 +3") and joined.contains("P3 +1"), "ghi rõ điều kiện top 3 và mức thưởng")
	check(box.find_child("Group_offense", true, false) != null and box.find_child("Group_defense", true, false) != null and box.find_child("Group_income", true, false) != null, "có ba nút lọc nhóm")
	check(box.find_child("Upgrade_speed_tune", true, false) != null and box.find_child("Upgrade_corner_grip", true, false) == null, "chỉ hiện nâng cấp của nhóm đang chọn")
	check(joined.contains("Tốc độ  +0 → +1"), "hiệu ứng là số cụ thể từ → tới")
	var buy: Button = box.find_child("Buy_speed_tune", true, false)
	check(buy != null and buy.text == "1" and buy.disabled, "nút giá 1 cúp bị khóa khi chưa có cúp")
	check(box.find_child("Buy_overtake_kit", true, false) == null and joined.contains("Mở ở giải"), "thẻ khóa gọn, không hiện nút mua trước khi mở giải")

	print("== Đổi nhóm ==")
	(box.find_child("Group_defense", true, false) as Button).pressed.emit()
	await settle()
	box = main._league_box
	check(box.find_child("Upgrade_corner_grip", true, false) != null and box.find_child("Upgrade_speed_tune", true, false) == null, "chuyển sang nhóm Phòng thủ")
	(box.find_child("Group_income", true, false) as Button).pressed.emit()
	await settle()
	box = main._league_box
	texts = []
	_texts(box, texts)
	check(box.find_child("Upgrade_sponsor", true, false) != null and "
".join(texts).contains("giây"), "nhóm Thu nhập hiện đơn vị giây")
	(box.find_child("Group_offense", true, false) as Button).pressed.emit()
	await settle()
	box = main._league_box

	print("== Có cúp thì mua được ==")
	state.trophies = 3
	state.trophies_earned = 3
	state.changed.emit()
	await settle()
	box = main._league_box
	buy = box.find_child("Buy_speed_tune", true, false)
	check(buy != null and not buy.disabled, "nút giá 1 cúp mở khi có cúp")
	buy.pressed.emit()
	await settle()
	box = main._league_box
	check(state.trophy_level("speed_tune") == 1 and state.trophies == 2, "bấm mua trừ 1 cúp, lên 1 cấp")
	check(box.find_child("TrophyCount", true, false).text == "2", "số cúp trên banner cập nhật")
	check(box.find_child("TrophyEarned", true, false).text == "3 / 100", "tiêu cúp không làm giảm tổng đã kiếm")
	check((box.find_child("Buy_speed_tune", true, false) as Button).text == "2", "giá cấp kế tăng lên 2")

	print("== Không tràn ngang ==")
	for width in [320, 360, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		var scroll := _find_scroll(main._league_box)
		check(scroll == null or main._league_box.get_combined_minimum_size().x <= width, "bảng vừa chiều rộng %d (min %.0f)" % [width, main._league_box.get_combined_minimum_size().x])
		if main._league_box.get_combined_minimum_size().x > width:
			for ch in main._league_box.get_children():
				print("    min.x=%.0f  %s" % [(ch as Control).get_combined_minimum_size().x, ch.name])
		if "--trophy-shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/trophy_layout_%d.png" % width)

	print("== Trạng thái khóa và giới hạn ==")
	state.business_tier = 2
	state.trophies = 100
	state.trophies_earned = 100
	state.changed.emit()
	await settle()
	box = main._league_box
	check(box.find_child("Buy_overtake_kit", true, false) != null, "thẻ khóa mở đầy đủ khi đạt giải Chuyên nghiệp")
	state.trophy_levels["speed_tune"] = 10
	state.changed.emit()
	await settle()
	buy = main._league_box.find_child("Buy_speed_tune", true, false)
	check(buy.disabled and buy.text == "TỐI ĐA", "cấp tối đa không thể mua thêm")
	state.save_blocked = true
	state.changed.emit()
	await settle()
	buy = main._league_box.find_child("Buy_launch_boost", true, false)
	check(buy.disabled, "khóa mua khi lưu game bị chặn")
	state.save_blocked = false
	for group in ["offense", "defense", "income"]:
		main._set_trophy_group(group)
		await settle()
		check(main._league_box.get_combined_minimum_size().x <= 320, "nhóm %s vừa chiều rộng 320 khi mở đủ nâng cấp" % group)

	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://trophy_ui_test_save.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://trophy_ui_test_save.bak"))
	print("TROPHY_UI_TEST failures=%d" % failures)
	quit(0 if failures == 0 else 1)
