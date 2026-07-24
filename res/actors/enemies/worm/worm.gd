extends CharacterBody3D
class_name CaveWorm

## Simple cave worm: patrols, lunges if the player is near, damages on touch, dies to hitscan.

signal died(world_pos: Vector3)

const _DamageNumber := preload("res://res/actors/fx/damage_number.gd")

@export var display_name: String = "Roadmap Worm"
@export var max_health: float = 50.0
@export var move_speed: float = 2.8
@export var lunge_speed: float = 6.5
@export var patrol_half_extent: float = 3.5
@export var aggro_range: float = 9.0
@export var lunge_range: float = 4.5
@export var contact_damage: float = 18.0
@export var contact_cooldown: float = 0.55
@export var contact_radius: float = 1.85
@export var contact_height: float = 2.4
@export var gravity: float = 18.0

var health: float
var _home: Vector3
var _patrol_dir: float = 1.0
var _contact_cd: float = 0.0
var _lunge_timer: float = 0.0
var _dead: bool = false
var _flash_left: float = 0.0

@onready var _mesh_root: Node3D = $Body
@onready var _damage_area: Area3D = $DamageArea
@onready var _name_label: Label3D = $NameLabel


func _ready() -> void:
	health = max_health
	_home = global_position
	add_to_group("enemy")
	add_to_group("damageable")
	_duplicate_segment_materials()
	if _name_label:
		_name_label.text = display_name
	# Area is a backup; distance checks are the reliable path for CharacterBody players.
	if _damage_area:
		_damage_area.monitoring = true
		_damage_area.monitorable = false
		_damage_area.collision_layer = 0
		_damage_area.collision_mask = 1
		if not _damage_area.body_entered.is_connected(_on_damage_body_entered):
			_damage_area.body_entered.connect(_on_damage_body_entered)


func _duplicate_segment_materials() -> void:
	if _mesh_root == null:
		return
	for child in _mesh_root.get_children():
		_dup_mat_recursive(child)


func _dup_mat_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.material_override:
			mi.material_override = mi.material_override.duplicate()
	for child in node.get_children():
		_dup_mat_recursive(child)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	if _contact_cd > 0.0:
		_contact_cd = maxf(_contact_cd - delta, 0.0)
	if _lunge_timer > 0.0:
		_lunge_timer = maxf(_lunge_timer - delta, 0.0)
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		_apply_flash()

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var player := _find_player()
	var to_player := Vector3.ZERO
	var dist := INF
	if player:
		to_player = player.global_position - global_position
		to_player.y = 0.0
		dist = to_player.length()

	if player and dist <= lunge_range and _lunge_timer <= 0.0:
		var dir := to_player.normalized() if dist > 0.05 else Vector3.FORWARD
		velocity.x = dir.x * lunge_speed
		velocity.z = dir.z * lunge_speed
		_lunge_timer = 1.1
		_face_direction(dir)
	elif player and dist <= aggro_range:
		var dir := to_player.normalized() if dist > 0.05 else Vector3.ZERO
		velocity.x = dir.x * move_speed * 1.35
		velocity.z = dir.z * move_speed * 1.35
		_face_direction(dir)
	else:
		_patrol(delta)

	# Wriggle animation
	if _mesh_root:
		var t := Time.get_ticks_msec() * 0.01
		_mesh_root.rotation.z = sin(t + global_position.x) * 0.18
		_mesh_root.position.y = 0.35 + sin(t * 1.7) * 0.05

	move_and_slide()
	_try_contact_damage(player, dist, to_player)


func take_damage(amount: float, from: Node = null) -> void:
	if _dead:
		return
	health -= amount
	_flash_left = 0.12
	_apply_flash()
	_DamageNumber.spawn(
		self,
		global_position + Vector3(0, 1.2, 0),
		"-%d" % int(round(amount)),
		Color(1.0, 0.75, 0.2),
		40
	)
	if health <= 0.0:
		if from != null and from.is_in_group("player") and from.has_method("notify_kill"):
			from.call("notify_kill", self)
		_die()


func _patrol(_delta: float) -> void:
	var offset := global_position.x - _home.x
	if offset > patrol_half_extent:
		_patrol_dir = -1.0
	elif offset < -patrol_half_extent:
		_patrol_dir = 1.0
	velocity.x = _patrol_dir * move_speed
	velocity.z = move_toward(velocity.z, 0.0, move_speed * 2.0 * _delta)
	_face_direction(Vector3(_patrol_dir, 0.0, 0.0))


func _face_direction(dir: Vector3) -> void:
	if dir.length_squared() < 0.0001:
		return
	var yaw := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, 0.2)


func _find_player() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var players := tree.get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node3D


func _try_contact_damage(player: Node3D, planar_dist: float, _to_player: Vector3) -> void:
	if _dead or _contact_cd > 0.0:
		return

	# Reliable path: distance to player (Area3D vs CharacterBody is flaky when layers don't overlap).
	if player and _player_in_contact_range(player, planar_dist):
		if _hurt_player(player):
			_contact_cd = contact_cooldown
			return

	# Backup: Area overlap, in case something else damageable walks through.
	if _damage_area:
		for body in _damage_area.get_overlapping_bodies():
			if _hurt_player(body):
				_contact_cd = contact_cooldown
				return


func _player_in_contact_range(player: Node3D, planar_dist: float) -> bool:
	if planar_dist > contact_radius:
		return false
	# Player origin is at feet; worm origin near body center — allow generous vertical slop.
	var dy := absf(player.global_position.y - global_position.y)
	return dy <= contact_height


func _on_damage_body_entered(body: Node) -> void:
	if _dead or _contact_cd > 0.0:
		return
	if _hurt_player(body):
		_contact_cd = contact_cooldown


func _hurt_player(target: Node) -> bool:
	var n: Node = target
	while n:
		if n.is_in_group("player") and n.has_method("take_damage"):
			n.call("take_damage", contact_damage, self)
			return true
		n = n.get_parent()
	return false


func _apply_flash() -> void:
	if _mesh_root == null:
		return
	var hot := _flash_left > 0.0
	for child in _mesh_root.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if mi.material_override is StandardMaterial3D:
				var mat := mi.material_override as StandardMaterial3D
				mat.emission_energy_multiplier = 1.8 if hot else 0.35


func _die() -> void:
	_dead = true
	velocity = Vector3.ZERO
	if _damage_area:
		_damage_area.monitoring = false
	if _name_label:
		_name_label.text = "%s\n(deprioritized)" % display_name
	var death_pos := global_position
	died.emit(death_pos)
	# Backup notify so boss always gets a drop even if signal connect failed.
	if is_in_group("board_thrall"):
		get_tree().call_group("boss", "notify_thrall_killed", death_pos)
	# Collapse into the floor comically, then free
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.2, 0.15, 1.2), 0.35)
	tw.tween_callback(queue_free)
