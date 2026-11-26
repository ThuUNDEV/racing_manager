extends SceneTree
## Popup quảng cáo pack kiểu Soft Miniature: header, hero, huy hiệu giá trị, thẻ thưởng, nút mua. --capture ghi ảnh.
const BigNumber = preload("res://core/math/big_number.gd")
const PopupAnim = preload("res://ui/popup_anim.gd")
const PackUi = preload("res://ui/shop_pack_ui.gd")
var failures := 0
var main: Control

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)

func settle() -> void:
	for i in 14:
		await process_frame

func capture(id: String) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://Design/Previews/pack_benefit_popup")
		root.get_texture().get_image().save_png("res://Design/Previews/pack_benefit_popup/" + id + ".png")
		var layout: Dictionary = {}
		for node_name in ["PromoHeader", "PromoPrimary", "PromoRewards", "PromoRewardsHeading", "PromoPrimaryValue", "PromoNote"]:
			var control := main._overlay_panel().find_child(node_name, true, false) as Control
			if control != null:
				var rect := control.get_global_rect()
				layout[node_name] = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
		var file := FileAccess.open("res://Design/Previews/pack_benefit_popup/" + id + "_layout.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(layout, "\t"))

func run() -> void:
	PopupAnim.enabled = false
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tests/pack_promo_popup.json"
	state.BAK_PATH = "user://tests/pack_promo_popup.bak"
	state.TMP_PATH = "user://tests/pack_promo_popup.tmp"
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.set_process(false)
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.coins = BigNumber.from_int(12500)
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	main = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)

	for dimensions: Vector2i in [Vector2i(320, 694), Vector2i(390, 778), Vector2i(412, 915)]:
		root.size = dimensions
		main._select_tab(0)
		await settle()
		for sku in ["starter_1", "weekly_s", "offer_noads_bundle", "income_x2", "no_ads", "char_my"]:
			var product := GameData.iap_product(sku)
			main._show_iap_detail(sku)
			await settle()
			var tag := "%s@%d" % [sku, dimensions.x]
			var header: Control = main.find_child("PromoHeader", true, false)
			check(header != null, "có tiêu đề navy: " + tag)
			var close: Control = main.find_child("PromoClose", true, false)
			check(close != null and close.size.x >= 48.0 and close.size.y >= 48.0, "nút đóng >= 48x48: " + tag)
			check(main.find_child("PromoPrimary", true, false) != null, "có quyền lợi chính: " + tag)
			check(main._overlay_panel().find_child("PromoRibbon", true, false) == null, "tiêu đề trơn theo concept: " + tag)
			if product.has("value_x"):
				var badge: Control = main.find_child("PromoBadge", true, false)
				check(badge != null, "huy hiệu giá trị: " + tag)
				check(main._overlay_panel().get_global_rect().encloses(badge.get_global_rect()), "huy hiệu không bị cắt: " + tag)
				var shown := ("%.1f" % float(product["value_x"])).replace(".", I18n.dec()) + "x"
				var found := false
				for l in badge.find_children("*", "Label", true, false):
					found = found or (l as Label).text == shown
				check(found, "huy hiệu ghi %s: %s" % [shown, tag])
			var cards: Array = main.find_children("PromoRewardRow*", "HBoxContainer", true, false)
			var parts: Dictionary = main._shop_content.BenefitUi.split_rewards(product)
			check(cards.size() == parts["gifts"].size(), "quà kèm không thiếu hoặc lặp quyền lợi chính: " + tag)
			if sku == "income_x2":
				check(cards.size() == 2, "income_x2 có online + thưởng đua: " + tag)
				check(main.find_child("PermanentChip", true, false) != null, "income_x2 có nhãn vĩnh viễn: " + tag)
			var buy: Button = main.find_child("DetailBuy_" + sku, true, false)
			check(buy != null and buy.size.y >= 44.0 and buy.is_visible_in_tree(), "nút mua hiện >= 44: " + tag)
			var panel: Control = main._overlay_panel()
			check(Rect2(Vector2.ZERO, Vector2(dimensions)).grow(1.0).encloses(panel.get_global_rect()), "panel nằm trong màn hình: %s %s" % [tag, panel.get_global_rect()])
			for card in cards:
				var cr := (card as Control).get_global_rect()
				var pr := panel.get_global_rect()
				check(cr.position.x >= pr.position.x - 1.0 and cr.end.x <= pr.end.x + 1.0, "thẻ thưởng không tràn ngang: %s card=%s panel=%s" % [tag, cr, pr])
				check(cr.size.y <= 132.0, "thẻ thưởng không quá cao (%s): %s" % [cr.size.y, tag])
			if "--capture" in OS.get_cmdline_user_args():
				await capture("%s_%d" % [sku, dimensions.x])
			for down in [true, false]:
				var click := InputEventMouseButton.new()
				click.button_index = MOUSE_BUTTON_LEFT
				click.pressed = down
				click.position = close.get_global_rect().get_center()
				click.global_position = click.position
				root.push_input(click, true)
				await process_frame
			await settle()
			check(not main._overlay.visible, "nút X đóng popup thật: " + tag)
	# The docked X stays inside the visible panel even after the content is scrolled.
	root.size = Vector2i(320, 568)
	main._show_iap_detail("starter_3")
	await settle()
	var scroll: ScrollContainer = main._overlay_box.get_parent()
	check(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "fixture màn thấp thực sự cần cuộn")
	scroll.scroll_vertical = 10000
	await settle()
	var pinned_close: Control = main._overlay_panel().find_child("PromoClose", true, false)
	check(main._overlay_panel().get_global_rect().encloses(pinned_close.get_global_rect()), "X vẫn trong popup khi cuộn màn thấp")
	check(pinned_close.get_global_rect().end.y <= scroll.get_global_rect().position.y, "header nằm ngoài vùng cuộn")
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = pinned_close.get_global_rect().get_center()
		click.global_position = click.position
		root.push_input(click, true)
		await process_frame
	await settle()
	check(not main._overlay.visible, "X đóng được sau khi cuộn hết")
	root.size = Vector2i(390, 845)
	main._show_iap_detail("starter_1")
	await settle()
	var odds: BaseButton = main._overlay_panel().find_child("PromoRates", true, false)
	check(odds != null and odds.size.y >= 44, "liên kết tỉ lệ có vùng chạm đủ lớn")
	odds.pressed.emit()
	await settle()
	check(main._overlay.visible and main._overlay_panel().find_child("DetailBuy_starter_1", true, false) == null, "liên kết mở nội dung tỉ lệ")
	main._close_overlay()
	await settle()
	for product: Dictionary in GameData.iap().get("products", []):
		for owned in [false, true]:
			var parts: Dictionary = main._shop_content.BenefitUi.split_rewards(product, owned)
			if not parts["income"]:
				var displayed: Array = [parts["primary"]] + parts["gifts"]
				check(displayed == PackUi.rewards(product, owned), "bảo toàn mọi grant: " + String(product["sku"]))
	# Localized layouts must keep native text within the card at phone width.
	root.size = Vector2i(320, 694)
	for lang in ["en", "vi", "id", "ms", "th", "ja", "ko", "zh_Hans"]:
		I18n.set_lang(lang)
		for sku in ["starter_1", "weekly_s", "offer_noads_bundle", "income_x2", "no_ads", "char_my"]:
			main._show_iap_detail(sku)
			await settle()
			var panel: Control = main._overlay_panel()
			for text: Label in panel.find_children("*", "Label", true, false):
				if not text.is_visible_in_tree():
					continue
				check(text.get_global_rect().position.x >= panel.get_global_rect().position.x and text.get_global_rect().end.x <= panel.get_global_rect().end.x, "chữ không tràn ngang %s/%s: %s" % [lang, sku, text.text])
			main._close_overlay()
			await settle()
	I18n.set_lang("vi")
	# Buying remains a single signal; state updates keep the original price/busy/lock behavior.
	var shop = main._shop_content
	shop.iap_requested.disconnect(main._buy_iap)
	shop._last_iap_view = {"busy": false, "items": {"starter_1": {"reason": "", "price": "$0.99"}}}
	var detail: Control = shop.build_detail("starter_1")
	root.add_child(detail)
	var requests: Array = []
	shop.iap_requested.connect(func(sku: String) -> void: requests.append(sku))
	shop._detail_buy.pressed.emit()
	check(requests == ["starter_1"], "mua gửi đúng một yêu cầu SKU")
	shop._last_iap_view["busy"] = true
	shop._refresh_detail()
	check(shop._detail_buy.disabled and shop._detail_buy.text == I18n.t("shop.processing"), "khóa nút khi đang xử lý")
	shop._last_iap_view["busy"] = false
	shop._last_iap_view["items"]["starter_1"]["reason"] = "once"
	shop._refresh_detail()
	check(shop._detail_buy.disabled, "gói đã mua vẫn bị khóa")
	detail.queue_free()
	main.queue_free()
	await settle()
	print("PACK_PROMO_POPUP_TEST failures=", failures)
	quit(1 if failures > 0 else 0)
