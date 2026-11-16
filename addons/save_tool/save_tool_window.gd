@tool
extends Window
## Cửa sổ quản lý save: tab "Chỉnh nhanh" (ô nhập số liệu), tab "JSON thô", sao lưu/khôi phục, reset.
## Chỉ thao tác trên user:// của project (cùng nơi game ghi save). Hãy tắt game trước khi sửa/reset.

const SAVE_FILES := ["save.json", "save.bak", "save.tmp"]
const BACKUP_DIR := "user://save_backups"
const PRECISION := 24
const MAX_LEVEL := 200
const REVENUE_KINDS := ["ticket", "celebration", "parking", "grandstands"]
const PART_KINDS := ["engine", "tyre", "chassis", "gearbox"]
const KIND_LABELS := {
	"engine": "Động cơ", "tyre": "Lốp", "chassis": "Khung gầm", "gearbox": "Hộp số",
	"ticket": "Vé", "celebration": "Ăn mừng", "parking": "Bãi đỗ", "grandstands": "Khán đài",
}

var _path_label: Label
var _tabs: TabContainer
var _file_select: OptionButton
var _info_label: Label
var _editor: TextEdit
var _status: Label
var _backup_first: CheckBox
var _backup_select: OptionButton
var _confirm_reset: ConfirmationDialog
var _confirm_tests: ConfirmationDialog
var _confirm_restore: ConfirmationDialog

# Tab chỉnh nhanh
var _quick_note: Label
var _coins_edit: LineEdit
var _coins_now: Label
var _gems_spin: SpinBox
var _trophies_spin: SpinBox
var _scout_spin: SpinBox
var _tier_spin: SpinBox
var _unlocked_spin: SpinBox
var _coupon_spins: Dictionary = {}   # "gear_coupons/standard" -> SpinBox
var _level_spins: Dictionary = {}    # kind -> SpinBox
var _quick_data: Dictionary = {}


func _init() -> void:
	title = "Save Tool"
	min_size = Vector2i(680, 520)
	close_requested.connect(hide)
	_build_ui()


# ============================================================ UI

func _build_ui() -> void:
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	bg.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var path_row := HBoxContainer.new()
	root.add_child(path_row)
	_path_label = Label.new()
	_path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_label.clip_text = true
	path_row.add_child(_path_label)
	path_row.add_child(_button("Mở thư mục", _on_open_folder))
	path_row.add_child(_button("Làm mới", refresh))

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_tabs)
	_tabs.add_child(_build_quick_tab())
	_tabs.set_tab_title(0, "Chỉnh nhanh")
	_tabs.add_child(_build_raw_tab())
	_tabs.set_tab_title(1, "JSON thô")

	var restore_row := HBoxContainer.new()
	root.add_child(restore_row)
	restore_row.add_child(_button("Sao lưu save.json", _on_backup))
	restore_row.add_child(_label("Bản sao lưu:"))
	_backup_select = OptionButton.new()
	_backup_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restore_row.add_child(_backup_select)
	restore_row.add_child(_button("Khôi phục", func() -> void:
		if _backup_select.item_count > 0:
			_confirm_restore.popup_centered()))
	restore_row.add_child(_button("Thư mục sao lưu", _on_open_backups))

	var reset_row := HBoxContainer.new()
	root.add_child(reset_row)
	_backup_first = CheckBox.new()
	_backup_first.text = "Sao lưu trước khi reset"
	_backup_first.button_pressed = true
	reset_row.add_child(_backup_first)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_row.add_child(spacer)
	reset_row.add_child(_button("Xoá user://tests", func() -> void: _confirm_tests.popup_centered()))
	var reset_btn := _button("RESET SAVE", func() -> void: _confirm_reset.popup_centered())
	reset_btn.modulate = Color(1.0, 0.55, 0.55)
	reset_row.add_child(reset_btn)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status)

	_confirm_reset = _make_confirm("Xoá save.json, save.bak, save.tmp?\nLần chạy tới game sẽ bắt đầu như người chơi mới.\n(Hãy tắt game trước, nếu không game có thể ghi lại save.)", _do_reset)
	_confirm_tests = _make_confirm("Xoá toàn bộ thư mục user://tests (save của các test headless)?", _do_clear_tests)
	_confirm_restore = _make_confirm("Ghi đè save.json bằng bản sao lưu đã chọn?\n(save.json hiện tại sẽ được sao lưu trước.)", _do_restore)


