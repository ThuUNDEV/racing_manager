extends Control
const RaceArt = preload("res://ui/race_hud_art.gd")
const CleanArt = preload("res://ui/clean_modern_art.gd")

const BigNumber = preload("res://core/math/big_number.gd")
const PowerIncreaseBanner = preload("res://ui/power_increase_banner.gd")
const PopupAnim = preload("res://ui/popup_anim.gd")
const TutorialMapFocus = preload("res://ui/tutorial_map_focus.gd")
## UI prototype: UI-01 Đua, UI-02 Tay đua (tối giản), UI-03 Garage, UI-04 Giải đấu,
## UI-05 Kết quả, UI-06 Thu nhập vắng mặt, UI-07 quà ngày. Dựng hoàn toàn bằng code.

## Bảng màu theo gói asset Racing UI HD (xanh UI, cam hành động, vàng thưởng, lá nhận; xem HdUi).
## Tên hằng giữ nguyên để phần code bên dưới không phải đổi: C_CYAN là màu nhấn (cam), C_PANEL là màu nền thẻ.
const ROOT := "res://assets/workshop_gp/"
const RACE_SPEED := 1.0  # thời gian đua = giờ thật; độ nhanh của xe nằm ở sim.json traffic.speed_scale
const HD := "res://assets/racing_ui_hd/"
const C_BG := Color("fff8ee")
const C_PANEL := HdUi.C_PANEL
const C_PANEL_HI := HdUi.C_PANEL_HI
const C_CYAN := HdUi.C_ORANGE
const C_GOLD := HdUi.C_GOLD
const C_TEXT := HdUi.C_TEXT
const C_MUTED := HdUi.C_MUTED
const C_RED := HdUi.C_RED
const C_GREEN := HdUi.C_GREEN

enum Tab { RACE, BAG, TEAM, LEAGUE, SHOP }
## Thứ tự hiển thị trên thanh dưới (trái → phải).
const NAV_ORDER := [Tab.SHOP, Tab.BAG, Tab.RACE, Tab.TEAM, Tab.LEAGUE]
const TAB_NAMES := ["main.race_2", "soft.bag", "main.team", "main.leagues", "main.shop"]
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
var _nav_pill: Panel
var _nav_inner_left: Panel
var _nav_inner_right: Panel
var _nav_amt: Array = []
var _nav_from: Array = []
var _nav_to: Array = []
var _nav_old := 0
var _nav_new := 0
var _nav_tween: Tween
var _nav_seen: Dictionary = {}
var _nav_icon_tween: Tween
var _nav_animated_icon: Control
const NAV_SEL_W := 1.0
const NAV_ICON_SEL := 42.0
const NAV_ICON_TOP := 8.0
const NAV_ICON_IDLE_TOP := 9.0
const NAV_DOT_SIZE := 13.0   # chấm báo, đặt lệch so với tâm icon
const NAV_DOT_DX := 25.0
const NAV_DOT_DY := 18.0
## Tab Race là tab chính nên luôn rộng hơn và icon to hơn các tab khác.
const NAV_RACE_W := 1.0
const NAV_RACE_ICON := 48.0
const NAV_RACE_ICON_IDLE := 46.0
const NAV_RACE_RAISE := 6.5
const CONTENT_SIDE := 12  # lề ngang vùng nội dung (cộng lề 4 của khung ngoài = 16)
const CONTENT_TOP := 10  # khoảng cách từ thanh trên tới nội dung
const NAV_BLEED := 10.0  # phần khay điều hướng lấn ra ngoài màn hình ở hai bên và đáy
const NAV_TRAY_COLOR := Color("fdf5ea")
const NAV_RIM_COLOR := Color("f3e8d6")
const NAV_TRAY_EDGE := Color("efe1cc")
const NAV_PILL_COLOR := Color("fcb744")
const NAV_PILL_EDGE := Color("e8962a")
const NAV_INNER_GAP := 2.5        # khe giữa tấm kem trong khay và mặt cam tab Đua
const NAV_INNER_TOP := 3.6        # tấm kem trong khay thấp hơn cạnh trên khay (dải viền nhạt)
const NAV_INNER_RADIUS := 10
const NAV_TRAY_TOP := -3.0        # cạnh trên khay, theo toạ độ của vùng tab
const NAV_HOLDER_H := 77.0
const NAV_PILL_BOTTOM := 66.0
const NAV_RACE_TOP := -1.0
const NAV_RACE_TOP_IDLE := 0.0
var _rows: Array = []
var _tab: int = Tab.RACE

var _pages_root: Control
var _coin_label: Label
var _gem_label: Label
var _promotion: Control
var _class_page: Control
## Icon quảng cáo pack ở dải chặng: kind -> {button, dot, skus}; _promo_seen đánh dấu pack đã bấm trong phiên (tắt chấm đỏ).
const PACK_PROMOS := [
	{"kind": "starter", "icon": "icons/pack_starter", "skus": ["starter_1", "starter_2", "starter_3"], "name": "shop.special_packs"},
	{"kind": "offer", "icon": "icons/pack_offer", "skus": ["offer_noads_bundle", "offer_combo_1", "offer_combo_2"], "name": "shop.special_packs"},
	{"kind": "weekly", "icon": "icons/pack_weekly", "skus": ["weekly_s", "weekly_m", "weekly_l", "weekly_xl"], "name": "shop.weekly_packs"},
	# Tiện ích vĩnh viễn (Design/28 §4.2). Icon tạm dùng icons/coin cho tới khi có icons/pack_perk.
	{"kind": "perk", "icon": "icons/coin", "skus": ["income_x2", "no_ads"], "name": "shop.more_perks"},
]
var _promo_ui: Dictionary = {}
var _promo_seen: Dictionary = {}
var _race_no_label: Label
var _income_label: Label
var _status_label: Label
var _save_err_box: PanelContainer
var _view_sim: TrafficSim = null # sim mà RaceView đang hiển thị
var _track_caption: Label
var _race_view_track: String = ""  # track RaceView đang vẽ (theo class đua)
var _race_view: RaceView
var _power_banner: Control
var _race_block: VBoxContainer   # Fixed circuit and HUD above the upgrade scroller.
var _upgrade_scroll: ScrollContainer
const STATUS_SLOT_H := 0.0  # Compact status row gives the race more vertical room.
const RACE_HEIGHT := 242.0  # Circuit height, scaled to the phone width.
var _drivers_box: VBoxContainer
var _roster: DriverRosterPage
var _league_box: VBoxContainer
var _shop_box: VBoxContainer
var _shop_content: VBoxContainer
var _toast: Label
var _overlay: Control
var _offline_popup_pending := false
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
## Bản này tạm ẩn Garage khỏi tab Đội (GaragePage vẫn dựng sẵn; đặt true để bật lại cùng tutorial U6_garage trong data/tutorial.json).
const TEAM_GARAGE_ENABLED := false
var _team_sub: int = 0
var _team_sub_buttons: Array = []
var _team_drivers_wrap: VBoxContainer
var _garage: GaragePage
var _gear: GearPage
var _catalog_buttons: Array = []

var _row_timer: float = 0.0
var _shop_iap_sig: int = 0
var _shop_ads_sig: int = 0
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
var _tutorial_map_focus := TutorialMapFocus.new()
var _coin_bar: Control
var _cli_tutorial: bool = false      # --tutorial: vẫn chạy hướng dẫn khi chụp ảnh/auto-race
var _cli_tutorial_step: String = ""  # --tutorial-step=A4_engine: nhảy tới bước (chụp ảnh kiểm tra)
var _cli_gated: bool = false         # --gated: bật lịch mở khóa dần (Design/23 §5) khi chụp ảnh
var _cli_races: int = -1             # --races=N: đặt số lượt đã hoàn tất (chụp ảnh các mốc mở khóa)
var _cli_tut_done: bool = false      # --tutorial-done: coi như xong Phần A (chụp ảnh mẹo Phần C)
var _cli_levels: String = ""         # --levels=ticket:23,parking:48: đặt cấp nâng cấp (chụp ảnh mẹo C4)
var _nav_items: Array = []           # ô điều hướng (chứa NavLock/NavDot)
var _toast_seq := 0
var _next_hint_key := ""             # khóa gợi ý "Sắp mở" đã báo (popup), tránh báo lặp
var _lock_sig := ""


## Gameplay được dựng phía sau màn loading (Design/09 §4): `_ready` chỉ chuẩn bị UI, `is_prepared`
## báo layout/vẽ đã xong, còn input/race/nhạc/panel chờ chỉ bật khi loading gọi `activate()`.
var is_prepared: bool = false
var _active: bool = false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot_prefix = a.substr(7)
			PopupAnim.enabled = false  # ảnh chụp kiểm thử cần popup hiện đủ ngay
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
	theme = HdUi.make_theme(CleanArt.asset(ROOT + "theme.tres") as Theme)
	_audio = (CleanArt.asset(ROOT + "components/workshop_audio.gd") as GDScript).new()
	add_child(_audio)
	_build_ui()
	resized.connect(_fit_overlay)
	resized.connect(_fit_race_view)
	_fit_race_view()
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
	_start_tutorial()
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
	# Cùng một bản nhạc chủ đề cho xưởng và đua: đang phát thì để chạy tiếp, không phát lại từ đầu.
	if _music_on and is_instance_valid(_music_player) and _music_player.playing:
		return
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
	var node := (CleanArt.asset(ROOT + "vfx/" + fx + ".tscn") as PackedScene).instantiate() as Node2D
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
	return CleanArt.asset(ROOT + path) as Texture2D


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
	_toast_seq += 1
	var seq := _toast_seq
	await get_tree().create_timer(3.0).timeout
	if seq == _toast_seq:  # chỉ toast mới nhất được tự tắt
		_toast.hide()


# ---------------------------------------------------------------- dựng UI

