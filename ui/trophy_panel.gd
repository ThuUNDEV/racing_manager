class_name TrophyPanel
extends RefCounted

## Approved League layout, using the reduced-gloss artwork.
const C_TEXT := HdUi.C_TEXT
const C_MUTED := HdUi.C_MUTED
const C_GREEN := HdUi.C_GREEN
const C_BLUE := Color("206ce1")
const C_LINE := Color("cfdef2")
const C_SOFT := Color("edf4fd")
const RANK_COLORS := [Color("946300"), Color("62728a"), Color("a05c32")]
const ART := "res://assets/league_redesign/"
static var _textures: Dictionary = {}


static func build(parent: Control, group: String, on_group: Callable, on_buy: Callable, on_info: Callable = Callable()) -> void:
	var box := VBoxContainer.new()
	box.name = "TrophyPanel"
	box.add_theme_constant_override("separation", 5)
	box.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var header := PanelContainer.new()
	header.name = "LeagueHeader"
	header.custom_minimum_size.y = 80
	header.add_theme_stylebox_override("panel", HdUi.Soft.surface("section_tall", Vector4(4, 3, 4, 3)))
	var title := HBoxContainer.new()
	header.add_child(title)
	title.add_child(HdUi.Soft.art("nav_league", Vector2(120, 78)))
	var name := _label(I18n.t("trophy.league") + Balance.league_name(GameState.business_tier), 30, HdUi.Soft.INK, true)
	name.add_theme_font_override("font", HdUi.font())
	name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.add_child(name)
	box.add_child(header)
	box.add_child(_banner(on_info))
	box.add_child(_filter(group, on_group))
	box.add_child(HdUi.Soft.heading(I18n.t("trophy.upgrade_with_trophies"), "nav_race", 44))
	for u: Dictionary in GameData.trophy_upgrades():
		if u["group"] == group and GameState.trophy_unlocked(String(u["id"])):
			box.add_child(_card(u, on_buy))



