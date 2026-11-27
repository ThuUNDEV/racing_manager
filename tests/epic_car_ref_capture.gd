extends SceneTree
## Chụp model 3D của 5 xe Epic và 5 bộ sơn Epic (xe mẫu Apex) làm ảnh tham chiếu dáng xe cho tools/gen_epic_stages.py.
##   XDG_DATA_HOME=/tmp/rmx godot --path . --screen 1 --audio-driver Dummy -s res://tests/epic_car_ref_capture.gd
const OUT := "res://output/imagegen/epic_popup_stage/"
const PAINT_CAR := "car_apex_tia_chop"


func _initialize() -> void:
	call_deferred("run")


func settle(count: int = 30) -> void:
	for i in count:
		await process_frame


func run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIP: no renderer under --headless")
		quit(0)
		return
	GameData.reload()
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DisplayServer.window_set_size(Vector2i(768, 512))
	root.size = Vector2i(768, 512)
	await settle()
	var jobs: Array = []
	for car: Dictionary in GameData.epic_cars():
		jobs.append(["ref3d_" + String(car["id"]), String(car["id"]), String(car["default_paint"])])
	for paint_id in ["epic_aurora", "epic_solar", "epic_midnight", "epic_sakura", "epic_neon"]:
		jobs.append(["ref3d_" + paint_id, PAINT_CAR, paint_id])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for job: Array in jobs:
		var holder := ColorRect.new()
		holder.color = Color("a07ce8")
		holder.size = Vector2(768, 512)
		root.add_child(holder)
		var preview := CarPreview.new()
		preview.show_floor = true
		preview.showroom_3d = true
		preview.pedestal_only = true
		preview.car_id = job[1]
		preview.paint_id = job[2]
		preview.size = Vector2(768, 512)
		holder.add_child(preview)
		await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + String(job[0]) + ".png"))
		print("WROTE ", job[0])
		holder.queue_free()
		await settle(3)
	quit(0)
