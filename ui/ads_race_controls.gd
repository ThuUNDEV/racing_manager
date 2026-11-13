class_name AdsRaceControls
extends Control
## Điều khiển quảng cáo trên khung đua (Design/26 §3–§4): chip tăng tốc ×2 ở góc phải HUD, lá cờ thưởng income chạy
## trên dải khán đài, và popup xác nhận xem video. Chỉ là lớp UI: mọi luật (lượt/ngày, thời gian chờ, thưởng) nằm trong Ads.
## Dựng thô để chạy được chức năng; giao diện sẽ được chỉnh sau.

const FLAG_W := 34.0
const CHIP_SIZE := Vector2(80, 44)
const CHIP_MARGIN := Vector2(6, 8)
const BOOST := "income_boost"
const FLAG := "flag_cash"

## Main đặt mỗi khung: có bảng/popup/hướng dẫn khác đang giữ màn hình (lá cờ không xuất hiện và đứng yên).
var blocked := false

# Truy cập autoload qua node để script này biên dịch được cả trong test SceneTree (autoload chưa đăng ký lúc parse).
var _ads: Node
var _gs: Node
var _chip: Button
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
	_chip.add_theme_font_size_override("font_size", 13)
	_chip.pressed.connect(func() -> void: _open(BOOST))
	_chip.hide()
	add_child(_chip)
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
	_popup = Control.new()
	_popup.name = "AdsPopup"
	_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popup.hide()
	add_child(_popup)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popup.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 0)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color("fff7e6")
	ps.border_color = Color("f59e0b")
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(14)
	ps.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	_title = _lbl(16, Color("3b2200"))
	box.add_child(_title)
	_body = _lbl(13, Color("3b2200"))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_body)
	_status = _lbl(12, Color("a32d2d"))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	_watch = Button.new()
	_watch.custom_minimum_size = Vector2(0, 44)
	HdUi.style_button(_watch, "claim")
	_watch.pressed.connect(_on_watch)
	box.add_child(_watch)
	_later = Button.new()
	_later.custom_minimum_size = Vector2(0, 40)
	HdUi.style_button(_later, "cancel")
	_later.pressed.connect(_on_later)
	box.add_child(_later)


func _lbl(size_px: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _process(delta: float) -> void:
	_refresh_chip()
	_tick_flag(delta)


# ---------------------------------------------------------------- chip tăng tốc

func _refresh_chip() -> void:
	var mult := GameData.ads_boost_multiplier()
	var left: float = _gs.income_boost_left
	if left > 0.0:
		_chip.show()
		_chip.disabled = true
		_chip.text = "×%d\n%s" % [mult, Balance.fmt_clock(left)]
		_chip_offered = false
	elif _ads.block_reason(BOOST) == "":
		_chip.show()
		if _ads.can_offer(BOOST):
			_chip.disabled = false
			_chip.text = "×%d ▶\n%d phút" % [mult, int(_ads.offer_amount(BOOST)["seconds"]) / 60]
			if not _chip_offered:
				_chip_offered = true
				_ads.note_offer(BOOST)
		else:
			_chip.disabled = true
			_chip.text = "Đang tải…"
	else:
		_chip.hide()
		_chip_offered = false
	_chip.position = Vector2(size.x - CHIP_SIZE.x - CHIP_MARGIN.x, CHIP_MARGIN.y)


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
	_watch.text = "Xem video"
	if pl == BOOST:
		_title.text = "Tăng tốc ×%d" % int(amount["multiplier"])
		_body.text = "Xem video để nhân %d thu nhập trong %d phút." % [int(amount["multiplier"]), int(amount["seconds"]) / 60]
		_later.text = "Để sau"
	else:
		_title.text = "Thưởng tiền mặt"
		_body.text = "Xem video để nhận %s." % Balance.fmt_money(amount)
		_later.text = "Đóng"
	_popup.show()


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
