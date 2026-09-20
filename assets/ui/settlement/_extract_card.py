from pathlib import Path

src = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市\scenes\SettlementPreview.tscn").read_text(encoding="utf-8")
start = src.find('[node name="PaperStack"')
end = src.find('[node name="Hint"')
body = src[start:end]
body = body.replace('parent="Card/', 'parent="')
body = body.replace('parent="Card"', 'parent="."')
header = """[gd_scene load_steps=13 format=3]

[ext_resource type="Script" path="res://scripts/SettlementCard.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/ui/settlement/layers/01-paper-stack.png" id="4_stack"]
[ext_resource type="Texture2D" path="res://assets/ui/settlement/layers/02-card-body.png" id="5_card"]
[ext_resource type="Texture2D" path="res://assets/ui/settlement/layers/03-hang-tag.png" id="6_tag"]
[ext_resource type="Texture2D" path="res://assets/ui/settlement/layers/10-news-chip.png" id="7_chip"]
[ext_resource type="Texture2D" path="res://assets/ui/settlement/layers/11-price-well.png" id="8_price"]
[ext_resource type="Texture2D" path="res://assets/ui/settlement/layers/12-ledger-cell.png" id="9_cell"]
[ext_resource type="Texture2D" path="res://assets/ui/settlement/layers/13-footnote-strip.png" id="10_note"]
[ext_resource type="Texture2D" path="res://assets/ui/settlement/layers/20-score-cell.png" id="11_score"]
[ext_resource type="Texture2D" path="res://assets/ui/settlement/layers/21-chart-well.png" id="12_chart"]
[ext_resource type="Texture2D" path="res://assets/ui/settlement/layers/22-quest-stamp.png" id="13_stamp"]
[ext_resource type="Texture2D" path="res://assets/ui/weather-cloud.png" id="15_weather"]

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_none"]

[node name="SettlementCard" type="Control"]
layout_mode = 3
anchors_preset = -1
anchor_left = 0.07
anchor_top = 0.13
anchor_right = 0.93
anchor_bottom = 0.9
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 0
script = ExtResource("1_script")

"""
out = Path(r"C:\Users\CYX\OneDrive\文档\小鸡股市\scenes\SettlementCard.tscn")
out.write_text(header + body, encoding="utf-8")
print("wrote", out, "nodes", (header + body).count("[node name="))
