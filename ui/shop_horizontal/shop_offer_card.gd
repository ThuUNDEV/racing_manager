@tool
class_name ShopOfferCard
extends PanelContainer

signal buy_pressed
signal buy2_pressed
signal detail_pressed
signal info_pressed

const GEM_ICON := preload("res://assets/soft_miniature_ui_v1/runtime_flare/currency_gem.png")
const TICKET_ICON := preload("res://assets/soft_miniature_ui_v1/runtime_flare/ticket.png")

@export var art: Texture2D: set = _set_art
@export var title: String = "": set = _set_title
@export var title_size: int = 38: set = _set_title_size
@export var gem_text: String = "": set = _set_gem
@export var ticket_text: String = "": set = _set_ticket
@export var badge_text: String = "": set = _set_badge
@export var badge_icon: Texture2D: set = _set_badge_icon
@export var badge_first: bool = false: set = _set_badge_first
@export var price_text: String = "": set = _set_price
@export var price_icon: Texture2D: set = _set_price_icon
@export var show_detail: bool = true: set = _set_detail
@export var show_info: bool = false: set = _set_info

var _custom_rewards: Array = []
var _reward_size := 36
var _reward_separators := true

@onready var _art: TextureRect = %Art
@onready var _title: Label = %Title
@onready var _info: Button = %InfoButton
@onready var _rewards: HFlowContainer = %Rewards
@onready var _badge: PanelContainer = %Badge
@onready var _badge_icon: TextureRect = %BadgeIcon
@onready var _badge_label: Label = %BadgeLabel
@onready var _center: VBoxContainer = %Center
@onready var _price: Button = %Price
@onready var _price2: Button = %Price2
@onready var _detail: LinkButton = %Detail


func _ready() -> void:
	_price.pressed.connect(buy_pressed.emit)
	_price2.pressed.connect(buy2_pressed.emit)
	_detail.pressed.connect(detail_pressed.emit)
	_info.pressed.connect(info_pressed.emit)
	_refresh()


## items: [{icon: Texture2D, text: String, tint: Color}] shown as one line of small reward chips.
func set_rewards(items: Array, font_size: int = 36, separators: bool = true) -> void:
	_custom_rewards = items
	_reward_size = font_size
	_reward_separators = separators
	_refresh()


func set_button_parts(button: Button, parts: Array, font_size: int = 30) -> void:
	for c in button.get_children():
		c.queue_free()
	button.text = ""
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for part in parts:
		if part is Texture2D:
			var icon := TextureRect.new()
			icon.texture = part
			icon.custom_minimum_size = Vector2(30, 30)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
		else:
			var label := Label.new()
			label.text = String(part)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_theme_font_size_override("font_size", font_size)
			label.add_theme_color_override("font_color", button.get_theme_color("font_disabled_color" if button.disabled else "font_color"))
			label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
			label.add_theme_constant_override("outline_size", 0)
			row.add_child(label)
	button.add_child(row)


func _refresh() -> void:
	if not is_node_ready():
		return
	_art.texture = art
	_title.text = title
	_title.add_theme_font_size_override("font_size", title_size)
	_info.visible = show_info
	var items := _custom_rewards
	if items.is_empty():
		if gem_text != "":
			items = items + [{"icon": GEM_ICON, "text": gem_text}]
		if ticket_text != "":
			items = items + [{"icon": TICKET_ICON, "text": ticket_text}]
	for c in _rewards.get_children():
		c.queue_free()
	for i in items.size():
		if i > 0 and _reward_separators:
			var sep := Panel.new()
			sep.custom_minimum_size = Vector2(2, 34)
			sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			sep.add_theme_stylebox_override("panel", _sep_style())
			_rewards.add_child(sep)
		_rewards.add_child(_chip(items[i]))
	_rewards.visible = not items.is_empty()
	_badge_label.text = badge_text
	_badge_icon.texture = badge_icon
	_badge_icon.visible = badge_icon != null
	_badge.visible = badge_text != ""
	_center.move_child(_badge, 1 if badge_first else _center.get_child_count() - 1)
	_price.text = price_text
	_price.icon = price_icon
	_detail.visible = show_detail


func _chip(item: Dictionary) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	if item.get("icon") != null:
		var icon := TextureRect.new()
		icon.texture = item["icon"]
		icon.modulate = item.get("tint", Color.WHITE)
		icon.custom_minimum_size = Vector2(_reward_size * 1.3, _reward_size * 1.2)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)
	var label := Label.new()
	label.text = String(item.get("text", ""))
	label.add_theme_font_size_override("font_size", _reward_size)
	box.add_child(label)
	return box


func _sep_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.86, 0.79, 0.69, 0.9)
	return s


func _set_art(v: Texture2D) -> void:
	art = v
	_refresh()


func _set_title(v: String) -> void:
	title = v
	_refresh()


func _set_title_size(v: int) -> void:
	title_size = v
	_refresh()


func _set_gem(v: String) -> void:
	gem_text = v
	_refresh()


func _set_ticket(v: String) -> void:
	ticket_text = v
	_refresh()


func _set_badge(v: String) -> void:
	badge_text = v
	_refresh()


func _set_badge_icon(v: Texture2D) -> void:
	badge_icon = v
	_refresh()


func _set_badge_first(v: bool) -> void:
	badge_first = v
	_refresh()


func _set_price(v: String) -> void:
	price_text = v
	_refresh()


func _set_price_icon(v: Texture2D) -> void:
	price_icon = v
	_refresh()


func _set_detail(v: bool) -> void:
	show_detail = v
	_refresh()


func _set_info(v: bool) -> void:
	show_info = v
	_refresh()
