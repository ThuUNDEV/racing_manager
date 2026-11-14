class_name DriverRosterPage
extends VBoxContainer
const CleanArt = preload("res://ui/clean_modern_art.gd")
## Đội → Tay đua (Design/Mockups/driver_roster_v2.html): thanh SP, tay đua đang dùng, lọc, lưới hai cột
## và bảng chi tiết kiểu bottom sheet có radar so sánh. Trang chỉ đọc GameState và gọi recruit/select.
## `sheet` do main gắn vào vùng nội dung (dưới khung đua) để bảng không che cuộc đua.

signal sfx(cue: String)
signal notice(msg: String)
signal open_requested(pack_id: String, count: int)
signal info_requested(pack_id: String)
## Lối tắt sang Shop (mục Mở gói tay đua).
signal shop_requested

const ROOT := "res://assets/workshop_gp/"
const C_BG := Color("f1f7fc")
const C_CARD := Color("eaf2ff")
const C_LINE := Color("adc9de")
const C_INK := Color("12294d")
const C_TEXT := Color("23394a")
const C_MUTED := Color("768ca0")
const C_ORANGE := Color("f2790a")
const C_ORANGE_D := Color("087ee6")
const C_GOLD := Color("b27300")
const C_GOOD := Color("15803d")
const C_BAD := Color("c62828")
const STAT_MAX := 70.0

const STATS := [
	["launch", "drivers.launch"], ["pace", "common.pace"], ["braking", "drivers.braking"], ["technique", "drivers.cornering"],
	["racecraft", "drivers.racecraft"], ["composure", "drivers.composure"], ["endurance", "drivers.endurance"],
]
const TRAITS := {
	"": "drivers.no_trait",
	"fast_start": "drivers.fast_start_plus_25_acceleration",
	"smooth_corners": "drivers.smooth_corners_plus_1_5",
	"calm": "drivers.calm_mistakes_last_30_shorter",
	"sprint": "drivers.sprint_plus_1_speed_final",
	"hunter": "drivers.hunter_easier_overtake_when_tailgating",
	"defender": "drivers.defender_harder_overtake",
	"straight_line": "drivers.straight_line_plus_1_5",
	"steady": "drivers.steady_15_lower_chance_mistakes",
	"recovery": "drivers.recovery_plus_30_acceleration_3",
	"golden": "drivers.golden_form_form_never_drops",
	"discipline": "drivers.discipline_no_mistakes_first_lap",
}
const COLORS := {
	"driver_an": "ed742b", "driver_binh": "2c8c84", "driver_chi": "c8432f", "driver_dung": "5b6c8f",
	"driver_ha": "9a5cb8", "driver_khoi": "2e8fd8", "driver_lam": "7a8b3a", "driver_my": "d1507a",
	"driver_nhan": "3f7f9e", "driver_phuong": "b8862b", "driver_quang": "a8402a", "driver_son": "4e5a64",
}

var sheet: Control            # main gắn vào _pages_root
var _viewed: String = ""
var _sig: String = ""
var _sheet_sig: String = ""
var _built: bool = false
var _sheet_box: VBoxContainer


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	_build_sheet_shell()


func _ready() -> void:
	refresh()


# ---------------------------------------------------------------- trạng thái

func _blocked() -> bool:
	return GameState.save_blocked or GameState.phase == "save_error"


func _status(d: Dictionary) -> String:
	var id := String(d["id"])
	if id == GameState.active_driver_id:
		return "active"
	if id in GameState.owned_drivers:
		return "owned"
	if GameState.driver_unlocked(id):
		return "avail"
	return "lock"


func _next_sp() -> int:
	return Pricing.scout_sp_cost(GameState.recruit_index())


func _all_owned() -> bool:
	return GameState.owned_drivers.size() >= GameData.drivers().size()


