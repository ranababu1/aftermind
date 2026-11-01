extends Node3D
## Skirmish match root: wires the map, camera, HUD and pause menu together.

## Offset from the player start so the Nexus sits slightly below screen center.
const START_FOCUS_OFFSET := Vector3(4.0, 0.0, -6.0)

@onready var _map: MapBuilder = $Battlefield/Map
@onready var _camera: RtsCamera = $CameraRig
@onready var _hud: Hud = $HUD
@onready var _pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	var definition := _map.definition
	var half := definition.half_extents()
	_camera.bounds = Rect2(-half, definition.size)
	_camera.focus_on(definition.player_start + START_FOCUS_OFFSET)
	_hud.set_map_name(definition.display_name)
	_hud.pause_requested.connect(_pause_menu.open)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if is_node_ready():
				_pause_menu.open()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_pause_menu.toggle()
