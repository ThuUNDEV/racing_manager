class_name TrophyPanel
extends RefCounted

## Layout Giải: số dư/trần cúp, ba nhóm và thẻ nâng cấp gọn.
const C_TEXT := HdUi.C_TEXT
const C_MUTED := HdUi.C_MUTED
const C_GREEN := HdUi.C_GREEN
const C_BLUE := Color("206ce1")
const C_LINE := Color("cfdef2")
const C_SOFT := Color("edf4fd")
const GROUP_ICONS := {"offense": "energy", "defense": "tools", "income": "cash"}
const RANK_COLORS := [Color("946300"), Color("62728a"), Color("a05c32")]


static func build(parent: Control, group: String, on_group: Callable, on_buy: Callable) -> void:
	var box := VBoxContainer.new()
	box.name = "TrophyPanel"
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", 8)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 1)
	names.add_child(_label("GIẢI ĐẤU", 10, C_MUTED))
	names.add_child(_label("Giải " + Balance.league_name(GameState.business_tier), 22, C_TEXT, true))
	title.add_child(names)
	var multiplier := maxi(1, GameData.trophy_reward(3, GameState.business_tier))
	var badge := _surface(Color.WHITE, C_LINE, 8, 6)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_child(_label("CÚP ×%d" % multiplier, 10, C_BLUE))
	title.add_child(badge)
	box.add_child(title)
	box.add_child(_banner())
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 6)
	heading.add_child(_label("Nâng cấp bằng cúp", 14, C_TEXT, true))
	var note := _label("Áp dụng từ lượt sau", 10, C_MUTED)
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(note)
	box.add_child(heading)
	box.add_child(_filter(group, on_group))
	for u: Dictionary in GameData.trophy_upgrades():
		if u["group"] == group:
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


static func _banner() -> PanelContainer:
	var gs := GameState
	var pc := _surface(Color("fff8e7"), Color("e7c878"), 16, 12)
	pc.name = "TrophyBanner"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	pc.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	top.add_child(HdUi.icon("icons/trophy.png", Vector2(42, 42)))
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 0)
	mid.add_child(_label("Cúp đang có", 12, C_MUTED))
	var amount := HBoxContainer.new()
	amount.add_theme_constant_override("separation", 5)
	var count := _label(str(gs.trophies), 28, Color("8c5300"))
	count.name = "TrophyCount"
	amount.add_child(count)
	var unit := _label("cúp", 13, Color("8c5300"))
	unit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	amount.add_child(unit)
	mid.add_child(amount)
	top.add_child(mid)
	var info := Button.new()
	info.name = "TrophyInfo"
	info.text = "i"
	info.toggle_mode = true
	info.custom_minimum_size = Vector2(32, 32)
	info.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	info.tooltip_text = "Giới hạn tổng cúp đã kiếm, tính cả cúp đã tiêu"
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		info.add_theme_color_override(state, C_MUTED)
	info.add_theme_stylebox_override("normal", _flat(Color.WHITE, C_LINE, 16, 0))
	info.add_theme_stylebox_override("hover", _flat(C_SOFT, C_LINE, 16, 0))
	info.add_theme_stylebox_override("pressed", _flat(C_SOFT, C_BLUE, 16, 0))
	top.add_child(info)
	var earned_row := HBoxContainer.new()
	var earned_title := _label("Tổng đã kiếm", 11, C_MUTED)
	earned_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	earned_row.add_child(earned_title)
	var earned := _label("%d / %d" % [gs.trophies_earned, gs.trophy_cap()], 11, C_TEXT)
	earned.name = "TrophyEarned"
	earned_row.add_child(earned)
	v.add_child(earned_row)
	var bar := ProgressBar.new()
	bar.name = "TrophyCapProgress"
	bar.show_percentage = false
	bar.max_value = maxf(1.0, float(gs.trophy_cap()))
	bar.value = float(mini(gs.trophies_earned, gs.trophy_cap()))
	bar.custom_minimum_size = Vector2(0, 6)
	bar.add_theme_stylebox_override("background", _flat(Color("e5ddc9"), Color.TRANSPARENT, 3, 0))
	bar.add_theme_stylebox_override("fill", _flat(Color("ffbf1d"), Color.TRANSPARENT, 3, 0))
	v.add_child(bar)
	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation", 8)
	var reward_title := _label("Thưởng top 3", 11, C_MUTED)
	reward_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards.add_child(reward_title)
	for p in 3:
		rewards.add_child(_label("P%d +%d" % [p + 1, GameData.trophy_reward(p + 1, gs.business_tier)], 11, RANK_COLORS[p]))
	v.add_child(rewards)
	var details := _label("Cúp chỉ nhận khi về đích top 3. Giới hạn tính cả cúp đã tiêu; dùng cúp không làm giảm tổng đã kiếm. Trần tăng khi lên giải.", 11, C_MUTED, true)
	details.name = "TrophyCapInfo"
	details.visible = false
	v.add_child(details)
	info.toggled.connect(func(pressed: bool) -> void: details.visible = pressed)
	if gs.trophies_earned >= gs.trophy_cap():
		var hint := "Đã chạm trần cúp, không nhận thêm."
		var next_cap := GameData.trophy_cap_for_league(gs.business_tier + 1) + maxi(0, gs.trophy_cap_bonus)
		if next_cap > gs.trophy_cap():
			hint += " Lên giải tiếp theo để mở trần %d." % next_cap
		v.add_child(_label(hint, 11, HdUi.C_RED, true))
	return pc


