extends Control

const BigNumber = preload("res://core/math/big_number.gd")
## UI prototype: UI-01 Đua, UI-02 Tay đua (tối giản), UI-03 Garage, UI-04 Giải đấu,
## UI-05 Kết quả, UI-06 Thu nhập vắng mặt, UI-07 quà ngày. Dựng hoàn toàn bằng code.

## Bảng màu theo gói asset Racing UI HD (xanh UI, cam hành động, vàng thưởng, lá nhận; xem HdUi).
## Tên hằng giữ nguyên để phần code bên dưới không phải đổi: C_CYAN là màu nhấn (cam), C_PANEL là màu nền thẻ.
const ROOT := "res://assets/workshop_gp/"
const RACE_SPEED := 1.0  # thời gian đua = giờ thật; độ nhanh của xe nằm ở sim.json traffic.speed_scale
const HD := "res://assets/racing_ui_hd/"
const C_BG := Color("dcebff")
const C_PANEL := HdUi.C_PANEL
const C_PANEL_HI := HdUi.C_PANEL_HI
const C_CYAN := HdUi.C_ORANGE
const C_GOLD := HdUi.C_GOLD
const C_TEXT := HdUi.C_TEXT
const C_MUTED := HdUi.C_MUTED
const C_RED := HdUi.C_RED
const C_GREEN := HdUi.C_GREEN

enum Tab { RACE, BAG, TEAM, LEAGUE, SHOP }
const TAB_NAMES := ["Đua", "Túi", "Đội", "Giải", "Shop"]
## Icon thanh dưới (gói racing_ui_hd/icons): Đua = cờ, Túi = dụng cụ, Đội = nhóm, Giải = cúp, Shop = cửa hàng.
const TAB_ICONS := ["flag", "tools", "staff", "trophy", "shop"]
## Icon cho từng loại nâng cấp (khóa trùng `kind` của hàng nâng cấp), đều thuộc gói racing_ui_hd/icons.
const ROW_ICONS := {
	"engine": "icons/energy.png",
	"tyre": "icons/gear.png",
	"chassis": "icons/crane.png",
	"gearbox": "icons/research.png",
	"ticket": "icons/cash.png",
	"celebration": "icons/crown.png",
	"parking": "icons/garage.png",
	"grandstands": "icons/seats.png",
}

var _pages: Array = []
var _nav: Array = []
var _rows: Array = []
var _tab: int = Tab.RACE

var _pages_root: Control
var _coin_label: Label
var _income_label: Label
var _gem_label: Label
var _header_avatar: Control
var _progress_label: Label
var _status_label: Label
var _save_err_box: PanelContainer
var _snapshot_label: Label       # nhắc đội đang đua dùng snapshot lúc xuất phát
var _view_sim: TrafficSim = null # sim mà RaceView đang hiển thị
var _race_view: RaceView
var _race_block: VBoxContainer   # khung đua + tiến độ + banner, ghim ở Đua/Túi/Đội
const RACE_HEIGHT := 250.0
const SCENERY_H := 190.0   # chiều cao dải ảnh sân đua phía sau thanh tài nguyên
var _drivers_box: VBoxContainer
var _roster: DriverRosterPage
var _league_box: VBoxContainer
var _shop_box: VBoxContainer
var _shop_content: VBoxContainer
var _toast: Label
var _overlay: Control
var _result_panel: Control          # bảng tổng kết lượt, chỉ phủ lên vùng đua (không phải popup toàn màn hình)
var _result_box: VBoxContainer
var _result_bar: ProgressBar
var _result_timer: float = 0.0      # giây còn lại trước khi bảng tổng kết tự tắt
const RESULT_SHOW_SEC := 2.0
var _overlay_box: VBoxContainer

var _audio: Node = null  # components/workshop_audio.gd
var _music_player: AudioStreamPlayer = null
var _music_on: bool = true
var _sfx_on: bool = true
var _team_sub: int = 0
var _team_sub_buttons: Array = []
var _team_drivers_wrap: VBoxContainer
var _garage: GaragePage
var _gear: GearPage
var _catalog_buttons: Array = []
var _expansion_button: Button
var _expansion_status: Label

var _row_timer: float = 0.0
var _last_count: int = -1        # số countdown vừa phát tiếng
var _seen_result: int = 0        # results_serial đã hiển thị

# CLI hỗ trợ kiểm thử: godot --path . -- --shot=prefix --auto-race --fast
# (vòng lặp đua tự chạy; --auto-race chụp chuỗi ảnh: countdown, đang đua, kết quả, tab)
var _shot_prefix: String = ""
var _cli_garage: String = ""
var _auto_race: bool = false
var _fast_forced: bool = false
var _dev_time: float = 0.0
var _shots_done: Dictionary = {}


## Gameplay được dựng phía sau màn loading (Design/09 §4): `_ready` chỉ chuẩn bị UI, `is_prepared`
## báo layout/vẽ đã xong, còn input/race/nhạc/panel chờ chỉ bật khi loading gọi `activate()`.
var is_prepared: bool = false
var _active: bool = false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot_prefix = a.substr(7)
		elif a == "--auto-race":
			_auto_race = true
		elif a == "--fast":
			_fast_forced = true
		elif a.begins_with("--tab="):
			_tab = int(a.substr(6))
		elif a.begins_with("--garage="):
			_cli_garage = a.substr(9)  # ví dụ: 1 | 2,draft=red:lightning | 0,collection | 1,part=tyre,mult=10
			_tab = Tab.TEAM
	var standalone := get_tree().current_scene == self  # chạy riêng scene này (F6): không có loading
	if standalone:
		_standalone_boot()
	theme = HdUi.make_theme(load(ROOT + "theme.tres") as Theme)
	_audio = (load(ROOT + "components/workshop_audio.gd") as GDScript).new()
	add_child(_audio)
	_build_ui()
	resized.connect(_fit_overlay)
	GameState.changed.connect(_refresh)
	_select_tab(_tab)
	_refresh()
	if _cli_garage != "":
		_select_team_sub(1)
		_garage.debug_show(_cli_garage)
	# Chờ một lượt bố trí/vẽ rồi mới báo sẵn sàng.
	await get_tree().process_frame
	await get_tree().process_frame
	is_prepared = true
	if standalone:
		activate()


## Bàn giao từ loading: bật phiên chơi. Gọi đúng một lần.
func activate() -> void:
	if _active:
		return
	_active = true
	GameState.race_started.connect(_on_race_started)
	GameState.race_finished.connect(_on_race_finished)
	_seen_result = GameState.results_serial
	_refresh()
	if GameState.load_error != "":
		_show_toast(GameState.load_error)
	_open_next_overlay()
	_set_music("music_workshop_loop")


## Dev: khởi tạo đồng bộ khi chạy riêng main.tscn, bỏ qua BootFlow.
func _standalone_boot() -> void:
	GameData.reload()
	GameState.init_new_game()
	if "--reset" in OS.get_cmdline_user_args():
		GameState.reset_progress()
	GameState.load_game()
	GameState.settle_offline()
	GameState.activate()


# ---------------------------------------------------------------- âm thanh / hiệu ứng

func _sfx(cue: String) -> void:
	if _audio != null and _shot_prefix == "":
		_audio.sfx_enabled = _sfx_on
		_audio.play(cue)


## Nhạc nền đang phát; đổi bản nhạc khi vào/ra đua.
func _set_music(cue: String) -> void:
	if is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.queue_free()
		_music_player = null
	if not _music_on or _audio == null or _shot_prefix != "":
		return
	_audio.music_enabled = true
	_music_player = _audio.play(cue)


