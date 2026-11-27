extends HBoxContainer
## Dải 1 · 2 · 3 trong popup gói Tân binh (Design/28 §4.3): vị trí trong chuỗi và chuyển giữa các gói đang mua được.
## Chỉ vẽ; nơi dùng quyết định gói nào mua được.

signal picked(sku: String)

const ButtonSkin = preload("res://ui/button_skin.gd")
const PackUi = preload("res://ui/shop_pack_ui.gd")
const INK := Color("0e2b5c")
const CHAIN := ["starter_1", "starter_2", "starter_3"]


func setup(current: String, open_skus: Array) -> void:
	name = "StarterSteps"
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)
	for index in CHAIN.size():
		var sku: String = CHAIN[index]
		if index > 0:
			var dot := PackUi.label("·", 22, INK)
			dot.autowrap_mode = TextServer.AUTOWRAP_OFF
			dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			add_child(dot)
		var step := Button.new()
		step.name = "Step_" + sku
		step.text = str(index + 1)
		step.accessibility_name = PackUi.title(GameData.iap_product(sku))
		step.custom_minimum_size = Vector2(64, 44)
		var selected := sku == current
		step.disabled = not selected and not sku in open_skus
		_style(step, selected)
		if not selected:
			step.pressed.connect(func() -> void: picked.emit(sku))
		add_child(step)


func _style(step: Button, selected: bool) -> void:
	var face := ButtonSkin.palette(Color("ffb43c"), Color("ff8a1f"), Color("c4520e")) if selected \
		else ButtonSkin.palette(Color("fff9ee"), Color("fbeedb"), Color("c79f68"))
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		step.add_theme_stylebox_override(state, face)
	step.add_theme_stylebox_override("disabled", ButtonSkin.palette(Color("e8e1d5"), Color("ddd4c6"), Color("c4b9a6")))
	step.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	step.add_theme_font_override("font", HdUi.font())
	step.add_theme_font_size_override("font_size", 20)
	var ink := Color.WHITE if selected else INK
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		step.add_theme_color_override(state, ink)
	step.add_theme_color_override("font_disabled_color", Color("9a907f"))
	step.mouse_default_cursor_shape = Control.CURSOR_ARROW if step.disabled else Control.CURSOR_POINTING_HAND
