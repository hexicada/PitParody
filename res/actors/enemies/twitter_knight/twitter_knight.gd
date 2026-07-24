extends CharacterBody3D
class_name TwitterCommentKnight

## Melee knight that quotes X discourse while swinging a sword.
## Visuals: KayKit Adventurers (CC0) with a hive-green material tint.
## Sword hits only reach ground-level targets — jump boxes get you out of range.

const _DamageNumber := preload("res://res/actors/fx/damage_number.gd")

const KAYKIT_PATHS := {
	"knight": "res://res/assets/characters/kaykit/characters/Knight.glb",
	"rogue": "res://res/assets/characters/kaykit/characters/Rogue.glb",
	"barbarian": "res://res/assets/characters/kaykit/characters/Barbarian.glb",
}

## Hive-ish green used to retint KayKit albedo / emission.
const HIVE_ALBEDO := Color(0.42, 0.72, 0.38, 1.0)
const HIVE_EMISSION := Color(0.18, 0.85, 0.22, 1.0)
const HIVE_TINT_BLEND := 0.42
const HIVE_EMISSION_IDLE := 0.22
const HIVE_EMISSION_FLASH := 2.4

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

## Which KayKit Adventurers mesh to instance: knight / rogue / barbarian.
@export_enum("knight", "rogue", "barbarian") var kaykit_variant: String = "knight"
## Optional full override — if set, used instead of kaykit_variant.
@export var kaykit_scene_override: PackedScene
## Extra Y rotation on the visual only. CharacterBody +Z faces chase dir (atan2).
## KayKit faces +Z in glTF → 0 matches chase. Flip to 180 if they moonwalk.
@export var model_yaw_offset_degrees: float = 0.0
@export var model_scale: float = 1.0

var health: float
var _home: Vector3
var _patrol_dir: float = 1.0
var _swing_cd: float = 0.0
var _windup: float = 0.0
var _dead: bool = false
var _flash_left: float = 0.0
var _taunt_cd: float = 1.0
var _attacking: bool = false
## Materials we own (duplicated + hive-tinted) for hit flash.
var _owned_mats: Array[StandardMaterial3D] = []

@onready var _mesh_root: Node3D = $Body
@onready var _kaykit_mount: Node3D = $Body/KaykitMount
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
	_setup_kaykit_visual()
	_apply_hive_look($Body)
	if _name_label:
		_name_label.text = display_name
	if _quote_label:
		_quote_label.text = ""
		_quote_label.modulate.a = 0.0
	_taunt_cd = randf_range(0.4, 1.8)
	_say_quote(true)


func _setup_kaykit_visual() -> void:
	if _kaykit_mount == null:
		return

	# Drop editor preview / previous instance children.
	for child in _kaykit_mount.get_children():
		_kaykit_mount.remove_child(child)
		child.free()

	var scene: PackedScene = kaykit_scene_override
	if scene == null:
		var key := kaykit_variant.to_lower()
		var path: String = KAYKIT_PATHS.get(key, KAYKIT_PATHS["knight"])
		if ResourceLoader.exists(path):
			scene = load(path) as PackedScene
		else:
			push_warning("TwitterCommentKnight: missing KayKit asset at %s" % path)

	if scene == null:
		return

	var inst := scene.instantiate()
	if inst is Node3D:
		var n3 := inst as Node3D
		_kaykit_mount.add_child(n3)
		n3.position = Vector3.ZERO
		n3.rotation = Vector3.ZERO
		n3.scale = Vector3.ONE
	else:
		_kaykit_mount.add_child(inst)

	_kaykit_mount.rotation_degrees = Vector3(0.0, model_yaw_offset_degrees, 0.0)
	_kaykit_mount.scale = Vector3.ONE * model_scale


func _apply_hive_look(node: Node) -> void:
	if node is MeshInstance3D:
		_tint_mesh_instance(node as MeshInstance3D)
	for child in node.get_children():
		_apply_hive_look(child)


func _tint_mesh_instance(mi: MeshInstance3D) -> void:
	if mi.material_override is StandardMaterial3D:
		var base := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		_hive_tint_material(base)
		mi.material_override = base
		_owned_mats.append(base)
		return

	var surface_count := 0
	if mi.mesh:
		surface_count = mi.mesh.get_surface_count()
	if surface_count <= 0:
		surface_count = mi.get_surface_override_material_count()

	for i in surface_count:
		var src: Material = mi.get_active_material(i)
		if src == null:
			continue
		if src is StandardMaterial3D:
			var mat := (src as StandardMaterial3D).duplicate() as StandardMaterial3D
			_hive_tint_material(mat)
			mi.set_surface_override_material(i, mat)
			_owned_mats.append(mat)
		elif src is BaseMaterial3D:
			# ORM / other BaseMaterial3D — still push a green Standard overlay feel.
			var mat2 := StandardMaterial3D.new()
			mat2.albedo_color = HIVE_ALBEDO
			mat2.emission_enabled = true
			mat2.emission = HIVE_EMISSION
			mat2.emission_energy_multiplier = HIVE_EMISSION_IDLE
			mat2.roughness = 0.7
			mi.set_surface_override_material(i, mat2)
			_owned_mats.append(mat2)


func _hive_tint_material(mat: StandardMaterial3D) -> void:
	mat.albedo_color = mat.albedo_color.lerp(HIVE_ALBEDO, HIVE_TINT_BLEND)
	mat.emission_enabled = true
	var em := mat.emission
	if em.r + em.g + em.b < 0.05:
		em = HIVE_EMISSION
	else:
		em = em.lerp(HIVE_EMISSION, 0.55)
	mat.emission = em
	mat.emission_energy_multiplier = maxf(mat.emission_energy_multiplier, HIVE_EMISSION_IDLE)


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
	# Makes CharacterBody local +Z face `dir` (KayKit face is +Z → no model offset needed).
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
	var energy := HIVE_EMISSION_FLASH if hot else HIVE_EMISSION_IDLE
	for mat in _owned_mats:
		if mat:
			mat.emission_energy_multiplier = energy
	# Fallback sword host material if it wasn't collected (hidden procedural blade).
	if _sword_mat_host and _sword_mat_host.material_override is StandardMaterial3D:
		var sm := _sword_mat_host.material_override as StandardMaterial3D
		sm.emission_energy_multiplier = (HIVE_EMISSION_FLASH if hot else 0.45)


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
