extends Node

func _ready() -> void:
	assert("audit-user" in OS.get_user_data_dir(), "Run with isolated APPDATA")
	var game = load("res://scenes/Game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	game._write_tutorial_status("dismissed")
	if FileAccess.file_exists(game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.SAVE_PATH))
	game._enter_play("challenge")
	game.set_process(false)
	assert(game.day == 9 and game.challenge_mode)
	for d in [12, 13, 16, 17]:
		game.day = d
		game._refresh()
		assert(str(game._chick_cost()) in game.wolf_buy.text)
	# Trades commit before any animation or settlement can cancel callbacks.
	game.coins = 1000
	game.cakes = 1
	game.shares = 1
	game.price = 220
	game.hens = 2
	assert(game.sell_cake(true))
	assert(game.coins == 1150)
	assert(game.sell_shares(true))
	assert(game.coins == 1370)
	assert(game.sell_hen(true))
	assert(game.coins == 1410)
	game._fx += 1
	await get_tree().create_timer(0.8).timeout
	assert(game.coins == 1410)
	# Every gate: exact hit, one coin short, one bird short.
	for gate in game.CHALLENGE_GATES:
		for miss in [0, 1, 2]:
			game.day = int(gate.day)
			game.challenge_mode = true
			game.endless_mode = false
			game.settling = false
			game.game_result = ""
			game.coins = int(gate.wealth) - (1 if miss == 1 else 0)
			game.hens = int(gate.birds) - (1 if miss == 2 else 0)
			game.shares = 0
			game.young_chicks = 0
			game.hatching = 0
			game.hatched = 0
			game.eggs = 0
			game.ready_eggs = 0
			game.pending_eggs = 0
			game.baking = 0
			game.left_ms = 0
			await game._next_day()
			var expected := "flop" if miss > 0 else ("won" if int(gate.day) == 20 else "")
			assert(game.game_result == expected)
			for lang in ["en", "zh"]:
				Loc.lang = lang
				var wait_id: int = game.card._cta_wait_id
				game._apply_locale()
				assert(game.game_result == expected)
				if expected != "":
					assert(game.card._finale_kind == ("win" if expected == "won" else "flop"))
					assert(game.card._cta_wait_id == wait_id)
					assert(game.card._wealth_pts.back() == game.total())
			game._save()
			game._load()
			game._restore_settlement()
			assert(game.game_result == expected)
	# Day 8 miss kicks the player out. No challenge unlock, no continue.
	game.challenge_mode = false
	game.endless_mode = false
	game._normal_cleared = false
	for miss in [1, 2, 0]:
		game.day = 8
		game.settling = false
		game.game_result = ""
		game.coins = game.WEALTH_GOAL - (1 if miss == 1 else 0)
		game.hens = game.FLOCK_GOAL - (1 if miss == 2 else 0)
		game.shares = 0
		game.young_chicks = 0
		game.hatching = 0
		game.hatched = 0
		game.eggs = 0
		game.ready_eggs = 0
		game.pending_eggs = 0
		game.baking = 0
		game.left_ms = 0
		game._capture_dawn()
		await game._next_day()
		if miss > 0:
			assert(game.game_result == "flop")
			assert(not game._normal_cleared)
			assert(game.card._finale_kind == "campaign_flop")
			assert(not game.card.get_node("Finale/Actions/EndlessBtn").visible)
			assert(game.card.get_node("Finale/Actions/AdBtn").visible)
			game._continue_endless_from_finale()
			assert(game.game_result == "flop" and not game.challenge_mode)
		else:
			assert(game.game_result == "ended")
			assert(game._normal_cleared)
			assert(game.card._finale_kind == "campaign")
			assert(game.card.get_node("Finale/Actions/EndlessBtn").visible)
			assert(not game.card.get_node("Finale/Actions/AdBtn").visible)
	# Rewind restores stage pricing and save state.
	game.game_result = ""
	game.settling = false
	game.challenge_mode = true
	game.endless_mode = false
	game.day = 13
	game.coins = 4321
	game._capture_dawn()
	game.day = 17
	game.coins = 1
	await game._rewind_to_dawn()
	assert(game.day == 13 and game.coins == 4321 and game._chick_cost() == 60)
	# Supply fixed eggs, disable external production, compare all oven levels.
	game.settling = false
	game.game_result = ""
	game.left_ms = 20000
	for level in range(1, 7):
		var baseline: Array = []
		for fps in [30, 60, 120]:
			game.bakery_level = level
			game.eggs = 200
			game.cakes = 0
			game.baking = 0
			game._bake_acc = 0.0
			game._bake_hold = 0.0
			game._egg_acc = 0.0
			for frame in range(fps * 16):
				game._advance_baking(1.0 / fps)
			var actual: Array = [game.eggs, game.cakes, game.baking]
			if baseline.is_empty():
				baseline = actual
			assert(actual == baseline, "FPS mismatch level %d" % level)
	print("CHALLENGE_SMOKE_OK")
	get_tree().quit(0)
