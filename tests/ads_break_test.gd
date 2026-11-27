extends SceneTree
## Ads Break (Design/26 §7, §17): điều kiện, máy trạng thái, thưởng, bộ đếm, mở gói no_ads và việc giữ vòng đua trong main.
const PopupAnim = preload("res://ui/popup_anim.gd")
const MockAds = preload("res://game/ads/mock_ads_provider.gd")
var failures := 0
var state: Node
var ads: Node
var iap: Node
var ctl: RefCounted
var mock: RefCounted
var events: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL ", message)

func settle() -> void:
	for i in 10:
		await process_frame

func now() -> float:
	return Time.get_unix_time_from_system()

## Trạng thái đủ mọi điều kiện để break.
func fresh() -> void:
	state.init_new_game()
	state.active = false
	state.tutorial["gated"] = false
	state.tutorial["state"] = "done"
	state.completed_races = 20
	state.ad_state["play_sec"] = 2000.0
	state.simulate_write_failure = false
	ctl.reset()
	ctl.warm_from = now() - 1000.0
	mock = MockAds.new()
	ads.provider = mock
	events.clear()

func why() -> String:
	return ctl.due()["why"]

## Chạy tới lúc quảng cáo được gọi.
func to_ad() -> void:
	check(ctl.begin(), "bắt đầu break (%s)" % why())
	ctl.tick(0.1)
	ctl.tick(1.5)

func finish_ad() -> void:
	for i in 4:
		await process_frame

