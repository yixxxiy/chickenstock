extends Control

const UiLayout := preload("res://scripts/UiLayout.gd")
const UiStyle := preload("res://scripts/UiStyle.gd")

signal confirmed
signal continue_endless
signal ad_rewind
signal notice(text: String)

const ShareIcon := preload("res://icons/share.png")
const PriceDown := preload("res://icons/price_down.png")
var UiGreenButton: Texture2D
var UiRedButton: Texture2D
var UiEmptyBeige: Texture2D
var PipEmpty: Texture2D
var PipHit: Texture2D
var PipNow: Texture2D
var PriceUp: Texture2D

const INK := Color("4a321f")
const MUTED := Color("8b633f")
const RISE := Color("3f8a52")
const FALL := Color("c45a4c")
const GOLD := Color("c4962a")
const FINALE_INK := Color("5c241c")
const FINALE_MUTED := Color("8a4a32")
const CTA_WAIT := 3.0

var _rank_lv := 1
var _rank_max := 12
var _wealth_pts: Array[int] = []
var _wealth_goal := 3000
var _sharing := false
var _rank_title := ""
var _cta_wait_id := 0
var _finale_cta_ready := true

func _ready() -> void:
	_load_kit_textures()
	_style_beige($Daily/Actions/AdBtn)
	_style_share($Finale/Actions/ShareBtn)
	_style_green($Daily/Actions/Cta)
	_style_beige($Finale/Actions/Cta)
	_style_green($Finale/Actions/EndlessBtn)
	$Daily/Actions/AdBtn.add_theme_font_size_override("font_size", 27)
	$Daily/Actions/Cta.add_theme_font_size_override("font_size", 30)
	if not $Daily/Actions/Cta.pressed.is_connected(_on_cta):
		$Daily/Actions/Cta.pressed.connect(_on_cta)
		$Finale/Actions/Cta.pressed.connect(_on_cta)
		$Daily/Actions/AdBtn.pressed.connect(_on_ad)
		$Finale/Actions/ShareBtn.pressed.connect(_on_share)
		$Finale/Actions/EndlessBtn.pressed.connect(_on_continue_endless)
	$Daily.visible = true
	$Finale.visible = false
	$Daily.clip_contents = false
	var host := get_parent() as Control
	if host and not host.resized.is_connected(_on_shell_resized):
		host.resized.connect(_on_shell_resized)
	UiLayout.report(self)
	apply_locale()

func _load_kit_textures() -> void:
	UiGreenButton = UiLayout.kit_tex("res://assets/ui/settlement/kit/09-btn-green-wide.png")
	UiRedButton = UiLayout.kit_tex("res://assets/ui/settlement/kit/11-btn-red-wide.png")
	UiEmptyBeige = UiLayout.kit_tex("res://assets/ui/settlement/kit/10-btn-beige-wide.png")
	PipEmpty = UiLayout.kit_tex("res://assets/ui/settlement/kit/22-pip-empty.png")
	PipHit = UiLayout.kit_tex("res://assets/ui/settlement/kit/21-pip-filled-gold.png")
	PipNow = PipHit
	PriceUp = UiLayout.kit_tex("res://assets/ui/settlement/kit/24-icon-arrow-up.png")

func _on_shell_resized() -> void:
	if not is_visible_in_tree():
		return
	_fit_shell($Finale.visible)

