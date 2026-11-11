class_name GaragePage
extends VBoxContainer
## Garage chuyên sâu (Design/15): xem/mua/chọn xe, nâng bốn phụ tùng theo car_id tường minh, màu sơn + decal.
## Trang chỉ đọc GameState và gọi giao dịch của nó; bản nháp ngoại hình chỉ nằm trong UI.

signal sfx(cue: String)
signal notice(msg: String)

const ROOT := "res://assets/workshop_gp/"
const C_BG := Color("dcebff")
const C_CARD := Color("eaf2ff")
const C_LINE := Color("9db9e3")
const C_INK := Color("12294d")
const C_TEXT := Color("16355c")
const C_MUTED := Color("5a7294")
const C_ORANGE := Color("f2790a")
const C_GOOD := Color("15803d")
const C_BAD := Color("c62828")

const SECTIONS := ["Xe", "Phụ tùng", "Ngoại hình"]
const STAT_NAMES := {"S": "Tốc độ", "H": "Bám đường", "B": "Ổn định", "A": "Tăng tốc"}
const PART_ORDER := ["engine", "tyre", "chassis", "gearbox"]
const MULTS := [1, 10, 0]  # 0 = ×Max

var _viewed: String = ""
var _section: int = 0
var _part: String = "engine"
var _mult: int = 1
var _draft_car: String = ""
var _draft_paint: String = ""
var _draft_decal: String = ""
var _collection: bool = false
var _owned_only: bool = false
var _confirm_buy: bool = false
var _pending: Callable = Callable()
var _sig: String = ""
var _built: bool = false
var _preview: CarPreview
var _body: VBoxContainer


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)


func _ready() -> void:
	refresh()


# ---------------------------------------------------------------- trạng thái

func _viewed_valid() -> void:
	if _viewed == "" or GameData.car(_viewed).is_empty():
		_viewed = GameState.active_car_id


func _saved_cos(car_id: String) -> Dictionary:
	return GameState.cosmetics_of(car_id)


func _owned(car_id: String) -> bool:
	return GameState.owned_cars.has(car_id)


func _dirty() -> bool:
	if _draft_car != _viewed or not _owned(_viewed):
		return false
	var s := _saved_cos(_viewed)
	return _draft_paint != s["paint_id"] or _draft_decal != s["decal_id"]


func _sync_draft() -> void:
	if _draft_car != _viewed:
		_draft_car = _viewed
		var s := _saved_cos(_viewed)
		_draft_paint = s["paint_id"]
		_draft_decal = s["decal_id"]


func _blocked() -> bool:
	return GameState.save_blocked or GameState.phase == "save_error"


func _min_class() -> int:
	return int(GameData.league(GameState.business_tier)["min_car_class"])


func _eligible(car_id: String) -> bool:
	return int(GameData.car(car_id)["class"]) >= _min_class()


## Gọi từ main mỗi khi dữ liệu đổi và theo nhịp ngắn: chỉ dựng lại khi dữ liệu hiển thị thật sự đổi.
func refresh() -> void:
	_viewed_valid()
	_sync_draft()
	var sig := _signature()
	if sig == _sig and _built:
		return
	_sig = sig
	_built = true
	_rebuild()


func _signature() -> String:
	var parts: Array = [_viewed, _section, _part, _mult, _draft_car, _draft_paint, _draft_decal, _collection, _owned_only,
		_confirm_buy, _pending.is_valid(), GameState.phase, GameState.save_blocked, GameState.active_car_id,
		GameState.business_tier, GameState.unlocked_tier, GameState.owned_cars.keys().size()]
	for id: String in GameState.owned_cars.keys():
		parts.append(id)
		parts.append(str(_saved_cos(id)))
	for kind: String in Balance.PARTS:
		parts.append(GameState.car_level(_viewed, kind))
		parts.append(GameState.car_level(GameState.active_car_id, kind))
	# Khả năng chi trả thay đổi theo thu nhập: chỉ đưa vào chữ ký phần ảnh hưởng tới nút đang hiện.
	if _collection:
		for c: Dictionary in GameData.cars():
			if not _owned(String(c["id"])):
				parts.append(GameState.coins.compare(Pricing.car_price(String(c["id"]))) >= 0)
	else:
		if not _owned(_viewed):
			parts.append(GameState.coins.compare(Pricing.car_price(_viewed)) >= 0)
		elif _section == 1:
			var plan := GameState.plan_buy(_part, _mult, _viewed)
			parts.append(plan["count"])
			parts.append(GameState.car_upgrade_state(_viewed, _part))
			parts.append(_next_cost(_part).format_compact())
	if GameState.race_snapshot.has("car_id"):
		parts.append(str(GameState.race_snapshot["car_id"]))
	return "|".join(parts.map(func(x: Variant) -> String: return str(x)))