## Phát một hiệu ứng khung hình một lần (tự giải phóng) tại `pos` trong hệ toạ độ của Main.
func _spawn_fx(fx: String, pos: Vector2, fx_scale: float = 1.0) -> void:
	var node := (load(ROOT + "vfx/" + fx + ".tscn") as PackedScene).instantiate() as Node2D
	node.position = pos
	node.scale = Vector2.ONE * fx_scale
	node.z_index = 100
	add_child(node)


# ---------------------------------------------------------------- helpers

func _style(bg: Color, radius: int = 12, border: Color = Color(0, 0, 0, 0), bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _label(text: String, size: int = 14, color: Color = C_TEXT, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


## Nút dựng bằng code. primary = cam (hành động chính); mặc định xanh; kind ghi đè: "cancel" xám, "claim" lá.
func _button(text: String, primary: bool = false, min_h: float = 48.0, kind: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, maxf(min_h, 44.0))
	b.add_theme_font_size_override("font_size", 16 if primary else 14)
	if kind == "":
		kind = "race" if primary else "upgrade"
	HdUi.style_button(b, kind)
	b.pressed.connect(func() -> void: _sfx("ui_click"))
	return b


func _tex(path: String) -> Texture2D:
	return load(ROOT + path) as Texture2D


## Ảnh vuông/đứng đặt vào container, giữ tỉ lệ.
func _icon(path: String, extent: Vector2 = Vector2(32, 32)) -> TextureRect:
	var t := TextureRect.new()
	t.texture = _tex(path)
	t.custom_minimum_size = extent
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t


func _toggle(text: String, on: bool, cb: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = on
	c.add_theme_font_size_override("font_size", 13)
	# Style/icon công tắc và màu chữ lấy từ theme HdUi; chỉ cần nút cao đủ ngón tay.
	c.custom_minimum_size = Vector2(0, 44)
	c.toggled.connect(cb)
	return c


func _card(parent: Control) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # kiểu panel lấy từ theme HdUi
	pc.mouse_filter = Control.MOUSE_FILTER_PASS  # để kéo cuộn xuyên qua thẻ
	parent.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	return v


func _clear(node: Node) -> void:
	for ch in node.get_children():
		node.remove_child(ch)
		ch.queue_free()


func _show_toast(msg: String) -> void:
	_toast.text = msg
	_toast.show()
	await get_tree().create_timer(3.0).timeout
	_toast.hide()


# ---------------------------------------------------------------- dựng UI

func _build_ui() -> void:
	# Nền: nền xanh nhạt; ảnh sân đua chỉ nằm ở dải trên cùng (sau thanh tài nguyên) rồi mờ dần vào nền,
	# để khung đua và bảng nâng cấp không che mất sân (art direction: panel xanh-trắng, tránh che sân đua).
	var sky := ColorRect.new()
	sky.color = C_BG
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	var scenery := TextureRect.new()
	scenery.texture = HdUi.scaled("backgrounds/racetrack_background.png", 0.6)
	scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scenery.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scenery.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scenery.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scenery.offset_bottom = SCENERY_H
	add_child(scenery)
	var fade := TextureRect.new()
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	grad.colors = PackedColorArray([Color(C_BG, 0.0), Color(C_BG, 0.0), C_BG])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 128
	fade.texture = gt
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_TOP_WIDE)
	fade.offset_bottom = SCENERY_H
	add_child(fade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	# Thanh tài nguyên: avatar | tiền (+ thu nhập) | gem | cài đặt
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)
	_header_avatar = HdUi.icon("icons/avatar.png", Vector2(52, 52))
	_header_avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(_header_avatar)
	var money := VBoxContainer.new()
	money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money.add_theme_constant_override("separation", 1)
	_coin_label = _hud_label(20)
	money.add_child(_hud_bar("icons/cash.png", _coin_label, 46.0))
	_income_label = _label("", 11, Color.WHITE)
	_income_label.add_theme_color_override("font_outline_color", HdUi.C_OUTLINE)
	_income_label.add_theme_constant_override("outline_size", 4)
	_income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money.add_child(_income_label)
	top.add_child(money)
	var gems := VBoxContainer.new()
	gems.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gem_label = _hud_label(20)
	gems.add_child(_hud_bar("icons/gem.png", _gem_label, 46.0))
	top.add_child(gems)
	var settings := _button("", false, 44, "menu")
	settings.name = "SettingsButton"
	settings.custom_minimum_size = Vector2(48, 48)
	settings.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	settings.icon = HdUi.scaled("icons/gear.png", 0.16)
	settings.expand_icon = true
	settings.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	settings.add_theme_constant_override("icon_max_width", 30)
	settings.tooltip_text = "Cài đặt"
	settings.accessibility_name = "Cài đặt"
	settings.pressed.connect(_show_settings)
	top.add_child(settings)

	_toast = _label("", 12, C_RED, true)
	_toast.hide()
	root.add_child(_toast)

	_pages_root = Control.new()
	_pages_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pages_root.clip_contents = true
	root.add_child(_pages_root)

	_build_race_page()
	_build_bag_page()
	_build_team_page()
	_build_league_page()
	_build_shop_page()

	# Thanh dưới: nút tứ giác nghiêng xanh (button_nav), icon lớn nhô lên trên mép nút, nhãn trắng viền ở đáy. Tab đang chọn = cam (button_race).
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 0)
	root.add_child(nav)
	for i in TAB_NAMES.size():
		var item := Control.new()
		item.custom_minimum_size = Vector2(0, 72)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(item)
		var b := _button("", false, 44.0, "tab")
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.offset_top = 17.0   # cao đúng 55 px = chiều cao tự nhiên của nền nút
		b.offset_left = -6.0  # rộng hơn ô một chút: các nút nghiêng khớp vào nhau như mẫu
		b.offset_right = 6.0
		b.accessibility_name = TAB_NAMES[i]
		b.pressed.connect(_select_tab.bind(i))
		item.add_child(b)
		var ic := HdUi.icon("icons/%s.png" % TAB_ICONS[i], Vector2(44, 44))
		ic.set_anchors_preset(Control.PRESET_CENTER_TOP)
		ic.offset_left = -22.0
		ic.offset_right = 22.0
		ic.offset_top = 0.0
		ic.offset_bottom = 44.0
		item.add_child(ic)
		var lab := _label(TAB_NAMES[i], 16, Color.WHITE)
		lab.add_theme_color_override("font_outline_color", HdUi.C_OUTLINE)
		lab.add_theme_constant_override("outline_size", 7)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		lab.offset_top = -33.0
		lab.offset_bottom = -10.0
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(lab)
		_nav.append(b)

	_build_overlay()


## Viền sáng quanh chữ đậm để đọc được khi nằm trên ảnh nền sân đua.
func _halo(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.95))
	l.add_theme_constant_override("outline_size", 5)


## Nhãn trong thanh tài nguyên: chữ trắng đậm có viền, căn giữa.
func _hud_label(size: int) -> Label:
	var l := _label("", size, Color.WHITE)
	l.add_theme_color_override("font_outline_color", HdUi.C_OUTLINE)
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	return l


## Thanh tài nguyên dạng viên thuốc xanh đậm, icon lớn đè lên mép trái.
func _hud_bar(icon_rel: String, label: Label, h: float) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, h)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_FULL_RECT)
	pc.offset_left = 14.0
	pc.offset_top = 3.0
	pc.offset_bottom = -3.0
	pc.add_theme_stylebox_override("panel", HdUi.hud_bar())
	pc.add_child(label)
	wrap.add_child(pc)
	var ic := HdUi.icon(icon_rel, Vector2(h, h))
	ic.position = Vector2(-4, 0)
	ic.size = Vector2(h, h)
	wrap.add_child(ic)
	return wrap


