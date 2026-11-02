class_name BuildingVisuals
extends RefCounted
## Original placeholder structure models built from primitives (Remnant
## style: pale concrete, steel, cyan accents). Each role has its own silhouette.

const BODY := Color(0.74, 0.72, 0.68)
const BODY_DARK := Color(0.4, 0.41, 0.44)
const STEEL := Color(0.45, 0.47, 0.5)
const RUST := Color(0.5, 0.29, 0.15)
const ACCENT := Color(0.25, 0.82, 0.88)
const ENERGY := Color(0.55, 1.0, 0.45)
const SCAFFOLD := Color(0.35, 0.95, 1.0)
const REFUND := Color(1.0, 0.78, 0.4)


static func build(building_id: StringName, radius: float) -> Node3D:
	match building_id:
		&"salvage_depot":
			return _salvage_depot(radius)
		&"power_reactor":
			return _power_reactor(radius)
		&"fabrication_bay":
			return _fabrication_bay(radius)
		&"research_lab":
			return _research_lab(radius)
	push_warning("BuildingVisuals: no model for '%s'" % building_id)
	return _salvage_depot(radius)


## Ground ring shown around the selected structure.
static func selection_ring(radius: float) -> Node3D:
	var ring := TorusMesh.new()
	ring.inner_radius = radius + 0.35
	ring.outer_radius = radius + 0.7
	ring.rings = 64
	ring.ring_segments = 4
	return MeshKit.instance(ring, MeshKit.translucent(UnitVisuals.SELECTION_COLOR, 0.9), Vector3(0, 0.08, 0))


