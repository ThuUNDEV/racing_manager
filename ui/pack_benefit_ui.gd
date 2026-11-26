extends RefCounted
## Approved benefit + gifts layout. Every label, quantity and price remains native UI.
const PackUi = preload("res://ui/shop_pack_ui.gd")
const PromoUi = preload("res://ui/pack_promo_ui.gd")
const Soft = preload("res://ui/soft_miniature.gd")
const ROOT := "res://assets/pack_benefit_v2/"
const INK := Color("0e2b5c")


static func scale_for(width: float) -> float:
	return clampf((width - 32.0) / 358.0, 0.72, 1.1)


static func shell() -> StyleBoxFlat:
	var style := PromoUi.shell_style()
	style.bg_color = Color("fff4e4")
	style.border_color = Color("ead7bd")
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	style.content_margin_left = 16
	style.content_margin_right = 16
	# The header is docked in this padding, completely outside the scroll viewport.
	style.content_margin_top = 70
	style.content_margin_bottom = 12
	return style


static func header(title: String, on_close: Callable, scale: float = 1.0) -> Control:
	var holder := Control.new()
	holder.name = "PromoHeaderHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.name = "PromoHeader"
	row.add_theme_constant_override("separation", 6)
	row.anchor_right = 1.0
	row.offset_top = -56
	row.offset_bottom = -8
	holder.add_child(row)
	var text := PackUi.label(title, roundi(34 * scale), INK)
	text.name = "PromoTitle"
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	text.clip_text = true
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.resized.connect(func() -> void: HdUi.fit_font(text, roundi(34 * scale), roundi(21 * scale)))
	row.add_child(text)
	var old_header := PromoUi.header("", on_close)
	var close := old_header.get_node("PromoClose") as TextureButton
	old_header.remove_child(close)
	old_header.free()
	row.add_child(close)
	return holder


static func split_rewards(product: Dictionary, owned: bool = false) -> Dictionary:
	var rows := PackUi.rewards(product, owned)
	var primary: Dictionary = {}
	var grant: Dictionary = product.get("grant", {})
	var income := String(grant.get("perk", "")).begins_with("income_")
	if not rows.is_empty():
		primary = rows.pop_front()
	if income:
		var mult := "×2" if String(grant["perk"]) == "income_x2" else "×3"
		primary = {"icon": "income_online", "value": mult, "label": I18n.t("shop.online_income_race_rewards")}
		rows = [
			{"icon": "income_online", "value": mult, "label": I18n.t("shop.online_income")},
			{"icon": "race_reward", "value": mult, "label": I18n.t("shop.race_rewards")},
		]
	return {"primary": primary, "gifts": rows, "income": income}


