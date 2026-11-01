class_name MapProps
extends RefCounted
## Builds original placeholder meshes for map features from primitives.
## Presentation only: no gameplay state lives here.

const SPINNER := preload("res://scripts/visual/spinner.gd")

const ROCK_COLOR := Color(0.36, 0.33, 0.32)
const ROCK_TOP_COLOR := Color(0.5, 0.44, 0.39)
const CONCRETE_COLOR := Color(0.44, 0.44, 0.46)
const CONCRETE_DARK := Color(0.24, 0.24, 0.27)
const RUST_COLOR := Color(0.45, 0.25, 0.14)
const STEEL_COLOR := Color(0.38, 0.4, 0.43)
const REMNANT_BODY := Color(0.78, 0.76, 0.72)
const REMNANT_ACCENT := Color(0.25, 0.82, 0.88)
const COLLECTIVE_BODY := Color(0.07, 0.075, 0.09)
const COLLECTIVE_ACCENT := Color(1.0, 0.27, 0.22)
const ENERGY_COLOR := Color(0.55, 1.0, 0.45)
const CORE_COLOR := Color(0.78, 0.45, 1.0)
const SCRAP_MARK_COLOR := Color(1.0, 0.68, 0.25)
const WINDOW_GLOW := Color(1.0, 0.55, 0.25)
const DEBRIS_COLOR := Color(0.3, 0.29, 0.29)

static var _materials: Dictionary = {}


static func rock(radius: float, height: float, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Rock"
	var body := CylinderMesh.new()
	body.bottom_radius = radius
	body.top_radius = radius * 0.72
	body.height = height
	body.radial_segments = 7
	body.rings = 1
	root.add_child(_mesh(body, _solid(ROCK_COLOR, 0.95), Vector3(0, height * 0.5, 0)))
	var cap := CylinderMesh.new()
	cap.bottom_radius = radius * 0.74
	cap.top_radius = radius * 0.55
	cap.height = height * 0.18
	cap.radial_segments = 7
	cap.rings = 1
	root.add_child(_mesh(cap, _solid(ROCK_TOP_COLOR, 1.0), Vector3(0, height * 1.09, 0), Vector3(0, 25, 0)))
	# A leaning shard breaks up the silhouette.
	var shard := CylinderMesh.new()
	shard.bottom_radius = radius * 0.42
	shard.top_radius = radius * 0.12
	shard.height = height * 0.75
	shard.radial_segments = 5
	shard.rings = 1
	var angle := rng.randf_range(0.0, TAU)
	var offset := Vector3(cos(angle), 0, sin(angle)) * radius * 0.95
	root.add_child(_mesh(shard, _solid(ROCK_COLOR, 0.95), offset + Vector3(0, height * 0.3, 0), Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(-14, 14))))
	root.rotation.y = rng.randf_range(0.0, TAU)
	return root


