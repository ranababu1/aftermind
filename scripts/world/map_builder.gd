class_name MapBuilder
extends Node3D
## Instantiates the visual layout of a MapDefinition at runtime.

const GROUND_SHADER := preload("res://shaders/ground.gdshader")
## Ground extends past the playable area so the camera never sees its edge.
const GROUND_MARGIN := 160.0

@export var definition: MapDefinition


func _ready() -> void:
	if definition == null:
		push_error("MapBuilder: no MapDefinition assigned.")
		return
	build()


func build() -> void:
	for child in get_children():
		child.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = definition.decor_seed
	_build_ground()
	for r in definition.rocks:
		_place(MapProps.rock(r.z, r.w, rng), Vector3(r.x, 0, r.y))
	for r in definition.ruins:
		_place(MapProps.ruin(r.z, r.w, rng), Vector3(r.x, 0, r.y))
	for site in definition.scrap_sites:
		_place(MapProps.scrap_pile(rng), site)
	for site in definition.energy_sites:
		_place(MapProps.energy_well(), site)
	_place(MapProps.ai_core(), definition.core_site)
	_place(MapProps.remnant_nexus(), definition.player_start)
	_place(MapProps.collective_nexus(), definition.enemy_start)


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = definition.size + Vector2.ONE * GROUND_MARGIN * 2.0
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("play_half_extents", definition.half_extents())
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = mat
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)


func _place(node: Node3D, pos: Vector3) -> void:
	node.position = pos
	add_child(node)
