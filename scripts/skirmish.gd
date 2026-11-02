extends Node3D
## Skirmish match root: wires the map, camera, units, controllers, HUD and
## pause menu together, and routes world taps to selection or orders.

## Offset from the player start so the Nexus sits slightly below screen center.
const START_FOCUS_OFFSET := Vector3(4.0, 0.0, -6.0)
## Starting units gather this far from the Nexus, toward the map center.
const SPAWN_DISTANCE := 11.0
const SPAWN_SPACING := 2.2
const NAV_SYNC_MAX_FRAMES := 600
## Screen-space pick radius for resource deposits (they are wider than units).
const DEPOSIT_PICK_RADIUS_PX := 96.0
const NEXUS_DROP_OFF_RADIUS := 6.4

@export var starting_units: Array[UnitDefinition] = []
@export var buildable: Array[BuildingDefinition] = []
## Collective guard placed on each of the map's sentry posts.
@export var sentry_unit: UnitDefinition

@onready var _map: MapBuilder = $Battlefield/Map
@onready var _camera: RtsCamera = $CameraRig
@onready var _economy: Economy = $PlayerEconomy
@onready var _units: Node3D = $Units
@onready var _construction: ConstructionService = $ConstructionService
@onready var _placement: PlacementController = $PlacementController
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
	_construction.setup(_map, $Structures, _units)
	_placement.setup(_camera, _construction, _economy)
	_hud.set_buildable(buildable)
	_hud.building_chosen.connect(_on_building_chosen)
	_hud.placement_confirmed.connect(_on_placement_confirmed)
	_hud.placement_cancelled.connect(_placement.cancel)
	_placement.state_changed.connect(_hud.show_placement_state)
	_placement.finished.connect(_hud.end_placement)
	_hud.set_map_name(definition.display_name)
	_hud.bind_economy(_economy)
	_hud.pause_requested.connect(_pause_menu.open)
	_hud.select_all_requested.connect(_selection.select_all)
	_hud.clear_selection_requested.connect(_selection.clear)
	_selection.selection_changed.connect(_hud.show_selection)
	_selection.structure_selection_changed.connect(_hud.show_structure)
	_hud.cancel_construction_requested.connect(_on_cancel_construction)
	_hud.produce_requested.connect(_on_produce_requested)
	_hud.cancel_production_requested.connect(_on_cancel_production)
	_add_player_drop_off(definition.player_start)
	_camera.tapped.connect(_on_world_tapped)
	_camera.long_pressed.connect(_on_world_long_pressed)
	# Spawn points are snapped to walkable ground, which needs the
	# navigation map to have synced the freshly baked mesh.
	var waited := 0
	while not _map.is_navigation_ready() and waited < NAV_SYNC_MAX_FRAMES:
		await get_tree().physics_frame
		waited += 1
	_spawn_starting_units()
	_spawn_sentries()


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
		unit.economy = _economy
		_units.add_child(unit)


func _spawn_sentries() -> void:
	if sentry_unit == null:
		return
	var posts := _map.definition.sentry_posts
	for i in posts.size():
		var unit := Unit.new()
		unit.definition = sentry_unit
		unit.faction = Combat.COLLECTIVE
		unit.name = "Sentinel%d" % i
		unit.position = _commands.closest_walkable(posts[i])
		unit.guard_point = unit.position
		var outward := posts[i] - _map.definition.core_site
		unit.rotation.y = atan2(-outward.x, -outward.z)
		_units.add_child(unit)


## The Command Nexus is a placeholder model for now; this makes it accept
## deliveries.
func _add_player_drop_off(at: Vector3) -> void:
	var drop := DropOff.new()
	drop.name = "NexusDropOff"
	drop.faction = &"remnants"
	drop.radius = NEXUS_DROP_OFF_RADIUS
	drop.position = at
	add_child(drop)


func _on_building_chosen(definition: BuildingDefinition) -> void:
	_hud.begin_placement(definition)
	_placement.begin(definition)


func _on_placement_confirmed() -> void:
	var builders := _selection.selected_units()
	var site := _placement.confirm()
	if site != null:
		_commands.issue_build(builders, site)


func _on_world_tapped(screen_position: Vector2) -> void:
	if _placement.is_active():
		_placement.jump_to(screen_position)
		return
	var unit := _selection.pick_unit(screen_position)
	if unit != null:
		_selection.select_only(unit)
		return
	var enemy := _selection.pick_enemy(screen_position)
	if enemy != null and _selection.has_selection():
		if not _commands.issue_attack(_selection.selected_units(), enemy):
			_commands.reject(enemy.global_position)
		return
	var deposit := _selection.pick_in_group(ResourceNode.GROUP, screen_position, 0.5, DEPOSIT_PICK_RADIUS_PX) as ResourceNode
	if deposit != null and _selection.has_selection():
		_commands.issue_gather(_selection.selected_units(), deposit)
		return
	# Workers build or repair the building they are sent to; any other tap on
	# a building selects it.
	var structure_hit := _camera.raycast(screen_position, 1 << (Structure.PICK_LAYER - 1))
	if not structure_hit.is_empty():
		var structure := Structure.from_collider(structure_hit.collider)
		if structure != null and structure.faction != _selection.faction and _selection.has_selection():
			if not _commands.issue_attack(_selection.selected_units(), structure):
				_commands.reject(structure_hit.position)
			return
		if not _commands.issue_build(_selection.selected_units(), structure):
			_selection.select_structure(structure)
		return
	if not _selection.has_selection():
		_selection.clear()
		return
	# A tap on a rock or structure must not resolve to the ground behind it.
	var hit := _camera.raycast(screen_position, 1 << (MapBuilder.OBSTACLE_LAYER - 1))
	if not hit.is_empty():
		_commands.reject(hit.position)
		return
	var ground: Variant = _camera.screen_to_ground(screen_position)
	if ground != null:
		_commands.issue_move(_selection.selected_units(), ground)


func _on_cancel_construction() -> void:
	var structure := _selection.selected_structure()
	if structure != null:
		structure.cancel_construction()


func _on_produce_requested(definition: UnitDefinition) -> void:
	var structure := _selection.selected_structure()
	if structure != null and structure.production != null:
		structure.production.enqueue(definition)


func _on_cancel_production() -> void:
	var structure := _selection.selected_structure()
	if structure != null and structure.production != null:
		structure.production.cancel_last()


func _on_world_long_pressed(screen_position: Vector2) -> void:
	var unit := _selection.pick_unit(screen_position)
	if unit != null:
		_selection.toggle(unit)
