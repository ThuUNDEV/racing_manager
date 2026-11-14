extends Control
class_name DailyRewardsPopup
## Reference-registered skin with live text, reward art and interactive controls.
signal closed
signal claimed(reward: Dictionary)

const COUPON_NAMES := {"pro": "Pro", "allstar": "All-Star", "standard": "Standard", "elite": "Elite"}
const ICON_GEM := "icons/gem.png"
const ICON_DRIVER := "icons/staff.png"
const ICON_GEAR := "icons/tools.png"
const DESIGN_SIZE := Vector2(922, 1706)
const INK := Color("0a2050")
const FONT = preload("res://assets/clean_modern/fonts/Roboto-Bold.ttf")

var _built_key := ""
var _claim_button: Button
var _tick := 0.0
var _canvas: Control

func _ready() -> void:
	name = "DailyRewardsPopup"
	_update_requested_size()
	get_viewport().size_changed.connect(_update_requested_size)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resized.connect(_layout_canvas)
	refresh()

func _update_requested_size() -> void:
	var viewport := get_viewport_rect().size
	var width := minf(viewport.x, minf(430.0, (viewport.y - 90.0) * DESIGN_SIZE.x / DESIGN_SIZE.y))
	custom_minimum_size = Vector2(width, ceilf(width * DESIGN_SIZE.y / DESIGN_SIZE.x))
	if get_parent() != null and get_parent().get_parent() is ScrollContainer:
		get_parent().get_parent().set_meta("preferred_width", width)
	if is_node_ready():
		_layout_canvas()

func _layout_canvas() -> void:
	var factor := maxf(size.x, custom_minimum_size.x) / DESIGN_SIZE.x
	if is_instance_valid(_canvas):
		_canvas.scale = Vector2.ONE * factor

func _process(delta: float) -> void:
	_tick -= delta
	if _tick > 0:
		return
	_tick = 0.4
	if _state_key() != _built_key:
		refresh()
	elif is_instance_valid(_claim_button) and _claim_button.disabled:
		_claim_button.text = _countdown_text()

static func part_icon(kind: String) -> String:
	return {"gems": ICON_GEM, "driver": ICON_DRIVER, "gear": ICON_GEAR}.get(kind, ICON_GEM)


## Các dòng hiển thị của một thưởng: [{kind: "gems" | "driver" | "gear", text}]. Gem trước, rồi coupon tay đua, coupon trang bị.
static func reward_parts(r: Dictionary) -> Array:
	var out: Array = []
	if int(r.get("gems", 0)) > 0:
		out.append({"kind": "gems", "text": "%d gem" % int(r["gems"]), "short": "%d" % int(r["gems"])})
	for kind in (r.get("driver_coupon", {}) as Dictionary):
		out.append({"kind": "driver", "text": I18n.t("daily.x_ticket") % [int(r["driver_coupon"][kind]), COUPON_NAMES.get(kind, kind)], "short": "%d %s" % [int(r["driver_coupon"][kind]), COUPON_NAMES.get(kind, kind)]})
	for kind in (r.get("gear_coupon", {}) as Dictionary):
		out.append({"kind": "gear", "text": I18n.t("daily.x_ticket") % [int(r["gear_coupon"][kind]), COUPON_NAMES.get(kind, kind)], "short": "%d %s" % [int(r["gear_coupon"][kind]), COUPON_NAMES.get(kind, kind)]})
	return out


## Một dòng tóm tắt thưởng, dùng cho toast.
static func reward_line(r: Dictionary) -> String:
	var bits: PackedStringArray = []
	for p: Dictionary in reward_parts(r):
		bits.append(String(p["text"]))
	return " + ".join(bits)


func _state_key() -> String:
	var s: Dictionary = GameState.daily_rewards
	return "%s|%d|%d|%d|%d" % [GameState.daily_reward_available(), int(s["total_days"]), int(s["cycle_day"]), int(s["grand_ordinal"]), int(s["claimed_milestones"])]


func _countdown_text() -> String:
	var left := int(GameState.daily_reward_seconds_left())
	return I18n.t("daily.reopens") % [left / 3600, (left % 3600) / 60, left % 60]


const ART_RECTS := {
	"header": Rect2(8, 125, 403, 200), "chest": Rect2(449, 88, 363, 296),
	"pro": Rect2(849, 102, 394, 257), "standard": Rect2(12, 502, 399, 259),
	"allstar": Rect2(427, 494, 399, 270), "elite": Rect2(846, 495, 400, 269),
	"gem": Rect2(70, 934, 286, 231), "gems": Rect2(432, 927, 379, 258),
	"gift": Rect2(892, 893, 306, 300)
}
static var _art_cache: Dictionary = {}


