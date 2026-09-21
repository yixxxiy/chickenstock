extends Control

const UiLayout := preload("res://scripts/UiLayout.gd")
const UiStyle := preload("res://scripts/UiStyle.gd")

const SheetSpr := preload("res://scripts/SheetSprite.gd")
const SurveyCardScript := preload("res://scripts/SurveyCard.gd")
## 占位等待秒数。这是等待，不是广告：文案和事件都不得说成广告。
const REWARD_WAIT_SECONDS := 5
## 问卷题目或选项有任何改动都要加一，否则新旧回答会被混在一张表里。
## 2：加入难度感受 / 没看懂的系统 / 停下来的原因 / 真广告意愿，并拆成三份表单。
const SURVEY_VERSION := 3
## 主菜单单题脉冲的门槛：累计有效游玩不到这么久不问。
## 教学第一分钟就弹一次问卷会直接赶走人；这条线也保证问到的人确实玩过。
const PULSE_MIN_ACTIVE_MS := 60000
const YardBirdScr := preload("res://scripts/YardBird.gd")
const UiSimplePanel := preload("res://assets/ui/farm-ui/simple-ui/panel.png")
const UiSimpleBeige := preload("res://assets/ui/farm-ui/simple-ui/button-beige.png")
const UiSimpleGreen := preload("res://assets/ui/farm-ui/simple-ui/button-green.png")
const UiSimpleRed := preload("res://assets/ui/farm-ui/simple-ui/button-red.png")
const UiSimpleTag := preload("res://assets/ui/farm-ui/simple-ui/tag.png")
const UiChipOn := preload("res://assets/ui/farm-ui/simple-ui/chip-on.png")
const UiFlourish := preload("res://assets/ui/farm-ui/simple-ui/flourish.png")
const LogoWordZh := preload("res://assets/ui/logo_wordmark.png")
const LogoWordEn := preload("res://assets/ui/logo_wordmark_en.png")

const DAY_MS := 20000.0
const TUTORIAL_DAY_MS := 60000.0
const DUSK_WARN_MS := 5000.0
const EGG_PRE_DUSK_RATIO := 0.75
const EGG_PRE_DUSK_FLOOR := 0.65
const EGG_FIRST_MIN_S := 0.0
const EGG_FIRST_MAX_S := 1.0
const HOLD_REP_S := 0.11
const EGG_HOLD_REP_S := 0.22
const BAKE_HOLD_S := 0.30
const BAKE_HOLD_LV5_S := 0.20
const BAKE_HOLD_LV6_S := 0.10
const BAKE_IGNITE_S := 0.10
const WEALTH_GOAL := 3000
const FLOCK_GOAL := 15
const CHICK_COST := 50
const CHICK_SALE := 40
const CAKE_SALE := 150
const BAKE_STEP_BASE := 0.12
const BAKERY_MAX_LEVEL := 6
const CAMPAIGN_BAKERY_MAX := 4
const BAKERY_UPGRADE_COSTS := [0, 200, 500, 950, 1600, 2800]
const BAKERY_SPEED_MULTIPLIERS := [1.60, 1.05, 0.70, 0.42, 0.30, 0.20]
const CHALLENGE_GATES := [
	{"day": 12, "wealth": 7300, "birds": 22},
	{"day": 16, "wealth": 11600, "birds": 37},
	{"day": 20, "wealth": 22500, "birds": 58},
]
const SAVE_PATH := "user://cluck-farm-v7.json"
const TUTORIAL_PATH := "user://cluck-tutorial.json"
const TROPHY_PATH := "user://cluck-trophies.json"
const UNLOCK_PATH := "user://cluck-unlocks.json"
const TROPHY_DEFS := [
	{"id": "primer", "icon": "res://icons/chick.png", "title": "trophy_primer", "desc": "trophy_primer_desc"},
	{"id": "cake", "icon": "res://icons/cake.png", "title": "trophy_cake", "desc": "trophy_cake_desc"},
	{"id": "hen", "icon": "res://icons/hen.png", "title": "trophy_hen", "desc": "trophy_hen_desc"},
	{"id": "share", "icon": "res://icons/stock.png", "title": "trophy_share", "desc": "trophy_share_desc"},
	{"id": "flock", "icon": "res://icons/hen.png", "title": "trophy_flock", "desc": "trophy_flock_desc"},
	{"id": "day8", "icon": "res://assets/ui/settlement/layers/22-quest-stamp.png", "title": "trophy_day8", "desc": "trophy_day8_desc"},
	{"id": "endless7", "icon": "res://assets/ui/logo_icon.png", "title": "trophy_endless7", "desc": "trophy_endless7_desc"},
	{"id": "chicken_king", "icon": "res://icons/hen.png", "title": "trophy_chicken_king", "desc": "trophy_chicken_king_desc"},
	{"id": "chicken_emperor", "icon": "res://icons/hen.png", "title": "trophy_chicken_emperor", "desc": "trophy_chicken_emperor_desc"},
	{"id": "retail_not_chives", "icon": "res://icons/stock.png", "title": "trophy_retail", "desc": "trophy_retail_desc"},
	{"id": "stock_god", "icon": "res://icons/stock.png", "title": "trophy_stock_god", "desc": "trophy_stock_god_desc"},
]
const WEALTH_TROPHY_DEFS := [
	{"id": "wealth_100k", "min": 100000, "title": "trophy_wealth_100k", "desc": "trophy_wealth_tier_desc"},
	{"id": "wealth_90k", "min": 90000, "title": "trophy_wealth_90k", "desc": "trophy_wealth_tier_desc"},
	{"id": "wealth_80k", "min": 80000, "title": "trophy_wealth_80k", "desc": "trophy_wealth_tier_desc"},
	{"id": "wealth_70k", "min": 70000, "title": "trophy_wealth_70k", "desc": "trophy_wealth_tier_desc"},
	{"id": "wealth_60k", "min": 60000, "title": "trophy_wealth_60k", "desc": "trophy_wealth_tier_desc"},
	{"id": "wealth_50k", "min": 50000, "title": "trophy_wealth_50k", "desc": "trophy_wealth_tier_desc"},
	{"id": "wealth_40k", "min": 40000, "title": "trophy_wealth_40k", "desc": "trophy_wealth_tier_desc"},
	{"id": "wealth_30k", "min": 30000, "title": "trophy_wealth_30k", "desc": "trophy_wealth_tier_desc"},
	{"id": "wealth_20k", "min": 20000, "title": "trophy_wealth_20k", "desc": "trophy_wealth_tier_desc"},
]
const CAMPAIGN_RANK_CAP := 10
# Long-run guards. A challenge run reaches 58+ birds and day 20, and every bird
# is its own animated YardBird node; the wealth log otherwise grows forever and
# goes into the save as-is.
const FLOCK_RENDER_CAP := 28
const WEALTH_LOG_MAX := 40
const WORLD_BACK := ["Bg", "Map", "Flock", "HatchEgg"]
const WORLD_FRONT := [
	"EggThought", "CakeThought", "HatchThought", "ChickThought",
	"BakeryEggs", "BakeryUpgrade", "FlyLayer",
]

const NEWS := {
	"hoard": {"text": "狼商囤粮", "up": true, "weather": "cloud"},
	"cake": {"text": "蛋糕热销", "up": true, "weather": "sun"},
	"rain": {"text": "雨天减产", "up": false, "weather": "rain"},
}

const RANKS := [
	{"lv": 1, "min": 0, "title": "流浪小鸡"},
	{"lv": 2, "min": 500, "title": "见习农民"},
	{"lv": 3, "min": 1000, "title": "咯咯佃农"},
	{"lv": 4, "min": 1600, "title": "篱笆鸡舍"},
	{"lv": 5, "min": 2300, "title": "积谷农户"},
	{"lv": 6, "min": 3000, "title": "温饱农场"},
	{"lv": 7, "min": 4200, "title": "街口商贩"},
	{"lv": 8, "min": 5200, "title": "农场掌柜"},
	{"lv": 9, "min": 6500, "title": "金币大亨"},
	{"lv": 10, "min": 8000, "title": "农场传奇"},
	{"lv": 11, "min": 13000, "title": "农场街新贵"},
	{"lv": 12, "min": 18000, "title": "鸡隆·股斯克"},
]

const FENCE_POLY := [
	Vector2(18.5, 58.5), Vector2(26.0, 54.5), Vector2(38.0, 50.8), Vector2(50.0, 49.8),
	Vector2(64.0, 51.0), Vector2(74.0, 54.5), Vector2(78.0, 59.0), Vector2(75.0, 64.5),
	Vector2(69.0, 69.5), Vector2(48.0, 71.5), Vector2(28.0, 69.5), Vector2(18.5, 64.5),
]

var _walk_poly_pts: Array = []
var _yard_spot_cache: Array[Vector2] = []

var coins := 120
var eggs := 0
var ready_eggs := 3
var pending_eggs := 0
var hens := 1
var young_chicks := 0
var cakes := 0
var cakes_sold := 0
var shares := 0
var stock_spent := 0
var stock_sold := 0
var price := 120
var day := 1
var left_ms := DAY_MS
var history: Array[int] = [108, 96, 132, 114, 120]
var wealth_log: Array[int] = [120]
var baking := 0
var bakery_level := 1
var hatching := 0
var hatched := 0
var news := "cake"
var seen_goal := 0
var mail_seen := ""
var settling := false
var game_result := ""
var endless_mode := false
var challenge_mode := false
# One reward-retry per gate day, tracked independently: spending day 12's does
# not touch day 16's or day 20's. Keys are the gate day, as String (JSON).
var _gate_retry_used: Dictionary = {}
var _normal_cleared := false
var _challenge_cleared := false
var _return_to_menu := false
# ---- 统计标识。只用于埋点，不参与任何玩法判断。 ----
# run_id / attempt_id 必须进存档：_enter_play 的续档分支不重置任何状态，
# 只放内存的话玩家刷新后续档会换新 run_id，第 1–8 天漏斗会断成两截。
var run_id := ""
var attempt_id := ""
var attempt_index := 0
# 一次奖励重试机会，贯穿曝光→点击→问卷/等待→恢复。刷新页面重开结算卡不新建。
var _offer_id := ""
var _offer_context := ""
var _offer_reward := ""
var _retry_resume_offer := ""
# 终局后的一次主动选择。要跨过主菜单才能落到新局上，所以带过期时间。
var _decision_id := ""
var _decision_prev_run := ""
var _decision_choice := ""
var _decision_ms := 0
var _continuation_decision := ""
var _tutorial_start_ms := 0
var _tutorial_step_ms := 0
var _gesture_start_ms := 0
var _offer_key := ""
var survey_pop: Control = null
var _settings_feedback_btn: Button = null
## 问卷这一次是从哪里打开的。和 _offer_context 分开：设置里的反馈入口
## 只补填问卷、不发奖励，不能借用某次重试机会的上下文。
var _survey_source := ""
var _survey_offer := ""
## 这一次开的是哪份表单（reward / exit / pulse）。提交后按它决定记哪个完成标记，
## 也随事件上报——三份表单题量不同，完成率不能混在一起算。
var _survey_form := "reward"
## 玩过一局之后回主菜单才问脉冲。在这里置位，在 _show_main_menu 里消费：
## 开局第一次进菜单（还没玩过）不问，正要再开一局的人也不问。
var _pulse_pending := false
## 冒烟测试用：跳过问卷/等待这一段，直接发奖励。
## 那些测试验的是额度与存档，不是奖励 UI；不跳过的话 `await pop.closed`
## 在无人点击的 headless 环境里会永远等下去。玩家不会走到这条分支。
var skip_reward_gate := false
var _trophies: Dictionary = {}
var summary: Dictionary = {}
var _dawn_snap: Dictionary = {}
var just_grown := 0
var fanfare := false
var _booted := false
var show_quest := false
var show_settings := false
var reveal := "off"
var _quest_ignore_close := false
var _settings_ignore_close := false
var _audio_toggle_ms := 0
var _quest_toggle_ms := 0
var _settings_toggle_ms := 0
var _hatch_ignore_ms := 0
var panic_told := false
var quest_done := false
var _bake_acc := 0.0
var _egg_acc := 0.0
var _egg_ready_acc := 0.0
var _egg_drip_gap := 0.0
var _egg_pre_dusk_target := 0
var _egg_drip_at: Array[float] = []
var _bake_hold := 0.0
var _bake_bar: Panel
var _bake_fill: Panel
var _bake_label: Label
var _cake_baking_ui := false
var _hold_fn: Callable
var _hold_wait := 0.0
var _hold_rep := 0.0
var _holding := false
var _hold_btn: BaseButton
## Active long-presses keyed by button. Multi-finger holds each keep their own
## repeat timer so egg + buy (etc.) can collect in parallel on phones.
var _holds: Dictionary = {}
var _sweep_hit: Control = null
var _manual_button: BaseButton = null
## touch index → armed button. Multi-finger taps must not share one slot —
## otherwise the 2nd finger steals/cancels the 1st, and release fires the wrong btn.
var _armed_touches: Dictionary = {}
var _press_from_touch := false
var _flock_sig := ""
var _cash_shown := 120.0
var _stock_shown := 0.0
var _dusk_hurry := false
var _fx := 0
var tutorial_mode := false
var tutorial_day := 0
var tutorial_step := 0
var tutorial_eggs_stored := 0
var tutorial_eggs_tapped := 0
var _had_main_save := false
var _tutorial_focused_target: Control
var _tutorial_target_z_index := 0
var _tutorial_target_z_as_relative := true

var sfx: Node
var juice: Node
var _worlds: Array[Control] = []
var _touch_pos: Dictionary = {}
## Per-finger vertical travel while dragging. Used so survey chip taps aren't
## cancelled by ScrollContainer micro-jitter on phones.
var _touch_drag_travel: Dictionary = {}
var _mouse_drag_travel := 0.0
## 成就 / 问卷 / 设置列表：跟手速度 + 松手惯性。
var _kin_scroll := MobileScroll.new()
var _scroll_dragging := false
@onready var flock_layer: Control = $Flock
@onready var hen_placement: TextureRect = $EditorAssetPlacement/HenPreview
@onready var chick_placement: TextureRect = $EditorAssetPlacement/ChickPreview
@onready var hud_cash: Label = $HUD/HudBar/CashChip/Row/CashBox/Cash
@onready var hud_stock: Label = $HUD/HudBar/StockChip/Row/StockBox/Stock
@onready var hud_hens: Label = $HUD/HudBar/HenChip/Row/Num
@onready var hud_chicks: Label = $HUD/HudBar/ChickChip/Row/Num
@onready var hud_bar: Control = $HUD/HudBar
@onready var hud_bar_bg: Panel = $HUD/HudBar/HudBarBg
@onready var day_label: Label = $HUD/ClockBox/DayChip/DayLabel
@onready var day_clock: DayClock = $HUD/ClockBox/Clock
@onready var toast_box: VBoxContainer = $Toasts
@onready var night: ColorRect = $Night
@onready var card: Control = $Night/Card
@onready var quest_pop: Control = $QuestPop
@onready var quest_card: PanelContainer = $QuestPop/Card
@onready var settings_pop: Control = $SettingsPop
@onready var settings_card: PanelContainer = $SettingsPop/Card
@onready var guide_pop: Control = $GuidePop
@onready var guide_card: TextureRect = $GuidePop/GuideCard
@onready var egg_btn: Button = $EggThought
@onready var cake_btn: Button = $CakeThought
@onready var hatch_btn: Button = $HatchThought
@onready var chick_btn: Button = $ChickThought
@onready var ticker_price: Label = $Dock/Row/Ticker/Face/Col/TickerPrice
@onready var ticker_hold: Label = $Dock/Row/Ticker/Face/Col/TickerHold
@onready var ticker_delta: Label = $Dock/Row/Ticker/Face/Col/TickerDelta
@onready var stock_graph = $Dock/Row/Ticker/Face/StockGraph
@onready var ticker_price_cap: Label = $Dock/Row/Ticker/Face/Col/PriceCap
@onready var ticker_hold_hint: Label = $Dock/Row/Ticker/Face/Col/HoldHint
@onready var quest_btn: TextureButton = $HUD/QuestBtn
@onready var mail_dot: Control = $HUD/QuestBtn/UnreadDot
@onready var day_end_btn: Button = $Dock/Row/Day/TradeRow/DayEnd
@onready var day_track: ColorRect = $Dock/Row/Day/DayTrack
@onready var day_track_fill: ColorRect = $Dock/Row/Day/DayTrack/Fill
@onready var bakery_eggs: Label = $BakeryEggs
@onready var bakery_upgrade: Button = $BakeryUpgrade
@onready var wolf_shop: Control = $WolfShop
@onready var wolf_buy: Button = $WolfShop/Animals/WolfBuy
@onready var wolf_sell: Button = $WolfShop/Animals/WolfSell
@onready var wolf_talk: Control = $WolfShop/Talk
@onready var wolf_hit: Button = $WolfShop/WolfHit
@onready var share_buy: Button = $Dock/Row/Day/TradeRow/ShareBuy
@onready var share_sell: Button = $Dock/Row/Day/TradeRow/ShareSell
@onready var hatch_sprite = $HatchEgg
@onready var quest_title: Label = $QuestPop/Card/Box/QuestTitle
@onready var quest_wealth: Label = $QuestPop/Card/Box/WealthCard/Row/Col/Top/QuestWealth
@onready var quest_flock: Label = $QuestPop/Card/Box/FlockCard/Row/Col/Top/QuestFlock
@onready var quest_news: Label = $QuestPop/Card/Box/QuestNews
@onready var quest_note: Label = $QuestPop/Card/Box/QuestNote
@onready var quest_stamp: TextureRect = $QuestPop/Card/Stamp
@onready var wealth_card: PanelContainer = $QuestPop/Card/Box/WealthCard
@onready var flock_card: PanelContainer = $QuestPop/Card/Box/FlockCard
@onready var wealth_fill: Panel = $QuestPop/Card/Box/WealthCard/Row/Col/Track/Fill
@onready var flock_fill: Panel = $QuestPop/Card/Box/FlockCard/Row/Col/Track/Fill
@onready var wealth_hint: Label = $QuestPop/Card/Box/WealthCard/Row/Col/Hint
@onready var flock_hint: Label = $QuestPop/Card/Box/FlockCard/Row/Col/Hint
@onready var tutorial_layer: Control = $TutorialLayer
@onready var tutorial_dim: ColorRect = $TutorialLayer/Dim
@onready var tutorial_wolf: TextureRect = $TutorialLayer/TutorWolf
@onready var tutorial_title: Label = $TutorialLayer/Card/Box/Title
@onready var tutorial_body: Label = $TutorialLayer/Card/Box/Body
@onready var tutorial_next: Button = $TutorialLayer/Card/Box/Actions/Next
@onready var tutorial_exit: Button = $TutorialLayer/Card/Box/Actions/Exit
@onready var start_menu: Control = $StartMenuLayer
@onready var menu_backdrop: TextureRect = $MenuBackdrop
@onready var start_menu_tutorial: Button = $StartMenuLayer/Card/Box/Tutorial
@onready var start_menu_direct: Button = $StartMenuLayer/Card/Box/Direct
@onready var start_menu_endless: Button = $StartMenuLayer/Card/Box/Endless
@onready var start_menu_challenge: Button = $StartMenuLayer/Card/Box/Challenge
@onready var start_menu_settings: Button = $StartMenuLayer/Card/Box/Settings
@onready var start_menu_trophies: Button = $StartMenuLayer/Card/Box/Trophies
@onready var settings_home: Button = $SettingsPop/Card/Col/HomeBtn
@onready var trophy_pop: Control = $TrophyPop
@onready var trophy_card: PanelContainer = $TrophyPop/Card

func _ready() -> void:
	Analytics.set_build(str(ProjectSettings.get_setting("application/config/version", "dev")))
	_lock_web_gestures()
	hatch_sprite.texture_filter = TEXTURE_FILTER_NEAREST
	sfx = preload("res://scripts/Sfx.gd").new()
	add_child(sfx)
	juice = preload("res://scripts/Juice.gd").new()
	add_child(juice)
	_ensure_settings_scroll()
	_connect_ui()
	UiLayout.apply(self)
	_style_top_hud_bar()
	start_menu_tutorial.pressed.connect(_start_menu_tutorial_pressed)
	start_menu_direct.pressed.connect(_start_menu_direct_pressed)
	start_menu_challenge.pressed.connect(_start_menu_challenge_pressed)
	start_menu_endless.pressed.connect(_start_menu_endless_pressed)
	start_menu_settings.pressed.connect(_start_menu_settings_pressed)
	start_menu_trophies.pressed.connect(_start_menu_trophies_pressed)
	_raise_home_buttons()
	_raise_hud_chrome()
	juice.bind(self)
	_setup_world_zoom()
	Loc.load_settings()
	_load_trophies()
	_load_unlocks()
	_had_main_save = FileAccess.file_exists(SAVE_PATH)
	_load()
	_cash_shown = float(cash())
	_stock_shown = float(held() * maxi(1, price))
	resized.connect(_rebuild_flock)
	call_deferred("_finish_boot")
	gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			sfx.unlock()
	)

func _lock_web_gestures() -> void:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return
	# selectstart / touch 拦截必须放过 INPUT：问卷 LineEdit 靠 experimentalVK 的 HTML
	# 输入框弹系统键盘；一律 preventDefault 会让手机「点了也不出输入法」。
	Engine.get_singleton("JavaScriptBridge").eval(
		"(function(){var s=document.getElementById('cluck-no-select');if(!s){s=document.createElement('style');s.id='cluck-no-select';s.textContent='html,body,#canvas{height:100%!important;height:100dvh!important;width:100%!important;max-height:100dvh!important;-webkit-user-select:none!important;user-select:none!important;-webkit-touch-callout:none!important;-webkit-tap-highlight-color:transparent;touch-action:none!important;overscroll-behavior:none}#canvas input,#canvas textarea,input,textarea{ -webkit-user-select:text!important;user-select:text!important;touch-action:auto!important;}#netlify-badge,.netlify-badge,a[href*=netlify]{display:none!important}';document.head.appendChild(s);}var isField=function(t){return t&&(t.tagName==='INPUT'||t.tagName==='TEXTAREA'||t.isContentEditable);};var stop=function(e){if(isField(e.target))return;e.preventDefault();};var pinch=function(e){if(isField(e.target))return;if(e.touches&&e.touches.length>1)e.preventDefault();};document.addEventListener('contextmenu',stop,{passive:false});document.addEventListener('selectstart',stop,{passive:false});document.addEventListener('gesturestart',stop,{passive:false});document.addEventListener('gesturechange',stop,{passive:false});document.addEventListener('gestureend',stop,{passive:false});document.addEventListener('touchmove',pinch,{passive:false});window.addEventListener('wheel',function(e){if(e.ctrlKey||e.metaKey)e.preventDefault();},{passive:false});var c=document.getElementById('canvas');if(c){c.style.touchAction='none';c.style.height='100dvh';c.addEventListener('contextmenu',stop,{passive:false});c.addEventListener('touchmove',function(e){if(isField(e.target))return;e.preventDefault();},{passive:false});}})();",
		true
	)

func _make_world(p_name: String) -> Control:
	var w := Control.new()
	w.name = p_name
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.clip_contents = false
	w.position = Vector2.ZERO
	return w

func _raise_home_buttons() -> void:
	# Keep every main-screen action above scenery and effects. Modal panels use
	# z-index 24+ and therefore still cover these buttons when they are open.
	for node in find_children("*", "BaseButton", true, false):
		var b := node as BaseButton
		if b == null:
			continue
		if night.is_ancestor_of(b) or settings_pop.is_ancestor_of(b) or quest_pop.is_ancestor_of(b):
			continue
		if start_menu.is_ancestor_of(b) or trophy_pop.is_ancestor_of(b) or tutorial_layer.is_ancestor_of(b):
			continue
		if guide_pop.is_ancestor_of(b):
			continue
		if b == wolf_hit or b == quest_btn or b == get_node_or_null("HUD/SettingsBtn"):
			continue
		b.z_index = 21

func _raise_hud_chrome() -> void:
	# Farm chrome stays under the night report. Mail / settings stay above it
	# so the envelope can still open during settlement.
	var dock := get_node("Dock") as Control
	dock.z_index = 8
	dock.z_as_relative = false
	var hud := get_node("HUD") as Control
	hud.z_index = 40
	hud.z_as_relative = false
	night.z_index = 100
	night.z_as_relative = false
	quest_btn.z_index = 120
	quest_btn.z_as_relative = false
	quest_btn.focus_mode = Control.FOCUS_NONE
	quest_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var settings_btn := get_node_or_null("HUD/SettingsBtn") as Control
	if settings_btn:
		settings_btn.z_index = 120
		settings_btn.z_as_relative = false
		settings_btn.focus_mode = Control.FOCUS_NONE
		settings_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	# Mail / settings stay above Night and both panels so one can close the other.
	quest_pop.z_index = 110
	quest_pop.z_as_relative = false
	settings_pop.z_index = 115
	settings_pop.z_as_relative = false
	trophy_pop.z_index = 125
	trophy_pop.z_as_relative = false
	tutorial_layer.z_index = 105
	tutorial_layer.z_as_relative = false
	guide_pop.z_index = 126
	guide_pop.z_as_relative = false
	if menu_backdrop:
		menu_backdrop.z_index = 90
		menu_backdrop.z_as_relative = false
	if start_menu:
		start_menu.z_index = 500
		start_menu.z_as_relative = false
	var toasts := get_node_or_null("Toasts") as Control
	if toasts:
		# Stay under StartMenuLayer (500). Menu lock hints go into MenuToasts.
		toasts.z_index = 130
		toasts.z_as_relative = false
	_sync_toast_layout()

