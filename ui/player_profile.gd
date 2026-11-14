extends Control
const CleanArt = preload("res://ui/clean_modern_art.gd")
const PopupAnim = preload("res://ui/popup_anim.gd")
## Centered player-profile popup. Racing continues behind the dimmed backdrop.
signal closed

const INK := Color("23394a")
const MUTED := Color("768ca0")
const TouchScroll = preload("res://ui/touch_scroll.gd")
var _name: Label
var _league: Label
var _races: Label
var _race_caption: Label
var _seasons: Label
var _collection: VBoxContainer
var _lineup: HBoxContainer
var _storage: Label
var _edit: Button
var _dialog: Control
var _dialog_panel: PanelContainer
var _name_input: LineEdit
var _error: Label
var _rename_cost: Label
var _rename_save: Button
var _scroll: ScrollContainer
var _popup: PanelContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.12, 0.25, 0.65)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_popup = PanelContainer.new()
	_popup.name = "ProfilePopup"
	_popup.clip_contents = true
	var popup_skin := StyleBoxFlat.new()
	popup_skin.bg_color = Color("e7f0ff")
	popup_skin.set_corner_radius_all(20)
	popup_skin.shadow_color = Color(0, 0, 0, 0.25)
	popup_skin.shadow_size = 12
	_popup.add_theme_stylebox_override("panel", popup_skin)
	add_child(_popup)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	_popup.add_child(root)
	var header := _panel(root, Color("174c8c"), 0, 14)
	var header_skin := header.get_theme_stylebox("panel") as StyleBoxFlat
	header_skin.corner_radius_top_left = 20
	header_skin.corner_radius_top_right = 20
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	header.add_child(row)
	var title := _label(I18n.t("common.player_profile"), 20, Color.WHITE, true)
	title.name = "ProfileTitle"
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(title)
	var close := HdUi.close_button(_close, "ProfileBack")
	close.accessibility_name = I18n.t("profile.close_profile")
	row.add_child(close)
	_scroll = TouchScroll.new()
	_scroll.name = "ProfileScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	_scroll.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var identity := _panel(content, Color("1b5baa"), 20, 18)
	var id_box := VBoxContainer.new()
	id_box.add_theme_constant_override("separation", 14)
	identity.add_child(id_box)
	var id_row := HBoxContainer.new()
	id_row.add_theme_constant_override("separation", 14)
	id_box.add_child(id_row)
	var avatar_frame := _panel(id_row, Color("dbeeff"), 18, 3)
	avatar_frame.size_flags_horizontal = SIZE_SHRINK_BEGIN
	avatar_frame.size_flags_vertical = SIZE_SHRINK_CENTER
	avatar_frame.add_child(HdUi.icon("icons/avatar.png", Vector2(72, 72)))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	id_row.add_child(info)
	info.add_child(_label("WORKSHOP GP", 11, Color("d2e6ff")))
	_name = _label("", 23, Color.WHITE, true)
	_name.name = "ProfileTeamName"
	info.add_child(_name)
	_league = _label("", 13, Color("fff1ce"), true)
	info.add_child(_league)
	var edit_row := HBoxContainer.new()
	id_box.add_child(edit_row)
	var caption := _label(I18n.t("profile.profile"), 12, Color("e1efff"))
	caption.size_flags_horizontal = SIZE_EXPAND_FILL
	edit_row.add_child(caption)
	_edit = _button(I18n.t("profile.edit_team_name"), _show_edit)
	_edit.name = "ProfileEditName"
	edit_row.add_child(_edit)
	_heading(content, I18n.t("profile.racing_journey"), I18n.t("profile.accumulated"))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	content.add_child(stats)
	var race_data := _stat(stats, "flag")
	_races = race_data[0]
	_races.name = "ProfileCompletedRaces"
	_race_caption = race_data[1]
	var season_data := _stat(stats, "trophy")
	_seasons = season_data[0]
	season_data[1].text = I18n.t("profile.facilities_opened")
	_heading(content, I18n.t("profile.collection"), I18n.t("common.owned_2"))
	var collection_panel := _panel(content)
	_collection = VBoxContainer.new()
	_collection.add_theme_constant_override("separation", 14)
	collection_panel.add_child(_collection)
	_heading(content, I18n.t("profile.current_lineup"))
	_lineup = HBoxContainer.new()
	_lineup.add_theme_constant_override("separation", 10)
	content.add_child(_lineup)
	var storage_panel := _panel(content, Color("dce9fb"), 12, 12)
	_storage = _label("", 12, MUTED, true)
	_storage.name = "ProfileStorageStatus"
	storage_panel.add_child(_storage)
	var footer := _panel(root, Color("edf4ff"), 0, 16)
	var footer_skin := footer.get_theme_stylebox("panel") as StyleBoxFlat
	footer_skin.corner_radius_bottom_left = 20
	footer_skin.corner_radius_bottom_right = 20
	var done := _button(I18n.t("common.close"), _close, true, true)
	done.name = "ProfileClose"
	done.custom_minimum_size.y = 48
	footer.add_child(done)
	_build_edit_dialog()
	PopupAnim.close_on_outside_click(self, _popup, _close)
	GameState.changed.connect(_refresh_if_visible)
	visibility_changed.connect(_refresh_if_visible)
	resized.connect(_fit_popup)
	_fit_popup()
	refresh()


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