static func _art_texture(key: String) -> Texture2D:
	if not _art_cache.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/daily_rewards/art.png")
		atlas.region = ART_RECTS[key]
		atlas.filter_clip = true
		_art_cache[key] = atlas
	return _art_cache[key]


func refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_built_key = _state_key()
	_canvas = Control.new()
	_canvas.name = "ReferenceCanvas"
	_canvas.size = DESIGN_SIZE
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	var background := _image(_canvas, load("res://assets/daily_rewards/skin.png"), Rect2(Vector2.ZERO, DESIGN_SIZE))
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/daily_rewards/button_free_skin.gdshader")
	background.material = material
	_label(_canvas, I18n.t("daily.daily_gift"), Rect2(193, 137, 548, 91), 61, Color.WHITE, true)
	_label(_canvas, I18n.t("daily.log_every_day_get_great"), Rect2(159, 247, 605, 40), 27)
	var counter := Panel.new()
	counter.add_theme_stylebox_override("panel", _surface(Color("d3e9fc"), Color("8cbae7"), 22))
	_mount(_canvas, counter, Rect2(327, 288, 270, 44))
	var st: Dictionary = GameState.daily_rewards
	_label(counter, I18n.tn("daily.claimed_days", int(st["total_days"])) % int(st["total_days"]), Rect2(6, 1, 258, 40), 27)
	var close := _button(_canvas, Rect2(789, 87, 124, 124), "PopupClose")
	close.accessibility_name = I18n.t("common.close")
	for state in ["normal", "hover", "pressed", "disabled"]:
		close.add_theme_stylebox_override(state, HdUi.ButtonSkin.palette(Color("ff6655"), Color("e82922"), Color("a81713"), 124.0 / 48.0))
	close.text = "×"
	close.add_theme_font_override("font", FONT)
	close.add_theme_font_size_override("font_size", 94)
	close.add_theme_color_override("font_color", Color.WHITE)
	close.add_theme_constant_override("outline_size", 0)
	HdUi.ButtonSkin.apply(close)
	close.pressed.connect(func() -> void: closed.emit())
	var can: bool = GameState.daily_reward_available()
	var cycle_day := int(st["cycle_day"])
	var ordinal := int(st["grand_ordinal"])
	var done := cycle_day
	if not can and int(st["total_days"]) > 0 and cycle_day == 0:
		done = 7
		ordinal = posmod(ordinal - 1, maxi(1, (GameData.daily_rewards().get("grand", []) as Array).size()))
	var xs := [60.0, 343.0, 607.0]
	var widths := [274.0, 252.0, 257.0]
	for row_index in 2:
		var row := Control.new()
		row.name = "DailyRow%d" % (row_index + 1)
		_mount(_canvas, row, Rect2(Vector2.ZERO, DESIGN_SIZE))
		for col in 3:
			var index := row_index * 3 + col
			var state := "claimed" if index < done else ("today" if index == cycle_day and can else ("next" if index == cycle_day else "later"))
			_daily_card(row, index, DailyRewards.slot_reward(index, ordinal), state, Rect2(xs[col], 350 if row_index == 0 else 622, widths[col], 258 if row_index == 0 else 228))
	_grand(DailyRewards.slot_reward(6, ordinal), "claimed" if done == 7 else ("today" if cycle_day == 6 and can else "later"))
	_milestones(st)
	_claim_button = _button(_canvas, Rect2(122, 1505, 680, 102), "ClaimDailyReward")
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var face := HdUi.ButtonSkin.palette(Color("359d16"), Color("258a0b"), Color("145e15"), 102.0 / 48.0)
		if state == "disabled":
			face = HdUi.ButtonSkin.palette(Color("c3d6df"), Color("c3d6df"), Color("8cabbc"), 102.0 / 48.0)
		elif state in ["pressed", "hover_pressed"]:
			face.modulate_color = Color("d0e9c4")
		_claim_button.add_theme_stylebox_override(state, face)
	HdUi.ButtonSkin.apply(_claim_button)
	_claim_button.disabled = not can
	_claim_button.accessibility_name = I18n.t("common.claim_reward") if can else _countdown_text()
	_claim_button.add_theme_font_override("font", FONT)
	_claim_button.add_theme_font_size_override("font_size", 31)
	_claim_button.add_theme_color_override("font_disabled_color", INK)
	_claim_button.add_theme_constant_override("outline_size", 0)
	_claim_button.add_theme_constant_override("shadow_offset_y", 0)
	if can:
		_image(_claim_button, _art_texture("gift"), Rect2(155, 9, 85, 85), true)
		_label(_claim_button, I18n.t("daily.claim_gift"), Rect2(235, 13, 365, 70), 49, Color.WHITE, true)
	else:
		_claim_button.text = _countdown_text()
	_claim_button.pressed.connect(_on_claim)
	if GameState.save_blocked or GameState.phase == "save_error":
		_label(_canvas, I18n.t("daily.could_not_save_try_again"), Rect2(120, 1468, 680, 32), 24, HdUi.C_RED)
	_layout_canvas()


