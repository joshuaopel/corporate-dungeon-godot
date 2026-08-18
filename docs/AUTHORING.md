# Corporate Dungeon Authoring Guide

The pipeline separates authored data from runtime behavior. A weapon, enemy, FX burst, or surface is a small `.tres` file. The shared actors in `scenes/` interpret those resources, so most new content needs no GDScript.

## Content Studio

Enable the **Cubicle Forge + Content Studio** plugin and open the **Content Studio** dock on the right side of the Godot editor. It provides four visual libraries: Weapons, Enemies, FX, and Surfaces.

- Select an asset to see a purpose-built preview and gameplay summary.
- Tune the common balance and presentation fields directly in the dock; quick-field edits save immediately.
- Use **+ New** to make a valid resource with sensible dependencies already assigned.
- Use **Duplicate** to create a variant without duplicating referenced FX or animation resources.
- Use **Inspector** for every advanced field, audio slot, SpriteFrames assignment, or material property.

Enemy previews play the `idle` animation. Weapon previews use the generated viewmodel silhouette and colors. FX previews animate their burst palette and density. Surface previews show the palette used by Cubicle Forge.

## Weapons

1. In Content Studio, choose **Weapons** and click **+ New**, or duplicate `content/_templates/new_weapon.tres` into `content/weapons/`.
2. Tune the common values visually, then use **Inspector** for optional audio and FX references.
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

3. Use Content Studio's **Enemies** category to create/duplicate the definition, or duplicate `content/_templates/new_enemy.tres` manually.
4. Assign the `SpriteFrames` and tune stats/feedback.
5. Instance `scenes/enemies/billboard_enemy.tscn` in a level and assign the definition.

`BillboardEnemy` always faces the active camera. It automatically changes animations while idle, chasing, attacking, and dying. The definition controls sprite tint and scale, so palette swaps and size variants can reuse one frame set. The three demo archetypes show this directly.

Keep feet at a consistent point in every frame and leave transparent breathing room around attack poses. For a crunchy 1990s look, import final sprites with nearest filtering, no compression artifacts, and a modest source resolution such as 128–256 px tall.

## FX

Duplicate `content/_templates/new_fx.tres`. `FxDefinition` controls the two-color palette, particle count, lifetime, speed range, particle size, transient light, and optional sound. Assign the result to any weapon muzzle/impact or enemy hit/death slot.

The shared burst actor is intentionally cheap and composable. Bespoke effects—persistent smoke, decals, beams, animated impact sprites—should be separate scenes referenced by a future `PackedScene` field, while ordinary hit feedback stays data-only.

## Cubicle Forge 2 level workflow

The plugin is enabled in `project.godot`. Open **Cubicle Forge** in the left dock. Structural geometry should use editable CSG brushes and be baked before gameplay. `ForgeBlock3D` remains available for a small number of independent modular props.

1. Open a 3D scene.
2. Click **Room Shell** for a hollow starting room, or **+ Add Box** to start a new CSG root.
3. Resize box brushes with Godot's built-in viewport handles. Transforms and the inherited CSG **Operation** remain editable in the Inspector.
4. Add **Cut Box**, **Cylinder Cut**, or **Door Cut** brushes to carve the current solid. Use **Intersect** when only overlapping volume should remain.
5. Use **Stair Run** for an editable eight-step generator. The steps remain ordinary additive brushes.
6. Multi-select primitives and click a surface to paint them. A cut brush's material controls newly exposed cut faces where Godot's CSG result supports it.
7. Select the CSG root or any child brush and click **Bake Selected CSG for Gameplay**.
8. Save the scene after baking. Use **Edit Source** later, make changes, then bake again. **Show Bake** previews the optimized result.

The bake writes an `ArrayMesh` and `ConcavePolygonShape3D` into `generated/forge_bakes/`, installs one static-body sibling, hides the CSG authoring tree, and links the two. At runtime the baked node is forced visible and the editable source tree queues itself for removal. This avoids a level made from hundreds of independent mesh/collision nodes and avoids live CSG recomputation during play.

The included demo already uses this split: `demo_floor_source.tscn` retains the 17 editable legacy blocks, while `demo_floor.tscn` contains only the generated static mesh and collision used by `main.tscn`. Run `tools/rebuild_demo_floor_bake.gd` after changing the source scene.

Godot positions CSG as a prototyping system and recommends baking final results into static geometry because live CSG carries significant CPU cost. Keep separate CSG roots for unrelated rooms/props rather than one world-sized boolean tree. Official references: [CSG tools](https://docs.godotengine.org/en/stable/tutorials/3d/csg_tools.html) and [CSGShape3D baking](https://docs.godotengine.org/en/stable/classes/class_csgshape3d.html).

### Migrating existing block levels

Multi-select existing `ForgeBlock3D` nodes and click **Blocks → CSG**. Cubicle Forge creates equivalent additive brushes using their transforms, sizes, and surfaces, then disables the old blocks without deleting them. Inspect the result, add cuts where useful, bake it, and only remove the disabled originals after the baked scene has been verified.

This is BSP-like in feel—solid brushes, boolean cuts, rapid greybox, and palette painting—but it stays Godot-native and does not compile a Doom BSP tree. Godot CSG has no built-in per-face UV editor, so production texture alignment still benefits from modular materials, triplanar shaders, or a final DCC pass for hero spaces.

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
godot --headless --path . --script res://tools/editor_pipeline_smoke_test.gd
```

The content validator catches missing materials, effects, core weapon values, enemy frames, and animation names. The gameplay smoke test catches broken scene references and runtime initialization failures. The editor-pipeline test compiles all plugin scripts and verifies boolean mesh/collision baking.
