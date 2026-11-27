extends SceneTree
## Capture every screen and popup into output/screens/<width>/*.webp plus index.json.
## XDG_DATA_HOME=$(mktemp -d) RM_LANG=vi godot --path . --screen 1 --audio-driver Dummy -s res://tools/capture_all_screens.gd

const BigNumber = preload("res://core/math/big_number.gd")
const PopupAnim = preload("res://ui/popup_anim.gd")
const OUT := "res://output/screens"
const SIZES := [Vector2i(320, 693), Vector2i(390, 844), Vector2i(412, 892)]

var state: Node
var main: Control
var width := 390
var index: Array = []


func _initialize() -> void:
	call_deferred("run")


func settle(frames: int = 20) -> void:
	for i in frames:
		await process_frame


func shot(group: String, id: String, title: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var dir := "%s/%d" % [OUT, width]
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_texture().get_image().save_webp("%s/%s.webp" % [dir, id], true, 0.86)
	if not index.any(func(e: Dictionary) -> bool: return e["id"] == id):
		index.append({"group": group, "id": id, "title": title, "widths": [width]})
	else:
		for entry: Dictionary in index:
			if entry["id"] == id and not width in entry["widths"]:
				entry["widths"].append(width)
	print("SHOT %d %s" % [width, id])


## Fresh, mid-game state so most content is unlocked and filled.
func seed_state() -> void:
	state.init_new_game()
	state.active = false
	state.set_process(false)
	state.save_blocked = false
	state.tutorial = {"state": "done", "step": "", "gated": false, "tips_off": true}
	state.completed_races = 25
	state.coins = BigNumber.from_int(1250000)
	state.gems = 1240
	state.trophies = 12
	state.trophies_earned = 12
	state.grant_gear_coupons("standard", 3)
	state.driver_coupons["pro"] = 2


func build_main() -> void:
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._tutorial.set_process(false)
	main._overlay.hide()


func drop_main() -> void:
	main.queue_free()
	await settle(4)


func close_all() -> void:
	main._overlay.hide()
	main._promotion.hide()
	main._class_page.hide()
	await settle(4)


## Scroll a tab page and capture each screenful.
func scroll_shots(scroll: ScrollContainer, group: String, id: String, title: String) -> void:
	scroll.scroll_vertical = 0
	await settle()
	var step := int(scroll.size.y * 0.85)
	var limit := int(scroll.get_v_scroll_bar().max_value - scroll.size.y)
	var n := 1
	var y := 0
	while true:
		scroll.scroll_vertical = y
		await shot(group, "%s_%d" % [id, n], "%s %d" % [title, n])
		if y >= limit - 4 or n >= 12:
			break
		y = mini(y + step, limit)
		n += 1
	scroll.scroll_vertical = 0


func page_scroll(tab: int) -> ScrollContainer:
	var page: Node = main._pages[tab]
	if page is ScrollContainer:
		return page
	var found := page.find_children("*", "ScrollContainer", true, false)
	for node: ScrollContainer in found:
		if node.is_visible_in_tree() and node.size.y > 200:
			return node
	return null


func tab_shots(tab: int, group: String, id: String, title: String) -> void:
	var scroll := page_scroll(tab)
	if scroll == null:
		await shot(group, id + "_1", title + " 1")
	else:
		await scroll_shots(scroll, group, id, title)


func run() -> void:
	PopupAnim.enabled = false
	state = root.get_node("GameState")
	assert(OS.get_user_data_dir().begins_with("/tmp"), "run with an isolated XDG_DATA_HOME")
	GameData.reload()
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	var sizes := SIZES.duplicate()
	sizes.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return absi(a.x - 390) < absi(b.x - 390))  # 390 sets the order
	for dimensions: Vector2i in sizes:
		width = dimensions.x
		root.size = dimensions
		await settle()
		await capture_game()
		await capture_startup()
	index = ordered(index)
	var file := FileAccess.open(OUT + "/index.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(index, "  "))
	file.close()
	print("DONE ", index.size())
	quit(0)


## Entries first seen at a later width (extra scroll step) move next to their siblings.
func ordered(list: Array) -> Array:
	var out: Array = []
	for e: Dictionary in list:
		var stem: String = e["id"].rstrip("0123456789")
		var at := out.size()
		if stem.ends_with("_"):
			for i in out.size():
				if out[i]["id"].begins_with(stem) and out[i]["group"] == e["group"]:
					at = i + 1
		out.insert(at, e)
	return out


func capture_game() -> void:
	seed_state()
	await build_main()

	# Race
	state.begin_countdown()
	state._start_race()
	state.active = false
	for i in state.sim.cars.size():
		var car: TrafficSim.Car = state.sim.cars[i]
		car.s = state.sim.lap_length * (0.12 + i * 0.085)
		car.prev_s = car.s
	state.sim.tick_count = 1
	main._select_tab(main.Tab.RACE)
	main._sync_sim()
	main._update_race_ui()
	main._race_view.overlay_text = ""
	main._race_view.alpha = 1.0
	await shot("Đua", "race_main", "Màn đua")
	main._upgrade_scroll.scroll_vertical = 100000
	await shot("Đua", "race_upgrades", "Nâng cấp (cuối danh sách)")
	main._upgrade_scroll.scroll_vertical = 0
	main._show_race_result({"position": 1, "money": BigNumber.from_int(5400), "trophies": 1, "points": 120, "unlocked": []})
	await shot("Đua", "race_result", "Kết quả lượt đua")
	main._result_panel.hide()
	main._ads_controls._open("income_boost")
	await shot("Đua", "ad_boost", "Quảng cáo ×2 thu nhập")
	await drop_main()
	seed_state()
	await build_main()
	main._select_tab(main.Tab.RACE)
	main._ads_controls._open("flag_cash")
	await shot("Đua", "ad_flag", "Quảng cáo cờ thưởng tiền")
	await drop_main()
	seed_state()
	await build_main()
	main._select_tab(main.Tab.RACE)
	main._break_card.open(Balance.fmt_money(BigNumber.from_int(5400)))
	await shot("Đua", "ads_break", "Ads Break: thẻ báo trước")
	await drop_main()
	seed_state()
	await build_main()

	# Gear
	main._select_tab(main.Tab.BAG)
	await tab_shots(main.Tab.BAG, "Gear", "gear", "Gear")
	main._show_gear_info("standard")
	await shot("Gear", "gear_rates", "Tỉ lệ gói gear")
	await close_all()
	main._on_gear_open("standard", 1)
	await settle(260)
	await shot("Gear", "gear_result", "Kết quả mở gói gear")
	await close_all()

	# Team
	main._select_tab(main.Tab.TEAM)
	main._select_team_sub(0)
	await tab_shots(main.Tab.TEAM, "Đội", "drivers", "Tay đua")
	main._roster._open_sheet(state.active_driver_id)
	await shot("Đội", "driver_sheet", "Chi tiết tay đua")
	main._roster.close_sheet()
	main._show_driver_info("pro")
	await shot("Đội", "driver_rates", "Tỉ lệ gói tay đua")
	await close_all()
	main._on_driver_open("pro", 1)
	await settle(260)
	await shot("Đội", "driver_result", "Kết quả mở gói tay đua")
	await close_all()
	main._select_team_sub(1)
	await tab_shots(main.Tab.TEAM, "Đội", "garage", "Garage")
	for section in [1, 2]:
		main._garage.debug_show(str(section))
		await shot("Đội", "garage_section_%d" % section, ["Garage: phụ tùng", "Garage: ngoại hình"][section - 1])
	main._garage.debug_show("0,collection")
	await shot("Đội", "garage_collection", "Bộ sưu tập xe")

	# Leagues
	main._select_tab(main.Tab.LEAGUE)
	for group in ["offense", "defense", "income"]:
		main._set_trophy_group(group)
		await shot("Giải đấu", "league_" + group, "Cúp: " + {"offense": "tấn công", "defense": "phòng thủ", "income": "thu nhập"}[group])
	main._show_trophy_rules()
	await shot("Giải đấu", "trophy_rules", "Luật cúp")
	await close_all()
	main._show_promotion()
	await shot("Giải đấu", "promotion", "Thăng hạng")
	await close_all()
	main._show_classes()
	await shot("Giải đấu", "classes", "Class xe")
	main._class_page._open_picker()
	await shot("Giải đấu", "facility_picker", "Chọn cơ sở")
	main._class_page._close_picker()
	main._class_page._rename_dialog._show_edit()
	await shot("Giải đấu", "team_name", "Đổi tên đội")
	main._class_page._rename_dialog.hide()
	await close_all()

	# Shop
	main._select_tab(main.Tab.SHOP)
	await settle(40)
	await tab_shots(main.Tab.SHOP, "Shop", "shop", "Shop")
	for sku in ["starter_1", "starter_2", "starter_3", "offer_combo_1", "offer_combo_2", "offer_noads_bundle", "weekly_s", "daily_gear", "daily_driver", "income_x2", "no_ads", "char_my"]:
		main._show_iap_detail(sku)
		await shot("Shop", "iap_" + sku, "Chi tiết gói " + sku)
		await close_all()
	main._show_iap_odds("starter_1")
	await shot("Shop", "iap_odds", "Tỉ lệ trong gói IAP")
	await close_all()

	# Common popups
	main._select_tab(main.Tab.RACE)
	main._show_settings()
	await shot("Popup chung", "settings", "Cài đặt")
	main._show_language_picker()
	await shot("Popup chung", "language", "Chọn ngôn ngữ")
	await close_all()
	state.offline_report = {"elapsed": 5400.0, "eligible": 5400.0, "rate": 8.0, "ratio": 0.5, "reward": BigNumber.from_int(28800), "capped": false}
	main._show_offline()
	await shot("Popup chung", "offline", "Thu nhập vắng mặt")
	await close_all()
	state.offline_report = {}
	main._show_feedback("Garage", "Tính năng mở khóa sau vài lượt đua nữa.", "icons/vector_dark/lock.svg")
	await shot("Popup chung", "locked", "Tính năng đang khóa")
	await close_all()
	await drop_main()

	# Tutorial welcome (same setup as tools/preview_tutorial_story.gd)
	state.init_new_game()
	state.active = false
	state.begin_countdown()
	await build_main()
	main._sync_sim()
	main._tutorial.start()
	main._tutorial._enter("A1_welcome")
	for i in 40:
		main._tutorial._process(0.01)
		await process_frame
	await shot("Khởi động", "tutorial_welcome", "Hướng dẫn: lời chào")
	if not main._tutorial._panel.visible:
		push_error("Tutorial panel not visible")
	await drop_main()


func capture_startup() -> void:
	seed_state()
	var splash: Node = load("res://scenes/splash.tscn").instantiate()
	root.add_child(splash)
	await create_timer(0.85).timeout
	await shot("Khởi động", "splash", "Splash")
	splash.free()  # before it switches the scene to loading
	await settle(4)
	var ui := Node.new()
	root.add_child(ui)
	ui.set_script(load("res://ui/loading.gd"))
	ui.set_process(false)
	ui.call("_build_ui")
	ui.set("_shown", 0.6)
	ui.call("_update_bar")
	await shot("Khởi động", "loading", "Loading")
	ui.call("_on_failed", "BOOT_SAVE", "Không thể đọc tiến trình đã lưu. Hãy thử lại.")
	await shot("Khởi động", "loading_error", "Loading lỗi")
	ui.queue_free()
	await settle(4)