func _mount(parent: Node, node: Control, rect: Rect2) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size


func _image(parent: Node, texture: Texture2D, rect: Rect2, keep_aspect: bool = false) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if keep_aspect else TextureRect.STRETCH_SCALE
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mount(parent, image, rect)
	return image


func _label(parent: Node, value: String, rect: Rect2, font_size: int, color: Color = INK, shadow: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	var width := FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if width > rect.size.x - 4:
		font_size = maxi(18, floori(font_size * (rect.size.x - 4) / width))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_constant_override("shadow_offset_y", 3 if shadow else 0)
	label.add_theme_color_override("font_shadow_color", Color("08245699"))
	_mount(parent, label, rect)
	return label


func _surface(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style


func _button(parent: Node, rect: Rect2, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	for key in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(key, StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", _surface(Color.TRANSPARENT, Color("ffdf66"), 28))
	_mount(parent, button, rect)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _empty_panel(parent: Node, rect: Rect2, node_name: String) -> Control:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_mount(parent, panel, rect)
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)
	return content


func _part_asset(part: Dictionary) -> String:
	if part["kind"] == "gems": return "gem"
	for key in ["allstar", "pro", "elite", "standard"]:
		if String(part["text"]).contains(String(COUPON_NAMES[key])):
			return key
	return "pro"


func _daily_card(parent: Node, index: int, reward: Dictionary, state: String, rect: Rect2) -> void:
	var content := _empty_panel(parent, rect, "DailyCell%d" % (index + 1))
	var w := rect.size.x
	var first_row := index < 3
	if state == "today":
		var selected := AtlasTexture.new()
		selected.atlas = load("res://assets/daily_rewards/today.png")
		selected.region = Rect2(124, 40, 1072, 1105)
		selected.filter_clip = true
		_image(content, selected, Rect2(-2, -4, w + 4, rect.size.y + 7))
	_label(content, I18n.t("daily.day") % (index + 1), Rect2(36, 2, w - 72, 43), 32, INK if state == "today" else Color.WHITE)
	var parts := reward_parts(reward)
	for i in parts.size():
		var part: Dictionary = parts[i]
		var asset := "gems" if index == 5 and part["kind"] == "gems" else _part_asset(part)
		var icon_w := w * (0.48 if asset == "gem" else 0.77)
		var claimed_day := state == "claimed"
		var icon_rect := Rect2((w - icon_w) / 2, 57 if first_row else 52, icon_w, 110)
		var quantity_rect := Rect2(8, 173 if first_row else 159, w - 16, 42)
		if claimed_day:
			icon_rect.position.y = 52
			icon_rect.size.y = 100 if first_row else 82
			quantity_rect.position.y = 158 if first_row else 139
			quantity_rect.size.y = 34
		var icon := _image(content, _art_texture(asset), icon_rect, true)
		icon.name = "RewardIcon"
		var quantity := _label(content, String(part["text"]), quantity_rect, 30)
		quantity.name = "RewardQuantity"
		if claimed_day:
			icon.self_modulate.a = 0.25
			quantity.self_modulate.a = 0.30
	if state == "today":
		_label(content, I18n.t("daily.today"), Rect2(38, rect.size.y - 45, w - 76, 35), 28, Color.WHITE)
	elif state == "claimed":
		_claimed_badge(content, Rect2(20, rect.size.y - 48, w - 40, 36))
	elif state == "next":
		_label(content, I18n.t("daily.tomorrow"), Rect2(30, rect.size.y - 30, w - 60, 24), 22, Color("426c95"))


class ClaimedCheck extends Control:
	func _draw() -> void:
		draw_circle(Vector2(14, 14), 13, Color("267734"))
		draw_polyline(PackedVector2Array([Vector2(7, 14), Vector2(12, 19), Vector2(22, 9)]), Color.WHITE, 3.5, true)


func _claimed_badge(parent: Control, rect: Rect2) -> void:
	var badge := Panel.new()
	badge.name = "ClaimedBadge"
	badge.add_theme_stylebox_override("panel", _surface(Color("c4efd4"), Color("60ad83"), 18))
	_mount(parent, badge, rect)
	var check := ClaimedCheck.new()
	_mount(badge, check, Rect2(10, 4, 28, 28))
	_label(badge, I18n.t("daily.claimed"), Rect2(44, 1, rect.size.x - 53, 34), 25, Color("216331"))


func _grand(reward: Dictionary, state: String) -> void:
	var root := _empty_panel(_canvas, Rect2(53, 865, 816, 286), "DailyCell7")
	_label(root, I18n.t("daily.day_7_special_reward"), Rect2(233 - 53, 7, 454, 44), 32)
	var parts := reward_parts(reward)
	if parts.size() == 2:
		for i in 2:
			var part: Dictionary = parts[i]
			var x := 365.0 if i == 0 else 577.0
			var icon := _image(root, _art_texture(_part_asset(part)), Rect2(x + 26, 85, 133, 84), true)
			var quantity := _label(root, String(part["text"]), Rect2(x + 4, 165, 176 if i == 0 else 198, 42), 29)
			if state == "claimed":
				icon.self_modulate.a = 0.25
				quantity.self_modulate.a = 0.30
	else:
		var cover := Panel.new()
		cover.add_theme_stylebox_override("panel", _surface(Color("0751aa"), Color("0751aa"), 20))
		_mount(root, cover, Rect2(354, 78, 429, 140))
		var step := 423.0 / parts.size()
		for i in parts.size():
			var part: Dictionary = parts[i]
			var chip := Panel.new()
			chip.add_theme_stylebox_override("panel", _surface(Color("d2e9fc"), Color("9fcdf2"), 18))
			_mount(root, chip, Rect2(359 + step * i, 81, step - 8, 126))
			var icon := _image(chip, _art_texture(_part_asset(part)), Rect2(12, 10, step - 32, 67), true)
			var quantity := _label(chip, String(part["text"]).get_slice(" ", 0) if parts.size() > 2 else String(part["text"]), Rect2(4, 80, step - 16, 36), 29)
			if state == "claimed":
				icon.self_modulate.a = 0.25
				quantity.self_modulate.a = 0.30
	if state == "claimed":
		_claimed_badge(root, Rect2(460, 230, 244, 36))
	else:
		var tag := I18n.t("daily.today_2") if state == "today" else I18n.t("daily.complete_7_days_claim")
		_label(root, tag, Rect2(379, 228, 407, 38), 27, Color.WHITE)


func _milestones(st: Dictionary) -> void:
	var root := Control.new()
	root.name = "DailyMilestones"
	_mount(_canvas, root, Rect2(55, 1167, 815, 326))
	_label(root, I18n.t("daily.milestone_gift"), Rect2(90, 7, 280, 52), 34)
	var iv := int(GameData.daily_rewards().get("milestone_interval", 10))
	_label(root, I18n.t("daily.days") % [int(st["total_days"]) % iv, iv], Rect2(585, 7, 204, 52), 30)
	var window := DailyRewards.milestone_window(st)
	var xs := [21.0, 219.0, 416.0, 615.0]
	for i in window.size():
		var m: Dictionary = window[i]
		if m["state"] != "locked":
			var marker := AtlasTexture.new()
			marker.atlas = load("res://assets/daily_rewards/skin.png")
			marker.region = Rect2(136, 1227, 62, 62)
			marker.filter_clip = true
			var marker_x: float = [80.0, 279.0, 474.0, 672.0][i]
			_image(root, marker, Rect2(marker_x, 60, 62, 62))
		var col := VBoxContainer.new()
		col.name = "Milestone%d" % int(m["day"])
		_mount(root, col, Rect2(xs[i], 129, 182, 143))
		var content := Control.new()
		content.custom_minimum_size = Vector2(182, 143)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(content)
		_label(content, I18n.t("daily.day") % int(m["day"]), Rect2(3, 3, 176, 35), 27)
		var rewards := Control.new()
		rewards.name = "MilestoneRewards"
		_mount(content, rewards, Rect2(0, 40, 182, 99))
		var parts := reward_parts(m["reward"])
		var step := 182.0 / parts.size()
		for j in parts.size():
			var part: Dictionary = parts[j]
			var reward_col := Control.new()
			_mount(rewards, reward_col, Rect2(j * step, 0, step, 98))
			_image(reward_col, _art_texture(_part_asset(part)), Rect2((step - 68) / 2, 0, 68, 54), true)
			var caption := String(part["text"]) if parts.size() == 1 else String(part["text"]).get_slice(" ", 0)
			_label(reward_col, caption, Rect2(2, 60, step - 4, 35), 26 if parts.size() == 1 else 30)
		if m["state"] == "claimed":
			content.modulate = Color("b1d5af")
	_label(root, I18n.t("daily.more_reward_days_reach_next") % DailyRewards.days_to_next_milestone(st), Rect2(100, 280, 620, 36), 25)


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
