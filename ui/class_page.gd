extends Control
const PopupAnim = preload("res://ui/popup_anim.gd")
const ClassSwitchLoading = preload("res://ui/class_switch_loading.gd")
## Popup Classes: cơ sở đua, quản lý và mở rộng. Đua vẫn chạy sau lớp nền tối.
signal closed
signal first_class_chosen

const INK := Color("0e2b5c")
const MUTED := Color("5f7391")
const TouchScroll = preload("res://ui/touch_scroll.gd")
const TILE := {"blue": Color("cfe3f7"), "orange": Color("ffdcae"), "red": Color("ffd0c8"),
	"purple": Color("e2d6f5"), "gold": Color("fbe9a8"), "green": Color("cdeec0")}
const EDGE := Color("d8d7ca")
const CARD_FILL := Color("f6edd9")
var _popup: PanelContainer
var _header: PanelContainer
var _list: VBoxContainer
var _scroll: ScrollContainer
var _rename_dialog: Control
var _toast: Label
var _picker: Control
var _picker_choice: String = ""
var _picker_first := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.name = "ClassBackdrop"
	dim.color = Color(0.04, 0.12, 0.25, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not is_instance_valid(_picker) and not _rename_dialog.visible:
			_close())
	add_child(dim)
	_popup = _surface(HdUi.Soft.BG, EDGE, 24, 0)
	_popup.name = "ClassPopup"
	_popup.clip_contents = true
	var skin := _popup.get_theme_stylebox("panel") as StyleBoxFlat
	skin.shadow_color = Color(0, 0, 0, 0.3)
	skin.shadow_size = 14
	add_child(_popup)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	_popup.add_child(root)
	var head := PanelContainer.new()
	_header = head
	var hs := HdUi.Soft.flat(Color("f3e6c9"), 10, 0)
	hs.corner_radius_top_left = 24
	hs.corner_radius_top_right = 24
	hs.border_width_left = 0
	hs.border_width_right = 0
	hs.border_width_top = 0
	head.add_theme_stylebox_override("panel", hs)
	root.add_child(head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	head.add_child(row)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	row.add_child(titles)
	titles.add_child(_label("Classes", 25, INK))
	titles.add_child(_label(I18n.t("class.manage_race_facilities"), 11, MUTED, true))
	row.add_child(HdUi.close_button(_close, "ClassClose"))
	_scroll = TouchScroll.new()
	_scroll.name = "ClassScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	_scroll.add_child(margin)
	_list = VBoxContainer.new()
	_list.name = "ClassList"
	_list.add_theme_constant_override("separation", 12)
	margin.add_child(_list)
	_list.minimum_size_changed.connect(func() -> void: _fit_popup.call_deferred())
	resized.connect(_fit_popup)
	_fit_popup.call_deferred()
	_toast = _label("", 14, Color.WHITE, true)
	_toast.name = "ClassToast"
	_toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_toast.offset_left = 16
	_toast.offset_right = -16
	_toast.offset_top = -64
	_toast.offset_bottom = -16
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := StyleBoxFlat.new()
	ts.bg_color = INK
	ts.set_corner_radius_all(12)
	_toast.add_theme_stylebox_override("normal", ts)
	_toast.hide()
	add_child(_toast)
	_rename_dialog = preload("res://ui/team_name_dialog.gd").new()
	add_child(_rename_dialog)
	GameState.changed.connect(func() -> void:
		if is_visible_in_tree():
			refresh())


func open() -> void:
	PopupAnim.open(self, _popup)
	refresh()
	_scroll.scroll_vertical = 0
	_fit_popup.call_deferred()


## Game mới: chỉ hiện popup chọn class đầu tiên (không hiện danh sách cơ sở), không đóng được cho tới khi chọn.
func open_first_choice() -> void:
	show()
	_popup.hide()
	_open_picker(true)


func _close() -> void:
	_rename_dialog.hide()
	_close_picker()
	PopupAnim.close(self, _popup, closed.emit)


func _fit_popup() -> void:
	if is_instance_valid(_picker):
		var picker_panel := _picker.find_child("PickerPanel", true, false) as PanelContainer
		if picker_panel != null:
			picker_panel.custom_minimum_size.x = minf(358.0, maxf(0.0, size.x - 32.0))
	if not is_instance_valid(_popup):
		return
	var width := minf(420.0, maxf(0.0, size.x - 24.0))
	# Resolve wrapped text at the new width before measuring the desired height.
	_popup.size.x = width
	var content_height := _header.get_combined_minimum_size().y + _list.get_combined_minimum_size().y + 24.0
	_popup.size = Vector2(width, minf(maxf(0.0, size.y - 48.0), minf(740.0, content_height)))
	_popup.position = (size - _popup.size) * 0.5


func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		if _rename_dialog.visible:
			_rename_dialog._hide_dialog()
		elif _picker_first:
			pass
		elif is_instance_valid(_picker):
			_close_picker()
		else:
			_close()
		get_viewport().set_input_as_handled()


func refresh() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var progress := _label(I18n.t("class.unlocked_progress") % [GameState.facilities.size(), GameState.facility_limit()], 16, INK, true)
	progress.name = "ClassProgress"
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(progress)
	if GameState.pending_class != "" and GameState.class_has(GameState.pending_class):
		_list.add_child(_pending_banner(String(GameData.race_class(GameState.pending_class)["name"])))
	for cls: Dictionary in GameData.race_classes():
		if GameState.class_has(String(cls["id"])):
			_list.add_child(_card(cls))
	_list.add_child(_facility_panel())
	_list.add_child(_coming_soon())
	if OS.is_debug_build():
		_list.add_child(_dev_panel())


func _pending_banner(class_name_text: String) -> Control:
	var banner := _surface(Color("d6ebfb"), Color("9fcdf0"), 16, 10)
	banner.name = "ClassPendingBanner"
	var text := _label(I18n.t("class.switching_banner") % class_name_text, 15, INK, true)
	text.name = "ClassPendingText"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(text)
	return banner


func _coming_soon() -> Control:
	var card := _surface(Color("efe9dc"), EDGE, 18, 12)
	card.name = "ClassComingSoon"
	card.modulate = Color(1, 1, 1, 0.8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var tile := _surface(Color("e4e0d6"), EDGE, 14, 4)
	tile.add_child(HdUi.Soft.art("nav_race", Vector2(44, 44)))
	row.add_child(tile)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	col.add_child(_label(I18n.t("class.more_soon"), 18, MUTED, true))
	col.add_child(_label(I18n.t("class.more_soon_hint"), 12, MUTED, true))
	return card


func _card(cls: Dictionary) -> Control:
	var id := String(cls["id"])
	var is_active := id == GameState.active_class
	var managed := id == GameState.managed_class
	var card := _surface(Color("fffaf0"), Color("ff9225") if managed else EDGE, 22, 14)
	card.name = "ClassCard_" + id
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	var tint: Color = TILE.get(String(cls.get("color", "blue")), TILE["blue"])
	var tile := _surface(tint, EDGE, 16, 4)
	tile.size_flags_vertical = SIZE_SHRINK_CENTER
	var art := TextureRect.new()
	art.texture = _class_texture(id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(60, 60)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(art)
	head.add_child(tile)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 4)
	head.add_child(names)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	names.add_child(name_row)
	name_row.add_child(_label(String(cls["name"]), 22, INK, true))
	names.add_child(_label(String(cls.get("blurb", "")), 12, MUTED, true))
	if is_active:
		var badge := HdUi.Soft.pill(I18n.t("class.active"), Color("d3f2c6"), 13)
		badge.size_flags_vertical = SIZE_SHRINK_CENTER
		badge.get_child(0).name = "ClassActive_" + id
		badge.get_child(0).add_theme_color_override("font_color", Color("238331"))
		head.add_child(badge)
	else:
		head.add_child(_watch_button(id))
	var line := ColorRect.new()
	line.color = EDGE
	line.custom_minimum_size.y = 1
	line.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(line)
	var team := VBoxContainer.new()
	team.add_theme_constant_override("separation", 2)
	team.add_child(_label(I18n.t("class.team_name"), 11, MUTED))
	var team_name := _label(GameState.facility_team_name(id), 20, INK, true)
	team_name.name = "ClassTeamName_" + id
	team.add_child(team_name)
	var team_row := HBoxContainer.new()
	team_row.add_theme_constant_override("separation", 8)
	team.size_flags_horizontal = SIZE_EXPAND_FILL
	team_row.add_child(team)
	var edit := Button.new()
	edit.name = "ClassEditName_" + id
	edit.text = "✎"
	edit.accessibility_name = I18n.t("profile.edit_team_name")
	edit.tooltip_text = I18n.t("profile.edit_team_name")
	edit.custom_minimum_size = Vector2(44, 44)
	edit.size_flags_vertical = SIZE_SHRINK_CENTER
	edit.add_theme_font_size_override("font_size", 22)
	HdUi.style_button(edit, "amber")
	edit.disabled = not GameState.feature_unlocked("U2_league") or not managed
	edit.pressed.connect(_rename_dialog._show_edit)
	team_row.add_child(edit)
	box.add_child(team_row)
	var metrics := _surface(CARD_FILL, CARD_FILL, 16, 10)
	box.add_child(metrics)
	var metric_row := HBoxContainer.new()
	metric_row.add_theme_constant_override("separation", 8)
	metrics.add_child(metric_row)
	metric_row.add_child(_metric("trophy_large", I18n.t("class.current_league"), String(GameData.league(GameState.facility_tier(id))["name"]), INK))
	var divider := ColorRect.new()
	divider.color = EDGE
	divider.custom_minimum_size.x = 1
	divider.mouse_filter = MOUSE_FILTER_IGNORE
	metric_row.add_child(divider)
	metric_row.add_child(_metric("currency_cash", I18n.t("class.income"), I18n.t("common.plus_sec") % Balance.fmt_rate(GameState.facility_rate(id)), Color("22852f")))
	var hint := _surface(CARD_FILL, CARD_FILL, 14, 8)
	box.add_child(hint)
	var hint_row := HBoxContainer.new()
	hint_row.add_theme_constant_override("separation", 8)
	hint.add_child(hint_row)
	hint_row.add_child(HdUi.Soft.art("engine", Vector2(34, 34)))
	var hints := VBoxContainer.new()
	hints.size_flags_horizontal = SIZE_EXPAND_FILL
	hint_row.add_child(hints)
	var variant := _variant_name(String(cls.get("recommended_variant", "")))
	if variant != "":
		hints.add_child(_label(I18n.t("class.suggested_car") + variant, 13, INK, true))
	hints.add_child(_label(String(cls.get("key_stats", "")), 12, MUTED, true))
	return card


func _watch_button(id: String) -> Button:
	var pending := id == GameState.pending_class
	var watch := Button.new()
	watch.name = "ClassWatch_" + id
	watch.text = I18n.t("class.after_this_race") if pending else I18n.t("class.watch_race")
	watch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	watch.custom_minimum_size = Vector2(98, 48)
	watch.size_flags_vertical = SIZE_SHRINK_CENTER
	watch.add_theme_font_size_override("font_size", 15)
	HdUi.style_button(watch, "claim")
	watch.pressed.connect(_on_watch.bind(id))
	return watch


func _on_watch(id: String) -> void:
	if not GameState.class_has(id):
		_say(I18n.t("class.could_not_change_class"))
		return
	var cname := String(GameData.race_class(id)["name"])
	var loader := ClassSwitchLoading.new()
	loader.setup(cname, func() -> bool:
		if not GameState.select_class(id) or not GameState.manage_class(id):
			return false
		if GameState.pending_class == id:
			loader.note = I18n.t("class.switching_after_current_race_ends") % cname
		return true)
	loader.finished.connect(func(ok: bool) -> void:
		if not ok:
			open()
			_say(I18n.t("class.could_not_change_class")))
	get_tree().root.add_child(loader)
	_close()


func _metric(icon_path: String, caption: String, value: String, color: Color) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = 1.0
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	col.add_child(row)
	row.add_child(HdUi.Soft.art(icon_path, Vector2(24, 24)))
	row.add_child(_label(caption, 9, MUTED, true))
	col.add_child(_label(value, 17, color, true))
	return col


func _surface(fill: Color, border: Color, radius: int, padding: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := HdUi.Soft.flat(fill, padding, radius)
	style.border_color = border
	style.set_border_width_all(2 if fill != border else 0)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _variant_name(variant: String) -> String:
	return {"tia_chop": I18n.t("common.lightning"), "bam_duong": I18n.t("common.grip"), "ben_bi": I18n.t("class.endurance")}.get(variant, "")


## Chỉ bản debug: đổi sang bất kỳ class nào, kể cả class chưa mở, không tốn tiền.
func _dev_panel() -> Control:
	var card := _surface(Color("ffe9e5"), Color("e8a89c"), 20, 12)
	card.name = "DevClassPanel"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	box.add_child(_label("DEV · đổi class", 15, INK, true))
	for cls: Dictionary in GameData.race_classes():
		var id := String(cls["id"])
		var button := Button.new()
		button.name = "DevClass_" + id
		button.text = String(cls["name"]) + (" (đang dùng)" if id == GameState.active_class else "")
		button.custom_minimum_size = Vector2(0, 44)
		button.disabled = id == GameState.active_class and GameState.pending_class == ""
		button.pressed.connect(_on_dev_class.bind(id))
		box.add_child(button)
	return card


func _on_dev_class(id: String) -> void:
	if not GameState.dev_switch_class(id):
		_say("Không đổi được class")
		return
	_close()


func _facility_panel() -> Control:
	var card := _surface(Color("eef0f3"), Color("cfd6de"), 20, 12)
	card.name = "FacilityPanel"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var tile := _surface(Color("d5e3f2"), EDGE, 16, 4)
	tile.size_flags_vertical = SIZE_SHRINK_CENTER
	tile.custom_minimum_size = Vector2(68, 68)
	var mark := _label("?", 38, Color("7f95b3"))
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_child(mark)
	row.add_child(tile)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var state: String = GameState.facility_state()
	col.add_child(_label(I18n.t("class.all_facilities_unlocked") if state == "full" else I18n.t("class.unlock_new"), 19, INK, true))
	col.add_child(_label(I18n.t("class.facility_count") % [GameState.facilities.size(), GameState.facility_limit()], 14, MUTED, true))
	var note: String = {"unassigned": I18n.t("class.new_facility_waiting_you_pick"),
		"short": I18n.t("class.short") % Balance.fmt_money(GameState.facility_price().subtract_checked(GameState.coins)) if GameState.coins.compare(GameState.facility_price()) < 0 else "",
		"save_error": I18n.t("class.waiting_progress_save")}.get(state, "")
	var nl := _label(note, 13, Color("99600a"), true)
	nl.name = "FacilityNote"
	nl.visible = note != ""
	col.add_child(nl)
	if state == "ok" or state == "short":
		var buy := Button.new()
		buy.name = "FacilityBuy"
		buy.text = I18n.t("class.unlock_price") + Balance.fmt_money(GameState.facility_price())
		buy.icon = HdUi.Soft.icon("cash")
		buy.expand_icon = true
		buy.add_theme_constant_override("icon_max_width", 26)
		buy.add_theme_font_size_override("font_size", 18)
		buy.custom_minimum_size.y = 48
		HdUi.style_button(buy, "blue")
		buy.add_theme_color_override("font_disabled_color", Color("4c6589"))
		buy.add_theme_constant_override("outline_size", 1)
		buy.disabled = state != "ok"
		buy.pressed.connect(_on_open_facility)
		box.add_child(buy)
	elif state == "unassigned":
		var pick := Button.new()
		pick.name = "FacilityPick"
		pick.text = I18n.t("class.pick_type")
		pick.custom_minimum_size.y = 48
		HdUi.style_button(pick, "blue")
		pick.pressed.connect(_open_picker)
		box.add_child(pick)
	return card


func _on_open_facility() -> void:
	if GameState.buy_facility():
		_open_picker()
	else:
		_say(I18n.t("class.could_not_open_facility"))


## Popup chọn loại cơ sở: lưới 2 cột, chọn một ô rồi bấm OK. Bấm ra ngoài thì cơ sở vẫn chờ (nút đổi thành "Chọn loại").
func _open_picker(first: bool = false) -> void:
	if _picker != null:
		_picker.queue_free()
	_picker_choice = ""
	_picker_first = first
	_picker = Control.new()
	_picker.name = "FacilityPicker"
	_picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_picker)
	var dim := ColorRect.new()
	dim.name = "PickerDim"
	dim.color = Color(0.09, 0.21, 0.36, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and not _picker_first:
			_close_picker())
	_picker.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	_picker.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "PickerPanel"
	var ps := HdUi.Soft.flat(HdUi.Soft.BG, 16, 22)
	ps.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", ps)
	panel.custom_minimum_size = Vector2(minf(358.0, size.x - 32.0), 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var t := _label(I18n.t("class.first_class_title" if first else "class.choose_title"), 20, INK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var sub := _label(I18n.t("class.first_class_hint" if first else "class.pick_class_new_facility_this"), 13, MUTED, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	var grid := GridContainer.new()
	grid.name = "PickerGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for cls: Dictionary in GameData.race_classes():
		if first or not GameState.class_has(String(cls["id"])):
			grid.add_child(_option(cls))
	var ok := Button.new()
	ok.name = "PickerOk"
	ok.text = "OK"
	ok.custom_minimum_size = Vector2(0, 48)
	ok.disabled = true
	HdUi.style_button(ok, "claim")
	ok.pressed.connect(_on_picker_ok)
	box.add_child(ok)


func _option(cls: Dictionary) -> Button:
	var id := String(cls["id"])
	var b := Button.new()
	b.name = "PickerOption_" + id
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(0, 120)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.text = "%s
%s" % [String(cls["name"]), String(cls.get("blurb", ""))]
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.icon = _class_texture(id)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", 52)
	b.add_theme_font_size_override("font_size", 12)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, INK)
	var tint: Color = TILE.get(String(cls.get("color", "blue")), TILE["blue"])
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		var s := StyleBoxFlat.new()
		var on: bool = st.contains("pressed")
		s.bg_color = Color("d3f2c6") if on else tint.lerp(HdUi.Soft.BG, 0.45)
		s.border_color = Color("5cbf5a") if on else EDGE
		s.set_border_width_all(2)
		s.set_corner_radius_all(16)
		s.set_content_margin_all(8)
		b.add_theme_stylebox_override(st, s)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(_on_option.bind(id))
	return b


func _on_option(id: String) -> void:
	_picker_choice = id
	var grid := _picker.find_child("PickerGrid", true, false)
	for b: Button in grid.get_children():
		b.set_pressed_no_signal(b.name == "PickerOption_" + id)
	(_picker.find_child("PickerOk", true, false) as Button).disabled = false


func _on_picker_ok() -> void:
	var cname := String(GameData.race_class(_picker_choice)["name"])
	if _picker_first:
		if GameState.choose_first_class(_picker_choice):
			_picker_first = false
			_close_picker()
			_popup.show()
			hide()
			first_class_chosen.emit()
		else:
			_say(I18n.t("class.could_not_pick") % cname)
	elif GameState.assign_facility(_picker_choice):
		_close_picker()
		_say(I18n.t("class.opened_facility_tap_watch_race") % cname)
	else:
		_say(I18n.t("class.could_not_pick") % cname)


func _close_picker() -> void:
	if _picker != null:
		_picker.queue_free()
		_picker = null
	if GameState.facility_unassigned() >= 0:
		_say(I18n.t("class.facility_still_waiting_tap_pick"))


func _say(text: String) -> void:
	_toast.text = text
	_toast.show()
	await get_tree().create_timer(2.6).timeout
	if is_instance_valid(_toast) and _toast.text == text:
		_toast.hide()


func _label(text: String, font_size: int = 14, color: Color = INK, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = MOUSE_FILTER_IGNORE
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = SIZE_EXPAND_FILL
	return l



func _class_texture(id: String) -> Texture2D:
	return load("res://assets/models/class_vehicles/%s.png" % id) as Texture2D
