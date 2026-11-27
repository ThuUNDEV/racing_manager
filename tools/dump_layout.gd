extends SceneTree
## Dump the visible Control tree (logical rects) of each screen to output/layout/<id>.txt.
## Source of the numbers in Design/34_Layer_Layout_Spec.md.
## XDG_DATA_HOME=$(mktemp -d) RM_LANG=vi godot --headless --path . -s res://tools/dump_layout.gd

const BigNumber = preload("res://core/math/big_number.gd")
const PopupAnim = preload("res://ui/popup_anim.gd")
const OUT := "res://output/layout"
const SIBLING_LIMIT := 4

var state: Node
var main: Control


func _initialize() -> void:
	call_deferred("run")


func settle() -> void:
	for i in 20:
		await process_frame


func dump(id: String, from: Node = null) -> void:
	await settle()
	var lines: PackedStringArray = []
	walk(from if from != null else main, 0, lines)
	var file := FileAccess.open("%s/%s.txt" % [OUT, id], FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("DUMP ", id, " ", lines.size())


func walk(node: Node, depth: int, lines: PackedStringArray) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is CanvasLayer and not (node as CanvasLayer).visible:
		return
	var script: Script = node.get_script()
	var kind := node.get_class()
	if script != null:
		kind = script.get_global_name() if script.get_global_name() != &"" else script.resource_path.get_file()
	var named := not String(node.name).begins_with("@")
	var shown := named or node is Label or node is BaseButton or node is ScrollContainer or node is PanelContainer or script != null
	if node is Control and shown:
		var r: Rect2 = node.get_global_rect()
		var text := ""
		if node is Label or node is Button:
			text = String(node.text).replace("\n", " ").left(40)
		lines.append("%s%s [%s] %d,%d %dx%d%s" % ["  ".repeat(depth), node.name if named else "-", kind,
			roundi(r.position.x), roundi(r.position.y), roundi(r.size.x), roundi(r.size.y),
			(" \"%s\"" % text) if text != "" else ""])
		depth += 1
	var seen := {}
	for child in node.get_children():
		# Long grids and lists: keep the first few of each kind.
		var key := "%s/%s" % [child.get_class(), String(child.name).rstrip("0123456789@_")]
		seen[key] = int(seen.get(key, 0)) + 1
		if String(child.name).begins_with("@") and int(seen[key]) > SIBLING_LIMIT:
			continue
		walk(child, depth, lines)


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


func close_all() -> void:
	main._overlay.hide()
	main._promotion.hide()
	main._class_page.hide()
	await settle()


func run() -> void:
	PopupAnim.enabled = false
	state = root.get_node("GameState")
	assert(OS.get_user_data_dir().begins_with("/tmp"), "run with an isolated XDG_DATA_HOME")
	GameData.reload()
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 845)
	DirAccess.make_dir_recursive_absolute(OUT)
	seed_state()
	await build_main()

	state.begin_countdown()
	state._start_race()
	state.active = false
	main._select_tab(main.Tab.RACE)
	main._sync_sim()
	main._update_race_ui()
	await dump("race")
	main._show_race_result({"position": 1, "money": BigNumber.from_int(5400), "trophies": 1, "points": 120, "unlocked": []})
	await dump("race_result", main._result_panel)
	main._result_panel.hide()

	main._select_tab(main.Tab.BAG)
	await dump("gear")
	main._select_tab(main.Tab.TEAM)
	main._select_team_sub(0)
	await dump("drivers")
	main._roster._open_sheet(state.active_driver_id)
	await dump("driver_sheet", main._roster.sheet)
	main._roster.close_sheet()
	main._select_team_sub(1)
	for section in 3:
		main._garage.debug_show(str(section))
		await dump("garage_%d" % section)
	main._select_tab(main.Tab.LEAGUE)
	await dump("leagues")
	main._select_tab(main.Tab.SHOP)
	await dump("shop")

	main._show_iap_detail("starter_1")
	await dump("popup_iap_starter", main._overlay)
	await close_all()
	main._select_tab(main.Tab.RACE)
	main._show_settings()
	await dump("popup_settings", main._overlay)
	main._show_language_picker()
	await dump("popup_language", main._overlay)
	main._show_trophy_rules()
	await dump("popup_trophy_rules", main._overlay)
	main._show_gear_info("standard")
	await dump("popup_rates", main._overlay)
	main._show_feedback("Garage", "...", "icons/vector_dark/lock.svg")
	await dump("popup_feedback", main._overlay)
	await close_all()
	state.offline_report = {"elapsed": 5400.0, "eligible": 5400.0, "rate": 8.0, "ratio": 0.5, "reward": BigNumber.from_int(28800), "capped": false}
	main._show_offline()
	await dump("popup_offline", main._overlay)
	await close_all()
	state.offline_report = {}
	main._show_promotion()
	await dump("popup_promotion", main._promotion)
	await close_all()
	main._show_classes()
	await dump("popup_classes", main._class_page)
	await close_all()
	main._ads_controls._open("income_boost")
	await dump("popup_ad_boost")
	quit(0)
