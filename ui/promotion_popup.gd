extends Control
const PopupAnim = preload("res://ui/popup_anim.gd")
const PromoUi = preload("res://ui/pack_promo_ui.gd")
## Bảng thăng hạng (thăng giải): mở từ huy hiệu góc trái khung đua. Logic ở GameState.expansion_state()/request_expansion().
## Bố cục theo Design/Demos/PromotionPopup/flare_A.png (Soft Miniature, kiểu popup pack promo).
signal closed
signal notice(text: String)

const INK := Color("0e2b5c")
const MUTED := Color("52636c")
const OK_EDGE := Color("5dbb4a")
const OK_FILL := Color("3fae3f")
const NO_EDGE := Color("e8604f")
const NO_FILL := Color("e5483c")
const RANK_DIR := "res://assets/league_ranks_v1/"
const UI_DIR := "res://assets/promotion_ui_v1/"
var _popup: PanelContainer
var _current: Label
var _next: Label
var _current_icon: TextureRect
var _next_icon: TextureRect
var _tiles: HBoxContainer
var _tiles_box: Control
var _rewards: HBoxContainer
var _note: Label
var _action: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.12, 0.25, 0.65)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_popup = PanelContainer.new()
	_popup.name = "PromotionPopup"
	_popup.add_theme_stylebox_override("panel", PromoUi.shell_style())
	add_child(_popup)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	_popup.add_child(root)
	var header := PromoUi.header(I18n.t("promotion.title"), _close)
	header.name = "PromotionHeader"
	root.add_child(header)
	# Khối hai khiên: giải hiện tại › giải kế tiếp.
	var leagues := PanelContainer.new()
	leagues.name = "PromotionLeagues"
	leagues.add_theme_stylebox_override("panel", _flat(Color("bfe4f6"), Color("8cc7e6"), 18, 3, 10))
	root.add_child(leagues)
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 6)
	leagues.add_child(lrow)
	var cur := _league_box(lrow, "PromotionCurrent")
	_current = cur[0]
	_current_icon = cur[1]
	var arrow := _icon(UI_DIR + "arrow_gold.png", 34)
	arrow.size_flags_vertical = SIZE_SHRINK_CENTER
	arrow.custom_minimum_size = Vector2(34, 34)
	lrow.add_child(arrow)
	var nxt := _league_box(lrow, "PromotionNext")
	_next = nxt[0]
	_next_icon = nxt[1]
	_tiles = HBoxContainer.new()
	_tiles.name = "PromotionRequirements"
	_tiles.add_theme_constant_override("separation", 8)
	root.add_child(_tiles)
	var reward_panel := PanelContainer.new()
	reward_panel.name = "PromotionRewardPanel"
	reward_panel.add_theme_stylebox_override("panel", _flat(Color("f4ecff"), Color("b58ae8"), 16, 3, 8))
	root.add_child(reward_panel)
	_tiles_box = reward_panel
	_rewards = HBoxContainer.new()
	_rewards.name = "PromotionRewards"
	_rewards.alignment = BoxContainer.ALIGNMENT_CENTER
	_rewards.add_theme_constant_override("separation", 14)
	reward_panel.add_child(_rewards)
	_note = _label("", 12, MUTED, true)
	_note.name = "PromotionNote"
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_note)
	_action = Button.new()
	_action.name = "PromotionAction"
	_action.text = I18n.t("promotion.action")
	_action.custom_minimum_size = Vector2(0, 52)
	_action.add_theme_font_size_override("font_size", 22)
	PromoUi.style_cta(_action)
	_action.add_theme_stylebox_override("focus", StyleBoxEmpty.new())  # style_cta dùng khung cam đặc cho focus, che mất trạng thái tắt
	_action.pressed.connect(_promote)
	root.add_child(_action)
	PopupAnim.close_on_outside_click(self, _popup, _close)
	GameState.changed.connect(_refresh_if_visible)
	visibility_changed.connect(_refresh_if_visible)
	resized.connect(_fit_popup)
	refresh()
	_fit_popup()


func open() -> void:
	refresh()
	_fit_popup()
	PopupAnim.open(self, _popup)
	_fit_popup()


func _close() -> void:
	PopupAnim.close(self, _popup, closed.emit)


func _fit_popup() -> void:
	if not is_instance_valid(_popup):
		return
	# Đặt bề ngang trước, đợi container xếp lại (nhãn tự xuống dòng) rồi mới căn giữa theo chiều cao thật.
	_popup.size = Vector2(minf(366, maxf(0, size.x - 32)), 0.0)
	await get_tree().process_frame
	if not is_instance_valid(_popup):
		return
	_popup.size.y = 0.0
	_popup.position = ((size - _popup.size) * 0.5).floor()


func _refresh_if_visible() -> void:
	if is_visible_in_tree():
		refresh()


func _promote() -> void:
	var target := GameState.business_tier + 1
	if GameState.request_expansion():
		if GameState.business_tier >= target:
			notice.emit(I18n.t("promotion.promoted") % Balance.league_name(GameState.business_tier))
		else:
			notice.emit(I18n.t("promotion.queued"))
	else:
		notice.emit(I18n.t("promotion.failed"))
	refresh()