func _build_quick_tab() -> Control:
	var page := VBoxContainer.new()
	page.name = "Quick"
	page.add_theme_constant_override("separation", 6)
	_quick_note = Label.new()
	_quick_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_quick_note)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)

	body.add_child(_section("Tiền tệ"))
	var g1 := _grid()
	body.add_child(g1)
	g1.add_child(_label("Coins (số hoặc 1e30)"))
	var coin_row := HBoxContainer.new()
	_coins_edit = LineEdit.new()
	_coins_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_coins_edit.placeholder_text = "vd: 5000000 hoặc 2.5e40"
	coin_row.add_child(_coins_edit)
	_coins_now = Label.new()
	coin_row.add_child(_coins_now)
	g1.add_child(coin_row)
	_gems_spin = _spin(g1, "Gems", 0, 2000000000)
	_trophies_spin = _spin(g1, "Cúp (đang có)", 0, 2000000000)
	_scout_spin = _spin(g1, "Điểm tuyển (scout)", 0, 2000000000)

	body.add_child(_section("Coupon"))
	var g2 := _grid()
	body.add_child(g2)
	for entry in [["gear_coupons", "standard", "Coupon phụ kiện: standard"], ["gear_coupons", "elite", "Coupon phụ kiện: elite"],
			["driver_coupons", "pro", "Coupon tay đua: pro"], ["driver_coupons", "allstar", "Coupon tay đua: allstar"]]:
		_coupon_spins[entry[0] + "/" + entry[1]] = _spin(g2, entry[2], 0, 2000000000)

	body.add_child(_section("Giải đấu"))
	var g3 := _grid()
	body.add_child(g3)
	_tier_spin = _spin(g3, "business_tier (giải đang chơi)", 0, 100)
	_unlocked_spin = _spin(g3, "unlocked_tier (giải đã mở)", 0, 100)

	body.add_child(_section("Cấp nâng cấp (0 – %d)" % MAX_LEVEL))
	var g4 := _grid()
	body.add_child(g4)
	for kind in PART_KINDS + REVENUE_KINDS:
		_level_spins[kind] = _spin(g4, "%s (%s)" % [KIND_LABELS[kind], kind], 0, MAX_LEVEL)

	var row := HBoxContainer.new()
	page.add_child(row)
	row.add_child(_button("Tải lại từ save.json", _load_quick))
	row.add_child(_button("Đặt tất cả cấp = 200", func() -> void:
		for k in _level_spins:
			(_level_spins[k] as SpinBox).value = MAX_LEVEL))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	var apply := _button("Áp dụng vào save.json", _apply_quick)
	apply.modulate = Color(0.6, 1.0, 0.7)
	row.add_child(apply)
	return page


func _build_raw_tab() -> Control:
	var page := VBoxContainer.new()
	page.name = "Raw"
	var file_row := HBoxContainer.new()
	page.add_child(file_row)
	file_row.add_child(_label("File:"))
	_file_select = OptionButton.new()
	_file_select.item_selected.connect(func(_i: int) -> void: _load_selected())
	file_row.add_child(_file_select)
	_info_label = Label.new()
	_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_label.clip_text = true
	file_row.add_child(_info_label)

	_editor = TextEdit.new()
	_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor.add_theme_font_size_override("font_size", 13)
	page.add_child(_editor)

	var edit_row := HBoxContainer.new()
	page.add_child(edit_row)
	edit_row.add_child(_button("Tải lại file", _load_selected))
	edit_row.add_child(_button("Định dạng JSON", _on_pretty))
	edit_row.add_child(_button("Lưu thay đổi", _on_save_edits))
	return page


func _section(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
	return l


func _grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 16)
	return g


func _spin(parent: Control, text: String, lo: float, hi: float) -> SpinBox:
	var l := _label(text)
	l.custom_minimum_size.x = 260
	parent.add_child(l)
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 1
	s.allow_greater = false
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(s)
	return s


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l


func _button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	return b


func _make_confirm(text: String, callback: Callable) -> ConfirmationDialog:
	var d := ConfirmationDialog.new()
	d.dialog_text = text
	d.confirmed.connect(callback)
	add_child(d)
	return d


# ============================================================ Làm mới / đọc

