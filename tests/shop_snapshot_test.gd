extends SceneTree
## Pixel snapshot of the Shop at the supported phone widths.
##
## Catches the "UI got skewed / clipped after an edit" class of bug: every width is rendered
## and compared against tests/golden/shop_<width>_<scroll>.png.
##   godot --path . -s tests/shop_snapshot_test.gd                       compare
##   godot --path . -s tests/shop_snapshot_test.gd -- --update-golden    rewrite goldens
## Needs a real renderer; under --headless it prints SKIP and passes.
const WIDTHS := [320, 390, 412, 448]
const SCROLLS := [0, 400, 700, 800, 1500]
const GOLDEN_DIR := "res://tests/golden/"
## A pixel counts as different when any channel moves by more than this (0-1).
const CHANNEL_TOLERANCE := 0.06
## Fail when more than this fraction of pixels differ.
const MAX_DIFF_FRACTION := 0.004

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	print("OK " if ok else "FAIL ", message)
	if not ok:
		failures += 1


func settle() -> void:
	for i in 12:
		await process_frame


func diff_fraction(a: Image, b: Image) -> float:
	if a.get_size() != b.get_size():
		return 1.0
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	var bad := 0
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if absf(ca.r - cb.r) > CHANNEL_TOLERANCE or absf(ca.g - cb.g) > CHANNEL_TOLERANCE or absf(ca.b - cb.b) > CHANNEL_TOLERANCE:
				bad += 1
	return float(bad) / float(a.get_width() * a.get_height())


func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIP shop snapshot: no renderer under --headless")
		print("SHOP_SNAPSHOT_TEST failures=0")
		quit(0)
		return
	var update := "--update-golden" in OS.get_cmdline_user_args()
	var state := root.get_node("GameState")
	check(state.SAVE_PATH.contains("/tests/"), "save isolated")
	GameData.reload()
	state.init_new_game()
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.business_tier = 4
	state.unlocked_tier = 4
	state.owned_cars["car_titan_tia_chop"] = true
	state.car_levels["car_titan_tia_chop"] = {"engine": 0, "tyre": 0, "chassis": 0, "gearbox": 0}
	state.active_car_id = "car_titan_tia_chop"
	state.completed_races = 30
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	state.active = false
	main._select_tab(main.Tab.SHOP)
	main._rebuild_shop()
	await settle()
	var scroll: ScrollContainer = main._shop_box.get_parent()
	if update:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GOLDEN_DIR))
	for width: int in WIDTHS:
		root.size = Vector2i(width, 844)
		for offset: int in SCROLLS:
			scroll.scroll_vertical = offset
			await settle()
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			var path := "%sshop_%d_%d.png" % [GOLDEN_DIR, width, offset]
			if update:
				image.save_png(path)
				print("WROTE ", path)
				continue
			if not FileAccess.file_exists(path):
				check(false, "golden exists %s (run with -- --update-golden)" % path)
				continue
			var fraction := diff_fraction(image, Image.load_from_file(ProjectSettings.globalize_path(path)))
			check(fraction <= MAX_DIFF_FRACTION, "shop %dpx scroll %d matches golden (%.3f%% differ)" % [width, offset, fraction * 100.0])
			if fraction > MAX_DIFF_FRACTION:
				image.save_png("user://shop_snapshot_%d_%d.png" % [width, offset])
	print("SHOP_SNAPSHOT_TEST failures=%d" % failures)
	quit(1 if failures > 0 else 0)
