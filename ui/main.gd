extends Control

const BigNumber = preload("res://core/math/big_number.gd")
const PowerIncreaseBanner = preload("res://ui/power_increase_banner.gd")
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
var _gem_label: Label
var _profile: Control
var _class_page: Control
var _class_btn: Button
var _header_avatar: Control
var _progress_label: Label
var _status_label: Label
var _save_err_box: PanelContainer
var _snapshot_label: Label       # nhắc đội đang đua dùng snapshot lúc xuất phát
var _view_sim: TrafficSim = null # sim mà RaceView đang hiển thị
var _race_view: RaceView
var _power_banner: Control
var _race_block: VBoxContainer   # khung đua + tiến độ + banner, ghim ở Đua/Túi/Đội
const RACE_HEIGHT := 294.0  # 250 + dải khán đài 44 (RaceView.STAND_H) để đường đua giữ nguyên chỗ
const SCENERY_H := 190.0   # chiều cao dải ảnh sân đua phía sau thanh tài nguyên
var _drivers_box: VBoxContainer
var _roster: DriverRosterPage
var _league_box: VBoxContainer
var _shop_box: VBoxContainer
var _shop_content: VBoxContainer
var _toast: Label
var _overlay: Control
var _ads_controls: AdsRaceControls  # chip ×2 + lá cờ thưởng + popup xem video (ui/ads_race_controls.gd)
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
var _tutorial: TutorialOverlay       # hướng dẫn đầu game Phần A (Design/23 §4)
var _coin_bar: Control
var _cli_tutorial: bool = false      # --tutorial: vẫn chạy hướng dẫn khi chụp ảnh/auto-race
var _cli_tutorial_step: String = ""  # --tutorial-step=A4_engine: nhảy tới bước (chụp ảnh kiểm tra)
var _cli_gated: bool = false         # --gated: bật lịch mở khóa dần (Design/23 §5) khi chụp ảnh
var _cli_races: int = -1             # --races=N: đặt số lượt đã hoàn tất (chụp ảnh các mốc mở khóa)
var _cli_tut_done: bool = false      # --tutorial-done: coi như xong Phần A (chụp ảnh mẹo Phần C)
var _cli_levels: String = ""         # --levels=ticket:23,parking:48: đặt cấp nâng cấp (chụp ảnh mẹo C4)
var _nav_items: Array = []           # ô điều hướng (chứa NavLock/NavDot)
var _sched_btn: Button
var _next_label: Label               # "Sắp mở: ..."
var _lock_sig := ""


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
		elif a == "--gated":
			_cli_gated = true
		elif a.begins_with("--races="):
			_cli_races = int(a.substr(8))
		elif a == "--tutorial-done":
			_cli_tut_done = true
		elif a.begins_with("--levels="):
			_cli_levels = a.substr(9)
		elif a == "--tutorial":
			_cli_tutorial = true
		elif a.begins_with("--tutorial-step="):
			_cli_tutorial = true
			_cli_tutorial_step = a.substr(16)
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
	_start_tutorial()
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
	_header_avatar = Button.new()
	_header_avatar.name = "PlayerProfileButton"
	_header_avatar.custom_minimum_size = Vector2(52, 52)
	_header_avatar.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_header_avatar.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_header_avatar.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_header_avatar.tooltip_text = "Hồ sơ người chơi"
	_header_avatar.accessibility_name = "Hồ sơ người chơi"
	_header_avatar.pressed.connect(_show_profile)
	var avatar_icon := HdUi.icon("icons/avatar.png", Vector2(52, 52))
	avatar_icon.name = "PlayerAvatarIcon"
	avatar_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_avatar.add_child(avatar_icon)
	avatar_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_header_avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(_header_avatar)
	var money := VBoxContainer.new()
	money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money.add_theme_constant_override("separation", 1)
	_coin_label = _hud_label(20)
	_coin_bar = _hud_bar("icons/cash.png", _coin_label, 46.0)
	_coin_bar.name = "HudCoins"
	money.add_child(_coin_bar)
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
	# Center the gear in the whole button, independently of skin padding.
	var settings_center := CenterContainer.new()
	settings_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings.add_child(settings_center)
	var settings_icon := HdUi.icon("icons/gear.png", Vector2(28, 28))
	# Center the visible gear, excluding the PNG's uneven transparent margins.
	var settings_texture := AtlasTexture.new()
	settings_texture.atlas = HdUi.tex("icons/gear.png")
	settings_texture.region = Rect2(11, 57, 262, 256)
	settings_icon.texture = settings_texture
	settings_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_center.add_child(settings_icon)
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
		var lock := TextureRect.new()
		lock.name = "NavLock"
		lock.texture = _tex("icons/vector/lock.svg")
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.set_anchors_preset(Control.PRESET_CENTER_TOP)
		lock.offset_left = 4.0
		lock.offset_right = 28.0
		lock.offset_top = 14.0
		lock.offset_bottom = 38.0
		lock.hide()
		item.add_child(lock)
		var dot := Panel.new()
		dot.name = "NavDot"
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dsb := StyleBoxFlat.new()
		dsb.bg_color = Color("ef4444")
		dsb.border_color = Color.WHITE
		dsb.set_border_width_all(2)
		dsb.set_corner_radius_all(9)
		dot.add_theme_stylebox_override("panel", dsb)
		dot.set_anchors_preset(Control.PRESET_CENTER_TOP)
		dot.offset_left = 10.0
		dot.offset_right = 28.0
		dot.offset_top = 0.0
		dot.offset_bottom = 18.0
		dot.hide()
		item.add_child(dot)
		_nav_items.append(item)
		_nav.append(b)

	_profile = preload("res://ui/player_profile.gd").new()
	_profile.name = "PlayerProfile"
	_profile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_profile)
	_profile.hide()
	_profile.closed.connect(func() -> void: _header_avatar.grab_focus())
	_profile.settings_requested.connect(_show_settings)
	_class_page = preload("res://ui/class_page.gd").new()
	_class_page.name = "ClassPage"
	_class_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_class_page)
	_class_page.hide()
	_class_page.closed.connect(func() -> void: _class_btn.grab_focus())
	_build_overlay()
	_tutorial = TutorialOverlay.new()
	_tutorial.name = "TutorialOverlay"
	_tutorial.target_provider = _tutorial_target
	_tutorial.context_provider = _tutorial_context
	_tutorial.result_released.connect(func() -> void: _result_panel.hide())
	_tutorial.reveal_requested.connect(_tutorial_reveal)
	add_child(_tutorial)


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
	_sched_btn = sched
	head.add_child(sched)
	_class_btn = _button("Class", true, 44.0)
	_class_btn.name = "ClassButton"
	_class_btn.custom_minimum_size = Vector2(72, 44)
	_class_btn.pressed.connect(_show_classes)
	head.add_child(_class_btn)
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
	# Clip both the HUD and the grass to the same rounded silhouette.
	# clip_contents alone only clips to a rectangle.
	var race_clip := PanelContainer.new()
	race_clip.name = "RaceRoundedClip"
	race_clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var rounded := StyleBoxFlat.new()
	rounded.bg_color = RaceView.C_GROUND
	rounded.set_corner_radius_all(12)
	rounded.corner_detail = 12
	race_clip.add_theme_stylebox_override("panel", rounded)
	frame.add_child(race_clip)
	_race_view = RaceView.new()
	_race_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_race_view.size_flags_vertical = Control.SIZE_FILL
	_race_view.custom_minimum_size = Vector2(0, RACE_HEIGHT)
	_race_view.clip_contents = true
	race_clip.add_child(_race_view)
	_race_view.set_track(GameState.PROTOTYPE_TRACK)
	_ads_controls = AdsRaceControls.new()
	_race_view.add_child(_ads_controls)
	_power_banner = PowerIncreaseBanner.new()
	_race_view.add_child(_power_banner)
	_build_race_result_panel()
	# Gợi ý đường đua nằm trong tooltip của dòng tiến độ (không còn chỗ cho dòng chữ riêng).
	var track: Dictionary = GameData.track(GameState.PROTOTYPE_TRACK)

	_status_label = _label("", 14, C_TEXT)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.clip_text = true
	v.add_child(_status_label)
	_next_label = _label("", 12, C_MUTED)
	_next_label.name = "NextUnlock"
	_next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_next_label.clip_text = true
	_next_label.hide()
	v.add_child(_next_label)

	_snapshot_label = _label("", 12, C_MUTED, true)
	_snapshot_label.hide()

	# Lỗi lưu khi chốt kết quả: giữ giao dịch đang chờ, cho thử lại (Design/10 §5).
	_save_err_box = PanelContainer.new()
	var eh := HBoxContainer.new()
	eh.add_theme_constant_override("separation", 8)
	_save_err_box.add_child(eh)
	var el := _label("Không lưu được kết quả lượt đua. Chưa có lượt mới cho tới khi lưu xong.", 12, C_RED, true)
	eh.add_child(el)
	var retry := _button("Thử lại", true, 44.0)
	retry.custom_minimum_size = Vector2(88, 44)
	retry.pressed.connect(func() -> void: GameState.retry_save())
	eh.add_child(retry)
	_save_err_box.hide()
	v.add_child(_save_err_box)


