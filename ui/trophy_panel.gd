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


static func build(parent: Control, group: String, on_group: Callable, on_buy: Callable) -> void:
	var box := VBoxContainer.new()
	box.name = "TrophyPanel"
	box.add_theme_constant_override("separation", 5)
	box.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", 8)
	var header := _art_surface("league_header", 13)
	header.name = "LeagueHeader"
	header.custom_minimum_size.y = 58
	header.add_child(title)
	var accent := ColorRect.new()
	accent.color = Color("ffcd39")
	accent.custom_minimum_size = Vector2(3, 34)
	accent.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_child(accent)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 1)
	names.add_child(_label(I18n.t("trophy.leagues"), 10, Color("e4efff")))
	names.add_child(_label(I18n.t("trophy.league") + Balance.league_name(GameState.business_tier), 21, Color.WHITE, true))
	title.add_child(names)
	var multiplier := maxi(1, GameData.trophy_reward(3, GameState.business_tier))
	var badge := _surface(Color.WHITE, C_LINE, 8, 6)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 3)
	badge_row.add_child(_icon("trophy", Vector2(22, 24)))
	badge_row.add_child(_label(I18n.t("trophy.trophies_x") % multiplier, 10, C_BLUE))
	badge.add_child(badge_row)
	title.add_child(badge)
	box.add_child(header)
	box.add_child(_banner())
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 6)
	heading.add_child(_label(I18n.t("trophy.upgrade_with_trophies"), 14, C_TEXT, true))
	var note := _label(I18n.t("trophy.applies_from_next_race"), 10, C_MUTED)
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


static func _texture(folder: String, asset: String) -> Texture2D:
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
	var skin := StyleBoxTexture.new()
	skin.texture = _texture("panels", asset)
	var margin := minf(20 if asset == "icon_tile" else 16, floorf((skin.texture.get_height() - 1) / 2.0))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		skin.set_texture_margin(side, margin)
		skin.set_content_margin(side, padding)
	if asset.begins_with("buy_") or asset.begins_with("tab_"):
		return HdUi.ButtonSkin.rounded(skin) as StyleBoxTexture
	return skin


static func _art_surface(asset: String, padding: int = 12) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", _skin(asset, padding))
	return panel


