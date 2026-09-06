extends Control

const UiLayout := preload("res://scripts/UiLayout.gd")
const UiStyle := preload("res://scripts/UiStyle.gd")

const SheetSpr := preload("res://scripts/SheetSprite.gd")
const YardBirdScr := preload("res://scripts/YardBird.gd")
const UiSimplePanel := preload("res://assets/ui/farm-ui/simple-ui/panel.png")
const UiSimpleBeige := preload("res://assets/ui/farm-ui/simple-ui/button-beige.png")
const UiSimpleGreen := preload("res://assets/ui/farm-ui/simple-ui/button-green.png")
const UiSimpleRed := preload("res://assets/ui/farm-ui/simple-ui/button-red.png")
const UiSimpleTag := preload("res://assets/ui/farm-ui/simple-ui/tag.png")
const UiChipOn := preload("res://assets/ui/farm-ui/simple-ui/chip-on.png")
const UiFlourish := preload("res://assets/ui/farm-ui/simple-ui/flourish.png")

const DAY_MS := 20000.0
const TUTORIAL_DAY_MS := 60000.0
const DUSK_WARN_MS := 5000.0
const EGG_PRE_DUSK_RATIO := 0.75
const EGG_PRE_DUSK_FLOOR := 0.65
const EGG_DRIP_MIN_S := 0.12
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
const ZOOM_MIN := 1.0
const ZOOM_MAX := 2.4
const ZOOM_WHEEL := 1.08
const WORLD_BACK := ["Bg", "Map", "Flock", "HatchEgg"]
const WORLD_FRONT := [
	"EggThought", "CakeThought", "HatchThought", "ChickThought",
	"BakeryEggs", "BakeryUpgrade", "WolfShop", "FlyLayer",
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
var _normal_cleared := false
var _challenge_cleared := false
var _return_to_menu := false
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
var _quest_toggle_ms := 0
var _hatch_ignore_ms := 0
var panic_told := false
var quest_done := false
var _bake_acc := 0.0
var _egg_acc := 0.0
var _egg_ready_acc := 0.0
var _egg_drip_gap := 0.0
var _egg_pre_dusk_target := 0
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
var _sweep_hit: Control = null
var _manual_button: BaseButton = null
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
var _tutorial_return_has_save := false
var _had_main_save := false
var _tutorial_focused_target: Control
var _tutorial_target_z_index := 0
var _tutorial_target_z_as_relative := true

var sfx: Node
var juice: Node
var _worlds: Array[Control] = []
var _zoom := 1.0
var _touch_pos: Dictionary = {}
var _pinch_dist := 0.0
var _pinch_mid := Vector2.ZERO
var _pinch_block_mouse := false
var _pinch_guard_until := 0
var _magnify_last := 0.0
var _mmb_pan := false
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
	_lock_web_gestures()
	hatch_sprite.texture_filter = TEXTURE_FILTER_NEAREST
	sfx = preload("res://scripts/Sfx.gd").new()
	add_child(sfx)
	juice = preload("res://scripts/Juice.gd").new()
	add_child(juice)
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
	Engine.get_singleton("JavaScriptBridge").eval(
		"(function(){var s=document.getElementById('cluck-no-select');if(!s){s=document.createElement('style');s.id='cluck-no-select';s.textContent='html,body,#canvas{height:100%!important;height:100dvh!important;width:100%!important;max-height:100dvh!important;-webkit-user-select:none!important;user-select:none!important;-webkit-touch-callout:none!important;-webkit-tap-highlight-color:transparent;touch-action:none!important;overscroll-behavior:none}#netlify-badge,.netlify-badge,a[href*=netlify]{display:none!important}';document.head.appendChild(s);}var stop=function(e){e.preventDefault();};var pinch=function(e){if(e.touches&&e.touches.length>1)e.preventDefault();};document.addEventListener('contextmenu',stop,{passive:false});document.addEventListener('selectstart',stop,{passive:false});document.addEventListener('gesturestart',stop,{passive:false});document.addEventListener('gesturechange',stop,{passive:false});document.addEventListener('gestureend',stop,{passive:false});document.addEventListener('touchmove',pinch,{passive:false});window.addEventListener('wheel',function(e){if(e.ctrlKey||e.metaKey)e.preventDefault();},{passive:false});var c=document.getElementById('canvas');if(c){c.style.touchAction='none';c.style.height='100dvh';c.addEventListener('contextmenu',stop,{passive:false});c.addEventListener('touchmove',stop,{passive:false});}})();",
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
	# Pops sit above mail/settings so those icons cannot rest on the wooden frame.
	# Mail stays at 120 so it remains above Night (100) during settlement.
	quest_pop.z_index = 124
	quest_pop.z_as_relative = false
	settings_pop.z_index = 125
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
	var toasts := get_node_or_null("Toasts") as Control
	if toasts:
		toasts.z_index = 130
		toasts.z_as_relative = false

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

func _fit_worlds() -> void:
	var sz := size
	if sz.x < 8.0:
		sz = get_viewport_rect().size
	for w in _worlds:
		w.size = sz
	_clamp_world()

func _zoom_blocked() -> bool:
	return settings_pop.visible or guide_pop.visible or quest_pop.visible or night.visible or start_menu.visible or trophy_pop.visible or _return_to_menu

func _reset_zoom() -> void:
	_zoom = 1.0
	for w in _worlds:
		w.position = Vector2.ZERO
		w.scale = Vector2.ONE

func _apply_world_pos(pos: Vector2) -> void:
	for w in _worlds:
		w.scale = Vector2(_zoom, _zoom)
		w.position = pos

func _clamp_world() -> void:
	if _worlds.is_empty():
		return
	if _zoom <= ZOOM_MIN + 0.001:
		_reset_zoom()
		return
	var min_pos := size - size * _zoom
	var p: Vector2 = _worlds[0].position
	p.x = clampf(p.x, min_pos.x, 0.0)
	p.y = clampf(p.y, min_pos.y, 0.0)
	_apply_world_pos(p)

func _zoom_at(gpos: Vector2, factor: float) -> void:
	_focus_zoom(gpos, gpos, _zoom * factor)

func _focus_zoom(from_gpos: Vector2, to_gpos: Vector2, next: float) -> void:
	if _worlds.is_empty() or not is_finite(next) or next <= 0.0:
		return
	var old := _zoom
	next = clampf(next, ZOOM_MIN, ZOOM_MAX)
	if next <= ZOOM_MIN + 0.001:
		_reset_zoom()
		return
	var w0 := _worlds[0]
	var local := (from_gpos - w0.global_position) / maxf(old, 0.001)
	_zoom = next
	_apply_world_pos(to_gpos - local * _zoom - global_position)
	_clamp_world()

func _pan_world(delta: Vector2) -> void:
	if _worlds.is_empty() or _zoom <= ZOOM_MIN + 0.001:
		return
	_apply_world_pos(_worlds[0].position + delta)
	_clamp_world()

func _pinch_points() -> PackedVector2Array:
	if _touch_pos.size() < 2:
		return PackedVector2Array()
	var ids: Array = _touch_pos.keys()
	ids.sort()
	return PackedVector2Array([_touch_pos[ids[0]], _touch_pos[ids[1]]])

func _sync_pinch_anchor() -> void:
	var pts := _pinch_points()
	if pts.size() < 2:
		_pinch_dist = 0.0
		return
	_pinch_dist = pts[0].distance_to(pts[1])
	_pinch_mid = (pts[0] + pts[1]) * 0.5

func _apply_pinch() -> void:
	var pts := _pinch_points()
	if pts.size() < 2:
		return
	var d := pts[0].distance_to(pts[1])
	var mid := (pts[0] + pts[1]) * 0.5
	if _pinch_dist > 12.0 and d > 12.0:
		var factor := d / _pinch_dist
		if factor > 0.7 and factor < 1.4:
			_focus_zoom(_pinch_mid, mid, _zoom * factor)
	_pinch_dist = d
	_pinch_mid = mid

func _cancel_press() -> void:
	if _manual_button != null:
		_manual_button.button_up.emit()
		_manual_button = null
	_holding = false
	_sweep_hit = null

func _track_touch(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			_touch_pos[event.index] = event.position
			if _touch_pos.size() == 2:
				_pinch_block_mouse = true
				_pinch_guard_until = Time.get_ticks_msec() + 400
				_cancel_press()
				_sync_pinch_anchor()
		else:
			_touch_pos.erase(event.index)
			if _touch_pos.size() < 2:
				_pinch_dist = 0.0
				if _pinch_block_mouse:
					_pinch_guard_until = Time.get_ticks_msec() + 280
	elif event is InputEventScreenDrag:
		_touch_pos[event.index] = event.position

func _mouse_blocked() -> bool:
	return _touch_pos.size() >= 2 or _pinch_block_mouse or Time.get_ticks_msec() < _pinch_guard_until

func _magnify_factor(raw: float) -> float:
	if not is_finite(raw) or raw <= 0.0:
		return 1.0
	if raw < 0.45:
		_magnify_last = 0.0
		return clampf(1.0 + raw, 0.88, 1.14)
	if raw <= 1.16:
		_magnify_last = 0.0
		return clampf(raw, 0.88, 1.14)
	if _magnify_last > 0.5:
		var inc := raw / _magnify_last
		_magnify_last = raw
		return clampf(inc, 0.88, 1.14)
	_magnify_last = raw
	return 1.0

func _hud_button_at(pos: Vector2) -> BaseButton:
	if settings_pop.visible or guide_pop.visible or quest_pop.visible or night.visible or start_menu.visible or trophy_pop.visible or _return_to_menu:
		return null
	for b in [quest_btn, get_node_or_null("HUD/SettingsBtn") as BaseButton]:
		if b != null and b.is_visible_in_tree() and not b.disabled and b.get_global_rect().grow(12.0).has_point(pos):
			return b
	return null

func _input(event: InputEvent) -> void:
	_track_touch(event)
	var pinching := _touch_pos.size() >= 2
	var mouse_blocked := _mouse_blocked()
	if pinching:
		_cancel_press()
	# Touch also creates a mouse click. Swallow the extra ScreenTouch so
	# settings (language) and other buttons do not fire twice on phones.
	if event is InputEventScreenTouch:
		var touch_pos: Vector2 = event.position
		if _hud_button_at(touch_pos) != null or _button_at(touch_pos) != null:
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if mouse_blocked:
			if not event.pressed:
				_cancel_press()
				if _touch_pos.size() < 2:
					_pinch_block_mouse = false
			get_viewport().set_input_as_handled()
		elif event.pressed:
			_manual_button = _button_at(event.global_position)
			if _manual_button != null:
				_manual_button.button_down.emit()
				get_viewport().set_input_as_handled()
		else:
			if _manual_button != null:
				var released := _manual_button
				released.button_up.emit()
				if released.is_visible_in_tree() and not released.disabled and released.get_global_rect().has_point(event.global_position):
					released.pressed.emit()
				get_viewport().set_input_as_handled()
			_manual_button = null
			_holding = false
			_sweep_hit = null
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if mouse_blocked:
			get_viewport().set_input_as_handled()
		else:
			_sweep_at(event.global_position)
	if _worlds.is_empty() or _zoom_blocked():
		if pinching:
			get_viewport().set_input_as_handled()
		return
	if pinching:
		if event is InputEventScreenDrag:
			_apply_pinch()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.global_position, pow(ZOOM_WHEEL, clampf(absf(event.factor), 0.25, 1.5)))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.global_position, 1.0 / pow(ZOOM_WHEEL, clampf(absf(event.factor), 0.25, 1.5)))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_mmb_pan = event.pressed and _zoom > ZOOM_MIN + 0.001
			if event.pressed:
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _mmb_pan:
		_pan_world(event.relative)
		get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		_zoom_at(event.position, _magnify_factor(event.factor))
		get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture and _zoom > ZOOM_MIN + 0.001:
		_pan_world(-event.delta)
		get_viewport().set_input_as_handled()

func _button_at(pos: Vector2) -> BaseButton:
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
		if b != null and b.is_visible_in_tree() and not b.disabled and b.get_global_rect().has_point(pos):
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
	if tutorial_status == "in_progress":
		_restore_settlement()
		call_deferred("_start_tutorial")
	else:
		_show_main_menu()

func _menu_holds_clock() -> bool:
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
	_sync_menu_locks()
	_set_menu_idle(true)

func _restore_menu_if_needed() -> void:
	if not _return_to_menu or tutorial_mode:
		return
	if settings_pop.visible or guide_pop.visible or trophy_pop.visible:
		return
	start_menu.visible = true
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
	var show := not _hud_chrome_blocked()
	if quest_btn:
		quest_btn.visible = show
	var settings_btn := get_node_or_null("HUD/SettingsBtn") as Control
	if settings_btn:
		settings_btn.visible = show

func _set_menu_idle(on: bool) -> void:
	if menu_backdrop:
		menu_backdrop.visible = on
	_sync_hud_chrome()
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
	_return_to_menu = false
	start_menu.visible = false
	_set_menu_idle(false)
	_start_tutorial()

func _start_menu_direct_pressed() -> void:
	_enter_play("normal")

func _start_menu_challenge_pressed() -> void:
	if not _normal_cleared:
		_toast(Loc.t("toast_lock_challenge"))
		return
	_enter_play("challenge")

func _start_menu_endless_pressed() -> void:
	if not _challenge_cleared:
		_toast(Loc.t("toast_lock_endless"))
		return
	_enter_play("endless")

func _start_menu_settings_pressed() -> void:
	_return_to_menu = true
	start_menu.visible = false
	_open_settings()

func _start_menu_trophies_pressed() -> void:
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
	_apply_locale()
	_rebuild_flock()
	_refresh()
	_save()

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
	ready_eggs = 1
	pending_eggs = maxi(0, hens - 1)
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

func _check_trophies() -> void:
	if tutorial_mode:
		return
	if birds() >= FLOCK_GOAL:
		_grant_trophy("flock")
	if birds() >= 100:
		_grant_trophy("chicken_king")
	if birds() >= 1000:
		_grant_trophy("chicken_emperor")
	var stock_gain := stock_profit()
	if stock_gain >= 2000:
		_grant_trophy("retail_not_chives")
	if stock_gain >= 3000:
		_grant_trophy("stock_god")
	if not endless_mode:
		return
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

func _fill_trophy_list() -> void:
	var rows := get_node("TrophyPop/Card/Col/List/Rows") as VBoxContainer
	for child in rows.get_children():
		rows.remove_child(child)
		child.free()
	for def in _trophy_catalog():
		rows.add_child(_make_trophy_row(def))

func _make_trophy_row(def: Dictionary) -> PanelContainer:
	var unlocked: bool = _trophies.get(str(def.id), false)
	var panel := PanelContainer.new()
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
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var title := Label.new()
	title.text = Loc.t(str(def.title))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("4b2d16") if unlocked else Color("8d7a61"))
	col.add_child(title)
	var desc := Label.new()
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
	_sync_bird_occluders()
	if _holding:
		_hold_wait -= delta
		if _hold_wait <= 0.0:
			_hold_rep -= delta
			if _hold_rep <= 0.0:
				_hold_rep = _hold_repeat_s()
				if _hold_fn.is_valid():
					if not _hold_fn.call(true):
						_holding = false
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
	if _can_drip_egg():
		if _egg_drip_gap <= 0.0:
			_egg_drip_gap = _egg_drip_wait()
		_egg_ready_acc += delta
		if _egg_ready_acc >= _egg_drip_gap:
			_egg_ready_acc = 0.0
			_egg_drip_gap = 0.0
			pending_eggs -= 1
			ready_eggs += 1
			sfx.egg_ready()
			juice.punch(egg_btn, 1.12)
			_refresh_thoughts()
	else:
		_egg_ready_acc = 0.0
		_egg_drip_gap = 0.0
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
	var total := maxi(0, hens)
	if total <= 0:
		_egg_pre_dusk_target = 0
		return
	var lo := maxi(1, int(round(float(total) * _egg_ratio_lo())))
	var hi := clampi(int(round(float(total) * _egg_ratio_hi())), lo, total)
	_egg_pre_dusk_target = randi_range(lo, hi)

