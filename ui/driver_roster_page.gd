class_name DriverRosterPage
extends VBoxContainer
## Đội → Tay đua (Design/Mockups/driver_roster_v2.html): thanh SP, tay đua đang dùng, lọc, lưới hai cột
## và bảng chi tiết kiểu bottom sheet có radar so sánh. Trang chỉ đọc GameState và gọi recruit/select.
## `sheet` do main gắn vào vùng nội dung (dưới khung đua) để bảng không che cuộc đua.

signal sfx(cue: String)
signal notice(msg: String)
signal open_requested(pack_id: String, count: int)
signal info_requested(pack_id: String)

const ROOT := "res://assets/workshop_gp/"
const C_BG := Color("dcebff")
const C_CARD := Color("eaf2ff")
const C_LINE := Color("9db9e3")
const C_INK := Color("12294d")
const C_TEXT := Color("16355c")
const C_MUTED := Color("5a7294")
const C_ORANGE := Color("f2790a")
const C_ORANGE_D := Color("d96a00")
const C_GOLD := Color("b27300")
const C_GOOD := Color("15803d")
const C_BAD := Color("c62828")
const STAT_MAX := 70.0

const STATS := [
	["launch", "Xuất phát"], ["pace", "Tốc độ"], ["braking", "Phanh"], ["technique", "Vào cua"],
	["racecraft", "Đua sát"], ["composure", "Bình tĩnh"], ["endurance", "Bền sức"],
]
const TRAITS := {
	"": "Không có đặc tính",
	"fast_start": "Xuất phát nhanh: tăng tốc +25% trong 10 giây đầu",
	"smooth_corners": "Cua mượt: +1,5% tốc độ vào cua",
	"calm": "Điềm tĩnh: lỗi kéo dài ngắn hơn 30%",
	"sprint": "Nước rút: +1% tốc độ ở vòng cuối",
	"hunter": "Thợ săn: dễ vượt hơn khi bám đuôi",
	"defender": "Phòng thủ: khó bị vượt hơn",
	"straight_line": "Đường thẳng: +1,5% tốc độ ở đoạn thẳng",
	"steady": "Ổn định: giảm 15% xác suất mắc lỗi",
	"recovery": "Hồi phục: tăng tốc +30% trong 3 giây",
	"golden": "Phong độ vàng: phong độ không tụt dưới 99,5%",
	"discipline": "Kỷ luật: không mắc lỗi ở vòng đầu",
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
		parts.append("Hoàn tất %d lượt đua" % int(u["count"]))
	if int(u.get("league", 0)) > GameState.business_tier:
		parts.append("Mở giải %s" % Balance.league_name(int(u["league"])))
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
	return String(best[1])


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
		t.texture = load(path) as Texture2D
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
	return {"active": "Đang dùng", "owned": "Đã có", "avail": "Có thể tuyển", "lock": "Khóa"}[s]


func _state_color(s: String) -> Color:
	return {"active": C_ORANGE_D, "owned": C_GOOD, "avail": C_GOLD, "lock": C_MUTED}[s]


func _ignore_mouse(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore_mouse(c)


# ---------------------------------------------------------------- trang chính

const TIER_NAMES := ["Tân binh", "Pro", "Elite", "Legend"]
const TIER_COLORS := ["776d61", "2e6fd8", "8a3fd1", "b8862b"]


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build_packs()
	_build_sp_card()
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
	_build_section("ĐỘI HÌNH", team, "ĐANG ĐUA: %s" % String(active.get("name", "")), C_GOOD)
	_build_section("CÓ THỂ TUYỂN", avail, "", C_MUTED)
	_build_section("CHƯA MỞ", locked, "", C_MUTED)


const PACK_TINT := {"pro": Color("2e6fd8"), "allstar": Color("8a3fd1")}


## Hai gói rút tay đua (giống gói phụ kiện ở tab Túi): mở x1/x10 bằng coupon hoặc gem, có bảo đảm.
func _build_packs() -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for pack: Dictionary in GameData.driver_packs():
		var id := String(pack["id"])
		var tint: Color = PACK_TINT.get(id, C_ORANGE)
		var p := _panel(_sb(C_CARD, tint, 2, 14, 8))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		p.add_child(v)
		var header_row := HBoxContainer.new()
		header_row.add_theme_constant_override("separation", 4)
		v.add_child(header_row)
		# Mặt nút bo tròn hai đầu; giữ trọn hai nắp khi kéo giãn theo tiêu đề.
		var header := PanelContainer.new()
		var header_skin := HdUi.pack_header(0.76 if id == "allstar" else 0.60)
		header.add_theme_stylebox_override("panel", header_skin)
		header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(header)
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 2)
		header.add_child(top)
		var name := _label(String(pack["name"]), 11, Color.WHITE, true)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name.custom_minimum_size.y = 30
		name.add_theme_color_override("font_outline_color", HdUi.C_OUTLINE)
		name.add_theme_constant_override("outline_size", 2)
		top.add_child(name)
		var info := Button.new()
		info.text = "i"
		info.name = "DriverInfo_" + id
		HdUi.style_button(info, "info")
		info.custom_minimum_size = Vector2(28, 28)
		info.add_theme_font_size_override("font_size", 12)
		info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		info.size_flags_horizontal = Control.SIZE_SHRINK_END
		info.tooltip_text = "Thông tin tỉ lệ"
		info.pressed.connect(func() -> void: info_requested.emit(id))
		header_row.add_child(info)
		v.add_child(ExpansionArt.icon("standard_driver_pack" if id == "pro" else "elite_driver_pack", Vector2(0, 64)))
		var left := maxi(1, int(pack["pity_draws"]) - GameState.driver_pity_count(id))
		var tier := String(pack["pity_tier"]).capitalize()
		var pity_text := "Lượt kế bảo đảm %s" % tier if left <= 1 else "Bảo đảm %s sau %d lượt" % [tier, left]
		var subtitle := _label(pity_text, 11, C_MUTED, true)
		subtitle.custom_minimum_size.y = 42
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		v.add_child(subtitle)
		var kind := String(pack["coupon"])
		var coupon_panel := PanelContainer.new()
		coupon_panel.custom_minimum_size.y = 30
		var coupon_skin := HdUi.coupon()
		coupon_panel.add_theme_stylebox_override("panel", coupon_skin)
		v.add_child(coupon_panel)
		var coupon := HBoxContainer.new()
		coupon.add_theme_constant_override("separation", 2)
		coupon_panel.add_child(coupon)
		var coupon_count := _label("Coupon: %d" % int(GameState.driver_coupons.get(kind, 0)), 12, C_TEXT, true)
		coupon_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		coupon_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		coupon.add_child(coupon_count)
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 4)
		v.add_child(actions)
		for n in [1, 10]:
			var pay := GameState.driver_payment(id, n)
			var cost := "%d coupon" % int(pay["amount"]) if pay["method"] == "coupon" else "%d gem" % int(pay["amount"])
			var payment := "Mở x%d · %s" % [n, cost]
			var b := Button.new()
			b.text = payment.replace("Mở ", "").replace(" · ", "\n")
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.clip_text = true
			b.disabled = not GameState.driver_can_afford(id, n)
			HdUi.style_button(b, "upgrade")
			b.tooltip_text = payment
			b.custom_minimum_size.y = 48
			b.add_theme_font_size_override("font_size", 11)
			# Hai nút chia đều chiều rộng; nhãn giá xuống dòng để vừa thẻ trên màn hình hẹp.
			for state: String in ["normal", "hover", "pressed", "disabled"]:
				var skin := b.get_theme_stylebox(state).duplicate() as StyleBoxTexture
				if n == 1 and state != "disabled":
					skin.modulate_color = Color(0.8, 0.9, 1.0)
				skin.content_margin_left = 3
				skin.content_margin_right = 3
				b.add_theme_stylebox_override(state, skin)
			b.name = "DriverOpen_%s_x%d" % [id, n]
			b.pressed.connect(func() -> void: open_requested.emit(id, n))
			actions.add_child(b)
		h.add_child(p)
	add_child(h)


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
	var count := _label("%d/%d đã tuyển" % [GameState.owned_drivers.size(), GameData.drivers().size()], 12, C_MUTED)
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
		note = "Bạn đã tuyển toàn bộ tay đua."
	else:
		var need := _next_sp()
		bar.value = minf(1.0, float(GameState.scout_points) / float(maxi(need, 1)))
		var tail := "Mỗi lượt đua cộng khoảng 5–14 SP. Tuyển không ngẫu nhiên."
		if GameState.scout_points >= need:
			note = "Lần tuyển kế cần %d SP · đủ cho %d lần tuyển. %s" % [need, GameState.scout_points / need, tail]
		else:
			note = "Lần tuyển kế cần %d SP · còn thiếu %d SP. %s" % [need, need - GameState.scout_points, tail]
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)

	var open := Button.new()
	open.custom_minimum_size = Vector2(0, 72)
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open.accessibility_name = "Xem chi tiết %s" % String(d["name"])
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

	var portrait := _portrait(id, Vector2(52, 52))
	portrait.modulate.a = 0.5 if s == "lock" else 1.0
	h.add_child(portrait)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	var l1 := HBoxContainer.new()
	l1.add_theme_constant_override("separation", 6)
	l1.add_child(_label(String(d["name"]), 16))
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _sb(tcol.lightened(0.8), tcol.lightened(0.45), 1, 8, 2))
	var cl := _label(String(TIER_NAMES[tier]), 11, tcol)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(cl)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l1.add_child(chip)
	if s == "active" or s == "owned":
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
			act = _flat_button("Đang dùng", Color("ffe8cf"), C_ORANGE_D, C_ORANGE, 1, 44.0)
			act.disabled = true
		"owned":
			act = _flat_button("Chọn", C_INK, Color.WHITE, C_INK, 1, 44.0)
			act.disabled = _blocked()
			act.pressed.connect(_select.bind(id))
		"avail":
			act = _flat_button("Tuyển", C_ORANGE, Color.WHITE, C_ORANGE_D, 1, 44.0)
			act.pressed.connect(_open_sheet.bind(id))
		_:
			act = _flat_button("Khóa", Color("e1e8f4"), C_MUTED, C_LINE, 1, 44.0)
			act.pressed.connect(_open_sheet.bind(id))
	act.custom_minimum_size = Vector2(82, 44)
	act.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	act.add_theme_font_size_override("font_size", 13)
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
			h.add_child(_label("%s tiền · %d SP" % [price.format_compact(), _next_sp()], 12, C_GOOD if ok else C_BAD))
		"lock":
			var l := _label(_unlock_text(d), 12, C_MUTED)
			l.clip_text = true
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(l)
		_:
			var ranked: Array = STATS.duplicate()
			ranked.sort_custom(func(a: Array, b: Array) -> bool: return _stat(d, a[0]) > _stat(d, b[0]))
			h.add_child(_label("%s %d" % [ranked[0][1], _stat(d, ranked[0][0])], 12, C_ORANGE_D))
			h.add_child(_label("%s %d" % [ranked[1][1], _stat(d, ranked[1][0])], 12, Color("1e6b64")))
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
	hv.add_child(_label(String(d["name"]), 20))
	hv.add_child(_label(_style_name(d), 12, C_MUTED))
	hv.add_child(_label(_state_text(s), 12, _state_color(s)))
	head.add_child(hv)
	var x := HdUi.close_button(close_sheet, "DriverDetailClose")
	head.add_child(x)
	_sheet_box.add_child(head)

	var note := "So với tay đua đang dùng (%s)" % String(act["name"]) if cmp else "Chỉ số của tay đua đang dùng"
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
		lg.add_child(_label("■ %s (đường nét đứt)" % String(act["name"]), 12, C_INK))
		_sheet_box.add_child(lg)

	for st: Array in STATS:
		_sheet_box.add_child(_stat_row(String(st[1]), _stat(d, st[0]), _stat(act, st[0]), cmp))
	var tot := _total(d)
	var tot_txt := "Tổng chỉ số %d" % tot
	if cmp:
		var dt := tot - _total(act)
		tot_txt += " (%s%d)" % ["+" if dt >= 0 else "−", absi(dt)]
	var tp := _panel(_sb(Color("e2f2ef"), Color("b7ddd8"), 1, 12, 10))
	tp.add_child(_label("Đặc tính: %s\n%s" % [String(TRAITS.get(String(d["trait"]), "")), tot_txt], 12, Color("1e5f59"), true))
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
			var coin_txt := "%s · bạn có %s" % [price.format_compact(), GameState.coins.format_compact()]
			if not ok_c:
				coin_txt += " · thiếu %s" % price.subtract_checked(GameState.coins).format_compact()
			rv.add_child(_req_row("Tiền", coin_txt, ok_c))
			var sp_txt := "%d SP · bạn có %d" % [need_sp, GameState.scout_points]
			if not ok_s:
				sp_txt += " · thiếu %d" % (need_sp - GameState.scout_points)
			rv.add_child(_req_row("Điểm tuyển", sp_txt, ok_s))
			_sheet_box.add_child(req)
			cta.text = "Tuyển %s" % String(d["name"])
			cta.disabled = not (ok_c and ok_s) or _blocked()
			cta.pressed.connect(_recruit.bind(_viewed))
			hint = "Tuyển không tự chọn. Không ngẫu nhiên, không trùng lặp."
		"lock":
			var req2 := _panel(_sb(C_CARD, C_LINE, 1, 14, 10))
			req2.add_child(_req_row("Điều kiện mở", _unlock_text(d), false))
			_sheet_box.add_child(req2)
			cta.text = "Chưa thể tuyển"
			cta.disabled = true
			hint = "Bạn vẫn xem được chỉ số để lập kế hoạch."
		"owned":
			cta.text = "Chọn %s cho lượt kế" % String(d["name"])
			cta.disabled = _blocked()
			cta.pressed.connect(_select.bind(_viewed))
			hint = "Áp dụng từ lượt đua kế tiếp; lượt đang chạy giữ nguyên."
		_:
			cta.text = "Đang dùng"
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
	v.add_child(_label("Cấp %d / %d · +%d mọi chỉ số" % [lv, mx, bonus], 13))
	var need := GameState.driver_upgrade_cost(id)
	if need < 0:
		v.add_child(_label("Cấp tối đa", 12, C_MUTED))
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
	v.add_child(_label("%d/%d mảnh · tay đua trùng khi mở gói đổi thành mảnh" % [shards, need], 12, C_MUTED, true))
	if shards >= need:
		var up := _flat_button("Nâng cấp", C_ORANGE, Color.WHITE, C_ORANGE_D, 1, 44.0)
		up.disabled = _blocked()
		up.pressed.connect(_upgrade.bind(id))
		v.add_child(up)
	return p


