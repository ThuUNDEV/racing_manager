extends SceneTree

const BigNumber = preload("res://core/math/big_number.gd")
## Chạy: godot --headless --path . -s res://tests/boot_test.gd
## Kiểm tra BootFlow (Design/09 §3–§5, §8): tiến độ không lùi và không 100% trước readiness, bàn giao đúng một lần,
## retry không phát thưởng offline hai lần, save lỗi/mới hơn được giữ nguyên, lần thử cũ không làm gì sau retry.

var _fails := 0
var _gs: Node  # autoload GameState (không gọi bằng tên trong script SceneTree)


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


## Chạy BootFlow tới khi ready hoặc failed (tối đa ~20 giây). Trả về {ready, code, progress[], flow}.
func _boot(debug_fail: String = "") -> Dictionary:
	var flow := BootFlow.new()
	flow.debug_fail = debug_fail
	root.add_child(flow)
	var st := {"ready": false, "code": "", "progress": [], "flow": flow}
	flow.progressed.connect(func(v: float) -> void: (st["progress"] as Array).append(v))
	flow.failed.connect(func(c: String, _m: String) -> void: st["code"] = c)
	flow.ready_for_handoff.connect(func() -> void: st["ready"] = true)
	flow.start()
	var frames := 0
	while not st["ready"] and st["code"] == "" and frames < 1200:
		await process_frame
		frames += 1
	return st


func _retry(st: Dictionary) -> void:
	st["ready"] = false
	st["code"] = ""
	(st["progress"] as Array).clear()
	(st["flow"] as BootFlow).start()
	var frames := 0
	while not st["ready"] and st["code"] == "" and frames < 1200:
		await process_frame
		frames += 1


func _cleanup(st: Dictionary) -> void:
	var flow := st["flow"] as BootFlow
	if is_instance_valid(flow.gameplay):
		flow.gameplay.queue_free()
	flow.queue_free()
	_gs.active = false
	await process_frame
	await process_frame


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _monotonic(arr: Array) -> bool:
	for i in range(1, arr.size()):
		if float(arr[i]) < float(arr[i - 1]):
			return false
	return true


func _initialize() -> void:
	await process_frame
	_gs = root.get_node("GameState")
	var gs: Node = _gs
	gs.reset_progress()

	print("== Khởi động bình thường ==")
	var st := await _boot()
	var prog: Array = st["progress"]
	_check(st["ready"] and st["code"] == "", "đạt ready, không lỗi")
	_check(_monotonic(prog), "tiến độ không lùi trong cùng một lần thử")
	_check(prog.size() > 0 and float(prog.max()) <= 0.99, "không vượt 99% trước khi gameplay sẵn sàng")
	_check(float(prog.max()) >= 0.99, "chạm 99% khi sẵn sàng")
	var flow: BootFlow = st["flow"]
	_check(is_instance_valid(flow.gameplay) and bool(flow.gameplay.get("is_prepared")), "gameplay đã dựng và vẽ phía sau loading")
	_check(not gs.active, "chưa cộng online/autosave trước bàn giao")
	_check(flow.handoff(), "bàn giao thành công")
	_check(gs.active and not flow.handoff(), "chỉ bàn giao đúng một lần")
	await _cleanup(st)

	print("== Lỗi ghi: retry không phát thưởng offline hai lần ==")
	gs.reset_progress()
	gs.last_accrual_utc = Time.get_unix_time_from_system() - 3600.0
	gs.save_game()
	var coins_saved: BigNumber = gs.coins
	var rate: BigNumber = gs.online_rate()
	st = await _boot("BOOT_WRITE")
	_check(st["code"] == "BOOT_WRITE" and not st["ready"], "ghi lỗi => dừng với BOOT_WRITE, không sẵn sàng")
	await _retry(st)
	_check(st["ready"] and st["code"] == "", "retry thành công")
	_check(_monotonic(st["progress"]), "tiến độ lần thử mới không lùi")
	var reward: BigNumber = gs.coins.subtract_checked(coins_saved)
	var expect := Pricing.offline_reward(rate, 3600.0)
	_check(reward.compare(expect) >= 0 and reward.compare(expect.add(rate.multiply_ratio(5, 1))) <= 0, "thưởng offline đúng một lần (%s ≈ %s)" % [reward.format_compact(), expect.format_compact()])
	_check(not gs.offline_report.is_empty(), "có báo cáo offline chờ hiển thị")
	await _cleanup(st)

	print("== Save mới hơn: giữ nguyên, không ghi đè ==")
	var future := JSON.stringify({"schema_version": 99, "coins": 7})
	_write(_gs.SAVE_PATH, future)
	st = await _boot()
	_check(st["code"] == "BOOT_SAVE" and not st["ready"], "BOOT_SAVE khi save thuộc phiên bản mới hơn")
	_check(gs.save_blocked, "khóa ghi save")
	_check(FileAccess.get_file_as_string(_gs.SAVE_PATH) == future, "file save giữ nguyên")
	await _cleanup(st)

	print("== Save và backup đều hỏng ==")
	_write(_gs.SAVE_PATH, "{hỏng")
	_write(_gs.BAK_PATH, "cũng hỏng")
	st = await _boot()
	_check(st["code"] == "BOOT_SAVE" and not st["ready"], "BOOT_SAVE khi cả hai file hỏng")
	_check(FileAccess.get_file_as_string(_gs.SAVE_PATH) == "{hỏng", "save chính giữ nguyên, không reset")
	_check(FileAccess.get_file_as_string(_gs.BAK_PATH) == "cũng hỏng", "backup giữ nguyên")
	await _cleanup(st)

	print("== Save chính hỏng, backup hợp lệ ==")
	gs.reset_progress()
	gs.coins = BigNumber.from_int(4321)
	gs.save_game()
	var good := FileAccess.get_file_as_string(_gs.SAVE_PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_gs.BAK_PATH))
	_write(_gs.BAK_PATH, good)
	_write(_gs.SAVE_PATH, "không phải json")
	st = await _boot()
	_check(st["ready"] and gs.coins.compare(BigNumber.from_int(4321)) >= 0, "khôi phục từ backup và vào game")
	_check(gs.load_error != "", "có thông báo để gameplay hiện một lần")
	await _cleanup(st)

	print("== Lỗi dữ liệu / tài nguyên có mã riêng ==")
	st = await _boot("BOOT_DATA")
	_check(st["code"] == "BOOT_DATA", "BOOT_DATA")
	await _retry(st)
	_check(st["ready"], "retry sau BOOT_DATA vào được game")
	await _cleanup(st)
	st = await _boot("BOOT_RESOURCE")
	_check(st["code"] == "BOOT_RESOURCE", "BOOT_RESOURCE")
	await _cleanup(st)

	gs.reset_progress()
	print("")
	if _fails > 0:
		print("%d kiểm tra thất bại" % _fails)
		quit(1)
	else:
		print("boot_test: tất cả đạt")
		quit(0)
