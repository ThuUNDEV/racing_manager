extends SceneTree

const OUT = "res://assets/models/race_car/"
var car: Node3D
var paint: StandardMaterial3D

func material(label: String, color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.resource_name = label
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.35 if metallic > 0 else 0.65
	return m

func part(label: String, mesh: Mesh, pos: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	n.material_override = mat
	(parent if parent else car).add_child(n)
	n.owner = car
	n.position = pos
	return n

func box(label: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	return part(label, mesh, pos, mat)

# Octagonal horizontal sections give the body chamfered corners rather than a cube silhouette.
func shell(label: String, sections: Array, mat: Material) -> void:
	var vertices: Array[Vector3] = []
	for s in sections:
		var w: float = s[0]; var length: float = s[1]; var y: float = s[2]; var z: float = s[3]
		var c = min(w, length) * 0.22
		for p in [Vector2(-w+c,-length),Vector2(w-c,-length),Vector2(w,-length+c),Vector2(w,length-c),Vector2(w-c,length),Vector2(-w+c,length),Vector2(-w,length-c),Vector2(-w,-length+c)]:
			vertices.append(Vector3(p.x,y,p.y+z))
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for level in range(sections.size()-1):
		for i in range(8):
			var a=level*8+i; var b=level*8+(i+1)%8; var c=(level+1)*8+i; var d=(level+1)*8+(i+1)%8
			for idx in [a,c,b,b,c,d]: st.add_vertex(vertices[idx])
	for i in range(1,7):
		for idx in [0,i,(i+1), (sections.size()-1)*8,(sections.size()-1)*8+i+1,(sections.size()-1)*8+i]: st.add_vertex(vertices[idx])
	st.generate_normals()
	part(label,st.commit(),Vector3.ZERO,mat)

func _initialize() -> void:
	car = Node3D.new()
	car.name = "RaceCar"
	root.add_child(car)
	paint = material("Body_Paint_Blue", Color("159cfa"),0.15)
	var white = material("Pearl_White",Color("f5fbff"))
	var dark = material("Rubber",Color("172131"))
	var glass = material("Smoked_Glass",Color("163954"),0.35)
	var metal = material("Alloy",Color("c4d4e0"),0.7)
	var lamp = material("Headlight",Color("fff1b0"))
	var red = material("Tail_Light",Color("ff394c"))
	shell("Body",[[0.68,1.35,0.30,0.0],[0.77,1.39,0.49,0.0],[0.67,1.28,0.70,0.0]],paint)
	shell("Cabin_Glass",[[0.55,0.69,0.70,0.13],[0.44,0.40,1.11,0.23]],glass)
	shell("Roof",[[0.45,0.41,1.11,0.23],[0.43,0.39,1.16,0.23]],paint)
	for x in [-0.19,0.19]:
		box("Hood_Stripe",Vector3(0.14,0.012,0.61),Vector3(x,0.708,-0.94),white)
		box("Roof_Stripe",Vector3(0.14,0.012,0.70),Vector3(x,1.167,0.23),white)
		box("Rear_Stripe",Vector3(0.14,0.012,0.35),Vector3(x,0.708,1.05),white)
	box("Front_Splitter",Vector3(1.47,0.10,0.24),Vector3(0,0.29,-1.31),dark)
	box("Front_Grille",Vector3(0.68,0.16,0.025),Vector3(0,0.47,-1.398),dark)
	for x in [-0.49,0.49]:
		box("Headlight",Vector3(0.29,0.15,0.035),Vector3(x,0.54,-1.37),lamp)
		box("Taillight",Vector3(0.30,0.12,0.035),Vector3(x,0.53,1.37),red)
		box("Wing_Support",Vector3(0.07,0.28,0.09),Vector3(x,0.86,1.12),dark)
	box("Rear_Wing",Vector3(1.64,0.08,0.32),Vector3(0,1.02,1.12),paint)
	for x in [-0.80,0.80]:
		box("Wing_Endplate",Vector3(0.045,0.20,0.36),Vector3(x,1.04,1.12),white)
	for x in [-0.79,0.79]:
		for z in [-0.87,0.87]:
			var pivot=Node3D.new()
			pivot.name=("Left" if x<0 else "Right")+("Front" if z<0 else "Rear")+"Wheel"
			car.add_child(pivot); pivot.owner=car; pivot.position=Vector3(x,0.32,z)
			var tire=CylinderMesh.new(); tire.top_radius=0.32; tire.bottom_radius=0.32; tire.height=0.24; tire.radial_segments=16
			var n=part("Tire",tire,Vector3.ZERO,dark,pivot); n.rotation.z=PI/2
			var rim=CylinderMesh.new(); rim.top_radius=0.20; rim.bottom_radius=0.20; rim.height=0.25; rim.radial_segments=12
			n=part("Rim",rim,Vector3.ZERO,metal,pivot); n.rotation.z=PI/2
			var hub=CylinderMesh.new(); hub.top_radius=0.09; hub.bottom_radius=0.09; hub.height=0.26; hub.radial_segments=8
			n=part("Hub",hub,Vector3.ZERO,paint,pivot); n.rotation.z=PI/2
	var packed=PackedScene.new()
	packed.pack(car)
	var err=ResourceSaver.save(packed,OUT+"race_car.tscn")
	var gltf=GLTFDocument.new(); var state=GLTFState.new()
	gltf.append_from_scene(car,state)
	var glb_err=gltf.write_to_filesystem(state,OUT+"race_car.glb")
	print("Car saved: scene=",err," glb=",glb_err)
	quit(err if err else glb_err)
