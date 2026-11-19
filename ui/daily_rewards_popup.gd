extends Control
class_name DailyRewardsPopup
## Daily Gift demo layout, assembled from separate v3 skins and live reward data.
signal closed
signal claimed(reward: Dictionary)
signal notice(text: String)

const TIERS := ["pro", "allstar", "standard", "elite"]
const DESIGN_SIZE := Vector2(360, 628)
const MIN_FONT := 9
const INK := Color("0a2050")
const FONT = preload("res://assets/clean_modern/fonts/Roboto-Bold.ttf")
const Art = preload("res://assets/daily_gift_v3/daily_gift_assets.gd")
const UnitScale = preload("res://ui/unit_scale.gd")

var _built_key := ""
var _claim_button: Button
var _x2_button: Button
var _claim_gift: TextureRect
var _claim_caption: Label
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
	if is_instance_valid(_x2_button):
		var x2_size := roundi(20 * factor)
		while x2_size > 9 and FONT.get_string_size(_x2_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, x2_size).x > _x2_button.size.x - 20.0 * factor:
			x2_size -= 1
		_x2_button.add_theme_font_size_override("font_size", x2_size)
	if is_instance_valid(_claim_button):
		var caption := _claim_caption.text if is_instance_valid(_claim_caption) else _claim_button.text
		var font_size := roundi((19 if _claim_button.disabled else 27) * factor)
		while font_size > 9 and FONT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > _claim_button.size.x - (24.0 if _claim_button.disabled else 78.0 * factor):
			font_size -= 1
		_claim_button.add_theme_font_size_override("font_size", font_size)
		_claim_button.add_theme_constant_override("icon_max_width", roundi(40 * factor))
		_claim_button.add_theme_constant_override("h_separation", roundi(8 * factor))
		if is_instance_valid(_claim_caption):
			var icon_size := 40.0 * factor
			var gap := 8.0 * factor
			var text_width := FONT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 2
			var start_x := (_claim_button.size.x - icon_size - gap - text_width) * 0.5
			_claim_gift.position = Vector2(start_x, (_claim_button.size.y - icon_size) * 0.5)
			_claim_gift.size = Vector2(icon_size, icon_size)
			_claim_caption.add_theme_font_size_override("font_size", font_size)
			_claim_caption.position = Vector2(start_x + icon_size + gap, 0)
			_claim_caption.size = Vector2(text_width, _claim_button.size.y)

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
	var fallback := String({"gems": "gem", "driver": "drivers", "gear": "gear_bag"}.get(kind, "gem"))
	var id := String(Art.COUPON_ICONS.get(kind + "." + tier, fallback))
	return Art.ROOT + "icons/" + id + ".png"

## Tier is data, never inferred from translated text.
static func reward_parts(reward: Dictionary) -> Array:
	var out: Array = []
	if int(reward.get("gems", 0)) > 0:
		out.append({"kind": "gems", "tier": "", "asset": "gem", "text": I18n.t("daily.x_gem") % int(reward["gems"]), "short": "%d" % int(reward["gems"]), "compact": I18n.t("daily.x_gem") % int(reward["gems"])})
	for tier in (reward.get("driver_coupon", {}) as Dictionary):
		out.append(_coupon_part("driver", tier, int(reward["driver_coupon"][tier])))
	for tier in (reward.get("gear_coupon", {}) as Dictionary):
		out.append(_coupon_part("gear", tier, int(reward["gear_coupon"][tier])))
	return out

## "compact" drops the tier name ("2 vé") for rows that share one caption such as "80 gem + 2 vé".
static func _coupon_part(kind: String, tier: String, count: int) -> Dictionary:
	var fallback := "drivers" if kind == "driver" else "gear_bag"
	return {"kind": kind, "tier": tier, "asset": Art.COUPON_ICONS.get(kind + "." + tier, fallback),
		"text": I18n.t("daily.x_ticket") % [count, I18n.t("daily.tier_" + tier) if tier in TIERS else tier], "short": "%d" % count,
		"compact": (I18n.t("daily.x_ticket") % [count, ""]).strip_edges()}

