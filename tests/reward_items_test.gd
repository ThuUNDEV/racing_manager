extends SceneTree
## Danh mục vật phẩm thưởng: mỗi loại một icon duy nhất, mọi icon thưởng của gói IAP đều tra được.
const RewardItems = preload("res://core/data/reward_items.gd")
const PackUi = preload("res://ui/shop_pack_ui.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)


func run() -> void:
	GameData.reload()
	var seen := {}
	for id: String in RewardItems.ITEMS:
		var item = RewardItems.ITEMS[id]
		check(item.id == id, "id trong .tres khớp khóa: " + id)
		check(item.icon != null, "có icon: " + id)
		var path: String = item.icon.resource_path
		check(not seen.has(path), "không hai loại dùng chung một icon (%s, %s)" % [id, seen.get(path, "")])
		seen[path] = id
		check(RewardItems.item_name(id) != id, "có tên hiển thị đã dịch: " + id)
	for product: Dictionary in GameData.iap_products():
		for row: Dictionary in PackUi.rewards(product):
			var id := String(row["icon"])
			if id.begins_with("driver_") or bool(row.get("shards", false)):
				continue
			check(RewardItems.has(id), "icon thưởng '%s' của %s có trong danh mục" % [id, product["sku"]])
	var a := PackUi.icon("gem", 30)
	check(a.texture == RewardItems.icon("gem"), "PackUi.icon dùng icon của danh mục")
	print("REWARD_ITEMS_TEST failures=", failures)
	quit(1 if failures > 0 else 0)
