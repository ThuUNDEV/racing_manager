extends Button
## The face follows the reference rectangle; its invisible hit target stays 44px
## and is clamped inside the card. No scaling transform or extra layout minimum.
var face := Button.new()
var _face_styles: Dictionary = {}

func _init() -> void:
	clip_text = true
	self_modulate.a = 0.0
	set_meta("ub_floor", Vector2(44, 44))
	set_meta("reference_face", true)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.focus_mode = Control.FOCUS_NONE
	face.clip_text = true
	add_child(face)

func _process(_delta: float) -> void:
	if not has_meta("ub_rect"):
		return
	var u := preload("res://ui/unit_scale.gd").unit_of(self)
	var design: Array = get_meta("ub_rect")
	var at := Rect2((design[0] as Vector2) * u, (design[1] as Vector2) * u)
	var hit_size := at.size.max(Vector2(44, 44))
	var hit_at := at.get_center() - hit_size * 0.5
	var bounds := (get_parent() as Control).size
	hit_at = hit_at.clamp(Vector2.ZERO, (bounds - hit_size).max(Vector2.ZERO))
	position = hit_at
	size = hit_size
	face.text = text.trim_prefix("▶ ") if icon != null else text
	face.icon = icon
	face.expand_icon = expand_icon
	face.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	face.alignment = HORIZONTAL_ALIGNMENT_CENTER
	face.disabled = disabled
	face.set_pressed_no_signal(button_pressed)
	for key in ["font_size"]:
		face.add_theme_font_size_override(key, get_theme_font_size(key))
	face.add_theme_font_override("font", get_theme_font("font"))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_outline_color"]:
		face.add_theme_color_override(key, get_theme_color(key))
	for key in ["outline_size", "icon_max_width", "h_separation"]:
		face.add_theme_constant_override(key, roundi(get_theme_constant(key) * u) if key in ["icon_max_width", "h_separation"] else get_theme_constant(key))
	for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		face.add_theme_stylebox_override(state, _face_style(state, at.size))
	if icon != null:
		for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			var style := face.get_theme_stylebox(state)
			var text_width := face.get_theme_font("font").get_string_size(face.text, HORIZONTAL_ALIGNMENT_LEFT, -1, face.get_theme_font_size("font_size")).x
			var content_width := text_width + face.get_theme_constant("icon_max_width") + face.get_theme_constant("h_separation")
			var inset := maxf(3 * u, (at.size.x - content_width) * 0.5)
			style.content_margin_left = inset
			style.content_margin_right = inset
	face.position = at.position - hit_at
	face.size = at.size

## Cache each resized raster face; reference cards update their text every frame.
func _face_style(state: String, extent: Vector2) -> StyleBox:
	var source := get_theme_stylebox(state)
	if not source.has_meta("soft_skin"):
		return source
	var cached: Dictionary = _face_styles.get(state, {})
	if int(cached.get("source", 0)) != source.get_instance_id() or cached.get("extent", Vector2.ZERO) != extent:
		_face_styles[state] = {"source": source.get_instance_id(), "extent": extent,
			"skin": preload("res://ui/soft_miniature.gd").fit_button(source as StyleBoxTexture, extent)}
	return _face_styles[state]["skin"] as StyleBox
