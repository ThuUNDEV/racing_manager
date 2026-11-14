extends SceneTree
## Run in the isolated asset project created by verify_iap_assets.py, not the live game.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/iap_offers/manifest.json"))
	var skin_script = load("res://assets/iap_offers/iap_skin.gd")
	var failures := 0
	for id in data["textures"]:
		var info: Dictionary = data["textures"][id]
		var tex := load("res://" + String(info["resource"])) as AtlasTexture
		if tex == null or tex.get_width() <= 0 or tex.get_height() <= 0:
			push_error("Invalid texture: " + String(id))
			failures += 1
	for id in data["styles"]:
		var skin: StyleBoxTexture = skin_script.style(String(id))
		if skin == null or skin.texture == null or skin.texture.get_width() <= 0:
			push_error("Invalid skin: " + String(id))
			failures += 1
	for sku in data["recipes"]:
		var info: Dictionary = data["recipes"][sku]
		var packed := load("res://" + String(info["scene"])) as PackedScene
		if packed == null:
			push_error("Invalid scene: " + String(sku))
			failures += 1
			continue
		var node := packed.instantiate() as Control
		root.add_child(node)
		node.size = Vector2(320, 320.0 * 2.0 / 3.0)
		if node.get_node("Background").texture == null:
			failures += 1
		node.free()
	print("IAP ART: %s textures, %s styles, %s SKU scenes; %s failures" % [data["textures"].size(), data["styles"].size(), data["recipes"].size(), failures])
	quit(0 if failures == 0 else 1)
