class_name PlacementController
extends Node3D
## Building placement mode. A ghost of the chosen building sits on the ground
## under the screen center: the player pans (or taps to jump) to position it,
## then confirms or cancels. Validity is re-checked as it moves and the ghost
## turns green or red.

signal state_changed(definition: BuildingDefinition, problem: ConstructionService.Problem, energy_rate: float)
signal finished

const RECHECK_INTERVAL := 0.1
## Ghost snaps to this grid so it does not jitter while panning.
const GRID := 0.5
const VALID_COLOR := Color(0.35, 0.95, 0.55)
const INVALID_COLOR := Color(1.0, 0.3, 0.25)
const GHOST_ALPHA := 0.45

var definition: BuildingDefinition
var problem: ConstructionService.Problem = ConstructionService.Problem.NONE

var _camera: RtsCamera
var _service: ConstructionService
var _economy: Economy
var _ghost: Node3D
var _timer: float = 0.0
var _tint_valid: int = -1
var _energy_rate: float = 0.0


func setup(camera: RtsCamera, service: ConstructionService, economy: Economy) -> void:
	_camera = camera
	_service = service
	_economy = economy


func is_active() -> bool:
	return definition != null


func begin(new_definition: BuildingDefinition) -> void:
	_clear()
	definition = new_definition
	_ghost = Node3D.new()
	_ghost.name = "Ghost"
	_ghost.add_child(BuildingVisuals.build(definition.building_id, definition.footprint_radius))
	_ghost.add_child(BuildingVisuals.scaffold(definition.footprint_radius, 5.0))
	add_child(_ghost)
	_tint_valid = -1
	_follow_screen_center()
	_recheck()
	state_changed.emit(definition, problem, _energy_rate)


func cancel() -> void:
	if not is_active():
		return
	_clear()
	finished.emit()


## Places the building if the current spot is valid. Returns the new
## construction site, or null (and stays in placement mode) when it is not.
func confirm() -> Structure:
	if not is_active():
		return null
	_recheck()
	if problem != ConstructionService.Problem.NONE:
		return null
	var structure := _service.place(definition, _ghost.global_position, _economy, &"remnants")
	if structure != null:
		_clear()
		finished.emit()
	return structure


## Centers the camera on a tapped ground point, which moves the ghost there.
func jump_to(screen_position: Vector2) -> void:
	var ground: Variant = _camera.screen_to_ground(screen_position)
	if ground != null:
		_camera.focus_on(ground)


func ghost_position() -> Vector3:
	return _ghost.global_position if _ghost != null else Vector3.ZERO


func _process(delta: float) -> void:
	if not is_active():
		return
	var moved := _follow_screen_center()
	_timer -= delta
	if moved or _timer <= 0.0:
		_recheck()


func _follow_screen_center() -> bool:
	var center := get_viewport().get_visible_rect().size * 0.5
	var ground: Variant = _camera.screen_to_ground(center)
	if ground == null:
		return false
	var p: Vector3 = ground
	var snapped_pos := Vector3(snappedf(p.x, GRID), 0.0, snappedf(p.z, GRID))
	if snapped_pos.is_equal_approx(_ghost.position):
		return false
	_ghost.position = snapped_pos
	return true


func _recheck() -> void:
	_timer = RECHECK_INTERVAL
	var next := _service.check_placement(definition, _ghost.global_position, _economy)
	var valid := 1 if next == ConstructionService.Problem.NONE else 0
	if valid != _tint_valid:
		_tint_valid = valid
		_tint(_ghost, VALID_COLOR if valid == 1 else INVALID_COLOR)
	var rate := Structure.energy_rate_at(get_tree(), definition, _ghost.global_position)
	if next != problem or not is_equal_approx(rate, _energy_rate):
		problem = next
		_energy_rate = rate
		state_changed.emit(definition, problem, _energy_rate)


func _tint(node: Node, color: Color) -> void:
	var instance := node as GeometryInstance3D
	if instance != null:
		instance.material_override = MeshKit.translucent(color, GHOST_ALPHA)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_tint(child, color)


func _clear() -> void:
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	definition = null
	problem = ConstructionService.Problem.NONE
