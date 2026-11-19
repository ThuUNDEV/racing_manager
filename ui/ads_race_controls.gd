class_name AdsRaceControls
extends Control
const RaceArt = preload("res://ui/race_hud_art.gd")
const CleanArt = preload("res://ui/clean_modern_art.gd")
## Điều khiển quảng cáo trên khung đua (Design/26 §3–§4): chip tăng tốc ×2 ở góc phải HUD, lá cờ thưởng income chạy
## trên dải khán đài, và popup xác nhận xem video. Chỉ là lớp UI: mọi luật (lượt/ngày, thời gian chờ, thưởng) nằm trong Ads.
## Popup thưởng dùng cash; thông số thưởng lấy trực tiếp từ Ads.

const FLAG_W := 44.0
const CHIP_SIZE := Vector2(100, 36)
const BOARD_H := 32.0
const BOARD_HIT_H := 44.0           # vùng chạm tối thiểu; bảng vẽ nằm ở đáy vùng này
const BOARD_TOP := BOARD_HIT_H - BOARD_H
const BOARD_MIN_W := 74.0
const BOARD_GAP := 14.0            # khoảng hở giữa đáy bảng và mái nhà (gồm cả đuôi)
const BOARD_PAD := 8.0
const BOARD_ICON := 20.0
const BOARD_VIDEO := 16.0
const BOARD_TAIL_W := 8.0          # nửa bề ngang chân đuôi
const BOARD_TAIL_H := 7.0
const BOARD_FONT := 13
const BUBBLE_INSET := 28.0
const BUBBLE_POP_SEC := 0.28
const BUBBLE_BREAK_SEC := 0.18
const BUBBLE_BLINK_SEC := 4.0
const BUBBLE_DRAG_PX := 8.0
const BOOST := "income_boost"
const FLAG := "flag_cash"

## Main đặt mỗi khung: có bảng/popup/hướng dẫn khác đang giữ màn hình (lá cờ không xuất hiện và đứng yên).
var blocked := false

