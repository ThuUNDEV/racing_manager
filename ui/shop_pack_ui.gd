extends RefCounted
const CleanArt = preload("res://ui/clean_modern_art.gd")
const RewardItems = preload("res://core/data/reward_items.gd")
## Presentation helpers only. Prices, eligibility and grants remain owned by the IAP service.
const IapSkin = preload("res://assets/iap_offers/iap_skin.gd")
const INK := Color("23394a")
const MUTED := Color("768ca0")
static var _manifest: Dictionary = {}
static var _manifest_rev := -1


static func recipe(sku: String) -> Dictionary:
	if _manifest.is_empty() or _manifest_rev != I18n.revision:
		_manifest_rev = I18n.revision
		_manifest = I18n.translate_tree(JSON.parse_string(FileAccess.get_file_as_string("res://assets/iap_offers/manifest.json")))
	return (_manifest.get("recipes", {}) as Dictionary).get(sku, {})


static func label(value: String, font_size: int = 13, color: Color = INK) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node


static func title(product: Dictionary) -> String:
	match String(product.get("kind", "")):
		"limited":
			return I18n.t("shop.limited_pack")
		"chooseone":
			var tier_keys := {"s": I18n.t("drivers.tier_pro"), "m": I18n.t("drivers.tier_elite"), "l": I18n.t("drivers.tier_legend")}
			var size := String(product.get("size", ""))
			return I18n.t("shop.choose_all_title") if size == "all" else I18n.t("shop.tier_shards_title") % String(tier_keys.get(size, ""))
		"epic_car":
			return String(GameData.car(String(product["grant"]["car"])).get("name", product["sku"]))
		"epic_paint":
			return String(GameData.paint(String(product["grant"]["paint"])).get("name", product["sku"]))
		"chain":
			return I18n.t("shop.chain_driver") if String(product.get("chain_id", "")) == "driver" else I18n.t("shop.chain_gear")
	return String(recipe(String(product["sku"])).get("title", product["sku"]))


static func limit(product: Dictionary) -> String:
	if bool(product.get("once", false)):
		return I18n.t("shop.buy_once")
	match String(product.get("kind", "")):
		"weekly": return I18n.t("shop.1_time_week")
		"daily": return I18n.t("shop.1_time_day")
		"pass_month": return I18n.tn("shop.days", int(product.get("days", 30))) % int(product.get("days", 30))
		"perk": return I18n.t("shop.permanent")
		"pass_growth": return I18n.t("shop.buy_once")
		"limited", "chooseone": return I18n.t("shop.limit_once") if int(product.get("week_cap", 1)) == 1 else ""
	return ""


