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
const C_BG := Color("fff8ee")
const C_CARD := Color("fffdf7")
const C_LINE := Color("d8e2df")
const C_INK := Color("0e2b5c")
const C_TEXT := Color("0e2b5c")
const C_MUTED := Color("5f7391")
const C_ORANGE := Color("f2790a")
const C_ORANGE_D := Color("62b8e5")
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
	var summary := _panel(HdUi.panel())
	summary.name = "TeamSummary"
	var summary_box := VBoxContainer.new()
	var summary_row := HBoxContainer.new()
	summary.add_child(summary_row)
	summary_row.add_child(HdUi.Soft.art("speedometer", Vector2(61, 61)))
	summary_row.add_child(summary_box)
	summary_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(HdUi.Soft.art("helmet_pit", Vector2(72, 61)))
	summary_box.add_theme_constant_override("separation", 0)
	summary_box.add_child(_label(I18n.t("soft.team_power"), 15, C_TEXT, true))
	summary_box.add_child(_label(RaceView.format_team_power(GameState.team_power()), 24, Color("b64d12")))
	summary_box.add_child(_label(String(active["name"]) + " · Lv.%d" % GameState.driver_level(GameState.active_driver_id), 12, C_MUTED))
	add_child(summary)
	_build_shop_shortcut()
	var grid := GridContainer.new()
	grid.name = "DriverGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)
	for d: Dictionary in team + avail:
		grid.add_child(_driver_row(d, _status(d)))


func _build_shop_shortcut() -> void:
	var coupons := 0
	for k: String in GameState.driver_coupons:
		coupons += int(GameState.driver_coupons[k])
	# Dải xanh theo demo: cờ + tiêu đề, nút "Mở gói" nằm bên phải.
	var card := PanelContainer.new()
	card.name = "ShopShortcut"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", HdUi.Soft.surface("section", Vector4(8, 3, 6, 5)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	row.add_child(HdUi.Soft.art("nav_race", Vector2(40, 32)))
	var info := _label("Danh sách tay đua" if I18n.lang() == "vi" else I18n.t("shop.shortcut_driver") % coupons, 20, C_TEXT)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.clip_text = true
	info.add_theme_font_override("font", HdUi.font())
	info.resized.connect(HdUi.fit_font.bind(info, 20, 13))
	row.add_child(info)
	var go := Button.new()
	go.name = "OpenPacksInShop"
	go.text = I18n.t("shop.shortcut_button")
	go.custom_minimum_size = Vector2(96, 34)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	go.add_theme_font_size_override("font_size", 14)
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
func _driver_row(d: Dictionary, state: String) -> Control:
	var id := String(d["id"])
	var card: PanelContainer
	if state == "active":
		# Thẻ đang dùng: khung vàng bóng như demo.
		card = PanelContainer.new()
		var gold := _sb(C_CARD, Color("f6b81c"), 4, 18, 9)
		gold.shadow_color = Color(1.0, 0.75, 0.1, 0.45)
		gold.shadow_size = 6
		card.add_theme_stylebox_override("panel", gold)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		card = _panel(HdUi.Soft.surface("panel", Vector4(10, 9, 10, 10)))
	card.name = "Driver_" + id
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 4)
	col.add_child(title_row)
	var title := _label(String(d["name"]), 18, C_TEXT)
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var details := Button.new()
	details.name = "DriverDetails_" + id
	details.text = "i"
	details.custom_minimum_size = Vector2(30, 30)
	details.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	details.add_theme_font_size_override("font_size", 16)
	var info_bg := _sb(C_ORANGE_D, Color.WHITE, 2, 15, 0)
	for st: String in ["normal", "hover", "pressed", "focus"]:
		details.add_theme_stylebox_override(st, info_bg)
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		details.add_theme_color_override(c, Color.WHITE)
	details.pressed.connect(_open_sheet.bind(id))
	title_row.add_child(details)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 5)
	col.add_child(status_row)
	if state == "active":
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.add_theme_stylebox_override("panel", _sb(C_GOOD, Color.WHITE, 1, 5, 0))
		status_row.add_child(dot)
	elif state == "lock":
		var lock := TextureRect.new()
		lock.texture = CleanArt.asset(ROOT + "icons/vector/lock.svg") as Texture2D
		lock.custom_minimum_size = Vector2(14, 14)
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lock.modulate = C_MUTED
		status_row.add_child(lock)
	var status_color: Color = C_GOOD if state == "active" else C_MUTED
	var status := _label(_state_text(state) + (" · Lv.%d" % GameState.driver_level(id) if state in ["active", "owned"] else ""), 13, status_color)
	status.clip_text = true
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(status)
	col.add_child(_tier_chip(d))
	# Ảnh đặt trong khung bo góc nền xanh nhạt (khoá: xám xanh).
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _sb(Color("d3e9f8") if state != "lock" else Color("dfe4ec"), Color(1, 1, 1, 0.8), 2, 14, 0))
	frame.clip_contents = true
	var portrait := _portrait(id, Vector2(0, 132))
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait.modulate.a = 0.85 if state == "lock" else 1.0
	frame.add_child(portrait)
	col.add_child(frame)
	var stat_pill := HdUi.Soft.pill("SP %d" % _total(d), Color("b6e4f7"), 16)
	stat_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_child(stat_pill)
	if state in ["active", "owned"]:
		col.add_child(_shard_bar(id))
	return card


