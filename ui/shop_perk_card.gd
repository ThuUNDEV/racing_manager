extends PanelContainer
## Approved Soft Miniature A layout. Containers grow for translations; no scaled text.
signal buy_pressed
const Soft = preload("res://ui/soft_miniature.gd")
const ButtonSkin = preload("res://ui/button_skin.gd")
const RewardItems = preload("res://core/data/reward_items.gd")
const HERO_PATH := "res://assets/perk_cards_v1/heroes.png"
const PromoUi = preload("res://ui/pack_promo_ui.gd")
const SKUS := ["income_x2"]
## Nền cảnh đua phủ cả thẻ (trời, mây, đồi, lề đường); vẽ bằng SVG nhúng, nạp lúc chạy. Mỗi nhóm gói một bảng màu.
const SCENE_SVG := """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 366 150" preserveAspectRatio="xMidYMid slice">
<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{sky0}"/><stop offset=".6" stop-color="{sky1}"/><stop offset="1" stop-color="{sky2}"/></linearGradient>
<radialGradient id="ray" cx=".2" cy=".45" r=".5"><stop offset="0" stop-color="{glow}" stop-opacity=".95"/><stop offset="1" stop-color="{glow}" stop-opacity="0"/></radialGradient></defs>
<rect width="366" height="150" fill="url(#sky)"/><rect width="366" height="150" fill="url(#ray)"/>{extra}
<g fill="#fff" opacity="{cloud}"><ellipse cx="46" cy="26" rx="16" ry="6.5"/><ellipse cx="58" cy="21" rx="10" ry="6.5"/><ellipse cx="190" cy="22" rx="15" ry="6"/><ellipse cx="200" cy="18" rx="9" ry="5.5"/><ellipse cx="312" cy="36" rx="17" ry="6.5"/><ellipse cx="302" cy="31" rx="10" ry="6"/></g>
<path d="M0 92 Q50 70 110 88 T230 82 T366 84 V150 H0Z" fill="{h0}"/><path d="M0 108 Q80 92 160 106 T366 100 V150 H0Z" fill="{h1}"/>
<g fill="{bush0}"><circle cx="14" cy="104" r="9"/><circle cx="26" cy="109" r="7"/><circle cx="352" cy="100" r="9"/><circle cx="340" cy="106" r="7"/><circle cx="170" cy="112" r="6"/><circle cx="182" cy="115" r="5"/></g>
<g fill="{bush1}"><circle cx="12" cy="100" r="6"/><circle cx="354" cy="96" r="6"/></g>
<g fill="#ffd34d"><path d="M22 44 l2 6 6 2 -6 2 -2 6 -2 -6 -6 -2 6 -2z"/><path d="M118 38 l1.6 4.6 4.6 1.6 -4.6 1.6 -1.6 4.6 -1.6 -4.6 -4.6 -1.6 4.6 -1.6z"/></g></svg>"""
const SCENES := {
	"starter": {"sky0": "#63bff3", "sky1": "#c6ebff", "sky2": "#eaf8ff", "glow": "#fff6c8", "cloud": "1", "h0": "#9ad97a", "h1": "#6cc64d", "bush0": "#3fa63a", "bush1": "#58bb45", "k0": "#fff", "k1": "#e8453c", "extra": ""},
	"offer": {"sky0": "#ff8f5e", "sky1": "#ffc58a", "sky2": "#fff0cf", "glow": "#fff2a8", "cloud": ".55", "h0": "#a98ad0", "h1": "#8a6cc0", "bush0": "#6d54a8", "bush1": "#8266bb", "k0": "#fff", "k1": "#e8453c",
		"extra": "<circle cx=\"300\" cy=\"58\" r=\"34\" fill=\"#fff2a8\" opacity=\".35\"/><circle cx=\"300\" cy=\"58\" r=\"22\" fill=\"#fff7c2\"/>"},
	"weekly": {"sky0": "#35c4b8", "sky1": "#a8ece2", "sky2": "#e2fbf6", "glow": "#ffffff", "cloud": "1", "h0": "#8fdcae", "h1": "#52c48e", "bush0": "#2f9d6f", "bush1": "#44b583", "k0": "#fff", "k1": "#2f8be6",
		"extra": "<g opacity=\".9\"><circle cx=\"150\" cy=\"30\" r=\"3\" fill=\"#ff6b8a\"/><circle cx=\"230\" cy=\"48\" r=\"3\" fill=\"#ffd34d\"/><circle cx=\"280\" cy=\"22\" r=\"3\" fill=\"#fff\"/><circle cx=\"340\" cy=\"60\" r=\"3\" fill=\"#ff6b8a\"/><circle cx=\"110\" cy=\"60\" r=\"3\" fill=\"#ffd34d\"/></g>"},
	"character": {"sky0": "#3a4bb4", "sky1": "#8e9cf0", "sky2": "#d3dcff", "glow": "#ffe9a8", "cloud": ".35", "h0": "#5fb06f", "h1": "#3f9158", "bush0": "#2d7a47", "bush1": "#3f9158", "k0": "#ffd34d", "k1": "#33424f",
		"extra": "<g fill=\"#fff\"><circle cx=\"150\" cy=\"18\" r=\"1.6\"/><circle cx=\"210\" cy=\"34\" r=\"1.3\"/><circle cx=\"270\" cy=\"14\" r=\"1.8\"/><circle cx=\"330\" cy=\"40\" r=\"1.4\"/><circle cx=\"100\" cy=\"12\" r=\"1.3\"/><circle cx=\"240\" cy=\"56\" r=\"1.2\"/></g>"},
	"daily": {"sky0": "#ffc84a", "sky1": "#ffe9a0", "sky2": "#fff8da", "glow": "#ffffff", "cloud": ".8", "h0": "#b7e07a", "h1": "#8fcf56", "bush0": "#6fb440", "bush1": "#86c750", "k0": "#fff", "k1": "#ff9a2e",
		"extra": "<path d=\"M70 130 L-40 0 L10 -10Z M70 130 L90 -20 L150 -10Z M70 130 L210 -20 L280 10Z M70 130 L380 40 L380 90Z\" fill=\"#fff\" opacity=\".28\"/>"},
	"perk": {"sky0": "#5a8ff0", "sky1": "#a9c8ff", "sky2": "#e3eeff", "glow": "#e8f4ff", "cloud": ".9", "h0": "#8fd6b0", "h1": "#55bf8e", "bush0": "#2f9d74", "bush1": "#46b386", "k0": "#fff", "k1": "#2f6fe0", "extra": ""},
}
const PODIUM_SVG := """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 104 26">
<defs><clipPath id="pc"><path d="M0 8 V16 A52 10 0 0 0 104 16 V8 Z"/></clipPath></defs>
<ellipse cx="52" cy="16" rx="52" ry="10" fill="#d9ccb4"/>
<g clip-path="url(#pc)"><rect y="8" width="104" height="20" fill="#f4ead6"/></g>
<ellipse cx="52" cy="8" rx="52" ry="8" fill="#f7eedb"/></svg>"""
const CREAM := Color("fff4e4")
const PRICE_FONT := 21
const TITLE_FONT := 20
## Mọi thẻ pack cao bằng nhau; thưởng nhỏ gọn để 3 mục nằm một hàng.
const CARD_HEIGHT := 192
const REWARD_TILE := 46.0
const REWARD_TILE_MIN := 24.0
const REWARD_TILE_2ROW := 36.0
const REWARD_GAP := 2
const REWARD_SEP := 8
const PLATE_MAX_WIDTH := 184.0
static var _textures: Dictionary = {}

