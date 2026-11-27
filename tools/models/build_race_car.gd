extends SceneTree
## Original procedural miniature cars. No external meshes, textures or reference art.
const OUT := "res://assets/models/race_car/"
const NAMES := ["pico", "nova", "apex", "titan", "zenith"]
var car: Node3D
var body_tier := 0
const NOSE_WIDTH := [0.87,0.93,0.77,1.0,0.62]

func material(label: String, color: String, roughness: float = 0.48, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = label
	m.albedo_color = Color(color)
	m.roughness = roughness
	m.metallic = metallic
	return m

func part(label: String, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	n.material_override = mat
	car.add_child(n)
	n.owner = car
	n.position = pos
	return n

## Six subdivided faces projected onto a rounded box: analytic smooth normals,
## broad flat decal surfaces, curved edges instead of chamfered low-poly facets.
func soft_box(label: String, size: Vector3, pos: Vector3, radius: float, mat: Material, taper: float = 1.0, roof_mat: Material = null) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roof_surface := SurfaceTool.new()
	roof_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
	var inner := half - Vector3.ONE * radius
	var steps := 20
	for axis in 3:
		for sign_value in [-1.0, 1.0]:
			var surface := roof_surface if roof_mat != null and axis == 1 and sign_value > 0 else st
			for u in steps:
				for v in steps:
					for raw_corner in [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(0,0), Vector2i(1,1), Vector2i(0,1)]:
						var corner: Vector2i = Vector2i(raw_corner.y,raw_corner.x) if sign_value > 0 else raw_corner
						var p := Vector3.ZERO
						p[axis] = sign_value * half[axis]
						p[(axis+1)%3] = lerpf(-half[(axis+1)%3], half[(axis+1)%3], float(u+corner.x)/steps)
						p[(axis+2)%3] = lerpf(-half[(axis+2)%3], half[(axis+2)%3], float(v+corner.y)/steps)
						var q := p.clamp(-inner, inner)
						var normal := (p-q).normalized()
						p = q + normal * radius
						var factor := lerpf(1.0, taper, (p.y+half.y)/size.y)
						var z_taper := 0.66 if taper < 1.0 else 1.0
						var z_factor := lerpf(1.0,z_taper,(p.y+half.y)/size.y)
						normal = Vector3(normal.x/factor, normal.y-normal.x/factor*p.x*(taper-1.0)/size.y-normal.z/z_factor*p.z*(z_taper-1.0)/size.y,normal.z/z_factor).normalized()
						p.x *= factor
						p.z *= z_factor
						if label == "Body" and p.z < 0:
							var nose: float = NOSE_WIDTH[body_tier]
							var width_factor := lerpf(1.0,nose,-p.z/half.z)
							normal = Vector3(normal.x/width_factor,normal.y,normal.z-normal.x/width_factor*p.x*(1.0-nose)/half.z).normalized()
							p.x *= width_factor
						if label == "Body" or label == "Cabin_Glass":
							var dome := 0.14 if label == "Body" else 0.12
							var xx := p.x/half.x
							var zz := p.z/half.z
							var dx := -2.0*dome*xx/half.x*(1.0-zz*zz)
							var dz := -2.0*dome*zz/half.z*(1.0-xx*xx)
							p.y += dome*(1.0-xx*xx)*(1.0-zz*zz)
							normal = Vector3(normal.x-normal.y*dx,normal.y,normal.z-normal.y*dz).normalized()
						surface.set_normal(normal)
						surface.add_vertex(p)
	st.index()
	var n := part(label, st.commit(), pos, mat)
	if roof_mat != null:
		roof_surface.index()
		part("Roof",roof_surface.commit(),pos,roof_mat)
	return n

func cylinder(label: String, radius: float, depth: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = depth
	mesh.radial_segments = 40
	var n := part(label, mesh, pos, mat)
	n.rotation.z = PI/2
	return n

func build(tier: int) -> void:
	body_tier = tier
	car = Node3D.new()
	car.name = "RaceCar"
	root.add_child(car)
	var paint := material("Body_Paint_Blue", "32a6e8", 0.34)
	paint.clearcoat_enabled = true
	paint.clearcoat = 0.28
	paint.clearcoat_roughness = 0.3
	var accent := material("Accent_Trim", "e86240", 0.4)
	var rubber := material("Soft_Rubber", "28303b", 0.87)
	var trim := material("Satin_Charcoal", "334252", 0.6)
	var glass := material("Blue_Glazing", "238ec2", 0.16, 0.28)
	var alloy := material("Warm_Alloy", "e4dec9", 0.3, 0.35)
	var lamp := material("Ivory_Lens", "fff2bc", 0.24)
	var red := material("Ruby_Lens", "e74d50", 0.26)
	var widths := [1.64,1.66,1.86,1.90,1.94]
	var lengths := [2.56,2.94,3.12,2.90,3.48]
	var heights := [0.60,0.56,0.46,0.65,0.40]
	var cabin_heights := [0.56,0.47,0.37,0.44,0.30]
	var cabin_lengths := [1.44,1.58,1.46,1.20,1.68]
	var w: float = widths[tier]
	var l: float = lengths[tier]
	var h: float = heights[tier]
	var ch: float = cabin_heights[tier]
	var cl: float = cabin_lengths[tier]
	var top := 0.26+h
	var cabin_z := 0.17 if tier != 3 else 0.30
	soft_box("Body", Vector3(w,h,l), Vector3(0,0.26+h/2,0),minf(0.29,h/2-0.01),paint)
	soft_box("Sill", Vector3(w+0.09,0.16,l-0.25),Vector3(0,0.30,0),0.06,accent)
	soft_box("Cabin_Glass",Vector3(w*0.80,ch,cl),Vector3(0,top+ch/2-0.06,cabin_z),minf(ch*0.49,0.28),glass,0.86,paint)
	# Painted pillars split side windows; bright inset catches the studio lights.
	for side: float in [-1.0,1.0]:
		soft_box("Window_Pillar",Vector3(0.045,ch*0.55,0.065),Vector3(side*w*0.347,top+ch*0.37,cabin_z+0.12),0.02,paint)
		soft_box("Door_Handle",Vector3(0.035,0.045,0.19),Vector3(side*(w/2-0.015),top-0.18,0.22),0.016,alloy)
		soft_box("Mirror",Vector3(0.20,0.14,0.23),Vector3(side*(w/2+0.03),top+0.12,-0.39),0.065,accent)
		var nose_width: float = NOSE_WIDTH[tier]
		for bezel in [true,false]:
			var lens := SphereMesh.new()
			lens.radius = 0.215 if bezel else 0.175
			lens.height = lens.radius*2
			var n := part("Headlight_Bezel" if bezel else "Headlight",lens,Vector3(side*w*0.31*nose_width,top-0.17,-l/2+0.09 if bezel else -l/2+0.025),alloy if bezel else lamp)
			n.scale = Vector3(1.0,1.05,0.48)
		soft_box("Taillight",Vector3(0.34,0.12,0.08),Vector3(side*w*0.31,top-0.19,l/2-0.01),0.035,red)
		# Body-coloured haunches give the wheels a toy-like fender lip.
		for z: float in [-l*0.31,l*0.31]:
			soft_box("Fender",Vector3(0.27,0.40,0.84),Vector3(side*(w/2-0.08),0.55,z),0.13,paint)
			var x := side*(w/2+0.025)
			var tire_mesh := TorusMesh.new()
			tire_mesh.inner_radius = 0.265
			tire_mesh.outer_radius = 0.405
			tire_mesh.rings = 48
			tire_mesh.ring_segments = 16
			var tire := part("Tire",tire_mesh,Vector3(x,0.405,z),rubber)
			tire.rotation.z = PI/2
			tire.scale.y = 1.8
			cylinder("Rim_Recess",0.28,0.285,Vector3(x,0.40,z),trim)
			cylinder("Rim",0.25,0.30,Vector3(x,0.40,z),alloy)
			cylinder("Hub",0.09,0.32,Vector3(x,0.40,z),paint)
			for spoke in 5:
				var a := TAU*spoke/5.0
				var n := soft_box("Rim_Slot",Vector3(0.022,0.095,0.055),Vector3(x+side*0.165,0.40+cos(a)*0.145,z+sin(a)*0.145),0.008,trim)
				n.rotation.x = -a
			for groove in [-0.075,0.075]:
				var torus := TorusMesh.new()
				torus.inner_radius = 0.388
				torus.outer_radius = 0.403
				torus.rings = 32
				torus.ring_segments = 6
				var n := part("Tire_Groove",torus,Vector3(x+groove,0.40,z),trim)
				n.rotation.z = PI/2
	soft_box("Grille",Vector3(w*0.46,0.19,0.07),Vector3(0,0.47,-l/2+0.012),0.065,trim)
	soft_box("Front_Bumper",Vector3(w*0.92*float(NOSE_WIDTH[tier]),0.13,0.16),Vector3(0,0.31,-l/2+0.06),0.055,accent)
	soft_box("Rear_Bumper",Vector3(w*0.91,0.14,0.16),Vector3(0,0.32,l/2-0.06),0.055,trim)
	if tier >= 0:
		for side: float in [-1.0,1.0]:
			soft_box("Wing_Support",Vector3(0.065,0.20 + tier*0.045,0.10),Vector3(side*w*0.30,top+0.10 + tier*0.02,l*0.38),0.025,trim)
		soft_box("Rear_Wing",Vector3(w+0.12,0.12,0.33 if tier<4 else 0.44),Vector3(0,top+0.23 + tier*0.04,l*0.39),0.055,accent)
	if tier == 3:
		for side: float in [-1.0,1.0]:
			soft_box("Hood_Vent",Vector3(0.16,0.045,0.36),Vector3(side*0.44,top+0.01,-0.77),0.02,trim)
	if tier == 4:
		for side: float in [-1.0,1.0]:
			soft_box("Side_Intake",Vector3(0.08,0.16,0.38),Vector3(side*w/2,0.51,0.48),0.04,trim)
	# Planar decal zones sit on the flat centres of each rounded surface.
	var hood_front := -l/2+minf(0.29,h/2-0.01)+0.04
	var hood_rear := cabin_z-cl/2-0.04
	car.set_meta("wheel_track",w/2+0.025)
	car.set_meta("wheel_base",l*0.31)
	car.set_meta("decal_surfaces", [Vector3(top+0.009,(hood_front+hood_rear)/2,hood_rear-hood_front),Vector3(top+ch-0.051,cabin_z,cl*0.34),Vector3(top+0.009,l*0.36,0.20)])
	car.set_meta("body_class",tier+1)
	car.set_meta("body_width",w)
	car.set_meta("body_top",top)
	car.set_meta("body_length",l)
	var packed := PackedScene.new()
	packed.pack(car)
	ResourceSaver.save(packed,OUT+NAMES[tier]+".tscn")
	if tier == 0:
		ResourceSaver.save(packed,OUT+"race_car.tscn")
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		gltf.append_from_scene(car,state)
		gltf.write_to_filesystem(state,OUT+"race_car.glb")
	car.free()

func _initialize() -> void:
	for tier in 5:
		build(tier)
	print("Built five original Soft Miniature bodies")
	quit()
