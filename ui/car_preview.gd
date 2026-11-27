class_name CarPreview
extends Control
## Xe 3D (assets/models/race_car, dùng chung với màn đua) render vào SubViewport trong suốt, đặt trên nền khu trưng bày.
## Màu sơn đổi vật liệu thân xe, decal bám mesh cong trên mui/nóc/đuôi/cửa. Bật `rotatable` để kéo ngang xoay xe.

signal yaw_changed(value: float)

const MODELS = preload("res://ui/car_appearance.gd").MODELS
const SCENE_RATIO := 600.0 / 1024.0
const C_DARK := Color("1d1f24")
const C_LIGHT := Color("fff8e7")
const PAINT_NAME := "Body_Paint_Blue"
## Mặt trước xe là -Z; góc này cho mũi xe quay chéo về phía trái người xem.
const DEFAULT_YAW := 145.0
const DRAG_DEGREES_PER_UNIT := 0.8
const FOV := 24.0

## Opt in from Garage; Shop previews retain their own Racing presentation.
var race_class_id: String = "racing":
	set(value):
		if race_class_id == value:
			return
		race_class_id = value
		if _car != null:
			_replace_car()
			_update()

var car_id: String = "car_pico_tia_chop":
	set(v):
		if car_id == v:
			return
		car_id = v
		if _car != null:
			_replace_car()
			_update()
## Nhìn từ trên cao hơn để thấy rõ decal (mục Ngoại hình).
var top_down: bool = false:
	set(v):
		top_down = v
		_update()
var paint_id: String = "orange":
	set(v):
		paint_id = v
		_update()
var decal_id: String = "none":
	set(v):
		decal_id = v
		_update()
## Khu trưng bày: tự giữ chiều cao theo tỉ lệ ảnh nền xưởng.
var keep_scene_ratio: bool = false
var show_floor: bool = true:
	set(v):
		show_floor = v
		_update()
		queue_redraw()
var yaw: float = DEFAULT_YAW:
	set(v):
		yaw = v
		if _car != null:
			_car.rotation_degrees.y = v
			_request_render()
var dimmed: bool = false:  # xe chưa sở hữu: mờ nhẹ
	set(v):
		dimmed = v
		_update()
## Optional Garage-only background; other previews keep their existing scene.
var showroom_texture: Texture2D
## Opt-in so collection thumbnails and other car previews keep their original rendering.
var showroom_3d := false:
	set(value):
		showroom_3d = value
		_update()
		queue_redraw()
## Chỉ bục xoay có ô caro, không sàn và không tường xưởng (thẻ Shop dùng nền riêng). Cần showroom_3d.
var pedestal_only := false:
	set(value):
		pedestal_only = value
		_update()
var rotatable: bool = false:
	set(v):
		rotatable = v
		mouse_filter = Control.MOUSE_FILTER_PASS if v else Control.MOUSE_FILTER_IGNORE
		_request_render()

var _viewport: SubViewport
var _view: TextureRect
var _car: Node3D
var _camera: Camera3D
var _stage: Node3D
var _key_light: DirectionalLight3D
var _paint_material: StandardMaterial3D
var _paint_roughness := 0.5
var _decals: Node3D
var _accent_material: StandardMaterial3D
var _decal_material: StandardMaterial3D


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.size = Vector2i(64, 64)
	add_child(_viewport)
	_build_world()
	_view = TextureRect.new()
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_view.stretch_mode = TextureRect.STRETCH_SCALE
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.texture = _viewport.get_texture()
	add_child(_view)
	resized.connect(_on_resized)


