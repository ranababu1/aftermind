class_name AttackJob
extends Node
## Engages one target: closes to weapon range, then fires on a cooldown. An
## automatic engagement (an idle unit reacting to an enemy in sight) gives up
## once the target leaves sight or a guard strays too far from its post. When
## the target dies the unit moves on to the next enemy in sight, if any.

## Re-path a chase once the target has moved this far.
const REPATH_DISTANCE := 1.5
const MUZZLE_HEIGHT := 1.7
## Share of the cooldown waited before the first shot.
const WIND_UP := 0.35

var target: Node3D
var automatic: bool

var _unit: Unit
var _cooldown: float = 0.0
var _chase_point: Variant = null


func _init(attack_target: Node3D, is_automatic: bool = false) -> void:
	name = "AttackJob"
	target = attack_target
	automatic = is_automatic


func _ready() -> void:
	_unit = get_parent() as Unit
	_cooldown = _unit.definition.attack_seconds * WIND_UP


func _physics_process(delta: float) -> void:
	var definition := _unit.definition
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not Combat.is_alive(target):
		var next := Combat.nearest_enemy(get_tree(), _unit.global_position, _unit.faction, definition.sight_range)
		if next == null:
			_unit.cancel_job()
			return
		target = next
		automatic = true
		_chase_point = null
	var gap := Combat.gap(_unit.global_position, target)
	if automatic and (gap > definition.sight_range or _beyond_leash()):
		_unit.cancel_job()
		return
	if gap > definition.attack_range:
		var goal := target.global_position
		if _chase_point == null or not _unit.is_moving() or _flat(goal, _chase_point) > REPATH_DISTANCE:
			_chase_point = goal
			_unit.move_to(goal)
		return
	if _unit.is_moving():
		_unit.stop()
	_chase_point = null
	var to_target := target.global_position - _unit.global_position
	if Vector2(to_target.x, to_target.z).length_squared() > 0.01:
		var yaw := atan2(-to_target.x, -to_target.z)
		_unit.rotation.y = lerp_angle(_unit.rotation.y, yaw, 1.0 - exp(-definition.turn_speed * delta))
	if _cooldown > 0.0:
		return
	_cooldown = definition.attack_seconds
	var damage := definition.attack_damage
	if target is Structure:
		damage *= definition.structure_damage_multiplier
	var muzzle := _unit.global_position + Vector3.UP * MUZZLE_HEIGHT
	CombatEffects.tracer(_unit.get_parent(), muzzle, Combat.aim_point(target), CombatEffects.faction_color(_unit.faction))
	if target is Unit:
		(target as Unit).take_damage(damage)
	elif target is Structure:
		(target as Structure).take_damage(damage)


func _beyond_leash() -> bool:
	return _unit.guard_point != null and _flat(_unit.global_position, _unit.guard_point) > _unit.definition.sight_range


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