var sku := ""
var price: Button
var title: Label
var benefit: Label
var permanent: Label
var _art_column: VBoxContainer
var _flow: VBoxContainer
var _plate: PanelContainer
var _hero: Control
var _badge: Control


## Thẻ perk (Income ×N, Offline+): hero cắt từ atlas, huy hiệu hệ số; thưởng là icon + số (không viết chữ).
func setup(product: Dictionary) -> void:
	var sku_id := String(product["sku"])
	var art: Texture2D
	if sku_id == "income_x2":
		art = PromoUi.tex("perk_income.png")
	else:
		var sheet := load(HERO_PATH) as Texture2D
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		var cell := sheet.get_size() / 2.0
		atlas.region = Rect2(Vector2(SKUS.find(sku_id) % 2, SKUS.find(sku_id) / 2) * cell, cell)
		atlas.filter_clip = true
		art = atlas
	var multiplier := 2 if sku_id == "income_x2" else 3
	var title_text := I18n.t("shop.perk_income_title") % multiplier
	if sku_id == "income_x3_up": title_text = I18n.t("shop.perk_upgrade_title")
	if sku_id == "offline_plus": title_text = I18n.t("shop.perk_offline_title")
	var rewards: Array = []
	if sku_id == "offline_plus":
		rewards.append(reward("research", "×3"))
	else:
		rewards.append(reward("income_online", "×%d" % multiplier))
		rewards.append(reward("race_reward", "×%d" % multiplier))
	build(product, {
		"art": art, "title": title_text, "rewards": rewards,
		"badge": "×2 → ×3" if sku_id == "income_x3_up" else ("×2" if sku_id == "income_x2" else "×3"),
	})


