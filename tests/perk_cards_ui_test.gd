extends SceneTree
## --capture uses a native renderer. All saves are isolated by XDG_DATA_HOME.
const PerkCard = preload("res://ui/shop_perk_card.gd")
var failures := 0
var clicks: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)

func settle() -> void:
	for i in 12: await process_frame

func view() -> Dictionary:
	var iap := root.get_node("Iap")
	var items := {}
	for p: Dictionary in GameData.iap_products():
		var sku := String(p["sku"])
		items[sku] = {"price": iap.price(sku), "reason": iap.block_reason(sku)}
	return {"items": items, "busy": false}

func run() -> void:
	RenderingServer.set_default_clear_color(Color("f4e7d8"))
	var state := root.get_node("GameState")
	GameData.reload()
	state.init_new_game()
	state.active = false
	state.set_process(false)
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	for lang: String in I18n.codes():
		I18n.set_lang(lang)
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 12)
		root.add_child(margin)
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		margin.add_child(scroll)
		var cards := VBoxContainer.new()
		cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards.add_theme_constant_override("separation", 10)
		scroll.add_child(cards)
		for sku: String in PerkCard.SKUS:
			var card := PerkCard.new()
			cards.add_child(card)
			card.setup(GameData.iap_product(sku))
			card.buy_pressed.connect(func() -> void: clicks.append(sku))
		for width: int in [320, 390, 412]:
			root.size = Vector2i(width, 845)
			await settle()
			for card in cards.get_children():
				var bounds: Rect2 = card.get_global_rect()
				var tag: String = "%s %s %d" % [card.sku, lang, width]
				check(bounds.position.x >= 11 and bounds.end.x <= width - 11, "lề và chiều rộng: " + tag)
				check(card.size.y >= 150 and card.size.y <= 228, "chiều cao 150–228: " + tag + " " + str(card.size))
				check(card.price.size.y >= 44 and card.price.size.x >= 44, "vùng chạm: " + tag)
				for child: Control in [card.title, card.benefit, card.price, card.permanent]:
					check(bounds.grow(1).encloses(child.get_global_rect()), "nội dung trong thẻ: " + tag + " " + child.name)
					if child is Label:
						check(child.get_line_count() == child.get_visible_line_count(), "đủ dòng chữ: " + tag + " " + child.text)
				check(card.benefit.get_global_rect().end.y <= card.price.global_position.y, "lợi ích không chồng CTA: " + tag)
				check(card.title.get_global_rect().end.y <= card.benefit.global_position.y, "title không chồng lợi ích: " + tag)
				check(not card._hero.get_global_rect().intersects(card.benefit.get_global_rect()), "hero không che lợi ích: " + tag)
			if "--capture" in OS.get_cmdline_user_args() and lang in ["en", "vi", "id"]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://Design/Previews/perk_cards/%s_%d.png" % [lang, width])
		margin.queue_free()
		await settle()
	I18n.set_lang("en")
	var margin := MarginContainer.new()
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := ScrollContainer.new()
	margin.add_child(scroll)
	var wrapper := VBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(wrapper)
	var shop := load("res://ui/shop_page.gd").new() as VBoxContainer
	wrapper.add_child(shop)
	await settle()
	shop.iap_requested.connect(func(sku: String) -> void: clicks.append(sku))
	state.iap["owned"] = []
	shop.update_iap(view())
	check(shop._offer_cards["income_x2"].visible, "chưa mua hiện ×2")
	shop._iap_buttons["income_x2"]["button"].pressed.emit()
	check(clicks.has("income_x2"), "CTA phát đúng SKU cho luồng IAP")
	state.iap["owned"] = ["income_x2"]
	shop.update_iap(view())
	check(shop._iap_buttons["income_x2"]["button"].disabled, "không mua lại quyền đã có")
	var data := view()
	data["busy"] = true
	shop.update_iap(data)
	check(shop._iap_buttons["income_x2"]["button"].disabled, "đang xử lý khóa CTA")
	data["busy"] = false
	data["items"]["income_x2"] = {"reason": "", "price": "Rp 1.234.567,00"}
	shop.update_iap(data)
	await settle()
	check(shop._iap_buttons["income_x2"]["button"].text == "Rp 1.234.567,00", "hiện nguyên giá store bản địa")
	check(not shop._iap_buttons["income_x2"]["button"].disabled, "khôi phục CTA sau xử lý")
	var localized_price: Button = shop._iap_buttons["income_x2"]["button"]
	check(localized_price.get_theme_font("font").get_string_size(localized_price.text, HORIZONTAL_ALIGNMENT_LEFT, -1, localized_price.get_theme_font_size("font_size")).x <= localized_price.size.x - 20, "giá bản địa dài không bị cắt")
	margin.queue_free()
	await settle()
	if "--capture" in OS.get_cmdline_user_args():
		state.init_new_game()
		state.active = false
		state.tutorial["gated"] = false
		root.size = Vector2i(390, 845)
		var main := load("res://ui/main.gd").new() as Control
		root.add_child(main)
		main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await settle()
		main.set_process(false)
		main._select_tab(main.Tab.SHOP)
		await settle()
		var live_shop: Control = main._shop_content
		var live_scroll: ScrollContainer = main._shop_box.get_parent()
		for sku: String in ["income_x2"]:
			live_scroll.ensure_control_visible(live_shop._offer_cards[sku])
			await settle()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Design/Previews/perk_cards/shop_%s_390.png" % sku)
		main.queue_free()
		await settle()
	print("PERK_CARDS_UI_TEST failures=", failures)
	quit(1 if failures else 0)