func _build_ui() -> void:
	# The resource and stage rows share the demo sky.
	var sky := ColorRect.new()
	sky.name = "PageBackground"
	sky.color = C_BG
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	var header_back := preload("res://ui/race_header_backdrop.gd").new()
	header_back.name = "SoftHeaderBackground"
	header_back.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header_back.offset_bottom = 46
	add_child(header_back)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 3)
	margin.add_child(root)

	# Positions and type sizes are measured on the approved 887px-wide demo.
	# One scaled canvas keeps icon, text, and spacing proportions at every width.
	var top := _header_canvas(root, 101.0)
	top.name = "ResourceHeader"
	for x in [391, 782]:
		var divider := _hud_divider()
		divider.custom_minimum_size = Vector2.ZERO
		_header_place(top, divider, Rect2(x, 21, 2, 57))
	_coin_label = _hud_label(48)
	_coin_bar = _hud_bar("icons/cash.png", _coin_label, 74)
	_coin_bar.name = "HudCoins"
	_header_place(top, _coin_bar, Rect2(18, 12, 352, 74))
	_gem_label = _hud_label(48)
	var gem_bar := _hud_bar("icons/gem.png", _gem_label, 74)
	gem_bar.name = "HudGems"
	_header_place(top, gem_bar, Rect2(414, 12, 352, 74))
	_hud_bar_link(_coin_bar, "cash", I18n.t("main.buy_cash"))
	_hud_bar_link(gem_bar, "gem", I18n.t("main.buy_gems"))
	var settings := Button.new()
	settings.name = "SettingsButton"
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		settings.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	settings.accessibility_name = I18n.t("common.settings")
	settings.pressed.connect(_show_settings)
	_header_place(top, settings, Rect2(801, 13, 74, 70))
	var settings_icon := _header_icon("icons/gear.png")
	settings.add_child(settings_icon)
	settings_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_toast = _label("", 12, C_RED, true)
	_toast.hide()
	root.add_child(_toast)

	_pages_root = Control.new()
	_pages_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pages_root.clip_contents = true
	# Vùng nội dung (giữa thanh trên và điều hướng) lùi vào CONTENT_SIDE hai bên, CONTENT_TOP phía trên.
	var content_margin := MarginContainer.new()
	content_margin.name = "ContentArea"
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", CONTENT_SIDE)
	content_margin.add_theme_constant_override("margin_right", CONTENT_SIDE)
	content_margin.add_theme_constant_override("margin_top", CONTENT_TOP)
	root.add_child(content_margin)
	content_margin.add_child(_pages_root)
	# Màn hẹp (<360): Shop còn đặt chiều rộng tối thiểu ~316, nên bỏ lề ngang để khỏi tràn.
	resized.connect(func() -> void:
		var side := CONTENT_SIDE if size.x >= 360.0 and _tab != Tab.SHOP else 0
		content_margin.add_theme_constant_override("margin_left", side)
		content_margin.add_theme_constant_override("margin_right", side))

	_build_race_page()
	_build_bag_page()
	_build_team_page()
	_build_league_page()
	_build_shop_page()

	# Khay kem tràn hai mép và sát đáy; tab Đua đặt trên một bệ kem nhô lên, tab đang chọn có mặt cam nổi nhẹ.
	var nav_frame := PanelContainer.new()
	nav_frame.name = "BottomNavigation"
	var nav_skin := _nav_tray_skin(0)
	nav_skin.content_margin_left = 3.0 + NAV_BLEED
	nav_skin.content_margin_right = 3.0 + NAV_BLEED
	nav_skin.content_margin_top = 3.0
	nav_skin.content_margin_bottom = 3.0 + NAV_BLEED
	nav_frame.add_theme_stylebox_override("panel", nav_skin)
	var nav_visible_h := NAV_HOLDER_H + 6.0
	var nav_spacer := Control.new()
	nav_spacer.name = "BottomNavigationSpace"
	nav_spacer.custom_minimum_size = Vector2(0, nav_visible_h)
	nav_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(nav_spacer)
	add_child(nav_frame)
	nav_frame.anchor_left = 0.0
	nav_frame.anchor_right = 1.0
	nav_frame.anchor_top = 1.0
	nav_frame.anchor_bottom = 1.0
	nav_frame.offset_left = -NAV_BLEED
	nav_frame.offset_right = NAV_BLEED
	nav_frame.offset_bottom = NAV_BLEED
	nav_frame.offset_top = -nav_visible_h
	var nav_holder := Control.new()
	nav_holder.custom_minimum_size = Vector2(0, NAV_HOLDER_H)
	nav_frame.add_child(nav_holder)
	var rim := ColorRect.new()
	rim.name = "NavRim"
	rim.color = NAV_RIM_COLOR
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rim.position = Vector2(-NAV_BLEED, NAV_TRAY_TOP)
	rim.size = Vector2(4000.0, NAV_INNER_TOP - NAV_TRAY_TOP)
	nav_holder.add_child(rim)
	_nav_inner_left = _nav_inner_panel()
	nav_holder.add_child(_nav_inner_left)
	_nav_inner_right = _nav_inner_panel()
	nav_holder.add_child(_nav_inner_right)
	# Mặt cam trượt giữa các tab, chỉ giữ cạnh đáy 3px để tạo độ nổi.
	_nav_pill = Panel.new()
	_nav_pill.name = "NavPill"
	_nav_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var selected_skin := HdUi.Soft.flat(NAV_PILL_COLOR, 0, 20)
	selected_skin.set_border_width_all(0)
	selected_skin.border_width_bottom = 3
	selected_skin.border_color = NAV_PILL_EDGE
	selected_skin.shadow_color = Color(0.55, 0.3, 0.05, 0.18)
	selected_skin.shadow_size = 3
	selected_skin.shadow_offset = Vector2(0, 2)
	_nav_pill.add_theme_stylebox_override("panel", selected_skin)
	nav_holder.add_child(_nav_pill)
	nav_holder.resized.connect(func() -> void: _nav_apply(1.0, true))
	var nav := HBoxContainer.new()
	nav.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nav.add_theme_constant_override("separation", 0)
	nav_holder.add_child(nav)
	for i in TAB_NAMES.size():
		var item := Control.new()
		item.custom_minimum_size = Vector2(0, NAV_HOLDER_H)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(item)
		var b := _button("", false, 44.0, "tab")
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.offset_top = -NAV_RACE_RAISE if i == Tab.RACE else 0.0
		b.offset_left = 0.0
		b.offset_right = 0.0
		b.accessibility_name = I18n.t(TAB_NAMES[i])
		# Khay đã xanh sẵn và NavPill lo tab đang chọn: nút chỉ nhận chạm, không vẽ nền
		# (nền nút bo góc từng ô làm lộ vệt sáng ở khe giữa các tab).
		for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		b.pressed.connect(_select_tab.bind(i))
		item.add_child(b)
		var ic := HdUi.icon("icons/%s.png" % TAB_ICONS[i], Vector2(32, 32))
		ic.set_anchors_preset(Control.PRESET_CENTER_TOP)
		ic.offset_left = -16.0
		ic.offset_right = 16.0
		ic.offset_top = 4.0
		ic.offset_bottom = 36.0
		ic.name = "NavIcon"
		item.add_child(ic)
		ic.resized.connect(func() -> void: ic.pivot_offset = ic.size * 0.5)
		var lab := _label(I18n.t(TAB_NAMES[i]), 15, HdUi.Soft.INK)
		lab.name = "NavLabel"
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		var lab_lift := 0.0
		lab.offset_top = -33.0 - lab_lift
		lab.offset_bottom = -15.0 - lab_lift
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(lab)
		item.resized.connect(_fit_nav_label.bind(lab, item))
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
		dsb.set_border_width_all(0)
		dsb.set_corner_radius_all(7)
		dot.add_theme_stylebox_override("panel", dsb)
		dot.set_anchors_preset(Control.PRESET_CENTER_TOP)
		dot.hide()
		item.add_child(dot)
		lab.modulate.a = 0.0
		_nav_items.append(item)
		_nav.append(b)
		_nav_amt.append(0.0)

	for slot in NAV_ORDER.size():
		nav.move_child(_nav_items[NAV_ORDER[slot]], slot)

	_promotion = preload("res://ui/promotion_popup.gd").new()
	_promotion.name = "PromotionPopup"
	_promotion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_promotion)
	_promotion.hide()
	_promotion.notice.connect(_show_toast)
	_class_page = preload("res://ui/class_page.gd").new()
	_class_page.name = "ClassPage"
	_class_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_class_page)
	_class_page.hide()
	_build_overlay()
	_tutorial = TutorialOverlay.new()
	_tutorial.name = "TutorialOverlay"
	_tutorial.target_provider = _tutorial_target
	_tutorial.context_provider = _tutorial_context
	_tutorial.result_released.connect(func() -> void: _result_panel.hide())
	_tutorial.reveal_requested.connect(_tutorial_reveal)
	add_child(_tutorial)


## Lay out a demo-sized canvas, scaling the entire row rather than squeezing labels.
func _header_canvas(parent: Control, height: float) -> Control:
	var slot := Control.new()
	parent.add_child(slot)
	var canvas := Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.size = Vector2(887, height)
	slot.add_child(canvas)
	var fit := func() -> void:
		var factor := (slot.size.x + 8.0) / 887.0
		canvas.position.x = -4.0
		canvas.scale = Vector2.ONE * factor
		slot.custom_minimum_size.y = height * factor
	slot.resized.connect(fit)
	fit.call()
	return canvas


func _header_icon(path: String) -> TextureRect:
	var art := TextureRect.new()
	art.texture = HdUi.tex(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


func _header_place(parent: Control, child: Control, rect: Rect2) -> void:
	parent.add_child(child)
	child.position = rect.position
	child.size = rect.size


## Vạch đứng mảnh ngăn các khối trên thanh tài nguyên.
func _hud_divider() -> Control:
	var d := ColorRect.new()
	d.color = Color(1, 1, 1, 0.55)
	d.custom_minimum_size = Vector2(2, 34)
	d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


## Viền sáng quanh chữ đậm để đọc được khi nằm trên ảnh nền sân đua.
func _halo(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.95))
	l.add_theme_constant_override("outline_size", 5)


## Nhãn trong thanh tài nguyên: chữ trắng đậm có viền, căn giữa.
func _hud_label(size: int) -> Label:
	var l := _label("", size, Color.WHITE)
	l.add_theme_color_override("font_outline_color", HdUi.C_OUTLINE)
	HdUi.text_depth(l, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	l.resized.connect(_fit_hud_label.bind(l, size))
	return l


## Thu nhỏ chữ vừa đủ để số không bị cắt trong ô tiền/gem hẹp (không đổi kích thước ô).
func _fit_hud_label(l: Label, max_size: int = 16, min_size: int = 10) -> void:
	var avail := l.size.x
	if avail <= 4.0 or l.text.is_empty():
		return
	var font := l.get_theme_font("font")
	var s := max_size
	while s > min_size and font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x + 2.0 > avail:
		s -= 1
	if l.get_theme_font_size("font_size") != s:
		l.add_theme_font_size_override("font_size", s)


## Thanh tài nguyên dạng viên thuốc xanh đậm, icon lớn đè lên mép trái.
func _hud_bar(icon_rel: String, label: Label, h: float) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size.y = h
	var pc := Panel.new()
	pc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pc.offset_left = 16
	pc.offset_top = 8
	pc.offset_bottom = -8
	pc.add_theme_stylebox_override("panel", HdUi.Soft.surface("hud", Vector4.ZERO))
	wrap.add_child(pc)
	var ic := _header_icon(icon_rel)
	_header_place(wrap, ic, Rect2(0, 0, 78, h))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 78
	label.offset_right = -58
	wrap.add_child(label)
	var plus_bg := TextureRect.new()
	plus_bg.texture = HdUi.Soft.texture("plus_button")
	plus_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plus_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plus_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plus_bg.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	plus_bg.offset_left = -54
	plus_bg.offset_right = -4
	plus_bg.offset_top = -25
	plus_bg.offset_bottom = 25
	wrap.add_child(plus_bg)
	return wrap


## Phủ nút trong suốt lên thanh tài nguyên: bấm để nhảy sang Shop, cuộn tới gói tương ứng.
func _hud_bar_link(bar: Control, kind: String, hint: String) -> void:
	var b := Button.new()
	b.name = "Link_" + kind
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.accessibility_name = hint
	b.pressed.connect(_open_shop_section.bind(kind))
	bar.add_child(b)


func _open_shop_section(kind: String) -> void:
	_select_tab(Tab.SHOP)
	if _tab == Tab.SHOP and is_instance_valid(_shop_content):
		_shop_content.scroll_to_section(kind)


## Fixed page shell; children choose which region can scroll.
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
	v.add_theme_constant_override("separation", 5)
	sc.add_child(v)
	_pages.append(sc)
	return v


## Keep the stage and circuit fixed; only upgrades scroll in the remaining space.
func _build_race_page() -> void:
	var v := _make_fixed_page()
	v.name = "RacePage"
	_race_block = VBoxContainer.new()
	_race_block.add_theme_constant_override("separation", 0)
	v.add_child(_race_block)
	_build_race_block(_race_block)
	_upgrade_scroll = preload("res://ui/touch_scroll.gd").new()
	_upgrade_scroll.name = "UpgradeScroll"
	_upgrade_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_upgrade_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_upgrade_scroll)
	var upgrades := VBoxContainer.new()
	upgrades.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_scroll.add_child(upgrades)
	_build_upgrade_grid(upgrades)


## Keep the circuit readable without pushing navigation off short phone screens.
func _fit_race_view() -> void:
	if _race_view == null:
		return
	_race_view.custom_minimum_size.y = (size.x - 8.0) * 0.75



