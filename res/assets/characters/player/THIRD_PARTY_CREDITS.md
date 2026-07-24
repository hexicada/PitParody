# Third-party character assets

## CesiumMan (`cesium_man.glb`)

- Source: [Khronos glTF-Sample-Models — CesiumMan](https://github.com/KhronosGroup/glTF-Sample-Models/tree/master/2.0/CesiumMan)
- Original: Cesium  
- License: **Apache License 2.0**  
- Used as a temporary **game-ready humanoid base** (looks like a normal skinned character, not a cube melt).

If you keep this in a public build, retain this credit file.

## Recommended free upgrades (CC0 — replace when you want)

These look **orders of magnitude** better than anything a script can invent from primitives:

| Pack | Style | License | Notes |
|------|--------|---------|--------|
| [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) | Knight, rogue, mage… | **CC0** | Free download (“name your price” → $0). Knight = best Destiny-adjacent armor silhouette. |
| [Quaternius RPG Characters](https://quaternius.com/packs/rpgcharacters.html) | Fantasy heroes | **CC0** | Rigged + animated glTF |
| [Quaternius Ultimate Modular Characters](https://quaternius.com/) | Mix-and-match | **CC0** | Huge free library |

### How to swap in KayKit Knight (recommended)

1. Download **Free 2.0** from the KayKit Adventurers itch page ($0 is fine).  
2. Unzip; find the knight `.glb` / `.gltf` (path varies by pack version).  
3. Copy to:  
   `res/assets/characters/player/guardian_body.glb`  
   (overwrite)  
4. Reopen Godot / reimport.  
5. Scale in `player.tscn` under `WorldBodyRoot/GuardianBody` if needed (often 1.0–1.5).  
6. Update this credits file to Kay Lousberg / CC0.
