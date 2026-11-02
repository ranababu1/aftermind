class_name Combat
extends RefCounted
## Shared rules for anything that can be attacked: units and structures.

const REMNANTS := &"remnants"
const COLLECTIVE := &"collective"


## Untyped on purpose: callers may hold a reference to an already freed node.
static func is_alive(target: Variant) -> bool:
	if target == null or not is_instance_valid(target) or not (target as Node).is_inside_tree():
		return false
	if target is Unit:
		return (target as Unit).health > 0.0
	if target is Structure:
		return (target as Structure).health > 0.0
	return false


static func faction_of(target: Node3D) -> StringName:
	if target is Unit:
		return (target as Unit).faction
	if target is Structure:
		return (target as Structure).faction
	return &""


static func radius_of(target: Node3D) -> float:
	if target is Unit:
		return (target as Unit).definition.radius
	if target is Structure:
		return (target as Structure).definition.footprint_radius
	return 0.0


## Ground distance from `from` to the edge of `target`.
static func gap(from: Vector3, target: Node3D) -> float:
	var p := target.global_position
	return maxf(Vector2(p.x - from.x, p.z - from.z).length() - radius_of(target), 0.0)


## Where shots land on `target`.
static func aim_point(target: Node3D) -> Vector3:
	return target.global_position + Vector3.UP * (2.0 if target is Structure else 1.4)


## The closest living unit or structure hostile to `faction` within `max_gap`
## of `from`, or null. Units are preferred over structures at equal range.
static func nearest_enemy(tree: SceneTree, from: Vector3, faction: StringName, max_gap: float) -> Node3D:
	var best: Node3D = null
	var best_gap := max_gap
	for group in [Unit.GROUP, Structure.GROUP]:
		for node in tree.get_nodes_in_group(group):
			var target := node as Node3D
			if faction_of(target) == faction or not is_alive(target):
				continue
			var g := gap(from, target)
			if g < best_gap or (best == null and g <= best_gap):
				best_gap = g
				best = target
	return best
