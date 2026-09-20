extends Node
## 统一统计入口（Autoload 名 `Analytics`）。
##
## 设计约束，改动前请先看 docs/ANALYTICS.md：
##
## 1. 非 Web 环境、未配置 token、SDK 没加载：全部安全退化成空操作，
##    绝不阻塞启动，也绝不抛错。冒烟测试会显式 `enabled = false`。
## 2. 不做逐次动作的事件。玩法动作只在客户端累加计数，
##    随 30 秒一条的 `playtime_tick` 和每天一条的 `day_end` 上报。
## 3. 成功事件只在状态确实变更之后发。界面重绘、刷新页面重开结算卡
##    不得重复计一次通关或一次入口曝光——去重键由调用方传进来。
## 4. 有效时长用单调时钟累加，后台、问卷、等待、主菜单都不计入。

const SCHEMA_VERSION := 1

## 每累计这么多「有效游玩」时间提交一条区间摘要。
## 计划 §3.5 原写 15 秒，这里按 30 秒合并了心跳与区间摘要：
## 一条事件同时承担两件事，20 分钟会话约 40 条，留在免费额度内。
const TICK_ACTIVE_MS := 30000

## 超过这么久没有任何输入就停止累计有效时长。
## 本作有自动生产（母鸡下蛋、烤炉推进），不能要求玩家每秒点击才算在玩，
## 但也不能让挂机页面一直涨时长。
const IDLE_CUTOFF_MS := 60000

## 同一原因的连续拒绝在这个窗口内只算一次尝试。
const DENY_DEBOUNCE_MS := 600

## 首次游玩会话的累计有效时长节点（毫秒）：1 / 3 / 5 / 10 / 20 分钟。
const MILESTONES := [60000, 180000, 300000, 600000, 1200000]

## 玩家可见阶段。只有 tutorial / play 计入有效时长；
## settle 单独计时；menu / survey / wait / boot 两者都不计。
const PHASE_BOOT := "boot"
const PHASE_MENU := "menu"
const PHASE_TUTORIAL := "tutorial"
const PHASE_PLAY := "play"
const PHASE_SETTLE := "settle"
const PHASE_SURVEY := "survey"
const PHASE_WAIT := "wait"

## 区间计数的全部键。列在这里是为了每次开新区间都能归零成 0，
## 而不是缺键——缺键在 PostHog 里求和会变成「没有这个属性」而不是 0。
const COUNTER_KEYS := [
	"collect_egg_count",
	"hatch_start_count",
	"hatch_collect_count",
	"bake_start_count",
	"bake_complete_count",
	"cake_sell_count",
	"stock_buy_count",
	"stock_sell_count",
	"chick_buy_count",
	"hen_sell_count",
	"bakery_upgrade_count",
	"tap_count",
	"hold_count",
	"hold_duration_ms",
	"deny_funds_count",
	"deny_resource_count",
	"deny_other_count",
]

var enabled := true
var verbose := false

var live := false
var storage_ok := false
var distinct_id := ""
var visit_id := ""
var js_session_id := ""
var cohort := "unknown"
## 三份问卷各有各的完成标记，互不影响：
## `survey_done` 只管奖励入口的主问卷（决定入口给问卷还是五秒等待），
## `exit_done` 管设置里的补充反馈，`pulse_done` 管回主菜单的单题脉冲。
## 合成一个布尔会让「填过主问卷的人再也问不到流失原因」。
var survey_done := false
var exit_done := false
var pulse_done := false
var first_play_done := false
var test_env := false

var build := "dev"
var lang := "en"

var phase := PHASE_BOOT
var page_hidden := false

var mode := "menu"
var day := 0
var run_id := ""
var attempt_id := ""
var attempt_index := 0
var source_offer_id := ""
var source_decision_id := ""

var active_ms_total := 0
var settle_ms_total := 0
var first_play_session := false