func _upgrade(id: String) -> void:
	if GameState.upgrade_driver(id):
		sfx.emit("ui_click")
		notice.emit("Đã nâng cấp %s." % String(GameData.driver(id)["name"]))
	else:
		notice.emit("Chưa đủ mảnh hoặc không lưu được.")
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
		notice.emit("Đã tuyển %s. Bấm Chọn để dùng ở lượt kế." % dname)
	else:
		notice.emit("Không tuyển được %s." % dname)
	_sig = ""
	refresh()
	if sheet.visible:
		_rebuild_sheet()


func _select(id: String) -> void:
	var dname := String(GameData.driver(id)["name"])
	if GameState.select_driver(id):
		notice.emit("%s sẽ đua từ lượt kế." % dname)
		close_sheet()
	else:
		notice.emit("Không chọn được %s." % dname)
	_sig = ""
	refresh()


# ---------------------------------------------------------------- radar

## Biểu đồ mạng nhện 7 chỉ số: `a` tô cam, `b` (nếu có) vẽ nét đứt đen để so sánh.
class RadarChart extends Control:
	const LABELS := ["Xuất phát", "Tốc độ", "Phanh", "Vào cua", "Đua sát", "Bình tĩnh", "Bền sức"]
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
			draw_polyline(ring, Color("9db9e3"), 1.0)
		var font := get_theme_default_font()
		for i in n:
			draw_line(c, _pt(c, r, i, n), Color("c3d6f2"), 1.0)
			var lp := _pt(c, r + 18.0, i, n)
			var w := font.get_string_size(LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(font, lp + Vector2(-w * 0.5, 4), LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("5a7294"))
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
