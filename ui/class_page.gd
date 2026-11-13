extends Control
## Popup Classes: cơ sở đua, quản lý và mở rộng. Đua vẫn chạy sau lớp nền tối.
signal closed

const INK := Color("16355c")
const MUTED := Color("6a7d99")
const TouchScroll = preload("res://ui/touch_scroll.gd")
const TILE := {"blue": Color("bfd9ff"), "orange": Color("ffd9b0"), "red": Color("ffc4c4"),
	"purple": Color("dcc9ff"), "gold": Color("ffeaa0"), "green": Color("bff0cf")}
var _popup: PanelContainer
var _header: PanelContainer
var _list: VBoxContainer
var _scroll: ScrollContainer
var _coins: Label
var _toast: Label
var _picker: Control
var _picker_choice: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.name = "ClassBackdrop"
	dim.color = Color(0.04, 0.12, 0.25, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not is_instance_valid(_picker):
			_close())
	add_child(dim)
	_popup = _surface(Color("e6f3ff"), Color("b6dbfa"), 24, 0)
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
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color("dcefff")
	hs.corner_radius_top_left = 24
	hs.corner_radius_top_right = 24
	hs.set_content_margin_all(10)
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
	titles.add_child(_label("Quản lý cơ sở đua", 11, MUTED, true))
	var wallet := _surface(Color("e0efff"), Color("8eb4e9"), 18, 8)
	wallet.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(wallet)
	var cash_row := HBoxContainer.new()
	cash_row.add_theme_constant_override("separation", 4)
	wallet.add_child(cash_row)
	cash_row.add_child(HdUi.icon("icons/cash.png", Vector2(24, 24)))
	_coins = _label("", 16, INK)
	cash_row.add_child(_coins)
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
	GameState.changed.connect(func() -> void:
		if is_visible_in_tree():
			refresh())


func open() -> void:
	show()
	refresh()
	_scroll.scroll_vertical = 0
	_fit_popup.call_deferred()


func _close() -> void:
	_close_picker()
	hide()
	closed.emit()


func _fit_popup() -> void:
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
		if is_instance_valid(_picker):
			_close_picker()
		else:
			_close()
		get_viewport().set_input_as_handled()


func refresh() -> void:
	_coins.text = Balance.fmt_money(GameState.coins)
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var section := HBoxContainer.new()
	section.add_child(_label("CƠ SỞ CỦA BẠN", 13, INK, true))
	section.add_child(_label("%d / %d" % [GameState.facilities.size(), GameState.facility_limit()], 16, INK))
	_list.add_child(section)
	for cls: Dictionary in GameData.race_classes():
		if GameState.class_has(String(cls["id"])):
			_list.add_child(_card(cls))
	_list.add_child(_facility_panel())


