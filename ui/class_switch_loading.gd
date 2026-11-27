extends CanvasLayer
## Màn loading khi đổi class: che toàn màn hình, đổi class và dựng lại map phía sau, rồi mờ dần để lộ map mới.
## Không chứa logic kinh tế: việc đổi class do `work` (trả về true nếu thành công) thực hiện.
signal finished(ok: bool)

const ART := "res://assets/startup_loading/loading_race_flare_v1.png"
const C_BG := Color("fff3e2")
const C_TEXT := Color("173f60")
const LoadingProgress = preload("res://ui/loading_progress.gd")
const CleanArt = preload("res://ui/clean_modern_art.gd")
const PRE_FRAMES := 3
const SETTLE_FRAMES := 10
const FILL_TIME := 1.1
const HOLD_100 := 0.15
const FADE_TIME := 0.25

var note: String = ""
var _class_name := ""
var _work: Callable
var _screen: Control
var _status: Label
var _percent: Label
var _bar: ProgressBar


func setup(class_name_text: String, work: Callable) -> void:
	_class_name = class_name_text
	_work = work


func _ready() -> void:
	layer = 100
	_build_ui()
	_run()


func _build_ui() -> void:
	_screen = Control.new()
	_screen.name = "ClassSwitchLoading"
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen.theme = HdUi.theme()
	add_child(_screen)
	var fill := ColorRect.new()
	fill.color = C_BG
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(fill)
	if ResourceLoader.exists(ART):
		var bg := TextureRect.new()
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.texture = CleanArt.asset(ART) as Texture2D
		_screen.add_child(bg)
	var box := VBoxContainer.new()
	box.name = "ClassSwitchProgress"
	box.add_theme_constant_override("separation", 8)
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.anchor_top = 0.8
	box.anchor_bottom = 0.95
	box.offset_left = 32.0
	box.offset_right = -32.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(box)
	var title := _label(I18n.t("class.switching_title") % _class_name, 20)
	title.name = "ClassSwitchTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_bar = LoadingProgress.new()
	_bar.custom_minimum_size = Vector2(0, 32)
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.step = 0.0001
	_bar.show_percentage = false
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_bar)
	var row := HBoxContainer.new()
	box.add_child(row)
	_status = _label(I18n.t("boot.loading_race_track"), 14)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_status)
	_percent = _label("0%", 18)
	_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_percent)


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", C_TEXT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _set_progress(value: float) -> void:
	_bar.value = value
	_percent.text = "%d%%" % int(round(value * 100.0))


func _run() -> void:
	var fill := create_tween()
	fill.tween_method(_set_progress, 0.0, 0.9, FILL_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for i in PRE_FRAMES:
		await get_tree().process_frame
	var ok: bool = _work.call()
	if note != "":
		_status.text = note
	for i in SETTLE_FRAMES:
		await get_tree().process_frame
	if fill.is_running():
		await fill.finished
	_status.text = note if note != "" else I18n.t("boot.finishing_up")
	var last := create_tween()
	last.tween_method(_set_progress, 0.9, 1.0, 0.2)
	await last.finished
	await get_tree().create_timer(HOLD_100).timeout
	var fade := create_tween()
	fade.tween_property(_screen, "modulate:a", 0.0, FADE_TIME)
	await fade.finished
	finished.emit(ok)
	queue_free()
