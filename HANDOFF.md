# Handoff: Pit of Hulst

Workspace: `C:\Users\hexicada\Projects\PitOfHulst`  
**Do not edit** `C:\Users\hexicada\Projects\Fate` while building this parody.

---

## What this is

| | |
|--|--|
| **Title** | Pit of Hulst: Heresy of the Live Service |
| **Engine** | Godot **4.6** |
| **Genre** | Short Destiny *Pit of Heresy* parody FPS (Vault of Cars energy, more structured) |
| **Tone** | Affectionate roast + corporate cosmic horror (live service as dark religion) |
| **Legal** | Fan parody — **not** affiliated with Bungie / Destiny / PlayStation. **No real-person likenesses.** |

### Projects

| Path | Role |
|------|------|
| `Fate` | Serious Godot FPS — leave alone |
| `PitOfHulst` (this) | Joke dungeon — all work here |
| GitHub `hexicada/PitParody` | `origin` remote |

### Remotes

- `origin` → `https://github.com/hexicada/PitParody.git`
- `upstream` → `https://github.com/hexicada/Fate.git` (cherry-picks only; **never** push parody here)

---

## Playable flow (current)

```text
[1] ENTRY YARD     overlook spawn → broken bridge / rim walk
                   wall-of-doors gag, cliff "org chart" towers, central pit
        ↓ fall shaft (cross ledges + side platforms, sealed warrens)
[2] WORM CAVE      Board Thrall / roadmap fauna (no jump puzzle)
        ↓
[3] BOSS ROOM      The Instrument (thoughtform) — Zulmak-shaped fight
```

**PoH homage notes (entry/pit):** modular parts under `res/levels/parts/`  
(`entry_poh_homage.tscn`, `shaft_poh_homage.tscn`) — cliff towers, rim approach, door wall, side ledges.

**Boss (The Instrument):**

1. **Exposed** — shoot boss (damage numbers)  
2. **Shielded** — white mist, **Immune!** if shot  
3. Kill **Board Thrall** → **Voltaic OKR** drops  
4. **F** pick up OKR (one at a time) → walk into **Pillar of Engagement** to dunk  
5. All pillars charged → **SHIELD DOWN** → next phase (×3 total DPS windows)

---

## Architecture map (keep this shape)

```text
res/
  actors/
    player/          # controller, HUD scene, weapon viewmodel
    enemies/worm/    # thrall (also used as boss adds)
    bosses/instrument/  # InstrumentBoss, pillars, OKRs
    fx/              # DamageNumber floating text
  levels/
    pit_of_hulst.tscn   # main dungeon (single scene for now)
    test_arena.tscn     # legacy sandbox
  assets/            # textures, sky
control_scheme_manager.gd   # autoload input schemes
```

### Important scripts

| Script | Responsibility |
|--------|----------------|
| `player_controller.gd` | Locomotion + combat input + health/heal + OKR carry |
| `player_hud.gd` / `.tscn` | **All** player chrome (health bar, death, crosshair, status) |
| `instrument_boss.gd` | Boss phases, shield, thrall spawn, OKR drops, pillars |
| `voltaic_okr.gd` | Mote pickup (**F** / `interact`) |
| `engagement_pillar.gd` | Dunk zone |
| `worm.gd` | Thrall AI, contact damage, `died` signal |
| `damage_number.gd` | World-space floating text |

### Contracts (do not break casually)

- **Player** is in group `player`; exposes `take_damage`, `heal`, `give_okr` / `has_okr` / `consume_okr` / `clear_okr`, `notify_kill`.
- **Boss** is in group `boss`; thrall adds use group `board_thrall`.
- **OKRs** are in group `voltaic_okr`.
- **Damageable** combat targets implement `take_damage(amount, from)`.
- **HUD**: controller talks only through `PlayerHud` API — do not re-scatter UI nodes under Player.

---

## Maintainability standards (project rules)

1. **Fate isolation** — no edits under `Projects/Fate` for this game.  
2. **No real likenesses** — abstract / parody only (The Instrument, not named execs).  
3. **Single main scene is OK for now** — `pit_of_hulst.tscn` is large; split later if editing becomes painful (entry / shaft / cave / boss instances).  
4. **Prefer small scenes for entities** — boss parts already split (`instrument_boss`, `voltaic_okr`, `engagement_pillar`, `worm`, `player_hud`).  
5. **Magic numbers** live as `@export` on the owning script when tunable (heal CD, phase HP, thrall counts).  
6. **Input** via named actions (`ult`, `interact`, move/*, etc.) + `ControlSchemeManager`; fallbacks in `player_controller._ensure_default_input_actions`.  
7. **Docs** — update this file when flow, boss rules, or remotes change. README is the public blurb.  
8. **Commits** — ship playable slices; don’t leave multi-day WIP unpushed to `origin`.  
9. **Ignore** noisy `*.import` line-ending churn unless import settings actually changed.

### Known debt (acceptable for short parody scope)

| Item | Notes |
|------|--------|
| `player_controller.gd` ~600+ lines | Locomotion + combat + heal + OKR in one file; split only if it hurts |
| `pit_of_hulst.tscn` ~780 lines | Monolithic level; CSG blockout is intentional |
| `docs/hybrid_player_body_spec.md` | Fate-era; not active for this parody |
| No automated tests | Manual playtest is the bar |
| Soft thrall respawn during shield | Prevents soft-lock if OKRs/thrall depleted before pillars filled |

---

## Next work (when un-parking)

Pick one:

1. Iron-out: pillar positions, thrall spawn floors, shield readability  
2. Win / dungeon-complete screen after Instrument dies  
3. Comedy pass (signs, thrall names, death lines)  
4. Optional Chamber-lite plate before boss door  
5. Split level into instanced area scenes if CSG edits thrash git  

---

## Open in Godot

1. Godot 4.6 → open this folder  
2. Main scene: `res://res/levels/pit_of_hulst.tscn`  
3. Or `open_project.bat`
