extends RefCounted

# Presentation only: all existing controls, signals, text and game state stay owned
# by Game. Coordinates are relative to the 576 x 1024 portrait canvas.
const PANEL := preload("res://assets/ui/farm-ui/simple-ui/panel.png")
const BTN_BEIGE := preload("res://assets/ui/farm-ui/simple-ui/button-beige.png")
const BTN_GREEN := preload("res://assets/ui/farm-ui/simple-ui/button-green.png")
const BTN_RED := preload("res://assets/ui/farm-ui/simple-ui/button-red.png")
const TAG := preload("res://assets/ui/farm-ui/simple-ui/tag.png")
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
	if node is TextureRect:
		var image := node as TextureRect
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.custom_minimum_size = Vector2.ZERO
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.anchor_left = x
	node.anchor_top = y
	node.anchor_right = x + w
	node.anchor_bottom = y + h
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0

# Pixel box on a known parent size. Anchors-only layout can stay 0×0 during
# _ready, which makes Start Game undroppable while the PNG still paints.
static func pin(node: Control, x: float, y: float, w: float, h: float, pw: float, ph: float) -> void:
	if node is TextureRect:
		var image := node as TextureRect
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.custom_minimum_size = Vector2.ZERO
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0
	node.offset_left = x * pw
	node.offset_top = y * ph
	node.offset_right = (x + w) * pw
	node.offset_bottom = (y + h) * ph

static func font(node: Control, points: int) -> void:
	node.add_theme_font_size_override("font_size", points)
	if node is Label:
		node.add_theme_color_override("font_color", INK)
	node.add_theme_constant_override("outline_size", 0)

static func surface(node: Control, padding := 22.0) -> void:
	node.add_theme_stylebox_override("panel", panel_box(padding))

static func panel_box(padding := 12.0) -> StyleBoxTexture:
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
	return box

static func button_box(tex: Texture2D, pad_x := 16.0, pad_y := 10.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 42.0
	sb.texture_margin_top = 20.0
	sb.texture_margin_right = 42.0
	sb.texture_margin_bottom = 20.0
	sb.content_margin_left = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_right = pad_x
	sb.content_margin_bottom = pad_y
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return sb

static func apply_button(button: Button, tex: Texture2D, pad_x := 16.0, pad_y := 10.0) -> void:
	var sb := button_box(tex, pad_x, pad_y)
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, sb)
	button.set_meta("ui_normal_surface", sb)
	button.set_meta("ui_hover_surface", sb)

static func apply(game: Control) -> void:
	_hud(game)
	_menu(game)
	_farm(game)
	_dialogs(game)
	_tutorial(game)
	var follow := CloseFollow.new()
	follow.game = game
	game.add_child(follow)

