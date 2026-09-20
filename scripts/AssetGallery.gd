@tool
extends Control

@export_range(96, 320, 8) var preview_size := 176:
	set(value):
		preview_size = value
		if is_inside_tree():
			call_deferred("_rebuild")
@export_range(2, 8, 1) var columns := 4:
	set(value):
		columns = value
		if is_inside_tree():
			call_deferred("_rebuild")
@export var background_color := Color("#d9d4c8"):
	set(value):
		background_color = value
		if is_inside_tree():
			call_deferred("_rebuild")

var _animated_previews: Array[Dictionary] = []
var _animation_time := 0.0


func _ready() -> void:
	_rebuild()


func _process(delta: float) -> void:
	_animation_time += delta
	for item in _animated_previews:
		var atlas := item["atlas"] as AtlasTexture
		var frame_count := int(item["frames"])
		var fps := float(item["fps"])
		var frame := int(_animation_time * fps) % frame_count
		var region := atlas.region
		region.position.x = frame * region.size.x
		atlas.region = region


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_animated_previews.clear()
	
	var background := ColorRect.new()
	background.color = background_color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	
	var page := VBoxContainer.new()
	page.custom_minimum_size = Vector2(0, 1000)
	page.add_theme_constant_override("separation", 18)
	scroll.add_child(page)
	MobileScroll.prepare(scroll, page)
	
	var title := Label.new()
	title.text = "小鸡股市 · 美术资产总览"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	page.add_child(title)
	
	var hint := Label.new()
	hint.text = "自动读取 res://assets ｜ 打开此场景即可集中检查尺寸、透明区域和整体画风"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color("#655f55")
	page.add_child(hint)
	
	_add_wolf_animation_preview(page)
	_add_category(page, "角色与逐帧动画", "res://assets/sprites")
	_add_category(page, "地图与建筑", "res://assets/map")
	_add_category(page, "界面素材", "res://assets/ui")


func _add_wolf_animation_preview(page: VBoxContainer) -> void:
	var path := "res://assets/sprites/wolf-hen-idle-6x1.png"
	if not ResourceLoader.exists(path):
		return
	_add_section_title(page, "动画播放预览")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_child(row)
	var card := _make_card_shell("wolf-hen-idle · 6 FPS 循环")
	row.add_child(card)
	var texture_rect := card.get_node("Content/Preview") as TextureRect
	var source := load(path) as Texture2D
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(0, 0, source.get_width() / 6.0, source.get_height())
	texture_rect.texture = atlas
	_animated_previews.append({"atlas": atlas, "frames": 6, "fps": 6.0})


func _add_category(page: VBoxContainer, heading: String, directory: String) -> void:
	var paths := _png_paths(directory)
	if paths.is_empty():
		return
	_add_section_title(page, "%s（%d）" % [heading, paths.size()])
	var grid := GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	page.add_child(grid)
	for path in paths:
		var card := _make_card_shell(path.get_file())
		var texture_rect := card.get_node("Content/Preview") as TextureRect
		texture_rect.texture = load(path)
		texture_rect.tooltip_text = path
		grid.add_child(card)


func _make_card_shell(label_text: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(preview_size + 28, preview_size + 66)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 8)
	card.add_child(content)
	var preview := TextureRect.new()
	preview.name = "Preview"
	preview.custom_minimum_size = Vector2(preview_size, preview_size)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	content.add_child(preview)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = label_text
	content.add_child(label)
	return card


func _add_section_title(page: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("#453e34"))
	page.add_child(label)


func _png_paths(directory: String) -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(directory)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
			result.append(directory.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result
