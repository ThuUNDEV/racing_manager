class_name TutorialOverlay
extends Control
const CleanArt = preload("res://ui/clean_modern_art.gd")
## Lớp hiển thị hướng dẫn đầu game Phần A (Design/23 §4): một callout của Linh + một spotlight + bàn tay.
## Không chặn vòng đua; chỉ giữ bảng kết quả hiện có ở bước A6. Lớp gốc bỏ qua chuột, chỉ callout nhận chạm.
## main.gd cấp vị trí mục tiêu qua `target_provider` và số liệu lời thoại qua `context_provider`.

signal result_released          # A6 xong: main ẩn bảng kết quả, vòng đua chạy tiếp
signal reveal_requested(step: String)  # main cuộn trang tới mục tiêu (ô nâng cấp) nếu đang khuất

const C_RING := Color("087ee6")
const C_DIM := Color(0, 0, 0, 0.6)
const HAND_PATH := "res://assets/workshop_gp/ui/tutorial_hand.svg"
const LINH_PORTRAITS := {
	"smile": preload("res://assets/clean_modern/resources/tutorial/portraits/linh_smile.tres"),
	"point": preload("res://assets/clean_modern/resources/tutorial/portraits/linh_point.tres"),
	"excited": preload("res://assets/clean_modern/resources/tutorial/portraits/linh_excited.tres"),
}

## (step: String, sub: int) -> {"rect": Rect2 toàn cục, "round": bool, "hand": Vector2 toàn cục (tùy chọn)}; {} = không có mục tiêu.
var target_provider: Callable
## (step: String, result: Dictionary) -> Dictionary số liệu chèn vào lời thoại.
var context_provider: Callable
## main đặt mỗi frame: đang ở tab khác / có modal, hồ sơ, trang Class mở.
var blocked: bool = false

var running: bool = false
var step: String = ""
var sub: int = 0
## Hướng dẫn ngắn khi vừa mở một tính năng (Phần B, Design/23 §5.3): id trong data/tutorial.json, "" = không có.
var intro: String = ""
var intro_sub: int = 0
## Mẹo theo tình huống (Phần C, Design/23 §6): dùng chung callout với hướng dẫn ngắn; `intro` giữ id mẹo, `tip_data` là {text, target}.
var tip_mode: bool = false
var tip_data: Dictionary = {}
var _timer: float = 0.0
var _confirm: bool = false
var _holding: bool = false
var _result: Dictionary = {}
var _resumed: bool = false
var _was_shown: bool = false
var _pulse: float = 0.0
var _target: Dictionary = {}

