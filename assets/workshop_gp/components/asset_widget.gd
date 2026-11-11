extends PanelContainer
## Reusable, data-only UI. Call configure() with display data; connect action_requested.
## No economy, save or race logic lives in this component.
signal action_requested(id: String)

const ROOT := "res://assets/workshop_gp/"
const INK := Color("16355c")
const MUTED := Color("5a7294")
@export_enum("upgrade", "driver", "league", "reward", "mission", "toast", "stat", "resource", "modal") var kind := "upgrade"
@export var item_id := ""
@export var title := "Động cơ"
@export_multiline var subtitle := "Cấp 2 · 44 → 46"
@export var image_path := "res://assets/workshop_gp/icons/vector_dark/engine.svg"
@export var action_text := "Nâng cấp · 120"
@export var disabled := false
@export var selected := false
@export_range(0, 100) var progress := 40.0
var _built := false


func configure(data: Dictionary) -> void:
	for key: String in data:
		if key in ["kind", "item_id", "title", "subtitle", "image_path", "action_text", "disabled", "selected", "progress"]:
			set(key, data[key])
	if is_node_ready():
		_rebuild()


func _ready() -> void:
	theme = HdUi.theme()
	_rebuild()


## Update affordability without rebuilding the card every frame.
func set_action_disabled(value: bool) -> void:
	if disabled == value:
		return
	disabled = value
	var button := get_node_or_null("Content/Action") as Button
	if button != null:
		button.disabled = value
	var style_name := "card_selected" if selected else ("card_locked" if disabled else "card")
	add_theme_stylebox_override("panel", HdUi.card_style(style_name))


func _text(value: String, point_size: int, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", point_size)
	label.add_theme_color_override("font_color", color)
	return label


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_built = true
	var style_name := "card_selected" if selected else ("card_locked" if disabled else "card")
	if kind == "toast":
		style_name = "toast"
	add_theme_stylebox_override("panel", HdUi.card_style(style_name))
	var vertical := VBoxContainer.new()
	vertical.name = "Content"
	vertical.add_theme_constant_override("separation", 7)
	add_child(vertical)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vertical.add_child(row)
	if not image_path.is_empty():
		var picture := TextureRect.new()
		picture.name = "Artwork"
		picture.texture = load(image_path) as Texture2D
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var extent := Vector2(32, 36)
		if kind == "driver":
			extent = Vector2(90, 112)
		elif kind == "reward" or kind == "modal":
			extent = Vector2(92, 100)
		elif kind == "league":
			extent = Vector2(62, 65)
		picture.custom_minimum_size = extent
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(picture)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	labels.add_theme_constant_override("separation", 5)
	row.add_child(labels)
	var heading := _text(title, 16 if kind != "resource" else 18, Color.WHITE if kind == "toast" else INK)
	heading.name = "Title"
	labels.add_child(heading)
	if not subtitle.is_empty():
		var detail := _text(subtitle, 12, Color("dbe7fb") if kind == "toast" else MUTED)
		detail.name = "Subtitle"
		labels.add_child(detail)
	if kind in ["stat", "mission", "league"]:
		var bar := ProgressBar.new()
		bar.name = "Progress"
		bar.custom_minimum_size.y = 8
		bar.show_percentage = false
		bar.value = progress
		var background := StyleBoxFlat.new()
		background.bg_color = Color("b9cfee")
		background.set_corner_radius_all(4)
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("ff8a00")
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("background", background)
		bar.add_theme_stylebox_override("fill", fill)
		vertical.add_child(bar)
	if not action_text.is_empty():
		var button := Button.new()
		button.name = "Action"
		button.text = action_text
		button.custom_minimum_size.y = 44
		HdUi.style_button(button, "upgrade")
		button.disabled = disabled
		button.pressed.connect(func(): action_requested.emit(item_id))
		vertical.add_child(button)
