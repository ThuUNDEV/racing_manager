@tool
extends EditorPlugin
## Thêm mục "Save Tool..." vào menu Project > Tools để mở cửa sổ quản lý save.

const SaveToolWindow = preload("res://addons/save_tool/save_tool_window.gd")
const MENU_NAME := "Save Tool... (F10)"

var _window: Window = null


func _enter_tree() -> void:
	add_tool_menu_item(MENU_NAME, _open_window)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_NAME)
	if is_instance_valid(_window):
		_window.queue_free()
	_window = null


## Phím tắt F10: mở cửa sổ, bấm lại thì đóng.
func _shortcut_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F10 and not (key.ctrl_pressed or key.shift_pressed or key.alt_pressed or key.meta_pressed):
		get_viewport().set_input_as_handled()
		if is_instance_valid(_window) and _window.visible:
			_window.hide()
		else:
			_open_window()


func _open_window() -> void:
	# Luôn dựng cửa sổ mới để không giữ lại bản cũ bị dựng dở khi script vừa đổi.
	if is_instance_valid(_window):
		_window.queue_free()
	_window = SaveToolWindow.new()
	EditorInterface.get_base_control().add_child(_window)
	_window.refresh()
	_window.popup_centered(Vector2i(820, 620))
