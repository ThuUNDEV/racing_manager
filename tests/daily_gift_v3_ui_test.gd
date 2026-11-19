extends SceneTree
## Runtime demo parity and pointer input with isolated test saves.
## RM_LANG=vi godot --path . -s res://tests/daily_gift_v3_ui_test.gd -- --capture
const PopupAnim = preload("res://ui/popup_anim.gd")
const D0 := 21000
var failures := 0
var main: Control
var gs: Node
var capture_enabled := false
const OUT := "res://output/daily_gift_runtime_v3/"

func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func settle() -> void:
	for i in 12:
		await process_frame
func capture(id: String) -> void:
	if capture_enabled:
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(image.save_png(OUT + id + ".png") == OK, "capture " + id)
		if is_instance_valid(main._daily_popup) and main._overlay.visible:
			var bounds: Rect2 = main._daily_popup.get_global_rect()
			image.get_region(Rect2i(bounds)).save_png(OUT + id + "_popup.png")
func click(button: BaseButton) -> void:
	var pos := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	root.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = pos
		event.global_position = pos
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()
func demo_state() -> void:
	gs.daily_device_unix = float(D0) * 86400 + 3600
	gs.daily_rewards = DailyRewards.unlock(DailyRewards.default_state(), D0 - 2)
	gs.daily_rewards["cycle_day"] = 2
	gs.daily_rewards["total_days"] = 2
	gs.daily_rewards["last_claim_day"] = D0 - 1
	gs.daily_rewards["max_seen_day"] = D0
func assert_layout(width: int) -> void:
	var popup: Control = main._daily_popup
	var bounds := popup.get_global_rect()
	check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(bounds), "%d popup fits: %s root=%s main=%s overlay=%s" % [width,bounds,root.size,main.size,main._overlay.size])
	for label: Label in popup.find_children("*", "Label", true, false):
		check(bounds.encloses(label.get_global_rect()), "%d label fits popup: %s" % [width, label.text])
		check(label.get_minimum_size().x <= label.size.x + .5, "%d text width: %s" % [width, label.text])
		check(int(label.get_meta("ub_font", 99)) >= 9, "%d font stays readable (%d design units): %s" % [width, int(label.get_meta("ub_font", 99)), label.text])
	for i in 7:
		var cell: Control = popup.find_child("DailyCell%d" % (i+1),true,false)
		for label: Label in cell.find_children("*", "Label", true, false):
			check(cell.get_global_rect().encloses(label.get_global_rect()), "%d label fits cell%d: %s" % [width,i+1,label.text])
		var quantity: Control = cell.find_child("RewardQuantity",true,false)
		var badge: Control = cell.find_child("ClaimedBadge",true,false)
		if badge==null:
			badge=cell.find_child("TodayBadge",true,false)
		if badge!=null and quantity!=null:
			check(quantity.get_global_rect().end.y <= badge.global_position.y+.5, "%d reward clears badge day%d: quantity=%s badge=%s"%[width,i+1,quantity.get_global_rect(),badge.get_global_rect()])
	var action: Button = popup.find_child("ClaimDailyReward",true,false)
	var close: TextureButton = popup.find_child("PopupClose",true,false)
	check(action.size.y>=48 and close.size.x>=48 and close.size.y>=48,"48px targets")
	check(action.get_global_rect().position.y >= popup.find_child("MilestoneHint",true,false).get_global_rect().end.y-.5,"action clears milestone hint")
	var sc: ScrollContainer = main._overlay_box.get_parent()
	check(sc.get_v_scroll_bar().max_value <= sc.get_v_scroll_bar().page+1,"all rewards fit without scrolling")
	for state in ["normal","hover","pressed","disabled"]:
		var face=action.get_theme_stylebox(state)
		check(face is StyleBoxTexture and face.texture.resource_path.begins_with("res://assets/daily_gift_v3/"), "v3 action state "+state)
