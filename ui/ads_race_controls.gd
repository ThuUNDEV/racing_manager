class_name AdsRaceControls
extends Control
## Điều khiển quảng cáo trên khung đua (Design/26 §3–§4): chip tăng tốc ×2 ở góc phải HUD, lá cờ thưởng income chạy
## trên dải khán đài, và popup xác nhận xem video. Chỉ là lớp UI: mọi luật (lượt/ngày, thời gian chờ, thưởng) nằm trong Ads.
## Popup vé thưởng dùng cash; thông số thưởng lấy trực tiếp từ Ads.

const FLAG_W := 34.0
const CHIP_SIZE := Vector2(100, 48)
const BOOST := "income_boost"
const FLAG := "flag_cash"

## Main đặt mỗi khung: có bảng/popup/hướng dẫn khác đang giữ màn hình (lá cờ không xuất hiện và đứng yên).
var blocked := false

# Truy cập autoload qua node để script này biên dịch được cả trong test SceneTree (autoload chưa đăng ký lúc parse).
var _ads: Node
var _gs: Node
var _chip: Button
var _chip_title: Label
var _chip_time: Label
var _chip_cash: TextureRect
var _chip_progress: ProgressBar
var _chip_state := ""
var _chip_idle_styles: Dictionary = {}
var _chip_active_style: StyleBoxFlat
var _flag: Button
var _flag_x := 0.0
var _flag_on := false
var _chip_offered := false
var _popup: Control
var _popup_pl := ""
var _title: Label
var _body: Label
var _status: Label
var _watch: Button
var _later: Button
var _popup_layer: CanvasLayer
var _card: Control
var _close_button: Button
var _cash_art: TextureRect
var _multiplier: Label
var _duration: Label
var _separator: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	name = "AdsRaceControls"
	_ads = get_node("/root/Ads")
	_gs = get_node("/root/GameState")
	_chip = Button.new()
	_chip.name = "BoostChip"
	_chip.custom_minimum_size = CHIP_SIZE
	_chip.size = CHIP_SIZE
	_chip.tooltip_text = "Xem quảng cáo để nhân đôi thu nhập cash"
	_chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Live labels stay sharp over the orange ticket background.
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		_chip.add_theme_color_override(state, Color.TRANSPARENT)
	_chip.add_theme_constant_override("outline_size", 0)
	for state in ["normal", "hover", "pressed", "disabled"]:
		# Scale the complete silhouette, preserving the side cutouts.
		var ticket := StyleBoxTexture.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/ads_income_boost/boost_ticket_button.png")
		# Exclude transparent padding so visible art aligns with the rank panel.
		atlas.region = Rect2(50, 94, 1624, 728)
		ticket.texture = atlas
		if state == "hover":
			ticket.modulate_color = Color(1.08, 1.08, 1.08)
		elif state == "pressed":
			ticket.modulate_color = Color(0.85, 0.85, 0.85)
		elif state == "disabled":
			ticket.modulate_color = Color(0.9, 0.9, 0.9)
		_chip.add_theme_stylebox_override(state, ticket)
		_chip_idle_styles[state] = ticket
	_chip_active_style = StyleBoxFlat.new()
	_chip_active_style.bg_color = Color("112e3b")
	_chip_active_style.border_color = Color("57dc8a")
	_chip_active_style.set_border_width_all(2)
	_chip_active_style.set_corner_radius_all(9)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color.WHITE
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(8)
	_chip.add_theme_stylebox_override("focus", focus)
	_chip.pressed.connect(func() -> void: _open(BOOST))
	_chip.hide()
	add_child(_chip)
	_chip_cash = _art("res://assets/racing_ui_hd/icons/cash.png")
	_chip.add_child(_chip_cash)
	_chip_title = _lbl(23, Color.WHITE)
	_chip_title.add_theme_font_override("font", HdUi.font())
	_chip_title.add_theme_color_override("font_outline_color", Color("b44b00"))
	_chip_title.add_theme_constant_override("outline_size", 2)
	_chip_title.position = Vector2(46, 7)
	_chip_title.size = Vector2(39, 27)
	_chip.add_child(_chip_title)
	_chip_time = _lbl(11, HdUi.C_NAVY)
	_chip_time.add_theme_font_override("font", HdUi.font())
	_chip_time.position = Vector2(13, 30)
	_chip_time.size = Vector2(72, 16)
	_chip.add_child(_chip_time)
	_chip_progress = ProgressBar.new()
	_chip_progress.name = "BoostTimeRemaining"
	_chip_progress.show_percentage = false
	_chip_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := StyleBoxFlat.new()
	track.bg_color = Color("294953")
	track.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("57dc8a")
	fill.set_corner_radius_all(2)
	_chip_progress.add_theme_stylebox_override("background", track)
	_chip_progress.add_theme_stylebox_override("fill", fill)
	_chip.add_child(_chip_progress)
	_flag = Button.new()
	_flag.name = "CashFlag"
	_flag.text = "$"
	_flag.size = Vector2(FLAG_W, FLAG_W)
	_flag.add_theme_font_size_override("font_size", 18)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("e53935")
	sb.border_color = Color("ffd0cc")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	for st in ["normal", "hover", "pressed", "focus"]:
		_flag.add_theme_stylebox_override(st, sb)
	_flag.add_theme_color_override("font_color", Color.WHITE)
	_flag.pressed.connect(_on_flag_pressed)
	_flag.hide()
	add_child(_flag)
	_build_popup()


