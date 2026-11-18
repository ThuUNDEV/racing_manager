extends RefCounted
## Transparent 3D renders composited by RaceView in its existing draw order.
const MODEL = preload("res://assets/models/race_car/race_car.tscn")
var viewport: SubViewport
var car: Node3D
var paint: StandardMaterial3D

func _init(host: Control) -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(96, 96)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.add_child(viewport)
	car = MODEL.instantiate()
	viewport.add_child(car)
	paint = _find_paint(car)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.2
	viewport.add_child(camera)
	camera.position = Vector3(0, 6, 4)
	camera.look_at(Vector3(0, 0.45, 0))
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 1.0
	viewport.add_child(light)

func _find_paint(node: Node) -> StandardMaterial3D:
	var result: StandardMaterial3D = null
	for child in node.get_children():
		if child is MeshInstance3D and child.material_override != null and child.material_override.resource_name == "Body_Paint_Blue":
			if paint == null:
				paint = child.material_override.duplicate()
			child.material_override = paint
			result = paint
		else:
			var found := _find_paint(child)
			if found != null:
				result = found
	return result if result != null else paint

func update(heading: float, color: Color) -> Texture2D:
	# Camera foreshortens the ground's Z axis; undo that for the screen tangent.
	car.rotation.y = atan2(-cos(heading), -sin(heading) / 0.83)
	paint.albedo_color = color
	return viewport.get_texture()
