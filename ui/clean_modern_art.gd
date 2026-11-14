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
	_initialize()
	return load(String(_paths.get(path, path)))

static func source_size(path: String, fallback: Vector2i) -> Vector2i:
	_initialize()
	return _sizes.get(path, fallback)