func _build_race_block(v: VBoxContainer) -> void:
	_race_view = RaceView.new()
	_race_view.name = "FixedRaceCluster"
	_race_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_race_view.custom_minimum_size = Vector2(0, RACE_HEIGHT)
	v.add_child(_race_view)
	var canvas := Control.new()
	canvas.name = "RaceHudCanvas"
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.size = Vector2(1448, 1086)
	_race_view.add_child(canvas)
	var fit := func() -> void: canvas.scale = Vector2.ONE * _race_view.size.x / 1448.0
	_race_view.resized.connect(fit)
	fit.call()
	# Huy hiệu hạng góc trái: bấm để mở bảng thăng hạng.
	var stage := Button.new()
	stage.name = "RaceStageRow"
	stage.accessibility_name = I18n.t("promotion.title")
	for state in ["normal", "hover", "pressed", "disabled"]:
		stage.add_theme_stylebox_override(state, RaceArt.hud_skin("rank_cream"))
	stage.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	stage.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	stage.pressed.connect(_show_promotion)
	canvas.add_child(stage)
	RaceArt.place(stage, Rect2(30, 20, 172, 111))
	RaceArt.image(stage, "icons/trophy", Rect2(22, 7, 128, 97))
	# Race count remains internal; the reviewed HUD shows only the rank.
	_race_no_label = Label.new()
	_race_no_label.name = "RaceNumberLabel"
	_race_no_label.hide()
	canvas.add_child(_race_no_label)
	var facilities := Button.new()
	facilities.name = "FacilitiesButton"
	facilities.accessibility_name = I18n.t("soft.facilities")
	RaceArt.button_skin(facilities, "facilities_orange")
	for state in ["normal", "hover", "pressed", "disabled"]:
		facilities.add_theme_stylebox_override(state, RaceArt.hud_skin("facilities_orange"))
	facilities.pressed.connect(_show_classes)
	canvas.add_child(facilities)
	RaceArt.place(facilities, Rect2(1078, 20, 340, 111))
	RaceArt.image(facilities, "icons/facility", Rect2(18, 8, 124, 94))
	var facility_label := _label(I18n.t("soft.facilities"), 57, Color.WHITE)
	facility_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	facility_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	facility_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	facility_label.clip_text = true
	facilities.add_child(facility_label)
	RaceArt.place(facility_label, Rect2(142, 4, 190, 100))
	var chip := Panel.new()
	chip.name = "IncomePill"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", RaceArt.hud_skin("income_green"))
	canvas.add_child(chip)
	RaceArt.place(chip, Rect2(240, 20, 420, 111))
	var cash_icon := _header_icon("icons/cash.png")
	chip.add_child(cash_icon)
	RaceArt.place(cash_icon, Rect2(10, 9, 90, 90))
	_income_label = _label("", 56, Color.WHITE)
	_income_label.name = "IncomeLabel"
	_income_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_income_label.clip_text = true
	chip.add_child(_income_label)
	RaceArt.place(_income_label, Rect2(108, 4, 300, 99))
	var strip := Control.new()
	strip.name = "ActionStrip"
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(strip)
	var strip_canvas := Control.new()
	strip_canvas.name = "ActionStripCanvas"
	strip_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip_canvas.size = Vector2(1448, 225)
	strip.add_child(strip_canvas)
	var fit_strip := func() -> void:
		var k: float = maxf(strip.size.x, 1.0) / 1448.0
		strip_canvas.scale = Vector2.ONE * k
		strip.custom_minimum_size.y = 225.0 * k
	strip.resized.connect(fit_strip)
	fit_strip.call()
	var strip_row := HBoxContainer.new()
	strip_row.name = "ActionStripRow"
	strip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	strip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip_row.add_theme_constant_override("separation", 36)
	strip_canvas.add_child(strip_row)
	RaceArt.place(strip_row, Rect2(0, 10, 1448, 205))
	var boost_slot := Control.new()
	boost_slot.name = "BoostSlot"
	boost_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boost_slot.custom_minimum_size = Vector2(260, 205)
	strip_row.add_child(boost_slot)
	_build_pack_promos(strip_row)
	_race_view_track = GameData.class_track(GameState.race_class_id)
	_race_view.set_track(_race_view_track)
	_ads_controls = AdsRaceControls.new()
	_race_view.add_child(_ads_controls)
	_ads_controls.dock_chip(boost_slot)
	_power_banner = PowerIncreaseBanner.new()
	_race_view.add_child(_power_banner)
	_build_race_result_panel()
	# The caption always follows the active simulation circuit.
	var track: Dictionary = GameData.track(_race_view_track)
	_track_caption = _label(String(track.get("name", _race_view_track)), 11, C_MUTED)
	_track_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_track_caption.clip_text = true
	v.add_child(_track_caption)
	_track_caption.hide()

	_status_label = _label("", 14, C_TEXT)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.clip_text = true
	_status_label.custom_minimum_size = Vector2(0, STATUS_SLOT_H)
	_status_label.hide()
	v.add_child(_status_label)
	_status_label.hide()

	# Lỗi lưu khi chốt kết quả: giữ giao dịch đang chờ, cho thử lại (Design/10 §5).
	_save_err_box = PanelContainer.new()
	var eh := HBoxContainer.new()
	eh.add_theme_constant_override("separation", 8)
	_save_err_box.add_child(eh)
	var el := _label(I18n.t("main.could_not_save_race_result"), 12, C_RED, true)
	eh.add_child(el)
	var retry := _button(I18n.t("common.retry"), true, 44.0)
	retry.custom_minimum_size = Vector2(88, 44)
	retry.pressed.connect(func() -> void: GameState.retry_save())
	eh.add_child(retry)
	_save_err_box.hide()
	v.add_child(_save_err_box)


func _build_pack_promos(strip_row: HBoxContainer) -> void:
	for promo: Dictionary in PACK_PROMOS:
		var kind := String(promo["kind"])
		var button := Button.new()
		button.name = "PackPromo_" + kind
		button.accessibility_name = I18n.t(String(promo["name"]))
		RaceArt.button_skin(button, "reward_cream")
		button.custom_minimum_size = Vector2(260, 205)
		button.pressed.connect(_open_pack_promo.bind(kind))
		strip_row.add_child(button)
		RaceArt.image(button, String(promo["icon"]), Rect2(35, 28, 190, 149))
		var dot := Panel.new()
		dot.name = "Dot"
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dot_skin := StyleBoxTexture.new()
		dot_skin.texture = RaceArt.texture("icons/notification")
		dot.add_theme_stylebox_override("panel", dot_skin)
		button.add_child(dot)
		RaceArt.place(dot, Rect2(207, 9, 40, 40))
		_promo_ui[kind] = {"button": button, "dot": dot, "skus": promo["skus"], "sku": ""}
	_refresh_pack_promos()


## Pack đầu tiên của nhóm còn mua được (cùng nguồn sự thật với thẻ trong Shop: Iap.block_reason).
func _pack_promo_sku(skus: Array) -> String:
	for sku: String in skus:
		# Đã có thẻ "Đội tự do + quà" (cùng quyền lợi, nhiều quà hơn) thì không quảng cáo no_ads đơn lẻ.
		if sku == "no_ads" and Iap.block_reason("offer_noads_bundle") in ["", "busy"]:
			continue
		if Iap.block_reason(sku) in ["", "busy"]:
			return sku
	return ""


func _refresh_pack_promos() -> void:
	for kind: String in _promo_ui:
		var entry: Dictionary = _promo_ui[kind]
		var sku := _pack_promo_sku(entry["skus"])
		entry["sku"] = sku
		(entry["button"] as Button).visible = sku != ""
		(entry["dot"] as Control).visible = sku != "" and not _promo_seen.has(sku)


func _open_pack_promo(kind: String) -> void:
	var sku := String((_promo_ui[kind] as Dictionary)["sku"])
	if sku == "":
		return
	_promo_seen[sku] = true
	_refresh_pack_promos()
	_show_iap_detail(sku)


func _build_upgrade_grid(v: VBoxContainer) -> void:
	v.add_theme_constant_override("separation", 8)
	for group in [[I18n.t("main.race_car"), "icons/car_red.png", Balance.PARTS, "CarUpgradeGrid"], [I18n.t("main.revenue"), "icons/coins.png", Balance.REVENUE, "RevenueUpgradeGrid"]]:
		_section_head(v, group[0], group[1])
		var grid := GridContainer.new()
		grid.name = group[3]
		grid.columns = 1
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 1)
		v.add_child(grid)
		for kind: String in group[2]:
			_add_tile(grid, kind)


## Tiêu đề nhóm theo mẫu: dải đua thấp, đầu chéo và vạch tốc độ.
func _section_head(parent: Control, text: String, icon_rel: String) -> void:
	var ribbon := preload("res://ui/racing_section_header.gd").new()
	ribbon.name = "CarSectionHeader" if text == I18n.t("main.race_car") else "RevenueSectionHeader"
	ribbon.title = text
	ribbon.icon_texture = HdUi.tex("icons/flag.png") if text == I18n.t("main.race_car") else HdUi.tex(icon_rel)
	ribbon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(ribbon)


func _build_team_page() -> void:
	var page := _make_page()
	# Đội có hai mục con: Tay đua / Garage (Design/15 §3).
	var tabs := PanelContainer.new()
	tabs.name = "TeamTabs"
	tabs.visible = TEAM_GARAGE_ENABLED
	var track := StyleBoxFlat.new()
	track.bg_color = Color("e9f3f5")
	track.border_color = Color("d1e4e8")
	track.set_border_width_all(1)
	track.set_corner_radius_all(15)
	track.set_content_margin_all(4)
	tabs.add_theme_stylebox_override("panel", track)
	page.add_child(tabs)
	var sub := HBoxContainer.new()
	sub.add_theme_constant_override("separation", 4)
	tabs.add_child(sub)
	_team_sub_buttons = [_button(I18n.t("common.drivers"), false, 44.0), _button("Garage", false, 44.0)]
	for i in _team_sub_buttons.size():
		var sb: Button = _team_sub_buttons[i]
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.size_flags_stretch_ratio = 1.0
		sb.toggle_mode = true
		sb.clip_text = true
		sb.pressed.connect(_select_team_sub.bind(i))
		sub.add_child(sb)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 5)
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
	_roster.shop_requested.connect(_open_shop_section.bind("packs"))
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
		_style_team_tab(b, on)
	if i == 1:
		_garage.refresh()


func _style_team_tab(button: Button, selected: bool) -> void:
	button.set_pressed_no_signal(selected)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var skin := StyleBoxFlat.new()
		skin.set_corner_radius_all(11)
		skin.content_margin_left = 12
		skin.content_margin_right = 12
		skin.bg_color = Color("ff9225") if selected else Color("fff7e9")
		if state in ["hover", "hover_pressed"]:
			skin.bg_color = Color("ffad45") if selected else Color("d2e3f1")
		elif state == "pressed":
			skin.bg_color = Color("ed7e19") if selected else Color("c5dbed")
		button.add_theme_stylebox_override(state, skin)
	HdUi.ButtonSkin.apply(button)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("69b9ff")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(11)
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color.WHITE if selected else Color("47627b"))
	button.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size", 0)


func _build_bag_page() -> void:
	var v := _make_page()  # cả trang Túi cuộn (khung đua ghim chiếm chỗ phía trên)
	_gear = GearPage.new()
	_gear.open_requested.connect(_on_gear_open)
	_gear.info_requested.connect(_show_gear_info)
	_gear.shop_requested.connect(_open_shop_section.bind("packs"))
	_gear.upgrade_requested.connect(_on_gear_upgrade)
	v.add_child(_gear)


## Bảng tỉ lệ gói phụ kiện: hai hàng xác suất bậc, đóng không mua gì.
func _show_gear_info(pack_id: String) -> void:
	var pack := GameData.gear_pack(pack_id)
	if pack.is_empty():
		return
	_sfx("ui_click")
	_begin_overlay()
	_overlay_box.add_child(HdUi.close_header(I18n.t("main.rates") % pack["name"], _close_overlay))
	var tiers: Dictionary = pack["tiers"]
	var keys: Array = tiers.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return float(tiers[a]) > float(tiers[b]))
	for k: String in keys:
		var row := _label("%s: %s%%" % [String(k).capitalize(), str(snappedf(float(tiers[k]), 0.01))], 15)
		_overlay_box.add_child(row)
	_overlay_box.add_child(_label(I18n.t("main.one_coupon_one_pull_if"), 12, C_MUTED, true))


func _on_gear_open(pack_id: String, count: int) -> void:
	if _pack_is_opening():
		return
	var out := GameState.open_gear_pack(pack_id, count)
	if out.is_empty():
		_show_toast(I18n.t("main.cannot_open_pack_check_gems"))
		_gear.refresh()
		return
	_show_gear_result(out)
	_animate_pack_opening("gear", pack_id, count)
	_gear.refresh()


func _show_gear_result(out: Dictionary) -> void:
	_begin_overlay()
	_overlay_box.add_child(_label(I18n.t("main.pack_results"), 18))
	var pay: Dictionary = out["payment"]
	var paid := "%d coupon" % int(pay["amount"]) if pay["method"] == "coupon" else "%d gem" % int(pay["amount"])
	_overlay_box.add_child(_label(I18n.t("main.used") + paid, 12, C_MUTED))
	for e: Dictionary in out["results"]:
		var item := GameData.gear_item(String(e["id"]))
		var line := "%s · %s" % [item["name"], String(item["rarity"]).capitalize()]
		line += I18n.t("main.new") if e["is_new"] else I18n.tn("main.duplicate_plus_shards", int(e["shards"])) % int(e["shards"])
		var reward := HBoxContainer.new()
		reward.add_child(ExpansionArt.icon(String(e["id"]), Vector2(48, 48)))
		var reward_text := _label(line, 13, C_GREEN if e["is_new"] else C_TEXT, true)
		reward_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reward.add_child(reward_text)
		_overlay_box.add_child(reward)
	var ok := _button(I18n.t("main.done"), true)
	ok.pressed.connect(func() -> void: _close_overlay())
	_overlay_box.add_child(ok)


## Bảng tỉ lệ gói tay đua: các hàng xác suất bậc và bảo đảm; đóng không mua gì.
func _show_driver_info(pack_id: String) -> void:
	var pack := GameData.driver_pack(pack_id)
	if pack.is_empty():
		return
	_sfx("ui_click")
	_begin_overlay()
	_overlay_box.add_child(HdUi.close_header(I18n.t("main.rates") % pack["name"], _close_overlay))
	var tiers: Dictionary = pack["tiers"]
	var keys: Array = tiers.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return float(tiers[a]) > float(tiers[b]))
	for k: String in keys:
		_overlay_box.add_child(_label("%s: %s%%" % [String(k).capitalize(), str(snappedf(float(tiers[k]), 0.01))], 15))
	_overlay_box.add_child(_label(I18n.t("main.guarantee_after_pulls_row_without") % [int(pack["pity_draws"]) - 1, String(pack["pity_tier"]).capitalize(), int(pack["pity_draws"])], 12, C_MUTED, true))
	_overlay_box.add_child(_label(I18n.t("main.duplicate_drivers_turn_into_shards"), 12, C_MUTED, true))