func _ensure_egg_pre_dusk_target() -> void:
	if hens > 0 and _egg_pre_dusk_target <= 0:
		_roll_egg_pre_dusk_target()

func _can_drip_egg() -> bool:
	if tutorial_mode or pending_eggs <= 0 or left_ms <= _dusk_warn_ms():
		return false
	_ensure_egg_pre_dusk_target()
	return _egg_generated() < _egg_pre_dusk_target

func _egg_drip_wait() -> float:
	# More hens = more drips in the same pre-red window = shorter gaps.
	# Each gap is random, but remaining time is split so 65–75% still lands.
	_ensure_egg_pre_dusk_target()
	var left_to_drip := maxi(1, _egg_pre_dusk_target - _egg_generated())
	var window_left := maxf(0.35, (left_ms - _dusk_warn_ms()) / 1000.0)
	var base := window_left / float(left_to_drip)
	var slack := 0.06 * float(left_to_drip - 1)
	var cap := maxf(EGG_DRIP_MIN_S, window_left - slack)
	return clampf(randf_range(base * 0.45, base * 1.12), EGG_DRIP_MIN_S, cap)

func _flush_dusk_eggs() -> void:
	if pending_eggs <= 0:
		return
	var total := maxi(1, hens)
	var generated := total - pending_eggs
	var floor_n := maxi(1, ceili(float(total) * _egg_ratio_lo()))
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
	return clampi(int((day - 9) / 4), 0, 2)

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
	b.button_up.connect(func(): _holding = false)

