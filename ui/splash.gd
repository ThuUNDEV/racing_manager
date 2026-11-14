extends Control
## Splash có hoạt ảnh chạy trước loading; boot splash native chỉ giữ nền đen.

const FADE_IN := 0.6
const HOLD := 0.5
const FADE_OUT := 0.6
const LOADING := "res://scenes/loading.tscn"

var _logo: TextureRect
var _animation: Tween


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_logo = TextureRect.new()
	_logo.texture = preload("res://assets/branding/racing_tycoon_splash_black.png")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_logo.modulate.a = 0.0
	add_child(_logo)
	_animation = create_tween()
	_animation.tween_property(_logo, "modulate:a", 1.0, FADE_IN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_animation.tween_interval(HOLD)
	_animation.tween_property(_logo, "modulate:a", 0.0, FADE_OUT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _animation.finished
	# Giữ một khung nền đen trước khi loading dựng UI.
	await get_tree().process_frame
	var error := get_tree().change_scene_to_file(LOADING)
	if error != OK:
		push_error("Could not open the loading screen: %s" % error_string(error))


func _notification(what: int) -> void:
	if _animation == null:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_animation.pause()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_animation.play()
