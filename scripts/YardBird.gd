@tool
class_name YardBird
extends SheetSprite

const CHICK_WALK := "res://assets/sprites/chick-walk-8.png"
const CHICK_IDLE := "res://assets/sprites/chick-idle-8.png"
const HEN_WALK := "res://assets/sprites/hen-walk-8.png"
const HEN_IDLE := "res://assets/sprites/hen-idle-8.png"
const OUTLINE_MAT := preload("res://materials/bird_outline.tres")
const GHOST_MAT := preload("res://materials/bird_ghost.tres")
const GRID := 64.0

static var occluders: Array[Rect2] = []
static var _grid_frame := -1
static var _cells: Dictionary = {}

var kind := "hen"
var feet := Vector2(50, 62)
var in_yard: Callable
var pick_spot: Callable

var _state := "idle"
var _wait := 1.2
var _target := Vector2(50, 62)
var _speed := 22.0
var _hop := 0.0
var _bump_cd := 0.0
var _idle_sheet := HEN_IDLE
var _walk_sheet := HEN_WALK
var _under_ui := false
var _layer_sz := Vector2.ZERO
var _step_acc := 0.0
var _step_span := 11.0

func _ready() -> void:
	super._ready()
	material = OUTLINE_MAT
	texture_filter = TEXTURE_FILTER_LINEAR

func setup(p_kind: String, spawn: Vector2, ok: Callable, pick: Callable) -> void:
	kind = p_kind
	feet = spawn
	in_yard = ok
	pick_spot = pick
	_speed = 20.0 if p_kind == "hen" else 28.0
	columns = 8
	rows = 1
	row = 0
	frame_count = 8
	_idle_uses_full_sheet = true
	texture_filter = TEXTURE_FILTER_LINEAR
	if p_kind == "hen":
		_idle_sheet = HEN_IDLE
		_walk_sheet = HEN_WALK
		frame_step = 0.14
	else:
		_idle_sheet = CHICK_IDLE
		_walk_sheet = CHICK_WALK
		frame_step = 0.12
	if randf() < 0.45:
		_begin_walk()
	else:
		_begin_idle()
	call_deferred("_place")

func _process(delta: float) -> void:
	super._process(delta)
	if _state == "walk":
		_step_walk(delta)
	else:
		_wait -= delta
		if _wait <= 0.0:
			if randf() < 0.34:
				_begin_idle()
			else:
				_begin_walk()
	if _state == "walk" or _hop > 0.05 or (Engine.get_process_frames() + get_index()) % 2 == 0:
		_resolve_hits()
	_bump_cd = maxf(0.0, _bump_cd - delta)
	_hop = move_toward(_hop, 0.0, 34.0 * delta)
	rotation = move_toward(rotation, 0.0, 2.2 * delta)
	_place()

func _begin_idle() -> void:
	_state = "idle"
	_frame = 0
	_acc = 0.0
	load_sheet(_idle_sheet)
	play = "loop"
	frame_step = 0.2 if kind == "hen" else 0.18
	_wait = randf_range(1.4, 4.2)
	if kind == "young":
		_wait *= 0.85

func _begin_walk() -> void:
	if not pick_spot.is_valid():
		_begin_idle()
		return
	var nxt: Vector2 = _pick_clear_spot()
	if nxt.distance_to(feet) < 3.0:
		nxt = _pick_clear_spot()
	_target = nxt
	_state = "walk"
	_frame = 0
	_acc = 0.0
	load_sheet(_walk_sheet)
	play = "loop"
	frame_step = 0.14 if kind == "hen" else 0.12

func _pick_clear_spot() -> Vector2:
	var nxt: Vector2 = pick_spot.call()
	for _i in 4:
		if not _blocked_at(nxt):
			return nxt
		nxt = pick_spot.call()
	return nxt

func _blocked_at(pct: Vector2) -> bool:
	var sz := _layer_size()
	if sz.x < 8.0:
		return false
	var pos := Vector2(sz.x * pct.x / 100.0, sz.y * pct.y / 100.0)
	var need := radius_px() + 8.0
	for other in _neighbors_at(pos):
		if pos.distance_to(other.feet_px()) < need + other.radius_px():
			return true
	return false