func _bind_resource_hold(b: Button, cb: Callable) -> void:
	b.button_down.connect(func():
		# _input performs a larger, reliable hit test first. Only fall back to
		# the native Button signal when that path did not already activate it.
		if _sweep_hit != b:
			_start_hold(cb, b)
	)
	b.button_up.connect(func():
		_holding = false
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
		_holding = false
		_sweep_hit = null
		return
	if hit == _sweep_hit:
		return
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
	_style_red(get_node("SettingsPop/Card/Col/Restart"))
	get_node("SettingsPop/Card/Col/Restart").add_theme_font_size_override("font_size", 28)
	_style_beige(settings_home)
	settings_home.add_theme_font_size_override("font_size", 28)
	_style_beige(get_node("SettingsPop/Card/Col/GuideBtn"))
	get_node("SettingsPop/Card/Col/GuideBtn").add_theme_font_size_override("font_size", 28)
	_style_tag(get_node("SettingsPop/Card/Col/FontRow/Options/SmallBtn"))
	_style_tag(get_node("SettingsPop/Card/Col/FontRow/Options/NormalBtn"))
	_style_tag(get_node("SettingsPop/Card/Col/FontRow/Options/LargeBtn"))
	_style_toggle_chip(get_node("SettingsPop/Card/Col/SfxRow/SfxBtn"), sfx.sfx_on)
	_style_toggle_chip(get_node("SettingsPop/Card/Col/AmbRow/AmbBtn"), sfx.amb_on)
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
	_set_menu_icon(start_menu_settings, "res://icons/settings.png", 42)
	_set_menu_icon(start_menu_trophies, "res://icons/trophy.png", 42)
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
	bakery_upgrade.add_theme_font_size_override("font_size", 15)
	bakery_upgrade.custom_minimum_size.y = 36.0
	bakery_upgrade.autowrap_mode = TextServer.AUTOWRAP_OFF
	bakery_upgrade.clip_text = true
	_set_menu_icon(bakery_upgrade, "res://assets/ui/farm-ui/icon_coin.png", 20)
	bakery_upgrade.add_theme_constant_override("h_separation", 4)
	chick_btn.icon = load("res://icons/chick.png")
	get_node("HUD/SettingsBtn").pressed.connect(_open_settings)
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
	_bind_close_x($QuestPop/CloseBtn, quest_card, _close_quest)
	_bind_close_x($SettingsPop/CloseBtn, settings_card, _close_settings)
	$GuidePop/CloseBtn.pressed.connect(_close_guide)
	$GuidePop/Dim.gui_input.connect(_on_guide_dim_input)
	get_node("SettingsPop/Card/Col/SfxRow/SfxBtn").pressed.connect(func():
		sfx.set_sfx(not sfx.sfx_on)
		sfx.egg()
		_apply_settings_labels()
	)
	get_node("SettingsPop/Card/Col/AmbRow/AmbBtn").pressed.connect(func():
		sfx.set_amb(not sfx.amb_on)
		_apply_settings_labels()
	)
	get_node("SettingsPop/Card/Col/LangRow/Options/ZhBtn").pressed.connect(func():
		if Loc.lang != "zh":
			Loc.toggle()
			_apply_locale()
	)
	get_node("SettingsPop/Card/Col/LangRow/Options/EnBtn").pressed.connect(func():
		if Loc.lang != "en":
			Loc.toggle()
			_apply_locale()
	)
	get_node("SettingsPop/Card/Col/FontRow/Options/SmallBtn").pressed.connect(func(): _set_font_scale(0.85))
	get_node("SettingsPop/Card/Col/FontRow/Options/NormalBtn").pressed.connect(func(): _set_font_scale(1.0))
	get_node("SettingsPop/Card/Col/FontRow/Options/LargeBtn").pressed.connect(func(): _set_font_scale(1.15))
	get_node("SettingsPop/Card/Col/GuideBtn").pressed.connect(_replay_tutorial_from_settings)
	tutorial_next.pressed.connect(_tutorial_next_pressed)
	tutorial_exit.pressed.connect(func(): _leave_tutorial(false))
	get_node("SettingsPop/Card/Col/Restart").pressed.connect(_restart)
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
	$SettingsPop/Card/Col.add_theme_constant_override("separation", 14)
	$SettingsPop/Card/Col/Credits.add_theme_font_size_override("font_size", 18)
	# Keep settings within the portrait card in both languages and font scales.
	for row_name in ["SfxRow", "AmbRow", "LangRow", "FontRow"]:
		var row := settings_card.get_node("Col/" + row_name)
		for item in row.find_children("*", "Control", true, false):
			if item is Label:
				item.custom_minimum_size.x = 0.0
				item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				item.add_theme_font_size_override("font_size", 26)
				item.add_theme_color_override("font_color", Color("4e3d2c"))
			elif item is Button:
				item.clip_text = true
				item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

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
	b.add_theme_constant_override("icon_max_width", width)
	b.add_theme_constant_override("h_separation", 8)

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
	_bind_dock_button_states(b, sb)

# Wolf animal trade: tall chip, icon on top, action+price below (no letter-wrap).
func _style_wolf_trade(b: Button, is_buy: bool) -> void:
	if is_buy:
		_style_dock_green(b, 17)
	else:
		_style_dock_red(b, 17)
	var sb := b.get_theme_stylebox("normal").duplicate() as StyleBoxTexture
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	_bind_dock_button_states(b, sb)
	b.icon = load("res://icons/chick.png" if is_buy else "res://icons/hen.png")
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 34)
	b.add_theme_constant_override("h_separation", 0)
	b.autowrap_mode = TextServer.AUTOWRAP_OFF
	b.clip_text = false
	b.custom_minimum_size.y = 72.0

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
	b.clip_text = true
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