func _unlock_text(d: Dictionary) -> String:
	var u: Dictionary = d["unlock"]
	var parts := PackedStringArray()
	if String(u.get("type", "")) == "races" and int(u.get("count", 0)) > GameState.completed_races:
		parts.append(I18n.tn("drivers.finish_races", int(u["count"])) % int(u["count"]))
	if int(u.get("league", 0)) > GameState.business_tier:
		parts.append(I18n.t("drivers.unlock_league") % Balance.league_name(int(u["league"])))
	return " · ".join(parts)


func _style_name(d: Dictionary) -> String:
	return String((GameData.sim().get("styles", {}) as Dictionary).get(String(d["style"]), {}).get("name", ""))


## Chỉ số hiệu lực = chỉ số gốc + thưởng level (0 khi chưa nâng).
func _stat(d: Dictionary, key: String) -> int:
	return int(d[key]) + roundi(GameState.driver_level_bonus(String(d["id"])))


func _total(d: Dictionary) -> int:
	var t := 0
	for s: Array in STATS:
		t += _stat(d, s[0])
	return t


func _best_stat(d: Dictionary) -> String:
	var best: Array = STATS[0]
	for s: Array in STATS:
		if _stat(d, s[0]) > _stat(d, best[0]):
			best = s
	return I18n.t(String(best[1]))


## Gọi từ main khi dữ liệu đổi và theo nhịp ngắn: chỉ dựng lại khi thứ đang hiển thị thật sự đổi.
func refresh() -> void:
	var sig := _signature(false)
	if not _built or sig != _sig:
		_sig = sig
		_built = true
		_rebuild()
	if sheet != null and sheet.visible:
		var ssig := _signature(true)
		if ssig != _sheet_sig:
			_rebuild_sheet()


func _signature(with_view: bool) -> String:
	var parts: Array = [GameState.active_driver_id, GameState.scout_points, GameState.phase, GameState.save_blocked,
		GameState.business_tier, GameState.completed_races, GameState.owned_drivers.size(), GameState.gems,
		GameState.driver_coupons.duplicate(), GameState.driver_pity.duplicate()]
	if with_view:
		parts.append(_viewed)
	for id: String in GameState.owned_drivers:
		parts.append([id, GameState.driver_level(id), GameState.driver_shards(id)])
	# Khả năng chi trả đổi theo thu nhập: chỉ đưa vào chữ ký trạng thái đủ/thiếu tiền của từng người chưa tuyển.
	for d: Dictionary in GameData.drivers():
		var id := String(d["id"])
		if not id in GameState.owned_drivers and (not with_view or id == _viewed):
			parts.append(GameState.coins.compare(Pricing.scout_coin_cost(id)) >= 0)
	return str(parts)


func close_sheet() -> void:
	if sheet != null:
		sheet.hide()
	_viewed = ""


# ---------------------------------------------------------------- tiện ích dựng

