extends Label3D
class_name DamageNumber

## Floating world-space combat text (damage / Immune!).


static func spawn(host: Node, world_pos: Vector3, text: String, color: Color = Color(1, 0.85, 0.2), size: int = 48) -> void:
	if host == null or not is_instance_valid(host):
		return
	var tree := host.get_tree()
	if tree == null:
		return
	var parent: Node = tree.current_scene
	if parent == null:
		parent = host
	var n := DamageNumber.new()
	parent.add_child(n)
	n._boot(world_pos, text, color, size)


func _boot(world_pos: Vector3, text: String, color: Color, size: int) -> void:
	global_position = world_pos + Vector3(randf_range(-0.25, 0.25), 0.2, randf_range(-0.25, 0.25))
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	font_size = size
	outline_size = 8
	modulate = color
	self.text = text
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rise := Vector3(randf_range(-0.4, 0.4), randf_range(1.4, 2.0), randf_range(-0.4, 0.4))
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "global_position", global_position + rise, 0.75).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.75).set_delay(0.15)
	tw.chain().tween_callback(queue_free)