static func _label(text: String, size: int, color: Color, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func _flat(bg: Color, line: Color, radius: int, padding: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = line
	sb.set_border_width_all(0 if line.a == 0.0 else 1)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = padding
	sb.content_margin_right = padding
	sb.content_margin_top = padding
	sb.content_margin_bottom = padding
	return sb


static func _surface(bg: Color, line: Color, radius: int = 14, padding: int = 12) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.mouse_filter = Control.MOUSE_FILTER_PASS
	pc.add_theme_stylebox_override("panel", _flat(bg, line, radius, padding))
	return pc


static func _texture(folder: String, asset: String) -> Texture2D:
	var alias: String = {"trophy": "trophy_large", "speed_tune": "engine", "launch_control": "gearbox", "corner_grip": "tyre", "sponsor": "currency_cash", "overtake_kit": "spoiler", "stability": "stability_scales"}.get(asset, "")
	if alias != "":
		return HdUi.Soft.texture(alias)
	var path := ART + folder + "/" + asset + ".png"
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path] as Texture2D


static func _icon(asset: String, dimensions: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = _texture("icons", asset)
	image.custom_minimum_size = dimensions
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


static func _skin(asset: String, padding: int = 12) -> StyleBoxTexture:
	var kind := "panel"
	if asset == "league_header": kind = "hud"
	elif asset.begins_with("buy_"): kind = "disabled" if asset.contains("locked") or asset.contains("disabled") else "orange"
	elif asset.begins_with("tab_"): kind = "orange" if asset == "tab_active" else "cancel"
	elif asset == "upgrade_locked": kind = "locked"
	elif asset in ["icon_tile", "reward_pill"]: kind = "selected"
	return HdUi.Soft.surface(kind, Vector4.ONE * padding)


static func _art_surface(asset: String, padding: int = 12) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", _skin(asset, padding))
	return panel


static func _banner(on_info: Callable) -> PanelContainer:
	var gs := GameState
	var pc := _art_surface("trophy_summary", 6)
	pc.name = "TrophyBanner"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	pc.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	top.add_child(_icon("trophy", Vector2(68, 60)))
	var divider := ColorRect.new()
	divider.color = Color("e2bd63")
	divider.custom_minimum_size = Vector2(1, 52)
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(divider)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 0)
	mid.add_child(_label(I18n.t("trophy.trophies_owned"), 16, C_TEXT, true))
	var amount := HBoxContainer.new()
	amount.add_theme_constant_override("separation", 5)
	var count := _label(str(gs.trophies), 39, Color("1b8a1b"))
	count.name = "TrophyCount"
	amount.add_child(count)
	var unit := _label(I18n.t("trophy.trophies_2"), 15, C_TEXT)
	unit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	amount.add_child(unit)
	mid.add_child(amount)
	top.add_child(mid)
	var multiplier := HdUi.Soft.pill("×%d" % maxi(1, GameData.trophy_reward(3, gs.business_tier)), Color("c9efbf"), 24)
	multiplier.custom_minimum_size = Vector2(48, 0)
	multiplier.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if on_info.is_valid():
		var info := Button.new()
		info.name = "TrophyInfo"
		info.text = "i"
		info.accessibility_name = I18n.t("trophy.rules")
		info.custom_minimum_size = Vector2(30, 30)
		info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		info.add_theme_font_size_override("font_size", 16)
		info.add_theme_color_override("font_color", Color.WHITE)
		info.add_theme_color_override("font_hover_color", Color.WHITE)
		info.add_theme_color_override("font_pressed_color", Color.WHITE)
		for st: String in ["normal", "hover", "pressed", "focus"]:
			info.add_theme_stylebox_override(st, _flat(Color("2f8fd8"), Color("ffffff"), 15, 0))
		info.pressed.connect(on_info)
		top.add_child(info)
	top.add_child(multiplier)
	# Thanh tiến độ dày, số đã kiếm / trần nằm ngay trong thanh.
	var bar := ProgressBar.new()
	bar.name = "TrophyCapProgress"
	bar.show_percentage = false
	bar.max_value = maxf(1.0, float(gs.trophy_cap()))
	bar.value = float(mini(gs.trophies_earned, gs.trophy_cap()))
	bar.custom_minimum_size = Vector2(0, 20)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_stylebox_override("background", _flat(Color("e5ddc9"), Color.TRANSPARENT, 10, 0))
	bar.add_theme_stylebox_override("fill", _flat(Color("ffbf1d"), Color.TRANSPARENT, 10, 0))
	var earned := _label("%d / %d" % [gs.trophies_earned, gs.trophy_cap()], 13, C_TEXT)
	earned.name = "TrophyEarned"
	earned.set_anchors_preset(Control.PRESET_FULL_RECT)
	earned.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	earned.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	earned.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(earned)
	v.add_child(bar)
	return pc


static func _filter(group: String, on_group: Callable) -> PanelContainer:
	var pc := _surface(Color.TRANSPARENT, Color.TRANSPARENT, 12, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	pc.add_child(row)
	for g: Dictionary in GameData.trophy_groups():
		var id: String = g["id"]
		var b := Button.new()
		b.name = "Group_" + id
		b.text = String(g["name"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 66)
		b.add_theme_font_size_override("font_size", 17 if b.text.length() <= 9 else 14)
		b.icon = _texture("icons", id)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 34)
		b.add_theme_constant_override("h_separation", 3)
		b.clip_text = true
		b.toggle_mode = true
		b.button_pressed = id == group
		var inactive := HdUi.Soft.surface("panel", Vector4(4, 4, 4, 4))
		b.add_theme_stylebox_override("normal", inactive)
		b.add_theme_stylebox_override("hover", inactive)
		b.add_theme_stylebox_override("pressed", _skin("tab_active", 4))
		b.add_theme_stylebox_override("hover_pressed", _skin("tab_active", 4))
		b.add_theme_color_override("font_color", C_TEXT)
		b.add_theme_color_override("font_hover_color", C_TEXT)
		b.add_theme_color_override("font_focus_color", Color.WHITE if id == group else C_TEXT)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
		HdUi.ButtonSkin.apply(b)
		b.pressed.connect(func() -> void: on_group.call(id))
		row.add_child(b)
		if group_can_upgrade(id):
			b.add_child(_notify_dot())
	return pc


## Nhóm có ít nhất một nâng cấp đã mở khoá, chưa tối đa và đủ cúp để mua.
static func group_can_upgrade(group: String) -> bool:
	if GameState.phase == "save_error" or GameState.save_blocked:
		return false
	for u: Dictionary in GameData.trophy_upgrades():
		if u["group"] != group:
			continue
		var id: String = u["id"]
		if GameState.trophy_unlocked(id) and GameState.trophy_cost(id) > 0 \
				and GameState.trophies >= GameState.trophy_cost(id):
			return true
	return false


static func _notify_dot() -> Panel:
	var dot := Panel.new()
	dot.name = "NotifyDot"
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dot.offset_left = -16
	dot.offset_right = -4
	dot.offset_top = 4
	dot.offset_bottom = 16
	var sb := _flat(Color("ff3b30"), Color.WHITE, 6, 0)
	sb.set_border_width_all(2)
	dot.add_theme_stylebox_override("panel", sb)
	return dot


## Số cụ thể và đơn vị lấy từ cấu hình, kể cả hiệu ứng kép và cấp tối đa.
static func effect_lines(u: Dictionary, level: int, maxed: bool) -> Array:
	var labels := GameData.trophy_effect_labels()
	var units := GameData.trophy_effect_units()
	var cur := GameState.trophy_effect_at(String(u["id"]), level)
	var nxt := GameState.trophy_effect_at(String(u["id"]), level + 1)
	var out: Array = []
	for k: String in cur:
		var unit := String(units.get(k, ""))
		var name := String(labels.get(k, k))
		if maxed:
			out.append("%s  +%d%s" % [name, int(cur[k]), unit])
		else:
			out.append("%s  +%d → +%d%s" % [name, int(cur[k]), int(nxt.get(k, cur[k])), unit])
	return out


static func _card(u: Dictionary, on_buy: Callable) -> PanelContainer:
	var id: String = u["id"]
	var lv := GameState.trophy_level(id)
	var max_lv := int(u["max_level"])
	var total_lv := GameState.trophy_total_levels(id)
	var maxed := lv >= total_lv
	var unlocked := GameState.trophy_unlocked(id)
	var pc := _art_surface("upgrade_card", 7)
	if not unlocked:
		# Thẻ khoá: nền phẳng xám kem (texture button_disabled bị kéo thành viên thuốc khổng lồ).
		pc.add_theme_stylebox_override("panel", _flat(Color("efe9dc"), Color("d9d0b8"), 16, 7))
	pc.name = "Upgrade_" + id
	pc.custom_minimum_size.y = 87
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	pc.add_child(row)
	row.add_child(_icon(id, Vector2(82, 71)))
	var card_divider := ColorRect.new()
	card_divider.color = Color("cfc6b0") if unlocked else Color("d9d0b8")
	card_divider.custom_minimum_size = Vector2(1, 60)
	card_divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(card_divider)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(v)
	v.add_child(_label(String(u["name"]), 19, C_TEXT if unlocked else C_MUTED, true))
	var level := _label(I18n.t("trophy.level") % [lv, max_lv], 15, C_TEXT)
	level.name = "TrophyLevel_" + id
	v.add_child(level)
	if not unlocked:
		var lock_text := _label(I18n.t("trophy.unlocks_league") + Balance.league_name(int(u["unlock_league"])), 11, C_MUTED, true)
		lock_text.name = "UnlockLeague"
		v.add_child(lock_text)
		var lock_btn := Button.new()
		lock_btn.name = "Locked_" + id
		lock_btn.disabled = true
		lock_btn.custom_minimum_size = Vector2(78, 44)
		lock_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lock_btn.icon = load("res://assets/workshop_gp/icons/vector/lock.svg") as Texture2D
		lock_btn.expand_icon = true
		lock_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_btn.add_theme_constant_override("icon_max_width", 24)
		for st: String in ["normal", "hover", "pressed", "disabled"]:
			lock_btn.add_theme_stylebox_override(st, _skin("buy_disabled", 8))
		HdUi.ButtonSkin.apply(lock_btn)
		row.add_child(lock_btn)
		return pc
	for text: String in effect_lines(u, lv, maxed):
		var effect := PanelContainer.new()
		effect.add_theme_stylebox_override("panel", HdUi.Soft.flat(Color("d3f2c6"), 3, 9))
		effect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var effect_row := HBoxContainer.new()
		effect_row.add_theme_constant_override("separation", 3)
		effect.add_child(effect_row)
		var gauge := TextureRect.new()
		gauge.texture = HdUi.Soft.icon("speed")
		gauge.custom_minimum_size = Vector2(13, 13)
		gauge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gauge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect_row.add_child(gauge)
		var effect_label := _label(text, 13, C_GREEN)
		effect_label.name = "Effect"
		effect_label.clip_text = true
		effect_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		effect_row.add_child(effect_label)
		v.add_child(effect)
	row.add_child(_buy_button(u, maxed, on_buy))
	return pc


static func _buy_button(u: Dictionary, maxed: bool, on_buy: Callable) -> Button:
	var id: String = u["id"]
	var b := Button.new()
	b.name = "Buy_" + id
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size = Vector2(78, 44)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _skin("buy_normal", 8))
	b.add_theme_stylebox_override("hover", _skin("buy_normal", 8))
	b.add_theme_stylebox_override("pressed", _skin("buy_pressed", 8))
	b.add_theme_stylebox_override("disabled", _skin("buy_disabled", 8))
	HdUi.ButtonSkin.apply(b)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("e9edf3"))
	b.add_theme_color_override("font_outline_color", Color("8a4a08"))
	b.add_theme_constant_override("outline_size", 4)
	if maxed:
		b.text = I18n.t("trophy.max")
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = true
		return b
	var cost := GameState.trophy_cost(id)
	b.text = str(cost)
	b.add_theme_font_size_override("font_size", 22 if b.text.length() <= 2 else (18 if b.text.length() == 3 else 15))
	b.icon = _texture("icons", "trophy")
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 22)
	b.add_theme_constant_override("h_separation", 5)
	var blocked := GameState.phase == "save_error" or GameState.save_blocked
	b.disabled = GameState.trophies < cost or blocked
	b.pressed.connect(func() -> void: on_buy.call(id))
	return b


