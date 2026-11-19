extends Control
const PopupAnim = preload("res://ui/popup_anim.gd")
## Bảng thăng hạng (thăng giải): mở từ huy hiệu góc trái khung đua. Logic ở GameState.expansion_state()/request_expansion().
signal closed
signal notice(text: String)

const INK := Color("0e2b5c")
const MUTED := Color("788b95")
const OK := Color("2a9d57")
const BAD := Color("d24b3a")
const TouchScroll = preload("res://ui/touch_scroll.gd")
var _popup: PanelContainer
var _scroll: ScrollContainer
var _current: Label
var _next: Label
var _reqs: VBoxContainer
var _rewards: VBoxContainer
var _note: Label
var _action: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.12, 0.25, 0.65)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_popup = PanelContainer.new()
	_popup.name = "PromotionPopup"
	_popup.clip_contents = true
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("fff8ee")
	skin.set_corner_radius_all(20)
	skin.shadow_color = Color(0, 0, 0, 0.25)
	skin.shadow_size = 12
	_popup.add_theme_stylebox_override("panel", skin)
	add_child(_popup)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	_popup.add_child(root)
	var header := _panel(root, Color("579cc5"), 0, 14)
	var header_skin := header.get_theme_stylebox("panel") as StyleBoxFlat
	header_skin.corner_radius_top_left = 20
	header_skin.corner_radius_top_right = 20
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	header.add_child(row)
	var title := _label(I18n.t("promotion.title"), 20, Color.WHITE, true)
	title.name = "PromotionTitle"
	row.add_child(title)
	var close := HdUi.close_button(_close, "PromotionBack")
	close.accessibility_name = I18n.t("promotion.close")
	row.add_child(close)
	_scroll = TouchScroll.new()
	_scroll.name = "PromotionScroll"
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
	var leagues := _panel(content, Color("72b4d7"), 20, 16)
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 10)
	leagues.add_child(lrow)
	_current = _league_box(lrow, "PromotionCurrent")
	var arrow := _label("›", 30, Color.WHITE)
	lrow.add_child(arrow)
	_next = _league_box(lrow, "PromotionNext")
	var req_panel := _panel(content, Color("f8fbff"), 14, 12)
	_reqs = VBoxContainer.new()
	_reqs.name = "PromotionRequirements"
	_reqs.add_theme_constant_override("separation", 8)
	req_panel.add_child(_reqs)
	var reward_panel := _panel(content, Color("f8fbff"), 14, 12)
	_rewards = VBoxContainer.new()
	_rewards.name = "PromotionRewards"
	_rewards.add_theme_constant_override("separation", 8)
	reward_panel.add_child(_rewards)
	_note = _label("", 12, MUTED, true)
	_note.name = "PromotionNote"
	content.add_child(_note)
	var footer := _panel(root, Color("edf4ff"), 0, 14)
	var footer_skin := footer.get_theme_stylebox("panel") as StyleBoxFlat
	footer_skin.corner_radius_bottom_left = 20
	footer_skin.corner_radius_bottom_right = 20
	var fcol := VBoxContainer.new()
	fcol.add_theme_constant_override("separation", 8)
	footer.add_child(fcol)
	_action = _button(I18n.t("promotion.action"), _promote, true)
	_action.name = "PromotionAction"
	fcol.add_child(_action)
	PopupAnim.close_on_outside_click(self, _popup, _close)
	GameState.changed.connect(_refresh_if_visible)
	visibility_changed.connect(_refresh_if_visible)
	resized.connect(_fit_popup)
	_fit_popup()
	refresh()


func open() -> void:
	PopupAnim.open(self, _popup)
	_fit_popup()
	refresh()
	_scroll.scroll_vertical = 0
	_action.grab_focus()


func _close() -> void:
	PopupAnim.close(self, _popup, closed.emit)


func _fit_popup() -> void:
	if not is_instance_valid(_popup):
		return
	_popup.size = Vector2(minf(390, maxf(0, size.x - 32)), minf(440, maxf(0, size.y - 64)))
	_popup.position = (size - _popup.size) * 0.5


func _refresh_if_visible() -> void:
	if is_visible_in_tree():
		refresh()