func _setup_world_zoom() -> void:
	var back := _make_world("WorldBack")
	add_child(back)
	move_child(back, $Bg.get_index())
	for n in WORLD_BACK:
		get_node(n).reparent(back, false)
	var front := _make_world("WorldFront")
	add_child(front)
	move_child(front, $HUD.get_index() + 1)
	for n in WORLD_FRONT:
		get_node(n).reparent(front, false)
	_worlds = [back, front]
	resized.connect(_fit_worlds)
	call_deferred("_fit_worlds")
	_reset_zoom()

func _fit_worlds() -> void:
	var sz := size
	if sz.x < 8.0:
		sz = get_viewport_rect().size
	for w in _worlds:
		w.size = sz
	_reset_zoom()

func _reset_zoom() -> void:
	# 固定 1×；缩放入口已全部关掉。
	for w in _worlds:
		w.position = Vector2.ZERO
		w.scale = Vector2.ONE

func _cancel_press() -> void:
	if _manual_button != null:
		_manual_button.button_up.emit()
		_manual_button = null
	for idx in _armed_touches.keys():
		var b: BaseButton = _armed_touches[idx]
		if b != null and is_instance_valid(b):
			b.button_up.emit()
	_armed_touches.clear()
	_press_from_touch = false
	_end_all_holds()
	_sweep_hit = null

func _touch_hits_button() -> bool:
	for idx in _touch_pos.keys():
		var raw: Vector2 = _touch_pos[idx]
		var pos := get_viewport().get_canvas_transform().affine_inverse() * raw
		var btn := _hud_button_at(pos)
		if btn == null:
			btn = _button_at(pos)
		if btn != null:
			return true
	return false

func _track_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			_touch_pos[event.index] = event.position
			_touch_drag_travel[event.index] = 0.0
			_kin_scroll.stop_fling()
			_scroll_dragging = false
		else:
			if _scroll_dragging:
				_kin_scroll.release_fling()
			_scroll_dragging = false
			_touch_pos.erase(event.index)
			_touch_drag_travel.erase(event.index)
	elif event is InputEventScreenDrag:
		_touch_pos[event.index] = event.position
		_touch_drag_travel[event.index] = float(_touch_drag_travel.get(event.index, 0.0)) + absf(event.relative.y)

func _mouse_blocked() -> bool:
	return false

func _click_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouse:
		return get_global_mouse_position()
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch:
		pos = (event as InputEventScreenTouch).position
	elif event is InputEventScreenDrag:
		pos = (event as InputEventScreenDrag).position
	else:
		return Vector2.ZERO
	var canvas := get_viewport().get_canvas_transform()
	return canvas.affine_inverse() * pos

func _arm_button(btn: BaseButton) -> void:
	if btn == null:
		return
	if _manual_button == btn:
		return
	if _manual_button != null:
		_manual_button.button_up.emit()
	_manual_button = btn
	_manual_button.button_down.emit()

func _arm_touch(index: int, btn: BaseButton) -> void:
	if btn == null:
		return
	var prev: BaseButton = _armed_touches.get(index) as BaseButton
	if prev == btn:
		return
	if prev != null and is_instance_valid(prev):
		prev.button_up.emit()
	_armed_touches[index] = btn
	_press_from_touch = true
	btn.button_down.emit()

func _fire_armed(_pos: Vector2) -> void:
	if _manual_button == null:
		return
	var released := _manual_button
	released.button_up.emit()
	# 已 arm 且未被滚动取消：松手必点。不再用抬手坐标卡命中——
	# 手机一点偏就「按下字变大/高亮，抬起没功能」。
	if released.is_visible_in_tree() and not released.disabled:
		released.pressed.emit()
	_manual_button = null
	if _armed_touches.is_empty():
		_press_from_touch = false

func _fire_touch(index: int, _pos: Vector2) -> void:
	if not _armed_touches.has(index):
		return
	var released: BaseButton = _armed_touches[index]
	# Erase before button_up so other fingers still on the same button keep the hold.
	_armed_touches.erase(index)
	# 同一颗钮若也被 mouse 路径 arm 过，避免松手时再 fire 一次。
	if _manual_button == released:
		_manual_button = null
	if released != null and is_instance_valid(released):
		released.button_up.emit()
		if released.is_visible_in_tree() and not released.disabled:
			released.pressed.emit()
	if _armed_touches.is_empty() and _manual_button == null:
		_press_from_touch = false

func _hud_button_at(pos: Vector2) -> BaseButton:
	if settings_pop.visible or guide_pop.visible or quest_pop.visible or night.visible or start_menu.visible or trophy_pop.visible or _return_to_menu or (survey_pop != null and survey_pop.visible):
		return null
	for b in [quest_btn, get_node_or_null("HUD/SettingsBtn") as BaseButton]:
		if b != null and b.is_visible_in_tree() and not b.disabled and b.get_global_rect().grow(16.0).has_point(pos):
			return b
	return null

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey:
		# 静置判定的唯一输入源。本作有自动生产，不能要求每秒点击才算在玩，
		# 但也不能让挂机页面一直涨有效时长。
		Analytics.note_input()
	_track_touch(event)
	var mouse_blocked := _mouse_blocked()
	# emulate_touch_from_mouse sends ScreenTouch AND Mouse. Arm once in canvas
	# space and swallow the duplicate. Viewport pixels vs get_global_rect()
	# used to miss, steal the event, and leave Start Game dead.
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var touch_pos := _click_pos(event)
		var touch_btn := _hud_button_at(touch_pos)
		if touch_btn == null:
			touch_btn = _button_at(touch_pos)
		if touch.pressed and not touch.canceled:
			if touch_btn != null:
				_arm_touch(touch.index, touch_btn)
				get_viewport().set_input_as_handled()
		elif _armed_touches.has(touch.index):
			_fire_touch(touch.index, touch_pos)
			if _armed_touches.is_empty():
				_end_gesture()
				_sweep_hit = null
			get_viewport().set_input_as_handled()
		elif touch_btn != null:
			# Release over a button we never armed (should be rare); still swallow
			# so GUI doesn't double-fire with the emulated mouse.
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := _click_pos(event)
		if event.pressed:
			_mouse_drag_travel = 0.0
			_kin_scroll.stop_fling()
			_scroll_dragging = false
		if mouse_blocked:
			if not event.pressed:
				_cancel_press()
			get_viewport().set_input_as_handled()
		elif _press_from_touch or not _armed_touches.is_empty():
			# 触屏已接管：吞掉 mouse 回声，防止 pressed 触发两次（开关会闪一下又关）。
			get_viewport().set_input_as_handled()
			if not event.pressed:
				if _manual_button != null and _armed_touches.is_empty():
					_fire_armed(mouse_pos)
				_end_gesture()
				_sweep_hit = null
		elif event.pressed:
			var hit := _button_at(mouse_pos)
			if hit != null:
				_arm_button(hit)
				get_viewport().set_input_as_handled()
		else:
			if _scroll_dragging and _touch_pos.is_empty():
				_kin_scroll.release_fling()
			_scroll_dragging = false
			if _manual_button != null:
				_fire_armed(mouse_pos)
				get_viewport().set_input_as_handled()
			_end_gesture()
			_sweep_hit = null
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if mouse_blocked:
			get_viewport().set_input_as_handled()
		elif not _touch_pos.is_empty():
			# Touch owns panel scroll via ScreenDrag; skip mouse echo so it doesn't 2×.
			pass
		elif _try_mobile_scroll(event):
			get_viewport().set_input_as_handled()
		else:
			_sweep_at(_click_pos(event))
	# Phone web: ScrollContainer often ignores ScreenDrag; drive all modal lists here.
	if event is InputEventScreenDrag and _try_mobile_scroll(event):
		get_viewport().set_input_as_handled()
		return
	# 画面缩放已关闭：滚轮 / 捏合 / 触控板放大不再处理。

func _button_at(pos: Vector2) -> BaseButton:
	# 问卷是模态的，排在最前。走这条链路才能拿到既有的「合成 pressed + 吞
	# ScreenTouch」处理，手机上才不会一点两下。
	if survey_pop != null and survey_pop.visible:
		return _control_button_at(survey_pop, pos)
	if start_menu.visible:
		return _control_button_at(start_menu, pos)
	if trophy_pop.visible:
		return _control_button_at(trophy_pop, pos)
	if guide_pop.visible:
		return _control_button_at(guide_pop, pos)
	if settings_pop.visible:
		return _control_button_at(settings_pop, pos)
	if quest_pop.visible:
		return _control_button_at(quest_pop, pos)
	if night.visible:
		# Mail and settings are above the report visually; route their clicks first.
		for chrome in [quest_btn, get_node("HUD/SettingsBtn")]:
			if chrome.is_visible_in_tree() and not chrome.disabled and chrome.get_global_rect().has_point(pos):
				return chrome
		return _control_button_at(night, pos)
	# Tutorial controls must win hit-testing over the game controls beneath them.
	# Without this priority, the bottom tutorial card can overlap the day dock
	# and clicks are routed to the wrong control (or swallowed by the card).
	if tutorial_layer.visible:
		var tutorial_btn := _control_button_at(tutorial_layer, pos)
		if tutorial_btn != null:
			return tutorial_btn
	var hud_btn := _hud_button_at(pos)
	if hud_btn != null:
		return hud_btn
	return _control_button_at(self, pos)

func _control_button_at(scope: Node, pos: Vector2) -> BaseButton:
	var buttons := scope.find_children("*", "BaseButton", true, false)
	for i in range(buttons.size() - 1, -1, -1):
		var b := buttons[i] as BaseButton
		if b == null or not b.is_visible_in_tree() or b.disabled:
			continue
		if b.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		var box := b.get_global_rect()
		if box.size.x < 8.0 or box.size.y < 8.0:
			continue
		# 手机点按略偏也要命中；过小会漏 arm，GUI 与合成 pressed 叠成双击。
		if box.grow(14.0).has_point(pos):
			return b
	return null

func _finish_boot() -> void:
	_ensure_dawn_snap()
	_apply_locale()
	_booted = true
	# Resume an interrupted first-time lesson even though its safe checkpoint
	# created a normal-game save. A player who explicitly exits is not forced
	# back in; they can replay it from Settings.
	var tutorial_status := _tutorial_status()
	# 首个入口真实可操作的时刻。在 _show_main_menu / _start_tutorial 之前发，
	# 事件自带的 ms_since_open 就是「从页面导航开始到能开始操作」的耗时。
	Analytics.set_lang(Loc.lang)
	Analytics.log_event("game_ready", {
		"tutorial_resumed": tutorial_status == "in_progress",
		"has_save": _had_main_save,
		"normal_cleared": _normal_cleared,
		"challenge_cleared": _challenge_cleared,
	}, true)
	if tutorial_status == "in_progress":
		_restore_settlement()
		call_deferred("_start_tutorial")
	else:
		_show_main_menu()

func _menu_holds_clock() -> bool:
	if survey_pop != null and survey_pop.visible:
		return true
	return start_menu.visible or _return_to_menu or settings_pop.visible

func _show_main_menu() -> void:
	_return_to_menu = true
	_tutorial_clear_highlights()
	tutorial_mode = false
	tutorial_layer.visible = false
	show_settings = false
	show_quest = false
	settings_pop.visible = false
	guide_pop.visible = false
	quest_pop.visible = false
	if trophy_pop:
		trophy_pop.visible = false
	wolf_talk.visible = false
	night.visible = false
	card.visible = false
	start_menu.visible = true
	UiLayout._menu(self)
	_sync_menu_locks()
	_set_menu_idle(true)
	# 主菜单既是模式入口曝光，也是「有效游玩」的边界：先把残区间结掉。
	Analytics.flush_interval("menu")
	Analytics.set_phase(Analytics.PHASE_MENU)
	Analytics.set_mode("menu")
	Analytics.set_day(0)
	Analytics.log_event("menu_view", {
		"challenge_unlocked": _normal_cleared,
		"endless_unlocked": _challenge_cleared,
		"has_save": FileAccess.file_exists(SAVE_PATH),
	})
	# 菜单先摆好再弹，否则问卷会盖在还没布好的界面上。
	call_deferred("_maybe_open_pulse")

func _restore_menu_if_needed() -> void:
	if not _return_to_menu or tutorial_mode:
		return
	if settings_pop.visible or guide_pop.visible or trophy_pop.visible:
		return
	start_menu.visible = true
	UiLayout._menu(self)
	_set_menu_idle(true)

func _hud_chrome_blocked() -> bool:
	if start_menu.visible:
		return true
	if settings_pop.visible or quest_pop.visible or guide_pop.visible:
		return true
	if trophy_pop != null and trophy_pop.visible:
		return true
	return false

func _sync_hud_chrome() -> void:
	var chrome_on := not _hud_chrome_blocked()
	if quest_btn:
		quest_btn.visible = chrome_on
	var settings_btn := get_node_or_null("HUD/SettingsBtn") as Control
	if settings_btn:
		settings_btn.visible = chrome_on

func _set_menu_idle(on: bool) -> void:
	if menu_backdrop:
		menu_backdrop.visible = on
	_sync_hud_chrome()
	_sync_toast_layout()
	if on:
		sfx.set_flock(0, 0)
		sfx.set_night(false)
		night.visible = false
		card.visible = false
		_set_settle_chrome(true)
	for w in _worlds:
		if w == null:
			continue
		w.visible = not on
		w.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT
	if flock_layer:
		flock_layer.visible = not on
		flock_layer.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT
	if not on and not settling:
		_set_settle_chrome(false)

func _start_menu_tutorial_pressed() -> void:
	Analytics.log_event("menu_click", {"item": "tutorial"})
	_return_to_menu = false
	start_menu.visible = false
	_set_menu_idle(false)
	_start_tutorial()

func _start_menu_direct_pressed() -> void:
	Analytics.log_event("menu_click", {"item": "normal"})
	_enter_play("normal")

func _start_menu_challenge_pressed() -> void:
	if not _normal_cleared:
		# 想玩但被解锁条件挡住，和成功进入是两件事，分开记。
		Analytics.log_event("menu_click_locked", {"item": "challenge", "lock": "normal_not_cleared"})
		_toast(Loc.t("toast_lock_challenge"))
		return
	Analytics.log_event("menu_click", {"item": "challenge"})
	_enter_play("challenge")

func _start_menu_endless_pressed() -> void:
	if not _challenge_cleared:
		Analytics.log_event("menu_click_locked", {"item": "endless", "lock": "challenge_not_cleared"})
		_toast(Loc.t("toast_lock_endless"))
		return
	Analytics.log_event("menu_click", {"item": "endless"})
	_enter_play("endless")

func _start_menu_settings_pressed() -> void:
	Analytics.log_event("menu_click", {"item": "settings"})
	_return_to_menu = true
	start_menu.visible = false
	_open_settings()

func _start_menu_trophies_pressed() -> void:
	Analytics.log_event("menu_click", {"item": "trophies"})
	_return_to_menu = true
	start_menu.visible = false
	_open_trophies()

func _enter_play(kind: String) -> void:
	_return_to_menu = false
	start_menu.visible = false
	trophy_pop.visible = false
	show_settings = false
	settings_pop.visible = false
	_set_menu_idle(false)
	if FileAccess.file_exists(SAVE_PATH):
		_load()
	var want_challenge := kind == "challenge"
	var want_endless := kind == "endless"
	var can_continue := (
		FileAccess.file_exists(SAVE_PATH)
		and game_result == ""
		and challenge_mode == want_challenge
		and endless_mode == want_endless
	)
	if can_continue:
		_begin_run(kind, true)
		_apply_locale()
		_rebuild_flock()
		_restore_settlement()
		_refresh()
		return
	_reset_new_game_data()
	tutorial_mode = false
	if want_challenge:
		_apply_challenge_seed()
	elif want_endless:
		endless_mode = true
	left_ms = _day_len_ms()
	_write_tutorial_status("dismissed")
	night.visible = false
	card.visible = false
	_set_settle_chrome(false)
	sfx.set_night(false)
	_capture_dawn()
	_begin_run(kind, false)
	_apply_locale()
	_rebuild_flock()
	_refresh()
	_save()

## 一局开始（新开或续档）的统计口径。玩法状态在调用前已经就位。
func _begin_run(kind: String, continued: bool, forced_reason := "") -> void:
	if continued:
		# 续档保留原局标识。存档里没有（旧存档、或统计上线前存的）才补一个，
		# 这种局在报表里用 run_resumed_legacy 标出来，不要当成新局。
		if run_id == "":
			run_id = Analytics.new_id()
			attempt_id = Analytics.new_id()
			attempt_index = 0
	else:
		run_id = Analytics.new_id()
		attempt_id = Analytics.new_id()
		attempt_index = 0
	var entry_reason := forced_reason
	if entry_reason == "":
		entry_reason = _take_entry_reason("menu_continue" if continued else "menu_new")
	else:
		_continuation_decision = ""
	Analytics.set_mode(kind)
	Analytics.set_run(run_id, attempt_id, attempt_index)
	Analytics.set_day(day)
	Analytics.set_phase(Analytics.PHASE_SETTLE if settling else Analytics.PHASE_PLAY)
	Analytics.mark_first_play()
	Analytics.log_event("play_start", {"entry_reason": entry_reason})
	Analytics.log_event("run_start", {
		"continued": continued,
		"entry_reason": entry_reason,
		"decision_id": _continuation_decision,
		"previous_run_id": _decision_prev_run,
		"start_day": day,
	})
	if not settling:
		_log_day_start(entry_reason)

## 取一次待兑现的终局决策。取不到就用默认值，取到后不再重复归因。
func _take_entry_reason(fallback: String) -> String:
	_continuation_decision = ""
	if _decision_id == "":
		return fallback
	# 玩家在终局点了「重新开局」后可能在菜单里逛很久。超过十分钟就不再算
	# 这次终局带来的继续行为，避免把无关的一局挂到上一次终局的漏斗里。
	if Time.get_ticks_msec() - _decision_ms > 600000:
		_decision_id = ""
		_decision_prev_run = ""
		_decision_choice = ""
		return fallback
	var reason := _decision_choice
	_continuation_decision = _decision_id
	Analytics.set_source_decision(_decision_id)
	_decision_id = ""
	_decision_choice = ""
	_decision_ms = 0
	return reason

func _log_day_start(entry_reason: String) -> void:
	Analytics.set_day(day)
	Analytics.reset_day_counters()
	Analytics.log_event("day_start", {
		"entry_reason": entry_reason,
		"wealth": total(),
		"birds": birds(),
		"coins": cash(),
		"bakery_level": bakery_level,
		"price": price,
	})

func _apply_challenge_seed() -> void:
	challenge_mode = true
	endless_mode = false
	day = 9
	hens = 12
	bakery_level = 3
	coins = 1800
	price = 220
	history = [180, 200, 210, 220]
	wealth_log = [1800]
	_cash_shown = 1800.0
	ready_eggs = 0
	pending_eggs = maxi(0, hens)
	_roll_egg_pre_dusk_target()

func _load_unlocks() -> void:
	_normal_cleared = false
	_challenge_cleared = false
	if not FileAccess.file_exists(UNLOCK_PATH):
		return
	var f := FileAccess.open(UNLOCK_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	_normal_cleared = bool(d.get("normalCleared", false))
	_challenge_cleared = bool(d.get("challengeCleared", false))

func _save_unlocks() -> void:
	var f := FileAccess.open(UNLOCK_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"normalCleared": _normal_cleared,
			"challengeCleared": _challenge_cleared,
		}))

func _unlock_normal() -> void:
	if _normal_cleared:
		return
	_normal_cleared = true
	_save_unlocks()

func _unlock_challenge_clear() -> void:
	if _challenge_cleared:
		return
	_challenge_cleared = true
	_save_unlocks()

func _load_trophies() -> void:
	_trophies.clear()
	if not FileAccess.file_exists(TROPHY_PATH):
		return
	var f := FileAccess.open(TROPHY_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	for k in d.keys():
		if bool(d[k]):
			_trophies[str(k)] = true

func _save_trophies() -> void:
	var f := FileAccess.open(TROPHY_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_trophies))

func _grant_trophy(id: String) -> void:
	if _trophies.get(id, false):
		return
	var known := false
	var title_key := "trophy_" + id
	for def in _trophy_catalog():
		if str(def.id) == id:
			known = true
			title_key = str(def.title)
			break
	if not known:
		return
	_trophies[id] = true
	_save_trophies()
	if tutorial_mode or _menu_holds_clock():
		return
	_toast(Loc.t("toast_trophy", [Loc.t(title_key)]))

func _grant_challenge_wealth_trophies(closing: int) -> void:
	var top_title := ""
	var newly := false
	for def in WEALTH_TROPHY_DEFS:
		if closing < int(def.min):
			continue
		var id := str(def.id)
		if top_title == "":
			top_title = str(def.title)
		if _trophies.get(id, false):
			continue
		_trophies[id] = true
		newly = true
	if newly:
		_save_trophies()
		if not tutorial_mode:
			_toast(Loc.t("toast_trophy", [Loc.t(top_title)]))

func _trophy_catalog() -> Array:
	var out: Array = []
	for def in WEALTH_TROPHY_DEFS:
		var row: Dictionary = def.duplicate()
		row["icon"] = "res://icons/coin.png"
		out.append(row)
	out.append_array(TROPHY_DEFS.duplicate())
	for x in RANKS:
		var lv := int(x.lv)
		out.append({
			"id": "rank_%d" % lv,
			"icon": "res://icons/coin.png",
			"title": "rank_%d_title" % lv,
			"desc": "trophy_rank_day8_desc" if lv <= CAMPAIGN_RANK_CAP else "trophy_rank_endless_desc",
			"min": int(x.min),
		})
	return out

func _grant_day8_ranks(closing: int) -> void:
	for x in RANKS:
		if int(x.lv) > CAMPAIGN_RANK_CAP:
			continue
		if closing >= int(x.min):
			_grant_trophy("rank_%d" % int(x.lv))

func _check_closing_trophies(closing: int) -> void:
	if tutorial_mode:
		return
	# The closing price can cross stock/wealth thresholds without a player action
	# calling _refresh(). Check before displaying any daily or terminal report.
	_check_trophies()
	if day == 8 and not challenge_mode and not endless_mode:
		# These trophies describe finishing day 8 and its closing wealth, not
		# passing both campaign goals. A flock shortfall must not discard them.
		_grant_trophy("day8")
		_grant_day8_ranks(closing)
	if game_result == "won" and challenge_mode and not endless_mode:
		_grant_challenge_wealth_trophies(closing)

func _check_trophies() -> void:
	if tutorial_mode:
		return
	if birds() >= FLOCK_GOAL:
		_grant_trophy("flock")
	if birds() >= 100:
		_grant_trophy("chicken_king")
	# 200, not 1000: buy_chick repeats every 0.11s while held, so 1000 birds was
	# 110 seconds of pure button-holding -- and 1000 nodes sinks the framerate.
	if birds() >= 200:
		_grant_trophy("chicken_emperor")
	var stock_gain := stock_profit()
	if stock_gain >= 2000:
		_grant_trophy("retail_not_chives")
	if stock_gain >= 3000:
		_grant_trophy("stock_god")
	if not endless_mode:
		return
	# 只有 _wake() 那一瞬间发 endless7，中途读档和老存档刷新都补不回来，
	# 所以这里按当前天数补一次；_grant_trophy 自带去重。
	if day >= 7:
		_grant_trophy("endless7")
	for x in RANKS:
		if int(x.lv) <= CAMPAIGN_RANK_CAP:
			continue
		if total() >= int(x.min):
			_grant_trophy("rank_%d" % int(x.lv))

func _open_trophies() -> void:
	_close_quest()
	show_settings = false
	settings_pop.visible = false
	trophy_pop.visible = true
	_sync_tutorial_layer()
	_fill_trophy_list()
	juice.pop_in(trophy_card)
	_pin_close_x($TrophyPop/CloseBtn, trophy_card)
	_sync_hud_chrome()

func _close_trophies() -> void:
	trophy_pop.visible = false
	_sync_hud_chrome()
	_sync_tutorial_layer()
	if not _return_to_menu:
		_refresh_thoughts()
	_restore_menu_if_needed()

func _on_trophy_dim_input(event: InputEvent) -> void:
	if not trophy_pop.visible:
		return
	var tap := false
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap = true
		pos = event.global_position
	elif event is InputEventScreenTouch and event.pressed:
		tap = true
		pos = event.position
	if not tap:
		return
	if _control_button_at(trophy_pop, pos) != null:
		return
	if trophy_card.get_global_rect().has_point(pos):
		return
	_close_trophies()

