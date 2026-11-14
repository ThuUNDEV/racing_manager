class_name I18n
extends RefCounted
## Đa ngôn ngữ bằng ID khóa ổn định (Design: docs/i18n.md).
##
##   I18n.t("shop.claim")                  -> chữ theo ngôn ngữ đang chọn
##   I18n.t("main.level") % lv             -> bản dịch giữ nguyên placeholder %d/%s của bản gốc
##   I18n.tn("main.sec", n) % n            -> dạng số ít/số nhiều (khóa "<id>.one" khi cần)
##   "@data.cars.pico_lightning" trong data/*.json được dịch lúc nạp (translate_tree)
##
## Bảng dịch: i18n/<code>.json = {"id": "text"}. Thiếu khóa -> lấy tiếng Anh -> trả chính ID
## (để lộ rõ khóa thiếu). Ngôn ngữ chọn lưu ở user://language.cfg; lần đầu theo ngôn ngữ máy.

const DIR := "res://i18n/"
const FALLBACK := "en"
const PREF_PATH := "user://language.cfg"
## Tiền tố đánh dấu chuỗi trong data JSON là ID khóa.
const DATA_PREFIX := "@"

## Thứ tự hiện trong popup chọn ngôn ngữ. name = tên bằng chính ngôn ngữ đó.
## dec = dấu thập phân; font = nhóm font cần ưu tiên (xem _FONT_FILES).
const LANGS := [
	{"code": "en", "name": "English", "dec": ".", "font": ""},
	{"code": "vi", "name": "Tiếng Việt", "dec": ",", "font": ""},
	{"code": "id", "name": "Bahasa Indonesia", "dec": ",", "font": ""},
	{"code": "ms", "name": "Bahasa Melayu", "dec": ".", "font": ""},
	{"code": "th", "name": "ไทย", "dec": ".", "font": "th"},
	{"code": "ja", "name": "日本語", "dec": ".", "font": "ja"},
	{"code": "ko", "name": "한국어", "dec": ".", "font": "ko"},
	{"code": "zh_Hans", "name": "简体中文", "dec": ".", "font": "zh"},
]
## Font bổ sung cho chữ ngoài bảng Latin/Việt (Roboto không có). Thiếu tệp thì dùng font hệ thống.
const _FONT_FILES := {
	"th": "res://assets/fonts/NotoSansThai-Bold.ttf",
	"ja": "res://assets/fonts/NotoSansJP-Bold.ttf",
	"ko": "res://assets/fonts/NotoSansKR-Bold.ttf",
	"zh": "res://assets/fonts/NotoSansSC-Bold.ttf",
}
const _BASE_FONTS := [
	"res://assets/clean_modern/fonts/Roboto-Bold.ttf",
	"res://assets/clean_modern/fonts/Roboto-BlackItalic.ttf",
]

static var _lang := ""
static var _table: Dictionary = {}
static var _fallback: Dictionary = {}
## Tăng mỗi lần đổi ngôn ngữ; nơi nào cache chữ đã dịch thì so với số này.
static var revision := 0


# ---------------------------------------------------------------- chọn ngôn ngữ

static func codes() -> Array:
	var out: Array = []
	for l in LANGS:
		out.append(l["code"])
	return out


static func info(code: String) -> Dictionary:
	for l in LANGS:
		if l["code"] == code:
			return l
	return {}


static func has_lang(code: String) -> bool:
	return not info(code).is_empty()


static func lang() -> String:
	if _lang == "":
		set_lang(saved_lang())
	return _lang


static func lang_name(code: String = "") -> String:
	return String(info(code if code != "" else lang()).get("name", code))


## Mã ngôn ngữ của máy (OS.get_locale) quy về danh sách hỗ trợ; không hỗ trợ -> FALLBACK.
static func detect(locale: String = "") -> String:
	var loc := (locale if locale != "" else OS.get_locale()).replace("-", "_")
	var low := loc.to_lower()
	if low.begins_with("zh"):
		return "zh_Hans"  # chưa có phồn thể: dùng giản thể
	var base := low.get_slice("_", 0)
	if base == "in":
		base = "id"  # mã cũ của tiếng Indonesia
	return base if has_lang(base) else FALLBACK