func _build_upgrade_grid(v: VBoxContainer) -> void:
	v.add_theme_constant_override("separation", 8)
	for group in [["XE ĐUA", "icons/car_red.png", Balance.PARTS, "CarUpgradeGrid"], ["DOANH THU", "icons/cash.png", Balance.REVENUE, "RevenueUpgradeGrid"]]:
		_section_head(v, group[0], group[1])
		var grid := GridContainer.new()
		grid.name = group[3]
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		v.add_child(grid)
		for kind: String in group[2]:
			_add_tile(grid, kind)


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
	if i == 1 and not GameState.feature_unlocked("U6_garage"):
		_toast_lock("U6_garage")
		i = 0
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
	_overlay_box.add_child(HdUi.close_header("Drop Information · %s" % pack["name"], _overlay.hide))
	var tiers: Dictionary = pack["tiers"]
	var keys: Array = tiers.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return float(tiers[a]) > float(tiers[b]))
	for k: String in keys:
		var row := _label("%s: %s%%" % [String(k).capitalize(), str(snappedf(float(tiers[k]), 0.01))], 15)
		_overlay_box.add_child(row)
	_overlay_box.add_child(_label("Một coupon = một lượt mở. Có đủ coupon đúng loại thì dùng coupon trước gem.", 12, C_MUTED, true))


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
	_overlay_box.add_child(HdUi.close_header("Tỉ lệ · %s" % pack["name"], _overlay.hide))
	var tiers: Dictionary = pack["tiers"]
	var keys: Array = tiers.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return float(tiers[a]) > float(tiers[b]))
	for k: String in keys:
		_overlay_box.add_child(_label("%s: %s%%" % [String(k).capitalize(), str(snappedf(float(tiers[k]), 0.01))], 15))
	_overlay_box.add_child(_label("Bảo đảm: sau %d lượt liên tiếp chưa ra %s thì lượt thứ %d chắc chắn ra bậc này (đếm riêng từng gói)." % [int(pack["pity_draws"]) - 1, String(pack["pity_tier"]).capitalize(), int(pack["pity_draws"])], 12, C_MUTED, true))
	_overlay_box.add_child(_label("Tay đua trùng đổi thành mảnh để nâng cấp. Một coupon = một lượt mở; có đủ coupon đúng loại thì dùng coupon trước gem.", 12, C_MUTED, true))


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
	var background := StyleBoxFlat.new()
	background.bg_color = Color("eaf3ff")
	background.content_margin_top = 12
	background.content_margin_bottom = 12
	(_league_box.get_parent() as ScrollContainer).add_theme_stylebox_override("panel", background)


func _build_shop_page() -> void:
	_shop_box = _make_page()
	_shop_content = (load("res://ui/shop_page.gd") as GDScript).new()
	_shop_box.add_child(_shop_content)
	_shop_content.daily_requested.connect(_claim_shop_daily)
	_shop_content.offer_requested.connect(_show_shop_offer)
	_shop_content.iap_requested.connect(_buy_iap)
	_shop_content.restore_requested.connect(_restore_iap)
	_shop_content.ad_requested.connect(_watch_shop_ad)
	Ads.changed.connect(_rebuild_shop)
	Iap.changed.connect(_rebuild_shop)