# ---------------------------------------------------------------- khối dựng UI

func _label(text: String, size: int = 14, color: Color = C_TEXT, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _box(bg: Color, border: Color, radius: int = 12, bw: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _style_button(b: Button, bg: Color, fg: Color, border: Color, bw: int = 1) -> void:
	for st: String in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, _box(bg, border, 12, bw))
	b.add_theme_stylebox_override("disabled", _box(bg.lerp(C_BG, 0.45), border.lerp(C_BG, 0.45), 12, bw))
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)
	b.add_theme_color_override("font_disabled_color", fg.lerp(C_MUTED, 0.5))


## Nút phụ: nền kem viền be; `on` = đang chọn (graphite chữ trắng).
func _choice(text: String, on: bool, cb: Callable, h: float = 44.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, maxf(h, 44.0))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 14)
	if on:
		_style_button(b, C_INK, Color.WHITE, C_INK)
	else:
		_style_button(b, C_CARD, C_TEXT, C_LINE)
	b.pressed.connect(func() -> void:
		sfx.emit("ui_tab")
		cb.call())
	return b


func _cta(text: String, enabled: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 16)
	_style_button(b, C_ORANGE, C_INK, Color("d9620a"))
	b.pressed.connect(func() -> void:
		sfx.emit("ui_click")
		cb.call())
	return b


func _plain(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 14)
	_style_button(b, C_CARD, C_TEXT, C_LINE)
	b.pressed.connect(func() -> void:
		sfx.emit("ui_click")
		cb.call())
	return b


func _panel(parent: Control, bg: Color = C_CARD) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _box(bg, C_LINE, 12))
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	return v


func _grid(parent: Control, cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(g)
	return g


func _rebuild() -> void:
	for ch in get_children():
		remove_child(ch)
		ch.queue_free()
	_preview = null
	_body = null
	if _collection:
		_build_collection()
		return
	_build_header()
	_build_unsaved_bar()
	_build_showroom()
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_body)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	_body.add_child(tabs)
	for i in SECTIONS.size():
		tabs.add_child(_choice(SECTIONS[i], _section == i, _set_section.bind(i)))
	match _section:
		0:
			_build_car_section()
		1:
			_build_parts_section()
		2:
			_build_look_section()


func _build_header() -> void:
	var car := GameData.car(_viewed)
	var head := HBoxContainer.new()
	add_child(head)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	head.add_child(titles)
	titles.add_child(_label("Garage", 22))
	var sub := _label("%s · Hạng %d" % [car["name"], int(car["class"])], 14, C_MUTED, true)
	titles.add_child(sub)
	var change := _plain("Đổi xe", func() -> void: _guard(func() -> void:
		_collection = true
		_confirm_buy = false
		refresh()))
	change.custom_minimum_size = Vector2(88, 48)
	head.add_child(change)


func _build_showroom() -> void:
	_preview = CarPreview.new()
	_preview.custom_minimum_size = Vector2(0, 176)
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _box(Color("cfe0fb"), C_LINE, 14))
	pc.add_child(_preview)
	add_child(pc)
	var cos := _saved_cos(_viewed)
	if _owned(_viewed):
		_preview.paint_id = _draft_paint if _draft_car == _viewed else cos["paint_id"]
		_preview.decal_id = _draft_decal if _draft_car == _viewed else cos["decal_id"]
	else:
		_preview.paint_id = GameData.default_paint_id()
		_preview.decal_id = GameData.default_decal_id()
		_preview.dimmed = true
	add_child(_label(_status_text(), 13, C_MUTED, true))


func _status_text() -> String:
	var id := _viewed
	var racing := GameState.phase == "racing"
	var snap_car := String(GameState.race_snapshot.get("car_id", ""))
	if racing and snap_car != "" and snap_car != GameState.active_car_id:
		return "Đang đua: %s · Lượt kế: %s" % [String(GameData.car(snap_car).get("name", snap_car)), String(GameData.car(GameState.active_car_id)["name"])]
	if not _owned(id):
		if not GameState.car_unlocked(id):
			return "Khóa · cần mở giải %s" % Balance.league_name(int(GameData.car(id)["entry_tier"]))
		return "Chưa mua · xem chỉ số và ngoại hình mặc định"
	if id == GameState.active_car_id:
		return "✓ Đang dùng" + (" · thay đổi áp dụng từ lượt sau" if racing else "")
	if not _eligible(id):
		return "Đã có · hạng thấp hơn mức giải hiện tại (cần hạng %d)" % _min_class()
	return "Đã có · chưa chọn cho lượt kế"


