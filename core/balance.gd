class_name Balance
extends RefCounted

const BigNumber = preload("res://core/math/big_number.gd")
## Mặt tiền (facade) cho UI và game: tên hiển thị, định dạng, và các giá trị cân bằng đọc từ data/*.json.
## Hằng số cấu trúc ở đầu file (số vòng, độ dài vòng, tick) phải khớp data/sim.json;
## tests/data_test.gd kiểm tra điều này. Mọi hệ số cân bằng còn lại nằm trong dữ liệu.

# --- Cấu trúc cuộc đua (khớp sim.json) ---
const LAPS := 3
const LAP_LENGTH := 400.0
const RACE_LENGTH := 1200.0
const TICK := 0.1
const GRID_GAP := 3.0
const CAR_COUNT := 8
## Đếm ngược trước mỗi lần xuất phát (Design/10 §2): cố định 3 giây, dùng chung cho điều phối và UI.
const COUNTDOWN_SECONDS := 3

# --- Xe (tên hiển thị; tên bộ phận → khóa chỉ số) ---
const REVENUE := ["ticket", "celebration", "parking", "grandstands"]

const PARTS := ["engine", "tyre", "chassis", "gearbox"]
const PART_KEY := {"engine": "S", "tyre": "H", "chassis": "B", "gearbox": "A"}
const PART_NAMES := {
	"engine": "part.engine", "tyre": "part.tyres", "chassis": "part.chassis", "gearbox": "part.gearbox",
}
const PART_STATS := {
	"engine": "Speed", "tyre": "Handling", "chassis": "Stability", "gearbox": "Acceleration",
}
const PART_HINTS := {
	"engine": "common.engine_boosts_top_speed_straights",
	"tyre": "common.tyres_help_car_hold_speed",
	"chassis": "part.chassis_lowers_chance_mistakes",
	"gearbox": "part.gearbox_improves_acceleration_out_corners",
}


# --- Giá trị từ dữ liệu ---
static func start_coins() -> BigNumber:
	return BigNumber.parse_decimal(GameData.economy()["start_coins"])


static func start_gems() -> int:
	return int(GameData.economy()["start_gems"])


static func base_rate() -> BigNumber:
	return BigNumber.parse_decimal(GameData.economy()["base_rate"])


static func max_level() -> int:
	return Pricing.max_level()


static func daily_gift(rate: BigNumber) -> BigNumber:
	return Pricing.daily_gift(rate)


static func offline_ratio() -> float:
	return float(GameData.economy()["offline"]["ratio"])


static func offline_cap_sec() -> float:
	return float(GameData.economy()["offline"]["cap_sec"])


static func offline_panel_min_sec() -> float:
	return float(GameData.economy()["offline"]["panel_min_sec"])


## Thời gian một vòng của xe chuẩn (chỉ số = nền giải, form 1) chạy tự do, đã nhân hệ số tốc độ hiển thị.
static func reference_lap_time(track_id: String) -> float:
	var sm: Dictionary = GameData.sim()
	var straight := float(sm["straight_base"])
	var corner := minf(straight, float(sm["corner_base"]))
	var scale := float(sm["traffic"].get("speed_scale", 1.0))
	var t := 0.0
	for d: Dictionary in GameData.sector_defs(track_id):
		t += float(d["len"]) / (corner if bool(d["corner"]) else straight)
	return t / scale


## Số vòng mặc định của một lượt (data/sim.json race_loop.race_laps).
static func race_laps() -> int:
	return int(GameData.sim()["race_loop"]["race_laps"])


static var _duration_cache: Dictionary = {}


## Thời lượng lượt đua = thời gian để xe CHẬM NHẤT của đoàn chuẩn (chỉ số = nền giải, seed cố định) chạy đủ
## số vòng cấu hình (race_laps), đo bằng chính mô phỏng đua theo vòng (đã gồm xuất phát, cua, lỗi, kẹt xe),
## nhân hệ số hiệu chỉnh race_time_factor. Tính một lần cho mỗi track rồi nhớ lại.
static func race_duration(track_id: String) -> float:
	var rl: Dictionary = GameData.sim()["race_loop"]
	var key := "%s|%d|%s|%s" % [track_id, race_laps(), str(GameData.sim()["traffic"].get("speed_scale", 1.0)), str(rl["race_time_factor"])]
	if _duration_cache.has(key):
		return float(_duration_cache[key])
	var lg := GameData.league(0)
	var cb := float(lg["car_base"])
	var db := float(lg["driver_base"])
	var sim := TrafficSim.new()
	sim.setup(1, {"S": cb, "H": cb, "B": cb, "A": cb, "P": db, "T": db, "C": db}, 0, track_id, {})
	sim.run_to_end()
	var slowest := 0.0
	for c: TrafficSim.Car in sim.cars:
		slowest = maxf(slowest, c.finish_time)
	var d := slowest / float(sim.laps) * float(race_laps()) * float(rl["race_time_factor"])
	_duration_cache[key] = d
	return d


static func sprint_duration() -> float:
	return float(GameData.sim()["race_loop"]["sprint_duration_seconds"])


static func league_name(index: int) -> String:
	return String(GameData.league(index)["name"])


static func car_cost(level: int, class_index: int = 0) -> BigNumber:
	return Pricing.part_cost(class_index, level)

static func race_points(position: int) -> int:
	return Pricing.race_points(position)

# --- Định dạng hiển thị (vi-VN) ---
static func fmt_int(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if n < 0 else "") + out


static func fmt_compact(n: BigNumber) -> String:
	return n.format_compact()

static func fmt_money(value: Variant) -> String:
	var n := BigNumber.coerce(value)
	return n.format_compact() if n != null else "0"

static func fmt_rate(r: Variant) -> String:
	if r is BigNumber:
		return r.format_compact() if r.exponent >= 3 else r.format_decimal()
	var s := "%.2f" % float(r)
	return s.rstrip("0").rstrip(".").replace(".", I18n.dec())

static func fmt_clock(sec: float) -> String:
	var m := int(sec / 60.0)
	return "%02d:%02d" % [m, int(sec) % 60]


static func fmt_time(sec: float) -> String:
	var m := int(sec / 60.0)
	return "%d:%04.1f" % [m, fmod(sec, 60.0)]
