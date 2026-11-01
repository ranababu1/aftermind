extends Node3D
## Title screen over a slowly orbiting view of the battlefield.

const SKIRMISH_SCENE := "res://scenes/skirmish.tscn"

@onready var _start_button: Button = %StartButton
@onready var _quit_button: Button = %QuitButton
@onready var _version_label: Label = %VersionLabel


func _ready() -> void:
	get_tree().paused = false
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_version_label.text = "Prototype %s" % ProjectSettings.get_setting("application/config/version")
	_start_button.grab_focus()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_quit_pressed()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(SKIRMISH_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