func _build_world() -> void:
	_replace_car()

	_camera = Camera3D.new()
	_camera.fov = FOV
	_viewport.add_child(_camera)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff6ea")
	environment.environment.ambient_light_energy = 0.42
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("87b9de")
	sky_mat.sky_horizon_color = Color("fff5e6")
	sky_mat.ground_horizon_color = Color("e0efff")
	sky.sky_material = sky_mat
	environment.environment.sky = sky
	environment.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	_viewport.add_child(environment)
	var key := DirectionalLight3D.new()
	_key_light = key
	key.rotation_degrees = Vector3(-48, -35, 0)
	key.light_energy = 1.0
	key.light_color = Color("fff0d9")
	_viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 55, 0)
	fill.light_color = Color("cfe4ff")
	fill.light_energy = 0.45
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-35, 155, 0)
	rim.light_color = Color("e4f4ff")
	rim.light_energy = 0.65
	_viewport.add_child(rim)
	_viewport.add_child(fill)


func _replace_car() -> void:
	if _car != null:
		_viewport.remove_child(_car)
		_car.queue_free()
	var data := GameData.car(car_id)
	var tier := clampi(int(data.get("class", 1)), 1, 5)
	_car = preload("res://ui/car_appearance.gd").model_for_class(race_class_id, tier).instantiate()
	_viewport.add_child(_car)
	_car.rotation_degrees.y = yaw
	_paint_material = null
	_accent_material = null
	_apply_paint_material(_car)
	_decal_material = StandardMaterial3D.new()
	_decal_material.roughness = 0.55
	_decal_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_decals = Node3D.new()
	_decals.name = "Decals"
	_car.add_child(_decals)
	_car.add_child(_make_shadow())
	if race_class_id == "racing" and String(data.get("variant", "")) != "epic":
		_build_race_number()
	var glass := _car.get_node_or_null("Cabin_Glass") as MeshInstance3D
	if glass == null:
		return
	var glint := MeshInstance3D.new()
	glint.name = "WindshieldReflection"
	glint.mesh = glass.mesh
	glint.transform = glass.transform
	var glint_mat := ShaderMaterial.new()
	glint_mat.shader = preload("res://ui/car_livery.gdshader")
	glint_mat.set_shader_parameter("pattern",4)
	glint_mat.set_shader_parameter("ink",Color("bceaff"))
	glint_mat.set_shader_parameter("panel_offset",glass.position)
	glint.material_override = glint_mat
	_car.add_child(glint)


## Mỗi khung xem có bản vật liệu sơn riêng để màu của xe này không lan sang xe khác.
func _apply_paint_material(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.material_override != null and child.material_override.resource_name == PAINT_NAME:
			if _paint_material == null:
				_paint_material = child.material_override.duplicate()
				_paint_roughness = _paint_material.roughness
			child.material_override = _paint_material
		if child is MeshInstance3D and child.material_override != null and child.material_override.resource_name == "Accent_Trim":
			if _accent_material == null:
				_accent_material = child.material_override.duplicate()
			child.material_override = _accent_material
		_apply_paint_material(child)


## Bóng tiếp đất mềm dưới gầm xe.
func _make_shadow() -> MeshInstance3D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0.45))
	gradient.set_color(1, Color(0, 0, 0, 0.0))
	gradient.add_point(0.6, Color(0, 0, 0, 0.3))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = tex
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.5, 3.6)
	var shadow := MeshInstance3D.new()
	shadow.name = "Shadow"
	shadow.mesh = plane
	shadow.material_override = mat
	shadow.position.y = 0.005
	# Small overlapping pools anchor each tire to the illustrated turntable.
	var track: float = _car.get_meta("wheel_track",0.78)
	var wheelbase: float = _car.get_meta("wheel_base",0.87)
	for x: float in [-track,track]:
		for z: float in [-wheelbase,wheelbase]:
			var contact := MeshInstance3D.new()
			var patch := PlaneMesh.new()
			patch.size = Vector2(0.62,0.82)
			contact.mesh = patch
			contact.material_override = mat
			contact.position = Vector3(x,0.002,z)
			shadow.add_child(contact)
	return shadow


## Màu tương phản cố định cho decal theo độ sáng của màu sơn (Design/15 §8).
static func contrast_for(paint: String) -> Color:
	var p := GameData.paint(paint)
	if paint == "white":
		return Color("dc583c")
	if p.is_empty():
		return C_LIGHT
	if p.has("ink"):
		return Color(String(p["ink"]))
	return C_DARK if Color(String(p["color"])).get_luminance() > 0.65 else C_LIGHT


