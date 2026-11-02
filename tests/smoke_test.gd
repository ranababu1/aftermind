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
## Background work (navigation sync and re-bakes) runs in real time, which
## --fixed-fps frames outpace, so those waits are budgeted in seconds.
const BACKGROUND_WAIT_SECONDS := 20.0
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
	await _check_construction()
	await _check_worker_construction()
	await _check_energy_wells()
	await _check_structure_selection()
	await _check_production()
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
	var deadline := Time.get_ticks_msec() + int(BACKGROUND_WAIT_SECONDS * 1000.0)
	while units_root.get_child_count() < EXPECTED_STARTING_UNITS and Time.get_ticks_msec() < deadline:
		await physics_frame
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
	var deadline := Time.get_ticks_msec() + int(BACKGROUND_WAIT_SECONDS * 1000.0)
	while units_root.get_child_count() < EXPECTED_STARTING_UNITS and Time.get_ticks_msec() < deadline:
		await physics_frame
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


func _find_open_spot(service: ConstructionService, definition: BuildingDefinition, around: Vector3) -> Variant:
	for ring in range(2, 9):
		for step in 12:
			var a := TAU * step / 12.0
			var pos := around + Vector3(cos(a), 0, sin(a)) * ring * 4.0
			if service.check_placement(definition, pos) == ConstructionService.Problem.NONE:
				return pos
	return null


