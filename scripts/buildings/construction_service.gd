class_name ConstructionService
extends Node
## Validates building placement, charges the cost, and spawns construction
## sites. Keeps navigation in step with the buildings that exist.

signal structure_placed(structure: Structure)

enum Problem { NONE, OUT_OF_BOUNDS, BLOCKED, OVERLAPS_BUILDING, TOO_CLOSE_TO_DEPOSIT, UNITS_IN_THE_WAY, CANNOT_AFFORD, ON_ENERGY_WELL }

const PROBLEM_TEXT := {
	Problem.NONE: "",
	Problem.OUT_OF_BOUNDS: "Too close to the edge",
	Problem.BLOCKED: "Ground is blocked",
	Problem.OVERLAPS_BUILDING: "Overlaps a building",
	Problem.TOO_CLOSE_TO_DEPOSIT: "Too close to a deposit",
	Problem.UNITS_IN_THE_WAY: "Units in the way",
	Problem.CANNOT_AFFORD: "Not enough resources",
	Problem.ON_ENERGY_WELL: "Build beside the well, not on it",
}
## Keep buildings this far inside the playable edge.
const EDGE_MARGIN := 4.0
const STRUCTURE_GAP := 1.5
const DEPOSIT_CLEARANCE := 3.5
## Footprint edge points checked against the navigation mesh.
const GROUND_SAMPLES := 10
const WALKABLE_TOLERANCE := 0.4
const MAX_GROUND_HEIGHT := 0.6
const BLOCKER_HEIGHT := 4.0

var _map: MapBuilder
var _root: Node3D


func setup(map: MapBuilder, structures_root: Node3D) -> void:
	_map = map
	_root = structures_root


static func describe(problem: Problem) -> String:
	return PROBLEM_TEXT.get(problem, "")


func check_placement(definition: BuildingDefinition, pos: Vector3, economy: Economy = null) -> Problem:
	var r := definition.footprint_radius
	var half := _map.definition.half_extents()
	if absf(pos.x) + r > half.x - EDGE_MARGIN or absf(pos.z) + r > half.y - EDGE_MARGIN:
		return Problem.OUT_OF_BOUNDS
	for node in get_tree().get_nodes_in_group(Structure.GROUP):
		var other := node as Structure
		if other != null and _flat(other.global_position, pos) < r + other.definition.footprint_radius + STRUCTURE_GAP:
			return Problem.OVERLAPS_BUILDING
	if not _ground_is_open(pos, r):
		return Problem.BLOCKED
	for node in get_tree().get_nodes_in_group(ResourceNode.GROUP):
		if _flat((node as Node3D).global_position, pos) < r + DEPOSIT_CLEARANCE:
			return Problem.TOO_CLOSE_TO_DEPOSIT
	for node in get_tree().get_nodes_in_group(EnergyWell.GROUP):
		if _flat((node as Node3D).global_position, pos) < r + EnergyWell.PAD_RADIUS + STRUCTURE_GAP:
			return Problem.ON_ENERGY_WELL
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit != null and _flat(unit.global_position, pos) < r + unit.definition.radius:
			return Problem.UNITS_IN_THE_WAY
	if economy != null and not economy.can_afford(definition.cost()):
		return Problem.CANNOT_AFFORD
	return Problem.NONE


## Charges the cost and spawns a construction site. Returns null (and spends
## nothing) when the placement is invalid or unaffordable.
func place(definition: BuildingDefinition, pos: Vector3, economy: Economy, faction: StringName) -> Structure:
	if check_placement(definition, pos, economy) != Problem.NONE:
		return null
	if not economy.try_spend(definition.cost()):
		return null
	var structure := Structure.new()
	structure.definition = definition
	structure.faction = faction
	structure.economy = economy
	structure.name = definition.display_name.to_pascal_case()
	structure.position = Vector3(pos.x, 0.0, pos.z)
	_root.add_child(structure)
	_map.add_footprint_blocker(structure, definition.footprint_radius, BLOCKER_HEIGHT)
	structure.destroyed.connect(_on_structure_destroyed)
	_map.rebake_navigation()
	structure_placed.emit(structure)
	return structure


func _ground_is_open(pos: Vector3, radius: float) -> bool:
	var map_rid := _map.navigation_map()
	var points: Array[Vector3] = [pos]
	for i in GROUND_SAMPLES:
		var a := TAU * i / GROUND_SAMPLES
		points.append(pos + Vector3(cos(a), 0, sin(a)) * radius)
	for point in points:
		var nav := NavigationServer3D.map_get_closest_point(map_rid, point)
		if _flat(nav, point) > WALKABLE_TOLERANCE or absf(nav.y) > MAX_GROUND_HEIGHT:
			return false
	return true


func _on_structure_destroyed(_structure: Structure) -> void:
	# The blocker leaves the tree at the end of this frame; bake after that.
	await get_tree().process_frame
	_map.rebake_navigation()


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