func _on_driver_open(pack_id: String, count: int) -> void:
	if _pack_is_opening():
		return
	var out := GameState.open_driver_pack(pack_id, count)
	if out.is_empty():
		_show_toast(I18n.t("main.cannot_open_pack_check_gems"))
		_roster.refresh()
		return
	_show_driver_result(out)
	_animate_pack_opening("driver", pack_id, count)
	_roster.refresh()


func _show_driver_result(out: Dictionary) -> void:
	_begin_overlay()
	_overlay_box.add_child(_label(I18n.t("main.pack_results"), 18))
	var pay: Dictionary = out["payment"]
	var paid := "%d coupon" % int(pay["amount"]) if pay["method"] == "coupon" else "%d gem" % int(pay["amount"])
	_overlay_box.add_child(_label(I18n.t("main.used") + paid, 12, C_MUTED))
	for e: Dictionary in out["results"]:
		var d := GameData.driver(String(e["id"]))
		var tier_name := String(GameData.driver_tier_ids()[int(d["tier"])]).capitalize()
		var line := "%s · %s" % [d["name"], tier_name]
		line += I18n.t("main.new") if e["is_new"] else I18n.tn("main.duplicate_plus_shards", int(e["shards"])) % int(e["shards"])
		var reward := HBoxContainer.new()
		reward.add_child(ExpansionArt.icon(String(e["id"]), Vector2(48, 48)))
		var reward_text := _label(line, 13, C_GREEN if e["is_new"] else C_TEXT, true)
		reward_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reward.add_child(reward_text)
		_overlay_box.add_child(reward)
	var ok := _button(I18n.t("main.done"), true)
	ok.pressed.connect(func() -> void: _close_overlay())
	_overlay_box.add_child(ok)


func _pack_is_opening() -> bool:
	var opening := _overlay_box.get_node_or_null("PackOpening")
	return _overlay.visible and opening != null and not opening.completed


func _animate_pack_opening(kind: String, pack_id: String, count: int) -> void:
	# Keep the committed result in this same overlay. Closing or replacing it
	# destroys the animation too, so a delayed callback cannot reopen a popup.
	var results := VBoxContainer.new()
	results.name = "PackResultContent"
	results.add_theme_constant_override("separation", 8)
	for child in _overlay_box.get_children():
		_overlay_box.remove_child(child)
		results.add_child(child)
	results.hide()
	_overlay_box.add_child(results)
	var opening := preload("res://ui/pack_opening.gd").new()
	var pack := GameData.driver_pack(pack_id) if kind == "driver" else GameData.gear_pack(pack_id)
	var art_path := "res://assets/shop_horizontal_v1/pack_%s_%s.png" % [kind, pack_id]
	opening.setup(load(art_path) as Texture2D, "%s ×%d" % [String(pack.get("name", "")), count], pack_id in ["elite", "allstar"])
	opening.finished.connect(func() -> void:
		if not _overlay.visible or not results.is_inside_tree():
			return
		results.show()
		_sfx("daily_gift")
		if PopupAnim.motion_on():
			results.modulate.a = 0.0
			results.create_tween().tween_property(results, "modulate:a", 1.0, 0.22)
		_fit_overlay.call_deferred())
	_overlay_box.add_child(opening)
	_overlay_box.move_child(opening, 0)
	_fit_overlay.call_deferred()


func _on_gear_upgrade(gear_id: String) -> void:
	if GameState.upgrade_gear(gear_id):
		_sfx("ui_click")
	else:
		_show_toast(I18n.t("common.not_enough_shards_or_save"))
	_gear.refresh()


func _build_league_page() -> void:
	_league_box = _make_page()
	var background := StyleBoxFlat.new()
	background.bg_color = Color("fff8ee")
	background.content_margin_top = 12
	background.content_margin_bottom = 12
	(_league_box.get_parent() as ScrollContainer).add_theme_stylebox_override("panel", background)


func _build_shop_page() -> void:
	_shop_box = _make_page()
	# Lề ngang chung 8 cho mọi khối Shop (tiêu đề, thẻ miễn phí, gói đặc biệt đều thẳng hàng).
	var shop_panel := StyleBoxFlat.new()
	shop_panel.bg_color = preload("res://ui/shop_demo_theme.gd").BG
	shop_panel.content_margin_left = 8
	shop_panel.content_margin_right = 8
	(_shop_box.get_parent() as ScrollContainer).add_theme_stylebox_override("panel", shop_panel)
	_shop_content = (CleanArt.asset("res://ui/shop_page.gd") as GDScript).new()
	_shop_box.add_child(_shop_content)

	_shop_content.daily_requested.connect(_claim_shop_daily)
	_shop_content.offer_requested.connect(_show_shop_offer)
	_shop_content.iap_requested.connect(_buy_iap)
	_shop_content.restore_requested.connect(_restore_iap)
	_shop_content.details_requested.connect(_show_iap_detail)
	_shop_content.odds_requested.connect(_show_iap_odds)
	_shop_content.ad_requested.connect(_watch_shop_ad)
	_shop_content.pack_open_requested.connect(func(kind: String, id: String, n: int) -> void:
		if kind == "driver":
			_on_driver_open(id, n)
		else:
			_on_gear_open(id, n)
		_rebuild_shop())
	_shop_content.pack_info_requested.connect(func(kind: String, id: String) -> void:
		if kind == "driver":
			_show_driver_info(id)
		else:
			_show_gear_info(id))
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
			_show_toast(I18n.t("main.purchase_successful") + (" · +%d gem" % int(g["gems"]) if int(g.get("gems", 0)) > 0 else ""))
		"pending":
			_show_toast(I18n.t("main.waiting_payment_finish"))
		"invalid":
			_show_toast(I18n.t("main.invalid_transaction"))
		"failed":
			_show_toast(I18n.t("main.paid_but_save_failed_reopen"))
		"cancelled", "busy":
			pass
		"blocked":
			_show_toast(I18n.t("main.this_pack_not_available_buy"))
		_:
			_show_toast(I18n.t("main.could_not_buy_try_again"))
	_refresh()


func _restore_iap() -> void:
	_sfx("ui_click")
	Iap.restore(_on_iap_restored)


func _on_iap_restored(r: Dictionary) -> void:
	_show_toast(I18n.t("main.purchases_restored") if String(r.get("status", "")) == "ok" else I18n.t("main.could_not_restore_purchases_try"))
	_refresh()


func _show_promotion() -> void:
	if not GameState.feature_unlocked("U2_league"):
		_toast_lock("U2_league")
		return
	_promotion.open()


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
	var title := _label(I18n.t("common.settings"), 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(HdUi.close_button(_close_overlay, "SettingsClose"))
	var divider := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = Color("639ce8")
	line.thickness = 2
	divider.add_theme_stylebox_override("separator", line)
	content.add_child(divider)
	content.add_child(_label(I18n.t("main.audio"), 14))
	_settings_audio_row(content, "MusicToggle", I18n.t("main.music"), "music", _music_on, func(on: bool) -> void:
		_music_on = on
		_set_music("music_race_loop" if GameState.phase == "racing" else "music_workshop_loop"))
	_settings_audio_row(content, "SfxToggle", I18n.t("main.sound_effects"), "sound", _sfx_on, func(on: bool) -> void:
		_sfx_on = on)
	var lang_panel := PanelContainer.new()
	lang_panel.name = "LanguageRow"
	lang_panel.custom_minimum_size.y = 68
	lang_panel.add_theme_stylebox_override("panel", HdUi.panel())
	content.add_child(lang_panel)
	var lang_line := HBoxContainer.new()
	lang_line.add_theme_constant_override("separation", 10)
	lang_panel.add_child(lang_line)
	var lang_icon := _icon("icons/vector_dark/flag.svg", Vector2(34, 34))
	lang_icon.modulate = Color("2876d6") / Color("202b38")
	lang_line.add_child(lang_icon)
	var lang_title := _label(I18n.t("main.language"), 16, C_TEXT, true)
	lang_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lang_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lang_line.add_child(lang_title)
	var lang_btn := _button(I18n.lang_name(), false, 44.0)
	lang_btn.name = "LanguageButton"
	lang_btn.custom_minimum_size.x = 140
	lang_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lang_btn.pressed.connect(_show_language_picker)
	lang_line.add_child(lang_btn)


## Popup chọn ngôn ngữ (lưới 2 cột, tên viết bằng chính ngôn ngữ đó). Chọn xong game tự tải lại.
func _show_language_picker() -> void:
	_begin_overlay()
	_overlay_box.add_child(HdUi.close_header(I18n.t("main.choose_language"), _close_overlay, 22))
	var box := GridContainer.new()
	box.name = "LanguagePicker"
	box.columns = 2
	box.add_theme_constant_override("h_separation", 10)
	box.add_theme_constant_override("v_separation", 10)
	_overlay_box.add_child(box)
	for code: String in I18n.codes():
		var chosen: bool = code == I18n.lang()
		var b := _button(("✓  " if chosen else "") + I18n.lang_name(code), true, 52.0)
		b.name = "Lang_" + code
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.x = 0
		if size.x < 360.0:  # hai cột phải lọt màn 320
			b.add_theme_font_size_override("font_size", 13)
		# Both options share the same rounded face, raised base and nine-patch margins.
		# Selection changes only the color and checkmark.
		if not chosen:
			for state in ["normal", "hover", "pressed", "disabled"]:
				var skin := HdUi.button("race", "normal" if state == "disabled" else state).duplicate() as StyleBoxTexture
				skin.texture = preload("res://assets/clean_modern/icons/button_raised_locked.svg")
				skin.remove_meta("rounded_button")
				b.add_theme_stylebox_override(state, HdUi.ButtonSkin.rounded(skin))
			for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
				b.add_theme_color_override(state, C_TEXT)
			HdUi.text_depth(b)
		b.pressed.connect(func() -> void:
			if code == I18n.lang():
				_close_overlay()
			else:
				_switch_language(code))
		box.add_child(b)


## Đổi ngôn ngữ ngay: lưu tiến trình, nạp bảng dịch mới rồi dựng lại game qua màn loading
## (BootFlow đọc lại save, mọi chữ trên màn hình được dựng mới theo ngôn ngữ vừa chọn).
func _switch_language(code: String) -> void:
	if GameState.active and not GameState.save_blocked and GameState.phase != "save_error":
		GameState.save_game()
	I18n.switch(code)
	get_tree().change_scene_to_file("res://scenes/loading.tscn")


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
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(toggle)


# ---------------------------------------------------------------- ô nâng cấp

## Một ô nâng cấp gọn: icon + tên/cấp, dòng hiệu ứng ngắn, nút giá. Chi tiết (gợi ý, hoàn vốn) ở tooltip.
func _add_tile(parent: Control, kind: String) -> void:
	var pc := PanelContainer.new()
	pc.name = "Upgrade_" + kind
	pc.add_theme_stylebox_override("panel", HdUi.Soft.surface("panel", Vector4(5, 3, 5, 4)))
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(pc)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	pc.add_child(row)
	var art := ExpansionArt.icon(kind, Vector2(56, 48))
	if kind == "gearbox": art.texture = HdUi.Soft.texture("upgrade_gearbox")
	row.add_child(art)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_stretch_ratio = 1.0
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	var name_l := _label("", 17)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_l.max_lines_visible = 2
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(name_l)
	var values := VBoxContainer.new()
	values.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	values.size_flags_stretch_ratio = 1.15
	values.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	values.add_theme_constant_override("separation", 1)
	row.add_child(values)
	var values_gap := Control.new()
	values_gap.custom_minimum_size.x = 4
	values_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(values_gap)
	var level_l := _label("", 15, C_TEXT)
	level_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	values.add_child(level_l)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 0)
	var stat_pill := PanelContainer.new()
	stat_pill.add_theme_stylebox_override("panel", HdUi.Soft.flat(Color("d3f2c6"), 2, 9))
	values.add_child(stat_pill)
	stat_pill.add_child(stats)
	var eff_l := _label("", 15)
	stats.add_child(eff_l)
	var next_l := _label("", 15, C_GREEN)
	stats.add_child(next_l)
	var action := VBoxContainer.new()
	action.custom_minimum_size.x = 82
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action.add_theme_constant_override("separation", 3)
	row.add_child(action)
	var btn := Button.new()
	btn.name = "Buy_" + kind
	btn.custom_minimum_size = Vector2(82, 34)
	HdUi.style_button(btn, "upgrade")
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		btn.add_theme_stylebox_override(state, _upgrade_buy_skin(state))
	action.add_child(btn)
	var price_center := CenterContainer.new()
	price_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	price_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(price_center)
	var price_group := HBoxContainer.new()
	price_group.add_theme_constant_override("separation", 3)
	price_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_center.add_child(price_group)
	var cash_icon := HdUi.icon("icons/cash.png", Vector2(21, 21))
	price_group.add_child(cash_icon)
	var price_label := _label("", 17, Color.WHITE)
	HdUi.text_depth(price_label, true)
	price_group.add_child(price_label)
	btn.button_down.connect(_start_hold_buy.bind(kind))
	btn.button_up.connect(_stop_hold_buy)
	pc.resized.connect(func() -> void:
		var narrow := pc.size.x < 330
		pc.custom_minimum_size.y = 55.0 if narrow else 59.0
		art.custom_minimum_size.x = 42 if narrow else 56
		row.add_theme_constant_override("separation", 4 if narrow else 7)
		_fit_tile_name(name_l, pc)
		level_l.add_theme_font_size_override("font_size", 13 if narrow else 15)
		eff_l.add_theme_font_size_override("font_size", 13 if narrow else 15)
		next_l.add_theme_font_size_override("font_size", 13 if narrow else 15))
	name_l.resized.connect(func() -> void: _fit_tile_name(name_l, pc))
	_rows.append({"kind": kind, "name": name_l, "level": level_l, "eff": eff_l, "next": next_l,"btn": btn, "price": price_label, "cash_icon": cash_icon, "tile": pc})


