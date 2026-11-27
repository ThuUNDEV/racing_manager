class_name GaragePage
extends VBoxContainer
## Garage chuyên sâu (Design/15): xem/mua/chọn xe, nâng bốn phụ tùng theo car_id tường minh, màu sơn + decal.
## Concept Garage_Redesign_v2: bộ sưu tập tại chỗ, CTA cố định.
## Trang chỉ đọc GameState và gọi giao dịch của nó; bản nháp ngoại hình chỉ nằm trong UI.

signal sfx(cue: String)
signal notice(msg: String)
## Xe/sơn Epic chỉ bán trong Shop (Design/35 đợt E1): trang chính chuyển sang tab Shop.
signal shop_requested

const ROOT := "res://assets/workshop_gp/"
const C_BG := Color("fff8ee")
const C_CARD := Color("fffdf7")
const C_LINE := Color("d8e2df")
const C_INK := Color("0e2b5c")
const C_TEXT := Color("0e2b5c")
const C_MUTED := Color("5f7391")
const C_ORANGE := Color("f2790a")
const C_GOOD := Color("15803d")
const C_BAD := Color("c62828")

const SECTIONS := ["garage.cars", "garage.parts", "garage.appearance"]
const STAT_NAMES := {"S": "common.pace", "H": "common.grip", "B": "common.stability", "A": "common.acceleration"}
const PART_ORDER := ["engine", "tyre", "chassis", "gearbox"]
const MULTS := [1, 10, 0]  # 0 = ×Max
const STAT_ICONS := {"engine": "speedometer", "tyre": "tyre", "chassis": "stability_scales", "gearbox": "rocket_acceleration"}
const POLISH_ROOT := "res://assets/garage_soft_miniature_v2/"
const POLISH_STATS := {"engine": "stat_speed", "tyre": "stat_grip", "chassis": "stat_stability", "gearbox": "stat_acceleration"}
const STAT_CARD_ORDER := ["engine", "gearbox", "tyre", "chassis"]  # thứ tự thẻ theo concept 04-garage

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
var _rendered_section := -1
var _preview: CarPreview
var _yaw: float = CarPreview.DEFAULT_YAW  # góc xoay xe trưng bày, giữ qua các lần dựng lại
var _body: VBoxContainer
var _footer: VBoxContainer
var _support_font: FontVariation


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


## Owned cars show their real saved appearance; unowned cars use the catalogue
## preview palette in both the showroom and collection, without writing cosmetics.
func _preview_cosmetics(car_id: String) -> Dictionary:
	if _owned(car_id) or GameState.garage_cosmetics.has(car_id):
		return _saved_cos(car_id)
	var car := GameData.car(car_id)
	if car.has("default_paint"):
		return {"paint_id": String(car["default_paint"]), "decal_id": GameData.default_decal_id()}
	var variants := ["orange", "blue", "teal"] if int(car["class"]) % 2 == 1 else ["purple", "yellow", "red"]
	var variant := String(car.get("variant", "tia_chop"))
	var index := 1 if variant == "bam_duong" else (2 if variant == "ben_bi" else 0)
	return {"paint_id": variants[index], "decal_id": GameData.default_decal_id()}


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
	var parts: Array = [get_viewport_rect().size.x, _viewed, _section, _part, _mult, _draft_car, _draft_paint, _draft_decal, _collection, _owned_only,
		_confirm_buy, _pending.is_valid(), GameState.phase, GameState.save_blocked, GameState.active_car_id,
		GameState.managed_class, GameState.business_tier, GameState.unlocked_tier, GameState.owned_cars.keys().size(), (GameState.iap["buys"] as Array).size()]
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
	if size <= 14:
		if _support_font == null:
			_support_font = FontVariation.new()
			_support_font.base_font = preload("res://assets/soft_miniature_ui_v1/fonts/Nunito.ttf")
			_support_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 750.0}
		l.add_theme_font_override("font", _support_font)
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
	HdUi.style_button(b, "race" if bg == C_ORANGE or border == C_ORANGE else "upgrade" if bg == C_INK else "cancel")
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, fg)
	b.add_theme_color_override("font_disabled_color", fg.lerp(C_MUTED, 0.5))