var _panel: PanelContainer
var _text: Label
var _primary: Button
var _skip: Button
var _hand: TextureRect
var _portrait: TextureRect
var _progress: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	_panel.name = "TutorialCallout"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var card := StyleBoxFlat.new()
	card.bg_color = Color("ffffff")
	card.border_color = Color("adc9de")
	card.set_border_width_all(2)
	card.set_corner_radius_all(16)
	card.content_margin_left = 18
	card.content_margin_right = 18
	card.content_margin_top = 14
	card.content_margin_bottom = 12
	card.shadow_color = Color(0.03, 0.12, 0.29, 0.23)
	card.shadow_size = 8
	card.shadow_offset = Vector2(0, 4)
	_panel.add_theme_stylebox_override("panel", card)
	add_child(_panel)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	_panel.add_child(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	body.add_child(row)
	var portrait_space := Control.new()
	portrait_space.custom_minimum_size = Vector2(72, 50)
	portrait_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait_space)
	_portrait = TextureRect.new()
	_portrait.name = "LinhPortrait"
	_portrait.size = Vector2(84, 92)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture = LINH_PORTRAITS["smile"]
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	var who := VBoxContainer.new()
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_theme_constant_override("separation", 2)
	row.add_child(who)
	var name_l := Label.new()
	name_l.text = Tutorial.MENTOR
	name_l.add_theme_font_size_override("font_size", 22)
	name_l.add_theme_color_override("font_color", Color("087ee6"))
	who.add_child(name_l)
	var role := Label.new()
	role.text = I18n.t("tutorial.chief_engineer")
	role.add_theme_font_size_override("font_size", 11)
	role.add_theme_color_override("font_color", Color("768ca0"))
	who.add_child(role)
	_progress = Label.new()
	_progress.name = "TutorialProgress"
	_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_progress.add_theme_font_size_override("font_size", 11)
	_progress.add_theme_color_override("font_color", Color("087ee6"))
	row.add_child(_progress)
	var rule := HSeparator.new()
	var rule_style := StyleBoxLine.new()
	rule_style.color = Color("adc9de")
	rule_style.thickness = 1
	rule.add_theme_stylebox_override("separator", rule_style)
	body.add_child(rule)
	_text = Label.new()
	_text.name = "TutorialText"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("font_size", 15)
	_text.add_theme_constant_override("line_spacing", 4)
	_text.add_theme_color_override("font_color", Color("23394a"))
	body.add_child(_text)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	body.add_child(buttons)
	_skip = Button.new()
	_skip.name = "TutorialSkip"
	_skip.flat = false
	_skip.custom_minimum_size = Vector2(0, 44)
	_skip.add_theme_font_size_override("font_size", 13)
	_skip.add_theme_color_override("font_color", Color("768ca0"))
	_skip.add_theme_color_override("font_hover_color", Color("087ee6"))
	_skip.add_theme_color_override("font_pressed_color", Color("ffd478"))
	_skip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	HdUi.style_button(_skip, "cancel")
	_skip.pressed.connect(_on_skip)
	buttons.add_child(_skip)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons.add_child(gap)
	_primary = Button.new()
	_primary.name = "TutorialNext"
	_primary.custom_minimum_size = Vector2(108, 44)
	_primary.add_theme_font_size_override("font_size", 16)
	HdUi.style_button(_primary, "race")
	_primary.pressed.connect(_on_primary)
	buttons.add_child(_primary)
	_hand = TextureRect.new()
	_hand.name = "TutorialHand"
	_hand.texture = CleanArt.asset(HAND_PATH) as Texture2D
	_hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hand.custom_minimum_size = Vector2(56, 56)
	_hand.size = Vector2(56, 56)
	_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hand)
	_set_shown(false)


# ---------------------------------------------------------------- API cho main.gd

## Bắt đầu hoặc tiếp tục hướng dẫn nếu save cần (save mới chưa đua / đang dở). Trả về có chạy không.
func start() -> bool:
	if running or not Tutorial.should_run(GameState):
		return false
	var first := GameState.tutorial_state() == "new"
	var s := Tutorial.resume_step(GameState)
	_resumed = not first and s != Tutorial.first_step()
	if first:
		# Save mới: bắt đầu cả lịch mở khóa dần (Phần B); bỏ qua hướng dẫn không tắt lịch này.
		GameState.set_tutorial("active", s, {"power_before": GameState.team_power(), "gated": true})
	running = true
	_enter(s)
	return true


## Bảng kết quả vừa hiện. Ở bước A6 (và đang xem tab Đua) thì giữ bảng cho tới khi đọc xong hai câu.
func on_result(res: Dictionary) -> bool:
	if not running or step != "A6_result" or _holding or blocked:
		return false
	_holding = true
	_result = res.duplicate(true)
	sub = 0
	_timer = 0.0
	return true


func holds_result() -> bool:
	return _holding


## Thoát hướng dẫn khi đang chạy (bỏ qua). Không đụng tới tiến trình chơi.
func skip_all() -> void:
	_finish("skipped")


## Đang có lời dẫn nào (Phần A hoặc hướng dẫn ngắn) chiếm callout.
func _active() -> bool:
	return running or intro != ""


## Mở hướng dẫn ngắn của một tính năng vừa mở. main.gd gọi khi người chơi đang ở đúng tab và không có gì che.
func show_intro(id: String) -> bool:
	if _active() or Tutorial.feature(id).is_empty():
		return false
	intro = id
	intro_sub = 0
	_timer = 0.0
	_confirm = false
	_was_shown = false
	GameState.mark_intro_seen(id)  # chỉ hướng dẫn một lần: đã hiện là coi như đã xem, dù đổi tab hay thoát game
	return true


