@tool
extends PanelContainer

@export var title: String = "": set = _set_title
@export var icon: Texture2D: set = _set_icon


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	%Title.text = title
	%Icon.texture = icon


func _set_title(v: String) -> void:
	title = v
	_apply()


func _set_icon(v: Texture2D) -> void:
	icon = v
	_apply()
