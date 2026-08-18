# Corporate Dungeon: Hostile Takeover

![Corporate Dungeon](assets/brand/boot_mark.svg)

A Godot 4 boomer-shooter vertical slice and content pipeline built around a simple rule: designers make resources; shared runtime code supplies the behavior.

The included demo is a neon-lit corporate dungeon crawl with a fast FPS controller, three weapons, three enemy archetypes, animated billboard art, responsive combat FX, an in-world blockout kit, and a corporate terminal-style HUD.

## Run it

Open `project.godot` in Godot 4.3 or newer and press **F6/F5**. The project has been imported and smoke-tested with Godot 4.7.

Controls:

| Input | Action |
|---|---|
| WASD | Move |
| Mouse | Look |
| Left mouse | Fire |
| R | Reload |
| 1 / 2 / 3 or wheel | Switch weapons |
| Shift | Sprint |
| Space | Jump |
| Escape | Release/capture mouse |

## What is included

- **Resource-driven weapons:** semi/full-auto triggers, pellets, spread, magazine/reserve ammo, reload, recoil, knockback, generated viewmodels, sound hooks, and FX hooks.
- **Billboard enemies:** `AnimatedSprite3D` actors with mandatory `idle`, `move`, `attack`, and `death` animations; shared AI/damage behavior; per-resource health, speed, range, windup, tint, scale, score, sounds, and FX.
- **Reusable FX:** one small runtime actor creates particle bursts, emissive quads, a fading light, and optional spatial sound from an `FxDefinition`.
- **Content Studio:** a visual editor dock with animated previews, quick tuning, creation, duplication, and full-Inspector handoff for weapons, enemies, FX, and surfaces.
- **Cubicle Forge 2:** additive, subtractive, and intersection CSG brushes; box/cylinder cuts; hollow rooms; door cuts; stair generation; surface painting; legacy-block conversion; and a bake-to-static workflow.
- **Runtime-ready level bakes:** editable CSG source is converted into one static mesh node plus concave collision resources, then removed from the runtime tree.
- **Modern presentation:** emissive architectural trim, colored dynamic lights, fog, screen feedback, animated reticle confirmations, view kick, head bob, and a diegetic corporate-security HUD.
- **Validation:** content-schema validation and full-scene smoke tests runnable through Godot headless mode.

## Fast authoring paths

Duplicate one of the resources in `content/_templates`:

- `new_weapon.tres` → `content/weapons/`
- `new_enemy.tres` → `content/enemies/`
- `new_fx.tres` → `content/fx/`

Then edit the duplicate in Godot's Inspector. Weapon and enemy variations do not need new scripts. See [Authoring Guide](docs/AUTHORING.md) for the complete workflow and animation contract.

## Project map

```text
addons/cubicle_forge/       Content Studio and CSG level-authoring docks
assets/sprites/enemies/     billboard animation frames
content/                    designer-authored .tres definitions
scenes/                     reusable actors and playable demo
scripts/resources/          data schemas
scripts/player|enemies|fx/  shared runtime behavior
scripts/world/              procedural ForgeBlock geometry/collision
tools/                      content validation and scene smoke tests
```

## Validation

From this directory, using your Godot executable:

```powershell
godot --headless --path . --script res://tools/validate_content.gd
godot --headless --path . --script res://tools/smoke_test.gd
godot --headless --path . --script res://tools/editor_pipeline_smoke_test.gd
```

All three commands currently pass. The editor-pipeline check compiles the plugin and verifies that boolean CSG produces a static mesh and concave collision.
