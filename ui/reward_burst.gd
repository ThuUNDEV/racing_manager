extends Control
## Lightweight vector backdrop; drawn at viewport resolution without stretched artwork.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var center := size * Vector2(0.5, 0.5)
	var radius := minf(size.x, size.y) * 0.49
	# Soft halo with tapered rays behind the reward illustration.
	for step in range(18, 0, -1):
		draw_circle(center, radius * float(step) / 18.0, Color(0.85, 0.96, 1.0, 0.018))
	for i in 12:
		var angle := TAU * i / 12.0 - 0.15
		var points := PackedVector2Array([
			center + Vector2.from_angle(angle - 0.025) * radius * 0.24,
			center + Vector2.from_angle(angle - 0.10) * radius,
			center + Vector2.from_angle(angle + 0.10) * radius,
			center + Vector2.from_angle(angle + 0.025) * radius * 0.24])
		draw_polygon(points, PackedColorArray([Color(0.9, 0.98, 1, 0.22), Color(0.9, 0.98, 1, 0), Color(0.9, 0.98, 1, 0), Color(0.9, 0.98, 1, 0.22)]))
	for spark in [Vector3(0.15, 0.32, 7), Vector3(0.81, 0.28, 9), Vector3(0.89, 0.58, 5), Vector3(0.20, 0.72, 5)]:
		var origin := size * Vector2(spark.x, spark.y)
		var points := PackedVector2Array()
		for i in 8:
			var length: float = spark.z if i % 2 == 0 else spark.z * 0.24
			points.append(origin + Vector2.from_angle(PI * i / 4.0) * length)
		draw_colored_polygon(points, Color("ffffff"))
