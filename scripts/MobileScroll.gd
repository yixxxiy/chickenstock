class_name MobileScroll
extends RefCounted
## 手机网页上 ScrollContainer 经常吃不到触屏拖拽。
## 由 Game._input 把 ScreenDrag / 鼠标拖交给这里，直接改 scroll_vertical。

const DRAG_CANCEL_PX := 10.0


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


static func try_drag(scroll: ScrollContainer, event: InputEvent, canvas_pos: Vector2) -> float:
	## 成功滚动时返回 |dy|，否则 0。调用方用它决定是否取消已按下的按钮。
	if scroll == null or not scroll.is_visible_in_tree():
		return 0.0
	var dy := drag_delta(event)
	if absf(dy) < 0.01:
		return 0.0
	if not scroll.get_global_rect().has_point(canvas_pos):
		return 0.0
	var before := scroll.scroll_vertical
	scroll.scroll_vertical = before - int(dy)
	if scroll.scroll_vertical == before:
		return 0.0
	return absf(dy)
