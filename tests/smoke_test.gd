extends SceneTree
## Headless smoke and scenario test. Run with a fixed frame rate so the
## simulation is deterministic and does not wait in real time:
##   godot --headless --fixed-fps 60 --path . --script res://tests/smoke_test.gd
## Exits with code 0 on success, 1 on any failed check.

const SCENES := [
	"res://scenes/ui/main_menu.tscn",
	"res://scenes/skirmish.tscn",
]
const FRAMES_PER_SCENE := 30
const EXPECTED_STARTING_UNITS := 8
const SPAWN_FRAME_BUDGET := 240
## Frames allowed for a first delivery (60 fps -> 40 s).
const GATHER_FRAME_BUDGET := 2400
## Frames allowed for a group to cross the map (60 fps -> 30 s).
const MOVE_FRAME_BUDGET := 1800
## Slack beyond the formation radius for avoidance jostling at arrival.
const ARRIVAL_SLACK := 2.0

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check_map_definition()
	_check_economy()
	for path in SCENES:
		await _check_scene(path)
	await _check_pause_cycle()
	await _check_movement_and_selection()
	await _check_gathering()
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


func _check_movement_and_selection() -> void:
	var skirmish: Node = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	root.add_child(skirmish)
	# Units spawn once the navigation map has synced, which takes a variable
	# number of frames (region updates are asynchronous).
	var units_root := skirmish.get_node("Units")
	var waited := 0
	while units_root.get_child_count() < EXPECTED_STARTING_UNITS and waited < SPAWN_FRAME_BUDGET:
		await physics_frame
		waited += 1
	var map := skirmish.get_node("Battlefield/Map") as MapBuilder
	var selection := skirmish.get_node("SelectionController") as SelectionController
	var commands := skirmish.get_node("CommandController") as CommandController
	var units := units_root.get_children()
	_expect(units.size() == EXPECTED_STARTING_UNITS, "spawns %d starting units (got %d)" % [EXPECTED_STARTING_UNITS, units.size()])
	if units.size() != EXPECTED_STARTING_UNITS:
		skirmish.queue_free()
		return
	for unit in units:
		_expect(commands.snap_to_navigation(unit.global_position) != null, "%s spawns on walkable ground" % unit.name)

	selection.select_all()
	_expect(selection.selected_units().size() == units.size(), "select all selects every owned unit")
	var camera := (skirmish.get_node("CameraRig") as RtsCamera).get_camera()
	var first := units[0] as Unit
	var picked := selection.pick_unit(camera.unproject_position(first.global_position + Vector3.UP))
	_expect(picked != null, "tapping a unit on screen picks it")

	# Inside a rock formation: rejected, nobody moves.
	var rock: Vector4 = map.definition.rocks[0]
	_expect(not commands.issue_move(selection.selected_units(), Vector3(rock.x, 0, rock.y)), "move into a rock is rejected")
	_expect(units.all(func(u: Unit) -> bool: return not u.is_moving()), "rejected move leaves units idle")
	# Tapping the top of a tall rock must hit the rock, not the ground behind it.
	var rig := skirmish.get_node("CameraRig") as RtsCamera
	var rock_top := camera.unproject_position(Vector3(rock.x, rock.w, rock.y))
	_expect(not rig.raycast(rock_top, 1 << (MapBuilder.OBSTACLE_LAYER - 1)).is_empty(), "tap on a rock top hits the rock")

	# Across the map, past a ruin that blocks the straight line.
	var target: Vector3 = map.definition.scrap_sites[4]
	_expect(commands.issue_move(selection.selected_units(), target), "move to open ground is accepted")
	var frames := 0
	while frames < MOVE_FRAME_BUDGET and units.any(func(u: Unit) -> bool: return u.is_moving()):
		await physics_frame
		frames += 1
	_expect(frames < MOVE_FRAME_BUDGET, "group finishes its move within the frame budget")
	var tolerance := CommandController.FORMATION_SPACING * sqrt(float(units.size())) + ARRIVAL_SLACK
	for unit in units:
		var dist := Vector2(unit.global_position.x - target.x, unit.global_position.z - target.z).length()
		_expect(dist <= tolerance, "%s arrives near the target (%.1f m away)" % [unit.name, dist])

	# A selected unit disappearing must not break selection or orders.
	var before := selection.selected_units().size()
	(units[1] as Unit).queue_free()
	await process_frame
	_expect(selection.selected_units().size() == before - 1, "freed unit leaves the selection")
	_expect(commands.issue_move(selection.selected_units(), map.definition.player_start + Vector3(8, 0, -8)), "orders still work after a unit is freed")
	selection.clear()
	_expect(not selection.has_selection(), "clear empties the selection")
	skirmish.queue_free()
	await process_frame


