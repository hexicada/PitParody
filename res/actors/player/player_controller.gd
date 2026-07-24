extends CharacterBody3D

@export var movement_profile: PlayerMovementProfile

var walk_speed: float
var sprint_speed: float
var crouch_speed: float
var jump_velocity: float
var ground_acceleration: float
var ground_deceleration: float
var air_acceleration: float
var max_air_jumps: int
var air_jump_velocity: float
var standing_capsule_height: float
var crouched_capsule_height: float
var standing_eye_height: float
var crouched_eye_height: float
var crouch_blend_speed: float
var mantle_min_height: float
var mantle_max_height: float
var mantle_duration: float
var mantle_forward_distance: float
var mantle_wall_angle_limit: float
var slide_start_speed: float
var slide_min_start_speed: float
var slide_duration: float
var slide_friction: float
var slide_cooldown: float

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var head_pivot: Node3D = $HeadPivot
@onready var camera_controller: PlayerCameraController = $HeadPivot
@onready var interaction_component: PlayerInteractionComponent = $HeadPivot/InteractionRayCast3D
@onready var mantle_probe_lower: RayCast3D = $MantleProbeLower
@onready var mantle_probe_upper: RayCast3D = $MantleProbeUpper
@onready var combat_bridge: PlayerCombatBridge = $CombatBridge
@onready var weapon_anchor: WeaponAnchor = $HeadPivot/Camera3D/ViewModelRoot/UpperFP/WeaponAnchor
@onready var camera_3d: Camera3D = $HeadPivot/Camera3D
@onready var hud: PlayerHud = $PlayerHud

@export var max_health: float = 300.0
@export var fire_damage: float = 25.0
@export var fire_range: float = 55.0
@export var fire_cooldown: float = 0.14
@export var death_hold_time: float = 3.6
@export_group("Healing")
@export var heal_ability_amount: float = 90.0
@export var heal_ability_cooldown: float = 14.0
@export var kill_heal_amount: float = 20.0
@export var ooc_regen_delay: float = 3.5
@export var ooc_regen_per_second: float = 12.0
@export_group("Low Health FX")
@export var low_health_start_ratio: float = 0.35
@export var low_health_full_ratio: float = 0.12

const _DamageNumber := preload("res://res/actors/fx/damage_number.gd")

var _gravity := 9.8
var _state := PlayerLocomotionState.Value.STANDING
var _is_crouching := false
var _crouch_alpha := 0.0
var _slide_time_left := 0.0
var _slide_cooldown_left := 0.0
var _slide_speed := 0.0
var _slide_direction := Vector3.ZERO
var _mantle_time_left := 0.0
var _mantle_start_position := Vector3.ZERO
var _mantle_target_position := Vector3.ZERO
var _air_jumps_left := 0
var health: float = 300.0
var _spawn_position: Vector3
var _spawn_yaw: float = 0.0
var _fire_cd: float = 0.0
var _is_dead: bool = false
var _death_timer: float = 0.0
var _camera_punch: float = 0.0
var _holding_okr: bool = false
var _heal_cd: float = 0.0
var _time_since_damage: float = 999.0


func _ready() -> void:
	add_to_group("player")
	_ensure_default_input_actions()
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_apply_movement_profile()
	_apply_crouch_pose(0.0)
	camera_controller.standing_eye_height = standing_eye_height
	camera_controller.crouched_eye_height = crouched_eye_height
	mantle_probe_lower.enabled = true
	mantle_probe_upper.enabled = true
	_air_jumps_left = max_air_jumps
	health = max_health
	_spawn_position = global_position
	_spawn_yaw = rotation.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if hud:
		hud.set_hint("WASD | Mouse | Shift sprint | Space jump | Ctrl crouch | LMB shoot | Q heal | F pick up OKR | dunk on pillars | Esc")
	combat_bridge.update_from_locomotion_state(_state)
	_update_okr_hud()
	_update_heal_hud()
	_update_health_ui()
	_update_debug_label()


