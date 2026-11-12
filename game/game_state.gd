extends Node

const BigNumber = preload("res://core/math/big_number.gd")
const MoneyCodec = preload("res://core/save/money_codec.gd")
## Autoload: tiền, nâng cấp, mùa giải, thưởng và save local.
## Vòng lặp đua liên tục (Design/10): countdown 3 giây -> đua theo thời gian -> chốt thưởng + lưu -> countdown kế tiếp.
## Tầng game điều phối vòng lặp (không phụ thuộc tab đang hiển thị); UI chỉ đọc trạng thái và gửi thao tác quản lý đội.

signal changed
signal race_started
signal race_finished(result: Dictionary)

var SAVE_PATH := _storage_path("save.json")
var BAK_PATH := _storage_path("save.bak")
var TMP_PATH := _storage_path("save.tmp")
const SAVE_VERSION := 7
const MAX_FRAME_GAP := 10.0  # giây; frame cách nhau hơn mức này thì coi là vắng mặt, không tính vào đua
const SAVE_RETRY_SEC := 3.0  # tự thử lưu lại khi chốt kết quả bị lỗi ghi
var business_tier: int = 0
const PROTOTYPE_TRACK := "track_circuit_b"  # track có hình học để RaceView vẽ (Design/08): đường dài, uốn lượn (circuit_a là oval ngắn dùng cho test); các track khác tới M3

# Giá trị mặc định trung tính: autoload không đọc dữ liệu cấu hình khi khởi tạo.
# BootFlow gọi init_new_game() rồi load_game() theo đúng thứ tự (Design/09 §6).
var coins: BigNumber = BigNumber.zero()
var income_remainder: BigNumber = BigNumber.zero()
var gems: int = 0
var levels: Dictionary = {"engine": 0, "tyre": 0, "chassis": 0, "gearbox": 0,
		"ticket": 0, "celebration": 0, "parking": 0, "grandstands": 0}
var season_number: int = 1
var stage_index: int = 0
var season_results: Array = []
var last_result: Dictionary = {}   # kết quả lượt gần nhất (xem lại; không điều khiển trạng thái đua)
var last_season: Dictionary = {}   # tổng kết mùa gần nhất (xem lại ở tab Giải)
var records: Dictionary = {}       # "track|thời lượng" -> quãng đường xa nhất
var processed_rewards: Dictionary = {}
var last_daily_day: int = -1
var last_accrual_utc: float = 0.0
var saved_online_rate: BigNumber = BigNumber.zero()
var save_revision: int = 0
var race_counter: int = 0
var active_car_id: String = ""
var active_driver_id: String = "driver_an"

var offline_report: Dictionary = {}  # tạm thời, chỉ để UI hiển thị
var load_error: String = ""
var save_blocked: bool = false
## Chỉ bật khi loading bàn giao sang gameplay: trước đó không cộng tiền online, không autosave.
var active: bool = false
## Giả lập lỗi ghi save (kiểm thử đường lỗi BOOT_WRITE).
var simulate_write_failure: bool = false
var _save_timer: float = 0.0

# Economy/progression state. Only successful writes are published as transactions.
var unlocked_tier: int = 0
var owned_cars: Dictionary = {}
var owned_drivers: Array = ["driver_an"]
var car_levels: Dictionary = {}
var gear_owned: Dictionary = {}        # gear_id -> {level, shards}; tập sở hữu duy nhất theo mẫu (Design/14 §7)
var gear_coupons: Dictionary = {"standard": 0, "elite": 0}
var gear_open_count: int = 0
var last_gear_result: Array = []       # kết quả lần mở gói gần nhất: [{id, is_new, shards}]
# Gacha tay đua (data/driver_gacha.json), mô phỏng cơ chế gói phụ kiện: trùng → mảnh riêng của tay đua, nâng level chỉ tốn mảnh.
var driver_progress: Dictionary = {}   # driver_id -> {level, shards}
var driver_coupons: Dictionary = {"pro": 0, "allstar": 0}
var driver_pity: Dictionary = {"pro": 0, "allstar": 0}  # số lượt liên tiếp chưa ra bậc bảo đảm, theo gói
var driver_open_count: int = 0
var driver_pack_new: int = 0           # số tay đua nhận từ gói (không tính vào bậc giá tuyển bằng SP)
var last_driver_result: Array = []     # [{id, is_new, shards, pity}]
var garage_cosmetics: Dictionary = {}  # car_id -> {paint_id, decal_id}; thiếu = mặc định (Design/15 §8)
var revenue_history: Dictionary = {}
var scout_points: int = 0
var completed_seasons: int = 0
var season_history: Array = []
var _legacy_season: bool = false
var expansion_requested: bool = false
var _pending_commit: Dictionary = {}
var _pending_result: Dictionary = {}
var _failed_checkpoint: Dictionary = {}
var _rate_key: String = ""
var _rate_value: BigNumber = BigNumber.zero()
var _income_micro_fraction: float = 0.0
var _resume_pending: bool = false

# --- Vòng lặp đua ---
## "idle" (chưa kích hoạt) | "countdown" | "racing" | "save_error" (chốt kết quả nhưng lưu thất bại, chờ thử lại)
var phase: String = "idle"
var countdown_left: float = 0.0
var sim: TrafficSim = null         # grid xem trước khi countdown, cuộc đua đang chạy khi racing
var race_cfg: Dictionary = {}      # cấu hình của lượt (chốt khi bắt đầu countdown)
var race_snapshot: Dictionary = {} # chỉ số/xe/tay đua của lượt đang chạy (chốt lúc xuất phát)
var time_scale: float = 1.0        # chỉ để thử (x4); countdown không bị rút ngắn
var suspended: bool = false
## UI đang hiện bảng tổng kết lượt vừa xong: dừng countdown/đua tới khi người chơi đóng bảng (thu nhập vẫn chạy).
var result_hold: bool = false
var results_serial: int = 0        # tăng mỗi khi có kết quả lượt mới
var _race_seed: int = 0
var _sim_accum: float = 0.0
var _clock_usec: int = 0           # mốc đồng hồ monotonic (µs) của frame trước; 0 = chưa đặt/đang tạm dừng
var _retry_timer: float = 0.0
var _loaded_checkpoint: Dictionary = {}


static func _storage_path(file: String) -> String:
	# Headless tests must never delete or migrate the player's real save.
	for argument in OS.get_cmdline_args():
		var normalized := argument.replace("\\", "/")
		if (normalized.contains("/tests/") or normalized.begins_with("tests/")) and normalized.ends_with(".gd"):
			return "user://tests/" + normalized.get_file().get_basename() + "/" + file
	if "--economy-test" in OS.get_cmdline_user_args():
		return "user://tests/economy_preview/" + file
	return "user://" + file


func _exit_tree() -> void:
	Pricing.reset_cache()
	BigNumber.release_parser()


func _process(delta: float) -> void:
	if _resume_pending:
		_retry_timer -= delta
		if _retry_timer <= 0.0:
			if settle_offline():
				_resume_pending = false
				suspended = false
				changed.emit()
			_retry_timer = SAVE_RETRY_SEC
	if not active or suspended:
		_clock_usec = 0  # quay lại sẽ không tính khoảng vắng mặt
		return
	if phase == "save_error":
		advance(delta)
		return
	var step := _real_step()
	tick_income(step)
	last_accrual_utc = Time.get_unix_time_from_system()
	_save_timer += delta
	if _save_timer >= 10.0:
		_save_timer = 0.0
		save_game()
	advance(step)


## Thời gian thật trôi qua kể từ frame trước, lấy từ đồng hồ monotonic của hệ điều hành (không phụ thuộc delta của engine:
## --fixed-fps, giật lag, delta bị chia/giới hạn đều không làm đua chậm hay nhanh hơn giờ ngoài đời).
## Khoảng nghỉ > MAX_FRAME_GAP là máy ngủ/treo hẳn, không tính vào lượt (giống ra nền, Design/10 §ra nền).
func _real_step() -> float:
	var now := Time.get_ticks_usec()
	var dt := 0.0 if _clock_usec == 0 else float(now - _clock_usec) / 1000000.0
	_clock_usec = now
	if dt > MAX_FRAME_GAP:
		if not settle_offline():
			suspended = true
			_resume_pending = true
			_retry_timer = SAVE_RETRY_SEC
		return 0.0
	return dt


func _notification(what: int) -> void:
	if not active:
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		set_suspended(true)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		set_suspended(false)


