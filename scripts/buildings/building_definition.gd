class_name BuildingDefinition
extends Resource
## Static, data-driven description of a structure type.

## Stable identifier; also selects the visual model.
@export var building_id: StringName = &""
@export var display_name: String = ""
## One short line shown in the build menu.
@export var summary: String = ""
@export var cost_scrap: int = 0
@export var cost_energy: int = 0
@export var max_health: int = 500
## Seconds for one worker to finish it; more workers build faster.
@export var build_seconds: float = 20.0
@export var footprint_radius: float = 3.0
## Accepts gatherer deliveries once complete.
@export var is_drop_off: bool = false
## Energy produced per minute once complete.
@export var energy_per_minute: int = 0


func cost() -> Dictionary:
	return {Economy.SCRAP: cost_scrap, Economy.ENERGY: cost_energy}
