class_name EnergyWell
extends Node3D
## A strategic map point: Power Reactors built within BONUS_RADIUS of a well
## produce more Energy. Wells cannot be built on.

const GROUP := &"energy_wells"
const BONUS_RADIUS := 10.0
## The well's pad; buildings must keep clear of it.
const PAD_RADIUS := 3.4


func _ready() -> void:
	add_to_group(GROUP)


## The well whose bonus covers `pos`, or null.
static func covering(tree: SceneTree, pos: Vector3) -> EnergyWell:
	for node in tree.get_nodes_in_group(GROUP):
		var well := node as EnergyWell
		if well != null and Vector2(well.global_position.x - pos.x, well.global_position.z - pos.z).length() <= BONUS_RADIUS:
			return well
	return null
