extends SceneTree
## Render reproducible thumbnails directly from the runtime meshes.
const Appearance = preload("res://ui/car_appearance.gd")
const OUT := "res://Design/Previews/Class_Vehicles_v2/"
var previews: Array[SubViewport] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(960,660)
	var bg := ColorRect.new()
	bg.color = Color("fcf3e4")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var ids := ["racing","rally","stock","bike","speed","monster"]
	for i in ids.size():
		var id: String = ids[i]
		var vp := SubViewport.new()
		vp.own_world_3d = true
		vp.transparent_bg = true
		vp.size = Vector2i(512,512)
		vp.msaa_3d = Viewport.MSAA_4X
		root.add_child(vp)
		previews.append(vp)
		var car := Appearance.model_for_class(id).instantiate()
		vp.add_child(car)
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_CLEAR_COLOR
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color("e2edff")
		env.environment.ambient_light_energy = 0.55
		vp.add_child(env)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-48,-35,0)
		light.light_energy = 1.2
		vp.add_child(light)
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 4.2
		vp.add_child(camera)
		camera.position = Vector3(4.5,3.5,-6)
		camera.look_at(Vector3(0,0.85,0))
		var tex := TextureRect.new()
		tex.texture = vp.get_texture()
		tex.position = Vector2(20+(i%3)*315,15+(i/3)*320)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.size = Vector2(300,270)
		tex.stretch_mode = TextureRect.STRETCH_SCALE
		root.add_child(tex)
		var label := Label.new()
		label.text = String(GameData.race_class(id).get("name",id))
		label.position = tex.position+Vector2(0,270)
		label.size = Vector2(300,40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color",Color("16385a"))
		label.add_theme_font_size_override("font_size",23)
		root.add_child(label)
	for frame in 8:
		await process_frame
	for child in root.get_children():
		if child is TextureRect:
			child.size = Vector2(280,250)
	await process_frame
	await RenderingServer.frame_post_draw
	for i in ids.size():
		var image := previews[i].get_texture().get_image()
		image.save_png(OUT+ids[i]+"_closeup.png")
		image.resize(192,192,Image.INTERPOLATE_LANCZOS)
		image.save_png("res://assets/models/class_vehicles/"+ids[i]+".png")
	root.get_texture().get_image().save_png(OUT+"vehicles.png")
	print("Rendered six class vehicle icons and gallery")
	quit()
