extends Node

const EGG := preload("res://icons/egg.png")
const CAKE := preload("res://icons/cake.png")
const COIN := preload("res://icons/coin.png")
const CHICK := preload("res://icons/chick.png")
const ROTTEN := preload("res://icons/rotten_egg.png")

var layer: Control
var hud: Control
var egg_btn: Control
var cake_btn: Control
var hatch_btn: Control
var bakery: Control
var ticker: Control
var wolf: Control
var flock: Control
var quest_btn: Control
var day_end: Control
var chick_btn: Control

var _bobs: Dictionary = {}
var _hurry: Tween
var _hud_tw: Tween
var _flash_tw: Tween

func bind(root: Control) -> void:
	layer = root.get_node("FlyLayer")
	hud = root.get_node("HUD/HudBar")
	egg_btn = root.get_node("EggThought")
	cake_btn = root.get_node("CakeThought")
	hatch_btn = root.get_node("HatchThought")
	bakery = root.get_node("BakeryEggs")
	ticker = root.get_node("Dock/Row/Ticker/Face")
	wolf = root.get_node("WolfShop")
	flock = root.get_node("Flock")
	quest_btn = root.get_node("HUD/QuestBtn")
	day_end = root.get_node("Dock/Row/Day/TradeRow/DayEnd")
	chick_btn = root.get_node("ChickThought")
	for n in [egg_btn, cake_btn, hatch_btn, chick_btn]:
		_keep_pivot(n)
	_keep_pivot(hud)
	_keep_pivot(ticker)
	_keep_pivot(day_end)
	_keep_pivot(root.get_node("HUD/ClockBox/Clock"))
	_keep_pivot(quest_btn)
	_keep_pivot(root.get_node("Night/Card"))
	_keep_pivot(root.get_node("QuestPop/Card"))

func _keep_pivot(n: Control) -> void:
	if n == null:
		return
	var apply := func():
		if is_instance_valid(n):
			n.pivot_offset = n.size * 0.5
	n.resized.connect(apply)
	call_deferred("_pivot_now", n)

func _pivot_now(n: Control) -> void:
	if is_instance_valid(n):
		n.pivot_offset = n.size * 0.5

func _center(n: Control) -> Vector2:
	if n == null:
		return Vector2.ZERO
	return n.get_global_rect().get_center()

func _kill_meta(n: Object, key: String) -> void:
	if n.has_meta(key):
		var tw = n.get_meta(key)
		if tw is Tween and is_instance_valid(tw):
			tw.kill()
		n.remove_meta(key)

func _store(n: Object, key: String, tw: Tween) -> void:
	_kill_meta(n, key)
	n.set_meta(key, tw)

func _reset_xform(n: Control) -> void:
	_kill_meta(n, "punch")
	_kill_meta(n, "press")
	_kill_meta(n, "shake")
	n.rotation = 0.0
	n.scale = Vector2.ONE
	_pivot_now(n)

