# Handoff: Pit of Hulst

Workspace: `C:\Users\hexicada\Projects\PitOfHulst`  
**Do not edit** `C:\Users\hexicada\Projects\Fate` while building this parody.

---

## What this is

| | |
|--|--|
| **Title** | Pit of Hulst: Heresy of the Live Service |
| **Engine** | Godot **4.6** |
| **Genre** | Short Destiny *Pit of Heresy* parody FPS |
| **Tone** | Affectionate roast + corporate cosmic horror |
| **Legal** | Fan parody — **not** affiliated with Bungie / Destiny / PlayStation. **No real-person likenesses.** |

### Remotes

- `origin` → `https://github.com/hexicada/PitParody.git`
- `upstream` → `https://github.com/hexicada/Fate.git` (cherry-picks only; **never** push parody here)

---

## Playable flow (current)

```text
[1] ENTRY YARD       overlook spawn → rim → pit; cliff towers; Earth + spire
        ↓ shaft (ledges, sealed warrens)
[2] FURTHER DROP     rim hole → vestibule
        ↓
[3] NECROPOLIS       large hive cavern, hive towers, wall of doors
                     Hive Comment Knights (sword ~65 dmg) + jump crates
                     correct door = lower yellow-lit entrance
        ↓
[4] ANTECHAMBER      short room past correct door
        ↓
[5] SHAREHOLDER HALL worms / roadmap fauna
        ↓
[6] BOSS ROOM        The Instrument (Zulmak-shaped OKR dunk fight)
```

**Boss:** Exposed → Shielded (kill **board_worm** adds → **F** pick up Voltaic OKR → dunk pillars) → repeat ×3.

**Level parts:** `res/levels/parts/entry_poh_homage.tscn`, `shaft_poh_homage.tscn`, `necropolis_poh_homage.tscn`

---

## Architecture

```text
res/
  actors/
    player/                 # controller, HUD, weapon viewmodel
    enemies/worm/           # cave + boss-add worms (not thralls)
    enemies/twitter_knight/ # Hive Comment Knights (necropolis)
    bosses/instrument/      # InstrumentBoss, pillars, OKRs
    fx/                     # DamageNumber
  assets/
    characters/player/      # world body GLB (CesiumMan for now)
    skyboxes/ shaders/
  levels/
    pit_of_hulst.tscn       # main dungeon
    parts/                  # modular homage chunks
docs/
  ref/                      # mood reference images
  hybrid_fp_arms_plan.md    # queued FP arms plan
tools/blender/              # experimental mesh scripts (not used in-game)
```

### Contracts

- **Player** group `player`: `take_damage`, `heal`, `give_okr` / `has_okr` / `consume_okr` / `clear_okr`, `notify_kill`
- **Boss** group `boss`; shield adds group **`board_worm`**
- **OKRs** group `voltaic_okr`
- **Damageable** targets implement `take_damage(amount, from)`
- **HUD** only via `PlayerHud` API

### Player presentation (hybrid, WIP)

| Layer | Location | Status |
|-------|----------|--------|
| Collision | Capsule on Player | Source of truth |
| World body | `WorldBodyRoot/GuardianBody` | CesiumMan GLB (Apache 2.0) — temporary |
| FP weapon | `ViewModelRoot/UpperFP/WeaponAnchor` | Placeholder gun |
| FP arms | `UpperFP` | **Not built** — see `docs/hybrid_fp_arms_plan.md` |
| 3rd person cam | — | **Not built** |

---

## Next work (priority)

1. **Weapon anchor retune** for current body + camera  
2. **Third-person camera** toggle  
3. Optional: replace body with KayKit Knight (CC0) — see `res/assets/characters/player/README.md`  
4. Hybrid FP arms (`docs/hybrid_fp_arms_plan.md`)  
5. Win screen / comedy polish / iron-out necropolis combat  

---

## Open in Godot

1. Godot 4.6 → this folder  
2. Main scene: `res://res/levels/pit_of_hulst.tscn`  
3. Or `open_project.bat`
