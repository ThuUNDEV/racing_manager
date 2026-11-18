extends Node
## Removes every hover effect: a hovered button looks exactly like its normal (or pressed) state.
## Buttons are skinned in many places and restyled on resize, so this re-syncs on each draw.

const COLOR_PAIRS := {
	"font_hover_color": "font_color",
	"font_hover_pressed_color": "font_pressed_color",
}


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta("no_hover"):
		node.set_meta("no_hover", true)
		node.draw.connect(_sync.bind(node))


func _sync(button: BaseButton) -> void:
	if button is TextureButton:
		button.texture_hover = null
		return
	if not button is Button:
		return
	_copy_style(button, "hover", "normal")
	_copy_style(button, "hover_pressed", "pressed")
	for hover_color: String in COLOR_PAIRS:
		var base: Color = button.get_theme_color(COLOR_PAIRS[hover_color])
		if not button.has_theme_color_override(hover_color) or button.get_theme_color(hover_color) != base:
			button.add_theme_color_override(hover_color, base)


func _copy_style(button: Button, target: String, source: String) -> void:
	var style := button.get_theme_stylebox(source)
	if not button.has_theme_stylebox_override(target) or button.get_theme_stylebox(target) != style:
		button.add_theme_stylebox_override(target, style)
