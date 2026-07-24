extends WeaponViewModel
class_name AmusingFirearm

## Joke primary with real hitscan feedback: kick, flash, and smug flavor text.

@export var kick_position := Vector3(0.0, 0.02, 0.06)
@export var kick_rotation_degrees := Vector3(-6.0, 1.5, 2.0)
@export var kick_recover_speed := 14.0
@export var muzzle_flash_time := 0.05

var _kick_blend := 0.0
var _base_pos := Vector3.ZERO
var _flash_left := 0.0
var _bark_lines: PackedStringArray = PackedStringArray()

@onready var _muzzle_flash: MeshInstance3D = get_node_or_null("MuzzleFlash")
@onready var _flavor: Label3D = get_node_or_null("FlavorLabel")


func _ready() -> void:
	super._ready()
	_base_pos = position
	if _muzzle_flash:
		_muzzle_flash.visible = false
	if _flavor:
		_flavor.text = weapon_name
	if _bark_lines.is_empty():
		_bark_lines = PackedStringArray([
			"Action item!",
			"Circling back!",
			"Per my last bullet!",
			"Synergy applied.",
			"Let's take this offline.",
			"Noted.",
			"Bandwidth secured.",
			"Stakeholder aligned.",
		])


func apply_weapon_def(def: WeaponDef) -> void:
	if def == null:
		return
	weapon_name = def.display_name
	hip_offset = def.hip_offset
	ads_offset = def.ads_offset
	if not def.bark_lines.is_empty():
		_bark_lines = def.bark_lines.duplicate()
	_apply_mesh_colors(def.body_color, def.accent_color)
	# Snap to hip pose for the new weapon so offsets apply immediately.
	if _current_pose == Pose.HIP:
		position = hip_offset
	else:
		position = ads_offset
	_base_pos = position
	_kick_blend = 0.0
	if _flavor:
		_flavor.text = weapon_name


func _apply_mesh_colors(body: Color, accent: Color) -> void:
	var body_names := ["BodyMesh", "BarrelMesh", "Mag"]
	var accent_names := ["GoldRail"]
	for n in body_names:
		var mi := get_node_or_null(n) as MeshInstance3D
		if mi:
			_set_mesh_albedo(mi, body, false)
	for n in accent_names:
		var mi := get_node_or_null(n) as MeshInstance3D
		if mi:
			_set_mesh_albedo(mi, accent, true)


func _set_mesh_albedo(mi: MeshInstance3D, color: Color, with_emission: bool) -> void:
	var mat := mi.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mi.material_override = mat
	else:
		mat = mat.duplicate() as StandardMaterial3D
		mi.material_override = mat
	mat.albedo_color = color
	if with_emission:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.5


func _process(delta: float) -> void:
	super._process(delta)
	_kick_blend = move_toward(_kick_blend, 0.0, kick_recover_speed * delta)
	# Apply kick as an offset, not a per-frame accumulate (that spun the gun forever).
	position += kick_position * _kick_blend
	rotation_degrees = kick_rotation_degrees * _kick_blend
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		if _muzzle_flash:
			_muzzle_flash.visible = _flash_left > 0.0
			_muzzle_flash.rotate_z(delta * 40.0)
	elif _muzzle_flash:
		_muzzle_flash.visible = false


func _on_fire() -> void:
	_kick_blend = 1.0
	_flash_left = muzzle_flash_time
	if _muzzle_flash:
		_muzzle_flash.visible = true
	if _flavor:
		_flavor.text = _random_bark()


func _random_bark() -> String:
	if _bark_lines.is_empty():
		return weapon_name
	return _bark_lines[randi() % _bark_lines.size()]
