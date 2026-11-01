class_name SafeAreaMargin
extends MarginContainer
## Pads its content so it stays inside the device safe area (notches, rounded
## corners, gesture bars), on top of a fixed base margin.

@export var base_margin: int = 48


func _ready() -> void:
	get_viewport().size_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var insets := _safe_insets()
	add_theme_constant_override("margin_left", base_margin + int(insets.position.x))
	add_theme_constant_override("margin_top", base_margin + int(insets.position.y))
	add_theme_constant_override("margin_right", base_margin + int(insets.size.x))
	add_theme_constant_override("margin_bottom", base_margin + int(insets.size.y))


## Returns left/top in position and right/bottom in size, in canvas units.
func _safe_insets() -> Rect2:
	var screen_size := Vector2(DisplayServer.screen_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if screen_size.x <= 0.0 or screen_size.y <= 0.0 or safe.size.x <= 0.0:
		return Rect2()
	var scale := get_viewport_rect().size / screen_size
	var left := safe.position.x * scale.x
	var top := safe.position.y * scale.y
	var right := (screen_size.x - safe.end.x) * scale.x
	var bottom := (screen_size.y - safe.end.y) * scale.y
	return Rect2(maxf(left, 0.0), maxf(top, 0.0), maxf(right, 0.0), maxf(bottom, 0.0))