func _step_walk(delta: float) -> void:
	var sz := _layer_size()
	if sz.x < 8.0:
		return
	var now := Vector2(sz.x * feet.x / 100.0, sz.y * feet.y / 100.0)
	var dest := Vector2(sz.x * _target.x / 100.0, sz.y * _target.y / 100.0)
	var delta_p := dest - now
	if delta_p.length() <= 4.0:
		_begin_idle()
		return
	var step := delta_p.normalized() * _speed * delta
	if step.length() > delta_p.length():
		step = delta_p
	var nxt := now + step
	var pct := Vector2(nxt.x / sz.x * 100.0, nxt.y / sz.y * 100.0)
	if in_yard.is_valid() and not bool(in_yard.call(pct.x, pct.y)):
		_begin_idle()
		return
	feet = pct
	flip_h = delta_p.x < -0.4
	_step_acc += step.length()
	if _step_acc >= _step_span:
		_step_acc = 0.0
		_step_span = randf_range(9.5, 18.0) if kind != "hen" else randf_range(13.0, 24.0)
		Sfx.grass_step(kind != "hen", feet)

func _resolve_hits() -> void:
	var my := feet_px()
	var r := radius_px()
	for item in _neighbors_at(my):
		var other := item as YardBird
		if other == null or other.get_index() <= get_index():
			continue
		var sep: Vector2 = my - other.feet_px()
		var need: float = r + other.radius_px()
		var dist := sep.length()
		if dist < 0.4:
			sep = Vector2(randf() - 0.5, randf() - 0.5)
			dist = 0.4
		if dist >= need:
			continue
		var push: Vector2 = sep.normalized() * ((need - dist) * 0.58)
		_nudge(push)
		other._nudge(-push)
		_bump(push)
		other._bump(-push)

func _nudge(px: Vector2) -> void:
	var sz := _layer_size()
	if sz.x < 8.0:
		return
	var nxt := feet_px() + px
	var pct := Vector2(nxt.x / sz.x * 100.0, nxt.y / sz.y * 100.0)
	if in_yard.is_valid() and not bool(in_yard.call(pct.x, pct.y)):
		return
	feet = pct

func _bump(dir: Vector2) -> void:
	if _bump_cd > 0.0:
		return
	_bump_cd = 0.55
	_hop = randf_range(6.0, 11.0)
	rotation = 0.16 if dir.x >= 0.0 else -0.16
	flip_h = dir.x < 0.0
	if _state != "walk" and randf() < 0.32:
		_begin_walk()

func _place() -> void:
	var sz := _layer_size()
	if sz.x < 8.0:
		return
	pivot_offset = Vector2(size.x * 0.5, size.y * 0.82)
	position = Vector2(sz.x * feet.x / 100.0 - size.x * 0.5, sz.y * feet.y / 100.0 - size.y * 0.82 - _hop)
	z_index = clampi(int(feet.y), 0, 100)
	_sync_under_ui()

func feet_px() -> Vector2:
	var sz := _layer_size()
	return Vector2(sz.x * feet.x / 100.0, sz.y * feet.y / 100.0)

func radius_px() -> float:
	return size.x * (0.24 if kind == "hen" else 0.21)

func _layer_size() -> Vector2:
	if _layer_sz.x >= 8.0:
		return _layer_sz
	var p := get_parent() as Control
	if p and p.size.x >= 8.0:
		_layer_sz = p.size
		return _layer_sz
	return get_viewport_rect().size

func _cell_key(px: Vector2) -> Vector2i:
	return Vector2i(int(floor(px.x / GRID)), int(floor(px.y / GRID)))

func _rebuild_grid() -> void:
	var f := Engine.get_process_frames()
	if _grid_frame == f:
		return
	_grid_frame = f
	_cells.clear()
	var p := get_parent()
	if p == null:
		return
	for c in p.get_children():
		if c is YardBird and is_instance_valid(c) and not c.is_queued_for_deletion():
			var key: Vector2i = c._cell_key(c.feet_px())
			if not _cells.has(key):
				_cells[key] = []
			_cells[key].append(c)

func _neighbors_at(px: Vector2) -> Array:
	_rebuild_grid()
	var k := _cell_key(px)
	var out: Array = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var arr: Variant = _cells.get(k + Vector2i(dx, dy))
			if arr == null:
				continue
			for other in arr:
				if other != self and is_instance_valid(other):
					out.append(other)
	return out

func refresh_ghost() -> void:
	_sync_under_ui()

func _sync_under_ui() -> void:
	var hit := false
	if not occluders.is_empty():
		var gr := get_global_rect()
		for r in occluders:
			if r.intersects(gr):
				hit = true
				break
	var want: Material = GHOST_MAT if hit else OUTLINE_MAT
	if hit == _under_ui and material == want:
		return
	_under_ui = hit
	material = want