func _apply_movement_profile() -> void:
	if movement_profile == null:
		movement_profile = PlayerMovementProfile.new()

	walk_speed = movement_profile.walk_speed
	sprint_speed = movement_profile.sprint_speed
	crouch_speed = movement_profile.crouch_speed
	jump_velocity = movement_profile.jump_velocity
	ground_acceleration = movement_profile.ground_acceleration
	ground_deceleration = movement_profile.ground_deceleration
	air_acceleration = movement_profile.air_acceleration
	max_air_jumps = movement_profile.max_air_jumps
	air_jump_velocity = movement_profile.air_jump_velocity
	standing_capsule_height = movement_profile.standing_capsule_height
	crouched_capsule_height = movement_profile.crouched_capsule_height
	standing_eye_height = movement_profile.standing_eye_height
	crouched_eye_height = movement_profile.crouched_eye_height
	crouch_blend_speed = movement_profile.crouch_blend_speed
	mantle_min_height = movement_profile.mantle_min_height
	mantle_max_height = movement_profile.mantle_max_height
	mantle_duration = movement_profile.mantle_duration
	mantle_forward_distance = movement_profile.mantle_forward_distance
	mantle_wall_angle_limit = movement_profile.mantle_wall_angle_limit
	slide_start_speed = movement_profile.slide_start_speed
	slide_min_start_speed = movement_profile.slide_min_start_speed
	slide_duration = movement_profile.slide_duration
	slide_friction = movement_profile.slide_friction
	slide_cooldown = movement_profile.slide_cooldown


func _input(event: InputEvent) -> void:
	# Use _input (not _unhandled_input) so HUD Controls can't swallow look/fire.
	if _is_dead:
		return

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return
		_try_fire()
		get_viewport().set_input_as_handled()
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event.is_action_pressed("ult") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q):
		_try_heal_ability()
		get_viewport().set_input_as_handled()
		return

	# Interact is also read by nearby Voltaic OKRs; keep binding hot.
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		camera_controller.handle_input(event, self)
		get_viewport().set_input_as_handled()


func take_damage(amount: float, from: Node = null) -> void:
	if _is_dead or health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	_time_since_damage = 0.0
	_camera_punch = minf(_camera_punch + 0.08, 0.25)
	_update_debug_label()
	if health <= 0.0:
		_begin_death(from)


func heal(amount: float, label: String = "HEAL", show_popup: bool = true) -> float:
	if _is_dead or amount <= 0.0 or health >= max_health:
		return 0.0
	var before := health
	health = minf(health + amount, max_health)
	var gained := health - before
	if gained <= 0.0:
		return 0.0
	if show_popup and gained >= 0.5:
		_DamageNumber.spawn(
			self,
			global_position + Vector3(0, 1.8, 0),
			"+%d" % int(round(gained)),
			Color(0.45, 1.0, 0.55),
			42
		)
		_set_weapon_hud("%s  ·  +%d HP" % [label, int(round(gained))])
	_update_debug_label()
	return gained


func notify_kill(_victim: Node = null) -> void:
	if _is_dead or kill_heal_amount <= 0.0:
		return
	heal(kill_heal_amount, "Kill heal", true)


func _try_heal_ability() -> void:
	if _is_dead:
		return
	if _heal_cd > 0.0:
		_set_weapon_hud("Restorative Sync on cooldown (%.1fs)" % _heal_cd)
		return
	if health >= max_health:
		_set_weapon_hud("Already at full Light / HP")
		return
	_heal_cd = heal_ability_cooldown
	heal(heal_ability_amount, "Restorative Sync", true)
	_update_heal_hud()


func has_okr() -> bool:
	return _holding_okr


func give_okr() -> bool:
	if _is_dead:
		return false
	if _holding_okr:
		_set_weapon_hud("Already carrying a Voltaic OKR (one at a time)")
		return false
	_holding_okr = true
	_update_okr_hud()
	_set_weapon_hud("Voltaic OKR acquired — dunk on a Pillar of Engagement")
	return true


func consume_okr() -> bool:
	if not _holding_okr:
		return false
	_holding_okr = false
	_update_okr_hud()
	_set_weapon_hud("OKR banked")
	return true


func clear_okr() -> void:
	_holding_okr = false
	_update_okr_hud()


func _update_okr_hud() -> void:
	if hud:
		hud.set_okr_carrying(_holding_okr)


func _update_heal_hud() -> void:
	if hud:
		hud.set_heal_status(_heal_cd <= 0.0, _heal_cd)


