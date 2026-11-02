class_name GatherJob
extends Node
## Worker loop: walk to a resource node, harvest, carry the load to the
## nearest drop-off, repeat. Moves to the nearest other deposit when the
## target runs out, and ends with on-screen feedback when nothing is left or
## a destination keeps proving unreachable.

enum State { TO_NODE, HARVESTING, TO_DROP_OFF }

## How far from the last deposit to look for another one of the same type.
const RETARGET_RADIUS := 45.0
const MAX_FAILED_TRIPS := 3
const STAND_OFF := 2.4
## Workers fan out around a deposit or drop-off instead of queuing for one
## spot; each retry also swings to a fresh angle.
const SPREAD_STEP := 0.55
const SPREAD_SLOTS := 5
const DELIVERY_COLOR := Color(1.0, 0.78, 0.35)
const PROBLEM_COLOR := Color(1.0, 0.4, 0.35)

var state: State = State.TO_NODE
var target: ResourceNode
var carrying: int = 0

var _unit: Unit
var _resource: StringName
var _last_site: Vector3
var _timer: float = 0.0
var _failures: int = 0
var _slot: int = 0


func _init(node: ResourceNode) -> void:
	name = "GatherJob"
	target = node
	_resource = node.resource
	_last_site = node.global_position


func _ready() -> void:
	_unit = get_parent() as Unit
	_slot = int(_unit.get_instance_id() % SPREAD_SLOTS)
	_unit.set_pass_through(true)
	_unit.order_finished.connect(_on_unit_arrived)
	_go_to_node()


func _exit_tree() -> void:
	if _unit == null:
		return
	_unit.set_pass_through(false)
	if _unit.order_finished.is_connected(_on_unit_arrived):
		_unit.order_finished.disconnect(_on_unit_arrived)


func _physics_process(delta: float) -> void:
	if state != State.HARVESTING:
		return
	if not _target_valid():
		_go_to_node()
		return
	_timer -= delta
	if _timer > 0.0:
		return
	var taken := target.harvest(_unit.definition.carry_capacity)
	if taken <= 0:
		_go_to_node()
		return
	carrying = taken
	_unit.set_cargo(true)
	if target.is_depleted():
		# Pick the next deposit now so the worker heads there after delivering.
		_retarget()
	_go_to_drop_off()


func _go_to_node() -> void:
	if not _target_valid() and not _retarget():
		_finish("No scrap nearby")
		return
	_last_site = target.global_position
	state = State.TO_NODE
	_unit.move_to(_stand_point(target.global_position, ResourceNode.HARVEST_REACH - STAND_OFF * 0.5))


func _go_to_drop_off() -> void:
	var drop := DropOff.nearest(get_tree(), _unit.faction, _unit.global_position)
	if drop == null:
		_finish("No drop-off")
		return
	state = State.TO_DROP_OFF
	_unit.move_to(_stand_point(drop.global_position, drop.radius + 1.0))


func _on_unit_arrived(_unit_arg: Unit) -> void:
	match state:
		State.TO_NODE:
			if not _target_valid():
				_go_to_node()
			elif _flat_distance(target.global_position) <= ResourceNode.HARVEST_REACH:
				_failures = 0
				state = State.HARVESTING
				_timer = _unit.definition.gather_seconds
			else:
				_retry(_go_to_node)
		State.TO_DROP_OFF:
			var drop := DropOff.nearest(get_tree(), _unit.faction, _unit.global_position)
			if drop != null and _flat_distance(drop.global_position) <= drop.radius + DropOff.DELIVERY_MARGIN:
				_deliver(drop)
				_go_to_node()
			else:
				_retry(_go_to_drop_off)


func _deliver(drop: DropOff) -> void:
	_failures = 0
	if _unit.economy != null:
		_unit.economy.add(_resource, carrying)
	FloatingText.spawn(_unit.get_parent(), drop.global_position + Vector3.UP * 5.0, "+%d" % carrying, DELIVERY_COLOR)
	carrying = 0
	_unit.set_cargo(false)


func _retry(step: Callable) -> void:
	_failures += 1
	if _failures >= MAX_FAILED_TRIPS:
		_finish("Can't reach")
		return
	step.call()


func _retarget() -> bool:
	var best: ResourceNode = null
	var best_distance := RETARGET_RADIUS * RETARGET_RADIUS
	for node in get_tree().get_nodes_in_group(ResourceNode.GROUP):
		var candidate := node as ResourceNode
		if candidate == null or candidate.resource != _resource or candidate.is_depleted():
			continue
		var d := candidate.global_position.distance_squared_to(_last_site)
		if d < best_distance:
			best_distance = d
			best = candidate
	target = best
	return best != null


func _target_valid() -> bool:
	return target != null and is_instance_valid(target) and not target.is_depleted() and target.is_inside_tree()


## A point `distance` from `center` on the side facing this unit, swung by
## this worker's spread slot (and by each failed attempt).
func _stand_point(center: Vector3, distance: float) -> Vector3:
	var away := _unit.global_position - center
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3.FORWARD
	var swing := (float(_slot) - float(SPREAD_SLOTS - 1) * 0.5 + float(_failures) * 2.0) * SPREAD_STEP
	return center + away.normalized().rotated(Vector3.UP, swing) * distance


func _flat_distance(point: Vector3) -> float:
	return Vector2(point.x - _unit.global_position.x, point.z - _unit.global_position.z).length()


func _finish(reason: String) -> void:
	FloatingText.spawn(_unit.get_parent(), _unit.global_position + Vector3.UP * 3.2, reason, PROBLEM_COLOR)
	_unit.cancel_job()
