extends RefCounted
class_name WeaponCatalog

## Comedy Destiny-parody loadout. All five unlocked by default.


static func all_weapons() -> Array[WeaponDef]:
	return [
		_feedback_loop(),
		_scope_creep(),
		_stakeholder_shotgun(),
		_ping_of_shame(),
		_quarterly_review(),
	]


static func count() -> int:
	return 5


static func weapon_at(index: int) -> WeaponDef:
	var list := all_weapons()
	if list.is_empty():
		return WeaponDef.new()
	return list[posmod(index, list.size())]


static func _feedback_loop() -> WeaponDef:
	var w := WeaponDef.new()
	w.id = &"feedback_loop"
	w.display_name = "The Feedback Loop"
	w.hud_tag = "AR"
	w.damage = 25.0
	w.fire_cooldown = 0.14
	w.fire_range = 55.0
	w.pellet_count = 1
	w.spread_deg = 0.0
	w.hip_offset = Vector3(0.06, -0.06, 0.02)
	w.ads_offset = Vector3(0.01, -0.015, -0.11)
	w.body_color = Color(0.22, 0.24, 0.28, 1)
	w.accent_color = Color(0.95, 0.75, 0.2, 1)
	w.bark_lines = PackedStringArray([
		"Action item!",
		"Circling back!",
		"Per my last bullet!",
		"Synergy applied.",
		"Let's take this offline.",
		"Noted.",
		"Bandwidth secured.",
		"Stakeholder aligned.",
	])
	return w


static func _scope_creep() -> WeaponDef:
	var w := WeaponDef.new()
	w.id = &"scope_creep"
	w.display_name = "Scope Creep"
	w.hud_tag = "SCTR"
	w.damage = 95.0
	w.fire_cooldown = 0.85
	w.fire_range = 120.0
	w.pellet_count = 1
	w.spread_deg = 0.0
	w.hip_offset = Vector3(0.08, -0.05, 0.04)
	w.ads_offset = Vector3(0.0, -0.01, -0.16)
	w.body_color = Color(0.18, 0.22, 0.3, 1)
	w.accent_color = Color(0.35, 0.75, 1.0, 1)
	w.bark_lines = PackedStringArray([
		"Requirements updated.",
		"Just one more feature!",
		"Mid-sprint pivot!",
		"Out of scope? Never.",
		"Long-range alignment.",
		"Precision deck.",
	])
	return w


static func _stakeholder_shotgun() -> WeaponDef:
	var w := WeaponDef.new()
	w.id = &"stakeholder_shotgun"
	w.display_name = "Stakeholder Shotgun"
	w.hud_tag = "SG"
	w.damage = 14.0
	w.fire_cooldown = 0.75
	w.fire_range = 18.0
	w.pellet_count = 8
	w.spread_deg = 8.5
	w.hip_offset = Vector3(0.07, -0.08, 0.0)
	w.ads_offset = Vector3(0.02, -0.03, -0.08)
	w.body_color = Color(0.28, 0.2, 0.16, 1)
	w.accent_color = Color(1.0, 0.45, 0.2, 1)
	w.bark_lines = PackedStringArray([
		"Consensus achieved!",
		"All hands on deck!",
		"Buy-in secured.",
		"Close-range synergy!",
		"Spray and pray the roadmap.",
		"Meeting adjourned.",
	])
	return w


static func _ping_of_shame() -> WeaponDef:
	var w := WeaponDef.new()
	w.id = &"ping_of_shame"
	w.display_name = "Ping of Shame"
	w.hud_tag = "SMG"
	w.damage = 12.0
	w.fire_cooldown = 0.07
	w.fire_range = 35.0
	w.pellet_count = 1
	w.spread_deg = 1.8
	w.hip_offset = Vector3(0.05, -0.05, 0.03)
	w.ads_offset = Vector3(0.01, -0.012, -0.09)
	w.body_color = Color(0.2, 0.26, 0.22, 1)
	w.accent_color = Color(0.55, 1.0, 0.45, 1)
	w.bark_lines = PackedStringArray([
		"@everyone",
		"Seen at 3am.",
		"Can you hop on a call?",
		"Quick ping!",
		"Read receipts enabled.",
		"Typing…",
	])
	return w


static func _quarterly_review() -> WeaponDef:
	var w := WeaponDef.new()
	w.id = &"quarterly_review"
	w.display_name = "Quarterly Review"
	w.hud_tag = "HVY"
	w.damage = 160.0
	w.fire_cooldown = 1.35
	w.fire_range = 45.0
	w.pellet_count = 1
	w.spread_deg = 0.5
	w.hip_offset = Vector3(0.09, -0.09, -0.02)
	w.ads_offset = Vector3(0.02, -0.04, -0.12)
	w.body_color = Color(0.32, 0.18, 0.2, 1)
	w.accent_color = Color(1.0, 0.3, 0.35, 1)
	w.bark_lines = PackedStringArray([
		"Needs Improvement.",
		"Exceeds Expectations!",
		"See me after the retro.",
		"KPI: liquidated.",
		"Performance managed.",
		"Q4 loaded.",
	])
	return w
