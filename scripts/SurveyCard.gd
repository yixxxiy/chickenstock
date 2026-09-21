extends Control
## 反馈问卷卡。三份表单共用这一张卡，由 `open()` 的第一个参数选：
##
## - `reward`：奖励重试入口的主问卷。画像四题 + 当下难度 + 重试原因 + 真广告意愿 + 开放建议。
##   画像四题写成 person 属性用于分群，其余只留在事件上。
## - `exit`：设置里的补充反馈。给已经交过主问卷的人，问难度、没看懂的系统、停下来的原因。
## - `pulse`：回主菜单时的单题脉冲。**唯一能采到「不走奖励入口就离开」那批人的位点**，
##   所以只问一题、不发奖励、随手可关。
##
## 为什么画在 Godot 层而不是 DOM 覆盖层：
## 线上包带 COEP require-corp，外部问卷资源加载不进来；就算自己写 DOM 层，
## 还要绕开 Game._lock_web_gestures() 装在 document 上的 selectstart / touchmove
## 拦截，以及 user-select:none。而本项目最贵的历史 bug 全在输入层
## （双触摸、防抖、结算层级）。画在画布里就能直接沿用既有那一套：
## Game._button_at 把本节点排在最前，合成 pressed 与吞 ScreenTouch 自动生效。
##
## 答案枚举是稳定值，永不本地化。「未回答」与「不想披露」必须是不同的值：
## 前者在事件里直接不出现这个属性，后者是 "undisclosed"。
## 选择题提交前必填；最后一题开放文本可空。
##
## 题库或表单有任何改动都要同步加 `Game.SURVEY_VERSION`，
## 否则新旧回答会被混进同一张表。

signal submitted(answers: Dictionary)
signal dismissed(dwell_ms: int, answered: int)
## 提交和关闭都会发。调用方 await 这一个信号就够了。
signal closed

const CARD_BG := Color("fff4dc")
const INK := Color("4a3b2a")
const CHIP_BG := Color("f3e4c4")
const CHIP_ON := Color("8fc06a")

## 单题表单用的紧凑卡片高度。一题占满一屏会让人以为后面还有，
## 而它恰恰是最该「看一眼就答完」的那份。
const COMPACT_HEIGHT := 440.0

