class_name RtsCamera
extends Node3D
## Tactical camera rig. The rig sits on the ground plane; the child Camera3D
## orbits above it. One-finger drag or right/middle mouse drag pans, pinch or
## mouse wheel zooms, arrow keys pan on desktop.

@export var bounds: Rect2 = Rect2(-60.0, -60.0, 120.0, 120.0)
@export var min_distance: float = 16.0
@export var max_distance: float = 80.0
@export var start_distance: float = 54.0
## Pitch lowers as the camera zooms in for a more dramatic close view.
@export var near_pitch_degrees: float = 46.0
@export var far_pitch_degrees: float = 62.0
@export var zoom_smoothing: float = 14.0
@export var wheel_zoom_step: float = 0.12
## Fraction of the current camera distance panned per second with keys.
@export var key_pan_speed: float = 1.1
@export var drag_threshold_px: float = 12.0

@onready var _camera: Camera3D = $Camera3D

var _distance: float
var _target_distance: float
var _touches: Dictionary = {}
var _touch_travel: float = 0.0
var _touch_dragging: bool = false
var _pinch_distance: float = 0.0
var _pinch_center: Vector2 = Vector2.ZERO
var _mouse_panning: bool = false


func _ready() -> void:
	_distance = clampf(start_distance, min_distance, max_distance)
	_target_distance = _distance
	_apply_camera_transform()


func focus_on(point: Vector3) -> void:
	position = Vector3(point.x, 0.0, point.z)
	_clamp_to_bounds()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_touch_drag(event)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion and _mouse_panning and event.device != InputEvent.DEVICE_ID_EMULATION:
		_pan_between(event.position - event.relative, event.position)


func _process(delta: float) -> void:
	var keys := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if keys != Vector2.ZERO:
		position += Vector3(keys.x, 0.0, keys.y) * _distance * key_pan_speed * delta
		_clamp_to_bounds()
	_distance = lerpf(_distance, _target_distance, 1.0 - exp(-zoom_smoothing * delta))
	_apply_camera_transform()


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touches[event.index] = event.position
	else:
		_touches.erase(event.index)
	_touch_travel = 0.0
	_touch_dragging = false
	if _touches.size() == 2:
		_capture_pinch()


func _on_touch_drag(event: InputEventScreenDrag) -> void:
	if not _touches.has(event.index):
		return
	var previous: Vector2 = _touches[event.index]
	_touches[event.index] = event.position
	if _touches.size() == 1:
		if not _touch_dragging:
			_touch_travel += previous.distance_to(event.position)
			if _touch_travel < drag_threshold_px:
				return
			_touch_dragging = true
		_pan_between(previous, event.position)
	elif _touches.size() == 2:
		_update_pinch()


func _capture_pinch() -> void:
	var points: Array = _touches.values()
	_pinch_distance = (points[0] as Vector2).distance_to(points[1])
	_pinch_center = ((points[0] as Vector2) + (points[1] as Vector2)) * 0.5


func _update_pinch() -> void:
	var points: Array = _touches.values()
	var dist := (points[0] as Vector2).distance_to(points[1])
	var center := ((points[0] as Vector2) + (points[1] as Vector2)) * 0.5
	if dist > 1.0 and _pinch_distance > 1.0:
		_target_distance = clampf(_target_distance * _pinch_distance / dist, min_distance, max_distance)
		_distance = _target_distance
	_pan_between(_pinch_center, center)
	_pinch_distance = dist
	_pinch_center = center


func _on_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
			_mouse_panning = event.pressed
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				_zoom_by(1.0 - wheel_zoom_step)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				_zoom_by(1.0 + wheel_zoom_step)


func _zoom_by(factor: float) -> void:
	_target_distance = clampf(_target_distance * factor, min_distance, max_distance)


## Moves the rig so the ground point under `from` ends up under `to`.
func _pan_between(from: Vector2, to: Vector2) -> void:
	var a: Variant = _ground_point(from)
	var b: Variant = _ground_point(to)
	if a == null or b == null:
		return
	var delta: Vector3 = (a as Vector3) - (b as Vector3)
	position += Vector3(delta.x, 0.0, delta.z)
	_clamp_to_bounds()
	_apply_camera_transform()


func _ground_point(screen_pos: Vector2) -> Variant:
	var origin := _camera.project_ray_origin(screen_pos)
	var direction := _camera.project_ray_normal(screen_pos)
	return Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)


func _clamp_to_bounds() -> void:
	position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	position.z = clampf(position.z, bounds.position.y, bounds.end.y)


func _apply_camera_transform() -> void:
	var t := inverse_lerp(min_distance, max_distance, _distance)
	var pitch := deg_to_rad(lerpf(near_pitch_degrees, far_pitch_degrees, t))
	_camera.position = Vector3(0.0, sin(pitch) * _distance, cos(pitch) * _distance)
	_camera.rotation = Vector3(-pitch, 0.0, 0.0)
