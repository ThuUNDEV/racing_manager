extends SceneTree
## Regressions: collection clicks must update body, number and displayed cosmetics.
const OUT := "res://Design/Previews/Garage_Selection_Fix/"
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for frame in 8:
		await process_frame
func run() -> void:
	GameData.reload()
	var gs := root.get_node("GameState")
	check(gs.SAVE_PATH.contains("/tests/"), "Save cách ly")
	gs.init_new_game()
	gs.active = false
	gs.set_process(false)
	gs.tutorial["state"] = "done"
	gs.tutorial["gated"] = false
	gs.tutorial["tips_off"] = true
	gs.coins = BigNumber.from_int(949000)
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 845)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.set_process(false)
	main._select_tab(main.Tab.TEAM)
	main._select_team_sub(1)
	await settle()
	var garage = main._garage
	var active: String = gs.active_car_id
	var saved: Dictionary = gs.garage_cosmetics.duplicate(true)
	var owned: Dictionary = gs.owned_cars.duplicate(true)
	DirAccess.make_dir_recursive_absolute(OUT)
	for width in [320, 390, 412]:
		root.size = Vector2i(width, roundi(width * 845.0 / 390))
		var index := 0
		for car: Dictionary in GameData.cars():
			var id := String(car["id"])
			var button: Button = garage.find_child("Collection_" + id, true, false)
			var thumbnail: CarPreview = button.find_child("CarPreview", true, false)
			var paint := thumbnail.paint_id
			var decal := thumbnail.decal_id
			button.pressed.emit()
			await settle()
			check(garage._viewed == id and garage._preview.car_id == id, "Chọn đúng xe " + id)
			check(garage._preview._car.get_meta("body_class") == int(car["class"]), "Đổi đúng thân xe " + id)
			check(garage._preview._car.get_node("RaceNumber").text == "%02d" % (index + 3), "Đổi đúng số xe " + id)
			check(garage._preview.paint_id == paint and garage._preview.decal_id == decal, "Showroom khớp thumbnail " + id)
			check(garage._preview._paint_material.albedo_color.is_equal_approx(Color(String(GameData.paint(paint)["color"]))), "Vật liệu đúng màu " + id)
			check(not garage._preview.dimmed, "Xe xem trước rõ nét " + id)
			if id == "car_pico_bam_duong":
				check(paint == "blue", "Pico Bám đường chưa sở hữu hiện màu xanh")
			if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless" and (id == "car_pico_bam_duong" or (width == 390 and id in ["car_pico_ben_bi", "car_nova_tia_chop"])):
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT + "%d_%s.png" % [width, id])
			index += 1
	check(gs.active_car_id == active and gs.owned_cars == owned and gs.garage_cosmetics == saved, "Xem xe không mua, trang bị hoặc sửa cosmetics")
	# A newly owned car with no cosmetic record must match its real default paint.
	check(gs.buy_car("car_pico_bam_duong"), "Mua fixture xe qua GameState")
	garage.find_child("Collection_car_pico_bam_duong", true, false).pressed.emit()
	await settle()
	check(garage._preview.paint_id == gs.cosmetics_of("car_pico_bam_duong")["paint_id"], "Xe sở hữu chưa tùy chỉnh dùng mặc định thật")
	# Saved custom paint/decal take precedence over catalogue colours.
	check(gs.set_cosmetics("car_pico_bam_duong", "white", "checker"), "Lưu fixture ngoại hình")
	garage._view_car(active)
	garage.find_child("Collection_car_pico_bam_duong", true, false).pressed.emit()
	await settle()
	var owned_card: Button = garage.find_child("Collection_car_pico_bam_duong", true, false)
	var owned_thumbnail: CarPreview = owned_card.find_child("CarPreview", true, false)
	check(garage._preview.paint_id == "white" and owned_thumbnail.paint_id == "white", "Màu đã lưu khớp hai preview")
	check(garage._preview.decal_id == "checker" and owned_thumbnail.decal_id == "checker", "Họa tiết đã lưu khớp hai preview")
	main.queue_free()
	await settle()
	print("GARAGE_SELECTION_UI_TEST failures=", failures)
	quit(1 if failures else 0)