static func reward_line(reward: Dictionary) -> String:
	var bits: PackedStringArray = []
	for part: Dictionary in reward_parts(reward):
		bits.append(String(part["text"]))
	return " + ".join(bits)

func _state_key() -> String:
	var state: Dictionary = GameState.daily_rewards
	return "%s|%d|%d|%d|%d|%s|%d|%s" % [GameState.daily_reward_available(), int(state["total_days"]), int(state["cycle_day"]), int(state["grand_ordinal"]), int(state["claimed_milestones"]), GameState.save_blocked or GameState.phase == "save_error", I18n.revision, _x2_offered()]

func _x2_offered() -> bool:
	return Ads.has_pending("daily_x2") or Ads.can_offer("daily_x2")


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
	_claim_gift = null
	_claim_caption = null
	_x2_button = null
	_built_key = _state_key()
	_canvas = Control.new()
	_canvas.name = "ReferenceCanvas"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel(_canvas, "panel_cream", Rect2(Vector2.ZERO, DESIGN_SIZE), "DailyBackground")
	_panel(_canvas, "header_cyan", Rect2(14, 12, 332, 54), "DailyHeader")
	var checker := _image(_canvas, _art_texture("checker_flag"), Rect2(264, 14, 28, 50))
	checker.name = "HeaderChecker"
	_image(_canvas, _art_texture("gift"), Rect2(22, 7, 54, 58))
	_label(_canvas, I18n.t("daily.daily_gift"), Rect2(78, 20, 182, 38), 23)
	var close := TextureButton.new()
	close.name = "PopupClose"
	Art.setup_close_button(close)
	close.accessibility_name = I18n.t("common.close")
	close.pressed.connect(func() -> void: closed.emit())
	_mount(_canvas, close, Rect2(302, 19, 43, 43))
	close.set_meta("ub_min", Vector2.ZERO)
	close.set_meta("ub_floor", Vector2(48, 48))
	_label(_canvas, I18n.t("daily.log_every_day_get_great"), Rect2(24, 70, 312, 20), 14)
	var state: Dictionary = GameState.daily_rewards
	_panel(_canvas, "pill_counter_cyan", Rect2(106, 92, 148, 19), "ClaimedDaysPill")
	_label(_canvas, I18n.tn("daily.claimed_days", int(state["total_days"])) % int(state["total_days"]), Rect2(108, 92, 144, 19), 13)
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
			_daily_card(row, index, DailyRewards.slot_reward(index, ordinal), card_state, Rect2(20 + col * (card_width + 5), 116 if row_index == 0 else 220, card_width, 98 if row_index == 0 else 84))
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
	_claim_button.icon = null
	_claim_button.add_theme_font_override("font", FONT)
	_claim_button.add_theme_font_size_override("font_size", 27 if can_claim else 19)
	_claim_button.add_theme_constant_override("outline_size", 0)
	var x2_shown := can_claim and not save_error and _x2_offered()
	_mount(_canvas, _claim_button, Rect2(26, 570, 192 if x2_shown else 308, 52))
	_claim_button.set_meta("ub_min", Vector2.ZERO)
	_claim_button.set_meta("ub_floor", Vector2(0, 48))
	if x2_shown:
		_build_x2_button()
	if can_claim and not save_error:
		_claim_button.text = ""
		_claim_gift = _image(_claim_button, _art_texture("gift"), Rect2(66, 6, 40, 40))
		_claim_gift.name = "ClaimGiftIcon"
		_claim_caption = _label(_claim_button, I18n.t("daily.claim_gift"), Rect2(114, 0, 150, 52), 27, Color.WHITE)
		_claim_caption.name = "ClaimCaption"
	_claim_button.pressed.connect(_on_claim)
	_layout_canvas()