func refresh() -> void:
	_path_label.text = "user://  →  " + ProjectSettings.globalize_path("user://")
	var keep := _selected_file()
	_file_select.clear()
	for f in SAVE_FILES:
		var exists := FileAccess.file_exists("user://" + f)
		_file_select.add_item(f + ("" if exists else "  (không có)"))
		_file_select.set_item_metadata(_file_select.item_count - 1, f)
	_file_select.select(maxi(0, SAVE_FILES.find(keep)))
	_refresh_backups()
	_load_selected()
	_load_quick()


func _selected_file() -> String:
	if _file_select == null or _file_select.selected < 0:
		return ""
	return String(_file_select.get_item_metadata(_file_select.selected))


func _load_selected() -> void:
	var f := _selected_file()
	var path := "user://" + f
	if not FileAccess.file_exists(path):
		_editor.text = ""
		_editor.editable = false
		_info_label.text = "Không có file"
		return
	_editor.editable = true
	_editor.text = FileAccess.get_file_as_string(path)
	var info := "%s | %s" % [_size_text(_editor.text.length()),
			Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(path), true)]
	var parsed: Variant = _parse(_editor.text)
	if typeof(parsed) == TYPE_DICTIONARY:
		var d: Dictionary = parsed
		for key in ["schema_version", "save_revision"]:
			if d.has(key):
				info += " | %s=%s" % [key, str(d[key])]
		info += " | %d khoá" % d.size()
	else:
		info += " | KHÔNG phải JSON object hợp lệ"
	_info_label.text = info


func _size_text(bytes: int) -> String:
	return "%d B" % bytes if bytes < 1024 else "%.1f KB" % (bytes / 1024.0)


func _refresh_backups() -> void:
	_backup_select.clear()
	var dir := DirAccess.open(BACKUP_DIR)
	if dir == null:
		return
	var names: Array = []
	for n in dir.get_files():
		if n.ends_with(".json"):
			names.append(n)
	names.sort()
	names.reverse()
	for n in names:
		_backup_select.add_item(n)


func _say(text: String, ok := true) -> void:
	_status.text = text
	_status.modulate = Color(0.6, 1.0, 0.7) if ok else Color(1.0, 0.6, 0.6)


## Parse giống MoneyCodec.parse của game: số nguyên > 15 chữ số được giữ dạng chuỗi, không bị làm tròn thành float.
func _parse(text: String) -> Variant:
	var regex := RegEx.new()
	regex.compile('"(?:[^"\\\\]|\\\\.)*"|-?[0-9]+(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?')
	var tokens := regex.search_all(text)
	var preserved := text
	for i in range(tokens.size() - 1, -1, -1):
		var token: RegExMatch = tokens[i]
		var raw := token.get_string()
		if not raw.begins_with('"') and raw.is_valid_int() and raw.trim_prefix("-").length() > 15:
			preserved = preserved.left(token.get_start()) + '"' + raw + '"' + preserved.substr(token.get_end())
	var parser := JSON.new()
	return parser.data if parser.parse(preserved) == OK else null


# ============================================================ Chỉnh nhanh