## Tên nâng cấp tự xuống dòng giữa các từ; giảm cỡ chữ nếu một từ đơn rộng hơn cột tên.
func _fit_tile_name(name_l: Label, tile: Control) -> void:
	var avail := name_l.size.x
	if avail < 8.0:
		return
	var font := name_l.get_theme_font("font")
	var font_size := 14 if tile.size.x < 330 else 17
	while font_size > 11:
		var widest := 0.0
		for word in name_l.text.split(" "):
			widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		if widest <= avail:
			break
		font_size -= 1
	if name_l.get_theme_font_size("font_size") != font_size:
		name_l.add_theme_font_size_override("font_size", font_size)


func _upgrade_buy_skin(state: String) -> StyleBoxTexture:
	if state == "disabled":
		return HdUi.button("upgrade", state)
	var skin := StyleBoxTexture.new()
	skin.texture = preload("res://assets/soft_miniature_ui_v1/custom/cash_upgrade_button_v1.png")
	skin.set_content_margin_all(0)
	skin.set_meta("rounded_button", true)
	if state in ["pressed", "hover_pressed"]:
		skin.modulate_color = Color(0.78, 0.88, 0.85)
	elif state == "hover":
		skin.modulate_color = Color(1.08, 1.08, 1.08)
	return skin


## Rounded gradient surfaces sized for the compact upgrade cards.
func _upgrade_skin(button: bool) -> StyleBoxTexture:
	var skin := (HdUi.button("upgrade") if button else HdUi.panel()).duplicate() as StyleBoxTexture
	skin.content_margin_left = 0
	skin.content_margin_right = 0
	skin.content_margin_top = 0
	skin.content_margin_bottom = 0
	return skin


func _on_buy(kind: String) -> bool:
	if GameState.buy_many(kind, 1):
		_sfx("upgrade")
		return true
	_sfx("ui_error")
	return false


const HOLD_DELAY := 0.4
const HOLD_START_INTERVAL := 0.14
const HOLD_MIN_INTERVAL := 0.04
var _hold_kind := ""
var _hold_timer: Timer


## Nhấn giữ nút nâng cấp: mua ngay một cấp, sau HOLD_DELAY giữ thì mua liên tục và nhanh dần.
func _start_hold_buy(kind: String) -> void:
	if not _on_buy(kind):
		return
	_hold_kind = kind
	if _hold_timer == null:
		_hold_timer = Timer.new()
		_hold_timer.one_shot = true
		_hold_timer.timeout.connect(_hold_buy_tick)
		add_child(_hold_timer)
	_hold_timer.wait_time = HOLD_DELAY
	_hold_timer.start()


func _hold_buy_tick() -> void:
	if _hold_kind == "" or not _on_buy(_hold_kind):
		_stop_hold_buy()
		return
	_hold_timer.wait_time = maxf(HOLD_MIN_INTERVAL, _hold_timer.wait_time * 0.85 if _hold_timer.wait_time < HOLD_DELAY else HOLD_START_INTERVAL)
	_hold_timer.start()


func _stop_hold_buy() -> void:
	_hold_kind = ""
	if _hold_timer != null:
		_hold_timer.stop()


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
			(r["name"] as Label).text = I18n.t(Balance.PART_NAMES[kind])
		_fit_tile_name(r["name"], r["tile"])
		(r["level"] as Label).text = I18n.t("main.level") % lv
		# Dòng ngắn trên ô: xe "Speed 46 → 48"; doanh thu "+x/giây" (hết cấp thì giá trị hiện tại).
		var short_eff := ""
		if kind in Balance.PARTS:
			short_eff = "%.1f" % GameState.part_stat(kind, lv) if maxed else "%.0f → %.0f" % [GameState.part_stat(kind, lv), GameState.part_stat(kind, lv + 1)]
		elif kind in Balance.REVENUE:
			if maxed:
				short_eff = Balance.fmt_rate(rate) + I18n.t("main.sec_2")
			else:
				var nl: Dictionary = GameState.levels.duplicate()
				nl[kind] = lv + 1
				var delta := Pricing.revenue_rate(nl, GameState.business_tier).subtract_checked(rate)
				short_eff = I18n.t("common.plus_sec") % Balance.fmt_rate(delta)
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
				(r["price"] as Label).text = I18n.t("common.saving")
				btn.disabled = true
			"maxed":
				(r["price"] as Label).text = I18n.t("main.max")
				btn.disabled = true
		btn.accessibility_name = (r["name"] as Label).text + " · " + (r["level"] as Label).text + " · " + (r["price"] as Label).text
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
	var prev_tab := _tab
	_tab = i
	get_node("PageBackground").color = preload("res://ui/shop_demo_theme.gd").BG if i == Tab.SHOP else C_BG
	var content_area := find_child("ContentArea", true, false) as MarginContainer
	var side := CONTENT_SIDE if size.x >= 360.0 and i != Tab.SHOP else 0
	content_area.add_theme_constant_override("margin_left", side)
	content_area.add_theme_constant_override("margin_right", side)
	_pages_root.clip_contents = true

	# The fixed race cluster is shown only on the Race page.
	if _race_block != null:
		_race_block.visible = i == Tab.RACE
	if _roster != null and i != Tab.TEAM:
		_roster.close_sheet()
	if i == Tab.TEAM and _roster != null:
		_roster.refresh()
	if i == Tab.TEAM and _garage != null:
		_garage.refresh()
	if i == Tab.BAG and _gear != null:
		_gear.refresh()
	for k in _pages.size():
		var page := _pages[k] as Control
		if k == i:
			var fresh := not page.visible or page.modulate.a < 1.0
			page.visible = true
			if fresh and prev_tab != i:
				PopupAnim.page_in(page)
		elif page.visible and prev_tab != i:
			PopupAnim.page_out(page)
		else:
			page.visible = false
	_animate_nav(prev_tab, i)
	_animate_nav_icon(prev_tab, i)


## Mỗi icon chào tab lần đầu trong phiên bằng một chuyển động riêng.
func _animate_nav_icon(from_tab: int, to_tab: int) -> void:
	if from_tab == to_tab:
		return
	var first_visit := not _nav_seen.has(to_tab)
	_nav_seen[to_tab] = true
	# Đổi tab nhanh phải trả icon cũ về trạng thái nghỉ ngay.
	if _nav_icon_tween != null and _nav_icon_tween.is_valid():
		_nav_icon_tween.kill()
	if is_instance_valid(_nav_animated_icon):
		_nav_animated_icon.scale = Vector2.ONE
		_nav_animated_icon.rotation = 0.0
	if not first_visit or not PopupAnim.motion_on():
		return
	var icon := _nav_items[to_tab].get_node("NavIcon") as Control
	_nav_animated_icon = icon
	icon.pivot_offset = icon.size * 0.5
	_nav_icon_tween = icon.create_tween()
	_nav_icon_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	match to_tab:
		Tab.SHOP:  # Cửa hàng đung đưa nhẹ hai bên.
			_nav_icon_pose(icon, Vector2.ONE, -0.10, 0.10)
			_nav_icon_pose(icon, Vector2.ONE, 0.08, 0.14)
			_nav_icon_pose(icon, Vector2.ONE, -0.035, 0.12)
		Tab.BAG:  # Túi nén xuống rồi bật căng lên.
			_nav_icon_pose(icon, Vector2(1.12, 0.86), 0.0, 0.10)
			_nav_icon_pose(icon, Vector2(0.93, 1.13), 0.0, 0.15)
			_nav_icon_pose(icon, Vector2(1.04, 0.97), 0.0, 0.12)
		Tab.RACE:  # Cờ phấp phới: co ngang và nghiêng luân phiên.
			_nav_icon_pose(icon, Vector2(0.82, 1.0), -0.12, 0.10)
			_nav_icon_pose(icon, Vector2(1.06, 1.0), 0.10, 0.12)
			_nav_icon_pose(icon, Vector2(0.91, 1.0), -0.06, 0.10)
			_nav_icon_pose(icon, Vector2(1.03, 1.0), 0.035, 0.10)
		Tab.TEAM:  # Cả đội gật chào hai nhịp, không lắc ngang.
			_nav_icon_pose(icon, Vector2(1.0, 0.86), 0.0, 0.10)
			_nav_icon_pose(icon, Vector2.ONE, 0.0, 0.12)
			_nav_icon_pose(icon, Vector2(1.0, 0.93), 0.0, 0.09)
		Tab.LEAGUE:  # Nâng cúp rồi lắc mừng, biên độ giảm dần.
			_nav_icon_pose(icon, Vector2.ONE * 1.13, -0.15, 0.14)
			_nav_icon_pose(icon, Vector2.ONE * 1.10, 0.13, 0.12)
			_nav_icon_pose(icon, Vector2.ONE * 1.05, -0.065, 0.12)
	_nav_icon_pose(icon, Vector2.ONE, 0.0, 0.14)


func _nav_icon_pose(icon: Control, stretch: Vector2, turn: float, seconds: float) -> void:
	_nav_icon_tween.chain().tween_property(icon, "scale", stretch, seconds)
	_nav_icon_tween.parallel().tween_property(icon, "rotation", turn, seconds)