## Secondary action beside the claim button: watch a video first, then claim with doubled gems (Design/30 §6).
func _build_x2_button() -> void:
	_x2_button = Button.new()
	_x2_button.name = "ClaimDailyRewardX2"
	_x2_button.text = I18n.t("daily.x2_claim")
	_x2_button.accessibility_name = _x2_button.text
	_x2_button.add_theme_font_override("font", FONT)
	_x2_button.add_theme_color_override("font_color", INK)
	_x2_button.add_theme_color_override("font_hover_color", INK)
	_x2_button.add_theme_color_override("font_pressed_color", INK)
	_x2_button.add_theme_constant_override("outline_size", 0)
	_x2_button.add_theme_font_size_override("font_size", 20)
	for button_state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		_x2_button.add_theme_stylebox_override(button_state, _skin("pill_hint_cyan"))
	_x2_button.pressed.connect(_on_claim_x2)
	_mount(_canvas, _x2_button, Rect2(224, 570, 110, 52))
	_x2_button.set_meta("ub_min", Vector2.ZERO)
	_x2_button.set_meta("ub_floor", Vector2(0, 48))
	Ads.note_offer("daily_x2")


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

func _fits(text: String, width: float, font_size: int) -> bool:
	return FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width - 2


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
	var tall := index < 3
	var has_badge := state in ["today", "claimed", "next"]
	var icon_y := 22.0
	var icon_h := 32.0 if tall else (24.0 if has_badge else 30.0)
	var quantity_y := 55.0 if tall else (46.0 if has_badge else 53.0)
	var quantity_font := 14 if tall or not has_badge else 13
	var badge_y := 78.0 if tall else 64.0
	_label(content, I18n.t("daily.day") % (index + 1), Rect2(4, 3, w - 8, 20), 16)
	var parts := reward_parts(reward)
	var part_width := (w - 12) / maxi(1, parts.size())
	for i in parts.size():
		var part: Dictionary = parts[i]
		var icon := _image(content, _art_texture(part["asset"]), Rect2(6 + i * part_width + part_width * 0.1, icon_y, part_width * 0.9, icon_h))
		icon.name = "RewardIcon" if i == 0 else "RewardIcon%d" % i
		icon.set_meta("tier", part["tier"])
		var caption := String(part["text"]) if parts.size() == 1 else String(part["short"])
		var quantity_rect := Rect2(5 + i * part_width, quantity_y, part_width + 2, 16 if not tall else 18)
		if parts.size() == 1:
			quantity_rect = Rect2(2, quantity_y, w - 4, quantity_rect.size.y)
		var quantity := _label(content, caption, quantity_rect, quantity_font)
		quantity.name = "RewardQuantity" if i == 0 else "RewardQuantity%d" % i
		if state == "claimed":
			# Demo: claimed cards go grey but their art stays readable.
			icon.self_modulate.a = 0.8
			quantity.self_modulate.a = 0.75
	if state == "today":
		_panel(content, "badge_today_gold", Rect2(14, badge_y, w - 28, 16), "TodayBadge")
		_label(content, I18n.t("daily.today"), Rect2(16, badge_y, w - 32, 16), 12)
	elif state == "claimed":
		_claimed_badge(content, Rect2(11, badge_y, w - 22, 16))
	elif state == "next":
		# Touch screens have no tooltip, so tomorrow's card carries a visible pill.
		_panel(content, "pill_counter_cyan", Rect2(14, badge_y, w - 28, 16), "NextBadge")
		_label(content, I18n.t("daily.tomorrow"), Rect2(16, badge_y, w - 32, 16), 12)

func _claimed_badge(parent: Control, rect: Rect2) -> void:
	var badge := _panel(parent, "badge_claimed_green", rect, "ClaimedBadge")
	var text := I18n.t("daily.claimed")
	# Long translations drop the check mark instead of shrinking below a readable size.
	if _fits(text, rect.size.x - 31, MIN_FONT + 1):
		_image(badge, _art_texture("check_white"), Rect2(10, rect.size.y * 0.5 - 5, 11, 10))
		_label(badge, text, Rect2(23, 0, rect.size.x - 31, rect.size.y), 12, Color.WHITE)
	else:
		_label(badge, text, Rect2(2, 0, rect.size.x - 4, rect.size.y), 12, Color.WHITE)

