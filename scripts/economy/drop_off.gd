class_name DropOff
extends Node3D
## A place where gatherers deliver resources for a faction (the Command Nexus,
## later also Salvage Depots).

const GROUP := &"drop_offs"
## Gatherers deliver once within radius + this margin of the center.
const DELIVERY_MARGIN := 3.0

@export var faction: StringName = &"remnants"
## Footprint radius; gatherers stop at its edge.
@export var radius: float = 6.0


func _ready() -> void:
	add_to_group(GROUP)


static func nearest(tree: SceneTree, faction_id: StringName, from: Vector3) -> DropOff:
	var best: DropOff = null
	var best_distance := INF
	for node in tree.get_nodes_in_group(GROUP):
		var drop := node as DropOff
		if drop == null or drop.faction != faction_id or drop.is_queued_for_deletion():
			continue
		var d := drop.global_position.distance_squared_to(from)
		if d < best_distance:
			best_distance = d
			best = drop
	return best
