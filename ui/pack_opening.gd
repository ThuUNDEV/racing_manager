extends VBoxContainer
## Presentation only: rewards have already been saved before this node is shown.
signal finished

const PopupAnim = preload("res://ui/popup_anim.gd")
const DURATION := 1.65
var motion_enabled := PopupAnim.motion_on()
var completed := false
var elapsed := 0.0
var art: PackArt

class PackArt extends Control:
	var texture: Texture2D
	var elapsed := 0.0
	var accent := Color("ffcd58")

	func _draw() -> void:
		var center := size * Vector2(0.5, 0.54)
		var burst := clampf((elapsed - 0.85) / 0.5, 0.0, 1.0)
		var fade := 1.0 - clampf((elapsed - 1.28) / 0.37, 0.0, 1.0)
		for i in 12:
			var angle := TAU * float(i) / 12.0 + elapsed * 0.18
			var direction := Vector2.from_angle(angle)
			var side := direction.orthogonal() * (4.0 + burst * 5.0)
			var near := center + direction * (24.0 + burst * 24.0)
			var far := center + direction * (62.0 + burst * 42.0)
			draw_colored_polygon(PackedVector2Array([near - side, far, near + side]), Color(accent, (0.12 + burst * 0.45) * fade))
		var enter := clampf(elapsed / 0.3, 0.0, 1.0)
		var shake := sin(elapsed * 56.0) * 0.075 if elapsed > 0.35 and elapsed < 0.95 else 0.0
		var pop := sin(clampf((elapsed - 0.95) / 0.35, 0.0, 1.0) * PI) * 0.18
		var shrink := clampf((elapsed - 1.22) / 0.35, 0.0, 1.0)
		var extent := Vector2(174, 174)
		if texture != null:
			var ratio := texture.get_size()
			extent *= ratio / maxf(ratio.x, ratio.y)
			draw_set_transform(center + Vector2(0, (1.0 - enter) * 32.0 - burst * 15.0), shake, Vector2.ONE * (0.65 + enter * 0.35 + pop - shrink * 0.45))
			draw_texture_rect(texture, Rect2(-extent * 0.5, extent), false, Color(1, 1, 1, enter * (1.0 - shrink)))
			draw_set_transform(Vector2.ZERO)
		for i in 10:
			var angle := TAU * float(i) / 10.0
			var point := center + Vector2.from_angle(angle) * (32.0 + burst * 85.0)
			draw_circle(point, 2.0 + burst, Color(accent, burst * fade))


func setup(texture: Texture2D, caption: String, elite: bool) -> void:
	name = "PackOpening"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = caption
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	art = PackArt.new()
	art.texture = texture
	art.accent = Color("c89aff") if elite else Color("ffcd58")
	art.custom_minimum_size.y = 220
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var skip := Button.new()
	skip.name = "SkipOpening"
	skip.text = I18n.t("tutorial.skip")
	skip.custom_minimum_size.y = 44
	HdUi.style_button(skip, "cancel")
	skip.pressed.connect(finish)
	add_child(skip)


func _ready() -> void:
	if not motion_enabled:
		finish.call_deferred()


func _process(delta: float) -> void:
	if completed or not motion_enabled:
		return
	elapsed += delta
	art.elapsed = elapsed
	art.queue_redraw()
	if elapsed >= DURATION:
		finish()


func finish() -> void:
	if completed or not is_inside_tree():
		return
	completed = true
	set_process(false)
	hide()
	finished.emit()