## Trang Đua không cuộn: khung đua co giãn, lưới nâng cấp cố định bên dưới.
func _make_fixed_page() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 6)
	_pages_root.add_child(v)
	_pages.append(v)
	return v


func _make_page() -> VBoxContainer:
	var sc := preload("res://ui/touch_scroll.gd").new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_pages_root.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)
	_pages.append(sc)
	return v


## Khung đua ghim cố định phía trên vùng nội dung ở các tab Đua/Túi/Đội (cùng kích thước), ẩn ở Giải/Shop.
## Trang Đua chỉ còn lưới nâng cấp (cuộn được khi màn thấp).
func _build_race_page() -> void:
	var v := _make_page()
	_race_block = VBoxContainer.new()
	_race_block.add_theme_constant_override("separation", 6)
	var host := _pages_root.get_parent()
	host.add_child(_race_block)
	host.move_child(_race_block, _pages_root.get_index())
	_build_race_block(_race_block)
	_build_upgrade_grid(v)


func _build_race_block(v: VBoxContainer) -> void:
	# Dải chặng: viên thuốc xanh đậm (cùng kiểu thanh tài nguyên) + nút Lịch.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var stage_pill := PanelContainer.new()
	stage_pill.custom_minimum_size = Vector2(0, 44)
	stage_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_pill.add_theme_stylebox_override("panel", HdUi.hud_bar())
	var pill_row := HBoxContainer.new()
	pill_row.add_theme_constant_override("separation", 6)
	pill_row.add_child(HdUi.icon("icons/flag.png", Vector2(22, 22)))
	_progress_label = _hud_label(13)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_progress_label.add_theme_constant_override("outline_size", 3)
	pill_row.add_child(_progress_label)
	stage_pill.add_child(pill_row)
	head.add_child(stage_pill)
	var sched := _button("Lịch", true, 44.0)
	sched.custom_minimum_size = Vector2(84, 44)
	sched.icon = HdUi.scaled("icons/event.png", 0.1)
	sched.expand_icon = true
	sched.add_theme_constant_override("icon_max_width", 24)
	sched.add_theme_constant_override("h_separation", 4)
	sched.pressed.connect(_select_tab.bind(Tab.LEAGUE))
	head.add_child(sched)
	v.add_child(head)

	# Khung đua đặt trong panel xanh-trắng có viền, giống bức tranh có khung.
	var frame := PanelContainer.new()
	var frame_sb := HdUi.panel().duplicate() as StyleBoxTexture
	frame_sb.content_margin_left = 8.0
	frame_sb.content_margin_right = 8.0
	frame_sb.content_margin_top = 8.0
	frame_sb.content_margin_bottom = 11.0
	frame.add_theme_stylebox_override("panel", frame_sb)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(frame)
	_race_view = RaceView.new()
	_race_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_race_view.size_flags_vertical = Control.SIZE_FILL
	_race_view.custom_minimum_size = Vector2(0, RACE_HEIGHT)
	_race_view.clip_contents = true
	frame.add_child(_race_view)
	_race_view.set_track(GameState.PROTOTYPE_TRACK)
	_build_race_result_panel()
	# Gợi ý đường đua nằm trong tooltip của dòng tiến độ (không còn chỗ cho dòng chữ riêng).
	var track: Dictionary = GameData.track(GameState.PROTOTYPE_TRACK)

	_status_label = _label("", 14, C_TEXT)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.clip_text = true
	v.add_child(_status_label)

	_snapshot_label = _label("", 12, C_MUTED, true)
	_snapshot_label.hide()

	# Lỗi lưu khi chốt kết quả: giữ giao dịch đang chờ, cho thử lại (Design/10 §5).
	_save_err_box = PanelContainer.new()
	var eh := HBoxContainer.new()
	eh.add_theme_constant_override("separation", 8)
	_save_err_box.add_child(eh)
	var el := _label("Không lưu được kết quả chặng. Chưa có lượt mới cho tới khi lưu xong.", 12, C_RED, true)
	eh.add_child(el)
	var retry := _button("Thử lại", true, 44.0)
	retry.custom_minimum_size = Vector2(88, 44)
	retry.pressed.connect(func() -> void: GameState.retry_save())
	eh.add_child(retry)
	_save_err_box.hide()
	v.add_child(_save_err_box)


func _build_upgrade_grid(v: VBoxContainer) -> void:
	# Hai nhóm một cột: XE ĐUA (chỉ số xe) và DOANH THU. Mỗi hàng: icon lớn, tên + chỉ số + thanh cấp, nút giá cam.
	v.add_theme_constant_override("separation", 8)
	_section_head(v, "XE ĐUA", "icons/car_red.png")
	for kind: String in Balance.PARTS:
		_add_tile(v, kind)
	_section_head(v, "DOANH THU", "icons/cash.png")
	for kind: String in Balance.REVENUE:
		_add_tile(v, kind)


## Tiêu đề nhóm: viên thuốc xanh đậm với icon và chữ trắng đậm.
func _section_head(parent: Control, text: String, icon_rel: String) -> void:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(0, 40)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.mouse_filter = Control.MOUSE_FILTER_PASS
	pc.add_theme_stylebox_override("panel", HdUi.hud_bar())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(HdUi.icon(icon_rel, Vector2(28, 28)))
	var l := _hud_label(15)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.text = text
	h.add_child(l)
	pc.add_child(h)
	parent.add_child(pc)


func _build_team_page() -> void:
	var page := _make_page()
	# Đội có hai mục con: Tay đua / Garage (Design/15 §3).
	var sub := HBoxContainer.new()
	sub.add_theme_constant_override("separation", 8)
	page.add_child(sub)
	_team_sub_buttons = [_button("Tay đua", false, 44.0), _button("Garage", false, 44.0)]
	for i in _team_sub_buttons.size():
		var sb: Button = _team_sub_buttons[i]
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.pressed.connect(_select_team_sub.bind(i))
		sub.add_child(sb)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	page.add_child(v)
	_team_drivers_wrap = v
	_garage = GaragePage.new()
	_garage.sfx.connect(_sfx)
	_garage.notice.connect(_show_toast)
	page.add_child(_garage)
	_drivers_box = v
	# Trang Tay đua dựng lại theo mockup (ui/driver_roster_page.gd); bảng chi tiết phủ vùng nội dung, không che khung đua.
	_roster = DriverRosterPage.new()
	_roster.sfx.connect(_sfx)
	_roster.notice.connect(_show_toast)
	_roster.open_requested.connect(_on_driver_open)
	_roster.info_requested.connect(_show_driver_info)
	v.add_child(_roster)
	_pages_root.add_child(_roster.sheet)
	_select_team_sub(0)


func _select_team_sub(i: int) -> void:
	_team_sub = i
	if _roster != null:
		_roster.close_sheet()
	_team_drivers_wrap.visible = i == 0
	_garage.visible = i == 1
	for j in _team_sub_buttons.size():
		var b: Button = _team_sub_buttons[j]
		var on := j == i
		HdUi.style_button(b, "upgrade" if on else "cancel")
	if i == 1:
		_garage.refresh()


func _build_bag_page() -> void:
	var v := _make_page()  # cả trang Túi cuộn (khung đua ghim chiếm chỗ phía trên)
	_gear = GearPage.new()
	_gear.open_requested.connect(_on_gear_open)
	_gear.info_requested.connect(_show_gear_info)
	_gear.upgrade_requested.connect(_on_gear_upgrade)
	v.add_child(_gear)