## Ra nền: dừng countdown/đua và lưu checkpoint; quay lại thì tiếp tục phần còn lại (không tính thời gian vắng mặt).
func set_suspended(on: bool) -> void:
	if suspended == on:
		return
	if on:
		last_accrual_utc = Time.get_unix_time_from_system()
		suspended = true
		save_game()
	else:
		if phase != "save_error" and not settle_offline():
			_resume_pending = true
			_retry_timer = SAVE_RETRY_SEC
			return
		suspended = false
	_clock_usec = 0
	changed.emit()


# ---------- Khởi động ----------

## Trạng thái của người chơi mới. Cần GameData đã nạp được (BootFlow bước B).
func init_new_game() -> void:
	coins = Balance.start_coins()
	income_remainder = BigNumber.zero()
	gems = Balance.start_gems()
	levels = {"engine": 0, "tyre": 0, "chassis": 0, "gearbox": 0,
		"ticket": 0, "celebration": 0, "parking": 0, "grandstands": 0}
	season_number = 1
	stage_index = 0
	season_results = []
	last_result = {}
	last_season = {}
	records = {}
	phase = "idle"
	sim = null
	race_cfg = {}
	race_snapshot = {}
	countdown_left = 0.0
	_loaded_checkpoint = {}
	_sim_accum = 0.0
	suspended = false
	processed_rewards = {}
	last_daily_day = -1
	last_accrual_utc = 0.0
	saved_online_rate = Balance.base_rate()
	save_revision = 0
	race_counter = 0
	active_car_id = GameData.starter_car_id()
	active_driver_id = "driver_an"
	offline_report = {}
	load_error = ""
	save_blocked = false
	business_tier = 0
	unlocked_tier = 0
	owned_cars = {active_car_id: true}
	owned_drivers = ["driver_an"]
	car_levels = {active_car_id: _part_levels()}
	garage_cosmetics = {}
	gear_owned = {}
	gear_coupons = {"standard": 0, "elite": 0}
	gear_open_count = 0
	last_gear_result = []
	driver_progress = {}
	driver_coupons = {"pro": 0, "allstar": 0}
	driver_pity = {"pro": 0, "allstar": 0}
	driver_open_count = 0
	driver_pack_new = 0
	last_driver_result = []
	revenue_history = {}
	scout_points = 0
	completed_seasons = 0
	season_history = []
	_legacy_season = false
	expansion_requested = false
	_pending_commit = {}
	_pending_result = {}
	_failed_checkpoint = {}
	_rate_key = ""
	_income_micro_fraction = 0.0
	_resume_pending = false


## Bàn giao: từ đây gameplay mới được cộng thu nhập online và tự lưu.
## Mốc online mới đặt tại đây; khoảng trước đó đã được quyết toán offline đúng một lần.
func activate() -> void:
	if active:
		return
	last_accrual_utc = Time.get_unix_time_from_system()
	_save_timer = 0.0
	active = true
	_resume_loop()
	changed.emit()


# ---------- Kinh tế ----------

func online_rate() -> BigNumber:
	var key := str(business_tier) + str(levels)
	if key != _rate_key:
		_rate_key = key
		_rate_value = Pricing.revenue_rate(levels, business_tier)
	return _rate_value


func tick_income(delta: float) -> void:
	if delta <= 0.0 or not is_finite(delta) or suspended or phase == "save_error":
		return
	_income_micro_fraction += delta * 1000000.0
	var micros := int(floor(_income_micro_fraction + 0.000001))
	_income_micro_fraction = maxf(0.0, _income_micro_fraction - micros)
	income_remainder = income_remainder.add(online_rate().multiply_ratio(micros, 1000000))
	var whole := income_remainder.floor_number()
	coins = coins.add(whole)
	income_remainder = income_remainder.subtract_checked(whole)


func level_of(kind: String) -> int:
	return int(levels.get(kind, 0))


func cost_of(kind: String) -> BigNumber:
	if kind in Balance.REVENUE:
		return Pricing.revenue_cost(kind, level_of(kind), business_tier)
	if kind in Balance.PARTS:
		return Pricing.part_cost(int(GameData.car(active_car_id)["class"]) - 1, level_of(kind), kind)
	return BigNumber.zero()


func upgrade_state(kind: String) -> String:
	if not levels.has(kind):
		return "invalid"
	if save_blocked or phase == "save_error":
		return "save_error"
	if level_of(kind) >= Balance.max_level():
		return "maxed"
	return "short" if coins.compare(cost_of(kind)) < 0 else "ok"


func applies_next_race(kind: String) -> bool:
	return phase == "racing" and kind in Balance.PARTS


func _part_levels() -> Dictionary:
	var out := {}
	for kind in Balance.PARTS:
		out[kind] = level_of(kind)
	return out


func _restore_transaction(before: Dictionary) -> void:
	_apply(before)
	_loaded_checkpoint = {}  # live sim/phase are not restarted by a rollback


func _cost_at(kind: String, level: int, car_id: String = "") -> BigNumber:
	if kind in Balance.REVENUE:
		return Pricing.revenue_cost(kind, level, business_tier)
	var cid := active_car_id if car_id == "" else car_id
	return Pricing.part_cost(int(GameData.car(cid)["class"]) - 1, level, kind)


## Kế hoạch mua tối đa `amount` cấp liên tiếp (amount <= 0: ×Max theo số tiền hiện có).
## Tổng cộng từng cấp đã làm tròn (không dùng công thức tổng hình học). Trả {"count": int, "cost": BigNumber}.
func plan_buy(kind: String, amount: int, car_id: String = "") -> Dictionary:
	var total := BigNumber.zero()
	var count := 0
	var lv := level_of(kind) if car_id == "" else car_level(car_id, kind)
	var limit := Balance.max_level() - lv if amount <= 0 else mini(amount, Balance.max_level() - lv)
	for i in limit:
		var next := total.add(_cost_at(kind, lv + i, car_id))
		if coins.compare(next) < 0:
			break
		total = next
		count += 1
	return {"count": count, "cost": total}


func buy(kind: String) -> bool:
	return buy_many(kind, 1)


## Mua tối đa `amount` cấp (<= 0: hết mức có thể) trong khả năng tài chính; một lần lưu.
func buy_many(kind: String, amount: int) -> bool:
	if upgrade_state(kind) != "ok":
		return false
	var plan := plan_buy(kind, amount)
	var count: int = plan["count"]
	if count <= 0:
		return false
	var before := _save_data()
	coins = coins.subtract_checked(plan["cost"])
	levels[kind] = level_of(kind) + count
	car_levels[active_car_id] = _part_levels()
	saved_online_rate = online_rate()
	if not save_game():
		_restore_transaction(before)
		return false
	if phase == "countdown" and kind in Balance.PARTS:
		_rebuild_preview()
	changed.emit()
	return true


# ---------- Garage: nâng cấp theo car_id tường minh và ngoại hình (Design/15) ----------

## Cấp bộ phận của một xe: xe đang dùng đọc từ `levels` (nguồn sống), xe dự bị đọc từ `car_levels`.
func car_level(car_id: String, kind: String) -> int:
	if car_id == active_car_id:
		return level_of(kind)
	return int((car_levels.get(car_id, {}) as Dictionary).get(kind, 0))


## Chỉ số bộ phận của một xe bất kỳ ở cấp `level`.
func car_part_stat(car_id: String, kind: String, level: int) -> float:
	var base: int = int(GameData.car(car_id)["base"][Balance.PART_KEY[kind]])
	return base + Pricing.part_stat_per_level(kind) * level


## Trạng thái nâng bộ phận của xe `car_id` (không cần chọn xe đó): "ok" | "short" | "maxed" | "save_error" | "invalid".
func car_upgrade_state(car_id: String, kind: String) -> String:
	if not owned_cars.has(car_id) or not kind in Balance.PARTS:
		return "invalid"
	if save_blocked or phase == "save_error":
		return "save_error"
	var lv := car_level(car_id, kind)
	if lv >= Balance.max_level():
		return "maxed"
	return "short" if coins.compare(_cost_at(kind, lv, car_id)) < 0 else "ok"


## Mua tối đa `amount` cấp (<= 0: ×Max) cho xe `car_id` mà không đổi xe đang dùng. Một lần lưu, lỗi lưu thì hoàn tác.
func buy_many_for(car_id: String, kind: String, amount: int) -> bool:
	if car_id == active_car_id:
		return buy_many(kind, amount)
	if car_upgrade_state(car_id, kind) != "ok":
		return false
	var plan := plan_buy(kind, amount, car_id)
	var count: int = plan["count"]
	if count <= 0:
		return false
	var before := _save_data()
	coins = coins.subtract_checked(plan["cost"])
	var lv: Dictionary = car_levels[car_id]
	lv[kind] = int(lv.get(kind, 0)) + count
	if not save_game():
		_restore_transaction(before)
		return false
	changed.emit()
	return true