func _try_fire() -> void:
	if _is_dead or _fire_cd > 0.0:
		return
	if combat_bridge and combat_bridge.readiness == PlayerCombatBridge.WeaponReadiness.SLIDE:
		return
	_fire_cd = fire_cooldown
	_camera_punch = minf(_camera_punch + 0.035, 0.12)

	var gun := weapon_anchor.get_active_view_model() if weapon_anchor else null
	if gun and gun.has_method("on_fire"):
		gun.on_fire()
	elif weapon_anchor:
		for child in weapon_anchor.get_children():
			if child.has_method("on_fire"):
				child.on_fire()
				break

	if camera_3d == null:
		return
	var from := camera_3d.global_position
	var aim := -camera_3d.global_transform.basis.z
	var to := from + aim * fire_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	query.collision_mask = 0xFFFFFFFF
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_set_weapon_hud("The Feedback Loop  ·  missed (no alignment)")
		return
	var node: Node = hit.get("collider") as Node
	while node:
		if node != self and node.has_method("take_damage"):
			node.call("take_damage", fire_damage, self)
			_show_hit_marker()
			var victim_name := _killer_name(node)
			_set_weapon_hud("The Feedback Loop  ·  hit %s" % victim_name)
			return
		node = node.get_parent()
	_set_weapon_hud("The Feedback Loop  ·  terrain (out of scope)")


func _begin_death(from: Node = null) -> void:
	_is_dead = true
	_death_timer = death_hold_time
	velocity = Vector3.ZERO
	if hud:
		hud.show_death("Killed by\n%s" % _killer_name(from), _random_death_flavor())
	_update_debug_label()