## Hiện một mẹo (`info` = Tutorial.tip_info + id). main.gd gọi khi đúng tab và không có gì che.
func show_tip(id: String, info: Dictionary) -> bool:
	if _active() or Tutorial.tip(id).is_empty():
		return false
	intro = id
	tip_mode = true
	tip_data = info
	intro_sub = 0
	_timer = 0.0
	_confirm = false
	_was_shown = false
	return true


func _finish_intro() -> void:
	if intro == "":
		return
	var id := intro
	var was_tip := tip_mode
	intro = ""
	intro_sub = 0
	tip_mode = false
	tip_data = {}
	_set_shown(false)
	if was_tip:
		GameState.mark_tip_seen(id)
	else:
		GameState.mark_intro_seen(id)


# ---------------------------------------------------------------- máy trạng thái

func _enter(s: String) -> void:
	if s == "":
		_finish("done")
		return
	step = s
	sub = 0
	_timer = 0.0
	_confirm = false
	_was_shown = false
	GameState.set_tutorial("active", s)


func _finish(state: String) -> void:
	if not running:
		return
	running = false
	GameState.set_tutorial(state, "")
	if _holding:
		_holding = false
		result_released.emit()
	_set_shown(false)


func _advance() -> void:
	_timer = 0.0
	_resumed = false
	match step:
		"A4_engine", "A5_ticket":
			if sub == 0:
				return  # chỉ qua bằng thao tác mua thật
			_enter(Tutorial.next_of(step))
		"A6_result":
			if sub == 0:
				sub = 1
				return
			_holding = false
			result_released.emit()
			_enter(Tutorial.next_of(step))
		"A7_race2":
			if sub < 2:  # 0: Power trước → sau, 1: giải thích Power, 2: câu kết
				sub += 1
				return
			_finish("done")
		_:
			_enter(Tutorial.next_of(step))


func _waiting() -> bool:
	if step == "A6_result":
		return not _holding
	if step == "A7_race2":
		return sub == 0 and GameState.phase != "racing"
	return false


## Callout đang hiện và chờ người chơi thao tác → main dừng game (kể cả mẹo, chờ bấm Đã hiểu). Câu phụ sau thao tác không dừng.
func wants_pause() -> bool:
	if not _panel.visible:
		return false
	if intro != "":
		return tip_mode or intro_sub == 0
	return running and Tutorial.pauses_game(step, sub, GameState)


func _process_intro(delta: float) -> void:
	if tip_mode:
		# Tình huống không còn đúng (đã nâng, đã đổi tay đua...): đóng mẹo, coi như đã xem.
		var info := Tutorial.tip_info(intro, GameState)
		if info.is_empty():
			_finish_intro()
			return
		tip_data = info
		var tip_show := not blocked
		if tip_show and not _was_shown:
			reveal_requested.emit("tip:" + intro)
		_was_shown = tip_show
		_set_shown(tip_show)
		if tip_show:
			_pulse = fmod(_pulse + delta, 1.2)
			_update_view()
			queue_redraw()
		return
	var f := Tutorial.feature(intro)
	var lines := Tutorial.intro_lines(f)
	if intro_sub == 0 and Tutorial.intro_action_done(f, GameState):
		if lines.size() > 1:
			intro_sub = 1
			_timer = 0.0
		else:
			_finish_intro()
			return
	var show := not blocked
	if show and not _was_shown:
		reveal_requested.emit("intro:" + intro)
	_was_shown = show
	_set_shown(show)
	if not show:
		return
	_timer += delta
	if intro_sub == 1 and _timer >= Tutorial.AFTER_SEC:
		_finish_intro()
		return
	_pulse = fmod(_pulse + delta, 1.2)
	_update_view()
	queue_redraw()


