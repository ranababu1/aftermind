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
