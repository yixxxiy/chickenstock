extends Node

# 层级冒烟。对照 AGENTS.md 的 z 表逐项核，外加「开弹层时谁盖住谁」。
#
# 这里**不用裸 assert**：Godot 的 assert 失败只中断当前函数，控制流回到
# _ready() 继续跑，最后照样打印 LAYER_SMOKE_OK、退出码还是 0。
# 这个测试就这么假绿过一轮（guide_z 期望 116、实际 126，第 61 行之后一条没跑）。
# 改成计数 + 退出码，坏了才看得出来。

var _fail := 0


func _eq(actual: int, expected: int, name: String) -> void:
	if actual == expected:
		print("  PASS  ", name, " = ", actual)
	else:
		_fail += 1
		printerr("  FAIL  ", name, " 期望 ", expected, " 实际 ", actual)


func _ok(cond: bool, name: String) -> void:
	if cond:
		print("  PASS  ", name)
	else:
		_fail += 1
		printerr("  FAIL  ", name)


func _ready() -> void:
	# 冒烟测试不产生统计事件：长按连点走的是 quiet=true，和测试调用同一个标记，
	# 所以只能在这里整体关掉，不能靠 quiet 区分。
	Analytics.enabled = false
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
	_ok(game.tutorial_mode, "进入教学模式")
	_ok(game.tutorial_layer.visible, "教学层可见")
	_ok(game.tutorial_layer.z_index > _max_bird_z(game), "教学层盖住鸡群")
	game._open_settings()
	await get_tree().process_frame
	_ok(game.settings_pop.visible, "设置可见")
	_ok(not game.tutorial_layer.visible, "开设置时教学层收起")
	_ok(game.settings_pop.z_index > game.tutorial_layer.z_index, "设置盖住教学层")
	game._close_settings()
	await get_tree().process_frame
	_ok(game.tutorial_layer.visible, "关设置后教学层回来")
	game._show_main_menu()
	await get_tree().process_frame
	_ok(game.start_menu.visible, "主菜单可见")
	_ok(not game.tutorial_layer.visible, "回菜单时教学层收起")
	_ok(game.start_menu.z_index > game.settings_pop.z_index, "菜单盖住设置")
	_ok(game.menu_backdrop.visible, "菜单背景可见")
	if _fail > 0:
		printerr("LAYER_SMOKE_FAIL count=", _fail)
		get_tree().quit(1)
		return
	print("LAYER_SMOKE_OK")
	get_tree().quit(0)


func _assert_stack(game) -> void:
	var bird_z := _max_bird_z(game)
	var tut_z: int = game.tutorial_layer.z_index
	_eq(game.get_node("Dock").z_index, 8, "Dock")
	_eq(game.get_node("HUD").z_index, 40, "HUD")
	_eq(game.night.z_index, 100, "Night 结算")
	_eq(game.quest_pop.z_index, 110, "QuestPop")
	_eq(game.settings_pop.z_index, 115, "SettingsPop")
	_eq(game.quest_btn.z_index, 120, "信封 QuestBtn")
	_eq(game.trophy_pop.z_index, 125, "TrophyPop")
	# 新手指南是整屏模态：它盖住信封按钮是刻意的，不是漏改。
	# 改这个值要同步改 AGENTS.md 的 z 表。
	_eq(game.guide_pop.z_index, 126, "GuidePop")
	_eq(game.get_node("Toasts").z_index, 510, "Toasts")
	_eq(game.menu_backdrop.z_index, 90, "菜单背景")
	_eq(game.start_menu.z_index, 500, "StartMenuLayer")
	_ok(bird_z <= 100, "鸡群 z 不越过结算层（实际 %d）" % bird_z)
	_ok(tut_z > 100, "教学层在结算层之上（实际 %d）" % tut_z)
	_ok(tut_z > bird_z, "教学层在鸡群之上")
	_ok(tut_z > game.get_node("HUD").z_index, "教学层在 HUD 之上")
	_ok(tut_z < game.quest_pop.z_index, "教学层 < QuestPop")
	_ok(game.quest_pop.z_index < game.settings_pop.z_index, "QuestPop < SettingsPop")
	_ok(game.settings_pop.z_index < game.quest_btn.z_index, "SettingsPop < 信封按钮")
	_ok(game.quest_btn.z_index < game.trophy_pop.z_index, "信封按钮 < TrophyPop")
	_ok(game.trophy_pop.z_index < game.guide_pop.z_index, "TrophyPop < GuidePop")
	_ok(game.guide_pop.z_index < game.get_node("Toasts").z_index, "GuidePop < Toasts")
	_ok(game.start_menu.z_index < game.get_node("Toasts").z_index, "主菜单 < Toasts")
	_ok(game.menu_backdrop.z_index < tut_z, "菜单背景在教学层之下")


func _max_bird_z(game) -> int:
	var m := 0
	if game.flock_layer == null:
		return m
	for c in game.flock_layer.get_children():
		if c is CanvasItem:
			m = maxi(m, (c as CanvasItem).z_index)
	return m