func _heading(parent: Control, title: String, detail: String = "") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label := _label(title, 17)
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(_label(detail, 12, MUTED))


func _stat(parent: Control, icon: String) -> Array:
	var panel := _panel(parent, Color("f8fbff"), 14, 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(HdUi.icon("icons/%s.png" % icon, Vector2(28, 28)))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	row.add_child(box)
	var value := _label("0", 23, INK, true)
	box.add_child(value)
	var caption := _label("", 12, MUTED, true)
	box.add_child(caption)
	return [value, caption]


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _collect(icon: String, title: String, catalog: Array, owned: Variant) -> void:
	var count := 0
	for item: Dictionary in catalog:
		if item["id"] in owned:
			count += 1
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_collection.add_child(row)
	row.add_child(HdUi.icon("icons/%s.png" % icon, Vector2(40, 40)))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(box)
	var labels := HBoxContainer.new()
	box.add_child(labels)
	var label := _label(title, 13)
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	labels.add_child(label)
	labels.add_child(_label("%d / %d" % [count, catalog.size()], 12, MUTED))
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 7
	bar.max_value = maxi(1, catalog.size())
	bar.value = count
	bar.show_percentage = false
	for key in ["background", "fill"]:
		var skin := StyleBoxFlat.new()
		skin.bg_color = Color("dce7f7") if key == "background" else Color("377bd8")
		skin.set_corner_radius_all(4)
		bar.add_theme_stylebox_override(key, skin)
	box.add_child(bar)


func _member(title: String, data: Dictionary, texture: Texture2D) -> void:
	var panel := _panel(_lineup, Color("f8fbff"), 14, 10)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var caption := _label(title, 12, MUTED)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(caption)
	var image := TextureRect.new()
	image.texture = texture if texture != null else HdUi.tex("icons/staff.png" if title == I18n.t("common.drivers") else "icons/car_red.png")
	image.custom_minimum_size = Vector2(0, 64)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(image)
	var label := _label(String(data.get("name", I18n.t("profile.not_selected"))), 14, INK, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)


func refresh() -> void:
	_name.text = GameState.player_team_name
	_league.text = "◆ " + String(GameData.league(GameState.business_tier).get("name", ""))
	_races.text = str(GameState.completed_races)
	_race_caption.text = I18n.t("profile.races_completed") if GameState.race_history_complete else I18n.t("profile.races_since_update")
	_seasons.text = str(GameState.business_tier)
	_clear(_collection)
	_collect("car_red", I18n.t("profile.race_car"), GameData.cars(), GameState.owned_cars)
	_collect("staff", I18n.t("common.drivers"), GameData.drivers(), GameState.owned_drivers)
	_collect("tools", I18n.t("common.gear"), GameData.gear_items(), GameState.gear_owned)
	_clear(_lineup)
	var driver_id: String = GameState.active_driver_id
	var portrait := ExpansionArt.texture(driver_id)
	var path := "res://assets/workshop_gp/portraits/%s.tres" % driver_id
	if portrait == null and ResourceLoader.exists(path):
		portrait = CleanArt.asset(path) as Texture2D
	_member(I18n.t("common.drivers"), GameData.driver(driver_id), portrait)
	_member(I18n.t("profile.race_car"), GameData.car(GameState.active_car_id), ExpansionArt.texture(ExpansionArt.car_id(GameState.active_car_id)))
	var error := GameState.save_blocked or GameState.phase == "save_error" or GameState.simulate_write_failure
	_storage.text = I18n.t("profile.could_not_save_data_return") if error else I18n.t("profile.data_this_device_account_sync")
	_storage.add_theme_color_override("font_color", HdUi.C_RED if error else MUTED)


func _refresh_if_visible() -> void:
	if is_visible_in_tree():
		refresh()


func open() -> void:
	PopupAnim.open(self, _popup)
	_fit_popup()
	refresh()
	_scroll.scroll_vertical = 0
	_edit.grab_focus()


func _fit_popup() -> void:
	if not is_instance_valid(_popup):
		return
	_popup.size = Vector2(minf(390, maxf(0, size.x - 32)), minf(720, maxf(0, size.y - 64)))
	_popup.position = (size - _popup.size) * 0.5


func _close() -> void:
	_dialog.hide()
	PopupAnim.close(self, _popup, closed.emit)


func _build_edit_dialog() -> void:
	_dialog = Control.new()
	_dialog.name = "ProfileNameDialog"
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dialog)
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
	_dialog.visibility_changed.connect(func() -> void:
		if not _dialog.visible and visible:
			_edit.grab_focus())
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
	refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _dialog.visible:
			_hide_dialog()
		else:
			_close()
		get_viewport().set_input_as_handled()