## Một ô thưởng lấy từ danh mục vật phẩm (data/reward_items): icon, số lượng ("" = chỉ icon) và tên cho tooltip.
static func reward(item_id: String, text: String, label: String = "") -> Dictionary:
	return {"icon": RewardItems.icon(item_id), "text": text, "label": label if label != "" else RewardItems.item_name(item_id)}


## Thẻ gói thường (Starter, combo, tay đua, gói tuần/ngày) cùng khung với thẻ perk.
## opts: art (Texture2D), title, rewards ([{icon, text, tint}]), chip (nhãn nhỏ dưới art, có thể rỗng).
func setup_pack(product: Dictionary, opts: Dictionary) -> void:
	build(product, opts)


## opts: art, title, benefit (đoạn mô tả), rewards (hàng chip thưởng), chip, badge (huy hiệu góc phải hero).
func build(product: Dictionary, opts: Dictionary) -> void:
	sku = String(product["sku"])
	name = "Offer_" + sku
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size.y = CARD_HEIGHT
	var surface := Soft.flat(CREAM, 2, 20)
	surface.border_color = Color("e8d5bc")
	surface.set_border_width_all(2)
	surface.shadow_color = Color("79593633")
	surface.shadow_size = 4
	surface.shadow_offset = Vector2(0, 3)
	add_theme_stylebox_override("panel", surface)
	# Nền: cảnh đua phủ kín thẻ, bo theo góc thẻ.
	var scene := Panel.new()
	scene.name = "Scene"
	scene.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scene_skin := StyleBoxFlat.new()
	scene_skin.bg_color = Color("c6ebff")
	scene_skin.set_corner_radius_all(18)
	scene.add_theme_stylebox_override("panel", scene_skin)
	add_child(scene)
	var backdrop := TextureRect.new()
	var kind := String(product.get("kind", ""))
	if not SCENES.has(kind):
		kind = "starter"
	backdrop.texture = _svg_texture("scene_" + kind, SCENE_SVG.format(SCENES[kind]), 2.0)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8 if side != "bottom" else 8)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	_art_column = VBoxContainer.new()
	_art_column.add_theme_constant_override("separation", 3)
	_art_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_art_column)
	_hero = Control.new()
	_hero.name = "OfferArt_" + sku
	_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hero.custom_minimum_size.y = 104
	_art_column.add_child(_hero)
	var podium := TextureRect.new()
	podium.name = "Podium"
	podium.texture = _svg_texture("podium", PODIUM_SVG, 3.0)
	podium.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	podium.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	podium.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.add_child(podium)
	podium.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	podium.offset_top = -28
	podium.offset_bottom = -4
	var art := TextureRect.new()
	art.name = "Hero"
	art.texture = opts.get("art") as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 2
	art.offset_right = -2
	art.offset_bottom = -6
	var badge_text := String(opts.get("badge", ""))
	if badge_text != "":
		_badge = PromoUi.badge(badge_text, "", 64.0)
		_badge.name = "PerkBadge"
		_hero.add_child(_badge)
		_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		_badge.offset_left = -50
		_badge.offset_right = 14
		_badge.offset_top = -10
		_badge.offset_bottom = 54
	var chip_text := String(opts.get("chip", ""))
	if chip_text != "":
		var chip := PanelContainer.new()
		chip.name = "PermanentChip" if sku in SKUS else "LimitChip"
		chip.add_theme_stylebox_override("panel", Soft.flat(Color("d8ebcb"), 3, 10))
		_art_column.add_child(chip)
		permanent = _label(chip_text, 13, Color("365c42"))
		permanent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(permanent)
	var copy := VBoxContainer.new()
	copy.name = "Copy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	row.add_child(copy)
	# Tấm kem chỉ bọc tên và phần thưởng; nút mua nằm ngoài, trực tiếp trên cảnh.
	var plate := PanelContainer.new()
	plate.name = "Plate"
	_plate = plate
	plate.size_flags_horizontal = Control.SIZE_SHRINK_END
	plate.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var plate_skin := Soft.flat(Color(1.0, 0.973, 0.925, 0.94), 6, 16)
	plate_skin.shadow_color = Color("79593622")
	plate_skin.shadow_size = 3
	plate.add_theme_stylebox_override("panel", plate_skin)
	plate.clip_contents = true
	copy.add_child(plate)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.custom_minimum_size.y = 4
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(gap)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 2)
	plate.add_child(info)
	title = _label(String(opts.get("title", "")), TITLE_FONT)
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title.add_theme_color_override("font_color", Soft.INK)
	# Tên gói nằm ngoài tấm kem, góc trên trái của thẻ, trên một nhãn kem bo tròn ôm sát chữ.
	var title_pill := PanelContainer.new()
	title_pill.name = "TitlePill"
	title_pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var pill_skin := Soft.flat(Color(1.0, 0.973, 0.925, 0.94), 3, 13)
	pill_skin.content_margin_left = 10
	pill_skin.content_margin_right = 10
	pill_skin.shadow_color = Color("79593622")
	pill_skin.shadow_size = 3
	title_pill.add_theme_stylebox_override("panel", pill_skin)
	title_pill.add_child(title)
	column.add_child(title_pill)
	column.move_child(title_pill, 0)
	if String(opts.get("benefit", "")) != "":
		benefit = _label(String(opts["benefit"]), 15, Color("465a60"))
		benefit.name = "Benefit"
		info.add_child(benefit)
	var rewards: Array = opts.get("rewards", [])
	if not rewards.is_empty():
		# Tối đa 3 ô một hàng; từ 4 ô trở lên chia 2 hàng cân nhau (4 = 2+2, 5 = 3+2, 6 = 3+3).
		# Mỗi ô nằm trong một ngăn giãn đều theo chiều ngang nên thưởng dàn đều, không dồn về một bên.
		var flow := VBoxContainer.new()
		flow.name = "Rewards"
		flow.add_theme_constant_override("separation", REWARD_GAP)
		flow.alignment = BoxContainer.ALIGNMENT_CENTER
		flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flow = flow
		info.add_child(flow)
		var per_row := rewards.size() if rewards.size() <= 3 else int(ceil(rewards.size() / 2.0))
		var row_box: HBoxContainer = null
		var index := 0
		for item: Dictionary in rewards:
			if index % per_row == 0:
				row_box = HBoxContainer.new()
				row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
				flow.add_child(row_box)
			index += 1
			# Ô thưởng: icon lớn, số lượng đè ở góc dưới phải (viền tối). Giữ tên đầy đủ trong tooltip.
			var tile := Control.new()
			tile.custom_minimum_size = Vector2(REWARD_TILE_MIN, REWARD_TILE_MIN)
			tile.mouse_filter = Control.MOUSE_FILTER_STOP
			var text := String(item["text"])
			var label_text := String(item.get("label", ""))
			var icon := TextureRect.new()
			icon.texture = item["icon"]
			icon.modulate = item.get("tint", Color.WHITE)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.add_child(icon)
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			icon.offset_bottom = -4
			if text != "":
				var amount := Label.new()
				amount.text = text
				amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
				amount.add_theme_font_override("font", HdUi.font())
				amount.add_theme_font_size_override("font_size", 17 if text.length() <= 4 else (14 if text.length() <= 6 else 12))
				amount.add_theme_color_override("font_color", Color.WHITE)
				amount.add_theme_color_override("font_outline_color", Color("1f3347"))
				amount.add_theme_constant_override("outline_size", 5)
				tile.add_child(amount)
				amount.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
				amount.offset_left = -REWARD_TILE - 4
				amount.offset_right = 3
				amount.offset_top = -22
				amount.offset_bottom = 3
			var slot := CenterContainer.new()
			slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(tile)
			row_box.add_child(slot)
	else:
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		info.add_child(spacer)
	price = Button.new()
	price.name = "Iap_" + sku
	price.text = String(product.get("price_fallback", ""))
	price.custom_minimum_size = Vector2(120, 44)
	price.size_flags_horizontal = Control.SIZE_SHRINK_END
	price.add_theme_font_override("font", HdUi.font())
	price.add_theme_font_size_override("font_size", PRICE_FONT)
	price.clip_text = true
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var disabled: bool = state == "disabled"
		var pressed: bool = state in ["pressed", "hover_pressed"]
		var top := Color("ecdcc8") if disabled else Color("ffab4d" if state == "hover" else ("e8700f" if pressed else "ff9a2e"))
		price.add_theme_stylebox_override(state, ButtonSkin.palette(top, Color("e6d4bc") if disabled else Color("e8700f" if pressed else "ff831e"), Color("cbb79b") if disabled else Color("a8420a" if pressed else "d5570e")))
		price.add_theme_color_override("font_" + state + "_color" if state != "normal" else "font_color", Color("657079") if disabled else Color.WHITE)
	price.add_theme_color_override("font_outline_color", Color("a2420a"))
	price.set_meta("price_outline_color", Color("a2420a"))
	price.add_theme_constant_override("outline_size", 4)
	var focus := Soft.flat(Color.TRANSPARENT, 0, 24)
	focus.border_color = Color("168cc2")
	focus.set_border_width_all(2)
	price.add_theme_stylebox_override("focus", focus)
	price.pressed.connect(buy_pressed.emit)
	copy.add_child(price)
	resized.connect(_adapt)
	price.resized.connect(_fit_price)
	_adapt()