func _ensure_settings_scroll() -> void:
	# 设置项多（含反馈入口），手机上卡片高度不够；包进 Scroll 后路径仍用 _settings_col()。
	if settings_card == null:
		return
	if settings_card.get_node_or_null("Scroll") != null:
		return
	var col := settings_card.get_node_or_null("Col") as VBoxContainer
	if col == null:
		return
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var idx := col.get_index()
	settings_card.remove_child(col)
	settings_card.add_child(scroll)
	settings_card.move_child(scroll, idx)
	scroll.add_child(col)
	MobileScroll.prepare(scroll, col)

func _settings_col() -> VBoxContainer:
	var scroll := settings_card.get_node_or_null("Scroll") as ScrollContainer
	if scroll != null:
		return scroll.get_node("Col") as VBoxContainer
	return settings_card.get_node("Col") as VBoxContainer

func _settings_node(path: String) -> Node:
	return _settings_col().get_node(path)

func _settings_node_or_null(path: String) -> Node:
	return _settings_col().get_node_or_null(path)

func _modal_scrolls() -> Array[ScrollContainer]:
	var out: Array[ScrollContainer] = []
	if trophy_pop != null and trophy_pop.visible:
		var trophy_list := get_node_or_null("TrophyPop/Card/Col/List") as ScrollContainer
		if trophy_list != null:
			out.append(trophy_list)
	if settings_pop != null and settings_pop.visible:
		var settings_scroll := get_node_or_null("SettingsPop/Card/Scroll") as ScrollContainer
		if settings_scroll != null:
			out.append(settings_scroll)
	if survey_pop != null and survey_pop.visible and survey_pop.has_method("scroll_box"):
		var survey_scroll := survey_pop.call("scroll_box") as ScrollContainer
		if survey_scroll != null:
			out.append(survey_scroll)
	return out

func _on_sfx_toggle_pressed() -> void:
	var now := Time.get_ticks_msec()
	if now - _audio_toggle_ms < 280:
		return
	_audio_toggle_ms = now
	sfx.set_sfx(not sfx.sfx_on)
	sfx.egg()
	_apply_settings_labels()

func _on_amb_toggle_pressed() -> void:
	var now := Time.get_ticks_msec()
	if now - _audio_toggle_ms < 280:
		return
	_audio_toggle_ms = now
	sfx.set_amb(not sfx.amb_on)
	_apply_settings_labels()

func _armed_is_choice_button() -> bool:
	# 问卷选项 / 设置里的开关：手指落在上面时不要改成列表滚动，否则一点就取消。
	if _manual_button != null and is_instance_valid(_manual_button) and _is_choice_button(_manual_button):
		return true
	for v in _armed_touches.values():
		var b := v as BaseButton
		if b != null and is_instance_valid(b) and _is_choice_button(b):
			return true
	return false

func _is_choice_button(b: BaseButton) -> bool:
	if survey_pop != null and survey_pop.visible and survey_pop.is_ancestor_of(b):
		return true
	if settings_pop != null and settings_pop.visible and settings_pop.is_ancestor_of(b):
		return true
	return false

func _try_mobile_scroll(event: InputEvent) -> bool:
	# 正在打字时不要拖问卷，否则焦点和输入法会被打断。
	var focused := get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:
		return false
	# 选项/音量钮按下期间：点按优先，绝不抢成滚动。
	if _armed_is_choice_button():
		return false
	var pos := _click_pos(event)
	var armed := _manual_button != null or not _armed_touches.is_empty()
	var travel := 0.0
	if event is InputEventScreenDrag:
		travel = float(_touch_drag_travel.get((event as InputEventScreenDrag).index, 0.0))
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_mouse_drag_travel += absf(motion.relative.y)
			travel = _mouse_drag_travel
	# 其它按钮仍保留容差，避免误滑取消。
	if armed and travel < MobileScroll.DRAG_CANCEL_PX:
		if absf(MobileScroll.drag_delta(event)) < 0.01:
			return false
		for scroll in _modal_scrolls():
			if scroll.get_global_rect().has_point(pos):
				return true
		return false
	for scroll in _modal_scrolls():
		var moved := _kin_scroll.try_drag(scroll, event, pos)
		if moved > 0.0:
			_scroll_dragging = true
			if armed:
				_cancel_press()
			return true
	return false

func _fill_trophy_list() -> void:
	var scroll := get_node("TrophyPop/Card/Col/List") as ScrollContainer
	var rows := scroll.get_node("Rows") as VBoxContainer
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	MobileScroll.prepare(scroll, rows)
	for child in rows.get_children():
		rows.remove_child(child)
		child.free()
	for def in _trophy_catalog():
		rows.add_child(_make_trophy_row(def))
	scroll.scroll_vertical = 0

func _make_trophy_row(def: Dictionary) -> PanelContainer:
	var unlocked: bool = _trophies.get(str(def.id), false)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color("bd9a6655")
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := load(str(def.icon))
	if tex is Texture2D:
		icon.texture = tex
	icon.modulate = Color.WHITE if unlocked else Color(1, 1, 1, 0.35)
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = Loc.t(str(def.title))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("4b2d16") if unlocked else Color("8d7a61"))
	col.add_child(title)
	var desc := Label.new()
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unlocked:
		if def.has("min"):
			desc.text = Loc.t(str(def.desc), [int(def.min)])
		else:
			desc.text = Loc.t(str(def.desc))
	else:
		desc.text = Loc.t("trophy_locked")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 21)
	desc.add_theme_color_override("font_color", Color("6a5340") if unlocked else Color("a09078"))
	col.add_child(desc)
	return panel

func _tutorial_status() -> String:
	if not FileAccess.file_exists(TUTORIAL_PATH):
		return ""
	var f := FileAccess.open(TUTORIAL_PATH, FileAccess.READ)
	if f == null:
		return ""
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		var status := str(parsed.get("status", ""))
		if status != "":
			return status
		# Compatibility with the older marker format.
		if bool(parsed.get("completed", false)):
			return "completed"
		if bool(parsed.get("started", false)):
			return "in_progress"
	return ""

func _write_tutorial_status(status: String) -> void:
	var f := FileAccess.open(TUTORIAL_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"status": status}))