## Ngoại hình đã lưu của xe (luôn hợp lệ: id lạ/thiếu quay về mặc định).
func cosmetics_of(car_id: String) -> Dictionary:
	var c: Dictionary = garage_cosmetics.get(car_id, {})
	var paint_id := String(c.get("paint_id", ""))
	var decal_id := String(c.get("decal_id", ""))
	return {
		"paint_id": paint_id if not GameData.paint(paint_id).is_empty() else GameData.default_paint_id(),
		"decal_id": decal_id if not GameData.decal(decal_id).is_empty() else GameData.default_decal_id(),
	}


func _clean_cosmetics(raw: Variant) -> Dictionary:
	var out := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for id in raw:
		if GameData.car(String(id)).is_empty() or typeof(raw[id]) != TYPE_DICTIONARY:
			continue
		out[String(id)] = cosmetics_of_dict(raw[id])
	return out


func cosmetics_of_dict(c: Dictionary) -> Dictionary:
	var p := str(c.get("paint_id", ""))  # str(): save hỏng có thể chứa số/null thay vì chuỗi
	var d := str(c.get("decal_id", ""))
	return {
		"paint_id": p if not GameData.paint(p).is_empty() else GameData.default_paint_id(),
		"decal_id": d if not GameData.decal(d).is_empty() else GameData.default_decal_id(),
	}


## Lưu ngoại hình cho xe đang sở hữu. Miễn phí, không đổi chỉ số; lượt đã có snapshot giữ ngoại hình cũ.
func set_cosmetics(car_id: String, paint_id: String, decal_id: String) -> bool:
	if not owned_cars.has(car_id) or GameData.paint(paint_id).is_empty() or GameData.decal(decal_id).is_empty():
		return false
	if phase == "save_error" or save_blocked:
		return false
	var before := _save_data()
	garage_cosmetics[car_id] = {"paint_id": paint_id, "decal_id": decal_id}
	if not save_game():
		_restore_transaction(before)
		return false
	changed.emit()
	return true


## Ngoại hình xe người chơi đang hiển thị trong đua: snapshot khi đang đua, còn lại là cấu hình lượt kế.
func race_cosmetics() -> Dictionary:
	if phase == "racing" and not race_snapshot.is_empty():
		return cosmetics_of_dict({"paint_id": race_snapshot.get("paint_id", ""), "decal_id": race_snapshot.get("decal_id", "")})
	return cosmetics_of(active_car_id)


func car_unlocked(id: String) -> bool:
	var car := GameData.car(id)
	return not car.is_empty() and int(car["entry_tier"]) <= unlocked_tier


func buy_car(id: String) -> bool:
	if phase == "save_error" or save_blocked or owned_cars.has(id) or not car_unlocked(id):
		return false
	var price := Pricing.car_price(id)
	if coins.compare(price) < 0:
		return false
	var before := _save_data()
	coins = coins.subtract_checked(price)
	owned_cars[id] = true
	car_levels[id] = {"engine": 0, "tyre": 0, "chassis": 0, "gearbox": 0}
	if not save_game():
		_restore_transaction(before)
		return false
	changed.emit()
	return true


func select_car(id: String) -> bool:
	if not owned_cars.has(id) or phase == "save_error" or save_blocked:
		return false
	if int(GameData.car(id)["class"]) < int(GameData.league(business_tier)["min_car_class"]):
		return false
	var before := _save_data()
	car_levels[active_car_id] = _part_levels()
	active_car_id = id
	for kind in Balance.PARTS:
		levels[kind] = int(car_levels[id].get(kind, 0))
	if not save_game():
		_restore_transaction(before)
		return false
	if phase == "countdown":
		_rebuild_preview()
	changed.emit()
	return true


func driver_unlocked(id: String) -> bool:
	var d := GameData.driver(id)
	if d.is_empty():
		return false
	var unlock: Dictionary = d["unlock"]
	return completed_seasons >= int(unlock.get("count", 0)) and business_tier >= int(unlock.get("league", 0))


## Thứ tự lần tuyển kế bằng SP: tay đua nhận từ gói không làm đắt thêm giá tuyển.
func recruit_index() -> int:
	return maxi(0, owned_drivers.size() - 1 - driver_pack_new)


func recruit_driver(id: String) -> bool:
	if not driver_unlocked(id) or id in owned_drivers or phase == "save_error" or save_blocked:
		return false
	var sp := Pricing.scout_sp_cost(recruit_index())
	var price := Pricing.scout_coin_cost(id)
	if scout_points < sp or coins.compare(price) < 0:
		return false
	var before := _save_data()
	coins = coins.subtract_checked(price)
	scout_points -= sp
	owned_drivers.append(id)
	if not save_game():
		_restore_transaction(before)
		return false
	changed.emit()
	return true


func select_driver(id: String) -> bool:
	if not id in owned_drivers or phase == "save_error" or save_blocked:
		return false
	var before := _save_data()
	active_driver_id = id
	if not save_game():
		_restore_transaction(before)
		return false
	if phase == "countdown":
		_rebuild_preview()
	changed.emit()
	return true


func expansion_state() -> String:
	if business_tier >= GameData.leagues().size() - 1:
		return "complete"
	if phase == "save_error" or save_blocked:
		return "save_error"
	if unlocked_tier <= business_tier:
		return "points"
	for kind in Balance.REVENUE:
		if level_of(kind) < int(GameData.economy()["business"]["expansion_min_revenue_level"]):
			return "revenue"
	if int(GameData.car(active_car_id)["class"]) < int(GameData.league(business_tier + 1)["min_car_class"]):
		return "car"
	if coins.compare(Pricing.expansion_cost(business_tier)) < 0:
		return "short"
	return "ok"


func request_expansion() -> bool:
	if expansion_state() != "ok":
		return false
	var before := _save_data()
	expansion_requested = true
	if not save_game():
		_restore_transaction(before)
		return false
	if phase != "racing":
		if _commit_expansion():
			begin_countdown()
	changed.emit()
	return true


func _commit_expansion() -> bool:
	if not expansion_requested:
		return false
	var before := _save_data()
	expansion_requested = false
	if expansion_state() != "ok":
		if not save_game():
			_restore_transaction(before)
		return false
	coins = coins.subtract_checked(Pricing.expansion_cost(business_tier))
	var old_revenue := {}
	for kind in Balance.REVENUE:
		old_revenue[kind] = level_of(kind)
		levels[kind] = 0
	revenue_history[str(business_tier)] = old_revenue
	business_tier += 1
	var id := "business_open/%d" % business_tier
	if not processed_rewards.has(id):
		coins = coins.add(Pricing.opening_reserve(business_tier))
		gems += int(GameData.economy()["rewards"]["first_league_gems"])
		processed_rewards[id] = true
	if not season_results.is_empty():
		season_history.append({"season_number": season_number, "business_tier": business_tier - 1,
			"complete": false, "rows": season_results.duplicate(true)})
	season_number += 1
	stage_index = 0
	season_results = []
	saved_online_rate = online_rate()
	if not save_game():
		_restore_transaction(before)
		return false
	return true


## Chỉ số bộ phận = nền của xe đang dùng + hệ số riêng của bộ phận × cấp (economy.json: part_stat_per_level_by_part).
func part_stat(kind: String, level: int) -> float:
	var base: int = int(GameData.car(active_car_id)["base"][Balance.PART_KEY[kind]])
	return base + Pricing.part_stat_per_level(kind) * level


func _driver() -> Dictionary:
	return GameData.driver(active_driver_id)


## Sức mạnh hiển thị: trung bình 11 chỉ số xe + tay đua (thang giống chỉ số, ví dụ 40 = chuẩn giải đầu).
## Đang đua thì lấy chỉ số đã chốt lúc xuất phát (nâng cấp mới chỉ áp dụng từ lượt sau).
func power() -> int:
	var st: Dictionary = player_stats()
	if phase == "racing" and not race_snapshot.is_empty():
		st = race_snapshot["stats"]
	var sum := 0.0
	for k: String in st:
		sum += float(st[k])
	return int(round(sum / maxf(float(st.size()), 1.0)))


## ĐỘI CỦA BẠN: tổng 11 chỉ số xe + tay đua, luôn theo cấp hiện tại để nâng động cơ (hay bộ phận khác)
## thấy sức mạnh tăng ngay. Mô phỏng lượt đang chạy vẫn dùng chỉ số chốt lúc xuất phát (giữ tính xác định).
func team_power() -> float:
	var st: Dictionary = player_stats()
	var sum := 0.0
	for k: String in st:
		sum += float(st[k])
	return snappedf(sum, 0.1)


