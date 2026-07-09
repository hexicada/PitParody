extends StaticBody3D
class_name HermenBoss

## Cardboard head boss: 3 damage phases, shield interludes with shareholder adds.

const _DamageNumber := preload("res://res/actors/fx/damage_number.gd")

enum FightState {
	VULNERABLE,
	SHIELDED,
	DEAD,
}

@export var display_name: String = "Hermen Hulst"
@export var max_health: float = 450.0
@export var bob_amp: float = 0.12
@export var bob_speed: float = 1.6
@export var face_player: bool = true
@export var turn_speed: float = 2.2
@export var worm_scene: PackedScene
@export var shield_wave_1_count: int = 3
@export var shield_wave_2_count: int = 5

var health: float
var phase: int = 1
var state: FightState = FightState.VULNERABLE
var _base_y: float
var _flash_left: float = 0.0
var _t: float = 0.0
var _adds: Array[Node] = []
var _spawn_index: int = 0

@onready var _visual: Node3D = $Cutout
@onready var _name_label: Label3D = $NameLabel
@onready var _taunt_label: Label3D = $TauntLabel
@onready var _status_label: Label3D = get_node_or_null("StatusLabel")
@onready var _shield_root: Node3D = get_node_or_null("ShieldMist")
@onready var _shield_light: OmniLight3D = get_node_or_null("ShieldMist/ShieldLight")
@onready var _spawn_root: Node3D = get_node_or_null("AddSpawnPoints")


func _ready() -> void:
	health = max_health
	_base_y = position.y
	add_to_group("enemy")
	add_to_group("damageable")
	add_to_group("boss")
	if worm_scene == null:
		worm_scene = load("res://res/actors/enemies/worm/worm.tscn") as PackedScene
	if _name_label:
		_name_label.text = "%s\nInstrument of the Portfolio" % display_name
	if _taunt_label:
		_taunt_label.text = "You took the scenic route."
	_set_shield_visual(false)
	_update_status()
	_dup_mats($Cutout)
	_crawl_face_uvs(0.0)


func _physics_process(delta: float) -> void:
	if state == FightState.DEAD:
		return

	_t += delta
	position.y = _base_y + sin(_t * bob_speed) * bob_amp
	if _visual:
		_visual.rotation_degrees.z = sin(_t * bob_speed * 0.7) * 3.0

	if face_player:
		var player := _find_player()
		if player:
			var to := player.global_position - global_position
			to.y = 0.0
			if to.length_squared() > 0.01:
				var target_yaw := atan2(to.x, to.z)
				rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))

	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		_apply_flash(_flash_left > 0.0)

	_crawl_face_uvs(_t)

	if state == FightState.SHIELDED:
		_prune_adds()
		if _adds.is_empty():
			_drop_shield()
		else:
			_update_status()


func take_damage(amount: float, _from: Node = null) -> void:
	if state == FightState.DEAD:
		return

	if state == FightState.SHIELDED:
		_DamageNumber.spawn(
			self,
			global_position + Vector3(0, 2.4, 0),
			"Immune!",
			Color(0.85, 0.95, 1.0),
			52
		)
		if _taunt_label:
			_taunt_label.text = "Shareholders still in the room."
		return

	var applied := amount
	var floor_hp := _phase_floor(phase)
	if health - applied < floor_hp:
		applied = health - floor_hp
	if applied <= 0.0 and health <= floor_hp and phase < 3:
		# Already at threshold — force shield if somehow still vulnerable
		_enter_shield()
		return

	health = maxf(health - applied, floor_hp)
	_flash_left = 0.12
	_apply_flash(true)
	_DamageNumber.spawn(
		self,
		global_position + Vector3(0, 2.4, 0),
		"-%d" % int(round(applied)),
		Color(1.0, 0.55, 0.15),
		48
	)
	if _taunt_label:
		_taunt_label.text = _random_taunt()
	_update_status()

	if phase < 3 and health <= floor_hp + 0.01:
		_enter_shield()
		return

	if phase >= 3 and health <= 0.0:
		_die()


func _phase_floor(p: int) -> float:
	# Three equal damage windows: 100%→66%, 66%→33%, 33%→0%
	match p:
		1:
			return max_health * (2.0 / 3.0)
		2:
			return max_health * (1.0 / 3.0)
		_:
			return 0.0


func _enter_shield() -> void:
	if state != FightState.VULNERABLE or phase >= 3:
		return
	state = FightState.SHIELDED
	health = _phase_floor(phase)  # lock at threshold
	_set_shield_visual(true)
	var count := shield_wave_1_count if phase == 1 else shield_wave_2_count
	_spawn_shareholders(count)
	if _taunt_label:
		_taunt_label.text = "SHIELDED — eliminate shareholders!"
	_update_status()


func _drop_shield() -> void:
	if state != FightState.SHIELDED:
		return
	phase = mini(phase + 1, 3)
	state = FightState.VULNERABLE
	_set_shield_visual(false)
	if _taunt_label:
		_taunt_label.text = "Shield dropped. Portfolio exposed."
	_DamageNumber.spawn(
		self,
		global_position + Vector3(0, 2.6, 0),
		"SHIELD DOWN",
		Color(0.4, 1.0, 0.55),
		40
	)
	_update_status()


