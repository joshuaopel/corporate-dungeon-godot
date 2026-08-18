# Corporate Dungeon Authoring Guide

The pipeline separates authored data from runtime behavior. A weapon, enemy, FX burst, or surface is a small `.tres` file. The shared actors in `scenes/` interpret those resources, so most new content needs no GDScript.

## Weapons

1. Duplicate `content/_templates/new_weapon.tres` into `content/weapons/`.
2. Rename the file and edit it in the Inspector.
3. Select `Player/Head/Camera3D/WeaponController` in `scenes/player/player.tscn`.
4. Increase the Loadout array size and assign the resource.
5. Run `tools/validate_content.gd`.

Important tuning groups:

- **Ballistics:** trigger mode, fire rate, per-ray damage, pellet count, spread, range, and knockback. A shotgun is just a weapon with multiple pellets and wider spread.
- **Magazine:** capacity, starting reserve, and reload duration.
- **Feel:** vertical recoil, camera shake, viewmodel kick, color, accent, and one of three generated silhouettes.
- **Presentation:** optional fire/reload sounds plus muzzle and impact `FxDefinition` resources.

The runtime controller is hitscan-first. That suits the immediate response of classic shooters and keeps authoring cheap. A projectile/plasma branch can be added later without changing existing resource files by extending `WeaponDefinition` with a fire-type enum and optional `PackedScene`.

## Billboard enemies

1. Prepare transparent frames. PNG/WebP is ideal for finished pixel art; the demo deliberately uses editable SVG placeholders.
2. Create a `SpriteFrames` resource with exactly these animation names:

   - `idle` — looping
   - `move` — looping
   - `attack` — normally non-looping
   - `death` — non-looping

3. Duplicate `content/_templates/new_enemy.tres` into `content/enemies/`.
4. Assign the `SpriteFrames` and tune stats/feedback.
5. Instance `scenes/enemies/billboard_enemy.tscn` in a level and assign the definition.

`BillboardEnemy` always faces the active camera. It automatically changes animations while idle, chasing, attacking, and dying. The definition controls sprite tint and scale, so palette swaps and size variants can reuse one frame set. The three demo archetypes show this directly.

Keep feet at a consistent point in every frame and leave transparent breathing room around attack poses. For a crunchy 1990s look, import final sprites with nearest filtering, no compression artifacts, and a modest source resolution such as 128–256 px tall.

## FX

Duplicate `content/_templates/new_fx.tres`. `FxDefinition` controls the two-color palette, particle count, lifetime, speed range, particle size, transient light, and optional sound. Assign the result to any weapon muzzle/impact or enemy hit/death slot.

The shared burst actor is intentionally cheap and composable. Bespoke effects—persistent smoke, decals, beams, animated impact sprites—should be separate scenes referenced by a future `PackedScene` field, while ordinary hit feedback stays data-only.

## Cubicle Forge level workflow

The plugin is enabled in `project.godot`. In the Godot editor, open **Cubicle Forge** in the left dock.

1. Open a 3D scene.
2. Click **+ 16m TEST ROOM** for a sealed starter room or **+ 2m BLOCK** for a single brush-like solid.
3. Change a block's **Size** in the Inspector. Sizes snap to 0.25 m. Keep Transform Scale at `(1,1,1)` so collision and visuals stay identical.
4. Multi-select Forge blocks and click a surface in the dock to paint all of them.
5. Duplicate blocks with Godot's normal scene tools to build corridors, stairs, pillars, cover, trims, and arena boundaries.
6. Save the result as its own scene and instance it into the game scene.

This is a BSP-like workflow in feel—solid brushes, grid snapping, rapid greybox, palette painting—but it stays Godot-native. Each block generates its own mesh and collision in editor and at runtime. It does not compile a binary Doom BSP tree. That keeps iteration immediate and scenes merge-friendly.

Painting is currently per block. Split a wall into adjacent blocks when regions need different surfaces; that also makes trim and secret-panel logic easier later. Surface resources carry a material, palette swatch, footstep family, and optional contact-damage metadata, so sound and hazards have a clean expansion point.

## Modern flair without losing readability

The demo uses modern rendering as punctuation rather than visual noise:

- emissive teal/magenta navigation lines;
- restrained fog and colored local lights;
- physical material contrast between carpet, concrete, metal, and brass;
- recoil, hit stop-like stagger, damage flash, kill confirmation, and transient FX lights;
- a high-information HUD styled as an internal corporate security terminal.

For production levels, keep the combat floor readable, use emissive colors to communicate routes/factions, and reserve the brightest values for targets, hazards, pickups, and exits.

## Adding sound

All weapon, enemy, and FX resources already expose audio slots. Drag imported `.wav` or `.ogg` streams into them; no code changes are required. Prefer short, dry weapon transients and add environmental reverb through Godot audio buses per level zone.

## Validation contract

Run both checks before committing content:

```powershell
godot --headless --path . --script res://tools/validate_content.gd
godot --headless --path . --script res://tools/smoke_test.gd
```

The validator catches missing materials, effects, core weapon values, enemy frames, and animation names. The smoke test catches broken scene references and runtime initialization failures.

