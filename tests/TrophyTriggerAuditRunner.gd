extends Node

## Spec-vs-grant audit for every trophy in the current catalog.
## Failures are missing unlocks, wrong-mode unlocks, or copy/catalog holes.

var game
var failures := 0
var passes := 0

func check(ok: bool, label: String) -> void:
	if ok:
		passes += 1
		print("PASS ", label)
	else:
		failures += 1
		print("FAIL ", label)

func _ready() -> void:
	if not ("audit-user-trophies" in OS.get_user_data_dir()):
		push_error("TrophyTriggerAudit requires isolated APPDATA containing audit-user-trophies")
		print("TROPHY_AUDIT_SKIPPED need_isolated_appdata user_dir=", OS.get_user_data_dir())
		get_tree().quit(2)
		return
	Analytics.enabled = false
	game = load("res://scenes/Game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.set_process(false)
	catalog_copy()
	action_grants()
	await tutorial_grants()
	threshold_grants()
	await closing_mode_grants()
	await endless7_grants()
	print("TROPHY_AUDIT_DONE pass=", passes, " fail=", failures)
	get_tree().quit(1 if failures else 0)

func fresh() -> void:
	game._reset_new_game_data()
	game._trophies.clear()
	game._save_trophies()
	game.start_menu.visible = false
	game._return_to_menu = false
	game.tutorial_mode = false
	game.tutorial_layer.visible = false
	game._normal_cleared = false
	game._challenge_cleared = false
	game.settling = false
	game.game_result = ""
	game.summary = {}
	game.left_ms = game.DAY_MS

func catalog_copy() -> void:
	var seen := {}
	for def in game._trophy_catalog():
		var id := str(def.id)
		check(not seen.has(id), "catalog id unique " + id)
		seen[id] = true
		check(Loc.ZH.has(str(def.title)), "zh title " + id)
		check(Loc.EN.has(str(def.title)), "en title " + id)
		check(Loc.ZH.has(str(def.desc)), "zh desc " + id)
		check(Loc.EN.has(str(def.desc)), "en desc " + id)
		check(str(Loc.ZH[str(def.title)]) != str(def.title), "zh title not raw key " + id)
		check(str(Loc.EN[str(def.title)]) != str(def.title), "en title not raw key " + id)
	for id in ["primer", "cake", "hen", "share", "flock", "day8", "endless7", "chicken_king", "chicken_emperor", "retail_not_chives", "stock_god", "rank_1", "rank_7", "rank_10", "rank_12"]:
		check(seen.has(id), "catalog contains " + id)
	game._grant_trophy("not_a_real_trophy")
	check(not game._trophies.has("not_a_real_trophy"), "unknown id is ignored")

func action_grants() -> void:
	fresh()
	game.cakes = 1
	game.coins = 200
	game.price = 120
	check(game.sell_cake(true), "sell cake succeeds")
	check(game._trophies.get("cake", false), "cake unlocks on sell")
	check(not game._trophies.get("hen", false), "selling cake does not unlock hen")
	check(game.buy_chick(true), "buy chick succeeds")
	check(game._trophies.get("hen", false), "hen unlocks on wolf buy")
	check(game.buy_shares(true), "buy share succeeds")
	check(game._trophies.get("share", false), "share unlocks on first buy")
	var before: Dictionary = game._trophies.duplicate()
	game.cakes = 1
	game.sell_cake(true)
	check(game._trophies == before, "repeat cake sale does not duplicate")

func tutorial_grants() -> void:
	fresh()
	game._start_tutorial()
	game.hens = 20
	game.coins = 5000
	game.shares = 10
	game.stock_spent = 100
	game.price = 400
	game._refresh()
	check(not game._trophies.get("flock", false), "tutorial does not grant flock from refresh")
	check(not game._trophies.get("retail_not_chives", false), "tutorial does not grant stock from refresh")
	game.tutorial_step = 3
	game.cakes = 1
	check(game.sell_cake(true), "tutorial cake sale succeeds")
	check(game._trophies.get("cake", false), "tutorial cake sale still persists the trophy")
	var toasts_before := _toast_texts()
	game._leave_tutorial(true)
	check(game._trophies.get("primer", false), "completing tutorial unlocks primer")
	check(game._trophies.get("cake", false), "tutorial cake trophy survives the reset into day 1")
	check(_toast_has_trophy("primer", toasts_before), "primer shows an unlock toast after tutorial")
	fresh()
	game._start_tutorial()
	game._leave_tutorial(false)
	check(not game._trophies.get("primer", false), "aborting tutorial does not unlock primer")

func threshold_grants() -> void:
	fresh()
	game.hens = 14
	game._refresh()
	check(not game._trophies.get("flock", false), "14 birds do not unlock flock")
	game.hens = 15
	game._refresh()
	check(game._trophies.get("flock", false), "15 birds unlock flock")
	game.hens = 99
	game._refresh()
	check(not game._trophies.get("chicken_king", false), "99 birds do not unlock chicken king")
	game.hens = 100
	game._refresh()
	check(game._trophies.get("chicken_king", false), "100 birds unlock chicken king")
	game.hens = 199
	game._refresh()
	check(not game._trophies.get("chicken_emperor", false), "199 birds do not unlock emperor")
	game.hens = 200
	game._refresh()
	check(game._trophies.get("chicken_emperor", false), "200 birds unlock emperor")

	fresh()
	game.shares = 0
	game.stock_spent = 0
	game.stock_sold = 1999
	game._refresh()
	check(not game._trophies.get("retail_not_chives", false), "stock gain 1999 does not unlock retail")
	game.stock_sold = 2000
	game._refresh()
	check(game._trophies.get("retail_not_chives", false), "stock gain 2000 unlocks retail")
	check(not game._trophies.get("stock_god", false), "stock gain 2000 does not unlock stock god")
	game.stock_sold = 3000
	game._refresh()
	check(game._trophies.get("stock_god", false), "stock gain 3000 unlocks stock god")

	fresh()
	game.coins = 18000
	game.shares = 0
	game._refresh()
	check(game._trophies.get("rank_6", false), "18000 wealth unlocks Full-Belly Farm")
	check(not game._trophies.get("rank_7", false), "18000 wealth does not unlock Corner Vendor")
	game.endless_mode = true
	game._refresh()
	check(game._trophies.get("rank_6", false), "endless uses the same rank ladder")
	check(not game._trophies.get("rank_12", false), "18000 does not unlock Clucklon Musk")

func closing_mode_grants() -> void:
	fresh()
	game.day = 7
	game.hens = 15
	game.coins = 3000
	game.left_ms = 0
	game.eggs = 0
	game.ready_eggs = 0
	game.pending_eggs = 0
	await game._next_day()
	check(not game._trophies.get("day8", false), "day 7 close does not unlock day8")
	check(game._trophies.get("rank_4", false), "3000 wealth unlocks Fence Coop")
	check(not game._trophies.get("rank_6", false), "3000 wealth does not unlock Full-Belly Farm")

	fresh()
	game.day = 8
	game.hens = 1
	game.coins = 0
	game.shares = 0
	game.left_ms = 0
	game.eggs = 0
	game.ready_eggs = 0
	game.pending_eggs = 0
	await game._next_day()
	check(game.game_result == "flop", "day 8 shortfall is a flop")
	check(game._trophies.get("day8", false), "day 8 flop still unlocks day8")
	check(game._trophies.get("rank_1", false), "day 8 flop still unlocks rank 1")
	check(not game._trophies.get("rank_7", false), "campaign flop at 0 does not unlock Corner Vendor")

	fresh()
	game.challenge_mode = true
	game.day = 20
	game.hens = 1
	game.coins = 30000
	game.shares = 0
	game.left_ms = 0
	game.eggs = 0
	game.ready_eggs = 0
	game.pending_eggs = 0
	await game._next_day()
	check(game.game_result == "flop", "challenge bird shortfall is a flop")
	check(game._trophies.get("rank_7", false), "challenge flop at 30000 still unlocks Corner Vendor")
	check(not game._trophies.get("rank_8", false), "challenge flop at 30000 does not unlock Farm Keeper")

	fresh()
	game.challenge_mode = true
	game.day = 20
	game.hens = 58
	game.coins = 22500
	game.shares = 0
	game.left_ms = 0
	game.eggs = 0
	game.ready_eggs = 0
	game.pending_eggs = 0
	await game._next_day()
	check(game.game_result == "won", "challenge clear is won")
	check(game._trophies.get("rank_7", false), "challenge clear 22500 unlocks Corner Vendor")
	check(not game._trophies.get("rank_8", false), "challenge clear 22500 does not unlock Farm Keeper")

	fresh()
	game.hens = 15
	game._save()
	game._trophies.clear()
	game._save_trophies()
	game._load()
	game._refresh()
	check(game._trophies.get("flock", false), "loading a 15-bird save repairs flock on refresh")

func endless7_grants() -> void:
	fresh()
	game.endless_mode = true
	game.day = 6
	game.hens = 1
	game.coins = 120
	game.left_ms = 0
	game.eggs = 0
	game.ready_eggs = 0
	game.pending_eggs = 0
	await game._next_day()
	await game._wake()
	check(game.day == 7, "wake from day 6 lands on day 7")
	check(game._trophies.get("endless7", false), "waking into endless day 7 unlocks endless7")

	fresh()
	game.endless_mode = true
	game.day = 7
	game.settling = false
	game.summary = {}
	game._refresh()
	check(game._trophies.get("endless7", false), "already on endless day 7, refresh repairs endless7")

	fresh()
	game.endless_mode = true
	game.day = 7
	game.left_ms = game.DAY_MS
	game._save()
	game._trophies.clear()
	game._save_trophies()
	game._load()
	game._refresh()
	check(game._trophies.get("endless7", false), "loading a mid-day endless day 7 save repairs endless7")

	fresh()
	game.challenge_mode = true
	game.day = 20
	game.hens = 58
	game.coins = 22500
	game.shares = 0
	game.left_ms = 0
	game.eggs = 0
	game.ready_eggs = 0
	game.pending_eggs = 0
	await game._next_day()
	check(game.game_result == "won", "setup: challenge clear before endless continue")
	game._continue_endless_from_finale()
	# _wake is async; wait for day to advance.
	var waits := 0
	while game.day < 21 and waits < 40:
		await get_tree().create_timer(0.05).timeout
		waits += 1
	check(game.endless_mode and game.day >= 7, "challenge continue enters endless past day 7")
	check(game._trophies.get("endless7", false), "challenge continue into endless grants endless7 by current day number")

func _toast_texts() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for host in [game.toast_box, game.start_menu.get_node_or_null("MenuToasts")]:
		if host == null:
			continue
		for child in host.get_children():
			out.append(_label_text(child))
	return out

func _toast_has_trophy(id: String, before: PackedStringArray) -> bool:
	var title := Loc.t("trophy_" + id)
	if id == "primer":
		title = Loc.t("trophy_primer")
	var needle := Loc.t("toast_trophy", [title])
	for text in _toast_texts():
		if text == needle or needle in text:
			var seen := false
			for old in before:
				if old == text:
					seen = true
					break
			if not seen:
				return true
	return false

func _label_text(n: Node) -> String:
	if n is Label:
		return (n as Label).text
	var acc := ""
	for child in n.get_children():
		var piece := _label_text(child)
		if piece != "":
			acc += piece
	return acc