func _load_quick() -> void:
	_quick_data = {}
	var path := "user://save.json"
	if not FileAccess.file_exists(path):
		_quick_note.text = "Chưa có save.json (game chưa ghi save lần nào). Chạy game một lần để tạo save, rồi quay lại."
		_set_quick_enabled(false)
		return
	var parsed: Variant = _parse(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		_quick_note.text = "save.json không phải JSON object hợp lệ. Dùng tab JSON thô hoặc khôi phục từ bản sao lưu."
		_set_quick_enabled(false)
		return
	_quick_data = parsed
	_set_quick_enabled(true)
	_quick_note.text = "Sửa số rồi bấm \"Áp dụng\". Bản cũ được tự sao lưu. Hãy tắt game trước, nếu không game sẽ ghi đè lại."
	var d := _quick_data
	_coins_edit.text = _big_to_text(d.get("coins"))
	_coins_now.text = ""
	_gems_spin.value = int(d.get("gems", 0))
	_trophies_spin.value = int(d.get("trophies", 0))
	_scout_spin.value = int(d.get("scout_points", 0))
	_tier_spin.value = int(d.get("business_tier", 0))
	_unlocked_spin.value = int(d.get("unlocked_tier", 0))
	for key in _coupon_spins:
		var parts: PackedStringArray = String(key).split("/")
		var sub: Variant = d.get(parts[0], {})
		(_coupon_spins[key] as SpinBox).value = int((sub as Dictionary).get(parts[1], 0)) if typeof(sub) == TYPE_DICTIONARY else 0
	var levels: Variant = d.get("levels", {})
	for kind in _level_spins:
		(_level_spins[kind] as SpinBox).value = int((levels as Dictionary).get(kind, 0)) if typeof(levels) == TYPE_DICTIONARY else 0


func _set_quick_enabled(on: bool) -> void:
	_coins_edit.editable = on
	for s in [_gems_spin, _trophies_spin, _scout_spin, _tier_spin, _unlocked_spin]:
		(s as SpinBox).editable = on
	for s in _coupon_spins.values() + _level_spins.values():
		(s as SpinBox).editable = on


## {"significand": "<24 chữ số>", "exponent": n} -> "d.ddd e+n" hoặc số nguyên đầy đủ nếu nhỏ.
func _big_to_text(value: Variant) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return str(value)
	var sig := str((value as Dictionary).get("significand", "0"))
	var e := int((value as Dictionary).get("exponent", 0))
	if sig == "0":
		return "0"
	var trimmed := sig.rstrip("0")
	if e < 18 and trimmed.length() <= e + 1:
		return trimmed + "0".repeat(e + 1 - trimmed.length())
	return "%s%se%d" % [trimmed[0], ("." + trimmed.substr(1)) if trimmed.length() > 1 else "", e]


## Chuỗi người dùng nhập ("12345", "2.5e40") -> dictionary BigNumber đúng định dạng save. null nếu sai cú pháp.
func _text_to_big(text: String) -> Variant:
	var rx := RegEx.new()
	rx.compile("^([0-9]+)(?:\\.([0-9]+))?(?:[eE]([+-]?[0-9]+))?$")
	var m := rx.search(text.strip_edges().replace(",", "").replace("_", ""))
	if m == null:
		return null
	var fraction := m.get_string(2)
	var exp_text := m.get_string(3)
	var power := (int(exp_text) if exp_text != "" else 0) - fraction.length()
	var digits := (m.get_string(1) + fraction).lstrip("0")
	if digits == "":
		return {"significand": "0", "exponent": 0}
	var e := power + digits.length() - 1
	if absi(e) > 1000000:
		return null
	digits = digits.left(PRECISION)
	digits += "0".repeat(PRECISION - digits.length())
	return {"significand": digits, "exponent": e}


func _apply_quick() -> void:
	if _quick_data.is_empty():
		_say("Chưa có save.json hợp lệ để sửa.", false)
		return
	var coins: Variant = _text_to_big(_coins_edit.text)
	if coins == null:
		_say("Coins không hợp lệ. Nhập số nguyên hoặc dạng 2.5e40.", false)
		return
	var d := _quick_data.duplicate(true)
	d["coins"] = coins
	d["income_remainder"] = {"significand": "0", "exponent": 0}
	d["gems"] = int(_gems_spin.value)
	d["trophies"] = int(_trophies_spin.value)
	d["trophies_earned"] = maxi(int(d.get("trophies_earned", 0)), int(_trophies_spin.value))
	d["scout_points"] = int(_scout_spin.value)
	d["business_tier"] = int(_tier_spin.value)
	d["unlocked_tier"] = maxi(int(_unlocked_spin.value), int(_tier_spin.value))
	for key in _coupon_spins:
		var parts: PackedStringArray = String(key).split("/")
		if typeof(d.get(parts[0])) != TYPE_DICTIONARY:
			d[parts[0]] = {}
		d[parts[0]][parts[1]] = int((_coupon_spins[key] as SpinBox).value)
	if typeof(d.get("levels")) != TYPE_DICTIONARY:
		d["levels"] = {}
	for kind in _level_spins:
		d["levels"][kind] = int((_level_spins[kind] as SpinBox).value)
	# Game giữ bản sao cấp bộ phận của xe đang dùng trong car_levels: đồng bộ để không bị ghi đè khi đổi xe.
	var car_id := String(d.get("active_car_id", ""))
	if car_id != "":
		if typeof(d.get("car_levels")) != TYPE_DICTIONARY:
			d["car_levels"] = {}
		var cl: Dictionary = d["car_levels"].get(car_id, {}) if typeof(d["car_levels"].get(car_id)) == TYPE_DICTIONARY else {}
		for kind in PART_KINDS:
			cl[kind] = int((_level_spins[kind] as SpinBox).value)
		d["car_levels"][car_id] = cl
	_write_save(d)


func _write_save(d: Dictionary) -> void:
	if FileAccess.file_exists("user://save.json"):
		_copy_to_backup("user://save.json", "before_edit")
	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	if file == null:
		_say("Không ghi được save.json (lỗi %d)." % FileAccess.get_open_error(), false)
		return
	file.store_string(JSON.stringify(d))
	file.close()
	_say("Đã áp dụng vào save.json (bản cũ nằm trong save_backups).")
	refresh()


# ============================================================ Thao tác chung

func _on_open_folder() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://"))


func _on_open_backups() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BACKUP_DIR))
	OS.shell_open(ProjectSettings.globalize_path(BACKUP_DIR))


