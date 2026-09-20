@tool
extends Control

@export var header_pad := 8.0
@export var values := PackedFloat32Array([108.0, 96.0, 132.0, 114.0, 120.0]):
	set(next_values):
		values = next_values
		queue_redraw()


func set_history(source: Array) -> void:
	var next_values := PackedFloat32Array()
	for value in source:
		next_values.append(float(value))
	values = next_values


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if values.size() < 2:
		return
	var well := Rect2(Vector2.ZERO, size)
	draw_rect(well, Color(0.97, 0.97, 0.96, 0.55), true)
	draw_rect(well, Color(0.55, 0.5, 0.45, 0.12), false, 1.0)
	var plot := Rect2(Vector2(6.0, header_pad), Vector2(size.x - 12.0, size.y - header_pad - 6.0))
	if plot.size.x < 16.0 or plot.size.y < 12.0:
		return

	var low := values[0]
	var high := values[0]
	for value in values:
		low = minf(low, value)
		high = maxf(high, value)
	var spread := maxf(1.0, high - low)
	low -= maxf(3.0, spread * 0.12)
	high += maxf(3.0, spread * 0.12)

	var grid_color := Color(0.45, 0.42, 0.38, 0.12)
	for i in 3:
		var y := plot.position.y + plot.size.y * float(i) / 2.0
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), grid_color, 1.0)
	for i in 4:
		var x := plot.position.x + plot.size.x * float(i) / 3.0
		draw_line(Vector2(x, plot.position.y), Vector2(x, plot.end.y), grid_color, 1.0)

	var points := PackedVector2Array()
	for i in values.size():
		var x := plot.position.x + plot.size.x * float(i) / float(values.size() - 1)
		var normalized := (values[i] - low) / (high - low)
		var y := plot.end.y - normalized * plot.size.y
		points.append(Vector2(x, y))

	var rising := values[values.size() - 1] >= values[0]
	var line_color := Color("#5a8f5e") if rising else Color("#b86a5c")
	var fill_color := Color(line_color.r, line_color.g, line_color.b, 0.14)
	var fill_points := PackedVector2Array(points)
	fill_points.append(Vector2(points[points.size() - 1].x, plot.end.y))
	fill_points.append(Vector2(points[0].x, plot.end.y))
	draw_colored_polygon(fill_points, fill_color)
	draw_polyline(points, line_color, 2.4, true)
	var dot := Color("e8c76a")
	for point in points:
		draw_circle(point, 3.2, Color("4a3726"))
		draw_circle(point, 2.2, dot)
