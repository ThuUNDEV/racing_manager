extends "res://tools/models/build_race_car.gd"
## Class vehicles v2: share the Racing car's sculpted body/cabin construction.
const CLASS_OUT := "res://assets/models/class_vehicles/"
var paint: StandardMaterial3D
var glass: StandardMaterial3D
var rubber: StandardMaterial3D
var trim: StandardMaterial3D
var alloy: StandardMaterial3D
var ivory: StandardMaterial3D
var red: StandardMaterial3D
var accent: StandardMaterial3D
var wheel_templates: Dictionary = {}

func _initialize() -> void:
	call_deferred("build_classes")

## Small parts need bevel tessellation at their edges, not dense flat faces.
func soft_box(label: String, size: Vector3, pos: Vector3, radius: float, mat: Material, _taper: float = 1.0, _roof_mat: Material = null) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
	radius = minf(radius,minf(half.x,minf(half.y,half.z))*0.98)
	var inner := half - Vector3.ONE * radius
	for axis in 3:
		var u_axis := (axis+1)%3
		var v_axis := (axis+2)%3
		var us := bevel_samples(half[u_axis],radius)
		var vs := bevel_samples(half[v_axis],radius)
		for sign_value: float in [-1.0,1.0]:
			for u in us.size()-1:
				for v in vs.size()-1:
					for raw in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
						var c: Vector2i = Vector2i(raw.y,raw.x) if sign_value > 0 else raw
						var p := Vector3.ZERO
						p[axis] = sign_value*half[axis]
						p[u_axis] = us[u+c.x]
						p[v_axis] = vs[v+c.y]
						var q := p.clamp(-inner,inner)
						var normal := (p-q).normalized()
						st.set_normal(normal)
						st.add_vertex(q+normal*radius)
	st.index()
	return part(label,st.commit(),pos,mat)

func bevel_samples(half: float, radius: float) -> PackedFloat32Array:
	return PackedFloat32Array([-half,-half+radius*0.293,-half+radius,half-radius,half-radius*0.293,half])

