extends Node


func _ready() -> void:
	print("TUTORIAL_SMOKE_START")
	var game = load("res://scenes/Game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	if not game.tutorial_mode:
		game._start_tutorial()
	assert(game.tutorial_mode)
	assert(game._tutorial_status() == "in_progress")
	assert(game.tutorial_day == 1 and game.tutorial_step == 0)
	game._tutorial_next_pressed()
	assert(game.tutorial_step == 1)
	assert(game.collect_egg(true))
	assert(game.collect_egg(true))
	assert(game.collect_egg(true))
	await get_tree().create_timer(1.2).timeout
	assert(game.tutorial_step == 2)
	assert(game.start_hatch(true))
	assert(game.tutorial_step == 3)
	await get_tree().create_timer(4.2).timeout
	assert(game.cakes >= 1)
	assert(game.sell_cake(true))
	await get_tree().create_timer(1.0).timeout
	assert(game.tutorial_step == 4)
	assert(game.buy_chick(true))
	assert(game.tutorial_step == 5)
	await game._next_day()
	await game._wake()
	assert(game.tutorial_day == 2 and game.tutorial_step == 0)
	assert(game.price == 120)
	assert(game.collect_chick(true))
	await get_tree().create_timer(1.0).timeout
	assert(game.tutorial_step == 1)
	game._tutorial_next_pressed()
	assert(game.tutorial_step == 2)
	assert(game.buy_shares(true))
	assert(game.tutorial_step == 3 and game.shares == 1)
	await game._next_day()
	await game._wake()
	assert(game.tutorial_day == 3 and game.tutorial_step == 0)
	assert(game.price == 150)
	game._tutorial_next_pressed()
	assert(game.tutorial_step == 1)
	assert(game.sell_shares(true))
	await get_tree().create_timer(1.0).timeout
	assert(game.tutorial_step == 2 and game.shares == 0)
	game._tutorial_next_pressed()
	assert(not game.tutorial_mode)
	assert(game._tutorial_status() == "completed")
	game._write_tutorial_status("in_progress")
	assert(game._tutorial_status() == "in_progress")
	game._write_tutorial_status("completed")
	print("TUTORIAL_SMOKE_OK")
	get_tree().quit(0)