## Chip phẩm (Rookie/Pro/Elite/Legend), màu theo TIER_COLORS.
func _tier_chip(d: Dictionary) -> Control:
	var t := clampi(int(d["tier"]), 0, TIER_NAMES.size() - 1)
	var chip := PanelContainer.new()
	chip.name = "TierChip"
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := _sb(Color(String(TIER_COLORS[t])), Color(1, 1, 1, 0.85), 1, 9, 0)
	box.content_margin_left = 7
	box.content_margin_right = 7
	box.content_margin_top = 1
	box.content_margin_bottom = 1
	chip.add_theme_stylebox_override("panel", box)
	var l := _label(I18n.t(String(TIER_NAMES[t])), 11, Color.WHITE)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(l)
	return chip


## Thanh mảnh trên thẻ: mảnh đang có / mảnh cần để nâng cấp tiếp. Đạt cấp tối đa thì đầy và ghi "Cấp tối đa".
func _shard_bar(id: String) -> Control:
	var need := GameState.driver_upgrade_cost(id)
	var shards := GameState.driver_shards(id)
	var ready := need >= 0 and shards >= need
	var bar := ProgressBar.new()
	bar.name = "ShardBar"
	bar.show_percentage = false
	bar.max_value = maxi(need, 1)
	bar.value = 1.0 if need < 0 else float(mini(shards, need))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(24, 20)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _sb(Color("c3d6f2"), Color(0, 0, 0, 0), 0, 10, 0))
	bar.add_theme_stylebox_override("fill", _sb(C_GOOD if ready else C_ORANGE, Color(0, 0, 0, 0), 0, 10, 0))
	# Chữ nằm trong thanh: trắng viền tối để đọc được cả trên nền nhạt lẫn phần đã đầy.
	var text := I18n.t("common.max_level") if need < 0 else I18n.t("drivers.shards_short") % [shards, need]
	var l := _label(text, 12, Color.WHITE)
	l.name = "ShardText"
	l.add_theme_color_override("font_outline_color", Color("0e2b5c"))
	l.add_theme_constant_override("outline_size", 4)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(l)
	return bar


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
	var s := _status(d)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(_portrait(_viewed, Vector2(60, 60)))
	head.add_child(ExpansionArt.icon(String(d.get("style", "counter")), Vector2(32, 32)))
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_theme_constant_override("separation", 0)
	hv.add_child(_fit_name(String(d["name"]), 20, 150.0, 13))
	hv.add_child(_label(_style_name(d), 12, C_MUTED))
	hv.add_child(_tier_chip(d))
	hv.add_child(_label(_state_text(s), 12, _state_color(s)))
	head.add_child(hv)
	var x := HdUi.close_button(close_sheet, "DriverDetailClose")
	head.add_child(x)
	_sheet_box.add_child(head)

	_sheet_box.add_child(_radar(d))
	var tp := _panel(_sb(Color("e2f2ef"), Color("b7ddd8"), 1, 12, 10))
	tp.add_child(_label(I18n.t("drivers.trait") % [I18n.t(String(TRAITS.get(String(d["trait"]), TRAITS[""]))), I18n.t("drivers.total_stats") % _total(d)], 12, Color("1e5f59"), true))
	_sheet_box.add_child(tp)

	if s == "active" or s == "owned":
		_sheet_box.add_child(_level_panel(_viewed))

	var cta := Button.new()
	cta.custom_minimum_size = Vector2(0, 52)
	cta.add_theme_font_size_override("font_size", 16)
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
		"lock":
			var req2 := _panel(_sb(C_CARD, C_LINE, 1, 14, 10))
			req2.add_child(_req_row(I18n.t("drivers.unlock_requirement"), _unlock_text(d), false))
			_sheet_box.add_child(req2)
			cta.text = I18n.t("drivers.cannot_recruit_yet")
			HdUi.style_button(cta, "cancel")
			cta.disabled = true
		"owned":
			cta.text = I18n.t("drivers.select_next_race") % String(d["name"])
			HdUi.style_button(cta, "race")
			cta.disabled = _blocked()
			cta.pressed.connect(_select.bind(_viewed))
		_:
			cta.text = I18n.t("common.use")
			HdUi.style_button(cta, "cancel")
			cta.disabled = true
	_sheet_box.add_child(cta)


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


func _req_row(left: String, right: String, ok: bool) -> Control:
	var h := HBoxContainer.new()
	h.add_child(_label(left, 13))
	var r := _label(right, 13, C_GOOD if ok else C_BAD, true)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(r)
	return h


## Biểu đồ mạng nhện 7 chỉ số; đang xem người khác với tay đua đang dùng thì vẽ thêm đường nét của người đang dùng để so sánh.
func _radar(d: Dictionary) -> Control:
	var r := DriverRadar.new()
	r.name = "DriverRadar"
	r.max_value = STAT_MAX
	var names := PackedStringArray()
	var vals: Array = []
	for st: Array in STATS:
		names.append(I18n.t(String(st[1])))
		vals.append(_stat(d, st[0]))
	r.labels = names
	r.values = vals
	var active := GameData.driver(GameState.active_driver_id)
	if not active.is_empty() and String(active["id"]) != String(d["id"]):
		var ref: Array = []
		for st: Array in STATS:
			ref.append(_stat(active, st[0]))
		r.ref_values = ref
	return r


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
