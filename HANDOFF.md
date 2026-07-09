# Handoff: Pit of Hulst

Workspace for this project: `C:\Users\hexicada\Projects\PitOfHulst`

**Do not edit** `C:\Users\hexicada\Projects\Fate` while building the parody.

---

## Projects

| Path | Role |
|------|------|
| `C:\Users\hexicada\Projects\Fate` | Serious Godot FPS — leave alone |
| `C:\Users\hexicada\Projects\PitOfHulst` | Joke dungeon fork — all work here |

---

## What this is

- Godot **4.6** FPS prototype forked from Fate (sibling folder, full git history).
- **Title:** **Pit of Hulst: Heresy of the Live Service**
- Destiny **Pit of Heresy** parody (Vault of Cars energy, more structured).
- Final boss: **Herman Hulst** (e.g. *Instrument of the Portfolio*).
- Tone: affectionate roast + corporate cosmic horror (live service as dark religion).
- Fan parody — not affiliated with Bungie / Destiny / PlayStation.

---

## Git state

- Branch: `master`
- History: Fate commits + fork commit: *Establish Pit of Hulst fork identity*
- `project.godot` name: `"Pit of Hulst"`
- README present with title + disclaimer
- Remote: **`upstream` only** → `https://github.com/hexicada/Fate.git`
- **No `origin`** yet
- Upstream tracking on `master` was unset (avoid accidental push to Fate)

---

## Inherited tech (from Fate)

- Main scene: `res/levels/test_arena.tscn` (moon floor, skybox, mantle blocks, player)
- FP controller: walk, sprint, jump/air jump, crouch, slide, mantle
- Player under `res/actors/player/`
- Autoload: `ControlSchemeManager`
- Combat bridge + weapon placeholder; no real combat/enemies yet

---

## Design lock (~1 week scope)

**Flow:**

```text
[1] ENTRY YARD  — expand current test zone; big hole in the middle
        ↓
[2] WORM CAVE   — short cave, worms; NO long jump puzzle
        ↓
[3] BOSS ROOM   — Herman Hulst
```

**In:** entry yard, central pit/shaft, worm cave (simple enemies/hazards), boss arena, comedy via text/signage.

**Out:** full jump puzzle, multi-chamber hive, second mid-boss, classes/seasons/netcode, heavy VO/cinematics.

**Boss:** 1 arena, 1–2 mechanics max, placeholder mesh OK.

---

## First build step

Blockout only:

1. Expand moon yard as entry
2. Dig big central hole / shaft
3. Cave tunnel stub
4. Boss room box
5. Playable path: spawn → fall → walk → boss door (zero enemies)
6. Prefer one level scene with three areas (evolve `test_arena` or new `pit_of_hulst.tscn`)

---

## Blockout status (done)

- Main scene: `res/levels/pit_of_hulst.tscn` (wired in `project.godot`)
- Legacy sandbox kept: `res/levels/test_arena.tscn`
- Path: entry yard → central shaft fall → worm cave walk → boss room (no enemies)
- Comedy via `Label3D` signage; Herman = red box on gold dais

## Next chat should

1. Confirm cwd/workspace is `PitOfHulst` (do **not** edit Fate)
2. Playtest blockout in editor; tweak scales/lighting if needed
3. Next content (pick one): worm hazards/simple enemies, boss 1–2 mechanics, or more signage polish
4. Optional: add `origin` remote when a PitOfHulst GitHub repo exists
