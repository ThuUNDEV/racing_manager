class_name BootFlow
extends Node
## Điều phối khởi động (Design/09): dữ liệu → save → tài nguyên → dựng gameplay → sẵn sàng → bàn giao.
## Không đụng giao diện loading: chỉ phát tín hiệu tiến độ/trạng thái/lỗi. Mỗi lần thử có token riêng;
## coroutine của lần thử cũ tự dừng ở lần chờ kế tiếp nên không đổi UI, save hay scene sau khi retry.

signal progressed(target: float)  ## 0..1, không lùi trong một lần thử, tối đa 0.99 trước khi sẵn sàng
signal status_changed(text: String)
signal failed(code: String, message: String)
signal attempt_started
signal ready_for_handoff  ## mọi điều kiện §4 đã đạt, gameplay đang được loading che kín

const GAMEPLAY_SCENE := "res://scenes/main.tscn"
const WORKSHOP := "res://assets/workshop_gp/"
const DATA_FILES := ["sim", "economy", "tracks", "leagues", "cars", "drivers"]
const MAX_BEFORE_READY := 0.99
const PREPARE_TIMEOUT_MS := 30000

## Trọng số bước: [id, từ, tới, chữ hiển thị]. Cần hiệu chỉnh bằng đo thực tế trên thiết bị.
const STEPS := {
	"start": [0.00, 0.10, "boot.starting_up"],
	"data": [0.10, 0.25, "boot.loading_game_data"],
	"save": [0.25, 0.45, "boot.restoring_racing_team"],
	"resources": [0.45, 0.85, "boot.loading_race_track"],
	"prepare": [0.85, 0.99, "boot.finishing_up"],
}

## Tài nguyên bắt buộc của màn đầu tiên. Thiếu một tệp => BOOT_RESOURCE.
const REQUIRED := [
	GAMEPLAY_SCENE,
	WORKSHOP + "theme.tres",
	WORKSHOP + "components/workshop_audio.gd",
	WORKSHOP + "styles/card.tres",
	WORKSHOP + "styles/modal.tres",
	WORKSHOP + "styles/avatar.tres",
	WORKSHOP + "styles/button_secondary.tres",
	WORKSHOP + "styles/nav_selected.tres",
	WORKSHOP + "ui/app_background.svg",
]

var gameplay: Control = null
var attempt: int = 0

# Tham số gỡ lỗi (CLI): --boot-slow=<giây mỗi bước>, --boot-fail=<mã lỗi> (chỉ lần thử đầu), --reset.
var debug_slow: float = 0.0
var debug_fail: String = ""
var reset_save: bool = false

var _token: int = 0
var _target: float = 0.0
var _handed_off: bool = false
var _held: Array = []  # giữ tham chiếu tài nguyên đã nạp cho tới khi gameplay dựng xong


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--boot-slow="):
			debug_slow = float(a.substr(12))
		elif a.begins_with("--boot-fail="):
			debug_fail = a.substr(12)
		elif a == "--reset":
			reset_save = true


## Bắt đầu một lần thử mới (lần đầu hoặc retry). Lần thử cũ, nếu còn, bị vô hiệu.
func start() -> void:
	_token += 1
	attempt += 1
	_run(_token)


## Autoload lấy qua đường dẫn node để script này cũng biên dịch được trong test dạng SceneTree.
func _gs() -> Node:
	return get_node("/root/GameState")


func _alive(tok: int) -> bool:
	return tok == _token and is_inside_tree()


# ---------------------------------------------------------------- tiến độ

func _enter(step: String) -> void:
	status_changed.emit(I18n.t(String(STEPS[step][2])))
	_advance(step, 0.0)


## Tiến độ nội bộ `frac` (0..1) trong bước `step`; chỉ tăng.
func _advance(step: String, frac: float) -> void:
	var s: Array = STEPS[step]
	var v := minf(MAX_BEFORE_READY, float(s[0]) + (float(s[1]) - float(s[0])) * clampf(frac, 0.0, 1.0))
	if v > _target:
		_target = v
		progressed.emit(_target)


func _pause(tok: int) -> bool:
	## Một khung hình (để loading vẽ kịp), cộng độ trễ giả lập nếu đang gỡ lỗi. false = lần thử đã bị thay.
	if debug_slow > 0.0:
		await get_tree().create_timer(debug_slow / 4.0).timeout
	else:
		await get_tree().process_frame
	return _alive(tok)


func _fail(tok: int, code: String, message: String) -> void:
	if _alive(tok):
		failed.emit(code, message)


func _consume_debug_fail(code: String) -> bool:
	return debug_fail == code and attempt == 1


# ---------------------------------------------------------------- các bước

