extends SceneTree

const BigNumber = preload("res://core/math/big_number.gd")
const MoneyCodec = preload("res://core/save/money_codec.gd")
var fails := 0
var gs: Node

func check(ok: bool, label: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + label)
	if not ok:
		fails += 1

func n(value: String) -> BigNumber:
	return BigNumber.parse_decimal(value)

func reset() -> void:
	gs.active = false
	gs.simulate_write_failure = false
	gs.reset_progress()

func finish_race() -> void:
	if gs.phase == "countdown":
		gs.advance(3.0)
	var guard := 0
	while gs.phase == "racing" and guard < 2000:
		gs.advance(0.1)
		guard += 1

func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	reset()
	check(gs.SAVE_PATH.contains("/tests/"), "isolated save; real player progress untouched")
	gs.coins = n("1e300")
	check(gs.buy("engine") and gs.level_of("engine") == 1, "huge wallet buys without int/float conversion")
	check(gs.save_game(), "write BigNumber save")
	gs.init_new_game()
	check(gs.load_game() == "ok" and gs.coins.equals("1e300"), "huge wallet round trip")
	check(gs.level_of("engine") == 1, "small cost below wallet precision still commits level")
	reset()
	var old := gs.coins as BigNumber
	gs.simulate_write_failure = true
	check(not gs.buy("engine") and gs.level_of("engine") == 0 and gs.coins.equals(old), "failed purchase rolls back coins and level")
	check(not gs.claim_daily() and gs.last_daily_day == -1 and gs.gems == 100, "failed daily claim rolls back timestamp and gems")
	gs.saved_online_rate = n("8")
	gs.last_accrual_utc = Time.get_unix_time_from_system() - 3600
	var timestamp: float = gs.last_accrual_utc
	check(not gs.settle_offline() and gs.coins.equals(old) and gs.last_accrual_utc == timestamp, "offline save failure preserves previous accrual")
	gs.simulate_write_failure = false
	check(gs.settle_offline() and gs.coins.compare(old.add(n("14400"))) >= 0, "offline retry credits once")
	var claimed: BigNumber = gs.coins
	check(gs.settle_offline() and gs.coins.equals(claimed), "offline replay does not duplicate hours")
	reset()
	var totals := []
	for fps in [30, 60, 120]:
		gs.coins = BigNumber.zero()
		gs.income_remainder = BigNumber.zero()
		gs._income_micro_fraction = 0.0
		for i in fps * 60:
			gs.tick_income(1.0 / fps)
		totals.append(gs.coins.add(gs.income_remainder))
	check(totals[0].equals(480) and totals[1].equals(480) and totals[2].equals(480), "60s income identical at 30/60/120 FPS")
	reset()
	var raw := '{"schema_version":3,"coins":9007199254740993,"levels":{"engine":4},"saved_online_rate":8,"gems":101}'
	var parsed: Dictionary = MoneyCodec.parse(raw)
	gs._apply(parsed)
	# Save v3 là thang 20 cấp: migration nhân với level_subdivision (200 cấp).
	check(gs.coins.equals("9007199254740993") and gs.level_of("engine") == 4 * Pricing.level_subdivision() and gs.gems == 101, "legacy integer >2^53 migrates exactly")
	check(gs.save_game(), "commit migration v4")
	gs.init_new_game()
	gs.load_game()
	check(gs.coins.equals("9007199254740993"), "migration remains exact after JSON round trip")
	var corrupted: Dictionary = MoneyCodec.encode(gs._save_data())
	corrupted["coins"]["significand"] = "NaN"
	check(not gs._valid_save(corrupted), "reject malformed BigNumber save")
	reset()
	gs.coins = n("1e12")
	var lvl := int(GameData.economy()["business"]["expansion_min_revenue_level"])
	for kind in Balance.REVENUE:
		gs.levels[kind] = lvl
	check(gs.expansion_state() == "points", "wealth alone cannot unlock a league")
	gs.unlocked_tier = 1
	gs.begin_countdown()
	gs.advance(3.0)
	var snapshot: BigNumber = gs.race_snapshot["reward_rate"]
	gs.buy("ticket")
	check(gs.race_snapshot["reward_rate"].equals(snapshot), "mid-race revenue upgrade does not change reward snapshot")
	check(gs.request_expansion() and gs.business_tier == 0, "expansion queues until the current race completes")
	finish_race()
	check(gs.business_tier == 1 and gs.phase == "countdown", "queued expansion commits at race boundary")
	check(gs.online_rate().equals(8000000) and gs.level_of("ticket") == 0, "new business starts its own four levels")
	check(gs.revenue_history["0"]["ticket"] == lvl + 1 and gs.processed_rewards.has("business_open/1"), "old levels and unique opening ID saved")
	var gems1: int = gs.gems
	check(not gs.request_expansion() and gs.gems == gems1, "cannot reopen same business or duplicate grant")
	gs.unlocked_tier = 2
	for kind in Balance.REVENUE:
		gs.levels[kind] = lvl
	check(gs.expansion_state() == "car", "next class is required before business tier 2")
	gs.coins = n("1e40")  # giá xe hạng 2 theo thang bậc mới (2,3AA)
	check(gs.buy_car("car_nova_tia_chop") and gs.select_car("car_nova_tia_chop"), "purchase and select new car")
	check(gs.level_of("engine") == 0, "car upgrades are stored per owned car")
	gs.coins = n("1e30")
	gs.simulate_write_failure = true
	check(not gs.request_expansion() and gs.business_tier == 1, "expansion request write failure rolls back")
	gs.simulate_write_failure = false
	check(gs.request_expansion() and gs.business_tier == 2, "countdown expansion switches tier safely")
	check(not gs.select_car(GameData.starter_car_id()), "cannot select ineligible old car in higher league")
	var before_buy: BigNumber = gs.coins
	check(gs.buy("engine") and gs.coins.equals(before_buy.subtract_checked(Pricing.part_cost(1, 0, "engine"))), "higher-tier upgrade charges fixed entry-tier price")
	check(gs.save_game(), "save ownership and tier")
	gs.init_new_game()
	check(gs.load_game() == "ok" and gs.business_tier == 2 and gs.level_of("engine") == 1, "ownership, tier and car levels survive reload")
	check(gs.processed_rewards.has("business_open/2"), "opening reward id survives reload")
	reset()
	gs.coins = n("1e300")
	for next_tier in range(1, 6):
		gs.unlocked_tier = next_tier
		for kind in Balance.REVENUE:
			gs.levels[kind] = Balance.max_level()
		var old_rate: BigNumber = gs.online_rate()
		var required_class := int(GameData.league(next_tier)["min_car_class"])
		for car: Dictionary in GameData.cars():
			if int(car["class"]) == required_class:
				if not gs.owned_cars.has(car["id"]):
					gs.buy_car(car["id"])
				gs.select_car(car["id"])
				break
		check(gs.request_expansion() and gs.business_tier == next_tier and gs.online_rate().compare(old_rate) >= 0, "business tier %d opens without lowering max old income" % next_tier)
	check(gs.expansion_state() == "complete", "sixth tier completes the finite content ladder")
	reset()
	gs.completed_seasons = 1
	gs.scout_points = 100
	gs.coins = n("1e6")
	check(gs.recruit_driver("driver_binh") and gs.select_driver("driver_binh"), "SP + BigNumber recruitment and selection")
	var coins2: BigNumber = gs.coins
	check(not gs.recruit_driver("driver_binh") and gs.coins.equals(coins2), "owned driver cannot be charged twice")
	reset()
	gs.begin_countdown()
	gs.advance(3.0)
	gs.simulate_write_failure = true
	finish_race()
	check(gs.phase == "save_error" and gs.stage_index == 0 and gs.coins.equals(1000), "reward remains unpublished during write failure")
	gs.simulate_write_failure = false
	check(gs.save_game(), "persist recovery checkpoint while reward is pending")
	gs.init_new_game()
	gs.load_game()
	gs.active = false
	gs.activate()
	check(gs.stage_index == 1 and gs.phase == "countdown" and gs.processed_rewards.has("race/s1/st1"), "finished checkpoint recovers reward exactly once after restart")
	reset()
	print("economy_test: %d failures" % fails)
	quit(1 if fails else 0)
