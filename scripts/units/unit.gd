class_name Unit
extends Node3D
## A mobile unit. Executes move orders on the navigation mesh with local
## avoidance, and gives up safely if it stops making progress. A unit can run
## one job (such as gathering) that drives it; a direct player order cancels
## the job.

signal order_finished(unit: Unit)

const GROUP := &"units"
const ARRIVAL_DISTANCE := 0.5
## A moving unit that covers less than this distance within STUCK_SECONDS
## abandons its order instead of pushing against a blocker forever.
const STUCK_SECONDS := 2.0
const STUCK_MIN_PROGRESS := 0.4

@export var definition: UnitDefinition
@export var faction: StringName = &"remnants"

## Stockpile that this unit's deliveries go to.
var economy: Economy
var job: Node = null

var selected: bool = false:
	set(value):
		selected = value
		if _selection_ring != null:
			_selection_ring.visible = value

var _agent: NavigationAgent3D
var _selection_ring: MeshInstance3D
var _cargo: Node3D
var _moving: bool = false
var _stuck_timer: float = 0.0
var _stuck_origin: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group(GROUP)
	add_child(UnitVisuals.build(definition.unit_id))
	_selection_ring = UnitVisuals.selection_ring(definition.radius)
	_selection_ring.visible = selected
	add_child(_selection_ring)
	_agent = NavigationAgent3D.new()
	_agent.radius = definition.radius
	_agent.height = 2.4
	_agent.max_speed = definition.move_speed
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = ARRIVAL_DISTANCE
	_agent.avoidance_enabled = true
	_agent.neighbor_distance = 6.0
	_agent.velocity_computed.connect(_on_velocity_computed)
	add_child(_agent)
	if definition.can_gather:
		_cargo = UnitVisuals.cargo()
		_cargo.visible = false
		add_child(_cargo)


func is_moving() -> bool:
	return _moving


## Player move order: cancels any running job first.
func command_move(target: Vector3) -> void:
	cancel_job()
	move_to(target)


func assign_job(new_job: Node) -> void:
	cancel_job()
	job = new_job
	add_child(new_job)


func cancel_job() -> void:
	if job != null and is_instance_valid(job):
		remove_child(job)
		job.queue_free()
	job = null
	set_cargo(false)


## While true the unit ignores other units in local avoidance, so busy
## workers can thread through idle crowds (others still steer around it).
func set_pass_through(enabled: bool) -> void:
	if _agent != null:
		_agent.avoidance_mask = 0 if enabled else 1


func set_cargo(carrying: bool) -> void:
	if _cargo != null:
		_cargo.visible = carrying


func move_to(target: Vector3) -> void:
	_agent.target_position = target
	_moving = true
	_stuck_timer = 0.0
	_stuck_origin = global_position


func stop() -> void:
	var was_moving := _moving
	_moving = false
	_agent.velocity = Vector3.ZERO
	if was_moving:
		order_finished.emit(self)


func _physics_process(delta: float) -> void:
	if not _moving:
		return
	if _agent.is_navigation_finished():
		stop()
		return
	var to_next := _agent.get_next_path_position() - global_position
	to_next.y = 0.0
	_agent.velocity = to_next.normalized() * definition.move_speed if to_next.length() > 0.01 else Vector3.ZERO
	_stuck_timer += delta
	if _stuck_timer >= STUCK_SECONDS:
		if global_position.distance_to(_stuck_origin) < STUCK_MIN_PROGRESS:
			stop()
			return
		_stuck_timer = 0.0
		_stuck_origin = global_position


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if not _moving:
		return
	safe_velocity.y = 0.0
	var delta := get_physics_process_delta_time()
	global_position += safe_velocity * delta
	if safe_velocity.length_squared() > 0.04:
		var target_yaw := atan2(-safe_velocity.x, -safe_velocity.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-definition.turn_speed * delta))