## Bảng Drop Information của gói: hai hàng xác suất bậc, đóng không mua gì.
func _show_gear_info(pack_id: String) -> void:
	var pack := GameData.gear_pack(pack_id)
	if pack.is_empty():
		return
	_sfx("ui_click")
	_begin_overlay()
	_overlay_box.add_child(_label("Drop Information · %s" % pack["name"], 18, C_TEXT, true))
	var tiers: Dictionary = pack["tiers"]
	var keys: Array = tiers.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return float(tiers[a]) > float(tiers[b]))
	for k: String in keys:
		var row := _label("%s: %s%%" % [String(k).capitalize(), str(snappedf(float(tiers[k]), 0.01))], 15)
		_overlay_box.add_child(row)
	_overlay_box.add_child(_label("Một coupon = một lượt mở. Có đủ coupon đúng loại thì dùng coupon trước gem.", 12, C_MUTED, true))
	var close := _button("Đóng", false)
	close.pressed.connect(func() -> void: _overlay.hide())
	_overlay_box.add_child(close)


func _on_gear_open(pack_id: String, count: int) -> void:
	var out := GameState.open_gear_pack(pack_id, count)
	if out.is_empty():
		_show_toast("Chưa thể mở gói. Kiểm tra gem/coupon hoặc trạng thái lưu.")
		_gear.refresh()
		return
	_sfx("daily_gift")
	_show_gear_result(out)
	_gear.refresh()


func _show_gear_result(out: Dictionary) -> void:
	_begin_overlay()
	_overlay_box.add_child(_label("Kết quả mở gói", 18))
	var pay: Dictionary = out["payment"]
	var paid := "%d coupon" % int(pay["amount"]) if pay["method"] == "coupon" else "%d gem" % int(pay["amount"])
	_overlay_box.add_child(_label("Đã dùng " + paid, 12, C_MUTED))
	for e: Dictionary in out["results"]:
		var item := GameData.gear_item(String(e["id"]))
		var line := "%s · %s" % [item["name"], String(item["rarity"]).capitalize()]
		line += "  — Mới" if e["is_new"] else "  — Trùng → +%d mảnh" % int(e["shards"])
		var reward := HBoxContainer.new()
		reward.add_child(ExpansionArt.icon(String(e["id"]), Vector2(48, 48)))
		var reward_text := _label(line, 13, C_GREEN if e["is_new"] else C_TEXT, true)
		reward_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reward.add_child(reward_text)
		_overlay_box.add_child(reward)
	var ok := _button("Xong", true)
	ok.pressed.connect(func() -> void: _overlay.hide())
	_overlay_box.add_child(ok)


## Bảng tỉ lệ gói tay đua: các hàng xác suất bậc và bảo đảm; đóng không mua gì.
func _show_driver_info(pack_id: String) -> void:
	var pack := GameData.driver_pack(pack_id)
	if pack.is_empty():
		return
	_sfx("ui_click")
	_begin_overlay()
	_overlay_box.add_child(_label("Tỉ lệ · %s" % pack["name"], 18, C_TEXT, true))
	var tiers: Dictionary = pack["tiers"]
	var keys: Array = tiers.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return float(tiers[a]) > float(tiers[b]))
	for k: String in keys:
		_overlay_box.add_child(_label("%s: %s%%" % [String(k).capitalize(), str(snappedf(float(tiers[k]), 0.01))], 15))
	_overlay_box.add_child(_label("Bảo đảm: sau %d lượt liên tiếp chưa ra %s thì lượt thứ %d chắc chắn ra bậc này (đếm riêng từng gói)." % [int(pack["pity_draws"]) - 1, String(pack["pity_tier"]).capitalize(), int(pack["pity_draws"])], 12, C_MUTED, true))
	_overlay_box.add_child(_label("Tay đua trùng đổi thành mảnh để nâng cấp. Một coupon = một lượt mở; có đủ coupon đúng loại thì dùng coupon trước gem.", 12, C_MUTED, true))
	var close := _button("Đóng", false)
	close.pressed.connect(func() -> void: _overlay.hide())
	_overlay_box.add_child(close)


func _on_driver_open(pack_id: String, count: int) -> void:
	var out := GameState.open_driver_pack(pack_id, count)
	if out.is_empty():
		_show_toast("Chưa thể mở gói. Kiểm tra gem/coupon hoặc trạng thái lưu.")
		_roster.refresh()
		return
	_sfx("daily_gift")
	_begin_overlay()
	_overlay_box.add_child(_label("Kết quả mở gói", 18))
	var pay: Dictionary = out["payment"]
	var paid := "%d coupon" % int(pay["amount"]) if pay["method"] == "coupon" else "%d gem" % int(pay["amount"])
	_overlay_box.add_child(_label("Đã dùng " + paid, 12, C_MUTED))
	for e: Dictionary in out["results"]:
		var d := GameData.driver(String(e["id"]))
		var tier_name := String(GameData.driver_tier_ids()[int(d["tier"])]).capitalize()
		var line := "%s · %s" % [d["name"], tier_name]
		line += "  — Mới" if e["is_new"] else "  — Trùng → +%d mảnh" % int(e["shards"])
		var reward := HBoxContainer.new()
		reward.add_child(ExpansionArt.icon(String(e["id"]), Vector2(48, 48)))
		var reward_text := _label(line, 13, C_GREEN if e["is_new"] else C_TEXT, true)
		reward_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reward.add_child(reward_text)
		_overlay_box.add_child(reward)
	var ok := _button("Xong", true)
	ok.pressed.connect(func() -> void: _overlay.hide())
	_overlay_box.add_child(ok)
	_roster.refresh()


func _on_gear_upgrade(gear_id: String) -> void:
	if GameState.upgrade_gear(gear_id):
		_sfx("ui_click")
	else:
		_show_toast("Chưa đủ mảnh hoặc không lưu được.")
	_gear.refresh()


func _build_league_page() -> void:
	_league_box = _make_page()


func _build_shop_page() -> void:
	_shop_box = _make_page()
	_shop_content = (load("res://ui/shop_page.gd") as GDScript).new()
	_shop_box.add_child(_shop_content)
	_shop_content.daily_requested.connect(_claim_shop_daily)
	_shop_content.offer_requested.connect(_show_shop_offer)


func _show_settings() -> void:
	_begin_overlay()
	_overlay_box.add_child(_label("Cài đặt", 20))
	var snd := _card(_overlay_box)
	snd.add_child(_label("Âm thanh", 15))
	snd.add_child(_toggle("Nhạc nền", _music_on, func(on: bool) -> void:
		_music_on = on
		_set_music("music_race_loop" if GameState.phase == "racing" else "music_workshop_loop")))
	snd.add_child(_toggle("Hiệu ứng âm thanh", _sfx_on, func(on: bool) -> void:
		_sfx_on = on))
	var close := _button("Đóng", true)
	close.pressed.connect(func() -> void: _overlay.hide())
	_overlay_box.add_child(close)


# ---------------------------------------------------------------- ô nâng cấp