## Ngôn ngữ đã lưu; chưa lưu thì theo máy. RM_LANG (test/CI) ghi đè.
static func saved_lang() -> String:
	var forced := OS.get_environment("RM_LANG")
	if has_lang(forced):
		return forced
	var cfg := ConfigFile.new()
	if cfg.load(PREF_PATH) == OK:
		var code := String(cfg.get_value("i18n", "lang", ""))
		if has_lang(code):
			return code
	return detect()


## Nạp bảng dịch cho ngôn ngữ (không lưu lựa chọn).
static func set_lang(code: String) -> void:
	if not has_lang(code):
		code = FALLBACK
	_lang = code
	_fallback = _read(FALLBACK)
	_table = _fallback if code == FALLBACK else _read(code)
	revision += 1
	TranslationServer.set_locale(code)
	_apply_fonts()


## Người chơi đổi ngôn ngữ: lưu, nạp bảng và xóa cache dữ liệu đã dịch.
## Màn hình đang mở phải tự dựng lại (main gọi reload qua màn loading).
static func switch(code: String) -> void:
	if not has_lang(code):
		return
	var cfg := ConfigFile.new()
	cfg.set_value("i18n", "lang", code)
	cfg.save(PREF_PATH)
	set_lang(code)  # revision tăng: GameData/Tutorial/ShopPackUi tự nạp lại chữ đã dịch


static func _read(code: String) -> Dictionary:
	var path := "%s%s.json" % [DIR, code]
	if not FileAccess.file_exists(path):
		push_warning("i18n: missing catalog " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


# ---------------------------------------------------------------- tra cứu

static func has(key: String) -> bool:
	lang()
	return _table.has(key) or _fallback.has(key)


## Chữ của một ID khóa.
static func t(key: String) -> String:
	if _lang == "":
		set_lang(saved_lang())
	var v: Variant = _table.get(key)
	if v == null:
		v = _fallback.get(key, key)
	return String(v)


## Số ít/số nhiều: dùng "<key>.one" khi ngôn ngữ coi n là số ít và có khóa đó, ngược lại "<key>".
## (Tiếng Việt, Indonesia, Mã Lai, Thái, Nhật, Hàn, Trung không chia số nhiều.)
static func tn(key: String, n: int) -> String:
	if plural_one(n) and has(key + ".one"):
		return t(key + ".one")
	return t(key)


static func plural_one(n: int) -> bool:
	return lang() == "en" and absi(n) == 1


## Một ID có phải bản dịch (ở bất kỳ ngôn ngữ nào) của chữ này không. Dùng cho chữ mặc định đã lưu
## vào save (ví dụ tên đội mặc định) để vẫn nhận ra sau khi đổi ngôn ngữ.
static func is_any_translation(key: String, text: String) -> bool:
	if t(key) == text:
		return true
	for code in codes():
		if String(_read(code).get(key, "")) == text:
			return true
	return false


## Dịch các chuỗi "@id" trong cây dữ liệu (Dictionary/Array) của data/*.json.
static func translate_tree(v: Variant) -> Variant:
	if v is String:
		var s: String = v
		return t(s.substr(DATA_PREFIX.length())) if s.begins_with(DATA_PREFIX) else s
	if v is Array:
		var out: Array = []
		for x in v:
			out.append(translate_tree(x))
		return out
	if v is Dictionary:
		var d: Dictionary = {}
		for k in v:
			d[k] = translate_tree(v[k])
		return d
	return v


# ---------------------------------------------------------------- số và font

## Dấu thập phân hiển thị theo ngôn ngữ.
static func dec() -> String:
	return String(info(lang()).get("dec", "."))


## Gắn font bổ sung vào Roboto (dùng chung toàn game) để hiện chữ Thái/Nhật/Hàn/Trung.
## Font của ngôn ngữ đang chọn đứng trước (chữ Hán Nhật và Trung khác nét).
static func _apply_fonts() -> void:
	var want := String(info(_lang).get("font", ""))
	var order: Array = []
	if want != "":
		order.append(want)
	for g in ["ja", "zh", "ko", "th"]:
		if not g in order:
			order.append(g)
	var extras: Array[Font] = []
	for g in order:
		var path: String = _FONT_FILES[g]
		if ResourceLoader.exists(path):
			extras.append(load(path))
	for p in _BASE_FONTS:
		if not ResourceLoader.exists(p):
			continue
		var f := load(p) as FontFile
		if f == null:
			continue
		f.fallbacks = extras
		f.allow_system_fallback = true