func _hold_repeat_s() -> float:
	return EGG_HOLD_REP_S if _hold_btn == egg_btn else HOLD_REP_S

func _start_hold(cb: Callable, b: BaseButton = null) -> void:
	sfx.unlock()
	_hold_fn = cb
	_hold_btn = b
	_sweep_hit = b
	_holding = true
	_hold_wait = 0.26
	_hold_rep = _hold_repeat_s()
	if b:
		juice.press(b)
	cb.call(false)

func _toast(text: String) -> void:
	var l := _label(text, 16, Color.WHITE)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color("3a2e22cc"))
	l.add_theme_constant_override("outline_size", 4)
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
	toast_box.add_child(toast_panel)
	juice.toast_in(toast_panel)
	get_tree().create_timer(2.2).timeout.connect(toast_panel.queue_free)

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

func _apply_locale() -> void:
	_apply_settings_labels()
	_apply_guide_labels()
	get_node("HUD/HudBar/CashChip/Row/CashBox/CashTitle").text = Loc.t("cash")
	get_node("HUD/HudBar/CashChip/Row/CashBox/CashTitle").visible = false
	get_node("HUD/HudBar/StockChip/Row/StockBox/StockTitle").text = Loc.t("stock")
	get_node("HUD/HudBar/StockChip/Row/StockBox/StockTitle").visible = false
	get_node("QuestPop/Card/Box/Head").text = Loc.t("quest_head")
	wolf_buy.text = Loc.t("buy_chick", [_chick_cost()])
	wolf_sell.text = Loc.t("sell_hen", [CHICK_SALE])
	share_buy.text = Loc.t("buy_share")
	share_sell.text = Loc.t("sell_share")
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
	get_node("SettingsPop/Card/Col/Title").text = Loc.t("settings")
	get_node("SettingsPop/Card/Col/SfxRow/SfxTitle").text = Loc.t("sfx_title")
	get_node("SettingsPop/Card/Col/AmbRow/AmbTitle").text = Loc.t("amb_title")
	get_node("SettingsPop/Card/Col/SfxRow/SfxBtn").text = Loc.t("toggle_on" if sfx.sfx_on else "toggle_off")
	get_node("SettingsPop/Card/Col/AmbRow/AmbBtn").text = Loc.t("toggle_on" if sfx.amb_on else "toggle_off")
	_style_toggle_chip(get_node("SettingsPop/Card/Col/SfxRow/SfxBtn"), sfx.sfx_on)
	_style_toggle_chip(get_node("SettingsPop/Card/Col/AmbRow/AmbBtn"), sfx.amb_on)
	get_node("SettingsPop/Card/Col/LangRow/LangTitle").text = Loc.t("language")
	get_node("SettingsPop/Card/Col/LangRow/Options/ZhBtn").text = "中文"
	get_node("SettingsPop/Card/Col/LangRow/Options/EnBtn").text = "English"
	_style_lang_buttons()
	get_node("SettingsPop/Card/Col/FontRow/FontTitle").text = Loc.t("font_size")
	get_node("SettingsPop/Card/Col/FontRow/Options/SmallBtn").text = Loc.t("font_small")
	get_node("SettingsPop/Card/Col/FontRow/Options/NormalBtn").text = Loc.t("font_standard")
	get_node("SettingsPop/Card/Col/FontRow/Options/LargeBtn").text = Loc.t("font_large")
	_style_font_buttons()
	get_node("SettingsPop/Card/Col/GuideBtn").text = Loc.t("tutorial_replay")
	get_node("SettingsPop/Card/Col/Help").text = Loc.t("help")
	get_node("SettingsPop/Card/Col/Restart").text = Loc.t("restart")
	settings_home.text = Loc.t("home_menu")
	var credits := get_node("SettingsPop/Card/Col/Credits") as Label
	credits.text = Loc.t("credits")
	var col := credits.get_parent()
	col.move_child(credits, col.get_child_count() - 1)
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
	juice.set_panic(hatch_btn, panic and eggs > 0 and hatching < 1 and hatched < 1)
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

