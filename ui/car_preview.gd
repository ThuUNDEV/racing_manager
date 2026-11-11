class_name CarPreview
extends Control
## Xe nhìn từ trên xuống (atlas Workshop GP) + decal vẽ bằng code. Dùng cho khu trưng bày Garage và thẻ bộ sưu tập.
## Toạ độ decal tính theo điểm ảnh của ảnh xe gốc (238×421), gốc ở tâm xe, mũi xe hướng xuống (+y), cánh gió ở trên.
## Xe là TextureRect (vẽ atlas bằng _draw cho ra ô trắng khi texture chưa được node nào dùng), decal là lớp Control con.

const ROOT := "res://assets/workshop_gp/"
const TEX_SIZE := Vector2(238.0, 421.0)
const C_DARK := Color("1d1f24")
const C_LIGHT := Color("fff8e7")

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
	var tex := load(ROOT + String(p["texture"])) as Texture2D
	_car.texture = tex
	_shadow.texture = tex
	var k := minf(size.y * 0.9 / TEX_SIZE.y, size.x * 0.9 / TEX_SIZE.y)
	if angle != 0.0:
		k *= 0.86  # chừa chỗ cho góc xoay
	_rig.position = size * 0.5
	_rig.rotation = angle
	_rig.scale = Vector2(k, k)
	var a := 0.55 if dimmed else 1.0
	_car.modulate = Color(1, 1, 1, a)
	_shadow.modulate = Color(0, 0, 0, 0.18 * a)
	_layer.paint_id = paint_id
	_layer.decal_id = decal_id
	_layer.alpha = a
	_layer.queue_redraw()
	queue_redraw()


func _ready() -> void:
	_update()


func _draw() -> void:
	if show_floor:
		draw_set_transform(size * 0.5, 0.0, Vector2(1.0, 0.42))
		draw_arc(Vector2.ZERO, size.x * 0.36, 0.0, TAU, 72, Color("b7a995", 0.7), 1.5, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