## 题库。顺序不决定展示顺序，展示顺序由 FORMS 里的 keys 决定。
const QUESTIONS := [
	{
		"key": "self_reported_skill",
		"prompt": "survey_q_skill",
		"options": [
			["novice", "survey_skill_novice"],
			["intermediate", "survey_skill_intermediate"],
			["hardcore", "survey_skill_hardcore"],
			["undisclosed", "survey_undisclosed"],
		],
	},
	{
		"key": "age_bracket",
		"prompt": "survey_q_age",
		"options": [
			["under18", "survey_age_under18"],
			["18_24", "survey_age_18_24"],
			["25_34", "survey_age_25_34"],
			["35_plus", "survey_age_35_plus"],
			["undisclosed", "survey_undisclosed"],
		],
	},
	{
		"key": "gender",
		"prompt": "survey_q_gender",
		"options": [
			["male", "survey_gender_male"],
			["female", "survey_gender_female"],
			["other", "survey_gender_other"],
			["undisclosed", "survey_undisclosed"],
		],
	},
	{
		"key": "genre_experience",
		"prompt": "survey_q_genre",
		"options": [
			["never", "survey_genre_never"],
			["rarely", "survey_genre_rarely"],
			["occasionally", "survey_genre_occasionally"],
			["sometimes", "survey_genre_sometimes"],
			["often", "survey_genre_often"],
			["undisclosed", "survey_undisclosed"],
		],
	},
	{
		"key": "retry_reason",
		"prompt": "survey_q_reason",
		"options": [
			["rules", "survey_reason_rules"],
			["too_slow", "survey_reason_too_slow"],
			["trade_regret", "survey_reason_trade_regret"],
			["try_other", "survey_reason_try_other"],
			["misclick_lag", "survey_reason_misclick_lag"],
			["other", "survey_reason_other"],
		],
	},
	# 埋点能看到「差多少没过」（gate_result.shortfall_pct），看不到玩家觉得这是难还是没看懂。
	# unclear_why_lost 和 too_hard 的修法完全相反，必须是两个选项。
	{
		"key": "difficulty_feel",
		"prompt": "survey_q_difficulty",
		"options": [
			["too_easy", "survey_diff_too_easy"],
			["just_right", "survey_diff_just_right"],
			["hard_but_fair", "survey_diff_hard_fair"],
			["too_hard", "survey_diff_too_hard"],
			["unclear_why_lost", "survey_diff_unclear"],
		],
	},
	# 直接指向教程改哪一步。和 tutorial_step_complete.step_duration_ms 交叉看。
	{
		"key": "unclear_system",
		"prompt": "survey_q_unclear",
		"options": [
			["stock_price", "survey_unclear_stock"],
			["bakery", "survey_unclear_bakery"],
			["hatching", "survey_unclear_hatch"],
			["day_timer", "survey_unclear_timer"],
			["goal", "survey_unclear_goal"],
			["all_clear", "survey_unclear_none"],
		],
	},
	# 埋点只能看到「后面没有事件了」，看不到为什么。
	{
		"key": "stop_reason",
		"prompt": "survey_q_stop",
		"options": [
			["satisfied_done", "survey_stop_satisfied"],
			["too_hard", "survey_stop_too_hard"],
			["too_repetitive", "survey_stop_repetitive"],
			["boring_early", "survey_stop_boring"],
			["lag_or_misclick", "survey_stop_lag"],
			["no_time", "survey_stop_no_time"],
			["other", "survey_stop_other"],
		],
	},
	# 本轮没有真实广告，五秒占位等待测不出真广告意愿。这题是唯一的替代。
	# 它问的是意愿，不是完播率，不得用来推算广告收入。
	{
		"key": "would_watch_real_ad",
		"prompt": "survey_q_ad",
		"options": [
			["yes_any_time", "survey_ad_yes"],
			["only_when_stuck", "survey_ad_stuck"],
			["only_if_short", "survey_ad_short"],
			["no", "survey_ad_no"],
		],
	},
]

## 表单定义。`keys` 是展示顺序，`free` 决定有没有那一行自由文本。
##
## 同一道题可以出现在两份表单里（难度、真广告意愿），靠事件上的 `survey_form` 区分；
## 每份表单每人只填一次，所以不会重复采同一个人的同一份答案。
const FORMS := {
	"reward": {
		"keys": [
			"self_reported_skill",
			"age_bracket",
			"gender",
			"genre_experience",
			"difficulty_feel",
			"retry_reason",
			"would_watch_real_ad",
		],
		"free": true,
		"title": "survey_title",
		"intro": "survey_intro",
	},
	"exit": {
		"keys": ["difficulty_feel", "unclear_system", "stop_reason", "would_watch_real_ad"],
		"free": true,
		"title": "survey_exit_title",
		"intro": "survey_exit_intro",
	},
	"pulse": {
		"keys": ["stop_reason"],
		"free": false,
		"title": "survey_pulse_title",
		"intro": "survey_pulse_intro",
	},
}

## 画像四项写进 person 属性用于分群；其余全部只留在事件上。
## 感受题随局变化，写成 person 属性会被后一局覆盖，历史就没了。
const PROFILE_KEYS := ["self_reported_skill", "age_bracket", "gender", "genre_experience"]

var form := "reward"
var source := ""