var _js: Object = null
var _vis_cb = null
var _seen_keys := {}
var _milestones_sent := {}
var _counters := {}
var _day_counters := {}
var _interval_id := ""
var _interval_seq := 0
var _tick_active_ms := 0
var _tick_settle_ms := 0
var _last_input_ms := 0
var _last_deny_reason := ""
var _last_deny_ms := 0
var _poll_acc := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_last_input_ms = Time.get_ticks_msec()
	_reset_counters()
	_reset_day_counters()
	_interval_id = new_id()
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		_js = Engine.get_singleton("JavaScriptBridge")
	if _js == null:
		# 编辑器、桌面调试、headless 冒烟测试都会走到这里。
		enabled = false
		return
	_read_identity()
	_bind_visibility()


## 生成一个标识。所有 run / attempt / offer / decision / interval 标识都从这里来。
func new_id() -> String:
	return "%x%08x%08x" % [Time.get_unix_time_from_system(), _rng.randi(), _rng.randi()]


func set_build(p_build: String) -> void:
	build = p_build


func set_lang(p_lang: String) -> void:
	lang = p_lang


## 局上下文。续档时传原来的 run_id，新开一局才换。
func set_run(p_run_id: String, p_attempt_id: String, p_attempt_index: int) -> void:
	run_id = p_run_id
	attempt_id = p_attempt_id
	attempt_index = p_attempt_index


func set_mode(p_mode: String) -> void:
	mode = p_mode


func set_day(p_day: int) -> void:
	day = p_day


## 恢复/继续归属。持续到下一次重试恢复、新局或本次会话结束。
func set_source_offer(p_offer_id: String) -> void:
	source_offer_id = p_offer_id


func set_source_decision(p_decision_id: String) -> void:
	source_decision_id = p_decision_id


## 切阶段前先把当前区间的时间结掉，避免把结算时间算进游玩时间。
func set_phase(p_phase: String) -> void:
	if phase == p_phase:
		return
	phase = p_phase


func note_input() -> void:
	_last_input_ms = Time.get_ticks_msec()


func mark_first_play() -> void:
	if first_play_done:
		first_play_session = false
		return
	first_play_session = true
	first_play_done = true
	_eval("window.CluckA && window.CluckA.markFirstPlayDone()")


func mark_survey_done() -> void:
	survey_done = true
	_eval("window.CluckA && window.CluckA.markSurveyDone()")


func mark_exit_done() -> void:
	exit_done = true
	_eval("window.CluckA && window.CluckA.markExitDone()")


func mark_pulse_done() -> void:
	pulse_done = true
	_eval("window.CluckA && window.CluckA.markPulseDone()")


## 设置「Reset Game」专用：换新匿名身份，问卷和首玩标记一并清掉。
## 结算卡「再开一局」不要走这里，否则会把成就和问卷进度一起抹掉。
func reset_player() -> void:
	_eval("window.CluckA && window.CluckA.resetPlayer()")
	_seen_keys.clear()
	_milestones_sent.clear()
	first_play_session = false
	first_play_done = false
	survey_done = false
	exit_done = false
	pulse_done = false
	active_ms_total = 0
	settle_ms_total = 0
	run_id = ""
	attempt_id = ""
	attempt_index = 0
	source_offer_id = ""
	source_decision_id = ""
	_interval_seq = 0
	_interval_id = new_id()
	_tick_active_ms = 0
	_tick_settle_ms = 0
	_reset_counters()
	_reset_day_counters()
	if _js != null:
		_read_identity()


## 玩法动作计数。同时进区间摘要和当天合计。
##
## 注意：长按连点走的是 `quiet = true`，和冒烟测试同一个标记，
## 所以计数不能靠 `quiet` 区分测试调用——测试靠 `enabled = false` 关掉。
func bump(key: String, amount := 1) -> void:
	if not enabled or amount == 0:
		return
	_counters[key] = int(_counters.get(key, 0)) + amount
	_day_counters[key] = int(_day_counters.get(key, 0)) + amount


