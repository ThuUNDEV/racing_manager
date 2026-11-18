@tool
extends PanelContainer

@export var icon: Texture2D: set = _set_icon
@export var value_text: String = "": set = _set_value


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	%Icon.texture = icon
	%Value.text = value_text


func _set_icon(v: Texture2D) -> void:
	icon = v
	_apply()


func _set_value(v: String) -> void:
	value_text = v
	_apply()