## Flat ivory cards; selected cards use a blue border. Meta giữ lớp bo viên thuốc chung không ghi đè.
func _card_style(on: bool) -> StyleBoxFlat:
	var sb := _box(Color("e8f5fc") if on else Color("fffdf7"), Color("6cb5d5") if on else Color("ded9c8"), 14, 2 if on else 1)
	sb.set_content_margin_all(4 if get_viewport_rect().size.x < 340 else 6)
	sb.set_meta("rounded_button", true)
	return sb


func _style_card_button(b: Button, on: bool) -> void:
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, _card_style(on))
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, C_TEXT)
	b.add_theme_constant_override("outline_size", 0)


## Nút phụ dạng thẻ (decal).
func _choice(text: String, on: bool, cb: Callable, h: float = 44.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, maxf(h, 44.0))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 14)
	_style_card_button(b, on)
	b.pressed.connect(func() -> void:
		sfx.emit("ui_tab")
		cb.call())
	return b


## Quiet blue selections leave orange for transaction actions.
func _segmented(texts: Array, selected: int, cb: Callable) -> PanelContainer:
	var tray := PanelContainer.new()
	var track := _box(Color("edf5f7"), Color.TRANSPARENT, 14, 0)
	track.set_content_margin_all(0 if get_viewport_rect().size.x < 340 else 4)
	tray.add_theme_stylebox_override("panel", track)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	tray.add_child(row)
	for i in texts.size():
		var on := i == selected
		var b := Button.new()
		b.text = String(texts[i])
		b.clip_text = true
		b.custom_minimum_size = Vector2(0, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 14)
		if on:
			for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
				var face := _box(Color("c9eaf7"), Color("78b9d5"), 10, 1)
				face.set_content_margin_all(0)
				face.set_meta("rounded_button", true)
				b.add_theme_stylebox_override(state, face)
			for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
				b.add_theme_color_override(color, C_TEXT)
			b.add_theme_constant_override("outline_size", 0)
		else:
			for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
				b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
			for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
				b.add_theme_color_override(c, C_TEXT)
			b.add_theme_constant_override("outline_size", 0)
		b.pressed.connect(func() -> void:
			sfx.emit("ui_tab")
			cb.call(i))
		row.add_child(b)
	return tray


func _cta(text: String, enabled: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 16)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(b, C_ORANGE, Color.WHITE, Color("d9620a"))
	b.add_theme_color_override("font_disabled_color", Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color("8a3a05") if enabled else Color("6d7480"))
	b.add_theme_constant_override("outline_size", 0)
	var inactive := _box(Color("eeeae1"), Color("d9d5cd"), 14, 1)
	inactive.set_meta("rounded_button", true)
	b.add_theme_stylebox_override("disabled", inactive)
	b.add_theme_color_override("font_disabled_color", C_MUTED)
	b.pressed.connect(func() -> void:
		sfx.emit("ui_click")
		cb.call())
	return b


func _plain(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 14)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var face := _box(Color("f3f7f8") if state != "disabled" else Color("eeeae1"), C_LINE, 14, 1)
		face.set_meta("rounded_button", true)
		b.add_theme_stylebox_override(state, face)
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(color, C_TEXT)
	b.add_theme_color_override("font_disabled_color", C_MUTED)
	b.add_theme_constant_override("outline_size", 0)
	b.pressed.connect(func() -> void:
		sfx.emit("ui_click")
		cb.call())
	return b


