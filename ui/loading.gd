extends Node
## Màn loading khởi động UI-25 (Design/09). Chỉ hiển thị %, trạng thái và lỗi; không xử lý kinh tế.
## Điều phối nằm ở BootFlow. Gameplay được dựng phía sau lớp che này (CanvasLayer cao), sau khi thanh đạt
## 100% và đã vẽ ít nhất một khung hình, loading bàn giao, mờ dần rồi tự giải phóng.

const ART := "res://assets/startup_loading/"
const BG_FILE := "loading_pitlane_cyan.png"  # art đã gồm logo, không chứa UI tiến độ
const GAME_TITLE := "RACING TYCOON"
const C_BG := Color("061b51")
const C_TEXT := Color.WHITE
const C_MUTED := Color("b8c9e8")
const C_ACCENT := Color("79f6ff")
const LoadingProgress = preload("res://ui/loading_progress.gd")
const C_TRACK := Color("0f2a52")
const C_RED := HdUi.C_RED

const SLOW_NOTE := "Lần khởi động này đang mất nhiều thời gian hơn…"
const HOLD_100 := 0.15  # giữ khung 100% trước khi chuyển cảnh
const FADE_TIME := 0.2
const SLOW_AFTER := 10.0
const RETRY_AFTER := 30.0
const SMOOTH_TIME := 0.18  # nội suy hiển thị, không vượt target

var _boot: BootFlow
var _layer: CanvasLayer
var _screen: Control
var _safe: Control
var _bg: TextureRect
var _status: Label
var _percent: Label
var _bar: ProgressBar
var _slow_note: Label
var _progress_box: VBoxContainer
var _error_box: VBoxContainer
var _error_panel: Control
var _err_title: Label
var _err_msg: Label
var _err_code: Label
var _stall_retry: Button

var _shown: float = 0.0
var _target: float = 0.0
var _stall: float = 0.0
var _foreground: bool = true
var _failed: bool = false
var _finishing: bool = false
var _reduce_motion: bool = false  # chưa có hệ thống cài đặt: mặc định tắt, bật bằng --reduce-motion
var _shot_prefix: String = ""
var _shot_marks: Array = [0.3, 0.6, 0.99]
var _shot_count: int = 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--reduce-motion":
			_reduce_motion = true
		elif a.begins_with("--boot-shot="):
			_shot_prefix = a.substr(12)
	_build_ui()
	get_viewport().size_changed.connect(_on_viewport_resized)

	_boot = BootFlow.new()
	add_child(_boot)
	_boot.attempt_started.connect(_on_attempt_started)
	_boot.progressed.connect(_on_progress)
	_boot.status_changed.connect(_on_status)
	_boot.failed.connect(_on_failed)
	_boot.ready_for_handoff.connect(_on_ready)
	# Vẽ tối thiểu hai khung hình trước khi làm việc nặng đầu tiên.
	await get_tree().process_frame
	await get_tree().process_frame
	_boot.start()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_foreground = false  # dừng hiệu ứng và bộ đếm tải lâu; tác vụ vẫn được hoàn tất
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_foreground = true


# ---------------------------------------------------------------- dựng UI

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_screen = Control.new()
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP  # chặn chạm xuyên xuống gameplay
	_screen.theme = HdUi.theme()
	_layer.add_child(_screen)

	var fill := ColorRect.new()
	fill.color = C_BG
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(fill)

	# Thiếu art trang trí thì bỏ qua, màn vẫn đủ trạng thái và tiến độ (§5). Ảnh dọc phủ kín, cắt bớt khi tỉ lệ khác.
	_bg = TextureRect.new()
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.texture = _art(BG_FILE)
	_screen.add_child(_bg)

	_safe = Control.new()
	_safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_safe)
	_apply_safe_area()

	if _bg.texture == null:
		_build_header()  # nhận diện dự phòng khi thiếu art
	_build_progress()
	_build_error()
	_build_footer()


func _art(file: String) -> Texture2D:
	var path := ART + file
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


## Đặt `c` vào dải [top, bottom] (tỉ lệ chiều cao vùng an toàn) với lề ngang tối thiểu 24.
func _band(c: Control, top: float, bottom: float) -> void:
	c.anchor_left = 0.0
	c.anchor_right = 1.0
	c.anchor_top = top
	c.anchor_bottom = bottom
	c.offset_left = 24.0
	c.offset_right = -24.0
	c.offset_top = 0.0
	c.offset_bottom = 0.0
	_safe.add_child(c)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Chữ trắng đậm có viền xanh đậm, đọc được trên ảnh nền.
func _label_outlined(text: String, size: int, outline: int) -> Label:
	var l := _label(text, size, Color.WHITE)
	l.add_theme_color_override("font_outline_color", HdUi.C_OUTLINE)
	l.add_theme_constant_override("outline_size", outline)
	return l


func _build_header() -> void:
	var title := _label_outlined(GAME_TITLE, 34, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_band(title, 0.10, 0.24)


func _build_progress() -> void:
	# UI thật đặt trên vùng navy của art, không dùng panel hoặc mẹo.
	_progress_box = VBoxContainer.new()
	_progress_box.add_theme_constant_override("separation", 10)
	_band(_progress_box, 0.835, 0.95)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_progress_box.add_child(row)
	_status = _label("", 16, C_TEXT)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_status)
	_percent = _label("0%", 20, C_TEXT)
	_percent.custom_minimum_size = Vector2(48, 0)
	_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_percent)

	_bar = LoadingProgress.new()
	_bar.custom_minimum_size = Vector2(0, 26)
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.step = 0.0001
	_bar.show_percentage = false
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_box.add_child(_bar)

	_slow_note = _label(SLOW_NOTE, 12, C_MUTED)
	_slow_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_slow_note.hide()
	_progress_box.add_child(_slow_note)
	_stall_retry = _retry_button()
	_stall_retry.hide()
	_progress_box.add_child(_stall_retry)


