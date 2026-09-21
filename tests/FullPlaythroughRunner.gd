extends Node

# 一次性「当测试员」跑完整条主线：开机 → 层级 → 翻译 → 新手关 → 普通八日真打通关
# → 从终局续进挑战 → 设置每一项 → 三份问卷 → 存读档。
#
# 和已有的几个 SmokeRunner 不同，这里**不用 assert**：
# assert 失败只会中断当前函数，外层照样往下跑并打印 OK（LayerSmokeRunner 就是这么
# 「假通过」的）。这里用 _check 计数，最后按失败数决定退出码。
#
# 时间加速：Engine.time_scale 放大，一天 20 秒压到两三秒。
# 烤炉、下蛋、_later 全部走 delta / SceneTreeTimer，会一起加速。

const SPEED := 8.0

var _fail := 0
var _pass := 0
var _notes: Array[String] = []
var game


func _check(ok: bool, name: String, detail := "") -> bool:
	if ok:
		_pass += 1
		print("  PASS  ", name, ("" if detail == "" else "  (" + detail + ")"))
	else:
		_fail += 1
		print("  FAIL  ", name, ("" if detail == "" else "  (" + detail + ")"))
		_notes.append(name + ("" if detail == "" else " — " + detail))
	return ok


func _sec(title: String) -> void:
	print("")
	print("=== ", title, " ===")


