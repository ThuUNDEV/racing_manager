extends RefCounted
## Temporary presentation zoom for the car-identification lesson.
## Leave the race renderer and simulation unchanged; restore the original framing on exit.
const ZOOM := 1.45
const TRANSITION_SEC := 0.35
const PAN_SHARE := 0.65

var _camera: Camera3D
var _base_size := 0.0
var _base_position := Vector3.ZERO
var _last_size := 0.0
var _last_position := Vector3.ZERO
var _amount := 0.0


func update(view: RaceView, enabled: bool, delta: float) -> void:
	var world: RefCounted = view._world_3d
	if not view._use_3d or world == null or view.sim == null:
		reset()
		return
	if _camera != world.camera:
		reset()
		if not enabled:
			return
		_camera = world.camera
		_capture_base()
	# A resize, track rebuild or user rotation may refit the camera between frames.
	if not is_equal_approx(_camera.size, _last_size) or not _camera.position.is_equal_approx(_last_position):
		_capture_base()
	_amount = move_toward(_amount, 1.0 if enabled else 0.0, delta / TRANSITION_SEC)
	if _amount <= 0.0:
		reset()
		return
	var weight := _amount * _amount * (3.0 - 2.0 * _amount)
	var player := view.sim.player_car()
	var focus: Vector3 = world.at(view.sim.render_pos(player, view.alpha), view.sim.render_lat(player, view.alpha) * RaceView.ROAD_WIDTH_SCALE, 0.11)
	var offset := focus - _base_position
	var pan := _camera.basis.x * offset.dot(_camera.basis.x) + _camera.basis.y * offset.dot(_camera.basis.y)
	_camera.size = _base_size / lerpf(1.0, ZOOM, weight)
	_camera.position = _base_position + pan * PAN_SHARE * weight
	_last_size = _camera.size
	_last_position = _camera.position
	view.queue_redraw()


func _capture_base() -> void:
	_base_size = _camera.size
	_base_position = _camera.position
	_last_size = _base_size
	_last_position = _base_position


func reset() -> void:
	if is_instance_valid(_camera):
		_camera.size = _base_size
		_camera.position = _base_position
	_camera = null
	_amount = 0.0