func _process(delta: float) -> void:
	if intro != "":
		_process_intro(delta)
		return
	if not running:
		return
	if (step == "A4_engine" or step == "A5_ticket") and sub == 0 and Tutorial.action_done(step, GameState):
		sub = 1
		_timer = 0.0
	var show := not blocked and not _waiting()
	if show and not _was_shown:
		reveal_requested.emit(step)
	_was_shown = show
	_set_shown(show)
	if not show:
		return
	if not _confirm:
		_timer += delta
		var auto := float(Tutorial.AUTO_SEC.get(step, 0.0))
		if auto > 0.0 and _timer >= auto and not wants_pause():  # đang dừng game: chờ người chơi bấm Tiếp
			_advance()
		elif ((step == "A4_engine" or step == "A5_ticket") and sub == 1) or (step == "A7_race2" and sub == 0):
			if _timer >= Tutorial.AFTER_SEC:
				_advance()
	if not running:
		return
	_pulse = fmod(_pulse + delta, 1.2)
	_update_view()
	queue_redraw()


func _on_primary() -> void:
	if intro != "":
		_finish_intro()
		return
	if _confirm:
		_confirm = false  # "Tiếp tục hướng dẫn"
		return
	_advance()


func _on_skip() -> void:
	if intro != "":
		if tip_mode:
			GameState.set_tips_enabled(false)  # "Tắt mẹo": bật lại trong Cài đặt
		_finish_intro()
		return
	if _confirm:
		_finish("skipped")
		return
	_confirm = true


# ---------------------------------------------------------------- hiển thị

func _set_shown(on: bool) -> void:
	_panel.visible = on
	_portrait.visible = on
	if not on:
		_hand.visible = false
		_target = {}
		queue_redraw()


func _update_view() -> void:
	var expression := "smile"
	if intro != "" and tip_mode:
		expression = "point" if String(tip_data.get("target", "")) != "" else "smile"
		_portrait.texture = LINH_PORTRAITS[expression]
		_text.text = String(tip_data.get("text", ""))
		_primary.text = I18n.t("common.got")
		_primary.visible = true
		_skip.visible = false  # không có nút "Tắt mẹo" trên callout; tắt mẹo trong Cài đặt
		_target = target_provider.call("tip:" + intro, 0) if target_provider.is_valid() else {}
		_place_panel()
		return
	if intro != "":
		var f := Tutorial.feature(intro)
		var lines := Tutorial.intro_lines(f)
		expression = "excited" if intro_sub == 1 else ("point" if f.has("target") else "smile")
		_portrait.texture = LINH_PORTRAITS[expression]
		var line := String(lines[mini(intro_sub, lines.size() - 1)])
		if intro == "U3_bag" and "%s" in line:  # câu sau khi mở gói: Power đội vừa tăng
			line = line % GearPage._fmt_power(GameState.gear_power_bonus())
		_text.text = line
		_primary.text = I18n.t("common.got") if intro_sub == 0 else "Xong"
		_primary.visible = true
		_skip.visible = false
		_target = target_provider.call("intro:" + intro, intro_sub) if target_provider.is_valid() else {}
		_place_panel()
		return
	_skip.visible = true
	if not _confirm:
		if step == "A7_race2" or ((step == "A4_engine" or step == "A5_ticket") and sub == 1):
			expression = "excited"
		elif step in ["A2_car", "A3_income", "A4_engine", "A5_ticket"] or (step == "A6_result" and sub == 1):
			expression = "point"
	_portrait.texture = LINH_PORTRAITS[expression]
	var ctx: Dictionary = context_provider.call(step, _result) if context_provider.is_valid() else {}
	var txt: String
	if _confirm:
		txt = I18n.t("tutorial.skip_tutorial_you_can_still")
		_primary.text = I18n.t("common.continue")
		_skip.text = I18n.t("tutorial.skip")
	else:
		txt = Tutorial.line(step, sub, ctx)
		if _resumed:
			txt = I18n.t("tutorial.let_continue") + txt
		_primary.text = Tutorial.primary_text(step, sub)
		_skip.text = I18n.t("tutorial.skip")
	_primary.visible = _primary.text != ""
	_text.text = txt
	_target = target_provider.call(step, sub) if target_provider.is_valid() and not _confirm else {}
	_place_panel()


