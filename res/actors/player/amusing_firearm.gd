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

@onready var _muzzle_flash: MeshInstance3D = get_node_or_null("MuzzleFlash")
@onready var _flavor: Label3D = get_node_or_null("FlavorLabel")


func _ready() -> void:
	super._ready()
	_base_pos = position
	if _muzzle_flash:
		_muzzle_flash.visible = false
	if _flavor:
		_flavor.text = weapon_name


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
	var lines := [
		"Action item!",
		"Circling back!",
		"Per my last bullet!",
		"Synergy applied.",
		"Let's take this offline.",
		"Noted.",
		"Bandwidth secured.",
		"Stakeholder aligned.",
	]
	return lines[randi() % lines.size()]
