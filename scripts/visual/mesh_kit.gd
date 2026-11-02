class_name MeshKit
extends RefCounted
## Shared helpers for building primitive-based visuals with cached materials.

static var _materials: Dictionary = {}


static func instance(mesh: Mesh, material: Material, pos: Vector3, rot_degrees: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = faceted(mesh) if mesh is CylinderMesh else mesh
	node.material_override = material
	node.position = pos
	node.rotation_degrees = rot_degrees
	return node


## Rebuilds a primitive with per-face normals for a crisp low-poly look.
static func faceted(mesh: PrimitiveMesh) -> ArrayMesh:
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


static func solid(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "solid_%s_%.2f_%.2f" % [color.to_html(), roughness, metallic]
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = roughness
		mat.metallic = metallic
		_materials[key] = mat
	return _materials[key]


static func emissive(color: Color, energy: float) -> StandardMaterial3D:
	var key := "emit_%s_%.2f" % [color.to_html(), energy]
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = energy
		_materials[key] = mat
	return _materials[key]


static func glow_light(color: Color, pos: Vector3, light_range: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.6
	light.omni_range = light_range
	light.omni_attenuation = 1.4
	light.position = pos
	return light


static func translucent(color: Color, alpha: float) -> StandardMaterial3D:
	var key := "translucent_%s_%.2f" % [color.to_html(), alpha]
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(color, alpha)
		_materials[key] = mat
	return _materials[key]