## Đặt callout cạnh mục tiêu (trên hoặc dưới) và bàn tay nếu có.
func _place_panel() -> void:
	_progress.text = I18n.t("tutorial.tip") if tip_mode else (I18n.t("tutorial.unlocked") if intro != "" else "%d / %d" % [maxi(1, Tutorial.STEPS.find(step) + 1), Tutorial.STEPS.size()])
	var w := minf(size.x - 32.0, 380.0)
	_panel.custom_minimum_size = Vector2(w, 0)
	_panel.size = Vector2(w, 0)
	var h := _panel.get_combined_minimum_size().y
	var pos := Vector2((size.x - w) * 0.5, size.y * 0.55)
	if _target.has("rect"):
		var r := _local(_target["rect"])
		if r.get_center().y < size.y * 0.5:
			pos.y = r.end.y + 40.0
		else:
			pos.y = r.position.y - h - 14.0
	pos.y = clampf(pos.y, 34.0, maxf(34.0, size.y - h - 8.0))
	_panel.position = pos
	_portrait.position = pos + Vector2(12, -26)
	var has_hand := _target.has("hand")
	_hand.visible = has_hand
	if has_hand:
		var bob := sin(_pulse / 1.2 * TAU) * 6.0
		_hand.position = _local_point(_target["hand"]) + Vector2(-8.0, 6.0 + bob)


func _local(r: Rect2) -> Rect2:
	return Rect2(r.position - global_position, r.size)


func _local_point(p: Vector2) -> Vector2:
	return p - global_position


func _draw() -> void:
	if not _active() or not _panel.visible:
		return
	if not _target.has("rect"):
		draw_rect(Rect2(Vector2.ZERO, size), C_DIM)
		return
	var r := _local(_target["rect"]).grow(6.0)
	var is_round := bool(_target.get("round", false))
	var a := 0.55 + 0.45 * sin(_pulse / 1.2 * TAU)
	var col := Color(C_RING, a)
	if is_round:
		# Nền đen phía sau callout; vòng trắng/cam giữ xe dễ nhận biết.
		draw_rect(Rect2(Vector2.ZERO, size), C_DIM)
		var c := r.get_center()
		var rad := minf(r.size.x, r.size.y) * 0.5
		draw_arc(c, rad, 0.0, TAU, 48, Color(1, 1, 1, 0.95), 8.0, true)
		draw_arc(c, rad, 0.0, TAU, 48, col, 4.5, true)
		draw_arc(c, rad + 8.0 + 6.0 * (_pulse / 1.2), 0.0, TAU, 48, Color(C_RING, 0.5 * (1.0 - _pulse / 1.2)), 3.0, true)
		return
	# Nền đen quanh mục tiêu, giữ ô cần thao tác sáng.
	draw_rect(Rect2(0, 0, size.x, maxf(0.0, r.position.y)), C_DIM)
	draw_rect(Rect2(0, r.end.y, size.x, maxf(0.0, size.y - r.end.y)), C_DIM)
	draw_rect(Rect2(0, r.position.y, maxf(0.0, r.position.x), r.size.y), C_DIM)
	draw_rect(Rect2(r.end.x, r.position.y, maxf(0.0, size.x - r.end.x), r.size.y), C_DIM)
	# Bo cả lỗ spotlight để nền tối không để lộ bốn góc vuông ngoài viền.
	var radius := minf(16.0, minf(r.size.x, r.size.y) * 0.5)
	if radius > 0.0:
		var corners := [
			Vector2(r.position.x, r.position.y),
			Vector2(r.end.x, r.position.y),
			Vector2(r.end.x, r.end.y),
			Vector2(r.position.x, r.end.y),
		]
		var centers := [
			r.position + Vector2(radius, radius),
			Vector2(r.end.x - radius, r.position.y + radius),
			r.end - Vector2(radius, radius),
			Vector2(r.position.x + radius, r.end.y - radius),
		]
		for i in 4:
			var points := PackedVector2Array([corners[i]])
			for segment in 17:
				var angle := PI + float(i) * PI * 0.5 + float(segment) / 16.0 * PI * 0.5
				points.append(centers[i] + Vector2(cos(angle), sin(angle)) * radius)
			draw_colored_polygon(points, C_DIM)
	if r.size.x > 0.0:
		var sb := StyleBoxFlat.new()
		sb.draw_center = false
		sb.border_color = col
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(16)
		sb.corner_detail = 16
		draw_style_box(sb, r)