func player_stats() -> Dictionary:
	var b := driver_level_bonus(active_driver_id)  # 0 khi chưa nâng level: không đổi chỉ số gốc
	return {
		"S": float(part_stat("engine", level_of("engine"))),
		"H": float(part_stat("tyre", level_of("tyre"))),
		"B": float(part_stat("chassis", level_of("chassis"))),
		"A": float(part_stat("gearbox", level_of("gearbox"))),
		"P": float(int(_driver()["pace"])) + b,
		"T": float(int(_driver()["technique"])) + b,
		"C": float(int(_driver()["composure"])) + b,
		"L": float(int(_driver()["launch"])) + b,
		"R": float(int(_driver()["braking"])) + b,
		"K": float(int(_driver()["racecraft"])) + b,
		"E": float(int(_driver()["endurance"])) + b,
	}


# ---------- Vòng lặp đua và mùa giải ----------

func _make_sim(p_seed: int, stats: Dictionary, driver_id: String) -> TrafficSim:
	var t := TrafficSim.new()
	t.setup(p_seed, stats, business_tier, PROTOTYPE_TRACK, {
		"driver_id": driver_id,
		"duration": float(race_cfg["duration"]), "sprint_duration": float(race_cfg["sprint"]),
	})
	return t


## Bắt đầu hoặc phục hồi vòng lặp khi gameplay nhận quyền hoạt động (Design/10 §8).
func _resume_loop() -> void:
	var cp := _loaded_checkpoint
	_loaded_checkpoint = {}
	if not cp.is_empty() and _restore_checkpoint(cp):
		return
	begin_countdown()


func _cfg_valid(cfg: Variant) -> bool:
	return typeof(cfg) == TYPE_DICTIONARY and float((cfg as Dictionary).get("duration", 0.0)) > 0.0 \
		and float((cfg as Dictionary).get("sprint", -1.0)) >= 0.0


## Phục hồi từ checkpoint. Cuộc đua xác định theo seed nên chơi lại đúng số tick đã chạy cho cùng trạng thái.
func _restore_checkpoint(cp: Dictionary) -> bool:
	if not _cfg_valid(cp.get("cfg")):
		return false
	race_cfg = {"duration": float(cp["cfg"]["duration"]), "sprint": float(cp["cfg"]["sprint"])}
	_race_seed = int(cp.get("seed", 0))
	_sim_accum = 0.0
	var ph := String(cp.get("phase", ""))
	if ph == "countdown":
		countdown_left = clampf(float(cp.get("left", Balance.COUNTDOWN_SECONDS)), 0.0, float(Balance.COUNTDOWN_SECONDS))
		sim = _make_sim(_race_seed, player_stats(), active_driver_id)
		phase = "countdown"
		return true
	if ph == "racing" and typeof(cp.get("snapshot")) == TYPE_DICTIONARY:
		var snap: Dictionary = cp["snapshot"]
		var src: Variant = snap.get("stats", {})
		if typeof(src) != TYPE_DICTIONARY:
			return false
		var st: Dictionary = {}
		for k in ["S", "H", "B", "A", "P", "T", "C"]:
			if not (src as Dictionary).has(k):
				return false
			st[k] = float(src[k])
		for k in ["L", "R", "K", "E"]:  # chỉ số tay đua mới; checkpoint cũ không có thì sim dùng mặc định
			if (src as Dictionary).has(k):
				st[k] = float(src[k])
		race_snapshot = snap.duplicate(true)
		race_snapshot["stats"] = st
		race_snapshot["driver_id"] = String(snap.get("driver_id", active_driver_id))
		race_snapshot["car_id"] = String(snap.get("car_id", active_car_id))
		race_snapshot["paint_id"] = String(snap.get("paint_id", GameData.default_paint_id()))
		race_snapshot["decal_id"] = String(snap.get("decal_id", GameData.default_decal_id()))
		sim = _make_sim(_race_seed, st, String(race_snapshot["driver_id"]))
		var ticks := int(cp.get("ticks", 0))
		while sim.tick_count < ticks and not sim.finished:
			sim.step()
		phase = "racing"
		if sim.finished:
			_resolve()
		return true
	return false


## Tạo countdown cho lượt kế tiếp: chốt cấu hình lượt, đặt grid xem trước.
func begin_countdown() -> void:
	race_counter += 1
	race_cfg = {"duration": Balance.race_duration(PROTOTYPE_TRACK), "sprint": Balance.sprint_duration()}
	_race_seed = hash("race_%d_%d_%d" % [season_number, stage_index, race_counter])
	countdown_left = float(Balance.COUNTDOWN_SECONDS)
	_sim_accum = 0.0
	race_snapshot = {}
	sim = _make_sim(_race_seed, player_stats(), active_driver_id)
	phase = "countdown"
	changed.emit()


func _rebuild_preview() -> void:
	sim = _make_sim(_race_seed, player_stats(), active_driver_id)


## Xuất phát: snapshot chỉ số/xe/tay đua tại đúng thời điểm này (Design/10 §6).
func _start_race() -> void:
	race_snapshot = {"stats": player_stats(), "driver_id": active_driver_id, "car_id": active_car_id,
		"paint_id": cosmetics_of(active_car_id)["paint_id"], "decal_id": cosmetics_of(active_car_id)["decal_id"],
		"reward_rate": online_rate(), "reward_duration": float(race_cfg["duration"]) / maxf(time_scale, 0.001),
		"economy_version": 2, "business_tier": business_tier}
	sim = _make_sim(_race_seed, race_snapshot["stats"], active_driver_id)
	_sim_accum = 0.0
	phase = "racing"
	race_started.emit()
	changed.emit()


## Tiến vòng lặp theo thời gian gameplay đang hoạt động (gọi từ _process; test gọi trực tiếp).
func advance(delta: float) -> void:
	if suspended or result_hold or delta <= 0.0:
		return
	match phase:
		"countdown":
			countdown_left -= delta  # không nhân time_scale: tua nhanh không rút ngắn 3 giây
			if countdown_left <= 0.000001:
				countdown_left = 0.0
				_start_race()
		"racing":
			_sim_accum += delta * time_scale
			var guard := 0
			while not sim.finished and guard < 2000:
				var need := minf(sim.tick, sim.time_left())
				if _sim_accum < need - 0.000001:
					break
				sim.step()
				_sim_accum -= need
				guard += 1
			if sim.finished:
				_resolve()
		"save_error":
			_retry_timer -= delta
			if _retry_timer <= 0.0:
				retry_save()


## Phần lẻ của tick tiếp theo (0..1) để vẽ nội suy mượt.
func render_alpha() -> float:
	if phase != "racing" or sim == null or sim.finished:
		return 1.0
	return clampf(_sim_accum / sim.tick, 0.0, 1.0)


## Chốt kết quả, phát thưởng đúng một lần (reward id), chuyển chặng/mùa rồi ghi save; chỉ khi lưu xong mới tạo countdown kế tiếp.
func _resolve() -> void:
	var before := _save_data()
	_failed_checkpoint = before["checkpoint"]
	_pending_result = _compute_result(sim)
	last_result = _pending_result
	_pending_commit = _save_data()
	_pending_commit["checkpoint"] = {}
	_restore_transaction(before)
	phase = "save_error"
	retry_save()


func retry_save() -> bool:
	if phase != "save_error" or _pending_commit.is_empty():
		return false
	if save_game(_pending_commit):
		var result := _pending_result
		_pending_commit["save_revision"] = save_revision
		_apply(_pending_commit)
		_loaded_checkpoint = {}
		_pending_commit = {}
		_pending_result = {}
		_failed_checkpoint = {}
		phase = "idle"
		results_serial += 1
		race_finished.emit(result)
		_commit_expansion()
		begin_countdown()
		return true
	_retry_timer = SAVE_RETRY_SEC
	changed.emit()
	return false


