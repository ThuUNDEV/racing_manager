extends SceneTree
const Ribbon = preload("res://ui/section_ribbon_style.gd")
const Soft = preload("res://ui/soft_miniature.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)
func _initialize() -> void:
	for width in [288, 358, 380]:
		for height in [34, 38, 44, 84]:
			var image := Ribbon.face_for_size(Vector2(width, height)).get_image()
			check(image.get_pixel(0, 0).a == 0, "Góc ngoài trong suốt %dx%d" % [width, height])
			check(image.get_pixel(image.get_width() / 2, image.get_height() / 2).a == 1, "Nền giữa kín %dx%d" % [width, height])
			# The old edge highlight changed abruptly at half-height, even when
			# the gradient in the middle of the panel was continuous.
			for y in range(37, image.get_height() - 37):
				var previous := image.get_pixel(1, y - 1)
				var current := image.get_pixel(1, y)
				check(absf(current.r - previous.r) < 0.03 and absf(current.g - previous.g) < 0.03, "Viền không gãy màu tại y=%d" % y)
			# Every opaque checker cell stays inside the same rounded silhouette.
			for y in image.get_height():
				check(is_equal_approx(image.get_pixel(0, y).a, image.get_pixel(image.get_width() - 1, y).a), "Hai mép bo góc đối xứng")
	# Changing height must preserve the checker grid in destination coordinates.
	var amounts: Array[float] = []
	for height in [44, 84]:
		var image := Ribbon.face_for_size(Vector2(358, height)).get_image()
		var y := 61
		var base := image.get_pixel(200, y).r
		var tile := image.get_pixel(1021, y).r
		amounts.append((tile - base) / (1.0 - base))
	check(absf(amounts[0] - amounts[1]) < 0.04, "Ô cờ không méo khi chiều cao thay đổi")
	for kind in ["section", "section_tall"]:
		var style := Soft.surface(kind, Vector4(8, 3, 8, 5))
		check(style.get_minimum_size() == Vector2(16, 8), "Nền không tăng kích thước layout")
	print("SECTION_RIBBON_UI_TEST failures=", failures)
	quit(1 if failures else 0)
