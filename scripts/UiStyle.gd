extends RefCounted

# Reuse painted surfaces while making interaction states consistent everywhere.
static func button_states(button: Button, surface: StyleBoxTexture) -> void:
	var hover := surface.duplicate() as StyleBoxTexture
	hover.modulate_color = Color(1.07, 1.06, 1.03)
	var pressed := surface.duplicate() as StyleBoxTexture
	pressed.modulate_color = Color(0.86, 0.84, 0.80)
	var disabled := surface.duplicate() as StyleBoxTexture
	disabled.modulate_color = Color(0.70, 0.70, 0.68, 0.88)
	button.add_theme_stylebox_override("normal", surface)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.set_meta("ui_normal_surface", surface)
	button.set_meta("ui_hover_surface", hover)
	# Game routes mobile clicks through button_down/up signals itself.
	var down := _press.bind(button)
	var up := _release.bind(button)
	if not button.button_down.is_connected(down):
		button.button_down.connect(down)
		button.button_up.connect(up)
		button.visibility_changed.connect(up)
		button.mouse_exited.connect(up)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("b88938")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(12)
	button.add_theme_stylebox_override("focus", focus)

static func _press(button: Button) -> void:
	if button.disabled:
		return
	var surface := button.get_theme_stylebox("pressed")
	button.add_theme_stylebox_override("normal", surface)
	button.add_theme_stylebox_override("hover", surface)

static func _release(button: Button) -> void:
	if not is_instance_valid(button):
		return
	if button.has_meta("ui_normal_surface"):
		button.add_theme_stylebox_override("normal", button.get_meta("ui_normal_surface"))
	if button.has_meta("ui_hover_surface"):
		button.add_theme_stylebox_override("hover", button.get_meta("ui_hover_surface"))
	button.scale = Vector2.ONE
	button.rotation = 0.0
	button.modulate = Color.WHITE