func _panel(parent: Control, bg: Color = C_CARD) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", HdUi.panel())
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
	var keep_scroll := 0
	var collection_y := -1.0
	var previous := get_node_or_null("GarageContent") as ScrollContainer
	if previous != null and _rendered_section == _section:
		keep_scroll = previous.scroll_vertical
		var collection := previous.find_child("CarCollection", true, false) as Control
		if collection != null:
			collection_y = collection.position.y
	_rendered_section = _section
	for ch in get_children():
		remove_child(ch)
		ch.queue_free()
	_preview = null
	_body = null
	_collection = false
	add_theme_constant_override("separation", 6)
	_build_unsaved_bar()
	_build_showroom()
	var tabs := _segmented(SECTIONS.map(func(key: String) -> String: return I18n.t(key)), _section, func(i: int) -> void: _guard(func() -> void: _set_section(i)))
	tabs.name = "GarageTabs"
	add_child(tabs)
	var scroll := preload("res://ui/touch_scroll.gd").new()
	scroll.name = "GarageContent"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_footer = VBoxContainer.new()
	_footer.add_theme_constant_override("separation", 4)
	add_child(_footer)
	match _section:
		0: _build_car_section()
		1: _build_parts_section()
		2: _build_look_section()
	if keep_scroll > 0:
		scroll.set_deferred("scroll_vertical", keep_scroll)
		_restore_scroll.call_deferred(scroll, keep_scroll, collection_y)


func _restore_scroll(scroll: ScrollContainer, offset: int, collection_y: float) -> void:
	# Containers need a layout pass before their final scroll range is available.
	await get_tree().process_frame
	if not is_instance_valid(scroll) or scroll != get_node_or_null("GarageContent"):
		return
	var collection := scroll.find_child("CarCollection", true, false) as Control
	if collection != null and collection_y >= 0.0:
		# Comparing another car adds a stat row / changes the action height.
		# Anchor the collection instead of letting those changes move its cards.
		offset += roundi(collection.position.y - collection_y)
	scroll.scroll_vertical = maxi(0, offset)


func _build_car_identity() -> void:
	var title := HBoxContainer.new()
	title.name = "CarTitle"
	title.add_theme_constant_override("separation", 12)
	_body.add_child(title)
	title.add_child(_label(String(GameData.car(_viewed)["name"]), 18, C_TEXT, true))
	var rank := TextureRect.new()
	rank.name = "RankBadge"
	rank.texture = load(POLISH_ROOT + "rank_badge.png")
	rank.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rank.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rank.custom_minimum_size = Vector2(90, 32)
	var rank_text := _label(I18n.t("garage.class_badge") % int(GameData.car(_viewed)["class"]), 13, Color.WHITE)
	rank_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rank_text.offset_left = 26
	rank_text.offset_right = -9
	rank_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank.add_child(rank_text)
	title.add_child(rank)


func _open_collection() -> void:
	_guard(func() -> void: _set_section(0))


func _build_showroom() -> void:
	_preview = CarPreview.new()
	_preview.name = "Showroom"
	_preview.race_class_id = GameState.managed_class
	_preview.showroom_texture = preload("res://assets/garage_soft_miniature_v2/showroom.png")
	_preview.showroom_3d = true
	_preview.car_id = _viewed
	_preview.top_down = false
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview.keep_scene_ratio = false
	_preview.custom_minimum_size = Vector2(0, 104 if get_viewport_rect().size.x < 340 else 170)
	_preview.rotatable = true
	_preview.yaw = _yaw
	_preview.yaw_changed.connect(func(v: float) -> void: _yaw = v)
	add_child(_preview)
	var cos := _preview_cosmetics(_viewed)
	if _owned(_viewed):
		_preview.paint_id = _draft_paint if _draft_car == _viewed else cos["paint_id"]
		_preview.decal_id = _draft_decal if _draft_car == _viewed else cos["decal_id"]
	else:
		_preview.paint_id = cos["paint_id"]
		_preview.decal_id = cos["decal_id"]

