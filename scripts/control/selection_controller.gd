class_name SelectionController
extends Node
## Owns the player's current unit selection. Picking is done in screen space
## with a generous radius so units are easy to hit with a finger.

signal selection_changed(units: Array[Unit])

## Pick radius in viewport pixels at the 1920x1080 reference resolution.
const PICK_RADIUS_PX := 72.0
## Units are picked by their torso, not their feet.
const PICK_HEIGHT := 1.4

@export var faction: StringName = &"remnants"

var _camera: Camera3D
var _selected: Array[Unit] = []


func setup(camera: Camera3D) -> void:
	_camera = camera


func selected_units() -> Array[Unit]:
	return _selected.duplicate()


func has_selection() -> bool:
	return not _selected.is_empty()


## Returns the closest owned unit under a screen position, or null.
func pick_unit(screen_position: Vector2) -> Unit:
	if _camera == null:
		return null
	var best: Unit = null
	var best_distance := PICK_RADIUS_PX
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit == null or unit.faction != faction or not unit.is_inside_tree():
			continue
		var anchor := unit.global_position + Vector3.UP * PICK_HEIGHT
		if _camera.is_position_behind(anchor):
			continue
		var distance := _camera.unproject_position(anchor).distance_to(screen_position)
		if distance < best_distance:
			best_distance = distance
			best = unit
	return best


## Closest node of `group` whose anchor (position + height) is within
## `radius_px` of a screen position, or null.
func pick_in_group(group: StringName, screen_position: Vector2, height: float, radius_px: float) -> Node3D:
	if _camera == null:
		return null
	var best: Node3D = null
	var best_distance := radius_px
	for node in get_tree().get_nodes_in_group(group):
		var spatial := node as Node3D
		if spatial == null or not spatial.is_inside_tree():
			continue
		var anchor := spatial.global_position + Vector3.UP * height
		if _camera.is_position_behind(anchor):
			continue
		var distance := _camera.unproject_position(anchor).distance_to(screen_position)
		if distance < best_distance:
			best_distance = distance
			best = spatial
	return best


func select_only(unit: Unit) -> void:
	if _selected.size() == 1 and _selected[0] == unit:
		return
	_set_selection([unit])


func toggle(unit: Unit) -> void:
	var next := _selected.duplicate()
	if next.has(unit):
		next.erase(unit)
	else:
		next.append(unit)
	_set_selection(next)


func select_all() -> void:
	var owned: Array[Unit] = []
	for node in get_tree().get_nodes_in_group(Unit.GROUP):
		var unit := node as Unit
		if unit != null and unit.faction == faction:
			owned.append(unit)
	_set_selection(owned)


func clear() -> void:
	if _selected.is_empty():
		return
	_set_selection([])


func _set_selection(units: Array) -> void:
	for unit in _selected:
		if is_instance_valid(unit):
			unit.selected = false
			if unit.tree_exiting.is_connected(_on_unit_removed):
				unit.tree_exiting.disconnect(_on_unit_removed)
	_selected.clear()
	for unit in units:
		if is_instance_valid(unit) and not _selected.has(unit):
			_selected.append(unit)
			unit.selected = true
			unit.tree_exiting.connect(_on_unit_removed.bind(unit), CONNECT_ONE_SHOT)
	selection_changed.emit(selected_units())


func _on_unit_removed(unit: Unit) -> void:
	_selected.erase(unit)
	selection_changed.emit(selected_units())
