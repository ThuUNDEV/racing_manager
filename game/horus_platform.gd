class_name HorusPlatform
extends Node
## Autoload "Horus": nối game với Horus SDK trong bản Web (Design/25 §7). Chỉ hoạt động khi chạy trong web/shell.html;
## trên desktop/editor/test không làm gì (quảng cáo dùng MockAdsProvider của Ads).
##
## Việc của nó: (1) khôi phục save từ bản sao của app khi máy chưa có save, (2) cài HorusAdsProvider cho Ads,
## (3) sao lưu mỗi lần ghi save sang app, (4) pause/resume của app -> tạm dừng game và tắt tiếng,
## (5) chuyển sự kiện quảng cáo sang analytics, (6) báo platform.ready() khi màn đầu đã vẽ.

var bridge: JavaScriptObject = null
# Autoload lấy bằng đường dẫn node, không gọi bằng tên: script class_name này còn được test (SceneTree) biên dịch trước khi
# autoload đăng ký tên toàn cục.
var _gs: Node = null
var _ads: Node = null
var _iap: Node = null
var _lifecycle_cb: JavaScriptObject = null  # giữ tham chiếu: callback bị giải phóng thì app gọi vào khoảng không


## Bridge của shell nếu đang chạy trên Web và SDK đã khởi động xong; null nếu không.
static func web_bridge() -> JavaScriptObject:
	if not OS.has_feature("web"):
		return null
	var b: Variant = JavaScriptBridge.get_interface("rmHorus")
	if b == null or not bool(b.ok):
		return null
	return b


## Khôi phục save từ bản sao của app khi máy chưa có save hay bản sao lưu nào (cài lại app, xoá dữ liệu WebView).
## Chỉ ghi khi nội dung là một JSON object; GameState.load_game() vẫn kiểm tra đầy đủ sau đó. Trả true nếu đã ghi.
static func restore_backup(save_path: String, bak_path: String, backup: String) -> bool:
	if backup.strip_edges() == "":
		return false
	if FileAccess.file_exists(save_path) or FileAccess.file_exists(bak_path):
		return false
	if typeof(JSON.parse_string(backup)) != TYPE_DICTIONARY:
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_path.get_base_dir()))
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(backup)
	f.close()
	return true


## Sự kiện vòng đời của app -> hành động. ("pause", "ad"): quảng cáo đang hiện, GameState đã tự dừng bằng ad_pause.
## ("pause", "bg"): ra nền như Android native, dùng luồng set_suspended sẵn có (lưu, rồi tính offline khi quay lại).
static func lifecycle_action(kind: String, reason: String) -> Dictionary:
	match kind:
		"pause":
			return {"mute": true, "suspend": reason != "ad", "resume": false}
		"resume":
			return {"mute": false, "suspend": false, "resume": true}
	return {"mute": false, "suspend": false, "resume": false}


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	_gs = get_node("/root/GameState")
	_ads = get_node("/root/Ads")
	_iap = get_node("/root/Iap")
	bridge = web_bridge()
	if bridge == null:
		# Không có SDK (shell mặc định, hoặc SDK lỗi lúc khởi động): tuyệt đối không dùng mock, vì mock phát thưởng miễn phí.
		push_warning("[Horus] Không có Horus SDK: tắt quảng cáo.")
		_ads.provider = AdsProvider.new()
		_iap.provider = IapProvider.new()  # provider rỗng: is_online() = true nhưng buy() luôn lỗi; mock sẽ giao hàng miễn phí
		return
	print("[Horus] SDK %s trên %s" % [String(bridge.sdk), String(bridge.kind)])
	if restore_backup(_gs.SAVE_PATH, _gs.BAK_PATH, String(bridge.backup)):
		print("[Horus] Đã khôi phục save từ bản sao của app.")
	_ads.provider = HorusAdsProvider.new(bridge)
	_iap.provider = HorusIapProvider.new(bridge)
	_iap.iap_event.connect(_on_iap_event)
	_ads.ad_event.connect(_on_ad_event)
	_gs.saved.connect(_on_saved)
	_lifecycle_cb = JavaScriptBridge.create_callback(_on_lifecycle)
	bridge.onLifecycle = _lifecycle_cb
	bridge.drain()
	_signal_ready()
	if OS.is_debug_build():
		_debug_adtest()


## Màn đầu (loading) đã vẽ vài khung thì app mới được bỏ màn chờ.
func _signal_ready() -> void:
	for i in 3:
		await get_tree().process_frame
	bridge.ready()


func _on_lifecycle(args: Array) -> void:
	var kind := String(args[0]) if args.size() > 0 else ""
	var reason := String(args[1]) if args.size() > 1 else ""
	if OS.is_debug_build():
		print("[Horus] lifecycle %s/%s" % [kind, reason])
	var act := lifecycle_action(kind, reason)
	AudioServer.set_bus_mute(0, bool(act["mute"]))
	if bool(act["suspend"]):
		_gs.set_suspended(true)
		bridge.flush()
	elif bool(act["resume"]):
		_gs.set_suspended(false)
		_iap.deliver_pending()  # đơn pending vừa thanh toán xong lúc ở ngoài app


func _on_saved() -> void:
	var json := FileAccess.get_file_as_string(_gs.SAVE_PATH)
	if json != "":
		bridge.mirror(json)


func _on_iap_event(event_name: String, params: Dictionary) -> void:
	bridge.log(event_name, JSON.stringify(params))


func _on_ad_event(event_name: String, params: Dictionary) -> void:
	bridge.log(event_name, JSON.stringify(params))


## Chỉ bản debug: mở ?adtest=<placement> trên URL thì sau vài giây gọi đúng luồng try_show_rewarded của game rồi in kết quả.
## (Thử đường Godot - JS - SDK khi UI chưa có nút.) Bản release không có hàm này chạy.
func _debug_adtest() -> void:
	var pl := String(JavaScriptBridge.eval("new URLSearchParams(location.search).get('adtest') || ''", true))
	if pl == "":
		return
	# Chờ tới khi có dịp thưởng thật (ví dụ lượt đua vừa xong) rồi thử tối đa 3 lần liên tiếp.
	for i in 150:
		if _ads.block_reason(pl) == "":
			break
		await get_tree().create_timer(1.0).timeout
	for attempt in 3:
		var before: String = _gs.coins.format_compact()
		print("[Horus][adtest] #%d %s: can_offer=%s reason=%s coins=%s" % [attempt + 1, pl, _ads.can_offer(pl), _ads.block_reason(pl), before])
		var res := {}
		_ads.try_show_rewarded(pl, func(r: Dictionary) -> void: res.merge(r))
		for i in 120:
			if not res.is_empty():
				break
			await get_tree().create_timer(0.5).timeout
		if res.is_empty():
			print("[Horus][adtest] #%d hết giờ chờ kết quả" % [attempt + 1])
			return
		print("[Horus][adtest] #%d status=%s reward_id=%s coins %s -> %s ad_pause=%s busy=%s" % [attempt + 1, res["status"], res["reward_id"], before, _gs.coins.format_compact(), _gs.ad_pause, _ads.is_busy()])
		await get_tree().create_timer(2.0).timeout