static func _banner() -> PanelContainer:
	var gs := GameState
	var pc := _art_surface("trophy_summary", 11)
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
	mid.add_child(_label(I18n.t("trophy.trophies_owned"), 14, C_TEXT, true))
	var amount := HBoxContainer.new()
	amount.add_theme_constant_override("separation", 5)
	var count := _label(str(gs.trophies), 34, Color("795000"))
	count.name = "TrophyCount"
	amount.add_child(count)
	var unit := _label(I18n.t("trophy.trophies_2"), 13, Color("8c5300"))
	unit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	amount.add_child(unit)
	mid.add_child(amount)
	top.add_child(mid)
	var info := Button.new()
	info.name = "TrophyInfo"
	info.text = "i"
	info.toggle_mode = true
	info.custom_minimum_size = Vector2(36, 36)
	info.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		info.add_theme_color_override(state, C_MUTED)
	info.add_theme_stylebox_override("normal", _flat(Color.WHITE, C_LINE, 16, 0))
	info.add_theme_stylebox_override("hover", _flat(C_SOFT, C_LINE, 16, 0))
	info.add_theme_stylebox_override("pressed", _flat(C_SOFT, C_BLUE, 16, 0))
	HdUi.ButtonSkin.apply(info)
	top.add_child(info)
	var earned_row := HBoxContainer.new()
	var earned_title := _label(I18n.t("trophy.total_earned"), 11, C_MUTED)
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
	bar.custom_minimum_size = Vector2(0, 7)
	bar.add_theme_stylebox_override("background", _flat(Color("e5ddc9"), Color.TRANSPARENT, 3, 0))
	bar.add_theme_stylebox_override("fill", _flat(Color("ffbf1d"), Color.TRANSPARENT, 3, 0))
	v.add_child(bar)
	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation", 5)
	v.add_child(_label(I18n.t("trophy.top_3_reward"), 10, C_MUTED))
	for p in 3:
		var pill := _art_surface("reward_pill", 5)
		var reward_row := HBoxContainer.new()
		reward_row.add_theme_constant_override("separation", 3)
		pill.add_child(reward_row)
		reward_row.add_child(_icon(["medal_gold", "medal_silver", "medal_bronze"][p], Vector2(20, 24)))
		reward_row.add_child(_label("P%d +%d" % [p + 1, GameData.trophy_reward(p + 1, gs.business_tier)], 11, RANK_COLORS[p]))
		rewards.add_child(pill)
	v.add_child(rewards)
	var details := _label(I18n.t("trophy.trophies_are_only_earned_by"), 11, C_MUTED, true)
	details.name = "TrophyCapInfo"
	details.visible = false
	v.add_child(details)
	info.toggled.connect(func(pressed: bool) -> void: details.visible = pressed)
	if gs.trophies_earned >= gs.trophy_cap():
		var hint := I18n.t("trophy.trophy_cap_reached_no_more")
		var next_cap := GameData.trophy_cap_for_league(gs.business_tier + 1) + maxi(0, gs.trophy_cap_bonus)
		if next_cap > gs.trophy_cap():
			hint += I18n.t("trophy.advance_next_league_raise_cap") % next_cap
		v.add_child(_label(hint, 11, HdUi.C_RED, true))
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
		b.custom_minimum_size = Vector2(0, 44)
		b.add_theme_font_size_override("font_size", 12)
		b.icon = _texture("icons", id)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 21)
		b.add_theme_constant_override("h_separation", 3)
		b.clip_text = true
		b.toggle_mode = true
		b.button_pressed = id == group
		b.add_theme_stylebox_override("normal", _skin("tab_inactive", 4))
		b.add_theme_stylebox_override("hover", _skin("tab_inactive", 4))
		b.add_theme_stylebox_override("pressed", _skin("tab_active", 4))
		b.add_theme_stylebox_override("hover_pressed", _skin("tab_active", 4))
		b.add_theme_color_override("font_color", C_TEXT)
		b.add_theme_color_override("font_hover_color", C_TEXT)
		b.add_theme_color_override("font_focus_color", C_TEXT)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
		HdUi.ButtonSkin.apply(b)
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
	var pc := _art_surface("upgrade_card" if unlocked else "upgrade_locked", 12)
	pc.name = "Upgrade_" + id
	pc.custom_minimum_size.y = 116 if unlocked else 86
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	pc.add_child(row)
	var tile := _art_surface("icon_tile", 3)
	tile.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.add_child(_icon(id, Vector2(64, 70)))
	row.add_child(tile)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	row.add_child(v)
	v.add_child(_label(String(u["name"]), 15, C_TEXT if unlocked else C_MUTED, true))
	var level := HBoxContainer.new()
	level.add_theme_constant_override("separation", 7)
	level.add_child(_label(I18n.t("trophy.level") % [lv, max_lv], 11, C_MUTED))
	var segments := HBoxContainer.new()
	segments.name = "LevelSegments"
	segments.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	segments.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	segments.add_theme_constant_override("separation", 2)
	for index in max_lv:
		var segment := _surface(C_BLUE if index < lv else Color("e3edf8"), Color("afc7df"), 2, 0)
		segment.custom_minimum_size = Vector2(0, 6)
		segments.add_child(segment)
	level.add_child(segments)
	v.add_child(level)
	if not unlocked:
		tile.modulate = Color(0.8, 0.85, 0.92)
		var locked := HBoxContainer.new()
		locked.add_theme_constant_override("separation", 4)
		locked.add_child(_icon("lock", Vector2(15, 20)))
		var lock_text := _label(I18n.t("trophy.unlocks_league") + Balance.league_name(int(u["unlock_league"])), 11, C_MUTED, true)
		lock_text.name = "UnlockLeague"
		locked.add_child(lock_text)
		v.add_child(locked)
		return pc
	v.add_child(_label(String(u["description"]), 11, C_MUTED, true))
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 5)
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
	b.custom_minimum_size = Vector2(76, 40)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _skin("buy_normal", 8))
	b.add_theme_stylebox_override("hover", _skin("buy_normal", 8))
	b.add_theme_stylebox_override("pressed", _skin("buy_pressed", 8))
	b.add_theme_stylebox_override("disabled", _skin("buy_disabled", 8))
	HdUi.ButtonSkin.apply(b)
	b.add_theme_color_override("font_color", Color("503600"))
	b.add_theme_color_override("font_hover_color", Color("503600"))
	b.add_theme_color_override("font_pressed_color", Color("503600"))
	b.add_theme_color_override("font_focus_color", Color("503600"))
	b.add_theme_color_override("font_disabled_color", C_MUTED)
	if maxed:
		b.text = I18n.t("trophy.max")
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = true
		return b
	var cost := GameState.trophy_cost(id)
	b.text = str(cost)
	b.icon = _texture("icons", "trophy")
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 22)
	b.add_theme_constant_override("h_separation", 5)
	var blocked := GameState.phase == "save_error" or GameState.save_blocked
	b.disabled = GameState.trophies < cost or blocked
	b.pressed.connect(func() -> void: on_buy.call(id))
	return b
