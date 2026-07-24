extends Area3D
class_name VoltaicOKR

## Green mote. Press Interact (F) while nearby to pick up. One orb at a time.

@export var bob_amp: float = 0.18
@export var bob_speed: float = 2.4
@export var spin_speed: float = 1.8
@export var pickup_action: StringName = &"interact"

var _base_y: float = 0.0
var _t: float = 0.0
var _taken: bool = false
var _placed: bool = false
var _player_in_range: Node = null

@onready var _label: Label3D = get_node_or_null("Label")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1
	add_to_group("voltaic_okr")
	_refresh_label()
	if not _placed:
		call_deferred("_capture_base_if_needed")


func place_at(world_pos: Vector3) -> void:
	global_position = world_pos
	_base_y = world_pos.y
	_placed = true


func _capture_base_if_needed() -> void:
	if not _placed:
		_base_y = global_position.y
		_placed = true


func _physics_process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	global_position.y = _base_y + sin(_t * bob_speed) * bob_amp
	rotate_y(spin_speed * delta)

	if _player_in_range != null and is_instance_valid(_player_in_range):
		_refresh_label()
		if Input.is_action_just_pressed(pickup_action):
			_try_pickup(_player_in_range)
	else:
		_player_in_range = null
		_refresh_label()


func _on_body_entered(body: Node) -> void:
	if _taken:
		return
	var player := _find_player(body)
	if player:
		_player_in_range = player
		_refresh_label()


func _on_body_exited(body: Node) -> void:
	var player := _find_player(body)
	if player != null and player == _player_in_range:
		_player_in_range = null
		_refresh_label()


func _try_pickup(player: Node) -> void:
	if _taken or player == null:
		return
	if player.has_method("has_okr") and player.call("has_okr"):
		if player.has_method("_set_weapon_hud"):
			player.call("_set_weapon_hud", "Already carrying a Voltaic OKR (one at a time)")
		elif player.has("hud") and player.hud and player.hud.has_method("set_weapon_line"):
			player.hud.set_weapon_line("Already carrying a Voltaic OKR (one at a time)")
		_refresh_label()
		return
	if player.has_method("give_okr") and player.call("give_okr"):
		_taken = true
		queue_free()


func _refresh_label() -> void:
	if _label == null:
		return
	if _player_in_range == null:
		_label.text = "Voltaic OKR"
		_label.modulate = Color(0.7, 1.0, 0.55, 1)
		return
	var holding := false
	if _player_in_range.has_method("has_okr"):
		holding = bool(_player_in_range.call("has_okr"))
	if holding:
		_label.text = "Hands full\n(one OKR at a time)"
		_label.modulate = Color(1.0, 0.7, 0.45, 1)
	else:
		_label.text = "[F] Pick up\nVoltaic OKR"
		_label.modulate = Color(0.85, 1.0, 0.65, 1)


func _find_player(body: Node) -> Node:
	var n: Node = body
	while n:
		if n.is_in_group("player"):
			return n
		n = n.get_parent()
	return null
