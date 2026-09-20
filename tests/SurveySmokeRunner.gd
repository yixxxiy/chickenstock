extends Node

# 问卷不是占位：这里把它整条走一遍——
# 日结 → 点奖励入口 → 主问卷真的弹出 → 选答案 → 提交 → 标记完成 → 恢复当天早晨，
# 并验证提交之后入口文案换成五秒等待。
#
# 三份表单各自的完成标记必须独立：交过主问卷之后，设置入口要变成补充表单、
# 回主菜单的单题脉冲仍然要能弹。合成一个布尔会让流失原因永远采不到，
# 所以这三条也在这里断言。
#
# 不要用裸 assert：失败只中断 _ready()，后面的 get_tree().quit() 永远到不了，
# headless 就挂在那里不退出也不打结论（这份文件踩过一次）。一律走 _check 计数，
# 最后按失败数决定退出码。
#
# 同时把 Analytics.verbose 打开。非 Web 环境下 enabled 本来就是 false（不发网络请求），
# verbose 会把这一轮本该上报的事件打印出来，用来肉眼对账。
# 注意：enabled 为 false 时动作计数和 playtime_tick 不累计，所以打印里看不到它们。

var _game
var _fail := 0
var _pass := 0
var _last_payload := {}


func _check(ok: bool, name: String, detail := "") -> bool:
	if ok:
		_pass += 1
		print("  PASS  ", name, ("" if detail == "" else "  (" + detail + ")"))
	else:
		_fail += 1
		print("  FAIL  ", name, ("" if detail == "" else "  (" + detail + ")"))
	return ok


func _done() -> void:
	print("SURVEY_SMOKE_DONE pass=", _pass, " fail=", _fail)
	if _fail == 0:
		print("SURVEY_SMOKE_OK")
	get_tree().quit(1 if _fail > 0 else 0)


func _on_submitted(answers: Dictionary) -> void:
	_last_payload = answers.duplicate()