func _build_unsaved_bar() -> void:
	if not _pending.is_valid():
		return
	var v := _panel(self, Color("ffe8cf"))
	v.add_child(_label("Ngoại hình xe này có thay đổi chưa lưu.", 14, C_TEXT, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var save := _cta("Lưu", not _blocked(), func() -> void:
		if _save_look():
			_run_pending())
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(save)
	var drop := _plain("Bỏ thay đổi", func() -> void:
		_reset_draft()
		_run_pending())
	drop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(drop)
	var stay := _plain("Ở lại", func() -> void:
		_pending = Callable()
		refresh())
	stay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stay)


## Dev/QA (CLI --garage=): "<mục>[,collection][,car=<id>][,part=<kind>][,mult=<n>][,draft=<màu>:<decal>]".
func debug_show(spec: String) -> void:
	var bits := spec.split(",")
	_section = int(bits[0])
	for b in bits.slice(1):
		if b == "collection":
			_collection = true
		elif b.begins_with("car="):
			_viewed = b.substr(4)
		elif b.begins_with("part="):
			_part = b.substr(5)
		elif b.begins_with("mult="):
			_mult = int(b.substr(5))
		elif b.begins_with("draft="):
			_viewed_valid()
			_draft_car = _viewed
			var pd := b.substr(6).split(":")
			_draft_paint = pd[0]
			_draft_decal = pd[1] if pd.size() > 1 else "none"
	refresh()


# ---------------------------------------------------------------- điều hướng có bảo vệ bản nháp

func _guard(action: Callable) -> void:
	if _dirty():
		_pending = action
		refresh()
	else:
		action.call()


func _run_pending() -> void:
	var a := _pending
	_pending = Callable()
	if a.is_valid():
		a.call()
	refresh()


func _reset_draft() -> void:
	var s := _saved_cos(_viewed)
	_draft_car = _viewed
	_draft_paint = s["paint_id"]
	_draft_decal = s["decal_id"]
	refresh()


func _set_section(i: int) -> void:
	_section = i
	_confirm_buy = false
	refresh()


func _view_car(id: String) -> void:
	_viewed = id
	_collection = false
	_confirm_buy = false
	_draft_car = ""
	refresh()


# ---------------------------------------------------------------- mục Xe

func _owned_level(kind: String) -> int:
	return GameState.car_level(_viewed, kind) if _owned(_viewed) else 0


func _build_car_section() -> void:
	var compare := _viewed != GameState.active_car_id
	var grid := _grid(_body, 2)
	for kind: String in PART_ORDER:
		var key: String = Balance.PART_KEY[kind]
		var value := GameState.car_part_stat(_viewed, kind, _owned_level(kind))
		var card := _panel(grid)
		card.add_child(_label(STAT_NAMES[key], 14, C_MUTED))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		row.add_child(_label(Balance.fmt_rate(snappedf(value, 0.1)), 22))
		if compare:
			var base := GameState.car_part_stat(GameState.active_car_id, kind, GameState.level_of(kind))
			var delta := snappedf(value - base, 0.1)
			var txt := "0" if is_zero_approx(delta) else ("%s%s" % ["+" if delta > 0.0 else "−", Balance.fmt_rate(absf(delta))])
			var l := _label(txt, 13, C_GOOD if delta > 0.0 else (C_BAD if delta < 0.0 else C_MUTED))
			l.size_flags_vertical = Control.SIZE_SHRINK_END
			row.add_child(l)
	var note := "So với xe đang dùng cho lượt kế." if compare else "Cấp phụ tùng được giữ riêng theo từng xe."
	_body.add_child(_label(note, 12, C_MUTED, true))
	_body.add_child(_car_cta())


func _car_cta() -> Control:
	var id := _viewed
	var car := GameData.car(id)
	if not _owned(id):
		var price := Pricing.car_price(id)
		if _confirm_buy:
			var v := _panel(_body)
			v.add_child(_label("Mua %s với giá %s tiền?" % [car["name"], price.format_compact()], 14, C_TEXT, true))
			v.add_child(_label("Ví còn lại: %s tiền. Mua xong xe chưa tự được chọn." % Balance.fmt_compact(GameState.coins.subtract_checked(price) if GameState.coins.compare(price) >= 0 else BigNumber.zero()), 12, C_MUTED, true))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			v.add_child(row)
			var ok := _cta("Xác nhận mua", GameState.coins.compare(price) >= 0 and not _blocked(), func() -> void:
				_confirm_buy = false
				if GameState.buy_car(id):
					sfx.emit("upgrade")
					notice.emit("Đã mua %s" % car["name"])
				refresh())
			ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(ok)
			var no := _plain("Hủy", func() -> void:
				_confirm_buy = false
				refresh())
			no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(no)
			return v
		if _blocked():
			return _cta("Chờ lưu", false, func() -> void: pass)
		if not GameState.car_unlocked(id):
			return _cta("Cần mở giải %s" % Balance.league_name(int(car["entry_tier"])), false, func() -> void: pass)
		if GameState.coins.compare(price) < 0:
			return _cta("Thiếu %s tiền" % Balance.fmt_compact(price.subtract_checked(GameState.coins)), false, func() -> void: pass)
		return _cta("Mua · %s tiền" % price.format_compact(), true, func() -> void:
			_confirm_buy = true
			refresh())
	if id == GameState.active_car_id:
		return _cta("Đang dùng", false, func() -> void: pass)
	if _blocked():
		return _cta("Chờ lưu", false, func() -> void: pass)
	if not _eligible(id):
		return _cta("Cần xe hạng %d trở lên" % _min_class(), false, func() -> void: pass)
	return _cta("Dùng xe này", true, func() -> void:
		if GameState.select_car(id):
			notice.emit("Đã chọn %s%s" % [car["name"], " · áp dụng từ lượt sau" if GameState.phase == "racing" else ""])
		refresh())


# ---------------------------------------------------------------- mục Phụ tùng

func _remaining(kind: String) -> int:
	return Balance.max_level() - GameState.car_level(_viewed, kind)


## Số cấp mục tiêu của lựa chọn ×1/×10/×Max (×Max = số cấp mua được, tối thiểu 1 để hiện giá cấp kế).
func _target_count(kind: String) -> int:
	var rem := _remaining(kind)
	if _mult == 0:
		return maxi(mini(GameState.plan_buy(kind, 0, _viewed)["count"], rem), 1 if rem > 0 else 0)
	return mini(_mult, rem)


func _cost_of(kind: String, n: int) -> BigNumber:
	var total := BigNumber.zero()
	var lv := GameState.car_level(_viewed, kind)
	for i in n:
		total = total.add(GameState._cost_at(kind, lv + i, _viewed))
	return total


func _next_cost(kind: String) -> BigNumber:
	if not _owned(_viewed) or _remaining(kind) <= 0:
		return BigNumber.zero()
	return _cost_of(kind, _target_count(kind))


func _build_parts_section() -> void:
	if not _owned(_viewed):
		_body.add_child(_label("Mua xe này để nâng cấp phụ tùng. Cấp phụ tùng được giữ riêng theo từng xe.", 13, C_MUTED, true))
		_body.add_child(_car_cta())
		return
	var grid := _grid(_body, 2)
	for kind: String in PART_ORDER:
		var lv := GameState.car_level(_viewed, kind)
		var stat := GameState.car_part_stat(_viewed, kind, lv)
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 62)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var on := kind == _part
		_style_button(b, C_INK if on else C_CARD, Color.WHITE if on else C_TEXT, C_INK if on else C_LINE)
		b.pressed.connect(func() -> void:
			sfx.emit("ui_tab")
			_part = kind
			refresh())
		var inner := VBoxContainer.new()
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.add_theme_constant_override("separation", 0)
		var n1 := _label(Balance.PART_NAMES[kind], 15, Color.WHITE if on else C_TEXT)
		var n2 := _label("Cấp %d/%d · %s" % [lv, Balance.max_level(), Balance.fmt_rate(snappedf(stat, 0.1))], 12, Color("cfe0fb") if on else C_MUTED)
		for l: Label in [n1, n2]:
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		inner.add_child(n1)
		inner.add_child(n2)
		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_child(inner)
		b.add_child(margin)
		grid.add_child(b)
	_build_part_detail()


