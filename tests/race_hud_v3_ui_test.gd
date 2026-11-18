extends SceneTree
## Integration checks against real GameState, containers and controls. --capture writes real renders.
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
		DirAccess.make_dir_recursive_absolute("res://Design/Previews/Soft_Miniature_Integrated")
		root.get_texture().get_image().save_png("res://Design/Previews/Soft_Miniature_Integrated/" + id + ".png")

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
	state.SAVE_PATH = "user://tests/race_hud_v3.json"
	state.BAK_PATH = "user://tests/race_hud_v3.bak"
	state.TMP_PATH = "user://tests/race_hud_v3.tmp"
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.set_process(false)
	var mock := MockAdsProvider.new()
	mock.tree = self
	root.get_node("Ads").provider = mock
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.coins = BigNumber.from_int(12500)
	state.gems = 240
	state.daily_rewards["unlocked"] = true
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	state.begin_countdown()
	state._start_race()
	state.active = false
	for i in state.sim.cars.size():
		var car: TrafficSim.Car = state.sim.cars[i]
		car.s = state.sim.lap_length * (0.12 + i * 0.085)
		car.prev_s = car.s
	state.sim.tick_count = 1
	main._sync_sim()
	main._update_race_ui()
	main._race_view.overlay_text = ""
	main._race_view.alpha = 1.0
	check(main._nav.size() == 5, "exactly five navigation tabs")
	check(main._rows.size() == 8, "four vehicle and four income upgrades")
	check(main._race_block.get_parent() == main._pages[0], "circuit belongs to fixed Race page")
	for dimensions: Vector2i in [Vector2i(320, 568), Vector2i(390, 778), Vector2i(412, 915)]:
		root.size = dimensions
		main._select_tab(0)
		await settle()
		check(main.find_child("ResetCircuitView", true, false) == null, "reset button removed")
		check(not main._race_no_label.visible, "race number removed")
		check(not "Income" in main._income_label.text and not "Thu nhập" in main._income_label.text, "compact income")
		var daily: Button = main._daily_btn
		var boost: Button = main._ads_controls._chip
		check(daily.is_visible_in_tree(), "Daily Gift visible when unlocked")
		check(not daily.get_global_rect().intersects(boost.get_global_rect()), "reward tiles do not overlap")
		check(main._race_view.get_global_rect().encloses(daily.get_global_rect()), "Daily Gift fits cluster")
		check(main._race_view.get_global_rect().encloses(boost.get_global_rect()), "ads tile fits cluster")
		check(daily.get_global_rect().size.y >= 40 and boost.get_global_rect().size.y >= 40, "reward targets usable at smallest width")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			DirAccess.make_dir_recursive_absolute("res://output/race_hud_v3")
			image.save_png("res://output/race_hud_v3/%s_%d_full.png" % [I18n.lang(), dimensions.x])
			image.get_region(Rect2i(main._race_view.get_global_rect())).save_png("res://output/race_hud_v3/%s_%d_cluster.png" % [I18n.lang(), dimensions.x])
		var sc: ScrollContainer = main._upgrade_scroll
		var race: Rect2 = main._race_block.get_global_rect()
		var first: Control = main._rows[0]["tile"]
		var last: Control = main._rows[-1]["tile"]
		var before := first.global_position.y
		var nav: Control = main.find_child("BottomNavigation", true, false)
		check(sc.size.y > 80, "upgrade viewport remains usable at %s" % dimensions)
		check(sc.get_global_rect().position.y >= race.end.y, "upgrades below fixed race")
		sc.scroll_vertical = 100000
		await settle()
		check(main._race_block.get_global_rect() == race, "entire race cluster stays fixed")
		check(first.global_position.y < before, "upgrades move")
		check(last.get_global_rect().end.y <= sc.get_global_rect().end.y + 1, "last upgrade reachable")
		check(nav.get_global_rect().end.y <= dimensions.y + 1, "navigation stays on screen")
		await main._tutorial_reveal("A4_engine")
		await settle()
		check(first.global_position.y >= sc.global_position.y - 1, "tutorial reveals engine in upgrade scroller")
		main._select_tab(4)
		await settle()
		check(not main._race_block.is_visible_in_tree(), "race hidden on other tabs")
		main._select_tab(0)
		await settle()
		check(main._race_block.is_visible_in_tree(), "race restored on Race tab")
		print("Checked fixed race at ", dimensions)
	await click(main._daily_btn)
	await settle()
	check(main._overlay.visible and is_instance_valid(main._daily_popup), "Daily Gift opens live reward popup")
	main._close_overlay()
	var ads: Control = main._ads_controls
	await click(ads._chip)
	await settle()
	check(ads._popup.visible, "ads button opens real confirmation")
	await click(ads._watch)
	for i in 40:
		await process_frame
	check(state.income_boost_left > 1700, "rewarded video activates actual income boost")
	check(ads._chip.disabled and ads._chip_progress.visible, "active boost displays countdown and progress")
	ads._on_later()
	main.queue_free()
	await settle()
	for path: String in [state.SAVE_PATH, state.BAK_PATH, state.TMP_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("RACE_HUD_V3_UI_TEST failures=", failures)
	quit(1 if failures else 0)
