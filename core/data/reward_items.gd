extends RefCounted
## Danh mục vật phẩm thưởng. Thêm loại mới: tạo data/reward_items/<id>.tres rồi khai báo ở ITEMS.
## id trùng với id icon trong PackUi.rewards (gem, cash, standard_driver_pack...).
const ITEMS := {
	"gem": preload("res://data/reward_items/gem.tres"),
	"cash": preload("res://data/reward_items/cash.tres"),
	"standard_driver_pack": preload("res://data/reward_items/standard_driver_pack.tres"),
	"elite_driver_pack": preload("res://data/reward_items/elite_driver_pack.tres"),
	"standard_gear_pack": preload("res://data/reward_items/standard_gear_pack.tres"),
	"elite_gear_pack": preload("res://data/reward_items/elite_gear_pack.tres"),
	"crown": preload("res://data/reward_items/crown.tres"),
	"energy": preload("res://data/reward_items/energy.tres"),
	"research": preload("res://data/reward_items/research.tres"),
	"race_reward": preload("res://data/reward_items/race_reward.tres"),
}


static func has(id: String) -> bool:
	return ITEMS.has(id)


## Icon duy nhất của vật phẩm; null nếu id chưa có trong danh mục.
static func icon(id: String) -> Texture2D:
	return ITEMS[id].icon if ITEMS.has(id) else null


static func tint(id: String) -> Color:
	return ITEMS[id].tint if ITEMS.has(id) else Color.WHITE


## Tên hiển thị đã dịch; id nếu chưa có khóa.
static func item_name(id: String) -> String:
	if not ITEMS.has(id):
		return id
	var key: String = ITEMS[id].name_key
	return I18n.t(key) if key != "" and I18n.has(key) else id
