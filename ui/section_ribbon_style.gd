extends StyleBox
## Render one complete ribbon at its destination size; no slices cross the artwork.
const RASTER_SCALE := 3.0
const CACHE_LIMIT := 48
static var _faces: Dictionary = {}
var _face: ImageTexture

func _draw(canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	_face = face_for_size(rect.size)
	RenderingServer.canvas_item_add_texture_rect(canvas_item, rect, _face.get_rid())

static func face_for_size(size: Vector2) -> ImageTexture:
	var extent := Vector2i(ceili(size.x * RASTER_SCALE), ceili(size.y * RASTER_SCALE))
	if _faces.has(extent):
		return _faces[extent]
	var logical := Vector2(extent) / RASTER_SCALE
	var radius := minf(12.0, minf(logical.x, logical.y) * 0.5)
	var pixels := Image.create_empty(extent.x, extent.y, false, Image.FORMAT_RGBA8)
	var light := Color("e0f7ff")
	var mid := Color("b3e4f7")
	var bottom := Color("95d1ed")
	for y in extent.y:
		var py := (y + 0.5) / RASTER_SCALE
		var v := py / logical.y
		var row := light.lerp(mid, smoothstep(0.0, 0.62, v)).lerp(bottom, smoothstep(0.65, 1.0, v))
		for x in extent.x:
			var point := Vector2((x + 0.5) / RASTER_SCALE, py)
			var edge_distance := Vector2(mini(x, extent.x - 1 - x) + 0.5, mini(y, extent.y - 1 - y) + 0.5)
			var corner_delta := (Vector2.ONE * radius * RASTER_SCALE - edge_distance).max(Vector2.ZERO)
			var inset := radius * RASTER_SCALE - corner_delta.length()
			var color := row
			# Evaluate the whole checker in destination coordinates so its cells
			# stay square and connected when a translated title changes the height.
			var pattern_x := point.x - (logical.x - 64.0)
			if pattern_x > 0:
				var column := floori((pattern_x + py * 0.32) / 11.0)
				if (column + floori(py / 11.0)) % 2 == 0:
					color = color.lerp(Color.WHITE, 0.65 * smoothstep(0.0, 56.0, pattern_x))
			# A continuous outline avoids the old light/dark break halfway down
			# the side edges. Supersampling keeps curves smooth at mobile scale.
			color.a = clampf(inset + 0.5, 0.0, 1.0)
			pixels.set_pixel(x, y, color)
	pixels.generate_mipmaps()
	var face := ImageTexture.create_from_image(pixels)
	if _faces.size() >= CACHE_LIMIT:
		_faces.erase(_faces.keys()[0])
	_faces[extent] = face
	return face
