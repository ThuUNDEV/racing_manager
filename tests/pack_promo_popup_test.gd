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
		DirAccess.make_dir_recursive_absolute("res://Design/Previews/pack_promo_popup")
		root.get_texture().get_image().save_png("res://Design/Previews/pack_promo_popup/" + id + ".png")

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

	for dimensions: Vector2i in [Vector2i(320, 568), Vector2i(390, 778), Vector2i(412, 915)]:
		root.size = dimensions
		main._select_tab(0)
		await settle()
		for sku in ["starter_1", "weekly_s", "offer_noads_bundle", "income_x2", "char_my"]:
			var product := GameData.iap_product(sku)
			main._show_iap_detail(sku)
			await settle()
			var tag := "%s@%d" % [sku, dimensions.x]
			var header: Control = main.find_child("PromoHeader", true, false)
			check(header != null, "có header ruy-băng: " + tag)
			var close: Control = main.find_child("PromoClose", true, false)
			check(close != null and close.size.x >= 48.0 and close.size.y >= 48.0, "nút đóng >= 48x48: " + tag)
			var promo_art := String(main._shop_content.PromoUi.art_file(sku, product)) != ""
			check((main.find_child("PromoHeroClip", true, false) != null) == promo_art, "hero mới đúng SKU: " + tag)
			if product.has("value_x"):
				var badge: Control = main.find_child("PromoBadge", true, false)
				check(badge != null, "huy hiệu giá trị: " + tag)
				var shown := ("%.1f" % float(product["value_x"])).replace(".", I18n.dec()) + "x"
				var found := false
				for l in badge.find_children("*", "Label", true, false):
					found = found or (l as Label).text == shown
				check(found, "huy hiệu ghi %s: %s" % [shown, tag])
			var cards: Array = []
			var rewards_box: Node = main.find_child("PromoRewards", true, false)
			if rewards_box != null:
				for line in rewards_box.get_children():
					cards.append_array(line.get_children())
			if sku != "income_x2":
				check(cards.size() == PackUi.rewards(product).size(), "đủ thẻ thưởng (%d): %s" % [PackUi.rewards(product).size(), tag])
			var buy: Button = main.find_child("DetailBuy_" + sku, true, false)
			check(buy != null and buy.size.y >= 44.0 and buy.is_visible_in_tree(), "nút mua hiện >= 44: " + tag)
			var panel: Control = main._overlay_panel()
			check(Rect2(Vector2.ZERO, Vector2(dimensions)).grow(1.0).encloses(panel.get_global_rect()), "panel nằm trong màn hình: %s %s" % [tag, panel.get_global_rect()])
			for card in cards:
				var cr := (card as Control).get_global_rect()
				var pr := panel.get_global_rect()
				check(cr.position.x >= pr.position.x - 1.0 and cr.end.x <= pr.end.x + 1.0, "thẻ thưởng không tràn ngang: %s card=%s panel=%s" % [tag, cr, pr])
				check(cr.size.y <= 110.0, "thẻ thưởng không quá cao (%s): %s" % [cr.size.y, tag])
			if sku in ["starter_1", "offer_noads_bundle"] or dimensions.x == 320:
				await capture("%s_%d" % [sku, dimensions.x])
			main._close_overlay()
			await settle()
	print("PACK_PROMO_POPUP_TEST failures=", failures)
	quit(1 if failures > 0 else 0)
