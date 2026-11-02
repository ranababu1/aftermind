class_name ProductionQueue
extends Node
## Builds units one at a time for a finished structure. An order is paid for
## when it is queued and refunded in full if cancelled. A finished unit waits
## inside until one of the exit points around the building is clear.

signal changed
signal unit_produced(unit: Unit)

const MAX_ORDERS := 5
## Exit points sit this far outside the footprint.
const EXIT_GAP := 2.0
const EXIT_SAMPLES := 12
const WALKABLE_TOLERANCE := 0.4
## Seconds between exit checks while every exit is blocked.
const RETRY_SECONDS := 0.5

var structure: Structure
var map: MapBuilder
var units_root: Node3D
var orders: Array[UnitDefinition] = []
## Seconds of work done on the front order.
var progress: float = 0.0
## True while a finished unit has no clear exit.
var blocked: bool = false

var _retry: float = 0.0
var _produced: int = 0


func can_enqueue() -> bool:
	return orders.size() < MAX_ORDERS


## Pays for and queues one unit. Returns false (and spends nothing) when the
## queue is full or the cost cannot be paid.
func enqueue(definition: UnitDefinition) -> bool:
	if definition == null or not can_enqueue() or structure.economy == null:
		return false
	if not structure.economy.try_spend(definition.cost()):
		return false
	orders.append(definition)
	changed.emit()
	return true


## Removes the newest order and refunds it in full.
func cancel_last() -> bool:
	if orders.is_empty():
		return false
	var definition: UnitDefinition = orders.pop_back()
	var cost := definition.cost()
	for resource in cost:
		if int(cost[resource]) > 0:
			structure.economy.add(resource, int(cost[resource]))
	if orders.is_empty():
		progress = 0.0
		blocked = false
	changed.emit()
	return true


## Share of the front order that is done, 0..1.
func front_fraction() -> float:
	if orders.is_empty():
		return 0.0
	return clampf(progress / maxf(orders[0].build_seconds, 0.01), 0.0, 1.0)


func _process(delta: float) -> void:
	if orders.is_empty():
		return
	var front := orders[0]
	if progress < front.build_seconds:
		progress = minf(progress + delta, front.build_seconds)
		changed.emit()
		if progress < front.build_seconds:
			return
	_retry -= delta
	if _retry > 0.0:
		return
	var exit: Variant = find_exit_point(front)
	if exit == null:
		_retry = RETRY_SECONDS
		if not blocked:
			blocked = true
			FloatingText.spawn(structure.get_parent(), structure.global_position + Vector3.UP * Structure.LABEL_HEIGHT, "Exit blocked", CommandMarkers.INVALID_COLOR)
			changed.emit()
		return
	blocked = false
	orders.pop_front()
	progress = 0.0
	_spawn(front, exit)
	changed.emit()


## Candidate exit points, starting on the side that faces the map center and
## alternating outward from there.
func exit_points() -> Array[Vector3]:
	var origin := structure.global_position
	var toward := Vector3(-origin.x, 0.0, -origin.z)
	var base := atan2(toward.z, toward.x) if toward.length_squared() > 0.01 else 0.0
	var distance := structure.definition.footprint_radius + EXIT_GAP
	var points: Array[Vector3] = []
	for i in EXIT_SAMPLES:
		var step := (i + 1) / 2 * (1 if i % 2 == 1 else -1)
		var a := base + TAU * step / EXIT_SAMPLES
		points.append(origin + Vector3(cos(a), 0.0, sin(a)) * distance)
	return points


## A walkable, unoccupied exit point for `definition`, or null.
func find_exit_point(definition: UnitDefinition) -> Variant:
	var map_rid := map.navigation_map()
	for point in exit_points():
		var nav := NavigationServer3D.map_get_closest_point(map_rid, point)
		if _flat(nav, point) > WALKABLE_TOLERANCE or _occupied(nav, definition.radius):
			continue
		return nav
	return null


func _occupied(point: Vector3, radius: float) -> bool:
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit != null and _flat(unit.global_position, point) < radius + unit.definition.radius:
			return true
	return false


func _spawn(definition: UnitDefinition, at: Vector3) -> void:
	_produced += 1
	var unit := Unit.new()
	unit.definition = definition
	unit.faction = structure.faction
	unit.economy = structure.economy
	unit.name = "%s%s%d" % [structure.name, definition.display_name.to_pascal_case(), _produced]
	unit.position = at
	var away := at - structure.global_position
	unit.rotation.y = atan2(-away.x, -away.z)
	units_root.add_child(unit)
	unit_produced.emit(unit)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