## Nội dung popup luật cúp: mức thưởng top 3 và giải thích giới hạn.
static func rules_content(parent: Control) -> void:
	var gs := GameState
	parent.add_child(_label(I18n.t("trophy.top_3_reward"), 14, C_TEXT))
	var rewards := HBoxContainer.new()
	rewards.name = "TrophyRewards"
	rewards.add_theme_constant_override("separation", 5)
	for p in 3:
		var pill := _surface(Color("fff1c9"), Color("e2bd63"), 12, 5)
		pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var reward_row := HBoxContainer.new()
		reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
		reward_row.add_theme_constant_override("separation", 3)
		pill.add_child(reward_row)
		reward_row.add_child(_icon(["medal_gold", "medal_silver", "medal_bronze"][p], Vector2(20, 24)))
		reward_row.add_child(_label("P%d +%d" % [p + 1, GameData.trophy_reward(p + 1, gs.business_tier)], 12, RANK_COLORS[p]))
		rewards.add_child(pill)
	parent.add_child(rewards)
	var details := _label(I18n.t("trophy.trophies_are_only_earned_by"), 12, C_MUTED, true)
	details.name = "TrophyCapInfo"
	parent.add_child(details)
	if gs.trophies_earned >= gs.trophy_cap():
		var hint := I18n.t("trophy.trophy_cap_reached_no_more")
		var next_cap := GameData.trophy_cap_for_league(gs.business_tier + 1) + maxi(0, gs.trophy_cap_bonus)
		if next_cap > gs.trophy_cap():
			hint += I18n.t("trophy.advance_next_league_raise_cap") % next_cap
		parent.add_child(_label(hint, 11, HdUi.C_RED, true))