func _build_part_detail() -> void:
	var kind := _part
	var key: String = Balance.PART_KEY[kind]
	var lv := GameState.car_level(_viewed, kind)
	var rem := _remaining(kind)
	var v := _panel(_body)
	var head := HBoxContainer.new()
	v.add_child(head)
	var title := _label(Balance.PART_NAMES[kind], 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var mlabel := _label("Mua", 14, C_MUTED)
	mlabel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(mlabel)
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(92, 44)
	opt.add_theme_font_size_override("font_size", 14)
	for i in MULTS.size():
		opt.add_item("×Max" if MULTS[i] == 0 else "×%d" % MULTS[i], i)
		if MULTS[i] == _mult:
			opt.select(i)
	opt.item_selected.connect(func(idx: int) -> void:
		_mult = MULTS[idx]
		refresh())
	head.add_child(opt)
	var n := _target_count(kind)
	var cur := GameState.car_part_stat(_viewed, kind, lv)
	var nxt := GameState.car_part_stat(_viewed, kind, lv + n)
	if rem > 0:
		v.add_child(_label("%s %s → %s" % [STAT_NAMES[key], Balance.fmt_rate(snappedf(cur, 0.1)), Balance.fmt_rate(snappedf(nxt, 0.1))], 15, C_TEXT, true))
		v.add_child(_label("Cấp %d → %d · Tối đa %d" % [lv, lv + n, Balance.max_level()], 12, C_MUTED, true))
	else:
		v.add_child(_label("%s %s · đã đạt cấp tối đa %d" % [STAT_NAMES[key], Balance.fmt_rate(snappedf(cur, 0.1)), Balance.max_level()], 14, C_TEXT, true))
	var hint := ""
	if _viewed != GameState.active_car_id:
		hint = "Nâng xe này không đổi xe đang dùng."
	elif GameState.phase == "racing":
		hint = "Áp dụng từ lượt sau."
	if hint != "":
		v.add_child(_label(hint, 12, C_MUTED, true))
	v.add_child(_part_cta(kind, n))


func _part_cta(kind: String, n: int) -> Control:
	var state := GameState.car_upgrade_state(_viewed, kind)
	var noop := func() -> void: pass
	if state == "maxed":
		return _cta("Cấp tối đa", false, noop)
	if state == "save_error":
		return _cta("Chờ lưu", false, noop)
	if not _eligible(_viewed):
		return _cta("Xe thấp hơn hạng giải hiện tại", false, noop)
	var cost := _cost_of(kind, n)
	if _mult == 0:
		var plan := GameState.plan_buy(kind, 0, _viewed)
		if int(plan["count"]) <= 0:
			return _cta("Thiếu tiền · cần %s" % cost.format_compact(), false, noop)
		n = int(plan["count"])
		cost = plan["cost"]
	elif GameState.coins.compare(cost) < 0:
		return _cta("Thiếu tiền · cần %s" % cost.format_compact(), false, noop)
	var car := _viewed
	return _cta("Nâng %d cấp · %s tiền" % [n, cost.format_compact()], true, func() -> void:
		if GameState.buy_many_for(car, kind, _mult):
			sfx.emit("upgrade")
		else:
			sfx.emit("ui_error")
		refresh())


# ---------------------------------------------------------------- mục Ngoại hình

func _build_look_section() -> void:
	if not _owned(_viewed):
		_body.add_child(_label("Mua xe này để tùy chỉnh ngoại hình. Đang xem ngoại hình mặc định.", 13, C_MUTED, true))
		_body.add_child(_car_cta())
		return
	_body.add_child(_label("Màu sơn", 17))
	var pg := _grid(_body, 4)
	for p: Dictionary in GameData.paints():
		var id := String(p["id"])
		var on := id == _draft_paint
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 56)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(b, C_INK if on else C_CARD, Color.WHITE if on else C_TEXT, C_INK if on else C_LINE)
		b.pressed.connect(func() -> void:
			sfx.emit("ui_tab")
			_draft_paint = id
			refresh())
		var col := VBoxContainer.new()
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		var dot := Panel.new()
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.custom_minimum_size = Vector2(22, 22)
		dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var ds := _box(Color(String(p["color"])), Color("1d1f24"), 11, 1)
		dot.add_theme_stylebox_override("panel", ds)
		col.add_child(dot)
		var nm := _label(String(p["name"]), 11, Color.WHITE if on else C_TEXT)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		col.add_child(nm)
		b.add_child(col)
		pg.add_child(b)
	_body.add_child(_label("Decal", 17))
	var dg := _grid(_body, 2)
	for d: Dictionary in GameData.decals():
		var id := String(d["id"])
		dg.add_child(_choice(String(d["name"]), id == _draft_decal, func() -> void:
			_draft_decal = id
			refresh()))
	var note := "Miễn phí · Không tăng chỉ số"
	if GameState.phase == "racing" and _viewed == GameState.active_car_id:
		note += " · lượt đang đua giữ ngoại hình cũ, áp dụng từ lượt sau"
	_body.add_child(_label(note, 12, C_MUTED, true))
	var row := HBoxContainer.new()
	_body.add_child(row)
	var st := _label("Bản nháp chưa lưu" if _dirty() else "Ngoại hình đã lưu", 13, C_ORANGE if _dirty() else C_MUTED)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(st)
	var cancel := _plain("Hủy", _reset_draft)
	cancel.disabled = not _dirty()
	cancel.custom_minimum_size = Vector2(72, 44)
	row.add_child(cancel)
	_body.add_child(_cta("Lưu ngoại hình", _dirty() and not _blocked(), func() -> void: _save_look()))