func _on_pretty() -> void:
	var parsed: Variant = _parse(_editor.text)
	if parsed == null:
		_say("Không định dạng được: nội dung không phải JSON hợp lệ.", false)
		return
	_editor.text = JSON.stringify(parsed, "\t")
	_say("Đã định dạng (chưa lưu vào file).")


func _on_save_edits() -> void:
	var f := _selected_file()
	if typeof(_parse(_editor.text)) != TYPE_DICTIONARY:
		_say("Không lưu: nội dung phải là JSON object hợp lệ.", false)
		return
	if FileAccess.file_exists("user://" + f):
		_copy_to_backup("user://" + f, f.get_basename())
	var file := FileAccess.open("user://" + f, FileAccess.WRITE)
	if file == null:
		_say("Không ghi được %s (lỗi %d)." % [f, FileAccess.get_open_error()], false)
		return
	file.store_string(_editor.text)
	file.close()
	_say("Đã lưu %s (bản cũ nằm trong save_backups)." % f)
	refresh()


func _on_backup() -> void:
	if not FileAccess.file_exists("user://save.json"):
		_say("Không có save.json để sao lưu.", false)
		return
	var target := _copy_to_backup("user://save.json", "save")
	_say(("Đã sao lưu: " + target) if target != "" else "Sao lưu thất bại.", target != "")
	_refresh_backups()


func _copy_to_backup(src: String, prefix: String) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BACKUP_DIR))
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var target := "%s/%s_%s.json" % [BACKUP_DIR, prefix, stamp]
	var content := FileAccess.get_file_as_string(src)
	var out := FileAccess.open(target, FileAccess.WRITE)
	if out == null:
		return ""
	out.store_string(content)
	out.close()
	return target


func _do_reset() -> void:
	if _backup_first.button_pressed and FileAccess.file_exists("user://save.json"):
		_copy_to_backup("user://save.json", "before_reset")
	var removed: Array = []
	var failed: Array = []
	for f in SAVE_FILES:
		if FileAccess.file_exists("user://" + f):
			var err := DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + f))
			(removed if err == OK else failed).append(f)
	if failed.is_empty():
		_say("Đã xoá: %s. Lần chạy tới game sẽ là người chơi mới." % (", ".join(removed) if not removed.is_empty() else "(không có file nào)"))
	else:
		_say("Không xoá được: " + ", ".join(failed), false)
	refresh()


func _do_clear_tests() -> void:
	var n := _remove_recursive("user://tests")
	_say("Đã xoá user://tests (%d mục)." % n)


func _remove_recursive(path: String) -> int:
	var dir := DirAccess.open(path)
	if dir == null:
		return 0
	var count := 0
	for sub in dir.get_directories():
		count += _remove_recursive(path + "/" + sub)
	for file in dir.get_files():
		dir.remove(file)
		count += 1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return count + 1


func _do_restore() -> void:
	if _backup_select.item_count == 0:
		return
	var backup_name := _backup_select.get_item_text(_backup_select.selected)
	var src := BACKUP_DIR + "/" + backup_name
	if FileAccess.file_exists("user://save.json"):
		_copy_to_backup("user://save.json", "before_restore")
	var out := FileAccess.open("user://save.json", FileAccess.WRITE)
	if out == null:
		_say("Không ghi được save.json.", false)
		return
	out.store_string(FileAccess.get_file_as_string(src))
	out.close()
	_say("Đã khôi phục save.json từ " + backup_name)
	refresh()