var _answers := {}
var _chips := {}
var _built := false
var _open_ms := 0
var _form_keys: Array = []
var _has_free := false
var _title_key := "survey_title"
var _intro_key := "survey_intro"
## 最后一次真正碰过的题。关掉时上报，用来看人卡在第几题跑掉——
## 只统计「答了几题」看不出是开头就走还是最后一题放弃。
var _last_key := ""
var _card: PanelContainer
var _title: Label
var _intro: Label
var _privacy: Label
var _scroll: ScrollContainer
var _body: VBoxContainer
var _free: LineEdit
var _submit: Button
var _later: Button
var _actions: HBoxContainer
## 手机触屏 + 鼠标回声可能连打两次；选项会选上又被取消。
var _chip_guard_ms := 0
## 系统键盘弹出时把卡片底边卡在输入法上方，输入条始终可见。
var _kb_watching := false
var _kb_pad_applied := -1.0
const _KB_GAP := 16.0


func scroll_box() -> ScrollContainer:
	return _scroll


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 高于设置（115）与信封按钮（120），低于 Toasts（510）。见 AGENTS.md 的层级表。
	z_index = 125
	visible = false
	set_process(false)
	_fit()
	get_viewport().size_changed.connect(_fit)
	_build()


## 铺满父节点。
##
## **必须是 `set_anchors_and_offsets_preset`，不能只用 `set_anchors_preset`。**
## 后者只改锚点、不重排，运行时 add_child 进来的 Control 尺寸会一直停在 0×0：
## 遮罩整个消失，卡片塌成内容的最小高度，题目一道都看不见——
## 弹是弹出来了，但看起来像个没内容的小条。这个坑踩过一次，别改回去。
func _fit() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## 打开某一份表单。同一张卡复用，题目每次按表单重建。
func open(p_form: String, p_source: String) -> void:
	form = p_form if FORMS.has(p_form) else "reward"
	source = p_source
	_open_ms = Time.get_ticks_msec()
	_last_key = ""
	_build_body(form)
	apply_locale()
	if _scroll != null:
		_scroll.scroll_vertical = 0
	visible = true


func close() -> void:
	_stop_keyboard_guard()
	if _free != null and _free.has_focus():
		_free.release_focus()
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()
	visible = false


func dwell_ms() -> int:
	return Time.get_ticks_msec() - _open_ms


## 当前表单一共几项（含自由文本）。完成度要按表单长度算，
## 不能拿绝对答题数横着比：三份表单的题量不一样。
func question_count() -> int:
	return _form_keys.size() + (1 if _has_free else 0)


## 最后碰过的题的键。一题都没碰是空字符串。
func last_question_key() -> String:
	return _last_key


## 最后碰过的题在本表单里的序号（自由文本算最后一项）。没碰过是 -1。
func last_question_index() -> int:
	if _last_key == "":
		return -1
	if _last_key == "free_text":
		return _form_keys.size()
	return _form_keys.find(_last_key)


func answered_count() -> int:
	var n := 0
	for k in _answers.keys():
		if str(_answers[k]) != "":
			n += 1
	if _has_free and _free != null and _free.text.strip_edges() != "":
		n += 1
	return n


func apply_locale() -> void:
	if not _built:
		return
	_title.text = Loc.t(_title_key)
	_intro.text = Loc.t(_intro_key)
	_privacy.text = Loc.t("survey_privacy")
	if _free != null:
		_free.placeholder_text = Loc.t("survey_free_hint")
	_submit.text = Loc.t("survey_submit")
	_later.text = Loc.t("survey_later")
	for node in _body.get_children():
		if node.has_meta("prompt_key"):
			(node as Label).text = Loc.t(str(node.get_meta("prompt_key")))
	for key in _chips.keys():
		for entry in _chips[key]:
			var btn: Button = entry[1]
			btn.text = Loc.t(str(entry[2]))


func _find_question(key: String) -> Dictionary:
	for q in QUESTIONS:
		if str(q.key) == key:
			return q
	return {}