func _compute_result(s_: TrafficSim) -> Dictionary:
	var rk: Array = s_.ranking()
	var pos := 1
	var rows: Array = []
	for i in rk.size():
		var c: TrafficSim.Car = rk[i]
		if c.is_player:
			pos = i + 1
		rows.append({
			"position": i + 1, "name": c.driver_name, "number": c.number, "is_player": c.is_player,
			"distance": s_.distance_of(c), "laps": c.laps_done, "id": c.id,
		})
	var player: TrafficSim.Car = s_.player_car()
	var points := Balance.race_points(pos)
	var rate: BigNumber = race_snapshot.get("reward_rate", online_rate())
	var economic_duration := float(race_snapshot.get("reward_duration", s_.duration))
	var exposure := Pricing.race_exposure(rate, economic_duration)
	var money := Pricing.race_money(pos, rate, economic_duration)
	# Legacy in-flight races keep their old reward table once, after migration.
	if int(race_snapshot.get("economy_version", 1)) < 2:
		money = BigNumber.from_int(int(GameData.economy()["race_rewards"][pos - 1][1]))
	var stage_no := stage_index + 1
	var granted := BigNumber.zero()
	var rid := "race/s%d/st%d" % [season_number, stage_no]
	if not processed_rewards.has(rid):
		processed_rewards[rid] = true
		coins = coins.add(money)
		granted = money
	scout_points += Pricing.scout_points(points)
	season_results.append({"position": pos, "points": points, "money": granted, "exposure": exposure})
	stage_index += 1

	var dist := s_.distance_of(player)
	var rec_key := "%s|%s" % [PROTOTYPE_TRACK, str(snappedf(s_.duration, 0.001))]
	var new_record := dist > float(records.get(rec_key, 0.0)) + 0.001
	if new_record:
		records[rec_key] = dist

	var res := {
		"stage": stage_no, "position": pos, "points": points, "money": granted,
		"distance": dist, "laps": player.laps_done, "duration": s_.duration, "rows": rows,
		"errors": player.errors, "error_loss": player.error_loss, "overtakes": player.overtakes,
		"record": float(records.get(rec_key, dist)), "new_record": new_record,
		"season_done": false, "season_number": season_number,
	}
	if stage_index >= Balance.stages():
		var total := 0
		for r in season_results:
			total += int(r["points"])
		var season_exposure := BigNumber.zero()
		for row in season_results:
			season_exposure = season_exposure.add(row.get("exposure", BigNumber.zero()))
		var completion := Pricing.completion_reward(season_exposure)
		if _legacy_season:
			completion = BigNumber.from_int(150)  # historical prototype was league 0
		_legacy_season = false
		var cid := "season/%d/completion" % season_number
		var cgranted := BigNumber.zero()
		if not processed_rewards.has(cid):
			processed_rewards[cid] = true
			coins = coins.add(completion)
			cgranted = completion
		completed_seasons += 1
		var first_season_id := "first_season/%d" % business_tier
		if not processed_rewards.has(first_season_id):
			processed_rewards[first_season_id] = true
			gems += int(GameData.economy()["rewards"]["first_season_gems"])
		if total >= Balance.promote_points():
			unlocked_tier = mini(GameData.leagues().size() - 1, maxi(unlocked_tier, business_tier + 1))
		res["season_done"] = true
		res["season_points"] = total
		res["completion_reward"] = cgranted
		res["qualified"] = total >= Balance.promote_points()
		res["season_rows"] = season_results.duplicate(true)
		last_season = res.duplicate(true)
		# Tự chuyển mùa mới, không chờ nút (Design/10 §5). Prototype chỉ có giải Tập sự nên thăng hạng chỉ được báo.
		season_number += 1
		stage_index = 0
		season_results = []
	return res


# ---------- Quà ngày ----------

func _today() -> int:
	return int(floor(Time.get_unix_time_from_system() / 86400.0))


func daily_available() -> bool:
	return last_daily_day != _today()


## Gói gem giả lập (chưa có IAP thật): danh sách lấy từ economy.json "mock_gem_packs".
func mock_gem_packs() -> Array:
	return GameData.economy().get("mock_gem_packs", [])


## Mua giả lập gói gem thứ `index`: cộng gem ngay, không qua store. Lưu lỗi thì không đổi gì.
func mock_buy_gems(index: int) -> bool:
	var packs := mock_gem_packs()
	if index < 0 or index >= packs.size() or save_blocked or phase == "save_error":
		return false
	var amount := int(packs[index]["gems"])
	if amount <= 0:
		return false
	var payload := _save_data()
	payload["gems"] = gems + amount
	if not save_game(payload):
		return false
	gems += amount
	changed.emit()
	return true


func claim_daily() -> bool:
	if not daily_available() or phase == "save_error" or save_blocked:
		return false
	var before := _save_data()
	last_daily_day = _today()
	coins = coins.add(Pricing.daily_gift(online_rate()))
	gems += int(GameData.economy()["rewards"]["daily_gems"])
	if not save_game():
		_restore_transaction(before)
		return false
	changed.emit()
	return true


# ---------- Trang bị / phụ kiện (Design/14) ----------
# Sở hữu phụ kiện = tăng sức mạnh toàn đội (không lắp/tháo). Trùng → mảnh riêng của mẫu đó; nâng level chỉ tốn mảnh.

func gear_total() -> int:
	return GameData.gear_items().size()


func gear_owned_count() -> int:
	return gear_owned.size()


func gear_has(id: String) -> bool:
	return gear_owned.has(id)


func gear_level(id: String) -> int:
	return int((gear_owned.get(id, {}) as Dictionary).get("level", 0))


func gear_shards(id: String) -> int:
	return int((gear_owned.get(id, {}) as Dictionary).get("shards", 0))


func gear_max_level(id: String) -> int:
	return int(GameData.gear_config(id).get("max_level", 0))


## Chỉ số kiếm/khiên của mẫu ở một level (bảng cấu hình). Ngoài bảng → 0.
func gear_stats_at(id: String, level: int) -> Dictionary:
	var stats: Array = GameData.gear_config(id).get("stats_by_level", [])
	if level < 0 or level >= stats.size():
		return {"attack": 0, "defense": 0}
	return {"attack": int(stats[level]["attack"]), "defense": int(stats[level]["defense"])}


## Mảnh cần để lên level kế; -1 khi đã tối đa hoặc chưa sở hữu.
func gear_upgrade_cost(id: String) -> int:
	if not gear_has(id):
		return -1
	var lv := gear_level(id)
	if lv >= gear_max_level(id):
		return -1
	var table: Array = GameData.gear_config(id).get("level_up_shards", [])
	return int(table[lv]) if lv < table.size() else -1


## Bonus kiếm/khiên toàn đội: tổng các mẫu sở hữu theo level hiện tại.
## Chưa nối vào mô phỏng đua: game gốc chưa có tooltip kiếm/khiên (Design/14 §3.1).
func gear_bonus() -> Dictionary:
	var a := 0
	var d := 0
	for id: String in gear_owned.keys():
		var st := gear_stats_at(id, gear_level(id))
		a += int(st["attack"])
		d += int(st["defense"])
	return {"attack": a, "defense": d}


func _gear_blocked() -> bool:
	return phase == "save_error" or save_blocked


## Cách trả cho một lần mở: đủ coupon đúng loại thì tiêu coupon (1 coupon = 1 lượt), nếu không thì gem.
## Không trộn coupon với gem trong cùng một lần mở; giao diện hiển thị rõ phương thức.
func gear_payment(pack_id: String, count: int) -> Dictionary:
	var pack := GameData.gear_pack(pack_id)
	if pack.is_empty() or not (count == 1 or count == 10):
		return {}
	var kind := String(pack["coupon"])
	if int(gear_coupons.get(kind, 0)) >= count:
		return {"method": "coupon", "kind": kind, "amount": count}
	return {"method": "gem", "amount": int(pack["price_x1"] if count == 1 else pack["price_x10"])}


func gear_can_afford(pack_id: String, count: int) -> bool:
	var pay := gear_payment(pack_id, count)
	if pay.is_empty() or _gear_blocked():
		return false
	return pay["method"] == "coupon" or gems >= int(pay["amount"])


func _gear_pick(pack: Dictionary, rng: RandomNumberGenerator) -> String:
	var tiers: Dictionary = pack["tiers"]
	var keys: Array = tiers.keys()
	keys.sort()
	var roll := rng.randf() * 100.0
	var rarity: String = keys[keys.size() - 1]
	var acc := 0.0
	for k: String in keys:
		acc += float(tiers[k])
		if roll < acc:
			rarity = k
			break
	var pool: Array = []
	for it: Dictionary in GameData.gear_items():
		if it["rarity"] == rarity:
			pool.append(String(it["id"]))
	return pool[rng.randi() % pool.size()]