## Five equal tabs keep their labels visible; the orange selection slides between them.
func _animate_nav(from_tab: int, to_tab: int) -> void:
	if _nav_tween != null and _nav_tween.is_valid():
		_nav_tween.kill()
	_nav_from = _nav_amt.duplicate()
	_nav_old = from_tab
	_nav_new = to_tab
	_nav_to = []
	for k in _nav.size():
		_nav_to.append(1.0 if k == to_tab else 0.0)
	if from_tab == to_tab or not _nav_pill.is_inside_tree() or not PopupAnim.motion_on():
		_nav_apply(1.0, true)
		return
	_nav_tween = create_tween()
	_nav_tween.tween_method(_nav_apply, 0.0, 1.0, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _fit_nav_label(lab: Label, item: Control) -> void:
	var avail := item.size.x - 4.0
	if avail < 8.0:
		return
	var font := lab.get_theme_font("font")
	var font_size := 15
	while font_size > 11 and font.get_string_size(lab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > avail:
		font_size -= 1
	if lab.get_theme_font_size("font_size") != font_size:
		lab.add_theme_font_size_override("font_size", font_size)


## `t` là tiến độ (có thể vượt 1 nhẹ do đường cong nảy); `done` bỏ qua nội suy.
func _nav_apply(t: float, done: bool = false) -> void:
	if _nav_to.is_empty():
		return
	var tc := 1.0 if done else clampf(t, 0.0, 1.0)
	for k in _nav.size():
		var a := lerpf(float(_nav_from[k]), float(_nav_to[k]), tc)
		_nav_amt[k] = a
		var item := _nav_items[k] as Control
		var is_race := k == Tab.RACE
		item.size_flags_stretch_ratio = (NAV_RACE_W if is_race else 1.0) + a * (NAV_SEL_W - 1.0)
		var icon := item.get_node("NavIcon") as Control
		# Keep all five labels visible; the selected icon grows slightly.
		var icon_size := lerpf(NAV_RACE_ICON_IDLE if is_race else 40.0, NAV_RACE_ICON if is_race else NAV_ICON_SEL, a)
		var top := lerpf(NAV_RACE_TOP_IDLE if is_race else NAV_ICON_IDLE_TOP, NAV_RACE_TOP if is_race else NAV_ICON_TOP, a)
		icon.offset_left = -icon_size * 0.5
		icon.offset_right = icon_size * 0.5
		icon.offset_top = top
		icon.offset_bottom = top + icon_size
		# Chấm đỏ bám theo góc trên phải của icon.
		var dot := item.get_node("NavDot") as Control
		var dot_x := NAV_DOT_DX
		var dot_y := top + icon_size * 0.5 - NAV_DOT_DY
		dot.offset_left = dot_x - NAV_DOT_SIZE * 0.5
		dot.offset_right = dot_x + NAV_DOT_SIZE * 0.5
		dot.offset_top = dot_y - NAV_DOT_SIZE * 0.5
		dot.offset_bottom = dot_y + NAV_DOT_SIZE * 0.5
		var label := item.get_node("NavLabel") as Label
		label.modulate.a = 1.0
		label.add_theme_color_override("font_color", HdUi.Soft.INK)
	var width: float = (_nav_pill.get_parent() as Control).size.x
	var total := 0.0
	for k in _nav.size():
		total += float((_nav_items[k] as Control).size_flags_stretch_ratio)
	var tt := 1.0 if done else t
	var r_old := _nav_slot(_nav_old, width, total)
	var r_new := _nav_slot(_nav_new, width, total)
	var rect := Rect2(r_old.position.lerp(r_new.position, tt), r_old.size.lerp(r_new.size, tt))
	_nav_pill.position = rect.position
	_nav_pill.size = rect.size
	var perch := _nav_slot(Tab.RACE, width, total)
	var holder_h := (_nav_pill.get_parent() as Control).size.y
	var inner_h := holder_h + NAV_BLEED + 6.0 - NAV_INNER_TOP
	_nav_inner_left.position = Vector2(-NAV_BLEED - NAV_INNER_RADIUS, NAV_INNER_TOP)
	_nav_inner_left.size = Vector2(perch.position.x - NAV_INNER_GAP + NAV_BLEED + NAV_INNER_RADIUS, inner_h)
	_nav_inner_right.position = Vector2(perch.end.x + NAV_INNER_GAP, NAV_INNER_TOP)
	_nav_inner_right.size = Vector2(width - perch.end.x - NAV_INNER_GAP + NAV_BLEED + NAV_INNER_RADIUS, inner_h)


func _nav_inner_panel() -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := StyleBoxFlat.new()
	skin.bg_color = NAV_TRAY_COLOR
	skin.set_corner_radius_all(NAV_INNER_RADIUS)
	panel.add_theme_stylebox_override("panel", skin)
	return panel


func _nav_tray_skin(top_radius: int) -> StyleBoxFlat:
	var skin := StyleBoxFlat.new()
	skin.bg_color = NAV_TRAY_COLOR
	skin.border_width_top = 2
	skin.border_color = NAV_TRAY_EDGE
	skin.corner_radius_top_left = top_radius
	skin.corner_radius_top_right = top_radius
	skin.shadow_color = Color(0.45, 0.3, 0.12, 0.22)
	skin.shadow_size = 8
	skin.shadow_offset = Vector2(0, -2)
	return skin


func _nav_slot(k: int, width: float, total: float) -> Rect2:
	var before := 0.0
	for j in NAV_ORDER:
		if j == k:
			break
		before += float((_nav_items[j] as Control).size_flags_stretch_ratio)
	var w := float((_nav_items[k] as Control).size_flags_stretch_ratio)
	var top := -NAV_RACE_RAISE if k == Tab.RACE else 2.0
	return Rect2(width * before / total, top, width * w / total, NAV_PILL_BOTTOM - top)


func _refresh_light() -> void:
	_refresh_locks()
	_coin_label.text = Balance.fmt_compact(GameState.coins)
	_fit_hud_label(_coin_label, 48)
	var mult := GameState.income_multiplier()
	_income_label.text = I18n.t("common.plus_sec") % Balance.fmt_rate(GameState.total_online_rate().multiply_ratio(mult, 1))
	var income_font := 56
	while income_font > 28 and _income_label.get_theme_font("font").get_string_size(_income_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, income_font).x > 300:
		income_font -= 1
	_income_label.add_theme_font_size_override("font_size", income_font)
	_gem_label.text = Balance.fmt_int(GameState.gems)
	_fit_hud_label(_gem_label, 48)
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
	_race_no_label.text = I18n.t("soft.race_no") % (GameState.race_counter + 1)
	_update_race_ui()
	if _roster != null and _tab == Tab.TEAM:
		_roster.refresh()
	_rebuild_league()


## Tạo thẻ từ một scene của gói asset; truyền dữ liệu bằng configure() trước khi thêm vào cây.
func _make_card(scene: String, data: Dictionary, parent: Control) -> Control:
	var card := (CleanArt.asset(ROOT + "components/" + scene + ".tscn") as PackedScene).instantiate() as Control
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
	TrophyPanel.build(_league_box, _trophy_group, _set_trophy_group, _buy_trophy, _show_trophy_rules)


## Popup luật cúp: mức thưởng top 3 và giới hạn (nút i ở thẻ cúp).
func _show_trophy_rules() -> void:
	_sfx("ui_click")
	_begin_overlay()
	_overlay_box.add_child(HdUi.close_header(I18n.t("trophy.rules"), _close_overlay, 20))
	TrophyPanel.rules_content(_overlay_box)
	_fit_overlay()


func _set_trophy_group(group: String) -> void:
	_sfx("ui_click")
	_trophy_group = group
	_rebuild_league()


func _buy_trophy(id: String) -> void:
	_sfx("ui_click")
	if not GameState.buy_trophy_upgrade(id):
		_show_toast(I18n.t("main.could_not_upgrade_check_trophies"))


func _rebuild_shop() -> void:
	if not is_instance_valid(_shop_content):
		return
	_shop_content.update_daily(
		Balance.fmt_money(GameState.daily_gift_amount()),
		int(GameData.economy()["rewards"]["daily_gems"]),
		GameState.daily_available(), GameState.save_blocked or GameState.phase == "save_error")
	var iap_view := _iap_view()
	var iap_sig := hash([iap_view.hash(), TranslationServer.get_locale()])
	if iap_sig != _shop_iap_sig:
		_shop_iap_sig = iap_sig
		_shop_content.update_iap(iap_view)
	var ads_view := _ads_view()
	var ads_sig := hash([ads_view.hash(), TranslationServer.get_locale()])
	if ads_sig != _shop_ads_sig:
		_shop_ads_sig = ads_sig
		_shop_content.update_ads(ads_view)
	_shop_content.update_packs()
	_refresh_pack_promos()


## Dữ liệu IAP cho trang Shop (view không gọi autoload): {sku: {price, reason, first_bonus}} + trạng thái chung.
func _iap_view() -> Dictionary:
	var items := {}
	for p: Dictionary in Iap.products():
		var sku := String(p["sku"])
		items[sku] = {"price": Iap.price(sku), "reason": Iap.block_reason(sku),
			"first_bonus": p.has("first_bonus") and not sku in GameState.iap["first_bonus_used"]}
		var did := String((p.get("grant", {}) as Dictionary).get("driver", ""))
		items[sku]["driver_owned"] = did != "" and GameState.driver_has(did)
	return {"items": items, "busy": Iap.is_busy(), "restorable": Iap.restorable()}


func _show_iap_detail(sku: String) -> void:
	var product := GameData.iap_product(sku)
	if product.is_empty():
		return
	_sfx("ui_click")
	_begin_overlay()
	var panel := _overlay_box.get_parent().get_parent() as PanelContainer
	panel.add_theme_stylebox_override("panel", _shop_content.BenefitUi.shell())
	_overlay_box.get_parent().set_meta("preferred_width", 366.0)
	panel.add_child(_shop_content.BenefitUi.header(I18n.t("main.my_joins_team") if sku == "char_my" else _shop_content.PackUi.title(product), _close_overlay, _shop_content.BenefitUi.scale_for(size.x)))
	_overlay_box.get_parent().set_meta("vertical_gutter", 80.0 + _shop_content.BenefitUi.shell().get_minimum_size().y)
	_overlay_box.add_child(_shop_content.build_detail(sku))
	_fit_overlay()


func _show_iap_odds(sku: String) -> void:
	var grant: Dictionary = GameData.iap_product(sku).get("grant", {})
	_begin_overlay()
	_overlay_box.add_child(HdUi.close_header(I18n.t("main.pack_rates"), _close_overlay, 20))
	for kind: String in grant.get("driver_coupon", {}):
		for pack: Dictionary in GameData.driver_packs():
			if String(pack["id"]) == kind:
				_append_iap_odds(pack)
	for kind: String in grant.get("gear_coupon", {}):
		for pack: Dictionary in GameData.gear_packs():
			if String(pack["id"]) == kind:
				_append_iap_odds(pack)
	_overlay_box.add_child(_label(I18n.t("main.pack_tickets_give_random_rewards"), 12, C_MUTED, true))
	_fit_overlay()


func _append_iap_odds(pack: Dictionary) -> void:
	_overlay_box.add_child(_label(String(pack.get("name", "")), 16))
	for tier: String in pack.get("tiers", {}):
		_overlay_box.add_child(_label("%s · %s%%" % [tier.capitalize(), str(pack["tiers"][tier])], 13))
	if pack.has("pity_draws"):
		_overlay_box.add_child(_label(I18n.t("main.guaranteed_after_pulls") % [String(pack.get("pity_tier", "")).capitalize(), int(pack["pity_draws"])], 12, C_MUTED, true))


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
	if GameState.claim_daily():
		_sfx("daily_gift")
	else:
		_show_toast(I18n.t("main.cannot_claim_reward_check_save"))
	_rebuild_shop()


func _show_shop_offer(title: String, description: String) -> void:
	_sfx("ui_click")
	_begin_overlay()
	_overlay_box.add_child(HdUi.close_header(title, _close_overlay, 20))
	_overlay_box.add_child(_label(description, 14, C_TEXT, true))
	_overlay_box.add_child(_label(I18n.t("main.coming_soon_this_pack_not"), 13, C_MUTED, true))
	var close := _button(I18n.t("common.got"), true)
	close.pressed.connect(func() -> void: _close_overlay())
	_overlay_box.add_child(close)


# ---------------------------------------------------------------- đua (UI chỉ đọc trạng thái từ GameState)

func _process(delta: float) -> void:
	if not _active:
		_tutorial_map_focus.reset()
		_power_banner.set_tutorial_focus(false)
		GameState.tutorial_pause = false
		return
	_pump_offline_popup()
	# Bảng tổng kết tự tắt sau RESULT_SHOW_SEC giây (thời gian thật) rồi thả đua tiếp.
	var modal_open: bool = _overlay.visible \
		or (is_instance_valid(_promotion) and _promotion.visible) \
		or (is_instance_valid(_class_page) and _class_page.visible)
	_ads_controls.blocked = modal_open or _result_panel.visible or _tab != Tab.RACE or _tutorial.running \
		or _tutorial.intro != "" or _tutorial.nav != "" or GameState.phase != "racing"
	_sync_tutorial_nav()
	if GameState.gating_on() and _tutorial.intro != "" and not _tutorial.tip_mode and not modal_open and not _result_panel.visible:
		if not _intro_tab_ok(Tutorial.feature(_tutorial.intro)):
			_tutorial.suspend_intro()
	if _tutorial.intro != "":
		var tab_ok: bool = _tip_tab_ok(Tutorial.tip(_tutorial.intro)) if _tutorial.tip_mode else _intro_tab_ok(Tutorial.feature(_tutorial.intro))
		_tutorial.blocked = modal_open or _result_panel.visible or not tab_ok
	elif _tutorial.running:
		_tutorial.blocked = _tab != Tab.RACE or modal_open
	else:
		_tutorial.blocked = modal_open or _result_panel.visible
		if not _tutorial.blocked:
			_pump_intro()
	GameState.tutorial_pause = _tutorial.wants_pause()  # callout đang chờ thao tác → dừng đua + thu nhập
	_sync_tutorial_power_banner()
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
	_sync_tutorial_map_focus(delta)
	_update_race_ui()
	_race_view.queue_redraw()
	_pump_events()
	_dev_tick(delta)


func _sync_tutorial_map_focus(delta: float) -> void:
	var identify_car := _tutorial.running and _tutorial.step == "A2_car" and not _tutorial.blocked and _tutorial.is_visible_in_tree()
	_tutorial_map_focus.update(_race_view, identify_car, delta)


func _exit_tree() -> void:
	_tutorial_map_focus.reset()


## Khi vòng lặp đổi sim (grid xem trước, xuất phát, lượt mới): chuyển khung đua sang sim đó.
func _sync_sim() -> void:
	var sim := GameState.sim
	if sim != _view_sim:
		_view_sim = sim
		if sim != null and sim.track_id != "" and sim.track_id != _race_view_track:
			_race_view_track = sim.track_id
			_race_view.set_track(sim.track_id)
			_track_caption.text = String(GameData.track(sim.track_id).get("name", sim.track_id))
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
			_status_label.text = ""  # Chỗ này dành cho dải icon pack; đếm ngược đã hiện ở giữa khung đua.
			if n != _last_count:
				_last_count = n
				_sfx("countdown_tick")
		"racing":
			_last_count = -1
			if sim.time < 0.8:
				overlay = I18n.t("main.race")
			_status_label.text = ""
		"save_error":
			_status_label.text = I18n.t("main.time_up_p") % [int(gs.last_result.get("position", 1)), Balance.CAR_COUNT]
	_race_view.overlay_text = overlay
	_race_view.power_value = gs.team_power()
	_race_view.set_parking_level(int(gs.levels.get("parking", 0)), Balance.max_level())
	_race_view.queue_redraw()
	_status_label.visible = gs.phase == "save_error"
	_save_err_box.visible = gs.phase == "save_error"


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
	PopupAnim.close_on_outside_click(_overlay, pc, _close_overlay)


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
	var title := I18n.t("main.victory") if pos == 1 else (I18n.t("main.podium") if podium else I18n.t("main.finished"))
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
	_result_box.add_child(_result_row(I18n.t("common.cash"), "+%s" % Balance.fmt_money(res["money"]), green.darkened(0.1)))
	_result_box.add_child(HSeparator.new())
	if int(res.get("trophies", 0)) > 0:
		_result_box.add_child(_result_row(I18n.t("common.trophies"), I18n.t("main.plus_have") % [int(res["trophies"]), GameState.trophies_earned, GameState.trophy_cap()], C_GOLD.darkened(0.35)))
		_result_box.add_child(HSeparator.new())
	_result_box.add_child(_result_row(I18n.t("main.recruit_points_sp"), "+%d" % Pricing.scout_points(int(res["points"])), Color("5d6b80")))
	for u: Dictionary in res.get("unlocked", []):
		_result_box.add_child(HSeparator.new())
		_result_box.add_child(_result_row(I18n.t("main.unlocked"), String(u["name"]), C_GOLD.darkened(0.35)))
		if String(u.get("gift", "")) != "":
			_result_box.add_child(_result_row(I18n.t("main.gift"), String(u["gift"]), green.darkened(0.1)))
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
		_offline_popup_pending = false
		_close_overlay()


## Báo cáo offline chờ hết phần làm quen (bao gồm A7), không chen vào thoại/modal khác.
func _pump_offline_popup() -> void:
	if not _offline_popup_pending or _tutorial._active() or _overlay.visible or _result_panel.visible:
		return
	if (is_instance_valid(_promotion) and _promotion.visible) or (is_instance_valid(_class_page) and _class_page.visible):
		return
	_show_offline()


func _begin_overlay() -> void:
	_clear(_overlay_box)
	var stale_header := _overlay_panel().get_node_or_null("PromoHeaderHolder")
	if stale_header != null:
		stale_header.get_parent().remove_child(stale_header)
		stale_header.queue_free()
	_overlay_box.get_parent().set_meta("preferred_width", 316.0)
	_overlay_box.get_parent().set_meta("vertical_gutter", 120.0)
	_overlay_box.get_parent().set_meta("horizontal_gutter", 32.0)
	var overlay_margin := _overlay_box.get_parent().get_parent().get_parent().get_parent() as MarginContainer
	overlay_margin.add_theme_constant_override("margin_left", 16)
	overlay_margin.add_theme_constant_override("margin_right", 16)
	overlay_margin.add_theme_constant_override("margin_top", 40)
	overlay_margin.add_theme_constant_override("margin_bottom", 40)
	_overlay_box.add_theme_constant_override("separation", 8)
	(_overlay_box.get_parent().get_parent() as PanelContainer).add_theme_stylebox_override("panel", HdUi.panel(6.0))
	PopupAnim.open(_overlay, _overlay_panel())
	_fit_overlay.call_deferred()


func _overlay_panel() -> Control:
	return _overlay_box.get_parent().get_parent() as Control


## Đóng overlay dùng chung kèm hoạt ảnh thu lại.
func _close_overlay() -> void:
	PopupAnim.close(_overlay, _overlay_panel())


## Panel cao vừa nội dung, tối đa bằng chiều cao khả dụng (cuộn khi dài).
func _fit_overlay() -> void:
	await get_tree().process_frame
	var sc := _overlay_box.get_parent() as ScrollContainer
	var panel := sc.get_parent() as PanelContainer
	var frame := panel.get_theme_stylebox("panel")
	# Account for the screen gutters and the panel's own padding on narrow phones.
	sc.custom_minimum_size.x = minf(float(sc.get_meta("preferred_width", 316.0)), maxf(0.0, size.x - float(sc.get_meta("horizontal_gutter", 32.0)) - frame.get_minimum_size().x))
	# Wrapped labels need the final width before their height can be measured.
	# A first-open measurement at the old/zero width makes the panel screen-high.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(sc):
		return
	var wanted := _overlay_box.get_combined_minimum_size().y
	sc.custom_minimum_size.y = minf(wanted, maxf(200.0, size.y - float(sc.get_meta("vertical_gutter", 120.0))))
	# Switching from a padded overlay to the wider Daily Gift frame can briefly
	# grow this anchored MarginContainer. Refit after its minimum size settles;
	# an unchanged viewport does not automatically shrink the old rectangle.
	await get_tree().process_frame
	if is_instance_valid(panel):
		var margin := panel.get_parent().get_parent() as MarginContainer
		margin.size = _overlay.size
		margin.queue_sort()


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
		return I18n.t("main.sec") % int(maxf(seconds, 0.0))
	if minutes < 60:
		return I18n.t("main.min") % minutes
	if minutes % 60 == 0:
		return I18n.t("common.h") % (minutes / 60)
	return I18n.t("main.h_min") % [minutes / 60, minutes % 60]


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
	if GameState.offline_report.is_empty():
		_offline_popup_pending = false
		return
	if _tutorial.running:
		_offline_popup_pending = true
		return
	_offline_popup_pending = false
	GameState.note_offline_shown()  # mẹo C1 hiện sau khi người chơi đóng panel
	_begin_overlay()
	var rep: Dictionary = GameState.offline_report
	var elapsed := maxf(float(rep["elapsed"]), 0.0)
	var cap := GameState.offline_cap_sec_now()
	var eligible := float(rep.get("eligible", minf(elapsed, cap)))
	(_overlay_box.get_parent().get_parent() as PanelContainer).add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_overlay_box.get_parent().set_meta("preferred_width", 374.0)
	var frame := preload("res://ui/offline_popup_frame.gd").new()
	frame.name = "OfflineFrame"
	_overlay_box.add_child(frame)
	# A narrow plaque straddles the top edge; its text remains a native Label.
	var header_panel := PanelContainer.new()
	header_panel.name = "OfflineHeader"
	var header_style := frame.face("3eabf6", "146fc7", "f4e4ca", 22)
	header_style.content_margin_left = 12
	header_style.content_margin_right = 12
	header_style.content_margin_top = 10
	header_style.content_margin_bottom = 10
	header_panel.add_theme_stylebox_override("panel", header_style)
	var title_margin := MarginContainer.new()
	title_margin.add_theme_constant_override("margin_left", 22)
	title_margin.add_theme_constant_override("margin_right", 22)
	frame.add_child(title_margin)
	title_margin.add_child(header_panel)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 5)
	header_panel.add_child(header)
	header.add_child(HdUi.Soft.art("nav_race", Vector2(34, 34)))
	var title := _label(I18n.t("main.offline_income"), 26, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.name = "OfflineTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(frame.speed_marks())
	# Keep a single-line title at the largest size that fits each phone width.
	title.resized.connect(func() -> void:
		var font := title.get_theme_font("font")
		var font_size := 26
		while font_size > 10 and font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > title.size.x:
			font_size -= 1
		title.add_theme_font_size_override("font_size", font_size))
	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 14)
	content_margin.add_theme_constant_override("margin_right", 14)
	frame.add_child(content_margin)
	var income_block := PanelContainer.new()
	income_block.name = "OfflineIncomeBlock"
	var block_style := StyleBoxEmpty.new()
	block_style.set_content_margin_all(0)
	income_block.add_theme_stylebox_override("panel", block_style)
	content_margin.add_child(income_block)
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 8)
	income_block.add_child(block)
	var art_window := PanelContainer.new()
	art_window.name = "OfflineArtWindow"
	var art_skin := frame.face("fffdf6", "e9d8c4", "d9c4ac", 24)
	art_skin.set_content_margin_all(5)
	art_window.add_theme_stylebox_override("panel", art_skin)
	block.add_child(art_window)
	var art_clip := Panel.new()
	art_clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	art_clip.custom_minimum_size.y = 184
	var clip_skin := _style(Color("43bcef"), 18)
	clip_skin.set_border_width_all(0)
	art_clip.add_theme_stylebox_override("panel", clip_skin)
	art_window.add_child(art_clip)
	var offline_art := TextureRect.new()
	offline_art.texture = load("res://assets/offline_popup_v1/offline_garage_landscape.png")
	offline_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	offline_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	offline_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	offline_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art_clip.add_child(offline_art)
	offline_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sfx("coin_pickup")
	var reward_panel := PanelContainer.new()
	reward_panel.name = "OfflineRewardBlock"
	var reward_skin := frame.face("fff6c8", "ffdb8c", "e6ad48", 20)
	reward_skin.content_margin_top = 12
	reward_skin.content_margin_bottom = 12
	reward_panel.add_theme_stylebox_override("panel", reward_skin)
	block.add_child(reward_panel)
	var reward_center := CenterContainer.new()
	reward_panel.add_child(reward_center)
	var reward_group := HBoxContainer.new()
	reward_group.add_theme_constant_override("separation", 8)
	reward_center.add_child(reward_group)
	reward_group.add_child(HdUi.icon("icons/cash.png", Vector2(64, 64)))
	var amount := _label("+%s" % Balance.fmt_money(rep["reward"]), 54, Color("8a3f0f"))
	amount.name = "OfflineAmount"
	reward_group.add_child(amount)
	var progress := ProgressBar.new()
	progress.name = "OfflineProgress"
	progress.custom_minimum_size.y = 14
	progress.show_percentage = false
	progress.max_value = maxf(cap, 1.0)
	progress.value = clampf(eligible, 0.0, cap)
	var track_style := _style(Color("fbe9ad"), 18, Color("e6b94f"), 2)
	track_style.set_content_margin_all(0)
	progress.add_theme_stylebox_override("background", track_style)
	var progress_fill := frame.face("ffe36e", "ffb42a", "e8951a", 15, 0)
	progress_fill.content_margin_left = 0
	progress_fill.content_margin_right = 0
	progress_fill.content_margin_top = 0
	progress_fill.content_margin_bottom = 0
	# Phần fill tự vẽ để luôn rộng tối thiểu bằng chiều cao, giữ hai đầu tròn khi giá trị nhỏ.
	progress.add_theme_stylebox_override("fill", StyleBoxEmpty.new())
	progress.custom_minimum_size.y = 36
	var fill_bar := Panel.new()
	fill_bar.name = "OfflineFill"
	fill_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill_bar.add_theme_stylebox_override("panel", progress_fill)
	progress.add_child(fill_bar)
	var ratio := clampf(eligible / maxf(cap, 1.0), 0.0, 1.0)
	progress.resized.connect(func() -> void:
		var h := progress.size.y
		fill_bar.position = Vector2.ZERO
		fill_bar.size = Vector2(minf(progress.size.x, maxf(h, progress.size.x * ratio)), h))
	block.add_child(progress)
	var time_text := I18n.t("main.min_2") % [int(eligible / 60.0), int(cap / 60.0)]
	if eligible >= cap:
		time_text = I18n.t("main.full") + time_text
	var time_label := _offline_center(time_text, 18, Color("1d2b44"))
	time_label.name = "OfflineTimeText"
	time_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_child(time_label)
	var button := _button(I18n.t("common.continue"), true)
	button.name = "OfflineContinue"
	button.custom_minimum_size.y = 48
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(func() -> void:
		GameState.offline_report = {}
		_open_next_overlay())
	var footer := PanelContainer.new()
	footer.name = "OfflineFooter"
	var footer_skin := frame.face("b6eaff", "79c9ee", "4ba6d6", 24)
	footer_skin.content_margin_left = 32
	footer_skin.content_margin_right = 32
	footer_skin.content_margin_top = 12
	footer_skin.content_margin_bottom = 14
	footer.add_theme_stylebox_override("panel", footer_skin)
	var footer_margin := MarginContainer.new()
	footer_margin.add_theme_constant_override("margin_left", 8)
	footer_margin.add_theme_constant_override("margin_right", 8)
	footer_margin.add_theme_constant_override("margin_bottom", 8)
	frame.add_child(footer_margin)
	footer_margin.add_child(footer)
	footer.add_child(button)