func _run(tok: int) -> void:
	_target = 0.0
	_handed_off = false
	_discard_gameplay()
	_gs().simulate_write_failure = _consume_debug_fail("BOOT_WRITE")
	attempt_started.emit()
	progressed.emit(0.0)

	# A. Khởi động
	_enter("start")
	if attempt > 1:
		status_changed.emit(I18n.t("boot.retrying"))
	if not await _pause(tok):
		return
	_advance("start", 1.0)

	# B. Dữ liệu cấu hình
	_enter("data")
	GameData.reload()
	for i in DATA_FILES.size():
		GameData._load(DATA_FILES[i])
		_advance("data", float(i + 1) / float(DATA_FILES.size() + 1))
		if not await _pause(tok):
			return
	var errs := GameData.validate()
	if _consume_debug_fail("BOOT_DATA"):
		errs = ["simulated data error"]
	if not errs.is_empty():
		push_error("BOOT_DATA: " + "; ".join(errs))
		_fail(tok, "BOOT_DATA", I18n.t("boot.game_data_missing_or_invalid"))
		return
	_advance("data", 1.0)

	# C. Save
	_enter("save")
	_gs().init_new_game()
	if reset_save and attempt == 1:
		_gs().reset_progress()
	if not await _pause(tok):
		return
	var result: String = _gs().load_game()
	if _consume_debug_fail("BOOT_SAVE"):
		result = "corrupt"
	match result:
		"corrupt":
			_fail(tok, "BOOT_SAVE", I18n.t("boot.could_not_read_saved_progress"))
			return
		"newer":
			_fail(tok, "BOOT_SAVE", I18n.t("boot.this_progress_was_saved_by"))
			return
	_advance("save", 1.0)
	if not await _pause(tok):
		return

	# D. Tài nguyên bắt buộc (nạp bất đồng bộ, không chặn main thread)
	_enter("resources")
	var failed_path := await _load_required(tok)
	if not _alive(tok):
		return
	if _consume_debug_fail("BOOT_RESOURCE"):
		failed_path = "simulated"
	if failed_path != "":
		push_error("BOOT_RESOURCE: " + failed_path)
		_fail(tok, "BOOT_RESOURCE", I18n.t("boot.could_not_load_game_required"))
		return

	# E. Dựng gameplay phía sau lớp loading
	_enter("prepare")
	var packed := _held[0] as PackedScene
	gameplay = packed.instantiate() as Control
	if gameplay == null or not gameplay.has_method("activate") or gameplay.get("is_prepared") == null:
		_discard_gameplay()
		_fail(tok, "BOOT_RESOURCE", I18n.t("common.could_not_build_game_screen"))
		return
	_advance("prepare", 0.2)
	if not await _pause(tok):
		_discard_gameplay()
		return
	get_tree().root.add_child(gameplay)  # Main._ready dựng UI nhưng chưa kích hoạt
	_advance("prepare", 0.6)
	var prepare_deadline := Time.get_ticks_msec() + PREPARE_TIMEOUT_MS
	while is_instance_valid(gameplay) and not gameplay.get("is_prepared"):
		if Time.get_ticks_msec() >= prepare_deadline:
			_discard_gameplay()
			_fail(tok, "BOOT_RESOURCE", I18n.t("common.could_not_build_game_screen"))
			return
		if debug_slow > 0.0:
			await get_tree().create_timer(0.05).timeout
		else:
			await get_tree().process_frame
		if not _alive(tok):
			return
	if not is_instance_valid(gameplay):
		_fail(tok, "BOOT_RESOURCE", I18n.t("common.could_not_build_game_screen"))
		return
	_advance("prepare", 0.8)
	if not await _pause(tok):
		return
	# Chốt offline sau cùng: lỗi ghi ở đây không để lại phần thưởng chưa kèm báo cáo cho lần thử sau.
	if not _gs().settle_offline():
		_fail(tok, "BOOT_WRITE", I18n.t("boot.could_not_save_progress_check"))
		return
	_held.clear()
	_advance("prepare", 1.0)
	ready_for_handoff.emit()


## Nạp REQUIRED bằng ResourceLoader threaded. Trả về đường dẫn lỗi đầu tiên, hoặc "" nếu đủ.
func _load_required(tok: int) -> String:
	_held.clear()
	for path: String in REQUIRED:
		if not ResourceLoader.exists(path):
			return path
		if ResourceLoader.load_threaded_request(path, "", true) != OK:
			return path
	var progress: Array = []
	while true:
		var done := 0
		var sum := 0.0
		for path: String in REQUIRED:
			var st := ResourceLoader.load_threaded_get_status(path, progress)
			match st:
				ResourceLoader.THREAD_LOAD_LOADED:
					done += 1
					sum += 1.0
				ResourceLoader.THREAD_LOAD_IN_PROGRESS:
					sum += float(progress[0]) if progress.size() > 0 else 0.0
				_:
					return path
		_advance("resources", sum / float(REQUIRED.size()))
		if done == REQUIRED.size():
			break
		if debug_slow > 0.0:
			await get_tree().create_timer(debug_slow / 4.0).timeout
		else:
			await get_tree().process_frame
		if not _alive(tok):
			return ""
	for path: String in REQUIRED:
		var res := ResourceLoader.load_threaded_get(path)
		if res == null:
			return path
		_held.append(res)
	return ""


func _discard_gameplay() -> void:
	if is_instance_valid(gameplay):
		gameplay.queue_free()
	gameplay = null
	_held.clear()


# ---------------------------------------------------------------- bàn giao

## Gọi đúng một lần sau khi loading đã vẽ 100%: mở khóa gameplay rồi đổi current_scene.
func handoff() -> bool:
	if _handed_off or not is_instance_valid(gameplay):
		return false
	_handed_off = true
	_gs().activate()
	get_tree().current_scene = gameplay
	gameplay.call("activate")
	return true
