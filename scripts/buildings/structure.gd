class_name Structure
extends Node3D
## A placed building. Starts as a construction site that workers raise to
## completion; once complete it applies its role (drop-off, energy).

signal completed(structure: Structure)
signal health_changed(structure: Structure)
signal destroyed(structure: Structure)

const GROUP := &"structures"
## A fresh site starts with this share of its health so it is not instantly
## destroyed; health then grows with construction.
const START_HEALTH_FRACTION := 0.1
const MIN_RISE := 0.12
const LABEL_HEIGHT := 6.5

@export var definition: BuildingDefinition
@export var faction: StringName = &"remnants"

var economy: Economy
var health: float = 0.0
var progress: float = 0.0

var _model: Node3D
var _scaffold: Node3D
var _label: Label3D
var _energy_carry: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)
	_model = BuildingVisuals.build(definition.building_id, definition.footprint_radius)
	add_child(_model)
	_scaffold = BuildingVisuals.scaffold(definition.footprint_radius, 5.0)
	add_child(_scaffold)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = 72
	_label.pixel_size = 0.012
	_label.outline_size = 10
	_label.outline_modulate = Color(0, 0, 0, 0.8)
	_label.modulate = BuildingVisuals.SCAFFOLD
	_label.position = Vector3(0, LABEL_HEIGHT, 0)
	add_child(_label)
	if health <= 0.0:
		health = definition.max_health * START_HEALTH_FRACTION
	_refresh_visuals()


func is_complete() -> bool:
	return progress >= 1.0


func is_damaged() -> bool:
	return is_complete() and health < definition.max_health


## Adds `seconds` of one worker's construction effort. Returns true when this
## call completed the structure.
func add_build_work(seconds: float) -> bool:
	if is_complete() or seconds <= 0.0:
		return false
	var step := seconds / maxf(definition.build_seconds, 0.01)
	progress = minf(progress + step, 1.0)
	health = minf(health + step * definition.max_health * (1.0 - START_HEALTH_FRACTION), definition.max_health)
	health_changed.emit(self)
	_refresh_visuals()
	if is_complete():
		_complete()
		return true
	return false


func repair(amount: float) -> void:
	if not is_damaged() or amount <= 0.0:
		return
	health = minf(health + amount, definition.max_health)
	health_changed.emit(self)


func take_damage(amount: float) -> void:
	if health <= 0.0 or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(self)
	if health <= 0.0:
		remove_from_group(GROUP)
		destroyed.emit(self)
		queue_free()


func _process(delta: float) -> void:
	if not is_complete() or definition.energy_per_minute <= 0 or economy == null:
		return
	_energy_carry += definition.energy_per_minute * delta / 60.0
	if _energy_carry >= 1.0:
		var whole := int(_energy_carry)
		_energy_carry -= whole
		economy.add(Economy.ENERGY, whole)


func _complete() -> void:
	if definition.is_drop_off:
		var drop := DropOff.new()
		drop.name = "DropOff"
		drop.faction = faction
		drop.radius = definition.footprint_radius
		add_child(drop)
	completed.emit(self)


func _refresh_visuals() -> void:
	if _model == null:
		return
	var done := is_complete()
	_model.scale = Vector3(1.0, maxf(progress, MIN_RISE), 1.0)
	_scaffold.visible = not done
	_label.visible = not done
	_label.text = "%d%%" % int(progress * 100.0)
