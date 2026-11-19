extends SceneTree
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
	check(state.SAVE_PATH.contains("/tests/"), "Cách ly save")
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	var badge := main.find_child("RaceStageRow", true, false) as Button
	var pos := badge.get_global_rect().get_center()
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		root.push_input(ev)
		await process_frame
	await settle()
	var pop = main._promotion
	check(pop.visible or not state.feature_unlocked("U2_league"), "Huy hiệu hạng mở bảng thăng hạng (hoặc báo khóa)")
	if pop.visible:
		for dims in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(412, 915)]:
			root.size = dims
			await settle()
			await settle()
			var r: Rect2 = pop._popup.get_global_rect()
			var vp: Vector2 = main.size  # stretch canvas_items giữ khung logic 390x845
			check(r.position.x >= 15 and r.end.x <= vp.x - 15 and r.position.y >= 31 and r.end.y <= vp.y - 31, "Popup vừa khung %s" % dims)
			var act: Button = pop.find_child("PromotionAction", true, false)
			check(act.get_global_rect().end.y <= vp.y and act.size.y >= 44, "Nút thăng hạng hiện đủ %s" % dims)
		check((pop.find_child("PromotionNext", true, false) as Label).text == Balance.league_name(1), "Hiện giải kế tiếp")
		check((pop.find_child("PromotionAction", true, false) as Button).disabled, "Chưa đủ điều kiện thì nút tắt")
		root.size = Vector2i(390, 844)
		await settle()
		if "--shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/promotion_popup_390.png")
	print("failures=", failures)
	quit(1 if failures else 0)
