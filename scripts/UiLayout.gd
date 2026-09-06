extends RefCounted

# Presentation only: all existing controls, signals, text and game state stay owned
# by Game. Coordinates are relative to the 576 x 1024 portrait canvas.
const PANEL := preload("res://assets/ui/farm-ui/simple-ui/panel.png")
const INK := Color("4e3522")
const MUTED := Color("80664b")
static var _kit_cache: Dictionary = {}

static func kit_tex(path: String) -> Texture2D:
	if _kit_cache.has(path):
		return _kit_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null:
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_path):
			var img := Image.load_from_file(abs_path)
			if img != null and not img.is_empty():
				tex = ImageTexture.create_from_image(img)
	_kit_cache[path] = tex
	return tex

static func rect(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.anchor_left = x
	node.anchor_top = y
	node.anchor_right = x + w
	node.anchor_bottom = y + h
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0

static func font(node: Control, points: int) -> void:
	node.add_theme_font_size_override("font_size", points)
	if node is Label:
		node.add_theme_color_override("font_color", INK)
	node.add_theme_constant_override("outline_size", 0)

static func surface(node: Control, padding := 22.0) -> void:
	var box := StyleBoxTexture.new()
	box.texture = PANEL
	box.texture_margin_left = 48
	box.texture_margin_right = 48
	box.texture_margin_top = 48
	box.texture_margin_bottom = 48
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	node.add_theme_stylebox_override("panel", box)

static func apply(game: Control) -> void:
	# HUD / wolf / dock positions live in Game.tscn for manual editor tuning.
	_menu(game)
	_farm(game)
	_dialogs(game)
	_tutorial(game)
	var follow := CloseFollow.new()
	follow.game = game
	game.add_child(follow)

static func _hud(game: Control) -> void:
	pass

static func _menu(game: Control) -> void:
	var card := game.get_node("StartMenuLayer/Card") as Control
	rect(card, 0.17, 0.08, 0.66, 0.67)
	var box := card.get_node("Box") as Control
	rect(box, 0, 0, 1, 1)
	var paper := Panel.new()
	paper.name = "MenuSurface"
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(paper)
	box.move_child(paper, 0)
	rect(paper, 0, 0.35, 1, 0.65)
	surface(paper)
	for name in ["LogoIcon", "LogoWordmark"]:
		box.get_node(name).custom_minimum_size = Vector2.ZERO
	rect(box.get_node("LogoIcon"), 0.28, -0.02, 0.44, 0.24)
	rect(box.get_node("LogoWordmark"), 0.04, 0.22, 0.92, 0.16)
	box.get_node("Subtitle").hide()
	for spec in [["Direct", 0.40, 0.11], ["Tutorial", 0.515, 0.095], ["Challenge", 0.615, 0.095], ["Endless", 0.715, 0.095]]:
		var button := box.get_node(spec[0]) as Button
		rect(button, 0.07, spec[1], 0.86, spec[2])
		font(button, 30 if spec[0] == "Direct" else 27)
		button.clip_text = true
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for spec in [["Settings", 0.07], ["Trophies", 0.515]]:
		var button := box.get_node(spec[0]) as Button
		rect(button, spec[1], 0.855, 0.415, 0.105)
		font(button, 24)
		button.clip_text = true
		button.add_theme_constant_override("icon_max_width", 42)
		button.add_theme_constant_override("h_separation", 10)

static func _farm(game: Control) -> void:
	# WolfShop + buy/sell live in Game.tscn — do not rewrite those anchors.
	# Building hit targets / thoughts still laid out here until baked.
	rect(game.get_node("EggThought"), 0.16, 0.25, 0.13, 0.065)
	rect(game.get_node("CakeThought"), 0.80, 0.29, 0.13, 0.065)
	var cake := game.get_node("CakeThought") as Control
	cake.anchor_bottom = cake.anchor_top
	cake.offset_bottom = 64
	rect(game.get_node("BakeryUpgrade"), 0.70, 0.355, 0.24, 0.042)
	font(game.get_node("BakeryUpgrade"), 15)
	compact_button(game.get_node("BakeryUpgrade"))
	game.get_node("BakeryUpgrade").autowrap_mode = TextServer.AUTOWRAP_OFF
	game.get_node("BakeryUpgrade").clip_text = true
	game.get_node("BakeryUpgrade").add_theme_constant_override("icon_max_width", 20)
	rect(game.get_node("BakeryEggs"), 0.68, 0.49, 0.28, 0.03)
	font(game.get_node("BakeryEggs"), 23)
	for name in ["HatchThought", "ChickThought"]:
		rect(game.get_node(name), 0.70, 0.58, 0.12, 0.065)
	rect(game.get_node("HatchEgg"), 0.70, 0.62, 0.15, 0.10)
	var toast := game.get_node("Toasts") as Control
	rect(toast, 0.12, 0.175, 0.76, 0.08)
	rect(game.get_node("Night/Moon"), 0.045, 0.02, 0.18, 0.11)

static func compact_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := button.get_theme_stylebox(state).duplicate() as StyleBoxTexture
		box.content_margin_left = 8
		box.content_margin_right = 8
		button.add_theme_stylebox_override(state, box)
	button.set_meta("ui_normal_surface", button.get_theme_stylebox("normal"))
	button.set_meta("ui_hover_surface", button.get_theme_stylebox("hover"))

static func dock(game: Control) -> void:
	# Dock layout authored in Game.tscn: wide chart on top,
	# buy / sell / end-day as one thick action row below.
	var face := game.get_node("Dock/Row/Ticker/Face") as Control
	face.get_node("Col/PriceCap").visible = false
	face.get_node("Col/HoldHint").visible = false

static func _dialogs(game: Control) -> void:
	# Settings card: narrower portrait like the redesign mock.
	var settings_card := game.get_node("SettingsPop/Card") as Control
	rect(settings_card, 0.14, 0.08, 0.72, 0.82)
	surface(settings_card, 24)
	var trophy_card := game.get_node("TrophyPop/Card") as Control
	rect(trophy_card, 0.07, 0.15, 0.86, 0.76)
	surface(trophy_card, 26)
	var quest := game.get_node("QuestPop/Card") as Control
	rect(quest, 0.07, 0.17, 0.86, 0.65)
	surface(quest, 26)
	font(quest.get_node("Box/Head"), 39)
	font(quest.get_node("Box/QuestTitle"), 23)
	font(quest.get_node("Box/QuestNews"), 23)
	quest.get_node("Box/QuestNews").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	font(quest.get_node("Box/QuestNote"), 21)
	for name in ["WealthCard", "FlockCard"]:
		var metric := quest.get_node("Box/" + name)
		metric.get_node("Row/Icon").custom_minimum_size = Vector2(58, 58)
		var top := metric.get_node("Row/Col/Top")
		for item in top.get_children():
			font(item, 31 if item.name.begins_with("Quest") else 21)
		font(metric.get_node("Row/Col/Hint"), 21)
		metric.get_node("Row/Col/Track").custom_minimum_size.y = 12
	var settings := game.get_node("SettingsPop/Card/Col")
	settings.add_theme_constant_override("separation", 14)
	font(settings.get_node("Title"), 40)
	settings.get_node("Title").add_theme_color_override("font_color", INK)
	for path in ["SfxRow/SfxTitle", "AmbRow/AmbTitle", "LangRow/LangTitle", "FontRow/FontTitle"]:
		font(settings.get_node(path), 26)
	for path in ["SfxRow/SfxBtn", "AmbRow/AmbBtn"]:
		var chip := settings.get_node(path) as Button
		font(chip, 26)
		chip.custom_minimum_size = Vector2(96, 48)
		chip.clip_text = true
	for name in ["GuideBtn", "HomeBtn", "Restart"]:
		var button := settings.get_node(name) as Button
		font(button, 28)
		button.custom_minimum_size.y = 56
		button.clip_text = true
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	font(settings.get_node("Credits"), 17)
	font(game.get_node("TrophyPop/Card/Col/Title"), 38)
	game.get_node("TrophyPop/Card/Col/List/Rows").add_theme_constant_override("separation", 2)

static func _tutorial(game: Control) -> void:
	rect(game.get_node("TutorialLayer"), 0, 0, 1, 1)
	font(game.get_node("TutorialLayer/Card/Box/Title"), 29)
	font(game.get_node("TutorialLayer/Card/Box/Body"), 23)
	var exit_btn := game.get_node("TutorialLayer/Card/Box/Actions/Exit") as Button
	exit_btn.visible = false
	var spacer := game.get_node_or_null("TutorialLayer/Card/Box/Actions/Spacer") as Control
	if spacer:
		spacer.visible = false
	var next_btn := game.get_node("TutorialLayer/Card/Box/Actions/Next") as Button
	font(next_btn, 22)
	next_btn.clip_text = true
	next_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial(game, null)

static func tutorial(game: Control, target: Control) -> void:
	var low_target := target != null and target.get_global_rect().get_center().y > game.size.y * 0.45
	var y := 0.18 if low_target else 0.48
	rect(game.get_node("TutorialLayer/Card"), 0.19, y, 0.75, 0.26)
	var tutor := game.get_node("TutorialLayer/TutorWolf") as Control
	tutor.scale = Vector2.ONE
	rect(tutor, -0.06, y - 0.01, 0.28, 0.23)

class CloseFollow extends Node:
	var game: Control
	func _process(_delta: float) -> void:
		for path in ["SettingsPop", "QuestPop", "TrophyPop"]:
			var pop := game.get_node(path) as Control
			if pop.is_visible_in_tree():
				var bounds := (pop.get_node("Card") as Control).get_global_rect()
				(pop.get_node("CloseBtn") as Control).global_position = bounds.position + Vector2(bounds.size.x - 62, 10)

static func report(card: Control) -> void:
	_paint_report_surfaces(card)
	var body := card.get_node("CardBody") as NinePatchRect
	body.texture = kit_tex("res://assets/ui/settlement/kit/01-panel-tall-modal.png")
	body.patch_margin_left = 48
	body.patch_margin_right = 48
	body.patch_margin_top = 48
	body.patch_margin_bottom = 48
	var daily := card.get_node("Daily") as VBoxContainer
	rect(daily, 0.10, 0.06, 0.80, 0.88)
	daily.alignment = BoxContainer.ALIGNMENT_CENTER
	daily.add_theme_constant_override("separation", 8)
	daily.get_node("Kicker").hide()
	daily.get_node("RuleA").hide()
	daily.get_node("StatsCap").hide()
	_title_row(daily)
	font(daily.get_node("DayLine"), 17)
	daily.get_node("DayLine").add_theme_color_override("font_color", MUTED)
	daily.get_node("DayLine").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var news := daily.get_node("NewsChip") as Control
	news.custom_minimum_size.y = 42
	daily.get_node("NewsChip/Row").alignment = BoxContainer.ALIGNMENT_CENTER
	daily.get_node("NewsChip/Row").add_theme_constant_override("separation", 8)
	var weather := daily.get_node("NewsChip/Row/Weather") as TextureRect
	weather.custom_minimum_size = Vector2(34, 34)
	weather.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weather.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	font(daily.get_node("NewsChip/Row/Txt"), 18)
	_price_hero(daily)
	_ensure_hairline(daily, "RulePrice", daily.get_node("PriceWell"))
	_ledger_cells(daily)
	_ensure_hairline(daily, "RuleLedger", daily.get_node("Ledger"))
	var foot := daily.get_node("Footnote") as Control
	foot.custom_minimum_size.y = 24
	daily.get_node("Footnote/Row").alignment = BoxContainer.ALIGNMENT_CENTER
	daily.get_node("Footnote/Row/Icon").hide()
	font(daily.get_node("Footnote/Row/Txt"), 20)
	daily.get_node("Footnote/Row/Txt").add_theme_color_override("font_color", INK)
	daily.get_node("Footnote/Row/Txt").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	daily.get_node("HatchNote").alignment = BoxContainer.ALIGNMENT_CENTER
	daily.get_node("HatchNote").add_theme_constant_override("separation", 0)
	daily.get_node("HatchNote/Icon").hide()
	font(daily.get_node("HatchNote/Txt"), 16)
	daily.get_node("HatchNote/Txt").add_theme_color_override("font_color", MUTED)
	daily.get_node("HatchNote/Txt").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	font(daily.get_node("BeatLine"), 13)
	daily.get_node("BeatLine").add_theme_color_override("font_color", MUTED)
	daily.get_node("BeatLine").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Match reference order: wealth → hatch → beat → actions
	daily.move_child(daily.get_node("HatchNote"), daily.get_node("Footnote").get_index() + 1)
	daily.move_child(daily.get_node("BeatLine"), daily.get_node("HatchNote").get_index() + 1)
	var actions := daily.get_node("Actions") as VBoxContainer
	actions.move_child(actions.get_node("Cta"), 0)
	actions.add_theme_constant_override("separation", 10)
	for child in actions.get_children():
		child.custom_minimum_size.y = 64
		(child as Button).clip_text = true
		(child as Button).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_finale_report(card)

static func _paint_report_surfaces(card: Control) -> void:
	# Reference is parchment-first: soft news chip, open price, plain wealth, no wood bars.
	_surface_chip(card.get_node("Daily/NewsChip"))
	card.get_node("Daily/PriceWell").add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	card.get_node("Daily/Footnote").add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	card.get_node("Daily/Ledger").add_theme_stylebox_override("panel", StyleBoxEmpty.new())

static func _surface_chip(node: Control) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("f0e2c4")
	box.border_color = Color("7a5a3c")
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	node.add_theme_stylebox_override("panel", box)

static func _surface_cell(node: Control) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("f6ebcf")
	box.border_color = Color("6e4f35")
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	box.content_margin_left = 4
	box.content_margin_right = 4
	box.content_margin_top = 8
	box.content_margin_bottom = 6
	node.add_theme_stylebox_override("panel", box)

static func _surface_tex(node: Control, path: String, mx: float, my: float, cx: float, cy: float) -> void:
	var box := StyleBoxTexture.new()
	box.texture = kit_tex(path)
	box.texture_margin_left = mx
	box.texture_margin_right = mx
	box.texture_margin_top = my
	box.texture_margin_bottom = my
	box.content_margin_left = cx
	box.content_margin_right = cx
	box.content_margin_top = cy
	box.content_margin_bottom = cy
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	node.add_theme_stylebox_override("panel", box)

static func _ensure_hairline(parent: Control, line_name: String, after: Node) -> void:
	var line: TextureRect
	if parent.has_node(line_name):
		line = parent.get_node(line_name)
	else:
		line = TextureRect.new()
		line.name = line_name
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		line.stretch_mode = TextureRect.STRETCH_SCALE
		parent.add_child(line)
	line.texture = kit_tex("res://assets/ui/settlement/kit/06-hairline-separator.png")
	line.custom_minimum_size = Vector2(0, 5)
	line.modulate = Color(1, 1, 1, 0.72)
	parent.move_child(line, after.get_index() + 1)

static func _title_row(daily: Control) -> void:
	var title := daily.get_node("Title") as Label
	font(title, 36)
	title.add_theme_color_override("font_color", INK)
	title.add_theme_constant_override("outline_size", 0)
	var flourish = kit_tex("res://assets/ui/settlement/kit/07-deco-flourish.png")
	if daily.has_node("TitleRow"):
		var existing := daily.get_node("TitleRow")
		existing.get_node("Left").texture = flourish
		existing.get_node("Right").texture = flourish
		existing.get_node("Left").custom_minimum_size = Vector2(36, 18)
		existing.get_node("Right").custom_minimum_size = Vector2(36, 18)
		existing.get_node("Right").flip_h = true
		return
	var row := HBoxContainer.new()
	row.name = "TitleRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var left := TextureRect.new()
	left.name = "Left"
	left.texture = flourish
	left.custom_minimum_size = Vector2(36, 18)
	left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var right := left.duplicate() as TextureRect
	right.name = "Right"
	right.flip_h = true
	var idx := title.get_index()
	daily.remove_child(title)
	row.add_child(left)
	row.add_child(title)
	row.add_child(right)
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	daily.add_child(row)
	daily.move_child(row, idx)

static func _price_hero(daily: Control) -> void:
	var well := daily.get_node("PriceWell") as Control
	well.custom_minimum_size.y = 96
	var col := well.get_node("Col") as VBoxContainer
	col.add_theme_constant_override("separation", -2)
	var cap_row := daily.get_node("PriceWell/Col/CapRow") as HBoxContainer
	cap_row.alignment = BoxContainer.ALIGNMENT_CENTER
	daily.get_node("PriceWell/Col/CapRow/Icon").hide()
	font(daily.get_node("PriceWell/Col/CapRow/Cap"), 17)
	daily.get_node("PriceWell/Col/CapRow/Cap").add_theme_color_override("font_color", MUTED)
	daily.get_node("PriceWell/Col/CapRow/Cap").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var num := daily.get_node("PriceWell/Col/Num") as Label
	var delta_row := daily.get_node("PriceWell/Col/DeltaRow") as Control
	if not col.has_node("HeroRow"):
		var hero := HBoxContainer.new()
		hero.name = "HeroRow"
		hero.alignment = BoxContainer.ALIGNMENT_CENTER
		hero.add_theme_constant_override("separation", 8)
		var nidx := num.get_index()
		col.remove_child(num)
		col.remove_child(delta_row)
		hero.add_child(num)
		hero.add_child(delta_row)
		col.add_child(hero)
		col.move_child(hero, nidx)
	font(num, 70)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var d_icon := delta_row.get_node("Icon") as TextureRect
	d_icon.custom_minimum_size = Vector2(26, 32)
	d_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	d_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	d_icon.texture = kit_tex("res://assets/ui/settlement/kit/24-icon-arrow-up.png")
	font(delta_row.get_node("Delta"), 26)

static func _ledger_cells(daily: Control) -> void:
	var ledger := daily.get_node("Ledger") as Control
	ledger.custom_minimum_size.y = 148
	var row := daily.get_node_or_null("Ledger/Row") as HBoxContainer
	if row == null:
		return
	row.add_theme_constant_override("separation", 8)
	var icons := {
		"Broken": "res://assets/ui/settlement/kit/33-icon-egg-cracked.png",
		"Grown": "res://assets/ui/settlement/kit/35-icon-chick-body.png",
		"Cake": "res://assets/ui/settlement/kit/32-icon-cake.png",
	}
	for name in ["Broken", "Grown", "Cake"]:
		var cell := row.get_node(name) as Control
		var panel := _ensure_kit_panel(cell, "")
		var col := panel.get_node("Col") if panel.has_node("Col") else panel.get_child(0)
		panel.custom_minimum_size = Vector2(0, 140)
		_surface_cell(panel)
		if col is VBoxContainer:
			(col as VBoxContainer).add_theme_constant_override("separation", 2)
			(col as VBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
		var icon := col.get_node("Icon") as TextureRect
		icon.custom_minimum_size = Vector2(72, 72)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = kit_tex(icons[name])
		font(col.get_node("Num"), 26)
		font(col.get_node("Cap"), 15)
		col.get_node("Cap").add_theme_color_override("font_color", MUTED)
		col.get_node("Num").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.get_node("Cap").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for sep_name in ["SepA", "SepB"]:
		var sep := row.get_node_or_null(sep_name) as ColorRect
		if sep:
			sep.hide()

static func _ensure_kit_panel(child: Control, _path: String) -> PanelContainer:
	var parent := child.get_parent()
	if parent is PanelContainer and parent.has_meta("kit_wrap"):
		return parent as PanelContainer
	var idx := child.get_index()
	var keep_name := child.name
	var panel := PanelContainer.new()
	panel.name = keep_name
	panel.set_meta("kit_wrap", true)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.name = "Col"
	parent.remove_child(child)
	panel.add_child(child)
	parent.add_child(panel)
	parent.move_child(panel, idx)
	return panel

static func _finale_report(card: Control) -> void:
	var finale := card.get_node("Finale") as VBoxContainer
	rect(finale, 0.09, 0.05, 0.82, 0.90)
	finale.alignment = BoxContainer.ALIGNMENT_CENTER
	finale.add_theme_constant_override("separation", 6)
	_finale_banner(finale)
	finale.get_node("Hook").hide()
	font(finale.get_node("RankTitle"), 34)
	finale.get_node("RankTitle").add_theme_constant_override("outline_size", 4)
	finale.get_node("Copy").hide()
	finale.get_node("Pips").custom_minimum_size.y = 30
	finale.get_node("StampRow").custom_minimum_size.y = 44
	var stamp := finale.get_node("StampRow/Stamp") as TextureRect
	stamp.texture = load("res://icons/check.png")
	stamp.custom_minimum_size = Vector2(42, 42)
	stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	font(finale.get_node("StampRow/StampTxt"), 22)
	finale.get_node("Scores").custom_minimum_size.y = 152
	finale.get_node("Scores").add_theme_constant_override("separation", 12)
	var stats_tex: Texture2D = kit_tex("res://assets/ui/settlement/kit/05-panel-stats-card.png")
	for name in ["Wealth", "Flock"]:
		var cell := finale.get_node("Scores/" + name)
		var bg := cell.get_node("Bg") as TextureRect
		bg.texture = stats_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		var col := cell.get_node("Col")
		col.get_node("Icon").custom_minimum_size = Vector2(34, 34)
		if name == "Wealth":
			col.get_node("Icon").texture = kit_tex("res://assets/ui/settlement/kit/23-icon-coin-chick.png")
		else:
			col.get_node("Icon").texture = kit_tex("res://assets/ui/settlement/kit/30-icon-hen.png")
		font(col.get_node("Cap"), 15)
		col.get_node("Cap").add_theme_color_override("font_color", MUTED)
		font(col.get_node("Num"), 30)
		font(col.get_node("Goal"), 14)
		col.get_node("Goal").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if not col.has_node("Target"):
			var target := Label.new()
			target.name = "Target"
			target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			font(target, 14)
			target.add_theme_color_override("font_color", MUTED)
			col.add_child(target)
			col.move_child(target, col.get_node("Num").get_index() + 1)
	finale.get_node("ChartWell").custom_minimum_size.y = 120
	var chart_bg := finale.get_node("ChartWell/Bg") as TextureRect
	chart_bg.texture = kit_tex("res://assets/ui/settlement/kit/04-chip-value-slot.png")
	font(finale.get_node("ChartWell/Cap"), 15)
	font(finale.get_node("Split"), 16)
	finale.get_node("Split").add_theme_color_override("font_color", MUTED)
	font(finale.get_node("BeatLine"), 15)
	finale.get_node("BeatLine").add_theme_color_override("font_color", MUTED)
	finale.get_node("Watermark").hide()
	var final_actions := finale.get_node("Actions") as Control
	final_actions.custom_minimum_size.y = 132
	for spec in [["EndlessBtn", 0.0, 0.0, 1.0, 0.46], ["AdBtn", 0.0, 0.0, 1.0, 0.46], ["ShareBtn", 0.0, 0.54, 0.49, 0.46], ["Cta", 0.51, 0.54, 0.49, 0.46]]:
		if not final_actions.has_node(spec[0]):
			continue
		var button := final_actions.get_node(spec[0]) as Button
		button.custom_minimum_size = Vector2(0, 58)
		rect(button, spec[1], spec[2], spec[3], spec[4])
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = true
	rect(card.get_node("HangTag"), 0.70, 0.012, 0.24, 0.028)
	card.get_node("HangTag/Bg").hide()
	rect(card.get_node("HangTag/TagLabel"), 0, 0, 1, 1)
	font(card.get_node("HangTag/TagLabel"), 12)
	card.get_node("HangTag/TagLabel").add_theme_color_override("font_color", MUTED)

static func _finale_banner(finale: Control) -> void:
	var title := finale.get_node("Title") as Label
	var banner_tex = kit_tex("res://assets/ui/settlement/kit/11-btn-red-wide.png")
	var flourish = kit_tex("res://assets/ui/settlement/kit/07-deco-flourish.png")
	if finale.has_node("Banner"):
		var banner := finale.get_node("Banner")
		banner.get_node("Bg").texture = banner_tex
		if banner.has_node("Ribbon"):
			banner.get_node("Ribbon").texture = flourish
			banner.get_node("Ribbon").custom_minimum_size = Vector2(40, 20)
		font(title, 22)
		title.add_theme_color_override("font_color", Color("fff6e8"))
		title.add_theme_constant_override("outline_size", 0)
		return
	var banner := Control.new()
	banner.name = "Banner"
	banner.custom_minimum_size = Vector2(0, 56)
	var bg := TextureRect.new()
	bg.name = "Bg"
	bg.texture = banner_tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.add_child(bg)
	var idx := title.get_index()
	finale.remove_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.offset_left = 48
	title.offset_right = -48
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	font(title, 22)
	title.add_theme_color_override("font_color", Color("fff6e8"))
	title.add_theme_constant_override("outline_size", 0)
	banner.add_child(title)
	var ribbon := TextureRect.new()
	ribbon.name = "Ribbon"
	ribbon.texture = flourish
	ribbon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ribbon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.custom_minimum_size = Vector2(40, 20)
	ribbon.anchor_left = 0.04
	ribbon.anchor_right = 0.16
	ribbon.anchor_top = 0.2
	ribbon.anchor_bottom = 0.8
	ribbon.offset_left = 0
	ribbon.offset_right = 0
	ribbon.offset_top = 0
	ribbon.offset_bottom = 0
	banner.add_child(ribbon)
	var ribbon_r := ribbon.duplicate() as TextureRect
	ribbon_r.name = "RibbonR"
	ribbon_r.flip_h = true
	ribbon_r.anchor_left = 0.84
	ribbon_r.anchor_right = 0.96
	banner.add_child(ribbon_r)
	finale.add_child(banner)
	finale.move_child(banner, idx)