func _spawn_shareholders(count: int) -> void:
	_prune_adds()
	if worm_scene == null:
		return
	var offsets := _spawn_offsets(count)
	for i in count:
		var worm := worm_scene.instantiate() as Node3D
		if worm == null:
			continue
		var parent: Node = get_tree().current_scene
		if parent == null:
			parent = get_parent()
		parent.add_child(worm)
		var off: Vector3 = offsets[i % offsets.size()]
		worm.global_position = global_position + off
		if "display_name" in worm:
			worm.set("display_name", _shareholder_name(i))
		if "patrol_half_extent" in worm:
			worm.set("patrol_half_extent", 2.2)
		worm.add_to_group("hermen_add")
		_adds.append(worm)
		_spawn_index += 1


func _spawn_offsets(count: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	# Around the dais; Y places them on boss room floor relative to boss base.
	var ring := [
		Vector3(-5.5, 0.1, 3.5),
		Vector3(-4.0, 0.1, -4.0),
		Vector3(3.5, 0.1, 4.5),
		Vector3(5.0, 0.1, -3.0),
		Vector3(-6.5, 0.1, 0.5),
		Vector3(2.0, 0.1, -5.5),
		Vector3(-2.5, 0.1, 5.5),
	]
	# Boss sits slightly above floor; worms need floor height ~ -44 world.
	# Use spawn points if present, else ring with corrected Y via floor snap later.
	if _spawn_root and _spawn_root.get_child_count() > 0:
		for c in _spawn_root.get_children():
			out.append(c.global_position - global_position)
	if out.is_empty():
		for i in count:
			var o: Vector3 = ring[i % ring.size()]
			# Boss origin is above the room floor; place worm feet on the floor.
			o.y = -0.9
			out.append(o)
	return out


func _shareholder_name(i: int) -> String:
	var names := [
		"Shareholder",
		"Board Observer",
		"Proxy Voter",
		"Preferred Stock",
		"Quiet Period",
		"Dilution Grub",
		"Quorum Worm",
	]
	return names[i % names.size()]


func _prune_adds() -> void:
	var live: Array[Node] = []
	for a in _adds:
		if is_instance_valid(a) and not a.is_queued_for_deletion():
			live.append(a)
	_adds = live


func _set_shield_visual(on: bool) -> void:
	if _shield_root:
		_shield_root.visible = on
	if _shield_light:
		_shield_light.visible = on
		_shield_light.light_energy = 3.2 if on else 0.0


func _update_status() -> void:
	if _status_label == null:
		return
	var hp_pct := int(round((health / maxf(max_health, 1.0)) * 100.0))
	match state:
		FightState.SHIELDED:
			_status_label.text = "Phase %d/3  ·  SHIELDED\nShareholders left: %d\nHP %d%% (locked)" % [
				phase, _adds.size(), hp_pct
			]
			_status_label.modulate = Color(0.75, 0.9, 1.0)
		FightState.VULNERABLE:
			_status_label.text = "Phase %d/3  ·  EXPOSED\nHP %d%%" % [phase, hp_pct]
			_status_label.modulate = Color(1.0, 0.75, 0.35)
		_:
			_status_label.text = "Phase complete"
			_status_label.modulate = Color(0.7, 1.0, 0.7)
	if _name_label and state != FightState.DEAD:
		_name_label.text = "%s\nInstrument of the Portfolio" % display_name


func _random_taunt() -> String:
	var lines := [
		"That's not in the portfolio.",
		"Have you considered synergy?",
		"We'll circle back.",
		"Bold strategy, entering that way.",
		"Head of Studios. Head of… you know.",
		"Live service is eternal.",
		"Your feedback is noted.",
		"This death will ship in a patch.",
	]
	return lines[randi() % lines.size()]


func _die() -> void:
	state = FightState.DEAD
	_set_shield_visual(false)
	# Clear remaining adds if any
	for a in _adds:
		if is_instance_valid(a):
			a.queue_free()
	_adds.clear()
	if _name_label:
		_name_label.text = "%s\n(portfolio restructured)" % display_name
	if _taunt_label:
		_taunt_label.text = "Okay that one hurt."
	if _status_label:
		_status_label.text = "DEFEATED"
		_status_label.modulate = Color(0.6, 1.0, 0.6)
	_DamageNumber.spawn(self, global_position + Vector3(0, 2.8, 0), "PORTFOLIO DOWN", Color(1, 0.3, 0.35), 44)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3(1.4, 0.08, 1.4), 0.55)
	tw.tween_property(self, "rotation_degrees:x", 80.0, 0.55)
	tw.chain().tween_callback(func() -> void:
		if _taunt_label:
			_taunt_label.text = "You beat the head.\n(The body is still the dungeon.)"
	)


func _find_player() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var players := tree.get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Node3D


func _dup_mats(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.material_override:
			mi.material_override = mi.material_override.duplicate()
	for c in node.get_children():
		_dup_mats(c)


func _apply_flash(hot: bool) -> void:
	if _visual == null:
		return
	for child in _visual.get_children():
		_flash_node(child, hot)


func _flash_node(node: Node, hot: bool) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.material_override is StandardMaterial3D:
			var mat := mi.material_override as StandardMaterial3D
			var rest := 0.35 if mat.albedo_texture != null else 0.15
			mat.emission_energy_multiplier = 1.8 if hot else rest
	for c in node.get_children():
		_flash_node(c, hot)


func _crawl_face_uvs(t: float) -> void:
	if _visual == null:
		return
	for child in _visual.get_children():
		if not (child is MeshInstance3D):
			continue
		var mi := child as MeshInstance3D
		if mi.material_override is StandardMaterial3D:
			var mat := mi.material_override as StandardMaterial3D
			if mat.albedo_texture == null:
				continue
			var ox := sin(t * 0.35 + child.position.x) * 0.04
			var oy := cos(t * 0.28 + child.position.y) * 0.03
			mat.uv1_offset = Vector3(ox, oy, 0.0)
