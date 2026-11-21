extends Control
## Shared team-name editor for the profile and Classes popups.
signal saved
const PopupAnim = preload("res://ui/popup_anim.gd")
const INK := Color("0e2b5c")
const MUTED := Color("788b95")
var _dialog: Control
var _dialog_panel: PanelContainer
var _name_input: LineEdit
var _error: Label
var _rename_cost: Label
var _rename_save: Button


func _ready() -> void:
	_dialog = self
	name = "ProfileNameDialog"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.12, 0.25, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.add_child(center)
	_dialog_panel = _panel(center, Color("f3f7ff"), 20, 20)
	PopupAnim.close_on_outside_click(_dialog, _dialog_panel, _hide_dialog)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_dialog_panel.add_child(box)
	box.add_child(HdUi.close_header(I18n.t("profile.team_name_2"), _hide_dialog, 20))
	box.add_child(_label(I18n.t("profile.pick_name_identify_racing_team"), 14, MUTED, true))
	box.add_child(_label(I18n.t("profile.team_name_up_24_characters"), 13, INK, true))
	_name_input = LineEdit.new()
	_name_input.name = "ProfileNameInput"
	_name_input.custom_minimum_size.y = 48
	_name_input.accessibility_name = I18n.t("profile.team_name")
	_name_input.add_theme_color_override("font_color", INK)
	_name_input.add_theme_color_override("font_selected_color", Color.WHITE)
	_name_input.add_theme_color_override("selection_color", Color("2462ca"))
	_name_input.add_theme_color_override("caret_color", INK)
	for state in ["normal", "read_only"]:
		var skin := StyleBoxFlat.new()
		skin.bg_color = Color.WHITE
		skin.border_color = Color("94add0")
		skin.set_border_width_all(1)
		skin.set_corner_radius_all(10)
		skin.set_content_margin_all(10)
		_name_input.add_theme_stylebox_override(state, skin)
	box.add_child(_name_input)
	_rename_cost = _label("", 13, MUTED, true)
	_rename_cost.name = "ProfileRenameCost"
	box.add_child(_rename_cost)
	_error = _label("", 13, HdUi.C_RED, true)
	_error.name = "ProfileNameError"
	box.add_child(_error)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	var cancel := _button(I18n.t("common.cancel"), _hide_dialog)
	cancel.size_flags_horizontal = SIZE_EXPAND_FILL
	actions.add_child(cancel)
	var save := _button(I18n.t("profile.save_name"), _save_name, true, true)
	_rename_save = save
	save.size_flags_horizontal = SIZE_EXPAND_FILL
	actions.add_child(save)
	_name_input.focus_next = _name_input.get_path_to(cancel)
	cancel.focus_next = cancel.get_path_to(save)
	save.focus_next = save.get_path_to(_name_input)
	_name_input.focus_previous = _name_input.get_path_to(save)
	save.focus_previous = save.get_path_to(cancel)
	cancel.focus_previous = cancel.get_path_to(_name_input)
	_name_input.text_submitted.connect(func(_value: String) -> void: _save_name())
	_name_input.text_changed.connect(func(_value: String) -> void: _update_rename_cost())
	resized.connect(_fit_dialog)
	_dialog.hide()


func _hide_dialog() -> void:
	PopupAnim.close(_dialog, _dialog_panel)


func _fit_dialog() -> void:
	_dialog_panel.custom_minimum_size.x = minf(340, maxf(260, size.x - 32))


func _show_edit() -> void:
	_name_input.text = GameState.player_team_name
	_error.text = ""
	_update_rename_cost()
	_fit_dialog()
	PopupAnim.open(_dialog, _dialog_panel)
	_name_input.grab_focus()
	_name_input.select_all()


func _update_rename_cost() -> void:
	var cost := GameState.team_name_change_cost()
	_rename_cost.text = (I18n.t("profile.first_rename_free_after_that") if cost == 0 else I18n.t("profile.rename_fee_gems_you_have") % [cost, GameState.gems])
	var unchanged := _name_input.text.strip_edges() == GameState.player_team_name
	_rename_save.text = I18n.t("profile.save_name") if unchanged else I18n.t("profile.free") if cost == 0 else I18n.t("profile.rename_gems") % cost


func _save_name() -> void:
	var clean := _name_input.text.strip_edges()
	if not GameState.valid_team_name(clean):
		_error.text = I18n.t("profile.enter_name_1_24_characters")
		return
	if clean != GameState.player_team_name and GameState.gems < GameState.team_name_change_cost():
		_update_rename_cost()
		_error.text = I18n.t("profile.not_enough_gems_you_need") % GameState.team_name_change_cost()
		return
	if not GameState.set_player_team_name(clean):
		_error.text = I18n.t("profile.could_not_save_name_please")
		return
	_hide_dialog()
	saved.emit()


func _panel(parent: Control, color: Color = Color("f8fbff"), radius: int = 14, pad: int = 14) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var skin := StyleBoxFlat.new()
	skin.bg_color = color
	skin.set_corner_radius_all(radius)
	skin.set_content_margin_all(pad)
	if radius > 0:
		skin.border_color = Color("bed1eb") if color == Color("f8fbff") else color
		skin.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", skin)
	parent.add_child(panel)
	return panel


func _label(text: String, font_size: int = 14, color: Color = INK, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = MOUSE_FILTER_IGNORE
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = SIZE_EXPAND_FILL
	return label


func _button(text: String, action: Callable, light: bool = true, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(44, 44)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", INK if light and not primary else Color.WHITE)
	button.add_theme_color_override("font_hover_color", INK if light and not primary else Color.WHITE)
	button.add_theme_color_override("font_pressed_color", INK if light and not primary else Color.WHITE)
	button.add_theme_color_override("font_focus_color", INK if light and not primary else Color.WHITE)
	button.add_theme_color_override("font_hover_pressed_color", INK if light and not primary else Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	HdUi.text_depth(button, not light or primary)
	for state in ["normal", "hover", "pressed"]:
		var skin := StyleBoxFlat.new()
		skin.bg_color = Color("d66a00") if primary else Color.WHITE if light else Color("2362ad")
		if state == "hover":
			skin.bg_color = skin.bg_color.lightened(0.08)
		elif state == "pressed":
			skin.bg_color = skin.bg_color.darkened(0.08)
		skin.set_corner_radius_all(12)
		skin.content_margin_left = 12
		skin.content_margin_right = 12
		button.add_theme_stylebox_override(state, skin)
	HdUi.ButtonSkin.apply(button)
	button.pressed.connect(action)
	return button


func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		_hide_dialog()
		get_viewport().set_input_as_handled()
