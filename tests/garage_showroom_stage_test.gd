extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	GameData.reload()
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 845)
	var plain := CarPreview.new()
	root.add_child(plain)
	plain.size = Vector2(120, 60)
	check(plain._stage == null and not plain._key_light.shadow_enabled, "Preview thường không tạo sân khấu 3D")
	var preview := CarPreview.new()
	preview.showroom_texture = preload("res://assets/garage_soft_miniature_v2/showroom.png")
	preview.showroom_3d = true
	preview.rotatable = true
	root.add_child(preview)
	check(preview._stage != null and preview._key_light.shadow_enabled, "Garage có nền và bóng đổ thật")
	var top: MeshInstance3D = preview._stage.get_node("TurntableTop")
	check(is_equal_approx(top.position.y + top.mesh.height * 0.5, 0.0), "Mặt bục ở cùng cao độ tiếp đất bánh xe")
	for dimensions in [Vector2(312,104), Vector2(358,170), Vector2(380,170)]:
		preview.size = dimensions
		for family in ["pico", "nova", "apex", "titan", "zenith"]:
			preview.car_id = "car_%s_tia_chop" % family
			for angle in [90.0, 145.0, 210.0]:
				preview.yaw = angle
				var screen := Rect2(Vector2.ZERO, Vector2(preview._viewport.size))
				for point in [Vector3(-2.56,-0.24,0), Vector3(2.56,-0.24,0), Vector3(0,-0.24,2.56), Vector3(0,0,-2.56)]:
					check(screen.grow(1).has_point(preview._camera.unproject_position(point)), "Bục trong viewport %s %s" % [dimensions, family])
				var car_fits := true
				for node in preview._car.find_children("*", "MeshInstance3D", true, false):
					var mesh := node as MeshInstance3D
					if mesh.name == "Shadow" or mesh.get_parent().name == "Shadow":
						continue
					var bounds := mesh.get_aabb()
					for corner in 8:
						var point := mesh.global_transform * bounds.get_endpoint(corner)
						car_fits = car_fits and screen.grow(1).has_point(preview._camera.unproject_position(point))
				check(car_fits, "Toàn bộ thân xe trong viewport %s %s góc%s" % [dimensions, family, angle])
	var platform_transform := top.global_transform
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.relative = Vector2(40,0)
	var before := preview.yaw
	preview._gui_input(motion)
	check(preview.yaw != before, "Kéo xoay xe")
	check(top.global_transform == platform_transform, "Bục giữ vị trí khi xe xoay")
	preview.showroom_3d = false
	check(not preview._stage.visible and not preview._key_light.shadow_enabled, "Có thể tắt thử nghiệm 3D")
	plain.queue_free()
	preview.queue_free()
	await process_frame
	print("GARAGE_SHOWROOM_STAGE_TEST failures=", failures)
	quit(1 if failures else 0)
