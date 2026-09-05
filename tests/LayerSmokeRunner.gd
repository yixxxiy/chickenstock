extends Node


func _ready() -> void:
	print("LAYER_SMOKE_START")
	var game = load("res://scenes/Game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
	_assert_stack(game)
	if not game.tutorial_mode:
		game._start_tutorial()
	await get_tree().process_frame
	assert(game.tutorial_mode)
	assert(game.tutorial_layer.visible)
	assert(game.tutorial_layer.z_index > _max_bird_z(game))
	game._open_settings()
	await get_tree().process_frame
	assert(game.settings_pop.visible)
	assert(not game.tutorial_layer.visible)
	assert(game.settings_pop.z_index > game.tutorial_layer.z_index)
	game._close_settings()
	await get_tree().process_frame
	assert(game.tutorial_layer.visible)
	game._show_main_menu()
	await get_tree().process_frame
	assert(game.start_menu.visible)
	assert(not game.tutorial_layer.visible)
	assert(game.start_menu.z_index > game.settings_pop.z_index)
	assert(game.menu_backdrop.visible)
	print("LAYER_SMOKE_OK")
	get_tree().quit(0)


func _assert_stack(game) -> void:
	var dock_z: int = game.get_node("Dock").z_index
	var hud_z: int = game.get_node("HUD").z_index
	var bird_z := _max_bird_z(game)
	var tut_z: int = game.tutorial_layer.z_index
	var night_z: int = game.night.z_index
	var quest_z: int = game.quest_pop.z_index
	var settings_z: int = game.settings_pop.z_index
	var guide_z: int = game.guide_pop.z_index
	var mail_z: int = game.quest_btn.z_index
	var toast_z: int = game.get_node("Toasts").z_index
	var menu_z: int = game.start_menu.z_index
	var back_z: int = game.menu_backdrop.z_index
	assert(dock_z == 8)
	assert(hud_z == 40)
	assert(bird_z <= 100)
	assert(tut_z > 100)
	assert(tut_z > bird_z)
	assert(tut_z > hud_z)
	assert(night_z == 100)
	assert(quest_z == 110)
	assert(settings_z == 115)
	assert(guide_z == 116)
	assert(mail_z == 120)
	assert(toast_z == 130)
	assert(back_z == 90)
	assert(menu_z == 500)
	assert(tut_z < quest_z)
	assert(quest_z < settings_z)
	assert(settings_z < guide_z)
	assert(guide_z < mail_z)
	assert(mail_z < toast_z)
	assert(toast_z < menu_z)
	assert(back_z < tut_z or back_z < settings_z)


func _max_bird_z(game) -> int:
	var m := 0
	if game.flock_layer == null:
		return m
	for c in game.flock_layer.get_children():
		if c is CanvasItem:
			m = maxi(m, (c as CanvasItem).z_index)
	return m