func _build() -> void:
	if _built:
		return
	_built = true

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.03, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 28
	card.offset_right = -28
	_card = card
	var box := StyleBoxFlat.new()
	box.bg_color = CARD_BG
	box.border_color = INK
	box.set_border_width_all(4)
	box.set_corner_radius_all(22)
	card.add_theme_stylebox_override("panel", box)
	add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	_title = _label("", 30, true)
	col.add_child(_title)
	_intro = _label("", 17, false)
	_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_intro)

	# 最长的表单是七题加一行自由文本，一屏放不下。滚动容器是必需的，不是装饰。
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_scroll)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	_scroll.add_child(_body)
	MobileScroll.prepare(_scroll, _body)

	_privacy = _label("", 15, false)
	_privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_privacy.modulate.a = 0.75
	col.add_child(_privacy)

	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override("separation", 10)
	_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_actions)

	_later = Button.new()
	_later.custom_minimum_size = Vector2(150, 58)
	_style_button(_later, CHIP_BG)
	_later.pressed.connect(_on_later)
	_actions.add_child(_later)

	_submit = Button.new()
	_submit.custom_minimum_size = Vector2(190, 58)
	_style_button(_submit, CHIP_ON)
	_submit.pressed.connect(_on_submit)
	_actions.add_child(_submit)

	_build_body(form)


## 卡片高度按表单长短走：多题的铺满一屏，单题的收成一张居中的小卡。
## 一道题占满整屏会让人以为下面还有，而单题脉冲恰恰是最该「看一眼就答完」的那份。
func _apply_card_metrics() -> void:
	if _card == null:
		return
	if _form_keys.size() <= 1 and not _has_free:
		_card.anchor_top = 0.5
		_card.anchor_bottom = 0.5
		_card.offset_top = -COMPACT_HEIGHT * 0.5
		_card.offset_bottom = COMPACT_HEIGHT * 0.5
	else:
		_card.anchor_top = 0.0
		_card.anchor_bottom = 1.0
		_card.offset_top = 56
		_card.offset_bottom = -56


## 题目每次打开按表单重建。旧节点立即 free，不能 queue_free：
## 那样这一帧它们还在树里，两份表单的题会叠在一起。
func _build_body(p_form: String) -> void:
	var def: Dictionary = FORMS.get(p_form, FORMS["reward"])
	_form_keys = (def.get("keys", []) as Array).duplicate()
	_has_free = bool(def.get("free", true))
	_title_key = str(def.get("title", "survey_title"))
	_intro_key = str(def.get("intro", "survey_intro"))
	_answers.clear()
	_chips.clear()
	_free = null
	_apply_card_metrics()
	for child in _body.get_children():
		_body.remove_child(child)
		child.free()

	for key in _form_keys:
		var q := _find_question(str(key))
		if q.is_empty():
			continue
		var k := str(q.key)
		var prompt := _label("", 20, true)
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		prompt.set_meta("prompt_key", str(q.prompt))
		prompt.set_meta("answer_key", k)
		_body.add_child(prompt)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		_body.add_child(flow)
		_answers[k] = ""
		_chips[k] = []
		for opt in q.options:
			var value := str(opt[0])
			var chip := _make_chip()
			flow.add_child(chip)
			_chips[k].append([value, chip, str(opt[1])])
			chip.button_down.connect(_on_chip.bind(k, value))

	if not _has_free:
		return
	var free_prompt := _label("", 20, true)
	free_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	free_prompt.set_meta("prompt_key", "survey_q_free")
	_body.add_child(free_prompt)
	_free = LineEdit.new()
	# 限长并在提示里写明不要填联系方式：自由文本是最容易误收个人信息的地方。
	_free.max_length = 80
	_free.custom_minimum_size = Vector2(0, 52)
	_free.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_free.focus_mode = Control.FOCUS_ALL
	_free.virtual_keyboard_enabled = true
	_free.add_theme_font_size_override("font_size", 22)
	_free.add_theme_color_override("font_color", INK)
	_free.add_theme_color_override("font_placeholder_color", Color(INK, 0.45))
	_free.text_changed.connect(_on_free_changed)
	_free.focus_entered.connect(_on_free_focus_entered)
	_free.focus_exited.connect(_on_free_focus_exited)
	_free.gui_input.connect(_on_free_gui_input)
	_body.add_child(_free)


