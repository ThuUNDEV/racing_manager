class_name ExpansionArt
extends RefCounted
const CleanArt = preload("res://ui/clean_modern_art.gd")
## Cached HD expansion textures. Decorative nodes do not consume input.
const ROOT := "res://assets/racing_ui_hd_expansion/sprites/"
static var _textures: Dictionary = {}

const GEAR_ICON_ROOT := "res://assets/gear_icons_soft_v1/"

static func texture(id: String) -> Texture2D:
	if id.begins_with("gear_"):
		var gear_path := GEAR_ICON_ROOT + id + ".png"
		if ResourceLoader.exists(gear_path):
			if not _textures.has(id):
				_textures[id] = load(gear_path) as Texture2D
			return _textures[id]
	var clay := HdUi.Soft.expansion(id)
	if clay != null: return clay
	if not _textures.has(id):
		var path := ROOT + id + ".tres"
		_textures[id] = CleanArt.asset(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[id]

static func icon(id: String, extent: Vector2 = Vector2(48, 48)) -> TextureRect:
	var node := TextureRect.new()
	node.name = "Art_" + id
	node.texture = texture(id)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = extent
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if extent.x <= 0:
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func car_id(id: String, top_down: bool = false) -> String:
	var car := GameData.car(id)
	var model := String(car.get("class_name", "Pico")).to_lower()
	return "car_%s_%s" % [model, "topdown" if top_down else "showroom"]
