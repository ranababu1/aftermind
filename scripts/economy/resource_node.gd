class_name ResourceNode
extends Node3D
## A harvestable deposit. Shrinks as it is drained and removes itself when
## empty; gatherers must re-check validity because it can vanish at any time.

signal depleted(node: ResourceNode)

const GROUP := &"resource_nodes"
## Gatherers stand within this distance of the center to harvest.
const HARVEST_REACH := 4.2
const MIN_VISUAL_SCALE := 0.45

@export var resource: StringName = Economy.SCRAP
@export var capacity: int = 600

var remaining: int = 0
var _visual: Node3D


func _ready() -> void:
	add_to_group(GROUP)
	remaining = capacity


func set_visual(visual: Node3D) -> void:
	_visual = visual
	add_child(visual)


func is_depleted() -> bool:
	return remaining <= 0


## Takes up to `max_amount` and returns what was actually taken.
func harvest(max_amount: int) -> int:
	if is_depleted() or max_amount <= 0:
		return 0
	var taken := mini(max_amount, remaining)
	remaining -= taken
	_update_visual()
	if remaining <= 0:
		remove_from_group(GROUP)
		depleted.emit(self)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
		tween.tween_callback(queue_free)
	return taken


func _update_visual() -> void:
	if _visual == null or capacity <= 0:
		return
	var fraction := float(remaining) / float(capacity)
	_visual.scale = Vector3.ONE * lerpf(MIN_VISUAL_SCALE, 1.0, fraction)
