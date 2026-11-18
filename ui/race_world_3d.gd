extends RefCounted
## One shared 3D world for the circuit, scenery and all eight cars.
const CAR = preload("res://assets/models/race_car/race_car.tscn")
const SCALE := 0.1
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var layout: TrackLayout
var center := Vector2.ZERO
var portrait := false
var cars: Dictionary = {}
var paints: Dictionary = {}
var materials: Dictionary = {}
var vertices := PackedVector3Array()
var colors := PackedColorArray()
var road_width := 5.5
var sample_step := 3.0
var host: Control
var view_rect := Rect2()
const DEFAULT_YAW := PI * 0.25
var camera_yaw := DEFAULT_YAW
var _frame_corners := PackedVector3Array()

func _init(control: Control) -> void:
	host = control
	viewport = SubViewport.new()
	viewport.name = "Circuit3DViewport"
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.msaa_3d = Viewport.MSAA_2X
	host.add_child(viewport)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.far = 1000.0
	viewport.add_child(camera)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.background_color = Color("47bfd4")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d8ecff")
	env.environment.ambient_light_energy = 0.45
	env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	viewport.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 250.0
	viewport.add_child(sun)

func mat(hex: String) -> StandardMaterial3D:
	if not materials.has(hex):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(hex)
		m.roughness = 0.8
		materials[hex] = m
	return materials[hex]

func point(p: Vector2, height: float = 0.0) -> Vector3:
	var q := p - center
	if portrait:
		q = Vector2(q.y, -q.x)
	return Vector3(q.x * SCALE, height, q.y * SCALE)

func at(s: float, lateral: float = 0.0, height: float = 0.04) -> Vector3:
	return point(layout.point_at(s, lateral), height + layout.elevation_at(s) * SCALE)