## Mở gói: trừ coupon/gem, nhận phụ kiện, ghi kết quả — một giao dịch, lỗi lưu thì hoàn tác toàn bộ.
## Trong cùng một lần x10, mẫu mới xuất hiện rồi lặp lại thì lần sau tính là trùng.
func open_gear_pack(pack_id: String, count: int, rng: RandomNumberGenerator = null) -> Dictionary:
	if not gear_can_afford(pack_id, count):
		return {}
	var pack := GameData.gear_pack(pack_id)
	var pay := gear_payment(pack_id, count)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var before := _save_data()
	if pay["method"] == "coupon":
		gear_coupons[pay["kind"]] = int(gear_coupons[pay["kind"]]) - count
	else:
		gems -= int(pay["amount"])
	var results: Array = []
	for i in count:
		var id := _gear_pick(pack, rng)
		if gear_owned.has(id):
			var add := int(GameData.gear_config(id).get("duplicate_shards", 0))
			gear_owned[id]["shards"] = gear_shards(id) + add
			results.append({"id": id, "is_new": false, "shards": add})
		else:
			gear_owned[id] = {"level": int(GameData.gear_config(id).get("initial_level", 0)), "shards": 0}
			results.append({"id": id, "is_new": true, "shards": 0})
	gear_open_count += count
	last_gear_result = results
	if not save_game():
		_restore_transaction(before)
		return {}
	changed.emit()
	return {"payment": pay, "results": results}


## Nâng level bằng mảnh của chính mẫu: trừ đúng ngưỡng, giữ mảnh dư, không đụng coins/gem/coupon/mẫu khác.
func upgrade_gear(id: String) -> bool:
	var need := gear_upgrade_cost(id)
	if need < 0 or gear_shards(id) < need or _gear_blocked():
		return false
	var before := _save_data()
	gear_owned[id]["shards"] = gear_shards(id) - need
	gear_owned[id]["level"] = gear_level(id) + 1
	if not save_game():
		_restore_transaction(before)
		return false
	changed.emit()
	return true


## Cấp coupon (nguồn nhận coupon của game gốc chưa xác minh; dùng cho test/debug/sự kiện sau này).
func grant_gear_coupons(kind: String, amount: int) -> bool:
	if not GameData.gear_coupon_types().has(kind) or amount <= 0 or _gear_blocked():
		return false
	var before := _save_data()
	gear_coupons[kind] = int(gear_coupons.get(kind, 0)) + amount
	if not save_game():
		_restore_transaction(before)
		return false
	changed.emit()
	return true


## Làm sạch dữ liệu phụ kiện từ save: id lạ bị bỏ; level ngoài cấu hình bị chặn lại.
func _apply_gear(d: Dictionary) -> void:
	gear_owned = {}
	var raw: Variant = d.get("gear_owned", {})
	if typeof(raw) == TYPE_DICTIONARY:
		for id in raw:
			if GameData.gear_item(String(id)).is_empty() or typeof(raw[id]) != TYPE_DICTIONARY:
				continue
			var cfg := GameData.gear_config(String(id))
			gear_owned[String(id)] = {
				"level": clampi(int(raw[id].get("level", cfg.get("initial_level", 0))), int(cfg.get("initial_level", 0)), int(cfg.get("max_level", 0))),
				"shards": maxi(0, int(raw[id].get("shards", 0))),
			}
	gear_coupons = {"standard": 0, "elite": 0}
	var rc: Variant = d.get("gear_coupons", {})
	if typeof(rc) == TYPE_DICTIONARY:
		for k in gear_coupons.keys():
			gear_coupons[k] = maxi(0, int(rc.get(k, 0)))
	gear_open_count = int(d.get("gear_open_count", 0))
	last_gear_result = []
	var lr: Variant = d.get("last_gear_result", [])
	if typeof(lr) == TYPE_ARRAY:
		for e in lr:
			if typeof(e) == TYPE_DICTIONARY and not GameData.gear_item(String(e.get("id", ""))).is_empty():
				last_gear_result.append({"id": String(e["id"]), "is_new": bool(e.get("is_new", false)), "shards": int(e.get("shards", 0))})


# ---------- Gacha tay đua (data/driver_gacha.json) ----------
# Mở gói nhận tay đua: chưa có → thêm vào đội; đã có → quy đổi mảnh riêng, nâng level chỉ tốn mảnh.
# Mỗi gói có bảo đảm (pity): đủ N lượt liên tiếp chưa ra bậc mục tiêu thì lượt N chắc chắn ra bậc đó.

func driver_has(id: String) -> bool:
	return id in owned_drivers


func driver_level(id: String) -> int:
	return int((driver_progress.get(id, {}) as Dictionary).get("level", 0))


func driver_shards(id: String) -> int:
	return int((driver_progress.get(id, {}) as Dictionary).get("shards", 0))


func driver_max_level(id: String) -> int:
	return int(GameData.driver_gacha_config(id).get("max_level", 0))


## Cộng thêm vào mọi chỉ số tay đua theo level đã nâng.
func driver_level_bonus(id: String) -> float:
	return float(driver_level(id)) * float(GameData.driver_gacha_config(id).get("stat_bonus_per_level", 0))


## Mảnh cần để lên level kế; -1 khi đã tối đa hoặc chưa sở hữu.
func driver_upgrade_cost(id: String) -> int:
	if not driver_has(id):
		return -1
	var lv := driver_level(id)
	if lv >= driver_max_level(id):
		return -1
	var table: Array = GameData.driver_gacha_config(id).get("level_up_shards", [])
	return int(table[lv]) if lv < table.size() else -1


func driver_payment(pack_id: String, count: int) -> Dictionary:
	var pack := GameData.driver_pack(pack_id)
	if pack.is_empty() or not (count == 1 or count == 10):
		return {}
	var kind := String(pack["coupon"])
	if int(driver_coupons.get(kind, 0)) >= count:
		return {"method": "coupon", "kind": kind, "amount": count}
	return {"method": "gem", "amount": int(pack["price_x1"] if count == 1 else pack["price_x10"])}


func driver_can_afford(pack_id: String, count: int) -> bool:
	var pay := driver_payment(pack_id, count)
	if pay.is_empty() or _gear_blocked():
		return false
	return pay["method"] == "coupon" or gems >= int(pay["amount"])


## Số lượt đã mở liên tiếp chưa ra bậc bảo đảm của gói.
func driver_pity_count(pack_id: String) -> int:
	return int(driver_pity.get(pack_id, 0))


func _driver_pick(pack: Dictionary, rng: RandomNumberGenerator) -> String:
	var ids := GameData.driver_tier_ids()
	var tiers: Dictionary = pack["tiers"]
	var pity_tier := String(pack["pity_tier"])
	var tier_id := pity_tier
	# Lượt chạm ngưỡng bảo đảm thì ra đúng bậc bảo đảm; còn lại theo tỉ lệ.
	if driver_pity_count(String(pack["id"])) + 1 < int(pack["pity_draws"]):
		var keys: Array = tiers.keys()
		keys.sort()
		var roll := rng.randf() * 100.0
		tier_id = String(keys[keys.size() - 1])
		var acc := 0.0
		for k: String in keys:
			acc += float(tiers[k])
			if roll < acc:
				tier_id = k
				break
	var pool: Array = []
	for d: Dictionary in GameData.drivers():
		if int(d["tier"]) == ids.find(tier_id):
			pool.append(String(d["id"]))
	return pool[rng.randi() % pool.size()]


## Mở gói: trừ coupon/gem, nhận tay đua, cập nhật bảo đảm — một giao dịch, lỗi lưu thì hoàn tác toàn bộ.
## Trong một lần x10, tay đua mới xuất hiện rồi lặp lại thì lần sau tính là trùng.
func open_driver_pack(pack_id: String, count: int, rng: RandomNumberGenerator = null) -> Dictionary:
	if not driver_can_afford(pack_id, count):
		return {}
	var pack := GameData.driver_pack(pack_id)
	var pay := driver_payment(pack_id, count)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var before := _save_data()
	if pay["method"] == "coupon":
		driver_coupons[pay["kind"]] = int(driver_coupons[pay["kind"]]) - count
	else:
		gems -= int(pay["amount"])
	var ids := GameData.driver_tier_ids()
	var pity_index := ids.find(String(pack["pity_tier"]))
	var results: Array = []
	for i in count:
		var id := _driver_pick(pack, rng)
		var got_tier := int(GameData.driver(id)["tier"])
		if got_tier >= pity_index:
			driver_pity[pack_id] = 0
		else:
			driver_pity[pack_id] = driver_pity_count(pack_id) + 1
		if driver_has(id):
			var add := int(GameData.driver_gacha_config(id).get("duplicate_shards", 0))
			var prog: Dictionary = driver_progress.get(id, {"level": 0, "shards": 0})
			prog["shards"] = int(prog.get("shards", 0)) + add
			driver_progress[id] = prog
			results.append({"id": id, "is_new": false, "shards": add})
		else:
			owned_drivers.append(id)
			driver_pack_new += 1
			driver_progress[id] = {"level": 0, "shards": 0}
			results.append({"id": id, "is_new": true, "shards": 0})
	driver_open_count += count
	last_driver_result = results
	if not save_game():
		_restore_transaction(before)
		return {}
	changed.emit()
	return {"payment": pay, "results": results}


