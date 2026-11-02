class_name FloatingText
extends RefCounted
## Short-lived world-space text that rises and fades (income, warnings).

const RISE := 2.0
const LIFETIME := 1.2


static func spawn(parent: Node, pos: Vector3, text: String, color: Color) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.outline_size = 10
	label.font_size = 96
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = pos
	parent.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", pos.y + RISE, LIFETIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, LIFETIME * 0.5).set_delay(LIFETIME * 0.5)
	tween.chain().tween_callback(label.queue_free)
