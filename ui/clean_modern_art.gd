extends RefCounted
## Central artwork routing. Gameplay data and original source images stay intact.
static var _paths: Dictionary = {}
static var _sizes: Dictionary = {}
static var _initialized := false

static func _initialize() -> void:
	if _initialized:
		return
	_initialized = true
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/clean_modern/manifest.json"))
	for entry: Dictionary in manifest["replacements"]:
		_paths["res://" + entry["source"]] = "res://" + entry["replacement"]
		_sizes["res://" + entry["source"]] = Vector2i(entry["original_size"][0], entry["original_size"][1])
	for entry: Dictionary in manifest["atlas_resources"]:
		_paths["res://" + entry["source"]] = "res://" + entry["replacement"]

static func asset(path: String) -> Resource:
	# Legacy components resolve known foregrounds through the approved new pack.
	if path.begins_with("res://assets/workshop_gp/portraits/"):
		var portrait := preload("res://ui/soft_miniature.gd").texture(path.get_file().get_basename())
		if portrait != null: return portrait
	_initialize()
	return load(String(_paths.get(path, path)))

static func source_size(path: String, fallback: Vector2i) -> Vector2i:
	_initialize()
	return _sizes.get(path, fallback)