func _label(text: String, font_px: int, bold: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_px)
	l.add_theme_color_override("font_color", INK)
	if bold:
		l.add_theme_constant_override("outline_size", 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _make_chip() -> Button:
	var b := Button.new()
	b.toggle_mode = false
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.custom_minimum_size = Vector2(0, 50)
	b.add_theme_font_size_override("font_size", 19)
	_style_button(b, CHIP_BG)
	return b


func _style_button(b: Button, bg: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)


func _on_chip(key: String, value: String) -> void:
	var now := Time.get_ticks_msec()
	if now - _chip_guard_ms < 280:
		return
	_chip_guard_ms = now
	# 再点一次已选项等于取消，回到「未回答」——和「不想披露」不是一回事。
	_answers[key] = "" if str(_answers.get(key, "")) == value else value
	_last_key = key
	_sync_chips(key)


func _on_free_changed(_text: String) -> void:
	_last_key = "free_text"


func _on_free_gui_input(event: InputEvent) -> void:
	# 手机网页要先抢到焦点，experimentalVK 才会弹出系统输入法。
	var tap := false
	if event is InputEventScreenTouch and event.pressed:
		tap = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap = true
	if not tap or _free == null:
		return
	_free.grab_focus()


func _on_free_focus_entered() -> void:
	_last_key = "free_text"
	_start_keyboard_guard()


func _on_free_focus_exited() -> void:
	_stop_keyboard_guard()
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()


func _start_keyboard_guard() -> void:
	_kb_watching = true
	_kb_pad_applied = -1.0
	set_process(true)
	call_deferred("_sync_keyboard_layout", true)


func _stop_keyboard_guard() -> void:
	var was := _kb_watching or _kb_pad_applied > 0.0
	_kb_watching = false
	_kb_pad_applied = -1.0
	set_process(false)
	if _privacy:
		_privacy.visible = true
	if _actions:
		_actions.visible = true
	if was:
		_apply_card_metrics()
		_reset_web_viewport()


func _process(_delta: float) -> void:
	if not _kb_watching:
		return
	if not visible or _free == null or not _free.has_focus():
		_stop_keyboard_guard()
		return
	_sync_keyboard_layout(false)


func _read_keyboard_pad() -> float:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return 0.0
	var raw = Engine.get_singleton("JavaScriptBridge").eval(
		"window.CluckKb && typeof window.CluckKb.pad === 'number' ? window.CluckKb.pad : 0",
		true
	)
	if raw == null:
		return 0.0
	return maxf(0.0, float(raw))


## 收起键盘后浏览器常把 visualViewport 留在半空：卡片缩着、整页偏上。
## 强制 scroll 归零并清 pad，再把卡片锚点拉回正常。
func _reset_web_viewport() -> void:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return
	Engine.get_singleton("JavaScriptBridge").eval(
		"window.CluckKb&&window.CluckKb.reset&&window.CluckKb.reset()",
		true
	)


func _sync_keyboard_layout(force_show_vk: bool) -> void:
	if _card == null or _free == null or not _free.has_focus():
		return
	var view_h := get_viewport_rect().size.y
	var pad := _read_keyboard_pad()
	if pad <= 12.0 and force_show_vk and OS.has_feature("web"):
		# 键盘高度还没报到时先按常见占比抬，避免首帧被挡住。
		pad = clampf(view_h * 0.38, 180.0, view_h * 0.5)
	if pad <= 12.0:
		# 键盘已收但焦点还在输入框：立刻把卡片弹回全高，别卡在「半屏上」。
		if _kb_pad_applied > 0.0:
			_kb_pad_applied = -1.0
			if _privacy:
				_privacy.visible = true
			if _actions:
				_actions.visible = true
			_apply_card_metrics()
			_reset_web_viewport()
		elif force_show_vk:
			_scroll_free_above_keyboard(0.0)
			call_deferred("_reshow_virtual_keyboard")
		return
	if absf(pad - _kb_pad_applied) < 8.0 and not force_show_vk:
		_keep_free_above_keyboard(pad)
		return
	_kb_pad_applied = pad
	# 打字时收起底栏，把输入条放到卡片最底（紧贴输入法上方）。
	if _privacy:
		_privacy.visible = false
	if _actions:
		_actions.visible = false
	# 卡片底边停在键盘顶上方，输入条落在卡片底部。
	_card.anchor_top = 0.0
	_card.anchor_bottom = 1.0
	_card.offset_top = 24.0
	_card.offset_bottom = -(pad + _KB_GAP)
	_scroll_free_above_keyboard(pad)
	call_deferred("_keep_free_above_keyboard", pad)
	if force_show_vk or DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		call_deferred("_reshow_virtual_keyboard")


func _scroll_free_above_keyboard(_pad: float) -> void:
	if _scroll == null or _free == null:
		return
	# 开放题滚到滚动视口底部，贴着卡片下沿（也就是输入法上方）。
	var target := _free.position.y + _free.size.y - _scroll.size.y + 8.0
	_scroll.scroll_vertical = maxi(0, int(target))


func _keep_free_above_keyboard(pad: float) -> void:
	if _free == null or not _free.has_focus() or _card == null:
		return
	var view_h := get_viewport_rect().size.y
	var kb_top := view_h - pad
	var free_bottom := _free.get_global_rect().end.y
	var overflow := free_bottom - (kb_top - _KB_GAP)
	if overflow <= 2.0:
		return
	_card.offset_bottom = _card.offset_bottom - overflow
	_scroll_free_above_keyboard(pad)


func _reshow_virtual_keyboard() -> void:
	if _free == null or not _free.has_focus():
		return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return
	DisplayServer.virtual_keyboard_show(
		_free.text,
		_free.get_global_rect(),
		DisplayServer.KEYBOARD_TYPE_DEFAULT,
		_free.max_length
	)


func _sync_chips(key: String) -> void:
	var picked := str(_answers.get(key, ""))
	for entry in _chips[key]:
		var value: String = entry[0]
		var btn: Button = entry[1]
		_style_button(btn, CHIP_ON if value == picked else CHIP_BG)


func _on_later() -> void:
	var ms := dwell_ms()
	var n := answered_count()
	close()
	dismissed.emit(ms, n)
	closed.emit()


func _missing_required_keys() -> Array:
	var missing: Array = []
	for key in _form_keys:
		if str(_answers.get(key, "")) == "":
			missing.append(str(key))
	return missing


func _scroll_to_key(key: String) -> void:
	if _scroll == null or _body == null:
		return
	for node in _body.get_children():
		if not (node is Control) or not node.has_meta("answer_key"):
			continue
		if str(node.get_meta("answer_key")) != key:
			continue
		var target := node as Control
		_scroll.scroll_vertical = maxi(0, int(target.position.y) - 12)
		return


func _prompt_incomplete(first_key: String) -> void:
	var game := get_parent()
	if game != null and game.has_method("_toast"):
		game.call("_toast", Loc.t("survey_need_all"))
	call_deferred("_scroll_to_key", first_key)


func _on_submit() -> void:
	var missing := _missing_required_keys()
	if not missing.is_empty():
		_prompt_incomplete(str(missing[0]))
		return
	var out := {}
	for key in _answers.keys():
		var v := str(_answers[key])
		# 未回答不写进事件：缺属性和 "undisclosed" 在报表里必须分得开。
		if v != "":
			out[key] = v
	if _has_free and _free != null:
		var free := _free.text.strip_edges()
		if free != "":
			out["free_text"] = free
	out["answered_count"] = answered_count()
	out["dwell_ms"] = dwell_ms()
	close()
	submitted.emit(out)
	closed.emit()