func apply_locale() -> void:
	var daily_title := $Daily.get_node_or_null("TitleRow/Title") as Label
	if daily_title == null:
		daily_title = $Daily/Title
	daily_title.text = Loc.t("daily_title")
	if $Daily.has_node("StatsCap"):
		$Daily/StatsCap.text = Loc.t("report_stats")
	$Daily/PriceWell/Col/CapRow/Cap.text = Loc.t("close_price")
	var broken_cap := $Daily.get_node_or_null("Ledger/Row/Broken/Col/Cap") as Label
	if broken_cap == null:
		broken_cap = $Daily.get_node_or_null("Ledger/Row/Broken/Cap") as Label
	if broken_cap:
		broken_cap.text = Loc.t("broken")
	var grown_cap := $Daily.get_node_or_null("Ledger/Row/Grown/Col/Cap") as Label
	if grown_cap == null:
		grown_cap = $Daily.get_node_or_null("Ledger/Row/Grown/Cap") as Label
	if grown_cap:
		grown_cap.text = Loc.t("grown")
	var wealth_cap := $Daily.get_node_or_null("Ledger/Row/Cake/Col/Cap") as Label
	if wealth_cap == null:
		wealth_cap = $Daily.get_node_or_null("Ledger/Row/Cake/Cap") as Label
	if wealth_cap:
		wealth_cap.text = Loc.t("wealth_gain")
	$Daily/Actions/Cta.text = Loc.t("start_new_day")
	$Daily/Actions/AdBtn.text = Loc.t("watch_ad")
	var finale_title := $Finale.get_node_or_null("Banner/Title") as Label
	if finale_title == null:
		finale_title = $Finale/Title
	finale_title.text = Loc.t("finale_title")
	$Finale/Hook.text = Loc.t("finale_hook")
	$Finale/Scores/Wealth/Col/Cap.text = Loc.t("wealth_cap")
	$Finale/Scores/Flock/Col/Cap.text = Loc.t("flock_cap")
	$Finale/ChartWell/Cap.text = Loc.t("chart_cap")
	$Finale/Watermark.text = Loc.t("share_mark")
	$Finale/Actions/ShareBtn.text = Loc.t("share_card")
	$Finale/Actions/EndlessBtn.text = Loc.t("continue_endless")
	if _finale_cta_ready or not $Finale.visible:
		$Finale/Actions/Cta.text = Loc.t("retry_eight")
	_fit_locale_type()

func _fit_locale_type() -> void:
	var en := Loc.lang == "en"
	var title_sz := 28 if en else 34
	var news_sz := 17 if en else 20
	var ad_sz := 20 if en else 24
	var cta_sz := 24 if en else 28
	var hatch_sz := 15 if en else 18
	var ledger_cap := 14 if en else 16
	var daily_title := $Daily.get_node_or_null("TitleRow/Title") as Label
	if daily_title == null:
		daily_title = $Daily/Title
	daily_title.add_theme_font_size_override("font_size", title_sz)
	$Daily/NewsChip/Row/Txt.add_theme_font_size_override("font_size", news_sz)
	$Daily/NewsChip/Row/Txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if en else TextServer.AUTOWRAP_OFF
	$Daily/Actions/AdBtn.add_theme_font_size_override("font_size", ad_sz)
	$Daily/Actions/Cta.add_theme_font_size_override("font_size", cta_sz)
	$Daily/Actions/AdBtn.clip_text = true
	$Daily/Actions/Cta.clip_text = true
	$Daily/HatchNote/Txt.add_theme_font_size_override("font_size", hatch_sz)
	$Daily/BeatLine.add_theme_font_size_override("font_size", 14 if en else 16)
	$Finale/BeatLine.add_theme_font_size_override("font_size", 13 if en else 15)
	$Daily/Ledger/Row/Broken/Col/Cap.add_theme_font_size_override("font_size", ledger_cap)
	$Daily/Ledger/Row/Grown/Col/Cap.add_theme_font_size_override("font_size", ledger_cap)
	$Daily/Ledger/Row/Cake/Col/Cap.add_theme_font_size_override("font_size", ledger_cap)
	$Finale/Actions/Cta.add_theme_font_size_override("font_size", 20 if en else 22)
	$Finale/Actions/EndlessBtn.add_theme_font_size_override("font_size", 20 if en else 22)
	$Finale/Actions/ShareBtn.add_theme_font_size_override("font_size", 18 if en else 20)
	$Finale/Hook.add_theme_font_size_override("font_size", 14 if en else 16)
	$Finale/StampRow/StampTxt.add_theme_font_size_override("font_size", 18 if en else 22)