## Nâng level bằng mảnh của chính tay đua đó: trừ đúng ngưỡng, giữ mảnh dư, không đụng coins/gem/coupon/tay đua khác.
func upgrade_driver(id: String) -> bool:
	var need := driver_upgrade_cost(id)
	if need < 0 or driver_shards(id) < need or _gear_blocked():
		return false
	var before := _save_data()
	var prog: Dictionary = driver_progress.get(id, {"level": 0, "shards": 0})
	prog["shards"] = int(prog.get("shards", 0)) - need
	prog["level"] = int(prog.get("level", 0)) + 1
	driver_progress[id] = prog
	if not save_game():
		_restore_transaction(before)
		return false
	if phase == "countdown":
		_rebuild_preview()
	changed.emit()
	return true


## Cấp coupon gói tay đua (nguồn nhận chưa thiết kế; dùng cho test/debug/sự kiện sau này).
func grant_driver_coupons(kind: String, amount: int) -> bool:
	if not GameData.driver_coupon_types().has(kind) or amount <= 0 or _gear_blocked():
		return false
	var before := _save_data()
	driver_coupons[kind] = int(driver_coupons.get(kind, 0)) + amount
	if not save_game():
		_restore_transaction(before)
		return false
	changed.emit()
	return true


## Làm sạch dữ liệu từ save: id lạ bị bỏ; level ngoài cấu hình bị chặn lại; tay đua sở hữu luôn có mục tiến trình.
func _apply_driver_gacha(d: Dictionary) -> void:
	driver_progress = {}
	var raw: Variant = d.get("driver_progress", {})
	if typeof(raw) == TYPE_DICTIONARY:
		for id in raw:
			if GameData.driver(String(id)).is_empty() or typeof(raw[id]) != TYPE_DICTIONARY:
				continue
			var cfg := GameData.driver_gacha_config(String(id))
			driver_progress[String(id)] = {
				"level": clampi(int(raw[id].get("level", 0)), 0, int(cfg.get("max_level", 0))),
				"shards": maxi(0, int(raw[id].get("shards", 0))),
			}
	driver_coupons = {"pro": 0, "allstar": 0}
	var rc: Variant = d.get("driver_coupons", {})
	if typeof(rc) == TYPE_DICTIONARY:
		for k in driver_coupons.keys():
			driver_coupons[k] = maxi(0, int(rc.get(k, 0)))
	driver_pity = {"pro": 0, "allstar": 0}
	var rp: Variant = d.get("driver_pity", {})
	if typeof(rp) == TYPE_DICTIONARY:
		for k in driver_pity.keys():
			var pack := GameData.driver_pack(String(k))
			driver_pity[k] = clampi(int(rp.get(k, 0)), 0, maxi(0, int(pack.get("pity_draws", 1)) - 1))
	driver_open_count = maxi(0, int(d.get("driver_open_count", 0)))
	driver_pack_new = clampi(int(d.get("driver_pack_new", 0)), 0, maxi(0, owned_drivers.size() - 1))
	last_driver_result = []
	var lr: Variant = d.get("last_driver_result", [])
	if typeof(lr) == TYPE_ARRAY:
		for e in lr:
			if typeof(e) == TYPE_DICTIONARY and not GameData.driver(String(e.get("id", ""))).is_empty():
				last_driver_result.append({"id": String(e["id"]), "is_new": bool(e.get("is_new", false)), "shards": int(e.get("shards", 0))})


# ---------- Offline ----------

## Quyết toán offline đúng một lần rồi ghi save. Trả về false nếu ghi thất bại
## (BootFlow dừng trước 100%; thử lại sẽ đọc lại save cũ nên không phát thưởng hai lần).
func settle_offline() -> bool:
	var before := _save_data()
	var now := Time.get_unix_time_from_system()
	offline_report = {}
	if last_accrual_utc <= 0.0:  # lần mở đầu tiên: không phát thưởng offline
		last_accrual_utc = now
		if not save_game():
			_restore_transaction(before)
			return false
		return true
	var elapsed := maxf(0.0, now - last_accrual_utc)  # giờ lùi => 0, không âm
	var eligible := minf(elapsed, Balance.offline_cap_sec())
	var reward := Pricing.offline_reward(saved_online_rate, eligible)
	coins = coins.add(reward)
	last_accrual_utc = now
	if elapsed >= Balance.offline_panel_min_sec():
		offline_report = {
			"elapsed": elapsed, "eligible": eligible,
			"rate": saved_online_rate, "ratio": Balance.offline_ratio(),
			"reward": reward, "capped": elapsed > Balance.offline_cap_sec(),
		}
	if not save_game():
		_restore_transaction(before)
		offline_report = {}
		return false
	return true


# ---------- Save / Load ----------

## Trả về true khi đã ghi xong. Gọi từ gameplay có thể bỏ qua kết quả.
func _save_data() -> Dictionary:
	var data := {
		"schema_version": SAVE_VERSION, "save_revision": save_revision, "economy_version": 2,
		"coins": coins, "income_remainder": income_remainder, "gems": gems,
		"income_micro_fraction": _income_micro_fraction,
		"levels": levels, "business_tier": business_tier, "unlocked_tier": unlocked_tier,
		"owned_cars": owned_cars, "owned_drivers": owned_drivers,
		"car_levels": car_levels, "garage_cosmetics": garage_cosmetics,
		"gear_owned": gear_owned, "gear_coupons": gear_coupons, "gear_open_count": gear_open_count,
		"last_gear_result": last_gear_result, "revenue_history": revenue_history,
		"driver_progress": driver_progress, "driver_coupons": driver_coupons, "driver_pity": driver_pity,
		"driver_open_count": driver_open_count, "driver_pack_new": driver_pack_new, "last_driver_result": last_driver_result,
		"scout_points": scout_points, "completed_seasons": completed_seasons,
		"season_history": season_history, "legacy_season": _legacy_season,
		"expansion_requested": expansion_requested,
		"season_number": season_number, "stage_index": stage_index,
		"season_results": season_results, "last_result": last_result,
		"last_season": last_season, "records": records,
		"checkpoint": _checkpoint(), "processed_rewards": processed_rewards,
		"last_daily_day": last_daily_day, "last_accrual_utc": last_accrual_utc,
		"saved_online_rate": saved_online_rate, "race_counter": race_counter,
		"active_car_id": active_car_id, "active_driver_id": active_driver_id,
	}
	# Deep snapshot including nested dictionaries, without serializing money as floats.
	return MoneyCodec.decode(MoneyCodec.encode(data))


