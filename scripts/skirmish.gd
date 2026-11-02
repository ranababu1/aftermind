extends Node3D
## Skirmish match root: wires the map, camera, units, controllers, HUD and
## pause menu together, and routes world taps to selection or orders.

## Offset from the player start so the Nexus sits slightly below screen center.
const START_FOCUS_OFFSET := Vector3(4.0, 0.0, -6.0)
## Starting units gather this far from the Nexus, toward the map center.
const SPAWN_DISTANCE := 11.0
const SPAWN_SPACING := 2.2
const NAV_SYNC_MAX_FRAMES := 600

@export var starting_units: Array[UnitDefinition] = []

@onready var _map: MapBuilder = $Battlefield/Map
@onready var _camera: RtsCamera = $CameraRig
@onready var _units: Node3D = $Units
@onready var _selection: SelectionController = $SelectionController
@onready var _commands: CommandController = $CommandController
@onready var _hud: Hud = $HUD
@onready var _pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	var definition := _map.definition
	var half := definition.half_extents()
	_camera.bounds = Rect2(-half, definition.size)
	_camera.focus_on(definition.player_start + START_FOCUS_OFFSET)
	_selection.setup(_camera.get_camera())
	_commands.setup(_map)
	_hud.set_map_name(definition.display_name)
	_hud.pause_requested.connect(_pause_menu.open)
	_hud.select_all_requested.connect(_selection.select_all)
	_hud.clear_selection_requested.connect(_selection.clear)
	_selection.selection_changed.connect(_hud.show_selection)
	_camera.tapped.connect(_on_world_tapped)
	_camera.long_pressed.connect(_on_world_long_pressed)
	# Spawn points are snapped to walkable ground, which needs the
	# navigation map to have synced the freshly baked mesh.
	var waited := 0
	while not _map.is_navigation_ready() and waited < NAV_SYNC_MAX_FRAMES:
		await get_tree().physics_frame
		waited += 1
	_spawn_starting_units()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if is_node_ready():
				_pause_menu.open()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_pause_menu.toggle()


func _spawn_starting_units() -> void:
	var definition := _map.definition
	var toward_center := (definition.core_site - definition.player_start).normalized()
	var rally := definition.player_start + toward_center * SPAWN_DISTANCE
	var offsets := CommandController.formation_offsets(starting_units.size(), SPAWN_SPACING)
	for i in starting_units.size():
		var unit := Unit.new()
		unit.definition = starting_units[i]
		unit.name = "%s%d" % [starting_units[i].display_name.to_pascal_case(), i]
		unit.position = _commands.closest_walkable(rally + offsets[i])
		unit.rotation.y = atan2(-toward_center.x, -toward_center.z)
		_units.add_child(unit)


func _on_world_tapped(screen_position: Vector2) -> void:
	var unit := _selection.pick_unit(screen_position)
	if unit != null:
		_selection.select_only(unit)
		return
	if not _selection.has_selection():
		return
	# A tap on a rock or structure must not resolve to the ground behind it.
	var hit := _camera.raycast(screen_position, 1 << (MapBuilder.OBSTACLE_LAYER - 1))
	if not hit.is_empty():
		_commands.reject(hit.position)
		return
	var ground: Variant = _camera.screen_to_ground(screen_position)
	if ground != null:
		_commands.issue_move(_selection.selected_units(), ground)


func _on_world_long_pressed(screen_position: Vector2) -> void:
	var unit := _selection.pick_unit(screen_position)
	if unit != null:
		_selection.toggle(unit)
