# Pit of Hulst: Heresy of the Live Service

A short, silly **Destiny dungeon parody** built as a fork of the [Fate](https://github.com/hexicada/Fate) Godot FPS prototype.

> Descend the sacred org chart. Carry the OKRs. Survive the portfolio.  
> Face the heresy that ships forever.

## What this is

- **Fan parody / joke game** — not affiliated with Bungie, Destiny, PlayStation, or any real executive.
- **Sibling to Fate** — Fate stays serious; this repo is the live-service heresy.
- **Engine:** Godot 4.6
- **Boss:** **The Instrument** — abstract thoughtform of the portfolio.

## Relationship to Fate

| Repo | Role |
|------|------|
| `Fate` | Serious game development |
| `PitOfHulst` / [PitParody](https://github.com/hexicada/PitParody) | Parody dungeon |

Optional: `upstream` → Fate for cherry-picks only. Never push parody into Fate.

## Open in Godot

1. Godot 4.6 → open this folder  
2. Main scene: `res/levels/pit_of_hulst.tscn`  
3. Or `open_project.bat`

## Playable path

1. **Entry yard** — overlook, rim, pit, cliff “org chart”  
2. **Shaft** → further drop → vestibule  
3. **Necropolis** — hive cavern, door wall, Hive Comment Knights  
4. **Shareholder Hall** — worms  
5. **Boss** — The Instrument (shield → kill worms → dunk OKRs)

**Boss loop:** DPS → shield → kill worms → **F** pick up Voltaic OKR → dunk pillars → shield drops → repeat.

## Layout (short)

| Path | Role |
|------|------|
| `res/actors/player/` | Controller, HUD, weapon |
| `res/actors/enemies/` | Worms, Hive Comment Knights |
| `res/actors/bosses/instrument/` | Boss, pillars, OKRs |
| `res/levels/pit_of_hulst.tscn` | Main dungeon |
| `res/levels/parts/` | Modular entry / shaft / necropolis |
| `HANDOFF.md` | Agent/human design lock |

## Credits / third-party

Player world body may use **CesiumMan** (Apache 2.0) — see `res/assets/characters/player/THIRD_PARTY_CREDITS.md`.
