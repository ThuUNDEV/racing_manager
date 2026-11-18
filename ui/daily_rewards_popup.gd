extends Control
class_name DailyRewardsPopup
## Daily Gift demo layout, assembled from separate v3 skins and live reward data.
signal closed
signal claimed(reward: Dictionary)

const COUPON_NAMES := {"pro": "Pro", "allstar": "All-Star", "standard": "Standard", "elite": "Elite"}
const DESIGN_SIZE := Vector2(360, 588)
const INK := Color("0a2050")
const FONT = preload("res://assets/daily_gift_v3/fonts/Roboto-Bold.ttf")
const Art = preload("res://assets/daily_gift_v3/daily_gift_assets.gd")
const UnitScale = preload("res://ui/unit_scale.gd")

var _built_key := ""
var _claim_button: Button
var _tick := 0.0
var _canvas: Control
static var _art_cache: Dictionary = {}

func _ready() -> void:
	name = "DailyRewardsPopup"
	_update_requested_size()
	get_viewport().size_changed.connect(_update_requested_size)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resized.connect(_layout_canvas)
	refresh()

func _update_requested_size() -> void:
	var viewport := get_viewport_rect().size
	var width := minf(viewport.x - 16.0, minf(430.0, (viewport.y - 24.0) * DESIGN_SIZE.x / DESIGN_SIZE.y))
	width = maxf(1.0, width)
	custom_minimum_size = Vector2(width, ceilf(width * DESIGN_SIZE.y / DESIGN_SIZE.x))
	if get_parent() != null and get_parent().get_parent() is ScrollContainer:
		get_parent().get_parent().set_meta("preferred_width", width)
	if is_node_ready():
		_layout_canvas()

