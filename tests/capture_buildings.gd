extends SceneTree
## Visual check (needs a window, not --headless): places one of each building
## near the player base, leaves one under construction, and saves a screenshot.
##   godot --path . --resolution 1920x1080 --script res://tests/capture_buildings.gd -- <out.png>

const BUILDINGS := [
	"res://data/buildings/salvage_depot.tres",
	"res://data/buildings/power_reactor.tres",
	"res://data/buildings/fabrication_bay.tres",
	"res://data/buildings/research_lab.tres",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://buildings.png"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]
	var skirmish: Node = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	root.add_child(skirmish)
	for i in 120:
		await physics_frame
	var economy := skirmish.get_node("PlayerEconomy") as Economy
	economy.add(Economy.SCRAP, 5000)
	economy.add(Economy.ENERGY, 5000)
	var service := skirmish.get_node("ConstructionService") as ConstructionService
	var map := skirmish.get_node("Battlefield/Map") as MapBuilder
	var start := map.definition.player_start
	var placed := 0
	for path in BUILDINGS:
		var definition := load(path) as BuildingDefinition
		for attempt in 60:
			var a := 0.4 + attempt * 0.35
			var pos := start + Vector3(cos(a), 0, sin(a)) * (12.0 + attempt * 0.4)
			var site := service.place(definition, pos, economy, &"remnants")
			if site != null:
				site.add_build_work(definition.build_seconds * (0.45 if placed == 3 else 1.0))
				placed += 1
				break
	var rig := skirmish.get_node("CameraRig") as RtsCamera
	rig.focus_on(start + Vector3(6, 0, -2))
	for i in 60:
		await process_frame
	var image := root.get_texture().get_image()
	image.save_png(out)
	print("placed %d buildings, saved %s" % [placed, out])
	quit(0)
