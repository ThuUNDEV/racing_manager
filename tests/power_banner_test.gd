extends SceneTree
const Banner = preload("res://ui/power_increase_banner.gd")
const BigNumber = preload("res://core/math/big_number.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	print("  OK " if ok else "  FAIL ", message)
	if not ok:
		failures += 1


func settle() -> void:
	for i in range(5):
		await process_frame


func run() -> void:
	var host := Control.new()
	host.size = Vector2(300, 250)
	root.add_child(host)
	var banner := Banner.new()
	host.add_child(banner)
	banner.set_process(false)
	banner.observe_power(460.4)
	banner.set_suspended(false)
	check(not banner.visible, "initial/load baseline does not notify")
	banner.observe_power(468.6)
	banner._process(0.3)
	check(banner.visible and is_equal_approx(banner.gain, 8.2), "positive delta appears")
	check(banner.position.y >= RaceView.HUD_H + 12.0, "banner stays below persistent HUD")
	banner._process(1.0)
	banner.observe_power(476.8)
	check(is_equal_approx(banner.gain, 16.4), "rapid purchases accumulate exact delta")
	banner.observe_power(476.8)
	banner._process(1.81)
	check(banner.visible, "unchanged refresh does not restart or dismiss banner")
	banner._process(0.20)
	check(not banner.visible, "banner disappears after two real seconds")
	banner.observe_power(485.0)
	check(is_equal_approx(banner.gain, 8.2), "next burst uses latest baseline")
	banner.observe_power(450.0)
	check(not banner.visible, "decrease clears stale positive notification")
	banner.set_suspended(true)
	banner.observe_power(458.2)
	banner._process(5.0)
	check(not banner.visible, "popup/tab suspension keeps pending notification hidden")
	banner.set_suspended(false)
	banner._process(0.3)
	check(banner.visible and is_equal_approx(banner.gain, 8.2), "pending increase appears when obstruction closes")
	check(banner.mouse_filter == Control.MOUSE_FILTER_IGNORE, "banner cannot block taps")
	check(RaceView.format_team_power(1000000) == "1,00M", "large totals fit compact formatter")
	host.queue_free()
	await settle()
	if not "--component-only" in OS.get_cmdline_user_args():
		await integration()
	print("POWER BANNER failures=", failures)
	quit(1 if failures else 0)


func integration() -> void:
	var state := root.get_node("GameState")
	# Every write stays in a dedicated test save; never reset the user's progress.
	state.SAVE_PATH = "user://power_banner_test.json"
	state.BAK_PATH = "user://power_banner_test.bak"
	state.TMP_PATH = "user://power_banner_test.tmp"
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.coins = BigNumber.from_int(1000000)
	state.begin_countdown()
	state._start_race()
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main_script = load("res://ui/main.gd")
	if not main_script.can_instantiate():
		check(false, "main UI compiles")
		return
	var main = main_script.new()
	main._shot_prefix = "power-test"
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main._active = true
	main.set_process(false)
	main._overlay.hide()
	var banner = main._power_banner
	banner.set_process(false)
	check(not banner.visible, "main startup has no fake increase")
	banner.set_suspended(false)
	var previous: float = state.team_power()
	check(state.buy("engine"), "real engine purchase succeeds")
	banner._process(0.3)
	check(banner.visible and is_equal_approx(banner.gain, state.team_power() - previous), "committed purchase triggers banner with real delta")
	check(is_equal_approx(main._race_view.power_value, banner.total_power), "persistent power HUD matches banner")
	check(state.buy("ticket"), "revenue purchase succeeds")
	check(is_equal_approx(banner.total_power, state.team_power()), "revenue does not add power")
	banner._process(2.0)
	state.coins = BigNumber.zero()
	check(not state.buy("engine") and not banner.visible, "failed purchase cannot trigger increase")
	main._sync_sim()
	state.sim.time = 5.0
	main._update_race_ui()
	state.coins = BigNumber.from_int(1000000)
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		check(state.buy("engine"), "purchase for native preview at %d" % width)
		banner._process(0.3)
		check(banner.position.y >= RaceView.HUD_H + 12.0 and banner.get_rect().end.x <= main._race_view.size.x, "HUD clear and banner fits at %d" % width)
		if "--power-shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/power_banner_native_%d.png" % width)
	main.queue_free()
	await settle()
	for path in [state.SAVE_PATH, state.BAK_PATH, state.TMP_PATH]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
