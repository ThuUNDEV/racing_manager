extends SceneTree
## Run this external script with --main-pack <export.pck> from an empty directory.
## Loading the pack into the source project would mask missing exported files.
const Art = preload("res://ui/clean_modern_art.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
	print("OK " if ok else "FAIL ", message)

func run() -> void:
	var font := load("res://assets/clean_modern/fonts/Roboto-Bold.ttf") as Font
	check(font != null and font.has_char(0x1ef7), "bundled bold font with Vietnamese exported")
	for icon in ["nav_bag", "nav_team", "shop_buy"]:
		check(load("res://assets/clean_modern/icons/%s.svg" % icon) != null, "exported navigation icon " + icon)
	check(not FileAccess.file_exists("res://tests/clean_modern_ui_test.gd"), "source tests excluded from pack")
	for hero in ["hero_starter", "hero_driver_my", "hero_income_x2"]:
		check(load("res://assets/iap_offers/illustrations/%s.png" % hero) != null, "V5 approved hero exported " + hero)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/clean_modern/manifest.json"))
	var loaded := 0
	for entry: Dictionary in manifest["replacements"] + manifest["atlas_resources"]:
		var texture := Art.asset("res://" + entry["source"]) as Texture2D
		if texture != null and texture.get_width() > 0 and texture.resource_path == "res://" + entry["replacement"]:
			loaded += 1
	check(loaded == 467, "467 routed textures load from exported pack")
	check(not JSON.parse_string(FileAccess.get_file_as_string("res://assets/iap_offers/manifest.json")).is_empty(), "Shop recipes exported")
	for product: Dictionary in root.get_node("Iap").products():
		var scene := load("res://assets/iap_offers/art/%s.tscn" % product["sku"]) as PackedScene
		check(scene != null, "exported offer scene " + String(product["sku"]))
		if scene != null:
			scene.instantiate().free()
	var audio: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop_gp/audio/catalog.json"))
	for entry: Dictionary in audio:
		check(load("res://assets/workshop_gp/" + String(entry["path"])) != null, "dynamic audio " + String(entry["path"]))
	for id in ["harbor", "pine", "city"]:
		check(not JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop_gp/layout/%s.json" % id)).is_empty(), "track layout " + id)
	print("CLEAN_MODERN_EXPORT_TEST failures=", failures)
	quit(1 if failures else 0)
