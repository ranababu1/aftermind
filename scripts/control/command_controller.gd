class_name CommandController
extends Node3D
## Validates and issues orders to units, and shows command feedback markers.

signal move_rejected(point: Vector3)

## A tap farther than this from walkable ground is rejected, not snapped.
const MAX_SNAP_DISTANCE := 2.5
const FORMATION_SPACING := 2.2
const GOLDEN_ANGLE := 2.39996323

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
		live[i].move_to(destination)
	add_child(CommandMarkers.move_marker(center))
	return true


## Shows invalid-order feedback at `point` (on the ground or on an obstacle).
func reject(point: Vector3) -> void:
	add_child(CommandMarkers.invalid_marker(point))
	move_rejected.emit(point)


## Closest walkable point to `point`, however far away it is.
func closest_walkable(point: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(_map.navigation_map(), point)


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