## Mua một SKU IAP. Kết quả qua Iap.buy; thông báo ngắn theo trạng thái. Lỗi lưu: đơn còn ở store, mở game lại sẽ giao.
func _buy_iap(sku: String) -> void:
	_sfx("ui_click")
	Iap.buy(sku, _on_iap_result)


func _on_iap_result(r: Dictionary) -> void:
	match String(r.get("status", "")):
		"ok":
			var g: Dictionary = GameState.last_iap_grant
			_sfx("daily_gift")
			_show_toast("Mua thành công" + (" · +%d gem" % int(g["gems"]) if int(g.get("gems", 0)) > 0 else ""))
		"pending":
			_show_toast("Đang chờ thanh toán hoàn tất.")
		"invalid":
			_show_toast("Giao dịch không hợp lệ.")
		"failed":
			_show_toast("Đã thanh toán nhưng chưa lưu được. Mở lại game để nhận hàng.")
		"cancelled", "busy":
			pass
		"blocked":
			_show_toast("Hiện chưa mua được gói này.")
		_:
			_show_toast("Chưa mua được, thử lại sau.")
	_refresh()


func _restore_iap() -> void:
	_sfx("ui_click")
	Iap.restore(_on_iap_restored)


func _on_iap_restored(r: Dictionary) -> void:
	_show_toast("Đã khôi phục giao dịch." if String(r.get("status", "")) == "ok" else "Chưa khôi phục được, thử lại sau.")
	_refresh()


func _show_profile() -> void:
	if not GameState.feature_unlocked("U2_league"):
		_toast_lock("U2_league")
		return
	_profile.open()


func _show_classes() -> void:
	if not GameState.feature_unlocked("U7_class"):
		_toast_lock("U7_class")
		return
	_class_page.open()


func _show_settings() -> void:
	_begin_overlay()
	var content := VBoxContainer.new()
	content.name = "SettingsContent"
	content.add_theme_constant_override("separation", 12)
	_overlay_box.add_child(content)
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 10)
	content.add_child(header)
	var gear := TextureRect.new()
	gear.texture = HdUi.tex("icons/gear.png")
	gear.custom_minimum_size = Vector2(36, 36)
	gear.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gear.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(gear)
	var title := _label("Cài đặt", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(HdUi.close_button(_overlay.hide, "SettingsClose"))
	var divider := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = Color("639ce8")
	line.thickness = 2
	divider.add_theme_stylebox_override("separator", line)
	content.add_child(divider)
	content.add_child(_label("ÂM THANH", 14))
	_settings_audio_row(content, "MusicToggle", "Nhạc nền", "music", _music_on, func(on: bool) -> void:
		_music_on = on
		_set_music("music_race_loop" if GameState.phase == "racing" else "music_workshop_loop"))
	_settings_audio_row(content, "SfxToggle", "Hiệu ứng âm thanh", "sound", _sfx_on, func(on: bool) -> void:
		_sfx_on = on)
	content.add_child(_label("HƯỚNG DẪN", 14))
	_settings_audio_row(content, "TipsToggle", "Mẹo từ Linh", "help", GameState.tips_enabled(), func(on: bool) -> void:
		GameState.set_tips_enabled(on))


func _settings_audio_row(parent: VBoxContainer, node_name: String, text: String, icon_name: String, on: bool, cb: Callable) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 68
	panel.add_theme_stylebox_override("panel", HdUi.panel())
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var icon := _icon("icons/vector_dark/%s.svg" % icon_name, Vector2(34, 34))
	icon.modulate = Color("2876d6") / Color("202b38")
	row.add_child(icon)
	var title := _label(text, 16, C_TEXT, true)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title)
	var toggle := _toggle("", on, cb)
	toggle.name = node_name
	toggle.accessibility_name = text
	toggle.tooltip_text = text
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(toggle)


# ---------------------------------------------------------------- ô nâng cấp

## Một ô nâng cấp gọn: icon + tên/cấp, dòng hiệu ứng ngắn, nút giá. Chi tiết (gợi ý, hoàn vốn) ở tooltip.
func _add_tile(parent: Control, kind: String) -> void:
	var pc := PanelContainer.new()
	var st := _upgrade_skin(false)
	st.content_margin_left = 10.0
	st.content_margin_right = 10.0
	st.content_margin_top = 12.0
	st.content_margin_bottom = 8.0
	pc.add_theme_stylebox_override("panel", st)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(pc)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	pc.add_child(content)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.custom_minimum_size.y = 48
	content.add_child(row)
	var art: TextureRect
	if ROW_ICONS.has(kind):
		var ic := ExpansionArt.icon(kind, Vector2(44, 44))
		art = ic
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(ic)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var name_l := _label("", 15, C_TEXT, true)
	name_l.max_lines_visible = 2
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if kind in Balance.REVENUE:
		row.custom_minimum_size.y = 60
		name_l.custom_minimum_size.y = 38
		name_l.autowrap_mode = TextServer.AUTOWRAP_WORD
		name_l.clip_text = true
	info.add_child(name_l)
	var level_l := _label("", 12, C_MUTED)
	info.add_child(level_l)
	pc.resized.connect(func() -> void:
		var narrow := pc.size.x < 150.0
		name_l.add_theme_font_size_override("font_size", 13 if narrow else 15)
		row.add_theme_constant_override("separation", 4 if narrow else 6)
		if art != null:
			art.custom_minimum_size = Vector2.ONE * (40 if narrow else 44))
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.custom_minimum_size.y = 26
	stats.add_theme_constant_override("separation", 0)
	content.add_child(stats)
	var eff_l := _label("", 17, C_TEXT)
	stats.add_child(eff_l)
	var next_l := _label("", 17, C_GREEN)
	stats.add_child(next_l)
	var btn := Button.new()
	HdUi.style_button(btn, "upgrade")
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := _upgrade_skin(true)
		if state == "hover":
			skin.modulate_color = Color(1.06, 1.06, 1.06)
		elif state == "pressed":
			skin.modulate_color = Color(0.85, 0.88, 0.95)
		elif state == "disabled":
			skin.modulate_color = Color(0.85, 0.85, 0.85)
		btn.add_theme_stylebox_override(state, skin)
	btn.custom_minimum_size = Vector2(0, 44)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 16)
	var price_center := CenterContainer.new()
	price_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	price_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(price_center)
	var price_group := HBoxContainer.new()
	price_group.add_theme_constant_override("separation", 5)
	price_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_center.add_child(price_group)
	var cash_icon := HdUi.icon("icons/cash.png", Vector2(24, 24))
	cash_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_group.add_child(cash_icon)
	var price_label := _label("", 22, Color.WHITE)
	price_label.add_theme_constant_override("outline_size", 0)
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_group.add_child(price_label)
	btn.pressed.connect(_on_buy.bind(kind))
	btn.pressed.connect(func() -> void: _sfx("ui_click"))
	content.add_child(btn)
	# `short` giữ cho _refresh_rows; ô không có chỗ cho dòng "Thiếu ..." nên để ẩn, nội dung đi vào tooltip.
	var short_l := _label("", 11, C_RED)
	short_l.hide()
	info.add_child(short_l)
	_rows.append({"kind": kind, "name": name_l, "level": level_l, "eff": eff_l, "next": next_l, "short": short_l, "btn": btn, "price": price_label, "cash_icon": cash_icon, "tile": pc})


