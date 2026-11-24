extends RefCounted
## Each lesson owns its goal, trigger, stages and completion contract.
## The manifest controls scheduling; stable lesson IDs preserve existing saves.
const PATH := "res://data/tutorial.json"
static var _groups: Dictionary = {}
static var _revision := -1


static func reload() -> void:
	_groups.clear()
	_revision = -1


static func group(kind: String) -> Array:
	if _revision != I18n.revision:
		_groups.clear()
		_revision = I18n.revision
	if not _groups.has(kind):
		var rows: Array = []
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if manifest is Dictionary:
			for path: String in manifest.get(kind, []):
				var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
				if raw is Dictionary:
					var item: Dictionary = I18n.translate_tree(raw)
					if kind == "features":
						item["races"] = int(item.get("trigger", {}).get("completed_races", 0))
					if kind in ["features", "tips"]:
						item["tab"] = String(item.get("trigger", {}).get("tab", ""))
					item["source"] = path
					rows.append(item)
		_groups[kind] = rows
	return _groups[kind]


static func lesson(id: String) -> Dictionary:
	for kind in ["onboarding", "features", "tips"]:
		for item: Dictionary in group(kind):
			if item.get("id", "") == id:
				return item
	return {}


static func stage(id: String, sub: int, ctx: Dictionary = {}) -> String:
	var spec: Dictionary = lesson(id).get("stages", {}).get(str(sub), {})
	if spec.has("variants"):
		var variants: Dictionary = spec["variants"]
		var position := int(ctx.get("position", 8))
		var variant := "top3" if position <= 3 else "other"
		if spec.get("variant_by", "position") == "has_trophy":
			variant = "earned" if bool(ctx.get("has_trophy", false)) else "other"
		elif position == 1 and variants.has("winner"):
			variant = "winner"
		spec = variants[variant]
	var line := String(spec.get("text", ""))
	var args: Array = []
	for key: String in spec.get("args", []):
		args.append(ctx.get(key, ""))
	return line % args if not args.is_empty() else line


static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := {}
	for kind in ["onboarding", "features", "tips"]:
		var rows := group(kind)
		if rows.is_empty():
			errors.append("No lessons in " + kind)
		var previous := ""
		for item: Dictionary in rows:
			var id := String(item.get("id", ""))
			if id.is_empty() or ids.has(id):
				errors.append("Duplicate or empty lesson ID: " + id)
			ids[id] = true
			if kind == "onboarding":
				var trigger: Dictionary = item.get("trigger", {})
				if (previous == "" and trigger.get("when", "") != "new_game") or (previous != "" and trigger.get("after", "") != previous):
					errors.append(id + ": entry condition does not match manifest order")
				previous = id
			for field in ["purpose", "trigger", "completion", "stages"]:
				if not item.has(field) or not item[field]:
					errors.append("%s: missing %s" % [id, field])
			var stages: Dictionary = item.get("stages", {})
			for sub in range(stages.size()):
				if not stages.has(str(sub)):
					errors.append("%s: missing stage %d" % [id, sub])
			if item.get("completion", "") not in ["read_all", "revenue_upgrade_and_acknowledge", "engine_level_1_and_acknowledge", "acknowledge_result", "perform_action_and_acknowledge", "acknowledge_or_condition_resolved"]:
				errors.append(id + ": unknown completion contract")
			if item.has("action_metric") and item["action_metric"] not in ["gear_open_count", "driver_open_count"]:
				errors.append(id + ": unknown action metric")
	return errors