## Một ô nâng cấp gọn: icon + tên/cấp, dòng hiệu ứng ngắn, nút giá. Chi tiết (gợi ý, hoàn vốn) ở tooltip.
func _add_tile(parent: Control, kind: String) -> void:
	var is_rev := kind in Balance.REVENUE
	var pc := PanelContainer.new()
	var st := HdUi.panel().duplicate() as StyleBoxTexture
	st.content_margin_left = 10.0
	st.content_margin_right = 10.0
	st.content_margin_top = 7.0
	st.content_margin_bottom = 10.0
	pc.add_theme_stylebox_override("panel", st)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(pc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	pc.add_child(row)
	if ROW_ICONS.has(kind):
		var ic := ExpansionArt.icon(kind, Vector2(44, 44))
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(ic)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 1)
	row.add_child(info)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	info.add_child(top)
	var name_l := _label("", 15)
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_l)
	var eff_l := _label("", 13, C_GREEN)
	eff_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(eff_l)
	# Thanh cấp: xanh dương cho xe, vàng cho doanh thu.
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.show_percentage = false
	bar.max_value = Balance.max_level()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("8fb0e0")
	bg.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("ffb703") if is_rev else Color("3b82f6")
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(bar)
	var btn := Button.new()
	HdUi.style_button(btn, "amber")
	btn.custom_minimum_size = Vector2(98, 46)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 16)
	btn.icon = HdUi.scaled("icons/cash.png", 0.07)
	btn.expand_icon = true
	btn.add_theme_constant_override("icon_max_width", 20)
	btn.add_theme_constant_override("h_separation", 3)
	btn.pressed.connect(_on_buy.bind(kind))
	btn.pressed.connect(func() -> void: _sfx("ui_click"))
	row.add_child(btn)
	# `short` giữ cho _refresh_rows; ô không có chỗ cho dòng "Thiếu ..." nên để ẩn, nội dung đi vào tooltip.
	var short_l := _label("", 11, C_RED)
	short_l.hide()
	info.add_child(short_l)
	_rows.append({"kind": kind, "name": name_l, "eff": eff_l, "short": short_l, "btn": btn, "tile": pc, "bar": bar})


func _on_buy(kind: String) -> void:
	var btn: Button = null
	for r in _rows:
		if r["kind"] == kind and (r["btn"] as Button).is_visible_in_tree():
			btn = r["btn"]
	if GameState.buy_many(kind, 1):
		_sfx("upgrade")
		if btn != null and _shot_prefix == "":
			_spawn_fx("upgrade", btn.global_position + btn.size * 0.5 - global_position, 0.7)
	else:
		_sfx("ui_error")


func _row_text(kind: String) -> Array:
	var lv: int = GameState.level_of(kind)
	var maxed: bool = lv >= Balance.max_level()
	if kind in Balance.REVENUE:
		var cfg: Dictionary = GameData.economy()["revenue_upgrades"][kind]
		var current: BigNumber = GameState.online_rate()
		var eff := "Tổng thu nhập %s/giây" % Balance.fmt_rate(current)
		if not maxed:
			var next_levels: Dictionary = GameState.levels.duplicate()
			next_levels[kind] = lv + 1
			var next_rate := Pricing.revenue_rate(next_levels, GameState.business_tier)
			var delta := next_rate.subtract_checked(current)
			eff = "%s → %s/giây · +%s/giây" % [Balance.fmt_rate(current), Balance.fmt_rate(next_rate), Balance.fmt_rate(delta)]
			var payback: BigNumber = GameState.cost_of(kind).divide(delta).ceil_number()
			eff += "\nHoàn vốn khoảng %s giây" % payback.format_compact()
		if kind == "grandstands":
			eff += " · %d chỗ" % int(Pricing.revenue_value(kind, lv))
		return ["%s · cấp %d" % [String(cfg["name"]), lv], eff]
	var now: float = GameState.part_stat(kind, lv)
	var stat: String = Balance.PART_STATS[kind]
	var eff := "%s %.1f" % [stat, now]
	if not maxed:
		eff = "%s %.1f → %.1f" % [stat, now, GameState.part_stat(kind, lv + 1)]
	return ["%s · cấp %d" % [Balance.PART_NAMES[kind], lv], eff]