func _spawn_flock() -> void:
	for c in flock_layer.get_children():
		c.queue_free()
	var grown_from := maxi(0, hens - just_grown)
	for i in hens:
		_add_one_bird("hen", i, just_grown > 0 and i >= grown_from)
	for i in young_chicks:
		_add_one_bird("young", hens + i, false)

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
	var sig := "%d:%d:%d" % [hens, young_chicks, just_grown]
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
	while have_h < hens:
		_add_one_bird("hen")
		have_h += 1
	while have_h > hens:
		_remove_one_bird("hen")
		have_h -= 1
	while have_y < young_chicks:
		_add_one_bird("young")
		have_y += 1
	while have_y > young_chicks:
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
	hatch_btn.visible = hatched < 1 and hatching < 1 and eggs > 0
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
		bakery_upgrade.text = Loc.t("oven_up", [bakery_level, bakery_level + 1, upgrade_cost])
		bakery_upgrade.disabled = coins < upgrade_cost or blocked()
		if bakery_upgrade.icon == null:
			bakery_upgrade.icon = load("res://assets/ui/farm-ui/icon_coin.png")
	wolf_buy.disabled = cash() < _chick_cost() or blocked()
	wolf_sell.disabled = hens < 1 or blocked()
	share_buy.disabled = cash() < price or blocked()
	share_sell.disabled = held() < 1 or blocked()

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
	elif not done:
		quest_stamp.visible = false
		quest_stamp.modulate.a = 0.0

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

