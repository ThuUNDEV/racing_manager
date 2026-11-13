extends SceneTree
## Chạy: godot --headless --path . -s res://tests/class_ui_test.gd [-- --class-shots]
## Modal Classes: mở từ HUD, thẻ Mua/Watch/Active, mua và đổi class, không tràn ngang trên màn nhỏ.
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
	state.coins = BigNumber.from_int(1000)
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	var btn: Button = main.find_child("ClassButton", true, false)
	check(btn != null and btn.get_global_rect().end.x <= 390.0 and btn.get_global_rect().size.y >= 44.0, "Nút Class trong HUD, vừa màn hình")
	btn.pressed.emit()
	await settle()
	var page = main._class_page
	check(page.visible, "Nút Class mở modal")
	check(page.find_child("ClassActive_racing", true, false) != null, "Racing là Active khi mới vào")
	check(page.find_child("ClassCard_rally", true, false) == null and page.find_child("ClassCard_racing", true, false) != null, "Chỉ hiện class đã có cơ sở")
	var fbuy: Button = page.find_child("FacilityBuy", true, false)
	check(fbuy != null and fbuy.disabled, "Thiếu tiền: nút Mở cơ sở xám")
	check(page.find_child("FacilityPicker", true, false) == null, "Chưa mở cơ sở: chưa có popup chọn loại")
	for dimensions in [Vector2i(320, 568), Vector2i(360, 800), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = dimensions
		await settle()
		var popup: PanelContainer = page.find_child("ClassPopup", true, false)
		var rect := popup.get_global_rect()
		check(rect.position.x >= 11 and rect.end.x <= dimensions.x - 11 and rect.position.y >= 23 and rect.end.y <= dimensions.y - 23, "Popup có khoảng hở quanh game %s" % dimensions)
		check(rect.get_center().distance_to(Vector2(dimensions) * 0.5) < 1.0, "Popup nằm giữa màn hình %s" % dimensions)
		check(page._scroll.get_h_scroll_bar().max_value <= page._scroll.size.x + 1, "Không tràn ngang %s" % dimensions)
		if "--class-shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/classes_native_%d.png" % dimensions.x)
	root.size = Vector2i(390, 844)
	state.coins = state.facility_price().add(BigNumber.from_int(1))
	state.changed.emit()
	await settle()
	fbuy = page.find_child("FacilityBuy", true, false)
	check(fbuy != null and not fbuy.disabled, "Đủ tiền: nút Mở cơ sở sáng")
	fbuy.pressed.emit()
	await settle()
	check(state.facilities == ["racing", ""] and page.find_child("FacilityBuy", true, false) == null, "Mở cơ sở xong: chờ chọn loại, hết nút mở")
	var picker = page.find_child("FacilityPicker", true, false)
	check(picker != null, "Mua xong mở ngay popup chọn loại")
	check(picker.find_child("PickerGrid", true, false).columns == 2 and picker.find_child("PickerOption_racing", true, false) == null and picker.find_child("PickerOption_rally", true, false) != null, "Popup dạng lưới 2 cột, không có class đã có cơ sở")
	var ok: Button = picker.find_child("PickerOk", true, false)
	check(ok.disabled, "Chưa chọn: nút OK xám")
	(picker.find_child("PickerOption_stock", true, false) as Button).pressed.emit()
	await settle()
	if "--class-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/classes_native_picker.png")
	(picker.find_child("PickerOption_rally", true, false) as Button).pressed.emit()
	await settle()
	ok = picker.find_child("PickerOk", true, false)
	ok.disabled = true
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	page._unhandled_key_input(cancel)
	await settle()
	check(page.visible, "Escape đóng bảng chọn loại trước, giữ popup Classes")
	check(page.find_child("FacilityPicker", true, false) == null and state.facility_unassigned() == 1 and page.find_child("FacilityPick", true, false) != null, "Bấm ra ngoài: cơ sở vẫn chờ, nút Chọn loại")
	(page.find_child("FacilityPick", true, false) as Button).pressed.emit()
	await settle()
	picker = page.find_child("FacilityPicker", true, false)
	(picker.find_child("PickerOption_rally", true, false) as Button).pressed.emit()
	await settle()
	ok = picker.find_child("PickerOk", true, false)
	check(not ok.disabled, "Chọn một ô: OK sáng")
	ok.pressed.emit()
	await settle()
	check(state.class_has("rally") and state.facilities == ["racing", "rally"] and page.find_child("FacilityPicker", true, false) == null and page.find_child("ClassWatch_rally", true, false) != null, "OK: hoàn tất, Rally có thẻ Watch")
	check(page.find_child("ClassActive_racing", true, false) != null, "Vẫn Active Racing")
	check(state.managed_class == "rally" and (page.find_child("ClassManage_rally", true, false) as Button).disabled, "Mở xong: tự quản lý Rally")
	var mg: Button = page.find_child("ClassManage_racing", true, false)
	check(mg != null and not mg.disabled, "Racing có nút Quản lý")
	mg.pressed.emit()
	await settle()
	check(state.managed_class == "racing" and state.active_class == "racing" and (page.find_child("ClassManage_racing", true, false) as Button).disabled, "Quản lý đổi tức thì, không đổi cơ sở đang đua")
	(page.find_child("ClassWatch_rally", true, false) as Button).pressed.emit()
	await settle()
	check(state.active_class == "rally" and page.find_child("ClassActive_rally", true, false) != null, "Watch đổi Active sang Rally")
	if "--class-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Design/Previews/classes_native_owned.png")
	(page.find_child("ClassClose", true, false) as Button).pressed.emit()
	await settle()
	check(not page.visible, "Nút × đóng modal")
	page.open()
	await settle()
	page._unhandled_key_input(cancel)
	check(not page.visible, "Escape đóng popup Classes")
	page.open()
	await settle()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	page.find_child("ClassBackdrop", true, false).gui_input.emit(click)
	check(not page.visible, "Bấm nền tối đóng popup Classes")
	print("Kết quả: ", "ĐẠT" if failures == 0 else "%d lỗi" % failures)
	quit(1 if failures > 0 else 0)
