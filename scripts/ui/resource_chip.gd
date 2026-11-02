class_name ResourceChip
extends PanelContainer
## HUD readout for one resource: colored marker, name, and an amount that
## pulses on change and flashes when a purchase could not be afforded.

const SHORTAGE_COLOR := Color(1.0, 0.35, 0.3)

@export var title: String = "RESOURCE"
@export var accent: Color = Color.WHITE

var _amount_label: Label
var _shown: int = 0


func _ready() -> void:
	theme_type_variation = &"ChipPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var marker := Panel.new()
	marker.custom_minimum_size = Vector2(18, 18)
	marker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dot := StyleBoxFlat.new()
	dot.bg_color = accent
	dot.set_corner_radius_all(9)
	marker.add_theme_stylebox_override("panel", dot)
	row.add_child(marker)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", -4)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(rows)
	var caption := Label.new()
	caption.text = title
	caption.add_theme_font_size_override("font_size", 18)
	caption.add_theme_color_override("font_color", accent)
	rows.add_child(caption)
	_amount_label = Label.new()
	_amount_label.add_theme_font_size_override("font_size", 34)
	_amount_label.custom_minimum_size = Vector2(96, 0)
	rows.add_child(_amount_label)
	_amount_label.text = str(_shown)


func set_amount(value: int) -> void:
	var previous := _shown
	_shown = value
	if _amount_label == null:
		return
	_amount_label.text = str(value)
	if value != previous:
		_amount_label.pivot_offset = _amount_label.size * 0.5
		var tween := create_tween()
		tween.tween_property(_amount_label, "scale", Vector2.ONE * 1.15, 0.08)
		tween.tween_property(_amount_label, "scale", Vector2.ONE, 0.16)


func flash_shortage() -> void:
	if _amount_label == null:
		return
	var tween := create_tween()
	tween.tween_property(_amount_label, "modulate", SHORTAGE_COLOR, 0.08)
	tween.tween_property(_amount_label, "modulate", Color.WHITE, 0.5)