func _check_construction() -> void:
	var skirmish: Node = await _spawn_skirmish()
	var economy := skirmish.get_node("PlayerEconomy") as Economy
	var service := skirmish.get_node("ConstructionService") as ConstructionService
	var map := skirmish.get_node("Battlefield/Map") as MapBuilder
	var Problem := ConstructionService.Problem
	var reactor := load("res://data/buildings/power_reactor.tres") as BuildingDefinition
	var depot := load("res://data/buildings/salvage_depot.tres") as BuildingDefinition
	var start := map.definition.player_start
	var rock: Vector4 = map.definition.rocks[0]

	_expect(service.check_placement(reactor, start) == Problem.BLOCKED, "cannot build on the Command Nexus")
	_expect(service.check_placement(reactor, Vector3(rock.x, 0, rock.y)) == Problem.BLOCKED, "cannot build on a rock")
	_expect(service.check_placement(reactor, Vector3(map.definition.size.x * 0.5, 0, 0)) == Problem.OUT_OF_BOUNDS, "cannot build at the map edge")
	_expect(service.check_placement(reactor, map.definition.scrap_sites[0] + Vector3(4, 0, 0)) == Problem.TOO_CLOSE_TO_DEPOSIT, "cannot build on a scrap pile")
	var unit_spot := (skirmish.get_node("Units").get_child(0) as Unit).global_position
	_expect(service.check_placement(reactor, unit_spot) in [Problem.UNITS_IN_THE_WAY, Problem.BLOCKED], "cannot build on top of units")

	var spot: Variant = _find_open_spot(service, reactor, start)
	_expect(spot != null, "an open building spot exists near the base")
	if spot == null:
		skirmish.queue_free()
		return

	# Unaffordable: refused, nothing spent.
	economy.try_spend({Economy.SCRAP: economy.amount(Economy.SCRAP) - 10})
	var before := economy.amount(Economy.SCRAP)
	_expect(service.check_placement(reactor, spot, economy) == Problem.CANNOT_AFFORD, "unaffordable placement reports the shortage")
	_expect(service.place(reactor, spot, economy, &"remnants") == null and economy.amount(Economy.SCRAP) == before, "unaffordable placement spends nothing")

	economy.add(Economy.SCRAP, 1000)
	before = economy.amount(Economy.SCRAP)
	var site := service.place(reactor, spot, economy, &"remnants")
	_expect(site != null, "valid placement creates a construction site")
	_expect(economy.amount(Economy.SCRAP) == before - reactor.cost_scrap, "placement charges the exact cost")
	_expect(service.check_placement(reactor, spot) == Problem.OVERLAPS_BUILDING, "cannot build on top of another building")
	_expect(not site.is_complete() and site.health > 0.0, "a new site starts incomplete with some health")

	# The footprint is carved out of navigation once the async re-bake lands.
	var deadline := Time.get_ticks_msec() + int(BACKGROUND_WAIT_SECONDS * 1000.0)
	while _carved_gap(map, site.global_position) < reactor.footprint_radius and Time.get_ticks_msec() < deadline:
		await physics_frame
	_expect(_carved_gap(map, site.global_position) >= reactor.footprint_radius, "new building is carved out of the navigation mesh")

	var finished := false
	for i in 1000:
		if site.add_build_work(0.1):
			finished = true
			break
	_expect(finished and site.is_complete(), "construction work completes the building")
	_expect(is_equal_approx(site.health, reactor.max_health), "a finished building has full health")
	var energy_before := economy.amount(Economy.ENERGY)
	for i in 180:
		await process_frame
	_expect(economy.amount(Economy.ENERGY) >= energy_before + 2, "a finished reactor generates energy")

	var depot_spot: Variant = _find_open_spot(service, depot, start)
	var depot_site := service.place(depot, depot_spot, economy, &"remnants") if depot_spot != null else null
	_expect(depot_site != null, "a salvage depot can be placed")
	if depot_site != null:
		while not depot_site.add_build_work(1.0):
			pass
		_expect(DropOff.nearest(self, &"remnants", depot_site.global_position).get_parent() == depot_site, "a finished depot accepts deliveries")
		depot_site.take_damage(depot.max_health * 2.0)
		await process_frame
		_expect(not is_instance_valid(depot_site), "a destroyed building is removed")
	skirmish.queue_free()
	await process_frame


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _check_worker_construction() -> void:
	var skirmish: Node = await _spawn_skirmish()
	var economy := skirmish.get_node("PlayerEconomy") as Economy
	var service := skirmish.get_node("ConstructionService") as ConstructionService
	var commands := skirmish.get_node("CommandController") as CommandController
	var placement := skirmish.get_node("PlacementController") as PlacementController
	var rig := skirmish.get_node("CameraRig") as RtsCamera
	var map := skirmish.get_node("Battlefield/Map") as MapBuilder
	var reactor := load("res://data/buildings/power_reactor.tres") as BuildingDefinition
	var workers: Array[Unit] = []
	for node in skirmish.get_node("Units").get_children():
		if (node as Unit).definition.can_gather:
			workers.append(node)
	economy.add(Economy.SCRAP, 2000)

	# Placement mode: refuses a rock (and stays open), places on open ground.
	var rock: Vector4 = map.definition.rocks[0]
	placement.begin(reactor)
	rig.focus_on(Vector3(rock.x, 0, rock.y))
	for i in 3:
		await process_frame
	_expect(placement.confirm() == null and placement.is_active(), "placement on a rock is refused and stays in placement mode")
	var spot: Variant = _find_open_spot(service, reactor, map.definition.player_start)
	rig.focus_on(spot)
	for i in 3:
		await process_frame
	var scrap_before := economy.amount(Economy.SCRAP)
	var site := placement.confirm()
	_expect(site != null and not placement.is_active(), "placement mode places on open ground and exits")
	_expect(economy.amount(Economy.SCRAP) == scrap_before - reactor.cost_scrap, "placing from placement mode charges the cost")
	placement.begin(reactor)
	placement.cancel()
	_expect(not placement.is_active(), "cancel leaves placement mode")
	if site == null:
		skirmish.queue_free()
		return

	# Workers walk over and raise it.
	_expect(commands.issue_build(workers, site), "build order accepted")
	var frames := 0
	while not site.is_complete() and frames < GATHER_FRAME_BUDGET:
		await physics_frame
		frames += 1
	_expect(site.is_complete(), "workers finish construction (%d frames)" % frames)
	await physics_frame
	_expect(workers.all(func(w: Unit) -> bool: return w.job == null), "workers stop when construction is done")
	_expect(not commands.issue_build(workers, site), "a healthy finished building needs no work")

	# Repair restores health and costs scrap.
	site.take_damage(reactor.max_health * 0.5)
	scrap_before = economy.amount(Economy.SCRAP)
	_expect(commands.issue_build(workers, site), "repair order accepted for a damaged building")
	frames = 0
	while site.is_damaged() and frames < GATHER_FRAME_BUDGET:
		await physics_frame
		frames += 1
	_expect(not site.is_damaged(), "workers repair to full health")
	var spent := scrap_before - economy.amount(Economy.SCRAP)
	# Each worker pre-pays one Scrap at a time, so allow one spare per worker.
	var fair := ceili(reactor.cost_scrap * BuildJob.REPAIR_COST_FACTOR * 0.5) + workers.size()
	_expect(spent > 0 and spent <= fair, "repair costs a fair amount of scrap (%d)" % spent)

	# Repair stops cleanly when scrap runs out.
	site.take_damage(reactor.max_health * 0.5)
	economy.try_spend({Economy.SCRAP: economy.amount(Economy.SCRAP)})
	commands.issue_build(workers, site)
	frames = 0
	while workers.any(func(w: Unit) -> bool: return w.job != null) and frames < GATHER_FRAME_BUDGET:
		await physics_frame
		frames += 1
	_expect(workers.all(func(w: Unit) -> bool: return w.job == null), "repair stops when scrap runs out")
	_expect(economy.amount(Economy.SCRAP) >= 0, "scrap never goes negative during repair")
	skirmish.queue_free()
	await process_frame


