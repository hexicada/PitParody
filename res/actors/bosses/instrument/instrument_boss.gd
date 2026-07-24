extends StaticBody3D
class_name InstrumentBoss

## The Instrument — live-service thoughtform. Zulmak-shaped: DPS → immune → thrall → OKR dunks → DPS.

enum FightState {
	VULNERABLE,
	SHIELDED,
	DEAD,
}

const _DamageNumber := preload("res://res/actors/fx/damage_number.gd")

@export var display_name: String = "The Instrument"
@export var max_health: float = 450.0
@export var bob_amp: float = 0.1
@export var bob_speed: float = 1.5
@export var face_player: bool = true
@export var turn_speed: float = 2.0
@export var thrall_scene: PackedScene
@export var okr_scene: PackedScene
@export var pillar_scene: PackedScene
@export var shield_wave_1_thralls: int = 3
@export var shield_wave_2_thralls: int = 5
@export var wave_1_pillars: int = 2
@export var wave_2_pillars: int = 3

var health: float
var phase: int = 1
var state: FightState = FightState.VULNERABLE
var _base_y: float
var _flash_left: float = 0.0
var _t: float = 0.0
var _adds: Array[Node] = []
var _pillars: Array[Node] = []
var _pillars_needed: int = 0
var _pillars_charged: int = 0
var _recent_drop_keys: Dictionary = {}

@onready var _visual: Node3D = $Body
@onready var _name_label: Label3D = $NameLabel
@onready var _taunt_label: Label3D = $TauntLabel
@onready var _status_label: Label3D = $StatusLabel
@onready var _shield_root: Node3D = $ShieldMist
@onready var _shield_light: OmniLight3D = $ShieldMist/ShieldLight
@onready var _pillar_anchor: Node3D = $PillarSlots


func _ready() -> void:
	health = max_health
	_base_y = position.y
	add_to_group("enemy")
	add_to_group("damageable")
	add_to_group("boss")
	if thrall_scene == null:
		thrall_scene = load("res://res/actors/enemies/worm/worm.tscn") as PackedScene
	if okr_scene == null:
		okr_scene = load("res://res/actors/bosses/instrument/voltaic_okr.tscn") as PackedScene
	if pillar_scene == null:
		pillar_scene = load("res://res/actors/bosses/instrument/engagement_pillar.tscn") as PackedScene
	if _name_label:
		_name_label.text = "%s\nThoughtform of the Portfolio" % display_name
	if _taunt_label:
		_taunt_label.text = "A live service wears many faces."
	_set_shield_visual(false)
	_hide_pillars()
	_update_status()
	_dup_mats($Body)


func _physics_process(delta: float) -> void:
	if state == FightState.DEAD:
		return

	_t += delta
	position.y = _base_y + sin(_t * bob_speed) * bob_amp
	if _visual:
		_visual.rotation_degrees.y = sin(_t * 0.4) * 6.0
		var halo := _visual.get_node_or_null("ThoughtHalo") as Node3D
		if halo:
			halo.rotate_y(delta * 0.9)

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

	if state == FightState.SHIELDED:
		_prune_adds()
		_ensure_thrall_for_remaining_dunks()
		_update_status()


