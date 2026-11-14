class_name CarPreview
extends Control
const CleanArt = preload("res://ui/clean_modern_art.gd")
## HD expansion body by car class, neutral-body paint shader and separate showroom.
## Three-quarter view by default; overhead for cosmetic editing or saved decals.
## Legacy decal coordinates use a 238x421 canvas; flip their Y axis for nose-up art.

const ROOT := "res://assets/workshop_gp/"
const TEX_SIZE := Vector2(238.0, 421.0)
const C_DARK := Color("1d1f24")
const C_LIGHT := Color("fff8e7")
const PAINT_SHADER := preload("res://ui/car_paint.gdshader")

var car_id: String = "car_pico_tia_chop":
	set(v):
		car_id = v
		_update()
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
var show_floor: bool = true:
	set(v):
		show_floor = v
		queue_redraw()
var angle: float = 0.5:
	set(v):
		angle = v
		_update()
var dimmed: bool = false:  # xe chưa sở hữu: mờ nhẹ
	set(v):
		dimmed = v
		_update()

var _rig: Control
var _shadow: TextureRect
var _car: TextureRect
var _layer: DecalLayer
var _paint_material: ShaderMaterial


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rig = Control.new()
	_rig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rig)
	_shadow = _make_tex()
	_shadow.position = Vector2(-TEX_SIZE.x * 0.5 + 12.0, -TEX_SIZE.y * 0.5 + 16.0)
	_shadow.modulate = Color(0, 0, 0, 0.18)
	_rig.add_child(_shadow)
	_car = _make_tex()
	_paint_material = ShaderMaterial.new()
	_paint_material.shader = PAINT_SHADER
	_car.material = _paint_material
	_car.position = -TEX_SIZE * 0.5
	_rig.add_child(_car)
	_layer = DecalLayer.new()
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rig.add_child(_layer)
	resized.connect(_update)


func _make_tex() -> TextureRect:
	var t := TextureRect.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size = TEX_SIZE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	return t


## Màu tương phản cố định cho decal theo độ sáng của màu sơn (Design/15 §8).
static func contrast_for(paint: String) -> Color:
	var p := GameData.paint(paint)
	if p.is_empty():
		return C_LIGHT
	return C_DARK if Color(String(p["color"])).get_luminance() > 0.5 else C_LIGHT


func _update() -> void:
	if _rig == null:
		return
	var p := GameData.paint(paint_id)
	if p.is_empty():
		p = GameData.paint(GameData.default_paint_id())
	# Preserve the saved decal view using the new overhead body, whose nose points up.
	var overhead := top_down or decal_id != "none"
	var tex := ExpansionArt.texture(ExpansionArt.car_id(car_id, overhead))
	if tex == null:
		tex = CleanArt.asset(ROOT + String(p["texture"])) as Texture2D
	var dimensions := TEX_SIZE if overhead else Vector2(360, 230)
	_car.texture = tex
	_car.size = dimensions
	_car.position = -dimensions * 0.5
	_car.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_paint_material.set_shader_parameter("paint_color", Color(String(p["color"])))
	_shadow.texture = ExpansionArt.texture("car_shadow")
	_shadow.size = Vector2(dimensions.x, dimensions.y * 0.18)
	_shadow.position = Vector2(-dimensions.x * 0.5, dimensions.y * 0.32)
	var k := minf(size.y * 0.85 / dimensions.y, size.x * 0.85 / dimensions.x)
	_rig.position = size * 0.5
	_rig.rotation = angle if overhead else 0.0
	_rig.scale = Vector2(k, k)
	var a := 0.55 if dimmed else 1.0
	_car.modulate = Color(1, 1, 1, a)
	_shadow.modulate = Color(0, 0, 0, 0.18 * a)
	_layer.paint_id = paint_id
	_layer.decal_id = decal_id
	_layer.alpha = a
	_layer.visible = overhead
	_layer.scale = Vector2(1, -1)
	_layer.queue_redraw()
	queue_redraw()


func _ready() -> void:
	_update()


func _draw() -> void:
	if show_floor:
		var floor_tex := ExpansionArt.texture("showroom_floor")
		if floor_tex != null:
			draw_texture_rect(floor_tex, Rect2(size.x * 0.08, size.y * 0.62, size.x * 0.84, size.y * 0.3), false)


## Lớp decal phủ lên thân xe (toạ độ điểm ảnh ảnh gốc, gốc ở tâm xe).
class DecalLayer extends Control:
	var paint_id: String = "orange"
	var decal_id: String = "none"
	var alpha: float = 1.0

	func _draw() -> void:
		var col := Color(CarPreview.contrast_for(paint_id), 0.94 * alpha)
		match decal_id:
			"double_stripe":
				for x: float in [-52.0, 40.0]:
					draw_rect(Rect2(x, 62.0, 12.0, 124.0), col)
					draw_rect(Rect2(x, -140.0, 12.0, 56.0), col)
			"lightning":
				draw_colored_polygon(_bolt(Vector2(0, 64), 1.0), col)
				draw_colored_polygon(_bolt(Vector2(0, -138), 0.45), col)
			"checker":
				for r in 6:
					for q in 6:
						if (r + q) % 2 == 0:
							draw_rect(Rect2(-54.0 + 18.0 * q, 70.0 + 18.0 * r, 18.0, 18.0), col)
				for r in 2:
					for q in 6:
						if (r + q) % 2 == 0:
							draw_rect(Rect2(-54.0 + 18.0 * q, -138.0 + 18.0 * r, 18.0, 18.0), col)

	## Tia chớp 6 đỉnh, cao khoảng 116 đơn vị khi scale = 1; `top` là điểm trên cùng giữa.
	func _bolt(top: Vector2, s: float) -> PackedVector2Array:
		var pts := PackedVector2Array([Vector2(12, 0), Vector2(-28, 52), Vector2(-4, 52), Vector2(-16, 116), Vector2(30, 40), Vector2(4, 40)])
		for i in pts.size():
			pts[i] = top + pts[i] * s
		return pts
