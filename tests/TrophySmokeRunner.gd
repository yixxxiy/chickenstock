extends Node

var game
var failures := 0
var passes := 0
var completed_cases := 0

func check(ok: bool, label: String) -> void:
	if ok:
		passes += 1
		print("PASS ", label)
	else:
		failures += 1
		print("FAIL ", label)

func _ready() -> void:
	if not ("audit-user-trophies" in OS.get_user_data_dir()):
		push_error("TrophySmokeTest requires isolated APPDATA containing audit-user-trophies")
		get_tree().quit(2)
		return
	Analytics.enabled = false
	game = load("res://scenes/Game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.set_process(false)
	for spec in [
		["daily close", 3, false, 1, 0, ""],
		["campaign clear", 8, false, 15, 3000, "ended"],
		["campaign flop", 8, false, 1, 0, "flop"],
		["challenge clear", 20, true, 58, 30000, "won"],
		["challenge flop", 20, true, 1, 0, "flop"],
		["endless close", 21, false, 1, 30000, "", true],
	]:
		await settle_case(spec)
	await threshold_cases()
	check(completed_cases == 10, "all settlement scenarios completed without script aborts")
	print("TROPHY_SMOKE_DONE pass=", passes, " fail=", failures)
	get_tree().quit(1 if failures else 0)

func prepare_case(spec: Array) -> void:
	game._reset_new_game_data()
	game._trophies.clear()
	game._save_trophies()
	game.start_menu.visible = false
	game._return_to_menu = false
	game.tutorial_mode = false
	game._normal_cleared = false
	game._challenge_cleared = false
	game.challenge_mode = spec[2]
	game.endless_mode = spec.size() > 6 and spec[6]
	game.day = spec[1]
	game.hens = spec[3]
	game.coins = spec[4]
	game.young_chicks = 0
	game.hatching = 0
	game.hatched = 0
	game.eggs = 0
	game.ready_eggs = 0
	game.pending_eggs = 0
	game.baking = 0
	game.shares = 300 if game.challenge_mode else 50
	game.price = 100
	game.stock_spent = game.shares * game.price
	game.stock_sold = 0
	game.news = "hoard"
	game.left_ms = 0
	# Pin the market RNG; the gain crosses both stock trophy thresholds at close.
	seed(17)

func settle_case(spec: Array) -> void:
	prepare_case(spec)
	check(game.stock_profit() == 0, str(spec[0]) + " starts below stock thresholds")
	await game._next_day()
	var label := str(spec[0])
	check(game.game_result == spec[5], label + " terminal result")
	check(game.stock_profit() >= 3000, label + " closing gain reaches 3000")
	check(game._trophies.has("retail_not_chives"), label + " stock 2000 awarded at close")
	check(game._trophies.has("stock_god"), label + " stock 3000 awarded at close")
	if game.day == 8:
		check(game._trophies.has("day8"), label + " finished eight days")
		for rank in game.RANKS:
			if int(rank.lv) <= game.CAMPAIGN_RANK_CAP and game.total() >= int(rank.min):
				check(game._trophies.has("rank_%d" % int(rank.lv)), label + " closing rank " + str(rank.lv))
	elif game.challenge_mode:
		check(game._trophies.has("wealth_20k") == (spec[5] == "won"), label + " challenge wealth requires clear")
	var earned: Dictionary = game._trophies.duplicate()
	game._load_trophies()
	check(game._trophies == earned, label + " trophies survive reload")
	var dock := game.get_node("Dock") as Control
	check(not dock.visible and dock.z_index == 8, label + " settlement hides dock at z8")
	# A save made by the broken version already has its closing result but no trophies.
	game._save()
	game._trophies.clear()
	game._save_trophies()
	game._load()
	check(game._trophies == earned, label + " loading old save repairs before menu restart")
	game._restore_settlement()
	check(game._trophies == earned, label + " old closing save repairs missed trophies")
	var toast_count: int = game.toast_box.get_child_count()
	game._restore_settlement()
	check(game.toast_box.get_child_count() == toast_count, label + " reopening does not repeat awards")
	game._load_trophies()
	check(game._trophies == earned, label + " repaired trophies persisted")
	completed_cases += 1

func threshold_cases() -> void:
	for values in [[499, 1999], [500, 2000], [999, 2999], [1000, 3000]]:
		prepare_case(["boundary", 8, false, 1, values[0], "flop"])
		game.shares = 0
		game.stock_spent = 0
		game.stock_sold = values[1]
		await game._next_day()
		var label := "boundary wealth=%d stock_gain=%d" % [values[0], values[1]]
		check(game.game_result == "flop", label + " remains a campaign failure")
		check(not game._normal_cleared, label + " does not unlock challenge")
		check(game._trophies.has("day8"), label + " completion trophy still awarded")
		check(game._trophies.has("retail_not_chives") == (values[1] >= 2000), label + " stock 2000 threshold")
		check(game._trophies.has("stock_god") == (values[1] >= 3000), label + " stock 3000 threshold")
		for rank in game.RANKS:
			var expected: bool = int(rank.lv) <= game.CAMPAIGN_RANK_CAP and values[0] >= int(rank.min)
			check(game._trophies.has("rank_%d" % int(rank.lv)) == expected, label + " rank " + str(rank.lv))
		completed_cases += 1
