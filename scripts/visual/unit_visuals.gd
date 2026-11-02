class_name UnitVisuals
extends RefCounted
## Builds original placeholder unit models from primitives. Models face -Z.
## Roles differ by silhouette, not only by color.

const ARMOR_COLOR := Color(0.62, 0.68, 0.6)
const DARK_COLOR := Color(0.16, 0.17, 0.19)
const STEEL_COLOR := Color(0.45, 0.47, 0.5)
const HIVIS_COLOR := Color(0.95, 0.6, 0.15)
const HAT_COLOR := Color(1.0, 0.82, 0.25)
const ACCENT_COLOR := Color(0.25, 0.82, 0.88)
const SELECTION_COLOR := Color(0.35, 0.95, 1.0)
const HEALTH_COLOR := Color(0.45, 1.0, 0.6)
const COLLECTIVE_BODY := Color(0.09, 0.09, 0.11)
const COLLECTIVE_PLATE := Color(0.3, 0.3, 0.34)
const COLLECTIVE_EYE := Color(1.0, 0.27, 0.22)
## Models are stylized larger than life so they read on a phone screen.
const MODEL_SCALE := 1.4


static func build(unit_id: StringName) -> Node3D:
	var model: Node3D
	match unit_id:
		&"worker":
			model = _worker()
		&"rifle":
			model = _rifle()
		&"sentinel":
			model = _sentinel()
		_:
			push_warning("UnitVisuals: no model for '%s'" % unit_id)
			model = _rifle()
	model.scale = Vector3.ONE * MODEL_SCALE
	return model


static func selection_ring(radius: float) -> MeshInstance3D:
	var ring := TorusMesh.new()
	ring.inner_radius = radius * 1.2
	ring.outer_radius = radius * 1.4
	ring.rings = 32
	ring.ring_segments = 4
	var node := MeshKit.instance(ring, MeshKit.translucent(SELECTION_COLOR, 0.9), Vector3(0, 0.06, 0))
	node.scale = Vector3(1, 0.12, 1)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


## Salvage bundle carried on a worker's back while delivering.
static func cargo() -> Node3D:
	var root := Node3D.new()
	root.name = "Cargo"
	root.scale = Vector3.ONE * MODEL_SCALE
	root.add_child(_box(Vector3(0.5, 0.36, 0.4), Color(0.55, 0.32, 0.16), Vector3(0, 1.62, 0.45), 0.6, 0.4))
	root.add_child(_box(Vector3(0.3, 0.2, 0.42), Color(0.5, 0.52, 0.55), Vector3(0.08, 1.88, 0.45), 0.5, 0.6))
	return root


static func _rifle() -> Node3D:
	var root := Node3D.new()
	root.name = "RifleModel"
	root.add_child(_box(Vector3(0.5, 0.75, 0.32), DARK_COLOR, Vector3(0, 0.38, 0)))
	root.add_child(_box(Vector3(0.7, 0.8, 0.45), ARMOR_COLOR, Vector3(0, 1.15, 0)))
	root.add_child(_box(Vector3(0.5, 0.5, 0.22), DARK_COLOR, Vector3(0, 1.2, 0.32)))
	var head := SphereMesh.new()
	head.radius = 0.24
	head.height = 0.48
	head.radial_segments = 10
	head.rings = 5
	root.add_child(MeshKit.instance(head, MeshKit.solid(ARMOR_COLOR, 0.6, 0.2), Vector3(0, 1.78, 0)))
	root.add_child(MeshKit.instance(_box_mesh(Vector3(0.34, 0.08, 0.06)), MeshKit.emissive(ACCENT_COLOR, 3.0), Vector3(0, 1.8, -0.21)))
	root.add_child(_box(Vector3(0.09, 0.09, 1.0), STEEL_COLOR, Vector3(0.36, 1.2, -0.3), 0.4, 0.7))
	root.add_child(MeshKit.instance(_box_mesh(Vector3(0.06, 0.4, 0.3)), MeshKit.emissive(ACCENT_COLOR, 2.0), Vector3(-0.36, 1.25, 0)))
	return root


