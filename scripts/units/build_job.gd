class_name BuildJob
extends Node
## Worker job: walk to a structure and construct it, or repair it if it is
## complete but damaged. Repair is paid in Scrap as it happens; the job ends
## when the work is done, the structure is gone, or Scrap runs out.

## Share of a building's Scrap cost that repairing it from zero to full costs.
const REPAIR_COST_FACTOR := 0.5
const WORK_REACH_MARGIN := 3.0
const STAND_MARGIN := 1.4
const MAX_FAILED_TRIPS := 3
const SPREAD_STEP := 0.6
const SPREAD_SLOTS := 5
const DONE_COLOR := Color(0.35, 0.95, 1.0)
const PROBLEM_COLOR := Color(1.0, 0.4, 0.35)

var target: Structure
var working: bool = false

var _unit: Unit
var _failures: int = 0
var _slot: int = 0
var _paid_repair_hp: float = 0.0


func _init(structure: Structure) -> void:
	name = "BuildJob"
	target = structure


func _ready() -> void:
	_unit = get_parent() as Unit
	_slot = int(_unit.get_instance_id() % SPREAD_SLOTS)
	_unit.set_pass_through(true)
	_unit.order_finished.connect(_on_unit_arrived)
	_approach()


func _exit_tree() -> void:
	if _unit == null:
		return
	_unit.set_pass_through(false)
	if _unit.order_finished.is_connected(_on_unit_arrived):
		_unit.order_finished.disconnect(_on_unit_arrived)


func _physics_process(delta: float) -> void:
	if not working:
		return
	if not _target_valid():
		_unit.cancel_job()
		return
	if not target.is_complete():
		if target.add_build_work(delta):
			FloatingText.spawn(_unit.get_parent(), target.global_position + Vector3.UP * 6.0, "%s ready" % target.definition.display_name, DONE_COLOR)
			_unit.cancel_job()
		return
	if target.is_damaged():
		_repair(delta)
		return
	_unit.cancel_job()


func _repair(delta: float) -> void:
	var definition := target.definition
	var step := definition.max_health / maxf(definition.build_seconds, 0.01) * delta
	var repair_scrap := definition.cost_scrap * REPAIR_COST_FACTOR
	if repair_scrap > 0.0 and _paid_repair_hp < step:
		var hp_per_scrap := definition.max_health / repair_scrap
		if _unit.economy == null or not _unit.economy.try_spend({Economy.SCRAP: 1}):
			_finish("Need scrap")
			return
		_paid_repair_hp += hp_per_scrap
	target.repair(step)
	_paid_repair_hp = maxf(_paid_repair_hp - step, 0.0)


func _approach() -> void:
	if not _target_valid():
		_unit.cancel_job()
		return
	working = false
	var center := target.global_position
	var away := _unit.global_position - center
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3.BACK
	var swing := (float(_slot) - float(SPREAD_SLOTS - 1) * 0.5 + float(_failures) * 2.0) * SPREAD_STEP
	_unit.move_to(center + away.normalized().rotated(Vector3.UP, swing) * (target.definition.footprint_radius + STAND_MARGIN))


func _on_unit_arrived(_unit_arg: Unit) -> void:
	if not _target_valid():
		_unit.cancel_job()
		return
	var reach := target.definition.footprint_radius + WORK_REACH_MARGIN
	if Vector2(target.global_position.x - _unit.global_position.x, target.global_position.z - _unit.global_position.z).length() <= reach:
		_failures = 0
		working = true
		return
	_failures += 1
	if _failures >= MAX_FAILED_TRIPS:
		_finish("Can't reach")
		return
	_approach()


func _target_valid() -> bool:
	return target != null and is_instance_valid(target) and target.is_inside_tree() and target.health > 0.0


func _finish(reason: String) -> void:
	FloatingText.spawn(_unit.get_parent(), _unit.global_position + Vector3.UP * 3.2, reason, PROBLEM_COLOR)
	_unit.cancel_job()