func _on_resized() -> void:
	if keep_scene_ratio:
		var wanted := roundf(size.x * SCENE_RATIO)
		if not is_equal_approx(custom_minimum_size.y, wanted):
			custom_minimum_size.y = wanted
	_update()


func _ready() -> void:
	_update()


func _update() -> void:
	if _car == null:
		return
	_sync_stage()
	var p := GameData.paint(paint_id)
	if p.is_empty():
		p = GameData.paint(GameData.default_paint_id())
	_paint_material.albedo_color = Color(String(p["color"]))
	var pearl := String(p.get("finish", "")) == "pearl"
	_paint_material.metallic = 0.55 if pearl else 0.0
	_paint_material.roughness = 0.28 if pearl else _paint_roughness
	for panel_name in ["Body", "Roof"]:
		var coated := preload("res://ui/car_appearance.gd").coated_material(_paint_material, paint_id, panel_name == "Roof")
		(_car.get_node(panel_name) as MeshInstance3D).material_override = coated

	_decal_material.albedo_color = contrast_for(paint_id)
	if _accent_material != null:
		_accent_material.albedo_color = Color("ef7047") if _paint_material.albedo_color.get_luminance() > 0.6 else contrast_for(paint_id)
	_rebuild_decals()
	_view.modulate.a = 0.55 if dimmed else 1.0
	if size.x >= 1.0 and size.y >= 1.0:
		# Render đúng số điểm ảnh thật trên màn hình để mép xe không bị nhoè.
		var scale_up := 2.0
		if is_inside_tree():
			scale_up = clampf(get_viewport().get_screen_transform().get_scale().x, 1.0, 3.0)
		_viewport.size = Vector2i((size * scale_up).round())
		_place_camera()
	_request_render()


func _sync_stage() -> void:
	var enabled := showroom_3d and show_floor
	if enabled and _stage == null:
		_stage = preload("res://ui/garage_showroom_stage.gd").new(showroom_texture)
		_viewport.add_child(_stage)
	if _stage != null:
		_stage.visible = enabled
		_stage.scale = Vector3.ONE * (0.74 if pedestal_only else 1.0)
		for node in _stage.get_children():
			if String(node.name).begins_with("Floor"):
				(node as Node3D).visible = not pedestal_only
	if _key_light != null:
		_key_light.shadow_enabled = enabled
		_key_light.shadow_blur = 3.0 if enabled else 1.0
		_key_light.shadow_opacity = 0.65 if enabled else 1.0
		_key_light.directional_shadow_max_distance = 20.0 if enabled else 100.0


## Khu trưng bày chừa lề cho bục và nền; thẻ bộ sưu tập thì xe chiếm gần hết khung.
func _place_camera() -> void:
	var aspect := size.x / size.y
	var span_x := 4.6 if show_floor else 3.9
	var span_y := (3.0 if top_down else 2.5) if show_floor else 1.9
	if show_floor and showroom_texture != null:
		span_y = 3.3
	if showroom_3d and show_floor:
		span_x = 3.85 if pedestal_only else 6.2
		span_y = 2.75 if pedestal_only else 3.7
	if race_class_id == "monster":
		span_y = maxf(span_y, 3.0)
	var half_tan := tan(deg_to_rad(FOV * 0.5))
	var distance := maxf(span_y, span_x / aspect) * 0.5 / half_tan
	var elevation := deg_to_rad(40.0 if top_down else 23.0)
	# Điểm ngắm cao hơn tâm xe đẩy xe xuống đúng mặt bục của ảnh nền.
	var target := Vector3(0, 0.95 if race_class_id == "monster" else 0.55, 0)
	if show_floor:
		target.y = 0.50 if top_down else 0.83
		if showroom_texture != null:
			target.y = 0.40
	if showroom_3d and show_floor:
		target.y = 0.65 if pedestal_only else (0.5 if race_class_id == "monster" else (0.28 if race_class_id == "bike" else 0.05))
	var direction := Vector3(0, sin(elevation), cos(elevation))
	_camera.position = target + direction * distance
	_camera.basis = Basis.looking_at(-direction)
	if showroom_3d and show_floor and _stage != null:
		_stage.fit_backdrop(2.0 * (_camera.position.z + 4.2) * half_tan * aspect * 1.02)