# Truy cập autoload qua node để script này biên dịch được cả trong test SceneTree (autoload chưa đăng ký lúc parse).
var _ads: Node
var _gs: Node
var _chip: Button
var _chip_host: Control
var _chip_title: Label
var _chip_mult: Label
var _chip_time: Label
var _chip_video: TextureRect
var _chip_cash: TextureRect
var _chip_progress: ProgressBar
var _chip_state := ""
var _chip_idle_styles: Dictionary = {}
var _chip_active_style: StyleBoxTexture
var _flag: Button
var _flag_art: TextureRect
var _flag_x := 0.0
var _flag_on := false
# Bong bóng thưởng bám theo mái khán đài 3D (Design/26 §4); chế độ 2D vẫn dùng lá cờ chạy ở trên.
var _bubble: Button
var _bubble_face: Control
var _bubble_on := false           # còn "chờ kết cục" (chưa gọi flag_end)
var _bubble_tapped := false
var _bubble_age := 0.0
var _bubble_t := 0.0              # thời gian từ lúc pop-in, cho hiệu ứng
var _bubble_break := -1.0         # >= 0: đang vỡ
var _bubble_tail := true
var _bubble_tail_dx := 0.0        # lệch ngang của đuôi so với tâm bảng, kẹp trong bề ngang bảng
var _bubble_amount: Label
var _bubble_video: TextureRect
var _bubble_down := Vector2.ZERO
var _bubble_dragging := false
var _bubble_rv: RaceView
var _reduce_motion := false
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
var _ticket_background: Panel
var _boost_details: Panel
var _reward_burst: Control
var _cash_background: Panel
var _cash_glow: Panel
var _cash_amount: Label
var _cash_caption: Label


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
	_chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Live labels stay sharp over the compact blue offer button.
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		_chip.add_theme_color_override(state, Color.TRANSPARENT)
	_chip.add_theme_constant_override("outline_size", 0)
	_chip.add_theme_font_size_override("font_size", 1)
	_chip.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var ticket := RaceArt.skin("reward_blue")
		# This tile uses a uniform scale, keeping all four rounded corners intact.
		ticket.texture_margin_left = 0
		ticket.texture_margin_right = 0
		ticket.texture_margin_top = 0
		ticket.texture_margin_bottom = 0
		_chip.add_theme_stylebox_override(state, ticket)
		_chip_idle_styles[state] = ticket
	_chip_active_style = (_chip_idle_styles["normal"] as StyleBoxTexture).duplicate()
	_chip_active_style.modulate_color = Color("c8edf7")
	_chip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_chip.pressed.connect(func() -> void: _open(BOOST))
	_chip.hide()
	add_child(_chip)
	_chip_cash = _art(RaceArt.ROOT + "icons/cash.png")
	_chip.add_child(_chip_cash)
	_chip_video = _art(RaceArt.ROOT + "icons/video.png")
	_chip.add_child(_chip_video)
	_chip_title = _lbl(23, Color.WHITE)
	_chip_title.add_theme_font_override("font", HdUi.font())
	_chip_title.add_theme_color_override("font_outline_color", Color("0452b8"))
	_chip_title.add_theme_constant_override("outline_size", 2)
	_chip_title.position = Vector2(46, 7)
	_chip_title.size = Vector2(39, 27)
	_chip.add_child(_chip_title)
	_chip_time = _lbl(11, HdUi.C_NAVY)
	_chip_time.add_theme_font_override("font", HdUi.font())
	_chip_time.position = Vector2(13, 30)
	_chip_time.size = Vector2(72, 16)
	_chip.add_child(_chip_time)
	_chip_mult = _lbl(36, Color.WHITE)
	_chip_mult.name = "BoostMultiplier"
	_chip_mult.add_theme_font_override("font", HdUi.font())
	_chip_mult.add_theme_color_override("font_outline_color", Color("0452b8"))
	_chip_mult.add_theme_constant_override("outline_size", 6)
	_chip_mult.clip_text = true
	_chip.add_child(_chip_mult)
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
	_flag.accessibility_name = I18n.t("ads.bonus_cash")
	_flag.size = Vector2(FLAG_W, FLAG_W)
	# The 16px artwork follows the compact audience strip; its 44px hit area
	# extends into the board below, leaving the boost button in the HUD clear.
	for st in ["normal", "hover", "pressed", "focus"]:
		_flag.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_flag_art = HdUi.icon("icons/cash.png", Vector2(24, 16))
	_flag_art.name = "FlagArtwork"
	_flag_art.position = Vector2(10, 0)
	_flag_art.size = Vector2(24, 16)
	_flag.add_child(_flag_art)
	_flag.pressed.connect(_on_flag_pressed)
	_flag.hide()
	add_child(_flag)
	_build_bubble()
	_reduce_motion = OS.get_cmdline_args().has("--reduce-motion")
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
	# Draw the portrait card directly: atlas ticket art has a landscape aspect ratio.
	var background := Panel.new()
	background.name = "BoostBackground"
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticket_background = background
	var boost_panel := StyleBoxFlat.new()
	boost_panel.bg_color = HdUi.C_BLUE
	boost_panel.border_color = HdUi.C_LINE
	boost_panel.set_border_width_all(3)
	boost_panel.set_corner_radius_all(26)
	boost_panel.shadow_color = Color(0.01, 0.06, 0.15, 0.35)
	boost_panel.shadow_size = 24
	boost_panel.shadow_offset = Vector2(0, 8)
	background.add_theme_stylebox_override("panel", boost_panel)
	_card.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boost_details = Panel.new()
	_boost_details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var details_skin := StyleBoxFlat.new()
	details_skin.bg_color = HdUi.C_PANEL
	details_skin.set_corner_radius_all(22)
	_boost_details.add_theme_stylebox_override("panel", details_skin)
	_card.add_child(_boost_details)
	_reward_burst = preload("res://ui/reward_burst.gd").new()
	_card.add_child(_reward_burst)
	_cash_background = Panel.new()
	_cash_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cash_panel := StyleBoxFlat.new()
	cash_panel.bg_color = Color("f7fbff")
	cash_panel.border_color = Color("74b9f1")
	cash_panel.set_border_width_all(2)
	cash_panel.set_corner_radius_all(24)
	cash_panel.shadow_color = Color(0.01, 0.06, 0.15, 0.4)
	cash_panel.shadow_size = 16
	cash_panel.shadow_offset = Vector2(0, 8)
	_cash_background.add_theme_stylebox_override("panel", cash_panel)
	_card.add_child(_cash_background)
	_cash_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cash_glow = Panel.new()
	_cash_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow := StyleBoxFlat.new()
	glow.bg_color = Color("e5f5d9")
	glow.set_corner_radius_all(72)
	_cash_glow.add_theme_stylebox_override("panel", glow)
	_card.add_child(_cash_glow)
	_cash_amount = _lbl(42, Color("173d61"))
	_cash_amount.name = "CashRewardAmount"
	_card.add_child(_cash_amount)
	_cash_caption = _lbl(12, Color("48732d"))
	_cash_caption.text = I18n.t("ads.bonus_cash")
	_card.add_child(_cash_caption)
	_title = _lbl(18, HdUi.C_TEXT)
	_title.name = "RewardTitle"
	_title.clip_text = true
	_card.add_child(_title)
	_close_button = HdUi.close_button(_on_later, "AdsClose")
	_card.add_child(_close_button)
	_cash_art = _art("res://assets/racing_ui_hd/icons/cash.png")
	_cash_art.name = "CashRewardArt"
	_card.add_child(_cash_art)
	_multiplier = _lbl(68, HdUi.C_BLUE)
	_multiplier.add_theme_color_override("font_outline_color", HdUi.C_BLUE)
	_multiplier.add_theme_constant_override("outline_size", 3)
	_card.add_child(_multiplier)
	_separator = HBoxContainer.new()
	_separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_separator.add_theme_constant_override("separation", 4)
	_card.add_child(_separator)
	for i in 20:
		var dash := ColorRect.new()
		dash.color = HdUi.C_LINE
		dash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_separator.add_child(dash)
	_duration = _lbl(17, HdUi.C_BLUE)
	var pill := StyleBoxFlat.new()
	pill.bg_color = HdUi.C_PANEL_HI
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
	HdUi.style_button(_watch, "race")
	_watch.add_theme_font_size_override("font_size", 18)
	HdUi.text_depth(_watch, true)
	_watch.pressed.connect(_on_watch)
	_card.add_child(_watch)
	_later = Button.new()
	_later.name = "AdsLater"
	_later.custom_minimum_size = Vector2(0, 40)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		_later.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_later.add_theme_color_override("font_color", HdUi.C_MUTED)
	_later.add_theme_color_override("font_hover_color", HdUi.C_NAVY)
	HdUi.text_depth(_later)
	_later.pressed.connect(_on_later)
	_card.add_child(_later)
	_popup.resized.connect(_layout_popup)
	_layout_popup()