func _build_error() -> void:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band(pc, 0.68, 0.95)
	var panel := _pill(Color("091f50"), Color("5475a3"), 1)
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 12
	panel.content_margin_bottom = 12
	pc.add_theme_stylebox_override("panel", panel)
	_error_box = VBoxContainer.new()
	_error_box.add_theme_constant_override("separation", 8)
	pc.add_child(_error_box)
	pc.hide()
	_error_panel = pc
	_err_title = _label("Chưa thể vào game", 20, C_RED)
	_error_box.add_child(_err_title)
	_err_msg = _label("", 14, C_TEXT)
	_err_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_err_msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_error_box.add_child(_err_msg)
	_err_code = _label("", 12, C_MUTED)
	_error_box.add_child(_err_code)
	_error_box.add_child(_retry_button())


func _build_footer() -> void:
	var row := HBoxContainer.new()
	_band(row, 0.955, 0.985)
	var ver := String(ProjectSettings.get_setting("application/config/version", ""))
	var v := _label_outlined("v" + ver if ver != "" else "", 13, 5)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_theme_color_override("font_color", Color("819dcf"))
	row.add_child(v)


func _pill(color: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(10)
	sb.border_color = border
	sb.set_border_width_all(bw)
	return sb


func _retry_button() -> Button:
	var b := Button.new()
	b.text = "Thử lại"
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 16)
	HdUi.style_button(b, "race")
	b.pressed.connect(_on_retry)
	return b


# ---------------------------------------------------------------- bố cục

func _safe_insets() -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var sa := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	if sa.size.x <= 0 or win.x <= 0:
		return Vector4.ZERO
	var k := get_viewport().get_visible_rect().size.x / float(win.x)
	return Vector4(
		maxf(0.0, sa.position.x) * k, maxf(0.0, sa.position.y) * k,
		maxf(0.0, win.x - sa.end.x) * k, maxf(0.0, win.y - sa.end.y) * k)


func _apply_safe_area() -> void:
	var s := _safe_insets()
	_safe.offset_left = s.x
	_safe.offset_top = s.y
	_safe.offset_right = -s.z
	_safe.offset_bottom = -s.w


func _on_viewport_resized() -> void:
	_apply_safe_area()


# ---------------------------------------------------------------- tiến độ

func _on_attempt_started() -> void:
	_shown = 0.0
	_target = 0.0
	_stall = 0.0
	_failed = false
	_finishing = false
	_progress_box.show()
	_error_panel.hide()
	_stall_retry.hide()
	_slow_note.hide()
	_update_bar()


func _on_status(text: String) -> void:
	if not _finishing:
		_status.text = text


func _on_progress(target: float) -> void:
	if target > _target or target == 0.0:
		_stall = 0.0
		_slow_note.hide()
		_stall_retry.hide()
	_target = target


func _on_failed(code: String, message: String) -> void:
	_failed = true
	_progress_box.hide()
	_err_msg.text = message
	_err_code.text = "Mã hỗ trợ: " + code
	_error_panel.show()
	_shoot("error")


func _on_retry() -> void:
	_boot.start()


func _process(delta: float) -> void:
	if _foreground:
		if not _failed and not _finishing:
			_stall += delta
			if _stall >= RETRY_AFTER:
				_stall_retry.show()
			if _stall >= SLOW_AFTER:
				_slow_note.show()
	if _shown < _target:
		if _reduce_motion:
			_shown = _target
		else:
			var speed := maxf(0.6, (_target - _shown) / SMOOTH_TIME)
			_shown = minf(_target, _shown + speed * delta)
	# Chừa đủ chỗ cho thông báo tải chậm và nút thử lại trên màn nhỏ.
	_progress_box.anchor_top = 0.70 if _stall_retry.visible else (0.78 if _slow_note.visible else 0.835)
	_update_bar()
	_check_shots()


func _update_bar() -> void:
	_bar.value = _shown
	# Làm tròn xuống: 99,9% vẫn hiện 99%, chỉ đúng 1.0 mới hiện 100%.
	_percent.text = "%d%%" % int(floor(_shown * 100.0 + 0.0001))


# ---------------------------------------------------------------- bàn giao

func _on_ready() -> void:
	if _finishing:
		return
	_finishing = true
	_stall_retry.hide()
	_status.text = "Sẵn sàng!"
	_slow_note.hide()
	_target = 1.0
	while _shown < 1.0:
		await get_tree().process_frame
	_update_bar()
	await get_tree().process_frame  # khung hình 100% đã được vẽ
	await get_tree().process_frame
	_shoot("full")
	await get_tree().create_timer(HOLD_100).timeout
	while not _foreground:  # không bàn giao khi ứng dụng đang ở nền
		await get_tree().process_frame
	if not _boot.handoff():
		_finishing = false
		_on_failed("BOOT_RESOURCE", "Không dựng được màn chơi. Hãy thử lại.")
		return
	if not _reduce_motion:
		var tw := create_tween()
		tw.tween_property(_screen, "modulate:a", 0.0, FADE_TIME)
		await tw.finished
	queue_free()


# ---------------------------------------------------------------- kiểm thử qua CLI

func _check_shots() -> void:
	if _shot_prefix == "" or _shot_count >= _shot_marks.size():
		return
	if _shown >= float(_shot_marks[_shot_count]) and not _failed:
		_shot_count += 1
		_shoot("%d" % int(round(_shown * 100.0)))


func _shoot(tag: String) -> void:
	if _shot_prefix == "":
		return
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [_shot_prefix, tag])