func _grand(reward: Dictionary, state: String) -> void:
	var content := _cell(_canvas, Rect2(16, 312, 328, 104), "DailyCell7", "panel_grand")
	# Demo: pale checker flags in both bottom corners and a soft glow behind the gift box.
	var flag_left := _image(content, _art_texture("checker_flag"), Rect2(4, 64, 34, 38))
	flag_left.self_modulate.a = 0.45
	var flag_right := _image(content, _art_texture("checker_flag"), Rect2(290, 62, 34, 38))
	flag_right.self_modulate.a = 0.45
	var glow := _image(content, _art_texture("glow_soft"), Rect2(-4, 6, 112, 98))
	glow.name = "GrandGlow"
	_label(content, I18n.t("daily.day_7_special_reward"), Rect2(72, 5, 226, 22), 16)
	var gift := _image(content, _art_texture("gift"), Rect2(20, 18, 76, 80))
	gift.name = "GrandGift"
	var divider := ColorRect.new()
	divider.name = "GrandDivider"
	divider.color = Color(0.45, 0.62, 0.8, 0.45)
	_mount(content, divider, Rect2(110, 30, 1, 46))
	var parts := reward_parts(reward)
	var step := 190.0 / maxi(1, parts.size())
	for i in parts.size():
		var part: Dictionary = parts[i]
		var x := 118 + i * step
		var icon := _image(content, _art_texture(part["asset"]), Rect2(x + 8, 27, step - 16, 33))
		icon.name = "RewardIcon%d" % i
		icon.set_meta("tier", part["tier"])
		var caption := String(part["text"]) if parts.size() < 3 else String(part["short"])
		var quantity := _label(content, caption, Rect2(x, 61, step, 18), 14)
		quantity.name = "RewardQuantity%d" % i
		if state == "claimed":
			icon.self_modulate.a = 0.8
			quantity.self_modulate.a = 0.75
	if state == "claimed":
		gift.self_modulate.a = 0.6
		_claimed_badge(content, Rect2(150, 83, 128, 17))
	else:
		_panel(content, "pill_hint_cyan", Rect2(116, 83, 178, 17), "GrandHint")
		_label(content, I18n.t("daily.today") if state == "today" else I18n.t("daily.complete_7_days_claim"), Rect2(118, 83, 174, 17), 12)