func _card(cls: Dictionary) -> Control:
	var id := String(cls["id"])
	var is_active := id == GameState.active_class
	var is_pending := id == GameState.pending_class
	var managed := id == GameState.managed_class
	var card := _surface(Color.WHITE, Color("2985ef") if managed else Color("c5d9ee"), 22, 14)
	card.name = "ClassCard_" + id
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	var tile := _surface(TILE.get(String(cls.get("color", "blue")), Color("bfd9ff")), Color("c2e1ff"), 16, 4)
	tile.size_flags_vertical = SIZE_SHRINK_CENTER
	tile.add_child(HdUi.icon("icons/car_blue.png", Vector2(56, 64)))
	head.add_child(tile)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 4)
	head.add_child(names)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	names.add_child(name_row)
	name_row.add_child(_label(String(cls["name"]), 22, INK, true))
	if is_active:
		var badge := _surface(Color("e0f8df"), Color("a7dfaa"), 14, 5)
		badge.size_flags_vertical = SIZE_SHRINK_CENTER
		var active := _label("● Đang đua", 11, Color("238331"))
		active.name = "ClassActive_" + id
		badge.add_child(active)
		name_row.add_child(badge)
	names.add_child(_label(String(cls.get("blurb", "")), 12, MUTED, true))
	var mg := Button.new()
	mg.name = "ClassManage_" + id
	mg.text = "✓ Đang quản lý" if managed else "Quản lý"
	mg.disabled = managed
	mg.custom_minimum_size.y = 28 if managed else 44
	mg.size_flags_horizontal = SIZE_SHRINK_BEGIN
	mg.add_theme_font_size_override("font_size", 13)
	if managed:
		mg.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		mg.add_theme_color_override("font_disabled_color", Color("1664cb"))
		mg.add_theme_constant_override("outline_size", 0)
	else:
		HdUi.style_button(mg, "upgrade")
	mg.pressed.connect(_on_manage.bind(id))
	names.add_child(mg)
	var line := ColorRect.new()
	line.color = Color("c9e1f7")
	line.custom_minimum_size.y = 1
	line.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(line)
	var team := VBoxContainer.new()
	team.add_theme_constant_override("separation", 2)
	team.add_child(_label("TÊN ĐỘI", 11, MUTED))
	team.add_child(_label(GameState.player_team_name, 20, INK, true))
	box.add_child(team)
	var metrics := _surface(Color("e6f3ff"), Color("e6f3ff"), 16, 10)
	box.add_child(metrics)
	var metric_row := HBoxContainer.new()
	metric_row.add_theme_constant_override("separation", 8)
	metrics.add_child(metric_row)
	metric_row.add_child(_metric("icons/trophy.png", "GIẢI HIỆN TẠI", String(GameData.league(GameState.facility_tier(id))["name"]), INK))
	var divider := ColorRect.new()
	divider.color = Color("bedaf4")
	divider.custom_minimum_size.x = 1
	divider.mouse_filter = MOUSE_FILTER_IGNORE
	metric_row.add_child(divider)
	metric_row.add_child(_metric("icons/cash.png", "THU NHẬP", "+%s/giây" % Balance.fmt_rate(GameState.facility_rate(id)), Color("22852f")))
	var hint := _surface(Color("eaf4ff"), Color("eaf4ff"), 14, 8)
	box.add_child(hint)
	var hint_row := HBoxContainer.new()
	hint_row.add_theme_constant_override("separation", 8)
	hint.add_child(hint_row)
	hint_row.add_child(HdUi.icon("icons/energy.png", Vector2(30, 34)))
	var hints := VBoxContainer.new()
	hints.size_flags_horizontal = SIZE_EXPAND_FILL
	hint_row.add_child(hints)
	var variant := _variant_name(String(cls.get("recommended_variant", "")))
	if variant != "":
		hints.add_child(_label("Xe gợi ý: " + variant, 13, INK, true))
	hints.add_child(_label(String(cls.get("key_stats", "")), 12, MUTED, true))
	if not is_active:
		var watch := Button.new()
		watch.name = "ClassWatch_" + id
		watch.text = "Sau lượt này" if is_pending else "Xem đua"
		watch.custom_minimum_size.y = 44
		HdUi.style_button(watch, "amber" if is_pending else "claim")
		watch.pressed.connect(_on_watch.bind(id))
		box.add_child(watch)
	return card


func _metric(icon_path: String, caption: String, value: String, color: Color) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = 1.0
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	col.add_child(row)
	row.add_child(HdUi.icon(icon_path, Vector2(22, 22)))
	row.add_child(_label(caption, 9, MUTED, true))
	col.add_child(_label(value, 17, color, true))
	return col


func _surface(fill: Color, border: Color, radius: int, padding: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2 if fill != border else 0)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _variant_name(variant: String) -> String:
	return {"tia_chop": "Tia chớp", "bam_duong": "Bám đường", "ben_bi": "Bền bỉ"}.get(variant, "")