static func ruin(size: float, height: float, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Ruin"
	var tower := BoxMesh.new()
	tower.size = Vector3(size, height, size * 0.8)
	root.add_child(_mesh(tower, _solid(CONCRETE_COLOR, 0.9), Vector3(0, height * 0.5, 0)))
	# Window band on the front face only, so the glow reads as interior light.
	var band := BoxMesh.new()
	band.size = Vector3(size * 0.82, 0.18, 0.05)
	var band_mat := _emissive(WINDOW_GLOW, 1.6)
	for i in 3:
		var y := height * (0.35 + 0.18 * i)
		if rng.randf() < 0.7:
			root.add_child(_mesh(band, band_mat, Vector3(0, y, size * 0.4 + 0.03)))
	# Collapsed upper floor, tilted.
	var slab := BoxMesh.new()
	slab.size = Vector3(size * 0.7, height * 0.25, size * 0.6)
	root.add_child(_mesh(slab, _solid(CONCRETE_DARK, 0.95), Vector3(size * 0.12, height * 1.08, 0), Vector3(0, 0, rng.randf_range(8, 18))))
	var rubble := BoxMesh.new()
	rubble.size = Vector3(size * 0.4, size * 0.25, size * 0.35)
	root.add_child(_mesh(rubble, _solid(CONCRETE_DARK, 0.95), Vector3(-size * 0.75, size * 0.12, size * 0.2), Vector3(0, 30, 12)))
	root.rotation.y = rng.randf_range(0.0, TAU)
	return root


static func scrap_pile(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "ScrapPile"
	for i in 7:
		var piece := BoxMesh.new()
		piece.size = Vector3(rng.randf_range(0.6, 1.6), rng.randf_range(0.3, 0.9), rng.randf_range(0.6, 1.4))
		var color := RUST_COLOR if i % 2 == 0 else STEEL_COLOR
		var pos := Vector3(rng.randf_range(-1.6, 1.6), piece.size.y * 0.4, rng.randf_range(-1.6, 1.6))
		var rot := Vector3(rng.randf_range(-20, 20), rng.randf_range(0, 360), rng.randf_range(-20, 20))
		root.add_child(_mesh(piece, _solid(color, 0.6, 0.5), pos, rot))
	root.add_child(site_ring(3.2, SCRAP_MARK_COLOR))
	return root


static func energy_well() -> Node3D:
	var root := Node3D.new()
	root.name = "EnergyWell"
	var pad := CylinderMesh.new()
	pad.top_radius = 3.0
	pad.bottom_radius = 3.4
	pad.height = 0.4
	pad.radial_segments = 6
	pad.rings = 1
	root.add_child(_mesh(pad, _solid(CONCRETE_DARK, 0.7, 0.3), Vector3(0, 0.2, 0)))
	var crystal := CylinderMesh.new()
	crystal.top_radius = 0.0
	crystal.bottom_radius = 0.9
	crystal.height = 3.2
	crystal.radial_segments = 4
	crystal.rings = 1
	var spinner := Node3D.new()
	spinner.set_script(SPINNER)
	spinner.position = Vector3(0, 2.6, 0)
	spinner.set("degrees_per_second", Vector3(0, 40, 0))
	spinner.set("bob_height", 0.25)
	spinner.set("bob_speed", 1.6)
	var crystal_mat := _emissive(ENERGY_COLOR, 3.0)
	spinner.add_child(_mesh(crystal, crystal_mat, Vector3(0, 0.8, 0)))
	spinner.add_child(_mesh(crystal, crystal_mat, Vector3(0, -0.8, 0), Vector3(180, 0, 0)))
	root.add_child(spinner)
	root.add_child(_glow_light(ENERGY_COLOR, Vector3(0, 2.5, 0), 9.0))
	root.add_child(site_ring(4.2, ENERGY_COLOR))
	return root


static func ai_core() -> Node3D:
	var root := Node3D.new()
	root.name = "AICoreFacility"
	var base := CylinderMesh.new()
	base.top_radius = 4.6
	base.bottom_radius = 5.4
	base.height = 0.8
	base.radial_segments = 8
	base.rings = 1
	root.add_child(_mesh(base, _solid(CONCRETE_DARK, 0.6, 0.4), Vector3(0, 0.4, 0)))
	var pillar := BoxMesh.new()
	pillar.size = Vector3(0.7, 4.0, 0.7)
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		root.add_child(_mesh(pillar, _solid(STEEL_COLOR, 0.5, 0.6), Vector3(cos(a) * 3.8, 2.6, sin(a) * 3.8), Vector3(0, -rad_to_deg(a), 0)))
	var ring := TorusMesh.new()
	ring.inner_radius = 2.3
	ring.outer_radius = 2.6
	ring.rings = 32
	ring.ring_segments = 8
	var ring_spin := Node3D.new()
	ring_spin.set_script(SPINNER)
	ring_spin.position = Vector3(0, 3.4, 0)
	ring_spin.set("degrees_per_second", Vector3(25, 40, 0))
	ring_spin.add_child(_mesh(ring, _emissive(CORE_COLOR, 2.2), Vector3.ZERO))
	root.add_child(ring_spin)
	var orb := SphereMesh.new()
	orb.radius = 1.0
	orb.height = 2.0
	orb.radial_segments = 16
	orb.rings = 8
	var orb_spin := Node3D.new()
	orb_spin.set_script(SPINNER)
	orb_spin.position = Vector3(0, 3.4, 0)
	orb_spin.set("bob_height", 0.2)
	orb_spin.set("bob_speed", 2.0)
	orb_spin.add_child(_mesh(orb, _emissive(Color(1, 0.9, 1), 4.0), Vector3.ZERO))
	root.add_child(orb_spin)
	root.add_child(_glow_light(CORE_COLOR, Vector3(0, 3.5, 0), 14.0))
	root.add_child(site_ring(6.4, CORE_COLOR))
	return root


static func remnant_nexus() -> Node3D:
	var root := Node3D.new()
	root.name = "RemnantNexus"
	var tiers := [[6.0, 6.6, 1.2], [4.6, 5.2, 1.6], [2.4, 3.0, 4.2]]
	var y := 0.0
	for tier in tiers:
		var mesh := CylinderMesh.new()
		mesh.top_radius = tier[0]
		mesh.bottom_radius = tier[1]
		mesh.height = tier[2]
		mesh.radial_segments = 6
		mesh.rings = 1
		root.add_child(_mesh(mesh, _solid(REMNANT_BODY, 0.75, 0.25), Vector3(0, y + tier[2] * 0.5, 0)))
		y += tier[2]
	var band := CylinderMesh.new()
	band.top_radius = 3.05
	band.bottom_radius = 3.05
	band.height = 0.25
	band.radial_segments = 6
	band.rings = 1
	root.add_child(_mesh(band, _emissive(REMNANT_ACCENT, 2.5), Vector3(0, 3.6, 0)))
	var mast := BoxMesh.new()
	mast.size = Vector3(0.35, 4.0, 0.35)
	root.add_child(_mesh(mast, _solid(STEEL_COLOR, 0.4, 0.7), Vector3(1.0, y + 2.0, 0.4)))
	var dish := CylinderMesh.new()
	dish.top_radius = 1.6
	dish.bottom_radius = 0.3
	dish.height = 0.6
	dish.radial_segments = 12
	dish.rings = 1
	root.add_child(_mesh(dish, _solid(REMNANT_BODY, 0.5, 0.4), Vector3(-0.6, y + 0.6, -0.4), Vector3(25, 0, -15)))
	var beacon := SphereMesh.new()
	beacon.radius = 0.3
	beacon.height = 0.6
	root.add_child(_mesh(beacon, _emissive(REMNANT_ACCENT, 5.0), Vector3(1.0, y + 4.2, 0.4)))
	root.add_child(_glow_light(REMNANT_ACCENT, Vector3(0, 4.0, 0), 12.0))
	root.add_child(site_ring(8.0, REMNANT_ACCENT))
	return root


static func collective_nexus() -> Node3D:
	var root := Node3D.new()
	root.name = "CollectiveNexus"
	var plinth := BoxMesh.new()
	plinth.size = Vector3(10.0, 1.0, 10.0)
	root.add_child(_mesh(plinth, _solid(COLLECTIVE_BODY, 0.3, 0.8), Vector3(0, 0.5, 0), Vector3(0, 45, 0)))
	var spire := CylinderMesh.new()
	spire.top_radius = 0.0
	spire.bottom_radius = 3.4
	spire.height = 11.0
	spire.radial_segments = 4
	spire.rings = 1
	root.add_child(_mesh(spire, _solid(COLLECTIVE_BODY, 0.25, 0.85), Vector3(0, 6.5, 0)))
	var fin := BoxMesh.new()
	fin.size = Vector3(0.6, 6.0, 3.0)
	for i in 4:
		var a := TAU * i / 4.0
		root.add_child(_mesh(fin, _solid(COLLECTIVE_BODY, 0.3, 0.8), Vector3(cos(a) * 3.8, 3.2, sin(a) * 3.8), Vector3(0, -rad_to_deg(a), 8)))
	var seam := BoxMesh.new()
	seam.size = Vector3(0.12, 5.0, 0.12)
	var seam_mat := _emissive(COLLECTIVE_ACCENT, 4.0)
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		root.add_child(_mesh(seam, seam_mat, Vector3(cos(a) * 1.75, 4.5, sin(a) * 1.75), Vector3(0, 0, 0)))
	var eye := SphereMesh.new()
	eye.radius = 0.55
	eye.height = 1.1
	var eye_spin := Node3D.new()
	eye_spin.set_script(SPINNER)
	eye_spin.position = Vector3(0, 13.0, 0)
	eye_spin.set("bob_height", 0.35)
	eye_spin.set("bob_speed", 1.2)
	eye_spin.add_child(_mesh(eye, _emissive(COLLECTIVE_ACCENT, 6.0), Vector3.ZERO))
	root.add_child(eye_spin)
	root.add_child(_glow_light(COLLECTIVE_ACCENT, Vector3(0, 6.0, 0), 14.0))
	root.add_child(site_ring(8.0, COLLECTIVE_ACCENT))
	return root


## Scattered small debris in a single draw call. Keeps clear of `avoid` points.
static func debris_field(count: int, half_extents: Vector2, avoid: Array[Vector3], clearance: float, rng: RandomNumberGenerator) -> MultiMeshInstance3D:
	var stone := CylinderMesh.new()
	stone.top_radius = 0.18
	stone.bottom_radius = 0.32
	stone.height = 0.3
	stone.radial_segments = 5
	stone.rings = 1
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _faceted(stone)
	var transforms: Array[Transform3D] = []
	var attempts := 0
	while transforms.size() < count and attempts < count * 4:
		attempts += 1
		var pos := Vector3(rng.randf_range(-half_extents.x, half_extents.x), 0.08, rng.randf_range(-half_extents.y, half_extents.y))
		var blocked := false
		for point in avoid:
			if Vector2(pos.x - point.x, pos.z - point.z).length() < clearance:
				blocked = true
				break
		if blocked:
			continue
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.6, 2.4))
		transforms.append(Transform3D(basis, pos))
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = "Debris"
	instance.multimesh = multimesh
	instance.material_override = _solid(DEBRIS_COLOR, 0.95)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## Flat translucent ring marking a site on the ground.
