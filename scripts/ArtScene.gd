@tool
extends Control

## Art board for Game's current visual assets. The 576×1024 board mirrors
## Game.tscn; the kit below lists leftover textures Game loads at runtime.

const UiGreenButton := preload("res://assets/ui/farm-ui/button_green.png")
const UiRedButton := preload("res://assets/ui/farm-ui/button_red.png")
const UiEmptyBeige := preload("res://assets/ui/farm-ui/button_empty_beige.png")

const KIT: Array[Array] = [
	["weather-sun", "res://assets/ui/weather-sun.png"],
	["weather-cloud", "res://assets/ui/weather-cloud.png"],
	["weather-rain", "res://assets/ui/weather-rain.png"],
	["weather-moon", "res://assets/ui/weather-moon.png"],
	["weather-partly", "res://assets/ui/weather-partly.png"],
	["rotten_egg", "res://icons/rotten_egg.png"],
	["hatch", "res://icons/hatch.png"],
	["flock", "res://icons/flock.png"],
	["hen icon", "res://icons/hen.png"],
	["price_up", "res://icons/price_up.png"],
	["price_down", "res://icons/price_down.png"],
	["icon_coin", "res://assets/ui/farm-ui/icon_coin.png"],
	["button_neutral", "res://assets/ui/farm-ui/button_neutral.png"],
	["farm-sheet-8x5", "res://assets/sprites/farm-sheet-8x5.png"],
	["chick-walk-8", "res://assets/sprites/chick-walk-8.png"],
	["chick-idle-8", "res://assets/sprites/chick-idle-8.png"],
	["moon", "res://assets/ui/settlement/layers/00-moon.png"],
	["paper-stack", "res://assets/ui/settlement/layers/01-paper-stack.png"],
	["card-body", "res://assets/ui/settlement/layers/02-card-body.png"],
	["hang-tag", "res://assets/ui/settlement/layers/03-hang-tag.png"],
	["news-chip", "res://assets/ui/settlement/layers/10-news-chip.png"],
	["price-well", "res://assets/ui/settlement/layers/11-price-well.png"],
	["ledger-cell", "res://assets/ui/settlement/layers/12-ledger-cell.png"],
	["footnote", "res://assets/ui/settlement/layers/13-footnote-strip.png"],
	["score-cell", "res://assets/ui/settlement/layers/20-score-cell.png"],
	["chart-well", "res://assets/ui/settlement/layers/21-chart-well.png"],
	["quest-stamp", "res://assets/ui/settlement/layers/22-quest-stamp.png"],
	["pip-empty", "res://assets/ui/settlement/layers/23-pip-empty.png"],
	["pip-hit", "res://assets/ui/settlement/layers/24-pip-hit.png"],
	["pip-now", "res://assets/ui/settlement/layers/25-pip-now.png"],
	["dialogue atlas", "res://assets/ui/cozyland-source/Cozyland UI/Dialogue boxes.png"],
	["frame 9-slice", "res://assets/ui/farm-ui/frame_tall_9slice.png"],
]


func _ready() -> void:
	_style_board()
	_build_kit()


func _style_board() -> void:
	var board := get_node_or_null("Board") as Control
	if board == null:
		return
	_style_green(board.get_node_or_null("DayEnd") as Button)
	_style_green(board.get_node_or_null("BakeryUpgrade") as Button)
	_style_green(board.get_node_or_null("WolfShop/Talk/Col/WolfBuy") as Button)
	_style_red(board.get_node_or_null("WolfShop/Talk/Col/WolfSell") as Button)
	_style_plank(board.get_node_or_null("Ticker/TradeRow/ShareBuy") as Button)
	_style_plank(board.get_node_or_null("Ticker/TradeRow/ShareSell") as Button)
	_style_hud_chip(board.get_node_or_null("HUD/HudBar/CashChip") as PanelContainer)
	_style_hud_chip(board.get_node_or_null("HUD/HudBar/StockChip") as PanelContainer)
	for path in ["EggThought", "CakeThought", "HatchThought", "ChickThought"]:
		_style_thought(board.get_node_or_null(path) as Button)


func _build_kit() -> void:
	var grid := get_node_or_null("Kit/Grid") as GridContainer
	if grid == null:
		return
	for child in grid.get_children():
		grid.remove_child(child)
		child.free()
	for item in KIT:
		var cap := String(item[0])
		var path := String(item[1])
		var tex := load(path) as Texture2D
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(88, 112)
		cell.add_theme_constant_override("separation", 4)
		var img := TextureRect.new()
		img.custom_minimum_size = Vector2(80, 80)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if tex:
			img.texture = tex
		cell.add_child(img)
		var label := Label.new()
		label.text = cap
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color("5a4a38"))
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cell.add_child(label)
		grid.add_child(cell)


func _style_green(b: Button) -> void:
	if b == null:
		return
	_apply_button(b, UiGreenButton, Color("3a2a18"))


func _style_red(b: Button) -> void:
	if b == null:
		return
	_apply_button(b, UiRedButton, Color("3a2a18"))


func _style_plank(b: Button) -> void:
	if b == null:
		return
	_apply_button(b, UiEmptyBeige, Color("3a2a18"))


func _apply_button(b: Button, source: Texture2D, ink: Color) -> void:
	b.add_theme_color_override("font_color", ink)
	b.add_theme_color_override("font_hover_color", ink)
	b.add_theme_color_override("font_pressed_color", ink)
	var sb := StyleBoxTexture.new()
	sb.texture = source
	sb.texture_margin_left = 24.0
	sb.texture_margin_top = 16.0
	sb.texture_margin_right = 24.0
	sb.texture_margin_bottom = 16.0
	sb.content_margin_left = 18.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 18.0
	sb.content_margin_bottom = 8.0
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("disabled", sb)


func _style_hud_chip(c: PanelContainer) -> void:
	if c == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff6e6cc")
	sb.border_color = Color("ead9b08c")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(22)
	sb.content_margin_left = 8
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	c.add_theme_stylebox_override("panel", sb)


func _style_thought(b: Button) -> void:
	if b == null:
		return
	b.text = ""
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff6e6f5")
	sb.border_color = Color("c4a574")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(28)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("disabled", sb)
