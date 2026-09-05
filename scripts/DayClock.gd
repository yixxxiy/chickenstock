@tool
class_name DayClock
extends Control

const FACE := preload("res://assets/ui/clock-face.png")
const HAND := preload("res://assets/ui/clock-hour-hand.png")
const PIE_FRAC := 0.57
const HAND_FRAC := 0.62

var elapsed := 0.0
var hurry := false
var _shown := 0.0
var _face: TextureRect
var _pie: ElapsedPie
var _hand: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_parts()
	if not resized.is_connected(_layout):
		resized.connect(_layout)
	_layout()
	_apply()

func _ensure_parts() -> void:
	_face = get_node_or_null("Face") as TextureRect
	if _face == null:
		_face = TextureRect.new()
		_face.name = "Face"
		add_child(_face)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _face.texture == null:
		_face.texture = FACE

	_pie = get_node_or_null("Elapsed") as ElapsedPie
	if _pie == null:
		_pie = ElapsedPie.new()
		_pie.name = "Elapsed"
		add_child(_pie)
	_pie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _pie.material == null:
		var add_mat := CanvasItemMaterial.new()
		add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_pie.material = add_mat

	_hand = get_node_or_null("Hand") as TextureRect
	if _hand == null:
		_hand = TextureRect.new()
		_hand.name = "Hand"
		add_child(_hand)
	_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if _hand.texture == null:
		_hand.texture = HAND

func set_elapsed(amount: float, is_hurry := false) -> void:
	elapsed = clampf(amount, 0.0, 1.0)
	hurry = is_hurry

func _layout() -> void:
	if _pie == null or _hand == null or size.x < 1.0 or size.y < 1.0:
		return
	pivot_offset = size * 0.5
	var side := minf(size.x, size.y)
	var pie_s := side * PIE_FRAC
	_pie.size = Vector2(pie_s, pie_s)
	_pie.position = (size - _pie.size) * 0.5
	var hand_s := side * HAND_FRAC
	_hand.size = Vector2(hand_s, hand_s)
	_hand.position = (size - _hand.size) * 0.5
	_hand.pivot_offset = _hand.size * 0.5

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if _face == null or _hand == null:
			_ensure_parts()
		_layout()
		return
	if absf(elapsed - _shown) > 0.5:
		_shown = elapsed
	else:
		_shown = lerpf(_shown, elapsed, 1.0 - exp(-16.0 * delta))
	_apply()

func _apply() -> void:
	if _pie == null or _hand == null:
		return
	var t := Time.get_ticks_msec() * 0.001
	_pie.progress = _shown
	_pie.hurry = hurry
	_pie.pulse = 0.55 + 0.45 * sin(t * 6.0) if hurry else 0.28 + 0.12 * sin(t * 1.6)
	_pie.queue_redraw()
	_hand.rotation = _shown * TAU


class ElapsedPie extends Control:
	var progress := 0.0
	var hurry := false
	var pulse := 0.0

	func _draw() -> void:
		if progress <= 0.002:
			return
		var center := size * 0.5
		var radius := minf(center.x, center.y)
		if radius < 2.0:
			return
		var glow := 0.72 + 0.28 * pulse
		var fill := Color(0.55, 0.40, 0.12, 1.0) * glow if not hurry else Color(0.70, 0.28, 0.08, 1.0) * glow
		fill.a = 1.0
		var sheen := Color(0.42, 0.36, 0.22, 1.0) * (0.45 + 0.25 * pulse)
		sheen.a = 1.0
		var rim := Color(0.85, 0.72, 0.32, 1.0) * (0.55 + 0.35 * pulse)
		rim.a = 1.0
		var from := -PI * 0.5
		var span := clampf(progress, 0.0, 1.0) * TAU
		if span >= TAU - 0.02:
			draw_circle(center, radius, fill)
			draw_circle(center, radius * 0.62, sheen)
			draw_arc(center, radius * 0.97, from, from + TAU, 48, rim, 2.2, true)
			return
		var segs := clampi(int(ceili(progress * 48.0)), 3, 48)
		for i in segs:
			var a0 := from + span * float(i) / float(segs)
			var a1 := from + span * float(i + 1) / float(segs)
			var p0 := center + Vector2.from_angle(a0) * radius
			var p1 := center + Vector2.from_angle(a1) * radius
			if absf((p0 - center).cross(p1 - center)) < 0.75:
				continue
			draw_colored_polygon(PackedVector2Array([center, p0, p1]), fill)
			var q0 := center + Vector2.from_angle(a0) * radius * 0.62
			var q1 := center + Vector2.from_angle(a1) * radius * 0.62
			if absf((q0 - center).cross(q1 - center)) >= 0.75:
				draw_colored_polygon(PackedVector2Array([center, q0, q1]), sheen)
		draw_arc(center, radius * 0.97, from, from + span, segs, rim, 2.2, true)