func cylinder(label: String, radius: float, depth: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = depth
	mesh.radial_segments = 32
	mesh.rings = 1
	var n := part(label,mesh,pos,mat)
	n.rotation.z = PI/2
	return n

func sphere(label: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 40
	mesh.rings = 20
	var n := part(label,mesh,pos,mat)
	n.scale = size
	return n

func rod(label: String, a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(radius*2.0,a.distance_to(b))
	mesh.radial_segments = 12
	mesh.rings = 3
	var n := part(label,mesh,(a+b)*0.5,mat)
	n.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	return n

func ring(label: String, pos: Vector3, inner: float, outer: float, mat: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 32
	mesh.ring_segments = 8
	var n := part(label,mesh,pos,mat)
	n.rotation.z = PI/2
	return n

func adopt(node: Node3D, parent: Node3D) -> void:
	node.owner = null
	car.remove_child(node)
	parent.add_child(node)
	node.owner = car

func make_wheel(label: String, pos: Vector3, r: float, width: float, offroad: bool = false) -> void:
	var key := "%s:%s:%s" % [r,width,offroad]
	if wheel_templates.has(key):
		var copy: Node3D = wheel_templates[key].duplicate(0)
		copy.name = label+"Wheel"
		car.add_child(copy)
		copy.owner = car
		for child in copy.get_children():
			child.owner = car
		copy.position = pos
		return
	var wheel := Node3D.new()
	wheel.name = label+"Wheel"
	car.add_child(wheel)
	wheel.owner = car
	wheel.position = pos
	wheel.set_meta("radius",r)
	var tire := ring("Tire",Vector3.ZERO,r*0.57,r,rubber)
	tire.scale.y = width/(r*0.43)
	adopt(tire,wheel)
	adopt(cylinder("RimWell",r*0.64,width*0.94,Vector3.ZERO,trim),wheel)
	for side: float in [-1.0,1.0]:
		var face := side*width*0.49
		adopt(ring("RimLip",Vector3(face,0,0),r*0.52,r*0.63,alloy),wheel)
		adopt(cylinder("BrakeRotor",r*0.45,0.012,Vector3(face*0.93,0,0),alloy),wheel)
		for i in 6:
			var angle := TAU*i/6.0
			var spoke := soft_box("AlloySpoke",Vector3(0.025,r*0.43,r*0.115),Vector3(face,cos(angle)*r*0.30,sin(angle)*r*0.30),r*0.045,alloy)
			spoke.rotation.x = angle
			adopt(spoke,wheel)
			adopt(cylinder("RotorHole",r*0.034,0.015,Vector3(face*0.965,cos(angle+0.2)*r*0.38,sin(angle+0.2)*r*0.38),trim),wheel)
		adopt(cylinder("Hub",r*0.16,0.035,Vector3(face*1.06,0,0),alloy),wheel)
		adopt(cylinder("HubCap",r*0.075,0.04,Vector3(face*1.09,0,0),accent),wheel)
		adopt(ring("SidewallRing",Vector3(side*width*0.39,0,0),r*0.80,r*0.825,trim),wheel)
	if offroad:
		# Low chevron tread follows the round tire; no block-shaped tire silhouette.
		for i in 22:
			var angle := TAU*i/22.0
			for side: float in [-1.0,1.0]:
				var p := Vector3(side*width*0.24,sin(angle)*r*0.98,cos(angle)*r*0.98)
				var n := rod("Tread",p-Vector3(width*0.23,0,side*r*0.045),p+Vector3(width*0.23,0,-side*r*0.045),r*0.033,rubber)
				adopt(n,wheel)
	else:
		for x in [-width*0.20,width*0.20]:
			adopt(ring("TireGroove",Vector3(x,0,0),r*0.975,r*0.988,trim),wheel)

	batch_details(wheel,[])
	wheel_templates[key] = wheel

func wheels(x: float, z: float, r: float, width: float, offroad: bool = false) -> void:
	for side: float in [-1.0,1.0]:
		for end: float in [-1.0,1.0]:
			make_wheel(("Left" if side < 0 else "Right")+("Front" if end < 0 else "Rear"),Vector3(x*side,r,z*end),r,width,offroad)

func arch(pos: Vector3, radius: float, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 32:
		for j in 10:
			for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var a := lerpf(-0.16,PI+0.16,float(i+c.x)/32.0)
				var b := TAU*float(j+c.y)/10.0
				var r := radius+0.06*cos(b)
				st.set_normal(Vector3(sin(b),sin(a)*cos(b),cos(a)*cos(b)))
				st.add_vertex(Vector3(0.12*sin(b),sin(a)*r,cos(a)*r))
	st.index()
	part("Fender",st.commit(),pos,mat)

func car_details(w: float, l: float, top: float, cabin_y: float, axle: float, round_lamps: bool = false) -> void:
	for side: float in [-1.0,1.0]:
		soft_box("DoorHandle",Vector3(0.045,0.05,0.18),Vector3(side*(w*0.48),top-0.18,0.24),0.02,alloy)
		soft_box("MirrorStem",Vector3(0.14,0.065,0.07),Vector3(side*w*0.48,cabin_y-0.13,-0.44),0.025,trim)
		soft_box("Mirror",Vector3(0.22,0.17,0.22),Vector3(side*w*0.53,cabin_y-0.1,-0.44),0.075,paint)
		soft_box("MirrorGlass",Vector3(0.17,0.11,0.025),Vector3(side*w*0.53,cabin_y-0.1,-0.32),0.035,glass)
		soft_box("B_Pillar",Vector3(0.055,0.31,0.07),Vector3(side*w*0.342,cabin_y+0.045,0.20),0.025,paint)
		for z: float in [-axle,axle]:
			arch(Vector3(side*w*0.48,0.43,z),0.47,paint)
		var lamp_size := Vector3(0.37,0.22,0.12) if round_lamps else Vector3(0.42,0.14,0.14)
		sphere("LampBezel",Vector3(side*w*0.31,top-0.18,-l*0.475),lamp_size*1.16,trim)
		var lens := sphere("Headlight",Vector3(side*w*0.31,top-0.18,-l*0.49),lamp_size,ivory)
		lens.rotation.z = side*-0.18
		soft_box("TailLens",Vector3(0.37,0.12,0.09),Vector3(side*w*0.31,top-0.14,l*0.475),0.04,red)
		soft_box("SideSkirt",Vector3(0.13,0.15,l*0.51),Vector3(side*w*0.465,0.35,0),0.06,trim)
	soft_box("Grille",Vector3(w*0.43,0.18,0.13),Vector3(0,0.51,-l*0.475),0.075,trim)
	for i in 3:
		soft_box("GrilleBar",Vector3(w*0.34,0.018,0.025),Vector3(0,0.46+i*0.05,-l*0.5),0.008,alloy)
	soft_box("Bumper",Vector3(w*0.83,0.15,0.22),Vector3(0,0.32,-l*0.43),0.07,paint)
	soft_box("RearDiffuser",Vector3(w*0.83,0.15,0.19),Vector3(0,0.32,l*0.43),0.065,trim)
	for side: float in [-1.0,1.0]:
		var exhaust := cylinder("Exhaust",0.066,0.18,Vector3(side*w*0.3,0.32,l*0.49),alloy)
		exhaust.rotation = Vector3(PI/2,0,0)

func rally() -> void:
	body_tier = 0
	rounded_body(1.78,0.76,2.85,paint)
	rounded_cabin(Vector3(1.48,0.80,1.83),Vector3(0,1.18,0.17),glass,paint)
	wheels(0.87,0.90,0.43,0.36,true)
	car_details(1.78,2.85,1.07,1.18,0.90,true)
	soft_box("HoodScoop",Vector3(0.59,0.12,0.36),Vector3(0,1.09,-0.70),0.055,paint)
	soft_box("ScoopIntake",Vector3(0.43,0.055,0.025),Vector3(0,1.10,-0.89),0.024,trim)
	for x in [-0.46,-0.15,0.15,0.46]:
		sphere("SpotlightHousing",Vector3(x,0.76,-1.43),Vector3(0.29,0.29,0.20),trim)
		sphere("SpotlightLens",Vector3(x,0.76,-1.52),Vector3(0.235,0.235,0.07),ivory)
	for x in [-0.48,0.48]:
		rod("RoofRail",Vector3(x,1.60,-0.23),Vector3(x,1.60,0.62),0.026,alloy)
		rod("SpoilerMount",Vector3(x,1.33,1.04),Vector3(x,1.48,1.10),0.035,trim)
	soft_box("RearSpoiler",Vector3(1.57,0.12,0.35),Vector3(0,1.5,1.1),0.055,paint)
	for side: float in [-1.0,1.0]:
		soft_box("Mudflap",Vector3(0.35,0.30,0.045),Vector3(side*0.85,0.26,1.19),0.02,trim)
		soft_box("RallyLivery",Vector3(0.035,0.10,0.70),Vector3(side*0.88,0.84,0.12),0.017,ivory)
	car.set_meta("body_top",1.07)

func stock() -> void:
	body_tier = 3
	rounded_body(1.94,0.60,3.22,paint)
	rounded_cabin(Vector3(1.59,0.60,1.77),Vector3(0,1.04,0.20),glass,paint)
	wheels(0.94,1.0,0.43,0.37)
	car_details(1.94,3.22,0.91,1.04,1.0)
	soft_box("FrontSplitter",Vector3(1.85,0.075,0.36),Vector3(0,0.25,-1.42),0.03,trim)
	soft_box("RearSpoiler",Vector3(1.78,0.20,0.09),Vector3(0,1.02,1.39),0.035,trim).rotation.x = -0.22
	for side: float in [-1.0,1.0]:
		for i in 3:
			soft_box("HoodVent",Vector3(0.26,0.025,0.035),Vector3(side*0.52,0.94,-0.65+i*0.09),0.01,trim)
		var badge := cylinder("DoorRoundel",0.22,0.018,Vector3(side*0.965,0.74,0.10),ivory)
		badge.rotation.z = PI/2
		var mesh := TextMesh.new()
		mesh.text = "08"
		mesh.font = ThemeDB.fallback_font
		mesh.font_size = 48
		mesh.pixel_size = 0.0045
		mesh.depth = 0.001
		var number := part("RaceNumber",mesh,Vector3(side*0.98,0.66,0.10),trim)
		number.rotation.y = side*PI/2
	car.set_meta("body_top",0.91)

func speedster() -> void:
	body_tier = 4
	rounded_body(0.91,0.43,3.20,paint)
	rounded_cabin(Vector3(0.66,0.36,0.88),Vector3(0,0.88,0.25),glass,paint)
	wheels(0.89,1.0,0.43,0.42)
	for side: float in [-1.0,1.0]:
		sphere("SidePod",Vector3(side*0.59,0.59,0.40),Vector3(0.53,0.52,1.42),paint)
		sphere("RadiatorIntake",Vector3(side*0.59,0.62,-0.17),Vector3(0.35,0.25,0.07),trim)
		for end: float in [-1.0,1.0]:
			for offset in [-0.20,0.20]:
				rod("Wishbone",Vector3(side*0.27,0.46,end*0.92+offset),Vector3(side*0.84,0.43,end*1.0),0.034,trim)
		soft_box("FloorEdge",Vector3(0.11,0.08,1.8),Vector3(side*0.79,0.28,0.25),0.035,trim)
		rod("RearWingPylon",Vector3(side*0.49,0.59,1.14),Vector3(side*0.49,1.09,1.25),0.045,trim)
		soft_box("FrontEndplate",Vector3(0.09,0.27,0.46),Vector3(side*0.96,0.33,-1.37),0.035,paint)
		soft_box("RearEndplate",Vector3(0.09,0.39,0.48),Vector3(side*0.86,1.10,1.26),0.04,paint)
	for level in 2:
		soft_box("FrontAerofoil",Vector3(1.89,0.065,0.25),Vector3(0,0.26+level*0.095,-1.47+level*0.15),0.03,paint)
		soft_box("RearAerofoil",Vector3(1.68,0.075,0.40),Vector3(0,0.99+level*0.15,1.27),0.035,paint)
	rod("RollHoop",Vector3(0,0.90,0.54),Vector3(0,1.17,0.64),0.08,trim)
	sphere("Airbox",Vector3(0,1.03,0.73),Vector3(0.30,0.40,0.48),paint)
	car.set_meta("body_top",0.74)

func coil_spring(a: Vector3, b: Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 64:
		for j in 6:
			for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var u := float(i+c.x)/64.0
				var angle := u*TAU*5
				var radial := Vector3(sin(angle),0,cos(angle))
				var v := TAU*float(j+c.y)/6.0
				var normal := radial*cos(v)+Vector3.UP*sin(v)
				st.set_normal(normal)
				st.add_vertex(Vector3(0,u*a.distance_to(b),0)+radial*0.073+normal*0.014)
	st.index()
	var n := part("CoilSpring",st.commit(),a,accent)
	n.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func monster() -> void:
	body_tier = 3
	rounded_body(1.72,0.59,2.85,paint)
	car.get_node("Body").position.y += 0.63
	rounded_cabin(Vector3(1.43,0.76,1.27),Vector3(0,1.79,-0.29),glass,paint)
	wheels(1.10,0.94,0.70,0.58,true)
	soft_box("LadderChassis",Vector3(1.14,0.19,2.4),Vector3(0,0.95,0),0.07,trim)
	for side: float in [-1.0,1.0]:
		for z: float in [-0.94,0.94]:
			arch(Vector3(side*0.80,1.02,z),0.53,paint)
			rod("SuspensionArm",Vector3(side*0.37,0.99,z*0.5),Vector3(side*1.04,0.70,z),0.065,alloy)
			var a := Vector3(side*0.60,0.73,z)
			var b := Vector3(side*0.60,1.20,z*0.85)
			rod("Damper",a,b,0.05,alloy)
			coil_spring(a,b)
		soft_box("Mirror",Vector3(0.23,0.18,0.23),Vector3(side*0.89,1.80,-0.62),0.075,paint)
		soft_box("DoorHandle",Vector3(0.045,0.05,0.18),Vector3(side*0.84,1.48,-0.11),0.02,alloy)
		soft_box("CabPillar",Vector3(0.06,0.31,0.065),Vector3(side*0.51,1.85,-0.18),0.025,paint)
		soft_box("BedRail",Vector3(0.13,0.20,0.91),Vector3(side*0.73,1.55,0.86),0.055,paint)
		soft_box("StepRail",Vector3(0.22,0.12,0.68),Vector3(side*0.80,0.89,0),0.055,alloy)
		sphere("LampBezel",Vector3(side*0.53,1.42,-1.35),Vector3(0.40,0.31,0.14),trim)
		sphere("Headlight",Vector3(side*0.53,1.42,-1.42),Vector3(0.32,0.24,0.07),ivory)
		soft_box("TailLight",Vector3(0.13,0.25,0.07),Vector3(side*0.64,1.43,1.37),0.035,red)
	soft_box("BedLiner",Vector3(1.29,0.055,0.85),Vector3(0,1.54,0.88),0.025,trim)
	soft_box("TailGate",Vector3(1.43,0.25,0.14),Vector3(0,1.53,1.28),0.06,paint)
	soft_box("TruckGrille",Vector3(0.59,0.27,0.11),Vector3(0,1.34,-1.38),0.05,trim)
	for i in 4:
		soft_box("GrilleChrome",Vector3(0.48,0.018,0.025),Vector3(0,1.24+i*0.065,-1.445),0.008,alloy)
	rod("BullBar",Vector3(-0.70,1.13,-1.44),Vector3(0.70,1.13,-1.44),0.065,alloy)
	for z in [-0.94,0.94]:
		rod("Axle",Vector3(-1.10,0.70,z),Vector3(1.10,0.70,z),0.085,trim)
	car.set_meta("body_top",1.53)

func bike() -> void:
	# Sculpted fairing, compact tank, curved screen and a rider tucked over the bars.
	body_tier = 0
	rounded_body(0.72,0.64,1.72,paint)
	car.get_node("Body").position = Vector3(0,0.08,-0.21)
	rounded_cabin(Vector3(0.51,0.36,0.64),Vector3(0,1.12,-0.55),glass,paint)
	sphere("FuelTank",Vector3(0,1.00,-0.08),Vector3(0.54,0.42,0.70),paint)
	sphere("TailCowl",Vector3(0,1.01,0.65),Vector3(0.44,0.30,0.66),paint)
	soft_box("Seat",Vector3(0.38,0.13,0.50),Vector3(0,1.10,0.39),0.06,trim)
	make_wheel("Front",Vector3(0,0.43,-1.0),0.43,0.23)
	make_wheel("Rear",Vector3(0,0.43,0.94),0.43,0.29)
	for side: float in [-1.0,1.0]:
		rod("FrontFork",Vector3(side*0.14,0.43,-1.0),Vector3(side*0.14,1.05,-0.64),0.045,alloy)
		rod("SwingArm",Vector3(side*0.18,0.43,0.94),Vector3(side*0.18,0.65,0.15),0.055,trim)
		soft_box("FairingGraphic",Vector3(0.022,0.12,0.68),Vector3(side*0.35,0.79,-0.25),0.01,ivory).rotation.x = -0.35
		for i in 3:
			soft_box("FairingVent",Vector3(0.023,0.045,0.17),Vector3(side*0.35,0.63+i*0.075,-0.12),0.01,trim).rotation.x = -0.4
		sphere("LampFairing",Vector3(side*0.15,0.87,-0.94),Vector3(0.25,0.16,0.20),paint)
		sphere("Headlight",Vector3(side*0.15,0.88,-1.03),Vector3(0.19,0.085,0.055),ivory).rotation.z = side*-0.30
		rod("HandleBar",Vector3(side*0.14,1.06,-0.47),Vector3(side*0.37,1.07,-0.43),0.035,trim)
		var shoulder := Vector3(side*0.19,1.40,-0.12)
		var elbow := Vector3(side*0.35,1.21,-0.12)
		var wrist := Vector3(side*0.31,1.09,-0.43)
		rod("UpperArm",shoulder,elbow,0.085,trim)
		rod("SleeveStripe",shoulder.lerp(elbow,0.25),shoulder.lerp(elbow,0.55),0.087,ivory)
		rod("Forearm",elbow,wrist,0.069,trim)
		sphere("Glove",wrist,Vector3(0.14,0.13,0.17),trim)
		var hip := Vector3(side*0.15,1.14,0.47)
		var knee := Vector3(side*0.31,0.88,0.04)
		var foot := Vector3(side*0.26,0.61,0.42)
		rod("Thigh",hip,knee,0.12,trim)
		rod("Shin",knee,foot,0.085,trim)
		sphere("KneeSlider",knee+Vector3(side*0.04,0,0),Vector3(0.09,0.15,0.15),ivory)
		sphere("Boot",foot,Vector3(0.14,0.16,0.27),trim)
	rod("Exhaust",Vector3(0.29,0.54,0.26),Vector3(0.29,0.68,0.91),0.08,alloy)
	sphere("RiderTorso",Vector3(0,1.34,0.20),Vector3(0.44,0.38,0.76),trim).rotation.x = -0.15
	sphere("SuitBackPanel",Vector3(0,1.49,0.25),Vector3(0.30,0.08,0.43),paint)
	sphere("Helmet",Vector3(0,1.61,-0.25),Vector3(0.47,0.46,0.53),paint)
	# Visor is a curved patch on the helmet rather than a rectangular block.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 24:
		for j in 8:
			for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(0,1)]:
				var a := lerpf(-1.12,1.12,float(i+c.x)/24)
				var b := lerpf(-0.05,0.40,float(j+c.y)/8)
				var n := Vector3(sin(a)*cos(b),sin(b),-cos(a)*cos(b))
				st.set_normal(n)
				st.add_vertex(Vector3(n.x*0.239,n.y*0.234,n.z*0.269))
	st.index()
	var visor := part("HelmetVisor",st.commit(),Vector3(0,1.61,-0.25),glass)
	visor.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	car.set_meta("body_top",1.03)

## Merge decorative geometry by material so extra detail stays inexpensive in races.
func batch_details(parent: Node3D, keep: Array[String]) -> void:
	var groups: Dictionary = {}
	for child in parent.get_children():
		if not child is MeshInstance3D or String(child.name) in keep:
			continue
		var mat: Material = child.material_override
		if not groups.has(mat):
			groups[mat] = []
		groups[mat].append(child)
	var index := 0
	for mat: Material in groups:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for child: MeshInstance3D in groups[mat]:
			for surface in child.mesh.get_surface_count():
				st.append_from(child.mesh,surface,child.transform)
		st.index()
		var merged := MeshInstance3D.new()
		merged.name = "Details%d" % index
		merged.mesh = st.commit()
		merged.material_override = mat
		parent.add_child(merged)
		merged.owner = car
		for child: MeshInstance3D in groups[mat]:
			child.free()
		index += 1

## Godot chooses reduced index buffers at race scale and full detail in closeups.
func add_lods() -> void:
	var processed: Dictionary = {}
	for node: MeshInstance3D in car.find_children("*","MeshInstance3D",true,false):
		var source: Mesh = node.mesh
		if processed.has(source):
			node.mesh = processed[source]
			continue
		var importer := ImporterMesh.new()
		for surface in source.get_surface_count():
			importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,source.surface_get_arrays(surface))
		importer.generate_lods(25.0,60.0,[])
		var result := importer.get_mesh()
		processed[source] = result
		node.mesh = result

func build_classes() -> void:
	DirAccess.make_dir_recursive_absolute(CLASS_OUT)
	for id in ["rally","stock","bike","speed","monster"]:
		car = Node3D.new()
		car.name = id.to_pascal_case()
		root.add_child(car)
		car.set_meta("race_class",id)
		wheel_templates.clear()
		paint = material("Body_Paint_Blue",{"rally":"f2b42e","stock":"ed5c48","bike":"a452d6","speed":"f4cc39","monster":"79c644"}[id],0.25)
		paint.clearcoat_enabled = true
		paint.clearcoat = 0.65
		paint.clearcoat_roughness = 0.25
		glass = material("Blue_Glazing","1269a9",0.16,0.12)
		glass.clearcoat_enabled = true
		glass.clearcoat = 0.8
		rubber = material("Soft_Rubber","35343d",0.80)
		trim = material("Satin_Charcoal","293b4a",0.55)
		alloy = material("Warm_Alloy","e6d5b7",0.30,0.18)
		ivory = material("Ivory_Lens","fff0c3",0.24)
		red = material("Ruby_Lens","e64b50",0.26)
		accent = material("Accent_Trim","ed744c",0.35)
		match id:
			"rally": rally()
			"stock": stock()
			"bike": bike()
			"speed": speedster()
			"monster": monster()
		batch_details(car,["Body","Roof","Cabin_Glass"])
		add_lods()
		car.set_meta("model_revision",2)
		var triangles := 0
		var meshes := car.find_children("*","MeshInstance3D",true,false)
		for node: MeshInstance3D in meshes:
			for surface in node.mesh.get_surface_count():
				var arrays := node.mesh.surface_get_arrays(surface)
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				triangles += indices.size()/3
		car.set_meta("triangle_count",triangles)
		car.set_meta("draw_mesh_count",meshes.size())
		print(id," meshes=",meshes.size()," triangles=",triangles)
		var packed := PackedScene.new()
		var pack_error := packed.pack(car)
		var save_error := ResourceSaver.save(packed,CLASS_OUT+id+".tscn")
		print("Class vehicle ",id," pack=",pack_error," save=",save_error)
		car.free()
	quit()
