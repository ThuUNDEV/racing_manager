extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for i in 12:
		await process_frame

func run() -> void:
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.tutorial["gated"] = false
	I18n.set_lang("en")
	var provider := MockAdsProvider.new()
	provider.tree = self
	provider.online = true
	provider.ready = true
	provider.outcome = "rewarded"
	provider.delay_sec = 0.0
	root.get_node("Ads").provider = provider
	root.size = Vector2i(390, 844)
	var main := load("res://ui/main.gd").new() as Control
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._select_tab(main.Tab.SHOP)
	await settle()
	var shop: Control = main._shop_content
	var button: Button = shop._daily_button
	check(shop.get_node("FreeGrid").get_child_count() == 3, "Only gem, gear and driver cards remain")
	check(shop.find_child("FreeGemBanner", true, false) == null, "Separate gem banner removed")
	check(button.icon == null and not button.disabled, "First claim is available without a video icon")
	var before: int = state.gems
	var free_amount := int(GameData.economy()["rewards"]["daily_gems"])
	button.pressed.emit()
	await settle()
	check(state.gems == before + free_amount and not state.daily_available(), "First click grants daily reward once")
	check(button.icon != null and not button.disabled and button.text == I18n.t("shop.watch_video").trim_prefix("▶ "), "Same button switches to video immediately")
	var ad_amount := int(GameData.ads()["placements"]["free_gems"]["amount"])
	button.pressed.emit()
	await settle()
	check(state.gems == before + free_amount + ad_amount, "Second click grants rewarded-ad gems")
	check(button.disabled, "Cooldown is enforced after video reward")
	# Changing only the daily availability must refresh the shared button even
	# when Main's ads-view hash has not changed.
	state.last_daily_day -= 1
	main._rebuild_shop()
	check(button.icon == null and not button.disabled, "Next day returns to a free claim despite ad cooldown")
	state.save_blocked = true
	main._rebuild_shop()
	check(button.disabled and button.icon == null, "Save errors block the free claim")
	state.save_blocked = false
	main._rebuild_shop()
	button.pressed.emit()
	await settle()
	check(button.disabled and button.icon != null, "After free claim, existing ad cooldown remains")
	var reloaded := load("res://ui/shop_page.gd").new() as Control
	var wrapper := VBoxContainer.new()
	var scroll := ScrollContainer.new()
	root.add_child(scroll)
	scroll.add_child(wrapper)
	wrapper.add_child(reloaded)
	await settle()
	reloaded.update_daily("", free_amount, state.daily_available(), false)
	reloaded.update_ads(main._ads_view())
	check(reloaded._daily_button.disabled and reloaded._daily_button.icon != null, "Reopening shop preserves video stage and cooldown")
	scroll.queue_free()
	main.queue_free()
	await settle()
	print("SHOP_MERGED_GIFT_TEST failures=", failures)
	quit(1 if failures else 0)
