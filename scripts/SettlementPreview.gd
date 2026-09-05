@tool
extends Control

@export_enum("daily", "finale", "flop") var mode := "daily":
	set(v):
		mode = v
		if is_inside_tree():
			_apply()

func _ready() -> void:
	_apply()
	if not Engine.is_editor_hint():
		$Hint.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			mode = "daily"
		elif event.keycode == KEY_2:
			mode = "finale"
		elif event.keycode == KEY_3:
			mode = "flop"

func _apply() -> void:
	if mode == "daily":
		$NightVeil.color = Color(0.05, 0.08, 0.16, 0.72)
		$Card.show_daily({
			"from_day": 3, "to_day": 4,
			"news_text": "狼商囤粮", "news_up": true, "weather": "cloud",
			"broken": 2, "grown": 3, "cakes": 1, "hatched": 1,
			"old_price": 144, "new_price": 186,
			"old_wealth": 980, "new_wealth": 1120,
			"beat_text": "你打败了 6% 的农场主。超过了一小撮人。",
		})
		return
	$NightVeil.color = Color(0.22, 0.06, 0.10, 0.72)
	if mode == "flop":
		$Card.show_finale({
			"rank_lv": 1, "rank_title": Loc.rank_title(1),
			"rank_copy": Loc.rank_copy(1),
			"wealth": 140, "birds": 2,
			"wealth_goal": 3000, "flock_goal": 15, "quest": false,
			"cash": 140, "stock": 0,
			"wealth_pts": [500, 420, 310, 260, 200, 180, 150, 140],
			"rank_max": 10,
			"beat_text": "八日收官，你打败了 0.1% 的挑战者。才刚进场，明天再捞。",
		})
		return
	$Card.show_finale({
		"rank_lv": 8, "rank_title": Loc.rank_title(8),
		"rank_copy": Loc.rank_copy(8),
		"wealth": 3240, "birds": 16,
		"wealth_goal": 3000, "flock_goal": 15, "quest": true,
		"cash": 1840, "stock": 1400,
		"wealth_pts": [140, 280, 420, 510, 680, 900, 1400, 3240],
		"rank_max": 10,
		"beat_text": "八日收官，你打败了 47% 的挑战者。快摸到中位了。",
	})
