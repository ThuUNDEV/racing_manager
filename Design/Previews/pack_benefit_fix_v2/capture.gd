extends SceneTree
const PopupAnim = preload("res://ui/popup_anim.gd")
const SKUS = ["starter_1", "weekly_s", "offer_noads_bundle", "income_x2", "no_ads", "char_my"]
const OUT = "res://Design/Previews/pack_benefit_fix_v2/"
var main: Control
var evidence: Array = []
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for i in 16:
		await process_frame
func rect(control: Control) -> Array:
	var r := control.get_global_rect()
	return [r.position.x, r.position.y, r.size.x, r.size.y]
func sample(sku: String, language: String, dimensions: Vector2i, shot: bool) -> void:
	root.size = dimensions
	I18n.set_lang(language)
	main._show_iap_detail(sku)
	await settle()
	var panel: Control = main._overlay_panel()
	var info: Dictionary = {"sku": sku, "lang": language, "viewport": [dimensions.x, dimensions.y], "panel": rect(panel), "controls": {}, "text": [], "interactions": {}}
	for name in ["PromoHeader", "PromoTitle", "PromoPrimary", "OfferArt_" + sku, "PromoPrimaryValue", "PromoPrimaryGem", "PromoBadge", "PermanentChip", "PromoRewards", "PromoRewardsHeading", "PromoRewardRows", "PromoNote", "DetailBuy_" + sku, "PromoClose", "PromoRates"]:
		var control := panel.find_child(name, true, false) as Control
		if control != null:
			info["controls"][name] = {"rect": rect(control), "minimum": [control.get_combined_minimum_size().x, control.get_combined_minimum_size().y]}
	for text: Label in panel.find_children("*", "Label", true, false):
		if text.is_visible_in_tree():
			info["text"].append({"name": str(text.name), "text": text.text, "rect": rect(text), "font_size": text.get_theme_font_size("font_size"), "lines": text.get_line_count(), "visible_lines": text.get_visible_line_count()})
	var buy := panel.find_child("DetailBuy_" + sku, true, false) as Button
	info["buy"] = {"rect": rect(buy), "font_size": buy.get_theme_font_size("font_size"), "disabled": buy.disabled, "text": buy.text}
	if shot:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "%s_%s_%dx%d.png" % [sku, language, dimensions.x, dimensions.y])
	var scroll := main._overlay_box.get_parent() as ScrollContainer
	info["scroll"] = {"viewport": rect(scroll), "content_min_height": main._overlay_box.get_combined_minimum_size().y, "max_value": scroll.get_v_scroll_bar().max_value, "page": scroll.get_v_scroll_bar().page}
	if dimensions.y == 568:
		scroll.scroll_vertical = 10000
		await settle()
		var close := panel.find_child("PromoClose", true, false) as Control
		info["interactions"]["short_close_after_scroll"] = rect(close)
		info["interactions"]["short_buy_after_scroll"] = rect(buy)
		if shot:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT + "%s_short_scrolled.png" % sku)
	evidence.append(info)
	main._close_overlay()
	await settle()
func run() -> void:
	PopupAnim.enabled = false
	var state := root.get_node("GameState")
	if not state.SAVE_PATH.contains("/tests/"):
		push_error("Review requires isolated save")
		quit(1)
		return
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.set_process(false)
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.business_tier = 3
	state.unlocked_tier = 3
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 845)
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main._select_tab(4)
	await settle()
	main.set_process(false)
	# Presentation fixture: match the approved demo's ready-to-purchase state.
	# Eligibility/grants in GameState and Iap are untouched; no purchase is invoked.
	for sku in SKUS:
		main._shop_content._last_iap_view["items"][sku]["reason"] = ""
		main._shop_content._last_iap_view["items"][sku]["driver_owned"] = false
		main._shop_content._last_iap_view["items"][sku]["price"] = GameData.iap_product(sku)["price_fallback"]
	main._shop_content._last_iap_view["busy"] = false
	if "--native" in OS.get_cmdline_user_args():
		root.content_scale_factor = 2.2718
		await sample("starter_1", "vi", Vector2i(886, 1920), true)
		var native_file := FileAccess.open(OUT + "native_measurements.json", FileAccess.WRITE)
		native_file.store_string(JSON.stringify(evidence, "\t"))
		main.queue_free()
		await settle()
		print("PACK_NATIVE_REVIEW done")
		quit()
		return
	for dims: Vector2i in [Vector2i(390, 845), Vector2i(320, 694), Vector2i(412, 893)]:
		for sku in SKUS:
			await sample(sku, "vi", dims, true)
	for language in ([] if "--quick" in OS.get_cmdline_user_args() else ["en", "vi", "id", "ms", "th", "ja", "ko", "zh_Hans"]):
		for sku in SKUS:
			await sample(sku, language, Vector2i(320, 694), false)
	await sample("starter_3", "vi", Vector2i(320, 568), true)
	var file := FileAccess.open(OUT + "measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence, "\t"))
	main.queue_free()
	await settle()
	print("PACK_BENEFIT_REVIEW samples=", evidence.size())
	quit()