func _request_render() -> void:
	if _viewport == null:
		return
	# Xe đứng yên trong thẻ chỉ cần vẽ một lần; khu trưng bày vẽ khi đang hiện.
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if rotatable else SubViewport.UPDATE_ONCE


func _gui_input(event: InputEvent) -> void:
	if rotatable and event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0 \
			and absf(event.relative.x) > absf(event.relative.y):
		yaw = fposmod(yaw + event.relative.x * DRAG_DEGREES_PER_UNIT, 360.0)
		yaw_changed.emit(yaw)
		accept_event()


func _draw() -> void:
	if show_floor and not showroom_3d:
		var background := showroom_texture if showroom_texture != null else HdUi.Soft.texture("garage_showroom_front")
		if background != null:
			if showroom_texture != null:
				# Uniform cover; the narrow viewport crops the room instead of flattening it.
				var texture_size := background.get_size()
				var scale_to_fill := maxf(size.x / texture_size.x, size.y / texture_size.y)
				var source_size := size / scale_to_fill
				var source := Rect2(Vector2((texture_size.x - source_size.x) * 0.5, texture_size.y - source_size.y), source_size)
				draw_texture_rect_region(background, Rect2(Vector2.ZERO, size), source)
			else:
				draw_texture_rect(background, Rect2(Vector2.ZERO, size), false)


# ---------------------------------------------------------------- decal

func _rebuild_decals() -> void:
	for child in _decals.get_children():
		_decals.remove_child(child)
		child.queue_free()
	if decal_id == "none":
		return
	var pattern := ["none","double_stripe","lightning","checker"].find(decal_id)
	for panel_name in ["Body", "Roof"]:
		var panel: MeshInstance3D = _car.get_node(panel_name)
		var overlay := MeshInstance3D.new()
		overlay.name = "Livery_"+panel_name
		overlay.mesh = panel.mesh
		overlay.transform = panel.transform
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://ui/car_livery.gdshader")
		mat.set_shader_parameter("ink",contrast_for(paint_id))
		mat.set_shader_parameter("pattern",pattern)
		mat.set_shader_parameter("panel_offset",panel.position)
		mat.set_shader_parameter("body_top",float(_car.get_meta("body_top",0.86)))
		overlay.material_override = mat
		_decals.add_child(overlay)


## Stable display number from the existing ordered car catalogue; no save field.
func _build_race_number() -> void:
	var number := 3
	for i in GameData.cars().size():
		if String(GameData.cars()[i]["id"]) == car_id:
			number = i + 3
			break
	var badge_mat := StandardMaterial3D.new()
	badge_mat.albedo_color = Color("fff1ce")
	badge_mat.roughness = 0.55
	var w := float(_car.get_meta("body_width",1.64))
	var top := float(_car.get_meta("body_top",0.86))
	for side: float in [-1.0,1.0]:
		var disk := MeshInstance3D.new()
		disk.name = "RaceNumberBadge_Left" if side < 0 else "RaceNumberBadge_Right"
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.205
		mesh.bottom_radius = 0.205
		mesh.height = 0.018
		mesh.radial_segments = 48
		disk.mesh = mesh
		disk.material_override = badge_mat
		disk.position = Vector3(side*(w/2+0.008),top-0.24,0.0)
		disk.rotation.z = PI/2
		_car.add_child(disk)
		var label := Label3D.new()
		label.name = "RaceNumber"
		label.text = "%02d" % number
		label.font = ThemeDB.fallback_font
		label.font_size = 96
		label.pixel_size = 0.0027
		label.modulate = Color("24313c")
		label.outline_size = 0
		label.no_depth_test = false
		label.position = disk.position + Vector3(side*0.013,0,0)
		label.rotation.y = side*PI/2
		_car.add_child(label)
