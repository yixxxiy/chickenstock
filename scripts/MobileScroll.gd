class_name MobileScroll
extends RefCounted
## 手机网页上 ScrollContainer 经常吃不到触屏拖拽。
## Game._input 把 ScreenDrag / 鼠标拖交给这里；按手指速度放大位移，松手后惯性滑行。

const DRAG_CANCEL_PX := 48.0
## 慢拖略快于 1:1；快甩最高约 2.8×，大列表翻得动。
const GAIN_SLOW := 1.15
const GAIN_FAST := 2.6
const FAST_SPEED := 1600.0
const FLING_MIN := 420.0
const FLING_MAX := 5200.0
const FLING_FRICTION := 5.2


static func prepare(scroll: ScrollContainer, body: Control = null) -> void:
	if scroll == null:
		return
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 12
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	if body != null:
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# FILL 会把内容压进视口高度，看起来像「有内容但滑不动」。
		body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


static func drag_delta(event: InputEvent) -> float:
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).relative.y
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return 0.0
		return motion.relative.y
	return 0.0


static func finger_speed_y(event: InputEvent) -> float:
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).velocity.y
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).velocity.y
	return 0.0


static func drag_gain(speed_y: float) -> float:
	var t := clampf(absf(speed_y) / FAST_SPEED, 0.0, 1.0)
	# 平方曲线：日常慢拖仍稳，只有甩得快才明显加速。
	return lerpf(GAIN_SLOW, GAIN_FAST, t * t)


var target: ScrollContainer
var fling_v := 0.0
var _last_finger_v := 0.0


func stop_fling() -> void:
	fling_v = 0.0
	_last_finger_v = 0.0
	target = null


func try_drag(scroll: ScrollContainer, event: InputEvent, canvas_pos: Vector2) -> float:
	## 成功滚动时返回 |applied|，否则 0。
	if scroll == null or not scroll.is_visible_in_tree():
		return 0.0
	var dy := drag_delta(event)
	if absf(dy) < 0.01:
		return 0.0
	if not scroll.get_global_rect().has_point(canvas_pos):
		return 0.0
	var speed := finger_speed_y(event)
	var gain := drag_gain(speed)
	var applied := dy * gain
	var before := scroll.scroll_vertical
	scroll.scroll_vertical = before - int(round(applied))
	if scroll.scroll_vertical == before:
		return 0.0
	target = scroll
	# 与位移同号：松手后继续往同一方向滑。
	_last_finger_v = speed * gain
	fling_v = 0.0
	return absf(applied)


func release_fling() -> void:
	if target == null or not is_instance_valid(target):
		stop_fling()
		return
	if absf(_last_finger_v) < FLING_MIN:
		fling_v = 0.0
		_last_finger_v = 0.0
		return
	fling_v = clampf(_last_finger_v, -FLING_MAX, FLING_MAX)
	_last_finger_v = 0.0


func tick(delta: float) -> void:
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		stop_fling()
		return
	if absf(fling_v) < 36.0:
		fling_v = 0.0
		return
	var before := target.scroll_vertical
	target.scroll_vertical = before - int(round(fling_v * delta))
	if target.scroll_vertical == before:
		fling_v = 0.0
		return
	fling_v *= exp(-FLING_FRICTION * delta)