func _ready() -> void:
	Analytics.verbose = true
	print("SURVEY_SMOKE_START")
	_game = load("res://scenes/Game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(_game)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	_game._write_tutorial_status("dismissed")
	if FileAccess.file_exists(_game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_game.SAVE_PATH))
	_game._enter_play("normal")
	await get_tree().process_frame
	_check(not _game.settling, "开局不在结算")

	await _game._next_day()
	await get_tree().create_timer(0.5).timeout
	_check(_game.settling, "日结进入结算")
	_check(_game._offer_id != "", "结算卡带重试入口")
	_check(_game._offer_reward == "survey", "没填过问卷时入口给问卷", str(_game._offer_reward))
	print("OFFER_VIEW_LOGGED offer_id=", _game._offer_id, " reward=", _game._offer_reward)

	# 还没填过问卷 → 奖励入口走问卷路径
	_check(not Analytics.survey_done, "起手未标记填过问卷")
	_game._on_ad_rewind()
	await get_tree().create_timer(0.4).timeout
	var pop = _game.survey_pop
	if not _check(pop != null, "问卷节点存在"):
		_done()
		return
	pop.submitted.connect(_on_submitted)
	_check(pop.visible, "主问卷弹出来了")
	_check(pop.form == "reward", "表单是 reward", str(pop.form))
	# 主问卷是七题加一行自由文本。题量变了就要同步改 SURVEY_VERSION。
	_check(pop.question_count() == 8, "主问卷 8 题", str(pop.question_count()))
	print("SURVEY_VISIBLE form=", pop.form, " items=", pop.question_count())

	# 先只答六题、留一道选择题空着：选择题提交前必填，这一下必须被拦住。
	# 一题主动选「不想披露」，验证它和「没答」在事件里不是同一个值。
	pop._on_chip("self_reported_skill", "intermediate")
	pop._on_chip("age_bracket", "18_24")
	pop._on_chip("gender", "undisclosed")
	pop._on_chip("genre_experience", "occasionally")
	pop._on_chip("difficulty_feel", "unclear_why_lost")
	pop._on_chip("would_watch_real_ad", "only_when_stuck")
	pop._free.text = "希望日结再慢一点"
	await get_tree().process_frame
	_check(pop.answered_count() == 7, "计到 7 题已答", str(pop.answered_count()))
	pop._on_submit()
	await get_tree().process_frame
	_check(pop.visible, "缺一道选择题时提交被拦住")
	_check(not Analytics.survey_done, "被拦住时不算填过")

	# 补上最后一道选择题，这才允许提交。
	pop._on_chip("retry_reason", "too_slow")
	await get_tree().process_frame
	_check(pop.answered_count() == 8, "补齐后 8 题已答", str(pop.answered_count()))
	# 代码里直接赋 text 不会触发 text_changed（那只在真人输入时发），
	# 所以「最后碰过的题」停在最后点的那颗 chip 上。
	_check(pop.last_question_key() == "retry_reason", "最后碰过的题是 retry_reason", str(pop.last_question_key()))
	_check(pop.last_question_index() == 5, "retry_reason 是第 6 题", str(pop.last_question_index()))

	_last_payload = {}
	pop._on_submit()
	await get_tree().process_frame
	_check(not pop.visible, "提交后关闭")
	_check(Analytics.survey_done, "主问卷标记完成")
	_check(_game.card.ad_label_key == "reward_wait_cta", "入口文案转成五秒等待", str(_game.card.ad_label_key))
	# 「不想披露」是一个稳定值，不能退化成缺属性。
	_check(str(_last_payload.get("gender", "")) == "undisclosed", "undisclosed 原样进事件", str(_last_payload.get("gender", "")))
	_check(_last_payload.has("free_text"), "填了的自由文本进事件")
	print("SURVEY_SUBMITTED")

	# 提交之后 _on_ad_rewind 的 await 恢复，继续走恢复当天早晨
	await get_tree().create_timer(2.0).timeout
	_check(not _game.settling, "问卷提交后恢复到当天早晨")
	_check(_game.day == 1, "恢复的是第 1 天", str(_game.day))
	_check(_game.attempt_index == 1, "还在同一次尝试里", str(_game.attempt_index))
	print("REWIND_AFTER_SURVEY day=", _game.day, " attempt_index=", _game.attempt_index)

	# 再次日结：这次入口应该是五秒等待，不是问卷
	await _game._next_day()
	await get_tree().create_timer(0.5).timeout
	_check(_game._offer_reward == "wait", "第二次入口是五秒等待", str(_game._offer_reward))
	print("SECOND_OFFER reward=", _game._offer_reward)

	# 交过主问卷之后，设置入口改成补充表单，而不是从此闭嘴。
	_check(not Analytics.exit_done, "补充表单还没交过")
	_game._ensure_settings_feedback()
	_check(_game._settings_feedback_btn.visible, "设置里出现补填入口")
	_game._open_settings_survey()
	await get_tree().process_frame
	_check(pop.visible, "补充表单能开")
	_check(pop.form == "exit", "表单是 exit", str(pop.form))
	_check(pop.question_count() == 5, "补充表单 5 题", str(pop.question_count()))
	print("EXIT_FORM_VISIBLE items=", pop.question_count())

	# 一题不答直接关：按已定规则，关掉也要留下痕迹（dismiss 事件），不能静默消失。
	pop._on_later()
	await get_tree().process_frame
	_check(not pop.visible, "关掉补充表单")
	_check(not Analytics.exit_done, "关掉不算填过")
	_check(_game._settings_feedback_btn.visible, "关掉后入口还在")

	# 补充表单答满四道选择题提交 → 两份都交完，按钮才隐藏。
	# 自由文本留空：没答的题不写进事件，报表里「缺属性」和 undisclosed 必须分得开。
	_game._open_settings_survey()
	await get_tree().process_frame
	pop._on_chip("difficulty_feel", "unclear_why_lost")
	pop._on_chip("unclear_system", "stock_price")
	pop._on_chip("stop_reason", "too_repetitive")
	pop._on_chip("would_watch_real_ad", "only_when_stuck")
	_last_payload = {}
	pop._on_submit()
	await get_tree().process_frame
	_check(Analytics.exit_done, "补充表单提交")
	_check(not _game._settings_feedback_btn.visible, "两份都交完按钮才隐藏")
	_check(not _last_payload.has("free_text"), "留空的自由文本不进事件")
	print("EXIT_FORM_SUBMITTED")

	# 单题脉冲和前两份互不影响：交过主问卷也照样问得到「为什么停下来」。
	_check(not Analytics.pulse_done, "脉冲还没交过")
	# 统计关着的时候脉冲按设计不弹——采不到数据就只剩打扰。这里打开它走真实路径；
	# headless 下 _js 为 null，所有上报仍然自动退化成空操作，不会发请求。
	Analytics.enabled = true
	Analytics.active_ms_total = _game.PULSE_MIN_ACTIVE_MS + 1000
	_game._pulse_pending = true
	_game._show_main_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(pop.visible, "回菜单弹单题脉冲")
	_check(pop.form == "pulse", "表单是 pulse", str(pop.form))
	_check(pop.question_count() == 1, "脉冲只有 1 题", str(pop.question_count()))
	_check(not _game._pulse_pending, "脉冲标记已消费")
	# StartMenuLayer 的 z 是 500，问卷卡是 125：菜单必须收起来，否则问卷画在菜单底下。
	_check(not _game.start_menu.visible, "脉冲期间菜单收起")
	pop._on_chip("stop_reason", "no_time")
	pop._on_submit()
	await get_tree().process_frame
	_check(Analytics.pulse_done, "脉冲标记完成")
	_check(Analytics.survey_done and Analytics.exit_done, "三份标记互不覆盖")
	# 关掉之后菜单必须自己回来，否则玩家会卡在一片空屏上。
	await get_tree().process_frame
	await get_tree().process_frame
	_check(_game.start_menu.visible, "脉冲关掉后菜单回来")
	print("PULSE_SUBMITTED")

	_done()
