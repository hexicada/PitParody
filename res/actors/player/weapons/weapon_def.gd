extends Resource
class_name WeaponDef

## Data-only definition for a hitscan loadout weapon.

@export var id: StringName = &""
@export var display_name: String = "Weapon"
@export var damage: float = 25.0
@export var fire_cooldown: float = 0.14
@export var fire_range: float = 55.0
@export var pellet_count: int = 1
@export var spread_deg: float = 0.0
@export var hip_offset := Vector3.ZERO
@export var ads_offset := Vector3.ZERO
@export var body_color := Color(0.22, 0.24, 0.28, 1)
@export var accent_color := Color(0.95, 0.75, 0.2, 1)
@export var bark_lines: PackedStringArray = PackedStringArray()
@export var hud_tag: String = ""