## Collective guard drone: a hovering dark hull with one red eye.
static func _sentinel() -> Node3D:
	var root := Node3D.new()
	root.name = "SentinelModel"
	var hull := SphereMesh.new()
	hull.radius = 0.55
	hull.height = 0.8
	hull.radial_segments = 8
	hull.rings = 4
	root.add_child(MeshKit.instance(MeshKit.faceted(hull), MeshKit.solid(COLLECTIVE_BODY, 0.35, 0.6), Vector3(0, 1.35, 0)))
	root.add_child(_box(Vector3(1.5, 0.08, 0.36), COLLECTIVE_PLATE, Vector3(0, 1.35, 0.05), 0.4, 0.7))
	root.add_child(_box(Vector3(0.12, 0.5, 0.4), COLLECTIVE_PLATE, Vector3(0.76, 1.3, 0.05), 0.4, 0.7))
	root.add_child(_box(Vector3(0.12, 0.5, 0.4), COLLECTIVE_PLATE, Vector3(-0.76, 1.3, 0.05), 0.4, 0.7))
	var eye := SphereMesh.new()
	eye.radius = 0.16
	eye.height = 0.32
	root.add_child(MeshKit.instance(eye, MeshKit.emissive(COLLECTIVE_EYE, 5.0), Vector3(0, 1.38, -0.48)))
	root.add_child(_box(Vector3(0.08, 0.08, 0.7), COLLECTIVE_PLATE, Vector3(0, 1.08, -0.35), 0.4, 0.7))
	var emitter := CylinderMesh.new()
	emitter.top_radius = 0.22
	emitter.bottom_radius = 0.05
	emitter.height = 0.35
	emitter.radial_segments = 6
	emitter.rings = 1
	root.add_child(MeshKit.instance(emitter, MeshKit.emissive(COLLECTIVE_EYE, 2.5), Vector3(0, 0.85, 0)))
	return root


static func _worker() -> Node3D:
	var root := Node3D.new()
	root.name = "WorkerModel"
	root.add_child(_box(Vector3(0.62, 0.6, 0.38), DARK_COLOR, Vector3(0, 0.3, 0)))
	root.add_child(_box(Vector3(0.9, 0.72, 0.58), HIVIS_COLOR, Vector3(0, 0.98, 0)))
	var tank := CylinderMesh.new()
	tank.top_radius = 0.2
	tank.bottom_radius = 0.2
	tank.height = 0.75
	tank.radial_segments = 8
	tank.rings = 1
	root.add_child(MeshKit.instance(tank, MeshKit.solid(STEEL_COLOR, 0.4, 0.7), Vector3(0, 1.05, 0.42)))
	var head := SphereMesh.new()
	head.radius = 0.22
	head.height = 0.44
	head.radial_segments = 10
	head.rings = 5
	root.add_child(MeshKit.instance(head, MeshKit.solid(DARK_COLOR, 0.8), Vector3(0, 1.55, 0)))
	var hat := CylinderMesh.new()
	hat.top_radius = 0.16
	hat.bottom_radius = 0.32
	hat.height = 0.2
	hat.radial_segments = 8
	hat.rings = 1
	root.add_child(MeshKit.instance(hat, MeshKit.solid(HAT_COLOR, 0.5), Vector3(0, 1.74, 0)))
	var lamp := SphereMesh.new()
	lamp.radius = 0.07
	lamp.height = 0.14
	root.add_child(MeshKit.instance(lamp, MeshKit.emissive(Color(1.0, 0.85, 0.5), 4.0), Vector3(0, 1.72, -0.28)))
	# Salvage arm with a two-prong claw.
	root.add_child(_box(Vector3(0.14, 0.14, 0.8), STEEL_COLOR, Vector3(0.5, 0.95, -0.25), 0.4, 0.7))
	root.add_child(_box(Vector3(0.06, 0.2, 0.06), DARK_COLOR, Vector3(0.44, 0.92, -0.68)))
	root.add_child(_box(Vector3(0.06, 0.2, 0.06), DARK_COLOR, Vector3(0.56, 0.92, -0.68)))
	return root


static func _box(size: Vector3, color: Color, pos: Vector3, roughness: float = 0.8, metallic: float = 0.0) -> MeshInstance3D:
	return MeshKit.instance(_box_mesh(size), MeshKit.solid(color, roughness, metallic), pos)


static func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh
