extends SceneTree
## Headless smoke test. Run:
##   godot --headless --path . --script res://tests/smoke_test.gd
## Exits with code 0 on success, 1 on any failed check.

const SCENES := [
	"res://scenes/ui/main_menu.tscn",
	"res://scenes/skirmish.tscn",
]
const FRAMES_PER_SCENE := 30

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_map_definition()
	for path in SCENES:
		await _check_scene(path)
	await _check_pause_cycle()
	if _failures.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
	else:
		for failure in _failures:
			printerr("FAIL: ", failure)
		quit(1)


func _check_map_definition() -> void:
	var definition := load("res://data/maps/ashfall_basin.tres") as MapDefinition
	_expect(definition != null, "map definition loads")
	if definition == null:
		return
	_expect(definition.scrap_sites.size() >= 2, "map has several scrap sites")
	_expect(definition.energy_sites.size() >= 1, "map has an energy site")
	var half := definition.half_extents()
	for point in [definition.player_start, definition.enemy_start, definition.core_site]:
		_expect(absf(point.x) <= half.x and absf(point.z) <= half.y, "key site %s inside bounds" % point)


func _check_scene(path: String) -> void:
	var packed := load(path) as PackedScene
	_expect(packed != null, "%s loads" % path)
	if packed == null:
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	for i in FRAMES_PER_SCENE:
		await process_frame
	var map := instance.get_node_or_null("Battlefield/Map")
	_expect(map != null and map.get_child_count() > 10, "%s builds map props" % path)
	instance.queue_free()
	await process_frame


func _check_pause_cycle() -> void:
	var instance: Node = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	root.add_child(instance)
	await process_frame
	var pause_menu := instance.get_node("PauseMenu") as PauseMenu
	pause_menu.open()
	pause_menu.open()
	_expect(paused and pause_menu.visible, "pause menu pauses the tree")
	pause_menu.close()
	_expect(not paused and not pause_menu.visible, "closing pause menu resumes")
	instance.queue_free()
	await process_frame


func _expect(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)