func _ready() -> void:
	Analytics.enabled = false
	Engine.time_scale = SPEED
	print("FULL_PLAYTHROUGH_START  user_dir=", OS.get_user_data_dir())

	# 干净起手：清掉存档 / 教学标记 / 奖杯 / 解锁。
	# 必须在实例化之前删——Game._ready 一开机就读这几份文件，
	# 删晚了第一节「挑战模式初始锁住」看到的是上一轮留下的解锁状态。
	for p in ["user://cluck-farm-v7.json", "user://cluck-tutorial.json",
			"user://cluck-trophies.json", "user://cluck-unlocks.json"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

	game = load("res://scenes/Game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout

	await _test_boot()
	await _test_layers()
	_test_i18n()
	await _test_tutorial()
	await _test_campaign()
	await _test_challenge()
	await _test_settings()
	await _test_surveys()
	await _test_save_load()

	_sec("总结")
	print("PASS=", _pass, "  FAIL=", _fail)
	for n in _notes:
		print("  ! ", n)
	print("FULL_PLAYTHROUGH_DONE fail=", _fail)
	Engine.time_scale = 1.0
	get_tree().quit(1 if _fail > 0 else 0)


# ---------------------------------------------------------------- 开机

func _test_boot() -> void:
	_sec("1 开机与主菜单")
	_check(game._booted, "_booted 为真")
	_check(game.start_menu.visible, "启动停在主菜单")
	_check(not game.night.visible, "开机不显示夜间结算层")
	_check(game.start_menu_direct.visible, "普通模式按钮可见")
	# 未通关时挑战 / 无尽应当是灰的（modulate.a 0.42）
	_check(game.start_menu_challenge.modulate.a < 0.5, "挑战模式初始锁住",
		"alpha=" + str(game.start_menu_challenge.modulate.a))
	_check(game.start_menu_endless.modulate.a < 0.5, "无尽模式初始锁住",
		"alpha=" + str(game.start_menu_endless.modulate.a))


# ---------------------------------------------------------------- 层级

func _max_bird_z() -> int:
	var m := 0
	if game.flock_layer == null:
		return m
	for c in game.flock_layer.get_children():
		if c is CanvasItem:
			m = maxi(m, (c as CanvasItem).z_index)
	return m


func _test_layers() -> void:
	_sec("2 层级（对照 AGENTS.md 那张表）")
	_check(game.get_node("Dock").z_index == 8, "Dock z=8", str(game.get_node("Dock").z_index))
	_check(game.get_node("HUD").z_index == 40, "HUD z=40", str(game.get_node("HUD").z_index))
	_check(game.night.z_index == 100, "Night z=100", str(game.night.z_index))
	_check(game.quest_pop.z_index == 110, "QuestPop z=110", str(game.quest_pop.z_index))
	_check(game.settings_pop.z_index == 115, "SettingsPop z=115", str(game.settings_pop.z_index))
	_check(game.trophy_pop.z_index == 125, "TrophyPop z=125", str(game.trophy_pop.z_index))
	_check(game.quest_btn.z_index == 120, "信封 QuestBtn z=120", str(game.quest_btn.z_index))
	_check(game.get_node("Toasts").z_index == 510, "Toasts z=510", str(game.get_node("Toasts").z_index))
	_check(game.start_menu.z_index == 500, "StartMenuLayer z=500", str(game.start_menu.z_index))
	_check(_max_bird_z() <= 100, "鸡群 z 不越过结算层", str(_max_bird_z()))
	_check(game.guide_pop.z_index > game.settings_pop.z_index, "攻略盖在设置之上",
		"guide=" + str(game.guide_pop.z_index) + " settings=" + str(game.settings_pop.z_index))
	# 问卷卡按 AGENTS.md 应当是 125，和奖杯页同层
	var pop = game._ensure_survey()
	_check(pop.z_index == 125, "SurveyPop z=125", str(pop.z_index))
	await get_tree().process_frame


# ---------------------------------------------------------------- 翻译

func _test_i18n() -> void:
	_sec("3 中英文案")
	var zh: Dictionary = Loc.ZH
	var en: Dictionary = Loc.EN
	var miss_en: Array = []
	var miss_zh: Array = []
	for k in zh.keys():
		if not en.has(k):
			miss_en.append(k)
	for k in en.keys():
		if not zh.has(k):
			miss_zh.append(k)
	_check(miss_en.is_empty(), "每条中文都有英文", str(miss_en.size()) + " 缺: " + str(miss_en.slice(0, 12)))
	_check(miss_zh.is_empty(), "每条英文都有中文", str(miss_zh.size()) + " 缺: " + str(miss_zh.slice(0, 12)))
	var empty_keys: Array = []
	var fmt_mismatch: Array = []
	for k in zh.keys():
		if String(zh[k]).strip_edges() == "":
			empty_keys.append(k)
		if en.has(k):
			if String(en[k]).strip_edges() == "":
				empty_keys.append(k)
			# 占位符数量对不上 = 换语言就会少一个数字或者直接报错
			var nz := String(zh[k]).count("%")
			var ne := String(en[k]).count("%")
			if nz != ne:
				fmt_mismatch.append(k + " zh=" + str(nz) + " en=" + str(ne))
	_check(empty_keys.is_empty(), "没有空文案", str(empty_keys.slice(0, 12)))
	_check(fmt_mismatch.is_empty(), "中英占位符数量一致", str(fmt_mismatch.slice(0, 12)))
	print("  文案条数 zh=", zh.size(), " en=", en.size())


# ---------------------------------------------------------------- 新手关

func _test_tutorial() -> void:
	_sec("4 新手关一日入门")
	game._start_tutorial()
	await get_tree().process_frame
	if not _check(game.tutorial_mode, "进入教学模式"):
		return
	_check(game.tutorial_layer.visible, "教学遮罩可见")
	# 教学日不走时钟：_process 在 tutorial_mode 下不扣 left_ms，
	# _tick_day_ui 也把表盘写死成 0。left_ms 是多少都不影响，所以这里不断言它。
	_check(game.day_label.text == Loc.t("tutorial_day_frac"), "时钟位显示「教学」",
		game.day_label.text)

	var guard := 0
	var last_step := -1
	var stuck := 0
	while game.tutorial_mode and guard < 4000:
		guard += 1
		if game.tutorial_step == last_step:
			stuck += 1
		else:
			stuck = 0
			last_step = game.tutorial_step
		match game.tutorial_step:
			0:
				game._tutorial_next_pressed()
			1:
				if game.ready_eggs > 0:
					game.collect_egg(true)
				elif game.pending_eggs > 0:
					game.ready_eggs += 1
					game.pending_eggs -= 1
			2:
				game.start_hatch(true)
			3:
				game.sell_cake(true)
			4:
				game.buy_chick(true)
			5:
				game.buy_shares(true)
			6:
				game.sell_shares(true)
			_:
				game._tutorial_next_pressed()
		await get_tree().process_frame
		if stuck > 900:
			break
	_check(not game.tutorial_mode, "教学七步能走完",
		"停在 step=" + str(game.tutorial_step) + " guard=" + str(guard))
	_check(game._tutorial_status() != "", "教学状态已落盘", game._tutorial_status())
	await get_tree().create_timer(0.3).timeout


# ---------------------------------------------------------------- 机器人

func _bot_tick(target_birds: int, invest: bool) -> void:
	if game.blocked():
		return
	while game.ready_eggs > 0:
		if not game.collect_egg(true):
			break
	if game.hatched > 0:
		game.collect_chick(true)
	if game.hatching < 1 and game.eggs >= 1:
		game.start_hatch(true)
	while game.cakes > 0:
		if not game.sell_cake(true):
			break
	while game.birds() < target_birds and game.coins >= game._chick_cost():
		if not game.buy_chick(true):
			break
	if game.day >= 2 and game.bakery_level < game._bakery_max():
		var cost: int = game._bakery_upgrade_cost()
		if cost > 0 and game.coins >= cost + 400:
			game.upgrade_bakery()
	if invest:
		# 今晚的新闻是明牌（HUD 上看得到），照它做：
		# 雨天减产必跌，清仓；囤粮 / 蛋糕热销必涨，满仓。
		# 不看新闻乱买的机器人在挑战模式会被 45% 概率的雨天来回削平。
		var up: bool = bool(game.NEWS[game.news]["up"]) if game.NEWS.has(game.news) else true
		if up:
			while game.coins >= game.price and game.price > 0:
				if not game.buy_shares(true):
					break
		else:
			while game.shares > 0:
				if not game.sell_shares(true):
					break


## 打一天，返回这一天是否正常进入结算。
func _play_one_day(target_birds: int, invest: bool) -> bool:
	var guard := 0
	while not game.settling and game.game_result == "" and guard < 60000:
		guard += 1
		_bot_tick(target_birds, invest)
		await get_tree().process_frame
	return game.settling or game.game_result != ""


## `_next_day()` 一进来就把 settling 置真，终局是在碎蛋动画之后才写进 game_result 的。
## 不等这一下就读 game_result，第 8 天会被当成普通日结，
## 于是「确认」按成了终局的「重新开局」，整局被悄悄重置。
func _await_settle_result() -> void:
	await get_tree().create_timer(2.5).timeout


func _confirm_settlement() -> void:
	game._on_settlement_confirm()
	var guard := 0
	while game.settling and guard < 4000:
		guard += 1
		await get_tree().process_frame


# ---------------------------------------------------------------- 普通八日

func _test_campaign() -> void:
	_sec("5 普通模式：真打八天")
	game._write_tutorial_status("dismissed")
	if FileAccess.file_exists(game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.SAVE_PATH))
	game._enter_play("normal")
	await get_tree().process_frame
	_check(game.day == 1 and not game.settling, "从第 1 天开始",
		"day=" + str(game.day))
	_check(game.coins == 120 and game.hens == 1, "初始 120 金币 1 只鸡",
		"coins=" + str(game.coins) + " hens=" + str(game.hens))

	var dock_seen_hidden := false
	for d in range(1, 9):
		var day_no: int = game.day
		var ok := await _play_one_day(game.FLOCK_GOAL, game.day >= 3)
		if not _check(ok, "第 " + str(day_no) + " 天能走到结算"):
			return
		if not game.get_node("Dock").visible:
			dock_seen_hidden = true
		await _await_settle_result()
		print("    第 %d 天收盘：资产 %d  鸡 %d  金币 %d  股价 %d  持股 %d  烤炉 Lv%d  终局=%s"
			% [day_no, game.total(), game.birds(), game.coins, game.price, game.shares,
				game.bakery_level, game.game_result])
		if game.game_result != "":
			_check(day_no == 8, "终局只在第 8 天出现", "day=" + str(day_no))
			break
		await _confirm_settlement()

	_check(dock_seen_hidden, "结算时底栏消失")
	_check(game.day == 8, "八天正好走完", "day=" + str(game.day))
	_check(game.game_result != "", "第 8 天给出终局", "result=" + str(game.game_result))
	print("    终局：result=", game.game_result, " 资产=", game.total(), " 鸡=", game.birds())
	var cleared: bool = game.game_result == "ended"
	_check(cleared, "机器人按常规打法能通关八日",
		"资产 " + str(game.total()) + "/" + str(game.WEALTH_GOAL)
		+ "  鸡 " + str(game.birds()) + "/" + str(game.FLOCK_GOAL))
	if cleared:
		_check(game._normal_cleared, "通关后解锁挑战模式")
		_check(game._trophies.has("day8"), "拿到八日奖杯")
		_check(game.start_menu_challenge != null, "挑战按钮存在")


# ---------------------------------------------------------------- 挑战

func _test_challenge() -> void:
	_sec("6 挑战模式：从终局续进，打到第 12 天考核")
	if game.game_result != "ended":
		print("  SKIP  八日没通关，跳过「继续挑战」入口")
		game._reset_new_game_data()
		game.game_result = ""
		game.settling = false
		game._enter_play("challenge")
		await get_tree().process_frame
	else:
		game._continue_endless_from_finale()
		var guard := 0
		while game.settling and guard < 4000:
			guard += 1
			await get_tree().process_frame
	_check(game.challenge_mode, "已在挑战模式")
	print("    起手：day=", game.day, " hens=", game.hens, " coins=", game.coins,
		" 烤炉Lv", game.bakery_level, " 股价=", game.price)
	_check(game._day_len_ms() == 20000.0, "第一波每天 20 秒", str(game._day_len_ms()))
	_check(game._chick_cost() == 50, "第一波买鸡 50", str(game._chick_cost()))

	var guard2 := 0
	while game.game_result == "" and game.day <= 20 and guard2 < 20:
		guard2 += 1
		var day_no: int = game.day
		# 关卡只要 22 / 37 / 58 只鸡，多买的每一只都是从资产里挖走的 50 金币。
		# 按下一关要求 + 3 只富余买，剩下的钱全进股市。
		var want: int = int(game._next_challenge_gate().birds) + 3
		var ok := await _play_one_day(want, true)
		if not _check(ok, "挑战第 " + str(day_no) + " 天能走到结算"):
			return
		await _await_settle_result()
		print("    第 %d 天收盘：资产 %d  鸡 %d  股价 %d  终局=%s"
			% [day_no, game.total(), game.birds(), game.price, game.game_result])
		if game.game_result != "":
			break
		await _confirm_settlement()

	var gate: Dictionary = game._challenge_gate_at(game.day)
	if gate.is_empty():
		gate = game._next_challenge_gate()
	print("    停在第 ", game.day, " 天：关卡要求 资产 ", gate.wealth, " 鸡 ", gate.birds,
		"；实际 资产 ", game.total(), " 鸡 ", game.birds())
	_check(game.day >= 12, "至少打到第 12 天考核", "day=" + str(game.day))
	if game.game_result == "flop":
		_notes.append("挑战模式第 %d 天关卡没过（难度观察，不算 bug）" % game.day)
		print("  NOTE  第 ", game.day, " 天关卡没过 —— 记一次难度观察")
		# 卡关后应当给出重试入口
		_check(game._offer_id != "", "关卡失败时给出重试入口",
			"offer=" + str(game._offer_reward))
	elif game.game_result == "won":
		print("  NOTE  挑战模式打穿到第 20 天")
		_check(game._challenge_cleared, "通关后写入挑战解锁标记")
		_check(game.card.get_node("Finale/Scores").visible, "第20天通关卡显示分数")
		_check(game.card.get_node("Finale/RankTitle").text != Loc.t("you_win"),
			"第20天通关卡不是 You win 占位", game.card.get_node("Finale/RankTitle").text)

	# 机器人不一定能打穿第 20 天。这里单独把关卡堆到达标，专测通关报告卡。
	await _test_day20_win_card()


func _test_day20_win_card() -> void:
	_sec("6b 挑战第 20 天通关报告（强制达标）")
	game.skip_reward_gate = true
	game._reset_new_game_data()
	game.game_result = ""
	game.settling = false
	game._normal_cleared = true
	game._enter_play("challenge")
	await get_tree().process_frame
	var gate: Dictionary = game._challenge_gate_at(20)
	game.day = 20
	game.coins = int(gate.wealth)
	game.hens = int(gate.birds)
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
	await _await_settle_result()
	_check(game.game_result == "won", "第 20 天达标记为 won", str(game.game_result))
	_check(game.card._finale_kind == "win", "结算卡 kind=win", str(game.card._finale_kind))
	_check(game.card.get_node("Finale/Scores").visible, "分数区可见")
	_check(game.card.get_node("Finale/StampRow").visible, "达标章可见")
	_check(game.card.get_node("Finale/Pips").visible, "评级点可见")
	_check(game.card.get_node("Finale/ChartWell").visible, "资产曲线可见")
	_check(not game.card.get_node("Finale/Actions/ShareBtn").visible, "分享按钮已隐藏")
	_check(game.card.get_node("Finale/Actions/EndlessBtn").visible, "继续无尽按钮可见")
	_check(game.card.get_node("Finale/RankTitle").text != Loc.t("you_win"),
		"标题是等级名不是 You win", game.card.get_node("Finale/RankTitle").text)
	_check(game.card.get_node("Finale/StampRow/StampTxt").text == Loc.t("quest_stamp"),
		"达标章文案", game.card.get_node("Finale/StampRow/StampTxt").text)
	game.skip_reward_gate = false


# ---------------------------------------------------------------- 设置

func _test_settings() -> void:
	_sec("7 设置面板每一项")
	# 语言防抖用的是 Time.get_ticks_msec()（真实墙钟），不跟 time_scale 走。
	# 加速状态下 create_timer(0.4) 只等 0.05 秒真实时间，永远绕不过 280ms 那一关。
	Engine.time_scale = 1.0
	game._return_to_menu = false
	game.game_result = ""
	game.settling = false
	game._open_settings()
	await get_tree().process_frame
	if not _check(game.settings_pop.visible, "设置能打开"):
		return

	# 语言
	await get_tree().create_timer(0.35).timeout
	Loc.set_lang("en")
	game._apply_locale()
	await get_tree().process_frame
	_check(Loc.lang == "en", "能切到英文")
	_check(game._settings_node("Title").text == Loc.EN["settings"],
		"英文标题跟着换", game._settings_node("Title").text)
	# 回归：底栏那颗「结束今天」平时由 _tick_day_ui 维护，而那里只在黄昏翻转的
	# 那一帧写它。白天中途切语言时它以前会一直停在旧语言，真机上肉眼可见。
	_check(game.day_end_btn.text == Loc.EN["end_day"], "底栏「结束今天」跟着切英文",
		game.day_end_btn.text)
	await get_tree().create_timer(0.35).timeout
	Loc.set_lang("zh")
	game._apply_locale()
	await get_tree().process_frame
	_check(Loc.lang == "zh", "能切回中文")
	_check(game._settings_node("Title").text == Loc.ZH["settings"],
		"中文标题跟着换", game._settings_node("Title").text)
	_check(game.day_end_btn.text == Loc.ZH["end_day"], "底栏「结束今天」跟着切回中文",
		game.day_end_btn.text)
	# 手机上 emulate_touch_from_mouse 会让一次点击打两下，
	# Loc.toggle 靠 280ms 防抖挡住第二下：连点两次只能切一次语言。
	await get_tree().create_timer(0.35).timeout
	var l0 := Loc.lang
	Loc.toggle()
	Loc.toggle()
	_check(Loc.lang != l0, "连点两次语言只切一次", l0 + " -> " + Loc.lang)
	await get_tree().create_timer(0.35).timeout
	Loc.set_lang("zh")
	game._apply_locale()

	# 音效 / 环境音互相独立
	var sfx_btn := game._settings_node("SfxRow/SfxBtn") as Button
	var amb_btn := game._settings_node("AmbRow/AmbBtn") as Button
	var s0: bool = game.sfx.sfx_on
	var a0: bool = game.sfx.amb_on
	sfx_btn.pressed.emit()
	await get_tree().process_frame
	_check(game.sfx.sfx_on != s0, "音效开关能切")
	_check(game.sfx.amb_on == a0, "切音效不会连带切环境音")
	amb_btn.pressed.emit()
	await get_tree().process_frame
	_check(game.sfx.amb_on != a0, "环境音开关能切")
	sfx_btn.pressed.emit()
	amb_btn.pressed.emit()
	await get_tree().process_frame
	_check(game.sfx.sfx_on == s0 and game.sfx.amb_on == a0, "再点一次能切回来")

	# 字号：设置里三颗按钮分别是 0.85 / 1.0 / 1.15，Loc 也按这个区间夹
	for sc in [0.85, 1.0, 1.15]:
		game._set_font_scale(sc)
		await get_tree().process_frame
		_check(is_equal_approx(Loc.ui_font_scale, sc), "字号能设到 " + str(sc), str(Loc.ui_font_scale))
	game._set_font_scale(2.0)
	_check(is_equal_approx(Loc.ui_font_scale, 1.15), "超范围的字号被夹住", str(Loc.ui_font_scale))
	game._set_font_scale(0.85)

	# 攻略页
	game._open_guide()
	await get_tree().process_frame
	_check(game.guide_pop.visible, "攻略能打开")
	_check(game.guide_pop.z_index > game.settings_pop.z_index, "攻略盖住设置")
	game._close_guide()
	await get_tree().process_frame
	_check(not game.guide_pop.visible, "攻略能关")

	game._close_settings()
	await get_tree().process_frame
	_check(not game.settings_pop.visible, "设置能关")

	# 奖杯页：菜单上开弹层必须先收菜单
	game._show_main_menu()
	await get_tree().process_frame
	game._start_menu_trophies_pressed()
	await get_tree().process_frame
	_check(game.trophy_pop.visible, "奖杯页能打开")
	_check(not game.start_menu.visible, "开奖杯页时主菜单先收起（否则被 z=500 盖住）")
	_check(game.get_node("TrophyPop/Card/Col/List/Rows").get_child_count() > 0,
		"奖杯列表有内容", str(game.get_node("TrophyPop/Card/Col/List/Rows").get_child_count()))
	game._close_trophies()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(game.start_menu.visible, "关掉奖杯页后菜单自己回来")

	# 菜单上的设置同理
	game._start_menu_settings_pressed()
	await get_tree().process_frame
	_check(game.settings_pop.visible, "菜单里能进设置")
	_check(not game.start_menu.visible, "进设置时主菜单先收起")
	game._close_settings()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(game.start_menu.visible, "关掉设置后菜单自己回来")


# ---------------------------------------------------------------- 问卷

func _test_surveys() -> void:
	_sec("8 问卷三份表单")
	Analytics.survey_done = false
	Analytics.exit_done = false
	Analytics.pulse_done = false
	game.game_result = ""
	game.settling = false
	game._return_to_menu = false
	if FileAccess.file_exists(game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.SAVE_PATH))
	game._enter_play("normal")
	await get_tree().process_frame

	await game._next_day()
	await get_tree().create_timer(1.0).timeout
	if not _check(game.settling, "日结进入结算"):
		return
	_check(game._offer_id != "", "结算卡带重试入口")
	_check(game._offer_reward == "survey", "没填过问卷时入口给问卷", str(game._offer_reward))

	game._on_ad_rewind()
	await get_tree().create_timer(0.8).timeout
	var pop = game.survey_pop
	if not _check(pop != null and pop.visible, "主问卷弹出来了"):
		return
	_check(pop.form == "reward", "表单是 reward", str(pop.form))
	_check(pop.question_count() == 8, "主问卷 8 题", str(pop.question_count()))
	# 卡片真的撑开了（AGENTS.md 记过：只 set_anchors_preset 会塌成 0×0）
	await get_tree().process_frame
	_check(pop.size.x > 100 and pop.size.y > 100, "问卷层有尺寸不是 0×0", str(pop.size))
	var card_node: Control = pop._card
	if card_node != null:
		_check(card_node.size.y > 100, "问卷卡片有高度", str(card_node.size))

	pop._on_chip("self_reported_skill", "intermediate")
	pop._on_chip("age_bracket", "25_34")
	pop._on_chip("gender", "undisclosed")
	pop._on_chip("genre_experience", "often")
	pop._on_chip("difficulty_feel", "unclear_why_lost")
	pop._on_chip("would_watch_real_ad", "only_when_stuck")
	pop._free.text = "测试员留言"
	await get_tree().process_frame
	_check(pop.answered_count() == 7, "计到 7 题已答", str(pop.answered_count()))
	# 选择题提交前必填：还缺 retry_reason，这一下要被拦住。
	pop._on_submit()
	await get_tree().process_frame
	_check(pop.visible and not Analytics.survey_done, "缺一道选择题时提交被拦住")
	pop._on_chip("retry_reason", "too_slow")
	await get_tree().process_frame
	_check(pop.answered_count() == 8, "补齐后 8 题已答", str(pop.answered_count()))
	pop._on_submit()
	await get_tree().process_frame
	_check(not pop.visible, "提交后关闭")
	_check(Analytics.survey_done, "主问卷标记完成")
	_check(game.card.ad_label_key == "reward_wait_cta", "入口文案转成五秒等待",
		str(game.card.ad_label_key))

	await get_tree().create_timer(3.0).timeout
	_check(not game.settling, "问卷提交后恢复到当天早晨")
	_check(game.day == 1, "恢复的是第 1 天", str(game.day))

	# 补充表单
	game._ensure_settings_feedback()
	_check(game._settings_feedback_btn.visible, "设置里出现补填入口")
	game._open_settings_survey()
	await get_tree().process_frame
	_check(pop.visible and pop.form == "exit", "补充表单能开", str(pop.form))
	pop._on_later()
	await get_tree().process_frame
	_check(not pop.visible and not Analytics.exit_done, "关掉不算填过")
	game._open_settings_survey()
	await get_tree().process_frame
	pop._on_chip("difficulty_feel", "unclear_why_lost")
	pop._on_chip("unclear_system", "stock_price")
	pop._on_chip("stop_reason", "too_repetitive")
	pop._on_chip("would_watch_real_ad", "only_when_stuck")
	pop._on_submit()
	await get_tree().process_frame
	_check(Analytics.exit_done, "补充表单提交")
	_check(not game._settings_feedback_btn.visible, "两份都交完按钮才隐藏")

	# 单题脉冲
	Analytics.enabled = true
	Analytics.active_ms_total = game.PULSE_MIN_ACTIVE_MS + 1000
	game._pulse_pending = true
	game._show_main_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(pop.visible and pop.form == "pulse", "回菜单弹单题脉冲", str(pop.form))
	_check(not game.start_menu.visible, "脉冲期间菜单收起")
	pop._on_chip("stop_reason", "no_time")
	pop._on_submit()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_check(Analytics.pulse_done, "脉冲标记完成")
	_check(game.start_menu.visible, "脉冲关掉后菜单回来")
	Analytics.enabled = false