func _build_popup() -> void:
	# A separate canvas escapes the rounded/clipped race view and covers the whole screen.
	_popup_layer = CanvasLayer.new()
	_popup_layer.layer = 20
	add_child(_popup_layer)
	_popup = Control.new()
	_popup.name = "AdsPopup"
	_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popup.theme = HdUi.make_theme(null)
	_popup.hide()
	_popup_layer.add_child(_popup)
	var dim := ColorRect.new()
	dim.name = "Backdrop"
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popup.add_child(dim)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not _later.disabled:
			_on_later())
	_card = Control.new()
	_card.name = "RewardTicket"
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup.add_child(_card)
	var background := _art("res://assets/ads_income_boost/ticket_panel.png")
	background.name = "TicketBackground"
	background.stretch_mode = TextureRect.STRETCH_SCALE
	_card.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title = _lbl(18, Color.WHITE)
	_title.name = "RewardTitle"
	_card.add_child(_title)
	_close_button = HdUi.close_button(_on_later, "AdsClose")
	_card.add_child(_close_button)
	_cash_art = _art("res://assets/ads_income_boost/cash_bundles.png")
	_cash_art.name = "CashRewardArt"
	_card.add_child(_cash_art)
	_multiplier = _lbl(64, Color("ff9d08"))
	_multiplier.add_theme_color_override("font_outline_color", Color("a43d00"))
	_multiplier.add_theme_constant_override("outline_size", 4)
	_card.add_child(_multiplier)
	_separator = HBoxContainer.new()
	_separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_separator.add_theme_constant_override("separation", 4)
	_card.add_child(_separator)
	for i in 20:
		var dash := ColorRect.new()
		dash.color = Color("ff9000")
		dash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_separator.add_child(dash)
	_duration = _lbl(19, Color.WHITE)
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color("142b4e")
	pill.set_corner_radius_all(16)
	_duration.add_theme_stylebox_override("normal", pill)
	_card.add_child(_duration)
	_body = _lbl(14, HdUi.C_NAVY)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card.add_child(_body)
	_status = _lbl(12, Color("a32d2d"))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card.add_child(_status)
	_watch = Button.new()
	_watch.name = "WatchAd"
	_watch.custom_minimum_size = Vector2(0, 44)
	HdUi.style_button(_watch, "amber")
	_watch.add_theme_font_size_override("font_size", 18)
	_watch.add_theme_constant_override("outline_size", 0)
	_watch.pressed.connect(_on_watch)
	_card.add_child(_watch)
	_later = Button.new()
	_later.name = "AdsLater"
	_later.custom_minimum_size = Vector2(0, 40)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		_later.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_later.add_theme_color_override("font_color", HdUi.C_MUTED)
	_later.add_theme_color_override("font_hover_color", HdUi.C_NAVY)
	_later.pressed.connect(_on_later)
	_card.add_child(_later)
	_popup.resized.connect(_layout_popup)
	_layout_popup()