func _facility_panel() -> Control:
	var card := _surface(Color("fff7e6"), Color("ffc65b"), 22, 14)
	card.name = "FacilityPanel"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	row.add_child(HdUi.icon("icons/garage.png", Vector2(64, 64)))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(col)
	var state: String = GameState.facility_state()
	col.add_child(_label("Đã mở đủ cơ sở" if state == "full" else "Mở cơ sở mới", 21, INK, true))
	col.add_child(_label("Thêm loại đua, tăng thu nhập", 12, MUTED, true))
	var note: String = {"ok": "Sẵn sàng mở cơ sở mới",
		"unassigned": "Cơ sở mới đang chờ chọn loại.",
		"short": "Còn thiếu %s" % Balance.fmt_money(GameState.facility_price().subtract_checked(GameState.coins)) if GameState.coins.compare(GameState.facility_price()) < 0 else "",
		"full": "Đã mở đủ cơ sở cho mọi class.", "save_error": "Đang chờ lưu tiến trình."}.get(state, "")
	var nl := _label(note, 13, Color("99600a"), true)
	nl.name = "FacilityNote"
	col.add_child(nl)
	if state == "ok" or state == "short":
		var buy := Button.new()
		buy.name = "FacilityBuy"
		buy.text = "Mở cơ sở · " + Balance.fmt_money(GameState.facility_price())
		buy.icon = HdUi.scaled("icons/cash.png", 0.08)
		buy.expand_icon = true
		buy.add_theme_constant_override("icon_max_width", 26)
		buy.add_theme_font_size_override("font_size", 18)
		buy.custom_minimum_size.y = 48
		HdUi.style_button(buy, "amber")
		buy.add_theme_color_override("font_disabled_color", Color("4c6589"))
		buy.add_theme_constant_override("outline_size", 0)
		buy.disabled = state != "ok"
		buy.pressed.connect(_on_open_facility)
		box.add_child(buy)
	elif state == "unassigned":
		var pick := Button.new()
		pick.name = "FacilityPick"
		pick.text = "Chọn loại"
		pick.custom_minimum_size.y = 48
		HdUi.style_button(pick, "amber")
		pick.pressed.connect(_open_picker)
		box.add_child(pick)
	return card


func _on_open_facility() -> void:
	if GameState.buy_facility():
		_open_picker()
	else:
		_say("Chưa mở được cơ sở.")


## Popup chọn loại cơ sở: lưới 2 cột, chọn một ô rồi bấm OK. Bấm ra ngoài thì cơ sở vẫn chờ (nút đổi thành "Chọn loại").
func _open_picker() -> void:
	if _picker != null:
		_picker.queue_free()
	_picker_choice = ""
	_picker = Control.new()
	_picker.name = "FacilityPicker"
	_picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_picker)
	var dim := ColorRect.new()
	dim.name = "PickerDim"
	dim.color = Color(0.09, 0.21, 0.36, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_picker())
	_picker.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	_picker.add_child(center)
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color.WHITE
	ps.set_corner_radius_all(22)
	ps.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", ps)
	panel.custom_minimum_size = Vector2(minf(358.0, size.x - 32.0), 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var t := _label("Chọn loại cơ sở", 20, INK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var sub := _label("Chọn class cho cơ sở mới. Không đổi lại được.", 13, MUTED, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	var grid := GridContainer.new()
	grid.name = "PickerGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for cls: Dictionary in GameData.race_classes():
		if not GameState.class_has(String(cls["id"])):
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
	b.icon = HdUi.scaled("icons/car_blue.png", 0.1)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", 44)
	b.add_theme_font_size_override("font_size", 12)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, INK)
	var tint: Color = TILE.get(String(cls.get("color", "blue")), Color("bfd9ff"))
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		var s := StyleBoxFlat.new()
		var on: bool = st.contains("pressed")
		s.bg_color = Color("dcf8e4") if on else tint.lerp(Color.WHITE, 0.6)
		s.border_color = Color("2fcf6c") if on else Color("dde6f1")
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
	if GameState.assign_facility(_picker_choice):
		_close_picker()
		_say("Đã mở cơ sở %s. Bấm Xem đua để dùng." % cname)
	else:
		_say("Chưa chọn được %s." % cname)


func _close_picker() -> void:
	if _picker != null:
		_picker.queue_free()
		_picker = null
	if GameState.facility_unassigned() >= 0:
		_say("Cơ sở vẫn đang chờ. Bấm Chọn loại khi sẵn sàng.")


func _on_manage(id: String) -> void:
	var cname := String(GameData.race_class(id)["name"])
	if GameState.manage_class(id):
		_say("Đang quản lý %s." % cname)
	else:
		_say("Chưa chuyển được cơ sở.")


func _on_watch(id: String) -> void:
	var cname := String(GameData.race_class(id)["name"])
	if not GameState.select_class(id):
		_say("Chưa đổi được class.")
	elif GameState.pending_class == id:
		_say("Đổi sang %s sau khi lượt hiện tại kết thúc." % cname)
	else:
		_say("Đã chuyển sang %s." % cname)


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

