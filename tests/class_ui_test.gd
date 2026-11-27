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
	var btn: Button = main.find_child("FacilitiesButton", true, false)
	check(btn != null and btn.is_visible_in_tree() and btn.get_global_rect().end.x <= 390.0, "Nút Class trong HUD, vừa màn hình")
	btn.pressed.emit()
	await settle()
	var page = main._class_page
	check(page.visible, "Nút Class mở modal")
	check(page._header.get_child(0).get_child_count() == 2, "Header chỉ có tiêu đề và nút đóng, không còn số dư tiền")
	var rename: Button = page.find_child("ClassEditName_racing", true, false)
	check(rename != null and not rename.disabled and rename.size.x >= 44, "Thẻ đội có nút sửa tên đủ lớn để chạm")
	rename.pressed.emit()
	await settle()
	var editor = page._rename_dialog
	check(editor.visible and editor._name_input.text == state.player_team_name, "Sửa tên mở ngay trong Classes với tên hiện tại")
	editor._name_input.text = " "
	editor._save_name()
	check(editor.visible and not editor._error.text.is_empty(), "Tên trống giữ hộp thoại mở và báo lỗi")
	editor._name_input.text = "  Đội Tia Chớp  "
	var gems_before: int = state.gems
	editor._save_name()
	await settle()
	check(not editor.visible and page.visible and state.player_team_name == "Đội Tia Chớp", "Lưu tên đã bỏ khoảng trắng, vẫn ở Classes")
	check(state.gems == gems_before and state.team_name_changes == 1, "Đổi tên lần đầu miễn phí")
	check(page.find_child("ClassTeamName_racing", true, false).text == state.player_team_name, "Thẻ đội cập nhật tên ngay sau khi lưu")
	check(state.load_game() == "ok" and state.player_team_name == "Đội Tia Chớp", "Tên đổi từ Classes được lưu qua tải lại")
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
		(page.find_child("ClassEditName_racing", true, false) as Button).pressed.emit()
		await settle()
		var edit_rect: Rect2 = editor._dialog_panel.get_global_rect()
		check(edit_rect.position.x >= 15 and edit_rect.end.x <= dimensions.x - 15, "Hộp đổi tên vừa màn hình %s" % dimensions)
		var cancel_edit := InputEventAction.new()
		cancel_edit.action = "ui_cancel"
		cancel_edit.pressed = true
		page._unhandled_key_input(cancel_edit)
		await settle()
		check(not editor.visible and page.visible, "Escape chỉ đóng đổi tên %s" % dimensions)
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
	check(page.find_child("ClassActive_racing", true, false) != null and page.find_child("ClassWatch_racing", true, false) == null, "Vẫn Active Racing, không có nút Watch cho lớp đang đua")
	check(state.managed_class == "rally" and (page.find_child("ClassEditName_racing", true, false) as Button).disabled, "Chỉ sửa được tên đội của cơ sở đang quản lý (Rally)")
	(page.find_child("ClassEditName_rally", true, false) as Button).pressed.emit()
	await settle()
	editor._name_input.text = "Đội Hai"
	editor._update_rename_cost()
	check(editor._rename_save.text == I18n.t("profile.rename_gems") % 50, "Đổi từ thẻ khác vẫn thông báo phí 50 gem")
	state.gems = 49
	editor._save_name()
	check(editor.visible and state.player_team_name != "Đội Hai" and state.gems == 49, "Không đủ gem: giữ tên và không trừ gem")
	state.gems = 50
	editor._save_name()
	await settle()
	check(not editor.visible and state.gems == 0 and state.team_name_changes == 2, "Đổi lần sau trừ đúng 50 gem")
	check(page.find_child("ClassTeamName_rally", true, false).text == "Đội Hai" and state.facility_team_name("rally") == "Đội Hai", "Thẻ Rally cập nhật tên đội")
	check(page.find_child("ClassTeamName_racing", true, false).text == "Đội Tia Chớp" and state.facility_team_name("racing") == "Đội Tia Chớp", "Tên đội của Racing tách riêng, không đổi theo Rally")
	check(state.active_class == "racing", "Mở xong: vẫn đua Racing")
	var watch: Button = page.find_child("ClassWatch_rally", true, false)
	check(watch != null and watch.size.y >= 44.0, "Rally có nút Watch race đủ lớn để chạm")
	watch.pressed.emit()
	await settle()
	check(state.active_class == "rally" and state.managed_class == "rally", "Watch đổi Active và cơ sở đang quản lý sang Rally")
	check(not page.visible, "Watch đóng popup để hiện màn của class mới")
	page.open()
	await settle()
	check(page.find_child("ClassActive_rally", true, false) != null and page.find_child("ClassWatch_racing", true, false) != null, "Mở lại: Rally Active, Racing có nút Watch")
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