func _process(delta: float) -> void:
	if not _booted:
		return
	_kin_scroll.tick(delta)
	if OS.is_debug_build() and FileAccess.file_exists("user://debug_skip_day8"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://debug_skip_day8"))
		_debug_skip_to_campaign_clear()
		return
	_sync_bird_occluders()
	if not _holds.is_empty():
		var stop: Array = []
		for btn in _holds.keys():
			var h: Dictionary = _holds[btn]
			h["wait"] = float(h["wait"]) - delta
			if float(h["wait"]) > 0.0:
				continue
			h["rep"] = float(h["rep"]) - delta
			if float(h["rep"]) > 0.0:
				continue
			var b := btn as BaseButton
			h["rep"] = _hold_repeat_s_for(b)
			var fn: Callable = h["fn"]
			if not fn.is_valid() or not fn.call(true):
				stop.append(btn)
		for btn in stop:
			_end_hold(btn as BaseButton)
	_tick_nums(delta)
	if settling or game_result != "" or fanfare or _menu_holds_clock():
		return
	if left_ms > 0.0:
		# The one-day primer pauses the clock so the player can learn
		# without a dusk cutoff cutting the lesson short.
		if not tutorial_mode:
			left_ms = maxf(0.0, left_ms - delta * 1000.0)
		_tick_day_ui()
		if not tutorial_mode and left_ms <= _dusk_warn_ms() and not panic_told and leftover_eggs() > 0:
			panic_told = true
			_toast(Loc.t("toast_dusk"))
			sfx.warn()
			_flush_dusk_eggs()
	elif not settling:
		_next_day()
		return
	_advance_baking(delta)
	if baking > 0:
		_sync_bake_bar()
	_tick_egg_drips()
	_save_throttled(delta)

func _advance_baking(delta: float) -> void:
	var remaining := delta
	while remaining > 0.000001:
		if baking > 0 and baking < 100:
			var used := minf(remaining, maxf(0.0, _bake_step_time() - _bake_acc))
			_bake_acc += used
			remaining -= used
			if _bake_acc + 0.000001 < _bake_step_time():
				break
			_bake_acc = 0.0
			baking = mini(baking + 5, 100)
			if baking >= 100:
				cakes += 1
				# 烤炉是自动推进的，记数量但不算主动操作。
				Analytics.bump("bake_complete_count")
				sfx.bake_done()
				juice.punch(cake_btn, 1.22)
				if tutorial_mode:
					_tutorial_refresh_prompt()
			_refresh_thoughts()
		elif baking >= 100:
			var used := minf(remaining, maxf(0.0, _bake_hold_s() - _bake_hold))
			_bake_hold += used
			remaining -= used
			if _bake_hold + 0.000001 < _bake_hold_s():
				break
			_bake_hold = 0.0
			baking = 0
			if _can_ignite_bake():
				_ignite_bake()
			_refresh()
			_save()
		elif _can_ignite_bake():
			var used := minf(remaining, maxf(0.0, BAKE_IGNITE_S - _egg_acc))
			_egg_acc += used
			remaining -= used
			if _egg_acc + 0.000001 < BAKE_IGNITE_S:
				break
			_ignite_bake()
			_refresh()
		else:
			_egg_acc = 0.0
			break

var _save_acc := 0.0
func _save_throttled(delta: float) -> void:
	_save_acc += delta
	if _save_acc > 1.0:
		_save_acc = 0.0
		_save()

func _sync_menu_locks() -> void:
	if start_menu_challenge:
		start_menu_challenge.modulate.a = 1.0 if _normal_cleared else 0.42
	if start_menu_endless:
		start_menu_endless.modulate.a = 1.0 if _challenge_cleared else 0.42

func leftover_eggs() -> int:
	return eggs + ready_eggs + pending_eggs

func _egg_generated() -> int:
	return maxi(0, hens) - pending_eggs

func _roll_egg_pre_dusk_target() -> void:
	var hen_n := maxi(0, hens)
	if hen_n <= 0:
		_egg_pre_dusk_target = 0
		_egg_drip_at.clear()
		return
	var lo := maxi(1, int(round(float(hen_n) * _egg_ratio_lo())))
	var hi := clampi(int(round(float(hen_n) * _egg_ratio_hi())), lo, hen_n)
	_egg_pre_dusk_target = randi_range(lo, hi)
	_schedule_egg_drips()

func _schedule_egg_drips() -> void:
	_egg_drip_at.clear()
	if tutorial_mode or hens <= 0 or _egg_pre_dusk_target <= 0:
		return
	var need := _egg_pre_dusk_target - _egg_generated()
	if need <= 0:
		return
	var elapsed := _day_elapsed_s()
	var window := _egg_drip_window_s()
	if _egg_generated() <= 0:
		var first_at := randf_range(EGG_FIRST_MIN_S, EGG_FIRST_MAX_S)
		if first_at < elapsed:
			first_at = elapsed
		_egg_drip_at.append(first_at)
		need -= 1
	for _i in need:
		var t := elapsed
		if window > elapsed:
			t = randf_range(elapsed, window)
		_egg_drip_at.append(t)
	_egg_drip_at.sort()

func _restore_egg_drip_at(d: Dictionary) -> void:
	_egg_drip_at.clear()
	var raw = d.get("eggDripAt", [])
	if typeof(raw) != TYPE_ARRAY:
		return
	for v in raw:
		_egg_drip_at.append(float(v))

func _day_elapsed_s() -> float:
	return maxf(0.0, (_day_len_ms() - left_ms) / 1000.0)

func _egg_drip_window_s() -> float:
	return maxf(0.0, (_day_len_ms() - _dusk_warn_ms()) / 1000.0)

func _tick_egg_drips() -> void:
	if not _can_drip_egg():
		return
	if _egg_drip_at.is_empty():
		_schedule_egg_drips()
	if _egg_drip_at.is_empty():
		return
	var elapsed := _day_elapsed_s()
	var popped := 0
	while not _egg_drip_at.is_empty() and pending_eggs > 0 and elapsed + 0.0001 >= _egg_drip_at[0]:
		_egg_drip_at.remove_at(0)
		pending_eggs -= 1
		ready_eggs += 1
		popped += 1
		if not _can_drip_egg():
			break
	if popped > 0:
		sfx.egg_ready()
		juice.punch(egg_btn, 1.12)
		_refresh_thoughts()

func _ensure_egg_pre_dusk_target() -> void:
	if hens > 0 and _egg_pre_dusk_target <= 0:
		_roll_egg_pre_dusk_target()

func _can_drip_egg() -> bool:
	if tutorial_mode or pending_eggs <= 0 or left_ms <= _dusk_warn_ms():
		return false
	_ensure_egg_pre_dusk_target()
	return _egg_generated() < _egg_pre_dusk_target

func _flush_dusk_eggs() -> void:
	_egg_drip_at.clear()
	if pending_eggs <= 0:
		return
	var hen_n := maxi(1, hens)
	var generated := hen_n - pending_eggs
	var floor_n := maxi(1, ceili(float(hen_n) * _egg_ratio_lo()))
	if generated < floor_n:
		var catchup := mini(pending_eggs, floor_n - generated)
		ready_eggs += catchup
		pending_eggs -= catchup
	if pending_eggs > 0:
		ready_eggs += pending_eggs
		pending_eggs = 0
	juice.punch(egg_btn, 1.2)
	_refresh_thoughts()

func _can_ignite_bake() -> bool:
	return baking == 0 and eggs >= 2 and left_ms > 0 and not (tutorial_mode and tutorial_step < 3)

func _ignite_bake() -> void:
	eggs -= 2
	Analytics.bump("bake_start_count")
	baking = 5
	_bake_hold = 0.0
	_bake_acc = 0.0
	_egg_acc = 0.0
	sfx.bake_start()

func cash() -> int:
	return maxi(0, coins)

func _in_challenge() -> bool:
	return challenge_mode and not tutorial_mode

func _challenge_wave() -> int:
	if not _in_challenge():
		return 0
	return clampi(int((day - 9) / 4.0), 0, 2)

func _day_len_ms() -> float:
	if tutorial_mode:
		return TUTORIAL_DAY_MS
	if not _in_challenge():
		return DAY_MS
	return [20000.0, 18000.0, 16000.0][_challenge_wave()]

func _dusk_warn_ms() -> float:
	if not _in_challenge():
		return DUSK_WARN_MS
	return [5000.0, 6000.0, 7000.0][_challenge_wave()]

func _chick_cost() -> int:
	if not _in_challenge():
		return CHICK_COST
	return [50, 60, 70][_challenge_wave()]

func _egg_ratio_lo() -> float:
	if not _in_challenge():
		return EGG_PRE_DUSK_FLOOR
	return [0.65, 0.70, 0.75][_challenge_wave()]

func _egg_ratio_hi() -> float:
	if not _in_challenge():
		return EGG_PRE_DUSK_RATIO
	return [0.75, 0.80, 0.85][_challenge_wave()]

func _bakery_max() -> int:
	return BAKERY_MAX_LEVEL if (_in_challenge() or endless_mode) else CAMPAIGN_BAKERY_MAX

func _bake_hold_s() -> float:
	if bakery_level >= 6:
		return BAKE_HOLD_LV6_S
	if bakery_level >= 5:
		return BAKE_HOLD_LV5_S
	return BAKE_HOLD_S

func _gate_retry_left(d: int) -> bool:
	return not bool(_gate_retry_used.get(str(d), false))

func _spend_gate_retry(d: int) -> void:
	_gate_retry_used[str(d)] = true

func _challenge_gate_at(d: int) -> Dictionary:
	for g in CHALLENGE_GATES:
		if int(g.day) == d:
			return g
	return {}

func _next_challenge_gate() -> Dictionary:
	for g in CHALLENGE_GATES:
		if day <= int(g.day):
			return g
	return CHALLENGE_GATES[CHALLENGE_GATES.size() - 1]

func _bake_step_time() -> float:
	return BAKE_STEP_BASE * float(BAKERY_SPEED_MULTIPLIERS[clampi(bakery_level, 1, BAKERY_MAX_LEVEL) - 1])

func _bakery_upgrade_cost() -> int:
	if bakery_level >= _bakery_max():
		return 0
	return int(BAKERY_UPGRADE_COSTS[bakery_level])

func held() -> int:
	return maxi(0, shares)

func stock_profit() -> int:
	return stock_sold + held() * maxi(1, price) - stock_spent

func beat_percent(wealth: int) -> float:
	if wealth >= 5000:
		return 99.0
	if wealth <= 500:
		return 0.1
	var anchors := [
		[500, 0.1],
		[1500, 10.0],
		[2500, 30.0],
		[3100, 45.0],
		[3500, 50.0],
		[5000, 99.0],
	]
	var prev_w := 500
	var prev_p := 0.1
	for a in anchors:
		var w := int(a[0])
		var p := float(a[1])
		if wealth <= w:
			var span := maxf(1.0, float(w - prev_w))
			return prev_p + (p - prev_p) * float(wealth - prev_w) / span
		prev_w = w
		prev_p = p
	return 99.0

func beat_pct_label(pct: float) -> String:
	if pct < 1.0:
		return "%.1f" % pct
	return str(int(round(pct)))

func beat_tail_key(pct: float) -> String:
	if pct < 1.0:
		return "beat_tail_0"
	if pct < 15.0:
		return "beat_tail_1"
	if pct < 35.0:
		return "beat_tail_2"
	if pct < 50.0:
		return "beat_tail_3"
	if pct < 70.0:
		return "beat_tail_4"
	if pct < 90.0:
		return "beat_tail_5"
	return "beat_tail_6"

func beat_line(wealth: int, finale: bool) -> String:
	var pct := beat_percent(wealth)
	return Loc.t("beat_finale" if finale else "beat_daily", [beat_pct_label(pct), Loc.t(beat_tail_key(pct))])

func _campaign_beat_text(wealth: int, finale: bool) -> String:
	if tutorial_mode or endless_mode or challenge_mode:
		return ""
	if int(summary.get("fromDay", day)) > 8:
		return ""
	return beat_line(wealth, finale)

func total() -> int:
	return cash() + held() * maxi(1, price)

func birds() -> int:
	return hens + young_chicks + hatched + hatching

func quest_complete() -> bool:
	return total() >= WEALTH_GOAL and birds() >= FLOCK_GOAL

func blocked() -> bool:
	return game_result != "" or settling or left_ms <= 0.0

func _label(text: String, font_size := 29, color := Color("4e3d2c")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("3a2e22aa"))
	l.add_theme_constant_override("outline_size", 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _bind_hold(b: BaseButton, cb: Callable) -> void:
	b.button_down.connect(func(): _start_hold(cb, b))
	b.button_up.connect(func():
		if _button_press_still_active(b):
			return
		_end_hold(b)
	)

func _bind_resource_hold(b: Button, cb: Callable) -> void:
	b.button_down.connect(func():
		# _input performs a larger, reliable hit test first. Only fall back to
		# the native Button signal when that path did not already activate it.
		if not _holds.has(b):
			_start_hold(cb, b)
	)
	b.button_up.connect(func():
		if _button_press_still_active(b):
			return
		_end_hold(b)
		if _sweep_hit == b:
			_sweep_hit = null
	)

func _resource_targets() -> Array:
	return [
		[egg_btn, Callable(self, "collect_egg")],
		[cake_btn, Callable(self, "sell_cake")],
		[hatch_btn, Callable(self, "start_hatch")],
		[chick_btn, Callable(self, "collect_chick")],
	]

func _sweep_at(pos: Vector2) -> void:
	if blocked() or settings_pop.visible or night.visible:
		return
	var hit: Button = null
	var cb: Callable
	for pair in _resource_targets():
		var b: Button = pair[0]
		if b == null or not b.visible or b.disabled:
			continue
		if b.get_global_rect().grow(14.0).has_point(pos):
			hit = b
			cb = pair[1]
			break
	if hit == null:
		if _sweep_hit is BaseButton:
			_end_hold(_sweep_hit as BaseButton)
		_sweep_hit = null
		return
	if _holds.has(hit):
		_sweep_hit = hit
		return
	if _sweep_hit is BaseButton and _sweep_hit != hit:
		_end_hold(_sweep_hit as BaseButton)
	_start_hold(cb, hit)

func _connect_ui() -> void:
	_bind_resource_hold(egg_btn, collect_egg)
	_bind_resource_hold(cake_btn, sell_cake)
	_bind_resource_hold(hatch_btn, start_hatch)
	_bind_resource_hold(chick_btn, collect_chick)
	_bind_hold(wolf_buy, buy_chick)
	_bind_hold(wolf_sell, sell_hen)
	wolf_talk.visible = false
	wolf_talk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bind_hold(share_buy, buy_shares)
	_bind_hold(share_sell, sell_shares)
	bakery_upgrade.pressed.connect(upgrade_bakery)
	_style_dock_green(day_end_btn, 28, true)
	day_end_btn.custom_minimum_size.y = 56.0
	day_end_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_end_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_settings_chrome()
	_style_red(_settings_node("Restart"))
	_settings_node("Restart").add_theme_font_size_override("font_size", 28)
	_style_beige(settings_home)
	settings_home.add_theme_font_size_override("font_size", 28)
	_style_beige(_settings_node("GuideBtn"))
	_settings_node("GuideBtn").add_theme_font_size_override("font_size", 28)
	_style_tag(_settings_node("FontRow/Options/SmallBtn"))
	_style_tag(_settings_node("FontRow/Options/NormalBtn"))
	_style_tag(_settings_node("FontRow/Options/LargeBtn"))
	_style_toggle_chip(_settings_node("SfxRow/SfxBtn"), sfx.sfx_on)
	_style_toggle_chip(_settings_node("AmbRow/AmbBtn"), sfx.amb_on)
	_style_guide_step($GuidePop/GuideCard/Content/StepEggs)
	_style_guide_step($GuidePop/GuideCard/Content/StepChick)
	_style_guide_step($GuidePop/GuideCard/Content/StepStock)
	_style_beige(tutorial_exit)
	_style_green(tutorial_next)
	_style_beige(start_menu_tutorial)
	_style_green(start_menu_direct)
	_style_beige(start_menu_challenge)
	_style_beige(start_menu_endless)
	_style_beige(start_menu_settings)
	_style_beige(start_menu_trophies)
	start_menu_tutorial.add_theme_font_size_override("font_size", 32)
	start_menu_direct.add_theme_font_size_override("font_size", 32)
	start_menu_challenge.add_theme_font_size_override("font_size", 32)
	start_menu_endless.add_theme_font_size_override("font_size", 32)
	start_menu_settings.add_theme_font_size_override("font_size", 32)
	start_menu_trophies.add_theme_font_size_override("font_size", 32)
	start_menu_direct.icon = null
	start_menu_tutorial.icon = null
	start_menu_challenge.icon = null
	start_menu_endless.icon = null
	_set_menu_icon(start_menu_settings, "res://icons/settings.png", 56)
	_set_menu_icon(start_menu_trophies, "res://icons/trophy.png", 56)
	_clean_panel(get_node("StartMenuLayer/Card"))
	_style_tutorial_card()
	_clean_panel(trophy_card)
	_bind_close_x($TrophyPop/CloseBtn, trophy_card, _close_trophies)
	$TrophyPop/Dim.gui_input.connect(_on_trophy_dim_input)
	_style_wolf_trade(wolf_buy, true)
	_style_wolf_trade(wolf_sell, false)
	_style_share_trade(share_buy, true)
	_style_share_trade(share_sell, false)
	_style_tag(bakery_upgrade)
	bakery_upgrade.add_theme_font_size_override("font_size", 14)
	bakery_upgrade.custom_minimum_size.y = 36.0
	bakery_upgrade.autowrap_mode = TextServer.AUTOWRAP_OFF
	bakery_upgrade.clip_text = false
	_set_menu_icon(bakery_upgrade, "res://assets/ui/farm-ui/icon_coin.png", 18)
	bakery_upgrade.add_theme_constant_override("h_separation", 4)
	chick_btn.icon = load("res://icons/chick.png")
	get_node("HUD/SettingsBtn").pressed.connect(_toggle_settings)
	card.confirmed.connect(_on_settlement_confirm)
	if card.has_signal("continue_endless"):
		card.continue_endless.connect(_continue_endless_from_finale)
	card.ad_rewind.connect(_on_ad_rewind)
	card.notice.connect(_toast)
	night.gui_input.connect(_on_night_gui_input)
	quest_btn.pressed.connect(_toggle_quest)
	$QuestPop/Dim.gui_input.connect(_on_quest_dim_input)
	$SettingsPop/Dim.gui_input.connect(_on_settings_dim_input)
	day_end_btn.pressed.connect(_next_day)
	var quest_continue := get_node("QuestPop/Card/Box/ContinueBtn") as Button
	_style_green(quest_continue)
	quest_continue.add_theme_font_size_override("font_size", 28)
	quest_continue.custom_minimum_size.y = 56
	quest_continue.pressed.connect(_close_quest)
	_bind_close_x($QuestPop/CloseBtn, quest_card, _close_quest)
	_bind_close_x($SettingsPop/CloseBtn, settings_card, _close_settings)
	$GuidePop/CloseBtn.pressed.connect(_close_guide)
	$GuidePop/Dim.gui_input.connect(_on_guide_dim_input)
	_settings_node("SfxRow/SfxBtn").pressed.connect(_on_sfx_toggle_pressed)
	_settings_node("AmbRow/AmbBtn").pressed.connect(_on_amb_toggle_pressed)
	_settings_node("LangRow/Options/ZhBtn").pressed.connect(func():
		if Loc.lang != "zh":
			Loc.toggle()
			_apply_locale()
	)
	_settings_node("LangRow/Options/EnBtn").pressed.connect(func():
		if Loc.lang != "en":
			Loc.toggle()
			_apply_locale()
	)
	_settings_node("FontRow/Options/SmallBtn").pressed.connect(func(): _set_font_scale(0.85))
	_settings_node("FontRow/Options/NormalBtn").pressed.connect(func(): _set_font_scale(1.0))
	_settings_node("FontRow/Options/LargeBtn").pressed.connect(func(): _set_font_scale(1.15))
	_settings_node("GuideBtn").pressed.connect(_replay_tutorial_from_settings)
	tutorial_next.pressed.connect(_tutorial_next_pressed)
	tutorial_exit.pressed.connect(func(): _leave_tutorial(false))
	_settings_node("Restart").pressed.connect(_factory_reset)
	settings_home.pressed.connect(_return_to_menu_pressed)
	_style_thought(egg_btn)
	_style_thought(cake_btn)
	_style_thought(hatch_btn)
	_style_thought(chick_btn)
	_ensure_bake_bar()
	_style_hud_chip(get_node("HUD/HudBar/CashChip"))
	_style_hud_chip(get_node("HUD/HudBar/StockChip"))
	_style_hud_chip(get_node("HUD/HudBar/HenChip"))
	_style_hud_chip(get_node("HUD/HudBar/ChickChip"))
	_style_top_hud_bar()
	_style_mail_dot()
	_style_dock(get_node("Dock"))
	_clean_panel(quest_card)
	_style_hud_chip(wealth_card)
	_style_hud_chip(flock_card)
	_style_quest_track(get_node("QuestPop/Card/Box/WealthCard/Row/Col/Track"), wealth_fill)
	_style_quest_track(get_node("QuestPop/Card/Box/FlockCard/Row/Col/Track"), flock_fill)
	_clean_panel(settings_card)
	_settings_col().add_theme_constant_override("separation", 14)
	_settings_node("Credits").add_theme_font_size_override("font_size", 18)
	# Keep settings within the portrait card in both languages and font scales.
	for row_name in ["SfxRow", "AmbRow", "LangRow", "FontRow"]:
		var row := _settings_node_or_null(row_name) as Control
		if row == null:
			continue
		for item in row.find_children("*", "Control", true, false):
			if item is Label:
				item.custom_minimum_size.x = 0.0
				item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				item.add_theme_font_size_override("font_size", 26)
				item.add_theme_color_override("font_color", Color("4e3d2c"))
			elif item is Button:
				item.clip_text = false
				item.autowrap_mode = TextServer.AUTOWRAP_OFF

func _toggle_wolf_talk() -> void:
	wolf_talk.visible = not wolf_talk.visible
	if wolf_talk.visible:
		juice.pop_in(wolf_talk)

func _style_green(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 29)
	b.add_theme_color_override("font_color", Color("fff8e8"))
	b.add_theme_color_override("font_hover_color", Color("fff8e8"))
	b.add_theme_color_override("font_pressed_color", Color("fff8e8"))
	b.add_theme_color_override("font_disabled_color", Color("fff8e888"))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	b.add_theme_constant_override("outline_size", 0)
	var sb := _clean_button_box(UiSimpleGreen)
	UiStyle.button_states(b, sb)
	b.clip_text = false
	b.autowrap_mode = TextServer.AUTOWRAP_OFF

func _style_red(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 29)
	b.add_theme_color_override("font_color", Color("fff8e8"))
	b.add_theme_color_override("font_hover_color", Color("fff8e8"))
	b.add_theme_color_override("font_pressed_color", Color("fff8e8"))
	b.add_theme_color_override("font_disabled_color", Color("fff8e888"))
	b.add_theme_color_override("font_outline_color", Color("6a2e2888"))
	b.add_theme_constant_override("outline_size", 3)
	var sb := _clean_button_box(UiSimpleRed)
	UiStyle.button_states(b, sb)
	b.clip_text = false
	b.autowrap_mode = TextServer.AUTOWRAP_OFF

func _style_beige(b: Button) -> void:
	_style_plank(b, UiSimpleBeige, Color("4e3d2c"))
	b.add_theme_font_size_override("font_size", 32)

func _set_menu_icon(b: Button, path: String, width: int) -> void:
	var tex := load(path) as Texture2D
	if tex:
		b.icon = tex
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.clip_text = false
	b.add_theme_constant_override("icon_max_width", width)
	b.add_theme_constant_override("h_separation", 6 if width >= 48 else 8)

func _style_tag(b: Button) -> void:
	var ink := Color("4e3d2c")
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	b.add_theme_color_override("font_disabled_color", Color(ink, 0.55))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	b.add_theme_constant_override("outline_size", 0)
	var sb := StyleBoxTexture.new()
	sb.texture = UiSimpleTag
	# Chip is ~119x68; keep pill caps, leave a stretchable center.
	sb.texture_margin_left = 28.0
	sb.texture_margin_top = 18.0
	sb.texture_margin_right = 28.0
	sb.texture_margin_bottom = 18.0
	sb.content_margin_left = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 6.0
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	UiStyle.button_states(b, sb)
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, 48.0)

func _bind_close_x(btn: TextureButton, card: Control, on_close: Callable) -> void:
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if not btn.pressed.is_connected(on_close):
		btn.pressed.connect(on_close)
	var pin := func():
		_pin_close_x(btn, card)
	if not card.resized.is_connected(pin):
		card.resized.connect(pin)
	pin.call()
	call_deferred("_pin_close_x", btn, card)

func _pin_close_x(btn: Control, card: Control) -> void:
	if btn == null or card == null or not is_instance_valid(btn) or not is_instance_valid(card):
		return
	if card.size.x < 8.0:
		return
	const S := 52.0
	const IN := 6.0
	btn.z_as_relative = true
	btn.z_index = 4
	btn.custom_minimum_size = Vector2(S, S)
	btn.size = Vector2(S, S)
	var corner := card.get_global_rect().position + Vector2(card.size.x - S - IN, IN)
	btn.global_position = corner

func _style_hud_chip(c: PanelContainer) -> void:
	# Top HUD slots are authored in Game.tscn; leave them alone.
	if hud_bar != null and c.get_parent() == hud_bar:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	if c.get_index() > 0:
		sb.border_color = Color(0.55, 0.42, 0.28, 0.35)
		sb.border_width_left = 1
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	c.add_theme_stylebox_override("panel", sb)

func _style_top_hud_bar() -> void:
	# HudBarBg is nested under HudBar and sized by anchors in the scene.
	pass

func _sync_top_hud_bar() -> void:
	pass

func _style_metric_card(c: PanelContainer, hit: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("e7f3d8ee") if hit else Color("fff6e6cc")
	sb.border_color = Color("8bb57aaa") if hit else Color("ead9b08c")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 12
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	c.add_theme_stylebox_override("panel", sb)

func _style_quest_track(track: Panel, fill: Panel) -> void:
	track.clip_contents = true
	track.add_theme_stylebox_override("panel", _pill_box(Color("eadfc6")))
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fill.anchor_right = 0.0
	fill.offset_left = 0.0
	fill.offset_top = 0.0
	fill.offset_right = 0.0
	fill.offset_bottom = 0.0
	fill.add_theme_stylebox_override("panel", _pill_box(Color("c4a056")))

func _set_quest_bar(fill: Panel, pct: float, hit: bool) -> void:
	fill.anchor_right = clampf(pct, 0.0, 1.0)
	fill.offset_right = 0.0
	fill.add_theme_stylebox_override("panel", _pill_box(Color("7ba56b") if hit else Color("c4a056")))

func _style_plank(b: Button, source: Texture2D, ink: Color) -> void:
	b.add_theme_font_size_override("font_size", 29)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	b.add_theme_color_override("font_disabled_color", Color(ink, 0.55))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	b.add_theme_constant_override("outline_size", 0)
	var sb := _plank_button_box(source)
	UiStyle.button_states(b, sb)
	b.clip_text = false
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, 58.0)

func _plank_button_box(source: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = source
	# Keep the rounded wooden caps intact; only the beige center stretches.
	sb.texture_margin_left = 44.0
	sb.texture_margin_top = 22.0
	sb.texture_margin_right = 44.0
	sb.texture_margin_bottom = 22.0
	sb.content_margin_left = 18.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 18.0
	sb.content_margin_bottom = 10.0
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return sb

func _cozy_button_box(source: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = source
	# Keep the painted metal caps intact when buttons stretch in Godot.
	sb.texture_margin_left = 18.0
	sb.texture_margin_top = 10.0
	sb.texture_margin_right = 18.0
	sb.texture_margin_bottom = 10.0
	sb.content_margin_left = 18.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 18.0
	sb.content_margin_bottom = 10.0
	return sb

func _clean_button_box(source: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = source
	# Wood-pill caps stay fixed; middle fill stretches.
	sb.texture_margin_left = 44.0
	sb.texture_margin_top = 22.0
	sb.texture_margin_right = 44.0
	sb.texture_margin_bottom = 22.0
	sb.content_margin_left = 18.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 18.0
	sb.content_margin_bottom = 10.0
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return sb

func _style_thought(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 29)
	b.add_theme_color_override("font_color", Color("4e3d2c"))
	b.add_theme_color_override("font_outline_color", Color("fff8e8e6"))
	b.add_theme_constant_override("outline_size", 3)
	b.text = ""
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sb := _thought_box(false)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("disabled", sb)
	_bubble_badge(b)

func _textured_button_box(source: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = source
	# Preserve the painted caps and outline while allowing any label width.
	sb.texture_margin_left = 11.0
	sb.texture_margin_top = 8.0
	sb.texture_margin_right = 11.0
	sb.texture_margin_bottom = 8.0
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb

func _bubble_badge(b: Button) -> Label:
	var badge := b.get_node_or_null("CountBadge") as Label
	if badge != null:
		return badge
	badge = Label.new()
	badge.name = "CountBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -25.0
	badge.offset_top = -6.0
	badge.offset_right = 4.0
	badge.offset_bottom = 16.0
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 22)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_color_override("font_outline_color", Color("7b3028"))
	badge.add_theme_constant_override("outline_size", 2)
	var badge_box := StyleBoxFlat.new()
	badge_box.bg_color = Color("d45a4c")
	badge_box.border_color = Color("fff6e6")
	badge_box.set_border_width_all(2)
	badge_box.set_corner_radius_all(11)
	badge.add_theme_stylebox_override("normal", badge_box)
	b.add_child(badge)
	return badge

func _set_bubble_badge(b: Button, text: String) -> void:
	var badge := _bubble_badge(b)
	badge.text = text
	badge.visible = not text.is_empty()

func _thought_box(is_baking: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff6e6f5")
	sb.border_color = Color("c4a574")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18 if is_baking else 28)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 30 if is_baking else 6
	return sb

func _pill_box(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(99)
	return sb

func _ensure_bake_bar() -> void:
	_bake_bar = cake_btn.get_node_or_null("BakeBar") as Panel
	if _bake_bar == null:
		_bake_bar = Panel.new()
		_bake_bar.name = "BakeBar"
		cake_btn.add_child(_bake_bar)
	_bake_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bake_bar.clip_contents = true
	_bake_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bake_bar.offset_left = 7.0
	_bake_bar.offset_right = -7.0
	_bake_bar.offset_top = -16.0
	_bake_bar.offset_bottom = -7.0
	_bake_bar.add_theme_stylebox_override("panel", _pill_box(Color("eadfc6")))
	_bake_fill = _bake_bar.get_node_or_null("Fill") as Panel
	if _bake_fill == null:
		_bake_fill = Panel.new()
		_bake_fill.name = "Fill"
		_bake_bar.add_child(_bake_fill)
	_bake_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bake_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_bake_fill.anchor_right = 0.0
	_bake_fill.offset_left = 0.0
	_bake_fill.offset_top = 0.0
	_bake_fill.offset_right = 0.0
	_bake_fill.offset_bottom = 0.0
	_bake_fill.add_theme_stylebox_override("panel", _pill_box(Color("f0a23d")))
	_bake_label = cake_btn.get_node_or_null("BakeLabel") as Label
	if _bake_label == null:
		_bake_label = Label.new()
		_bake_label.name = "BakeLabel"
		cake_btn.add_child(_bake_label)
	_bake_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bake_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bake_label.offset_left = 4.0
	_bake_label.offset_right = -4.0
	_bake_label.offset_top = -33.0
	_bake_label.offset_bottom = -17.0
	_bake_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bake_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bake_label.add_theme_font_size_override("font_size", 18)
	_bake_label.add_theme_color_override("font_color", Color("8b572f"))
	_bake_label.add_theme_color_override("font_outline_color", Color("fff8e8"))
	_bake_label.add_theme_constant_override("outline_size", 2)
	_bake_bar.visible = false
	_bake_label.visible = false
	_style_cake_thought(false)

func _style_cake_thought(is_baking: bool) -> void:
	var sb := _thought_box(is_baking)
	cake_btn.add_theme_stylebox_override("normal", sb)
	cake_btn.add_theme_stylebox_override("hover", sb)
	cake_btn.add_theme_stylebox_override("pressed", sb)
	cake_btn.add_theme_stylebox_override("disabled", sb)
	cake_btn.add_theme_color_override("icon_disabled_color", Color.WHITE)
	cake_btn.offset_bottom = 84.0 if is_baking else 64.0
	cake_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP if is_baking else VERTICAL_ALIGNMENT_CENTER

func _bake_visual() -> float:
	if baking <= 0:
		return 0.0
	if baking >= 100:
		return 100.0
	return minf(100.0, float(baking) + (_bake_acc / _bake_step_time()) * 5.0)

func _sync_bake_bar() -> void:
	if _bake_bar == null or _bake_fill == null or _bake_label == null:
		return
	var on := baking > 0 and baking < 100
	_bake_bar.visible = on
	_bake_label.visible = on
	if _cake_baking_ui != on:
		_cake_baking_ui = on
		_style_cake_thought(on)
	if not on:
		_bake_fill.anchor_right = 0.0
		return
	var visual := _bake_visual()
	var pct := clampf(visual / 100.0, 0.0, 1.0)
	var seconds_left := maxf(0.0, ((100.0 - visual) / 5.0) * _bake_step_time())
	_bake_label.text = Loc.t("baking", [seconds_left])
	_bake_fill.anchor_right = pct
	_bake_fill.offset_right = 0.0
	_bake_fill.visible = pct > 0.02

func _style_dock(c: PanelContainer) -> void:
	UiLayout.dock(self)
	# Same light-wood bar as top HUD so top/bottom read as one kit.
	var sb := StyleBoxTexture.new()
	sb.texture = preload("res://assets/ui/farm-ui/hud_bar.png")
	sb.texture_margin_left = 40.0
	sb.texture_margin_top = 28.0
	sb.texture_margin_right = 40.0
	sb.texture_margin_bottom = 28.0
	sb.content_margin_left = 10.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 10.0
	sb.content_margin_bottom = 8.0
	c.add_theme_stylebox_override("panel", sb)
	day_track.color = Color("4a3726a0")
	day_track_fill.color = Color("d4a04a")

func _fill_dock_row(_row: Control) -> void:
	UiLayout.dock(self)

func _bind_dock_button_states(b: Button, sb: StyleBoxTexture) -> void:
	UiStyle.button_states(b, sb)

func _style_dock_green(b: Button, font_size: int, wide := false) -> void:
	# Warm parchment ink; soft wood outline reads with light HUD dock.
	var ink := Color("fff4e4")
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	b.add_theme_color_override("font_disabled_color", Color(ink, 0.55))
	b.add_theme_color_override("font_outline_color", Color("3a2a18aa"))
	b.add_theme_constant_override("outline_size", 2)
	var sb := _clean_button_box(UiSimpleGreen)
	# Soften neon against cream HUD wood without touching node.modulate (Juice hurry).
	sb.modulate_color = Color(0.9, 0.88, 0.8)
	if wide:
		sb.content_margin_left = 20.0
		sb.content_margin_right = 20.0
		sb.content_margin_top = 12.0
		sb.content_margin_bottom = 12.0
	b.clip_text = false
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	_bind_dock_button_states(b, sb)

func _style_dock_red(b: Button, font_size: int) -> void:
	var ink := Color("fff4e4")
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	b.add_theme_color_override("font_disabled_color", Color(ink, 0.55))
	b.add_theme_color_override("font_outline_color", Color("4a241caa"))
	b.add_theme_constant_override("outline_size", 2)
	var sb := _clean_button_box(UiSimpleRed)
	sb.modulate_color = Color(0.9, 0.86, 0.8)
	b.clip_text = false
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	_bind_dock_button_states(b, sb)

# Wolf animal trade: length locked at 108. ZH keeps icon+label in a row;
# EN stacks icon above text and only grows height so the chick/hen stays
# the same size (long English labels used to crush expand_icon).
func _style_wolf_trade(b: Button, is_buy: bool) -> void:
	var en := Loc.lang != "zh"
	if is_buy:
		_style_dock_green(b, 15 if en else 17)
	else:
		_style_dock_red(b, 15 if en else 17)
	var sb := b.get_theme_stylebox("normal").duplicate() as StyleBoxTexture
	sb.content_margin_left = 6.0 if en else 8.0
	sb.content_margin_right = 6.0 if en else 8.0
	sb.content_margin_top = 6.0 if en else 8.0
	sb.content_margin_bottom = 6.0 if en else 8.0
	_bind_dock_button_states(b, sb)
	b.icon = load("res://icons/chick.png" if is_buy else "res://icons/hen.png")
	b.expand_icon = true
	if en:
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	else:
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 28)
	b.add_theme_constant_override("h_separation", 2 if en else 4)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if en else TextServer.AUTOWRAP_OFF
	b.clip_text = false
	b.custom_minimum_size = Vector2(108, 70 if en else 48)
	b.size_flags_horizontal = 0
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_fit_wolf_animal_row()

func _fit_wolf_animal_row() -> void:
	var animals := wolf_buy.get_parent() as Control
	if Loc.lang != "zh":
		animals.anchor_top = 0.52
		animals.anchor_bottom = 0.68
	else:
		animals.anchor_top = 0.56
		animals.anchor_bottom = 0.66

# Share trade: same plank thickness as DayEnd; sits in one action row.
func _style_share_trade(b: Button, is_buy: bool) -> void:
	if is_buy:
		_style_dock_green(b, 22)
	else:
		_style_dock_red(b, 22)
	var sb := b.get_theme_stylebox("normal").duplicate() as StyleBoxTexture
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	_bind_dock_button_states(b, sb)
	b.icon = load("res://icons/price_up.png" if is_buy else "res://icons/price_down.png")
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 22)
	b.add_theme_constant_override("h_separation", 6)
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.clip_text = false
	b.custom_minimum_size = Vector2(112, 56)

func _clean_panel(c: Control) -> void:
	var sb := StyleBoxTexture.new()
	sb.texture = UiSimplePanel
	# Riveted wood corners on the tall parchment panel.
	sb.texture_margin_left = 48.0
	sb.texture_margin_top = 48.0
	sb.texture_margin_right = 48.0
	sb.texture_margin_bottom = 48.0
	sb.content_margin_left = 22.0
	sb.content_margin_top = 26.0
	sb.content_margin_right = 22.0
	sb.content_margin_bottom = 22.0
	c.add_theme_stylebox_override("panel", sb)

func _cream_panel(c: Control) -> void:
	# Scene-provided atlas skins are already nine-sliced; do not replace them
	# with the fallback flat panel at runtime.
	if c.has_theme_stylebox_override("panel"):
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fffaf0")
	sb.border_color = Color("e4d4b8")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	c.add_theme_stylebox_override("panel", sb)

func _hold_repeat_s_for(b: BaseButton) -> float:
	return EGG_HOLD_REP_S if b == egg_btn else HOLD_REP_S

func _button_press_still_active(b: BaseButton) -> bool:
	if b == null:
		return false
	if _manual_button == b:
		return true
	for v in _armed_touches.values():
		if v == b:
			return true
	return false

## 一次按压结束。单击与长按分开计数，长按时长单独累计；重复 tick 不算新手势，
## 所以「一次长按收 8 个蛋」记成 1 次手势、8 次动作。
## 0.26 秒是 _start_hold 里开始连点的阈值，两处要一起改。
func _end_hold(b: BaseButton) -> void:
	if b == null or not _holds.has(b):
		return
	var h: Dictionary = _holds[b]
	_holds.erase(b)
	if _hold_btn == b:
		_hold_btn = null
		_holding = not _holds.is_empty()
		_hold_fn = Callable()
	var ms := Time.get_ticks_msec() - int(h.get("start_ms", Time.get_ticks_msec()))
	Analytics.note_gesture(ms >= 260, ms)

func _end_all_holds() -> void:
	var buttons: Array = _holds.keys()
	for btn in buttons:
		_end_hold(btn as BaseButton)

func _end_gesture() -> void:
	_end_all_holds()

func _start_hold(cb: Callable, b: BaseButton = null) -> void:
	if b == null:
		return
	if _holds.has(b):
		return
	sfx.unlock()
	_holds[b] = {
		"fn": cb,
		"wait": 0.26,
		"rep": _hold_repeat_s_for(b),
		"start_ms": Time.get_ticks_msec(),
	}
	_hold_fn = cb
	_hold_btn = b
	_sweep_hit = b
	_holding = true
	_gesture_start_ms = Time.get_ticks_msec()
	Analytics.note_input()
	juice.press(b)
	cb.call(false)

func _toast(text: String) -> void:
	var l := _label(text, 16, Color.WHITE)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color("3a2e22cc"))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var toast_panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("564b3ee8")
	sb.border_color = Color("fff0ce")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	toast_panel.add_theme_stylebox_override("panel", sb)
	toast_panel.add_child(l)
	var host := _toast_host()
	host.add_child(toast_panel)
	juice.toast_in(toast_panel)
	get_tree().create_timer(2.2).timeout.connect(toast_panel.queue_free)

func _toast_host() -> Control:
	# Menu is z=500 and would bury global Toasts (130) under the logo.
	# Host lock hints inside the menu layer, below the card (not over buttons).
	if start_menu != null and start_menu.visible:
		var slot := start_menu.get_node_or_null("MenuToasts") as VBoxContainer
		if slot == null:
			slot = VBoxContainer.new()
			slot.name = "MenuToasts"
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_theme_constant_override("separation", 8)
			start_menu.add_child(slot)
		start_menu.move_child(slot, start_menu.get_child_count() - 1)
		# Card ends ~0.75; keep hints in the clear strip under Settings/Trophies.
		UiLayout.rect(slot, 0.10, 0.78, 0.80, 0.14)
		return slot
	_sync_toast_layout()
	return toast_box

func _sync_toast_layout() -> void:
	if toast_box == null:
		return
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.clip_contents = false
	toast_box.add_theme_constant_override("separation", 8)
	# Below HUD / above farm; tall enough for two stacked hints.
	UiLayout.rect(toast_box, 0.10, 0.14, 0.80, 0.18)

func _tick_nums(delta: float) -> void:
	var c := float(cash())
	var s := float(held() * maxi(1, price))
	var cspd := maxf(90.0, absf(c - _cash_shown) * 9.0)
	var sspd := maxf(90.0, absf(s - _stock_shown) * 9.0)
	_cash_shown = move_toward(_cash_shown, c, cspd * delta)
	_stock_shown = move_toward(_stock_shown, s, sspd * delta)
	hud_cash.text = str(int(round(_cash_shown)))
	hud_stock.text = str(int(round(_stock_shown)))

func _later(sec: float, cb: Callable, cancel_on_settle := false) -> void:
	var id := _fx
	get_tree().create_timer(sec).timeout.connect(func():
		if id != _fx:
			return
		if cancel_on_settle and (settling or game_result != ""):
			return
		cb.call()
	)

func _deny(n: Control) -> void:
	sfx.deny()
	juice.shake(n if n else _hold_btn)

func _apply_menu_logo() -> void:
	var word := get_node_or_null("StartMenuLayer/Card/Box/LogoWordmark") as TextureRect
	if word == null:
		return
	word.texture = LogoWordEn if Loc.lang == "en" else LogoWordZh
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	word.custom_minimum_size = Vector2.ZERO

func _apply_locale() -> void:
	Analytics.set_lang(Loc.lang)
	_apply_menu_logo()
	if survey_pop != null:
		survey_pop.apply_locale()
	_apply_settings_labels()
	_apply_guide_labels()
	get_node("HUD/HudBar/CashChip/Row/CashBox/CashTitle").text = Loc.t("cash")
	get_node("HUD/HudBar/CashChip/Row/CashBox/CashTitle").visible = false
	get_node("HUD/HudBar/StockChip/Row/StockBox/StockTitle").text = Loc.t("stock")
	get_node("HUD/HudBar/StockChip/Row/StockBox/StockTitle").visible = false
	get_node("QuestPop/Card/Box/Head").text = Loc.t("quest_head")
	wolf_buy.text = Loc.t("buy_chick", [_chick_cost()])
	wolf_sell.text = Loc.t("sell_hen", [CHICK_SALE])
	_style_wolf_trade(wolf_buy, true)
	_style_wolf_trade(wolf_sell, false)
	share_buy.text = Loc.t("buy_share")
	share_sell.text = Loc.t("sell_share")
	# 底栏这颗按钮平时由 _tick_day_ui 维护，而那里**只在黄昏状态翻转的那一帧**写它。
	# 于是白天中途切语言，「结束今天」会一直停在旧语言，要等天黑或第二天早晨才跟上。
	# 这里补一次，取值逻辑和 _tick_day_ui 保持一致。
	if tutorial_mode:
		day_end_btn.text = Loc.t("end_day")
	else:
		day_end_btn.text = Loc.t("dusk_warn") if _dusk_hurry and leftover_eggs() > 0 else Loc.t("end_day")
	ticker_price_cap.text = Loc.t("price_cap")
	ticker_hold_hint.text = Loc.t("hold_hint")
	card.apply_locale()
	_refresh()
	if settling:
		card.preserve_actions_on_refresh = true
		_restore_settlement()
		card.preserve_actions_on_refresh = false
	_apply_font_scale()

func _apply_settings_labels() -> void:
	_settings_node("Title").text = Loc.t("settings")
	_settings_node("SfxRow/SfxTitle").text = Loc.t("sfx_title")
	_settings_node("AmbRow/AmbTitle").text = Loc.t("amb_title")
	_settings_node("SfxRow/SfxBtn").text = Loc.t("toggle_on" if sfx.sfx_on else "toggle_off")
	_settings_node("AmbRow/AmbBtn").text = Loc.t("toggle_on" if sfx.amb_on else "toggle_off")
	_style_toggle_chip(_settings_node("SfxRow/SfxBtn"), sfx.sfx_on)
	_style_toggle_chip(_settings_node("AmbRow/AmbBtn"), sfx.amb_on)
	_settings_node("LangRow/LangTitle").text = Loc.t("language")
	_settings_node("LangRow/Options/ZhBtn").text = "中文"
	_settings_node("LangRow/Options/EnBtn").text = "English"
	_style_lang_buttons()
	_settings_node("FontRow/FontTitle").text = Loc.t("font_size")
	_settings_node("FontRow/Options/SmallBtn").text = Loc.t("font_small")
	_settings_node("FontRow/Options/NormalBtn").text = Loc.t("font_standard")
	_settings_node("FontRow/Options/LargeBtn").text = Loc.t("font_large")
	_style_font_buttons()
	_settings_node("GuideBtn").text = Loc.t("tutorial_replay")
	# 按钮是打开设置时才建的，这里只在它已经存在时同步文案。
	_sync_feedback_btn()
	_settings_node("Help").text = Loc.t("help")
	_settings_node("Restart").text = Loc.t("restart")
	settings_home.text = Loc.t("home_menu")
	var credits := _settings_node("Credits") as Label
	credits.text = Loc.t("credits")
	var col := credits.get_parent()
	col.move_child(credits, col.get_child_count() - 1)
	if settings_pop != null and settings_pop.visible:
		call_deferred("_fit_settings_card")
	get_node("StartMenuLayer/Card/Box/Subtitle").visible = false
	start_menu_tutorial.text = Loc.t("start_tutorial")
	start_menu_direct.text = Loc.t("start_direct")
	start_menu_challenge.text = Loc.t("start_challenge")
	start_menu_endless.text = Loc.t("start_endless")
	_sync_menu_locks()
	start_menu_settings.text = Loc.t("start_settings")
	start_menu_trophies.text = Loc.t("start_trophies")
	get_node("TrophyPop/Card/Col/Title").text = Loc.t("trophy_title")
	if trophy_pop.visible:
		_fill_trophy_list()
	if tutorial_mode:
		_tutorial_refresh_prompt()

func _apply_guide_labels() -> void:
	get_node("GuidePop/GuideCard/Content/Title").text = Loc.t("guide_title")
	get_node("GuidePop/GuideCard/Content/SubTitle").text = Loc.t("guide_subtitle")
	get_node("GuidePop/GuideCard/Content/StepEggs/Row/Copy/Title").text = Loc.t("guide_step_eggs")
	get_node("GuidePop/GuideCard/Content/StepEggs/Row/Copy/Desc").text = Loc.t("guide_step_eggs_desc")
	get_node("GuidePop/GuideCard/Content/StepChick/Row/Copy/Title").text = Loc.t("guide_step_chick")
	get_node("GuidePop/GuideCard/Content/StepChick/Row/Copy/Desc").text = Loc.t("guide_step_chick_desc")
	get_node("GuidePop/GuideCard/Content/StepStock/Row/Copy/Title").text = Loc.t("guide_step_stock")
	get_node("GuidePop/GuideCard/Content/StepStock/Row/Copy/Desc").text = Loc.t("guide_step_stock_desc")

func _tick_day_ui() -> void:
	if tutorial_mode:
		day_label.text = Loc.t("tutorial_day_frac")
	elif endless_mode or challenge_mode:
		day_label.text = Loc.t("day_endless", [day])
	else:
		day_label.text = Loc.t("day_frac", [day])
	if tutorial_mode:
		day_track_fill.anchor_right = 0.0
		day_clock.set_elapsed(0.0, false)
		juice.set_panic(egg_btn, false)
		juice.set_panic(hatch_btn, false)
		if _dusk_hurry:
			_dusk_hurry = false
			juice.set_hurry(false)
		day_end_btn.text = Loc.t("end_day")
		return
	var gone := 1.0 - left_ms / _day_len_ms()
	day_track_fill.anchor_right = gone
	var panic := not settling and game_result == "" and left_ms > 0.0 and left_ms <= _dusk_warn_ms() and leftover_eggs() > 0
	juice.set_panic(egg_btn, panic and ready_eggs > 0)
	juice.set_panic(hatch_btn, false)
	var hurry := not settling and game_result == "" and left_ms <= _dusk_warn_ms()
	day_clock.set_elapsed(gone, hurry)
	if hurry != _dusk_hurry:
		_dusk_hurry = hurry
		juice.set_hurry(hurry)
		if hurry:
			juice.punch(day_clock, 1.12)
		day_end_btn.text = Loc.t("dusk_warn") if hurry and leftover_eggs() > 0 else Loc.t("end_day")

func rng(rng_seed: int) -> Callable:
	var s := [rng_seed]
	return func() -> float:
		s[0] = (s[0] * 1103515245 + 12345) & 0x7fffffff
		return float(s[0]) / 2147483647.0

func _in_poly(x: float, y: float, poly: Array) -> bool:
	var inside := false
	var j := poly.size() - 1
	for i in poly.size():
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[j]
		if ((a.y > y) != (b.y > y)) and x < ((b.x - a.x) * (y - a.y)) / (b.y - a.y + 0.000001) + a.x:
			inside = not inside
		j = i
	return inside

func _walk_poly() -> Array:
	if not _walk_poly_pts.is_empty():
		return _walk_poly_pts
	var c := Vector2.ZERO
	for p in FENCE_POLY:
		c += p
	c /= float(FENCE_POLY.size())
	for p in FENCE_POLY:
		_walk_poly_pts.append(p + (c - p).normalized() * 0.8)
	return _walk_poly_pts

func _in_yard(x: float, y: float) -> bool:
	var dx := x - 51.0
	var dy := y - 59.0
	if dx * dx + dy * dy < 16.0:
		return false
	return _in_poly(x, y, _walk_poly())

func _yard_spots() -> Array[Vector2]:
	if not _yard_spot_cache.is_empty():
		return _yard_spot_cache
	var s: Array[Vector2] = []
	var y := 49.4
	while y <= 72.2:
		var x := 17.0
		while x <= 79.0:
			if _in_yard(x, y):
				s.append(Vector2(x, y))
			x += 1.8
		y += 1.4
	_yard_spot_cache = s
	return s

func _pick_yard() -> Vector2:
	var spots := _yard_spots()
	if spots.is_empty():
		return Vector2(42, 62)
	return spots[randi() % spots.size()]

func _spread_spot(spots: Array[Vector2], taken: Array[Vector2], rand: Callable, min_gap: float) -> Vector2:
	if spots.is_empty():
		return Vector2(42, 62)
	var best := spots[int(rand.call() * spots.size())]
	var best_d := -1.0
	for _try in 10:
		var cand: Vector2 = spots[int(rand.call() * spots.size())]
		var near := 999.0
		for t in taken:
			near = minf(near, cand.distance_to(t))
		if taken.is_empty() or near >= min_gap:
			return cand
		if near > best_d:
			best_d = near
			best = cand
	return best

func _add_occluder(node: Control, rects: Array[Rect2], grow := 0.0) -> void:
	if node == null or not node.visible or not node.is_visible_in_tree():
		return
	if node.modulate.a < 0.08:
		return
	var r := node.get_global_rect()
	if grow != 0.0:
		r = r.grow(grow)
	if r.size.x < 10.0 or r.size.y < 10.0:
		return
	rects.append(r)

func _sync_bird_occluders() -> void:
	var rects: Array[Rect2] = []
	_add_occluder(get_node_or_null("HUD") as Control, rects)
	_add_occluder(get_node_or_null("Dock") as Control, rects)
	_add_occluder(wolf_hit, rects, 18.0)
	_add_occluder(wolf_talk, rects)
	_add_occluder(egg_btn, rects)
	_add_occluder(cake_btn, rects)
	_add_occluder(hatch_btn, rects)
	_add_occluder(chick_btn, rects)
	_add_occluder(bakery_upgrade, rects)
	_add_occluder(quest_card, rects)
	_add_occluder(settings_card, rects)
	if night.visible:
		_add_occluder(card, rects)
	YardBird.occluders = rects
	for c in flock_layer.get_children():
		if c is YardBird:
			(c as YardBird).refresh_ghost()

func _rebuild_flock() -> void:
	_flock_sig = ""
	_yard_spot_cache.clear()
	_walk_poly_pts.clear()
	_spawn_flock()

# Only the first FLOCK_RENDER_CAP birds get a node. HUD counts and birds()
# keep using the real numbers -- the yard is truncated, the logic is not.
func _render_hens() -> int:
	return mini(hens, FLOCK_RENDER_CAP)

func _render_chicks() -> int:
	return mini(young_chicks, maxi(0, FLOCK_RENDER_CAP - _render_hens()))

func _spawn_flock() -> void:
	for c in flock_layer.get_children():
		c.queue_free()
	var draw_h := _render_hens()
	var draw_y := _render_chicks()
	var grown_from := maxi(0, draw_h - just_grown)
	for i in draw_h:
		_add_one_bird("hen", i, just_grown > 0 and i >= grown_from)
	for i in draw_y:
		_add_one_bird("young", draw_h + i, false)

func _add_one_bird(kind: String, i: int = -1, grown := false) -> void:
	var spots := _yard_spots()
	var taken: Array[Vector2] = []
	for c in flock_layer.get_children():
		if c.is_queued_for_deletion() or not (c is YardBird):
			continue
		taken.append((c as YardBird).feet)
	if i < 0:
		i = flock_layer.get_child_count()
	var bird_seed := 0x9E3779B9 ^ ((i + 1) * 747796405) ^ (0xA5A5 if kind == "hen" else 0xC3C3)
	var rand := rng(bird_seed)
	var min_gap := 4.6 if kind == "hen" else 3.8
	var spot := _spread_spot(spots, taken, rand, min_gap)
	var sz := flock_layer.size
	if sz.x < 8.0:
		sz = get_viewport_rect().size
	var bird = YardBirdScr.new()
	var w := 0.122 if kind == "hen" else 0.086
	bird.size = Vector2(sz.x * w, sz.x * w)
	bird.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flock_layer.add_child(bird)
	bird.setup(kind, spot, _in_yard, _pick_yard)
	if grown:
		juice.grown(bird)

func _remove_one_bird(kind: String) -> void:
	var kids := flock_layer.get_children()
	for i in range(kids.size() - 1, -1, -1):
		var c := kids[i]
		if c.is_queued_for_deletion():
			continue
		if c is YardBird and (c as YardBird).kind == kind:
			c.queue_free()
			return

func _refresh_flock() -> void:
	var want_h := _render_hens()
	var want_y := _render_chicks()
	# Sign on the truncated counts, so past the cap the yard stops churning.
	var sig := "%d:%d:%d" % [want_h, want_y, just_grown]
	if sig == _flock_sig and flock_layer.get_child_count() > 0:
		return
	var need_rebuild := (
		just_grown > 0
		or _flock_sig == ""
		or flock_layer.get_child_count() == 0
	)
	_flock_sig = sig
	if need_rebuild:
		_spawn_flock()
		return
	var have_h := 0
	var have_y := 0
	for c in flock_layer.get_children():
		if c.is_queued_for_deletion() or not (c is YardBird):
			continue
		if (c as YardBird).kind == "hen":
			have_h += 1
		else:
			have_y += 1
	while have_h < want_h:
		_add_one_bird("hen")
		have_h += 1
	while have_h > want_h:
		_remove_one_bird("hen")
		have_h -= 1
	while have_y < want_y:
		_add_one_bird("young")
		have_y += 1
	while have_y > want_y:
		_remove_one_bird("young")
		have_y -= 1

func _refresh_thoughts() -> void:
	if settling or game_result != "" or _menu_holds_clock() or settings_pop.visible or guide_pop.visible or trophy_pop.visible or quest_pop.visible:
		egg_btn.visible = false
		cake_btn.visible = false
		hatch_btn.visible = false
		chick_btn.visible = false
		bakery_eggs.visible = false
		bakery_upgrade.visible = false
		return
	egg_btn.visible = ready_eggs > 0
	_set_bubble_badge(egg_btn, "×%d" % ready_eggs)
	egg_btn.disabled = blocked()
	cake_btn.visible = baking > 0 or cakes > 0
	cake_btn.disabled = cakes < 1 or blocked()
	_set_bubble_badge(cake_btn, ("×%d" % cakes) if cakes > 0 else "")
	if cakes > 0:
		cake_btn.tooltip_text = Loc.t("sell_cake_tip", [cakes])
	elif baking > 0:
		cake_btn.tooltip_text = Loc.t("cake_baking_tip")
	else:
		cake_btn.tooltip_text = ""
	_sync_bake_bar()
	hatch_btn.visible = hatched < 1 and hatching < 1
	hatch_btn.disabled = blocked()
	chick_btn.visible = hatched > 0
	chick_btn.disabled = blocked()
	_set_bubble_badge(chick_btn, "×%d" % hatched)
	_set_bubble_badge(hatch_btn, "")
	hatch_sprite.visible = hatching > 0 or hatched > 0
	if hatched > 0:
		if hatch_sprite.play != "once":
			hatch_sprite.start_once()
	else:
		hatch_sprite.play = "warm"
	bakery_eggs.visible = eggs > 0
	bakery_eggs.text = Loc.t("eggs_count", [eggs])
	var show_oven := day >= 2
	var oven_was_hidden := not bakery_upgrade.visible
	bakery_upgrade.visible = show_oven
	if show_oven and oven_was_hidden:
		juice.punch(bakery_upgrade, 1.12)
	var upgrade_cost := _bakery_upgrade_cost()
	if bakery_level >= _bakery_max():
		bakery_upgrade.text = Loc.t("oven_max", [bakery_level])
		bakery_upgrade.disabled = true
		bakery_upgrade.icon = null
	else:
		bakery_upgrade.text = Loc.t("oven_up", [upgrade_cost, bakery_level])
		bakery_upgrade.disabled = coins < upgrade_cost or blocked()
		if bakery_upgrade.icon == null:
			bakery_upgrade.icon = load("res://assets/ui/farm-ui/icon_coin.png")
	var broke_chick := cash() < _chick_cost()
	var broke_share := cash() < price
	var broke_oven := bakery_level < _bakery_max() and coins < upgrade_cost
	var no_hen := hens < 1
	var no_share := held() < 1
	wolf_buy.disabled = broke_chick or blocked()
	wolf_sell.disabled = no_hen or blocked()
	share_buy.disabled = broke_share or blocked()
	share_sell.disabled = no_share or blocked()
	_set_broke_mask(wolf_buy, broke_chick)
	_set_broke_mask(wolf_sell, no_hen)
	_set_broke_mask(share_buy, broke_share)
	_set_broke_mask(share_sell, no_share)
	_set_broke_mask(bakery_upgrade, broke_oven)

func _set_broke_mask(b: Control, on: bool) -> void:
	if b == null:
		return
	var existing := b.get_node_or_null("BrokeMask")
	if existing != null and not (existing is Panel):
		existing.name = "BrokeMaskOld"
		existing.queue_free()
		existing = null
	var mask := existing as Panel
	if mask == null:
		mask = Panel.new()
		mask.name = "BrokeMask"
		mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(mask)
		mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Sit inside the wood-pill nine-slice so square corners don't stick out.
		mask.offset_left = 5.0
		mask.offset_top = 5.0
		mask.offset_right = -5.0
		mask.offset_bottom = -5.0
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.16, 0.15, 0.14, 0.5)
		sb.set_corner_radius_all(999)
		sb.set_content_margin_all(0)
		mask.add_theme_stylebox_override("panel", sb)
	mask.visible = on

func _refresh() -> void:
	wolf_buy.text = Loc.t("buy_chick", [_chick_cost()])
	_tick_day_ui()
	_refresh_thoughts()
	_refresh_flock()
	if _menu_holds_clock():
		sfx.set_flock(0, 0)
	else:
		sfx.set_flock(hens, young_chicks + hatched)
	hud_hens.text = str(hens)
	hud_chicks.text = str(young_chicks + hatched)
	_refresh_quest()
	_sync_mail_dot()
	ticker_price.text = str(price)
	var prev := history[history.size() - 2] if history.size() > 1 else price
	var d := price - prev
	var up := d >= 0
	var tone := Color("3f8a52") if up else Color("c45a4c")
	ticker_price.add_theme_color_override("font_color", tone)
	ticker_delta.text = ("%s%d" % ["▲" if up else "▼", absi(d)])
	ticker_delta.add_theme_color_override("font_color", tone)
	ticker_hold.text = Loc.t("shares_n", [held()])
	stock_graph.set_history(history)
	_tutorial_apply_locks()
	if quest_complete() and not quest_done and game_result == "" and not settling and not challenge_mode:
		quest_done = true
		_start_fanfare()
	_check_trophies()

func _refresh_quest() -> void:
	var wealth_n := total()
	var flock_n := birds()
	var wealth_goal := WEALTH_GOAL
	var flock_goal := FLOCK_GOAL
	if _in_challenge():
		var gate := _next_challenge_gate()
		wealth_goal = int(gate.wealth)
		flock_goal = int(gate.birds)
	var wealth_hit := wealth_n >= wealth_goal
	var flock_hit := flock_n >= flock_goal
	var done := wealth_hit and flock_hit
	quest_title.text = Loc.t("quest_done") if done else Loc.t("quest_goal")
	if _in_challenge():
		quest_title.text = Loc.t("challenge_goal", [int(_next_challenge_gate().day), wealth_goal, flock_goal])
	get_node("QuestPop/Card/Box/WealthCard/Row/Col/Top/Name").text = Loc.t("quest_wealth_name")
	get_node("QuestPop/Card/Box/FlockCard/Row/Col/Top/Name").text = Loc.t("quest_flock_name")
	quest_wealth.text = "%d / %d" % [wealth_n, wealth_goal]
	quest_flock.text = "%d / %d" % [flock_n, flock_goal]
	wealth_hint.text = Loc.t("quest_hit") if wealth_hit else Loc.t("quest_need_gold", [maxi(0, wealth_goal - wealth_n)])
	flock_hint.text = Loc.t("quest_hit") if flock_hit else Loc.t("quest_need_birds", [maxi(0, flock_goal - flock_n)])
	wealth_hint.add_theme_color_override("font_color", Color("3f8a52") if wealth_hit else Color("8d7a61"))
	flock_hint.add_theme_color_override("font_color", Color("3f8a52") if flock_hit else Color("8d7a61"))
	_set_quest_bar(wealth_fill, float(wealth_n) / float(wealth_goal), wealth_hit)
	_set_quest_bar(flock_fill, float(flock_n) / float(flock_goal), flock_hit)
	_style_metric_card(wealth_card, wealth_hit)
	_style_metric_card(flock_card, flock_hit)
	quest_news.text = Loc.t("tonight_news", [Loc.news(news)])
	quest_news.add_theme_color_override("font_color", Color("3f8a52") if NEWS[news].up else Color("c45a4c"))
	quest_note.text = Loc.t("quest_note_done") if done else Loc.t("quest_note")
	if _in_challenge():
		quest_note.text = Loc.t("challenge_ready") if done else Loc.t("challenge_pending")
		quest_note.text += "\n" + Loc.t("challenge_rules", [int(_day_len_ms() / 1000.0), _chick_cost()])
	if done and not fanfare:
		quest_stamp.visible = true
		quest_stamp.modulate.a = 1.0
		quest_stamp.scale = Vector2.ONE
		quest_stamp.rotation = -0.22
		_fit_quest_stamp()
	elif not done:
		quest_stamp.visible = false
		quest_stamp.modulate.a = 0.0
	var cont := get_node_or_null("QuestPop/Card/Box/ContinueBtn") as Button
	if cont:
		cont.visible = done
		cont.text = Loc.t("continue_game")

func _fit_quest_stamp() -> void:
	# Absolute overlay on the card — never a PanelContainer layout child —
	# and sit above the metrics so it does not cover ContinueBtn.
	if quest_stamp == null or quest_card == null:
		return
	var card_sz := quest_card.size
	if card_sz.x < 8.0:
		return
	var side := minf(140.0, card_sz.x * 0.34)
	quest_stamp.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	quest_stamp.custom_minimum_size = Vector2(side, side)
	quest_stamp.size = Vector2(side, side)
	quest_stamp.position = Vector2(card_sz.x * 0.58 - side * 0.5, card_sz.y * 0.34 - side * 0.5)
	quest_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_stamp.z_as_relative = true
	quest_stamp.z_index = 2

func _sync_mail_dot() -> void:
	if mail_dot == null:
		return
	mail_dot.visible = mail_seen != news

func _style_mail_dot() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("e23b3b")
	sb.border_color = Color("fff6e6")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	mail_dot.add_theme_stylebox_override("panel", sb)

func pick_news(p: int) -> String:
	if _in_challenge():
		if randf() < 0.45:
			return "rain"
		return "hoard" if randf() < 0.5 else "cake"
	p = clampi(p, 50, 680)
	var roll := randf()
	if roll < 0.11 and p >= 110:
		return "rain"
	if roll < 0.22 and p <= 520:
		return "hoard"
	return "cake"

func next_price(current: int, n: String) -> int:
	if _in_challenge():
		var p := clampi(current if current else 220, 50, 1200)
		var nxt := 0
		if n == "rain":
			nxt = int(round(float(p) * randf_range(0.32, 0.78)))
		else:
			nxt = int(round(float(p) * randf_range(1.12, 1.90))) + randi_range(0, 40)
		return clampi(nxt, 50, 1200)
	var floor_p := 50
	var cap := 680
	var fair := 300
	var p := clampi(current if current else fair, floor_p, cap)
	var factor := 0.55 + randf() * 0.18 if n == "rain" else (1.22 + randf() * 0.28 if n == "hoard" else 1.05 + randf() * 0.12)
	var nxt := int(round((p + (fair - p) * 0.18) * factor))
	if n == "rain":
		nxt = mini(nxt, p - maxi(12, int(round(p * 0.1))))
	else:
		nxt = maxi(nxt, p + maxi(24 if n == "hoard" else 8, int(round(p * (0.16 if n == "hoard" else 0.05)))))
	return clampi(nxt, floor_p, cap)

## 一次真正改变了游戏状态的主动操作。
##
## 只有这里才会触发「重试后继续玩」和「自愿再玩」的转化事件：恢复画面、
## 点结算卡按钮、烤炉自动出炉都不算——那样会把「点了按钮就走」误判成继续玩。
func _note_effective_action(counter: String) -> void:
	Analytics.bump(counter)
	if _retry_resume_offer != "":
		var offer := _retry_resume_offer
		_retry_resume_offer = ""
		Analytics.log_event("retry_resumed", {"offer_id": offer, "action": counter})
	if _continuation_decision != "":
		var decision := _continuation_decision
		_continuation_decision = ""
		Analytics.log_event("continuation_engaged", {"decision_id": decision, "action": counter})

func collect_egg(quiet := false) -> bool:
	if blocked():
		return false
	if tutorial_mode and tutorial_step != 1:
		return false
	if ready_eggs < 1:
		Analytics.note_deny("resource")
		if not quiet:
			_toast(Loc.t("toast_eggs_done")); _deny(egg_btn)
		return false
	ready_eggs -= 1
	_note_effective_action("collect_egg_count")
	if tutorial_mode and tutorial_step == 1:
		tutorial_eggs_tapped = mini(3, tutorial_eggs_tapped + 1)
		_tutorial_refresh_prompt()
	sfx.egg()
	if not quiet:
		juice.fly("egg")
		juice.punch(egg_btn, 1.14)
	_refresh_thoughts()
	if not quiet:
		_save()
	_later(0.65, func():
		eggs += 1
		_tutorial_action("egg_stored")
		juice.punch(bakery_eggs, 1.18)
		_refresh(); _save()
	, true)
	return true

func collect_chick(quiet := false) -> bool:
	if blocked():
		return false
	if tutorial_mode:
		return false
	if hatched < 1:
		Analytics.note_deny("resource")
		if not quiet:
			_toast(Loc.t("toast_no_chick")); _deny(chick_btn)
		return false
	hatched -= 1
	_note_effective_action("hatch_collect_count")
	_hatch_ignore_ms = Time.get_ticks_msec()
	sfx.chick()
	if not quiet:
		juice.fly("chick")
		juice.punch(chick_btn, 1.16)
	_refresh_thoughts()
	if not quiet:
		_save()
	_later(0.65, func():
		young_chicks += 1
		_tutorial_action("chick_collected")
		_refresh(); _save()
	, true)
	return true

func start_hatch(quiet := false) -> bool:
	if blocked():
		return false
	if tutorial_mode and tutorial_step != 2:
		return false
	if Time.get_ticks_msec() - _hatch_ignore_ms < 400:
		return false
	if hatching >= 1:
		Analytics.note_deny("other")
		if not quiet:
			_toast(Loc.t("toast_hatch_once")); _deny(hatch_btn)
		return false
	# Free once-per-day nest: no egg inventory required or spent.
	hatching = 1
	_note_effective_action("hatch_start_count")
	_tutorial_action("hatch_started")
	sfx.hatch()
	juice.punch(hatch_sprite, 1.2)
	if not quiet:
		_toast(Loc.t("toast_hatching"))
	_refresh(); _save()
	return true

func sell_cake(quiet := false) -> bool:
	if blocked():
		return false
	if tutorial_mode and tutorial_step != 3:
		return false
	if cakes < 1:
		Analytics.note_deny("resource")
		if not quiet:
			_toast(Loc.t("toast_no_cake")); _deny(cake_btn)
		return false
	cakes -= 1
	cakes_sold += 1
	_note_effective_action("cake_sell_count")
	coins += CAKE_SALE
	_tutorial_action("cake_sold")
	_grant_trophy("cake")
	_save()
	if not quiet:
		juice.fly("cake")
		_later(0.08, func(): juice.fly("payout"))
		juice.punch(cake_btn, 1.14)
	_refresh()
	_later(0.72, func():
		sfx.coin()
		juice.wealth_pop(true)
	)
	return true

func buy_shares(quiet := false) -> bool:
	if blocked():
		return false
	if tutorial_mode and tutorial_step != 5:
		return false
	if price <= 0 or coins < price:
		Analytics.note_deny("funds")
		if not quiet:
			_toast(Loc.t("toast_need_gold_share")); _deny(share_buy)
		return false
	coins -= price
	shares += 1
	stock_spent += price
	_note_effective_action("stock_buy_count")
	_tutorial_action("share_bought")
	_grant_trophy("share")
	sfx.buy_share()
	if not quiet:
		juice.fly("spend")
		juice.punch(share_buy)
	_refresh()
	if not quiet:
		_save()
	_later(0.28, func(): juice.wealth_pop(true))
	return true

func sell_shares(quiet := false) -> bool:
	if blocked():
		return false
	if tutorial_mode and tutorial_step != 6:
		return false
	if shares < 1:
		Analytics.note_deny("resource")
		if not quiet:
			_toast(Loc.t("toast_no_shares")); _deny(share_sell)
		return false
	shares -= 1
	_note_effective_action("stock_sell_count")
	var gain := maxi(0, price)
	stock_sold += gain
	coins += gain
	_tutorial_action("share_sold")
	_save()
	sfx.sell_share()
	if not quiet:
		juice.fly("coin")
		juice.punch(share_sell)
	_refresh()
	_later(0.72, func():
		juice.wealth_pop(true)
	)
	return true

func buy_chick(quiet := false) -> bool:
	if blocked():
		return false
	if tutorial_mode and tutorial_step != 4:
		return false
	if coins < _chick_cost():
		Analytics.note_deny("funds")
		if not quiet:
			_toast(Loc.t("toast_need_gold_chick")); _deny(wolf_buy)
		return false
	coins -= _chick_cost()
	young_chicks += 1
	_note_effective_action("chick_buy_count")
	_tutorial_action("chick_bought")
	_grant_trophy("hen")
	sfx.spend(); sfx.chick()
	if not quiet:
		juice.fly("spend_wolf")
		juice.fly("chick_wolf")
		juice.punch(wolf_buy)
		juice.wealth_pop()
	_refresh()
	if not quiet:
		_save()
	return true

func upgrade_bakery() -> void:
	if day < 2 or blocked() or bakery_level >= _bakery_max():
		return
	var cost := _bakery_upgrade_cost()
	if coins < cost:
		Analytics.note_deny("funds")
		_toast(Loc.t("toast_oven_short", [cost - coins]))
		_deny(bakery_upgrade)
		return
	coins -= cost
	bakery_level += 1
	_note_effective_action("bakery_upgrade_count")
	sfx.spend()
	juice.punch(bakery_upgrade, 1.18)
	_toast(Loc.t("toast_oven_up", [bakery_level, _bake_step_time() * 20.0]))
	_refresh()
	_save()

func sell_hen(quiet := false) -> bool:
	if blocked():
		return false
	if tutorial_mode:
		return false
	if hens < 1:
		Analytics.note_deny("resource")
		if not quiet:
			_toast(Loc.t("toast_no_hen")); _deny(wolf_sell)
		return false
	hens -= 1
	_note_effective_action("hen_sell_count")
	coins += CHICK_SALE
	_save()
	sfx.hen()
	sfx.coin()
	if not quiet:
		juice.fly("coin_wolf")
		juice.punch(wolf_sell)
	_refresh()
	_later(0.65, func():
		juice.wealth_pop()
	)
	return true

## 一天结束发一条，带当天的动作计数和经济快照。
##
## 不给每次收蛋单独发事件：一局上千次点击会把额度吃光。
## 有了这些计数，「挂机流失」和「操作到手抽筋还是输」才分得开——
## 这两种流失的解法完全相反。
func _log_day_end(closing: int, old_wealth: int, broken: int, terminal: String, gate: Dictionary, gate_hit: bool) -> void:
	var props := {
		"how": "dusk" if left_ms <= 0.0 else "manual",
		"terminal": terminal,
		"gate_day": int(gate.day) if not gate.is_empty() else 0,
		"gate_hit": gate_hit,
		"wealth": closing,
		"old_wealth": old_wealth,
		"birds": birds(),
		"hens": hens,
		"coins": cash(),
		"shares": shares,
		"price": price,
		"bakery_level": bakery_level,
		"cakes_sold": cakes_sold,
		"stock_profit": stock_sold - stock_spent,
		"broken_eggs": broken,
	}
	var counters := Analytics.day_counters()
	for k in counters.keys():
		props[k] = counters[k]
	Analytics.log_event("day_end", props, true)

## 考核缺口。差 5% 和差 60% 的玩家复活意愿天差地别；
## 没有 shortfall_pct，「意愿率 34%」就是个无法解释的数字。
func _gate_props(gate: Dictionary, hit: bool, closing: int) -> Dictionary:
	var wealth_goal := int(gate.wealth)
	var birds_goal := int(gate.birds)
	var wealth_gap := maxi(0, wealth_goal - closing)
	var birds_gap := maxi(0, birds_goal - birds())
	var worst := maxf(
		float(wealth_gap) / maxf(1.0, float(wealth_goal)),
		float(birds_gap) / maxf(1.0, float(birds_goal))
	)
	return {
		"gate_day": int(gate.day),
		"hit": hit,
		"wealth": closing,
		"wealth_goal": wealth_goal,
		"wealth_gap": wealth_gap,
		"birds": birds(),
		"birds_goal": birds_goal,
		"birds_gap": birds_gap,
		"shortfall_pct": round(worst * 1000.0) / 10.0,
		"gate_retry_left": _gate_retry_left(int(gate.day)),
	}

func _next_day() -> void:
	if settling or game_result != "":
		return
	if tutorial_mode:
		# The primer is a single paused day. Never open night settlement.
		_tutorial_refresh_prompt()
		return
	settling = true
	# 结算阅读时间单独记，不计进有效游玩时长。
	Analytics.flush_interval("day_end")
	Analytics.set_phase(Analytics.PHASE_SETTLE)
	_set_settle_chrome(true)
	_fx += 1
	juice.set_hurry(false)
	_dusk_hurry = false
	if baking > 0 and baking < 100:
		cakes += 1
	baking = 0
	var leftover := leftover_eggs()
	var stored := eggs
	var loose := leftover - stored
	var hatch_open := hatching < 1 and hatched < 1
	var broken := 0
	if leftover > 0:
		broken = leftover
		if loose > 0:
			juice.spoil("coop", loose)
		if stored > 0:
			juice.spoil("hatch" if hatch_open else "bakery", stored)
		eggs = 0; ready_eggs = 0; pending_eggs = 0
		sfx.shatter()
		_toast(Loc.t("toast_eggs_lost"))
		_refresh_thoughts()
		await get_tree().create_timer(1.15 + mini(8, leftover) * 0.04).timeout
	var tonight := news
	var old_p := price
	var old_wealth := cash() + held() * old_p
	var p := next_price(price, tonight)
	if tutorial_mode:
		p = price
	price = p
	history.append(p)
	if history.size() > 8:
		history = history.slice(history.size() - 8)
	sfx.set_night(true)
	sfx.dusk()
	var grown := young_chicks
	var hatch_ready := hatching
	var sold := cakes_sold
	var closing := cash() + held() * p
	var big := absf(float(p - old_p)) / maxf(1.0, float(old_p)) >= 0.22
	summary = {
		"broken": broken, "grown": grown, "cakesSold": sold,
		"oldPrice": old_p, "newPrice": p, "day": day + 1, "fromDay": day,
		"hatched": hatch_ready, "news": tonight,
		"oldWealth": old_wealth, "newWealth": closing,
	}
	_check_closing_trophies(closing)
	# 日结数据到这里已经确定。先记这一天，再记终局：
	# 刷新页面重开结算卡走的是 _restore_settlement，不会再经过这里，所以不会重复计数。
	var gate_today := _challenge_gate_at(day) if challenge_mode else {}
	var gate_hit := false
	if not gate_today.is_empty():
		gate_hit = closing >= int(gate_today.wealth) and birds() >= int(gate_today.birds)
	var is_day8 := day == 8 and not endless_mode and not challenge_mode
	var day8_hit := closing >= WEALTH_GOAL and birds() >= FLOCK_GOAL
	var terminal := ""
	if is_day8:
		terminal = "campaign_clear" if day8_hit else "campaign_flop"
	elif not gate_today.is_empty():
		if not gate_hit:
			terminal = "gate_flop"
		elif int(gate_today.day) == 20:
			terminal = "challenge_clear"
	_log_day_end(closing, old_wealth, broken, terminal, gate_today, gate_hit)
	if not gate_today.is_empty():
		# 考核结果单独一条：第 12 / 16 / 20 关各自的通过率和缺口分布，
		# 是后面判断复活意愿衰减曲线的唯一依据。
		Analytics.log_event("gate_result", _gate_props(gate_today, gate_hit, closing), true)
	if is_day8:
		var hit := day8_hit
		if hit:
			game_result = "ended"
			_unlock_normal()
			_fill_finale_card(closing)
		else:
			game_result = "flop"
			_fill_campaign_flop_card(closing)
		# 保留八日语义的专用事件：打完 ≠ 达标，两者分开看。
		Analytics.log_event("campaign_end", {
			"quest_ok": hit,
			"wealth": closing,
			"birds": birds(),
			"wealth_goal": WEALTH_GOAL,
			"flock_goal": FLOCK_GOAL,
		}, true)
		sfx.ending("mid")
		await get_tree().process_frame
		juice.night_in(night, card)
		_save()
		return
	if challenge_mode:
		var gate := _challenge_gate_at(day)
		if not gate.is_empty():
			var hit := closing >= int(gate.wealth) and birds() >= int(gate.birds)
			if int(gate.day) == 20 and hit:
				game_result = "won"
				_unlock_challenge_clear()
				_grant_challenge_wealth_trophies(closing)
				_fill_win_card(closing)
				sfx.ending("mid")
				await get_tree().process_frame
				juice.night_in(night, card)
				_save()
				return
			if not hit:
				game_result = "flop"
				_fill_flop_card(closing, gate)
				sfx.ending("mid")
				await get_tree().process_frame
				juice.night_in(night, card)
				_save()
				return
	_fill_daily_card()
	sfx.price(p >= old_p, big)
	juice.flash_ticker(p >= old_p, big)
	await get_tree().process_frame
	juice.night_in(night, card)
	_save()

func _set_settle_chrome(hidden: bool) -> void:
	if _return_to_menu and not hidden:
		return
	var dock := get_node("Dock") as Control
	dock.visible = not hidden
	dock.z_index = 8
	flock_layer.process_mode = Node.PROCESS_MODE_DISABLED if hidden else Node.PROCESS_MODE_INHERIT
	var hud := get_node_or_null("HUD") as Control
	if hud:
		hud.visible = true
		hud.get_node("HudBar").visible = not hidden
		hud.get_node("ClockBox").visible = not hidden
	if hud_bar_bg:
		hud_bar_bg.visible = not hidden
	if hidden:
		egg_btn.visible = false
		cake_btn.visible = false
		hatch_btn.visible = false
		chick_btn.visible = false
		bakery_eggs.visible = false
		bakery_upgrade.visible = false
	else:
		_refresh_thoughts()
	_sync_bird_occluders()

## 终局后的一次主动选择。同一次接受的选择只建一个决策标识，双触摸不会重复创建。
## 奖励回档和普通续档不算「自愿再玩」，所以不建决策，只记选择。
func _note_settlement_choice(choice: String) -> void:
	var terminal := game_result != ""
	var decision := ""
	if terminal:
		decision = Analytics.new_id()
		_decision_id = decision
		_decision_prev_run = run_id
		_decision_choice = choice
		_decision_ms = Time.get_ticks_msec()
	Analytics.log_event("settlement_cta", {
		"choice": choice,
		"decision_id": decision,
		"previous_run_id": run_id,
		"result": game_result,
		"terminal": terminal,
	}, true)

func _on_settlement_confirm() -> void:
	if game_result != "":
		_note_settlement_choice("restart")
		_restart()
	else:
		_note_settlement_choice("next_day")
		_wake()

func _continue_endless_from_finale() -> void:
	if game_result == "won" and challenge_mode and not endless_mode:
		_note_settlement_choice("continue_endless")
		challenge_mode = false
		endless_mode = true
		game_result = ""
		if summary.is_empty():
			summary = {
				"broken": 0, "grown": young_chicks, "cakesSold": cakes_sold,
				"oldPrice": price, "newPrice": price, "day": day + 1, "fromDay": day,
				"hatched": hatching, "news": news,
				"oldWealth": total(), "newWealth": total(),
			}
		_save()
		_begin_run("endless", false)
		_wake()
		return
	if game_result != "ended" or challenge_mode or endless_mode:
		return
	if not quest_complete():
		return
	# 函数名是旧的：这里其实是「普通八日通关后进入挑战」。
	# 埋点按行为含义命名，不跟函数名叫 endless。
	_note_settlement_choice("continue_challenge")
	challenge_mode = true
	endless_mode = false
	game_result = ""
	if summary.is_empty():
		summary = {
			"broken": 0, "grown": young_chicks, "cakesSold": cakes_sold,
			"oldPrice": price, "newPrice": price, "day": day + 1, "fromDay": day,
			"hatched": hatching, "news": news,
			"oldWealth": total(), "newWealth": total(),
		}
	_save()
	# 模式变了，按新的一局记：run_start 会带上刚才那次终局的 decision_id。
	_begin_run("challenge", false)
	_wake()

func _toggle_quest() -> void:
	var now := Time.get_ticks_msec()
	if now - _quest_toggle_ms < 280:
		return
	_quest_toggle_ms = now
	if show_quest:
		_close_quest()
	else:
		_open_quest()

func _open_quest() -> void:
	_close_settings()
	show_quest = true
	seen_goal = 1
	mail_seen = news
	quest_pop.visible = true
	_sync_tutorial_layer()
	_quest_ignore_close = true
	_quest_toggle_ms = Time.get_ticks_msec()
	juice.pop_in(quest_card)
	_pin_close_x($QuestPop/CloseBtn, quest_card)
	_fit_quest_stamp()
	_sync_mail_dot()
	_refresh()
	_sync_hud_chrome()
	get_tree().create_timer(0.35).timeout.connect(func():
		_quest_ignore_close = false
	)

func _close_quest() -> void:
	show_quest = false
	quest_pop.visible = false
	_quest_ignore_close = false
	if quest_card:
		quest_card.modulate.a = 1.0
		quest_card.scale = Vector2.ONE
	_sync_tutorial_layer()
	if not _return_to_menu:
		_refresh_thoughts()
	_sync_hud_chrome()

func _toggle_settings() -> void:
	var now := Time.get_ticks_msec()
	if now - _settings_toggle_ms < 280:
		return
	_settings_toggle_ms = now
	if show_settings:
		_close_settings()
	else:
		_open_settings()

func _fit_settings_card() -> void:
	# 卡片高度跟着内容走并垂直居中，避免 Scroll 视口比内容高一截露出大片空白。
	if settings_card == null or not is_instance_valid(settings_card):
		return
	var col := _settings_col()
	if col == null:
		return
	var parent_sz := size
	if parent_sz.x < 8.0:
		parent_sz = get_viewport_rect().size
	var ms := col.get_combined_minimum_size()
	var pad_x := 48.0
	var pad_y := 52.0
	var sb := settings_card.get_theme_stylebox("panel")
	if sb != null:
		pad_x = sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)
		pad_y = sb.get_margin(SIDE_TOP) + sb.get_margin(SIDE_BOTTOM)
	var max_h := parent_sz.y * 0.86
	var h := minf(ms.y + pad_y, max_h)
	var w := clampf(parent_sz.x * 0.78, 420.0, parent_sz.x * 0.88)
	w = minf(maxf(w, ms.x + pad_x), parent_sz.x * 0.90)
	var x := (parent_sz.x - w) * 0.5
	var y := (parent_sz.y - h) * 0.5
	settings_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	settings_card.position = Vector2(x, y)
	settings_card.size = Vector2(w, h)
	_pin_close_x($SettingsPop/CloseBtn, settings_card)