## Translucent footprint volume shown around a structure under construction.
static func scaffold(radius: float, height: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Scaffold"
	var frame := CylinderMesh.new()
	frame.top_radius = radius
	frame.bottom_radius = radius
	frame.height = height
	frame.radial_segments = 6
	frame.rings = 1
	var node := MeshKit.instance(frame, MeshKit.translucent(SCAFFOLD, 0.12), Vector3(0, height * 0.5, 0))
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.12
	ring.outer_radius = radius
	ring.rings = 48
	ring.ring_segments = 4
	var base := MeshKit.instance(ring, MeshKit.translucent(SCAFFOLD, 0.8), Vector3(0, 0.06, 0))
	base.scale = Vector3(1, 0.15, 1)
	root.add_child(base)
	return root


static func _salvage_depot(r: float) -> Node3D:
	var root := Node3D.new()
	root.add_child(_cyl(r, r * 1.05, 0.6, 6, BODY_DARK, Vector3(0, 0.3, 0)))
	root.add_child(_box(Vector3(r * 1.1, 1.6, r * 0.9), BODY, Vector3(-r * 0.2, 1.4, 0)))
	root.add_child(_box(Vector3(r * 0.7, 0.9, r * 0.5), RUST, Vector3(r * 0.5, 1.05, r * 0.35)))
	root.add_child(_box(Vector3(r * 0.6, 0.8, r * 0.45), STEEL, Vector3(r * 0.45, 1.0, -r * 0.4)))
	# Crane mast and boom.
	root.add_child(_box(Vector3(0.3, 4.2, 0.3), STEEL, Vector3(-r * 0.55, 2.7, -r * 0.3)))
	root.add_child(_box(Vector3(r * 1.3, 0.22, 0.22), STEEL, Vector3(-r * 0.1, 4.7, -r * 0.3)))
	root.add_child(MeshKit.instance(_box_mesh(Vector3(r * 1.12, 0.12, 0.06)), MeshKit.emissive(ACCENT, 2.5), Vector3(-r * 0.2, 1.9, r * 0.46)))
	return root


static func _power_reactor(r: float) -> Node3D:
	var root := Node3D.new()
	root.add_child(_cyl(r, r * 1.05, 0.6, 8, BODY_DARK, Vector3(0, 0.3, 0)))
	root.add_child(_cyl(r * 0.55, r * 0.7, 3.6, 8, BODY, Vector3(0, 2.4, 0)))
	for i in 3:
		root.add_child(MeshKit.instance(_cyl_mesh(r * 0.62, r * 0.62, 0.16, 16), MeshKit.emissive(ENERGY, 2.6), Vector3(0, 1.4 + i * 1.0, 0)))
	for i in 4:
		var a := TAU * i / 4.0
		root.add_child(_box(Vector3(0.25, 2.4, r * 0.5), STEEL, Vector3(cos(a) * r * 0.75, 1.8, sin(a) * r * 0.75), Vector3(0, -rad_to_deg(a), 0)))
	var core := SphereMesh.new()
	core.radius = r * 0.32
	core.height = r * 0.64
	root.add_child(MeshKit.instance(core, MeshKit.emissive(ENERGY, 4.0), Vector3(0, 4.3, 0)))
	return root


static func _fabrication_bay(r: float) -> Node3D:
	var root := Node3D.new()
	root.add_child(_box(Vector3(r * 1.9, 0.5, r * 1.6), BODY_DARK, Vector3(0, 0.25, 0)))
	root.add_child(_box(Vector3(r * 1.7, 2.8, r * 1.4), BODY, Vector3(0, 1.9, 0)))
	var roof := PrismMesh.new()
	roof.size = Vector3(r * 1.8, 1.4, r * 1.5)
	root.add_child(MeshKit.instance(roof, MeshKit.solid(STEEL, 0.6, 0.4), Vector3(0, 4.0, 0)))
	# Hangar door on the front (-Z) face with an accent header.
	root.add_child(_box(Vector3(r * 0.95, 2.2, 0.1), Color(0.12, 0.13, 0.15), Vector3(0, 1.6, -r * 0.71)))
	root.add_child(MeshKit.instance(_box_mesh(Vector3(r * 1.05, 0.14, 0.08)), MeshKit.emissive(ACCENT, 3.0), Vector3(0, 2.8, -r * 0.73)))
	root.add_child(_box(Vector3(0.4, 1.8, 0.4), STEEL, Vector3(r * 0.7, 5.0, r * 0.4)))
	return root


static func _research_lab(r: float) -> Node3D:
	var root := Node3D.new()
	root.add_child(_cyl(r, r * 1.05, 0.7, 8, BODY_DARK, Vector3(0, 0.35, 0)))
	root.add_child(_cyl(r * 0.85, r * 0.9, 1.2, 8, BODY, Vector3(0, 1.3, 0)))
	var dome := SphereMesh.new()
	dome.radius = r * 0.8
	dome.height = r * 1.6
	dome.is_hemisphere = true
	dome.radial_segments = 16
	dome.rings = 6
	root.add_child(MeshKit.instance(dome, MeshKit.solid(BODY, 0.4, 0.2), Vector3(0, 1.9, 0)))
	root.add_child(MeshKit.instance(_cyl_mesh(r * 0.87, r * 0.87, 0.14, 16), MeshKit.emissive(ACCENT, 2.6), Vector3(0, 1.75, 0)))
	root.add_child(_box(Vector3(0.12, 2.2, 0.12), STEEL, Vector3(r * 0.35, 3.9, 0)))
	var tip := SphereMesh.new()
	tip.radius = 0.16
	tip.height = 0.32
	root.add_child(MeshKit.instance(tip, MeshKit.emissive(ACCENT, 5.0), Vector3(r * 0.35, 5.05, 0)))
	return root


static func _box(size: Vector3, color: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	return MeshKit.instance(_box_mesh(size), MeshKit.solid(color, 0.8, 0.1), pos, rot)


static func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _cyl(top: float, bottom: float, height: float, sides: int, color: Color, pos: Vector3) -> MeshInstance3D:
	return MeshKit.instance(_cyl_mesh(top, bottom, height, sides), MeshKit.solid(color, 0.8, 0.1), pos)


static func _cyl_mesh(top: float, bottom: float, height: float, sides: int) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return mesh
