extends SceneTree
## Icon quảng cáo pack ở dải chặng: hiện/ẩn theo Iap.block_reason, chấm đỏ, bấm mở popup, vùng chạm. --capture ghi ảnh.
const BigNumber = preload("res://core/math/big_number.gd")
const PopupAnim = preload("res://ui/popup_anim.gd")
var failures := 0
var main: Control

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)

func settle() -> void:
	for i in 10:
		await process_frame

func capture(id: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://Design/Previews/pack_promo_strip")
		root.get_texture().get_image().save_png("res://Design/Previews/pack_promo_strip/" + id + ".png")

func shown(kind: String) -> bool:
	return (main._promo_ui[kind]["button"] as Button).visible

func click(button: BaseButton) -> void:
	var pos := button.get_global_rect().get_center()
	var hover := InputEventMouseMotion.new()
	hover.position = pos
	root.push_input(hover, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = pos
		event.global_position = pos
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()

func run() -> void:
	PopupAnim.enabled = false
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tests/pack_promo_strip.json"
	state.BAK_PATH = "user://tests/pack_promo_strip.bak"
	state.TMP_PATH = "user://tests/pack_promo_strip.tmp"
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.set_process(false)
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.coins = BigNumber.from_int(12500)
	state.daily_rewards["unlocked"] = true
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)

	check(main._promo_ui.size() == 3, "ba icon pack: starter, offer, weekly")
	check(shown("starter") and main._promo_ui["starter"]["sku"] == "starter_1", "starter_1 hiện đầu tiên")
	check(not shown("offer"), "offer_noads_bundle ẩn khi chưa đủ 3 lần Ads Break")
	check((main._promo_ui["starter"]["dot"] as Control).visible, "chấm đỏ hiện khi chưa bấm")

	state.ad_state["breaks_today"] = 3
	main._refresh_pack_promos()
	check(shown("offer") and main._promo_ui["offer"]["sku"] == "offer_noads_bundle", "offer_noads_bundle hiện khi đủ 3 lần")

	for dimensions: Vector2i in [Vector2i(320, 568), Vector2i(390, 778), Vector2i(412, 915)]:
		root.size = dimensions
		main._select_tab(0)
		await settle()
		var strip := main.find_child("ActionStrip", true, false) as Control
		var rects: Array[Rect2] = []
		for button: Button in [main._daily_btn, main._ads_controls._chip, main._promo_ui["starter"]["button"], main._promo_ui["offer"]["button"]]:
			if not button.is_visible_in_tree():
				continue
			var r := button.get_global_rect()
			check(r.size.x >= 44.0 and r.size.y >= 44.0, "vùng chạm >= 44 ở %s: %s" % [dimensions, button.name])
			check(strip.get_global_rect().grow(1.0).encloses(r), "nằm trong ActionStrip ở %s: %s" % [dimensions, button.name])
			for other in rects:
				check(not other.intersects(r), "các ô không chồng nhau ở %s: %s" % [dimensions, button.name])
			rects.append(r)
		await capture("strip_%d" % dimensions.x)

	state.iap["buys"].append({"sku": "starter_1"})
	state.iap["buys"].append({"sku": "starter_2"})
	state.iap["buys"].append({"sku": "starter_3"})
	main._refresh_pack_promos()
	check(not shown("starter"), "starter ẩn khi đã mua cả ba")
	state.iap["buys"].clear()
	main._refresh_pack_promos()
	check(shown("starter"), "starter hiện lại khi chưa mua")

	root.size = Vector2i(390, 778)
	await settle()
	var button: Button = main._promo_ui["starter"]["button"]
	await click(button)
	check(not (main._promo_ui["starter"]["dot"] as Control).visible, "bấm xong tắt chấm đỏ")
	check(main._overlay_box.get_child_count() > 1, "bấm icon mở popup chi tiết pack")
	await capture("popup_starter_390")
	main._close_overlay()
	await settle()

	print("PACK_PROMO_STRIP_TEST failures=", failures)
	quit(1 if failures > 0 else 0)