func _open_settings() -> void:
	_end_gesture()
	_ensure_settings_feedback()
	_close_quest()
	show_settings = true
	settings_pop.visible = true
	settings_home.visible = not _return_to_menu
	_sync_tutorial_layer()
	_settings_ignore_close = true
	_settings_toggle_ms = Time.get_ticks_msec()
	_fit_settings_card()
	call_deferred("_fit_settings_card")
	juice.pop_in(settings_card, not settling)
	_pin_close_x($SettingsPop/CloseBtn, settings_card)
	var settings_scroll := settings_card.get_node_or_null("Scroll") as ScrollContainer
	if settings_scroll != null:
		settings_scroll.scroll_vertical = 0
	_sync_hud_chrome()
	get_tree().create_timer(0.35).timeout.connect(func():
		_settings_ignore_close = false
	)

func _return_to_menu_pressed() -> void:
	# 主动离开一局回菜单，是问「为什么停下来」最自然的时刻。
	_pulse_pending = true
	if tutorial_mode:
		_leave_tutorial(false)
		return
	show_settings = false
	settings_pop.visible = false
	_close_quest()
	_show_main_menu()

func _close_settings() -> void:
	show_settings = false
	settings_pop.visible = false
	_settings_ignore_close = false
	_sync_tutorial_layer()
	if not _return_to_menu:
		_refresh_thoughts()
	_restore_menu_if_needed()
	_sync_hud_chrome()

