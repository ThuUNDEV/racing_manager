extends RefCounted
## Shared material construction; never changes data or saved cosmetics.
const MODELS := [
	preload("res://assets/models/race_car/pico.tscn"),
	preload("res://assets/models/race_car/nova.tscn"),
	preload("res://assets/models/race_car/apex.tscn"),
	preload("res://assets/models/race_car/titan.tscn"),
	preload("res://assets/models/race_car/zenith.tscn"),
]

## Race discipline is independent of the 1–5 Garage vehicle tier.
const CLASS_MODELS := {
	"rally": preload("res://assets/models/class_vehicles/rally.tscn"),
	"stock": preload("res://assets/models/class_vehicles/stock.tscn"),
	"bike": preload("res://assets/models/class_vehicles/bike.tscn"),
	"speed": preload("res://assets/models/class_vehicles/speed.tscn"),
	"monster": preload("res://assets/models/class_vehicles/monster.tscn"),
}

static func model_for_class(class_id: String, tier: int = 1) -> PackedScene:
	return CLASS_MODELS.get(class_id, MODELS[clampi(tier - 1, 0, MODELS.size() - 1)])

static func class_for_track(track_id: String) -> String:
	for cls: Dictionary in GameData.race_classes():
		if GameData.class_track(String(cls["id"])) == track_id:
			return String(cls["id"])
	return GameData.default_class_id()

static func coated_material(base: StandardMaterial3D, paint_id: String, canopy: bool = false) -> StandardMaterial3D:
	var p := GameData.paint(paint_id)
	if not p.has("epic"):
		return base
	var finish := ShaderMaterial.new()
	finish.shader = preload("res://ui/car_epic_finish.gdshader")
	var kind := 0
	if String(p["epic"]) == "paint":
		kind = {"epic_aurora": 1, "epic_solar": 2, "epic_midnight": 3}.get(paint_id, 4)
	finish.set_shader_parameter("finish", kind)
	finish.set_shader_parameter("canopy", canopy)
	var color := Color(String(p["color"]))
	if paint_id == "epic_sapphire":
		color = Color("27afe9")
	finish.set_shader_parameter("base_color", color)
	finish.set_shader_parameter("ink_color", Color(String(p.get("ink", "#ffffff"))))
	var coated := base.duplicate() as StandardMaterial3D
	coated.next_pass = finish
	return coated