## Rounded gradient surfaces sized for the compact upgrade cards.
func _upgrade_skin(button: bool) -> StyleBoxTexture:
	var svg: String
	if button:
		svg = '<svg xmlns="http://www.w3.org/2000/svg" width="180" height="48"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="#3477e6"/><stop offset="0.55" stop-color="#2864cf"/><stop offset="1" stop-color="#2458be"/></linearGradient></defs><rect x="1" y="4" width="178" height="43" rx="15" fill="#184999"/><rect x="1" y="1" width="178" height="43" rx="15" fill="url(#g)" stroke="#2056b3" stroke-width="2"/></svg>'
	else:
		svg = '<svg xmlns="http://www.w3.org/2000/svg" width="180" height="156"><defs><linearGradient id="g" x2="0.5" y2="1"><stop stop-color="#eff7ff"/><stop offset="1" stop-color="#c8dff5"/></linearGradient></defs><rect x="1" y="4" width="178" height="151" rx="18" fill="#426998"/><rect x="1" y="1" width="178" height="151" rx="18" fill="url(#g)" stroke="#477dc6" stroke-width="2"/><rect x="3" y="3" width="174" height="147" rx="16" fill="none" stroke="#ffffff" stroke-opacity="0.9" stroke-width="1.5"/></svg>'
	var img := Image.new()
	img.load_svg_from_string(svg)
	var skin := StyleBoxTexture.new()
	skin.texture = ImageTexture.create_from_image(img)
	skin.texture_margin_left = 19
	skin.texture_margin_right = 19
	skin.texture_margin_top = 20
	skin.texture_margin_bottom = 20
	skin.content_margin_left = 0
	skin.content_margin_right = 0
	skin.content_margin_top = 0
	skin.content_margin_bottom = 0
	return skin


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


func _refresh_rows() -> void:
	# Gọi 5 lần/giây: chỉ tính phần thật sự hiện trên ô, và chỉ đặt lại màu khi đổi (đổi theme override rất tốn).
	var rate: BigNumber = GameState.online_rate()
	for r in _rows:
		var kind: String = r["kind"]
		var lv: int = GameState.level_of(kind)
		var maxed: bool = lv >= Balance.max_level()
		if kind in Balance.REVENUE:
			(r["name"] as Label).text = String(GameData.economy()["revenue_upgrades"][kind]["name"])
		else:
			(r["name"] as Label).text = String(Balance.PART_NAMES[kind])
		(r["level"] as Label).text = "Cấp %d" % lv
		# Dòng ngắn trên ô: xe "Speed 46 → 48"; doanh thu "+x/giây" (hết cấp thì giá trị hiện tại).
		var short_eff := ""
		if kind in Balance.PARTS:
			short_eff = "%.1f" % GameState.part_stat(kind, lv) if maxed else "%.1f → %.1f" % [GameState.part_stat(kind, lv), GameState.part_stat(kind, lv + 1)]
		elif kind in Balance.REVENUE:
			if maxed:
				short_eff = Balance.fmt_rate(rate) + "/giây"
			else:
				var nl: Dictionary = GameState.levels.duplicate()
				nl[kind] = lv + 1
				var delta := Pricing.revenue_rate(nl, GameState.business_tier).subtract_checked(rate)
				short_eff = "+%s/giây" % Balance.fmt_rate(delta)
		var values := short_eff.split(" → ")
		(r["eff"] as Label).text = values[0] + (" → " if values.size() > 1 else "")
		(r["next"] as Label).text = values[1] if values.size() > 1 else ""
		_set_font_color(r, "eff", C_GREEN if kind in Balance.REVENUE else C_TEXT)
		var btn: Button = r["btn"]
		var cost: BigNumber = GameState.cost_of(kind)
		var st := GameState.upgrade_state(kind)
		match st:
			"ok":
				(r["price"] as Label).text = Balance.fmt_money(cost)
				btn.disabled = false
			"short":
				(r["price"] as Label).text = Balance.fmt_money(cost)
				btn.disabled = true
			"save_error", "invalid":
				(r["price"] as Label).text = "Chờ lưu"
				btn.disabled = true
			"maxed":
				(r["price"] as Label).text = "Tối đa"
				btn.disabled = true
		_set_font_color(r, "price", Color("7a8aa6") if btn.disabled else Color.WHITE)
		(r["cash_icon"] as TextureRect).modulate.a = 0.5 if btn.disabled else 1.0


## Đặt màu chữ của nhãn r[key] chỉ khi khác lần trước (nhớ trong chính dict của ô).
func _set_font_color(r: Dictionary, key: String, c: Color) -> void:
	var mem := "_color_" + key
	if r.has(mem) and r[mem] == c:
		return
	r[mem] = c
	(r[key] as Label).add_theme_color_override("font_color", c)


# ---------------------------------------------------------------- làm mới