func save_game(payload: Dictionary = {}) -> bool:
	if save_blocked or simulate_write_failure:
		return false
	var data := _save_data() if payload.is_empty() else payload.duplicate(true)
	data["save_revision"] = save_revision + 1
	var encoded: Dictionary = MoneyCodec.encode(data)
	if not _valid_save(encoded):
		push_error("Save validation failed; previous save preserved.")
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TMP_PATH.get_base_dir()))
	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(encoded))
	f.flush()
	f.close()
	var check: Variant = MoneyCodec.parse(FileAccess.get_file_as_string(TMP_PATH))
	if not _valid_save(check):
		return false
	var tmp_abs := ProjectSettings.globalize_path(TMP_PATH)
	var save_abs := ProjectSettings.globalize_path(SAVE_PATH)
	var bak_abs := ProjectSettings.globalize_path(BAK_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		var current: Variant = MoneyCodec.parse(FileAccess.get_file_as_string(SAVE_PATH))
		# A corrupt primary must not overwrite the good backup we recovered from.
		if _valid_save(current):
			if DirAccess.copy_absolute(save_abs, bak_abs) != OK:
				return false
		if DirAccess.remove_absolute(save_abs) != OK:
			return false
	if DirAccess.rename_absolute(tmp_abs, save_abs) != OK:
		# The valid backup remains available even if replacement fails.
		return false
	save_revision = int(data["save_revision"])
	return true


func _valid_save(raw: Variant) -> bool:
	if typeof(raw) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = raw
	if not _integer_in(d.get("schema_version", 1), 1, 100000):
		return false
	var version := int(d.get("schema_version", 1))
	if not d.has("coins") or not MoneyCodec.valid_tree(d, "", version < 4):
		return false
	for key in ["levels", "checkpoint", "processed_rewards", "records", "last_result", "last_season"]:
		if d.has(key) and typeof(d[key]) != TYPE_DICTIONARY:
			return false
	for key in ["season_results", "owned_drivers", "season_history"]:
		if d.has(key) and typeof(d[key]) != TYPE_ARRAY:
			return false
	for key in ["gear_owned", "gear_coupons", "driver_progress", "driver_coupons", "driver_pity"]:
		if d.has(key) and typeof(d[key]) != TYPE_DICTIONARY:
			return false
	if d.has("last_driver_result") and typeof(d["last_driver_result"]) != TYPE_ARRAY:
		return false
	for key in ["driver_open_count", "driver_pack_new"]:
		if d.has(key) and not _integer_in(d[key], 0, 1000000000000):
			return false
	if d.has("last_gear_result") and typeof(d["last_gear_result"]) != TYPE_ARRAY:
		return false
	if d.has("gear_open_count") and not _integer_in(d["gear_open_count"], 0, 1000000000000):
		return false
	for key in ["gems", "scout_points", "completed_seasons", "save_revision", "race_counter"]:
		if d.has(key) and not _integer_in(d[key], 0, 1000000000000):
			return false
	for key in ["last_accrual_utc", "income_micro_fraction"]:
		if d.has(key) and (not (typeof(d[key]) == TYPE_INT or typeof(d[key]) == TYPE_FLOAT) or not is_finite(float(d[key])) or float(d[key]) < 0):
			return false
	if d.has("stage_index") and not _integer_in(d["stage_index"], 0, Balance.stages()):
		return false
	if d.has("season_number") and not _integer_in(d["season_number"], 1, 1000000000000):
		return false
	if version >= 4:
		for key in ["income_remainder", "saved_online_rate", "levels", "business_tier", "unlocked_tier", "car_levels", "owned_cars", "owned_drivers"]:
			if not d.has(key):
				return false
		if not _integer_in(d["business_tier"], 0, GameData.leagues().size() - 1) or not _integer_in(d["unlocked_tier"], 0, GameData.leagues().size() - 1):
			return false
		var tier := int(d["business_tier"])
		if tier < 0 or tier >= GameData.leagues().size() or int(d["unlocked_tier"]) < tier or int(d["unlocked_tier"]) >= GameData.leagues().size():
			return false
		if typeof(d["owned_cars"]) != TYPE_DICTIONARY or typeof(d["car_levels"]) != TYPE_DICTIONARY:
			return false
		var car_id := String(d.get("active_car_id", ""))
		if GameData.car(car_id).is_empty() or not d["owned_cars"].has(car_id):
			return false
		if int(GameData.car(car_id)["class"]) < int(GameData.league(tier)["min_car_class"]):
			return false
		if not String(d.get("active_driver_id", "")) in d["owned_drivers"]:
			return false
		for id in d["owned_cars"]:
			if GameData.car(id).is_empty() or not d["car_levels"].has(id) or typeof(d["car_levels"][id]) != TYPE_DICTIONARY:
				return false
			for kind in Balance.PARTS:
				if not _integer_in(d["car_levels"][id].get(kind), 0, Balance.max_level()):
					return false
		for id in d["owned_drivers"]:
			if GameData.driver(id).is_empty():
				return false
		for kind in Balance.PARTS + Balance.REVENUE:
			if not _integer_in(d["levels"].get(kind), 0, Balance.max_level()):
				return false
	return true


static func _integer_in(value: Variant, low: int, high: int) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high


func load_game() -> String:
	load_error = ""
	save_blocked = false
	var had_file := false
	for path in [SAVE_PATH, BAK_PATH]:
		if not FileAccess.file_exists(path):
			continue
		had_file = true
		var parsed: Variant = MoneyCodec.parse(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		if not _integer_in(parsed.get("schema_version", 1), 1, 100000):
			continue
		if int(parsed.get("schema_version", 1)) > SAVE_VERSION:
			save_blocked = true
			load_error = "Save thuộc phiên bản game mới hơn."
			return "newer"
		if not _valid_save(parsed):
			continue
		_apply(parsed)
		if path == BAK_PATH:
			load_error = "Save chính bị lỗi, đã khôi phục từ bản sao."
			return "backup"
		return "ok"
	if had_file:
		save_blocked = true
		load_error = "Không đọc được save. Tiến trình sẽ không bị ghi đè."
		return "corrupt"
	return "new"


func _apply(raw: Dictionary) -> void:
	var legacy := int(raw.get("schema_version", 1)) < 4
	var d: Dictionary = MoneyCodec.decode(raw, legacy)
	var level_mult := Pricing.level_subdivision() if int(raw.get("schema_version", 1)) < 5 else 1  # save thang 20 cấp → 200 cấp
	coins =MoneyCodec.legacy_number(d.get("coins", coins))
	income_remainder = MoneyCodec.legacy_number(d.get("income_remainder", BigNumber.zero()))
	_income_micro_fraction = float(d.get("income_micro_fraction", 0.0))
	gems = int(d.get("gems", gems))
	var lv: Dictionary = d.get("levels", {})
	for k in levels.keys():
		levels[k] = clampi(int(lv.get(k, 0)), 0, Balance.max_level())
	if int(d.get("schema_version", 1)) < 3:
		levels["ticket"] = clampi(int(d.get("venue_level", 0)), 0, Balance.max_level())
		for lv_old in clampi(int(d.get("driver_level", 0)), 0, 20):
			coins = coins.add(Pricing.legacy_driver_refund(lv_old))
	if level_mult > 1:
		for k in levels.keys():
			levels[k] = clampi(int(levels[k]) * level_mult, 0, Balance.max_level())
	season_number = int(d.get("season_number", 1))
	stage_index = clampi(int(d.get("stage_index", 0)), 0, Balance.stages())
	season_results = d.get("season_results", [])
	last_result = d.get("last_result", {})
	last_season = d.get("last_season", {})
	records = d.get("records", {})
	_loaded_checkpoint = d.get("checkpoint", {})
	processed_rewards = d.get("processed_rewards", {})
	last_daily_day = int(d.get("last_daily_day", -1))
	last_accrual_utc = float(d.get("last_accrual_utc", 0.0))
	saved_online_rate = MoneyCodec.legacy_number(d.get("saved_online_rate", Balance.base_rate()))
	save_revision = int(d.get("save_revision", 0))
	race_counter = int(d.get("race_counter", 0))
	active_car_id = String(d.get("active_car_id", GameData.starter_car_id()))
	active_driver_id = String(d.get("active_driver_id", "driver_an"))
	if GameData.car(active_car_id).is_empty():
		active_car_id = GameData.starter_car_id()
	if GameData.driver(active_driver_id).is_empty():
		active_driver_id = "driver_an"
	business_tier = int(d.get("business_tier", 0))
	unlocked_tier = int(d.get("unlocked_tier", business_tier))
	owned_cars = d.get("owned_cars", {active_car_id: true})
	owned_drivers = d.get("owned_drivers", [active_driver_id])
	car_levels = d.get("car_levels", {active_car_id: _part_levels()})
	if level_mult > 1 and d.has("car_levels"):
		for id: String in car_levels.keys():
			for k: String in car_levels[id].keys():
				car_levels[id][k] = clampi(int(car_levels[id][k]) * level_mult, 0, Balance.max_level())
	garage_cosmetics = _clean_cosmetics(d.get("garage_cosmetics", {}))
	_apply_gear(d)
	_apply_driver_gacha(d)
	revenue_history = d.get("revenue_history", {})
	scout_points = int(d.get("scout_points", 0))
	completed_seasons = int(d.get("completed_seasons", 0))
	season_history = d.get("season_history", [])
	_legacy_season = bool(d.get("legacy_season", legacy and (stage_index > 0 or _loaded_checkpoint.get("phase", "") == "racing")))
	expansion_requested = bool(d.get("expansion_requested", false))
	_rate_key = ""
	if stage_index >= Balance.stages():
		if bool(last_result.get("season_done", false)):
			last_season = last_result.duplicate(true)
		season_number += 1
		stage_index = 0
		season_results = []


## Checkpoint của countdown/đua đang chạy. Đua xác định theo seed nên chỉ cần seed, snapshot và số tick đã chạy.
func _checkpoint() -> Dictionary:
	match phase:
		"save_error":
			return _failed_checkpoint
		"countdown":
			return {"phase": "countdown", "left": countdown_left, "seed": _race_seed, "cfg": race_cfg}
		"racing":
			if sim != null:
				return {"phase": "racing", "ticks": sim.tick_count, "seed": _race_seed, "cfg": race_cfg,
					"snapshot": race_snapshot}
	return {}


## Dùng khi debug: xóa save và bắt đầu lại.
func reset_progress() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BAK_PATH))
	init_new_game()
	last_accrual_utc = Time.get_unix_time_from_system()
	save_game()
	changed.emit()
