class_name Hud
extends CanvasLayer
## In-match overlay. Emits intents; never changes match state directly.

signal pause_requested
signal select_all_requested
signal clear_selection_requested
signal building_chosen(definition: BuildingDefinition)
signal placement_confirmed
signal placement_cancelled
signal cancel_construction_requested
signal produce_requested(definition: UnitDefinition)
signal cancel_production_requested

const PLACEMENT_OK_COLOR := Color(0.55, 1.0, 0.6)
const PLACEMENT_BAD_COLOR := Color(1.0, 0.45, 0.4)
const HEALTH_FILL_COLOR := Color(0.35, 0.95, 1.0)
const HEALTH_TRACK_COLOR := Color(1, 1, 1, 0.12)

## Seconds the control hint stays fully visible before fading out.
@export var hint_duration: float = 8.0

@onready var _pause_button: Button = %PauseButton
@onready var _map_label: Label = %MapLabel
@onready var _hint: Control = %Hint
@onready var _selection_chip: Control = %SelectionChip
@onready var _selection_count: Label = %SelectionCount
@onready var _selection_detail: Label = %SelectionDetail
@onready var _structure_chip: Control = %StructureChip
@onready var _structure_name: Label = %StructureName
@onready var _structure_status: Label = %StructureStatus
@onready var _structure_health: ProgressBar = %StructureHealth
@onready var _cancel_build_button: Button = %CancelBuildButton
@onready var _production_row: HBoxContainer = %ProductionRow
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
	_cancel_build_button.pressed.connect(cancel_construction_requested.emit)
	_style_health_bar(_structure_health)
	show_selection([])
	var tween := create_tween()
	tween.tween_interval(hint_duration)
	tween.tween_property(_hint, "modulate:a", 0.0, 1.2)


var _economy: Economy
var _buildable: Array[BuildingDefinition] = []
var _structure: Structure
var _queue: ProductionQueue
var _produce_buttons: Array[Button] = []
var _queue_title: Label
var _queue_status: Label
var _queue_bar: ProgressBar
var _cancel_order_button: Button


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
	_clear_button.visible = has_units or _structure != null
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


func show_structure(structure: Structure) -> void:
	if is_instance_valid(_structure):
		_structure.health_changed.disconnect(_on_structure_changed)
		_structure.completed.disconnect(_on_structure_changed)
	_structure = structure
	if _structure != null:
		_structure.health_changed.connect(_on_structure_changed)
		_structure.completed.connect(_on_structure_changed)
	_structure_chip.visible = _structure != null
	_bind_production()
	_clear_button.visible = _structure != null or _selection_chip.visible
	_refresh_structure()


func _on_structure_changed(_changed: Structure) -> void:
	if _structure != null and _structure.production != _queue:
		_bind_production()
	_refresh_structure()


## Rebuilds the production row for the selected structure's queue.
func _bind_production() -> void:
	if is_instance_valid(_queue) and _queue.changed.is_connected(_refresh_production):
		_queue.changed.disconnect(_refresh_production)
	_queue = _structure.production if _structure != null else null
	for child in _production_row.get_children():
		child.queue_free()
	_produce_buttons.clear()
	_production_row.visible = _queue != null
	if _queue == null:
		return
	_queue.changed.connect(_refresh_production)
	for definition in _structure.definition.produces:
		var button := Button.new()
		button.custom_minimum_size = Vector2(260, 104)
		button.text = "%s\n%s" % [definition.display_name, BuildPanel.cost_text(definition.cost())]
		button.pressed.connect(func() -> void: produce_requested.emit(definition))
		_production_row.add_child(button)
		_produce_buttons.append(button)
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"ChipPanel"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.custom_minimum_size = Vector2(300, 0)
	_production_row.add_child(chip)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	chip.add_child(rows)
	_queue_title = Label.new()
	_queue_title.theme_type_variation = &"AccentLabel"
	_queue_title.add_theme_font_size_override("font_size", 20)
	rows.add_child(_queue_title)
	_queue_status = Label.new()
	_queue_status.add_theme_font_size_override("font_size", 28)
	rows.add_child(_queue_status)
	_queue_bar = ProgressBar.new()
	_queue_bar.custom_minimum_size = Vector2(0, 10)
	_queue_bar.max_value = 1.0
	_queue_bar.step = 0.0
	_queue_bar.show_percentage = false
	_queue_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_health_bar(_queue_bar)
	rows.add_child(_queue_bar)
	_cancel_order_button = Button.new()
	_cancel_order_button.custom_minimum_size = Vector2(0, 104)
	_cancel_order_button.text = "Cancel Last"
	_cancel_order_button.pressed.connect(cancel_production_requested.emit)
	_production_row.add_child(_cancel_order_button)
	_refresh_production()


func _refresh_production() -> void:
	if _queue == null or _queue_title == null:
		return
	var count := _queue.orders.size()
	_queue_title.text = "QUEUE %d / %d" % [count, ProductionQueue.MAX_ORDERS]
	_queue_bar.value = _queue.front_fraction()
	_cancel_order_button.visible = count > 0
	for button in _produce_buttons:
		button.disabled = not _queue.can_enqueue()
	if count == 0:
		_queue_status.text = "Idle"
		_queue_status.remove_theme_color_override("font_color")
	elif _queue.blocked:
		_queue_status.text = "Exit blocked"
		_queue_status.add_theme_color_override("font_color", PLACEMENT_BAD_COLOR)
	else:
		_queue_status.text = "%s  %d%%" % [_queue.orders[0].display_name, int(_queue.front_fraction() * 100.0)]
		_queue_status.remove_theme_color_override("font_color")


func _refresh_structure() -> void:
	var building := _structure != null and not _structure.is_complete()
	_cancel_build_button.visible = building
	if _structure == null:
		return
	var definition := _structure.definition
	_structure_name.text = definition.display_name.to_upper()
	_structure_health.value = _structure.health / definition.max_health
	_structure_status.text = Hud.structure_status(_structure)
	if building:
		var refund := _structure.cancel_refund()
		_cancel_build_button.text = "Cancel Build  +%d" % int(refund.get(Economy.SCRAP, 0))


static func _style_health_bar(bar: ProgressBar) -> void:
	for part in [["background", HEALTH_TRACK_COLOR], ["fill", HEALTH_FILL_COLOR]]:
		var box := StyleBoxFlat.new()
		box.bg_color = part[1]
		box.set_corner_radius_all(5)
		bar.add_theme_stylebox_override(part[0], box)


## One-line status for the info chip: progress or health, then the role.
static func structure_status(structure: Structure) -> String:
	var definition := structure.definition
	var parts: PackedStringArray = []
	if not structure.is_complete():
		parts.append("Building %d%%" % int(structure.progress * 100.0))
	parts.append("%d / %d HP" % [ceili(structure.health), definition.max_health])
	if structure.is_complete():
		if structure.energy_rate > 0.0:
			parts.append("+%d Energy/min" % int(structure.energy_rate))
		elif definition.is_drop_off:
			parts.append("Scrap drop-off")
	return "  ·  ".join(parts)


func _on_resource_changed(resource: StringName, amount: int) -> void:
	if _resource_chips.has(resource):
		(_resource_chips[resource] as ResourceChip).set_amount(amount)


func _on_spend_failed(cost: Dictionary, economy: Economy) -> void:
	for resource in cost:
		if _resource_chips.has(resource) and economy.amount(resource) < int(cost[resource]):
			(_resource_chips[resource] as ResourceChip).flash_shortage()