func _save_look() -> bool:
	if GameState.set_cosmetics(_viewed, _draft_paint, _draft_decal):
		sfx.emit("upgrade")
		notice.emit("Đã lưu ngoại hình")
		_draft_car = ""
		_sync_draft()
		refresh()
		return true
	sfx.emit("ui_error")
	notice.emit("Không lưu được ngoại hình. Bản nháp vẫn được giữ.")
	return false


# ---------------------------------------------------------------- bộ sưu tập

func _build_collection() -> void:
	var head := HBoxContainer.new()
	add_child(head)
	var t := _label("Bộ sưu tập xe", 22)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var back := _plain("Quay lại", func() -> void:
		_collection = false
		refresh())
	back.custom_minimum_size = Vector2(96, 48)
	head.add_child(back)
	var filt := HBoxContainer.new()
	filt.add_theme_constant_override("separation", 8)
	add_child(filt)
	filt.add_child(_choice("Tất cả", not _owned_only, func() -> void:
		_owned_only = false
		refresh()))
	filt.add_child(_choice("Đã có", _owned_only, func() -> void:
		_owned_only = true
		refresh()))
	add_child(_label("Chạm một xe để xem. Việc mua hoặc chọn xe làm ở trang chi tiết.", 12, C_MUTED, true))
	var by_class := {}
	for c: Dictionary in GameData.cars():
		if _owned_only and not _owned(String(c["id"])):
			continue
		var k := int(c["class"])
		if not by_class.has(k):
			by_class[k] = []
		by_class[k].append(c)
	var classes := by_class.keys()
	classes.sort()
	for k in classes:
		add_child(_label("Hạng %d · %s" % [k, String(by_class[k][0]["class_name"])], 16, C_MUTED))
		var grid := _grid(self, 2)
		for c: Dictionary in by_class[k]:
			grid.add_child(_collection_card(c))
	if classes.is_empty():
		add_child(_label("Chưa có xe nào trong bộ lọc này.", 13, C_MUTED))