static func _filter(group: String, on_group: Callable) -> PanelContainer:
	var pc := _surface(C_LINE, C_LINE, 12, 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	pc.add_child(row)
	for g: Dictionary in GameData.trophy_groups():
		var id: String = g["id"]
		var b := Button.new()
		b.name = "Group_" + id
		b.text = String(g["name"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 40)
		b.add_theme_font_size_override("font_size", 12)
		b.clip_text = true
		b.toggle_mode = true
		b.button_pressed = id == group
		b.add_theme_stylebox_override("normal", _flat(C_LINE, C_LINE, 8, 3))
		b.add_theme_stylebox_override("hover", _flat(C_SOFT, C_SOFT, 8, 3))
		b.add_theme_stylebox_override("pressed", _flat(C_BLUE, C_BLUE, 8, 3))
		b.add_theme_stylebox_override("hover_pressed", _flat(C_BLUE, C_BLUE, 8, 3))
		b.add_theme_color_override("font_color", C_TEXT)
		b.add_theme_color_override("font_hover_color", C_TEXT)
		b.add_theme_color_override("font_focus_color", C_TEXT)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
		b.pressed.connect(func() -> void: on_group.call(id))
		row.add_child(b)
	return pc


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
	var maxed := lv >= max_lv
	var unlocked := GameState.trophy_unlocked(id)
	var pc := _surface(Color.WHITE if unlocked else C_SOFT, C_LINE)
	pc.name = "Upgrade_" + id
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	v.add_child(head)
	var icon_box := _surface(C_SOFT, C_SOFT, 10, 5)
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_box.add_child(HdUi.icon("icons/%s.png" % GROUP_ICONS.get(u["group"], "trophy"), Vector2(28, 28)))
	head.add_child(icon_box)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 1)
	names.add_child(_label(String(u["name"]), 15, C_TEXT if unlocked else C_MUTED, true))
	names.add_child(_label("Cấp %d / %d" % [lv, max_lv], 11, C_MUTED))
	head.add_child(names)
	if not unlocked:
		var lock_text := _label("Mở ở giải " + Balance.league_name(int(u["unlock_league"])), 11, C_MUTED, true)
		lock_text.name = "UnlockLeague"
		v.add_child(lock_text)
		return pc
	v.add_child(_label(String(u["description"]), 11, C_MUTED, true))
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	var effects := VBoxContainer.new()
	effects.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effects.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	effects.add_theme_constant_override("separation", 2)
	for text: String in effect_lines(u, lv, maxed):
		var l := _label(text, 12, C_MUTED if maxed else C_GREEN, true)
		l.name = "Effect"
		effects.add_child(l)
	bottom.add_child(effects)
	bottom.add_child(_buy_button(u, maxed, on_buy))
	v.add_child(bottom)
	return pc


static func _buy_button(u: Dictionary, maxed: bool, on_buy: Callable) -> Button:
	var id: String = u["id"]
	var b := Button.new()
	b.name = "Buy_" + id
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size = Vector2(90, 40)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _flat(Color("ffcb39"), Color("ce9000"), 10, 8))
	b.add_theme_stylebox_override("hover", _flat(Color("ffdb65"), Color("ce9000"), 10, 8))
	b.add_theme_stylebox_override("pressed", _flat(Color("efaf11"), Color("ce9000"), 10, 8))
	b.add_theme_stylebox_override("disabled", _flat(C_SOFT, C_LINE, 10, 8))
	b.add_theme_color_override("font_color", Color("503600"))
	b.add_theme_color_override("font_hover_color", Color("503600"))
	b.add_theme_color_override("font_pressed_color", Color("503600"))
	b.add_theme_color_override("font_focus_color", Color("503600"))
	b.add_theme_color_override("font_disabled_color", C_MUTED)
	if maxed:
		b.text = "TỐI ĐA"
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = true
		return b
	var cost := GameState.trophy_cost(id)
	b.text = str(cost)
	var src := HdUi.tex("icons/trophy.png")
	var f := minf(1.0, 2.4 * 24.0 / float(maxi(src.get_width(), src.get_height())))
	b.icon = HdUi.scaled("icons/trophy.png", f) if f < 1.0 else src
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 22)
	b.add_theme_constant_override("h_separation", 5)
	var blocked := GameState.phase == "save_error" or GameState.save_blocked
	b.disabled = GameState.trophies < cost or blocked
	b.tooltip_text = "%s · %d cúp" % [String(u["name"]), cost]
	b.pressed.connect(func() -> void: on_buy.call(id))
	return b
