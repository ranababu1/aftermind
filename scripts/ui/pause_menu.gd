class_name PauseMenu
extends CanvasLayer
## Owns the paused state of the match. Processes while the tree is paused.

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _menu_button: Button = %MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(close)
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button.pressed.connect(_on_main_menu_pressed)


func open() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = true
	_resume_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