func collect_egg(quiet := false) -> bool:
	if blocked():
		return false
	if tutorial_mode and tutorial_step != 1:
		return false
	if ready_eggs < 1:
		if not quiet:
			_toast(Loc.t("toast_eggs_done")); _deny(egg_btn)
		return false
	ready_eggs -= 1
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
		if not quiet:
			_toast(Loc.t("toast_no_chick")); _deny(chick_btn)
		return false
	hatched -= 1
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
		if not quiet:
			_toast(Loc.t("toast_hatch_once")); _deny(hatch_btn)
		return false
	if eggs < 1:
		if not quiet:
			_toast(Loc.t("toast_need_egg")); _deny(hatch_btn)
		return false
	eggs -= 1
	hatching = 1
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
		if not quiet:
			_toast(Loc.t("toast_no_cake")); _deny(cake_btn)
		return false
	cakes -= 1
	cakes_sold += 1
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
		if not quiet:
			_toast(Loc.t("toast_need_gold_share")); _deny(share_buy)
		return false
	coins -= price
	shares += 1
	stock_spent += price
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
		if not quiet:
			_toast(Loc.t("toast_no_shares")); _deny(share_sell)
		return false
	shares -= 1
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
		if not quiet:
			_toast(Loc.t("toast_need_gold_chick")); _deny(wolf_buy)
		return false
	coins -= _chick_cost()
	young_chicks += 1
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
		_toast(Loc.t("toast_oven_short", [cost - coins]))
		_deny(bakery_upgrade)
		return
	coins -= cost
	bakery_level += 1
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
		if not quiet:
			_toast(Loc.t("toast_no_hen")); _deny(wolf_sell)
		return false
	hens -= 1
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

