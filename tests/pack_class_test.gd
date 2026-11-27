extends SceneTree
## Pack mua một lần và nhiều class: xe Epic theo class chọn, coupon vào đúng cơ sở được chọn.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)

func coupon_total(state: Node) -> int:
	return int(state.driver_coupons.get("pro", 0)) + int(state.driver_coupons.get("allstar", 0)) + int(state.gear_coupons.get("standard", 0)) + int(state.gear_coupons.get("elite", 0))

func run() -> void:
	var state := root.get_node("GameState")
	state.SAVE_PATH = "user://tests/pack_class.json"
	state.BAK_PATH = "user://tests/pack_class.bak"
	state.TMP_PATH = "user://tests/pack_class.tmp"
	check(state.SAVE_PATH.contains("/tests/"), "Save isolation")
	GameData.reload()
	state.init_new_game()
	state.first_class_pending = false
	state.active = false
	state.set_process(false)
	check(state.dev_switch_class("rally") and state.dev_switch_class("racing"), "Mở Rally rồi về Racing")
	state.iap_target_class = "rally"
	check(state.grant_iap("epic_car_pico", "pack_class_epic"), "Giao xe Epic cho Rally")
	check(state.managed_class == "racing" and state.last_iap_grant["class"] == "rally", "Vẫn quản lý Racing, báo nhận vào Rally")
	check(not state.owned_cars.has("car_pico_epic"), "Racing không có xe Epic")
	state.dev_switch_class("rally")
	check(state.owned_cars.has("car_pico_epic"), "Rally có xe Epic")
	check(state.dev_switch_class("stock") and not state.owned_cars.has("car_pico_epic"), "Class khác không có xe Epic")
	check(state.load_game() == "ok" and not state.owned_cars.has("car_pico_epic"), "Nạp lại vẫn đúng class")
	state.dev_switch_class("rally")
	check(state.owned_cars.has("car_pico_epic"), "Nạp lại Rally vẫn có xe Epic")
	state.dev_switch_class("racing")
	check(state.iap_per_class("starter_1") and state.iap_per_class("epic_car_pico"), "Coupon và xe Epic đều gắn class")
	var racing_before := coupon_total(state)
	state.iap_target_class = "rally"
	check(state.grant_iap("starter_1", "pack_class_starter"), "Giao gói Tân binh cho Rally")
	check(state.managed_class == "racing" and state.last_iap_grant["class"] == "rally", "Vẫn quản lý Racing, báo nhận vào Rally")
	check(coupon_total(state) == racing_before, "Racing không nhận coupon")
	state.dev_switch_class("rally")
	check(coupon_total(state) > 0, "Rally nhận coupon")
	print("PACK_CLASS_TEST failures=", failures)
	quit()