func _select_tab(i: int) -> void:
	var fid := _tab_feature(i)
	if fid != "" and not GameState.feature_unlocked(fid):
		_toast_lock(fid)
		return
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
	_refresh_locks()
	_coin_label.text = Balance.fmt_compact(GameState.coins)
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
	if _active:
		_power_banner.observe_power(GameState.team_power())
	else:
		_power_banner.reset_power(GameState.team_power())
	_progress_label.text = Balance.league_name(GameState.business_tier)
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
var _trophy_group := "offense"  # nhóm đang xem ở bảng cúp


func _rebuild_league() -> void:
	_clear(_league_box)
	_build_trophy_panel()


## Bảng nâng cấp bằng cúp ở tab Giải (dựng trong ui/trophy_panel.gd).
func _build_trophy_panel() -> void:
	TrophyPanel.build(_league_box, _trophy_group, _set_trophy_group, _buy_trophy)


func _set_trophy_group(group: String) -> void:
	_sfx("ui_click")
	_trophy_group = group
	_rebuild_league()


func _buy_trophy(id: String) -> void:
	_sfx("ui_click")
	if not GameState.buy_trophy_upgrade(id):
		_show_toast("Chưa nâng được. Kiểm tra số cúp hoặc thử lưu lại.")


func _rebuild_shop() -> void:
	if not is_instance_valid(_shop_content):
		return
	_shop_content.update_daily(
		Balance.fmt_money(GameState.daily_gift_amount()),
		int(GameData.economy()["rewards"]["daily_gems"]),
		GameState.daily_available(), GameState.save_blocked or GameState.phase == "save_error")
	_shop_content.update_iap(_iap_view())
	_shop_content.update_ads(_ads_view())


## Dữ liệu IAP cho trang Shop (view không gọi autoload): {sku: {price, reason, first_bonus}} + trạng thái chung.
func _iap_view() -> Dictionary:
	var items := {}
	for p: Dictionary in Iap.products():
		var sku := String(p["sku"])
		items[sku] = {"price": Iap.price(sku), "reason": Iap.block_reason(sku),
			"first_bonus": p.has("first_bonus") and not sku in GameState.iap["first_bonus_used"]}
	return {"items": items, "busy": Iap.is_busy(), "restorable": Iap.restorable()}


## Dữ liệu thẻ quảng cáo cho trang Shop: {placement: {state, left, reward, entitled}}.
func _ads_view() -> Dictionary:
	var out := {}
	for pl in ["free_gems", "free_driver_coupon", "free_gear_coupon"]:
		var st: Dictionary = Ads.card_state(pl)
		st["reward"] = _ad_reward_text(pl)
		st["entitled"] = Ads.entitled()
		out[pl] = st
	return out


## Chữ phần thưởng của một placement quảng cáo miễn phí, đọc thẳng từ data/ads.json: "+5 gem", "+1 Coupon Pro".
func _ad_reward_text(pl: String) -> String:
	var cfg: Dictionary = (GameData.ads().get("placements", {}) as Dictionary).get(pl, {})
	match String(cfg.get("reward", "")):
		"gems":
			return "+%d gem" % int(cfg.get("amount", 0))
		"driver_coupon":
			return "+%d Coupon %s" % [int(cfg.get("count", 1)), String(cfg.get("kind", "")).capitalize()]
		"gear_coupon":
			return "+%d Coupon Gear" % int(cfg.get("count", 1))
	return ""


func _watch_shop_ad(pl: String) -> void:
	_sfx("ui_click")
	var done := func(r: Dictionary) -> void:
		var status := String(r.get("status", ""))
		if status in ["rewarded", "skipped_entitled"]:
			_sfx("daily_gift")
			_show_toast(_ad_reward_text(pl))
		else:
			_show_toast(Ads.status_text(status))
		_rebuild_shop()
	if Ads.has_pending(pl):
		Ads.retry_pending(pl, done)
	else:
		Ads.try_show_rewarded(pl, done)
	_rebuild_shop()


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
	_overlay_box.add_child(HdUi.close_header(title, _overlay.hide, 20))
	_overlay_box.add_child(_label(description, 14, C_TEXT, true))
	_overlay_box.add_child(_label("Sắp có · Gói này chưa mở bán. Nội dung và giá có thể thay đổi khi ra mắt.", 13, C_MUTED, true))
	var close := _button("Đã hiểu", true)
	close.pressed.connect(func() -> void: _overlay.hide())
	_overlay_box.add_child(close)


# ---------------------------------------------------------------- đua (UI chỉ đọc trạng thái từ GameState)

func _process(delta: float) -> void:
	if not _active:
		return
	_power_banner.set_suspended(not _race_block.visible or _overlay.visible or _result_panel.visible or (is_instance_valid(_profile) and _profile.visible))
	# Bảng tổng kết tự tắt sau RESULT_SHOW_SEC giây (thời gian thật) rồi thả đua tiếp.
	var modal_open: bool = _overlay.visible or (is_instance_valid(_profile) and _profile.visible) \
		or (is_instance_valid(_class_page) and _class_page.visible)
	_ads_controls.blocked = modal_open or _result_panel.visible or _tab != Tab.RACE or _tutorial.running \
		or _tutorial.intro != "" or GameState.phase != "racing"
	if _tutorial.intro != "":
		var tab_ok: bool = _tip_tab_ok(Tutorial.tip(_tutorial.intro)) if _tutorial.tip_mode else _intro_tab_ok(Tutorial.feature(_tutorial.intro))
		_tutorial.blocked = modal_open or _result_panel.visible or not tab_ok
	else:
		_tutorial.blocked = _tab != Tab.RACE or modal_open
		if not modal_open and not _result_panel.visible:
			_pump_intro()
	# A6 của hướng dẫn giữ bảng kết quả tới khi đọc xong (Design/23 §4).
	if _result_panel.visible and not _tutorial.holds_result():
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
		# Keep the flash inside the clipped race viewport and below result/profile/modal UI.
		var flash := (load(ROOT + "vfx/finish_flash.tscn") as PackedScene).instantiate() as Node2D
		flash.position = _race_view.size * 0.5
		flash.scale = Vector2.ONE * 2.0
		_race_view.add_child(flash)
		_race_view.move_child(flash, 0)


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
	_race_view.set_seats(Pricing.revenue_value("parking", int(gs.levels.get("parking", 0))))
	_race_view.queue_redraw()
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
	if int(res.get("trophies", 0)) > 0:
		_result_box.add_child(_result_row("Cúp", "+%d · có %d/%d" % [int(res["trophies"]), GameState.trophies_earned, GameState.trophy_cap()], C_GOLD.darkened(0.35)))
		_result_box.add_child(HSeparator.new())
	_result_box.add_child(_result_row("Điểm tuyển (SP)", "+%d" % Pricing.scout_points(int(res["points"])), Color("5d6b80")))
	for u: Dictionary in res.get("unlocked", []):
		_result_box.add_child(HSeparator.new())
		_result_box.add_child(_result_row("Mở khóa", String(u["name"]), C_GOLD.darkened(0.35)))
		if String(u.get("gift", "")) != "":
			_result_box.add_child(_result_row("Quà", String(u["gift"]), green.darkened(0.1)))
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
	if _tutorial.on_result(res) and is_instance_valid(_result_bar):
		_result_bar.hide()  # không đếm ngược khi Linh đang giải thích


