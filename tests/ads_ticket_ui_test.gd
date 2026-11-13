extends SceneTree
## Screen layout and rewarded-ad dismissal/retry checks, using an isolated test save.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)

func settle() -> void:
	for i in 8:
		await process_frame

func run() -> void:
	var gs := root.get_node("GameState")
	var ads := root.get_node("Ads")
	check(gs.SAVE_PATH.contains("/tests/"), "isolated save")
	gs.reset_progress()
	gs.active = false
	gs.begin_countdown()
	gs._start_race()
	gs.active = false
	gs.set_process(false)
	var mock := MockAdsProvider.new()
	mock.tree = self
	ads.provider = mock
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main: Control
	var race: RaceView
	var ctl: AdsRaceControls
	if "--ticket-component" in OS.get_cmdline_user_args():
		main = Control.new()
		root.add_child(main)
		main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		race = RaceView.new()
		main.add_child(race)
		race.position = Vector2(16, 120)
		race.size = Vector2(root.size.x - 32, 300)
		race.set_track(gs.PROTOTYPE_TRACK)
		race.sim = gs.sim
		race.power_value = 449.4
		root.size_changed.connect(func() -> void: race.size.x = root.size.x - 32)
		ctl = AdsRaceControls.new()
		race.add_child(ctl)
	else:
		main = load("res://ui/main.gd").new() as Control
		root.add_child(main)
		main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		race = main._race_view
		ctl = main._ads_controls
	await settle()
	gs.active = false
	# Use the real clipped race view, rather than a standalone fullscreen popup.
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		check(ctl.get_global_rect().encloses(ctl._chip.get_global_rect()), "boost ticket fits race %d" % width)
		var rank := race.hud_rank_rect()
		check(is_equal_approx(rank.position.y, ctl._chip.position.y) and is_equal_approx(rank.size.y, ctl._chip.size.y), "rank and boost align %d" % width)
		check(rank.end.x + 7.9 <= ctl._chip.position.x, "rank and boost have gap %d" % width)
		check(ctl._chip.position.y + ctl._chip.size.y <= RaceView.HUD_H - 5.9, "boost stays above spectators")
		check(ctl._chip_time.text == "Xem video" and "×2" in ctl._chip_title.text, "orange ticket CTA and multiplier")
		if "--ticket-shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/ads_boost_entry_%d.png" % width)
			root.get_texture().get_image().get_region(Rect2i(race.get_global_rect())).save_png("res://Design/Previews/ads_boost_offer_race_%d.png" % width)
		# Render active boost during a live race as well as the offered button.
		var idle_skin := ctl._chip.get_theme_stylebox("disabled")
		gs.income_boost_left = 1549.0
		ctl._refresh_chip()
		await settle()
		check(ctl._chip_state == "active" and ctl._chip_title.text == "ĐANG ×2", "explicit active state")
		check(ctl._chip.get_theme_stylebox("disabled") != idle_skin and ctl._chip_progress.visible, "active has distinct skin and progress")
		check(ctl._chip.disabled and ctl._chip_time.text == "25:49", "active countdown and disabled action")
		check(ctl._chip.get_rect().encloses(Rect2(ctl._chip.position + ctl._chip_title.position, ctl._chip_title.size)), "active label fits ticket")
		if "--ticket-shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/ads_boost_active_%d.png" % width)
			root.get_texture().get_image().get_region(Rect2i(race.get_global_rect())).save_png("res://Design/Previews/ads_boost_active_race_%d.png" % width)
		gs.income_boost_left = 0.0
		ctl._refresh_chip()
		check(ctl._chip_state == "offer" and not ctl._chip_progress.visible and ctl._chip_time.text == "Xem video", "expiry restores orange offer")
		ctl._chip.pressed.emit()
		await settle()
		var screen := Rect2(Vector2.ZERO, Vector2(root.size))
		check(ctl._popup.get_global_rect().size.is_equal_approx(screen.size), "full-screen backdrop %d" % width)
		check(ctl._popup_layer.layer > 0, "escapes race clipping")
		for control in [ctl._card, ctl._title, ctl._watch, ctl._later, ctl._close_button]:
			check(screen.encloses(control.get_global_rect()), "fits screen %d: %s" % [width, control.name])
		check(ctl._title.get_global_rect().end.x <= ctl._close_button.get_global_rect().position.x + 1, "title clears close")
		check(ctl._watch.size.y >= 44 and ctl._close_button.size.y >= 48, "touch target sizes")
		check(ctl._watch.get_global_rect().end.y <= ctl._later.get_global_rect().position.y + 0.1, "actions do not overlap")
		check(ctl._multiplier.text == "×2" and "30 phút" in ctl._duration.text, "configured reward labels")
		check("cash" in ctl._body.text, "cash income copy")
		if "--ticket-shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/ads_ticket_%d.png" % width)
		ctl._close_button.pressed.emit()
		check(not ctl._popup.visible and gs.income_boost_left == 0, "X closes without reward")
	ctl._open(ctl.BOOST)
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	ctl._unhandled_key_input(escape)
	check(not ctl._popup.visible, "Escape dismisses")
	ctl._open(ctl.BOOST)
	mock.delay_sec = 0.15
	mock.outcome = "cancelled"
	ctl._on_watch()
	check(ctl._close_button.disabled and ctl._later.disabled, "cannot close during ad")
	ctl._unhandled_key_input(escape)
	check(ctl._popup.visible, "Escape cannot dismiss active ad")
	await create_timer(0.3).timeout
	check(ctl._popup.visible and not ctl._close_button.disabled and not ctl._watch.disabled, "cancelled ad can retry or close")
	check(not ctl._status.text.is_empty() and gs.income_boost_left == 0, "cancelled ad has feedback, no boost")
	# Switching placements must not leave a stale multiplier or cash-art position.
	ctl._on_later()
	ctl._open(ctl.FLAG)
	check(not ctl._multiplier.visible and not ctl._duration.visible, "cash flag has no timed boost")
	ctl._on_later()
	ctl._open(ctl.BOOST)
	check(ctl._multiplier.visible and ctl._cash_art.position.x < ctl._card.size.x * 0.2, "boost restores hero layout")
	ctl._on_later()
	ctl._open(ctl.BOOST)
	mock.delay_sec = 0.0
	mock.outcome = "rewarded"
	gs.simulate_write_failure = true
	ctl._on_watch()
	await settle()
	check(ctl._popup.visible and ctl._watch.text == "Thử nhận lại" and not ctl._close_button.disabled, "save failure offers retry and close")
	check(ads.has_pending(ctl.BOOST) and gs.income_boost_left == 0, "failed save keeps pending reward")
	gs.simulate_write_failure = false
	var shows := mock.shows
	ctl._on_watch()
	await settle()
	check(not ctl._popup.visible and gs.income_boost_left > 1700, "retry grants configured boost")
	check(mock.shows == shows, "retry does not replay ad")
	check(ctl._chip.disabled and ":" in ctl._chip_time.text and "×2" in ctl._chip_title.text, "active ticket shows countdown")
	main.queue_free()
	await settle()
	print("ADS_TICKET_UI_TEST failures=", failures)
	quit(1 if failures else 0)
