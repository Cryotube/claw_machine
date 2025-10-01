# Placeholder Asset Manifest

These assets provide free, stylized stand-ins that satisfy the MVP content shapes described in the PRD (`docs/game-prd/requirements.md`) and UX spec (`docs/front-end-spec.md`). All meshes are authored as Godot scenes using primitive geometry and palette materials, so they can ship with the project under a CC0-equivalent status until bespoke art or licensed packs replace them.

## Characters
| Asset | Path | Coverage |
|-------|------|----------|
| Penguin Chef | `res://resources/meshes/characters/PenguinPlaceholder.tscn` | Player avatar for cozy penguin proprietor fantasy (`docs/game-prd/goals-and-background-context.md:4`).
| Cat Personas (Black, Grey, Orange, Siamese, Tabby, White) | `res://resources/meshes/characters/CatPlaceholder_*.tscn` | Six feline customer variants needed for MVP content minimums (`docs/game-prd/requirements.md:37`). Material swaps allow quick mood tweaks.

## Seafood Cabinet Inventory
| Asset | Path | Notes |
|-------|------|-------|
| Salmon Fillet | `res://resources/meshes/seafood/Seafood_SalmonFillet.tscn` | Includes contrasting skin strip for readability (FR2).
| Tuna Steak | `res://resources/meshes/seafood/Seafood_TunaSteak.tscn` | Cylindrical cut silhouette.
| Shrimp | `res://resources/meshes/seafood/Seafood_Shrimp.tscn` | Horseshoe pose to echo claw-grab silhouettes.
| Crab | `res://resources/meshes/seafood/Seafood_Crab.tscn` | Body plus leg clusters for instant recognition.
| Lobster | `res://resources/meshes/seafood/Seafood_Lobster.tscn` | Elongated capsule with mirrored claws.
| Scallop | `res://resources/meshes/seafood/Seafood_Scallop.tscn` | Radial top for highlight shader tests.
| Squid | `res://resources/meshes/seafood/Seafood_Squid.tscn` | Cone mantle + tentacle block for silhouette.
| Octopus | `res://resources/meshes/seafood/Seafood_Octopus.tscn` | Uses multimesh tentacles to stress pooling.
| Clam | `res://resources/meshes/seafood/Seafood_Clam.tscn` | Dual shells for open/close animation hooks.
| Sea Urchin | `res://resources/meshes/seafood/Seafood_SeaUrchin.tscn` | Spines via multimesh to exercise physics grab edge cases.

## Claw & Restaurant Props
| Asset | Path | Purpose |
|-------|------|---------|
| Claw Rig Assembly | `res://resources/meshes/props/ClawRigAssembly.tscn` | Complete claw device with fingers, cable, glow strip for FR3/FR4 debug scenes.
| Freezer Cabinet | `res://resources/meshes/environment/FreezerCabinet.tscn` | Structural volume for seafood placement and highlight testing.
| Counter Assembly | `res://resources/meshes/props/CounterAssembly.tscn` | Service area for patron interactions (FR1/FR4).
| Kitchen Prep Table | `res://resources/meshes/props/KitchenPrepTable.tscn` | Back-of-house dressing for hub scenes.
| Menu Board | `res://resources/meshes/props/MenuBoardPlaceholder.tscn` | Placeholder signage for tutorial prompts.
| Stool | `res://resources/meshes/props/StoolPlaceholder.tscn` | Seating for ambience.

## Biomes & Scene Dressing
| Biome | Path | Highlights |
|-------|------|------------|
| Ice Shelf | `res://resources/meshes/environment/Biome_IceShelf.tscn` | Angular ice columns + snow floor to sell frozen cabinet fantasy.
| Kelp Cave | `res://resources/meshes/environment/Biome_KelpCave.tscn` | Cylindrical kelp stands for mid-session clutter.
| Volcanic Vent | `res://resources/meshes/environment/Biome_VolcanicVent.tscn` | Hot/cold contrast for late-wave tension.

## VFX Placeholders
| Asset | Path | Usage |
|-------|------|-------|
| Spark Burst | `res://resources/vfx/VFX_SparkBurst.tscn` | Claw impact feedback in success/fail loops.
| Freezer Mist | `res://resources/vfx/VFX_FreezerMist.tscn` | Ambient cabinet atmosphere for NFR3 audio-visual clarity tests.

## Palette Materials
All recolorable hues live under `res://resources/materials/palette/` with names aligned to UX palette values (`docs/front-end-spec.md:330-339`). Reuse them to guarantee stylistic cohesion and mobile-ready shader import defaults.

## Integration Notes
- Scenes are composed in meters and centered near the origin so they can drop into `SessionRoot.tscn` without extra transforms.
- Primitive geometry keeps draw calls and vertex counts low for mobile constraints (`docs/game-prd/requirements.md:15-23`).
- Multimesh usage on tentacles, kelp, and ice pillars exercises pooling/performance systems detailed in `docs/architecture/node-architecture-details.md`.
- Replace any placeholder by swapping the scene or material reference; autoloads and object pools can keep the same resource paths to ease iteration.

