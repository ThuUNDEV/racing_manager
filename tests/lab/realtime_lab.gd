extends SceneTree
## Chạy: godot --headless --path . -s res://tests/lab/realtime_lab.gd [-- --fixed-fps 10 cho Godot]
## Đo: đồng hồ đua (countdown + sim.time) có khớp giờ thật không, kể cả khi frame giật lag (OS.delay_msec)
## và khi engine chạy delta cố định (--fixed-fps 10 làm delta lệch giờ thật). Chạy ~8 giây thật.
## Không đụng save thật: dùng trạng thái mới trong bộ nhớ và chặn ghi đĩa.


func _initialize() -> void:
	await process_frame
	var gs: Node = root.get_node("GameState")
	gs.init_new_game()
	gs.save_blocked = true
	gs.activate()
	var t0 := Time.get_ticks_usec()
	var frames := 0
	var cd0: float = gs.countdown_left
	while float(Time.get_ticks_usec() - t0) / 1e6 < 8.0:
		await process_frame
		frames += 1
		if frames % 40 == 0:
			OS.delay_msec(250)  # giả lập giật lag 0,25 giây
	await process_frame  # frame kế tiếp hấp thụ lần giật cuối trước khi đọc đồng hồ
	var wall := float(Time.get_ticks_usec() - t0) / 1e6
	var game: float
	if gs.phase == "racing":
		game = cd0 + float(gs.sim.time)
	else:
		game = cd0 - float(gs.countdown_left)
	var diff := absf(game - wall)
	print("giờ thật %.2f s · đồng hồ game (countdown + đua) %.2f s · lệch %.2f s · %d frame" % [wall, game, diff, frames])
	print(("  ok   " if diff < 0.25 else "  FAIL ") + "đồng hồ game khớp giờ thật (lệch %.2f s)" % diff)
	quit(0 if diff < 0.25 else 1)