func _promote() -> void:
	var target := GameState.business_tier + 1
	if GameState.request_expansion():
		if GameState.business_tier >= target:
			notice.emit(I18n.t("promotion.promoted") % Balance.league_name(GameState.business_tier))
		else:
			notice.emit(I18n.t("promotion.queued"))
	else:
		notice.emit(I18n.t("promotion.failed"))
	refresh()


func refresh() -> void:
	if _current == null:
		return
	var top := GameData.leagues().size() - 1
	var tier := GameState.business_tier
	_current.text = Balance.league_name(tier)
	_clear(_reqs)
	_clear(_rewards)
	if tier >= top:
		_next.text = "-"
		_reqs.add_child(_label(I18n.t("promotion.max_league"), 14, INK, true))
		_rewards.get_parent().hide()
		_note.text = ""
		_action.disabled = true
		return
	_rewards.get_parent().show()
	var nxt := tier + 1
	_next.text = Balance.league_name(nxt)
	var min_rev := int(GameData.economy()["business"]["expansion_min_revenue_level"])
	var low_rev := min_rev
	for kind in Balance.REVENUE:
		low_rev = mini(low_rev, GameState.level_of(kind))
	_req_row(I18n.t("promotion.req_revenue"), "%d / %d" % [low_rev, min_rev], low_rev >= min_rev)
	var need_class := int(GameData.league(nxt)["min_car_class"])
	var have_class := int(GameData.car(GameState.active_car_id)["class"])
	_req_row(I18n.t("promotion.req_car"), "%d / %d" % [have_class, need_class], have_class >= need_class)
	var cost := Pricing.expansion_cost(tier)
	_req_row(I18n.t("promotion.req_fee"), "%s / %s" % [Balance.fmt_money(GameState.coins), Balance.fmt_money(cost)], GameState.coins.compare(cost) >= 0)
	var first := not GameState.processed_rewards.has("business_open/%d" % nxt)
	if first:
		_rewards.add_child(_label(I18n.t("promotion.reward_line") % [Balance.fmt_money(Pricing.opening_reserve(nxt)), int(GameData.economy()["rewards"]["first_league_gems"])], 14, INK, true))
	else:
		_rewards.add_child(_label(I18n.t("promotion.reward_none"), 14, MUTED, true))
	var state := GameState.expansion_state()
	var queued := GameState.expansion_requested
	match state:
		"save_error":
			_note.text = I18n.t("promotion.save_error")
		"ok":
			_note.text = I18n.t("promotion.queued") if queued else I18n.t("promotion.reset_warning")
		_:
			_note.text = ""
	_action.disabled = state != "ok" or queued


func _req_row(text: String, value: String, done: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_reqs.add_child(row)
	row.add_child(_label(text, 14, INK, true))
	var v := _label(value, 14, OK if done else BAD)
	v.size_flags_horizontal = SIZE_SHRINK_END
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)


func _league_box(parent: Control, node_name: String) -> Label:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	box.size_flags_vertical = SIZE_SHRINK_CENTER
	parent.add_child(box)
	var name_label := _label("", 18, Color.WHITE, true)
	name_label.name = node_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	return name_label


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _panel(parent: Control, color: Color, radius: int, pad: int) -> PanelContainer:
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


func _button(text: String, action: Callable, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(44, 44)
	button.add_theme_font_size_override("font_size", 15)
	var fg := Color.WHITE if primary else INK
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(key, fg)
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.7) if primary else MUTED)
	button.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	HdUi.text_depth(button, primary)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := StyleBoxFlat.new()
		skin.bg_color = Color("d66a00") if primary else Color.WHITE
		if state == "hover":
			skin.bg_color = skin.bg_color.lightened(0.08)
		elif state == "pressed":
			skin.bg_color = skin.bg_color.darkened(0.08)
		elif state == "disabled":
			skin.bg_color = Color("b8c2cc") if primary else Color("eef1f4")
		skin.set_corner_radius_all(12)
		skin.content_margin_left = 12
		skin.content_margin_right = 12
		button.add_theme_stylebox_override(state, skin)
	HdUi.ButtonSkin.apply(button)
	button.pressed.connect(action)
	return button