static func site_ring(radius: float, color: Color) -> MeshInstance3D:
	var ring := TorusMesh.new()
	ring.inner_radius = radius - 0.12
	ring.outer_radius = radius
	ring.rings = 48
	ring.ring_segments = 4
	var key := "ring_%s" % color.to_html()
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(color, 0.55)
		_materials[key] = mat
	var instance := _mesh(ring, _materials[key], Vector3(0, 0.06, 0))
	instance.scale = Vector3(1, 0.15, 1)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


static func _mesh(mesh: Mesh, material: Material, pos: Vector3, rot_degrees: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = _faceted(mesh) if mesh is CylinderMesh else mesh
	instance.material_override = material
	instance.position = pos
	instance.rotation_degrees = rot_degrees
	return instance


## Rebuilds a primitive with per-face normals for a crisp low-poly look.
static func _faceted(mesh: PrimitiveMesh) -> ArrayMesh:
	var arrays := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var out_verts := PackedVector3Array()
	var out_normals := PackedVector3Array()
	for i in range(0, indices.size(), 3):
		var ia := indices[i]
		var ib := indices[i + 1]
		var ic := indices[i + 2]
		var a := verts[ia]
		var b := verts[ib]
		var c := verts[ic]
		var reference := normals[ia] + normals[ib] + normals[ic]
		var face := (b - a).cross(c - a)
		if face.length_squared() < 0.000001:
			face = reference
		if face.dot(reference) < 0.0:
			face = -face
		face = face.normalized()
		out_verts.append_array([a, b, c])
		out_normals.append_array([face, face, face])
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = out_verts
	out[Mesh.ARRAY_NORMAL] = out_normals
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	return result


static func _solid(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "solid_%s_%.2f_%.2f" % [color.to_html(), roughness, metallic]
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = roughness
		mat.metallic = metallic
		_materials[key] = mat
	return _materials[key]


static func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var key := "emit_%s_%.2f" % [color.to_html(), energy]
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = energy
		_materials[key] = mat
	return _materials[key]


static func _glow_light(color: Color, pos: Vector3, light_range: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.6
	light.omni_range = light_range
	light.omni_attenuation = 1.4
	light.position = pos
	return light