static func _hud(game: Control) -> void:
	# Match the 576×1024 farm mock: round clock, shorter capsule, mail/gear flush right.
	const HUD_X := 0.024
	const HUD_Y := 0.014
	const HUD_W := 0.952
	const HUD_H := 0.102
	const BAR_Y := 0.10
	const BAR_H := 0.80
	var hud := game.get_node("HUD") as Control
	rect(hud, HUD_X, HUD_Y, HUD_W, HUD_H)
	for item in ["Spacer", "SpacerEnd"]:
		hud.get_node(item).hide()

	var hud_h := 1024.0 * HUD_H
	var hud_w := 576.0 * HUD_W
	var clock_w := hud_h / hud_w
	var clock_box := hud.get_node("ClockBox") as Control
	rect(clock_box, 0.0, 0.0, clock_w, 1.0)
	var clock := clock_box.get_node("Clock") as Control
	clock.custom_minimum_size = Vector2.ZERO
	rect(clock, 0.0, 0.0, 1.0, 1.0)
	var day_chip := clock_box.get_node_or_null("DayChip") as Panel
	if day_chip:
		day_chip.z_index = 4
		day_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect(day_chip, 0.06, 0.62, 0.88, 0.34)
		day_chip.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var day := clock_box.get_node_or_null("DayChip/DayLabel") as Label
	if day:
		rect(day, 0, 0, 1, 1)
		font(day, 17)
		day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		day.add_theme_color_override("font_color", INK)
		day.add_theme_color_override("font_outline_color", Color("fff8e8e6"))
		day.add_theme_constant_override("outline_size", 5)
		day.autowrap_mode = TextServer.AUTOWRAP_OFF
		day.clip_text = false

	var btn_w := BAR_H * hud_h / hud_w * 0.5
	var btn_h := BAR_H * 0.5
	var btn_y := BAR_Y + (BAR_H - btn_h) * 0.5
	var gear_x := 1.0 - 0.004 - btn_w
	var mail_x := gear_x - 0.014 - btn_w
	var bar_x := clock_w + 0.032
	var bar_w := mail_x - 0.020 - bar_x
	var bar := hud.get_node("HudBar") as Control
	bar.custom_minimum_size = Vector2.ZERO
	rect(bar, bar_x, BAR_Y, bar_w, BAR_H)
	var bar_bg := bar.get_node_or_null("HudBarBg") as Panel
	if bar_bg:
		bar_bg.show_behind_parent = true
		bar_bg.clip_contents = false
		rect(bar_bg, 0, 0, 1, 1)
		# panel.png 九宫默认上下各 48px，条子只有约 60px 高会被压扁，看起来像切了一半。
		var slim := panel_box(4.0)
		slim.texture_margin_top = 22
		slim.texture_margin_bottom = 22
		slim.texture_margin_left = 40
		slim.texture_margin_right = 40
		bar_bg.add_theme_stylebox_override("panel", slim)

	# Inset past the 9-slice caps so four equal columns, not a cramped left + empty tail.
	const CHIP_PAD := 0.06
	const CHIP_W := (1.0 - CHIP_PAD * 2.0) / 4.0
	var slots := ["CashChip", "StockChip", "HenChip", "ChickChip"]
	for i in slots.size():
		var chip := bar.get_node(slots[i]) as Control
		chip.custom_minimum_size = Vector2.ZERO
		rect(chip, CHIP_PAD + CHIP_W * float(i), 0.05, CHIP_W, 0.90)
		var row := chip.get_node("Row") as HBoxContainer
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 5)
		var icon := row.get_node("Icon") as Control
		icon.custom_minimum_size = Vector2(30, 30)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var num: Label
		if slots[i] == "CashChip" or slots[i] == "StockChip":
			var col := row.get_child(1) as Control
			col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			col.get_child(0).hide()
			num = col.get_child(1) as Label
		else:
			num = chip.get_node("Row/Num") as Label
		num.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		num.custom_minimum_size = Vector2(28, 0)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		font(num, 20)
		num.add_theme_color_override("font_color", INK)

	# Half-size squares, flush right so the capsule can use the middle.
	for pair in [["QuestBtn", mail_x], ["SettingsBtn", gear_x]]:
		var button := hud.get_node(pair[0]) as TextureButton
		button.custom_minimum_size = Vector2.ZERO
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		rect(button, pair[1], btn_y, btn_w, btn_h)
	var dot := hud.get_node("QuestBtn/UnreadDot") as Control
	dot.z_index = 2
	dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dot.anchor_left = 1.0
	dot.anchor_top = 0.0
	dot.anchor_right = 1.0
	dot.anchor_bottom = 0.0
	dot.offset_left = -8.0
	dot.offset_top = -1.0
	dot.offset_right = 4.0
	dot.offset_bottom = 11.0
	dot.grow_horizontal = Control.GROW_DIRECTION_BEGIN