func mesh_part(label: String, mesh: Mesh, pos: Vector3, color: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = mat(color)
	node.position = pos
	world.add_child(node)
	return node

func box(label: String, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh_part(label, mesh, pos, color)

func island(label: String, size: Vector2, bottom: float, top: float, color: String) -> void:
	var x := size.x*0.5
	var z := size.y*0.5
	var bevel := minf(x,z)*0.28
	var outline := [Vector2(-x+bevel,-z),Vector2(x-bevel,-z),Vector2(x,-z+bevel),Vector2(x,z-bevel),Vector2(x-bevel,z),Vector2(-x+bevel,z),Vector2(-x,z-bevel),Vector2(-x,-z+bevel)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 8:
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i+1)%8]
		for p: Vector3 in [Vector3(0,top,0),Vector3(a.x,top,a.y),Vector3(b.x,top,b.y),Vector3(a.x,bottom,a.y),Vector3(b.x,top,b.y),Vector3(a.x,top,a.y),Vector3(a.x,bottom,a.y),Vector3(b.x,bottom,b.y),Vector3(b.x,top,b.y)]:
			surface.add_vertex(p)
	surface.generate_normals()
	mesh_part(label,surface.commit(),Vector3.ZERO,color)

func cylinder(label: String, pos: Vector3, radius: float, height: float, color: String, top: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0 else top
	mesh.height = height
	mesh.radial_segments = 8
	return mesh_part(label, mesh, pos, color)

func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	for p: Vector3 in [a,b,c,a,c,d]:
		vertices.append(p)
		colors.append(color)

func strip(s: float, end: float, left: float, right: float, height: float, color: Color) -> void:
	quad(at(s,left,height),at(end,left,height),at(end,right,height),at(s,right,height),color)

func rebuild(track: TrackLayout, size: Vector2, width: float) -> void:
	var same_track := layout == track and world != null
	layout = track
	road_width = width
	center = layout.bounds.get_center()
	portrait = layout.bounds.size.y > layout.bounds.size.x
	view_rect = Rect2(size.x * 0.035, size.y * 0.22, maxf(size.x * 0.86, 8), maxf(size.y * 0.72, 8))
	viewport.size = Vector2i(view_rect.size * 2.0)
	if same_track:
		var dimensions := layout.bounds.grow(28.0).size * SCALE
		if portrait:
			dimensions = Vector2(dimensions.y, dimensions.x)
		fit_camera(dimensions)
		return
	if world != null:
		viewport.remove_child(world)
		world.queue_free()
	world = Node3D.new()
	world.name = "HarborCircuit3D"
	viewport.add_child(world)
	cars.clear()
	paints.clear()
	vertices.clear()
	colors.clear()
	var bounds := layout.bounds.grow(28.0)
	var dims := bounds.size * SCALE
	if portrait:
		dims = Vector2(dims.y,dims.x)
	island("IslandRock",dims+Vector2.ONE,-1.6,-0.1,"d5b786")
	island("IslandSand",dims+Vector2.ONE*0.35,-0.35,0.005,"f5dc9c")
	island("IslandGrass",dims,-0.12,0.045,"86c76a")
	# The transparent 3D scene shares the HUD sea instead of a separate ocean rectangle.
	var s := 0.0
	while s < layout.lap_length:
		var end := minf(s+sample_step,layout.lap_length)
		var half := layout.width_at(s)*road_width*0.5*1.55
		var half_end := layout.width_at(end)*road_width*0.5*1.55
		quad(at(s,half+3,0.06),at(end,half_end+3,0.06),at(end,-half_end-3,0.06),at(s,-half-3,0.06),Color("d6cfb6"))
		quad(at(s,half,0.08),at(end,half_end,0.08),at(end,-half_end,0.08),at(s,-half,0.08),Color("616e7b"))
		for sign_value: float in [-1.0,1.0]:
			var inner := sign_value * half
			var outer := sign_value * (half+2.0)
			quad(at(s,inner,0.095),at(end,sign_value*half_end,0.095),at(end,sign_value*(half_end+2),0.095),at(s,outer,0.095),Color("f26c59") if int(s/6)%2==0 else Color("fff5dd"))
		if int(s / sample_step) % 6 < 2:
			strip(s,end,0.25,-0.25,0.10,Color("e3e8df"))
		s = end
	var start_half := layout.width_at(0)*road_width*0.5*1.55
	for row in 2:
		for column in 12:
			strip(-2+row*2, row*2, -start_half+column*start_half/6,-start_half+(column+1)*start_half/6,0.12,Color.WHITE if (row+column)%2==0 else Color("263443"))
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = normals
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var road_material := StandardMaterial3D.new()
	road_material.vertex_color_use_as_albedo = true
	road_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var road := MeshInstance3D.new()
	road.name = "RoadKerbsAndFinish"
	road.mesh = mesh
	road.material_override = road_material
	world.add_child(road)
	build_bridge()
	build_fences()
	build_props(bounds)
	for id in Balance.CAR_COUNT:
		var car: Node3D = CAR.instantiate()
		car.name = "RaceCar%d" % id
		car.scale = Vector3.ONE * 0.55
		world.add_child(car)
		cars[id] = car
		var paint := StandardMaterial3D.new()
		paint.roughness = 0.5
		paints[id] = paint
		assign_paint(car,paint)
	_cache_frame_corners()
	fit_camera(dims)

func assign_paint(node: Node, paint: Material) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.material_override != null and child.material_override.resource_name == "Body_Paint_Blue":
			child.material_override = paint
		assign_paint(child,paint)

func _cache_frame_corners() -> void:
	_frame_corners.clear()
	for node in world.find_children("*", "MeshInstance3D", true, false):
		if node.name == "Ocean" or node.get_parent().name.begins_with("RaceCar"):
			continue
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		var bounds := mesh_node.mesh.get_aabb()
		for corner in 8:
			_frame_corners.append(mesh_node.global_transform * bounds.get_endpoint(corner))

func rotate_view(radians: float) -> void:
	camera_yaw = wrapf(camera_yaw + radians, -PI, PI)
	fit_camera(Vector2.ZERO)

func reset_view() -> void:
	camera_yaw = DEFAULT_YAW
	fit_camera(Vector2.ZERO)

func fit_camera(_dims: Vector2) -> void:
	# Orbit horizontally while retaining the isometric elevation and orthographic lens.
	var elevation := asin(1.0 / sqrt(3.0))
	var direction := Vector3(sin(camera_yaw)*cos(elevation),sin(elevation),cos(camera_yaw)*cos(elevation))
	camera.position = direction * 150.0
	camera.look_at(Vector3.ZERO)
	var frame := Rect2()
	var first := true
	for position in _frame_corners:
		var projected := Vector2(camera.basis.x.dot(position), camera.basis.y.dot(position))
		if first:
			frame = Rect2(projected, Vector2.ZERO)
			first = false
		else:
			frame = frame.expand(projected)
	var ratio := view_rect.size.x / view_rect.size.y
	camera.size = maxf(frame.size.y + 2.0, (frame.size.x + 2.0) / ratio) * 1.04
	var midpoint := frame.get_center()
	camera.position += camera.basis.x * midpoint.x + camera.basis.y * midpoint.y

func build_bridge() -> void:
	if layout.shape != "figure_eight":
		return
	# Thin structural deck follows the ramps, with concrete abutments off the underpass.
	var s := layout.lap_length*0.11
	while s < layout.lap_length*0.39:
		var next := s+sample_step
		var a := at(s,0,-0.08)
		var b := at(next,0,-0.08)
		var half := layout.width_at(s)*road_width*0.5*1.55+2.0
		var deck := box("BridgeDeck",(a+b)*0.5,Vector3(half*2*SCALE,0.22,a.distance_to(b)+0.03),"c6bd9e")
		deck.look_at(b)
		s = next
	for fraction: float in [0.19,0.31]:
		for side: float in [-1.0,1.0]:
			var half := layout.width_at(fraction*layout.lap_length)*road_width*0.5*1.55+1.0
			var pos := at(fraction*layout.lap_length,side*half)
			box("BridgePillar",Vector3(pos.x,pos.y*0.5,pos.z),Vector3(0.35,pos.y,0.45),"e8d7b1")

func build_fences() -> void:
	var s := 0.0
	while s < layout.lap_length:
		var next := minf(s+12.0,layout.lap_length)
		var half := layout.width_at(s)*road_width*0.5*1.55+5.0
		var next_half := layout.width_at(next)*road_width*0.5*1.55+5.0
		for sign_value: float in [-1.0,1.0]:
			var a := at(s,half*sign_value,0.45)
			var b := at(next,next_half*sign_value,0.45)
			box("FencePost",a,Vector3(0.12,0.9,0.12),"fff2d6")
			var rail := box("SafetyRail",(a+b)*0.5,Vector3(0.11,0.24,a.distance_to(b)),"f5e8cc")
			rail.look_at(b)
		s = next

func clearance(p: Vector2) -> float:
	var closest := INF
	var s := 0.0
	while s < layout.lap_length:
		var a := layout.pos_at(s)
		var b := layout.pos_at(minf(s+6.0,layout.lap_length))
		var distance := p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b)) - layout.width_at(s)*road_width*0.5*1.55
		closest = minf(closest,distance)
		s += 6.0
	return closest

