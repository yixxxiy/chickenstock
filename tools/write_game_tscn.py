from pathlib import Path

dst = Path(__file__).resolve().parents[1] / "scenes" / "Game.tscn"
dst.write_text(r'''[gd_scene load_steps=11 format=3]

[ext_resource type="Script" path="res://scripts/Game.gd" id="1_game"]
[ext_resource type="Texture2D" path="res://assets/map/farm-background.png" id="2_map"]
[ext_resource type="Texture2D" path="res://assets/ui/clock.png" id="3_clock"]
[ext_resource type="Texture2D" path="res://assets/ui/hud-bar.png" id="4_hud"]
[ext_resource type="Texture2D" path="res://assets/ui/settings.png" id="5_gear"]
[ext_resource type="Texture2D" path="res://assets/ui/egg-basket.png" id="6_basket"]
[ext_resource type="Texture2D" path="res://icons/egg.png" id="7_egg"]
[ext_resource type="Texture2D" path="res://icons/cake.png" id="8_cake"]
[ext_resource type="Texture2D" path="res://assets/ui/speech.png" id="9_speech"]
[ext_resource type="PackedScene" path="res://scenes/SheetSprite.tscn" id="10_sheet"]

[node name="Game" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
clip_contents = true
script = ExtResource("1_game")

[node name="Bg" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.776, 0.847, 0.714, 1)

[node name="Map" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("2_map")
expand_mode = 1
stretch_mode = 5

[node name="Flock" type="Control" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="HatchEgg" parent="." instance=ExtResource("10_sheet")]
visible = false
layout_mode = 1
anchor_left = 0.04
anchor_top = 0.43
anchor_right = 0.14
anchor_bottom = 0.53
offset_right = 0.0
offset_bottom = 0.0
row = 3
play = "warm"

[node name="HUD" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 10.0
offset_top = 10.0
offset_right = -10.0
offset_bottom = 78.0
grow_horizontal = 2
mouse_filter = 2
theme_override_constants/separation = 8

[node name="ClockBox" type="VBoxContainer" parent="HUD"]
layout_mode = 2
mouse_filter = 2

[node name="Clock" type="TextureRect" parent="HUD/ClockBox"]
custom_minimum_size = Vector2(58, 58)
layout_mode = 2
mouse_filter = 2
texture = ExtResource("3_clock")
expand_mode = 1
stretch_mode = 5

[node name="DayLabel" type="Label" parent="HUD/ClockBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.553, 0.478, 0.38, 1)
theme_override_font_sizes/font_size = 10
text = "1/8天"
horizontal_alignment = 1

[node name="Spacer" type="Control" parent="HUD"]
layout_mode = 2
size_flags_horizontal = 3
mouse_filter = 2

[node name="HudBar" type="TextureRect" parent="HUD"]
custom_minimum_size = Vector2(218, 46)
layout_mode = 2
mouse_filter = 2
texture = ExtResource("4_hud")
expand_mode = 1
stretch_mode = 1

[node name="Stats" type="HBoxContainer" parent="HUD/HudBar"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 42.0
offset_top = 4.0
offset_right = -12.0
offset_bottom = -4.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
theme_override_constants/separation = 12

[node name="CashBox" type="VBoxContainer" parent="HUD/HudBar/Stats"]
layout_mode = 2
size_flags_horizontal = 3

[node name="CashTitle" type="Label" parent="HUD/HudBar/Stats/CashBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.478, 0.396, 0.298, 1)
theme_override_font_sizes/font_size = 8
text = "现金"

[node name="Cash" type="Label" parent="HUD/HudBar/Stats/CashBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.306, 0.239, 0.173, 1)
theme_override_font_sizes/font_size = 14
text = "140"

[node name="StockBox" type="VBoxContainer" parent="HUD/HudBar/Stats"]
layout_mode = 2
size_flags_horizontal = 3

[node name="StockTitle" type="Label" parent="HUD/HudBar/Stats/StockBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.478, 0.396, 0.298, 1)
theme_override_font_sizes/font_size = 8
text = "股票"

[node name="Stock" type="Label" parent="HUD/HudBar/Stats/StockBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.306, 0.239, 0.173, 1)
theme_override_font_sizes/font_size = 14
text = "0"

[node name="SettingsBtn" type="TextureButton" parent="HUD"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
texture_normal = ExtResource("5_gear")
ignore_texture_size = true
stretch_mode = 5

[node name="EggThought" type="Button" parent="."]
layout_mode = 1
anchor_left = 0.16
anchor_top = 0.36
anchor_right = 0.16
anchor_bottom = 0.36
offset_right = 52.0
offset_bottom = 52.0
theme_override_font_sizes/font_size = 11
icon = ExtResource("6_basket")
expand_icon = true

[node name="CakeThought" type="Button" parent="."]
visible = false
layout_mode = 1
anchor_left = 0.66
anchor_top = 0.26
anchor_right = 0.66
anchor_bottom = 0.26
offset_right = 52.0
offset_bottom = 52.0
icon = ExtResource("8_cake")
expand_icon = true

[node name="HatchThought" type="Button" parent="."]
visible = false
layout_mode = 1
anchor_left = 0.025
anchor_top = 0.375
anchor_right = 0.025
anchor_bottom = 0.375
offset_right = 48.0
offset_bottom = 48.0
icon = ExtResource("7_egg")
expand_icon = true

[node name="ChickThought" type="Button" parent="."]
visible = false
layout_mode = 1
anchor_left = 0.025
anchor_top = 0.375
anchor_right = 0.025
anchor_bottom = 0.375
offset_right = 48.0
offset_bottom = 48.0
expand_icon = true

[node name="BakeryEggs" type="Label" parent="."]
visible = false
layout_mode = 1
anchor_left = 0.62
anchor_top = 0.48
anchor_right = 0.76
anchor_bottom = 0.52
theme_override_colors/font_color = Color(0.427, 0.345, 0.263, 1)
theme_override_font_sizes/font_size = 11
text = "蛋 0"
horizontal_alignment = 1

[node name="WolfShop" type="Control" parent="."]
layout_mode = 1
anchor_left = 0.16
anchor_top = 0.7
anchor_right = 0.42
anchor_bottom = 0.92
mouse_filter = 2

[node name="Talk" type="TextureRect" parent="WolfShop"]
layout_mode = 1
anchor_left = 0.0
anchor_top = -0.06
anchor_right = 0.58
anchor_bottom = 0.48
texture = ExtResource("9_speech")
expand_mode = 1
stretch_mode = 1
flip_h = true

[node name="Col" type="VBoxContainer" parent="WolfShop/Talk"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 10.0
offset_top = 10.0
offset_right = -12.0
offset_bottom = -14.0
theme_override_constants/separation = 4

[node name="Copy" type="Label" parent="WolfShop/Talk/Col"]
layout_mode = 2
theme_override_colors/font_color = Color(0.427, 0.345, 0.263, 1)
theme_override_font_sizes/font_size = 9
text = "小鸡五十，母鸡四十回收～"
autowrap_mode = 3

[node name="WolfBuy" type="Button" parent="WolfShop/Talk/Col"]
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "买小鸡  50"

[node name="WolfSell" type="Button" parent="WolfShop/Talk/Col"]
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "卖母鸡  40"

[node name="Wolf" parent="WolfShop" instance=ExtResource("10_sheet")]
layout_mode = 1
anchor_left = 0.38
anchor_top = 0.16
anchor_right = 0.95
anchor_bottom = 1.0
row = 4
play = "loop"

[node name="Ticker" type="Control" parent="."]
layout_mode = 1
anchor_left = 0.64
anchor_top = 0.58
anchor_right = 0.94
anchor_bottom = 0.86
mouse_filter = 2

[node name="Face" type="PanelContainer" parent="Ticker"]
layout_mode = 1
anchor_left = 0.1
anchor_top = 0.08
anchor_right = 0.9
anchor_bottom = 0.58

[node name="Col" type="VBoxContainer" parent="Ticker/Face"]
layout_mode = 2

[node name="TickerPrice" type="Label" parent="Ticker/Face/Col"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "金币  120"
horizontal_alignment = 1

[node name="TickerDelta" type="Label" parent="Ticker/Face/Col"]
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "▲0"
horizontal_alignment = 1

[node name="TickerHold" type="Label" parent="Ticker/Face/Col"]
layout_mode = 2
theme_override_colors/font_color = Color(0.553, 0.478, 0.38, 1)
theme_override_font_sizes/font_size = 10
text = "0股"
horizontal_alignment = 1

[node name="TradeRow" type="HBoxContainer" parent="Ticker"]
layout_mode = 1
anchor_left = 0.08
anchor_top = 0.64
anchor_right = 0.92
anchor_bottom = 0.92
theme_override_constants/separation = 6

[node name="ShareBuy" type="Button" parent="Ticker/TradeRow"]
layout_mode = 2
size_flags_horizontal = 3
text = "买1股"

[node name="ShareSell" type="Button" parent="Ticker/TradeRow"]
layout_mode = 2
size_flags_horizontal = 3
text = "卖1股"

[node name="QuestBtn" type="Button" parent="."]
layout_mode = 1
anchor_left = 0.46
anchor_top = 0.74
anchor_right = 0.63
anchor_bottom = 0.87
flat = true

[node name="NewsLabel" type="Label" parent="QuestBtn"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(0.247, 0.541, 0.322, 1)
theme_override_font_sizes/font_size = 10
text = "蛋糕热销"
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 3

[node name="QuestPop" type="PanelContainer" parent="."]
visible = false
layout_mode = 1
anchor_left = 0.12
anchor_top = 0.46
anchor_right = 0.88
anchor_bottom = 0.74

[node name="Box" type="VBoxContainer" parent="QuestPop"]
layout_mode = 2

[node name="Head" type="Label" parent="QuestPop/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 10
text = "农场任务"
horizontal_alignment = 1

[node name="QuestTitle" type="Label" parent="QuestPop/Box"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "资产 3000，同时养 15 只鸡"
horizontal_alignment = 1
autowrap_mode = 3

[node name="QuestWealth" type="Label" parent="QuestPop/Box"]
layout_mode = 2
text = "总资产 140 / 3000"
horizontal_alignment = 1

[node name="QuestFlock" type="Label" parent="QuestPop/Box"]
layout_mode = 2
text = "拥有鸡 1 / 15"
horizontal_alignment = 1

[node name="QuestNews" type="Label" parent="QuestPop/Box"]
layout_mode = 2
text = "今夜告示 · 蛋糕热销"
horizontal_alignment = 1

[node name="DayEnd" type="Button" parent="."]
layout_mode = 1
anchor_left = 0.28
anchor_top = 0.915
anchor_right = 0.72
anchor_bottom = 0.97
text = "结束本日"

[node name="DayTrack" type="ColorRect" parent="."]
layout_mode = 1
anchor_left = 0.32
anchor_top = 0.978
anchor_right = 0.32
anchor_bottom = 0.988
color = Color(0.906, 0.702, 0.31, 1)

[node name="Night" type="ColorRect" parent="."]
visible = false
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.05, 0.08, 0.16, 0.72)

[node name="Card" type="PanelContainer" parent="Night"]
layout_mode = 1
anchor_left = 0.1
anchor_top = 0.28
anchor_right = 0.9
anchor_bottom = 0.72

[node name="Box" type="VBoxContainer" parent="Night/Card"]
layout_mode = 2

[node name="CardText" type="RichTextLabel" parent="Night/Card/Box"]
custom_minimum_size = Vector2(0, 200)
layout_mode = 2
bbcode_enabled = true
fit_content = true
scroll_active = false

[node name="SettingsPop" type="PanelContainer" parent="."]
visible = false
layout_mode = 1
anchor_left = 0.08
anchor_top = 0.18
anchor_right = 0.92
anchor_bottom = 0.82

[node name="Col" type="VBoxContainer" parent="SettingsPop"]
layout_mode = 2

[node name="Title" type="Label" parent="SettingsPop/Col"]
layout_mode = 2
theme_override_font_sizes/font_size = 22
text = "设置"
horizontal_alignment = 1

[node name="CloseSettings" type="Button" parent="SettingsPop/Col"]
layout_mode = 2
text = "关闭"

[node name="SfxBtn" type="Button" parent="SettingsPop/Col"]
layout_mode = 2
text = "音效 开/关"

[node name="AmbBtn" type="Button" parent="SettingsPop/Col"]
layout_mode = 2
text = "环境音 开/关"

[node name="Help" type="Label" parent="SettingsPop/Col"]
layout_mode = 2
theme_override_font_sizes/font_size = 11
text = "只点气泡和按钮。长按可以连续收、买、卖。八日挑战：资产 3000，同时养 15 只鸡。"
autowrap_mode = 3

[node name="Restart" type="Button" parent="SettingsPop/Col"]
layout_mode = 2
text = "重新开始"

[node name="Toasts" type="VBoxContainer" parent="."]
layout_mode = 1
anchor_left = 0.5
anchor_top = 0.72
anchor_right = 0.97
anchor_bottom = 0.9
mouse_filter = 2
alignment = 2
'''
, encoding="utf-8")
print("wrote", dst, dst.stat().st_size)
