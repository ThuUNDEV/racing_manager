extends Control
## Art-only moving-sprite preview. Does not read or modify GameState/RaceSim.

const BACKGROUND := preload("res://assets/workshop_gp/textures/workshop_oval.png")
const CAR_FILES := ["orange", "graphite", "white", "blue", "red", "yellow", "teal", "purple"]
var cars: Array[Texture2D] = []
var path := Curve2D.new()
var seconds := 0.0
var animate_cars := true


func _ready() -> void:
	for color: String in CAR_FILES:
		cars.append(load("res://assets/workshop_gp/cars/%s.tres" % color) as Texture2D)
	_build_path()
	resized.connect(_build_path)


func _build_path() -> void:
	path.clear_points()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var k := 0.55228475
	var rx := 0.193
	var ry := 0.275
	_add(Vector2(0.263, 0.775), Vector2(-rx * k, 0), Vector2.ZERO)
	_add(Vector2(0.737, 0.775), Vector2.ZERO, Vector2(rx * k, 0))
	_add(Vector2(0.930, 0.500), Vector2(0, ry * k), Vector2(0, -ry * k))
	_add(Vector2(0.737, 0.225), Vector2(rx * k, 0), Vector2.ZERO)
	_add(Vector2(0.263, 0.225), Vector2.ZERO, Vector2(-rx * k, 0))
	_add(Vector2(0.070, 0.500), Vector2(0, -ry * k), Vector2(0, ry * k))
	_add(Vector2(0.263, 0.775), Vector2(-rx * k, 0), Vector2.ZERO)
	queue_redraw()


func _add(p: Vector2, incoming: Vector2, outgoing: Vector2) -> void:
	path.add_point(p * size, incoming * size, outgoing * size)


func _process(delta: float) -> void:
	if animate_cars:
		seconds += delta
		queue_redraw()


func _draw() -> void:
	draw_texture_rect(BACKGROUND, Rect2(Vector2.ZERO, size), false)
	var length := path.get_baked_length()
	if length < 1.0 or cars.is_empty():
		return
	for i in range(cars.size() - 1, -1, -1):
		var distance := fposmod(length * (0.04 + float(i) * 0.115) + seconds * 22.0, length)
		var p := path.sample_baked(distance)
		var next := path.sample_baked(fposmod(distance + 0.6, length))
		var direction := (next - p).normalized()
		# Source sprites face DOWN (+Y), so subtract PI/2 to face along the path.
		if i == 0:
			draw_arc(p, 13.0, 0, TAU, 28, Color("fff9e9"), 1.7, true)
		draw_set_transform(p, direction.angle() - PI * 0.5)
		var dimensions := Vector2(11.0, 21.0)
		draw_texture_rect(cars[i], Rect2(-dimensions * 0.5, dimensions), false)
		draw_set_transform(Vector2.ZERO)
