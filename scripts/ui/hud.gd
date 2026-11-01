class_name Hud
extends CanvasLayer
## In-match overlay. Emits intents; never changes match state directly.

signal pause_requested

## Seconds the control hint stays fully visible before fading out.
@export var hint_duration: float = 6.0

@onready var _pause_button: Button = %PauseButton
@onready var _map_label: Label = %MapLabel
@onready var _hint: Control = %Hint


func _ready() -> void:
	_pause_button.pressed.connect(pause_requested.emit)
	var tween := create_tween()
	tween.tween_interval(hint_duration)
	tween.tween_property(_hint, "modulate:a", 0.0, 1.2)


func set_map_name(map_name: String) -> void:
	_map_label.text = map_name.to_upper()