func build_props(bounds: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(layout.lap_length*100)
	var occupied: Array[Vector2] = []
	var building_count := 0
	for attempt in 260:
		var p := bounds.position + Vector2(rng.randf(),rng.randf())*bounds.size
		var room := clearance(p)
		if room < 13:
			continue
		var free := true
		for other in occupied:
			if p.distance_to(other) < 23:
				free = false
		if not free:
			continue
		occupied.append(p)
		var pos := point(p)
		if room > 25 and building_count < 2:
			if building_count == 0:
				garage(pos)
			else:
				grandstand(pos)
			building_count += 1
		else:
			tree(pos,rng.randf_range(0.8,1.35))
		if occupied.size() >= 32:
			break
	# Coastal dock and cargo sit outside the driving surface.
	var corner := Vector3(bounds.size.x*SCALE*0.20,-0.35,(bounds.size.x if portrait else bounds.size.y)*SCALE*0.5+1.2)
	box("HarborDock",corner,Vector3(5,0.25,2.4),"bd9569")
	for i in 4:
		box("DockPlank",corner+Vector3(float(i)-1.5,0.15,0),Vector3(0.05,0.03,2.4),"e9c68e")
	for i in 3:
		box("Cargo",corner+Vector3(float(i)*1.2-1.2,0.55,0.1),Vector3(1,0.8,1),["fa9950","55b2d9","f5d05c"][i])

func tree(pos: Vector3, scale_factor: float) -> void:
	cylinder("TreeTrunk",pos+Vector3(0,0.6,0),0.14,1.2,"b48251")
	for i in 2:
		var mesh := SphereMesh.new()
		mesh.radius = (0.85-float(i)*0.15)*scale_factor
		mesh.height = mesh.radius*1.7
		mesh.radial_segments = 8
		mesh.rings = 4
		mesh_part("TreeCrown",mesh,pos+Vector3(float(i)*0.3,1.25+float(i)*0.65,0),"55ab51" if i==0 else "8bc84d")

func garage(pos: Vector3) -> void:
	box("Garage",pos+Vector3(0,0.85,0),Vector3(3.6,1.7,2.3),"ffe7bb")
	var roof := box("GarageRoof",pos+Vector3(0,1.85,0),Vector3(4,0.3,2.7),"f37859")
	roof.rotation.z = 0.06
	for x: float in [-0.95,0.95]:
		box("GarageDoor",pos+Vector3(x,0.65,1.16),Vector3(1.4,1.2,0.05),"54798a")
		for row in 4:
			box("DoorSlat",pos+Vector3(x,0.25+row*0.24,1.20),Vector3(1.32,0.025,0.02),"a9c9d0")
	box("GarageSign",pos+Vector3(0,1.65,1.3),Vector3(1.6,0.4,0.12),"37a9dc")

func grandstand(pos: Vector3) -> void:
	for row in 3:
		box("StandTier",pos+Vector3(0,0.18+row*0.26,-row*0.45),Vector3(4,0.32,0.65),"e6cf9d")
		for seat in 9:
			var fan := pos+Vector3(-1.6+seat*0.4,0.58+row*0.26,-row*0.45)
			cylinder("Spectator",fan,0.12,0.3,["359bda","f6cc54","f27d5b"][seat%3])
			cylinder("FanHead",fan+Vector3(0,0.23,0),0.10,0.16,"ffdab0")
	for x: float in [-2.0,2.0]:
		box("CanopyPost",pos+Vector3(x,1.25,-0.4),Vector3(0.12,2.5,0.12),"fff1d2")
	for stripe in 8:
		box("StandCanopy",pos+Vector3(-1.84+stripe*0.525,2.55,-0.45),Vector3(0.53,0.16,2.2),"f4775d" if stripe%2==0 else "fff4dc")

func update_car(id: int, s: float, lateral: float, yaw: float, color: Color) -> void:
	if not cars.has(id):
		return
	var car: Node3D = cars[id]
	car.position = at(s,lateral*1.55,0.11)
	var direction := at(s+0.5,lateral*1.55,0.11)-car.position
	car.look_at(car.position+direction,Vector3.UP)
	car.rotate_object_local(Vector3.UP,yaw)
	paints[id].albedo_color = color
	for child in car.get_children():
		if String(child.name).ends_with("Wheel"):
			child.rotation.x = -s*SCALE/(0.32*0.55)

func screen_point(p: Vector2, height: float = 0.0) -> Vector2:
	return view_rect.position + camera.unproject_position(point(p,height))*0.5

func screen_at(s: float, lateral: float) -> Vector2:
	return view_rect.position + camera.unproject_position(at(s,lateral,0.11))*0.5