func _refresh_rows() -> void:
	for r in _rows:
		var kind: String = r["kind"]
		var t := _row_text(kind)
		var lv: int = GameState.level_of(kind)
		var maxed: bool = lv >= Balance.max_level()
		var full_name: String = t[0]
		var parts := full_name.split(" · cấp ")
		(r["name"] as Label).text = parts[0]
		(r["bar"] as ProgressBar).value = lv
		# Dòng ngắn trên ô: xe "Speed 46 → 48"; doanh thu "+x/giây" (hết cấp thì giá trị hiện tại).
		var short_eff: String = String(t[1]).split("
")[0]
		if kind in Balance.PARTS:
			short_eff = "%.1f" % GameState.part_stat(kind, lv) if maxed else "%.1f → %.1f" % [GameState.part_stat(kind, lv), GameState.part_stat(kind, lv + 1)]
		if kind in Balance.REVENUE:
			if maxed:
				short_eff = Balance.fmt_rate(GameState.online_rate()) + "/giây"
			else:
				var nl: Dictionary = GameState.levels.duplicate()
				nl[kind] = lv + 1
				var delta := Pricing.revenue_rate(nl, GameState.business_tier).subtract_checked(GameState.online_rate())
				short_eff = "+%s/giây" % Balance.fmt_rate(delta)
		var tip: String = String(t[1])
		if Balance.PART_HINTS.has(kind):
			tip += "
" + String(Balance.PART_HINTS[kind])
		(r["eff"] as Label).text = short_eff
		var btn: Button = r["btn"]
		var cost: BigNumber = GameState.cost_of(kind)
		match GameState.upgrade_state(kind):
			"ok":
				btn.text = Balance.fmt_money(cost)
				btn.disabled = false
			"short":
				btn.text = Balance.fmt_money(cost)
				btn.disabled = true
				tip += "
Thiếu %s" % Balance.fmt_money(cost.subtract_checked(GameState.coins))
			"save_error", "invalid":
				btn.text = "Chờ lưu"
				btn.disabled = true
			"maxed":
				btn.text = "Tối đa"
				btn.disabled = true
		if GameState.applies_next_race(kind):
			tip += "
Áp dụng từ lượt sau"
		tip += "
" + cost.format_scientific() + " tiền"


# ---------------------------------------------------------------- làm mới

func _select_tab(i: int) -> void:
	_tab = i
	_header_avatar.visible = i != Tab.SHOP
	# Khung đua cùng kích thước ở Đua/Túi/Đội; Giải/Shop dành toàn bộ chỗ cho nội dung.
	if _race_block != null:
		_race_block.visible = i == Tab.RACE or i == Tab.BAG or i == Tab.TEAM
	if _roster != null and i != Tab.TEAM:
		_roster.close_sheet()
	if i == Tab.TEAM and _roster != null:
		_roster.refresh()
	if i == Tab.TEAM and _garage != null:
		_garage.refresh()
	if i == Tab.BAG and _gear != null:
		_gear.refresh()
	for k in _pages.size():
		(_pages[k] as Control).visible = (k == i)
	for k in _nav.size():
		var b: Button = _nav[k]
		var on := k == i
		HdUi.style_button(b, "tab_on" if on else "tab")


func _refresh_light() -> void:
	_coin_label.text = Balance.fmt_compact(GameState.coins)
	_income_label.text = "Thu nhập %s/giây" % Balance.fmt_rate(GameState.online_rate())
	_gem_label.text = Balance.fmt_int(GameState.gems)
	_refresh_rows()
	_refresh_catalog()
	if _tab == Tab.TEAM and _team_sub == 1:
		_garage.refresh()
	if _tab == Tab.TEAM and _team_sub == 0 and _roster != null:
		_roster.refresh()
	if _tab == Tab.BAG and _gear != null:
		_gear.refresh()
	_rebuild_shop()


func _refresh() -> void:
	_refresh_light()
	var stage_no := mini(GameState.stage_index + 1, Balance.stages())
	_progress_label.text = "%s · Mùa %d · Chặng %d/%d" % [Balance.league_name(GameState.business_tier), GameState.season_number, stage_no, Balance.stages()]
	_update_race_ui()
	if _roster != null and _tab == Tab.TEAM:
		_roster.refresh()
	_rebuild_league()


## Tạo thẻ từ một scene của gói asset; truyền dữ liệu bằng configure() trước khi thêm vào cây.
func _make_card(scene: String, data: Dictionary, parent: Control) -> Control:
	var card := (load(ROOT + "components/" + scene + ".tscn") as PackedScene).instantiate() as Control
	card.call("configure", data)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	return card


func _refresh_catalog() -> void:
	for item: Dictionary in _catalog_buttons:
		if not is_instance_valid(item["button"]):
			continue
		var id: String = item["id"]
		var blocked := GameState.phase == "save_error" or GameState.save_blocked
		if item["type"] == "car":
			var owned := GameState.owned_cars.has(id)
			(item["button"] as Button).disabled = blocked or id == GameState.active_car_id or (owned and int(GameData.car(id)["class"]) < int(GameData.league(GameState.business_tier)["min_car_class"])) or (not owned and (not GameState.car_unlocked(id) or GameState.coins.compare(Pricing.car_price(id)) < 0))
		else:
			var owned := id in GameState.owned_drivers
			var disabled := blocked or id == GameState.active_driver_id or (not owned and (not GameState.driver_unlocked(id) or GameState.scout_points < Pricing.scout_sp_cost(GameState.recruit_index()) or GameState.coins.compare(Pricing.scout_coin_cost(id)) < 0))
			item["button"].call("set_action_disabled", disabled)
	if is_instance_valid(_expansion_button):
		var state := GameState.expansion_state()
		_expansion_button.disabled = state != "ok" or GameState.expansion_requested
		if is_instance_valid(_expansion_status):
			_expansion_status.text = _expansion_text(state) + "\nPhí: " + Pricing.expansion_cost(GameState.business_tier).format_compact()


func _expansion_text(state: String) -> String:
	return {"points": "Cần hoàn tất một mùa từ 36 điểm.", "revenue": "Cần cả bốn nguồn doanh thu từ cấp 12.", "car": "Cần chọn xe đủ hạng cho giải kế tiếp.", "short": "Chưa đủ tiền mở cơ sở.", "save_error": "Đang chờ lưu tiến trình.", "ok": "Đã đủ điều kiện mở rộng."}.get(state, "")


func _rebuild_league() -> void:
	_expansion_button = null
	_expansion_status = null
	_clear(_league_box)
	var league_title := _label("Giải %s · Mùa %d" % [Balance.league_name(GameState.business_tier), GameState.season_number], 18)
	_halo(league_title)
	_league_box.add_child(league_title)
	var total := 0
	for r in GameState.season_results:
		total += int(r["points"])
	var promote := maxi(1, Balance.promote_points())
	_make_card("league_card", {
		"item_id": "season", "title": "%s · Mùa %d" % [Balance.league_name(GameState.business_tier), GameState.season_number],
		"subtitle": "Điểm %d · Mục tiêu thăng hạng %d/%d" % [total, Balance.promote_points(), Balance.max_season_points()],
		"image_path": ROOT + "badges/rookie.svg", "action_text": "",
		"progress": 100.0 * float(mini(total, promote)) / float(promote),
	}, _league_box)
	var track_name: String = GameData.track(GameState.PROTOTYPE_TRACK)["name"]
	for i in Balance.stages():
		var title := "Chặng %d · %s" % [i + 1, track_name]
		var card := {"item_id": "stage%d" % i, "title": title, "action_text": "", "progress": 0.0}
		if i < GameState.season_results.size():
			var r: Dictionary = GameState.season_results[i]
			card["subtitle"] = "P%d · +%d điểm · +%s tiền" % [int(r["position"]), int(r["points"]), Balance.fmt_money(r["money"])]
			card["image_path"] = ROOT + "icons/vector_dark/check.svg"
			card["progress"] = 100.0
		elif i == GameState.stage_index:
			card["subtitle"] = "Đang đua" if GameState.phase == "racing" else "Sắp xuất phát"
			card["image_path"] = ROOT + "icons/vector_dark/flag.svg"
			card["selected"] = true
		else:
			card["subtitle"] = "Chưa mở"
			card["image_path"] = ROOT + "icons/vector_dark/lock.svg"
			card["disabled"] = true
		_make_card("mission_card", card, _league_box)
	if not GameState.last_season.is_empty():
		var ls := _card(_league_box)
		var lsr: Dictionary = GameState.last_season
		ls.add_child(_label("Tổng kết mùa %d: %d/%d điểm" % [int(lsr["season_number"]), int(lsr["season_points"]), Balance.max_season_points()], 14))
		var lsb := _button("Xem chi tiết", false, 44.0)
		lsb.pressed.connect(func() -> void: _show_summary(GameState.last_season.duplicate(true)))
		ls.add_child(lsb)
	var t := _card(_league_box)
	t.add_child(_label("Bảng quy đổi vị trí", 14))
	var lines := ""
	for p in 8:
		lines += "P%d: %d điểm · khoảng %s tiền\n" % [p + 1, Pricing.race_points(p + 1), Balance.fmt_money(Pricing.race_money(p + 1, GameState.online_rate(), Balance.race_duration(GameState.PROTOTYPE_TRACK) / RACE_SPEED))]
	t.add_child(_label(lines.strip_edges(), 12, C_MUTED, true))
	t.add_child(_label("Chỉ có kết quả của đội bạn; chưa giả lập BXH mùa của cả tám đội.", 12, C_MUTED, true))

	var expansion := GameState.expansion_state()
	if expansion != "complete":
		var box := _card(_league_box)
		box.add_child(ExpansionArt.icon("facility_tier_%d" % clampi(GameState.business_tier + 1, 1, 5), Vector2(0, 100)))
		box.add_child(_label("Mở cơ sở " + Balance.league_name(GameState.business_tier + 1), 16))
		_expansion_status = _label(_expansion_text(expansion) + "\nPhí: " + Pricing.expansion_cost(GameState.business_tier).format_compact(), 12, C_MUTED, true)
		box.add_child(_expansion_status)
		var btn := _button("Đang chờ hết lượt" if GameState.expansion_requested else "Xem mở cơ sở", true, 44.0)
		btn.disabled = expansion != "ok" or GameState.expansion_requested
		btn.pressed.connect(_confirm_expansion)
		box.add_child(btn)
		_expansion_button = btn


func _confirm_expansion() -> void:
	_begin_overlay()
	var next_tier := GameState.business_tier + 1
	_overlay_box.add_child(_label("Mở cơ sở " + Balance.league_name(next_tier), 18))
	_overlay_box.add_child(_label("Phí %s tiền. Giữ ví, xe, cấp xe và tay đua. Bốn nguồn doanh thu bắt đầu cấp 0 tại cơ sở mới; cơ sở cũ ngừng thu nhập. Mùa dở được ghi lịch sử, không nhận thưởng hoàn tất." % Pricing.expansion_cost(GameState.business_tier).format_compact(), 13, C_TEXT, true))
	_overlay_box.add_child(_label("Thu nhập mới %s/giây · Vốn khai trương %s tiền. Chuyển sau khi chốt lượt đang đua." % [Balance.fmt_rate(Pricing.revenue_rate({}, next_tier)), Pricing.opening_reserve(next_tier).format_compact()], 13, C_GREEN, true))
	var confirm := _button("Mở cơ sở", true)
	confirm.pressed.connect(func() -> void:
		if GameState.request_expansion():
			_overlay.hide()
		else:
			_show_toast("Chưa mở được cơ sở. Kiểm tra điều kiện hoặc thử lưu lại."))
	_overlay_box.add_child(confirm)
	var cancel := _button("Để sau", false)
	cancel.pressed.connect(func() -> void: _overlay.hide())
	_overlay_box.add_child(cancel)


func _rebuild_shop() -> void:
	if not is_instance_valid(_shop_content):
		return
	_shop_content.update_daily(
		Balance.fmt_money(Pricing.daily_gift(GameState.online_rate())),
		int(GameData.economy()["rewards"]["daily_gems"]),
		GameState.daily_available(), GameState.save_blocked or GameState.phase == "save_error")


func _claim_shop_daily() -> void:
	var at := _shop_content.global_position + Vector2(_shop_content.size.x * 0.5, 90) - global_position
	if GameState.claim_daily():
		_sfx("daily_gift")
		_spawn_fx("reward_burst", at, 1.2)
	else:
		_show_toast("Chưa thể nhận quà. Kiểm tra trạng thái lưu hoặc thử lại sau.")
	_rebuild_shop()


func _show_shop_offer(title: String, description: String) -> void:
	_sfx("ui_click")
	_begin_overlay()
	_overlay_box.add_child(_label(title, 20))
	_overlay_box.add_child(_label(description, 14, C_TEXT, true))
	_overlay_box.add_child(_label("Sắp có · Gói này chưa mở bán. Nội dung và giá có thể thay đổi khi ra mắt.", 13, C_MUTED, true))
	var close := _button("Đã hiểu", true)
	close.pressed.connect(func() -> void: _overlay.hide())
	_overlay_box.add_child(close)


# ---------------------------------------------------------------- đua (UI chỉ đọc trạng thái từ GameState)

func _process(delta: float) -> void:
	if not _active:
		return
	# Bảng tổng kết tự tắt sau RESULT_SHOW_SEC giây (thời gian thật) rồi thả đua tiếp.
	if _result_panel.visible:
		_result_timer -= delta
		if is_instance_valid(_result_bar):
			_result_bar.value = maxf(_result_timer, 0.0)
		if _result_timer <= 0.0:
			_result_panel.hide()
	if GameState.result_hold and not _result_panel.visible:
		GameState.result_hold = false
	GameState.time_scale = 10.0 if _fast_forced else RACE_SPEED
	_row_timer += delta
	if _row_timer >= 0.2:
		_row_timer = 0.0
		_refresh_light()
	_sync_sim()
	_update_race_ui()
	_race_view.queue_redraw()
	_pump_events()
	_dev_tick(delta)


## Khi vòng lặp đổi sim (grid xem trước, xuất phát, lượt mới): chuyển khung đua sang sim đó.
func _sync_sim() -> void:
	var sim := GameState.sim
	if sim != _view_sim:
		_view_sim = sim
		_race_view.sim = sim
	_race_view.alpha = GameState.render_alpha()


func _on_race_started() -> void:
	_sfx("countdown_go")
	_set_music("music_race_loop")


func _on_race_finished(res: Dictionary) -> void:
	_sfx("finish")
	_set_music("music_workshop_loop")
	# Hiện bảng tổng kết + thưởng theo hạng; lượt kế tiếp chỉ đếm ngược sau khi người chơi đóng bảng.
	if _shot_prefix == "" and not _auto_race:
		GameState.result_hold = true
		_show_race_result(res.duplicate(true))
	if _shot_prefix == "" and _race_view != null:
		_spawn_fx("finish_flash", _race_view.global_position + _race_view.size * 0.5 - global_position, 2.0)


## Trạng thái vòng lặp: countdown / thời gian còn lại / vị trí; lỗi lưu.
func _update_race_ui() -> void:
	var gs := GameState
	var look := gs.race_cosmetics()
	_race_view.player_paint_id = String(look["paint_id"])
	_race_view.player_decal_id = String(look["decal_id"])
	var sim := gs.sim
	if sim == null:
		return
	var overlay := ""
	match gs.phase:
		"countdown":
			var n := maxi(int(ceil(gs.countdown_left - 0.000001)), 1)
			overlay = str(n)
			_status_label.text = "Xuất phát sau %d giây · %d xe trên grid" % [n, Balance.CAR_COUNT]
			if n != _last_count:
				_last_count = n
				_sfx("countdown_tick")
		"racing":
			_last_count = -1
			if sim.time < 0.8:
				overlay = "ĐUA!"
			_status_label.text = ""
		"save_error":
			_status_label.text = "Hết giờ · P%d/%d" % [int(gs.last_result.get("position", 1)), Balance.CAR_COUNT]
	_race_view.overlay_text = overlay
	_race_view.power_value = gs.team_power()
	_save_err_box.visible = gs.phase == "save_error"
	var differs := false
	if gs.phase == "racing" and not gs.race_snapshot.is_empty():
		var cur := gs.player_stats()
		var snap: Dictionary = gs.race_snapshot["stats"]
		for k: String in cur:
			if not is_equal_approx(float(cur[k]), float(snap.get(k, 0.0))):
				differs = true
	_snapshot_label.text = "Lượt này dùng chỉ số lúc xuất phát. Nâng cấp mới áp dụng từ lượt sau."
	_snapshot_label.visible = differs


## Giữ hiệu ứng trên đường đua và âm thanh sự kiện, không dựng bảng tin bên dưới.
func _pump_events() -> void:
	var sim := _view_sim
	var fresh := _race_view.pump_events()
	if sim == null:
		return
	for e: Dictionary in fresh:
		var who: TrafficSim.Car = sim.cars[int(e["id"])]
		# Không phát tiếng "vèo" khi vượt xe: lượt vượt dày ở đầu lượt nghe như tiếng ồn.
		if String(e["type"]) != "pass" and who.is_player:
			_sfx("tyre_squeak")


# ---------------------------------------------------------------- overlay

func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.hide()
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.08, 0.13, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	_overlay.add_child(margin)
	var center := CenterContainer.new()
	margin.add_child(center)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", HdUi.panel(6.0))
	center.add_child(pc)
	var sc := preload("res://ui/touch_scroll.gd").new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pc.add_child(sc)
	_overlay_box = VBoxContainer.new()
	_overlay_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overlay_box.add_theme_constant_override("separation", 8)
	sc.add_child(_overlay_box)


## Bảng tổng kết lượt: thẻ gọn nằm giữa vùng đua (tiêu đề + hạng, các dòng thưởng, thanh thời gian), không che phần UI khác.
func _build_race_result_panel() -> void:
	_result_panel = Control.new()
	_result_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.hide()
	_race_view.add_child(_result_panel)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_panel.add_child(center)
	var card := PanelContainer.new()
	var sb := HdUi.panel().duplicate() as StyleBoxTexture
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 8.0
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(280, 0)
	center.add_child(card)
	_result_box = VBoxContainer.new()
	_result_box.add_theme_constant_override("separation", 0)
	card.add_child(_result_box)


func _result_row(label: String, value: String, col: Color) -> Control:
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 16)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 8)
	var h := HBoxContainer.new()
	var l := _label(label, 15, Color("5d6b80"))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var v := _label(value, 15, col)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	m.add_child(h)
	return m


