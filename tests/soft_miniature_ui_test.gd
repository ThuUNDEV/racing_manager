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

func check_width(scope: Node, width: int) -> void:
	for node in scope.find_children("*", "Control", true, false):
		if not node.is_visible_in_tree() or node is TextureRect or node is ScrollBar:
			continue
		if node is Label or node is Button or node is PanelContainer:
			var rect: Rect2 = node.get_global_rect()
			check(rect.position.x >= -1 and rect.end.x <= width + 1, "%s fits %d: %s" % [node.name, width, rect])

func run() -> void:
	PopupAnim.enabled = false
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tests/soft_miniature_integration.json"
	state.BAK_PATH = "user://tests/soft_miniature_integration.bak"
	state.TMP_PATH = "user://tests/soft_miniature_integration.tmp"
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.set_process(false)
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.coins = BigNumber.from_int(12500)
	state.gems = 240
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
		await settle()
		for tab in 5:
			main._select_tab(tab)
			await settle()
			check(main._pages[tab].is_visible_in_tree(), "selected page visible")
			check(main._race_block.is_visible_in_tree() == (tab == 0), "circuit only on Race")
			check_width(main._pages[tab], dimensions.x)
			var nav := main.find_child("BottomNavigation", true, false) as Control
			# Khay điều hướng tràn sát hai mép và đáy (lấn NAV_BLEED ra ngoài), không để hở nền.
			var nav_rect := nav.get_global_rect()
			check(nav_rect.position.x <= 0.0 and nav_rect.end.x >= dimensions.x, "navigation spans edge to edge at %d" % dimensions.x)
			check(nav_rect.end.y >= dimensions.y and nav_rect.end.y <= dimensions.y + main.NAV_BLEED + 1, "navigation flush with the bottom edge")
			await capture("%d_tab_%d" % [dimensions.x, tab])
			if tab == 0:
				var a: Control = main._rows[0]["tile"]
				var b: Control = main._rows[1]["tile"]
				check(b.global_position.y >= a.get_global_rect().end.y, "upgrades stack in one column")
				var nav_y := nav.global_position.y
				var race_rect: Rect2 = main._race_block.get_global_rect()
				var upgrade_y := a.global_position.y
				check(main._upgrade_scroll.size.y > 0, "upgrade viewport has space")
				(main._upgrade_scroll as ScrollContainer).scroll_vertical = 100000
				await settle()
				check(nav.global_position.y == nav_y, "scroll leaves navigation fixed")
				check(main._race_block.get_global_rect() == race_rect, "scroll leaves entire race cluster fixed")
				check(a.global_position.y < upgrade_y, "upgrades move when scrolling")
				var last_tile: Control = main._rows[-1]["tile"]
				check(last_tile.get_global_rect().end.y <= main._upgrade_scroll.get_global_rect().end.y + 1, "last upgrade is reachable")
				await capture("%d_race_income" % dimensions.x)
				(main._upgrade_scroll as ScrollContainer).scroll_vertical = 0
			if tab == 2:
				var grid := main._roster.find_child("DriverGrid", true, false) as GridContainer
				check(grid != null and grid.columns == 2, "driver roster has two columns")
				main._select_team_sub(1)
				for section in ["0", "1", "2"]:
					main._garage.debug_show(section)
					await settle()
					check_width(main._garage, dimensions.x)
					await capture("%d_garage_%s" % [dimensions.x, section])
				main._select_team_sub(0)
		main._show_settings()
		await settle()
		check_width(main._overlay, dimensions.x)
		await capture("%d_settings" % dimensions.x)
		main._overlay.hide()
		main._show_iap_detail("starter_1")
		await settle()
		check_width(main._overlay, dimensions.x)
		check(main._shop_content._detail_buy.text != "", "detail shows live store price")
		await capture("%d_pack_detail" % dimensions.x)
		main._overlay.hide()
		main._roster._open_sheet(state.active_driver_id)
		await settle()
		check(main._roster.sheet.visible, "driver detail opens")
		check_width(main._roster.sheet, dimensions.x)
		main._roster.close_sheet()
	main._select_tab(0)
	var level_before: int = state.level_of("engine")
	var coins_before: BigNumber = state.coins
	var buy := main._rows[0]["btn"] as Button
	check(not buy.disabled, "affordable upgrade enabled")
	buy.button_down.emit()
	buy.button_up.emit()
	check(state.level_of("engine") == level_before + 1, "upgrade increases real part level")
	check(state.coins.compare(coins_before) < 0, "upgrade spends real currency")
	state.coins = BigNumber.zero()
	main._refresh_rows()
	check(buy.disabled, "unaffordable upgrade disabled")
	state.grant_gear_coupons("standard", 1)
	main._select_tab(4)
	main._shop_content.update_packs()
	await settle()
	var pack := main.find_child("ShopOpen_gear_standard_x1", true, false) as Button
	check(pack != null and not pack.disabled, "gear ticket enables Shop pack")
	var count_before: int = state.gear_open_count
	pack.pressed.emit()
	await settle()
	check(state.gear_open_count == count_before + 1, "Shop pack button opens real gear pack")
	check(main._overlay.visible, "pack rewards open in modal")
	main._overlay.hide()
	main._show_settings()
	var music := main.find_child("MusicToggle", true, false) as CheckButton
	var on_before: bool = main._music_on
	music.toggled.emit(not on_before)
	check(main._music_on != on_before, "settings toggle updates actual music state")
	main.queue_free()
	await settle()
	for path: String in [state.SAVE_PATH, state.BAK_PATH, state.TMP_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("SOFT_MINIATURE_UI_TEST failures=", failures)
	quit(1 if failures else 0)