func show_daily(p: Dictionary) -> void:
	$Daily.visible = true
	$Finale.visible = false
	$Daily/Actions/Cta.disabled = false
	$Daily/Actions/AdBtn.disabled = false
	$Daily/Actions/AdBtn.visible = bool(p.get("rewind", true))
	_finale_cta_ready = true
	_cta_wait_id += 1
	_tint_shell(false)
	_fit_shell(false)
	call_deferred("_fit_shell", false)
	$HangTag.visible = false
	var from_day := int(p.get("from_day", 1))
	var to_day := int(p.get("to_day", from_day + 1))
	$HangTag/TagLabel.text = Loc.t("night_n", [from_day])
	$Daily/Kicker.text = Loc.t("night_n", [from_day])
	$Daily/DayLine.text = Loc.t("day_to_day", [from_day, to_day])
	var up := bool(p.get("news_up", true))
	var arrow := "▲" if up else "▼"
	$Daily/NewsChip/Row/Txt.text = "%s   %s" % [Loc.t("tonight_news", [str(p.get("news_text", ""))]), arrow]
	$Daily/NewsChip/Row/Txt.add_theme_color_override("font_color", INK if up else FALL)
	var weather := str(p.get("weather", "cloud"))
	var wtex: Texture2D = load("res://assets/ui/weather-%s.png" % weather)
	if wtex:
		$Daily/NewsChip/Row/Weather.texture = wtex
	var old_p := int(p.get("old_price", 0))
	var new_p := int(p.get("new_price", 0))
	var rose := new_p >= old_p
	var tone := RISE if rose else FALL
	var price_num := $Daily/PriceWell/Col.get_node_or_null("HeroRow/Num") as Label
	if price_num == null:
		price_num = $Daily/PriceWell/Col/Num
	var delta_row := $Daily/PriceWell/Col.get_node_or_null("HeroRow/DeltaRow") as Control
	if delta_row == null:
		delta_row = $Daily/PriceWell/Col/DeltaRow
	price_num.text = str(new_p)
	price_num.add_theme_color_override("font_color", tone)
	delta_row.get_node("Icon").texture = PriceUp if rose else PriceDown
	delta_row.get_node("Delta").text = str(absi(new_p - old_p))
	delta_row.get_node("Delta").add_theme_color_override("font_color", tone)
	var broken := int(p.get("broken", 0))
	var broken_num := $Daily.get_node_or_null("Ledger/Row/Broken/Col/Num") as Label
	if broken_num == null:
		broken_num = $Daily/Ledger/Row/Broken/Num
	var grown_num := $Daily.get_node_or_null("Ledger/Row/Grown/Col/Num") as Label
	if grown_num == null:
		grown_num = $Daily/Ledger/Row/Grown/Num
	var wealth_num := $Daily.get_node_or_null("Ledger/Row/Cake/Col/Num") as Label
	if wealth_num == null:
		wealth_num = $Daily/Ledger/Row/Cake/Num
	var wealth_cap := $Daily.get_node_or_null("Ledger/Row/Cake/Col/Cap") as Label
	if wealth_cap == null:
		wealth_cap = $Daily.get_node_or_null("Ledger/Row/Cake/Cap") as Label
	var wealth_icon := $Daily.get_node_or_null("Ledger/Row/Cake/Col/Icon") as TextureRect
	if wealth_icon == null:
		wealth_icon = $Daily.get_node_or_null("Ledger/Row/Cake/Icon") as TextureRect
	broken_num.text = str(broken)
	broken_num.add_theme_color_override("font_color", FALL if broken > 0 else INK)
	grown_num.text = str(int(p.get("grown", 0)))
	var old_w := int(p.get("old_wealth", 0))
	var new_w := int(p.get("new_wealth", 0))
	var delta := new_w - old_w
	var gained := delta >= 0
	wealth_num.text = Loc.t("wealth_delta", [delta])
	wealth_num.add_theme_color_override("font_color", RISE if gained else FALL)
	if wealth_cap:
		wealth_cap.text = Loc.t("wealth_gain" if gained else "wealth_loss")
	if wealth_icon:
		wealth_icon.texture = PriceUp if gained else PriceDown
	$Daily/Footnote.visible = false
	_set_beat_line($Daily/BeatLine, str(p.get("beat_text", "")))
	var hatched := int(p.get("hatched", 0))
	$Daily/HatchNote.visible = hatched > 0
	$Daily/HatchNote/Txt.text = Loc.t("hatch_note", [hatched])