# ---------------------------------------------------------------- hướng dẫn đầu game

## Tạm tắt toàn bộ hướng dẫn (onboarding, tính năng, mẹo). Đặt true để bật lại.
const TUTORIAL_ENABLED := true


func _start_tutorial() -> void:
	if not TUTORIAL_ENABLED and not _cli_tutorial:
		return
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
	_show_feedback(String(f["name"]), Tutorial.lock_text(f, GameState.completed_races), "icons/vector_dark/lock.svg")


## Popup phản hồi chung (tiêu đề + nội dung + nút đóng), dùng overlay có sẵn.
## Dùng khi cần giải thích cho người chơi, ví dụ vì sao một tính năng đang khóa.
func _show_feedback(title: String, content: String, icon_path: String = "") -> void:
	_begin_overlay()
	if icon_path != "":
		var ic := _icon(icon_path, Vector2(48, 48))
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_overlay_box.add_child(ic)
	if title != "":
		var t := _label(title, 20, C_TEXT, true)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_overlay_box.add_child(t)
	var body := _label(content, 14, C_MUTED, true)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_box.add_child(body)
	var ok := _button(I18n.t("main.done"), true)
	ok.pressed.connect(func() -> void: _close_overlay())
	_overlay_box.add_child(ok)


## Cập nhật ổ khóa/chấm trên thanh điều hướng, nút Lịch/Class, avatar, nút Garage và dòng "Sắp mở".
func _refresh_locks() -> void:
	_refresh_pack_promos()
	var shop_ad: bool = Ads.shop_ready()
	var has_coupons: bool = GameState.gear_coupons.values().any(func(n: Variant) -> bool: return int(n) > 0) or GameState.driver_coupons.values().any(func(n: Variant) -> bool: return int(n) > 0)
	var sig := "%s|%d|%s|%s|%s|%s" % [GameState.gating_on(), GameState.completed_races, str(GameState.tutorial.get("intro_seen", [])), shop_ad, has_coupons, str(GameState.tutorial.get("lessons", {}))]
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
		(item.get_node("NavDot") as Control).visible = new_feature or (open and i == Tab.SHOP and (shop_ad or has_coupons))
		_nav[i].accessibility_name = I18n.t(TAB_NAMES[i]) + ("" if open else I18n.t("main.locked"))
	var garage_btn: Button = _team_sub_buttons[1]
	garage_btn.icon = null if GameState.feature_unlocked("U6_garage") else _tex("icons/vector_dark/lock.svg")
	garage_btn.expand_icon = true
	garage_btn.add_theme_constant_override("icon_max_width", 18)
	var next := Tutorial.next_feature(GameState.completed_races)
	# "Sắp mở" không còn là dòng cố định: hiện popup tự tắt mỗi khi mục tiêu/số lượt còn lại đổi.
	if gated and not next.is_empty():
		var key := "%s|%d" % [next["name"], int(next["races"]) - GameState.completed_races]
		if key != _next_hint_key:
			_next_hint_key = key
			_show_toast(I18n.tn("main.coming_soon_more_races", int(next["races"]) - GameState.completed_races) % [next["name"], int(next["races"]) - GameState.completed_races])
	else:
		_next_hint_key = ""


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
	if not TUTORIAL_ENABLED and not _cli_tutorial:
		return
	if _tutorial.running or _tutorial.intro != "" or _tutorial.nav != "":
		return
	if _overlay.visible or _result_panel.visible or _promotion.visible or _class_page.visible:
		return
	if GameState.gating_on():
		# Earliest eligible lesson owns its entire route, from any current tab.
		for f: Dictionary in Tutorial.features():
			var id: String = f["id"]
			if not GameState.feature_unlocked(id) or Tutorial.intro_seen(GameState, id) or not Tutorial.intro_ready(f, GameState):
				continue
			if _intro_tab_ok(f):
				_tutorial.show_intro(id)
				return
			var hint := Tutorial.nav_hint(f, GameState)
			if hint == "none" or (hint == "soft" and Tutorial.nav_seen(GameState, id)):
				continue
			var destination := _nav_tab_of(f)
			if destination < 0 or not _nav_tab_open(destination):
				continue
			_tutorial.show_nav(id, hint == "force")
			return
	_pump_tip()