func _status_text() -> String:
	var id := _viewed
	var racing := GameState.phase == "racing"
	var snap_car := String(GameState.race_snapshot.get("car_id", ""))
	if racing and snap_car != "" and snap_car != GameState.active_car_id:
		return I18n.t("garage.racing_next_race") % [String(GameData.car(snap_car).get("name", snap_car)), String(GameData.car(GameState.active_car_id)["name"])]
	if not _owned(id):
		if bool(GameData.car(id).get("iap_only", false)):
			return I18n.t("garage.epic_shop_only")
		if not GameState.car_unlocked(id):
			return I18n.t("garage.locked_unlock_league") % Balance.league_name(int(GameData.car(id)["entry_tier"]))
		return I18n.t("garage.not_owned_view_default_stats")
	if id == GameState.active_car_id:
		return I18n.t("garage.use") + (I18n.t("garage.changes_apply_from_next_race") if racing else "")
	if not _eligible(id):
		return I18n.t("garage.owned_tier_below_current_league") % _min_class()
	return I18n.t("garage.owned_not_selected_next_race")


func _build_unsaved_bar() -> void:
	if not _pending.is_valid():
		return
	var v := _panel(self, Color("ffe8cf"))
	v.add_child(_label(I18n.t("garage.this_car_appearance_has_unsaved"), 14, C_TEXT, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var save := _cta(I18n.t("garage.save"), not _blocked(), func() -> void:
		if _save_look():
			_run_pending())
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(save)
	var drop := _plain(I18n.t("garage.discard_changes"), func() -> void:
		_reset_draft()
		_run_pending())
	drop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(drop)
	var stay := _plain(I18n.t("garage.stay"), func() -> void:
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
	_yaw = CarPreview.DEFAULT_YAW
	_collection = false
	_confirm_buy = false
	_draft_car = ""
	refresh()


# ---------------------------------------------------------------- mục Xe

func _owned_level(kind: String) -> int:
	return GameState.car_level(_viewed, kind) if _owned(_viewed) else 0


func _build_car_summary() -> void:
	var compare := _viewed != GameState.active_car_id
	var grid := _grid(_body, 4)
	grid.name = "CarStats"
	grid.add_theme_constant_override("h_separation", 6)
	for kind: String in PART_ORDER:
		var key: String = Balance.PART_KEY[kind]
		var value := GameState.car_part_stat(_viewed, kind, _owned_level(kind))
		var values := VBoxContainer.new()
		values.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		values.add_theme_constant_override("separation", 3)
		grid.add_child(values)
		var stat_row := HBoxContainer.new()
		stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
		stat_row.add_theme_constant_override("separation", 3)
		values.add_child(stat_row)
		stat_row.add_child(_polish_art(POLISH_STATS[kind], Vector2(20, 26)))
		stat_row.add_child(_label(Balance.fmt_rate(snappedf(value, 0.1)), 18, C_GOOD))
		var name_label := _label(I18n.t(STAT_NAMES[key]), 12, C_MUTED, true)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		values.add_child(name_label)
		if compare:
			var base := GameState.car_part_stat(GameState.active_car_id, kind, GameState.level_of(kind))
			var delta := snappedf(value - base, 0.1)
			var txt := "0" if is_zero_approx(delta) else ("%s%s" % ["+" if delta > 0.0 else "−", Balance.fmt_rate(absf(delta))])
			var l := _label(txt, 13, C_GOOD if delta > 0.0 else (C_BAD if delta < 0.0 else C_MUTED))
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			values.add_child(l)
	var actions := HBoxContainer.new()
	actions.name = "CarActions"
	_body.add_child(actions)
	var upgrade := _plain("↑ " + I18n.t("garage.upgrade"), func() -> void: _set_section(1))
	upgrade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(upgrade)
	var action := _car_cta()
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(action)


func _build_car_section() -> void:
	_build_car_identity()
	_build_car_summary()
	var heading := _label(I18n.t("garage.car_collection"), 17)
	heading.name = "CollectionHeading"
	_body.add_child(heading)
	var collection_grid := _grid(_body, 3)
	collection_grid.name = "CarCollection"
	for car: Dictionary in GameData.cars():
		collection_grid.add_child(_collection_card(car))
	var epic_heading := _label(I18n.t("garage.epic_cars"), 17)
	epic_heading.name = "EpicCollectionHeading"
	_body.add_child(epic_heading)
	var epic_grid := _grid(_body, 3)
	epic_grid.name = "EpicCollection"
	for car: Dictionary in GameData.epic_cars():
		epic_grid.add_child(_collection_card(car))


## Ghi chú nhỏ kẹp giữa hai vạch kẻ.
func _divider_note(text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var note := _label(text, 12, C_MUTED, true)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.size_flags_stretch_ratio = 12.0
	for i in 2:
		var line := HSeparator.new()
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var stroke := StyleBoxLine.new()
		stroke.color = Color("c9c5b6")
		line.add_theme_stylebox_override("separator", stroke)
		row.add_child(line)
		if i == 0:
			row.add_child(note)
	return row


func _car_cta() -> Control:
	var id := _viewed
	var car := GameData.car(id)
	if not _owned(id) and bool(car.get("iap_only", false)):
		return _cta(I18n.t("garage.epic_go_shop"), not _blocked(), func() -> void: shop_requested.emit())
	if not _owned(id):
		var price := Pricing.car_price(id)
		if _confirm_buy:
			var v := VBoxContainer.new()
			v.add_child(_label(I18n.t("garage.buy_cash") % [car["name"], price.format_compact()], 14, C_TEXT, true))
			v.add_child(_label(I18n.t("garage.wallet_left_cash_car_not") % Balance.fmt_compact(GameState.coins.subtract_checked(price) if GameState.coins.compare(price) >= 0 else BigNumber.zero()), 12, C_MUTED, true))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			v.add_child(row)
			var ok := _cta(I18n.t("garage.confirm_purchase"), GameState.coins.compare(price) >= 0 and not _blocked(), func() -> void:
				_confirm_buy = false
				if GameState.buy_car(id):
					sfx.emit("upgrade")
					notice.emit(I18n.t("garage.bought") % car["name"])
				refresh())
			ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(ok)
			var no := _plain(I18n.t("common.cancel"), func() -> void:
				_confirm_buy = false
				refresh())
			no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(no)
			return v
		if _blocked():
			return _cta(I18n.t("common.saving"), false, func() -> void: pass)
		if not GameState.car_unlocked(id):
			return _cta(I18n.t("garage.unlock_league_first") % Balance.league_name(int(car["entry_tier"])), false, func() -> void: pass)
		if GameState.coins.compare(price) < 0:
			return _cta(I18n.t("garage.cash_short") % Balance.fmt_compact(price.subtract_checked(GameState.coins)), false, func() -> void: pass)
		return _cta(I18n.t("garage.buy_cash_2") % price.format_compact(), true, func() -> void:
			_confirm_buy = true
			refresh())
	if id == GameState.active_car_id:
		var status := _label("✓ " + I18n.t("common.use"), 14, C_GOOD, true)
		status.name = "EquippedStatus"
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status.custom_minimum_size.y = 44
		return status
	if _blocked():
		return _cta(I18n.t("common.saving"), false, func() -> void: pass)
	if not _eligible(id):
		return _cta(I18n.t("garage.needs_tier_car_or_higher") % _min_class(), false, func() -> void: pass)
	return _cta(I18n.t("garage.use_this_car"), true, func() -> void:
		if GameState.select_car(id):
			notice.emit(I18n.t("garage.selected") % [car["name"], I18n.t("garage.applies_from_next_race") if GameState.phase == "racing" else ""])
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


func _polish_art(id: String, extent: Vector2) -> TextureRect:
	var art := TextureRect.new()
	art.texture = load(POLISH_ROOT + id + ".png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = extent
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


func _build_parts_section() -> void:
	if not _owned(_viewed):
		_body.add_child(_car_cta())
		return
	var grid := _grid(_body, 2)
	grid.name = "PartsGrid"
	for kind: String in PART_ORDER:
		var lv := GameState.car_level(_viewed, kind)
		var stat := GameState.car_part_stat(_viewed, kind, lv)
		var next := GameState.car_part_stat(_viewed, kind, mini(lv + _target_count(kind), Balance.max_level()))
		var b := _choice("", kind == _part, func() -> void:
			_part = kind
			refresh(), 88 if get_viewport_rect().size.x < 340 else 112)
		b.name = "Part_" + kind
		grid.add_child(b)
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for edge in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + edge, 7)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(margin)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 5)
		margin.add_child(row)
		row.add_child(_polish_art("part_" + kind, Vector2(36, 48) if get_viewport_rect().size.x < 340 else Vector2(48, 60)))
		var col := VBoxContainer.new()
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 3)
		row.add_child(col)
		col.add_child(_label(I18n.t(Balance.PART_NAMES[kind]), 14, C_TEXT, true))
		var level_pill := PanelContainer.new()
		var level_face := _box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0)
		level_face.content_margin_left = 0
		level_face.content_margin_right = 0
		level_face.content_margin_top = 0
		level_face.content_margin_bottom = 0
		level_pill.add_theme_stylebox_override("panel", level_face)
		level_pill.add_child(_label(I18n.t("garage.part_level_short") % [lv, Balance.max_level()], 13, C_MUTED, true))
		col.add_child(level_pill)
		col.add_child(_label("%s → %s" % [Balance.fmt_rate(snappedf(stat, 0.1)), Balance.fmt_rate(snappedf(next, 0.1))], 13, C_GOOD, true))
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 8
		bar.max_value = Balance.max_level()
		bar.value = lv
		bar.show_percentage = false
		var track := _box(Color("e6e1d6"), Color.TRANSPARENT, 3, 0)
		track.set_content_margin_all(0)
		var fill := _box(Color("a8c9d5"), Color.TRANSPARENT, 3, 0)
		fill.set_content_margin_all(0)
		bar.custom_minimum_size.y = 5
		bar.add_theme_stylebox_override("background", track)
		bar.add_theme_stylebox_override("fill", fill)
		col.add_child(bar)
	_build_part_detail()


func _build_part_detail() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_footer.add_child(v)
	v.name = "PartPurchase"
	v.add_child(_segmented(["×1", "×10", I18n.t("garage.maximum")], MULTS.find(_mult), func(i: int) -> void:
		_mult = MULTS[i]
		refresh()))
	var lv := GameState.car_level(_viewed, _part)
	var n := _target_count(_part)
	v.add_child(_label(I18n.t(Balance.PART_NAMES[_part]) + ": " + I18n.t("garage.level_max") % [lv, lv + n, Balance.max_level()], 13, C_TEXT, true))
	var before := GameState.car_part_stat(_viewed, _part, lv)
	var after := GameState.car_part_stat(_viewed, _part, mini(lv + n, Balance.max_level()))
	v.add_child(_label(I18n.t(STAT_NAMES[Balance.PART_KEY[_part]]) + ": " + Balance.fmt_rate(snappedf(before, 0.1)) + " → " + Balance.fmt_rate(snappedf(after, 0.1)), 14, C_GOOD, true))
	v.add_child(_part_cta(_part, n))


func _part_cta(kind: String, n: int) -> Control:
	var state := GameState.car_upgrade_state(_viewed, kind)
	var noop := func() -> void: pass
	if state == "maxed":
		return _cta(I18n.t("common.max_level"), false, noop)
	if state == "save_error":
		return _cta(I18n.t("common.saving"), false, noop)
	if not _eligible(_viewed):
		return _cta(I18n.t("garage.car_below_current_league_tier"), false, noop)
	var cost := _cost_of(kind, n)
	if _mult == 0:
		var plan := GameState.plan_buy(kind, 0, _viewed)
		if int(plan["count"]) <= 0:
			return _cta(I18n.t("garage.not_enough_cash_need") % cost.format_compact(), false, noop)
		n = int(plan["count"])
		cost = plan["cost"]
	elif GameState.coins.compare(cost) < 0:
		return _cta(I18n.t("garage.not_enough_cash_need") % cost.format_compact(), false, noop)
	var car := _viewed
	return _cta(I18n.t("garage.upgrade_levels_cash") % [n, cost.format_compact()], true, func() -> void:
		if GameState.buy_many_for(car, kind, _mult):
			sfx.emit("upgrade")
		else:
			sfx.emit("ui_error")
		refresh())


# ---------------------------------------------------------------- mục Ngoại hình

func _build_look_section() -> void:
	if not _owned(_viewed):
		_body.add_child(_label(I18n.t("garage.buy_this_car_customize_its"), 13, C_MUTED, true))
		_body.add_child(_car_cta())
		return
	var paints := _panel(_body)
	(paints.get_parent() as PanelContainer).add_theme_stylebox_override("panel", _card_style(false))
	paints.add_child(_look_heading("garage.paint_color"))
	var pg := _grid(paints, 4)
	if get_viewport_rect().size.x < 340:
		pg.add_theme_constant_override("v_separation", 4)
	for p: Dictionary in GameData.paints():
		var id := String(p["id"])
		var paint_open := GameState.paint_owned(id)
		if String(p.get("epic", "")) == "car" and not paint_open:
			continue
		var on := id == _draft_paint
		var b := _choice("", on, func() -> void:
			if not paint_open:
				shop_requested.emit()
				return
			_draft_paint = id
			refresh(), 56 if get_viewport_rect().size.x < 340 else 72)
		b.name = "Paint_" + id
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var col := VBoxContainer.new()
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		var dot := _paint_swatch(Color(String(p["color"])), on)
		dot.modulate.a = 1.0 if paint_open else 0.45
		col.add_child(dot)
		if not paint_open:
			var lock := TextureRect.new()
			lock.name = "PaintLock_" + id
			lock.texture = preload("res://assets/garage_soft_miniature_v2/lock.svg")
			lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock.custom_minimum_size = Vector2(16, 19)
			lock.size = Vector2(16, 19)
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.add_child(lock)
			lock.position = (dot.custom_minimum_size - lock.size) * 0.5
		var nm := _label(String(p["name"]), 12, C_TEXT, true)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(nm)
		b.add_child(col)
		pg.add_child(b)
	var patterns := _panel(_body)
	(patterns.get_parent() as PanelContainer).add_theme_stylebox_override("panel", _card_style(false))
	patterns.add_child(_look_heading("garage.patterns"))
	var dg := _grid(patterns, 4)
	for d: Dictionary in GameData.decals():
		var id := String(d["id"])
		var on := id == _draft_decal
		var choice := _choice("", on, func() -> void:
			_draft_decal = id
			refresh(), 56 if get_viewport_rect().size.x < 340 else 74)
		choice.name = "Decal_" + id
		var col := VBoxContainer.new()
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var art := TextureRect.new()
		art.texture = load(POLISH_ROOT + "decal_" + id + ".svg")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(34, 34) if get_viewport_rect().size.x < 340 else Vector2(40, 42)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(art)
		var label := _label(String(d["name"]), 12, C_TEXT, true)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(label)
		choice.add_child(col)
		if on:
			var badge := Panel.new()
			badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			badge.offset_left = -22
			badge.offset_bottom = 22
			badge.add_theme_stylebox_override("panel", _box(Color("3587ac"), Color("236584"), 11, 1))
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var tick := _label("✓", 16, Color.WHITE)
			tick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			tick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.add_child(tick)
			choice.add_child(badge)
		dg.add_child(choice)
	var note := I18n.t("garage.free_no_stat_boost")
	if GameState.phase == "racing" and _viewed == GameState.active_car_id:
		note += I18n.t("garage.current_race_keeps_old_look")
	_footer.tooltip_text = note
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_footer.add_child(row)
	var cancel := _plain(I18n.t("common.cancel"), _reset_draft)
	cancel.disabled = not _dirty()
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cancel)
	var save := _cta(I18n.t("garage.save"), _dirty() and not _blocked(), func() -> void: _save_look())
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(save)
	var status := _label("ⓘ " + (I18n.t("garage.unsaved_draft") if _dirty() else I18n.t("garage.saved_appearance")), 13, C_GOOD if _dirty() else C_MUTED, true)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.add_child(status)


func _save_look() -> bool:
	if GameState.set_cosmetics(_viewed, _draft_paint, _draft_decal):
		sfx.emit("upgrade")
		notice.emit(I18n.t("garage.appearance_saved"))
		_draft_car = ""
		_sync_draft()
		refresh()
		return true
	sfx.emit("ui_error")
	notice.emit(I18n.t("garage.could_not_save_appearance_draft"))
	return false


# ---------------------------------------------------------------- bộ sưu tập

func _collection_card(c: Dictionary) -> Control:
	var id := String(c["id"])
	var owned := _owned(id)
	var b := Button.new()
	b.name = "Collection_" + id
	b.custom_minimum_size = Vector2(0, 120)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var viewed := id == _viewed
	_style_card_button(b, viewed)
	b.pressed.connect(func() -> void:
		sfx.emit("ui_click")
		_guard(func() -> void: _view_car(id)))
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 0)
	var pv := CarPreview.new()
	pv.name = "CarPreview"
	pv.race_class_id = GameState.managed_class
	pv.car_id = id
	pv.custom_minimum_size = Vector2(0, 48 if get_viewport_rect().size.x < 340 else 54)
	pv.show_floor = false
	pv.dimmed = false
	var cos := _preview_cosmetics(id)
	pv.paint_id = cos["paint_id"]
	pv.decal_id = cos["decal_id"]
	col.add_child(pv)
	var nm := _label(String(c["name"]), 13, C_TEXT, true)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(nm)
	var active := id == GameState.active_car_id
	var state := _card_state(id)
	var badge := HdUi.Soft.pill(state, Color("c5eca5") if active else Color("edf0ef"), 12)
	col.add_child(badge)
	if not owned and not GameState.car_unlocked(id) and not bool(c.get("iap_only", false)):
		var lock := TextureRect.new()
		lock.name = "LockedBadge"
		lock.texture = preload("res://assets/garage_soft_miniature_v2/lock.svg")
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.position = Vector2(-25, 5)
		lock.size = Vector2(22, 26)
		lock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lock)
	b.add_child(col)
	return b