func refresh() -> void:
	if _current == null:
		return
	var top := GameData.leagues().size() - 1
	var tier := GameState.business_tier
	_current.text = Balance.league_name(tier)
	_set_icon(_current_icon, tier)
	_clear(_tiles)
	_clear(_rewards)
	if tier >= top:
		_next.text = "-"
		_next_icon.modulate = Color(1, 1, 1, 0.25)
		_tiles.hide()
		_tiles_box.hide()
		_note.text = I18n.t("promotion.max_league")
		_note.show()
		_action.disabled = true
		_fit_popup.call_deferred()
		return
	_tiles.show()
	_tiles_box.show()
	var nxt := tier + 1
	_next.text = Balance.league_name(nxt)
	_set_icon(_next_icon, nxt)
	_next_icon.modulate = Color.WHITE
	var min_rev := int(GameData.economy()["business"]["expansion_min_revenue_level"])
	var low_rev := min_rev
	for kind in Balance.REVENUE:
		low_rev = mini(low_rev, GameState.level_of(kind))
	_tile(Soft_icon("ticket"), I18n.t("promotion.req_revenue"), "%d/%d" % [low_rev, min_rev], low_rev >= min_rev)
	var need_class := int(GameData.league(nxt)["min_car_class"])
	var have_class := int(GameData.car(GameState.active_car_id)["class"])
	_tile(load("res://assets/racing_ui_hd/icons/car_red.png") as Texture2D, I18n.t("promotion.req_car"), "%d/%d" % [have_class, need_class], have_class >= need_class)
	var cost := Pricing.expansion_cost(tier)
	_tile(Soft_icon("currency_cash"), I18n.t("promotion.req_fee"), "%s/%s" % [Balance.fmt_money(GameState.coins), Balance.fmt_money(cost)], GameState.coins.compare(cost) >= 0)
	if not GameState.processed_rewards.has("business_open/%d" % nxt):
		_rewards.add_child(_icon_tex(Soft_icon("currency_cash"), 30))
		_rewards.add_child(_label(Balance.fmt_money(Pricing.opening_reserve(nxt)), 20, INK))
		_rewards.add_child(_icon_tex(Soft_icon("currency_gem"), 30))
		_rewards.add_child(_label(I18n.t("promotion.reward_gems") % int(GameData.economy()["rewards"]["first_league_gems"]), 20, INK))
	else:
		_rewards.add_child(_label(I18n.t("promotion.reward_none"), 16, MUTED))
	var state := GameState.expansion_state()
	var queued := GameState.expansion_requested
	match state:
		"save_error":
			_note.text = I18n.t("promotion.save_error")
		"ok":
			_note.text = I18n.t("promotion.queued") if queued else I18n.t("promotion.reset_warning")
		_:
			_note.text = ""
	_note.visible = _note.text != ""
	_action.disabled = state != "ok" or queued
	_fit_popup.call_deferred()


static func Soft_icon(id: String) -> Texture2D:
	return HdUi.Soft.texture(id)


func _set_icon(icon: TextureRect, tier: int) -> void:
	var path := RANK_DIR + "rank_%d.png" % tier
	icon.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null


## Ô điều kiện: icon, nhãn ngắn, pill giá trị (xanh khi đạt, đỏ khi chưa).
func _tile(texture: Texture2D, caption: String, value: String, done: bool) -> void:
	var card := PanelContainer.new()
	card.name = "PromotionTile"
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _flat(Color("fffbf3"), OK_EDGE if done else NO_EDGE, 16, 3, 6))
	_tiles.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	card.add_child(col)
	var pic := _icon_tex(texture, 38)
	col.add_child(pic)
	var name_label := _label(caption, 13, INK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name_label)
	var pill := PanelContainer.new()
	pill.name = "PromotionValue"
	pill.add_theme_stylebox_override("panel", _flat(OK_FILL if done else NO_FILL, Color.TRANSPARENT, 12, 0, 3))
	col.add_child(pill)
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 3)
	pill.add_child(line)
	line.add_child(_icon(UI_DIR + ("check_ok.png" if done else "check_no.png"), 16))
	line.add_child(_label(value, 12, Color.WHITE))


func _league_box(parent: Control, node_name: String) -> Array:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	parent.add_child(box)
	var icon := TextureRect.new()
	icon.name = node_name + "Icon"
	icon.custom_minimum_size = Vector2(0, 84)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _flat(Color("e8f5fc"), Color("a9d3ea"), 14, 2, 4))
	box.add_child(pill)
	var name_label := _label("", 15, INK, true)
	name_label.name = node_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(name_label)
	return [name_label, icon]


func _icon(path: String, extent: float) -> TextureRect:
	return _icon_tex(load(path) as Texture2D, extent)


func _icon_tex(texture: Texture2D, extent: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(extent, extent)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	icon.size_flags_horizontal = SIZE_SHRINK_CENTER
	icon.size_flags_vertical = SIZE_SHRINK_CENTER
	return icon


func _flat(fill: Color, edge: Color, radius: int, border: int, pad: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(pad)
	return style


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _label(text: String, font_size: int = 14, color: Color = INK, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = MOUSE_FILTER_IGNORE
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = SIZE_EXPAND_FILL
	return label