func show_finale(p: Dictionary) -> void:
	$Daily.visible = false
	$Finale.visible = true
	$Daily/Actions/Cta.disabled = true
	$Finale/Actions/Cta.disabled = true
	$Finale/Actions/EndlessBtn.disabled = true
	$Finale/Actions/ShareBtn.disabled = false
	_tint_shell(true)
	_fit_shell(true)
	call_deferred("_fit_shell", true)
	$HangTag.visible = true
	_rank_max = maxi(1, int(p.get("rank_max", 12)))
	_rank_lv = clampi(int(p.get("rank_lv", 1)), 1, _rank_max)
	_rank_title = str(p.get("rank_title", ""))
	$HangTag/TagLabel.text = Loc.t("rank_n", [_rank_lv, _rank_max])
	$Finale/RankTitle.text = _rank_title
	$Finale/RankTitle.add_theme_color_override("font_color", _rank_color(_rank_lv))
	$Finale/Copy.text = str(p.get("rank_copy", ""))
	var wealth := int(p.get("wealth", 0))
	var birds := int(p.get("birds", 0))
	_wealth_goal = int(p.get("wealth_goal", 3000))
	var wealth_goal := _wealth_goal
	var flock_goal := int(p.get("flock_goal", 15))
	$Finale/Scores/Wealth/Col/Num.text = str(wealth)
	$Finale/Scores/Flock/Col/Num.text = Loc.t("birds_n", [birds])
	var wealth_hit := wealth >= wealth_goal
	var flock_hit := birds >= flock_goal
	$Finale/Scores/Wealth/Col/Num.add_theme_color_override("font_color", GOLD if wealth_hit else FALL)
	$Finale/Scores/Flock/Col/Num.add_theme_color_override("font_color", GOLD if flock_hit else FALL)
	var wealth_target := $Finale/Scores/Wealth/Col.get_node_or_null("Target") as Label
	var flock_target := $Finale/Scores/Flock/Col.get_node_or_null("Target") as Label
	if wealth_target:
		wealth_target.text = Loc.t("goal_n", [wealth_goal])
	if flock_target:
		flock_target.text = Loc.t("goal_n", [flock_goal])
	if wealth_hit:
		var extra := wealth - wealth_goal
		$Finale/Scores/Wealth/Col/Goal.text = Loc.t("quest_hit") if extra <= 0 else Loc.t("goal_over_gold", [extra])
	else:
		$Finale/Scores/Wealth/Col/Goal.text = Loc.t("goal_gap_gold", [wealth_goal - wealth])
	if flock_hit:
		var extra_b := birds - flock_goal
		$Finale/Scores/Flock/Col/Goal.text = Loc.t("quest_hit") if extra_b <= 0 else Loc.t("goal_over_birds", [extra_b])
	else:
		$Finale/Scores/Flock/Col/Goal.text = Loc.t("quest_need_birds", [flock_goal - birds])
	$Finale/Scores/Wealth/Col/Goal.add_theme_color_override("font_color", RISE if wealth_hit else FALL)
	$Finale/Scores/Flock/Col/Goal.add_theme_color_override("font_color", RISE if flock_hit else FALL)
	var quest := bool(p.get("quest", false))
	var stamp := $Finale/StampRow/Stamp as TextureRect
	stamp.visible = true
	stamp.texture = load("res://icons/check.png") if quest else load("res://icons/alert.png")
	stamp.modulate = Color.WHITE if quest else Color(1.05, 0.75, 0.7)
	$Finale/StampRow/StampTxt.text = Loc.t("quest_stamp") if quest else Loc.t("quest_miss")
	$Finale/StampRow/StampTxt.add_theme_color_override("font_color", RISE if quest else FALL)
	$Finale/StampRow/StampTxt.add_theme_font_size_override("font_size", 20 if quest else 22)
	$Finale/Split.text = Loc.t("wealth_split", [int(p.get("cash", 0)), int(p.get("stock", 0))])
	_set_beat_line($Finale/BeatLine, str(p.get("beat_text", "")))
	_wealth_pts.clear()
	var raw = p.get("wealth_pts", [])
	if raw is Array and not raw.is_empty():
		for x in raw:
			_wealth_pts.append(int(x))
	else:
		_wealth_pts.append(wealth)
	_rebuild_pips()
	call_deferred("_draw_wealth_curve")
	_begin_cta_wait()

