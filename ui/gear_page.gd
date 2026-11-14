class_name GearPage
extends VBoxContainer
## Tab Túi (Design/14): hai gói Standard/Elite, kho phụ kiện ba cột, sao = level, nâng bằng mảnh riêng.
## Chỉ trình bày và phát tín hiệu; mọi giao dịch nằm ở GameState.
signal open_requested(pack_id: String, count: int)
signal info_requested(pack_id: String)
signal upgrade_requested(gear_id: String)
## Lối tắt sang Shop (mục Mở gói): mọi giao dịch mở gói nằm ở Shop.
signal shop_requested

const INK := Color("23394a")
const MUTED := Color("768ca0")
const CARD := Color("eaf2ff")
const LINE := Color("adc9de")
const SWORD := Color("c62828")
const SHIELD := Color("2f6fb5")
const RARITY_COLOR := {"rare": Color("3a78d6"), "epic": Color("8a5bd0"), "legendary": Color("d08a12")}
const RARITY_NAME := {"rare": "Rare", "epic": "Epic", "legendary": "Legendary"}
const PACK_TINT := {"standard": Color("3a78d6"), "elite": Color("8a5bd0")}
const MAX_STAR_ROW := 6  # nhiều hơn thì đổi sang nhãn "Lv. N / Max"

var _sig := ""
var _scroll: ScrollContainer


## Hàng sao: một nguồn dữ liệu là level; sao đạt tô màu, chưa đạt xám.
class StarRow extends Control:
	var level := 0
	var max_level := 5
	var color := Color("f2b01e")

	func _init() -> void:
		custom_minimum_size = Vector2(0, 16)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var n := maxi(1, max_level)
		var cell := minf(size.x / n, 16.0)
		var total := cell * n
		var x0 := (size.x - total) * 0.5
		for i in n:
			var c := Vector2(x0 + cell * (i + 0.5), size.y * 0.5)
			var r := cell * 0.46
			var pts := PackedVector2Array()
			for k in 10:
				var ang := -PI / 2.0 + k * PI / 5.0
				var rad := r if k % 2 == 0 else r * 0.45
				pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
			draw_colored_polygon(pts, color if i < level else Color("b5c3da"))


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_FILL
	add_theme_constant_override("separation", 10)


func _ready() -> void:
	refresh()


func _style(bg: Color, border: Color = LINE, bw: int = 1, radius: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(8)
	return s


func _text(value: String, size: int = 13, color: Color = INK, wrap: bool = true) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _panel(parent: Node, style: StyleBoxFlat) -> VBoxContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.mouse_filter = Control.MOUSE_FILTER_PASS  # để kéo cuộn xuyên qua thẻ
	var skin := HdUi.card_style("locked" if style.bg_color == Color("e3e9f4") else "card").duplicate() as StyleBoxTexture
	skin.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", skin)
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	return v


func _button(value: String, tint: Color, enabled: bool) -> Button:
	var b := Button.new()
	b.text = value
	b.custom_minimum_size.y = 44
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 12)
	b.disabled = not enabled
	b.clip_text = true
	var on := _style(tint, tint.darkened(0.2), 1, 10)
	var off := _style(Color("c9d4e6"), Color("b5c3da"), 1, 10)
	b.add_theme_stylebox_override("normal", on)
	b.add_theme_stylebox_override("hover", _style(tint.lightened(0.1), tint.darkened(0.2), 1, 10))
	b.add_theme_stylebox_override("pressed", _style(tint.darkened(0.15), tint.darkened(0.3), 1, 10))
	b.add_theme_stylebox_override("disabled", off)
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("768ca0"))
	HdUi.style_button(b, "upgrade")
	return b


func _pay_label(pack_id: String, count: int) -> String:
	var pay := GameState.gear_payment(pack_id, count)
	if pay.is_empty():
		return "—"
	if pay["method"] == "coupon":
		return I18n.t("gear.open_x_coupons") % [count, int(pay["amount"])]
	return I18n.t("gear.open_x_gems") % [count, int(pay["amount"])]


func _signature() -> String:
	var parts: Array = [GameState.gems, GameState.gear_coupons.duplicate(), GameState.save_blocked, GameState.phase == "save_error"]
	for id: String in GameState.gear_owned.keys():
		parts.append([id, GameState.gear_level(id), GameState.gear_shards(id)])
	return str(parts)


## Dựng lại chỉ khi dữ liệu hiển thị đổi (main gọi theo nhịp ngắn).
func refresh() -> void:
	var sig := _signature()
	if sig == _sig and get_child_count() > 0:
		return
	_sig = sig
	var keep := _scroll.scroll_vertical if is_instance_valid(_scroll) else 0
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build(keep)


