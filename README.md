# Pit of Hulst: Heresy of the Live Service

A short, silly **Destiny dungeon parody** built as a fork of the [Fate](https://github.com/hexicada/Fate) Godot FPS prototype.

> Descend the sacred org chart. Carry the OKRs. Survive the portfolio.  
> Face the heresy that ships forever.

## What this is

- **Fan parody / joke game** — not affiliated with Bungie, Destiny, PlayStation, or anyone who has ever said “synergy” unironically.
- **Sibling project to Fate** — Fate remains the more serious title; this repo is where the live-service heresy lives.
- **Engine:** Godot 4.6
- **Starting point:** Fate’s first-person movement sandbox (walk, sprint, jump, crouch, slide, mantle) + moon test arena.

## Relationship to Fate

| Repo | Role |
|------|------|
| `Fate` | Serious game development |
| `PitOfHulst` (this) | Parody dungeon spoof |

Optional remote: `upstream` → `https://github.com/hexicada/Fate.git` for cherry-picking controller/engine fixes. Do **not** merge this project back into Fate.

## Open in Godot

1. Open Godot 4.6
2. Import / open this folder
3. Main scene: `res/levels/pit_of_hulst.tscn` (legacy sandbox: `test_arena.tscn`)

Or use `open_project.bat` if present.

## Status

**Blockout playable.** One level scene with three areas:

1. **Entry yard** — expanded moon surface, central pit, comedy signage, mantle blocks  
2. **Worm cave** — short tunnel stub from shaft landing (no jump puzzle, zero enemies)  
3. **Boss room** — Herman Hulst placeholder dais/mesh  

Path: spawn → fall the shaft → walk the cave → boss door. Encounters/mechanics TBD.