func _open_guide() -> void:
	show_settings = false
	settings_pop.visible = false
	_close_quest()
	guide_pop.visible = true
	_sync_tutorial_layer()
	guide_card.modulate.a = 1.0
	guide_card.scale = Vector2.ONE
	juice.pop_in(guide_card)
	_sync_hud_chrome()

func _style_guide_step(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f8e7bb")
	style.border_color = Color("9a6330")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 14
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	for label in panel.find_children("*", "Label", true, false):
		label.add_theme_color_override("font_color", Color("4b2d16"))

func _style_tutorial_card() -> void:
	# Layout for Card / TutorWolf lives in Game.tscn. Do not rewrite anchors
	# here — Play would wipe a manual editor pass.
	_clean_panel(get_node("TutorialLayer/Card"))
	tutorial_title.add_theme_color_override("font_color", Color("4e3d2c"))
	tutorial_body.add_theme_color_override("font_color", Color("6a5340"))
	if tutorial_wolf:
		tutorial_wolf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tutorial_wolf.visible = true

func _style_lang_buttons() -> void:
	var zh := _settings_node("LangRow/Options/ZhBtn") as Button
	var en := _settings_node("LangRow/Options/EnBtn") as Button
	if Loc.lang == "zh":
		_style_toggle_chip(zh, true)
		_style_toggle_chip(en, false)
	else:
		_style_toggle_chip(zh, false)
		_style_toggle_chip(en, true)
	zh.add_theme_font_size_override("font_size", 24)
	en.add_theme_font_size_override("font_size", 24)
	zh.custom_minimum_size = Vector2(156, 56)
	en.custom_minimum_size = Vector2(156, 56)

func _style_font_buttons() -> void:
	var small := _settings_node("FontRow/Options/SmallBtn") as Button
	var normal := _settings_node("FontRow/Options/NormalBtn") as Button
	var large := _settings_node("FontRow/Options/LargeBtn") as Button
	_style_toggle_chip(small, false)
	_style_toggle_chip(normal, false)
	_style_toggle_chip(large, false)
	if is_equal_approx(Loc.ui_font_scale, 0.85):
		_style_toggle_chip(small, true)
	elif is_equal_approx(Loc.ui_font_scale, 1.15):
		_style_toggle_chip(large, true)
	else:
		_style_toggle_chip(normal, true)
	small.add_theme_font_size_override("font_size", 22)
	normal.add_theme_font_size_override("font_size", 24)
	large.add_theme_font_size_override("font_size", 26)
	for b in [small, normal, large]:
		b.custom_minimum_size = Vector2(140, 56)

func _chip_toggle_box(on: bool) -> StyleBoxTexture:
	# chip-on: knob on right; tag: knob on left. Protect knob so it stays round.
	var sb := StyleBoxTexture.new()
	sb.texture = UiChipOn if on else UiSimpleTag
	sb.texture_margin_left = 48.0 if not on else 26.0
	sb.texture_margin_right = 48.0 if on else 26.0
	sb.texture_margin_top = 16.0
	sb.texture_margin_bottom = 16.0
	sb.content_margin_left = 44.0 if not on else 12.0
	sb.content_margin_right = 44.0 if on else 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return sb

func _style_toggle_chip(b: Button, on: bool) -> void:
	var ink := Color("fff8e8") if on else Color("4e3d2c")
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	b.add_theme_color_override("font_disabled_color", Color(ink, 0.5))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	b.add_theme_constant_override("outline_size", 0)
	b.icon = null
	b.clip_text = false
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.button_states(b, _chip_toggle_box(on))
	# Keep height at native 56 so the knob stays round; width stretches the track only.
	b.custom_minimum_size = Vector2(maxf(b.custom_minimum_size.x, 132.0), 56.0)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _style_settings_chrome() -> void:
	var flourish := _settings_node_or_null("Flourish") as TextureRect
	if flourish:
		flourish.texture = UiFlourish
		flourish.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flourish.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flourish.custom_minimum_size = Vector2(0, 22)
		flourish.modulate = Color(1, 1, 1, 0.92)
	var title := _settings_node("Title") as Label
	title.add_theme_color_override("font_color", Color("4e3d2c"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _replay_tutorial_from_settings() -> void:
	_close_settings()
	_start_tutorial()

func _set_font_scale(scale: float) -> void:
	if is_equal_approx(Loc.ui_font_scale, scale):
		return
	Loc.set_ui_font_scale(scale)
	_apply_locale()

func _apply_font_scale() -> void:
	for node in find_children("*", "Control", true, false):
		if not (node is Label or node is Button):
			continue
		if night.is_ancestor_of(node):
			continue
		var base := 0
		if node.has_meta("base_font_size"):
			base = int(node.get_meta("base_font_size"))
		else:
			base = node.get_theme_font_size("font_size")
			if base <= 0:
				continue
			node.set_meta("base_font_size", base)
		node.add_theme_font_size_override("font_size", maxi(12, roundi(base * Loc.ui_font_scale)))

func _close_guide() -> void:
	guide_pop.visible = false
	guide_card.modulate.a = 1.0
	guide_card.scale = Vector2.ONE
	_sync_tutorial_layer()
	if not _return_to_menu:
		_refresh_thoughts()
	_restore_menu_if_needed()
	_sync_hud_chrome()

func _sync_tutorial_layer() -> void:
	if tutorial_layer == null:
		return
	var blocked := (
		_return_to_menu
		or settings_pop.visible
		or guide_pop.visible
		or quest_pop.visible
		or trophy_pop.visible
	)
	tutorial_layer.visible = tutorial_mode and not blocked

func _on_guide_dim_input(event: InputEvent) -> void:
	if not guide_pop.visible:
		return
	var tap := false
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap = true
		pos = event.global_position
	elif event is InputEventScreenTouch and event.pressed:
		tap = true
		pos = event.position
	if tap and not guide_card.get_global_rect().has_point(pos):
		_close_guide()

func _on_settings_dim_input(event: InputEvent) -> void:
	if not settings_pop.visible:
		return
	var tap := false
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap = true
		pos = event.global_position
	elif event is InputEventScreenTouch and event.pressed:
		tap = true
		pos = event.position
	if not tap:
		return
	if _settings_ignore_close:
		return
	if _hud_button_at(pos) != null:
		return
	if _control_button_at(settings_pop, pos) != null:
		return
	_close_settings()

func _on_quest_dim_input(event: InputEvent) -> void:
	if not quest_pop.visible or _quest_ignore_close:
		return
	var tap := false
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap = true
		pos = event.global_position
	elif event is InputEventScreenTouch and event.pressed:
		tap = true
		pos = event.position
	if not tap:
		return
	if _hud_button_at(pos) != null:
		return
	if quest_btn.get_global_rect().has_point(pos):
		return
	if _control_button_at(quest_pop, pos) != null:
		return
	_close_quest()

func _on_night_gui_input(event: InputEvent) -> void:
	if not settling or not night.visible or not card.visible:
		return
	var tap := false
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap = true
		pos = event.global_position
	elif event is InputEventScreenTouch and event.pressed:
		tap = true
		pos = event.position
	if not tap:
		return
	if card.get_global_rect().has_point(pos):
		return
	if card.has_method("_on_cta"):
		card._on_cta()

func _on_ad_rewind() -> void:
	if _dawn_snap.is_empty():
		_toast(Loc.t("toast_no_rewind"))
		if card.has_method("unlock_actions"):
			card.unlock_actions()
		return
	# Retrying a failed challenge gate burns that gate's one allowance. Each of
	# day 12 / 16 / 20 keeps its own, so spending one here leaves the others.
	var gate_day := -1
	if game_result == "flop" and challenge_mode:
		var gate := _challenge_gate_at(day)
		if not gate.is_empty():
			gate_day = int(gate.day)
			if not _gate_retry_left(gate_day):
				_toast(Loc.t("toast_no_gate_retry"))
				if card.has_method("unlock_actions"):
					card.unlock_actions()
				return
	if _offer_id == "":
		# 正常情况下曝光时就建好了，这里兜底，免得点击事件没有机会标识。
		_offer_id = Analytics.new_id()
	var offer := _offer_id
	# 没填过问卷就填问卷，填过了改成五秒占位等待。这两条路的转化必须分开看。
	var reward := "wait" if Analytics.survey_done else "survey"
	_offer_reward = reward
	Analytics.log_event("retry_offer_click", {
		"offer_id": offer,
		"offer_context": _offer_context,
		"reward_type": reward,
		"gate_day": maxi(0, gate_day),
	})
	var granted := false
	if skip_reward_gate:
		granted = true
	elif reward == "survey":
		granted = await _run_survey_reward(offer)
	else:
		granted = await _run_wait_reward(offer)
	if not granted:
		if card.has_method("unlock_actions"):
			card.unlock_actions()
		return
	if gate_day >= 0:
		_spend_gate_retry(gate_day)
	await _rewind_to_dawn()
	_save()

## 问卷路径。按已定规则：没填完就关掉，这次奖励照发，稍后还能再填；
## 提交成功之后两处入口都不再弹问卷。所以这里永远返回 true。
func _run_survey_reward(offer: String) -> bool:
	var pop := _ensure_survey()
	_survey_source = _offer_context
	_survey_offer = offer
	_survey_form = "reward"
	Analytics.set_phase(Analytics.PHASE_SURVEY)
	pop.open(_survey_form, _survey_source)
	Analytics.log_event("survey_view", {
		"offer_id": offer,
		"survey_source": _survey_source,
		"survey_form": _survey_form,
		"survey_version": SURVEY_VERSION,
		"question_count": pop.question_count(),
	})
	await pop.closed
	Analytics.set_phase(Analytics.PHASE_SETTLE)
	return true

## 设置里的自愿反馈入口：只补填问卷，不发当天重试。
## 有了它，早早离开的玩家也有地方反馈，不至于只有走奖励入口的人被采样。
##
## 没交过主问卷就补主问卷；交过了改成补充反馈（难度、没看懂什么、为什么停）。
## 玩得最久的那批人恰恰最早交完主问卷，之后再没地方说话——补充表单就是给他们的。
func _open_settings_survey() -> void:
	if Analytics.survey_done and Analytics.exit_done:
		_toast(Loc.t("toast_survey_done"))
		return
	_survey_source = "settings"
	_survey_offer = ""
	_survey_form = "reward" if not Analytics.survey_done else "exit"
	var pop := _ensure_survey()
	pop.open(_survey_form, "settings")
	Analytics.log_event("survey_view", {
		"offer_id": "",
		"survey_source": "settings",
		"survey_form": _survey_form,
		"survey_version": SURVEY_VERSION,
		"question_count": pop.question_count(),
	})


## 调试快捷键：F9 / F10 / F11 直接打开三份问卷表单。
##
## 存在的理由：非 Web 环境下 `Analytics.enabled` 是 false，有效时长压根不累计，
## 所以主菜单脉冲在编辑器里**永远不会自己弹**（门槛是玩满一分钟）。
## 没有这个入口，本地就没法把问卷点一遍。
## 只在 debug 构建里有效——正式导出的网页包是 release，玩家碰不到。
## 顺手打开 verbose：本地不会真的上报，但控制台能看到那条 survey_submit 长什么样。
func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var form := ""
	match (event as InputEventKey).keycode:
		KEY_F9:
			form = "reward"
		KEY_F10:
			form = "exit"
		KEY_F11:
			form = "pulse"
		_:
			return
	Analytics.verbose = true
	_survey_source = "debug_key"
	_survey_offer = ""
	_survey_form = form
	var pop := _ensure_survey()
	pop.open(form, _survey_source)
	get_viewport().set_input_as_handled()


## 回主菜单时的单题脉冲。不发奖励、随手可关、每人一次。
##
## 这是唯一能采到「不走奖励入口就离开」那批人的位点，而那批人正是流失分析最需要的样本。
## 正要再开一局的人不问（_decision_id 未兑现），玩不满 PULSE_MIN_ACTIVE_MS 的也不问。
func _maybe_open_pulse() -> void:
	if not _pulse_pending:
		return
	if Analytics.pulse_done or not Analytics.enabled:
		return
	if Analytics.active_ms_total < PULSE_MIN_ACTIVE_MS:
		return
	if _decision_id != "":
		return
	if survey_pop != null and survey_pop.visible:
		return
	if not start_menu.visible or settings_pop.visible or trophy_pop.visible or guide_pop.visible:
		return
	_pulse_pending = false
	_survey_source = "menu_return"
	_survey_offer = ""
	_survey_form = "pulse"
	var pop := _ensure_survey()
	# StartMenuLayer 的 z 是 500，问卷卡是 125：不把菜单收起来，问卷会画在菜单底下。
	# 设置和奖杯页也是这么做的（_start_menu_settings_pressed），这里走同一条路，
	# 关掉后由 _restore_menu_if_needed() 放回来。
	start_menu.visible = false
	pop.open(_survey_form, _survey_source)
	Analytics.log_event("survey_view", {
		"offer_id": "",
		"survey_source": _survey_source,
		"survey_form": _survey_form,
		"survey_version": SURVEY_VERSION,
		"question_count": pop.question_count(),
	})
	await pop.closed
	_restore_menu_if_needed()

func _ensure_settings_feedback() -> void:
	var col := _settings_col() as Control
	if col == null:
		return
	if _settings_feedback_btn == null:
		_settings_feedback_btn = Button.new()
		_settings_feedback_btn.name = "FeedbackBtn"
		col.add_child(_settings_feedback_btn)
		_style_beige(_settings_feedback_btn)
		_settings_feedback_btn.add_theme_font_size_override("font_size", 22)
		var guide := _settings_node_or_null("GuideBtn") as Button
		if guide != null:
			col.move_child(_settings_feedback_btn, guide.get_index() + 1)
		_settings_feedback_btn.pressed.connect(_open_settings_survey)
	_sync_feedback_btn()


## 设置里的反馈按钮：没交主问卷时是「留下反馈」，交过了变成「再说两句」的补充表单，
## 两份都交完才隐藏。奖励入口那边不受影响，仍然只看 survey_done。
func _sync_feedback_btn() -> void:
	if _settings_feedback_btn == null:
		return
	_settings_feedback_btn.text = Loc.t(
		"settings_feedback_more" if Analytics.survey_done else "settings_feedback"
	)
	_settings_feedback_btn.visible = not (Analytics.survey_done and Analytics.exit_done)
	if settings_pop != null and settings_pop.visible:
		call_deferred("_fit_settings_card")

## 五秒占位等待。这不是广告：事件名、文案都不得写成广告展示或完播。
func _run_wait_reward(offer: String) -> bool:
	Analytics.set_phase(Analytics.PHASE_WAIT)
	Analytics.log_event("retry_wait_start", {
		"offer_id": offer,
		"reward_type": "wait",
		"required_wait_seconds": REWARD_WAIT_SECONDS,
	})
	var left := REWARD_WAIT_SECONDS
	while left > 0:
		if card.has_method("set_ad_countdown"):
			card.set_ad_countdown(left)
		await get_tree().create_timer(1.0).timeout
		left -= 1
	if card.has_method("set_ad_label_key"):
		card.set_ad_label_key("reward_wait_cta")
	Analytics.log_event("retry_wait_complete", {
		"offer_id": offer,
		"reward_type": "wait",
		"required_wait_seconds": REWARD_WAIT_SECONDS,
	})
	Analytics.set_phase(Analytics.PHASE_SETTLE)
	return true

func _ensure_survey() -> Control:
	if survey_pop == null:
		survey_pop = SurveyCardScript.new()
		survey_pop.name = "SurveyPop"
		add_child(survey_pop)
		survey_pop.submitted.connect(_on_survey_submitted)
		survey_pop.dismissed.connect(_on_survey_dismissed)
	return survey_pop

func _mode_name() -> String:
	if tutorial_mode:
		return "tutorial"
	if challenge_mode:
		return "challenge"
	if endless_mode:
		return "endless"
	return "normal"

func _on_survey_submitted(answers: Dictionary) -> void:
	var props := {
		"offer_id": _survey_offer,
		"survey_source": _survey_source,
		"survey_form": _survey_form,
		"survey_version": SURVEY_VERSION,
		"question_count": survey_pop.question_count() if survey_pop != null else 0,
		"game_result": game_result,
	}
	for k in answers.keys():
		props[k] = answers[k]
	Analytics.log_event("survey_submit", props, true)
	# 画像四项写成 person 属性用于分群；感受题、重试原因和自由文本只留在事件上——
	# 感受随局变化，写成 person 属性会被后一局覆盖，历史就没了。
	var person := {}
	for k in SurveyCardScript.PROFILE_KEYS:
		if answers.has(k):
			person[str(k)] = answers[k]
	if not person.is_empty():
		Analytics.set_person(person)
	# 三份表单各记各的完成标记：交过主问卷的人仍然要能被问到流失原因。
	match _survey_form:
		"exit":
			Analytics.mark_exit_done()
		"pulse":
			Analytics.mark_pulse_done()
		_:
			Analytics.mark_survey_done()
			if card.has_method("set_ad_label_key"):
				card.set_ad_label_key("reward_wait_cta")
	_sync_feedback_btn()
	_toast(Loc.t("toast_survey_thanks"))

func _on_survey_dismissed(dwell_ms: int, answered: int) -> void:
	# 只统计 submit 会严重高估问卷体验：按已定规则，关掉也照发奖励。
	# last_question_* 是「最后碰过的题」：只看答了几题，分不出是开头就走还是最后一题放弃。
	var pop := survey_pop
	Analytics.log_event("survey_dismiss", {
		"offer_id": _survey_offer,
		"survey_source": _survey_source,
		"survey_form": _survey_form,
		"survey_version": SURVEY_VERSION,
		"question_count": pop.question_count() if pop != null else 0,
		"last_question_key": pop.last_question_key() if pop != null else "",
		"last_question_index": pop.last_question_index() if pop != null else -1,
		"dwell_ms": dwell_ms,
		"answered_count": answered,
	}, true)

## 入口真正可见时才算一次曝光，并按「局 + 天 + 尝试」去重：
## 玩家在结算页刷新会重开结算卡，那不是又看见了一次新机会。
func _note_retry_offer(context: String, available: bool, gate: Dictionary) -> void:
	if not available:
		return
	if card.has_method("set_ad_label_key"):
		card.set_ad_label_key("reward_wait_cta" if Analytics.survey_done else "reward_survey_cta")
	var key := "%s|%d|%s" % [run_id, day, attempt_id]
	if _offer_key == key:
		return
	_offer_key = key
	_offer_id = Analytics.new_id()
	_offer_context = context
	_offer_reward = "wait" if Analytics.survey_done else "survey"
	var props := {
		"offer_id": _offer_id,
		"offer_context": context,
		"reward_type": _offer_reward,
		"required_wait_seconds": REWARD_WAIT_SECONDS if _offer_reward == "wait" else 0,
	}
	if not gate.is_empty():
		var g := _gate_props(gate, false, total())
		for k in g.keys():
			props[k] = g[k]
	Analytics.log_event("retry_offer_view", props)

func _ensure_dawn_snap() -> void:
	if _dawn_snap.is_empty() and not settling and game_result == "":
		_capture_dawn()

func _capture_dawn() -> void:
	_dawn_snap = {
		"coins": coins,
		"eggs": eggs,
		"readyEggs": ready_eggs,
		"pendingEggs": pending_eggs,
		"hens": hens,
		"youngChicks": young_chicks,
		"cakes": cakes,
		"cakesSold": cakes_sold,
		"shares": shares,
		"stockSpent": stock_spent,
		"stockSold": stock_sold,
		"price": price,
		"day": day,
		"history": history.duplicate(),
		"wealthLog": wealth_log.duplicate(),
		"baking": baking,
		"bakeryLevel": bakery_level,
		"hatching": hatching,
		"hatched": hatched,
		"news": news,
		"seenGoal": seen_goal,
		"mailSeen": mail_seen,
		"questDone": quest_done,
		"bakeAcc": _bake_acc,
		"eggAcc": _egg_acc,
		"eggReadyAcc": _egg_ready_acc,
		"eggPreDuskTarget": _egg_pre_dusk_target,
		"eggDripAt": _egg_drip_at.duplicate(),
		"challengeMode": challenge_mode,
		"endlessMode": endless_mode,
	}

func _rewind_to_dawn() -> void:
	var d := _dawn_snap
	_fx += 1
	coins = int(d.get("coins", coins))
	eggs = int(d.get("eggs", eggs))
	ready_eggs = int(d.get("readyEggs", ready_eggs))
	pending_eggs = int(d.get("pendingEggs", pending_eggs))
	hens = int(d.get("hens", hens))
	young_chicks = int(d.get("youngChicks", young_chicks))
	cakes = int(d.get("cakes", cakes))
	cakes_sold = int(d.get("cakesSold", cakes_sold))
	shares = int(d.get("shares", shares))
	stock_spent = int(d.get("stockSpent", stock_spent))
	stock_sold = int(d.get("stockSold", stock_sold))
	price = int(d.get("price", price))
	day = int(d.get("day", day))
	baking = int(d.get("baking", baking))
	bakery_level = clampi(int(d.get("bakeryLevel", bakery_level)), 1, BAKERY_MAX_LEVEL)
	hatching = int(d.get("hatching", hatching))
	hatched = int(d.get("hatched", hatched))
	news = str(d.get("news", news))
	seen_goal = int(d.get("seenGoal", seen_goal))
	mail_seen = str(d.get("mailSeen", mail_seen))
	quest_done = bool(d.get("questDone", false))
	_bake_acc = float(d.get("bakeAcc", 0.0))
	_egg_acc = float(d.get("eggAcc", 0.0))
	_egg_ready_acc = float(d.get("eggReadyAcc", 0.0))
	_egg_pre_dusk_target = int(d.get("eggPreDuskTarget", 0))
	_restore_egg_drip_at(d)
	if d.has("history") and d.history is Array:
		history.clear()
		for x in d.history:
			history.append(int(x))
	if d.has("wealthLog") and d.wealthLog is Array:
		wealth_log.clear()
		for x in d.wealthLog:
			wealth_log.append(int(x))
	challenge_mode = bool(d.get("challengeMode", challenge_mode))
	endless_mode = bool(d.get("endlessMode", endless_mode))
	left_ms = _day_len_ms()
	summary = {}
	game_result = ""
	just_grown = 0
	panic_told = false
	_dusk_hurry = false
	juice.set_hurry(false)
	_cash_shown = float(cash())
	_stock_shown = float(held() * maxi(1, price))
	day_end_btn.text = Loc.t("end_day")
	sfx.set_night(false)
	sfx.dawn()
	await juice.dawn_out(night, card)
	settling = false
	_set_settle_chrome(false)
	# 快照确实恢复成功之后才发。同一天的新一次尝试要换 attempt_id，
	# 否则两次重试的漏斗会串在一起。
	Analytics.flush_interval("rewind")
	attempt_index += 1
	attempt_id = Analytics.new_id()
	Analytics.set_run(run_id, attempt_id, attempt_index)
	Analytics.set_source_offer(_offer_id)
	_retry_resume_offer = _offer_id
	Analytics.log_event("retry_restored", {
		"offer_id": _offer_id,
		"offer_context": _offer_context,
		"reward_type": _offer_reward,
	}, true)
	Analytics.set_phase(Analytics.PHASE_PLAY)
	_log_day_start("reward_rewind")
	_capture_dawn()
	_refresh()
	_rebuild_flock()
	_save()
	_toast(Loc.t("toast_rewound", [day]))

func _fill_daily_card() -> void:
	night.color = Color(0.05, 0.08, 0.16, 0.72)
	var nid := str(summary.get("news", news))
	var info: Dictionary = NEWS[nid] if NEWS.has(nid) else NEWS["cake"]
	card.show_daily({
		"from_day": int(summary.get("fromDay", int(summary.get("day", day + 1)) - 1)),
		"to_day": int(summary.get("day", day + 1)),
		"news_text": Loc.news(nid),
		"news_up": bool(info.up),
		"weather": str(info.weather),
		"broken": int(summary.get("broken", 0)),
		"grown": int(summary.get("grown", 0)),
		"cakes": int(summary.get("cakesSold", 0)),
		"hatched": int(summary.get("hatched", 0)),
		"old_price": int(summary.get("oldPrice", price)),
		"new_price": int(summary.get("newPrice", price)),
		"old_wealth": int(summary.get("oldWealth", total())),
		"new_wealth": int(summary.get("newWealth", total())),
		"rewind": not _dawn_snap.is_empty(),
		"beat_text": _campaign_beat_text(int(summary.get("newWealth", total())), false),
	})
	_note_retry_offer("daily", not _dawn_snap.is_empty(), {})

## 编辑器调试：放下 user://debug_skip_day8 后下一帧跳到第八天通关结算。
## 只在 debug 包生效，网页正式包不会读这个文件。
func _debug_skip_to_campaign_clear() -> void:
	_fx += 1
	_tutorial_clear_highlights()
	tutorial_mode = false
	tutorial_layer.visible = false
	_write_tutorial_status("completed")
	_return_to_menu = false
	show_settings = false
	show_quest = false
	settings_pop.visible = false
	guide_pop.visible = false
	quest_pop.visible = false
	if trophy_pop:
		trophy_pop.visible = false
	wolf_talk.visible = false
	start_menu.visible = false
	_set_menu_idle(false)
	challenge_mode = false
	endless_mode = false
	day = 8
	coins = 1840
	shares = 10
	price = 140
	hens = 16
	young_chicks = 0
	hatched = 0
	hatching = 0
	eggs = 0
	ready_eggs = 0
	pending_eggs = 0
	cakes = 0
	cakes_sold = 2
	bakery_level = 3
	stock_spent = 1400
	stock_sold = 0
	wealth_log = [140, 280, 420, 510, 680, 900, 1400, 3240]
	history = [108, 96, 132, 114, 120, 132, 140, 140]
	left_ms = 0.0
	baking = 0
	settling = true
	var closing := total()
	game_result = "ended"
	summary = {
		"broken": 0, "grown": 0, "cakesSold": cakes_sold,
		"oldPrice": price, "newPrice": price, "day": 9, "fromDay": 8,
		"hatched": 0, "news": news,
		"oldWealth": closing, "newWealth": closing,
	}
	_grant_trophy("day8")
	_grant_day8_ranks(closing)
	_unlock_normal()
	Analytics.set_phase(Analytics.PHASE_SETTLE)
	_set_settle_chrome(true)
	_fill_finale_card(closing)
	sfx.set_night(true)
	sfx.ending("mid")
	_rebuild_flock()
	_refresh()
	_save()
	juice.night_in(night, card)


func _fill_finale_card(closing: int = -1) -> void:
	night.color = Color(0.22, 0.06, 0.10, 0.72)
	if closing < 0:
		closing = total()
	var rank := _rank_of(closing)
	if int(rank.lv) > CAMPAIGN_RANK_CAP:
		rank = RANKS[CAMPAIGN_RANK_CAP - 1]
	var pts: Array[int] = []
	for x in wealth_log:
		pts.append(int(x))
	if pts.is_empty() or pts[pts.size() - 1] != closing:
		pts.append(closing)
	card.show_finale({
		"kind": "campaign",
		"rank_lv": int(rank.lv),
		"rank_title": Loc.rank_title(int(rank.lv)),
		"rank_copy": Loc.rank_copy(int(rank.lv)),
		"wealth": closing,
		"birds": birds(),
		"wealth_goal": WEALTH_GOAL,
		"flock_goal": FLOCK_GOAL,
		"quest": quest_complete(),
		"cash": cash(),
		"stock": held() * maxi(1, price),
		"wealth_pts": pts,
		"rewind": not _dawn_snap.is_empty(),
		"rank_max": CAMPAIGN_RANK_CAP,
		"beat_text": _campaign_beat_text(closing, true),
	})

func _closing_wealth_points(closing: int) -> Array[int]:
	var pts: Array[int] = wealth_log.duplicate()
	pts.append(closing)
	return pts

func _fill_win_card(closing: int) -> void:
	night.color = Color(0.22, 0.06, 0.10, 0.72)
	if closing < 0:
		closing = total()
	var rank := _rank_of(closing)
	var pts: Array[int] = []
	for x in wealth_log:
		pts.append(int(x))
	if pts.is_empty() or pts[pts.size() - 1] != closing:
		pts.append(closing)
	var gate := _challenge_gate_at(20)
	if gate.is_empty():
		gate = CHALLENGE_GATES[CHALLENGE_GATES.size() - 1]
	var pct := beat_percent(closing)
	card.show_finale({
		"kind": "win",
		"rank_lv": int(rank.lv),
		"rank_title": Loc.rank_title(int(rank.lv)),
		"rank_copy": Loc.rank_copy(int(rank.lv)),
		"wealth": closing,
		"birds": birds(),
		"wealth_goal": int(gate.wealth),
		"flock_goal": int(gate.birds),
		"quest": true,
		"cash": cash(),
		"stock": held() * maxi(1, price),
		"wealth_pts": pts,
		"rank_max": RANKS.size(),
		"beat_text": Loc.t("beat_challenge", [beat_pct_label(pct), Loc.t(beat_tail_key(pct))]),
	})

func _fill_campaign_flop_card(closing: int = -1) -> void:
	night.color = Color(0.22, 0.06, 0.10, 0.72)
	if closing < 0:
		closing = total()
	var rank := _rank_of(closing)
	if int(rank.lv) > CAMPAIGN_RANK_CAP:
		rank = RANKS[CAMPAIGN_RANK_CAP - 1]
	card.show_finale({
		"kind": "campaign_flop",
		"rank_lv": int(rank.lv),
		"rank_title": Loc.rank_title(int(rank.lv)),
		"rank_copy": Loc.t("campaign_flop_copy"),
		"wealth": closing,
		"birds": birds(),
		"wealth_goal": WEALTH_GOAL,
		"flock_goal": FLOCK_GOAL,
		"quest": false,
		"cash": cash(),
		"stock": held() * maxi(1, price),
		"wealth_pts": _closing_wealth_points(closing),
		"rewind": not _dawn_snap.is_empty(),
		"rank_max": CAMPAIGN_RANK_CAP,
		"beat_text": "",
	})
	_note_retry_offer("campaign_flop", not _dawn_snap.is_empty(), {})

func _fill_flop_card(closing: int, gate: Dictionary) -> void:
	night.color = Color(0.22, 0.06, 0.10, 0.72)
	card.show_finale({
		"kind": "flop",
		"rank_lv": int(_rank_of(closing).lv),
		"rank_title": Loc.rank_title(int(_rank_of(closing).lv)),
		"rank_copy": Loc.t("challenge_flop_copy", [int(gate.day)]),
		"wealth": closing,
		"birds": birds(),
		"wealth_goal": int(gate.wealth),
		"flock_goal": int(gate.birds),
		"quest": false,
		"cash": cash(),
		"stock": held() * maxi(1, price),
		"wealth_pts": _closing_wealth_points(closing),
		# This gate's single reward-retry, independent of the other two.
		"rewind": _gate_retry_left(int(gate.day)) and not _dawn_snap.is_empty(),
		"rank_max": 12,
		"beat_text": "",
	})
	_note_retry_offer("gate_flop", _gate_retry_left(int(gate.day)) and not _dawn_snap.is_empty(), gate)

func _restore_settlement() -> void:
	if _return_to_menu:
		return
	# Repair missed awards in older closing saves. Grants are persisted and
	# idempotent, so reopening a report never repeats an earned trophy toast.
	if game_result != "" or not summary.is_empty():
		_check_closing_trophies(total())
	if game_result != "":
		settling = true
		_set_settle_chrome(true)
		sfx.set_night(true)
		if game_result == "won":
			_fill_win_card(total())
		elif game_result == "flop":
			if challenge_mode:
				_fill_flop_card(total(), _challenge_gate_at(day) if not _challenge_gate_at(day).is_empty() else _next_challenge_gate())
			else:
				_fill_campaign_flop_card()
		else:
			_fill_finale_card()
		night.visible = true
		night.modulate.a = 1.0
		card.visible = true
		card.modulate.a = 1.0
		card.scale = Vector2.ONE
	elif not summary.is_empty():
		settling = true
		_set_settle_chrome(true)
		sfx.set_night(true)
		_fill_daily_card()
		night.visible = true
		night.modulate.a = 1.0
		card.visible = true
		card.modulate.a = 1.0
		card.scale = Vector2.ONE

func _wake() -> void:
	if summary.is_empty():
		return
	var grown: int = summary.get("grown", 0)
	var new_hatch := int(summary.get("hatched", 0))
	hens += grown
	young_chicks = 0
	just_grown = grown
	hatched += new_hatch
	hatching = 0
	day = int(summary.get("day", day + 1))
	left_ms = _day_len_ms()
	if endless_mode and day >= 7:
		_grant_trophy("endless7")
	ready_eggs = 0
	pending_eggs = maxi(0, hens)
	_roll_egg_pre_dusk_target()
	_egg_ready_acc = 0.0
	_egg_drip_gap = 0.0
	eggs = 0
	cakes_sold = 0
	summary = {}
	panic_told = false
	news = pick_news(price)
	if tutorial_mode:
		news = "cake"
	sfx.set_night(false)
	sfx.dawn()
	if grown > 0:
		sfx.hen()
	if new_hatch > 0:
		sfx.chick()
	wealth_log.append(total())
	# Unbounded, this array keeps growing and goes into the save verbatim, and
	# the finale curve smears into a solid block.
	if wealth_log.size() > WEALTH_LOG_MAX:
		wealth_log = wealth_log.slice(wealth_log.size() - WEALTH_LOG_MAX)
	day_end_btn.text = Loc.t("end_day")
	await juice.dawn_out(night, card)
	settling = false
	_set_settle_chrome(false)
	Analytics.set_phase(Analytics.PHASE_TUTORIAL if tutorial_mode else Analytics.PHASE_PLAY)
	_log_day_start("next_day")
	if tutorial_mode:
		tutorial_day = 1
		_sync_tutorial_layer()
		_tutorial_refresh_prompt()
	_capture_dawn()
	_refresh()
	_save()
	if hatched > 0:
		juice.punch(hatch_sprite, 1.25)
	await get_tree().create_timer(0.9).timeout
	just_grown = 0
	_rebuild_flock()

func _start_fanfare() -> void:
	fanfare = true
	quest_stamp.visible = false
	quest_stamp.modulate.a = 0.0
	_open_quest()
	juice.celebrate(quest_btn)
	_later(0.12, func(): juice.punch(wealth_card, 1.12))
	_later(0.22, func(): juice.punch(flock_card, 1.12))
	_later(0.32, func():
		_fit_quest_stamp()
		juice.stamp_in(quest_stamp)
	)
	juice.burst(22)
	_toast(Loc.t("toast_quest"))
	sfx.quest()
	_later(0.78, func(): sfx.stamp())
	_later(3.4, func(): fanfare = false)

func _rank_of(wealth: int) -> Dictionary:
	var r: Dictionary = RANKS[0]
	for x in RANKS:
		if wealth >= int(x.min):
			r = x
	return r

func _reset_new_game_data() -> void:
	coins = 120; eggs = 0; ready_eggs = 3; pending_eggs = 0
	hens = 1; young_chicks = 0; cakes = 0; cakes_sold = 0; shares = 0
	stock_spent = 0; stock_sold = 0
	price = 120; day = 1; left_ms = DAY_MS
	history = [108, 96, 114, 120]
	wealth_log = [120]
	_cash_shown = 120.0
	_stock_shown = 0.0
	baking = 0; bakery_level = 1; hatching = 0; hatched = 0
	_bake_acc = 0.0; _egg_acc = 0.0; _egg_ready_acc = 0.0; _bake_hold = 0.0
	_egg_drip_gap = 0.0
	_egg_pre_dusk_target = 0
	settling = false; game_result = ""; summary = {}
	just_grown = 0; fanfare = false; quest_done = false
	show_quest = false; show_settings = false
	seen_goal = 0; mail_seen = ""; news = "cake"
	panic_told = false; _dusk_hurry = false
	endless_mode = false
	challenge_mode = false
	_gate_retry_used.clear()

func _start_tutorial() -> void:
	if tutorial_mode:
		return
	_return_to_menu = false
	start_menu.visible = false
	if trophy_pop:
		trophy_pop.visible = false
	_set_menu_idle(false)
	_write_tutorial_status("in_progress")
	_fx += 1
	_reset_new_game_data()
	tutorial_mode = true
	tutorial_day = 1
	tutorial_step = 0
	tutorial_eggs_stored = 0
	tutorial_eggs_tapped = 0
	_close_settings()
	_close_quest()
	_set_settle_chrome(false)
	night.visible = false
	card.visible = false
	wolf_talk.visible = false
	if wolf_shop:
		wolf_shop.visible = false
	sfx.set_night(false)
	_sync_tutorial_layer()
	_tutorial_refresh_prompt()
	# The intro step must always expose a clear entry action; otherwise a
	# fresh player sees only the exit control and cannot reach the first
	# resource-bubble step.
	if tutorial_day == 1 and tutorial_step == 0:
		tutorial_next.visible = true
		tutorial_next.text = Loc.t("tutorial_begin")
	_refresh()
	_capture_dawn()
	_apply_locale()
	_rebuild_flock()
	# 教学也算「开始游玩」：分钟节点、D1 的起点都从这里算。
	run_id = Analytics.new_id()
	attempt_id = Analytics.new_id()
	attempt_index = 0
	_tutorial_start_ms = Time.get_ticks_msec()
	_tutorial_step_ms = _tutorial_start_ms
	Analytics.set_mode("tutorial")
	Analytics.set_run(run_id, attempt_id, attempt_index)
	Analytics.set_day(0)
	Analytics.set_phase(Analytics.PHASE_TUTORIAL)
	Analytics.mark_first_play()
	Analytics.log_event("play_start", {"entry_reason": _take_entry_reason("menu_new")})
	Analytics.log_event("tutorial_start", {})
	Analytics.log_event("tutorial_step_view", {"step": 0})

func _leave_tutorial(completed: bool) -> void:
	if not tutorial_mode:
		return
	var toast_key := "tutorial_complete_toast" if completed else "tutorial_exit_toast"
	# 教学结束是有效计时的阶段边界，先补报残区间再换上下文。
	Analytics.flush_interval("tutorial_end")
	Analytics.log_event("tutorial_finish" if completed else "tutorial_abort", {
		"step": tutorial_step,
		"duration_ms": Time.get_ticks_msec() - _tutorial_start_ms,
	}, true)
	_fx += 1
	_write_tutorial_status("completed" if completed else "dismissed")
	_tutorial_clear_highlights()
	tutorial_mode = false
	tutorial_layer.visible = false
	_reset_new_game_data()
	_capture_dawn()
	night.visible = false
	card.visible = false
	quest_pop.visible = false
	settings_pop.visible = false
	guide_pop.visible = false
	wolf_talk.visible = false
	sfx.set_night(false)
	_cash_shown = float(cash())
	_stock_shown = float(held() * maxi(1, price))
	if completed:
		# Completing the tutorial starts a fresh formal first day; never restore
		# the save that existed before entering the tutorial.
		_save()
		_return_to_menu = false
		_set_menu_idle(false)
		_set_settle_chrome(false)
		# 教学完成直接进正式第一天，中间不经过主菜单，所以在这里开新局。
		# 「教程完成率高但第 1 天完成率低」这条接缝靠这一对事件才看得出来。
		_begin_run("normal", false, "tutorial_finish")
		_apply_locale()
		_rebuild_flock()
		_refresh()
	else:
		# Exiting tutorial returns to the route menu without touching formal save.
		# 中途放弃教学的人是最该问一句的样本。
		_pulse_pending = true
		_load()
		_show_main_menu()
	_toast(Loc.t(toast_key))
	# 必须等 tutorial_mode 关掉再发：_grant_trophy 在教学期间会主动吞掉 toast，
	# 写在上面等于奖杯静默入账，玩家当场没有任何反馈。
	if completed:
		_grant_trophy("primer")

func _complete_tutorial() -> void:
	_leave_tutorial(true)

func _tutorial_next_pressed() -> void:
	if not tutorial_mode:
		return
	if tutorial_step == 0:
		_tutorial_set_step(1)
	elif tutorial_step == 7:
		_complete_tutorial()

func _tutorial_action(action: String) -> void:
	if not tutorial_mode:
		return
	# The player completed the currently highlighted instruction. Clear its
	# glow immediately so only the next required target draws attention.
	_tutorial_clear_highlights()
	if tutorial_step == 1 and action == "egg_stored":
		tutorial_eggs_stored = mini(3, tutorial_eggs_stored + 1)
		if tutorial_eggs_stored >= 3:
			_tutorial_set_step(2)
		else:
			_tutorial_refresh_prompt()
	elif tutorial_step == 2 and action == "hatch_started":
		_tutorial_set_step(3)
	elif tutorial_step == 3 and action == "cake_sold":
		_tutorial_set_step(4)
	elif tutorial_step == 4 and action == "chick_bought":
		_tutorial_set_step(5)
	elif tutorial_step == 5 and action == "share_bought":
		_tutorial_script_price_up()
		_tutorial_set_step(6)
	elif tutorial_step == 6 and action == "share_sold":
		_tutorial_set_step(7)

func _tutorial_script_price_up() -> void:
	price = 150
	history.append(150)
	if history.size() > 8:
		history = history.slice(history.size() - 8)
	news = "cake"

func _tutorial_set_step(next_step: int) -> void:
	# 到这里说明上一步的动作真的做成了，步骤才会推进。
	var now := Time.get_ticks_msec()
	Analytics.log_event("tutorial_step_complete", {
		"step": tutorial_step,
		"step_duration_ms": now - _tutorial_step_ms,
	})
	_tutorial_step_ms = now
	tutorial_step = next_step
	Analytics.log_event("tutorial_step_view", {"step": next_step})
	_tutorial_refresh_prompt()
	_tutorial_apply_locks()
	call_deferred("_tutorial_focus_target")

func _tutorial_apply_locks() -> void:
	# Reset tutorial-controlled buttons before applying the current step.
	# Using `old_disabled or current_lock` made a button stay disabled forever
	# after the first tutorial step, so the highlighted target looked clickable
	# but could never receive input.
	for item in [egg_btn, hatch_btn, cake_btn, chick_btn, wolf_buy, wolf_sell, share_buy, share_sell, day_end_btn, bakery_upgrade]:
		if item != null:
			item.disabled = false
	if not tutorial_mode:
		if wolf_shop:
			wolf_shop.visible = true
		wolf_buy.visible = true
		wolf_sell.visible = true
		share_buy.visible = true
		share_sell.visible = true
		day_end_btn.visible = true
		day_end_btn.disabled = false
		if wolf_hit:
			wolf_hit.disabled = false
			wolf_hit.mouse_filter = Control.MOUSE_FILTER_STOP
		_tutorial_clear_highlights()
		return
	# WolfBuy lives under WolfShop. Hiding the shop while setting the child
	# visible leaves nothing to tap on step 4 ("buy a hen").
	if wolf_shop:
		wolf_shop.visible = tutorial_step == 4
	wolf_buy.visible = tutorial_step == 4
	wolf_sell.visible = false
	if wolf_talk:
		wolf_talk.visible = false
	share_buy.visible = tutorial_step == 5
	share_sell.visible = tutorial_step == 6
	day_end_btn.visible = false
	# Keep the same farm presentation as the formal level. Tutorial only locks
	# actions; it does not hide the resource bubbles, so the scene never looks
	# empty and players can see what will unlock next.
	bakery_upgrade.visible = false
	egg_btn.disabled = tutorial_step != 1
	hatch_btn.disabled = tutorial_step != 2
	cake_btn.disabled = tutorial_step != 3
	chick_btn.disabled = true
	wolf_buy.disabled = tutorial_step != 4
	wolf_sell.disabled = true
	share_buy.disabled = tutorial_step != 5
	share_sell.disabled = tutorial_step != 6
	bakery_upgrade.disabled = true
	day_end_btn.disabled = true
	if wolf_hit:
		wolf_hit.disabled = tutorial_step != 4
		wolf_hit.mouse_filter = Control.MOUSE_FILTER_IGNORE if tutorial_step == 4 else Control.MOUSE_FILTER_STOP

func _tutorial_clear_highlights() -> void:
	if _tutorial_focused_target != null and is_instance_valid(_tutorial_focused_target):
		_tutorial_focused_target.z_index = _tutorial_target_z_index
		_tutorial_focused_target.z_as_relative = _tutorial_target_z_as_relative
	_tutorial_focused_target = null
	if tutorial_dim:
		tutorial_dim.visible = false
	for item in [egg_btn, hatch_btn, cake_btn, chick_btn, wolf_buy, wolf_sell, share_buy, share_sell, day_end_btn, stock_graph, quest_btn]:
		if item != null:
			item.modulate = Color.WHITE

func _tutorial_refresh_prompt() -> void:
	if not tutorial_mode:
		return
	_sync_tutorial_layer()
	tutorial_layer.get_node("Card").visible = true
	if tutorial_wolf:
		tutorial_wolf.visible = true
	tutorial_title.text = Loc.t("tutorial_header")
	# Beginner route has no early-exit control; finish via the last-step CTA.
	tutorial_exit.visible = false
	var exit_spacer := tutorial_layer.get_node_or_null("Card/Box/Actions/Spacer") as Control
	if exit_spacer:
		exit_spacer.visible = false
	tutorial_next.visible = false
	match tutorial_step:
		0:
			tutorial_body.text = Loc.t("tutorial_t0_goal")
			tutorial_next.text = Loc.t("tutorial_begin")
			tutorial_next.visible = true
		1:
			if tutorial_eggs_tapped >= 3 and tutorial_eggs_stored < 3:
				tutorial_body.text = Loc.t("tutorial_t1_eggs_landing", [tutorial_eggs_tapped])
			else:
				tutorial_body.text = Loc.t("tutorial_t1_eggs", [tutorial_eggs_tapped])
		2:
			tutorial_body.text = Loc.t("tutorial_t2_hatch")
		3:
			tutorial_body.text = Loc.t("tutorial_t3_cake_sell") if cakes > 0 else Loc.t("tutorial_t3_cake_wait")
		4:
			tutorial_body.text = Loc.t("tutorial_t4_hen")
		5:
			tutorial_body.text = Loc.t("tutorial_t5_buy")
		6:
			tutorial_body.text = Loc.t("tutorial_t6_sell")
		7:
			tutorial_body.text = Loc.t("tutorial_t7_done")
			tutorial_next.text = Loc.t("tutorial_finish")
			tutorial_next.visible = true
	if not tutorial_next.visible and tutorial_step > 0:
		tutorial_body.text += "\n" + Loc.t("tutorial_tap_hint")

func _tutorial_focus_target() -> void:
	if not tutorial_mode:
		return
	_tutorial_clear_highlights()
	var targets: Array = [quest_btn, egg_btn, hatch_btn, cake_btn, wolf_buy, share_buy, share_sell, quest_btn]
	var target: Control = targets[tutorial_step] if tutorial_step >= 0 and tutorial_step < targets.size() else null
	UiLayout.tutorial(self, target)
	if target != null and target.is_visible_in_tree():
		_tutorial_focused_target = target
		_tutorial_target_z_index = target.z_index
		_tutorial_target_z_as_relative = target.z_as_relative
		target.z_as_relative = false
		target.z_index = 106
		tutorial_dim.visible = true
		target.modulate = Color(1.18, 1.08, 0.72, 1.0)
		juice.punch(target, 1.12)

func _wipe_user_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## 设置里的 Reset Game：玩法、成就、解锁、统计身份全部从零。
## 结算卡「再开一局」仍走 `_restart()`，只清当前存档。
func _factory_reset() -> void:
	Analytics.flush_interval("restart")
	Analytics.reset_player()
	_wipe_user_file(SAVE_PATH)
	_wipe_user_file(TUTORIAL_PATH)
	_wipe_user_file(TROPHY_PATH)
	_wipe_user_file(UNLOCK_PATH)
	_trophies.clear()
	_normal_cleared = false
	_challenge_cleared = false
	_had_main_save = false
	_decision_id = ""
	_continuation_decision = ""
	_pulse_pending = false
	_restart()


func _restart() -> void:
	_fx += 1
	_tutorial_clear_highlights()
	tutorial_mode = false
	tutorial_layer.visible = false
	if wolf_shop:
		wolf_shop.visible = true
	fanfare = false
	quest_done = false
	_dusk_hurry = false
	juice.set_hurry(false)
	coins = 120; eggs = 0; ready_eggs = 3; pending_eggs = 0
	_egg_pre_dusk_target = 0
	hens = 1; young_chicks = 0; cakes = 0; cakes_sold = 0; shares = 0
	stock_spent = 0; stock_sold = 0
	price = 120; day = 1; left_ms = DAY_MS
	history = [108, 96, 132, 114, 120]
	wealth_log = [120]
	_cash_shown = 120.0
	_stock_shown = 0.0
	baking = 0; bakery_level = 1; hatching = 0; hatched = 0
	settling = false; game_result = ""; summary = {}
	show_quest = false; show_settings = false
	quest_pop.visible = false; settings_pop.visible = false
	guide_pop.visible = false
	wolf_talk.visible = false
	wolf_talk.modulate.a = 1.0
	wolf_talk.scale = Vector2.ONE
	night.visible = false; card.visible = false
	night.modulate.a = 1.0
	card.modulate.a = 1.0
	card.scale = Vector2.ONE
	news = pick_news(120)
	mail_seen = ""
	endless_mode = false
	challenge_mode = false
	_gate_retry_used.clear()
	day_end_btn.text = Loc.t("end_day")
	# 存档被删掉了，随它一起作废的埋点标识也要清干净，
	# 否则下一局会带着上一局的机会标识。玩家身份不在这里，不受影响。
	run_id = ""
	attempt_id = ""
	attempt_index = 0
	_offer_key = ""
	_offer_id = ""
	_offer_context = ""
	_retry_resume_offer = ""
	Analytics.set_source_offer("")
	Analytics.flush_interval("restart")
	_capture_dawn()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	# Reset clears the tutorial marker too, then returns to the route-selection
	# menu instead of forcing one of the two modes.
	if FileAccess.file_exists(TUTORIAL_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TUTORIAL_PATH))
	_show_main_menu()
	_apply_locale()

func _save() -> void:
	if tutorial_mode:
		return
	var d := {
		"coins": coins, "eggs": eggs, "readyEggs": ready_eggs, "pendingEggs": pending_eggs,
		"eggPreDuskTarget": _egg_pre_dusk_target,
		"eggDripAt": _egg_drip_at.duplicate(),
		"hens": hens, "youngChicks": young_chicks, "cakes": cakes, "cakesSold": cakes_sold,
		"shares": shares, "stockSpent": stock_spent, "stockSold": stock_sold,
		"price": price, "day": day, "leftMs": left_ms,
		"history": history, "wealthLog": wealth_log, "baking": baking, "bakeryLevel": bakery_level, "hatching": hatching,
		"hatched": hatched, "news": news, "seenGoal": seen_goal, "mailSeen": mail_seen, "gameResult": game_result,
		"endlessMode": endless_mode,
		"challengeMode": challenge_mode,
		# Deliberately NOT in _capture_dawn: a rewind must not hand the retry
		# back, or the one-per-gate allowance becomes unlimited.
		"gateRetryUsed": _gate_retry_used,
		"summary": summary, "dawnSnap": _dawn_snap,
		# 只给埋点用，不参与任何玩法判断。续档必须沿用同一个 run_id，
		# 否则玩家刷新后继续玩，第 1–8 天漏斗会断成两截。
		"runId": run_id,
		"attemptId": attempt_id,
		"attemptIndex": attempt_index,
		"offerKey": _offer_key,
		"offerId": _offer_id,
		"offerContext": _offer_context,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		news = pick_news(price)
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	coins = int(d.get("coins", coins))
	eggs = int(d.get("eggs", eggs))
	ready_eggs = int(d.get("readyEggs", ready_eggs))
	pending_eggs = int(d.get("pendingEggs", pending_eggs))
	_egg_pre_dusk_target = int(d.get("eggPreDuskTarget", 0))
	_restore_egg_drip_at(d)
	hens = int(d.get("hens", hens))
	young_chicks = int(d.get("youngChicks", young_chicks))
	cakes = int(d.get("cakes", cakes))
	cakes_sold = int(d.get("cakesSold", cakes_sold))
	shares = int(d.get("shares", shares))
	stock_spent = int(d.get("stockSpent", stock_spent))
	stock_sold = int(d.get("stockSold", stock_sold))
	price = int(d.get("price", price))
	day = int(d.get("day", day))
	left_ms = float(d.get("leftMs", left_ms))
	baking = int(d.get("baking", baking))
	bakery_level = clampi(int(d.get("bakeryLevel", bakery_level)), 1, BAKERY_MAX_LEVEL)
	hatching = int(d.get("hatching", hatching))
	hatched = int(d.get("hatched", hatched))
	news = str(d.get("news", news))
	game_result = str(d.get("gameResult", ""))
	endless_mode = bool(d.get("endlessMode", false))
	challenge_mode = bool(d.get("challengeMode", false))
	_gate_retry_used.clear()
	if d.has("gateRetryUsed") and d.gateRetryUsed is Dictionary:
		for k in d.gateRetryUsed.keys():
			if d.gateRetryUsed[k]:
				_gate_retry_used[str(k)] = true
	seen_goal = int(d.get("seenGoal", seen_goal))
	mail_seen = str(d.get("mailSeen", mail_seen))
	# 埋点标识。统计上线前存的旧档没有这些键，读成空值即可；
	# _begin_run 会补一个，报表里当作「续档但缺原始标识」，不要当成新局。
	run_id = str(d.get("runId", ""))
	attempt_id = str(d.get("attemptId", ""))
	attempt_index = int(d.get("attemptIndex", 0))
	_offer_key = str(d.get("offerKey", ""))
	_offer_id = str(d.get("offerId", ""))
	_offer_context = str(d.get("offerContext", ""))
	if d.has("history") and d.history is Array:
		history.clear()
		for x in d.history:
			history.append(int(x))
	if d.has("wealthLog") and d.wealthLog is Array:
		wealth_log.clear()
		for x in d.wealthLog:
			wealth_log.append(int(x))
	if d.has("summary") and d.summary is Dictionary:
		summary = d.summary
	if d.has("dawnSnap") and d.dawnSnap is Dictionary:
		_dawn_snap = d.dawnSnap
	if game_result != "" or not summary.is_empty():
		settling = true
		left_ms = 0.0
		# Boot returns to the menu; a finished run may be replaced before its
		# report is reopened. Recover its closing awards while loading it.
		_check_closing_trophies(total())
