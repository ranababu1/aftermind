class_name MapBuilder
extends Node3D
## Instantiates a MapDefinition at runtime: visuals and a navigation mesh baked
## from the ground, with obstacles carved out by NavigationObstacle3D so their
## tops never become walkable islands.

const GROUND_SHADER := preload("res://shaders/ground.gdshader")
## Ground extends past the playable area so the camera never sees its edge.
const GROUND_MARGIN := 160.0
const DEBRIS_COUNT := 420
## Debris keeps this far from sites and structures so they stay readable.
const DEBRIS_CLEARANCE := 7.0
## Must match navigation/3d/default_cell_size in project.godot.
const NAV_CELL_SIZE := 0.5
const NAV_CELL_HEIGHT := 0.25
const NAV_AGENT_RADIUS := 1.0
const NEXUS_BLOCK_RADIUS := 6.4
const CORE_BLOCK_RADIUS := 5.2
const BLOCKER_SIDES := 12
## Physics layers: the ground is baked into navigation; obstacle bodies exist
## only so taps on them can be detected and are excluded from the bake.
const GROUND_LAYER := 1
const OBSTACLE_LAYER := 2

@export var definition: MapDefinition

var _nav_region: NavigationRegion3D


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
	# Ground and blockers live under the region so baking finds them.
	_nav_region = NavigationRegion3D.new()
	_nav_region.name = "Navigation"
	add_child(_nav_region)
	_add_ground_collider()
	for r in definition.rocks:
		var rock := _place(MapProps.rock(r.z, r.w, rng), Vector3(r.x, 0, r.y), _nav_region)
		_add_round_blocker(rock, r.z * 1.1, r.w)
	for r in definition.ruins:
		var ruin := _place(MapProps.ruin(r.z, r.w, rng), Vector3(r.x, 0, r.y), _nav_region)
		_add_box_blocker(ruin, Vector3(r.z * 1.6, r.w, r.z * 0.9), Vector3(-r.z * 0.3, 0, 0))
	for site in definition.scrap_sites:
		_place(MapProps.scrap_pile(rng), site, self)
	for site in definition.energy_sites:
		_place(MapProps.energy_well(), site, self)
	var core := _place(MapProps.ai_core(), definition.core_site, _nav_region)
	_add_round_blocker(core, CORE_BLOCK_RADIUS, 2.0)
	var player_nexus := _place(MapProps.remnant_nexus(), definition.player_start, _nav_region)
	_add_round_blocker(player_nexus, NEXUS_BLOCK_RADIUS, 4.0)
	var enemy_nexus := _place(MapProps.collective_nexus(), definition.enemy_start, _nav_region)
	_add_round_blocker(enemy_nexus, NEXUS_BLOCK_RADIUS, 4.0)
	add_child(MapProps.debris_field(DEBRIS_COUNT, definition.half_extents(), _debris_exclusions(), DEBRIS_CLEARANCE, rng))
	_bake_navigation()


func navigation_map() -> RID:
	return get_world_3d().navigation_map


## True once the shared navigation map answers queries with this map's
## region. Region updates are applied asynchronously, a few frames after baking.
func is_navigation_ready() -> bool:
	if _nav_region == null or not is_inside_tree():
		return false
	if NavigationServer3D.map_get_iteration_id(navigation_map()) == 0:
		return false
	var owner_rid := NavigationServer3D.map_get_closest_point_owner(navigation_map(), definition.player_start)
	return owner_rid == _nav_region.get_rid()


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


func _add_ground_collider() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(definition.size.x, 1.0, definition.size.y)
	var body := StaticBody3D.new()
	body.name = "GroundBody"
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = Vector3(0, -0.5, 0)
	body.add_child(collider)
	_nav_region.add_child(body)


func _add_round_blocker(owner_node: Node3D, radius: float, height: float) -> void:
	var points := PackedVector3Array()
	for i in BLOCKER_SIDES:
		var a := TAU * i / BLOCKER_SIDES
		points.append(Vector3(cos(a) * radius, 0, sin(a) * radius))
	_add_blocker(owner_node, points, height)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	_add_obstacle_body(owner_node, shape, Vector3(0, height * 0.5, 0))


func _add_box_blocker(owner_node: Node3D, size: Vector3, offset: Vector3) -> void:
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var points := PackedVector3Array([
		offset + Vector3(-hx, 0, -hz), offset + Vector3(hx, 0, -hz),
		offset + Vector3(hx, 0, hz), offset + Vector3(-hx, 0, hz),
	])
	_add_blocker(owner_node, points, size.y)
	var shape := BoxShape3D.new()
	shape.size = size
	_add_obstacle_body(owner_node, shape, offset + Vector3(0, size.y * 0.5, 0))


## Carves a footprint (plus agent radius) out of the baked navigation mesh.
func _add_blocker(owner_node: Node3D, points: PackedVector3Array, height: float) -> void:
	var obstacle := NavigationObstacle3D.new()
	obstacle.vertices = points
	obstacle.height = height
	obstacle.affect_navigation_mesh = true
	obstacle.avoidance_enabled = false
	owner_node.add_child(obstacle)


func _add_obstacle_body(owner_node: Node3D, shape: Shape3D, offset: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1 << (OBSTACLE_LAYER - 1)
	body.collision_mask = 0
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = offset
	body.add_child(collider)
	owner_node.add_child(body)


func _bake_navigation() -> void:
	var nav := NavigationMesh.new()
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = 1 << (GROUND_LAYER - 1)
	nav.cell_size = NAV_CELL_SIZE
	nav.cell_height = NAV_CELL_HEIGHT
	nav.agent_radius = NAV_AGENT_RADIUS
	nav.agent_height = 2.0
	nav.agent_max_climb = 0.25
	_nav_region.navigation_mesh = nav
	_nav_region.bake_navigation_mesh(false)


func _place(node: Node3D, pos: Vector3, parent: Node) -> Node3D:
	node.position = pos
	parent.add_child(node)
	return node


func _debris_exclusions() -> Array[Vector3]:
	var points: Array[Vector3] = [definition.player_start, definition.enemy_start, definition.core_site]
	points.append_array(definition.scrap_sites)
	points.append_array(definition.energy_sites)
	for r in definition.rocks:
		points.append(Vector3(r.x, 0, r.y))
	for r in definition.ruins:
		points.append(Vector3(r.x, 0, r.y))
	return points