# ---------------------------------------------------------------- 存读档

func _test_save_load() -> void:
	_sec("9 存档与读档")
	game.game_result = ""
	game.settling = false
	game._return_to_menu = false
	if FileAccess.file_exists(game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game.SAVE_PATH))
	game._enter_play("normal")
	await get_tree().process_frame
	game.coins = 777
	game.hens = 5
	game.shares = 3
	game.bakery_level = 2
	game._save()
	_check(FileAccess.file_exists(game.SAVE_PATH), "存档文件写出来了")

	var f := FileAccess.open(game.SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	_check(typeof(parsed) == TYPE_DICTIONARY, "存档是合法 JSON")

	game.coins = 0
	game.hens = 0
	game.shares = 0
	game.bakery_level = 1
	game._load()
	_check(game.coins == 777, "金币读回来", str(game.coins))
	_check(game.hens == 5, "鸡数读回来", str(game.hens))
	_check(game.shares == 3, "持股读回来", str(game.shares))
	_check(game.bakery_level == 2, "烤炉等级读回来", str(game.bakery_level))

	# 续档：_enter_play 同模式时应当接着打，而不是重开
	game._show_main_menu()
	await get_tree().process_frame
	game._enter_play("normal")
	await get_tree().process_frame
	_check(game.coins == 777, "回菜单再进能续上", str(game.coins))

	# 重置游戏
	game._restart()
	await get_tree().create_timer(0.5).timeout
	_check(game.coins == 120, "重置回到 120 金币", str(game.coins))
	_check(game.day == 1, "重置回到第 1 天", str(game.day))