func _show_race_result(res: Dictionary) -> void:
	if res.is_empty():
		return
	_clear(_result_box)
	var pos := int(res["position"])
	var podium := pos <= 3
	var green := Color("22c55e")
	var head_col := green if podium else Color("64748b")
	# Tiêu đề + huy hiệu hạng.
	var hp := PanelContainer.new()
	var hs := StyleBoxFlat.new()
	hs.bg_color = head_col
	hs.corner_radius_top_left = 14
	hs.corner_radius_top_right = 14
	hs.set_content_margin_all(10)
	hp.add_theme_stylebox_override("panel", hs)
	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 10)
	hp.add_child(hh)
	var title := "CHIẾN THẮNG" if pos == 1 else ("LÊN BỤC VINH QUANG" if podium else "VỀ ĐÍCH")
	var t := _label(title, 15, Color.WHITE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hh.add_child(t)
	var badge := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = head_col.darkened(0.25)
	bs.set_corner_radius_all(10)
	bs.content_margin_left = 16
	bs.content_margin_right = 16
	bs.content_margin_top = 4
	bs.content_margin_bottom = 4
	badge.add_theme_stylebox_override("panel", bs)
	var bl := _label("P%d" % pos, 22, Color.WHITE)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(bl)
	hh.add_child(badge)
	_result_box.add_child(hp)
	# Các dòng thưởng.
	_result_box.add_child(_result_row("Tiền", "+%s" % Balance.fmt_money(res["money"]), green.darkened(0.1)))
	_result_box.add_child(HSeparator.new())
	_result_box.add_child(_result_row("Điểm mùa", "+%d" % int(res["points"]), Color("5d6b80")))
	if bool(res.get("season_done", false)):
		_result_box.add_child(HSeparator.new())
		_result_box.add_child(_result_row("Hoàn tất mùa %d" % int(res["season_number"]), "+%s" % Balance.fmt_money(res.get("completion_reward", 0)), green.darkened(0.1)))
	# Thanh thời gian còn lại của bảng.
	_result_bar = ProgressBar.new()
	_result_bar.show_percentage = false
	_result_bar.min_value = 0.0
	_result_bar.max_value = RESULT_SHOW_SEC
	_result_bar.value = RESULT_SHOW_SEC
	_result_bar.custom_minimum_size = Vector2(0, 6)
	_result_box.add_child(_result_bar)
	_result_timer = RESULT_SHOW_SEC
	_result_panel.show()


## Overlay chỉ còn dùng cho báo cáo vắng mặt lúc vào game; kết quả/tổng kết là thông tin xem lại, không điều khiển đua.
func _open_next_overlay() -> void:
	if not GameState.offline_report.is_empty():
		_show_offline()
	else:
		_overlay.hide()


func _begin_overlay() -> void:
	_clear(_overlay_box)
	_overlay.show()
	_fit_overlay.call_deferred()


## Panel cao vừa nội dung, tối đa bằng chiều cao khả dụng (cuộn khi dài).
func _fit_overlay() -> void:
	await get_tree().process_frame
	var sc := _overlay_box.get_parent() as ScrollContainer
	var panel := sc.get_parent() as PanelContainer
	var frame := panel.get_theme_stylebox("panel")
	# Account for the screen gutters and the panel's own padding on narrow phones.
	sc.custom_minimum_size.x = minf(316.0, maxf(0.0, size.x - 32.0 - frame.get_minimum_size().x))
	var wanted := _overlay_box.get_combined_minimum_size().y
	sc.custom_minimum_size.y = minf(wanted, maxf(200.0, size.y - 120.0))


## Ảnh minh hoạ ở đầu overlay (cúp, huy chương, túi tiền), căn giữa.
func _art(path: String, height: float) -> TextureRect:
	var t := _icon(path, Vector2(0, height))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return t


## Bung hiệu ứng ăn mừng từ phía trên giữa overlay (tắt khi chụp ảnh kiểm thử).
func _celebrate(fx: String) -> void:
	if _shot_prefix != "":
		return
	_spawn_fx(fx, Vector2(size.x * 0.5, size.y * 0.3), 3.0)


func _show_offline() -> void:
	_begin_overlay()
	var rep: Dictionary = GameState.offline_report
	_overlay_box.add_child(_label("Chào mừng quay lại", 18))
	_overlay_box.add_child(_art("rewards/money_bag.tres", 110.0))
	_sfx("coin_pickup")
	var mins := int(float(rep["elapsed"]) / 60.0)
	_overlay_box.add_child(_label("Bạn vắng %d phút. Tính tối đa %d phút." % [mins, int(Balance.offline_cap_sec() / 60.0)], 13, C_MUTED, true))
	_overlay_box.add_child(_label("Thu nhập cơ sở %s/giây × hệ số %d%%" % [Balance.fmt_rate(rep["rate"]), int(float(rep["ratio"]) * 100.0)], 13, C_TEXT, true))
	var big := _label("+%s tiền" % Balance.fmt_money(rep["reward"]), 28, C_GOLD)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_box.add_child(big)
	_overlay_box.add_child(_label("Đội không đua khi bạn vắng mặt; tiến trình giải không đổi.", 12, C_MUTED, true))
	var b := _button("Tiếp tục", true)
	b.pressed.connect(func() -> void:
		GameState.offline_report = {}
		_open_next_overlay())
	_overlay_box.add_child(b)


## Tổng kết mùa (xem lại ở tab Giải): mùa đã tự chuyển, đóng bảng không đổi trạng thái.
func _show_summary(res: Dictionary) -> void:
	if res.is_empty():
		return
	_begin_overlay()
	_overlay_box.add_child(_label("Tổng kết mùa %d" % int(res.get("season_number", 1)), 18))
	_overlay_box.add_child(_art("rewards/rookie_cup.tres", 110.0))
	var pts := int(res.get("season_points", 0))
	var big := _label("%d/%d điểm" % [pts, Balance.max_season_points()], 30, C_GOLD)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_box.add_child(big)
	var rows: Array = res.get("season_rows", [])
	var lines := ""
	for i in rows.size():
		lines += "Chặng %d: P%d · +%d điểm\n" % [i + 1, int(rows[i]["position"]), int(rows[i]["points"])]
	_overlay_box.add_child(_label(lines.strip_edges(), 13, C_TEXT, true))
	_overlay_box.add_child(_label("Thưởng hoàn tất mùa: +%s tiền" % Balance.fmt_money(res.get("completion_reward", 0)), 14, C_GREEN, true))
	var qualified := bool(res.get("qualified", false))
	var msg := "Đạt %d điểm trở lên: mở quyền vào giải kế tiếp. Xem điều kiện xe và mở cơ sở trong tab Giải." % Balance.promote_points() if qualified \
		else "Chưa đạt %d điểm nên ở lại giải này. Không bị tụt hạng." % Balance.promote_points()
	_overlay_box.add_child(_label(msg + " Mùa mới đã tự bắt đầu.", 12, C_MUTED, true))
	var b := _button("Đóng", true)
	b.pressed.connect(func() -> void: _overlay.hide())
	_overlay_box.add_child(b)


# ---------------------------------------------------------------- kiểm thử qua CLI

func _dev_tick(delta: float) -> void:
	if _shot_prefix == "" and not _auto_race:
		return
	_dev_time += delta
	var gs := GameState
	if _auto_race:
		if gs.phase == "countdown" and _dev_time > 0.5 and not _shots_done.has("count"):
			_shots_done["count"] = true
			_save_shot("1_countdown")
		if gs.phase == "racing" and gs.sim != null and gs.sim.time > 20.0 and not _shots_done.has("mid"):
			_shots_done["mid"] = true
			_save_shot("2_racing")
		if not gs.last_result.is_empty() and not _shots_done.has("result"):
			_shots_done["result"] = true
			await get_tree().create_timer(0.3).timeout
			_save_shot("3_result")
			_select_tab(Tab.TEAM)
			await get_tree().create_timer(0.2).timeout
			_save_shot("4_team")
			_select_tab(Tab.LEAGUE)
			await get_tree().create_timer(0.2).timeout
			_save_shot("5_league")
			get_tree().quit()
	elif _dev_time > 1.0 and not _shots_done.has("only"):
		_shots_done["only"] = true
		_save_shot("tab%d" % _tab)
		get_tree().quit()


func _save_shot(tag: String) -> void:
	if _shot_prefix == "":
		return
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s_%s.png" % [_shot_prefix, tag])
