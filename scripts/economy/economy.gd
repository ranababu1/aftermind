class_name Economy
extends Node
## One faction's resource stockpile. All spending goes through try_spend so a
## multi-resource cost is paid in full or not at all, and balances can never
## go negative.

signal changed(resource: StringName, amount: int)
signal spend_failed(cost: Dictionary)

const SCRAP := &"scrap"
const ENERGY := &"energy"
const RESOURCES: Array[StringName] = [SCRAP, ENERGY]

@export var faction: StringName = &"remnants"
@export var starting_scrap: int = 0
@export var starting_energy: int = 0

var _balances: Dictionary = {}


func _ready() -> void:
	reset()


func reset() -> void:
	_balances = {SCRAP: maxi(starting_scrap, 0), ENERGY: maxi(starting_energy, 0)}
	for resource in RESOURCES:
		changed.emit(resource, _balances[resource])


func amount(resource: StringName) -> int:
	return _balances.get(resource, 0)


func can_afford(cost: Dictionary) -> bool:
	for resource in cost:
		if int(cost[resource]) < 0 or amount(resource) < int(cost[resource]):
			return false
	return true


## Deducts every resource in `cost`, or nothing if any is short.
func try_spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		spend_failed.emit(cost)
		return false
	for resource in cost:
		var price := int(cost[resource])
		if price == 0:
			continue
		_balances[resource] = amount(resource) - price
		changed.emit(resource, _balances[resource])
	return true


func add(resource: StringName, value: int) -> void:
	if value <= 0 or not RESOURCES.has(resource):
		return
	_balances[resource] = amount(resource) + value
	changed.emit(resource, _balances[resource])
