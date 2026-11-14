extends SceneTree
## Shop có mục Mở gói: bốn thẻ (2 tay đua + 2 phụ kiện), nút x1/x10 mở được và trừ gem.
var failures := 0


func check(value: bool, message: String) -> void:
	print("  ", "OK " if value else "FAIL ", message)
	if not value:
		failures += 1


func _initialize() -> void:
	call_deferred("run")


func settle() -> void:
	for i in range(5):
		await process_frame


func run() -> void:
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	state.SAVE_PATH = "user://shop_packs_test_save.json"
	state.BAK_PATH = "user://shop_packs_test_save.bak"
	state.TMP_PATH = "user://shop_packs_test_save.tmp"
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 844)
	state.gems = 5000
	var main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main._select_tab(4)
	await settle()
	for k in ["driver_pro", "driver_allstar", "gear_standard", "gear_elite"]:
		for n in [1, 10]:
			check(main.find_child("ShopOpen_%s_x%d" % [k, n], true, false) != null, "có nút %s x%d trong Shop" % [k, n])
	var before: int = state.gear_open_count
	var b := main.find_child("ShopOpen_gear_standard_x1", true, false) as Button
	check(b != null, "tìm thấy nút mở gói phụ kiện")
	if b != null:
		b.pressed.emit()
		await settle()
		check(int(state.gear_open_count) > before or state.gems < 5000, "mở gói phụ kiện từ Shop có hiệu lực (gem hoặc lượt đổi)")
	main._close_overlay()
	var d := main.find_child("ShopOpen_driver_pro_x1", true, false) as Button
	var dbefore: int = state.driver_open_count
	if d != null:
		d.pressed.emit()
		await settle()
		check(int(state.driver_open_count) > dbefore or d.disabled, "mở gói tay đua từ Shop")
	var i := main.find_child("ShopPackInfo_gear_elite", true, false) as Button
	if i != null:
		i.pressed.emit()
		await settle()
		check(main._overlay.visible, "nút i mở bảng tỉ lệ")
	# Lối tắt từ Gear và Team sang Shop.
	state.grant_gear_coupons("standard", 1)
	for tab in [1, 2]:
		main._select_tab(tab)
		if tab == 2:
			main._select_team_sub(0)
		await settle()
		var go: Button = null
		for c in main.find_children("OpenPacksInShop", "Button", true, false):
			if c.is_visible_in_tree():
				go = c
		check(go != null, "tab %d có nút lối tắt Mở gói" % tab)
		if go != null:
			go.pressed.emit()
			await settle()
			check(main._tab == main.Tab.SHOP, "tab %d: bấm lối tắt sang Shop" % tab)
	var dot := main._nav_items[main.Tab.SHOP].get_node("NavDot") as Control
	check(dot.visible, "có coupon: chấm đỏ trên tab Shop")
	print("shop_packs_test: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(1 if failures > 0 else 0)