func _build_shop_shortcut() -> void:
	var coupons := 0
	for k: String in GameState.gear_coupons:
		coupons += int(GameState.gear_coupons[k])
	var card := PanelContainer.new()
	card.name = "ShopShortcut"
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_theme_stylebox_override("panel", _style(CARD, Color("f2a31e") if coupons > 0 else LINE, 2 if coupons > 0 else 1, 12))
	add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	row.add_child(ExpansionArt.icon("standard_gear_pack", Vector2(40, 40)))
	var info := _text(I18n.t("shop.shortcut_gear") % coupons, 13, INK)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	var go := Button.new()
	go.name = "OpenPacksInShop"
	go.text = I18n.t("shop.shortcut_button")
	go.custom_minimum_size = Vector2(96, 40)
	go.add_theme_font_size_override("font_size", 13)
	HdUi.style_button(go, "upgrade")
	go.pressed.connect(func() -> void: shop_requested.emit())
	row.add_child(go)


func _build(keep_scroll: int = 0) -> void:
	var title := _text(I18n.t("gear.gear_bag"), 17)
	add_child(title)
	_build_shop_shortcut()
	var head := HBoxContainer.new()
	add_child(head)
	head.add_child(_text(I18n.t("gear.gear_storage"), 15))
	var count := _text(I18n.t("gear.owned") % [GameState.gear_owned_count(), GameState.gear_total()], 13, MUTED, false)
	count.size_flags_horizontal = Control.SIZE_SHRINK_END
	head.add_child(count)

	# Chỉ kho phụ kiện cuộn; phần đầu trang (gói, sức mạnh) đứng yên.
	if GameState.gear_owned_count() > 0:
		var total := _text(I18n.t("gear.power_total") % _fmt_power(GameState.gear_power_bonus()), 13, SWORD, true)
		total.name = "GearPowerTotal"
		add_child(total)

	_scroll = ScrollContainer.new()
	_scroll.name = "InventoryScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Cuộn nằm ở trang Túi (main); kho giãn theo nội dung, không cuộn lồng nhau (khung đua ghim làm vùng này thấp).
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_FILL
	add_child(_scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(grid)
	for item: Dictionary in _sorted_items():
		_build_item(grid, item)
	if keep_scroll > 0:
		_scroll.set_deferred("scroll_vertical", keep_scroll)


## Số Power: bỏ ".0" thừa, dùng dấu thập phân theo ngôn ngữ.
static func _fmt_power(v: float) -> String:
	var r := snappedf(v, 0.1)
	return (str(int(r)) if is_equal_approx(r, round(r)) else "%.1f" % r).replace(".", I18n.dec())


## Đã sở hữu lên trước, trong nhóm giữ thứ tự trong dữ liệu.
func _sorted_items() -> Array:
	var owned: Array = []
	var rest: Array = []
	for it: Dictionary in GameData.gear_items():
		if GameState.gear_has(it["id"]):
			owned.append(it)
		else:
			rest.append(it)
	return owned + rest


func _build_item(parent: Node, item: Dictionary) -> void:
	var id := String(item["id"])
	var rarity := String(item["rarity"])
	var col: Color = RARITY_COLOR.get(rarity, INK)
	if not GameState.gear_has(id):
		var locked := _panel(parent, _style(Color("e3e9f4"), LINE, 1, 10))
		locked.custom_minimum_size = Vector2(0, 118)
		var silhouette := ExpansionArt.icon(id, Vector2(64, 64))
		silhouette.modulate = Color(0.1, 0.14, 0.22, 0.35)
		locked.add_child(silhouette)
		var q := _text(I18n.t("gear.not_owned"), 12, MUTED)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked.add_child(q)
		return
	var v := _panel(parent, _style(CARD, col, 2, 10))
	v.add_child(ExpansionArt.icon(id, Vector2(64, 64)))
	var level := GameState.gear_level(id)
	var max_level := GameState.gear_max_level(id)
	if max_level <= MAX_STAR_ROW:
		var stars := StarRow.new()
		stars.level = level
		stars.max_level = max_level
		v.add_child(stars)
	else:
		var lv := _text("Lv. %d / %d" % [level, max_level], 11, col, false)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lv)
	var name := _text(String(item["name"]), 12, INK)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name)
	var tag := _text(String(RARITY_NAME.get(rarity, rarity)), 10, col, false)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tag)
	var power := _text(I18n.t("gear.power_item") % _fmt_power(GameState.gear_item_power(id, level)), 12, SWORD, true)
	power.name = "ItemPower"
	power.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(power)
	var need := GameState.gear_upgrade_cost(id)
	var shards := GameState.gear_shards(id)
	if need < 0:
		var maxed := _text(I18n.t("common.max_level"), 11, MUTED, false)
		maxed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(maxed)
		return
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = need
	bar.value = mini(shards, need)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	v.add_child(bar)
	var prog := _text(I18n.t("gear.shards") % [shards, need], 11, MUTED, false)
	prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(prog)
	if shards >= need:
		var up := _button(I18n.t("common.upgrade"), col, not (GameState.save_blocked or GameState.phase == "save_error"))
		up.name = "Upgrade_" + id
		up.custom_minimum_size.y = 36
		up.pressed.connect(func() -> void: upgrade_requested.emit(id))
		v.add_child(up)