static func _menu(game: Control) -> void:
	var layer := game.get_node("StartMenuLayer") as Control
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var card := layer.get_node("Card") as Control
	var view_w := 576.0
	var view_h := 1024.0
	pin(card, 0.17, 0.08, 0.66, 0.67, view_w, view_h)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := card.get_node("Box") as Control
	var card_w := view_w * 0.66
	var card_h := view_h * 0.67
	pin(box, 0, 0, 1, 1, card_w, card_h)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paper := box.get_node_or_null("MenuSurface") as Panel
	if paper == null:
		paper = Panel.new()
		paper.name = "MenuSurface"
		box.add_child(paper)
		box.move_child(paper, 0)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin(paper, 0, 0.35, 1, 0.65, card_w, card_h)
	surface(paper)
	var icon := box.get_node("LogoIcon") as TextureRect
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin(icon, 0.28, -0.02, 0.44, 0.22, card_w, card_h)
	var word := box.get_node("LogoWordmark") as TextureRect
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin(word, 0.04, 0.18, 0.92, 0.16, card_w, card_h)
	box.get_node("Subtitle").visible = false
	for spec in [["Direct", 0.40, 0.11], ["Tutorial", 0.515, 0.095], ["Challenge", 0.615, 0.095], ["Endless", 0.715, 0.095]]:
		var button := box.get_node(spec[0]) as Button
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.z_index = 8
		pin(button, 0.07, spec[1], 0.86, spec[2], card_w, card_h)
		font(button, 30 if spec[0] == "Direct" else 27)
		button.clip_text = false
		button.autowrap_mode = TextServer.AUTOWRAP_OFF
	for spec in [["Settings", 0.055], ["Trophies", 0.505]]:
		var button := box.get_node(spec[0]) as Button
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.z_index = 8
		# Wider + tighter side pad so a larger icon still leaves room for
		# full English labels ("Settings" / "Trophies").
		pin(button, spec[1], 0.855, 0.44, 0.105, card_w, card_h)
		font(button, 24)
		button.clip_text = false
		button.autowrap_mode = TextServer.AUTOWRAP_OFF
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 56)
		button.add_theme_constant_override("h_separation", 6)
		for state in ["normal", "hover", "pressed", "disabled"]:
			var sb := button.get_theme_stylebox(state)
			if sb == null:
				continue
			var padded := sb.duplicate() as StyleBox
			padded.content_margin_left = 10.0
			padded.content_margin_right = 10.0
			button.add_theme_stylebox_override(state, padded)

static func _farm(game: Control) -> void:
	# WolfShop + buy/sell live in Game.tscn — do not rewrite those anchors.
	# Building hit targets / thoughts still laid out here until baked.
	rect(game.get_node("EggThought"), 0.16, 0.25, 0.13, 0.065)
	rect(game.get_node("CakeThought"), 0.80, 0.29, 0.13, 0.065)
	var cake := game.get_node("CakeThought") as Control
	cake.anchor_bottom = cake.anchor_top
	cake.offset_bottom = 64
	# Below the bakery building; hugs coin + two-line copy.
	rect(game.get_node("BakeryUpgrade"), 0.68, 0.515, 0.24, 0.055)
	font(game.get_node("BakeryUpgrade"), 14)
	var oven := game.get_node("BakeryUpgrade") as Button
	oven.autowrap_mode = TextServer.AUTOWRAP_OFF
	oven.clip_text = false
	oven.custom_minimum_size = Vector2(0, 36)
	oven.add_theme_constant_override("icon_max_width", 18)
	oven.add_theme_constant_override("h_separation", 4)
	apply_button(oven, BTN_BEIGE, 8.0, 3.0)
	oven.add_theme_color_override("font_color", INK)
	oven.add_theme_color_override("font_hover_color", INK)
	oven.add_theme_color_override("font_pressed_color", INK)
	oven.add_theme_color_override("font_disabled_color", Color(INK, 0.45))
	oven.add_theme_constant_override("outline_size", 0)
	rect(game.get_node("BakeryEggs"), 0.68, 0.49, 0.28, 0.03)
	font(game.get_node("BakeryEggs"), 23)
	for name in ["HatchThought", "ChickThought"]:
		rect(game.get_node(name), 0.70, 0.58, 0.12, 0.065)
	rect(game.get_node("HatchEgg"), 0.70, 0.62, 0.15, 0.10)
	var toast := game.get_node("Toasts") as Control
	# Tall enough for two stacked hints; keep under HUD, clear of logo on menu
	# (menu lock hints use StartMenuLayer/MenuToasts instead).
	rect(toast, 0.10, 0.14, 0.80, 0.18)
	toast.clip_contents = false
	toast.add_theme_constant_override("separation", 8)
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
	# simple-ui panel dock; price + hold left, chart right, buy/sell/end-day row.
	var dock_panel := game.get_node("Dock") as PanelContainer
	dock_panel.add_theme_stylebox_override("panel", panel_box(10.0))
	var face := game.get_node("Dock/Row/Ticker/Face") as Control
	var col := face.get_node("Col") as Control
	var price_cap := col.get_node("PriceCap") as Label
	price_cap.visible = true
	font(price_cap, 16)
	price_cap.add_theme_color_override("font_color", MUTED)
	price_cap.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	price_cap.clip_text = true
	# Strict non-overlapping bands: cap / price / delta / hold.
	rect(price_cap, 0.0, 0.0, 1.0, 0.16)
	var price := col.get_node("TickerPrice") as Label
	font(price, 36)
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price.clip_text = true
	rect(price, 0.0, 0.16, 1.0, 0.32)
	var delta := col.get_node("TickerDelta") as Label
	font(delta, 20)
	delta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	delta.clip_text = true
	rect(delta, 0.0, 0.48, 1.0, 0.2)
	col.get_node("HoldHint").visible = false
	var hold := col.get_node("TickerHold") as Label
	font(hold, 16)
	hold.add_theme_color_override("font_color", MUTED)
	hold.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hold.clip_text = true
	rect(hold, 0.0, 0.7, 1.0, 0.28)
	var trade_row := game.get_node("Dock/Row/Day/TradeRow") as HBoxContainer
	trade_row.add_theme_constant_override("separation", 8)
	for name in ["ShareBuy", "ShareSell"]:
		var action := game.get_node("Dock/Row/Day/TradeRow/" + name) as Button
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.size_flags_vertical = Control.SIZE_EXPAND_FILL
		action.size_flags_stretch_ratio = 1.0
		action.custom_minimum_size = Vector2(110, 54)
	var day_end := game.get_node("Dock/Row/Day/TradeRow/DayEnd") as Button
	day_end.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_end.size_flags_vertical = Control.SIZE_EXPAND_FILL
	day_end.size_flags_stretch_ratio = 1.35
	day_end.custom_minimum_size = Vector2(0, 54)

