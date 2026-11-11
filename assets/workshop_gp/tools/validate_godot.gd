extends SceneTree
## Run inside the isolated art project, never inside the gameplay project.
const ROOT := "res://assets/workshop_gp/"
var _failures: Array[String] = []
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
		if _failures.size()<=10:
			push_error(message)


func _buttons(node: Node, text: String) -> Array[Button]:
	var result: Array[Button] = []
	if node is Button and node.text==text:
		result.append(node)
	for child in node.get_children():
		result.append_array(_buttons(child,text))
	return result


func _audit_width(node: Node, width: float) -> void:
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		_check(rect.position.x>=-1 and rect.end.x<=width+1,"Horizontal overflow: "+str(node.get_path()))
	for child in node.get_children():
		_audit_width(child,width)


func _run() -> void:
	AudioServer.set_bus_mute(0,true)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"asset_catalog.json"))
	var stage := Control.new()
	stage.size = root.get_visible_rect().size
	print("WORKSHOP_QA_VIEWPORT ",stage.size)
	root.add_child(stage)
	for path: String in catalog.native_resources:
		var resource: Resource = load(ROOT+path)
		_check(resource!=null,"Load failed: "+path)
		if resource is PackedScene and not path.begins_with("preview/"):
			var instance: Node = (resource as PackedScene).instantiate()
			stage.add_child(instance)
			await process_frame
			if path.begins_with("components/") and not path.ends_with("dialog.tscn"):
				instance.configure({"title":"Kiểm tra tiếng Việt","disabled":true,"selected":true})
				_check(instance.get_node_or_null("Content/Action")==null or instance.get_node("Content/Action").disabled,"Disabled visual state: "+path)
			instance.queue_free()
			await process_frame
	var audio: Node = (load(ROOT+"components/workshop_audio.gd") as Script).new()
	stage.add_child(audio)
	for entry: Dictionary in catalog.audio:
		var cue: String = str(entry.path).get_file().get_basename()
		var player: AudioStreamPlayer = audio.play(cue)
		_check(player!=null,"Audio creation: "+cue)
		if player!=null:
			var stream := player.stream as AudioStreamWAV
			_check(stream.get_length()>0,"Audio decode: "+cue)
			if bool(entry.loop):
				_check(stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_end>0,"Audio loop: "+cue)
		audio.stop_all()
		await process_frame
	var gallery := (load(ROOT+"preview/asset_gallery.tscn") as PackedScene).instantiate()
	gallery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(gallery)
	await process_frame
	for screen: String in gallery.SCREENS:
		gallery._show(screen)
		await process_frame
		await process_frame
		_audit_width(gallery._root,stage.size.x)
	gallery._show("drivers")
	await process_frame
	var drivers := _buttons(gallery,"Chọn tay đua")
	_check(drivers.size()==2,"Two selectable driver previews")
	if not drivers.is_empty():
		drivers[0].pressed.emit()
		_check(gallery._selected_driver=="binh","Driver selection signal refreshes the preview")
	gallery._show("shop")
	await process_frame
	var gift := _buttons(gallery,"Nhận quà miễn phí")
	_check(gift.size()==1,"Daily reward action exists")
	if not gift.is_empty():
		gift[0].pressed.emit()
		await process_frame
		var claimed := _buttons(gallery,"Đã nhận · Hẹn ngày mai")
		_check(claimed.size()==1 and claimed[0].disabled,"Claimed preview state disables the button")
	await create_timer(.8).timeout
	stage.queue_free()
	await process_frame
	print("WORKSHOP_NATIVE_VALIDATION checks=",_checks," failures=",_failures.size())
	quit(0 if _failures.is_empty() else 1)