## Overlay chỉ còn dùng cho báo cáo vắng mặt lúc vào game; kết quả/tổng kết là thông tin xem lại, không điều khiển đua.
func _open_next_overlay() -> void:
	if not GameState.offline_report.is_empty():
		_show_offline()
	else:
		_overlay.hide()


func _begin_overlay() -> void:
	_clear(_overlay_box)
	_overlay_box.add_theme_constant_override("separation", 8)
	(_overlay_box.get_parent().get_parent() as PanelContainer).add_theme_stylebox_override("panel", HdUi.panel(6.0))
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
	# Wrapped labels need the final width before their height can be measured.
	# A first-open measurement at the old/zero width makes the panel screen-high.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(sc):
		return
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


## Compact duration shared by the offline report and its configurable cap.
func _offline_duration(seconds: float) -> String:
	var minutes := int(maxf(seconds, 0.0) / 60.0)
	if minutes < 1:
		return "%d giây" % int(maxf(seconds, 0.0))
	if minutes < 60:
		return "%d phút" % minutes
	if minutes % 60 == 0:
		return "%d giờ" % (minutes / 60)
	return "%d giờ %d phút" % [minutes / 60, minutes % 60]


func _offline_center(text: String, font_size: int, color: Color = C_TEXT) -> Label:
	var label := _label(text, font_size, color, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _offline_row(parent: VBoxContainer, caption: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var key := _label(caption, 12, C_MUTED, true)
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(key)
	var number := _label(value, 13)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(number)


func _show_offline() -> void:
	GameState.note_offline_shown()  # mẹo C1 hiện sau khi người chơi đóng panel
	_begin_overlay()
	var rep: Dictionary = GameState.offline_report
	var elapsed := maxf(float(rep["elapsed"]), 0.0)
	var cap := GameState.offline_cap_sec_now()
	var eligible := float(rep.get("eligible", minf(elapsed, cap)))
	_overlay_box.add_theme_constant_override("separation", 12)
	var frame := _style(Color("dfedff"), 18, Color("81b3ed"), 2)
	frame.content_margin_left = 12
	frame.content_margin_right = 12
	frame.content_margin_top = 10
	frame.content_margin_bottom = 12
	frame.shadow_color = Color(0.03, 0.12, 0.25, 0.3)
	frame.shadow_size = 4
	(_overlay_box.get_parent().get_parent() as PanelContainer).add_theme_stylebox_override("panel", frame)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	_overlay_box.add_child(header)
	var title := _offline_center("THU NHẬP NGOẠI TUYẾN", 18)
	title.name = "OfflineTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	# Keep a single-line title at the largest size that fits each phone width.
	title.resized.connect(func() -> void:
		var font := title.get_theme_font("font")
		var font_size := 18
		while font_size > 10 and font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > title.size.x:
			font_size -= 1
		title.add_theme_font_size_override("font_size", font_size))
	var info := Button.new()
	info.name = "OfflineInfo"
	info.custom_minimum_size = Vector2(36, 44)
	info.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		info.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	info.icon = load(ROOT + "icons/vector/offline_info.svg")
	info.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.tooltip_text = "Chi tiết thu nhập ngoại tuyến"
	info.pressed.connect(func() -> void: _sfx("ui_click"))
	header.add_child(info)
	_overlay_box.add_child(_art("rewards/offline_garage.png", 145.0))
	_sfx("coin_pickup")
	var reward_panel := PanelContainer.new()
	reward_panel.add_theme_stylebox_override("panel", _style(Color("fff3cf"), 16, Color("efc465"), 1))
	_overlay_box.add_child(reward_panel)
	var reward_center := CenterContainer.new()
	reward_panel.add_child(reward_center)
	var reward_group := HBoxContainer.new()
	reward_group.add_theme_constant_override("separation", 8)
	reward_center.add_child(reward_group)
	reward_group.add_child(HdUi.icon("icons/cash.png", Vector2(42, 42)))
	var amount := _label("+%s" % Balance.fmt_money(rep["reward"]), 36, C_GOLD)
	amount.name = "OfflineAmount"
	reward_group.add_child(amount)
	var progress := ProgressBar.new()
	progress.name = "OfflineProgress"
	progress.custom_minimum_size.y = 14
	progress.show_percentage = false
	progress.max_value = maxf(cap, 1.0)
	progress.value = clampf(eligible, 0.0, cap)
	var track_style := _style(Color("9ebfe8"), 7)
	track_style.set_content_margin_all(0)
	progress.add_theme_stylebox_override("background", track_style)
	var progress_fill := _style(Color("ffbd35"), 7)
	progress_fill.content_margin_left = 0
	progress_fill.content_margin_right = 0
	progress_fill.content_margin_top = 0
	progress_fill.content_margin_bottom = 0
	progress.add_theme_stylebox_override("fill", progress_fill)
	_overlay_box.add_child(progress)
	var time_text := "%d/%d phút" % [int(eligible / 60.0), int(cap / 60.0)]
	if eligible >= cap:
		time_text = "Đã đầy · " + time_text
	_overlay_box.add_child(_offline_center(time_text, 16))
	var details_panel := PanelContainer.new()
	details_panel.name = "OfflineDetails"
	details_panel.add_theme_stylebox_override("panel", _style(Color("d1e7ff"), 14))
	_overlay_box.add_child(details_panel)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 6)
	details_panel.add_child(details)
	_offline_row(details, "Vắng mặt", _offline_duration(elapsed))
	_offline_row(details, "Tính thu nhập", _offline_duration(eligible))
	details.add_child(_offline_center("%s tiền/giây × %d%% hiệu suất" % [Balance.fmt_rate(rep["rate"]), int(float(rep["ratio"]) * 100.0)], 12))
	details.add_child(_offline_center("Chỉ tích lũy thu nhập cơ sở.\nĐội không đua; tiến trình giải được giữ nguyên.", 12, C_MUTED))
	details_panel.hide()
	info.pressed.connect(func() -> void:
		details_panel.visible = not details_panel.visible
		_fit_overlay.call_deferred())
	var button := _button("Tiếp tục", true)
	button.name = "OfflineContinue"
	button.custom_minimum_size.y = 52
	button.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := StyleBoxTexture.new()
		skin.texture = load(ROOT + "icons/vector/offline_continue.svg")
		skin.texture_margin_left = 24
		skin.texture_margin_right = 24
		skin.texture_margin_top = 24
		skin.texture_margin_bottom = 24
		skin.content_margin_left = 12
		skin.content_margin_right = 12
		skin.content_margin_top = 8
		skin.content_margin_bottom = 8
		if state == "hover":
			skin.modulate_color = Color(1.0, 1.0, 0.9)
		elif state == "pressed":
			skin.modulate_color = Color(0.9, 0.85, 0.7)
		button.add_theme_stylebox_override(state, skin)

	button.pressed.connect(func() -> void:
		GameState.offline_report = {}
		_open_next_overlay())
	_overlay_box.add_child(button)


# ---------------------------------------------------------------- hướng dẫn đầu game

func _start_tutorial() -> void:
	if _cli_tut_done:
		GameState.tutorial["state"] = "done"
	if _cli_gated:
		GameState.tutorial["gated"] = true
	if _cli_races >= 0:
		GameState.completed_races = _cli_races
	for pair in _cli_levels.split(",", false):
		var kv := pair.split(":")
		if kv.size() == 2 and GameState.levels.has(kv[0]):
			GameState.levels[kv[0]] = int(kv[1])
	if (_shot_prefix != "" or _auto_race) and not _cli_tutorial:
		return  # giữ nguyên ảnh chụp/auto-race cũ
	if _cli_tutorial_step != "" and Tutorial.is_step(_cli_tutorial_step):
		GameState.set_tutorial("active", _cli_tutorial_step, {"power_before": GameState.team_power()})
	if _tutorial.start() and _cli_tutorial_step != "":
		_tutorial._resumed = false  # nhảy bước để chụp ảnh: không phải người chơi quay lại


func _row_of(kind: String) -> Dictionary:
	for r: Dictionary in _rows:
		if r["kind"] == kind:
			return r
	return {}


## Tính năng điều khiển từng tab ("" = tab luôn mở).
func _tab_feature(tab: int) -> String:
	match tab:
		Tab.BAG:
			return "U3_bag"
		Tab.TEAM:
			return "U5_drivers"
		Tab.LEAGUE:
			return "U2_league"
		Tab.SHOP:
			return "U4_shop"
	return ""


func _toast_lock(fid: String) -> void:
	var f := Tutorial.feature(fid)
	if f.is_empty():
		return
	_sfx("ui_click")
	_show_toast("%s · %s" % [f["name"], Tutorial.lock_text(f, GameState.completed_races)])


## Cập nhật ổ khóa/chấm trên thanh điều hướng, nút Lịch/Class, avatar, nút Garage và dòng "Sắp mở".
func _refresh_locks() -> void:
	var shop_ad: bool = Ads.shop_ready()
	var sig := "%s|%d|%s|%s" % [GameState.gating_on(), GameState.completed_races, str(GameState.tutorial.get("intro_seen", [])), shop_ad]
	if sig == _lock_sig:
		return
	_lock_sig = sig
	var gated := GameState.gating_on()
	for i in _nav_items.size():
		var fid := _tab_feature(i)
		var open := fid == "" or GameState.feature_unlocked(fid)
		var item := _nav_items[i] as Control
		item.modulate = Color.WHITE if open else Color(0.62, 0.68, 0.8)
		(item.get_node("NavLock") as Control).visible = not open
		var new_feature := open and gated and fid != "" and not Tutorial.intro_seen(GameState, fid)
		(item.get_node("NavDot") as Control).visible = new_feature or (open and i == Tab.SHOP and shop_ad)
		_nav[i].accessibility_name = TAB_NAMES[i] + ("" if open else ", đã khóa")
	var u2 := GameState.feature_unlocked("U2_league")
	HdUi.style_button(_sched_btn, "race" if u2 else "cancel")
	_header_avatar.modulate = Color.WHITE if u2 else Color(0.62, 0.66, 0.76)
	HdUi.style_button(_class_btn, "race" if GameState.feature_unlocked("U7_class") else "cancel")
	_class_btn.clip_text = true
	_class_btn.text = "Class" if GameState.managed_class == GameState.active_class else String(GameData.race_class(GameState.managed_class).get("name", "Class"))
	var garage_btn: Button = _team_sub_buttons[1]
	garage_btn.icon = null if GameState.feature_unlocked("U6_garage") else _tex("icons/vector_dark/lock.svg")
	garage_btn.expand_icon = true
	garage_btn.add_theme_constant_override("icon_max_width", 18)
	var next := Tutorial.next_feature(GameState.completed_races)
	_next_label.visible = gated and not next.is_empty()
	if _next_label.visible:
		_next_label.text = "Sắp mở: %s · %d lượt nữa" % [next["name"], int(next["races"]) - GameState.completed_races]


## Tab (và tab con) mà hướng dẫn ngắn của một tính năng cần người chơi đang đứng ở đó.
func _intro_tab_ok(f: Dictionary) -> bool:
	match String(f.get("tab", "")):
		"race":
			return _tab == Tab.RACE
		"bag":
			return _tab == Tab.BAG
		"shop":
			return _tab == Tab.SHOP
		"league":
			return _tab == Tab.LEAGUE
		"team":
			return _tab == Tab.TEAM and _team_sub == 0
		"garage":
			return _tab == Tab.TEAM and _team_sub == 1
	return false


## Tính năng đã mở mà chưa xem hướng dẫn: hiện khi người chơi đứng đúng tab (một cái một lúc).
func _pump_intro() -> void:
	if _tutorial.running or _tutorial.intro != "":
		return
	if GameState.gating_on():
		for f: Dictionary in Tutorial.features():
			var id: String = f["id"]
			if GameState.feature_unlocked(id) and not Tutorial.intro_seen(GameState, id) and _intro_tab_ok(f):
				_tutorial.show_intro(id)
				return
	_pump_tip()


## Tab hiện tại dưới dạng khóa của mẹo ("" = tab không có mẹo riêng, chỉ nhận mẹo "any").
func _tip_tab() -> String:
	match _tab:
		Tab.RACE:
			return "race"
		Tab.BAG:
			return "bag"
		Tab.TEAM:
			return "team" if _team_sub == 0 else ""
	return ""


func _tip_tab_ok(t: Dictionary) -> bool:
	return t.is_empty() or t["tab"] == "any" or t["tab"] == _tip_tab()


## Mẹo theo tình huống (Phần C): sau mọi hướng dẫn, tối đa một mẹo mới mỗi lượt.
func _pump_tip() -> void:
	var info := Tutorial.next_tip(GameState, _tip_tab())
	if not info.is_empty():
		_tutorial.show_tip(String(info["id"]), info)


## "tile:<kind>" (ô nâng cấp) hoặc "node:<tên node>" -> Control, null nếu không có.
func _ctrl_for_spec(spec: String) -> Control:
	if spec.begins_with("tile:"):
		var row := _row_of(spec.substr(5))
		return row["tile"] if not row.is_empty() else null
	if spec.begins_with("node:"):
		return find_child(spec.substr(5), true, false) as Control
	return null


## Cuộn trang chứa `n` để mục tiêu hiện trong vùng nhìn.
func _reveal_node(n: Control) -> void:
	var p := n.get_parent()
	while p != null:
		if p is ScrollContainer:
			(p as ScrollContainer).ensure_control_visible(n)
			return
		p = p.get_parent()


## Mục tiêu spotlight của từng bước, theo tọa độ toàn cục.
func _tutorial_target(step: String, sub: int) -> Dictionary:
	if step.begins_with("tip:"):
		var tctrl := _ctrl_for_spec(String(_tutorial.tip_data.get("target", "")))
		if tctrl == null or not tctrl.is_visible_in_tree():
			return {}
		return {"rect": tctrl.get_global_rect()}
	if step.begins_with("intro:"):
		var f := Tutorial.feature(step.substr(6))
		var spec := String(f.get("target", ""))
		var ctrl: Control = null
		if spec.begins_with("tile:"):
			var row := _row_of(spec.substr(5))
			ctrl = row["tile"] if not row.is_empty() else null
		elif spec.begins_with("node:"):
			ctrl = find_child(spec.substr(5), true, false) as Control
		if ctrl == null or not ctrl.is_visible_in_tree():
			return {}
		var t := {"rect": ctrl.get_global_rect()}
		if sub == 0 and f.has("action"):
			t["hand"] = ctrl.get_global_rect().get_center()
		return t
	match step:
		"A2_car":
			var m: Dictionary = _race_view.player_marker()
			if float(m["r"]) <= 0.0:
				return {}
			var c: Vector2 = _race_view.get_global_transform() * (m["pos"] as Vector2)
			var r := float(m["r"]) * 2.2 + 10.0
			return {"rect": Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), "round": true}
		"A3_income":
			return {"rect": _coin_bar.get_global_rect()}
		"A4_engine", "A5_ticket":
			var row := _row_of("engine" if step == "A4_engine" else "ticket")
			if row.is_empty():
				return {}
			var t := {"rect": (row["tile"] as Control).get_global_rect()}
			if sub == 0:
				t["hand"] = (row["btn"] as Control).get_global_rect().get_center()
			return t
		"A6_result":
			if _result_panel.visible:
				return {"rect": (_result_box.get_parent() as Control).get_global_rect()}
		"A7_race2":
			if sub == 0:
				var hud := _race_view.hud_rank_rect()
				var left := Rect2(Vector2.ZERO, Vector2(hud.position.x, RaceView.HUD_H))
				return {"rect": Rect2(_race_view.get_global_transform() * left.position, left.size)}
	return {}