func _art(path: String) -> TextureRect:
	var art := TextureRect.new()
	art.texture = CleanArt.asset(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


func _layout_popup() -> void:
	var view := get_viewport_rect().size
	var w := minf(view.x - 32.0, 360.0)
	var h := minf(480.0, view.y - 100.0)
	_card.size = Vector2(w, h)
	_card.position = (view - _card.size) * 0.5
	_place(_boost_details, 0.012, 0.39, 0.976, 0.60)
	_place(_reward_burst, -0.05, -0.19, 1.10, 0.67)
	_place(_title, 0.08, 0.43, 0.84, 0.09)
	_place(_close_button, 0.82, -0.015, 0.14, 0.11)
	_close_button.size = Vector2(48, 48)
	_place(_cash_art, 0.07, -0.12, 0.86, 0.55)
	_place(_multiplier, 0.58, 0.235, 0.34, 0.16)
	_multiplier.pivot_offset = _multiplier.size * 0.5
	_multiplier.rotation = -0.12
	_place(_duration, 0.28, 0.54, 0.44, 0.075)
	_place(_separator, 0.09, 0.64, 0.82, 0.003)
	_place(_body, 0.09, 0.66, 0.82, 0.09)
	_place(_status, 0.08, 0.75, 0.84, 0.05)
	_place(_watch, 0.07, 0.815, 0.86, 0.115)
	_place(_later, 0.08, 0.94, 0.84, 0.065)
	# Keep the secondary action inside the card, including its 40px touch target.
	_later.position.y = _watch.position.y + _watch.size.y + 8.0
	_card.size.y = maxf(_card.size.y, _later.position.y + _later.size.y + 16.0)
	_boost_details.size.y = _card.size.y - _boost_details.position.y - 5.0
	_card.position = (view - _card.size) * 0.5
	if _popup_pl == FLAG:
		_card.size = Vector2(minf(view.x - 32.0, 340.0), minf(408.0, view.y - 24.0))
		_card.position = (view - _card.size) * 0.5
		_place(_title, 0.07, 0.045, 0.72, 0.09)
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_place(_close_button, 0.80, 0.025, 0.15, 0.12)
		_close_button.size = Vector2(48, 48)
		_place(_cash_glow, 0.28, 0.16, 0.44, 0.29)
		_place(_cash_art, 0.19, 0.145, 0.62, 0.30)
		_place(_cash_caption, 0.08, 0.46, 0.84, 0.05)
		_place(_cash_amount, 0.06, 0.51, 0.88, 0.14)
		_place(_body, 0.07, 0.65, 0.86, 0.06)
		_place(_status, 0.06, 0.71, 0.88, 0.065)
		_place(_watch, 0.07, 0.79, 0.86, 0.13)
		_later.hide()
	else:
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_later.show()


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
	HdUi.text_depth(l, color.get_luminance() > 0.65)
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
	_chip_cash.visible = true
	_chip_video.visible = not running
	_chip_title.add_theme_color_override("font_color", HdUi.C_NAVY)
	_chip_title.add_theme_constant_override("outline_size", 0)
	_chip_title.add_theme_constant_override("shadow_offset_x", 0)
	_chip_title.add_theme_constant_override("shadow_offset_y", 0)
	_chip_title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	_chip_time.add_theme_color_override("font_color", Color("0877d2"))
	_chip.mouse_default_cursor_shape = Control.CURSOR_ARROW if running else Control.CURSOR_POINTING_HAND


func dock_chip(host: Control) -> void:
	_chip_host = host
	_chip.reparent(host, false)
	_chip.visibility_changed.connect(func() -> void: host.visible = _chip.visible)
	host.visible = _chip.visible
	_layout_chip()


func _layout_chip() -> void:
	var k := size.x / 1448.0
	var rect := RaceView.hud_boost_rect_for_width(size.x)
	if _chip_host != null:
		k = 1.0
		rect = Rect2(Vector2.ZERO, Vector2(260, 205))
	_chip.custom_minimum_size = Vector2.ZERO
	_chip.size = rect.size
	_chip.position = rect.position
	_chip_cash.position = Vector2(14, 51) * k
	_chip_cash.size = Vector2(150, 102) * k
	_chip_video.position = Vector2(166, 83) * k
	_chip_video.size = Vector2(83, 70) * k
	_chip_title.hide()
	_chip_time.hide()
	_chip_mult.position = Vector2(140, 0) * k
	_chip_mult.size = Vector2(114, 84) * k
	_chip_mult.add_theme_font_size_override("font_size", maxi(12, roundi(74 * k)))
	_chip_mult.add_theme_constant_override("outline_size", maxi(3, roundi(12 * k)))
	_chip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chip_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chip_title.clip_text = true
	_chip_title.position = Vector2(6, 103) * k
	_chip_title.size = Vector2(248, 47) * k
	_chip_title.add_theme_font_size_override("font_size", maxi(9, roundi(36 * k)))
	_chip_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chip_time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chip_time.clip_text = true
	_chip_time.position = Vector2(6, 150) * k
	_chip_time.size = Vector2(248, 40) * k
	var caption_font := maxi(8, roundi(30 * k))
	while caption_font > 7 and _chip_time.get_theme_font("font").get_string_size(_chip_time.text, HORIZONTAL_ALIGNMENT_LEFT, -1, caption_font).x > rect.size.x - 4:
		caption_font -= 1
	_chip_time.add_theme_font_size_override("font_size", caption_font)
	_chip_progress.position = Vector2(27, 192) * k
	_chip_progress.size = Vector2(206, 3) * k



func _refresh_chip() -> void:
	var mult := GameData.ads_boost_multiplier()
	var left: float = _gs.income_boost_left
	_chip_mult.text = "×%d" % mult
	if left > 0.0:
		_set_chip_state("active")
		_chip.show()
		_chip.disabled = true
		_chip.text = "×%d\n%s" % [mult, Balance.fmt_clock(left)]
		_chip_title.text = I18n.t("ads.active_x") % mult
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
			_chip.text = I18n.t("ads.x_min") % [mult, int(_ads.offer_amount(BOOST)["seconds"]) / 60]
			_chip_title.text = ("×%d Thưởng" if I18n.lang() == "vi" else "×%d Reward") % mult
			_chip_time.text = I18n.t("ads.watch_ad").replace("▶", "").strip_edges()
			if not _chip_offered:
				_chip_offered = true
				_ads.note_offer(BOOST)
		else:
			_chip.disabled = true
			_chip.text = I18n.t("common.loading")
			_chip_title.text = ("×%d Thưởng" if I18n.lang() == "vi" else "×%d Reward") % mult
			_chip_time.text = I18n.t("common.loading")
	else:
		_set_chip_state("offer")
		_chip.show()
		_chip.disabled = true
		_chip_title.text = ("×%d Thưởng" if I18n.lang() == "vi" else "×%d Reward") % mult
		var reason := String(_ads.block_reason(BOOST))
		var explanation := {"locked": I18n.t("ads.open_shop"), "capped": I18n.t("ads.daily_limit_reached"), "cooldown": I18n.t("ads.waiting"), "save": I18n.t("common.saving")}
		_chip_time.text = I18n.t("ads.owned_x") % _gs.purchased_mult() if _gs.purchased_mult() >= mult else String(explanation.get(reason, I18n.t("ads.not_ready")))
		_chip.text = "×%d · %s" % [mult, _chip_time.text]
		_chip_offered = false
	_layout_chip()
	_chip.accessibility_name = I18n.t("ads.cash_income") + _chip.text.replace("\n", ", ")


# ---------------------------------------------------------------- lá cờ

func _tick_flag(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var rv := get_parent() as RaceView
	var anchored := rv != null and rv.grandstand_screen_point() != null
	if _bubble_break >= 0.0:
		_tick_bubble_break(delta, rv)
	if _bubble_on:
		_tick_bubble(delta, rv, anchored)
		return
	if not _flag_on:
		if not _popup.visible and _ads.flag_due(blocked) and _ads.flag_begin():
			if anchored:
				_begin_bubble(rv)
				return
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
	_flag.position = Vector2(_flag_x, RaceView.HUD_H)


func _end_flag(tapped: bool) -> void:
	if _bubble_on:
		_bubble_on = false
		if not tapped and _bubble_break < 0.0:
			_start_bubble_break()
		_ads.flag_end(tapped)
		return
	if not _flag_on:
		return
	_flag_on = false
	_flag.hide()
	_ads.flag_end(tapped)


func _on_flag_pressed() -> void:
	_ads.flag_mark_intro_seen()
	_open(FLAG)


# ---------------------------------------------------------------- bong bóng khán đài

func _build_bubble() -> void:
	_bubble = Button.new()
	_bubble.name = "CashBubble"
	_bubble.accessibility_name = I18n.t("ads.bonus_cash")
	_bubble.size = Vector2(BOARD_MIN_W, BOARD_HIT_H)
	_bubble.pivot_offset = _bubble.size * 0.5
	_bubble.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		_bubble.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_bubble.pressed.connect(_on_bubble_pressed)
	_bubble.gui_input.connect(_on_bubble_gui_input)
	_bubble_face = Control.new()
	_bubble_face.name = "BubbleFace"
	_bubble_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bubble_face.draw.connect(_draw_bubble)
	_bubble.add_child(_bubble_face)
	var icon := HdUi.icon("icons/cash.png", Vector2(BOARD_ICON, BOARD_ICON))
	icon.name = "BubbleCash"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bubble.add_child(icon)
	icon.position = Vector2(BOARD_PAD, BOARD_TOP + (BOARD_H - BOARD_ICON) * 0.5 - 1.0)
	icon.size = Vector2(BOARD_ICON, BOARD_ICON)
	_bubble_amount = _lbl(BOARD_FONT, Color("ffffff"))
	_bubble_amount.name = "BubbleAmount"
	_bubble_amount.add_theme_font_override("font", HdUi.font())
	_bubble_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_bubble_amount.clip_text = true
	_bubble.add_child(_bubble_amount)
	_bubble_video = _art(RaceArt.ROOT + "icons/video.png")
	_bubble_video.name = "BubbleVideo"
	_bubble.add_child(_bubble_video)
	_bubble.hide()
	add_child(_bubble)


func _begin_bubble(rv: RaceView) -> void:
	_bubble_on = true
	_bubble_tapped = false
	_bubble_age = 0.0
	_bubble_t = 0.0
	_bubble_break = -1.0
	_bubble_dragging = false
	_bubble.disabled = false
	_bubble.modulate = Color.WHITE
	_bubble.scale = Vector2.ONE * (1.0 if _reduce_motion else 0.0)
	_layout_board()
	if _bubble_rv != rv:
		_bubble_rv = rv
		rv.view_rotated.connect(func() -> void: _place_bubble(_bubble_rv))
	_bubble.show()
	_place_bubble(rv)


func _tick_bubble(delta: float, rv: RaceView, anchored: bool) -> void:
	if not anchored:
		_bubble.hide()
		_bubble_break = -1.0
		_end_flag(false)
		return
	_bubble_t += delta
	var paused: bool = _popup.visible or blocked or _ads.is_busy()
	if not paused and not _bubble_tapped:
		_bubble_age += delta
	var stay := maxf(float(GameData.ads().get("placements", {}).get(FLAG, {}).get("stay_sec", 20)), 1.0)
	if _bubble_age >= stay:
		_end_flag(false)
		return
	if _bubble_break >= 0.0 or _bubble_tapped:
		return
	var left := stay - _bubble_age
	var alpha := 1.0
	if not _reduce_motion and left < BUBBLE_BLINK_SEC:
		alpha = 1.0 if int(left / 0.4) % 2 == 0 else 0.6
	_bubble.modulate.a = alpha
	_bubble.scale = Vector2.ONE * (1.0 if _reduce_motion else _pop_scale(_bubble_t / BUBBLE_POP_SEC))
	_place_bubble(rv)


## 0 → 1,15 → 1 (ease back).
func _pop_scale(t: float) -> float:
	if t >= 1.0:
		return 1.0
	if t < 0.65:
		return 1.15 * sin(t / 0.65 * PI * 0.5)
	return lerpf(1.15, 1.0, (t - 0.65) / 0.35)


func _start_bubble_break() -> void:
	_bubble_break = 0.0
	_bubble.disabled = true
	if _reduce_motion:
		_bubble.hide()
		_bubble_break = -1.0


func _tick_bubble_break(delta: float, rv: RaceView) -> void:
	_bubble_break += delta
	var u := clampf(_bubble_break / BUBBLE_BREAK_SEC, 0.0, 1.0)
	_bubble.scale = Vector2.ONE * lerpf(1.0, 1.3, u)
	_bubble.modulate.a = 1.0 - u
	_bubble_face.queue_redraw()
	if rv != null:
		_place_bubble(rv)
	if u >= 1.0:
		_bubble_break = -1.0
		_bubble.hide()


## Chữ số tiền + độ rộng bảng; gọi lúc bảng hiện ra.
func _layout_board() -> void:
	var amount: Variant = _ads.offer_amount(FLAG)
	var text := "+" + Balance.fmt_money(amount) if amount is BigNumber else ""
	_bubble_amount.text = text
	var font := HdUi.font()
	var text_w := ceilf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BOARD_FONT).x)
	var video := BOARD_VIDEO
	var w := maxf(BOARD_MIN_W, BOARD_PAD * 2.0 + BOARD_ICON + 4.0 + text_w + 6.0 + video)
	_bubble.size = Vector2(w, BOARD_HIT_H)
	_bubble.pivot_offset = _bubble.size * 0.5
	var text_x := BOARD_PAD + BOARD_ICON + 4.0
	_bubble_amount.position = Vector2(text_x, BOARD_TOP)
	_bubble_amount.size = Vector2(text_w + 4.0, BOARD_H - 2.0)
	_bubble_video.position = Vector2(w - BOARD_PAD - video, BOARD_TOP + (BOARD_H - video) * 0.5 - 1.0)
	_bubble_video.size = Vector2(video, video)


