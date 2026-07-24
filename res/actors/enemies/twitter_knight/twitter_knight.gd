extends CharacterBody3D
class_name TwitterCommentKnight

## Melee knight that quotes X discourse while swinging a sword.
## Sword hits only reach ground-level targets — jump boxes get you out of range.

const _DamageNumber := preload("res://res/actors/fx/damage_number.gd")

## Parody taunts inspired by public Destiny / live-service discourse on X.
const DEFAULT_QUOTES: PackedStringArray = [
	"Destiny 3 was never greenlit",
	"PlayStation is right not to greenlight a true D3",
	"They've already lost $3.6B on Bungie",
	"It's not happening. Do what they can with what they got",
	"Bungie dropped the ball. Sony fumbled canceling Destiny",
	"400k petition signatures won't save D3",
	"SURELY Sony greenlights Destiny 3... right?",
	"Live service garbage nobody asked for",
	"The industry shot itself in the foot then blamed us",
	"WHY NOT JUST MAKE DESTINY 3 REEEEEE",
	"Pit of Heresy still the worst dungeon is so crazy",
	"Loot refresh didn't save the Pit",
	"My first solo flawless ended at the first jump down",
	"There's a reason there was never a Destiny killer",
	"Marathon DOA. Give us D3 instead",
	"This is a skill issue. Touch grass. Ratio",
	"git gud or uninstall guardian",
	"Engagement metrics demand your Light",
]

@export var display_name: String = "Hive Comment Knight"
@export var max_health: float = 90.0
@export var move_speed: float = 3.6
@export var chase_speed: float = 5.2
@export var patrol_half_extent: float = 5.0
@export var aggro_range: float = 22.0
@export var sword_range: float = 2.35
## Vertical reach of the blade. Platforms above this are safe.
@export var sword_height: float = 1.65
@export var sword_damage: float = 65.0
@export var swing_cooldown: float = 1.35
@export var swing_windup: float = 0.28
@export var gravity: float = 20.0
@export var taunt_interval_min: float = 2.8
@export var taunt_interval_max: float = 5.5
@export var quotes: PackedStringArray = DEFAULT_QUOTES

var health: float
var _home: Vector3
var _patrol_dir: float = 1.0
var _swing_cd: float = 0.0
var _windup: float = 0.0
var _dead: bool = false
var _flash_left: float = 0.0
var _taunt_cd: float = 1.0
var _attacking: bool = false

@onready var _mesh_root: Node3D = $Body
@onready var _sword: Node3D = $Body/SwordPivot
@onready var _name_label: Label3D = $NameLabel
@onready var _quote_label: Label3D = $QuoteBubble
@onready var _sword_mat_host: MeshInstance3D = $Body/SwordPivot/Blade


func _ready() -> void:
	health = max_health
	_home = global_position
	add_to_group("enemy")
	add_to_group("damageable")
	add_to_group("twitter_knight")
	_dup_mats($Body)
	if _name_label:
		_name_label.text = display_name
	if _quote_label:
		_quote_label.text = ""
		_quote_label.modulate.a = 0.0
	_taunt_cd = randf_range(0.4, 1.8)
	_say_quote(true)