func _check_energy_wells() -> void:
	var skirmish: Node = await _spawn_skirmish()
	var economy := skirmish.get_node("PlayerEconomy") as Economy
	var service := skirmish.get_node("ConstructionService") as ConstructionService
	var map := skirmish.get_node("Battlefield/Map") as MapBuilder
	var reactor := load("res://data/buildings/power_reactor.tres") as BuildingDefinition
	var well_pos: Vector3 = map.definition.energy_sites[0]
	economy.add(Economy.SCRAP, 2000)
	_expect(service.check_placement(reactor, well_pos) == ConstructionService.Problem.ON_ENERGY_WELL, "cannot build on an energy well")
	var near: Variant = null
	for step in 16:
		var a := TAU * step / 16.0
		var pos := well_pos + Vector3(cos(a), 0, sin(a)) * (EnergyWell.BONUS_RADIUS - 1.0)
		if service.check_placement(reactor, pos) == ConstructionService.Problem.NONE:
			near = pos
			break
	_expect(near != null, "there is room for a reactor beside the energy well")
	var far: Variant = _find_open_spot(service, reactor, map.definition.player_start)
	if near == null or far == null:
		skirmish.queue_free()
		return
	_expect(is_equal_approx(Structure.energy_rate_at(self, reactor, near), reactor.energy_per_minute * reactor.energy_well_multiplier), "reactor beside a well gets the bonus")
	_expect(is_equal_approx(Structure.energy_rate_at(self, reactor, far), float(reactor.energy_per_minute)), "reactor away from wells gets the base rate")
	var bonus_site := service.place(reactor, near, economy, &"remnants")
	while bonus_site != null and not bonus_site.add_build_work(1.0):
		pass
	_expect(bonus_site != null and is_equal_approx(bonus_site.energy_rate, reactor.energy_per_minute * reactor.energy_well_multiplier), "finished reactor beside a well produces double")
	skirmish.queue_free()
	await process_frame


func _carved_gap(map: MapBuilder, point: Vector3) -> float:
	return _flat(NavigationServer3D.map_get_closest_point(map.navigation_map(), point), point)


func _check_structure_selection() -> void:
	var skirmish: Node = await _spawn_skirmish()
	var economy := skirmish.get_node("PlayerEconomy") as Economy
	var service := skirmish.get_node("ConstructionService") as ConstructionService
	var selection := skirmish.get_node("SelectionController") as SelectionController
	var map := skirmish.get_node("Battlefield/Map") as MapBuilder
	var reactor := load("res://data/buildings/power_reactor.tres") as BuildingDefinition
	var spot: Variant = _find_open_spot(service, reactor, map.definition.player_start)
	_expect(spot != null, "open spot for the selection check")
	if spot == null:
		skirmish.queue_free()
		return
	var before := economy.amount(Economy.SCRAP)
	var site := service.place(reactor, spot, economy, &"remnants")
	_expect(site != null, "site placed for the selection check")
	if site == null:
		skirmish.queue_free()
		return
	selection.select_all()
	selection.select_structure(site)
	_expect(selection.selected_structure() == site and site.selected, "a building can be selected")
	_expect(not selection.has_selection(), "selecting a building clears the unit selection")
	_expect(Hud.structure_status(site).begins_with("Building 0%"), "info shows construction progress")
	selection.select_all()
	_expect(selection.selected_structure() == null and not site.selected, "selecting units clears the building selection")
	selection.select_structure(site)
	var refund := floori(reactor.cost_scrap * Structure.CANCEL_REFUND)
	_expect(site.cancel_construction(), "an unfinished site can be cancelled")
	_expect(economy.amount(Economy.SCRAP) == before - reactor.cost_scrap + refund, "cancelling refunds 75% of the cost")
	await process_frame
	_expect(selection.selected_structure() == null, "a cancelled site leaves the selection")
	var other: Variant = _find_open_spot(service, reactor, map.definition.player_start)
	var built: Structure = service.place(reactor, other, economy, &"remnants") if other != null else null
	while built != null and not built.add_build_work(1.0):
		pass
	_expect(built != null and not built.cancel_construction(), "a finished building cannot be cancelled")
	_expect(built != null and Hud.structure_status(built).contains("Energy/min"), "info shows the reactor's output")
	skirmish.queue_free()
	await process_frame