## Đặt bảng lên mái khán đài theo góc xoay hiện tại; kẹp trong khung bản đồ.
func _place_bubble(rv: RaceView) -> void:
	if rv == null or _bubble == null or not _bubble.visible:
		return
	var anchor: Variant = rv.grandstand_screen_point()
	if anchor == null:
		return
	var half := _bubble.size * 0.5
	var area := rv.grandstand_view_rect().grow(-maxf(BUBBLE_INSET, half.x))
	var want := Vector2((anchor as Vector2).x, (anchor as Vector2).y - half.y - BOARD_GAP)
	var center := Vector2(clampf(want.x, area.position.x, maxf(area.end.x, area.position.x)),
		clampf(want.y, area.position.y, maxf(area.end.y, area.position.y)))
	_bubble_tail = is_equal_approx(center.x, want.x) and is_equal_approx(center.y, want.y)
	if _chip != null and _chip.is_visible_in_tree():
		var chip := Rect2(get_global_transform().affine_inverse() * _chip.get_global_rect().position, _chip.size).grow(half.x + 4.0)
		if chip.has_point(center):
			center.x = chip.position.x
			_bubble_tail = false
	_bubble_tail_dx = clampf(want.x - center.x, -(half.x - 14.0), half.x - 14.0)
	if not _reduce_motion and _bubble_break < 0.0:
		center.y += sin(_bubble_t * TAU / 1.2) * 2.0
	_bubble.position = center - half
	_bubble_face.queue_redraw()


