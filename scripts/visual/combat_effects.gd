class_name CombatEffects
extends RefCounted
## Short-lived combat feedback: weapon tracers, impact sparks, death bursts.
## Meshes and materials are shared so frequent shots stay cheap.

const REMNANT_SHOT := Color(0.45, 0.95, 1.0)
const COLLECTIVE_SHOT := Color(1.0, 0.32, 0.24)
const TRACER_SECONDS := 0.1
const IMPACT_SECONDS := 0.18
const BURST_SECONDS := 0.75
const BURST_SHARDS := 7

static var _tracer_mesh: BoxMesh
static var _spark_mesh: SphereMesh
static var _shard_mesh: BoxMesh
static var _materials: Dictionary = {}


static func faction_color(faction: StringName) -> Color:
	return COLLECTIVE_SHOT if faction == Combat.COLLECTIVE else REMNANT_SHOT


static func tracer(parent: Node, from: Vector3, to: Vector3, color: Color) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var length := from.distance_to(to)
	if length < 0.2:
		return
	if _tracer_mesh == null:
		_tracer_mesh = BoxMesh.new()
		_tracer_mesh.size = Vector3(0.07, 0.07, 1.0)
	var beam := _instance(_tracer_mesh, color)
	parent.add_child(beam)
	beam.look_at_from_position((from + to) * 0.5, to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.RIGHT)
	beam.scale = Vector3(1.0, 1.0, length)
	var tween := beam.create_tween()
	tween.tween_property(beam, "scale", Vector3(0.0, 0.0, length), TRACER_SECONDS).set_ease(Tween.EASE_IN)
	tween.tween_callback(beam.queue_free)
	if _spark_mesh == null:
		_spark_mesh = SphereMesh.new()
		_spark_mesh.radius = 0.22
		_spark_mesh.height = 0.44
		_spark_mesh.radial_segments = 8
		_spark_mesh.rings = 4
	var spark := _instance(_spark_mesh, color)
	parent.add_child(spark)
	spark.global_position = to
	var pop := spark.create_tween()
	pop.tween_property(spark, "scale", Vector3.ONE * 1.6, IMPACT_SECONDS * 0.4).from(Vector3.ONE * 0.4)
	pop.tween_property(spark, "scale", Vector3.ZERO, IMPACT_SECONDS * 0.6)
	pop.tween_callback(spark.queue_free)


## Shards thrown outward when a unit is destroyed.
static func death_burst(parent: Node, pos: Vector3, color: Color) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	if _shard_mesh == null:
		_shard_mesh = BoxMesh.new()
		_shard_mesh.size = Vector3(0.28, 0.28, 0.28)
	var origin := pos + Vector3.UP * 1.2
	for i in BURST_SHARDS:
		var a := TAU * i / BURST_SHARDS + 0.4
		var shard := _instance(_shard_mesh, color if i % 2 == 0 else Color(0.2, 0.21, 0.23))
		parent.add_child(shard)
		shard.global_position = origin
		var out := Vector3(cos(a), 0.0, sin(a)) * (1.6 + 0.3 * (i % 3))
		var tween := shard.create_tween().set_parallel()
		tween.tween_property(shard, "global_position", origin + out + Vector3.UP * 1.1, BURST_SECONDS * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(shard, "rotation", Vector3(a * 3.0, a * 2.0, a), BURST_SECONDS)
		tween.chain().tween_property(shard, "global_position", Vector3(origin.x, 0.1, origin.z) + out * 1.4, BURST_SECONDS * 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.chain().tween_property(shard, "scale", Vector3.ZERO, 0.2)
		tween.chain().tween_callback(shard.queue_free)


static func _instance(mesh: Mesh, color: Color) -> MeshInstance3D:
	if not _materials.has(color):
		_materials[color] = MeshKit.emissive(color, 3.5)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _materials[color]
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
