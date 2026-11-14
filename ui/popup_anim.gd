extends RefCounted
## Hoạt ảnh mở/tắt popup dùng chung: nền mờ dần, hộp bật nhẹ từ giữa (mở) và thu lại (tắt).
## Tắt hẳn khi chạy headless (test) hoặc khi `enabled = false` (chụp ảnh) để trạng thái đổi ngay lập tức.

const OPEN_SEC := 0.3
const OVERSHOOT := 1.2
const GROW_SEC := 0.18
const CLOSE_SEC := 0.16
const FROM_SCALE := 0.0
const TO_SCALE := 0.8
const META := "_popup_anim_tween"

static var enabled := true


static func _active() -> bool:
	return enabled and DisplayServer.get_name() != "headless"


static func motion_on() -> bool:
	return _active()


static func _kill(root: Control) -> void:
	if root.has_meta(META):
		var old := root.get_meta(META) as Tween
		if old != null and old.is_valid():
			old.kill()
		root.remove_meta(META)


static func _pivot(panel: Control) -> void:
	panel.pivot_offset = panel.size * 0.5


## Hiện `root` và chạy hoạt ảnh mở trên `panel` (hộp nội dung bên trong root).
static func open(root: Control, panel: Control) -> void:
	_kill(root)
	var was_visible := root.visible
	root.show()
	if not _active() or panel == null or was_visible and root.modulate.a >= 0.99:
		root.modulate.a = 1.0
		if panel != null:
			panel.scale = Vector2.ONE
		return
	if not panel.resized.is_connected(_pivot.bind(panel)):
		panel.resized.connect(_pivot.bind(panel))
	_pivot(panel)
	root.modulate.a = 0.0
	panel.scale = Vector2.ONE * FROM_SCALE
	var tw := root.create_tween().set_parallel(true)
	tw.tween_property(root, "modulate:a", 1.0, OPEN_SEC * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Phóng lên 1.2 lần rồi thu về 1.
	tw.tween_property(panel, "scale", Vector2.ONE * OVERSHOOT, GROW_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, OPEN_SEC - GROW_SEC).set_delay(GROW_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	root.set_meta(META, tw)


## Chạy hoạt ảnh tắt rồi ẩn `root`; gọi `done` sau khi đã ẩn (kể cả khi không có hoạt ảnh).
static func close(root: Control, panel: Control, done: Callable = Callable()) -> void:
	if not root.visible:
		if done.is_valid():
			done.call()
		return
	if not _active() or panel == null or not root.is_inside_tree():
		_finish(root, panel, done)
		return
	_kill(root)
	_pivot(panel)
	var tw := root.create_tween().set_parallel(true)
	tw.tween_property(root, "modulate:a", 0.0, CLOSE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(panel, "scale", Vector2.ONE * TO_SCALE, CLOSE_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(_finish.bind(root, panel, done))
	root.set_meta(META, tw)


static func _finish(root: Control, panel: Control, done: Callable) -> void:
	if not is_instance_valid(root):
		return
	root.hide()
	root.modulate.a = 1.0
	if panel != null and is_instance_valid(panel):
		panel.scale = Vector2.ONE
	if root.has_meta(META):
		root.remove_meta(META)
	if done.is_valid():
		done.call()


## Bấm vào vùng nền tối (ngoài `panel`) thì gọi `on_outside`. Dùng được cả khi lớp nền bị Container che.
static func close_on_outside_click(root: Control, panel: Control, on_outside: Callable) -> void:
	root.gui_input.connect(func(event: InputEvent) -> void:
		if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			return
		if not root.visible or not is_instance_valid(panel):
			return
		if panel.get_global_rect().has_point(event.global_position):
			return
		root.accept_event()
		on_outside.call())


## Chuyển tab (fade chéo): trang mới mờ dần hiện lên trong khi trang cũ mờ dần đi.
static func page_in(page: Control) -> void:
	_kill(page)
	page.show()
	if not _active():
		page.modulate.a = 1.0
		return
	page.modulate.a = 0.0
	var tw := page.create_tween()
	tw.tween_property(page, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	page.set_meta(META, tw)


static func page_out(page: Control) -> void:
	_kill(page)
	if not _active() or not page.visible:
		page.hide()
		page.modulate.a = 1.0
		return
	var tw := page.create_tween()
	tw.tween_property(page, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(_hide_page.bind(page))
	page.set_meta(META, tw)


static func _hide_page(page: Control) -> void:
	if not is_instance_valid(page):
		return
	page.hide()
	page.modulate.a = 1.0
	if page.has_meta(META):
		page.remove_meta(META)