func _draw_bubble() -> void:
	var rect := Rect2(0.0, BOARD_TOP, _bubble_face.size.x, BOARD_H)
	var tail_x := rect.size.x * 0.5 + _bubble_tail_dx
	var rim := Color("f3e3b8")
	_bubble_face.draw_colored_polygon(PackedVector2Array([Vector2(tail_x - BOARD_TAIL_W, rect.end.y - 3.0),
		Vector2(tail_x + BOARD_TAIL_W, rect.end.y - 3.0), Vector2(tail_x, rect.end.y + BOARD_TAIL_H + 1.5)]), rim)
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0, 0, 0, 0.22)
	shadow.set_corner_radius_all(11)
	_bubble_face.draw_style_box(shadow, Rect2(rect.position + Vector2(0, 3), rect.size))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("1f4b5a")
	panel.border_color = Color("f3e3b8")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(11)
	_bubble_face.draw_style_box(panel, rect)
	_bubble_face.draw_colored_polygon(PackedVector2Array([Vector2(tail_x - BOARD_TAIL_W + 2.5, rect.end.y - 2.0),
		Vector2(tail_x + BOARD_TAIL_W - 2.5, rect.end.y - 2.0), Vector2(tail_x, rect.end.y + BOARD_TAIL_H - 1.5)]), panel.bg_color)
	if _bubble_break >= 0.0:
		return
	var stay := maxf(float(GameData.ads().get("placements", {}).get(FLAG, {}).get("stay_sec", 20)), 1.0)
	var fraction := clampf(1.0 - _bubble_age / stay, 0.0, 1.0)
	if fraction > 0.0:
		var track := Rect2(BOARD_PAD, rect.end.y - 6.0, rect.size.x - BOARD_PAD * 2.0, 2.0)
		_bubble_face.draw_rect(track, Color(1, 1, 1, 0.18))
		_bubble_face.draw_rect(Rect2(track.position, Vector2(track.size.x * fraction, track.size.y)), Color("57dc8a"))