func _milestones(state: Dictionary) -> void:
	var content := Control.new()
	content.name = "DailyMilestones"
	_mount(_canvas, content, Rect2(20, 424, 320, 140))
	_label(content, I18n.t("daily.milestone_gift"), Rect2(4, 0, 185, 24), 18)
	var interval := maxi(1, int(GameData.daily_rewards().get("milestone_interval", 10)))
	var total := int(state["total_days"])
	_panel(content, "pill_counter_cyan", Rect2(235, 2, 84, 20), "MilestoneCounter")
	_label(content, I18n.t("daily.days") % [total % interval, interval], Rect2(235, 2, 84, 20), 13)
	var milestones := DailyRewards.milestone_window(state)
	# The track starts at x=4 so the lead-in 0..first milestone is visible; the first node sits at x=40.
	_panel(content, "progress_track", Rect2(4, 33, 276, 6), "MilestoneTrack")
	# Thin dividers between the four milestone columns, as in the demo.
	for d in 3:
		var line := ColorRect.new()
		line.name = "MilestoneDivider%d" % (d + 1)
		line.color = Color(0.6, 0.52, 0.42, 0.32)
		_mount(content, line, Rect2((d + 1) * 80, 56, 1, 56))
	# First visible milestone is at x=40, followed by equal 80-unit steps.
	# A lead-in represents the initial 0..first-milestone days without marking that milestone claimed early.
	var first_day := int(milestones[0]["day"])
	var fill_end := 4.0 + 36.0 * clampf(float(total) / maxf(1.0, first_day), 0.0, 1.0)
	if total > 0:
		fill_end = maxf(fill_end, 12.0)
	if total >= first_day:
		fill_end = 40.0 + 80.0 * clampf(float(total - first_day) / interval, 0.0, 3.0)
	if total > 0:
		_panel(content, "progress_fill", Rect2(4, 33, fill_end - 4, 6), "MilestoneProgress")
	for i in milestones.size():
		var milestone: Dictionary = milestones[i]
		var center_x := 40.0 + i * 80.0
		var marker := _image(content, _art_texture("milestone_claimed" if milestone["state"] == "claimed" else "milestone_empty", "runtime"), Rect2(center_x - 13, 23, 26, 26))
		marker.name = "MilestoneNode%d" % int(milestone["day"])
		var column := VBoxContainer.new()
		column.name = "Milestone%d" % int(milestone["day"])
		_mount(content, column, Rect2(i * 80, 54, 80, 62))
		var body := Control.new()
		body.custom_minimum_size = Vector2(80, 62)
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(body)
		_label(body, I18n.t("daily.day") % int(milestone["day"]), Rect2(0, 0, 80, 17), 14)
		var rewards := Control.new()
		rewards.name = "MilestoneRewards"
		_mount(body, rewards, Rect2(0, 18, 80, 44))
		var parts := reward_parts(milestone["reward"])
		# Icons sit in one row ("gem + ticket"); a single caption below carries the units.
		var icon_w := 30.0 if parts.size() < 3 else 24.0
		var plus_w := 10.0
		var row_w := parts.size() * icon_w + maxi(0, parts.size() - 1) * plus_w
		var start_x := (80.0 - row_w) * 0.5
		for j in parts.size():
			var part: Dictionary = parts[j]
			var icon := _image(rewards, _art_texture(part["asset"]), Rect2(start_x + j * (icon_w + plus_w), 0, icon_w, 26))
			icon.set_meta("tier", part["tier"])
			if j > 0:
				_label(rewards, "+", Rect2(start_x + j * (icon_w + plus_w) - plus_w, 3, plus_w, 18), 16)
		var captions: PackedStringArray = []
		var numbers: PackedStringArray = []
		for part: Dictionary in parts:
			captions.append(String(part["text"]) if parts.size() == 1 else String(part["compact"]))
			numbers.append(String(part["short"]))
		var caption := " + ".join(captions)
		# The icons already tell gem from ticket, so a caption too long at a readable size falls back to the numbers.
		if not _fits(caption, 80, MIN_FONT):
			caption = " + ".join(numbers)
		_label(rewards, caption, Rect2(0, 28, 80, 16), 13)
	_panel(content, "pill_hint_cyan", Rect2(25, 120, 270, 18), "MilestoneHint")
	var save_error: bool = GameState.save_blocked or GameState.phase == "save_error"
	var hint := I18n.t("daily.could_not_save_try_again") if save_error else I18n.t("daily.more_reward_days_reach_next") % DailyRewards.days_to_next_milestone(state)
	_label(content, hint, Rect2(29, 120, 262, 18), 12, HdUi.C_RED if save_error else INK)

func _on_claim() -> void:
	if Ads.is_busy():
		return
	if not GameState.claim_daily_reward():
		refresh()
		return
	_after_claim()


func _on_claim_x2() -> void:
	if Ads.is_busy():
		return
	_x2_button.disabled = true
	if Ads.has_pending("daily_x2"):
		Ads.retry_pending("daily_x2", _on_x2_finished)
	else:
		Ads.try_show_rewarded("daily_x2", _on_x2_finished)


func _on_x2_finished(result: Dictionary) -> void:
	var status := String(result.get("status", ""))
	if status in ["rewarded", "skipped_entitled"]:
		_after_claim()
		return
	notice.emit(I18n.t("main.cannot_claim_reward_check_save") if status == "failed" else Ads.status_text(status))
	refresh()


func _after_claim() -> void:
	var reward: Dictionary = GameState.last_daily_reward
	claimed.emit(reward)
	refresh()
	var cell := find_child("DailyCell%d" % (int(reward.get("slot", 0)) + 1), true, false) as Control
	if cell != null:
		cell.modulate = Color("d9f3c7")
		create_tween().tween_property(cell, "modulate", Color.WHITE, 0.4)