## 手势计数与动作计数分开：一次长按收 8 个蛋是 1 次手势、8 次动作。
func note_gesture(is_hold: bool, hold_ms := 0) -> void:
	if not enabled:
		return
	if is_hold:
		bump("hold_count")
		if hold_ms > 0:
			bump("hold_duration_ms", hold_ms)
	else:
		bump("tap_count")


## 无效尝试。长按被挡住时，一次按压会先后产生「首次点击」和「重复 tick」两次拒绝，
## 所以同一原因在 DENY_DEBOUNCE_MS 内只算一次连续尝试。
func note_deny(reason: String) -> void:
	if not enabled:
		return
	var now := Time.get_ticks_msec()
	if reason == _last_deny_reason and now - _last_deny_ms < DENY_DEBOUNCE_MS:
		_last_deny_ms = now
		return
	_last_deny_reason = reason
	_last_deny_ms = now
	match reason:
		"funds":
			bump("deny_funds_count")
		"resource":
			bump("deny_resource_count")
		_:
			bump("deny_other_count")


## 取当天累计动作数，给 day_end 用。
func day_counters() -> Dictionary:
	var out := {}
	for k in COUNTER_KEYS:
		out["day_" + k] = int(_day_counters.get(k, 0))
	return out


func reset_day_counters() -> void:
	_reset_day_counters()


## 主上报口。props 覆盖公共字段，同名以 props 为准。
func log_event(event: String, props := {}, flush := false) -> void:
	if not enabled:
		if verbose:
			print("[analytics] ", event, " ", props)
		return
	var payload := _context()
	for k in props.keys():
		payload[k] = props[k]
	_send(event, payload, flush)


## 带去重键的上报：同一个 key 在本次访问里只发一次。
## 用于「刷新页面会重开结算卡」这类会重复触发的曝光与终局事件。
func log_once(key: String, event: String, props := {}, flush := false) -> bool:
	if not enabled:
		return false
	if _seen_keys.has(key):
		return false
	_seen_keys[key] = true
	log_event(event, props, flush)
	return true


func seen(key: String) -> bool:
	return _seen_keys.has(key)


func mark_seen(key: String) -> void:
	_seen_keys[key] = true


## 写入画像属性（问卷提交成功时调用一次）。
func set_person(props: Dictionary) -> void:
	if not enabled:
		return
	_eval("window.CluckA && window.CluckA.setPerson(%s)" % JSON.stringify(JSON.stringify(props)))


## 在阶段边界补报非空区间：日结、教学结束、回档前、模式切换、页面隐藏。
func flush_interval(reason: String) -> void:
	if not enabled:
		return
	var has_time := _tick_active_ms > 0 or _tick_settle_ms > 0
	var has_action := false
	for k in COUNTER_KEYS:
		if int(_counters.get(k, 0)) != 0:
			has_action = true
			break
	if not has_time and not has_action:
		return
	var props := {
		"interval_id": _interval_id,
		"interval_seq": _interval_seq,
		"reason": reason,
		"active_ms": _tick_active_ms,
		"settle_ms": _tick_settle_ms,
		"active_ms_total": active_ms_total,
		"is_tutorial": phase == PHASE_TUTORIAL,
		"first_play_session": first_play_session,
	}
	for k in COUNTER_KEYS:
		props[k] = int(_counters.get(k, 0))
	log_event("playtime_tick", props, reason != "interval")
	_interval_seq += 1
	_interval_id = new_id()
	_tick_active_ms = 0
	_tick_settle_ms = 0
	_reset_counters()


func _process(delta: float) -> void:
	if not enabled:
		return
	_poll_visibility(delta)
	var ms := int(delta * 1000.0)
	if ms <= 0:
		return
	# 单帧跨度过大（切后台回来、断点、系统休眠）不计入有效时长。
	if ms > 2000:
		return
	if page_hidden:
		return
	if phase == PHASE_SETTLE:
		_tick_settle_ms += ms
		settle_ms_total += ms
		return
	if phase != PHASE_PLAY and phase != PHASE_TUTORIAL:
		return
	if Time.get_ticks_msec() - _last_input_ms > IDLE_CUTOFF_MS:
		return
	_tick_active_ms += ms
	active_ms_total += ms
	_check_milestones()
	if _tick_active_ms >= TICK_ACTIVE_MS:
		flush_interval("interval")