func _dup_mats(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.material_override:
			mi.material_override = mi.material_override.duplicate()
	for child in node.get_children():
		_dup_mats(child)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	if _swing_cd > 0.0:
		_swing_cd = maxf(_swing_cd - delta, 0.0)
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		_apply_flash()
	if _taunt_cd > 0.0:
		_taunt_cd = maxf(_taunt_cd - delta, 0.0)
	elif not _attacking:
		_say_quote(false)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var player := _find_player()
	var to_player := Vector3.ZERO
	var planar := INF
	var dy := INF
	if player:
		to_player = player.global_position - global_position
		var flat := Vector3(to_player.x, 0.0, to_player.z)
		planar = flat.length()
		dy = player.global_position.y - global_position.y

	if _attacking:
		_tick_attack(delta, player, planar, dy)
	elif player and planar <= sword_range * 1.15 and dy <= sword_height and _swing_cd <= 0.0:
		_begin_swing(player)
	elif player and planar <= aggro_range:
		var dir := Vector3(to_player.x, 0.0, to_player.z)
		if dir.length_squared() > 0.0001:
			dir = dir.normalized()
			# Stop just outside strike range so they don't shove into the player.
			if planar > sword_range * 0.85:
				velocity.x = dir.x * chase_speed
				velocity.z = dir.z * chase_speed
			else:
				velocity.x = 0.0
				velocity.z = 0.0
			_face_direction(dir)
		if _taunt_cd <= 0.0:
			_say_quote(false)
	else:
		_patrol(delta)

	_animate_idle(delta)
	move_and_slide()


func take_damage(amount: float, from: Node = null) -> void:
	if _dead:
		return
	health -= amount
	_flash_left = 0.12
	_apply_flash()
	_DamageNumber.spawn(
		self,
		global_position + Vector3(0, 1.8, 0),
		"-%d" % int(round(amount)),
		Color(1.0, 0.55, 0.2),
		40
	)
	if health <= 0.0:
		if from != null and from.is_in_group("player") and from.has_method("notify_kill"):
			from.call("notify_kill", self)
		_die()


func _begin_swing(player: Node3D) -> void:
	_attacking = true
	_windup = swing_windup
	velocity.x = 0.0
	velocity.z = 0.0
	if player:
		var dir := player.global_position - global_position
		dir.y = 0.0
		_face_direction(dir)
	_say_quote(true)
	if _name_label:
		_name_label.text = "%s\n*swings*" % display_name


func _tick_attack(delta: float, player: Node3D, planar: float, dy: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if _windup > 0.0:
		_windup = maxf(_windup - delta, 0.0)
		# Wind-up: raise sword
		if _sword:
			_sword.rotation.x = lerpf(_sword.rotation.x, -1.1, 1.0 - exp(-12.0 * delta))
		if _windup <= 0.0:
			_resolve_hit(player, planar, dy)
			_swing_cd = swing_cooldown
		return

	# Recovery: lower sword
	if _sword:
		_sword.rotation.x = lerpf(_sword.rotation.x, 0.15, 1.0 - exp(-8.0 * delta))
	if absf(_sword.rotation.x - 0.15) < 0.05 or _swing_cd < swing_cooldown - 0.45:
		_attacking = false
		if _name_label:
			_name_label.text = display_name


func _resolve_hit(player: Node3D, planar: float, dy: float) -> void:
	# Slash motion
	if _sword:
		_sword.rotation.x = 0.85
	if player == null:
		return
	# Out of reach if player is on a box / platform above sword height.
	if planar > sword_range or dy > sword_height or dy < -0.8:
		_DamageNumber.spawn(
			self,
			global_position + Vector3(0, 2.0, 0),
			"WHIFF",
			Color(0.7, 0.85, 1.0),
			28
		)
		return
	if _hurt_player(player):
		_DamageNumber.spawn(
			self,
			global_position + Vector3(0, 2.1, 0),
			"RATIO",
			Color(1.0, 0.35, 0.4),
			32
		)


func _patrol(delta: float) -> void:
	var offset := global_position.x - _home.x
	if offset > patrol_half_extent:
		_patrol_dir = -1.0
	elif offset < -patrol_half_extent:
		_patrol_dir = 1.0
	velocity.x = _patrol_dir * move_speed
	velocity.z = move_toward(velocity.z, 0.0, move_speed * 2.0 * delta)
	_face_direction(Vector3(_patrol_dir, 0.0, 0.0))


func _face_direction(dir: Vector3) -> void:
	if dir.length_squared() < 0.0001:
		return
	var yaw := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, 0.22)


func _animate_idle(_delta: float) -> void:
	if _mesh_root == null or _attacking:
		return
	var t := Time.get_ticks_msec() * 0.004
	_mesh_root.position.y = 0.02 + sin(t) * 0.03
	if _sword and not _attacking:
		_sword.rotation.x = 0.12 + sin(t * 1.3) * 0.05


func _say_quote(force: bool) -> void:
	if quotes.is_empty():
		return
	if not force and _taunt_cd > 0.0:
		return
	var line := quotes[randi() % quotes.size()]
	if _quote_label:
		_quote_label.text = "\"%s\"" % line
		_quote_label.modulate.a = 1.0
		var tw := create_tween()
		tw.tween_interval(2.6)
		tw.tween_property(_quote_label, "modulate:a", 0.0, 0.6)
	_taunt_cd = randf_range(taunt_interval_min, taunt_interval_max)


func _find_player() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var players := tree.get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node3D


func _hurt_player(target: Node) -> bool:
	var n: Node = target
	while n:
		if n.is_in_group("player") and n.has_method("take_damage"):
			n.call("take_damage", sword_damage, self)
			return true
		n = n.get_parent()
	return false


func _apply_flash() -> void:
	var hot := _flash_left > 0.0
	_flash_node($Body, hot)


func _flash_node(node: Node, hot: bool) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.material_override is StandardMaterial3D:
			var mat := mi.material_override as StandardMaterial3D
			mat.emission_energy_multiplier = 2.2 if hot else (0.25 if mi == _sword_mat_host else 0.15)
	for child in node.get_children():
		_flash_node(child, hot)


func _die() -> void:
	_dead = true
	_attacking = false
	velocity = Vector3.ZERO
	if _name_label:
		_name_label.text = "%s\n(blocked & reported)" % display_name
	if _quote_label:
		_quote_label.text = "\"ratioed\""
		_quote_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.1, 0.12, 1.1), 0.4)
	tw.tween_callback(queue_free)