func _tutorial_context(step: String, res: Dictionary) -> Dictionary:
	match step:
		"A1_welcome":
			return {"coins": Balance.fmt_money(GameState.coins)}
		"A3_income":
			return {"rate": Balance.fmt_rate(GameState.online_rate())}
		"A4_engine":
			return {"price": Balance.fmt_money(GameState.cost_of("engine"))}
		"A5_ticket":
			return {"price": Balance.fmt_money(GameState.cost_of("ticket"))}
		"A6_result":
			return {"position": int(res.get("position", 8)), "money": Balance.fmt_money(res.get("money", 0))}
		"A7_race2":
			return {"before": RaceView.format_team_power(float(GameState.tutorial.get("power_before", 0.0))),
				"after": RaceView.format_team_power(GameState.team_power())}
	return {}


## Ô nâng cấp ở nhóm Doanh thu có thể nằm dưới mép màn: cuộn trang Đua tới ô đó.
func _tutorial_reveal(step: String) -> void:
	if step.begins_with("tip:"):
		var tc := _ctrl_for_spec(String(_tutorial.tip_data.get("target", "")))
		if tc != null:
			_reveal_node(tc)
		return
	if step.begins_with("intro:"):
		var spec := String(Tutorial.feature(step.substr(6)).get("target", ""))
		var ctrl: Control = null
		if spec.begins_with("tile:"):
			var row := _row_of(spec.substr(5))
			ctrl = row["tile"] if not row.is_empty() else null
		elif spec.begins_with("node:"):
			ctrl = find_child(spec.substr(5), true, false) as Control
		if ctrl != null:
			_reveal_node(ctrl)
		return
	if step != "A4_engine" and step != "A5_ticket":
		return
	var row := _row_of("engine" if step == "A4_engine" else "ticket")
	var sc := _pages[Tab.RACE] as ScrollContainer
	if not row.is_empty() and sc != null:
		sc.ensure_control_visible(row["tile"])


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
