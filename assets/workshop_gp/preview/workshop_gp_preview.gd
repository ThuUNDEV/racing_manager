extends Control
## Standalone art assembly: no gameplay, purchases, player data or simulation changes.
## --capture=/absolute/path.png writes a preview and exits (use isolated preview project).

const ROOT := "res://assets/workshop_gp/"
const ART_THEME := preload("res://assets/workshop_gp/theme.tres")
const TrackPreview := preload("res://assets/workshop_gp/preview/track_preview.gd")
const INK := Color("202b38")
const MUTED := Color("81766a")
const ORANGE := Color("ec6d08")
var _coins := 12450
var _coin_label: Label
var _levels := [2, 2, 2, 2]
var _capture := ""
var _track: Control


func _ready() -> void:
	theme = ART_THEME
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			_capture = arg.trim_prefix("--capture=")
	_build()
	if not _capture.is_empty():
		_track.set("animate_cars", false)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(_capture)
		print("WORKSHOP_CAPTURE=", _capture, " ERROR=", error)
		get_tree().quit(error)


func _style(name: String) -> StyleBox:
	return load(ROOT + "styles/" + name + ".tres") as StyleBox


func _icon(name: String, extent: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load(ROOT + "icons/" + name + ".tres") as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = extent
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _label(text: String, font_size: int = 14, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel(style_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(style_name))
	return panel


func _space() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


func _button(text: String, dark: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	if dark:
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, _style("graphite"))
	return button


func _build() -> void:
	var background := TextureRect.new()
	background.texture = load(ROOT + "ui/app_background.svg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	root.add_child(header)
	var wallet := HBoxContainer.new()
	wallet.add_theme_constant_override("separation", 8)
	header.add_child(wallet)
	var cash := _panel("capsule")
	cash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wallet.add_child(cash)
	var cash_row := HBoxContainer.new()
	cash_row.add_child(_icon("coins", Vector2(22, 24)))
	_coin_label = _label("12.450", 16)
	cash_row.add_child(_coin_label)
	cash.add_child(cash_row)
	var income := VBoxContainer.new()
	income.custom_minimum_size.x = 90
	var rate_caption := _label("Thu nhập /s", 11)
	rate_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	income.add_child(rate_caption)
	var rate := _label("$8", 22, Color("3b942a"))
	rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	income.add_child(rate)
	wallet.add_child(income)
	var gem := _panel("capsule")
	gem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var gem_row := HBoxContainer.new()
	gem_row.add_child(_icon("gem", Vector2(22, 24)))
	gem_row.add_child(_label("100", 16))
	gem.add_child(gem_row)
	wallet.add_child(gem)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	header.add_child(actions)
	var avatar := _panel("avatar")
	avatar.custom_minimum_size = Vector2(48, 48)
	var portrait := TextureRect.new()
	portrait.texture = load(ROOT + "portraits/driver_avatar.tres")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.add_child(portrait)
	actions.add_child(avatar)
	actions.add_child(_space())
	var boost := _button("Thu nhập 2x")
	boost.disabled = true # Art preview only; there is no ad integration.
	actions.add_child(boost)
	var classes := _button("HẠNG XE", true)
	classes.disabled = true
	actions.add_child(classes)

	var race := _panel("graphite")
	root.add_child(race)
	var race_box := VBoxContainer.new()
	race_box.add_theme_constant_override("separation", 3)
	race.add_child(race_box)
	var scoreboard := HBoxContainer.new()
	race_box.add_child(scoreboard)
	var team := VBoxContainer.new()
	team.add_child(_label("WORKSHOP GP", 14, Color("ff8d19")))
	team.add_child(_label("Giải tập sự · 220 fan", 10, Color("d7dce2")))
	scoreboard.add_child(team)
	scoreboard.add_child(_space())
	var position := VBoxContainer.new()
	var rank := _label("P3/8", 22, Color("ff981f"))
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position.add_child(rank)
	var timer := _label("00:43", 11, Color("ffffff"))
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position.add_child(timer)
	scoreboard.add_child(position)
	scoreboard.add_child(_space())
	var progress := Control.new()
	progress.custom_minimum_size.y = 13
	progress.draw.connect(func():
		progress.draw_rect(Rect2(Vector2.ZERO, progress.size), Color("a5aeb9"))
		for i in range(8):
			progress.draw_circle(Vector2((float(i) + 0.7) * progress.size.x / 9.0, 7), 2.4, ORANGE if i == 0 else Color("334457"))
	)
	race_box.add_child(progress)
	_track = TrackPreview.new()
	_track.custom_minimum_size.y = 232
	race_box.add_child(_track)

	var breathing_room := Control.new()
	breathing_room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(breathing_room)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	root.add_child(grid)
	for i in range(4):
		_upgrade_card(grid, i)

	var nav := _panel("card")
	root.add_child(nav)
	var nav_row := HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 1)
	nav.add_child(nav_row)
	for i in range(6):
		var item := VBoxContainer.new()
		item.add_theme_constant_override("separation", 1)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var holder: Control = item
		if i == 0:
			var selected := _panel("nav_selected")
			selected.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			selected.add_child(item)
			nav_row.add_child(selected)
		else:
			nav_row.add_child(item)
		var icon_id: String = ["team", "gear", "driver", "league", "events", "shop"][i]
		var image := _icon(icon_id, Vector2(28, 28))
		holder.add_child(image)
		var label := _label(["ĐỘI", "GEAR", "TAY ĐUA", "GIẢI", "SỰ KIỆN", "SHOP"][i], 9, Color.WHITE if i == 0 else INK)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		holder.add_child(label)


func _upgrade_card(parent: GridContainer, i: int) -> void:
	var card := _panel("card")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	card.add_child(body)
	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", 5)
	var icon_id: String = ["pace", "overtaking", "defense", "car_control"][i]
	title.add_child(_icon(icon_id, Vector2(27, 27)))
	var labels := VBoxContainer.new()
	labels.add_theme_constant_override("separation", 0)
	labels.add_child(_label(["Tốc độ", "Vượt xe", "Phòng thủ", "Kiểm soát xe"][i], 12))
	var level := _label("Cấp 2", 10, MUTED)
	labels.add_child(level)
	title.add_child(labels)
	body.add_child(title)
	var stat := _panel("stat")
	var value := _label("4%  →  6%", 14, Color("397534"))
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_child(value)
	body.add_child(stat)
	var buy := _button("NÂNG CẤP   $%d" % [120, 160, 140, 180][i])
	body.add_child(buy)
	buy.pressed.connect(func():
		var price: int = [120, 160, 140, 180][i]
		if _coins < price:
			return
		_coins -= price
		_levels[i] += 1
		_coin_label.text = str(_coins)
		level.text = "Cấp %d" % _levels[i]
		value.text = "%d%%  →  %d%%" % [_levels[i] * 2, _levels[i] * 2 + 2]
	)