func _sb(bg: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, radius: int = 14, margin: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s


func _label(text: String, size: int = 14, color: Color = C_TEXT, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _fit_name(text: String, size: int, max_w: float, min_size: int = 10) -> Label:
	# Tên luôn 1 dòng, co cỡ chữ cho vừa bề rộng → chiều cao thẻ không đổi, 2 thẻ so sánh vẫn cân.
	var l := _label(text, size, C_TEXT)
	var font := ThemeDB.fallback_font
	var fs := size
	while fs > min_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
		fs -= 1
	l.add_theme_font_size_override("font_size", fs)
	l.clip_text = true
	l.custom_minimum_size = Vector2(0, ceil(font.get_height(size)))
	return l


func _panel(style: StyleBox) -> PanelContainer:
	var p := PanelContainer.new()
	if style is StyleBoxFlat:
		var skin := HdUi.card_style("pass" if style.border_color == C_ORANGE else "card").duplicate() as StyleBoxTexture
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			skin.set_content_margin(side, style.get_content_margin(side))
		p.add_theme_stylebox_override("panel", skin)
	else:
		p.add_theme_stylebox_override("panel", style)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


func _flat_button(text: String, bg: Color, fg: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, h: float = 44.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, h)
	b.add_theme_font_size_override("font_size", 14)
	for st: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, _sb(bg, border, bw, 12, 8))
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(c, fg)
	HdUi.style_button(b, "cancel" if bg.a == 0.0 or bg == Color("e1e8f4") else "race" if bg == C_ORANGE else "upgrade")
	b.pressed.connect(func() -> void: sfx.emit("ui_click"))
	return b


func _portrait(id: String, ext: Vector2) -> Control:
	if ExpansionArt.texture(id) != null:
		return ExpansionArt.icon(id, ext)
	var path := ROOT + "portraits/" + id + ".tres"
	if ResourceLoader.exists(path):
		var t := TextureRect.new()
		t.texture = CleanArt.asset(path) as Texture2D
		t.custom_minimum_size = ext
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return t
	# Chưa có chân dung riêng: ô màu + chữ cái đầu, không mượn ảnh của người khác.
	var p := PanelContainer.new()
	p.custom_minimum_size = ext
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _sb(Color(String(COLORS.get(id, "4e5a64"))), Color(0, 0, 0, 0), 0, 14, 0))
	var l := _label(String(GameData.driver(id)["name"]).substr(0, 1), int(ext.y * 0.45), Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


func _state_text(s: String) -> String:
	return {"active": I18n.t("common.use"), "owned": I18n.t("common.owned"), "avail": I18n.t("drivers.can_recruit_2"), "lock": I18n.t("common.locked")}[s]


func _state_color(s: String) -> Color:
	return {"active": C_ORANGE_D, "owned": C_GOOD, "avail": C_GOLD, "lock": C_MUTED}[s]


func _ignore_mouse(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore_mouse(c)


# ---------------------------------------------------------------- trang chính

const TIER_NAMES := ["common.rookie", "drivers.tier_pro", "drivers.tier_elite", "drivers.tier_legend"]
const TIER_COLORS := ["776d61", "2e6fd8", "8a3fd1", "b8862b"]


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var team: Array = []
	var avail: Array = []
	var locked: Array = []
	for d: Dictionary in GameData.drivers():
		match _status(d):
			"active":
				team.push_front(d)
			"owned":
				team.append(d)
			"avail":
				avail.append(d)
			_:
				locked.append(d)
	var active := GameData.driver(GameState.active_driver_id)
	_build_shop_shortcut()
	for d: Dictionary in team:
		add_child(_driver_row(d, _status(d)))
	_build_section(I18n.t("drivers.can_recruit"), avail, "", C_MUTED)
	_build_section(I18n.t("drivers.locked"), locked, "", C_MUTED)
	_build_sp_card()


func _build_shop_shortcut() -> void:
	var coupons := 0
	for k: String in GameState.driver_coupons:
		coupons += int(GameState.driver_coupons[k])
	var card := _panel(_sb(C_CARD, C_ORANGE if coupons > 0 else C_LINE, 2 if coupons > 0 else 1, 14, 8))
	card.name = "ShopShortcut"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	row.add_child(ExpansionArt.icon("standard_driver_pack", Vector2(40, 40)))
	var info := _label(I18n.t("shop.shortcut_driver") % coupons, 13, C_TEXT, true)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	var go := Button.new()
	go.name = "OpenPacksInShop"
	go.text = I18n.t("shop.shortcut_button")
	go.custom_minimum_size = Vector2(96, 40)
	go.add_theme_font_size_override("font_size", 13)
	HdUi.style_button(go, "upgrade")
	go.pressed.connect(func() -> void: shop_requested.emit())
	row.add_child(go)
	add_child(card)


func _build_sp_card() -> void:
	var p := _panel(_sb(C_CARD, C_LINE, 1, 16))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var sp := _label("%d SP" % GameState.scout_points, 22, C_ORANGE_D)
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var count := _label(I18n.t("drivers.recruited") % [GameState.owned_drivers.size(), GameData.drivers().size()], 12, C_MUTED)
	count.size_flags_vertical = Control.SIZE_SHRINK_END
	top.add_child(count)
	var note: String
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.add_theme_stylebox_override("background", _sb(Color("c3d6f2"), Color(0, 0, 0, 0), 0, 6, 0))
	bar.add_theme_stylebox_override("fill", _sb(C_ORANGE, Color(0, 0, 0, 0), 0, 6, 0))
	bar.max_value = 1.0
	if _all_owned():
		bar.value = 1.0
		note = I18n.t("drivers.you_have_recruited_every_driver")
	else:
		var need := _next_sp()
		bar.value = minf(1.0, float(GameState.scout_points) / float(maxi(need, 1)))
		var tail := I18n.t("drivers.each_race_earns_about_5")
		if GameState.scout_points >= need:
			note = I18n.t("drivers.next_recruit_costs_sp_enough") % [need, GameState.scout_points / need, tail]
		else:
			note = I18n.t("drivers.next_recruit_costs_sp_sp") % [need, need - GameState.scout_points, tail]
	v.add_child(bar)
	v.add_child(_label(note, 12, C_MUTED, true))
	add_child(p)


func _build_section(title: String, list: Array, right: String, right_color: Color) -> void:
	if list.is_empty():
		return
	var h := HBoxContainer.new()
	var t := _label("%s (%d)" % [title, list.size()], 13, C_MUTED)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	if right != "":
		h.add_child(_label(right, 11, right_color))
	add_child(h)
	for d: Dictionary in list:
		add_child(_driver_row(d, _status(d)))


## Hàng gọn: vòng điểm sức mạnh (tổng 7 chỉ số) · tên + bậc · phong cách · hai chỉ số nổi bật · nút hành động.
func _driver_row(d: Dictionary, s: String) -> Control:
	var id := String(d["id"])
	var tier := clampi(int(d["tier"]), 0, TIER_NAMES.size() - 1)
	var tcol := Color(String(TIER_COLORS[tier]))
	var border := C_ORANGE if s == "active" else C_LINE
	var card := _panel(_sb(C_CARD if s != "lock" else Color("e3e9f4"), border, 2 if s == "active" else 1, 16, 6))
	card.add_theme_stylebox_override("panel", _sb(Color("fff4e8") if s == "active" else Color("edf5fc"), Color("e3a96e") if s == "active" else C_LINE, 1, 14, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)

	var open := Button.new()
	open.custom_minimum_size = Vector2(0, 72)
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open.accessibility_name = I18n.t("drivers.view_details") % String(d["name"])
	for st: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		open.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	open.pressed.connect(func() -> void:
		sfx.emit("ui_click")
		_open_sheet(id))
	row.add_child(open)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 4)
	open.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	m.add_child(h)

	var portrait := _portrait(id, Vector2(44, 52))
	portrait.modulate.a = 0.5 if s == "lock" else 1.0
	h.add_child(portrait)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	var l1 := HBoxContainer.new()
	l1.add_theme_constant_override("separation", 6)
	l1.add_child(_fit_name(String(d["name"]), 16, 104.0))
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _sb(tcol.lightened(0.8), tcol.lightened(0.45), 1, 8, 2))
	var cl := _label(I18n.t(String(TIER_NAMES[tier])), 11, tcol)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(cl)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l1.add_child(chip)
	if s == "owned":
		var lv := _label("Lv.%d" % GameState.driver_level(id), 11, C_MUTED)
		lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		l1.add_child(lv)
	v.add_child(l1)
	v.add_child(_label(_style_name(d), 11, C_MUTED))
	v.add_child(_row_line(d, s))
	_ignore_mouse(m)

	var act: Button
	match s:
		"active":
			act = _flat_button(I18n.t("common.use"), Color("ffe8cf"), C_ORANGE_D, C_ORANGE, 1, 44.0)
			act.disabled = true
		"owned":
			act = _flat_button(I18n.t("drivers.select"), C_INK, Color.WHITE, C_INK, 1, 44.0)
			act.disabled = _blocked()
			act.pressed.connect(_select.bind(id))
		"avail":
			act = _flat_button(I18n.t("drivers.recruit"), C_ORANGE, Color.WHITE, C_ORANGE_D, 1, 44.0)
			act.icon = preload("res://assets/clean_modern/icons/recruit_person.svg")
			act.add_theme_constant_override("icon_max_width", 16)
			act.add_theme_constant_override("h_separation", 4)
			act.pressed.connect(_open_sheet.bind(id))
		_:
			act = _flat_button(I18n.t("common.locked"), Color("e1e8f4"), C_MUTED, C_LINE, 1, 44.0)
			act.pressed.connect(_open_sheet.bind(id))
	act.custom_minimum_size = Vector2(82, 44)
	# Keep recruit and locked actions on the same nine-patch geometry.
	if s in ["avail", "lock"]:
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			if s == "avail" and state != "disabled":
				continue
			var skin := HdUi.button("race", "normal" if state == "disabled" else state).duplicate() as StyleBoxTexture
			skin.texture = preload("res://assets/clean_modern/icons/button_raised_locked.svg")
			skin.remove_meta("rounded_button")
			act.add_theme_stylebox_override(state, HdUi.ButtonSkin.rounded(skin))
	act.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	act.add_theme_font_size_override("font_size", 13)
	HdUi.text_depth(act, s in ["owned", "avail"] and not act.disabled)
	row.add_child(act)
	return card


## Dòng thứ ba: hai chỉ số cao nhất (người đã có) · chi phí tuyển · điều kiện mở.
func _row_line(d: Dictionary, s: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	match s:
		"avail":
			var price := Pricing.scout_coin_cost(String(d["id"]))
			var ok := GameState.coins.compare(price) >= 0 and GameState.scout_points >= _next_sp()
			h.add_child(_label(I18n.t("drivers.cash_sp") % [price.format_compact(), _next_sp()], 12, C_GOOD if ok else C_BAD))
		"lock":
			var l := _label(_unlock_text(d), 12, C_MUTED)
			l.clip_text = true
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(l)
		_:
			var ranked: Array = STATS.duplicate()
			ranked.sort_custom(func(a: Array, b: Array) -> bool: return _stat(d, a[0]) > _stat(d, b[0]))
			var stats := _label("%s %d · %s %d" % [I18n.t(ranked[0][1]), _stat(d, ranked[0][0]), I18n.t(ranked[1][1]), _stat(d, ranked[1][0])], 11, C_ORANGE_D, true)
			return stats
	return h


# ---------------------------------------------------------------- bảng chi tiết (bottom sheet)

func _build_sheet_shell() -> void:
	sheet = Control.new()
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet.hide()
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.1, 0.07, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			close_sheet())
	sheet.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_top", 28)
	sheet.add_child(margin)
	var pc := PanelContainer.new()
	var st := _sb(C_BG, C_LINE, 1, 22, 14)
	st.corner_radius_bottom_left = 0
	st.corner_radius_bottom_right = 0
	pc.add_theme_stylebox_override("panel", st)
	margin.add_child(pc)
	var sc := preload("res://ui/touch_scroll.gd").new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(sc)
	_sheet_box = VBoxContainer.new()
	_sheet_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sheet_box.add_theme_constant_override("separation", 8)
	sc.add_child(_sheet_box)


func _open_sheet(id: String) -> void:
	_viewed = id
	sheet.show()
	_rebuild_sheet()


func _rebuild_sheet() -> void:
	_sheet_sig = _signature(true)
	for c in _sheet_box.get_children():
		_sheet_box.remove_child(c)
		c.queue_free()
	var d := GameData.driver(_viewed)
	if d.is_empty():
		close_sheet()
		return
	var act := GameData.driver(GameState.active_driver_id)
	var s := _status(d)
	var cmp := s != "active"

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(_portrait(_viewed, Vector2(60, 60)))
	head.add_child(ExpansionArt.icon(String(d.get("style", "counter")), Vector2(32, 32)))
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_theme_constant_override("separation", 0)
	hv.add_child(_fit_name(String(d["name"]), 20, 150.0, 13))
	hv.add_child(_label(_style_name(d), 12, C_MUTED))
	hv.add_child(_label(_state_text(s), 12, _state_color(s)))
	head.add_child(hv)
	var x := HdUi.close_button(close_sheet, "DriverDetailClose")
	head.add_child(x)
	_sheet_box.add_child(head)

	var note := I18n.t("drivers.compared_with_current_driver") % String(act["name"]) if cmp else I18n.t("drivers.current_driver_stats")
	_sheet_box.add_child(_label(note, 12, C_MUTED, true))
	var radar := RadarChart.new()
	radar.a = _values(d)
	radar.b = _values(act) if cmp else []
	radar.custom_minimum_size = Vector2(0, 230)
	_sheet_box.add_child(radar)
	if cmp:
		var lg := HBoxContainer.new()
		lg.alignment = BoxContainer.ALIGNMENT_CENTER
		lg.add_theme_constant_override("separation", 16)
		lg.add_child(_label("■ %s" % String(d["name"]), 12, C_ORANGE))
		lg.add_child(_label(I18n.t("drivers.dashed_line") % String(act["name"]), 12, C_INK))
		_sheet_box.add_child(lg)

	for st: Array in STATS:
		_sheet_box.add_child(_stat_row(I18n.t(String(st[1])), _stat(d, st[0]), _stat(act, st[0]), cmp))
	var tot := _total(d)
	var tot_txt := I18n.t("drivers.total_stats") % tot
	if cmp:
		var dt := tot - _total(act)
		tot_txt += " (%s%d)" % ["+" if dt >= 0 else "−", absi(dt)]
	var tp := _panel(_sb(Color("e2f2ef"), Color("b7ddd8"), 1, 12, 10))
	tp.add_child(_label(I18n.t("drivers.trait") % [I18n.t(String(TRAITS.get(String(d["trait"]), TRAITS[""]))), tot_txt], 12, Color("1e5f59"), true))
	_sheet_box.add_child(tp)

	if s == "active" or s == "owned":
		_sheet_box.add_child(_level_panel(_viewed))

	var cta := Button.new()
	cta.custom_minimum_size = Vector2(0, 52)
	cta.add_theme_font_size_override("font_size", 16)
	var hint := ""
	match s:
		"avail":
			var price := Pricing.scout_coin_cost(_viewed)
			var need_sp := _next_sp()
			var ok_c := GameState.coins.compare(price) >= 0
			var ok_s := GameState.scout_points >= need_sp
			var req := _panel(_sb(C_CARD, C_LINE, 1, 14, 10))
			var rv := VBoxContainer.new()
			rv.add_theme_constant_override("separation", 4)
			req.add_child(rv)
			var coin_txt := I18n.t("drivers.you_have") % [price.format_compact(), GameState.coins.format_compact()]
			if not ok_c:
				coin_txt += I18n.t("drivers.short_2") % price.subtract_checked(GameState.coins).format_compact()
			rv.add_child(_req_row(I18n.t("common.cash"), coin_txt, ok_c))
			var sp_txt := I18n.t("drivers.sp_you_have") % [need_sp, GameState.scout_points]
			if not ok_s:
				sp_txt += I18n.t("drivers.short") % (need_sp - GameState.scout_points)
			rv.add_child(_req_row(I18n.t("drivers.recruit_points"), sp_txt, ok_s))
			_sheet_box.add_child(req)
			cta.text = I18n.t("drivers.recruit_2") % String(d["name"])
			HdUi.style_button(cta, "race")
			cta.icon = preload("res://assets/clean_modern/icons/recruit_person.svg")
			cta.add_theme_constant_override("icon_max_width", 18)
			cta.disabled = not (ok_c and ok_s) or _blocked()
			cta.pressed.connect(_recruit.bind(_viewed))
			hint = I18n.t("drivers.recruiting_not_pick_not_random")
		"lock":
			var req2 := _panel(_sb(C_CARD, C_LINE, 1, 14, 10))
			req2.add_child(_req_row(I18n.t("drivers.unlock_requirement"), _unlock_text(d), false))
			_sheet_box.add_child(req2)
			cta.text = I18n.t("drivers.cannot_recruit_yet")
			cta.disabled = true
			hint = I18n.t("drivers.you_can_still_view_stats")
		"owned":
			cta.text = I18n.t("drivers.select_next_race") % String(d["name"])
			cta.disabled = _blocked()
			cta.pressed.connect(_select.bind(_viewed))
			hint = I18n.t("drivers.applies_from_next_race_current")
		_:
			cta.text = I18n.t("common.use")
			cta.disabled = true
	_sheet_box.add_child(cta)
	if hint != "":
		var hl := _label(hint, 12, C_MUTED, true)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_sheet_box.add_child(hl)


## Cấp độ của tay đua: sao/Lv, thanh mảnh riêng, nút Nâng cấp khi đủ mảnh. Thưởng level cộng vào mọi chỉ số.
func _level_panel(id: String) -> Control:
	var p := _panel(_sb(C_CARD, C_LINE, 1, 14, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var lv := GameState.driver_level(id)
	var mx := GameState.driver_max_level(id)
	var bonus := roundi(GameState.driver_level_bonus(id))
	v.add_child(_label(I18n.t("drivers.level_plus_all_stats") % [lv, mx, bonus], 13))
	var need := GameState.driver_upgrade_cost(id)
	if need < 0:
		v.add_child(_label(I18n.t("common.max_level"), 12, C_MUTED))
		return p
	var shards := GameState.driver_shards(id)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = need
	bar.value = mini(shards, need)
	bar.custom_minimum_size = Vector2(0, 8)
	bar.add_theme_stylebox_override("background", _sb(Color("c3d6f2"), Color(0, 0, 0, 0), 0, 5, 0))
	bar.add_theme_stylebox_override("fill", _sb(C_ORANGE, Color(0, 0, 0, 0), 0, 5, 0))
	v.add_child(bar)
	v.add_child(_label(I18n.t("drivers.shards_duplicate_drivers_from_packs") % [shards, need], 12, C_MUTED, true))
	if shards >= need:
		var up := _flat_button(I18n.t("common.upgrade"), C_ORANGE, Color.WHITE, C_ORANGE_D, 1, 44.0)
		up.disabled = _blocked()
		up.pressed.connect(_upgrade.bind(id))
		v.add_child(up)
	return p


func _upgrade(id: String) -> void:
	if GameState.upgrade_driver(id):
		sfx.emit("ui_click")
		notice.emit(I18n.t("drivers.upgraded") % String(GameData.driver(id)["name"]))
	else:
		notice.emit(I18n.t("common.not_enough_shards_or_save"))
	_sig = ""
	refresh()
	if sheet.visible:
		_rebuild_sheet()


func _values(d: Dictionary) -> Array:
	var out: Array = []
	for s: Array in STATS:
		out.append(float(_stat(d, s[0])))
	return out


func _req_row(left: String, right: String, ok: bool) -> Control:
	var h := HBoxContainer.new()
	h.add_child(_label(left, 13))
	var r := _label(right, 13, C_GOOD if ok else C_BAD, true)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(r)
	return h


func _stat_row(label: String, value: int, ref: int, cmp: bool) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := _label(label, 12)
	l.custom_minimum_size = Vector2(72, 0)
	h.add_child(l)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = STAT_MAX
	bar.value = value
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(0, 8)
	bar.add_theme_stylebox_override("background", _sb(Color("c3d6f2"), Color(0, 0, 0, 0), 0, 5, 0))
	bar.add_theme_stylebox_override("fill", _sb(C_ORANGE, Color(0, 0, 0, 0), 0, 5, 0))
	h.add_child(bar)
	var v := _label(str(value), 12)
	v.custom_minimum_size = Vector2(26, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	var dl := _label("", 12)
	dl.custom_minimum_size = Vector2(36, 0)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if cmp:
		var diff := value - ref
		dl.text = "=" if diff == 0 else "%s%d" % ["+" if diff > 0 else "−", absi(diff)]
		dl.add_theme_color_override("font_color", C_MUTED if diff == 0 else (C_GOOD if diff > 0 else C_BAD))
	h.add_child(dl)
	return h


func _recruit(id: String) -> void:
	var dname := String(GameData.driver(id)["name"])
	if GameState.recruit_driver(id):
		notice.emit(I18n.t("drivers.recruited_tap_select_use_them") % dname)
	else:
		notice.emit(I18n.t("drivers.could_not_recruit") % dname)
	_sig = ""
	refresh()
	if sheet.visible:
		_rebuild_sheet()


func _select(id: String) -> void:
	var dname := String(GameData.driver(id)["name"])
	if GameState.select_driver(id):
		notice.emit(I18n.t("drivers.will_race_from_next_race") % dname)
		close_sheet()
	else:
		notice.emit(I18n.t("drivers.could_not_select") % dname)
	_sig = ""
	refresh()


# ---------------------------------------------------------------- radar

## Biểu đồ mạng nhện 7 chỉ số: `a` tô cam, `b` (nếu có) vẽ nét đứt đen để so sánh.
class RadarChart extends Control:
	const LABELS := ["drivers.launch", "common.pace", "drivers.braking", "drivers.cornering", "drivers.racecraft", "drivers.composure", "drivers.endurance"]
	var a: Array = []
	var b: Array = []

	func _draw() -> void:
		var n := LABELS.size()
		var c := size * 0.5
		var r := minf(size.x * 0.5 - 48.0, size.y * 0.5 - 20.0)
		if r <= 10.0:
			return
		for f in [0.25, 0.5, 0.75, 1.0]:
			var ring := PackedVector2Array()
			for i in n:
				ring.append(_pt(c, r * f, i, n))
			ring.append(ring[0])
			draw_polyline(ring, Color("adc9de"), 1.0)
		var font := get_theme_default_font()
		for i in n:
			draw_line(c, _pt(c, r, i, n), Color("c3d6f2"), 1.0)
			var lp := _pt(c, r + 18.0, i, n)
			var w := font.get_string_size(I18n.t(LABELS[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(font, lp + Vector2(-w * 0.5, 4), I18n.t(LABELS[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("768ca0"))
		if a.size() == n:
			var pts := _poly(c, r, a, n)
			draw_colored_polygon(pts, Color(0.93, 0.45, 0.17, 0.28))
			draw_polyline(pts, Color("f2790a"), 2.0)
		if b.size() == n:
			var pb := _poly(c, r, b, n)
			for i in pb.size() - 1:
				_dash(pb[i], pb[i + 1])

	func _poly(c: Vector2, r: float, vals: Array, n: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in n:
			pts.append(_pt(c, r * clampf(float(vals[i]) / 70.0, 0.0, 1.0), i, n))
		pts.append(pts[0])
		return pts

	func _pt(c: Vector2, rad: float, i: int, n: int) -> Vector2:
		var ang := -PI * 0.5 + TAU * float(i) / float(n)
		return c + Vector2(cos(ang), sin(ang)) * rad

	func _dash(p: Vector2, q: Vector2) -> void:
		var seg := p.distance_to(q)
		var dir := (q - p) / maxf(seg, 0.001)
		var t := 0.0
		while t < seg:
			draw_line(p + dir * t, p + dir * minf(t + 5.0, seg), Color("12294d"), 2.0)
			t += 9.0
