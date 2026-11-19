extends Resource
## Một loại vật phẩm thưởng (kiểu ScriptableObject): mỗi loại có đúng MỘT icon, mọi nơi hiển thị đều lấy từ đây.
## Tệp .tres nằm ở data/reward_items/, tra cứu qua core/data/reward_items.gd.
@export var id: String = ""
@export var icon: Texture2D
## Khóa i18n của tên hiển thị (rỗng thì dùng id).
@export var name_key: String = ""
@export var tint: Color = Color.WHITE
