class_name CommandController
extends Node3D
## Validates and issues orders to units, and shows command feedback markers.

signal move_rejected(point: Vector3)

## A tap farther than this from walkable ground is rejected, not snapped.
const MAX_SNAP_DISTANCE := 2.5
const FORMATION_SPACING := 2.2
const GOLDEN_ANGLE := 2.39996323
## Non-gatherers sent to a deposit wait this far from it.
const STAGING_DISTANCE := 11.0

var _map: MapBuilder


func setup(map: MapBuilder) -> void:
	_map = map


## Sends units to spread positions around `point`. Returns false and shows
## invalid-order feedback when `point` is not reachable ground.
func issue_move(units: Array[Unit], point: Vector3) -> bool:
	var live: Array[Unit] = []
	for unit in units:
		if is_instance_valid(unit):
			live.append(unit)
	if live.is_empty() or _map == null:
		return false
	var nav_point: Variant = snap_to_navigation(point)
	if nav_point == null:
		reject(Vector3(point.x, 0, point.z))
		return false
	var center: Vector3 = nav_point
	var offsets := formation_offsets(live.size(), FORMATION_SPACING)
	# Nearest unit takes the center slot so the group settles without crossing.
	live.sort_custom(func(a: Unit, b: Unit) -> bool:
		return a.global_position.distance_squared_to(center) < b.global_position.distance_squared_to(center))
	var map_rid := _map.navigation_map()
	for i in live.size():
		var destination := NavigationServer3D.map_get_closest_point(map_rid, center + offsets[i])
		live[i].command_move(destination)
	add_child(CommandMarkers.move_marker(center))
	return true


## Shows invalid-order feedback at `point` (on the ground or on an obstacle).
func reject(point: Vector3) -> void:
	add_child(CommandMarkers.invalid_marker(point))
	move_rejected.emit(point)


## Closest walkable point to `point`, however far away it is.
func closest_walkable(point: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(_map.navigation_map(), point)


## Sends gatherers in `units` to work `node`; other units move next to it.
func issue_gather(units: Array[Unit], node: ResourceNode) -> bool:
	if node == null or not is_instance_valid(node) or node.is_depleted():
		return false
	var gatherers: Array[Unit] = []
	var others: Array[Unit] = []
	for unit in units:
		if not is_instance_valid(unit):
			continue
		if unit.definition.can_gather:
			gatherers.append(unit)
		else:
			others.append(unit)
	for unit in gatherers:
		unit.assign_job(GatherJob.new(node))
	if not others.is_empty():
		issue_move(others, _staging_point(others, node.global_position))
	if not gatherers.is_empty():
		add_child(CommandMarkers.gather_marker(node.global_position))
	return not gatherers.is_empty()


## Sends workers in `units` to construct or repair `structure`. Returns false
## when no worker can help (nothing to build, or no workers selected).
func issue_build(units: Array[Unit], structure: Structure) -> bool:
	if structure == null or not is_instance_valid(structure):
		return false
	if structure.is_complete() and not structure.is_damaged():
		return false
	var assigned := false
	for unit in units:
		if is_instance_valid(unit) and unit.definition.can_gather:
			unit.assign_job(BuildJob.new(structure))
			assigned = true
	if assigned:
		add_child(CommandMarkers.build_marker(structure.global_position, structure.definition.footprint_radius))
	return assigned


## A spot beside `site` on the side the group comes from, so escorts do not
## crowd the workers' harvesting ring.
func _staging_point(units: Array[Unit], site: Vector3) -> Vector3:
	var centroid := Vector3.ZERO
	for unit in units:
		centroid += unit.global_position
	centroid /= units.size()
	var away := centroid - site
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3.BACK
	return site + away.normalized() * STAGING_DISTANCE


## Closest walkable point to `point`, or null if it is too far away.
func snap_to_navigation(point: Vector3) -> Variant:
	var nav_point := NavigationServer3D.map_get_closest_point(_map.navigation_map(), point)
	if Vector2(nav_point.x - point.x, nav_point.z - point.z).length() > MAX_SNAP_DISTANCE:
		return null
	return nav_point


## Sunflower spiral: evenly packed, roughly circular group positions.
static func formation_offsets(count: int, spacing: float) -> Array[Vector3]:
	var offsets: Array[Vector3] = []
	for i in count:
		var r := spacing * sqrt(float(i))
		var a := float(i) * GOLDEN_ANGLE
		offsets.append(Vector3(cos(a) * r, 0.0, sin(a) * r))
	return offsets
