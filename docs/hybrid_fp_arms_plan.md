# Hybrid FP Arms — Implementation Plan (queued)

**Status:** Queued — do **after** weapon-anchor retune + third-person camera.  
**Owner:** next agent pass when unblocked.

## Decision

Use a **separate** low-poly FP arms mesh under `ViewModelRoot/UpperFP`, not a crop of the world body.

- World body: `WorldBodyRoot` (full body, head hidden in FP, shadows)
- FP arms: camera-relative, sibling to `WeaponAnchor` under `UpperFP`
- FP legs: still later (`LowerFP`)

## Hierarchy target

```text
Camera3D / ViewModelRoot
├── UpperFP
│   ├── ArmsRig              ← NEW (fp_arms.tscn)
│   │   ├── mesh / skeleton
│   │   ├── RightHandGrip    (Marker3D)
│   │   └── AnimationPlayer
│   └── WeaponAnchor         ← KEEP sibling (existing gun pose code)
│       └── weapon
└── LowerFP                  ← empty for now
```

## PR sequence

1. **Visibility foundation** — layers: world=1, viewmodel=2; hide world arms in FP if double silhouette  
2. **Art** — `tools/blender/build_tr2_style_fp_arms.py` → `res/assets/characters/player/fp_arms.glb`  
3. **Wire** — `fp_arms.tscn` under `UpperFP`; tune hands to hip gun pose  
4. **Poses** — drive READY / LOWERED / SLIDE from `CombatBridge`  
5. **Optional** — split WeaponAnchor hip vs true ADS; fire punch anim  

## Paths

| Path | Role |
|------|------|
| `tools/blender/build_tr2_style_fp_arms.py` | Builder (TBD) |
| `res/assets/characters/player/fp_arms.glb` | Export (TBD) |
| `res/actors/player/fp_arms.tscn` | Wrapper (TBD) |

## Risks

- Double arms if world body upper limbs stay visible in FP  
- Pose fight if weapon is parented under hand bone too early — keep `WeaponAnchor` sibling for v0  
- ADS currently overloaded as “weapon lowered” in controller — clean up when arms land  

Full research notes live in the hybrid-arms plan agent transcript; this file is the handoff stub.
