class_name HealthBar
extends Node3D
## Camera-facing bar above a unit or building. The fill shrinks toward the
## left and turns warning-red when health is low.

const THICKNESS := 0.16
const BORDER := 0.06
const LOW_FRACTION := 0.35
const LOW_COLOR := Color(1.0, 0.35, 0.3)

var _width: float
var _color: Color
var _fill_mesh: QuadMesh
var _fill_material: StandardMaterial3D


func _init(width: float, color: Color) -> void:
	name = "HealthBar"
	_width = width
	_color = color
	var back_mesh := QuadMesh.new()
	back_mesh.size = Vector2(width + BORDER * 2.0, THICKNESS + BORDER * 2.0)
	add_child(_quad(back_mesh, _material(Color(0.03, 0.04, 0.05, 0.75), 0)))
	_fill_mesh = QuadMesh.new()
	_fill_material = _material(color, 1)
	add_child(_quad(_fill_mesh, _fill_material))
	set_fraction(1.0)


func set_fraction(fraction: float) -> void:
	var f := clampf(fraction, 0.0, 1.0)
	_fill_mesh.size = Vector2(maxf(_width * f, 0.001), THICKNESS)
	_fill_mesh.center_offset = Vector3(-_width * 0.5 + _width * f * 0.5, 0.0, 0.0)
	_fill_material.albedo_color = LOW_COLOR if f < LOW_FRACTION else _color


static func _quad(mesh: QuadMesh, material: StandardMaterial3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


static func _material(color: Color, priority: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.no_depth_test = true
	material.render_priority = priority
	material.albedo_color = color
	return material
