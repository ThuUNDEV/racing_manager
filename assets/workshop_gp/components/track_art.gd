extends Control
const CleanArt = preload("res://ui/clean_modern_art.gd")
## Pure rendering component: caller supplies normalized lap distances via set_racers().
## Does not advance a race or infer a gameplay sector from the painted road.
const ROOT := "res://assets/workshop_gp/"
const COLORS := ["orange", "graphite", "white", "blue", "red", "yellow", "teal", "purple"]
@export_enum("harbor", "pine", "city") var track_id := "harbor"
@export var debug_path := false
var _background: Texture2D
var _cars: Array[Texture2D] = []
var _path := Curve2D.new()
var _definition: Dictionary
var _racers: Array = []


func _ready() -> void:
	clip_contents = true
	for color: String in COLORS:
		_cars.append(CleanArt.asset(ROOT + "cars/" + color + ".tres") as Texture2D)
	set_track(track_id)
	resized.connect(_build_path)


func set_track(id: String) -> void:
	track_id = id
	var json := FileAccess.get_file_as_string(ROOT + "layout/" + id + ".json")
	_definition = JSON.parse_string(json) as Dictionary
	_background = CleanArt.asset(ROOT + str(_definition.texture)) as Texture2D
	_build_path()


func set_racers(racers: Array) -> void:
	# Each entry: {"lap_fraction": 0.0..1.0, "color": 0..7, "player": bool}.
	_racers = racers
	queue_redraw()


func _build_path() -> void:
	_path.clear_points()
	if not _definition.has("points"):
		return
	for p: Array in _definition.points:
		_path.add_point(Vector2(p[0], p[1]) * size, Vector2(p[2], p[3]) * size, Vector2(p[4], p[5]) * size)
	queue_redraw()


func _draw() -> void:
	if _background == null:
		return
	draw_texture_rect(_background, Rect2(Vector2.ZERO, size), false)
	var length := _path.get_baked_length()
	if length < 1 or _cars.is_empty():
		return
	if debug_path:
		draw_polyline(_path.get_baked_points(), Color("00ffbd"), 1.5, true)
	for racer: Dictionary in _racers:
		var distance := fposmod(float(racer.get("lap_fraction", 0)), 1) * length
		var p := _path.sample_baked(distance)
		var next := _path.sample_baked(fposmod(distance + 0.5, length))
		var direction := (next-p).normalized()
		if bool(racer.get("player", false)):
			draw_arc(p, 11, 0, TAU, 24, Color("fff8e7"), 1.6, true)
			var mark := p + Vector2(0, -17)
			draw_colored_polygon(PackedVector2Array([mark+Vector2(-4,-3), mark+Vector2(4,-3), mark+Vector2(0,3)]), Color("f47510"))
		draw_set_transform(p, direction.angle()-PI/2)
		var extent := Vector2(10, 19)
		draw_texture_rect(_cars[clampi(int(racer.get("color", 0)),0,7)], Rect2(-extent/2,extent), false)
		draw_set_transform(Vector2.ZERO)
