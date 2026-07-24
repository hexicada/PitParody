extends StaticBody3D
class_name EngagementPillar

## Dunk zone for Voltaic OKRs. Lit while waiting; charged after a deposit.

signal charged(pillar: EngagementPillar)

@export var pillar_index: int = 0

var is_charged: bool = false
var _pulse: float = 0.0

@onready var _mesh: MeshInstance3D = $PillarMesh
@onready var _ring: MeshInstance3D = $ChargeRing
@onready var _label: Label3D = $Label
@onready var _dunk_area: Area3D = $DunkArea
@onready var _light: OmniLight3D = $PillarLight


func _ready() -> void:
	add_to_group("engagement_pillar")
	if _mesh and _mesh.material_override:
		_mesh.material_override = _mesh.material_override.duplicate()
	if _ring and _ring.material_override:
		_ring.material_override = _ring.material_override.duplicate()
	if _dunk_area:
		_dunk_area.body_entered.connect(_on_dunk_body)
	_set_charged(false)


func _physics_process(delta: float) -> void:
	_pulse += delta
	if is_charged:
		if _ring:
			_ring.rotate_y(delta * 1.2)
		return
	if _ring:
		_ring.rotate_y(delta * 2.4)
		var s := 1.0 + sin(_pulse * 3.0) * 0.08
		_ring.scale = Vector3(s, 1.0, s)


func reset_for_wave() -> void:
	_set_charged(false)


func _on_dunk_body(body: Node) -> void:
	if is_charged:
		return
	var player := _find_player(body)
	if player == null:
		return
	if not player.has_method("has_okr") or not player.call("has_okr"):
		return
	if player.has_method("consume_okr") and player.call("consume_okr"):
		_set_charged(true)
		charged.emit(self)
		var dn := preload("res://res/actors/fx/damage_number.gd")
		dn.spawn(self, global_position + Vector3(0, 2.5, 0), "OKR BANKED", Color(0.45, 1.0, 0.55), 36)


func _set_charged(on: bool) -> void:
	is_charged = on
	if _label:
		_label.text = "Pillar charged" if on else "Pillar of Engagement\n(dunk Voltaic OKR)"
		_label.modulate = Color(0.5, 1.0, 0.6) if on else Color(0.85, 0.95, 1.0)
	if _light:
		_light.light_energy = 4.5 if on else 1.4
		_light.light_color = Color(0.4, 1.0, 0.5) if on else Color(0.7, 0.85, 1.0)
	if _mesh and _mesh.material_override is StandardMaterial3D:
		var mat := _mesh.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = 1.6 if on else 0.35
		mat.albedo_color = Color(0.35, 0.75, 0.45) if on else Color(0.45, 0.5, 0.6)
	if _ring and _ring.material_override is StandardMaterial3D:
		var rm := _ring.material_override as StandardMaterial3D
		rm.emission_energy_multiplier = 2.0 if on else 0.6
		rm.albedo_color = Color(0.4, 1.0, 0.55, 0.85) if on else Color(0.75, 0.9, 1.0, 0.55)


func _find_player(body: Node) -> Node:
	var n: Node = body
	while n:
		if n.is_in_group("player"):
			return n
		n = n.get_parent()
	return null