static func picture(texture: Texture2D, extent: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.custom_minimum_size = extent
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


static func _skin(file: String, margin: float) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(ROOT + file)
	style.set_texture_margin_all(margin)
	style.set_meta("rounded_button", true)
	return style


static func _badge(value: String, extent: float) -> Control:
	var badge := Control.new()
	badge.name = "PromoBadge"
	badge.custom_minimum_size = Vector2.ONE * extent
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := picture(load(ROOT + "badge_gold.svg"), Vector2.ZERO)
	badge.add_child(face)
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var caption := PackUi.label(value, roundi(extent * 0.32), INK)
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return badge


static func _chip(text: String, gold: bool = false, scale: float = 1.0) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "PermanentChip"
	var style := _skin("pill_blue.svg", 16)
	style.content_margin_left = 12 * scale
	style.content_margin_right = 12 * scale
	style.content_margin_top = 1
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	var caption := PackUi.label(text, roundi(20 * scale) if gold else roundi(18 * scale), Color("ffe047") if gold else Color.WHITE)
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	if gold:
		caption.clip_text = true
		caption.resized.connect(func() -> void: HdUi.fit_font(caption, roundi(20 * scale), roundi(12 * scale)))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_outline_color", Color("1452a0"))
	caption.add_theme_constant_override("outline_size", 2)
	panel.add_child(caption)
	return panel


static func primary(product: Dictionary, row: Dictionary, scale: float) -> Control:
	var sku := String(product["sku"])
	var grant: Dictionary = product.get("grant", {})
	var perk := String(grant.get("perk", ""))
	var did := String(grant.get("driver", ""))
	var gems := String(row.get("icon", "")) == "gem"
	var hero := HBoxContainer.new()
	hero.name = "PromoPrimary"
	hero.custom_minimum_size.y = (156 if perk.begins_with("income_") else 142) * scale
	hero.add_theme_constant_override("separation", roundi(6 * scale))
	var texture: Texture2D
	if did == "driver_my":
		texture = load(ROOT + "driver_my.png")
	elif did != "":
		texture = Soft.texture(did)
	elif perk == "no_ads":
		texture = load(ROOT + "no_ads.png")
	elif perk.begins_with("income_"):
		texture = load(ROOT + "income.png")
	elif perk == "offline_plus":
		texture = PromoUi.tex("perk_offline.png")
	elif String(product.get("kind", "")) in ["starter", "weekly", "offer"]:
		texture = load(ROOT + "mechanic.png")
	else:
		var reward_icon := PackUi.icon(String(row.get("icon", "gem")), 80)
		texture = reward_icon.texture
		reward_icon.free()
	var image := picture(texture, Vector2((126 if gems else (136 if perk == "no_ads" else 142)) * scale, 0))
	image.name = "OfferArt_" + sku
	hero.add_child(image)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", -roundi(8 * scale) if gems or perk.begins_with("income_") else 0)
	hero.add_child(box)
	var value := String(row.get("value", ""))
	var caption := String(row.get("label", ""))
	if perk.begins_with("income_"):
		var context := PackUi.label(caption, roundi(18 * scale), INK)
		context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(context)
	if perk == "no_ads":
		value = I18n.t("shop.pack_remove_ads")
	var headline := PackUi.label(value, roundi((64 if gems or perk.begins_with("income_") else (34 if perk == "no_ads" else 36)) * scale), INK)
	headline.name = "PromoPrimaryValue"
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(headline)
	if perk != "":
		box.add_child(_chip(I18n.t("shop.permanent"), true, scale))
	elif did != "":
		box.add_child(_chip(caption, true, scale))
	else:
		var unit := PackUi.label(caption, roundi(28 * scale), INK)
		unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(unit)
	if gems:
		var gem_column := VBoxContainer.new()
		gem_column.custom_minimum_size.x = 64 * scale
		gem_column.alignment = BoxContainer.ALIGNMENT_END
		var gem := PackUi.icon("gem", 64 * scale)
		gem.name = "PromoPrimaryGem"
		gem_column.add_child(gem)
		hero.add_child(gem_column)
	if product.has("value_x"):
		if not gems:
			# Driver starters also have a value badge; keep it in the text column,
			# rather than covering the driver's face with a floating badge.
			var inline_badge := _badge(PromoUi.value_text(product), 52 * scale)
			inline_badge.size_flags_horizontal = Control.SIZE_SHRINK_END
			box.add_child(inline_badge)
			box.move_child(inline_badge, 0)
			return hero
		# Badge overlays the hero, so it cannot push the amount or the art down.
		var badge_host := Control.new()
		badge_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_parent: Control = hero.get_child(hero.get_child_count() - 1).get_child(0)
		badge_parent.add_child(badge_host)
		var badge := _badge(PromoUi.value_text(product), 76 * scale)
		badge_host.add_child(badge)
		badge_host.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -76 * scale
		badge.offset_right = 0
		badge.offset_top = -78 * scale if gems else 0.0
		badge.offset_bottom = badge.offset_top + 76 * scale
	return hero


static func gifts(rows: Array, income: bool, scale: float) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.name = "PromoRewards"
	block.add_theme_constant_override("separation", -roundi(12 * scale))
	var heading := _chip((I18n.t("shop.pack_benefits") if income else I18n.t("shop.pack_gifts")).to_upper(), false, scale)
	heading.name = "PromoRewardsHeading"
	heading.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	heading.z_index = 1
	block.add_child(heading)
	var panel := PanelContainer.new()
	var style := PromoUi.shell_style()
	style.bg_color = Color("fbeedb")
	style.border_color = Color("e9cfab")
	style.shadow_size = 0
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	block.add_child(panel)
	var list := VBoxContainer.new()
	list.name = "PromoRewardRows"
	list.add_theme_constant_override("separation", 1)
	panel.add_child(list)
	for index in rows.size():
		var data: Dictionary = rows[index]
		if index > 0:
			var line := HSeparator.new()
			var border := StyleBoxLine.new()
			border.color = Color("dfc4a1")
			border.thickness = 1
			line.add_theme_stylebox_override("separator", border)
			line.add_theme_constant_override("separation", 1)
			list.add_child(line)
		var row := HBoxContainer.new()
		row.name = "PromoRewardRow%d" % index
		row.custom_minimum_size.y = (84 if rows.size() == 1 else 48) * scale
		row.add_theme_constant_override("separation", roundi(8 * scale))
		var id := String(data["icon"])
		var icon: Control
		if id == "cash" or id == "income_online":
			icon = picture(load(ROOT + "cash_clock.png"), Vector2(68 * scale, 0)) if id == "cash" else PackUi.icon(id, 68 * scale)
		elif id == "driver_my":
			icon = picture(load(ROOT + "driver_my.png"), Vector2(68 * scale, 0))
		else:
			icon = PromoUi._reward_icon(id, 68 * scale)
		icon.custom_minimum_size = Vector2(68 * scale, 0)
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		row.add_child(icon)
		if bool(data.get("shards", false)):
			var shard := picture(load(ROOT + "shard.svg"), Vector2.ZERO)
			shard.name = "PromoShard"
			icon.add_child(shard)
			shard.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			shard.offset_left = -26 * scale
			shard.offset_top = -26 * scale
		var shown := String(data["value"])
		if PromoUi.TICKETS.has(id):
			shown = shown.trim_prefix("×")
		var description := "%s %s" % [data["label"], shown] if income else "%s %s" % [shown, data["label"]]
		var text := PackUi.label(description, roundi((32 if rows.size() == 1 else 24) * scale), INK)
		text.name = "PromoRewardText"
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(text)
		row.set_meta("reward", data)
		list.add_child(row)
	return block


static func style_cta(button: Button, scale: float) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var skin := _skin("button_orange.svg", 18)
		skin.set_content_margin_all(0)
		if state == "disabled":
			skin = _skin("button_disabled.svg", 18)
			skin.set_content_margin_all(0)
		elif state == "hover":
			skin.modulate_color = Color(1.04, 1.04, 1.04)
		elif state in ["pressed", "hover_pressed"]:
			skin.modulate_color = Color("e8d5be")
		button.add_theme_stylebox_override(state, skin)
	button.add_theme_font_size_override("font_size", roundi(38 * scale))
	button.add_theme_font_override("font", HdUi.font())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("f5f0e8"))
	button.add_theme_color_override("font_outline_color", Color("c4520e"))
	button.add_theme_constant_override("outline_size", 2)


static func rates_button(text: String, scale: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", HdUi.font())
	button.add_theme_font_size_override("font_size", roundi(18 * scale))
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color("005acb"))
	button.draw.connect(func() -> void:
		var font := button.get_theme_font("font")
		var font_size := button.get_theme_font_size("font_size")
		var extent := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var x := (button.size.x - extent.x) * 0.5
		var y := (button.size.y - extent.y) * 0.5 + font.get_ascent(font_size) + 2
		button.draw_line(Vector2(x, y), Vector2(x + extent.x, y), Color("005acb"), 1.0))
	return button
