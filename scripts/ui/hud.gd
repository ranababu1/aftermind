class_name Hud
extends CanvasLayer
## In-match overlay. Emits intents; never changes match state directly.

signal pause_requested
signal select_all_requested
signal clear_selection_requested
signal building_chosen(definition: BuildingDefinition)
signal placement_confirmed
signal placement_cancelled

const PLACEMENT_OK_COLOR := Color(0.55, 1.0, 0.6)
const PLACEMENT_BAD_COLOR := Color(1.0, 0.45, 0.4)

## Seconds the control hint stays fully visible before fading out.
@export var hint_duration: float = 8.0

@onready var _pause_button: Button = %PauseButton
@onready var _map_label: Label = %MapLabel
@onready var _hint: Control = %Hint
@onready var _selection_chip: Control = %SelectionChip
@onready var _selection_count: Label = %SelectionCount
@onready var _selection_detail: Label = %SelectionDetail
@onready var _clear_button: Button = %ClearButton
@onready var _all_button: Button = %AllButton
@onready var _build_button: Button = %BuildButton
@onready var _build_panel: BuildPanel = %BuildPanel
@onready var _bottom_bar: Control = $Margin/Layout/BottomBar
@onready var _placement_bar: Control = %PlacementBar
@onready var _placement_title: Label = %PlacementTitle
@onready var _placement_status: Label = %PlacementStatus
@onready var _confirm_button: Button = %ConfirmPlacementButton
@onready var _cancel_button: Button = %CancelPlacementButton
@onready var _resource_chips: Dictionary = {
	Economy.SCRAP: %ScrapChip,
	Economy.ENERGY: %EnergyChip,
}


func _ready() -> void:
	_pause_button.pressed.connect(pause_requested.emit)
	_all_button.pressed.connect(select_all_requested.emit)
	_clear_button.pressed.connect(clear_selection_requested.emit)
	_build_button.pressed.connect(_toggle_build_panel)
	_build_panel.closed.connect(func() -> void: _build_panel.visible = false)
	_build_panel.building_chosen.connect(_on_building_chosen)
	_confirm_button.pressed.connect(placement_confirmed.emit)
	_cancel_button.pressed.connect(placement_cancelled.emit)
	show_selection([])
	var tween := create_tween()
	tween.tween_interval(hint_duration)
	tween.tween_property(_hint, "modulate:a", 0.0, 1.2)


var _economy: Economy
var _buildable: Array[BuildingDefinition] = []


func bind_economy(economy: Economy) -> void:
	_economy = economy
	for resource in Economy.RESOURCES:
		(_resource_chips[resource] as ResourceChip).set_amount(economy.amount(resource))
	economy.changed.connect(_on_resource_changed)
	economy.spend_failed.connect(_on_spend_failed.bind(economy))


func set_buildable(definitions: Array[BuildingDefinition]) -> void:
	_buildable = definitions


func begin_placement(definition: BuildingDefinition) -> void:
	_build_panel.visible = false
	_bottom_bar.visible = false
	_placement_bar.visible = true
	_placement_title.text = "PLACE %s" % definition.display_name.to_upper()


func show_placement_state(definition: BuildingDefinition, problem: ConstructionService.Problem, energy_rate: float) -> void:
	var ok := problem == ConstructionService.Problem.NONE
	_placement_status.text = "Pan or tap to position" if ok else ConstructionService.describe(problem)
	if ok and energy_rate > definition.energy_per_minute:
		_placement_status.text = "Energy Well bonus: %d Energy/min" % int(energy_rate)
	_placement_status.add_theme_color_override("font_color", PLACEMENT_OK_COLOR if ok else PLACEMENT_BAD_COLOR)
	_confirm_button.disabled = not ok


func end_placement() -> void:
	_placement_bar.visible = false
	_bottom_bar.visible = true


func _toggle_build_panel() -> void:
	if _build_panel.visible:
		_build_panel.visible = false
		return
	_build_panel.populate(_buildable, _economy)
	_build_panel.visible = true


func _on_building_chosen(definition: BuildingDefinition) -> void:
	_build_panel.visible = false
	building_chosen.emit(definition)


func set_map_name(map_name: String) -> void:
	_map_label.text = map_name.to_upper()


func show_selection(units: Array[Unit]) -> void:
	var has_units := not units.is_empty()
	_selection_chip.visible = has_units
	_clear_button.visible = has_units
	var has_builders := units.any(func(u: Unit) -> bool: return u.definition.can_gather)
	_build_button.visible = has_builders
	if not has_builders:
		_build_panel.visible = false
	if not has_units:
		return
	_selection_count.text = "%d SELECTED" % units.size()
	var counts: Dictionary = {}
	for unit in units:
		var unit_name := unit.definition.display_name
		counts[unit_name] = counts.get(unit_name, 0) + 1
	var parts: PackedStringArray = []
	for unit_name in counts:
		parts.append("%s ×%d" % [unit_name, counts[unit_name]])
	_selection_detail.text = "  ·  ".join(parts)


func _on_resource_changed(resource: StringName, amount: int) -> void:
	if _resource_chips.has(resource):
		(_resource_chips[resource] as ResourceChip).set_amount(amount)


func _on_spend_failed(cost: Dictionary, economy: Economy) -> void:
	for resource in cost:
		if _resource_chips.has(resource) and economy.amount(resource) < int(cost[resource]):
			(_resource_chips[resource] as ResourceChip).flash_shortage()
