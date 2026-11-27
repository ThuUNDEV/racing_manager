extends SceneTree
## Chặn ảnh UI bị vỡ khi thu nhỏ: mọi texture trong res://assets phải import có mipmap,
## và project phải đặt filter canvas mặc định là Linear Mipmap.
## Ảnh nguồn thường to gấp nhiều lần kích thước hiển thị; thiếu mipmap thì viền răng cưa, nét đứt.
const ROOT := "res://assets"
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL ", message)


func collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		collect(dir_path.path_join(sub), out)
	for file in dir.get_files():
		if file.ends_with(".import"):
			out.append(dir_path.path_join(file))


func run() -> void:
	var filter: int = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", 1)
	check(filter == Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,
		"project.godot phải đặt rendering/textures/canvas_textures/default_texture_filter=2 (Linear Mipmap), đang là %d" % filter)
	var defaults: Variant = ProjectSettings.get_setting("importer_defaults/texture", {})
	check(defaults is Dictionary and defaults.get("mipmaps/generate", false) == true,
		"project.godot phải có [importer_defaults] texture={\"mipmaps/generate\": true}")

	var files: Array[String] = []
	collect(ROOT, files)
	var textures := 0
	var missing: Array[String] = []
	for path in files:
		var cfg := ConfigFile.new()
		if cfg.load(path) != OK:
			continue
		if cfg.get_value("remap", "importer", "") != "texture":
			continue
		textures += 1
		if cfg.get_value("params", "mipmaps/generate", false) != true:
			missing.append(path.trim_suffix(".import"))
	check(textures > 0, "không tìm thấy texture nào trong %s" % ROOT)
	for path in missing:
		print("  thiếu mipmap: ", path)
	check(missing.is_empty(),
		"%d texture chưa bật mipmap (Import > Mipmaps > Generate, hoặc mipmaps/generate=true trong .import)" % missing.size())

	print("texture_import_test: %d texture, %d lỗi" % [textures, failures])
	quit(1 if failures > 0 else 0)