static func _dialogs(game: Control) -> void:
	# Settings: fit content, center on screen (same treatment as quest card).
	var settings_card := game.get_node("SettingsPop/Card") as Control
	# Prefer runtime-wrapped Scroll/Col (phone overflow); fall back to authored Col.
	var settings := settings_card.get_node_or_null("Scroll/Col") as VBoxContainer
	if settings == null:
		settings = settings_card.get_node("Col") as VBoxContainer
	# 默认先给一块居中底；打开时 Game._fit_settings_card 再按内容收紧高度。
	rect(settings_card, 0.12, 0.18, 0.76, 0.58)
	surface(settings_card, 24)
	var trophy_card := game.get_node("TrophyPop/Card") as Control
	rect(trophy_card, 0.07, 0.15, 0.86, 0.76)
	surface(trophy_card, 26)
	var quest := game.get_node("QuestPop/Card") as Control
	# Fit content height and sit on viewport center (was tall + top-heavy).
	rect(quest, 0.14, 0.20, 0.72, 0.56)
	surface(quest, 24)
	var quest_box := quest.get_node("Box") as VBoxContainer
	quest_box.alignment = BoxContainer.ALIGNMENT_CENTER
	quest_box.add_theme_constant_override("separation", 14)
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
		var hint := metric.get_node("Row/Col/Hint") as Label
		font(hint, 21)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		metric.get_node("Row/Col/Track").custom_minimum_size.y = 12
	settings.alignment = BoxContainer.ALIGNMENT_CENTER
	settings.add_theme_constant_override("separation", 14)
	var footer_pad := settings.get_node_or_null("FooterPad") as Control
	if footer_pad:
		footer_pad.visible = false
		footer_pad.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	font(settings.get_node("Title"), 40)
	settings.get_node("Title").add_theme_color_override("font_color", INK)
	for path in ["SfxRow/SfxTitle", "AmbRow/AmbTitle", "LangRow/LangTitle", "FontRow/FontTitle"]:
		font(settings.get_node(path), 26)
	for path in ["SfxRow/SfxBtn", "AmbRow/AmbBtn"]:
		var chip := settings.get_node(path) as Button
		font(chip, 24)
		chip.custom_minimum_size = Vector2(132, 56)
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chip.clip_text = false
		chip.autowrap_mode = TextServer.AUTOWRAP_OFF
	var lang_opts := settings.get_node("LangRow/Options") as HBoxContainer
	lang_opts.alignment = BoxContainer.ALIGNMENT_CENTER
	lang_opts.add_theme_constant_override("separation", 12)
	for name in ["ZhBtn", "EnBtn"]:
		var lang_btn := lang_opts.get_node(name) as Button
		font(lang_btn, 24)
		lang_btn.custom_minimum_size = Vector2(156, 56)
		lang_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lang_btn.clip_text = false
		lang_btn.autowrap_mode = TextServer.AUTOWRAP_OFF
	var font_opts := settings.get_node("FontRow/Options") as HBoxContainer
	font_opts.alignment = BoxContainer.ALIGNMENT_CENTER
	font_opts.add_theme_constant_override("separation", 10)
	for name in ["SmallBtn", "NormalBtn", "LargeBtn"]:
		var font_btn := font_opts.get_node(name) as Button
		font_btn.custom_minimum_size = Vector2(140, 56)
		font_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		font_btn.clip_text = false
		font_btn.autowrap_mode = TextServer.AUTOWRAP_OFF
	for name in ["GuideBtn", "HomeBtn", "Restart"]:
		var button := settings.get_node(name) as Button
		font(button, 28)
		button.custom_minimum_size.y = 56
		button.clip_text = false
		button.autowrap_mode = TextServer.AUTOWRAP_OFF
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
	next_btn.clip_text = false
	next_btn.autowrap_mode = TextServer.AUTOWRAP_OFF
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
	daily.get_node("Footnote").visible = false
	daily.get_node("HatchNote").alignment = BoxContainer.ALIGNMENT_CENTER
	daily.get_node("HatchNote").add_theme_constant_override("separation", 0)
	daily.get_node("HatchNote/Icon").hide()
	font(daily.get_node("HatchNote/Txt"), 16)
	daily.get_node("HatchNote/Txt").add_theme_color_override("font_color", MUTED)
	daily.get_node("HatchNote/Txt").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	font(daily.get_node("BeatLine"), 13)
	daily.get_node("BeatLine").add_theme_color_override("font_color", MUTED)
	daily.get_node("BeatLine").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Match reference order: ledger → hatch → beat → actions
	daily.move_child(daily.get_node("HatchNote"), daily.get_node("Ledger").get_index() + 1)
	daily.move_child(daily.get_node("BeatLine"), daily.get_node("HatchNote").get_index() + 1)
	var actions := daily.get_node("Actions") as VBoxContainer
	actions.move_child(actions.get_node("Cta"), 0)
	actions.add_theme_constant_override("separation", 10)
	for child in actions.get_children():
		child.custom_minimum_size.y = 64
		(child as Button).clip_text = false
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
		"Grown": "res://icons/chick.png",
		"Cake": "res://assets/ui/settlement/kit/24-icon-arrow-up.png",
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
	for spec in [["EndlessBtn", 0.0, 0.0, 1.0, 0.46], ["AdBtn", 0.0, 0.0, 1.0, 0.46], ["Cta", 0.0, 0.54, 1.0, 0.46]]:
		if not final_actions.has_node(spec[0]):
			continue
		var button := final_actions.get_node(spec[0]) as Button
		button.custom_minimum_size = Vector2(0, 58)
		rect(button, spec[1], spec[2], spec[3], spec[4])
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = false
	if final_actions.has_node("ShareBtn"):
		final_actions.get_node("ShareBtn").visible = false
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
		var existing := finale.get_node("Banner")
		existing.get_node("Bg").texture = banner_tex
		if existing.has_node("Ribbon"):
			existing.get_node("Ribbon").texture = flourish
			existing.get_node("Ribbon").custom_minimum_size = Vector2(40, 20)
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
