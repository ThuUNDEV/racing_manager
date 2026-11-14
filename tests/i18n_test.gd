extends SceneTree

## Chạy: godot --headless --path . -s res://tests/i18n_test.gd
## Đa ngôn ngữ (docs/i18n.md): mọi bảng i18n/<code>.json đủ khóa so với en.json, giữ đúng thứ tự
## placeholder, không còn chữ Việt ngoài vi; tra khóa, fallback, số nhiều, nhận diện ngôn ngữ máy,
## dịch "@id" trong data, dấu thập phân, đổi ngôn ngữ làm mới cache dữ liệu.

var _fails := 0
const VI_CHARS := "ăâêôơưđĂÂÊÔƠƯĐàáạảãèéẹẻẽìíịỉĩòóọỏõùúụủũỳýỵỷỹắằẳẵặấầẩẫậếềểễệốồổỗộớờởỡợứừửữự"


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL "), msg)
	if not cond:
		_fails += 1


func _has_vi(s: String) -> bool:
	for i in s.length():
		if VI_CHARS.contains(s[i]):
			return true
	return false


func _placeholders(s: String) -> Array:
	var out: Array = []
	var re := RegEx.new()
	re.compile("%[-+0-9.]*[sdf]|%%|\\{[a-zA-Z_]+\\}")
	for m in re.search_all(s):
		out.append(m.get_string())
	return out  # giữ thứ tự: code truyền tham số theo vị trí


func _catalog(code: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://i18n/%s.json" % code))


func _initialize() -> void:
	var en := _catalog("en")
	_check(en.size() > 500, "en.json có %d khóa" % en.size())
	_check(I18n.codes().size() == 8, "8 ngôn ngữ: %s" % ", ".join(I18n.codes()))

	for code: String in I18n.codes():
		_check(FileAccess.file_exists("res://i18n/%s.json" % code), "%s.json tồn tại" % code)
		if code == "en":
			continue
		var cat := _catalog(code)
		var missing := 0
		var bad_ph := 0
		var bad_vi := 0
		for k: String in en:
			if k.ends_with(".one"):
				continue
			if not cat.has(k):
				missing += 1
				continue
			if _placeholders(String(en[k])) != _placeholders(String(cat[k])):
				bad_ph += 1
				print("    lệch placeholder %s.%s: %s" % [code, k, cat[k]])
			if code != "vi" and _has_vi(String(cat[k])):
				bad_vi += 1
		_check(missing == 0, "%s đủ khóa (thiếu %d)" % [code, missing])
		_check(bad_ph == 0, "%s giữ đúng thứ tự %%d/%%s/{x} (%d lỗi)" % [code, bad_ph])
		_check(bad_vi == 0, "%s không lẫn chữ Việt (%d lỗi)" % [code, bad_vi])

	# Tra khóa và fallback.
	I18n.set_lang("vi")
	_check(I18n.t("main.race_2") == "Đua", "vi: main.race_2 -> Đua")
	I18n.set_lang("en")
	_check(I18n.t("main.race_2") == "Race", "en: main.race_2 -> Race")
	_check(I18n.t("main.level") % 3 == "Level 3", "chuỗi định dạng giữ placeholder")
	_check(I18n.t("no.such.key") == "no.such.key", "thiếu khóa thì trả chính ID")
	I18n.set_lang("ja")
	_check(I18n.t("main.race_2") == "レース", "ja: main.race_2 -> レース")
	_check(I18n.t("drivers.tier_pro") == "Pro", "ja dùng tiếng Anh cho khóa ghi '='")
	I18n.set_lang("xx")
	_check(I18n.lang() == "en", "mã lạ -> en")

	# Số ít / số nhiều (chỉ tiếng Anh chia).
	I18n.set_lang("en")
	_check(I18n.tn("shop.days", 1) % 1 == "1 day", "en tn(1) -> 1 day")
	_check(I18n.tn("shop.days", 3) % 3 == "3 days", "en tn(3) -> 3 days")
	I18n.set_lang("ko")
	_check(I18n.tn("shop.days", 1) % 1 == "1일", "ko không chia số nhiều")

	# Ngôn ngữ của máy.
	_check(I18n.detect("ja_JP") == "ja", "detect ja_JP")
	_check(I18n.detect("zh_TW") == "zh_Hans", "detect zh_TW -> zh_Hans")
	_check(I18n.detect("in_ID") == "id", "detect mã cũ in_ID -> id")
	_check(I18n.detect("ms-MY") == "ms", "detect ms-MY")
	_check(I18n.detect("fr_FR") == "en", "ngôn ngữ chưa hỗ trợ -> en")

	# Dấu thập phân.
	I18n.set_lang("vi")
	_check(I18n.dec() == ",", "vi dùng dấu phẩy")
	I18n.set_lang("th")
	_check(I18n.dec() == ".", "th dùng dấu chấm")

	# Data JSON: "@id" được dịch, cache làm mới khi đổi ngôn ngữ.
	I18n.set_lang("en")
	var leftover := 0
	for c in GameData.race_classes():
		for f in ["name", "blurb", "key_stats"]:
			var v := String(c.get(f, ""))
			if v.begins_with("@") or _has_vi(v):
				leftover += 1
	_check(leftover == 0, "classes.json hiện bản dịch EN")
	var league0_en := String(GameData.leagues()[0]["name"])
	I18n.set_lang("zh_Hans")
	var league0_zh := String(GameData.leagues()[0]["name"])
	_check(league0_en == "Apprentice" and league0_zh == "学徒", "đổi ngôn ngữ làm mới tên giải (%s / %s)" % [league0_en, league0_zh])

	# Tên đội mặc định đã lưu ở ngôn ngữ khác vẫn được nhận ra.
	_check(I18n.is_any_translation("save.team", "Đội của bạn"), "nhận ra tên đội mặc định VI")
	_check(I18n.is_any_translation("save.team", "Your Team"), "nhận ra tên đội mặc định EN")
	_check(not I18n.is_any_translation("save.team", "Rồng Đỏ"), "tên tự đặt không phải mặc định")

	I18n.set_lang("vi")
	GameData.reload()
	print("")
	print("I18N ĐẠT" if _fails == 0 else "I18N THẤT BẠI: %d" % _fails)
	quit(1 if _fails > 0 else 0)