func _fit_shell(finale: bool) -> void:
	scale = Vector2.ONE
	pivot_offset = Vector2.ZERO
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	# Settlement typography is fixed and does not follow the game's text-size
	# preference. Keep the reusable nine-slice report centered in the phone safe area.
	anchor_left = 0.08
	anchor_right = 0.92
	if finale:
		anchor_top = 0.10
		anchor_bottom = 0.92
	else:
		anchor_top = 0.11
		anchor_bottom = 0.91

func _tint_shell(finale: bool) -> void:
	$PaperStack.visible = false
	var finale_title := $Finale.get_node_or_null("Banner/Title") as Label
	if finale_title == null:
		finale_title = $Finale/Title
	if finale:
		$CardBody.modulate = Color.WHITE
		$PaperStack.modulate = Color.WHITE
		$HangTag.modulate = Color.WHITE
		finale_title.add_theme_color_override("font_color", Color("fff6e8"))
		$Finale/Hook.add_theme_color_override("font_color", FINALE_MUTED)
		$Finale/Copy.add_theme_color_override("font_color", FINALE_MUTED)
		$Finale/Split.add_theme_color_override("font_color", FINALE_MUTED)
		$Finale/Watermark.add_theme_color_override("font_color", Color(0.541, 0.29, 0.196, 0.88))
		$Finale/ChartWell/Cap.add_theme_color_override("font_color", FINALE_MUTED)
		$Finale/ChartWell/Curve.default_color = Color("c4842a")
		$HangTag/TagLabel.add_theme_color_override("font_color", Color("4a2218"))
	else:
		$CardBody.modulate = Color.WHITE
		$HangTag.modulate = Color.WHITE
		$HangTag/TagLabel.add_theme_color_override("font_color", INK)

func _set_beat_line(lab: Label, text: String) -> void:
	lab.text = text
	lab.visible = text != ""

func _begin_cta_wait() -> void:
	_finale_cta_ready = false
	_cta_wait_id += 1
	var token := _cta_wait_id
	var cta: Button = $Finale/Actions/Cta
	var endless: Button = $Finale/Actions/EndlessBtn
	cta.disabled = true
	endless.disabled = true
	_run_cta_wait(token)

func _run_cta_wait(token: int) -> void:
	var cta: Button = $Finale/Actions/Cta
	var endless: Button = $Finale/Actions/EndlessBtn
	var left := int(ceil(CTA_WAIT))
	while left > 0:
		if token != _cta_wait_id or not is_inside_tree() or not $Finale.visible:
			return
		cta.text = str(left)
		await get_tree().create_timer(1.0).timeout
		left -= 1
	if token != _cta_wait_id or not is_inside_tree() or not $Finale.visible:
		return
	_finale_cta_ready = true
	cta.disabled = false
	endless.disabled = false
	cta.text = Loc.t("retry_eight")
	endless.text = Loc.t("continue_endless")