static func panel(sku: String = "") -> StyleBoxFlat:
	var id := String(recipe(sku).get("panel", "panel_blue"))
	var style := StyleBoxFlat.new()
	style.bg_color = HdUi.C_PANEL
	style.border_color = HdUi.C_LINE
	if "purple" in id:
		style.border_color = Color("9a52dc")
	elif "gold" in id:
		style.border_color = Color("e4a62d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(10)
	style.shadow_color = Color("adc9de80")
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	return style


static func buy_style(state: String = "normal") -> StyleBoxTexture:
	return HdUi.button("upgrade", state)


static func button(node: Button, secondary: bool = false) -> void:
	node.clip_text = true
	if secondary:
		HdUi.style_button(node, "cancel")
		return
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		node.add_theme_stylebox_override(state, buy_style(state))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		node.add_theme_color_override(state, Color.WHITE)
	node.add_theme_color_override("font_disabled_color", Color("50697f"))
	HdUi.text_depth(node, true)
	HdUi.ButtonSkin.apply(node)


static func art(sku: String, minimum_height: float = 144, approved_hero: bool = false) -> Control:
	var frame := Control.new()
	frame.name = "OfferArt_" + sku
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.custom_minimum_size.y = minimum_height
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key: String = {"starter_1": "shop_starter", "income_x2": "shop_income_x2", "no_ads": "shop_no_ads", "offer_noads_bundle": "shop_combo", "offer_combo_1": "shop_combo", "offer_combo_2": "shop_combo"}.get(sku, "")
	var did := String(GameData.iap_product(sku).get("grant", {}).get("driver", ""))
	if key == "" and did != "": key = "driver_lam_shop" if did == "driver_lam" else did
	var clay := HdUi.Soft.texture(key) if key != "" else null
	if clay != null:
		var image := TextureRect.new()
		image.texture = clay
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(image)
		return frame
	# V5 keeps the approved source illustrations, including My's orange uniform.
	var heroes := {
		"starter_1": preload("res://assets/iap_offers/illustrations/hero_starter.png"),
		"char_my": preload("res://assets/iap_offers/illustrations/hero_driver_my.png"),
		"income_x2": preload("res://assets/iap_offers/illustrations/hero_income_x2.png")
	}
	if approved_hero and heroes.has(sku):
		var picture := TextureRect.new()
		picture.texture = heroes[sku]
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(picture)
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return frame
	var scene := CleanArt.asset("res://assets/iap_offers/art/%s.tscn" % sku) as PackedScene
	if scene != null:
		var illustration := scene.instantiate() as Control
		frame.add_child(illustration)
		illustration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Keep the layout minimum independent of resize notifications. Updating it from
	# resized feeds back into ScrollContainer sorting and can exhaust Godot's queue.
	# The scene keeps its aspect ratio inside this stable, responsive-width frame.
	return frame


static func icon(id: String, extent: float = 30) -> TextureRect:
	# Vật phẩm thưởng có trong danh mục (data/reward_items) thì luôn dùng icon duy nhất của nó.
	if RewardItems.has(id):
		var item := TextureRect.new()
		item.texture = RewardItems.icon(id)
		item.custom_minimum_size = Vector2(extent, extent)
		item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL if extent <= 0 else Control.SIZE_SHRINK_CENTER
		return item
	if id.begins_with("driver_") or id.ends_with("_pack"):
		return ExpansionArt.icon(id, Vector2(extent, extent))
	return HdUi.icon("icons/%s.png" % id, Vector2(extent, extent))


static func rewards(product: Dictionary, owned_driver: bool = false) -> Array:
	var rows: Array = []
	var grant: Dictionary = product.get("grant", {})
	var did := String(grant.get("driver", ""))
	if did != "":
		var driver_name := String(GameData.driver(did).get("name", did))
		if owned_driver:
			rows.append({"icon": did, "value": I18n.t("shop.shards") % (int(GameData.iap().get("owned_driver_shards", 40)) + int(grant.get("driver_shards", 0))), "label": driver_name, "shards": true})
		else:
			rows.append({"icon": did, "value": driver_name, "label": I18n.t("shop.guaranteed")})
			if grant.has("driver_shards"):
				rows.append({"icon": did, "value": I18n.tn("shop.shards", int(grant["driver_shards"])) % int(grant["driver_shards"]), "label": driver_name, "shards": true})
	if grant.has("car"):
		rows.append({"icon": "car_blue", "value": String(GameData.car(String(grant["car"])).get("name", "")), "label": I18n.t("shop.epic_tag")})
	if grant.has("paint"):
		rows.append({"icon": "garage", "value": String(GameData.paint(String(grant["paint"])).get("name", "")), "label": I18n.t("shop.epic_for_all")})
	var perk := String(grant.get("perk", ""))
	if perk != "":
		var text := {"no_ads": I18n.t("shop.remove_ads_2"), "income_x2": I18n.t("common.income_x_2"), "income_x3": I18n.t("common.income_x_3"), "offline_plus": "Offline ×3"}
		rows.append({"icon": "crown" if perk == "no_ads" else ("research" if perk == "offline_plus" else "energy"), "value": text.get(perk, perk), "label": I18n.t("shop.permanent")})
	if grant.has("gems"):
		rows.append({"icon": "gem", "value": str(int(grant["gems"])), "label": "Gem"})
	for kind: String in grant.get("driver_coupon", {}):
		rows.append({"icon": "standard_driver_pack" if kind == "pro" else "elite_driver_pack", "value": "×%d" % int(grant["driver_coupon"][kind]), "label": I18n.t("shop.pro_ticket") if kind == "pro" else I18n.t("shop.all_star_ticket")})
	for kind: String in grant.get("gear_coupon", {}):
		rows.append({"icon": "standard_gear_pack" if kind == "standard" else "elite_gear_pack", "value": "×%d" % int(grant["gear_coupon"][kind]), "label": I18n.t("shop.standard_ticket") if kind == "standard" else I18n.t("shop.elite_ticket")})
	var tier_names := {"pro": I18n.t("drivers.tier_pro"), "elite": I18n.t("drivers.tier_elite"), "legend": I18n.t("drivers.tier_legend")}
	for tier: String in grant.get("driver_shards_tier", {}):
		rows.append({"icon": "standard_driver_pack" if tier == "pro" else "elite_driver_pack", "value": "×%d" % int(grant["driver_shards_tier"][tier]), "label": I18n.t("shop.tier_shards_title") % String(tier_names.get(tier, tier)), "shards": true})
	if grant.has("income_min"):
		rows.append({"icon": "cash", "value": I18n.t("common.h") % (int(grant["income_min"]) / 60), "label": I18n.t("common.income")})
	if String(product.get("kind", "")) == "pass_month":
		rows.append({"icon": "gem", "value": I18n.t("shop.day") % int(product.get("daily_gems", 0)), "label": I18n.tn("shop.days", int(product.get("days", 0))) % int(product.get("days", 0))})
		rows.append({"icon": "research", "value": I18n.t("shop.plus_h") % str(float(product.get("offline_bonus_sec", 0)) / 3600.0), "label": I18n.t("shop.offline_cap")})
	return rows


static func summary(product: Dictionary, owned_driver: bool = false) -> String:
	var lines := PackedStringArray()
	for row: Dictionary in rewards(product, owned_driver):
		lines.append("%s %s" % [row["value"], row["label"]])
	return " · ".join(lines)


static func reward_strip(product: Dictionary, owned_driver: bool = false) -> GridContainer:
	var rows := rewards(product, owned_driver)
	var grid := GridContainer.new()
	grid.columns = 3 if rows.size() > 4 else maxi(1, rows.size())
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for row: Dictionary in rows:
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.mouse_filter = Control.MOUSE_FILTER_PASS
		var style := StyleBoxFlat.new()
		style.bg_color = Color("ffffffed")
		style.set_corner_radius_all(8)
		style.set_content_margin_all(4)
		tile.add_theme_stylebox_override("panel", style)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 1)
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		var picture := icon(String(row["icon"]), 28)
		picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(picture)
		var value := label(String(row["value"]), 14)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(value)
		var caption := label(String(row["label"]), 11, Color("476991"))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(caption)
		tile.add_child(column)
		grid.add_child(tile)
	return grid


static func note(product: Dictionary) -> String:
	var grant: Dictionary = product.get("grant", {})
	if String(product.get("kind", "")) == "pass_month":
		return I18n.t("shop.get_gems_every_day_missed")
	if String(product.get("kind", "")) == "pass_growth":
		var milestones := PackedStringArray()
		for item: Array in product.get("milestones", []):
			milestones.append(I18n.t("shop.tier_gems") % [int(item[0]), int(item[1])])
		return " · ".join(milestones)
	if grant.has("income_min"):
		return I18n.t("shop.cash_based_team_income_at")
	match String(grant.get("perk", "")):
		"no_ads": return I18n.t("shop.turns_off_ads_break_gives")
		"income_x2", "income_x3": return I18n.t("shop.applies_online_income_race_rewards")
		"offline_plus": return I18n.t("shop.offline_income_x_3_accumulating")
	return ""
