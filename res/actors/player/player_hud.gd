extends CanvasLayer
class_name PlayerHud

## Central player HUD: health bar, status, combat chrome, death screen.

@onready var state_label: Label = $Debug/StateLabel
@onready var hint_label: Label = $Debug/HintLabel
@onready var interaction_label: Label = $Debug/InteractionLabel

@onready var health_label: Label = $LeftStack/HealthLabel
@onready var okr_hud: Label = $LeftStack/OkrHud
@onready var heal_hud: Label = $LeftStack/HealHud

@onready var health_bar_root: Control = $HealthBarRoot
@onready var health_bar_fill: ColorRect = $HealthBarRoot/Fill
@onready var health_bar_label: Label = $HealthBarRoot/BarLabel

@onready var weapon_hud: Label = $WeaponHud
@onready var hit_marker: Control = $HitMarker
@onready var low_health_fx: Control = $LowHealthFx

@onready var death_overlay: Control = $DeathOverlay
@onready var death_title: Label = $DeathOverlay/Center/VBox/DeathTitle
@onready var death_killer: Label = $DeathOverlay/Center/VBox/DeathKiller
@onready var death_flavor: Label = $DeathOverlay/Center/VBox/DeathFlavor

var _health_bar_full_width: float = 354.0
var _hit_marker_timer: float = 0.0


func _ready() -> void:
	if health_bar_fill:
		_health_bar_full_width = maxf(health_bar_fill.size.x, 354.0)
	if hit_marker:
		hit_marker.modulate.a = 0.0
	if low_health_fx:
		low_health_fx.modulate.a = 0.0
	if death_overlay:
		death_overlay.visible = false


func _process(delta: float) -> void:
	if _hit_marker_timer > 0.0:
		_hit_marker_timer = maxf(_hit_marker_timer - delta, 0.0)
		if hit_marker:
			hit_marker.modulate.a = clampf(_hit_marker_timer / 0.12, 0.0, 1.0)


func set_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text


func set_state_line(text: String) -> void:
	if state_label:
		state_label.text = text


func set_interaction(text: String) -> void:
	if interaction_label:
		interaction_label.text = text


func set_weapon_line(text: String) -> void:
	if weapon_hud:
		weapon_hud.text = text


func set_okr_carrying(holding: bool) -> void:
	if okr_hud == null:
		return
	if holding:
		okr_hud.text = "Carrying: Voltaic OKR"
		okr_hud.modulate = Color(0.55, 1.0, 0.5, 1)
	else:
		okr_hud.text = "Carrying: —"
		okr_hud.modulate = Color(0.75, 0.75, 0.78, 0.85)


func set_heal_status(ready: bool, cooldown_left: float = 0.0) -> void:
	if heal_hud == null:
		return
	if ready:
		heal_hud.text = "Restorative Sync [Q]: READY"
		heal_hud.modulate = Color(0.5, 1.0, 0.65, 1.0)
	else:
		heal_hud.text = "Restorative Sync [Q]: %.1fs" % cooldown_left
		heal_hud.modulate = Color(0.7, 0.75, 0.8, 0.9)


func set_health(current: float, maximum: float, is_dead: bool = false) -> void:
	var shown := 0.0 if is_dead else current
	if health_label:
		health_label.text = "HP: %.0f / %.0f" % [shown, maximum]
	if health_bar_label:
		health_bar_label.text = "%.0f / %.0f" % [shown, maximum]
	if health_bar_fill:
		var ratio := 0.0 if maximum <= 0.0 else clampf(shown / maximum, 0.0, 1.0)
		health_bar_fill.offset_left = 3.0
		health_bar_fill.offset_top = 3.0
		health_bar_fill.offset_bottom = 27.0
		health_bar_fill.offset_right = 3.0 + _health_bar_full_width * ratio
		health_bar_fill.color = Color(1, 1, 1, 0.95 if ratio > 0.35 else 0.8)


func set_low_health_intensity(intensity: float) -> void:
	if low_health_fx == null:
		return
	low_health_fx.modulate.a = clampf(intensity, 0.0, 1.0)


func flash_hit_marker(duration: float = 0.12) -> void:
	_hit_marker_timer = duration
	if hit_marker:
		hit_marker.modulate.a = 1.0


func show_death(killer_line: String, flavor: String) -> void:
	if death_overlay:
		death_overlay.visible = true
	if death_title:
		death_title.text = "You are dead."
	if death_killer:
		death_killer.text = killer_line
	if death_flavor:
		death_flavor.text = flavor
	set_low_health_intensity(0.0)


func set_death_flavor(text: String) -> void:
	if death_flavor:
		death_flavor.text = text


func hide_death() -> void:
	if death_overlay:
		death_overlay.visible = false