func _check_economy() -> void:
	var economy := Economy.new()
	economy.starting_scrap = 100
	economy.starting_energy = 20
	root.add_child(economy)
	_expect(economy.amount(Economy.SCRAP) == 100 and economy.amount(Economy.ENERGY) == 20, "economy starts with configured balances")
	_expect(economy.try_spend({Economy.SCRAP: 60}), "affordable spend succeeds")
	_expect(economy.amount(Economy.SCRAP) == 40, "spend deducts exactly")
	_expect(not economy.try_spend({Economy.SCRAP: 41}), "overspend is refused")
	_expect(economy.amount(Economy.SCRAP) == 40, "refused spend changes nothing")
	_expect(not economy.try_spend({Economy.SCRAP: 10, Economy.ENERGY: 21}), "partly affordable cost is refused")
	_expect(economy.amount(Economy.SCRAP) == 40 and economy.amount(Economy.ENERGY) == 20, "refused multi-resource spend is atomic")
	_expect(not economy.try_spend({Economy.SCRAP: -5}), "negative cost is refused")
	economy.add(Economy.SCRAP, -50)
	_expect(economy.amount(Economy.SCRAP) == 40, "negative income is ignored")
	economy.add(Economy.ENERGY, 5)
	_expect(economy.amount(Economy.ENERGY) == 25, "income adds")
	economy.queue_free()


func _spawn_skirmish() -> Node:
	var skirmish: Node = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	root.add_child(skirmish)
	var units_root := skirmish.get_node("Units")
	var waited := 0
	while units_root.get_child_count() < EXPECTED_STARTING_UNITS and waited < SPAWN_FRAME_BUDGET:
		await physics_frame
		waited += 1
	return skirmish


func _nearest_deposit(from: Vector3, exclude: Node = null) -> ResourceNode:
	var best: ResourceNode = null
	for node in get_nodes_in_group(ResourceNode.GROUP):
		if node == exclude:
			continue
		if best == null or node.global_position.distance_to(from) < best.global_position.distance_to(from):
			best = node
	return best


func _check_gathering() -> void:
	var skirmish: Node = await _spawn_skirmish()
	var economy := skirmish.get_node("PlayerEconomy") as Economy
	var commands := skirmish.get_node("CommandController") as CommandController
	var map := skirmish.get_node("Battlefield/Map") as MapBuilder
	var workers: Array[Unit] = []
	var riflemen: Array[Unit] = []
	for node in skirmish.get_node("Units").get_children():
		var unit := node as Unit
		(workers if unit.definition.can_gather else riflemen).append(unit)
	_expect(workers.size() == 3, "three workers available")
	_expect(not commands.issue_gather(riflemen, _nearest_deposit(map.definition.player_start)), "gather with no workers is refused")

	# Full loop: harvest, carry, deliver.
	var start_scrap := economy.amount(Economy.SCRAP)
	var deposit := _nearest_deposit(map.definition.player_start)
	# Send the whole army, as a player tapping "All Units" would: escorts must
	# not box the workers in.
	var everyone: Array[Unit] = []
	everyone.append_array(workers)
	everyone.append_array(riflemen)
	_expect(commands.issue_gather(everyone, deposit), "gather order accepted")
	var frames := 0
	while economy.amount(Economy.SCRAP) <= start_scrap and frames < GATHER_FRAME_BUDGET:
		await physics_frame
		frames += 1
	_expect(economy.amount(Economy.SCRAP) > start_scrap, "workers deliver scrap to the economy (%d frames)" % frames)
	if economy.amount(Economy.SCRAP) <= start_scrap:
		for worker in workers:
			var gather := worker.job as GatherJob
			print("  diag %s pos=%s moving=%s job=%s state=%s carrying=%s" % [worker.name, worker.global_position, worker.is_moving(), gather != null, gather.state if gather else -1, gather.carrying if gather else 0])
	_expect(deposit.remaining < deposit.capacity, "gathering drains the deposit")
	for rifle in riflemen:
		_expect(rifle.global_position.distance_to(deposit.global_position) > ResourceNode.HARVEST_REACH, "%s waits outside the harvesting ring" % rifle.name)

	# Depletion: the worker moves on to another deposit.
	var lone := workers[0]
	var tiny := _nearest_deposit(lone.global_position, deposit)
	tiny.remaining = lone.definition.carry_capacity
	lone.assign_job(GatherJob.new(tiny))
	frames = 0
	while is_instance_valid(tiny) and frames < GATHER_FRAME_BUDGET:
		await physics_frame
		frames += 1
	_expect(not is_instance_valid(tiny), "a drained deposit removes itself")
	var job := lone.job as GatherJob
	_expect(job != null and job.target != null and is_instance_valid(job.target), "worker retargets after its deposit is depleted")

	# A direct order cancels the job and drops the cargo.
	lone.command_move(map.definition.player_start + Vector3(10, 0, -10))
	_expect(lone.job == null, "move order cancels the gather job")
	skirmish.queue_free()
	await process_frame