func _check_production() -> void:
	var skirmish: Node = await _spawn_skirmish()
	var economy := skirmish.get_node("PlayerEconomy") as Economy
	var service := skirmish.get_node("ConstructionService") as ConstructionService
	var map := skirmish.get_node("Battlefield/Map") as MapBuilder
	var units_root := skirmish.get_node("Units") as Node3D
	var bay_def := load("res://data/buildings/fabrication_bay.tres") as BuildingDefinition
	var rifle := load("res://data/units/rifle.tres") as UnitDefinition
	economy.add(Economy.SCRAP, 2000)
	economy.add(Economy.ENERGY, 500)
	var spot: Variant = _find_open_spot(service, bay_def, map.definition.player_start)
	_expect(spot != null, "open spot for a fabrication bay")
	if spot == null:
		skirmish.queue_free()
		return
	var bay := service.place(bay_def, spot, economy, &"remnants")
	_expect(bay != null and bay.production == null, "an unfinished bay cannot produce")
	while bay != null and not bay.add_build_work(1.0):
		pass
	var queue := bay.production if bay != null else null
	_expect(queue != null, "a finished bay has a production queue")
	if queue == null:
		skirmish.queue_free()
		return
	queue.set_process(false)
	var scrap := economy.amount(Economy.SCRAP)
	_expect(queue.enqueue(rifle), "a rifle unit can be queued")
	_expect(economy.amount(Economy.SCRAP) == scrap - rifle.cost_scrap, "queuing pays the unit cost")
	for i in ProductionQueue.MAX_ORDERS - 1:
		queue.enqueue(rifle)
	_expect(not queue.enqueue(rifle), "the queue refuses orders past its limit")
	_expect(economy.amount(Economy.SCRAP) == scrap - rifle.cost_scrap * ProductionQueue.MAX_ORDERS, "a refused order costs nothing")
	_expect(queue.cancel_last(), "the newest order can be cancelled")
	_expect(economy.amount(Economy.SCRAP) == scrap - rifle.cost_scrap * (ProductionQueue.MAX_ORDERS - 1), "cancelling refunds in full")
	while queue.orders.size() > 1:
		queue.cancel_last()
	# Block every exit with a parked unit: the finished rifle must wait.
	var blockers: Array[Unit] = []
	for point in queue.exit_points():
		var blocker := Unit.new()
		blocker.definition = rifle
		blocker.position = NavigationServer3D.map_get_closest_point(map.navigation_map(), point)
		units_root.add_child(blocker)
		blockers.append(blocker)
	var before := units_root.get_child_count()
	queue.progress = rifle.build_seconds
	queue.set_process(true)
	for i in 30:
		await physics_frame
	_expect(queue.blocked and units_root.get_child_count() == before, "a finished unit waits while every exit is blocked")
	for blocker in blockers:
		blocker.queue_free()
	var deadline := Time.get_ticks_msec() + int(BACKGROUND_WAIT_SECONDS * 1000.0)
	while not queue.orders.is_empty() and Time.get_ticks_msec() < deadline:
		await physics_frame
	_expect(queue.orders.is_empty() and not queue.blocked, "production resumes once an exit clears")
	var produced: Unit = null
	for node in units_root.get_children():
		if node is Unit and not blockers.has(node) and String(node.name).begins_with(bay.name):
			produced = node
	_expect(produced != null and produced.definition == rifle, "the bay produced a rifle unit")
	if produced != null:
		_expect(_flat(produced.global_position, bay.global_position) > bay_def.footprint_radius, "the unit appears outside the building")
	skirmish.queue_free()
	await process_frame