func _finish_respawn() -> void:
	_is_dead = false
	_death_timer = 0.0
	if hud:
		hud.hide_death()
	global_position = _spawn_position
	rotation.y = _spawn_yaw
	velocity = Vector3.ZERO
	health = max_health
	_holding_okr = false
	_heal_cd = 0.0
	_time_since_damage = 999.0
	_state = PlayerLocomotionState.Value.STANDING
	_is_crouching = false
	_crouch_alpha = 0.0
	_apply_crouch_pose(0.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_weapon_hud("The Feedback Loop  ·  re-engaged")
	_update_okr_hud()
	_update_heal_hud()
	_update_debug_label()


func _killer_name(from: Node) -> String:
	if from == null:
		return "Unknown Hazard"
	if "display_name" in from:
		var n: Variant = from.get("display_name")
		if n != null and str(n) != "":
			return str(n)
	if from.name:
		return str(from.name)
	return "Unknown Hazard"


func _random_death_flavor() -> String:
	var lines := [
		"Your Light was reassigned.",
		"Scope expanded. You did not.",
		"Returning to the entry yard…",
		"Ghost says: maybe don't stand in the worm.",
		"Performance: Needs Improvement.",
		"This death will be reflected in the retro.",
	]
	return lines[randi() % lines.size()]


func _show_hit_marker() -> void:
	if hud:
		hud.flash_hit_marker(0.12)


func _set_weapon_hud(text: String) -> void:
	if hud:
		hud.set_weapon_line(text)


func _physics_process(delta: float) -> void:
	if _fire_cd > 0.0:
		_fire_cd = maxf(_fire_cd - delta, 0.0)
	if _heal_cd > 0.0:
		_heal_cd = maxf(_heal_cd - delta, 0.0)
		_update_heal_hud()
	else:
		_update_heal_hud()
	_time_since_damage += delta
	if not _is_dead and health < max_health and _time_since_damage >= ooc_regen_delay:
		heal(ooc_regen_per_second * delta, "Out-of-combat regen", false)
	_update_low_health_fx(delta)
	if _camera_punch > 0.0:
		_camera_punch = maxf(_camera_punch - delta * 0.8, 0.0)
		if camera_3d:
			camera_3d.rotation_degrees.x = -_camera_punch * 18.0
	elif camera_3d:
		camera_3d.rotation_degrees.x = move_toward(camera_3d.rotation_degrees.x, 0.0, 60.0 * delta)

	if _is_dead:
		_death_timer -= delta
		if _death_timer < 1.2 and hud:
			hud.set_death_flavor("Respawning…")
		if _death_timer <= 0.0:
			_finish_respawn()
		_update_debug_label()
		return

	camera_controller.update_controller_look(self, delta)

	if _state == PlayerLocomotionState.Value.MANTLING:
		_update_mantle(delta)
		camera_controller.update_state_effects(false, false, delta)
		combat_bridge.update_from_locomotion_state(_state)
		if weapon_anchor:
			var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
			weapon_anchor.set_ads_enabled(lowered)
		_update_debug_label()
		return

	if _slide_cooldown_left > 0.0:
		_slide_cooldown_left = max(_slide_cooldown_left - delta, 0.0)

	var on_floor := is_on_floor()
	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if on_floor:
		_air_jumps_left = max_air_jumps

	if Input.is_action_just_pressed("jump"):
		if on_floor:
			_end_slide()
			velocity.y = jump_velocity
		elif _air_jumps_left > 0:
			_air_jumps_left -= 1
			velocity.y = air_jump_velocity

	var sprint_requested := _can_sprint(move_input, on_floor)
	if _can_start_slide(sprint_requested) and Input.is_action_just_pressed("crouch"):
		_begin_slide()

	if _can_start_mantle(move_input, on_floor):
		_begin_mantle()
		camera_controller.update_state_effects(false, false, delta)
		combat_bridge.update_from_locomotion_state(_state)
		if weapon_anchor:
			var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
			weapon_anchor.set_ads_enabled(lowered)
		_update_debug_label()
		return

	_update_slide(delta)
	_update_crouch_state(delta)
	_update_horizontal_velocity(move_input, delta)
	camera_controller.update_state_effects(
		_state == PlayerLocomotionState.Value.SPRINTING,
		_state == PlayerLocomotionState.Value.SLIDING,
		delta
	)

	if not on_floor:
		velocity.y -= _gravity * delta

	move_and_slide()
	_update_state(sprint_requested)
	combat_bridge.update_from_locomotion_state(_state)
	if weapon_anchor:
		var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
		weapon_anchor.set_ads_enabled(lowered)
	_update_debug_label()


func _update_horizontal_velocity(move_input: Vector2, delta: float) -> void:
	var current_horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var desired_horizontal := Vector3.ZERO

	if _state == PlayerLocomotionState.Value.SLIDING:
		desired_horizontal = _slide_direction * _slide_speed
	else:
		var local_dir := Vector3(move_input.x, 0.0, move_input.y)
		var world_dir := (global_transform.basis * local_dir)
		world_dir.y = 0.0
		world_dir = world_dir.normalized()
		desired_horizontal = world_dir * _current_target_speed()

	var accel := ground_acceleration if is_on_floor() else air_acceleration
	var decel := ground_deceleration if is_on_floor() else air_acceleration
	var blend := accel if desired_horizontal.length() > 0.0 else decel
	current_horizontal = current_horizontal.move_toward(desired_horizontal, blend * delta)

	velocity.x = current_horizontal.x
	velocity.z = current_horizontal.z


func _update_state(sprint_requested: bool) -> void:
	if not is_on_floor():
		_state = PlayerLocomotionState.Value.AIRBORNE
		return

	if _state == PlayerLocomotionState.Value.SLIDING:
		return

	if _state == PlayerLocomotionState.Value.MANTLING:
		return

	if _is_crouching:
		_state = PlayerLocomotionState.Value.CROUCHED
		return

	if sprint_requested:
		_state = PlayerLocomotionState.Value.SPRINTING
		return

	_state = PlayerLocomotionState.Value.STANDING


func _current_target_speed() -> float:
	match _state:
		PlayerLocomotionState.Value.CROUCHED:
			return crouch_speed
		PlayerLocomotionState.Value.SPRINTING:
			return sprint_speed
		PlayerLocomotionState.Value.AIRBORNE:
			return walk_speed
		_:
			return walk_speed


func _update_crouch_state(delta: float) -> void:
	var crouch_held := Input.is_action_pressed("crouch")

	if _state == PlayerLocomotionState.Value.SLIDING:
		_is_crouching = true
	elif crouch_held:
		_is_crouching = true
	elif _can_stand_up():
		_is_crouching = false

	var target_alpha := 1.0 if _is_crouching else 0.0
	_crouch_alpha = move_toward(_crouch_alpha, target_alpha, crouch_blend_speed * delta)
	_apply_crouch_pose(_crouch_alpha)
	camera_controller.update_eye_height(_crouch_alpha, delta)


func _apply_crouch_pose(alpha: float) -> void:
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule == null:
		return

	var new_height: float = lerpf(standing_capsule_height, crouched_capsule_height, alpha)
	capsule.height = new_height
	collision_shape.position.y = new_height * 0.5
	body_mesh.position.y = collision_shape.position.y


func _can_stand_up() -> bool:
	if _state == PlayerLocomotionState.Value.SLIDING:
		return false

	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule == null:
		return true

	var required_clearance: float = maxf(standing_capsule_height - capsule.height, 0.0)
	if required_clearance <= 0.0:
		return true

	return not test_move(global_transform, Vector3.UP * required_clearance)


func _can_sprint(move_input: Vector2, on_floor: bool) -> bool:
	if not on_floor:
		return false

	if _is_crouching:
		return false

	if not Input.is_action_pressed("sprint"):
		return false

	return move_input.y < -0.35 and move_input.length() > 0.15


func _can_start_slide(sprint_requested: bool) -> bool:
	if _slide_cooldown_left > 0.0:
		return false

	if _state == PlayerLocomotionState.Value.SLIDING:
		return false

	if not is_on_floor():
		return false

	if not sprint_requested:
		return false

	return _horizontal_speed() >= slide_min_start_speed


func _begin_slide() -> void:
	_state = PlayerLocomotionState.Value.SLIDING
	_is_crouching = true
	_slide_time_left = slide_duration
	_slide_speed = max(_horizontal_speed(), slide_start_speed)
	_slide_direction = -global_transform.basis.z
	_slide_direction.y = 0.0
	_slide_direction = _slide_direction.normalized()


func _update_slide(delta: float) -> void:
	if _state != PlayerLocomotionState.Value.SLIDING:
		return

	_slide_time_left -= delta
	_slide_speed = move_toward(_slide_speed, crouch_speed, slide_friction * delta)
	if _slide_time_left <= 0.0 or _slide_speed <= crouch_speed + 0.2 or not is_on_floor():
		_end_slide()


func _end_slide() -> void:
	if _state == PlayerLocomotionState.Value.SLIDING:
		_slide_cooldown_left = slide_cooldown
	_state = PlayerLocomotionState.Value.STANDING
	_slide_time_left = 0.0
	combat_bridge.update_from_locomotion_state(_state)
	if weapon_anchor:
		var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
		weapon_anchor.set_ads_enabled(lowered)


func _can_start_mantle(move_input: Vector2, on_floor: bool) -> bool:
	if on_floor:
		return false

	if _state == PlayerLocomotionState.Value.SLIDING or _state == PlayerLocomotionState.Value.MANTLING:
		return false

	# Very permissive input: only hard back-pushing or almost no movement blocks it.
	# We want mantle to trigger on "any contact" with a valid ledge.
	if move_input.y > 0.45 or (move_input.length() < 0.05 and _horizontal_speed() < 0.8):
		return false

	# Extremely loose vertical velocity. We want reach-up even near jump apex or slight rise.
	if velocity.y > 7.5:
		return false

	# Main check: broad multi-direction, multi-height ledge finder.
	# This is designed to trigger whenever the player is in reasonable contact
	# with a ledge, including from angled approaches and ledges slightly above head.
	if _find_ledge_target() == null:
		return false

	return true


# Improved forgiving ledge detection.
# Uses a fan of forward directions (for angled approaches) and many heights
# (to catch ledges at or slightly above head height). Prefers any reasonable
# wall contact while airborne.
func _find_ledge_target() -> Variant:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	if forward.length() < 0.01:
		return null

	var space_state := get_world_3d().direct_space_state

	# Fan of directions to support angled approaches (not just perfectly straight-on).
	var dirs: Array[Vector3] = [forward]
	var side_angle := 0.45  # ~26 degrees left/right
	dirs.append(forward.rotated(Vector3.UP, side_angle))
	dirs.append(forward.rotated(Vector3.UP, -side_angle))
	# A bit wider for very forgiving "any contact"
	dirs.append(forward.rotated(Vector3.UP, side_angle * 1.6))
	dirs.append(forward.rotated(Vector3.UP, -side_angle * 1.6))

	# Heights from low (waist) to above head. Higher values enable "slightly higher than head" ledges.
	var test_heights: Array[float] = [0.5, 0.8, 1.1, 1.4, 1.7, 2.0, 2.3, 2.6]

	var wall_hit := {}
	for d in dirs:
		for h in test_heights:
			var from_pos := global_position + Vector3(0.0, h, 0.0)
			var to_pos := from_pos + d * (mantle_forward_distance + 0.5)
			var query := PhysicsRayQueryParameters3D.create(from_pos, to_pos)
			query.exclude = [self]
			var hit := space_state.intersect_ray(query)
			if not hit.is_empty():
				var normal: Vector3 = hit.get("normal", Vector3.UP)
				if absf(normal.y) <= mantle_wall_angle_limit:
					wall_hit = hit
					break
		if not wall_hit.is_empty():
			break

	if wall_hit.is_empty():
		# Fallback: use the probe data if the broad search missed but probes have contact.
		# This helps "any time in contact".
		if mantle_probe_lower.is_colliding():
			var n := mantle_probe_lower.get_collision_normal()
			if absf(n.y) <= mantle_wall_angle_limit:
				wall_hit = {
					"position": mantle_probe_lower.get_collision_point(),
					"normal": n
				}

	if wall_hit.is_empty():
		return null

	var hit_point: Vector3 = wall_hit["position"]

	# Search for ledge top, starting quite high to support above-head reaches.
	var search_up := mantle_max_height + 1.3
	var ray_from := hit_point + forward * 0.25 + Vector3.UP * search_up
	var ray_to := hit_point + forward * 0.25 - Vector3.UP * (search_up + 3.2)
	var top_query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	top_query.exclude = [self]
	var top_hit := space_state.intersect_ray(top_query)
	if top_hit.is_empty():
		return null

	var top_point: Vector3 = top_hit["position"]

	var base_target := top_point + Vector3.UP * (standing_capsule_height * 0.5 + 0.07) + forward * 0.1
	var target := base_target

	# Generous clearance search so it succeeds from many contact angles/positions.
	if test_move(global_transform, target - global_position):
		var found_clear_target := false
		for i in range(1, 14):
			var candidate := base_target - forward * (0.1 * float(i))
			if not test_move(global_transform, candidate - global_position):
				target = candidate
				found_clear_target = true
				break

		if not found_clear_target:
			for i in range(1, 6):
				var candidate_up := base_target + Vector3.UP * (0.08 * float(i))
				if not test_move(global_transform, candidate_up - global_position):
					target = candidate_up
					found_clear_target = true
					break

		if not found_clear_target:
			return null

	return target


func _begin_mantle() -> void:
	var target = _find_ledge_target()
	if target == null:
		return

	_state = PlayerLocomotionState.Value.MANTLING
	velocity = Vector3.ZERO
	_is_crouching = false
	_mantle_time_left = mantle_duration
	_mantle_start_position = global_position
	_mantle_target_position = target
	combat_bridge.update_from_locomotion_state(_state)
	if weapon_anchor:
		var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
		weapon_anchor.set_ads_enabled(lowered)


func _update_mantle(delta: float) -> void:
	_mantle_time_left = max(_mantle_time_left - delta, 0.0)
	var t := 1.0 - (_mantle_time_left / maxf(mantle_duration, 0.001))
	t = clampf(t, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	global_position = _mantle_start_position.lerp(_mantle_target_position, eased)

	if _mantle_time_left <= 0.0:
		global_position = _mantle_target_position
		_state = PlayerLocomotionState.Value.STANDING
		combat_bridge.update_from_locomotion_state(_state)
		if weapon_anchor:
			var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
			weapon_anchor.set_ads_enabled(lowered)


func _horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func _update_debug_label() -> void:
	var state_name := PlayerLocomotionState.name_for(_state)
	var weapon_ready := combat_bridge.readiness_name() if combat_bridge else "-"
	if hud:
		hud.set_state_line("State: %s | Speed: %.2f | Weapon: %s" % [
			state_name,
			_horizontal_speed(),
			weapon_ready
		])
		hud.set_interaction(interaction_component.get_interaction_hint())
	_update_health_ui()


func _update_health_ui() -> void:
	if hud:
		hud.set_health(health, max_health, _is_dead)


func _update_low_health_fx(_delta: float) -> void:
	if hud == null:
		return
	if _is_dead:
		hud.set_low_health_intensity(0.0)
		return
	var ratio := 0.0 if max_health <= 0.0 else health / max_health
	var start_r := low_health_start_ratio
	var full_r := low_health_full_ratio
	var danger := 0.0
	if ratio <= start_r:
		danger = clampf((start_r - ratio) / maxf(start_r - full_r, 0.001), 0.0, 1.0)
	if danger > 0.55:
		danger = clampf(danger + sin(Time.get_ticks_msec() * 0.008) * 0.08, 0.0, 1.0)
	hud.set_low_health_intensity(danger * 0.9)


func _ensure_default_input_actions() -> void:
	_ensure_action_with_key("move_forward", KEY_W)
	_ensure_action_with_key("move_back", KEY_S)
	_ensure_action_with_key("move_left", KEY_A)
	_ensure_action_with_key("move_right", KEY_D)
	_ensure_action_with_key("jump", KEY_SPACE)
	_ensure_action_with_key("sprint", KEY_SHIFT)
	_ensure_action_with_key("crouch", KEY_CTRL)
	_ensure_action_with_key("ult", KEY_Q)
	_ensure_action_with_key("interact", KEY_F)


func _ensure_action_with_key(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	if InputMap.action_has_event(action_name, key_event):
		return

	InputMap.action_add_event(action_name, key_event)
