extends SceneTree
## Exercise real container sizing and rendered asset skins at supported phone widths.
var failures := 0
var main: Control

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL ", message)

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in 8:
		await process_frame

func capture(id: String) -> void:
	if "--layout-shots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var directory := OS.get_environment("TEMP").replace("\\", "/") + "/racing_layout_review"
		DirAccess.make_dir_recursive_absolute(directory)
		root.get_texture().get_image().save_png(directory + "/" + id + ".png")

func check_pack(page: Control, info_pattern: String) -> void:
	for info: Button in page.find_children(info_pattern, "Button", true, false):
		var skin := info.get_theme_stylebox("normal") as StyleBoxTexture
		check(skin.texture.get_height() <= info.size.y + 1, "info source fits its small control")
		var column := info.get_parent().get_parent()
		var header := info.get_parent().get_child(0) as PanelContainer
		var title_skin := header.get_theme_stylebox("panel") as StyleBoxTexture
		check(title_skin.texture_margin_top + title_skin.texture_margin_bottom < title_skin.texture.get_height(), "pack header has a center strip to stretch")
		var coupon := column.get_child(3) as PanelContainer
		check(coupon != null, "coupon row exists")
		if coupon == null:
			continue
		var frame := coupon.get_theme_stylebox("panel") as StyleBoxTexture
		# Cuts must preserve the corner region used by the full-size panel.
		var full := HdUi.panel()
		check(frame.texture_margin_left / frame.texture.get_width() >= full.texture_margin_left / full.texture.get_width() - 0.002, "coupon keeps complete left corners")
		check(frame.texture_margin_top / frame.texture.get_height() >= full.texture_margin_top / full.texture.get_height() - 0.002, "coupon keeps complete top corners")
		check(frame.texture_margin_bottom / frame.texture.get_height() >= full.texture_margin_bottom / full.texture.get_height() - 0.002, "coupon keeps complete bottom corners")
		check(coupon.size.y >= frame.texture_margin_top + frame.texture_margin_bottom, "coupon height fits both corners")
		for child: Control in column.get_children():
			check(child.get_global_rect().position.x >= column.get_global_rect().position.x - 1 and child.get_global_rect().end.x <= column.get_global_rect().end.x + 1, "pack child fits column")

func run() -> void:
	GameData.reload()
	var state := root.get_node("GameState")
	state.init_new_game()
	state.active = false
	state.gems = 150
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for viewport: Vector2i in [Vector2i(320, 568), Vector2i(360, 800), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		await settle()
		for tab in 5:
			main._select_tab(tab)
			if tab == 2:
				main._select_team_sub(0)
			await settle()
			var page := main._pages[tab] as ScrollContainer
			check(page.get_child(0).size.x <= page.size.x + 1, "page %d fits %d" % [tab, viewport.x])
			if tab == 1:
				check_pack(main._gear, "Info_*")
			elif tab == 2:
				check_pack(main._roster, "DriverInfo_*")
			await capture("%d_tab%d" % [viewport.x, tab])
		main._select_tab(2)
		main._select_team_sub(1)
		for section in ["0", "1", "2"]:
			main._garage.debug_show(section)
			await settle()
			check(main._garage.size.x <= main._pages[2].size.x + 1, "garage section %s fits %d" % [section, viewport.x])
			await capture("%d_garage%s" % [viewport.x, section])
		main.find_child("SettingsButton", true, false).pressed.emit()
		await settle()
		var panel := main._overlay_box.get_parent().get_parent() as Control
		check(panel.get_global_rect().position.x >= 0 and panel.get_global_rect().end.x <= viewport.x, "settings panel fits %d" % viewport.x)
		await capture("%d_settings" % viewport.x)
		main._overlay.hide()
		for pack_type in ["gear", "driver"]:
			if pack_type == "gear":
				main._show_gear_info("standard")
			else:
				main._show_driver_info("pro")
			await settle()
			check(panel.get_global_rect().position.x >= 0 and panel.get_global_rect().end.x <= viewport.x, "%s info panel fits %d" % [pack_type, viewport.x])
			await capture("%d_%s_info" % [viewport.x, pack_type])
			main._overlay.hide()
	state.active = false
	main.queue_free()
	await settle()
	print("ASSET_LAYOUT_TEST failures=", failures)
	quit(1 if failures else 0)
