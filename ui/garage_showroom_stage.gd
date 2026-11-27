extends Node3D
## Garage-only geometry. The illustrated rear wall ends above the painted platform.
const TOP := 0.0
var _wall: MeshInstance3D
var _wall_ratio := 0.0

func _init(backdrop: Texture2D) -> void:
	name = "GarageStage"
	var floor_material := _material(Color("cba58b"), 0.82)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(60, 60)
	_add_mesh("Floor", floor_mesh, floor_material, Vector3(0, -0.245, 0))
	var blue := _material(Color("609edc"), 0.62)
	var cream := _material(Color("fff1d4"), 0.75)
	var base := CylinderMesh.new()
	base.top_radius = 2.44
	base.bottom_radius = 2.56
	base.height = 0.22
	base.radial_segments = 96
	_add_mesh("TurntableBase", base, blue, Vector3(0, -0.13, 0))
	var top := CylinderMesh.new()
	top.top_radius = 2.38
	top.bottom_radius = 2.42
	top.height = 0.08
	top.radial_segments = 96
	_add_mesh("TurntableTop", top, _material(Color("86b9ea"), 0.68), Vector3(0, -0.04, 0))
	var rim := TorusMesh.new()
	rim.inner_radius = 2.36
	rim.outer_radius = 2.46
	rim.rings = 96
	rim.ring_segments = 12
	_add_mesh("RoundedRim", rim, blue, Vector3(0, -0.04, 0))
	for parity in 2:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for row in 2:
			var upper_y := -0.055 - row * 0.075
			var lower_y := upper_y - 0.075
			var upper_radius := 2.44 + (-upper_y - 0.02) * 0.12 / 0.22 + 0.006
			var lower_radius := 2.44 + (-lower_y - 0.02) * 0.12 / 0.22 + 0.006
			for segment in 40:
				if (segment + row) % 2 != parity:
					continue
				var a := TAU * segment / 40.0
				var b := TAU * (segment + 1) / 40.0
				var points := [Vector3(cos(a) * upper_radius, upper_y, sin(a) * upper_radius), Vector3(cos(b) * upper_radius, upper_y, sin(b) * upper_radius), Vector3(cos(b) * lower_radius, lower_y, sin(b) * lower_radius), Vector3(cos(a) * lower_radius, lower_y, sin(a) * lower_radius)]
				for index in [0, 2, 1, 0, 3, 2]:
					var point: Vector3 = points[index]
					surface.set_normal(Vector3(point.x, 1.3, point.z).normalized())
					surface.add_vertex(point)
		_add_mesh("CheckerBlue" if parity == 0 else "CheckerCream", surface.commit(), blue if parity == 0 else cream)
	# Floor joints belong to the same camera and receive the same perspective.
	var joint := _material(Color("dec3ac"), 0.9)
	for index in range(-5, 6):
		var line_x := BoxMesh.new()
		line_x.size = Vector3(0.012, 0.002, 18)
		_add_mesh("FloorJointX", line_x, joint, Vector3(index * 1.6, -0.243, 0))
		var line_z := BoxMesh.new()
		line_z.size = Vector3(18, 0.002, 0.012)
		_add_mesh("FloorJointZ", line_z, joint, Vector3(0, -0.243, index * 1.6))
	if backdrop != null:
		var wall_material := _material(Color.WHITE, 1.0)
		wall_material.albedo_texture = backdrop
		wall_material.uv1_scale = Vector3(1.0, 0.535, 1.0)
		wall_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var wall := QuadMesh.new()
		_wall_ratio = backdrop.get_height() * 0.535 / backdrop.get_width()
		wall.size = Vector2(18, 18 * _wall_ratio)
		_wall = _add_mesh("WorkshopWall", wall, wall_material, Vector3(0, wall.size.y * 0.5 - 0.245, -4.2))

func fit_backdrop(width: float) -> void:
	if _wall == null:
		return
	var wall := _wall.mesh as QuadMesh
	wall.size = Vector2(width, width * _wall_ratio)
	_wall.position.y = wall.size.y * 0.5 - 0.245

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _add_mesh(node_name: String, mesh: Mesh, material: Material, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	add_child(instance)
	return instance