func take_damage(amount: float, _from: Node = null) -> void:
	if state == FightState.DEAD:
		return

	if state == FightState.SHIELDED:
		_DamageNumber.spawn(
			self,
			global_position + Vector3(0, 2.8, 0),
			"Immune!",
			Color(0.85, 0.95, 1.0),
			52
		)
		if _taunt_label:
			_taunt_label.text = "Bank the OKRs. Break the mist."
		return

	var floor_hp := _phase_floor(phase)
	var applied := amount
	if health - applied < floor_hp:
		applied = health - floor_hp
	if applied <= 0.0:
		if phase < 3 and health <= floor_hp + 0.01:
			_enter_shield()
		return

	health = maxf(health - applied, floor_hp)
	_flash_left = 0.12
	_apply_flash(true)
	_DamageNumber.spawn(
		self,
		global_position + Vector3(0, 2.8, 0),
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
	health = _phase_floor(phase)
	_set_shield_visual(true)
	_pillars_needed = wave_1_pillars if phase == 1 else wave_2_pillars
	_pillars_charged = 0
	_spawn_pillars(_pillars_needed)
	var thrall_n := shield_wave_1_thralls if phase == 1 else shield_wave_2_thralls
	_spawn_thralls(thrall_n)
	if _taunt_label:
		_taunt_label.text = "SHIELDED — kill thrall, dunk Voltaic OKRs"
	_DamageNumber.spawn(
		self,
		global_position + Vector3(0, 3.0, 0),
		"SHIELD UP",
		Color(0.8, 0.9, 1.0),
		40
	)
	_update_status()


func _on_pillar_charged(_pillar: EngagementPillar) -> void:
	if state != FightState.SHIELDED:
		return
	_pillars_charged += 1
	_update_status()
	if _pillars_charged >= _pillars_needed:
		_drop_shield()


func _drop_shield() -> void:
	if state != FightState.SHIELDED:
		return
	phase = mini(phase + 1, 3)
	state = FightState.VULNERABLE
	_set_shield_visual(false)
	_clear_pillars()
	_clear_adds()
	_clear_stray_okrs()
	if _taunt_label:
		_taunt_label.text = "Shield dropped. The thoughtform flinches."
	_DamageNumber.spawn(
		self,
		global_position + Vector3(0, 3.0, 0),
		"SHIELD DOWN",
		Color(0.4, 1.0, 0.55),
		40
	)
	_update_status()


func _spawn_pillars(count: int) -> void:
	_clear_pillars()
	if pillar_scene == null:
		return
	var slots := _pillar_slot_offsets(count)
	for i in count:
		var p := pillar_scene.instantiate() as Node3D
		if p == null:
			continue
		var parent: Node = get_tree().current_scene
		if parent == null:
			parent = get_parent()
		parent.add_child(p)
		p.global_position = global_position + slots[i]
		if p is EngagementPillar:
			var ep := p as EngagementPillar
			ep.pillar_index = i
			ep.reset_for_wave()
			if not ep.charged.is_connected(_on_pillar_charged):
				ep.charged.connect(_on_pillar_charged)
		_pillars.append(p)


func _pillar_slot_offsets(count: int) -> Array[Vector3]:
	# Relative to boss; Y places base on boss-room floor.
	var y := -0.85
	if count <= 2:
		return [Vector3(-6.5, y, 4.0), Vector3(-6.5, y, -4.0)] as Array[Vector3]
	return [
		Vector3(-7.0, y, 5.0),
		Vector3(-7.5, y, 0.0),
		Vector3(-7.0, y, -5.0),
	] as Array[Vector3]


func _spawn_thralls(count: int) -> void:
	if thrall_scene == null or count <= 0:
		return
	var ring := [
		Vector3(-5.0, -0.9, 3.0),
		Vector3(-4.0, -0.9, -3.5),
		Vector3(3.5, -0.9, 4.0),
		Vector3(4.5, -0.9, -3.0),
		Vector3(-3.0, -0.9, 5.5),
		Vector3(2.5, -0.9, -5.0),
	]
	var start_i := _adds.size()
	for i in count:
		var thrall := thrall_scene.instantiate() as Node3D
		if thrall == null:
			continue
		var parent: Node = get_tree().current_scene
		if parent == null:
			parent = get_parent()
		parent.add_child(thrall)
		thrall.global_position = global_position + ring[(start_i + i) % ring.size()]
		if "display_name" in thrall:
			thrall.set("display_name", _thrall_name(start_i + i))
		if "patrol_half_extent" in thrall:
			thrall.set("patrol_half_extent", 2.0)
		if thrall.has_signal("died"):
			thrall.died.connect(_on_thrall_died)
		thrall.add_to_group("board_thrall")
		_adds.append(thrall)


func _on_thrall_died(world_pos: Vector3) -> void:
	notify_thrall_killed(world_pos)


func notify_thrall_killed(world_pos: Vector3) -> void:
	if state != FightState.SHIELDED:
		return
	# Dedupe if both signal and call_group fire for the same kill.
	var frame := Engine.get_process_frames()
	var key := "%d_%d_%d" % [int(world_pos.x * 5.0), int(world_pos.y * 5.0), int(world_pos.z * 5.0)]
	if int(_recent_drop_keys.get(key, -1)) == frame:
		return
	_recent_drop_keys[key] = frame
	# Drop near floor height (boss pedestal is slightly above floor).
	var drop := world_pos
	drop.y = global_position.y - 0.35
	_spawn_okr_at(drop)


func _spawn_okr_at(world_pos: Vector3) -> void:
	if okr_scene == null or state != FightState.SHIELDED:
		return
	var mote := okr_scene.instantiate() as Node3D
	if mote == null:
		return
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(mote)
	if mote.has_method("place_at"):
		mote.call("place_at", world_pos)
	else:
		mote.global_position = world_pos
	_DamageNumber.spawn(self, world_pos + Vector3(0, 0.8, 0), "OKR", Color(0.5, 1.0, 0.45), 28)


func _ground_okrs_available() -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var n := 0
	for node in tree.get_nodes_in_group("voltaic_okr"):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			n += 1
	return n


func _player_holds_okr() -> bool:
	var player := _find_player()
	if player and player.has_method("has_okr"):
		return bool(player.call("has_okr"))
	return false


func _remaining_dunks() -> int:
	return maxi(_pillars_needed - _pillars_charged, 0)


func _ensure_thrall_for_remaining_dunks() -> void:
	# Soft-lock prevention: if still need dunks but no thrall/orbs in play, respawn thrall.
	var need := _remaining_dunks()
	if need <= 0:
		return
	var supply := _adds.size() + _ground_okrs_available() + (1 if _player_holds_okr() else 0)
	if supply >= need:
		return
	var missing := need - supply
	_spawn_thralls(missing)
	if _taunt_label:
		_taunt_label.text = "More thrall join the board. Harvest OKRs."


func _thrall_name(i: int) -> String:
	var names := [
		"Board Thrall",
		"Proxy Vote",
		"Quorum Grub",
		"Dilution Worm",
		"Silent Partner",
		"Preferred Stock",
	]
	return names[i % names.size()]


func _prune_adds() -> void:
	var live: Array[Node] = []
	for a in _adds:
		if is_instance_valid(a) and not a.is_queued_for_deletion():
			live.append(a)
	_adds = live


func _clear_adds() -> void:
	for a in _adds:
		if is_instance_valid(a):
			a.queue_free()
	_adds.clear()


func _clear_pillars() -> void:
	for p in _pillars:
		if is_instance_valid(p):
			p.queue_free()
	_pillars.clear()
	_pillars_charged = 0
	_pillars_needed = 0


func _clear_stray_okrs() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for n in tree.get_nodes_in_group("voltaic_okr"):
		if is_instance_valid(n):
			n.queue_free()
	var player := _find_player()
	if player and player.has_method("clear_okr"):
		player.call("clear_okr")


func _hide_pillars() -> void:
	_clear_pillars()


func _set_shield_visual(on: bool) -> void:
	if _shield_root:
		_shield_root.visible = on
	if _shield_light:
		_shield_light.visible = on
		_shield_light.light_energy = 3.4 if on else 0.0


func _update_status() -> void:
	if _status_label == null:
		return
	var hp_pct := int(round((health / maxf(max_health, 1.0)) * 100.0))
	match state:
		FightState.SHIELDED:
			_status_label.text = "Phase %d/3  ·  SHIELDED\nPillars %d/%d  ·  Thrall %d\nHP %d%% (locked)" % [
				phase, _pillars_charged, _pillars_needed, _adds.size(), hp_pct
			]
			_status_label.modulate = Color(0.75, 0.9, 1.0)
		FightState.VULNERABLE:
			_status_label.text = "Phase %d/3  ·  EXPOSED\nHP %d%%" % [phase, hp_pct]
			_status_label.modulate = Color(1.0, 0.75, 0.35)
		_:
			_status_label.text = "Thoughtform collapsed"
			_status_label.modulate = Color(0.7, 1.0, 0.7)


func _random_taunt() -> String:
	var lines := [
		"Synergy is a contagion.",
		"I wear whoever sits the chair.",
		"Your Light is an OKR now.",
		"Live service is eternal.",
		"The board thrives in the dark.",
		"Feedback received. Ignored.",
		"Circle back after the dunk.",
	]
	return lines[randi() % lines.size()]


func _die() -> void:
	state = FightState.DEAD
	_set_shield_visual(false)
	_clear_pillars()
	_clear_adds()
	_clear_stray_okrs()
	if _name_label:
		_name_label.text = "%s\n(portfolio restructured)" % display_name
	if _taunt_label:
		_taunt_label.text = "The infection loses cohesion."
	if _status_label:
		_status_label.text = "DEFEATED"
		_status_label.modulate = Color(0.6, 1.0, 0.6)
	_DamageNumber.spawn(self, global_position + Vector3(0, 3.0, 0), "PORTFOLIO DOWN", Color(1, 0.3, 0.35), 44)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.3, 0.1, 1.3), 0.6)
	tw.tween_callback(func() -> void:
		if _taunt_label:
			_taunt_label.text = "Thoughtform purged.\n(The dungeon still ships.)"
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
			mat.emission_energy_multiplier = 2.0 if hot else 0.4
	for c in node.get_children():
		_flash_node(c, hot)
