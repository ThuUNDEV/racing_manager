extends Control
## Standalone asset gallery: display values and button feedback are previews only.
## Never reads GameState, RaceSim, user:// or player saves.
const ROOT := "res://assets/workshop_gp/"
const Widget := preload("res://assets/workshop_gp/components/asset_widget.gd")
const TrackArt := preload("res://assets/workshop_gp/components/track_art.gd")
const Audio := preload("res://assets/workshop_gp/components/workshop_audio.gd")
const SCREENS := ["race", "drivers", "garage", "league", "shop", "result", "offline", "missions", "settings", "season", "onboarding", "library"]
const TITLES := ["Đường đua", "Tay đua", "Garage", "Giải đấu", "Cửa hàng", "Kết quả", "Thu nhập vắng mặt", "Nhiệm vụ", "Cài đặt", "Tổng kết mùa", "Hướng dẫn", "Thư viện asset"]
const INK := Color("202b38")
const MUTED := Color("776d61")
const ORANGE := Color("f47510")
var _screen := "race"
var _track_id := "harbor"
var _track: Control
var _content: VBoxContainer
var _audio: Node
var _capture_dir := ""
var _capture_file := ""
var _board_path := ""
var _asset_board_path := ""
var _animate := true
var _seconds := 0.0
var _selected_driver := "an"
var _sound_enabled := false
var _root: Control


func _ready() -> void:
	theme = load(ROOT + "theme.tres")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screen="):
			_screen = arg.trim_prefix("--screen=")
		elif arg.begins_with("--track="):
			_track_id = arg.trim_prefix("--track=")
		elif arg.begins_with("--capture-dir="):
			_capture_dir = arg.trim_prefix("--capture-dir=")
		elif arg.begins_with("--capture="):
			_capture_file = arg.trim_prefix("--capture=")
		elif arg.begins_with("--board="):
			_board_path = arg.trim_prefix("--board=")
		elif arg.begins_with("--asset-board="):
			_asset_board_path = arg.trim_prefix("--asset-board=")
	_animate = _capture_dir.is_empty() and _capture_file.is_empty()
	_audio = Audio.new()
	add_child(_audio)
	_build()
	if not _capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(_capture_dir)
		for id: String in SCREENS:
			_screen = id
			_build()
			await _capture(_capture_dir.path_join(id + ".png"))
		for id: String in ["pine", "city"]:
			_screen = "race"
			_track_id = id
			_build()
			await _capture(_capture_dir.path_join("race_" + id + ".png"))
		if not _board_path.is_empty():
			await _render_board()
		if not _asset_board_path.is_empty():
			await _render_asset_board()
		print("WORKSHOP_GALLERY_CAPTURE_OK")
		get_tree().quit()
	elif not _capture_file.is_empty():
		await _capture(_capture_file)
		get_tree().quit()


func _process(delta: float) -> void:
	if _animate and is_instance_valid(_track):
		_seconds += delta
		_update_racers()


func _update_racers() -> void:
	if not is_instance_valid(_track):
		return
	var racers: Array = []
	for i in range(8):
		racers.append({"lap_fraction": fposmod(0.025 + i*.118 + _seconds*.035, 1), "color": i, "player": i==0})
	_track.set_racers(racers)