func _next_day() -> void:
	if settling or game_result != "":
		return
	if tutorial_mode:
		# The primer is a single paused day. Never open night settlement.
		_tutorial_refresh_prompt()
		return
	settling = true
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
	if day == 8 and not endless_mode and not challenge_mode:
		var hit := closing >= WEALTH_GOAL and birds() >= FLOCK_GOAL
		if hit:
			game_result = "ended"
			_grant_trophy("day8")
			_grant_day8_ranks(closing)
			_unlock_normal()
			_fill_finale_card(closing)
		else:
			game_result = "flop"
			_fill_campaign_flop_card(closing)
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

func _on_settlement_confirm() -> void:
	if game_result != "":
		_restart()
	else:
		_wake()

func _continue_endless_from_finale() -> void:
	if game_result != "ended" or challenge_mode or endless_mode:
		return
	if not quest_complete():
		return
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

func _open_settings() -> void:
	_holding = false
	_close_quest()
	show_settings = true
	settings_pop.visible = true
	settings_home.visible = not _return_to_menu
	_sync_tutorial_layer()
	juice.pop_in(settings_card)
	_pin_close_x($SettingsPop/CloseBtn, settings_card)
	_sync_hud_chrome()

func _return_to_menu_pressed() -> void:
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
	var zh := get_node("SettingsPop/Card/Col/LangRow/Options/ZhBtn") as Button
	var en := get_node("SettingsPop/Card/Col/LangRow/Options/EnBtn") as Button
	if Loc.lang == "zh":
		_style_toggle_chip(zh, true)
		_style_toggle_chip(en, false)
	else:
		_style_toggle_chip(zh, false)
		_style_toggle_chip(en, true)
	zh.add_theme_font_size_override("font_size", 26)
	en.add_theme_font_size_override("font_size", 26)