func _art(path: String) -> TextureRect:
	var art := TextureRect.new()
	art.texture = load(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


func _layout_popup() -> void:
	var view := get_viewport_rect().size
	var w := minf(view.x - 12.0, 360.0)
	var h := minf(430.0, view.y - 16.0)
	_card.size = Vector2(w, h)
	_card.position = (view - _card.size) * 0.5
	_place(_title, 0.10, 0.065, 0.70, 0.11)
	_place(_close_button, 0.80, 0.05, 0.14, 0.12)
	_place(_cash_art, 0.12, 0.20, 0.43, 0.25)
	if _popup_pl == FLAG:
		_place(_cash_art, 0.29, 0.20, 0.42, 0.32)
	_place(_multiplier, 0.54, 0.20, 0.33, 0.25)
	_place(_separator, 0.12, 0.48, 0.76, 0.004)
	_place(_duration, 0.27, 0.51, 0.46, 0.075)
	_place(_body, 0.12, 0.59, 0.76, 0.08)
	_place(_status, 0.12, 0.675, 0.76, 0.06)
	_place(_watch, 0.12, 0.74, 0.76, 0.115)
	_place(_later, 0.25, 0.855, 0.50, 0.095)
	_later.position.y = maxf(_later.position.y, _watch.position.y + _watch.size.y)


func _place(control: Control, x: float, y: float, w: float, h: float) -> void:
	control.position = _card.size * Vector2(x, y)
	control.size = _card.size * Vector2(w, h)


func _unhandled_key_input(event: InputEvent) -> void:
	if _popup.visible and event.is_action_pressed("ui_cancel"):
		if not _later.disabled:
			_on_later()
		get_viewport().set_input_as_handled()


func _lbl(size_px: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _process(delta: float) -> void:
	_refresh_chip()
	_tick_flag(delta)


# ---------------------------------------------------------------- chip tăng tốc

func _set_chip_state(state: String) -> void:
	if state == _chip_state:
		return
	_chip_state = state
	var running := state == "active"
	for style in ["normal", "hover", "pressed", "disabled"]:
		_chip.add_theme_stylebox_override(style, _chip_active_style if running else _chip_idle_styles[style])
	_chip_progress.visible = running
	_chip_cash.visible = not running
	_chip_title.add_theme_font_size_override("font_size", 12 if running else 22)
	_chip_title.add_theme_constant_override("outline_size", 0 if running else 2)
	_chip_time.add_theme_font_size_override("font_size", 14 if running else 11)
	_chip_time.add_theme_color_override("font_color", Color("9bffc1") if running else HdUi.C_NAVY)
	_chip.tooltip_text = "Đang nhân đôi thu nhập cash" if running else "Xem quảng cáo để nhân đôi thu nhập cash"
	_chip.mouse_default_cursor_shape = Control.CURSOR_ARROW if running else Control.CURSOR_POINTING_HAND


func _layout_chip() -> void:
	var rect := RaceView.hud_boost_rect_for_width(size.x)
	_chip.custom_minimum_size = rect.size
	_chip.size = rect.size
	_chip.position = rect.position
	var w := rect.size.x
	if _chip_state == "active":
		_chip_title.position = Vector2(4, 4)
		_chip_title.size = Vector2(w - 8, 18)
		_chip_time.position = Vector2(4, 23)
		_chip_time.size = Vector2(w - 8, 18)
	else:
		_chip_cash.position = Vector2(w * 0.14, 3)
		_chip_cash.size = Vector2(27, 26)
		_chip_title.position = Vector2(w * 0.47, 1)
		_chip_title.size = Vector2(w * 0.39, 28)
		_chip_time.position = Vector2(w * 0.12, 29)
		_chip_time.size = Vector2(w * 0.76, 15)
	_chip_progress.position = Vector2(w * 0.12, 43)
	_chip_progress.size = Vector2(w * 0.76, 2)


func _refresh_chip() -> void:
	var mult := GameData.ads_boost_multiplier()
	var left: float = _gs.income_boost_left
	if left > 0.0:
		_set_chip_state("active")
		_chip.show()
		_chip.disabled = true
		_chip.text = "×%d\n%s" % [mult, Balance.fmt_clock(left)]
		_chip_title.text = "ĐANG ×%d" % mult
		_chip_time.text = Balance.fmt_clock(left)
		var config: Dictionary = GameData.ads().get("placements", {}).get(BOOST, {})
		_chip_progress.max_value = maxf(float(config.get("duration_sec", 1800)), left)
		_chip_progress.value = left
		_chip_offered = false
	elif _ads.block_reason(BOOST) == "":
		_set_chip_state("offer")
		_chip.show()
		if _ads.can_offer(BOOST):
			_chip.disabled = false
			_chip.text = "×%d ▶\n%d phút" % [mult, int(_ads.offer_amount(BOOST)["seconds"]) / 60]
			_chip_title.text = "×%d" % mult
			_chip_time.text = "Xem video"
			if not _chip_offered:
				_chip_offered = true
				_ads.note_offer(BOOST)
		else:
			_chip.disabled = true
			_chip.text = "Đang tải…"
			_chip_title.text = "×%d" % mult
			_chip_time.text = "Đang tải…"
	else:
		_chip.hide()
		_chip_offered = false
	_layout_chip()
	_chip.accessibility_name = "Thu nhập cash " + _chip.text.replace("\n", ", ")


# ---------------------------------------------------------------- lá cờ

func _tick_flag(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if not _flag_on:
		if not _popup.visible and _ads.flag_due(blocked) and _ads.flag_begin():
			_flag_on = true
			_flag_x = -FLAG_W
			_flag.show()
		else:
			return
	if _popup.visible or blocked or _ads.is_busy():
		return
	var cross := maxf(float(GameData.ads().get("placements", {}).get(FLAG, {}).get("cross_sec", 14)), 1.0)
	_flag_x += (size.x + FLAG_W) / cross * delta
	if _flag_x > size.x:
		_end_flag(false)
		return
	_flag.position = Vector2(_flag_x, RaceView.HUD_H + (RaceView.STAND_H - FLAG_W) * 0.5)


func _end_flag(tapped: bool) -> void:
	if not _flag_on:
		return
	_flag_on = false
	_flag.hide()
	_ads.flag_end(tapped)


func _on_flag_pressed() -> void:
	_ads.flag_mark_intro_seen()
	_open(FLAG)


# ---------------------------------------------------------------- popup

func _open(pl: String) -> void:
	var amount: Variant = _ads.offer_amount(pl)
	if amount == null:
		if pl == FLAG:
			_end_flag(true)
		return
	_popup_pl = pl
	_status.text = ""
	_watch.disabled = false
	_later.disabled = false
	_close_button.disabled = false
	_watch.text = "▶  Xem quảng cáo"
	_multiplier.visible = pl == BOOST
	_duration.visible = pl == BOOST
	_separator.visible = pl == BOOST
	if pl == BOOST:
		_title.text = "THU NHẬP ×%d" % int(amount["multiplier"])
		_multiplier.text = "×%d" % int(amount["multiplier"])
		_duration.text = "◷ %d phút" % (int(amount["seconds"]) / 60)
		var action := "nhân đôi" if int(amount["multiplier"]) == 2 else "nhân %d" % int(amount["multiplier"])
		_body.text = "Xem quảng cáo để %s\nthu nhập cash." % action
		_later.text = "Để sau"
	else:
		_title.text = "Thưởng tiền mặt"
		_body.text = "Xem video để nhận %s." % Balance.fmt_money(amount)
		_later.text = "Đóng"
	_popup.show()
	_layout_popup()


func _on_watch() -> void:
	_set_busy_buttons(true)
	_status.text = ""
	var pl := _popup_pl
	if _ads.has_pending(pl):
		_ads.retry_pending(pl, _on_done)
	else:
		_ads.try_show_rewarded(pl, _on_done)


func _on_done(r: Dictionary) -> void:
	var pl := String(r.get("placement", _popup_pl))
	var status := String(r.get("status", ""))
	if status in ["rewarded", "skipped_entitled"]:
		_close(pl, true)
		return
	_set_busy_buttons(false)
	if status == "failed" and _ads.has_pending(pl):
		_status.text = "Chưa lưu được thưởng. Thử nhận lại."
		_watch.text = "Thử nhận lại"
		return
	_status.text = _ads.status_text(status)


func _on_later() -> void:
	_ads.clear_pending()
	_close(_popup_pl, false)


func _close(pl: String, _watched: bool) -> void:
	_popup.hide()
	if pl == FLAG:
		_end_flag(true)  # xem hay đóng thì lá cờ đều mất


func _set_busy_buttons(busy: bool) -> void:
	_watch.disabled = busy
	_later.disabled = busy
	_close_button.disabled = busy