func _rank_color(lv: int) -> Color:
	if lv >= 12:
		return Color("b8860b")
	if lv >= 10:
		return Color("7a4eb5")
	if lv >= 8:
		return GOLD
	if lv >= 6:
		return Color("568458")
	if lv >= 3:
		return Color("8a6a3a")
	return Color("b9574c")

func _rebuild_pips() -> void:
	var box: HBoxContainer = $Finale/Pips
	while box.get_child_count():
		var c := box.get_child(0)
		box.remove_child(c)
		c.free()
	var pip_n := maxi(1, _rank_max)
	box.add_theme_constant_override("separation", 2 if pip_n >= 12 else 5)
	for i in pip_n:
		var lv := i + 1
		var t := TextureRect.new()
		t.texture = PipNow if lv == _rank_lv else (PipHit if lv < _rank_lv else PipEmpty)
		t.custom_minimum_size = Vector2(24, 24) if lv == _rank_lv else Vector2(18, 18)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		box.add_child(t)

func _draw_wealth_curve() -> void:
	var well: Control = $Finale/ChartWell
	var line: Line2D = well.get_node("Curve")
	var fill: Polygon2D = well.get_node("Fill")
	var goal_line: Line2D = well.get_node("Goal")
	var goal_lab: Label = well.get_node("GoalLab")
	var end_dot: ColorRect = well.get_node("EndDot")
	var end_lab: Label = well.get_node("EndLab")
	var pts := _wealth_pts
	if pts.is_empty():
		line.points = PackedVector2Array()
		fill.polygon = PackedVector2Array()
		goal_line.points = PackedVector2Array()
		end_dot.visible = false
		end_lab.visible = false
		goal_lab.visible = false
		return
	var sz := well.size
	if sz.x < 8.0 or sz.y < 8.0:
		sz = Vector2(280, well.custom_minimum_size.y)
	var r := Rect2(Vector2(16, 32), sz - Vector2(32, 44))
	var peak := 1.0
	for n in pts:
		peak = maxf(peak, float(n))
	var goal := float(maxi(1, _wealth_goal))
	var show_goal := peak >= goal * 0.28
	var lo := 0.0
	var hi: float
	if show_goal:
		hi = maxf(peak, goal) * 1.08
	else:
		hi = maxf(peak * 1.32, peak + 80.0)
	hi = maxf(hi, lo + 1.0)
	var draw_pts := pts.duplicate()
	if draw_pts.size() == 1:
		draw_pts.append(draw_pts[0])
	var out: PackedVector2Array = []
	var last := maxi(1, draw_pts.size() - 1)
	for i in draw_pts.size():
		var x := r.position.x + r.size.x * float(i) / float(last)
		var y := r.position.y + r.size.y * (1.0 - clampf((float(draw_pts[i]) - lo) / (hi - lo), 0.0, 1.0))
		out.append(Vector2(x, y))
	line.points = out
	line.width = 4.0
	var poly := PackedVector2Array()
	for p in out:
		poly.append(p)
	poly.append(Vector2(out[out.size() - 1].x, r.position.y + r.size.y))
	poly.append(Vector2(out[0].x, r.position.y + r.size.y))
	fill.polygon = poly
	goal_lab.visible = true
	goal_lab.text = Loc.t("chart_goal", [int(goal)])
	if show_goal:
		var gy := r.position.y + r.size.y * (1.0 - clampf((goal - lo) / (hi - lo), 0.0, 1.0))
		goal_line.points = PackedVector2Array([Vector2(r.position.x, gy), Vector2(r.position.x + r.size.x, gy)])
		goal_line.default_color = Color("c45a4c88") if peak < goal else Color("3f8a5288")
		goal_lab.position = Vector2(r.position.x + 4.0, gy - 18.0)
		goal_lab.size = Vector2(132, 20)
	else:
		goal_line.points = PackedVector2Array()
		goal_lab.position = Vector2(r.position.x + r.size.x - 120.0, r.position.y - 2.0)
		goal_lab.size = Vector2(120, 20)
	var ep := out[out.size() - 1]
	end_dot.visible = true
	end_dot.size = Vector2(10, 10)
	end_dot.position = ep - Vector2(5, 5)
	end_lab.visible = true
	end_lab.text = str(pts[pts.size() - 1])
	var lab_pos := Vector2(ep.x + 8.0, ep.y - 18.0)
	if lab_pos.x > r.position.x + r.size.x - 44.0:
		lab_pos.x = ep.x - 48.0
	if lab_pos.y < r.position.y:
		lab_pos.y = ep.y + 6.0
	end_lab.position = lab_pos
	end_lab.size = Vector2(64, 22)

