extends Node

# CONTEXT.md「考核失败一次机会」: day 12 / 16 / 20 each carry their own single
# 当天重试. Spending day 12's must not touch day 16's or day 20's, and the
# rewind itself must not hand the allowance back.

var _game


func _ready() -> void:
	# 冒烟测试不产生统计事件：长按连点走的是 quiet=true，和测试调用同一个标记，
	# 所以只能在这里整体关掉，不能靠 quiet 区分。
	Analytics.enabled = false
	print("GATE_RETRY_SMOKE_START")
	_game = load("res://scenes/Game.tscn").instantiate()
	# 本测试验的是考核额度与存档，不是奖励 UI。不跳过问卷/等待的话，
	# `await pop.closed` 在无人点击的 headless 环境里会永远等下去。
	_game.skip_reward_gate = true
	get_tree().root.add_child.call_deferred(_game)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	_game._write_tutorial_status("dismissed")
	if FileAccess.file_exists(_game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_game.SAVE_PATH))

	# --- gate table matches the spec: day 12 / 16 / 20.
	var gates: Array = _game.CHALLENGE_GATES
	assert(gates.size() == 3)
	assert(int(gates[0].day) == 12 and int(gates[1].day) == 16 and int(gates[2].day) == 20)

	_game._normal_cleared = true
	_game._enter_play("challenge")
	assert(_game.challenge_mode)
	assert(_game.day == 9)
	# All three allowances start unspent.
	for g in gates:
		assert(_game._gate_retry_left(int(g.day)))

	# --- fail gate 1 on purpose.
	await _run_to(12)
	_stock(int(gates[0].wealth) - 500, int(gates[0].birds) - 2)
	await _end_day()
	assert(_game.game_result == "flop", "expected flop, got '%s'" % _game.game_result)
	assert(_game._gate_retry_left(12), "retry should still be unspent before the ad")

	# --- spend day 12's retry.
	await _game._on_ad_rewind()
	await get_tree().create_timer(1.4).timeout
	assert(_game.game_result == "")
	assert(_game.day == 12, "当天重试 goes back to that day's morning, got %d" % _game.day)
	# THE point of this test: _gate_retry_used lives in _save(), never in
	# _capture_dawn(), so rewinding cannot restore the unspent state.
	assert(not _game._gate_retry_left(12), "rewind handed the allowance back")
	# The other two gates are untouched.
	assert(_game._gate_retry_left(16))
	assert(_game._gate_retry_left(20))

	# --- fail the same gate again: no second retry.
	_stock(int(gates[0].wealth) - 500, int(gates[0].birds) - 2)
	await _end_day()
	assert(_game.game_result == "flop")
	assert(not _game._gate_retry_left(12))
	var day_before: int = _game.day
	await _game._on_ad_rewind()
	await get_tree().create_timer(1.2).timeout
	assert(_game.game_result == "flop", "a spent gate must not rewind again")
	assert(_game.day == day_before)

	# --- the spent flag survives a save/load round trip.
	_game._save()
	_game._gate_retry_used.clear()
	assert(_game._gate_retry_left(12))
	_game._load()
	assert(not _game._gate_retry_left(12), "gateRetryUsed lost across save/load")
	assert(_game._gate_retry_left(16))

	# --- a fresh run clears all three.
	_game.game_result = ""
	_game._reset_new_game_data()
	for g in gates:
		assert(_game._gate_retry_left(int(g.day)))

	# --- long-run guards ported from chickenstock-2.0.
	_game.wealth_log.clear()
	for i in 300:
		_game.wealth_log.append(i)
	_game.summary = {"grown": 0, "hatched": 0, "day": _game.day + 1}
	await _game._wake()
	assert(_game.wealth_log.size() <= _game.WEALTH_LOG_MAX)
	_game.hens = 400
	_game.young_chicks = 40
	_game._rebuild_flock()
	await get_tree().process_frame
	assert(_game.flock_layer.get_child_count() <= _game.FLOCK_RENDER_CAP)
	assert(_game.birds() >= 440, "birds() must report the real flock, not the drawn one")

	print("GATE_RETRY_SMOKE_OK")
	get_tree().quit(0)


func _stock(wealth: int, birds: int) -> void:
	_game.shares = 0
	_game.coins = wealth
	_game.hens = maxi(1, birds)
	_game.young_chicks = 0
	_game.hatched = 0
	_game.hatching = 0
	_game.eggs = 0
	_game.ready_eggs = 0
	_game.pending_eggs = 0


func _end_day() -> void:
	_game.left_ms = 0.0
	await _game._next_day()
	await get_tree().create_timer(0.4).timeout


func _run_to(target_day: int) -> void:
	while _game.day < target_day:
		await _end_day()
		assert(_game.game_result == "", "unexpected stop on day %d" % _game.day)
		_game._on_settlement_confirm()
		await get_tree().create_timer(1.4).timeout