func _style_font_buttons() -> void:
	var small := get_node("SettingsPop/Card/Col/FontRow/Options/SmallBtn") as Button
	var normal := get_node("SettingsPop/Card/Col/FontRow/Options/NormalBtn") as Button
	var large := get_node("SettingsPop/Card/Col/FontRow/Options/LargeBtn") as Button
	_style_toggle_chip(small, false)
	_style_toggle_chip(normal, false)
	_style_toggle_chip(large, false)
	if is_equal_approx(Loc.ui_font_scale, 0.85):
		_style_toggle_chip(small, true)
	elif is_equal_approx(Loc.ui_font_scale, 1.15):
		_style_toggle_chip(large, true)
	else:
		_style_toggle_chip(normal, true)
	small.add_theme_font_size_override("font_size", 24)
	normal.add_theme_font_size_override("font_size", 26)
	large.add_theme_font_size_override("font_size", 28)

func _style_toggle_chip(b: Button, on: bool) -> void:
	if on:
		b.add_theme_font_size_override("font_size", 26)
		b.add_theme_color_override("font_color", Color("fff8e8"))
		b.add_theme_color_override("font_hover_color", Color("fff8e8"))
		b.add_theme_color_override("font_pressed_color", Color("fff8e8"))
		b.add_theme_color_override("font_disabled_color", Color("fff8e888"))
		b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
		b.add_theme_constant_override("outline_size", 0)
		var sb := StyleBoxTexture.new()
		sb.texture = UiChipOn
		sb.texture_margin_left = 28.0
		sb.texture_margin_top = 18.0
		sb.texture_margin_right = 28.0
		sb.texture_margin_bottom = 18.0
		sb.content_margin_left = 14.0
		sb.content_margin_top = 8.0
		sb.content_margin_right = 14.0
		sb.content_margin_bottom = 8.0
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		UiStyle.button_states(b, sb)
	else:
		_style_tag(b)
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, 48.0)

func _style_settings_chrome() -> void:
	var flourish := get_node_or_null("SettingsPop/Card/Col/Flourish") as TextureRect
	if flourish:
		flourish.texture = UiFlourish
		flourish.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flourish.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flourish.custom_minimum_size = Vector2(0, 22)
		flourish.modulate = Color(1, 1, 1, 0.92)
	var title := get_node("SettingsPop/Card/Col/Title") as Label
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
	if quest_btn.get_global_rect().has_point(pos):
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
	_toast(Loc.t("toast_watching_ad"))
	await get_tree().create_timer(0.9).timeout
	await _rewind_to_dawn()

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
	card.show_finale({
		"kind": "win",
		"rank_lv": int(_rank_of(closing).lv),
		"rank_title": Loc.t("you_win"),
		"rank_copy": "",
		"wealth": closing,
		"birds": birds(),
		"wealth_goal": 22500,
		"flock_goal": 58,
		"quest": true,
		"cash": cash(),
		"stock": held() * maxi(1, price),
		"wealth_pts": _closing_wealth_points(closing),
		"rank_max": 12,
		"beat_text": "",
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
		"rank_max": 12,
		"beat_text": "",
	})

func _restore_settlement() -> void:
	if _return_to_menu:
		return
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
	ready_eggs = 1 if hens > 0 else 0
	pending_eggs = maxi(0, hens - 1)
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
	day_end_btn.text = Loc.t("end_day")
	await juice.dawn_out(night, card)
	settling = false
	_set_settle_chrome(false)
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
	_later(0.32, func(): juice.stamp_in(quest_stamp))
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

func _leave_tutorial(completed: bool) -> void:
	if not tutorial_mode:
		return
	var toast_key := "tutorial_complete_toast" if completed else "tutorial_exit_toast"
	if completed:
		_grant_trophy("primer")
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
		_apply_locale()
		_rebuild_flock()
		_refresh()
	else:
		# Exiting tutorial returns to the route menu without touching formal save.
		_load()
		_show_main_menu()
	_toast(Loc.t(toast_key))

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
	tutorial_step = next_step
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
	day_end_btn.text = Loc.t("end_day")
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
		"hens": hens, "youngChicks": young_chicks, "cakes": cakes, "cakesSold": cakes_sold,
		"shares": shares, "stockSpent": stock_spent, "stockSold": stock_sold,
		"price": price, "day": day, "leftMs": left_ms,
		"history": history, "wealthLog": wealth_log, "baking": baking, "bakeryLevel": bakery_level, "hatching": hatching,
		"hatched": hatched, "news": news, "seenGoal": seen_goal, "mailSeen": mail_seen, "gameResult": game_result,
		"endlessMode": endless_mode,
		"challengeMode": challenge_mode,
		"summary": summary, "dawnSnap": _dawn_snap,
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
	seen_goal = int(d.get("seenGoal", seen_goal))
	mail_seen = str(d.get("mailSeen", mail_seen))
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