func _on_cta() -> void:
	if $Finale.visible:
		if $Finale/Actions/Cta.disabled or not _finale_cta_ready:
			return
	elif $Daily/Actions/Cta.disabled:
		return
	_lock_actions()
	confirmed.emit()

func _on_continue_endless() -> void:
	if not $Finale.visible:
		return
	if $Finale/Actions/EndlessBtn.disabled or not _finale_cta_ready:
		return
	_lock_actions()
	continue_endless.emit()

func _on_ad() -> void:
	_lock_actions()
	ad_rewind.emit()

func _on_share() -> void:
	if _sharing or not $Finale.visible:
		return
	_share_card()

func _share_card() -> void:
	_sharing = true
	var share_btn: Button = $Finale/Actions/ShareBtn
	var cta: Button = $Finale/Actions/Cta
	var endless: Button = $Finale/Actions/EndlessBtn
	share_btn.disabled = true
	cta.disabled = true
	endless.disabled = true
	var img := await _grab_card_image()
	if not is_inside_tree():
		_sharing = false
		return
	var ok := false
	if img != null and img.get_width() > 8:
		ok = _export_png(img)
	_sharing = false
	share_btn.disabled = false
	cta.disabled = not _finale_cta_ready
	endless.disabled = not _finale_cta_ready
	if ok:
		share_btn.text = Loc.t("share_saved")
		notice.emit(Loc.t("toast_card_saved"))
		get_tree().create_timer(1.4).timeout.connect(func():
			if is_instance_valid(share_btn):
				share_btn.text = Loc.t("share_card")
		)
	else:
		notice.emit(Loc.t("toast_card_fail"))

func _poster_bounds() -> Rect2:
	var r := Rect2(Vector2.ZERO, size)
	r = r.merge($PaperStack.get_rect())
	r = r.merge($HangTag.get_rect())
	return r.grow(6.0)

func _grab_card_image() -> Image:
	var bounds := _poster_bounds()
	if bounds.size.x < 8.0 or bounds.size.y < 8.0:
		return null
	var px := 2.0
	var sv := SubViewport.new()
	sv.size = Vector2i(maxi(1, int(ceil(bounds.size.x * px))), maxi(1, int(ceil(bounds.size.y * px))))
	sv.transparent_bg = true
	sv.disable_3d = true
	sv.gui_disable_input = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	var wrap := Control.new()
	wrap.size = bounds.size
	wrap.scale = Vector2(px, px)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var copy := duplicate() as Control
	copy.set_script(null)
	copy.modulate = Color.WHITE
	copy.scale = Vector2.ONE
	copy.rotation = 0.0
	copy.layout_mode = 0
	copy.position = -bounds.position
	copy.size = size
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var finale_actions := copy.get_node_or_null("Finale/Actions") as Control
	if finale_actions:
		finale_actions.visible = false
	var daily_actions := copy.get_node_or_null("Daily/Actions") as Control
	if daily_actions:
		daily_actions.visible = false
	get_tree().root.add_child(sv)
	sv.add_child(wrap)
	wrap.add_child(copy)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img: Image = null
	if is_instance_valid(sv):
		var tex := sv.get_texture()
		if tex:
			img = tex.get_image()
		sv.queue_free()
	return img

