extends ScrollContainer
## Finger scrolling independent of the platform's mouse-emulation behavior.
## Keep button taps, cancel button presses once a gesture becomes a vertical swipe.

var _finger := -1
var _distance := Vector2.ZERO
var _dragging := false
var _speed := 0.0
var _last_motion := 0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1:
			_stop_scroll()
			_finger = event.index
			_distance = Vector2.ZERO
			_last_motion = Time.get_ticks_msec()
		elif not event.pressed and event.index == _finger:
			_finger = -1
			if _dragging:
				if event.canceled or Time.get_ticks_msec() - _last_motion > 100:
					_speed = 0.0
				accept_event()
		return
	if event is InputEventScreenDrag and event.index == _finger:
		_distance += event.relative
		if not _dragging and absf(_distance.y) > scroll_deadzone and absf(_distance.y) > absf(_distance.x):
			_dragging = true
			propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
			scroll_started.emit()
		if _dragging:
			var now := Time.get_ticks_msec()
			var elapsed := maxf((now - _last_motion) / 1000.0, 0.008)
			_speed = clampf(-event.relative.y / elapsed, -1800.0, 1800.0)
			_last_motion = now
			scroll_vertical = roundi(scroll_vertical - event.relative.y)
			accept_event()
		return
	# Avoid the native mouse-based drag path applying the same motion twice.
	if _finger != -1 and (event is InputEventMouseButton or event is InputEventMouseMotion):
		accept_event()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		_finger = -1
		_stop_scroll()
		return
	if _finger != -1 or not _dragging:
		return
	var before := scroll_vertical
	scroll_vertical = roundi(scroll_vertical + _speed * delta)
	_speed = move_toward(_speed, 0.0, 3200.0 * delta)
	if absf(_speed) < 15.0 or scroll_vertical == before:
		_stop_scroll()


func _stop_scroll() -> void:
	_speed = 0.0
	if _dragging:
		_dragging = false
		propagate_notification(Control.NOTIFICATION_SCROLL_END)
		scroll_ended.emit()

func _ready() -> void:
	scroll_deadzone = 10
	_prepare_branch(self)
	get_tree().node_added.connect(_prepare_control)


func _prepare_branch(node: Node) -> void:
	for child in node.get_children():
		_prepare_control(child)
		_prepare_branch(child)


func _prepare_control(node: Node) -> void:
	if not is_ancestor_of(node) or node is ScrollBar:
		return
	if node is Control and node.mouse_filter == Control.MOUSE_FILTER_STOP:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