func _card_state(id: String) -> String:
	if _owned(id):
		return I18n.t("common.use") if id == GameState.active_car_id else I18n.t("common.owned")
	if bool(GameData.car(id).get("iap_only", false)):
		return I18n.t("garage.epic_shop_tag")
	if not GameState.car_unlocked(id):
		return I18n.t("common.locked")
	return I18n.t("garage.not_owned")


func _look_heading(key: String) -> Control:
	return _label(I18n.t(key), 16)


func _paint_swatch(color: Color, selected: bool) -> Control:
	var swatch := Control.new()
	swatch.custom_minimum_size = Vector2(30, 30) if get_viewport_rect().size.x < 340 else Vector2(42, 42)
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.draw.connect(func() -> void:
		var center := swatch.size * 0.5
		var scale_factor := swatch.size.x / 42.0
		swatch.draw_set_transform(center, 0, Vector2.ONE * scale_factor)
		center = Vector2.ZERO
		swatch.draw_circle(center + Vector2(0, 2), 18, Color(0.2, 0.12, 0.05, 0.18))
		if selected:
			swatch.draw_circle(center, 21, Color("3587ac"))
			swatch.draw_circle(center, 19, Color("dff3fc"))
		swatch.draw_circle(center, 17, color.darkened(0.35))
		for radius in range(16, 0, -1):
			var t := float(radius) / 16.0
			swatch.draw_circle(center + Vector2(-1, -1), radius, color.lightened((1.0-t)*0.22))
		swatch.draw_arc(center, 14, PI*1.1, PI*1.8, 24, Color(1,1,1,0.5), 1.5, true))
	if selected:
		var tick := _label("✓", 20 if get_viewport_rect().size.x < 340 else 25, Color.WHITE)
		tick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tick.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		swatch.add_child(tick)
	return swatch