## Nền cảnh đua theo nhóm màu (starter, offer, weekly, character, daily, perk); dùng chung cho thẻ nhỏ ở Shop.
static func scene_texture(kind: String) -> ImageTexture:
	if not SCENES.has(kind):
		kind = "starter"
	return _svg_texture("scene_" + kind, SCENE_SVG.format(SCENES[kind]), 2.0)


static func _svg_texture(key: String, svg: String, scale: float) -> ImageTexture:
	if not _textures.has(key):
		var image := Image.new()
		image.load_svg_from_string(svg, scale)
		_textures[key] = ImageTexture.create_from_image(image)
	return _textures[key]


func _label(value: String, font_size: int, color: Color = Soft.INK) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", HdUi.font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _adapt() -> void:
	_fit_title()
	_art_column.custom_minimum_size.x = clampf(((get_viewport_rect().size.x - 24.0) - 34) * 0.36, 90, 128)
	_fit_rewards()
	_fit_price()


## Ô thưởng co theo bề rộng thẻ (không theo bề rộng đo được của chính hàng đó, tránh vòng lặp kích thước).
## Một hàng: tối đa REWARD_TILE; hai hàng: REWARD_TILE_2ROW để thẻ vẫn cao bằng nhau.
func _fit_rewards() -> void:
	if _flow == null or _flow.get_child_count() == 0: return
	var rows := _flow.get_child_count()
	var per_row := (_flow.get_child(0) as Control).get_child_count()
	var card_w := (get_viewport_rect().size.x - 24.0)
	var column_w := card_w - 20.0 - _art_column.custom_minimum_size.x - 8.0
	# Khung kem rộng vừa phải (tối đa PLATE_MAX_WIDTH), thưởng dàn đều bên trong.
	var plate_w := minf(column_w, PLATE_MAX_WIDTH)
	_plate.custom_minimum_size.x = plate_w
	var avail := plate_w - 12.0
	# Ô thưởng có cỡ theo số lượng (1-2 ô: 56, 3 ô: 50, 4 ô: 44; hai hàng: 40), chỉ co lại khi màn quá hẹp.
	var cap := REWARD_TILE_2ROW
	if rows == 1:
		cap = 56.0 if per_row <= 2 else (50.0 if per_row == 3 else 44.0)
	var tile := clampf((avail - REWARD_SEP * (per_row - 1)) / per_row, REWARD_TILE_MIN, cap)
	for row in _flow.get_children():
		for slot in row.get_children():
			var cell := slot.get_child(0) as Control
			cell.custom_minimum_size = Vector2(tile, tile)
			if cell.get_child_count() > 1:
				var amount := cell.get_child(1) as Label
				var chars := amount.text.length()
				var base := int(clampf(tile * 0.38, 12.0, 24.0))
				amount.add_theme_font_size_override("font_size", base if chars <= 4 else (maxi(base - 3, 11) if chars <= 6 else maxi(base - 5, 10)))
				amount.offset_top = -(base + 6)


func _fit_title() -> void:
	if title == null: return
	var card_w := (get_viewport_rect().size.x - 24.0)
	var avail := card_w - 16.0 - 20.0 - 4.0
	var font_size := TITLE_FONT
	var font := title.get_theme_font("font")
	while font_size > 13 and font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > avail:
		font_size -= 1
	title.add_theme_font_size_override("font_size", font_size)


func _fit_price() -> void:
	if price == null or price.size.x <= 0: return
	var font_size := PRICE_FONT
	var font := price.get_theme_font("font")
	while font_size > 12 and font.get_string_size(price.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > price.size.x - 20:
		font_size -= 1
	price.add_theme_font_size_override("font_size", font_size)


func update_price(value: String, busy: bool, reason: String) -> void:
	price.text = I18n.t("shop.processing") if busy else (I18n.t("common.owned_2") if reason == "owned" else value)
	price.disabled = busy or reason != ""
	price.add_theme_constant_override("outline_size", 0 if price.disabled else 4)
	_fit_price()