func _collection_card(c: Dictionary) -> Control:
	var id := String(c["id"])
	var owned := _owned(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 132)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var viewed := id == _viewed
	_style_button(b, Color("ffe8cf") if viewed else C_CARD, C_TEXT, C_ORANGE if viewed else C_LINE, 2 if viewed else 1)
	b.pressed.connect(func() -> void:
		sfx.emit("ui_click")
		_view_car(id))
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 0)
	var pv := CarPreview.new()
	pv.custom_minimum_size = Vector2(0, 74)
	pv.show_floor = false
	pv.angle = 0.0
	pv.dimmed = not owned
	var cos := _saved_cos(id) if owned else {"paint_id": GameData.default_paint_id(), "decal_id": GameData.default_decal_id()}
	pv.paint_id = cos["paint_id"]
	pv.decal_id = cos["decal_id"]
	col.add_child(pv)
	var nm := _label(String(c["name"]), 13)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(nm)
	var state := _card_state(id)
	var sl := _label(state, 12, C_GOOD if state == "Đang dùng" else C_MUTED)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(sl)
	b.add_child(col)
	return b


func _card_state(id: String) -> String:
	if _owned(id):
		return "Đang dùng" if id == GameState.active_car_id else "Đã có"
	if not GameState.car_unlocked(id):
		return "Khóa"
	return "Chưa mua"