func run() -> void:
	PopupAnim.enabled = false
	state = root.get_node("GameState")
	ads = root.get_node("Ads")
	iap = root.get_node("Iap")
	state.SAVE_PATH = "user://tests/ads_break.json"
	state.BAK_PATH = "user://tests/ads_break.bak"
	state.TMP_PATH = "user://tests/ads_break.tmp"
	DirAccess.make_dir_recursive_absolute("user://tests")
	GameData.reload()
	state.set_process(false)
	ads.set_process(false)
	ctl = ads.break_ctl
	ads.ad_event.connect(func(n: String, p: Dictionary) -> void: events.append([n, p.get("why", "")]))

	fresh()
	check(ctl.due()["due"], "đủ điều kiện")
	state.ad_state["free"] = true
	check(why() == "no_ads", "mua Đội tự do thì không break")
	fresh()
	state.tutorial["state"] = "active"
	check(why() == "early", "tutorial chưa xong")
	fresh()
	state.completed_races = 7
	check(why() == "early", "chưa đủ 8 lượt")
	fresh()
	state.ad_state["play_sec"] = 800.0
	check(why() == "early", "chưa đủ 15 phút chơi")
	fresh()
	ctl.warm_from = now() - 100.0
	check(why() == "warmup", "2 phút đầu phiên")
	fresh()
	state.ad_state["break"] = {"last_race": 13, "last_t": now() - 1000.0}
	check(why() == "every", "chưa đủ 8 lượt từ break trước")
	state.ad_state["break"] = {"last_race": 12, "last_t": now() - 100.0}
	check(why() == "cooldown", "chưa đủ 7 phút")
	var hour: Array = []
	for i in 6:
		hour.append(now() - 500.0 - i)
	state.ad_state["break"] = {"last_race": 1, "last_t": now() - 500.0, "times": hour}
	check(why() == "cooldown", "tối đa 6 lần mỗi giờ")
	fresh()
	state.ad_state["last"] = {"free_gems": int(now()) - 10}
	check(why() == "rewarded", "vừa xem rewarded")
	fresh()
	mock.online = false
	check(why() == "blocked", "mất mạng")
	mock.online = true
	mock.inter_ready = false
	check(why() == "blocked", "chưa tải interstitial")

	# Chạm màn hình: chờ ngơi tay, quá 3 giây thì bỏ.
	fresh()
	ctl.note_touch()
	ctl.begin()
	ctl.tick(0.5)
	check(ctl.step == ctl.Step.WAITING_TOUCH, "vừa chạm thì chờ")
	for i in 6:
		ctl.note_touch()
		ctl.tick(0.5)
	check(not ctl.active() and mock.inter_shows == 0, "chạm liên tục quá 3 giây thì bỏ lượt")
	fresh()
	ctl.begin()
	ctl.tick(0.1)
	ctl.tick(0.1, true)
	check(not ctl.active() and mock.inter_shows == 0, "bị che khi đang hiện thẻ thì hủy")

	# Xem xong: một lần thưởng dù callback bắn hai lần.
	fresh()
	mock.double_fire = true
	var bonus = ctl.bonus()
	var coins = state.coins
	to_ad()
	check(mock.inter_shows == 1 and state.ad_pause, "đang phát, game tạm dừng")
	await finish_ad()
	check(not ctl.active() and not state.ad_pause, "xong thì chạy tiếp")
	check(state.coins.equals(coins.add(bonus)), "cộng đúng một lần 90 giây thu nhập")
	check(ads.breaks_today() == 1 and why() == "every", "đã đếm break")
	check(int(state.ad_state.get("count", 0)) == 0, "không tính vào trần rewarded")

	# Không hiện được và quá giờ: không thưởng, không cooldown.
	fresh()
	mock.inter_shown = false
	coins = state.coins
	to_ad()
	await finish_ad()
	check(state.coins.equals(coins) and ads.breaks_today() == 0 and why() == "", "shown=false: không thưởng, không cooldown")
	fresh()
	mock.tree = self
	mock.delay_sec = 0.2
	coins = state.coins
	to_ad()
	ctl.tick(90.0)
	check(not ctl.active() and not state.ad_pause, "quá 90 giây thì bỏ")
	await create_timer(0.4).timeout
	check(state.coins.equals(coins) and ads.breaks_today() == 0, "callback đến muộn bị bỏ qua")

	# Lưu lỗi: vẫn tính cooldown, tiền cộng ở lần sau.
	fresh()
	coins = state.coins
	bonus = ctl.bonus()
	to_ad()
	state.simulate_write_failure = true
	await finish_ad()
	check(state.coins.equals(coins) and ads.breaks_today() == 1 and why() == "every", "lưu lỗi: chưa cộng tiền, vẫn đếm break")
	state.simulate_write_failure = false
	ctl.begin()
	check(state.coins.equals(coins.add(bonus)), "thử lại thì cộng tiền")
	ctl.begin()
	check(state.coins.equals(coins.add(bonus)), "không cộng lần hai")

	# Đủ 3 break trong ngày: gói mở và còn mở sang ngày sau.
	fresh()
	for i in 3:
		check(iap.block_reason("offer_noads_bundle") == "locked", "gói còn khóa sau %d break" % i)
		state.completed_races += 8
		if state.ad_state.has("break"):
			state.ad_state["break"]["last_t"] = now() - 500.0
		to_ad()
		await finish_ad()
	check(ads.breaks_today() == 3 and iap.block_reason("offer_noads_bundle") == "", "đủ 3 break thì mở gói")
	state.ad_state["break"]["day"] = int(state.ad_state["break"]["day"]) - 1
	check(ads.breaks_today() == 0 and iap.block_reason("offer_noads_bundle") == "", "sang ngày: đếm lại, gói vẫn mở")
	check(iap.sales_popup_queue().has("offer_noads_bundle"), "gói vào hàng đợi popup")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(state.SAVE_PATH))
	state._apply_iap(saved)
	check(iap.block_reason("offer_noads_bundle") == "", "còn mở sau khi nạp save")

	# Giao diện: thẻ hiện, vòng đua đứng yên, xong thì chạy tiếp.
	fresh()
	root.content_scale_factor = 1.0
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(390, 778)
	var main: Control = load("res://ui/main.gd").new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle()
	main.set_process(false)
	main._select_tab(0)
	main._close_overlay()
	await settle()
	state.iap["buys"].append_array([{"sku": "starter_1"}, {"sku": "starter_2"}, {"sku": "starter_3"}])
	main._sales_position = 1
	check(not main._hold_for_sales_popup() and ctl.active(), "không có popup bán hàng thì xét Ads Break")
	check(main._tick_ads_break(0.1), "giữ vòng đua")
	await settle()
	check(main._break_card.visible, "thẻ báo trước hiện")
	var card := main._break_card.find_child("Card", true, false) as Control
	check(main.get_global_rect().encloses(card.get_global_rect()), "thẻ nằm trong màn hình")
	if "--capture" in OS.get_cmdline_user_args():
		for width: int in [320, 390, 412]:
			root.size = Vector2i(width, 778)
			await settle()
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://Design/Previews/ads_break")
			root.get_texture().get_image().save_png("res://Design/Previews/ads_break/card_%d.png" % width)
	main._tick_ads_break(1.5)
	await finish_ad()
	check(not main._tick_ads_break(0.1) and not main._break_card.visible, "xong thì thẻ ẩn, chạy tiếp")

	fresh()
	main._sales_position = 1
	main._hold_for_sales_popup()
	await settle()
	check(main._sales_sku == "starter_1" and not ctl.active(), "đã hiện popup bán hàng thì không break")

	print("ADS_BREAK_TEST failures=", failures)
	quit(1 if failures > 0 else 0)