func _on_bubble_gui_input(event: InputEvent) -> void:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_bubble_down = event.position
		_bubble_dragging = false
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 or event is InputEventScreenDrag:
		# Vuốt bắt đầu trên bong bóng: huỷ chạm và xoay bản đồ (Design/26 §4.3).
		if not _bubble_dragging and event.position.distance_to(_bubble_down) > BUBBLE_DRAG_PX:
			_bubble_dragging = true
		if _bubble_dragging and _bubble_rv != null:
			_bubble_rv.rotate_circuit_view(event.relative.x)


func _on_bubble_pressed() -> void:
	if _bubble_dragging:
		_bubble_dragging = false
		return
	if not _bubble_on or _bubble_tapped:
		return
	_bubble_tapped = true
	_start_bubble_break()
	_on_flag_pressed()


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
	_watch.text = I18n.t("ads.watch_ad")
	_multiplier.visible = pl == BOOST
	_duration.visible = pl == BOOST
	_separator.visible = pl == BOOST
	_ticket_background.visible = pl == BOOST
	_cash_background.visible = pl == FLAG
	_cash_glow.visible = pl == FLAG
	_boost_details.visible = pl == BOOST
	_reward_burst.visible = pl == BOOST
	_cash_amount.visible = pl == FLAG
	_cash_caption.visible = pl == FLAG
	var is_boost := pl == BOOST
	_title.add_theme_color_override("font_color", HdUi.C_TEXT)
	_title.add_theme_font_size_override("font_size", 24 if is_boost else 18)
	_body.add_theme_color_override("font_color", HdUi.C_NAVY)
	_status.add_theme_color_override("font_color", Color("a32d2d"))
	_later.add_theme_color_override("font_color", HdUi.C_MUTED)
	_later.add_theme_color_override("font_hover_color", HdUi.C_NAVY)
	var hero_skin := _cash_glow.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	hero_skin.bg_color = Color("1b4067") if is_boost else Color("e5f5d9")
	hero_skin.set_corner_radius_all(24 if is_boost else 72)
	_cash_glow.add_theme_stylebox_override("panel", hero_skin)
	HdUi.style_button(_watch, "race")
	_cash_art.texture = load("res://assets/ads_income_boost/cash_bundles.png") if is_boost else CleanArt.asset("res://assets/racing_ui_hd/icons/cash.png")
	if is_boost:
		_multiplier.add_theme_font_size_override("font_size", 56)
		_multiplier.add_theme_color_override("font_color", HdUi.C_BLUE)
		_multiplier.add_theme_constant_override("outline_size", 0)
		var badge := StyleBoxFlat.new()
		badge.bg_color = HdUi.C_PANEL
		badge.border_color = HdUi.C_PANEL_HI
		badge.set_border_width_all(3)
		badge.set_corner_radius_all(18)
		badge.shadow_color = Color(0.01, 0.04, 0.10, 0.5)
		badge.shadow_size = 5
		badge.shadow_offset = Vector2(0, 5)
		_multiplier.add_theme_stylebox_override("normal", badge)
	if pl == BOOST:
		_title.text = I18n.t("ads.income_x") % int(amount["multiplier"])
		_multiplier.text = "×%d" % int(amount["multiplier"])
		_duration.text = I18n.t("ads.min") % (int(amount["seconds"]) / 60)
		var action := I18n.t("ads.double") if int(amount["multiplier"]) == 2 else I18n.t("ads.multiply_by") % int(amount["multiplier"])
		_body.text = I18n.t("ads.watch_ad_cash_income") % action
		_later.text = I18n.t("ads.later")
	else:
		_title.text = I18n.t("ads.cash_gift")
		_cash_amount.text = "+" + Balance.fmt_money(amount)
		_body.text = I18n.t("ads.watch_whole_video_get_reward")
		_watch.text = I18n.t("ads.watch_video_get_cash")
		_later.text = I18n.t("common.close")
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
		_status.text = I18n.t("ads.could_not_save_reward_try")
		_watch.text = I18n.t("common.try_claiming_again")
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
