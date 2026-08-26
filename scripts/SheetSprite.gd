@tool
class_name SheetSprite
extends TextureRect

@export var row := 0
@export var play := "loop"
@export_file("*.png") var sheet_path := "res://assets/sprites/farm-sheet-8x5.png"
@export_range(1, 64, 1) var columns := 8
@export_range(1, 64, 1) var rows := 5
@export_range(1, 64, 1) var frame_count := 8
@export_range(0.01, 2.0, 0.01) var frame_step := 0.12

var _atlas := AtlasTexture.new()
var _frame := 0
var _acc := 0.0
var _fw := 1.0
var _fh := 1.0
var _sheet: Texture2D
var _idle_uses_full_sheet := false
static var _sheet_cache: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_init_sheet()

func load_sheet(path: String, p_columns := 8, p_rows := 1, p_count := 8) -> void:
	sheet_path = path
	columns = p_columns
	rows = p_rows
	frame_count = p_count
	row = 0
	_frame = 0
	_acc = 0.0
	_init_sheet()

func _init_sheet() -> void:
	if sheet_path.is_empty():
		return
	if _sheet_cache.has(sheet_path):
		_sheet = _sheet_cache[sheet_path]
	else:
		_sheet = load(sheet_path)
		if _sheet:
			_sheet_cache[sheet_path] = _sheet
	if _sheet == null:
		return
	_fw = _sheet.get_width() / float(columns)
	_fh = _sheet.get_height() / float(rows)
	_atlas.atlas = _sheet
	_atlas.filter_clip = true
	texture = _atlas
	_apply()

func _process(delta: float) -> void:
	if _sheet == null:
		return
	var step := frame_step
	var frames := frame_count
	if play == "warm":
		step = 0.8
		frames = 2
	elif play == "idle":
		if _idle_uses_full_sheet:
			step = frame_step
			frames = frame_count
		else:
			step = 0.62
			frames = 2
	elif play == "once":
		step = 0.14
		frames = frame_count
	elif play == "hold":
		_frame = 0
		_apply()
		return
	_acc += delta
	if _acc < step:
		return
	_acc = 0.0
	if play == "once":
		_frame = mini(_frame + 1, frames - 1)
	else:
		_frame = (_frame + 1) % frames
	_apply()

func _apply() -> void:
	_atlas.region = Rect2(_frame * _fw, row * _fh, _fw, _fh)
	queue_redraw()

func start_once() -> void:
	play = "once"
	_frame = 0
	_acc = 0.0
	_apply()
