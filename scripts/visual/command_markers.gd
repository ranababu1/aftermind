class_name CommandMarkers
extends RefCounted
## Short-lived ground markers that confirm or reject an order.

const MOVE_COLOR := Color(0.35, 0.95, 1.0)
const INVALID_COLOR := Color(1.0, 0.3, 0.25)
const LIFETIME := 0.6


static func move_marker(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	var ring := _ring(1.0, MOVE_COLOR)
	root.add_child(ring)
	var dot := _ring(0.25, MOVE_COLOR)
	root.add_child(dot)
	root.ready.connect(func() -> void:
		var tween := root.create_tween().set_parallel()
		tween.tween_property(ring, "scale", Vector3(1.8, 0.12, 1.8), LIFETIME).from(Vector3(0.6, 0.12, 0.6)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(ring, "transparency", 1.0, LIFETIME).from(0.0)
		tween.tween_property(dot, "transparency", 1.0, LIFETIME).from(0.0)
		tween.chain().tween_callback(root.queue_free), CONNECT_ONE_SHOT)
	return root


static func invalid_marker(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	var cross := Node3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(1.6, 0.05, 0.25)
	var mat := MeshKit.translucent(INVALID_COLOR, 0.95)
	cross.add_child(MeshKit.instance(bar, mat, Vector3(0, 0.08, 0), Vector3(0, 45, 0)))
	cross.add_child(MeshKit.instance(bar, mat, Vector3(0, 0.08, 0), Vector3(0, -45, 0)))
	root.add_child(cross)
	var ring := _ring(1.1, INVALID_COLOR)
	root.add_child(ring)
	root.ready.connect(func() -> void:
		var tween := root.create_tween().set_parallel()
		tween.tween_property(cross, "scale", Vector3.ONE, 0.25).from(Vector3.ONE * 1.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(ring, "transparency", 1.0, LIFETIME * 1.4).from(0.0)
		tween.chain().tween_property(cross, "scale", Vector3.ZERO, 0.2)
		tween.chain().tween_callback(root.queue_free), CONNECT_ONE_SHOT)
	return root


static func _ring(radius: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius * 0.8
	mesh.outer_radius = radius
	mesh.rings = 32
	mesh.ring_segments = 4
	var node := MeshKit.instance(mesh, MeshKit.translucent(color, 0.9), Vector3(0, 0.08, 0))
	node.scale = Vector3(1, 0.12, 1)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