func _capture(path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_update_racers()
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Capture failed: " + path)
		get_tree().quit(error)


func _label(value: String, point_size: int = 14, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", point_size)
	label.add_theme_color_override("font_color", color)
	return label


func _image(path: String, extent: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load(ROOT + path)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = extent
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _button(text: String, callback: Callable, secondary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	if secondary:
		for state: String in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, load(ROOT + "styles/button_secondary.tres"))
	button.pressed.connect(func():
		_cue("ui_click")
		callback.call()
	)
	return button


func _icon_button(icon: String, tip: String, callback: Callable) -> Button:
	var button := _button("", callback, true)
	button.custom_minimum_size = Vector2(44, 44)
	button.icon = load(ROOT + "icons/vector/" + icon + ".svg")
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 22)
	button.tooltip_text = tip
	return button


func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	return row


func _box(parent: Node, style_name: String = "card") -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", load(ROOT + "styles/" + style_name + ".tres"))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	return box


func _widget(parent: Node, data: Dictionary) -> PanelContainer:
	var widget := Widget.new()
	widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	widget.configure(data)
	parent.add_child(widget)
	return widget


func _heading(title: String, detail: String = "") -> void:
	_content.add_child(_label(title, 24))
	if not detail.is_empty():
		_content.add_child(_label(detail, 12, MUTED))


func _build() -> void:
	_track = null
	if is_instance_valid(_root):
		remove_child(_root)
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var background := _image("ui/app_background.svg", Vector2.ZERO)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.stretch_mode = TextureRect.STRETCH_SCALE
	_root.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_"+side, 12 if side in ["left", "right"] else 8)
	_root.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var toolbar := _row(column)
	var brand := _label("WORKSHOP GP", 18, ORANGE)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toolbar.add_child(brand)
	toolbar.add_child(_icon_button("mission", "Nhiệm vụ", func(): _show("missions")))
	toolbar.add_child(_icon_button("settings", "Cài đặt", func(): _show("settings")))
	var wallet := _row(column)
	for data: Array in [["coins", "12.450"], ["gem", "100"]]:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", load(ROOT + "styles/capsule.tres"))
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wallet.add_child(panel)
		var row := _row(panel)
		row.add_child(_image("icons/"+str(data[0])+".tres", Vector2(26,30)))
		row.add_child(_label(data[1], 18))
	if _animate:
		var menu := OptionButton.new()
		menu.custom_minimum_size.y = 44
		for i in range(SCREENS.size()):
			menu.add_item(TITLES[i])
		menu.select(maxi(SCREENS.find(_screen),0))
		menu.item_selected.connect(func(i: int): _show(SCREENS[i]))
		column.add_child(menu)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_content)
	match _screen:
		"race": _race()
		"drivers": _drivers()
		"garage": _garage()
		"league": _league()
		"shop": _shop()
		"result": _result()
		"offline": _offline()
		"missions": _missions()
		"settings": _settings()
		"season": _season()
		"onboarding": _onboarding()
		"library": _library()
	_build_nav(column)


func _build_nav(parent: Node) -> void:
	var box := _box(parent)
	var row := _row(box)
	for i in range(5):
		var id: String = ["race","drivers","garage","league","shop"][i]
		var icon: String = ["team","driver","gear","league","shop"][i]
		var button := Button.new()
		button.custom_minimum_size.y = 60
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var flat := StyleBoxEmpty.new()
		for state: String in ["normal","hover","pressed"]:
			button.add_theme_stylebox_override(state, load(ROOT+"styles/nav_selected.tres") if _screen==id else flat)
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation", 1)
		content.add_child(_image("icons/"+icon+".tres", Vector2(28,32)))
		var text := _label(["Đua","Tay đua","Garage","Giải","Shop"][i], 12, Color.WHITE if _screen==id else INK)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(text)
		button.add_child(content)
		button.pressed.connect(func(): _show(id))
		row.add_child(button)


func _show(screen: String) -> void:
	_cue("ui_tab")
	_screen = screen
	_build()


func _race() -> void:
	var track_name: String = {"harbor":"Harbor Oval","pine":"Pine Circuit","city":"City Technical"}.get(_track_id,"Harbor Oval")
	var header := _row(_content)
	var avatar := _image("portraits/driver_avatar.tres", Vector2(42,44))
	header.add_child(avatar)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.add_child(_label("Giải tập sự · Chặng 1/5", 15))
	labels.add_child(_label("Thu nhập cơ sở 8 tiền/giây",12,MUTED))
	header.add_child(labels)
	var box := _box(_content,"graphite")
	box.add_theme_constant_override("separation",6)
	var row := _row(box)
	var name := _label(track_name.to_upper(),14,Color("fff7e8"))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	row.add_child(_label("P3/8  ·  00:43",16,Color("ff9b32")))
	box.add_child(_label("Vòng 2/3                         Xe 01 · Bạn",12,Color("d5dce2")))
	var progress := HBoxContainer.new()
	progress.add_theme_constant_override("separation",4)
	for i in range(8):
		var segment := ColorRect.new()
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.custom_minimum_size.y = 5
		segment.color = ORANGE if i<3 else Color("5e6977")
		progress.add_child(segment)
	box.add_child(progress)
	_track = TrackArt.new()
	_track.track_id = _track_id
	_track.custom_minimum_size.y = 220
	box.add_child(_track)
	_update_racers()
	if _animate:
		var chooser := OptionButton.new()
		for value: String in ["Harbor Oval", "Pine Circuit", "City Technical"]:
			chooser.add_item(value)
		chooser.select(["harbor","pine","city"].find(_track_id))
		chooser.custom_minimum_size.y = 44
		chooser.item_selected.connect(func(i: int):
			_track_id = ["harbor","pine","city"][i]
			_build()
		)
		_content.add_child(chooser)
	_content.add_child(_button("ĐUA CHẶNG 1",func(): _show("result")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	_content.add_child(grid)
	for data: Array in [["engine","Động cơ"],["tyre","Lốp"],["chassis","Khung gầm"],["gearbox","Hộp số"]]:
		var card := _widget(grid,{"kind":"upgrade","item_id":data[0],"title":data[1],"subtitle":"Cấp 2 · 44 → 46","image_path":ROOT+"icons/vector_dark/"+str(data[0])+".svg","action_text":"Nâng · 120"})
		card.action_requested.connect(func(_id: String): _feedback("upgrade",card))


func _drivers() -> void:
	_heading("Đội ngũ tay đua", "Chọn tay đua trước khi bắt đầu cuộc đua.")
	for data: Array in [["an","An","Pace 44 · Kỹ thuật 40 · Bình tĩnh 40"],["binh","Bình","Pace 40 · Kỹ thuật 46 · Bình tĩnh 42"],["chi","Chi","Pace 42 · Kỹ thuật 43 · Bình tĩnh 46"]]:
		var active: bool = _selected_driver==data[0]
		var card := _widget(_content,{"kind":"driver","item_id":data[0],"title":data[1],"subtitle":data[2]+("\n✓ Đang thi đấu" if active else "\nChân dung / trạng thái minh họa"),"image_path":ROOT+"portraits/driver_"+str(data[0])+".tres","selected":active,"action_text":"Đang thi đấu" if active else "Chọn tay đua","disabled":active})
		card.action_requested.connect(func(id: String):
			_selected_driver = id
			_cue("ui_confirm")
			_build()
		)


func _garage() -> void:
	_heading("Garage", "Một xe · Bốn bộ phận nâng cấp")
	var stage := _box(_content,"graphite")
	var row := _row(stage)
	row.add_child(_image("cars/orange.tres",Vector2(110,180)))
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.add_child(_label("XE 01",25,Color("ff9b32")))
	labels.add_child(_label("WORKSHOP GP\nHạng tập sự\n\nCam · Graphite",13,Color("fff7e8")))
	row.add_child(labels)
	for data: Array in [["engine","Động cơ"],["tyre","Lốp"],["chassis","Khung gầm"],["gearbox","Hộp số"],["venue","Cơ sở"]]:
		var card := _widget(_content,{"kind":"upgrade","title":data[1],"subtitle":"Cấp 2 · 44 → 46" if data[0]!="venue" else "Cấp 0 · Thu nhập 8 → 8,96/s","image_path":ROOT+"icons/vector_dark/"+str(data[0])+".svg","action_text":"Nâng cấp · 120" if data[0]!="venue" else "Nâng cơ sở · 150"})
		card.action_requested.connect(func(_id: String): _feedback("upgrade",card))


func _league() -> void:
	_heading("Giải tập sự", "Mùa 1 · Năm chặng đua")
	_widget(_content,{"kind":"league","title":"Mục tiêu thăng hạng","subtitle":"24 / 36 điểm · Chặng 4/5","image_path":ROOT+"rewards/rookie_cup.tres","action_text":"","progress":66.7})
	var ids := ["harbor","pine","city","pine","harbor"]
	for i in range(5):
		var name: String = ["Harbor Oval","Pine Circuit","City Technical","Pine Circuit","Harbor Oval"][i]
		var image: String = {"harbor":"workshop_oval","pine":"pine_circuit","city":"city_technical"}[ids[i]]
		_widget(_content,{"kind":"league","title":"Chặng %d · %s"%[i+1,name],"subtitle":"Hoàn tất · 8 điểm" if i<3 else ("Chặng tiếp theo" if i==3 else "Chưa mở"),"image_path":ROOT+"textures/"+image+".png","action_text":"","selected":i==3,"disabled":i==4,"progress":100 if i<3 else 0})
	_content.add_child(_button("XEM TỔNG KẾT MÙA",func(): _show("season"),true))


func _shop() -> void:
	_heading("Quà mỗi ngày", "Cửa hàng MVP · Quà miễn phí")
	var card := _widget(_content,{"kind":"reward","title":"Quà hằng ngày","subtitle":"200 tiền\nMỗi ngày một lần","image_path":ROOT+"rewards/daily_gift.tres","action_text":"Nhận quà miễn phí"})
	card.action_requested.connect(func(_id: String):
		_feedback("daily_gift",card)
		card.configure({"action_text":"Đã nhận · Hẹn ngày mai","disabled":true})
	)
	_widget(_content,{"kind":"reward","title":"Tăng trưởng đội đua","subtitle":"Hoàn thành nhiệm vụ để nhận thêm tiền nâng cấp.","image_path":ROOT+"rewards/money_bag.tres","action_text":"Xem nhiệm vụ"}).action_requested.connect(func(_id: String): _show("missions"))
	_content.add_child(_label("Không có giao dịch tiền thật trong bộ xem asset này.",12,MUTED))


func _result() -> void:
	_heading("Kết quả cuộc đua", "Harbor Oval · Chặng 1/5")
	var podium := _box(_content,"graphite")
	podium.add_child(_image("rewards/semi_pro_cup.tres",Vector2(110,115)))
	var title := _label("VỊ TRÍ 2 / 8",26,Color("ffab44"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	podium.add_child(title)
	var rewards := _label("+100 tiền  ·  +8 điểm mùa",16,Color("fff7e8"))
	rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	podium.add_child(rewards)
	var table := _box(_content)
	for i in range(8):
		var row := _row(table)
		row.add_child(_label("%02d"%(i+1),14,ORANGE if i==1 else MUTED))
		var name := _label(["Kiên","An · Bạn","Lan","Minh","Nam","Oanh","Phúc","Quân"][i],14)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name)
		row.add_child(_label("01:%02d.%d"%[12+i,i%10],14))
	_content.add_child(_button("TIẾP TỤC",func(): _show("race")))
	_content.add_child(_label("Bảng và số liệu trên là dữ liệu duyệt UI.",12,MUTED))


func _offline() -> void:
	_heading("Chào mừng trở lại!", "Thu nhập cơ sở trong lúc bạn vắng mặt")
	var box := _box(_content)
	box.add_child(_image("rewards/money_bag.tres",Vector2(170,190)))
	for text: String in ["Thời gian tính: 30 phút","Thu nhập: 8 tiền/giây","Hệ số offline: 50% · Tối đa 2 giờ"]:
		box.add_child(_label(text,14,MUTED))
	var amount := _label("+7.200",36,ORANGE)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(amount)
	box.add_child(_label("Thu nhập cơ sở · Không chạy giải khi vắng mặt",12,MUTED))
	box.add_child(_button("TIẾP TỤC",func():
		_cue("reward")
		_show("race")
	))


func _missions() -> void:
	_heading("Nhiệm vụ", "Phần thưởng cho những bước đầu xây đội")
	for i in range(3):
		var title: String = ["Hoàn thành cuộc đua đầu","Mua ba cấp nâng cấp","Hoàn tất mùa đầu tiên"][i]
		var card := _widget(_content,{"kind":"mission","title":title,"subtitle":["1/1 · Thưởng 100 tiền","2/3 · Thưởng 150 tiền","0/1 · Thưởng 300 tiền"][i],"image_path":ROOT+"icons/vector_dark/mission.svg","progress":[100,66.7,0][i],"action_text":"Nhận thưởng" if i==0 else "Đang thực hiện","disabled":i>0})
		card.action_requested.connect(func(_id: String):
			_feedback("mission_complete",card)
			card.configure({"action_text":"Đã nhận","disabled":true})
		)
	_content.add_child(_button("QUAY VỀ ĐƯỜNG ĐUA",func(): _show("race"),true))


func _settings() -> void:
	_heading("Cài đặt", "Âm thanh và trải nghiệm")
	for data: Array in [["music","Âm nhạc"],["sound","Hiệu ứng âm thanh"],["vibration","Rung"],["motion","Giảm chuyển động"]]:
		var box := _box(_content)
		var row := _row(box)
		row.add_child(_image("icons/vector_dark/"+str(data[0])+".svg",Vector2(28,36)))
		var text := _label(data[1],15)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var toggle := TextureButton.new()
		toggle.custom_minimum_size = Vector2(64,44)
		toggle.texture_normal = load(ROOT+"ui/toggle_off.svg")
		toggle.texture_pressed = load(ROOT+"ui/toggle_on.svg")
		toggle.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		toggle.ignore_texture_size = true
		toggle.toggle_mode = true
		var id: String = data[0]
		toggle.toggled.connect(func(on: bool):
			if id=="music":
				_audio.stop_all()
				if on: _audio.play("music_workshop_loop")
			elif id=="sound":
				_sound_enabled = on
				if on: _cue("ui_confirm")
			elif id=="motion":
				_animate = not on
		)
		row.add_child(toggle)
	_widget(_content,{"kind":"resource","title":"Tiếng Việt","subtitle":"Workshop GP · Asset pack 1.0","image_path":ROOT+"icons/vector_dark/info.svg","action_text":""})
	_content.add_child(_button("THƯ VIỆN ASSET & ÂM THANH",func(): _show("library"),true))
	_content.add_child(_label("Các công tắc trong gallery chỉ tác động phiên xem thử.",12,MUTED))


func _season() -> void:
	_heading("Thăng hạng!", "Hoàn tất mùa giải tập sự")
	var box := _box(_content,"graphite")
	box.add_child(_image("rewards/pro_cup.tres",Vector2(200,210)))
	var text := _label("38 / 50 ĐIỂM",30,Color("ffab44"))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(text)
	var row := _row(_content)
	for id: String in ["rookie","semi_pro","pro"]:
		var badge := _image("badges/"+id+".svg",Vector2(75,80))
		badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(badge)
	_widget(_content,{"kind":"reward","title":"Mở giải Bán chuyên","subtitle":"Thưởng hoàn tất mùa: 150 tiền\nBa cấp giải · Ba huy hiệu riêng","image_path":ROOT+"badges/semi_pro.svg","action_text":"Bắt đầu mùa mới"}).action_requested.connect(func(_id: String):
		_cue("promotion")
		_show("race")
	)


func _onboarding() -> void:
	_heading("Chào chủ đội!", "Xây đội đua Workshop GP của bạn")
	var box := _box(_content)
	box.add_child(_image("portraits/driver_an.tres",Vector2(210,230)))
	box.add_child(_label("Nâng xe. Phát triển tay đua. Chinh phục giải đấu.",20))
	box.add_child(_label("Cuộc đua diễn ra tự động. Hãy nâng Động cơ để xe nhanh hơn trên đoạn thẳng.",14,MUTED))
	var row := _row(box)
	for i in range(6):
		var dot := ColorRect.new()
		dot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dot.custom_minimum_size.y = 5
		dot.color = ORANGE if i==0 else Color("cdbfae")
		row.add_child(dot)
	box.add_child(_button("NÂNG ĐỘNG CƠ",func(): _show("garage")))
	box.add_child(_button("Bỏ qua hướng dẫn",func(): _show("race"),true))


func _library() -> void:
	_heading("Thư viện asset", "Nhấn hiệu ứng hoặc âm thanh để xem/nghe thử.")
	var fx_box := _box(_content)
	fx_box.add_child(_label("HIỆU ỨNG · 6 ANIMATION",15))
	for id: String in ["upgrade","reward_burst","confetti","finish_flash","coin_spin","player_ring"]:
		fx_box.add_child(_button(id,func(): _play_fx(id,fx_box),true))
	var row := _row(_content)
	for color: String in ["orange","graphite","white","blue","red","yellow","teal","purple"]:
		var car := _image("cars/"+color+".tres",Vector2(28,54))
		car.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(car)
	var audio_box := _box(_content)
	audio_box.add_child(_label("ÂM THANH · 21 CUE",15))
	audio_box.add_child(_button("DỪNG MỌI ÂM THANH",func(): _audio.stop_all()))
	var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"audio/catalog.json"))
	for entry: Dictionary in catalog:
		var cue: String = str(entry.path).get_file().get_basename()
		audio_box.add_child(_button(cue+" · %.2fs"%float(entry.duration),func():
			_audio.stop_all()
			_audio.play(cue)
		,true))
	var prop_grid := GridContainer.new()
	prop_grid.columns = 4
	_content.add_child(prop_grid)
	for prop: String in ["garage","grandstand","pine","broadleaf","barrier","tyre_stack","tool_cabinet","light_pole"]:
		var picture := _image("props/"+prop+".tres",Vector2(58,80))
		picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		prop_grid.add_child(picture)


func _cue(id: String) -> void:
	if _sound_enabled:
		_audio.play(id)


func _feedback(cue: String, target: Control) -> void:
	_cue(cue)
	_play_fx("upgrade" if cue=="upgrade" else "reward_burst",target)


func _play_fx(id: String, target: Control) -> void:
	var scene := load(ROOT+"vfx/"+id+".tscn") as PackedScene
	var fx := scene.instantiate() as AnimatedSprite2D
	_root.add_child(fx)
	fx.position = target.get_global_rect().get_center()
	fx.scale = Vector2(.65,.65)
	fx.z_index = 30
	if id in ["coin_spin","player_ring"]:
		get_tree().create_timer(2).timeout.connect(func():
			if is_instance_valid(fx): fx.queue_free()
		)


func _render_board() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1328,1550)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var board := ColorRect.new()
	board.size = Vector2(1328,1550)
	board.color = INK
	viewport.add_child(board)
	var title := _label("WORKSHOP GP  /  2D MVP ASSET PACK",30,Color("fff7e8"))
	title.position = Vector2(24,16)
	title.size.x = 1250
	board.add_child(title)
	var subtitle := _label("3 tracks · 3 drivers · 8 cars · UI components · VFX · 21 audio cues",18,Color("ffab44"))
	subtitle.position = Vector2(24,58)
	subtitle.size.x = 1250
	board.add_child(subtitle)
	var ids := ["race","drivers","garage","league","shop","result","offline","season"]
	for i in range(ids.size()):
		var x := 24+(i%4)*326
		var y := 108+(i/4)*714
		var caption := _label(TITLES[SCREENS.find(ids[i])],18,Color("fff7e8"))
		caption.position = Vector2(x,y)
		caption.size.x = 304
		board.add_child(caption)
		var picture := TextureRect.new()
		picture.texture = ImageTexture.create_from_image(Image.load_from_file(_capture_dir.path_join(ids[i]+".png")))
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.position = Vector2(x,y+30)
		picture.size = Vector2(304,658)
		board.add_child(picture)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(_board_path)
	if error != OK: push_error("Board capture failed")
	viewport.queue_free()


func _board_text(parent: Node, value: String, at: Vector2, width: float = 1260, point_size: int = 18) -> void:
	var text := _label(value,point_size,Color("fff7e8"))
	text.position = at
	text.size.x = width
	parent.add_child(text)


func _board_art(parent: Node, texture: Texture2D, at: Vector2, extent: Vector2) -> void:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.position = at
	picture.size = extent
	parent.add_child(picture)


func _render_asset_board() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1328,1830)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var board := ColorRect.new()
	board.size = Vector2(viewport.size)
	board.color = INK
	viewport.add_child(board)
	_board_text(board,"WORKSHOP GP  /  ASSET CATALOG 1.0",Vector2(24,16),1180,30)
	_board_text(board,"Original 2D art · transparent sprites · editable vector UI · Godot resources",Vector2(24,58),1200,18)
	_board_art(board,load(ROOT+"branding/app_icon.svg"),Vector2(1240,12),Vector2(64,64))
	for i in range(3):
		var texture: String = ["workshop_oval","pine_circuit","city_technical"][i]
		_board_text(board,["HARBOR OVAL","PINE CIRCUIT","CITY TECHNICAL"][i],Vector2(24+i*436,98),416,18)
		_board_art(board,load(ROOT+"textures/"+texture+".png"),Vector2(24+i*436,128),Vector2(408,272))
	_board_text(board,"3 DRIVERS",Vector2(24,424))
	for i in range(3):
		var id: String = ["an","binh","chi"][i]
		_board_art(board,load(ROOT+"portraits/driver_"+id+".tres"),Vector2(24+i*174,462),Vector2(154,170))
		_board_text(board,["An","Bình","Chi"][i],Vector2(80+i*174,636),120,16)
	_board_text(board,"8 CAR COLORS",Vector2(586,424),700)
	for i in range(8):
		var id: String = ["orange","graphite","white","blue","red","yellow","teal","purple"][i]
		_board_art(board,load(ROOT+"cars/"+id+".tres"),Vector2(586+i*89,475),Vector2(70,140))
	_board_text(board,"LEAGUE TROPHIES & REWARDS",Vector2(24,686))
	for i in range(8):
		var id: String = ["rookie_cup","semi_pro_cup","pro_cup","daily_gift","toolbox","money_bag","finish_flags","venue_model"][i]
		_board_art(board,load(ROOT+"rewards/"+id+".tres"),Vector2(24+i*162,724),Vector2(144,144))
	_board_text(board,"8 MODULAR WORKSHOP PROPS",Vector2(24,900))
	for i in range(8):
		var id: String = ["garage","grandstand","pine","broadleaf","barrier","tyre_stack","tool_cabinet","light_pole"][i]
		_board_art(board,load(ROOT+"props/"+id+".tres"),Vector2(24+i*162,940),Vector2(144,132))
	_board_text(board,"12 PRIMARY ICONS + 40 UTILITY ICONS (LIGHT / DARK)",Vector2(24,1108))
	for i in range(12):
		var id: String = ["coins","gem","pace","overtaking","defense","car_control","team","gear","driver","league","events","shop"][i]
		_board_art(board,load(ROOT+"icons/"+id+".tres"),Vector2(24+i*107,1148),Vector2(78,78))
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"asset_catalog.json"))
	for i in range(catalog.utility_icons.size()):
		_board_art(board,load(ROOT+str(catalog.utility_icons[i])),Vector2(30+(i%10)*128,1254+(i/10)*64),Vector2(48,48))
	_board_text(board,"6 ANIMATED EFFECTS / 74 FRAMES",Vector2(24,1542))
	for i in range(6):
		var id: String = ["upgrade","reward_burst","confetti","finish_flash","coin_spin","player_ring"][i]
		var frames := load(ROOT+"vfx/"+id+".tres") as SpriteFrames
		_board_art(board,frames.get_frame_texture("default",6),Vector2(48+i*210,1580),Vector2(128,128))
		_board_text(board,id,Vector2(32+i*210,1710),198,16)
	_board_text(board,"21 AUDIO CUES  /  17 SFX + 2 ENGINE LOOPS + 2 MUSIC LOOPS",Vector2(24,1770),1280,19)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(_asset_board_path)
	if error!=OK: push_error("Asset catalog board capture failed")
	viewport.queue_free()
