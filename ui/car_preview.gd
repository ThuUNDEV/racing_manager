class_name CarPreview
extends Control
## Xe 3D (assets/models/race_car, dùng chung với màn đua) render vào SubViewport trong suốt, đặt trên nền khu trưng bày.
## Màu sơn đổi vật liệu thân xe, decal là mesh phẳng trên mui/nóc/đuôi. Bật `rotatable` để kéo ngang xoay xe.

signal yaw_changed(value: float)

const MODEL := preload("res://assets/models/race_car/race_car.tscn")
const SCENE_RATIO := 600.0 / 1024.0
const C_DARK := Color("1d1f24")
const C_LIGHT := Color("fff8e7")
const PAINT_NAME := "Body_Paint_Blue"
## Mặt trước xe là -Z; góc này cho mũi xe quay chéo về phía trái người xem.
const DEFAULT_YAW := 125.0
const DRAG_DEGREES_PER_UNIT := 0.8
const FOV := 24.0

var car_id: String = "car_pico_tia_chop"
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
var rotatable: bool = false:
	set(v):
		rotatable = v
		mouse_filter = Control.MOUSE_FILTER_PASS if v else Control.MOUSE_FILTER_IGNORE
		_request_render()

var _viewport: SubViewport
var _view: TextureRect
var _car: Node3D
var _camera: Camera3D
var _paint_material: StandardMaterial3D
var _decals: Node3D
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
	_car = MODEL.instantiate()
	_viewport.add_child(_car)
	_car.rotation_degrees.y = yaw
	# Sọc đúc sẵn của model được ẩn: hoa văn chỉ đến từ decal người chơi chọn.
	for child in _car.get_children():
		if child is MeshInstance3D and child.material_override != null and child.material_override.resource_name == "Pearl_White" \
				and absf(child.position.x) < 0.5:
			child.visible = false
	_apply_paint_material(_car)
	_decal_material = StandardMaterial3D.new()
	_decal_material.roughness = 0.5
	_decal_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_decals = Node3D.new()
	_decals.name = "Decals"
	_car.add_child(_decals)
	_car.add_child(_make_shadow())

	_camera = Camera3D.new()
	_camera.fov = FOV
	_viewport.add_child(_camera)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff6ea")
	environment.environment.ambient_light_energy = 0.6
	_viewport.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, -30, 0)
	key.light_energy = 0.9
	_viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 55, 0)
	fill.light_color = Color("cfe4ff")
	fill.light_energy = 0.3
	_viewport.add_child(fill)


## Mỗi khung xem có bản vật liệu sơn riêng để màu của xe này không lan sang xe khác.
func _apply_paint_material(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.material_override != null and child.material_override.resource_name == PAINT_NAME:
			if _paint_material == null:
				_paint_material = child.material_override.duplicate()
			child.material_override = _paint_material
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
	return shadow


## Màu tương phản cố định cho decal theo độ sáng của màu sơn (Design/15 §8).
static func contrast_for(paint: String) -> Color:
	var p := GameData.paint(paint)
	if p.is_empty():
		return C_LIGHT
	return C_DARK if Color(String(p["color"])).get_luminance() > 0.5 else C_LIGHT


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
	var p := GameData.paint(paint_id)
	if p.is_empty():
		p = GameData.paint(GameData.default_paint_id())
	_paint_material.albedo_color = Color(String(p["color"]))
	_decal_material.albedo_color = contrast_for(paint_id)
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


## Khu trưng bày chừa lề cho bục và nền; thẻ bộ sưu tập thì xe chiếm gần hết khung.
func _place_camera() -> void:
	var aspect := size.x / size.y
	var span_x := 5.1 if show_floor else 3.6
	var span_y := 2.5 if show_floor else 1.9
	var half_tan := tan(deg_to_rad(FOV * 0.5))
	var distance := maxf(span_y, span_x / aspect) * 0.5 / half_tan
	var elevation := deg_to_rad(38.0 if top_down else 12.0)
	# Điểm ngắm cao hơn tâm xe đẩy xe xuống đúng mặt bục của ảnh nền.
	var target := Vector3(0, 0.55, 0)
	if show_floor:
		target.y = 0.65 if top_down else 0.78
	var direction := Vector3(0, sin(elevation), cos(elevation))
	_camera.position = target + direction * distance
	_camera.basis = Basis.looking_at(-direction)


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
	if show_floor:
		var background := HdUi.Soft.texture("garage_showroom_front")
		if background != null:
			draw_texture_rect(background, Rect2(Vector2.ZERO, size), false)


# ---------------------------------------------------------------- decal

func _rebuild_decals() -> void:
	for child in _decals.get_children():
		_decals.remove_child(child)
		child.queue_free()
	# Ba mặt phẳng nhận decal: mui (trước kính), nóc, đuôi. Giá trị là (độ cao, z giữa, chiều dài).
	var hood := Vector3(0.708, -0.99, 0.56)
	var roof := Vector3(1.167, 0.23, 0.74)
	var tail := Vector3(0.708, 1.03, 0.40)
	match decal_id:
		"double_stripe":
			for surface: Vector3 in [hood, roof, tail]:
				for x: float in [-0.19, 0.19]:
					_decal_box(Vector2(x, surface.y), Vector2(0.14, surface.z), surface.x)
		"lightning":
			_decal_bolt(Vector2(0, hood.y), 0.0050, hood.x)
			_decal_bolt(Vector2(0, roof.y), 0.0062, roof.x)
		"checker":
			for surface: Vector3 in [hood, roof]:
				var cell := surface.z / 4.0
				for r in 4:
					for q in 4:
						if (r + q) % 2 == 0:
							_decal_box(Vector2((q - 1.5) * cell, surface.y + (r - 1.5) * cell), Vector2(cell, cell), surface.x)


## `at` và `extent` là toạ độ (x, z) trên mặt xe, `height` là độ cao mặt đó.
func _decal_box(at: Vector2, extent: Vector2, height: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(extent.x, 0.012, extent.y)
	_add_decal(mesh, Vector3(at.x, height, at.y))


## Tia chớp 6 đỉnh (cao 116 đơn vị), đặt nằm trên mặt xe, tâm tại `at`.
func _decal_bolt(at: Vector2, unit: float, height: float) -> void:
	var outline := PackedVector2Array([Vector2(12, 0), Vector2(-28, 52), Vector2(-4, 52), Vector2(-16, 116), Vector2(30, 40), Vector2(4, 40)])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in Geometry2D.triangulate_polygon(outline):
		surface.set_normal(Vector3.UP)
		surface.add_vertex(Vector3(outline[i].x * unit, 0.0, (outline[i].y - 58.0) * unit))
	_add_decal(surface.commit(), Vector3(at.x, height + 0.008, at.y))


func _add_decal(mesh: Mesh, at: Vector3) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _decal_material
	node.position = at
	_decals.add_child(node)
