# Pit of Hulst: Heresy of the Live Service

A short, silly **Destiny dungeon parody** built as a fork of the [Fate](https://github.com/hexicada/Fate) Godot FPS prototype.

> Descend the sacred org chart. Carry the OKRs. Survive the portfolio.  
> Face the heresy that ships forever.

## What this is

- **Fan parody / joke game** — not affiliated with Bungie, Destiny, PlayStation, or any real executive, studio, or corporation.
- **Sibling project to Fate** — Fate remains the more serious title; this repo is where the live-service heresy lives.
- **Engine:** Godot 4.6
- **Boss:** **The Instrument** — an abstract *thoughtform of the portfolio* (not a depiction of any real person).

## Relationship to Fate

| Repo | Role |
|------|------|
| `Fate` | Serious game development |
| `PitOfHulst` / [PitParody](https://github.com/hexicada/PitParody) | Parody dungeon spoof |

Optional remote: `upstream` → `https://github.com/hexicada/Fate.git` for cherry-picking controller/engine fixes. Do **not** merge this project back into Fate.

## Open in Godot

1. Open Godot 4.6  
2. Import / open this folder  
3. Main scene: `res/levels/pit_of_hulst.tscn`  

Or use `open_project.bat` if present.

## Status

**Playable day-one loop + release-safer boss:**

1. **Entry yard** — moon surface, central pit, comedy signage  
2. **Worm cave** — Board Thrall / roadmap fauna (shootable)  
3. **Boss room** — **The Instrument** (faceless thoughtform)

**Boss (Zulmak-shaped):**
- 3 DPS phases  
- White mist shield + **Immune!**  
- Kill thrall → **F** pick up **Voltaic OKR** (one at a time) → dunk on **Pillars of Engagement**  
- Shield drops → repeat  

Path: spawn → fall the shaft → cave → ritual DPS the thoughtform.

## Project layout (short)

| Path | Role |
|------|------|
| `res/actors/player/` | Controller + `player_hud.tscn` + weapon |
| `res/actors/bosses/instrument/` | Boss, pillars, OKR motes |
| `res/actors/enemies/worm/` | Cave thrall / boss adds |
| `res/levels/pit_of_hulst.tscn` | Main dungeon |
| `HANDOFF.md` | Design lock + maintainability notes for agents/humans |