func run() -> void:
	PopupAnim.enabled=false
	capture_enabled="--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(OUT)
	I18n.set_lang("vi")
	GameData.reload()
	gs=root.get_node("GameState")
	check(gs.SAVE_PATH.contains("/tests/"),"test save isolated")
	gs.init_new_game();gs.active=false;gs.set_process(false)
	gs.tutorial["gated"]=false;gs.tutorial["state"]="done"
	gs.completed_races=5
	demo_state()
	root.content_scale_factor=1;root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(390,778)
	main=load("res://ui/main.gd").new()
	root.add_child(main);main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle();main.set_process(false)
	main._select_tab(main.Tab.SHOP)
	for dims in [Vector2i(320,568),Vector2i(390,778),Vector2i(412,915)]:
		root.size=dims;await settle();demo_state()
		main._show_daily_rewards();await settle()
		assert_layout(dims.x)
		var popup: Control=main._daily_popup
		# Each received coupon shows its own ticket (driver helmet / gear wrench, colour by tier); the tier is also data on the node.
		for triple in [[1,"coupon_driver_pro","pro"],[2,"coupon_gear_standard","standard"],[4,"coupon_driver_allstar","allstar"],[5,"coupon_gear_elite","elite"]]:
			var cell=popup.find_child("DailyCell%d"%triple[0],true,false)
			var icon: TextureRect=cell.find_child("RewardIcon",true,false)
			check(icon.texture.resource_path.ends_with("/%s.png"%triple[1]) and icon.get_meta("tier")==triple[2],"ticket icon/tier %s"%triple[2])
		check((popup.find_child("GrandGift",true,false) as TextureRect).texture.resource_path.ends_with("/gift.png"),"day 7 uses the red gift box")
		check(popup.find_child("HeaderChecker",true,false)!=null,"header checker accent")
		var badge_today: Control=popup.find_child("TodayBadge",true,false)
		var today_cell: Control=popup.find_child("DailyCell3",true,false)
		check(badge_today.get_global_rect().position.x>today_cell.get_global_rect().position.x+6 and badge_today.get_global_rect().end.y<today_cell.get_global_rect().end.y-3,"today badge is an inset pill inside its card")
		var claimed_icon: TextureRect=popup.find_child("DailyCell1",true,false).find_child("RewardIcon",true,false)
		check(claimed_icon.self_modulate.a>=0.7,"claimed card icon stays readable")
		var marker: TextureRect=popup.find_child("MilestoneNode10",true,false)
		check(marker.texture.resource_path.ends_with("/milestone_empty.png"),"2/10 days must not mark day10 claimed")
		await capture("demo_%d"%dims.x)
		var action: Button=popup.find_child("ClaimDailyReward",true,false)
		var gems_before: int=gs.gems
		await click(action)
		check(gs.gems==gems_before+15 and gs.daily_rewards.total_days==3,"real pointer claim grants day3 once")
		action=popup.find_child("ClaimDailyReward",true,false)
		check(action.disabled and action.text.begins_with("Mở lại sau"),"countdown after claim")
		await click(action)
		check(gs.gems==gems_before+15,"disabled claim never duplicates reward")
		await capture("claimed_%d"%dims.x)
		var close: TextureButton=popup.find_child("PopupClose",true,false)
		await click(close)
		check(not main._overlay.visible,"real pointer close dismisses popup")
	# Watch-first x2: one video, then the day is claimed with doubled gems in a single save.
	root.size=Vector2i(390,778);await settle()
	demo_state();main._show_daily_rewards();await settle()
	var x2: Button=main._daily_popup.find_child("ClaimDailyRewardX2",true,false)
	check(x2!=null and not x2.disabled and x2.size.y>=48,"x2 button offered on a gem day")
	var gems_x2: int=gs.gems
	await click(x2)
	await create_timer(1.6).timeout;await settle()
	check(gs.gems==gems_x2+30 and gs.daily_rewards.total_days==3 and bool(gs.last_daily_reward["x2"]),"x2 grants doubled gems once")
	check(main._daily_popup.find_child("ClaimDailyRewardX2",true,false)==null,"x2 button gone after claim")
	demo_state();gs.daily_rewards["cycle_day"]=0;gs.daily_rewards["total_days"]=0
	main._daily_popup.refresh();await settle()
	check(main._daily_popup.find_child("ClaimDailyRewardX2",true,false)==null,"no x2 offer on a ticket-only day")
	main._close_overlay();await settle()
	# Grand can contain one, two or three reward types; keep every caption inside the card.
	root.size=Vector2i(320,568);await settle()
	for ordinal in 7:
		demo_state();gs.daily_rewards["cycle_day"]=6;gs.daily_rewards["grand_ordinal"]=ordinal
		gs.daily_rewards["total_days"]=48;gs.daily_rewards["claimed_milestones"]=4
		main._show_daily_rewards();await settle();assert_layout(320)
		if ordinal==6:await capture("grand_mixed_320")
	# Localized text keeps the same tier icon selection, and the native countdown stays readable.
	for language in ["en","id","ms","th","ja","ko","zh_Hans"]:
		I18n.set_lang(language);demo_state()
		main._show_daily_rewards();await settle();assert_layout(320)
		var icon: TextureRect=main._daily_popup.find_child("DailyCell4",true,false).find_child("RewardIcon",true,false)
		check(icon.texture.resource_path.ends_with("/coupon_driver_allstar.png") and icon.get_meta("tier")=="allstar","tier independent of language "+language)
		if language=="en":await capture("demo_en_320")
	I18n.set_lang("vi")
	demo_state();main._show_daily_rewards();await settle()
	gs.save_blocked=true
	main._daily_popup.refresh();await settle()
	var blocked: Button=main._daily_popup.find_child("ClaimDailyReward",true,false)
	check(blocked.disabled and blocked.text==I18n.t("common.saving"),"save blocked disables claim without false countdown")
	await capture("save_blocked_320")
	gs.save_blocked=false
	main._daily_popup.refresh();await settle()
	check(not (main._daily_popup.find_child("ClaimDailyReward",true,false) as Button).disabled,"save recovery restores claim")
	# Shared overlay gutters must be restored for the next popup.
	main._show_settings();await settle()
	var margin: MarginContainer=main._overlay_box.get_parent().get_parent().get_parent().get_parent()
	check(margin.get_theme_constant("margin_top")==40 and margin.get_theme_constant("margin_left")==16,"daily gutters do not leak into next popup")
	main.queue_free();await settle()
	print("DAILY_GIFT_V3_UI_TEST failures=",failures)
	quit(1 if failures else 0)
