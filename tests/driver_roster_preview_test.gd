extends SceneTree
## Roster tay đua: chip phẩm + thanh mảnh trên thẻ, chụp ở 320/390/412 vào Design/Previews/driver_roster_tier/.
## Chạy với XDG_DATA_HOME tạm (test ghi save).
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)


func settle() -> void:
	for i in 8:
		await process_frame


func _find(n: Node, node_name: String, out: Array) -> void:
	if n.name == node_name:
		out.append(n)
	for c in n.get_children():
		_find(c, node_name, out)


func run() -> void:
	var gs := root.get_node("GameState")
	check(gs.SAVE_PATH.contains("/tests/") or OS.get_environment("XDG_DATA_HOME") != "", "save cô lập")
	gs.reset_progress()
	gs.active = false
	gs.set_process(false)
	gs.owned_drivers = ["driver_an", "driver_dung", "driver_lam", "driver_phuong"]
	gs.driver_progress = {
		"driver_an": {"level": 0, "shards": 3},
		"driver_dung": {"level": 1, "shards": 20},
		"driver_lam": {"level": 2, "shards": 17},
		"driver_phuong": {"level": 5, "shards": 0},
	}
	gs.business_tier = 4
	gs.completed_races = 50
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	var out_dir := "res://Design/Previews/driver_roster_tier"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var page: Control = load("res://ui/driver_roster_page.gd").new()
	var holder := Control.new()
	root.add_child(holder)
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(scroll)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 12)
	pad.add_theme_constant_override("margin_right", 12)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(pad)
	pad.add_child(page)
	holder.add_child(page.sheet)
	await settle()
	for width in [320, 390, 412]:
		root.size = Vector2i(width, 844)
		await settle()
		var chips: Array = []
		_find(page, "TierChip", chips)
		var bars: Array = []
		_find(page, "ShardBar", bars)
		check(chips.size() >= 4, "mỗi thẻ có chip phẩm (%d)" % chips.size())
		check(bars.size() == 4, "4 thẻ đã có đều có thanh mảnh (%d)" % bars.size())
		for chip: Control in chips:
			check(chip.size.x <= 110.0, "chip không tràn ở %d" % width)
		for b: Control in bars:
			check(b.size.x > 40.0, "thanh mảnh còn chỗ ở %d" % width)
			var lab := b.get_child(0) as Label
			check(lab.get_minimum_size().x <= b.size.x - 4.0 and b.size.y >= 18.0, "chữ mảnh không bị cắt ở %d: %s" % [width, lab.text])
		var path := "%s/roster_%d.png" % [out_dir, width]
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	for width in [320, 390]:
		root.size = Vector2i(width, 844)
		for id in ["driver_an", "driver_lam"]:
			page._open_sheet(id)
			await settle()
			var radars: Array = []
			_find(page.sheet, "DriverRadar", radars)
			check(radars.size() == 1, "bảng chi tiết có biểu đồ (%s)" % id)
			check((radars[0] as Control).size.x > 200.0, "biểu đồ đủ rộng ở %d" % width)
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/sheet_%s_%d.png" % [out_dir, id, width]))
			page.close_sheet()
	print("driver_roster_preview_test: %s" % ("OK" if failures == 0 else "%d lỗi" % failures))
	quit(1 if failures > 0 else 0)