func _export_png(img: Image) -> bool:
	var buf := img.save_png_to_buffer()
	if buf.is_empty():
		return false
	var fname := _share_filename()
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		Engine.get_singleton("JavaScriptBridge").download_buffer(buf, fname, "image/png")
		return true
	var path := "user://%s" % fname
	var err := img.save_png(path)
	if err != OK:
		return false
	var abs_path := ProjectSettings.globalize_path(path)
	if abs_path != "":
		OS.shell_open(abs_path)
	return true

func _share_filename() -> String:
	var title := _rank_title if _rank_title != "" else "rank"
	var clean := ""
	for ch in title:
		if ch in "/\\:*?\"<>|":
			continue
		clean += ch
	if clean.strip_edges() == "":
		clean = "rank"
	return "小鸡股市-%s.png" % clean.strip_edges()

func unlock_actions() -> void:
	$Daily/Actions/Cta.disabled = false
	$Daily/Actions/AdBtn.disabled = false
	if _finale_cta_ready:
		$Finale/Actions/Cta.disabled = false
		$Finale/Actions/EndlessBtn.disabled = false
	$Finale/Actions/ShareBtn.disabled = false

func _lock_actions() -> void:
	$Daily/Actions/Cta.disabled = true
	$Daily/Actions/AdBtn.disabled = true
	$Finale/Actions/Cta.disabled = true
	$Finale/Actions/EndlessBtn.disabled = true
	$Finale/Actions/ShareBtn.disabled = true

func _style_share(b: Button) -> void:
	_style_beige(b)
	b.icon = ShareIcon
	b.expand_icon = true
	b.clip_text = false
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_constant_override("h_separation", 10)
	b.add_theme_constant_override("icon_max_width", 36)

func _style_beige(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color("4e3d2c"))
	b.add_theme_color_override("font_hover_color", Color("4e3d2c"))
	b.add_theme_color_override("font_pressed_color", Color("4e3d2c"))
	b.add_theme_color_override("font_disabled_color", Color("4e3d2c88"))
	var sb := StyleBoxTexture.new()
	sb.texture = UiEmptyBeige
	sb.texture_margin_left = 56
	sb.texture_margin_top = 32
	sb.texture_margin_right = 56
	sb.texture_margin_bottom = 32
	sb.content_margin_left = 16
	sb.content_margin_top = 14
	sb.content_margin_right = 16
	sb.content_margin_bottom = 14
	UiStyle.button_states(b, sb)

func _style_red(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color("fff8e8"))
	b.add_theme_color_override("font_hover_color", Color("fff8e8"))
	b.add_theme_color_override("font_pressed_color", Color("fff8e8"))
	b.add_theme_color_override("font_disabled_color", Color("fff8e888"))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.clip_text = true
	var sb := StyleBoxTexture.new()
	sb.texture = UiRedButton
	sb.texture_margin_left = 56
	sb.texture_margin_top = 32
	sb.texture_margin_right = 56
	sb.texture_margin_bottom = 32
	sb.content_margin_left = 12
	sb.content_margin_top = 10
	sb.content_margin_right = 12
	sb.content_margin_bottom = 10
	UiStyle.button_states(b, sb)

func _style_green(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color("fff8e8"))
	b.add_theme_color_override("font_hover_color", Color("fff8e8"))
	b.add_theme_color_override("font_pressed_color", Color("fff8e8"))
	b.add_theme_color_override("font_disabled_color", Color("fff8e888"))
	var sb := StyleBoxTexture.new()
	sb.texture = UiGreenButton
	sb.texture_margin_left = 56
	sb.texture_margin_top = 32
	sb.texture_margin_right = 56
	sb.texture_margin_bottom = 32
	sb.content_margin_left = 22
	sb.content_margin_top = 14
	sb.content_margin_right = 22
	sb.content_margin_bottom = 14
	UiStyle.button_states(b, sb)