func _check_milestones() -> void:
	for m in MILESTONES:
		if active_ms_total < int(m):
			continue
		if _milestones_sent.has(m):
			continue
		_milestones_sent[m] = true
		log_event("playtime_milestone", {
			"seconds": int(int(m) / 1000.0),
			"first_play_session": first_play_session,
			"active_ms_total": active_ms_total,
			"settle_ms_total": settle_ms_total,
		}, true)


func _poll_visibility(delta: float) -> void:
	# 回调注册成功时这里只是兜底；注册失败（旧浏览器、接口变动）时它就是唯一来源。
	_poll_acc += delta
	if _poll_acc < 0.5:
		return
	_poll_acc = 0.0
	var raw = _eval("window.CluckA ? (window.CluckA.hidden ? 1 : 0) : 0")
	if raw == null:
		return
	var hidden := int(raw) == 1
	if hidden != page_hidden:
		_set_hidden(hidden)


func _set_hidden(hidden: bool) -> void:
	if page_hidden == hidden:
		return
	page_hidden = hidden
	if hidden:
		flush_interval("page_hidden")
	else:
		# 回到前台不算玩家操作，但要把静置计时重新起算，
		# 否则切回来的第一分钟会被当成挂机而不计时长。
		_last_input_ms = Time.get_ticks_msec()


func _on_js_visibility(args: Array) -> void:
	var hidden := args.size() > 0 and int(args[0]) == 1
	_set_hidden(hidden)


func _context() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"build": build,
		"lang": lang,
		"mode": mode,
		"day": day,
		"phase": phase,
		"run_id": run_id,
		"attempt_id": attempt_id,
		"retry_index": attempt_index,
		"source_offer_id": source_offer_id,
		"source_decision_id": source_decision_id,
		"active_ms_total": active_ms_total,
		"first_play_session": first_play_session,
	}


func _send(event: String, props: Dictionary, flush: bool) -> void:
	var body := JSON.stringify({"event": event, "props": props, "flush": flush})
	_eval("window.CluckA && window.CluckA.capture(%s)" % JSON.stringify(body))


func _eval(code: String):
	if _js == null:
		return null
	return _js.eval(code, true)


func _read_identity() -> void:
	var raw = _eval("window.CluckA ? window.CluckA.identity() : ''")
	if typeof(raw) != TYPE_STRING or str(raw) == "":
		# 外壳脚本没加载（导出预设的 head_include 掉了）。不报错，静默停用。
		enabled = false
		return
	var parsed = JSON.parse_string(str(raw))
	if typeof(parsed) != TYPE_DICTIONARY:
		enabled = false
		return
	var d: Dictionary = parsed
	distinct_id = str(d.get("distinct_id", ""))
	visit_id = str(d.get("visit_id", ""))
	js_session_id = str(d.get("session_id", ""))
	cohort = str(d.get("cohort", "unknown"))
	storage_ok = bool(d.get("storage_ok", false))
	live = bool(d.get("live", false))
	test_env = bool(d.get("test_env", false))
	survey_done = bool(d.get("survey_done", false))
	exit_done = bool(d.get("exit_done", false))
	pulse_done = bool(d.get("pulse_done", false))
	first_play_done = bool(d.get("first_play_done", false))


func _bind_visibility() -> void:
	if _js == null or not _js.has_method("create_callback"):
		return
	_vis_cb = _js.create_callback(Callable(self, "_on_js_visibility"))
	var win = _js.get_interface("window")
	if win == null:
		return
	var api = win.CluckA
	if api == null:
		return
	api.onVisibility = _vis_cb


func _reset_counters() -> void:
	_counters.clear()
	for k in COUNTER_KEYS:
		_counters[k] = 0


func _reset_day_counters() -> void:
	_day_counters.clear()
	for k in COUNTER_KEYS:
		_day_counters[k] = 0