func _layout_canvas() -> void:
	if not is_instance_valid(_canvas):
		return
	var factor := maxf(size.x, custom_minimum_size.x) / DESIGN_SIZE.x
	_canvas.set_meta("unit", factor)
	UnitScale.apply(_canvas, factor)
	if is_instance_valid(_claim_button):
		var font_size := roundi((18 if _claim_button.disabled else 23) * factor)
		while font_size > 9 and FONT.get_string_size(_claim_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > _claim_button.size.x - (24.0 if _claim_button.disabled else 62.0):
			font_size -= 1
		_claim_button.add_theme_font_size_override("font_size", font_size)
		_claim_button.add_theme_constant_override("icon_max_width", roundi(30 * factor))
		_claim_button.add_theme_constant_override("h_separation", roundi(8 * factor))

func _process(delta: float) -> void:
	_tick -= delta
	if _tick > 0:
		return
	_tick = 0.4
	if _state_key() != _built_key:
		refresh()
	elif is_instance_valid(_claim_button) and _claim_button.disabled and not GameState.save_blocked and GameState.phase != "save_error":
		_claim_button.text = _countdown_text()
		_claim_button.accessibility_name = _claim_button.text

static func part_icon(kind: String, tier: String = "") -> String:
	var id := String(Art.COUPON_ICONS.get(kind + "." + tier, "gem"))
	return Art.ROOT + "icons/" + id + ".png"

## Tier is data, never inferred from translated text.
static func reward_parts(reward: Dictionary) -> Array:
	var out: Array = []
	if int(reward.get("gems", 0)) > 0:
		out.append({"kind": "gems", "tier": "", "asset": "gem", "text": "%d gem" % int(reward["gems"]), "short": "%d" % int(reward["gems"])})
	for tier in (reward.get("driver_coupon", {}) as Dictionary):
		out.append({"kind": "driver", "tier": tier, "asset": Art.COUPON_ICONS.get("driver." + tier, "drivers"), "text": I18n.t("daily.x_ticket") % [int(reward["driver_coupon"][tier]), COUPON_NAMES.get(tier, tier)], "short": "%d" % int(reward["driver_coupon"][tier])})
	for tier in (reward.get("gear_coupon", {}) as Dictionary):
		out.append({"kind": "gear", "tier": tier, "asset": Art.COUPON_ICONS.get("gear." + tier, "gear_bag"), "text": I18n.t("daily.x_ticket") % [int(reward["gear_coupon"][tier]), COUPON_NAMES.get(tier, tier)], "short": "%d" % int(reward["gear_coupon"][tier])})
	return out

static func reward_line(reward: Dictionary) -> String:
	var bits: PackedStringArray = []
	for part: Dictionary in reward_parts(reward):
		bits.append(String(part["text"]))
	return " + ".join(bits)

func _state_key() -> String:
	var state: Dictionary = GameState.daily_rewards
	return "%s|%d|%d|%d|%d|%s|%d" % [GameState.daily_reward_available(), int(state["total_days"]), int(state["cycle_day"]), int(state["grand_ordinal"]), int(state["claimed_milestones"]), GameState.save_blocked or GameState.phase == "save_error", I18n.revision]

func _countdown_text() -> String:
	var left := maxi(0, int(GameState.daily_reward_seconds_left()))
	return I18n.t("daily.reopens") % [left / 3600, (left % 3600) / 60, left % 60]

static func _art_texture(id: String, folder: String = "icons") -> Texture2D:
	var key := folder + "/" + id
	if not _art_cache.has(key):
		_art_cache[key] = load(Art.ROOT + key + ".png")
	return _art_cache[key]

func _skin(id: String) -> StyleBoxTexture:
	var skin := (load(Art.ROOT + "styles/" + id + ".tres") as StyleBoxTexture).duplicate() as StyleBoxTexture
	for side in 4:
		skin.set_content_margin(side, 0)
	# Native pixel caps are already validated at mobile sizes. UnitScale must not
	# change which source texels form the corners or the header's checker accent.
	skin.set_meta("rounded_button", true)
	return skin

func refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_built_key = _state_key()
	_canvas = Control.new()
	_canvas.name = "ReferenceCanvas"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel(_canvas, "panel_cream", Rect2(Vector2.ZERO, DESIGN_SIZE), "DailyBackground")
	_panel(_canvas, "header_cyan", Rect2(14, 12, 332, 54), "DailyHeader")
	_image(_canvas, _art_texture("gift"), Rect2(28, 4, 55, 62))
	_label(_canvas, I18n.t("daily.daily_gift"), Rect2(84, 22, 212, 35), 22)
	var close := TextureButton.new()
	close.name = "PopupClose"
	Art.setup_close_button(close)
	close.accessibility_name = I18n.t("common.close")
	close.pressed.connect(func() -> void: closed.emit())
	_mount(_canvas, close, Rect2(307, 19, 43, 43))
	close.set_meta("ub_min", Vector2.ZERO)
	close.set_meta("ub_floor", Vector2(48, 48))
	_label(_canvas, I18n.t("daily.log_every_day_get_great"), Rect2(24, 72, 312, 18), 12)
	var state: Dictionary = GameState.daily_rewards
	_panel(_canvas, "pill_counter_cyan", Rect2(121, 93, 118, 17), "ClaimedDaysPill")
	_label(_canvas, I18n.tn("daily.claimed_days", int(state["total_days"])) % int(state["total_days"]), Rect2(123, 93, 114, 17), 11)
	var can_claim: bool = GameState.daily_reward_available()
	var cycle_day := int(state["cycle_day"])
	var ordinal := int(state["grand_ordinal"])
	var done := cycle_day
	if not can_claim and int(state["total_days"]) > 0 and cycle_day == 0:
		done = 7
		ordinal = posmod(ordinal - 1, maxi(1, (GameData.daily_rewards().get("grand", []) as Array).size()))
	var card_width := 310.0 / 3.0
	for row_index in 2:
		var row := Control.new()
		row.name = "DailyRow%d" % (row_index + 1)
		_mount(_canvas, row, Rect2(Vector2.ZERO, DESIGN_SIZE))
		for col in 3:
			var index := row_index * 3 + col
			var card_state := "claimed" if index < done else ("today" if index == cycle_day and can_claim else ("next" if index == cycle_day else "later"))
			_daily_card(row, index, DailyRewards.slot_reward(index, ordinal), card_state, Rect2(20 + col * (card_width + 5), 115 if row_index == 0 else 216, card_width, 96 if row_index == 0 else 80))
	_grand(DailyRewards.slot_reward(6, ordinal), "claimed" if done == 7 else ("today" if cycle_day == 6 and can_claim else "later"))
	_milestones(state)
	_claim_button = Button.new()
	_claim_button.name = "ClaimDailyReward"
	Art.setup_claim_button(_claim_button)
	for button_state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var asset: String = {"normal": "button_claim_orange", "hover": "button_claim_orange_hover", "pressed": "button_claim_orange_pressed", "hover_pressed": "button_claim_orange_pressed", "disabled": "button_claim_orange_disabled"}[button_state]
		_claim_button.add_theme_stylebox_override(button_state, _skin(asset))
	var save_error: bool = GameState.save_blocked or GameState.phase == "save_error"
	_claim_button.disabled = not can_claim or save_error
	_claim_button.text = I18n.t("common.saving") if save_error else (I18n.t("daily.claim_gift") if can_claim else _countdown_text())
	_claim_button.accessibility_name = _claim_button.text
	_claim_button.icon = _art_texture("gift") if can_claim and not save_error else null
	_claim_button.expand_icon = true
	_claim_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_claim_button.add_theme_font_override("font", FONT)
	_claim_button.add_theme_font_size_override("font_size", 23 if can_claim else 18)
	_claim_button.add_theme_constant_override("outline_size", 0)
	_mount(_canvas, _claim_button, Rect2(28, 535, 304, 42))
	_claim_button.set_meta("ub_min", Vector2.ZERO)
	_claim_button.set_meta("ub_floor", Vector2(0, 48))
	_claim_button.pressed.connect(_on_claim)
	_layout_canvas()

func _mount(parent: Node, node: Control, rect: Rect2) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_STOP if node is BaseButton else Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	UnitScale.place(node, rect.position, rect.size)

func _panel(parent: Node, skin: String, rect: Rect2, node_name: String = "") -> Panel:
	var panel := Panel.new()
	if node_name != "":
		panel.name = node_name
	panel.add_theme_stylebox_override("panel", _skin(skin))
	_mount(parent, panel, rect)
	return panel

func _image(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mount(parent, image, rect)
	return image

func _label(parent: Node, value: String, rect: Rect2, font_size: int, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	while font_size > 8 and FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > rect.size.x - 2:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 0)
	_mount(parent, label, rect)
	return label

func _cell(parent: Node, rect: Rect2, node_name: String, skin: String) -> Control:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.add_theme_stylebox_override("panel", _skin(skin))
	_mount(parent, panel, rect)
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)
	return content

func _daily_card(parent: Node, index: int, reward: Dictionary, state: String, rect: Rect2) -> void:
	var skin := "card_today" if state == "today" else ("card_claimed" if state == "claimed" else "card_normal")
	var content := _cell(parent, rect, "DailyCell%d" % (index + 1), skin)
	var w := rect.size.x
	_label(content, I18n.t("daily.day") % (index + 1), Rect2(4, 3, w - 8, 19), 14)
	var parts := reward_parts(reward)
	var part_width := (w - 12) / maxi(1, parts.size())
	for i in parts.size():
		var part: Dictionary = parts[i]
		var icon := _image(content, _art_texture(part["asset"]), Rect2(6 + i * part_width + part_width * 0.15, 25, part_width * 0.7, 32))
		icon.name = "RewardIcon" if i == 0 else "RewardIcon%d" % i
		icon.tooltip_text = part["text"]
		var caption := String(part["text"]) if parts.size() == 1 else String(part["short"])
		var quantity := _label(content, caption, Rect2(5 + i * part_width, 58, part_width + 2, 16), 12)
		quantity.name = "RewardQuantity" if i == 0 else "RewardQuantity%d" % i
		if state == "claimed":
			icon.self_modulate.a = 0.25
			quantity.self_modulate.a = 0.30
	if state == "today":
		var y := 76.0 if index < 3 else 61.0
		# Bottom-row rewards use the same card height as the demo; make room for its state badge.
		if index >= 3:
			_move_short_card_reward(content)
		_panel(content, "badge_today_gold", Rect2(10, y, w - 20, 16), "TodayBadge")
		_label(content, I18n.t("daily.today"), Rect2(12, y, w - 24, 16), 11)
	elif state == "claimed":
		if index >= 3:
			_move_short_card_reward(content)
		_claimed_badge(content, Rect2(9, 76 if index < 3 else 61, w - 18, 16))
	elif state == "next":
		# Tomorrow is accessibility/help text rather than another row on the demo's clean future cards.
		content.get_parent().tooltip_text = I18n.t("daily.tomorrow")

func _move_short_card_reward(content: Control) -> void:
	for child in content.get_children():
		if child.name.begins_with("RewardIcon"):
			UnitScale.place(child, Vector2(child.position.x, 23), Vector2(child.size.x, 24))
		elif child.name.begins_with("RewardQuantity"):
			child.add_theme_font_size_override("font_size", 10)
			child.set_meta("ub_font", 10)
			UnitScale.place(child, Vector2(child.position.x, 45), Vector2(child.size.x, 14))

func _claimed_badge(parent: Control, rect: Rect2) -> void:
	var badge := _panel(parent, "badge_claimed_green", rect, "ClaimedBadge")
	_image(badge, _art_texture("check_white"), Rect2(8, 3, 11, 10))
	_label(badge, I18n.t("daily.claimed"), Rect2(21, 0, rect.size.x - 27, rect.size.y), 10, Color.WHITE)

func _grand(reward: Dictionary, state: String) -> void:
	var content := _cell(_canvas, Rect2(16, 303, 328, 98), "DailyCell7", "panel_grand")
	_label(content, I18n.t("daily.day_7_special_reward"), Rect2(94, 4, 226, 20), 14)
	var gift := _image(content, _art_texture("gift_grand"), Rect2(12, 20, 86, 72))
	gift.name = "GrandGift"
	var parts := reward_parts(reward)
	var step := 216.0 / maxi(1, parts.size())
	for i in parts.size():
		var part: Dictionary = parts[i]
		var x := 105 + i * step
		var icon := _image(content, _art_texture(part["asset"]), Rect2(x + 8, 29, step - 16, 31))
		icon.name = "RewardIcon%d" % i
		icon.tooltip_text = part["text"]
		var caption := String(part["text"]) if parts.size() < 3 else String(part["short"])
		var quantity := _label(content, caption, Rect2(x, 61, step, 17), 12)
		quantity.name = "RewardQuantity%d" % i
		if state == "claimed":
			icon.self_modulate.a = 0.25
			quantity.self_modulate.a = 0.30
	if state == "claimed":
		gift.self_modulate.a = 0.25
		_claimed_badge(content, Rect2(150, 80, 128, 15))
	else:
		_panel(content, "pill_hint_cyan", Rect2(111, 80, 210, 15), "GrandHint")
		_label(content, I18n.t("daily.today") if state == "today" else I18n.t("daily.complete_7_days_claim"), Rect2(114, 80, 204, 15), 10)

func _milestones(state: Dictionary) -> void:
	var content := Control.new()
	content.name = "DailyMilestones"
	_mount(_canvas, content, Rect2(20, 409, 320, 119))
	_label(content, I18n.t("daily.milestone_gift"), Rect2(4, 0, 185, 23), 16)
	var interval := maxi(1, int(GameData.daily_rewards().get("milestone_interval", 10)))
	var total := int(state["total_days"])
	_panel(content, "pill_counter_cyan", Rect2(245, 1, 74, 18), "MilestoneCounter")
	_label(content, I18n.t("daily.days") % [total % interval, interval], Rect2(245, 1, 74, 18), 11)
	var milestones := DailyRewards.milestone_window(state)
	_panel(content, "progress_track", Rect2(16, 31, 264, 6), "MilestoneTrack")
	# First visible milestone is at x=40, followed by equal 80-unit steps.
	# A short lead-in represents the initial 0..10 days without marking day 10 claimed early.
	var first_day := int(milestones[0]["day"])
	var fill_end := 16.0 + 24.0 * clampf(float(total) / maxf(1.0, first_day), 0.0, 1.0)
	if total >= first_day:
		fill_end = 40.0 + 80.0 * clampf(float(total - first_day) / interval, 0.0, 3.0)
	if fill_end > 16:
		_panel(content, "progress_fill", Rect2(16, 31, fill_end - 16, 6), "MilestoneProgress")
	for i in milestones.size():
		var milestone: Dictionary = milestones[i]
		var center_x := 40.0 + i * 80.0
		var marker := _image(content, _art_texture("milestone_claimed" if milestone["state"] == "claimed" else "milestone_empty", "runtime"), Rect2(center_x - 10, 24, 20, 20))
		marker.name = "MilestoneNode%d" % int(milestone["day"])
		var column := VBoxContainer.new()
		column.name = "Milestone%d" % int(milestone["day"])
		_mount(content, column, Rect2(i * 80, 45, 80, 54))
		var body := Control.new()
		body.custom_minimum_size = Vector2(80, 54)
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(body)
		_label(body, I18n.t("daily.day") % int(milestone["day"]), Rect2(0, 0, 80, 14), 12)
		var rewards := Control.new()
		rewards.name = "MilestoneRewards"
		_mount(body, rewards, Rect2(0, 16, 80, 38))
		var parts := reward_parts(milestone["reward"])
		var step := 80.0 / maxi(1, parts.size())
		for j in parts.size():
			var part: Dictionary = parts[j]
			var reward_column := Control.new()
			_mount(rewards, reward_column, Rect2(j * step, 0, step, 38))
			_image(reward_column, _art_texture(part["asset"]), Rect2((step - 29) / 2, 0, 29, 22))
			var caption := String(part["text"]) if parts.size() == 1 else String(part["short"])
			_label(reward_column, caption, Rect2(1, 24, step - 2, 14), 10)
	_panel(content, "pill_hint_cyan", Rect2(16, 101, 288, 16), "MilestoneHint")
	var save_error: bool = GameState.save_blocked or GameState.phase == "save_error"
	var hint := I18n.t("daily.could_not_save_try_again") if save_error else I18n.t("daily.more_reward_days_reach_next") % DailyRewards.days_to_next_milestone(state)
	_label(content, hint, Rect2(20, 101, 280, 16), 10, HdUi.C_RED if save_error else INK)

func _on_claim() -> void:
	if not GameState.claim_daily_reward():
		refresh()
		return
	var reward: Dictionary = GameState.last_daily_reward
	claimed.emit(reward)
	refresh()
	var cell := find_child("DailyCell%d" % (int(reward.get("slot", 0)) + 1), true, false) as Control
	if cell != null:
		cell.modulate = Color("d9f3c7")
		create_tween().tween_property(cell, "modulate", Color.WHITE, 0.4)