func punch(n: Control, amt := 1.12, dur := 0.28) -> void:
	if n == null:
		return
	_reset_xform(n)
	_kill_meta(n, "bob")
	var tw := create_tween()
	_store(n, "punch", tw)
	tw.tween_property(n, "scale", Vector2(amt, amt), dur * 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2.ONE, dur * 0.62).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func press(n: Control) -> void:
	if n == null:
		return
	_reset_xform(n)
	_kill_meta(n, "bob")
	var tw := create_tween()
	_store(n, "press", tw)
	# A short, readable touch response: compress, overshoot, then settle.
	tw.tween_property(n, "scale", Vector2(0.93, 0.93), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2(1.025, 1.025), 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func shake(n: Control) -> void:
	if n == null:
		return
	_reset_xform(n)
	var tw := create_tween()
	_store(n, "shake", tw)
	tw.tween_property(n, "rotation", -0.12, 0.045)
	tw.tween_property(n, "rotation", 0.12, 0.07)
	tw.tween_property(n, "rotation", -0.08, 0.06)
	tw.tween_property(n, "rotation", 0.0, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func bob(n: Control) -> void:
	if n == null:
		return
	_kill_meta(n, "bob")
	_pivot_now(n)
	var tw := create_tween().set_loops()
	_store(n, "bob", tw)
	tw.tween_property(n, "scale", Vector2(1.05, 1.05), 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
	_bobs[n] = tw

func _resume_bob(n: Control) -> void:
	if n == null or not is_instance_valid(n):
		return
	if n.get_meta("panic", false):
		return
	if n == egg_btn or n == cake_btn or n == hatch_btn or n == chick_btn:
		bob(n)

func set_panic(n: Control, on: bool) -> void:
	if n == null:
		return
	if n.get_meta("panic", false) == on:
		return
	n.set_meta("panic", on)
	_kill_meta(n, "bob")
	_kill_meta(n, "panic_tw")
	_pivot_now(n)
	if not on:
		n.rotation = 0.0
		n.scale = Vector2.ONE
		n.modulate = Color.WHITE
		if n is Button:
			_cream_thought(n)
		return
	if n is Button:
		_panic_thought(n)
	var tw := create_tween().set_loops()
	_store(n, "panic_tw", tw)
	tw.tween_property(n, "scale", Vector2(1.16, 1.16), 0.1)
	tw.parallel().tween_property(n, "rotation", 0.1, 0.1)
	tw.tween_property(n, "scale", Vector2.ONE, 0.1)
	tw.parallel().tween_property(n, "rotation", -0.09, 0.1)

func _cream_thought(b: Button) -> void:
	if b == cake_btn and b.get_node_or_null("BakeBar") and b.get_node("BakeBar").visible:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff6e6f5")
	sb.border_color = Color("c4a574")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(28)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)

func _panic_thought(b: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fde8e2f8")
	sb.border_color = Color("d56e5f")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(28)
	sb.shadow_size = 8
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)

func set_hurry(on: bool) -> void:
	if day_end == null:
		return
	if _hurry:
		_hurry.kill()
		_hurry = null
	day_end.scale = Vector2.ONE
	day_end.modulate = Color.WHITE
	if not on:
		return
	_hurry = create_tween().set_loops()
	_hurry.tween_property(day_end, "scale", Vector2(1.04, 1.06), 0.5).set_trans(Tween.TRANS_SINE)
	_hurry.parallel().tween_property(day_end, "modulate", Color("ffd8d0"), 0.5)
	_hurry.tween_property(day_end, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	_hurry.parallel().tween_property(day_end, "modulate", Color.WHITE, 0.5)

func wealth_pop(big := false) -> void:
	if hud == null:
		return
	_pivot_now(hud)
	if _hud_tw:
		_hud_tw.kill()
	_hud_tw = create_tween()
	var peak := 1.16 if big else 1.08
	_hud_tw.tween_property(hud, "scale", Vector2(peak, peak), 0.12 if big else 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hud_tw.tween_property(hud, "scale", Vector2.ONE, 0.42 if big else 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func flash_ticker(up: bool, big := false) -> void:
	if ticker == null:
		return
	if _flash_tw:
		_flash_tw.kill()
	var glow := Color("d8f3d8") if up else Color("f8d8d4")
	_flash_tw = create_tween()
	ticker.modulate = glow
	_flash_tw.tween_property(ticker, "modulate", Color.WHITE, 0.86 if big else 0.52)
	_pivot_now(ticker)
	if big:
		var extra := create_tween()
		extra.tween_property(ticker, "scale", Vector2(1.08, 1.08), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		extra.tween_property(ticker, "scale", Vector2.ONE, 0.4)

func pop_in(n: Control, animate_scale := true) -> void:
	if n == null:
		return
	_pivot_now(n)
	n.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(n, "modulate:a", 1.0, 0.18)
	if animate_scale:
		n.scale = Vector2(0.86, 0.86)
		tw.parallel().tween_property(n, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		# Settlement: fade only so mail/gear chrome stay visually pinned.
		n.scale = Vector2.ONE

func toast_in(n: Control) -> void:
	n.modulate.a = 0.0
	n.scale = Vector2(0.85, 0.85)
	n.pivot_offset = n.size * 0.5
	var tw := create_tween()
	tw.tween_property(n, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(n, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func night_in(veil: Control, card: Control) -> void:
	veil.visible = true
	veil.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(veil, "modulate:a", 1.0, 0.45)
	if card:
		card.visible = true
		_pivot_now(card)
		card.scale = Vector2(0.92, 0.92)
		card.modulate.a = 0.0
		tw.parallel().tween_property(card, "modulate:a", 1.0, 0.28).set_delay(0.12)
		tw.parallel().tween_property(card, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.12)

func dawn_out(veil: Control, card: Control) -> void:
	var tw := create_tween()
	if card:
		tw.tween_property(card, "modulate:a", 0.0, 0.2)
		tw.parallel().tween_property(card, "scale", Vector2(0.96, 0.96), 0.2)
	tw.tween_property(veil, "modulate:a", 0.0, 0.55)
	await tw.finished
	veil.visible = false
	if card:
		card.visible = false
		card.scale = Vector2.ONE
		card.modulate.a = 1.0
	veil.modulate.a = 1.0

func celebrate(n: Control) -> void:
	if n == null:
		return
	_pivot_now(n)
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2(1.34, 1.34), 0.18).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(n, "rotation", -0.05, 0.18)
	tw.tween_property(n, "scale", Vector2(1.22, 1.22), 0.16)
	tw.parallel().tween_property(n, "rotation", 0.035, 0.16)
	tw.tween_property(n, "scale", Vector2(1.16, 1.16), 0.22)
	tw.parallel().tween_property(n, "rotation", 0.0, 0.22)
	await get_tree().create_timer(3.2).timeout
	if is_instance_valid(n):
		var back := create_tween()
		back.tween_property(n, "scale", Vector2.ONE, 0.28)

func stamp_in(n: Control) -> void:
	if n == null:
		return
	n.visible = true
	_pivot_now(n)
	n.rotation = -0.58
	n.scale = Vector2(2.35, 2.35)
	n.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(n, "modulate:a", 1.0, 0.06)
	tw.parallel().tween_property(n, "scale", Vector2(0.9, 0.9), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(n, "rotation", -0.22, 0.22)
	tw.tween_property(n, "scale", Vector2(1.1, 1.1), 0.1)
	tw.tween_property(n, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func grown(n: Control) -> void:
	await get_tree().process_frame
	if n == null or not is_instance_valid(n):
		return
	_pivot_now(n)
	n.scale = Vector2(0.48, 0.48)
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2(1.2, 1.2), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func fly(kind: String) -> void:
	match kind:
		"egg":
			_icon(EGG, _center(egg_btn), _center(bakery) + Vector2(24, 0), 0.65, 12.0, 28.0)
		"hatch":
			# The spent egg travels from the coop bubble into the incubator.
			_icon(EGG, _center(egg_btn), _center(hatch_btn), 0.48, -10.0, 34.0)
		"cake":
			_icon(CAKE, _center(cake_btn), _center(ticker), 0.65, 30.0, 40.0)
		"payout":
			_text("+150", _center(cake_btn), _center(hud), Color("3f8a52"), 0.72)
		"coin":
			_icon(COIN, _center(ticker), _center(hud), 0.7, 8.0, 90.0)
		"coin_wolf":
			_icon(COIN, _center(wolf), _center(hud), 0.7, 10.0, 80.0)
		"spend":
			_icon(COIN, _center(hud), _center(ticker), 0.55, -6.0, 20.0)
		"spend_wolf":
			_icon(COIN, _center(hud), _center(wolf), 0.55, -8.0, 24.0)
		"chick":
			_icon(CHICK, _center(hatch_btn), _flock_land(), 0.7, 16.0, 50.0)
		"chick_wolf":
			_icon(CHICK, _center(wolf), _flock_land(), 0.7, 14.0, 46.0)

func spoil(at: String, count: int) -> void:
	var from := _center(egg_btn)
	if at == "bakery":
		from = _center(bakery)
	elif at == "hatch":
		from = _center(hatch_btn)
	for i in mini(count, 8):
		var idx := i
		var origin := from
		get_tree().create_timer(idx * 0.08).timeout.connect(func():
			var jitter := origin + Vector2(randf_range(-18, 18), randf_range(-10, 10))
			_icon(ROTTEN, jitter, jitter + Vector2(randf_range(-20, 28), 110), 1.1, 70.0, 16.0)
		)

func burst(count := 22) -> void:
	var sz := layer.size if layer.size.x > 8.0 else Vector2(576, 1024)
	for i in count:
		var idx := i
		get_tree().create_timer(idx * 0.055).timeout.connect(func():
			var p := Vector2(sz.x * randf_range(0.08, 0.92), sz.y * randf_range(0.08, 0.62))
			var tex := CHICK if idx % 3 == 0 else COIN
			_icon(tex, p, p + Vector2(randf_range(-40, 40), sz.y * 0.42), 1.35, randf_range(-40, 40), 0.0, 0.25)
		)

func _flock_land() -> Vector2:
	var r := flock.get_global_rect() if flock else Rect2()
	if r.size.x < 8.0:
		return Vector2(180, 620)
	return Vector2(r.position.x + r.size.x * 0.42, r.position.y + r.size.y * 0.64)

func _icon(tex: Texture2D, from: Vector2, to: Vector2, dur: float, spin: float, arc: float, start_scale := 1.0) -> void:
	if layer == null or tex == null:
		return
	var n := TextureRect.new()
	n.texture = tex
	n.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	n.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.size = Vector2(44, 44)
	n.pivot_offset = Vector2(22, 22)
	n.scale = Vector2(start_scale, start_scale)
	layer.add_child(n)
	n.global_position = from - n.pivot_offset
	_arc(n, from, to, dur, spin, arc)

func _text(copy: String, from: Vector2, to: Vector2, color: Color, dur: float) -> void:
	if layer == null:
		return
	var n := Label.new()
	n.text = copy
	n.add_theme_font_size_override("font_size", 40)
	n.add_theme_color_override("font_color", color)
	n.add_theme_color_override("font_outline_color", Color("fff8e8ee"))
	n.add_theme_constant_override("outline_size", 5)
	n.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.7))
	n.add_theme_constant_override("shadow_offset_x", 0)
	n.add_theme_constant_override("shadow_offset_y", 1)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.size = Vector2(96, 32)
	n.pivot_offset = n.size * 0.5
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(n)
	n.global_position = from - n.pivot_offset
	_arc(n, from, to, dur, 0.0, 36.0)

func _arc(n: Control, from: Vector2, to: Vector2, dur: float, spin: float, arc: float) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(u: float):
		if not is_instance_valid(n):
			return
		var p := from.lerp(to, u)
		p.y -= sin(u * PI) * arc
		n.global_position = p - n.pivot_offset
		n.rotation_degrees = spin * u
	, 0.0, 1.0, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(n, "scale", Vector2(0.22, 0.22), dur).set_delay(dur * 0.35)
	tw.tween_property(n, "modulate:a", 0.0, dur * 0.35).set_delay(dur * 0.65)
	tw.chain().tween_callback(n.queue_free)