## Complete navigation only at the lesson destination, including the Garage subtab.
func _sync_tutorial_nav() -> void:
	if _tutorial.nav != "" and _intro_tab_ok(Tutorial.feature(_tutorial.nav)):
		_tutorial.finish_nav()


## Tab điều hướng (chỉ số Tab) của tính năng, -1 nếu không có tab riêng.
func _nav_tab_of(f: Dictionary) -> int:
	match String(f.get("tab", "")):
		"race":
			return Tab.RACE
		"bag":
			return Tab.BAG
		"shop":
			return Tab.SHOP
		"league":
			return Tab.LEAGUE
		"team", "garage":
			return Tab.TEAM
	return -1


func _nav_tab_open(tab: int) -> bool:
	var fid := _tab_feature(tab)
	return fid == "" or GameState.feature_unlocked(fid)


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
	if not TUTORIAL_ENABLED and not _cli_tutorial:
		return
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
	_sync_tutorial_power_banner()
	if step.begins_with("nav:"):
		var destination := Tutorial.feature(step.substr(4))
		if destination.get("tab", "") == "garage" and _tab == Tab.TEAM:
			var garage_tab: Control = _team_sub_buttons[1]
			return {"rect": garage_tab.get_global_rect(), "hand": garage_tab.get_global_rect().get_center()}
		# Tab điều hướng của tính năng vừa mở: bàn tay đứng phía trên tab, chỉ xuống (Design/31 §3.5).
		var ni := _nav_tab_of(Tutorial.feature(step.substr(4)))
		if ni < 0 or ni >= _nav_items.size():
			return {}
		var nctrl := _nav_items[ni] as Control
		if nctrl == null or not nctrl.is_visible_in_tree():
			return {}
		var nr := nctrl.get_global_rect()
		return {"rect": nr, "hand": Vector2(nr.get_center().x, nr.position.y), "hand_down": true}
	if step.begins_with("tip:"):
		var tctrl := _ctrl_for_spec(String(_tutorial.tip_data.get("target", "")))
		if tctrl == null or not tctrl.is_visible_in_tree():
			return {}
		return {"rect": tctrl.get_global_rect()}
	if step.begins_with("intro:"):
		var f := Tutorial.feature(step.substr(6))
		var spec := String(f.get("target", ""))
		if f.get("action", "") == "trophy_upgrade" and sub == 1:
			spec = "node:TrophyLevel_" + String(f["upgrade_id"])
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
			# Vòng tròn quanh chấm xe của người chơi (Design/31 §3.2); chưa có vị trí xe thì sáng cả khung đua.
			if _race_view.size.x <= 0.0 or _race_view.size.y <= 0.0:
				return {}
			var mk := _race_view.player_marker()
			if float(mk["r"]) <= 0.0:
				return {"rect": _race_view.get_global_rect()}
			var mpos: Vector2 = _race_view.get_global_transform() * (mk["pos"] as Vector2)
			var mrad := maxf(float(mk["r"]) * 2.6, 22.0)
			return {"rect": Rect2(mpos - Vector2(mrad, mrad), Vector2(mrad, mrad) * 2.0), "round": true}
		"A3_income":
			if sub == 1:
				var header := find_child("RevenueSectionHeader", true, false) as Control
				if header != null:
					var rect := header.get_global_rect()
					var grid := find_child("RevenueUpgradeGrid", true, false) as Control
					if grid != null:
						rect = rect.merge(grid.get_global_rect())
					return {"rect": rect.intersection(_upgrade_scroll.get_global_rect())}
			if sub == 2:
				var row := _row_of("ticket")
				if not row.is_empty():
					return {"rect": (row["btn"] as Control).get_global_rect(), "hand": (row["btn"] as Control).get_global_rect().get_center()}
			# Ô thu nhập (tiền mỗi giây), không phải ô tiền: đúng thứ lời dẫn đang nói tới.
			var pill := find_child("IncomePill", true, false) as Control
			if pill != null and pill.is_visible_in_tree():
				return {"rect": pill.get_global_rect()}
			return {"rect": _coin_bar.get_global_rect()}
		"A4_engine":
			if sub == 3:
				var banner_rect := _power_banner.get_global_rect()
				return {"rect": banner_rect, "hand": Vector2(banner_rect.get_center().x, banner_rect.end.y + 4.0), "hand_clearance": true}
			if sub == 4:
				return _tutorial_power_target()
			var row := _row_of("engine")
			if row.is_empty():
				return {}
			var t := {"rect": (row["tile"] as Control).get_global_rect()}
			if sub == 0:
				t["hand"] = (row["btn"] as Control).get_global_rect().get_center()
			return t
		"A6_result":
			if _result_panel.visible:
				return {"rect": (_result_box.get_parent() as Control).get_global_rect()}
	return {}


func _sync_tutorial_power_banner() -> void:
	var suspended := _tab != Tab.RACE or not _race_block.is_visible_in_tree() or _overlay.visible or _result_panel.visible \
		or (is_instance_valid(_promotion) and _promotion.visible) or (is_instance_valid(_class_page) and _class_page.visible)
	_power_banner.set_suspended(suspended)
	var focus := _tutorial.running and _tutorial.step == "A4_engine" and _tutorial.sub == 3 and not _tutorial.blocked and not suspended
	var before: float = GameState.tutorial.get("lessons", {}).get("A4_engine", {}).get("context", {}).get("power_before", GameState.team_power())
	_power_banner.set_tutorial_focus(focus, before, GameState.team_power())


## Khớp đúng chip Power được RaceView vẽ trên canvas HUD 1448 px.
func _tutorial_power_target() -> Dictionary:
	var k := _race_view.size.x / 1448.0
	var rect := Rect2(_race_view.get_global_transform() * (Vector2(30, 146) * k), Vector2(330, 100) * k)
	return {"rect": rect, "hand": Vector2(rect.get_center().x, rect.end.y + 4.0), "hand_clearance": true}


func _tutorial_context(step: String, res: Dictionary) -> Dictionary:
	match step:
		"A1_welcome":
			return {"coins": Balance.fmt_money(GameState.coins)}
		"A3_income":
			var effective := GameState.total_online_rate().multiply_ratio(GameState.income_multiplier(), 1)
			return {"rate": Balance.fmt_rate(effective), "price": Balance.fmt_money(GameState.cost_of("ticket")), "before": String(Tutorial.income_snapshot(GameState).get("before", "")), "after": Balance.fmt_rate(effective)}
		"A4_engine":
			var before: float = GameState.tutorial.get("lessons", {}).get(step, {}).get("context", {}).get("power_before", GameState.team_power())
			return {"price": Balance.fmt_money(GameState.cost_of("engine")),
				"before": RaceView.format_team_power(before), "after": RaceView.format_team_power(GameState.team_power())}
		"A6_result":
			return {"position": int(res.get("position", 8)), "money": Balance.fmt_money(res.get("money", 0))}
		"A7_race2":
			return {"before": RaceView.format_team_power(float(GameState.tutorial.get("power_before", 0.0))),
				"after": RaceView.format_team_power(GameState.team_power()),
				"has_trophy": GameState.trophies_earned > 0}
	return {}


## Ô nâng cấp ở nhóm Doanh thu có thể nằm dưới mép màn: cuộn trang Đua tới ô đó.
func _tutorial_reveal(step: String) -> void:
	if step == "A3_income":
		if _tutorial.sub == 1:
			var header := find_child("RevenueSectionHeader", true, false) as Control
			if header != null:
				# Đưa cả nhóm lên đầu vùng cuộn, thay vì chỉ kéo tiêu đề vừa chạm mép dưới.
				_upgrade_scroll._stop_scroll()
				var offset := header.get_global_rect().position.y - _upgrade_scroll.get_global_rect().position.y
				_upgrade_scroll.scroll_vertical += roundi(offset - 8.0)
		elif _tutorial.sub == 2:
			var ticket := _row_of("ticket")
			if not ticket.is_empty():
				_reveal_node(ticket["tile"])
		return
	if step.begins_with("tip:"):
		var tc := _ctrl_for_spec(String(_tutorial.tip_data.get("target", "")))
		if tc != null:
			_reveal_node(tc)
		return
	if step.begins_with("intro:"):
		var f := Tutorial.feature(step.substr(6))
		if f.get("action", "") == "trophy_upgrade":
			var group := String(GameData.trophy_upgrade(String(f["upgrade_id"]))["group"])
			if _trophy_group != group:
				_set_trophy_group(group)
				await get_tree().process_frame
		var spec := String(f.get("target", ""))
		var ctrl: Control = null
		if spec.begins_with("tile:"):
			var row := _row_of(spec.substr(5))
			ctrl = row["tile"] if not row.is_empty() else null
		elif spec.begins_with("node:"):
			ctrl = find_child(spec.substr(5), true, false) as Control
		if ctrl != null:
			_reveal_node(ctrl)
		return
	if step != "A4_engine":
		return
	var row := _row_of("engine")
	var sc := _upgrade_scroll
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
