class_name Hud
extends CanvasLayer
## In-match overlay. Emits intents; never changes match state directly.

signal pause_requested
signal select_all_requested
signal clear_selection_requested

## Seconds the control hint stays fully visible before fading out.
@export var hint_duration: float = 8.0

@onready var _pause_button: Button = %PauseButton
@onready var _map_label: Label = %MapLabel
@onready var _hint: Control = %Hint
@onready var _selection_chip: Control = %SelectionChip
@onready var _selection_count: Label = %SelectionCount
@onready var _selection_detail: Label = %SelectionDetail
@onready var _clear_button: Button = %ClearButton
@onready var _all_button: Button = %AllButton


func _ready() -> void:
	_pause_button.pressed.connect(pause_requested.emit)
	_all_button.pressed.connect(select_all_requested.emit)
	_clear_button.pressed.connect(clear_selection_requested.emit)
	show_selection([])
	var tween := create_tween()
	tween.tween_interval(hint_duration)
	tween.tween_property(_hint, "modulate:a", 0.0, 1.2)


func set_map_name(map_name: String) -> void:
	_map_label.text = map_name.to_upper()


func show_selection(units: Array[Unit]) -> void:
	var has_units := not units.is_empty()
	_selection_chip.visible = has_units
	_clear_button.visible = has_units
	if not has_units:
		return
	_selection_count.text = "%d SELECTED" % units.size()
	var counts: Dictionary = {}
	for unit in units:
		var unit_name := unit.definition.display_name
		counts[unit_name] = counts.get(unit_name, 0) + 1
	var parts: PackedStringArray = []
	for unit_name in counts:
		parts.append("%s ×%d" % [unit_name, counts[unit_name]])
	_selection_detail.text = "  ·  ".join(parts)
