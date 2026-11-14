extends Control
const CleanArt = preload("res://ui/clean_modern_art.gd")
const PopupAnim = preload("res://ui/popup_anim.gd")
## Reusable responsive overlay. Caller owns rewards/persistence and closes the instance.
signal accepted
signal dismissed
const ROOT := "res://assets/workshop_gp/"
@export var title := "Thông báo"
@export_multiline var description := ""
@export_file var image_path := ""
@export var confirm_text := "Tiếp tục"
@export var cancel_text := "Hủy"
@export var show_cancel := false
var _panel: PanelContainer


func _ready() -> void:
	theme = HdUi.theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.04,0.08,0.13,.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,16)
	add_child(margin)
	var center := CenterContainer.new()
	margin.add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel",HdUi.card_style("modal"))
	center.add_child(_panel)
	PopupAnim.close_on_outside_click(self, _panel, func() -> void:
		if show_cancel:
			dismissed.emit())
	_resized()
	resized.connect(_resized)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	_panel.add_child(box)
	var heading := Label.new()
	heading.name = "Title"
	heading.text = title
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size",24)
	box.add_child(heading)
	if not image_path.is_empty():
		var picture := TextureRect.new()
		picture.name = "Artwork"
		picture.texture = CleanArt.asset(image_path)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size.y = 140
		box.add_child(picture)
	var body := Label.new()
	body.name = "Description"
	body.text = description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size",15)
	box.add_child(body)
	var confirm := Button.new()
	confirm.name = "Confirm"
	confirm.text = confirm_text
	confirm.custom_minimum_size.y = 48
	HdUi.style_button(confirm, "race")
	confirm.pressed.connect(func(): accepted.emit())
	box.add_child(confirm)
	if show_cancel:
		var cancel := Button.new()
		cancel.name = "Cancel"
		cancel.text = cancel_text
		cancel.custom_minimum_size.y = 44
		HdUi.style_button(cancel, "cancel")
		cancel.pressed.connect(func(): dismissed.emit())
		box.add_child(cancel)
	confirm.grab_focus()
	modulate.a = 0.0  # để PopupAnim chạy hoạt ảnh mở dù node đã hiện
	PopupAnim.open(self, _panel)


func _resized() -> void:
	if is_instance_valid(_panel):
		_panel.custom_minimum_size.x = minf(336,maxf(160,size.x-32))
