class_name UnitDefinition
extends Resource
## Static, data-driven description of a unit type.

## Stable identifier; also selects the unit's visual model.
@export var unit_id: StringName = &""
@export var display_name: String = ""
@export var move_speed: float = 5.0
@export var turn_speed: float = 12.0
## Footprint used for avoidance and the selection ring.
@export var radius: float = 0.6

@export_group("Combat")
@export var max_health: int = 100
## Damage per shot; 0 means the unit cannot attack.
@export var attack_damage: float = 0.0
## Reach from the unit to the target's edge.
@export var attack_range: float = 8.0
## Seconds between shots.
@export var attack_seconds: float = 1.0
## Idle units engage enemies this close on their own.
@export var sight_range: float = 12.0
@export var structure_damage_multiplier: float = 1.0

@export_group("Production")
@export var cost_scrap: int = 0
@export var cost_energy: int = 0
## Seconds a production building needs to finish one.
@export var build_seconds: float = 10.0

@export_group("Gathering")
@export var can_gather: bool = false
## Resources carried per trip.
@export var carry_capacity: int = 10
@export var gather_seconds: float = 2.0


func cost() -> Dictionary:
	return {Economy.SCRAP: cost_scrap, Economy.ENERGY: cost_energy}
