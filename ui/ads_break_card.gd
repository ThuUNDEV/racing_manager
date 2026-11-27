extends Control
## Thẻ báo trước Ads Break (Design/26 §17.7): chặn chạm, không có nút, không đóng bằng chạm ngoài.

const HdUi = preload("res://ui/hd_ui.gd")

const CARD_W := 280.0

var _title: Label
var _reward: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.08, 0.13, 0.76)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.name = "Card"
	panel.add_theme_stylebox_override("panel", HdUi.panel(16.0))
	panel.custom_minimum_size.x = CARD_W
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	_title = _line(16, Color("1d2b44"))
	column.add_child(_title)
	_reward = _line(22, Color("169c46"))
	column.add_child(_reward)


func _line(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func open(amount: String) -> void:
	_title.text = I18n.t("ads.break_title")
	_reward.text = I18n.t("ads.break_reward") % amount
	move_to_front()
	show()
