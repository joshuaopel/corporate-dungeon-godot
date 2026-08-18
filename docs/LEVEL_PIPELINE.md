# Cubicle Forge 2: Brush and Bake Pipeline

## Authoring model

`ForgeCSGRoot3D` is an editable boolean group. `ForgeBrush3D` is a resizable box brush using Godot's native CSG viewport handles. The dock can also add native cylinder primitives.

Operations are evaluated in scene-tree order:

1. **Union** adds solid volume.
2. **Subtraction** cuts its volume out of the accumulated result.
3. **Intersection** keeps only shared volume.

Every root needs an additive primitive before subtraction or intersection can produce useful geometry. Keep roots local: one room, architectural assembly, staircase, or prop per root is easier to edit and faster to rebuild than one boolean tree for an entire map.

## Bake output

**Bake Selected CSG for Gameplay** waits for Godot's deferred CSG update, then calls `bake_static_mesh()` and `bake_collision_shape()`. It saves both resources under `res://generated/forge_bakes/` and creates this runtime arrangement:

```text
Level
├── RoomCSG                 hidden editable source; removed at runtime
│   ├── RoomVolume          union
│   ├── RoomInteriorCut     subtraction
│   └── DoorCut             subtraction
└── RoomCSG__BAKED          static body used by the game
    ├── Mesh                one ArrayMesh, one surface per material
    └── Collision           one concave static collision shape
```

The source is kept in the scene so cuts can be revised. On runtime startup, `ForgeCSGRoot3D` makes its linked bake visible and removes itself. Re-baking overwrites the generated resources and updates the existing static node.

The demo uses the same production split across two scenes: edit `scenes/levels/demo_floor_source.tscn`, run `tools/rebuild_demo_floor_bake.gd`, and play the optimized `scenes/levels/demo_floor.tscn`.

## Performance rules

- Bake structural CSG before testing combat performance.
- Split unrelated architecture into separate roots and bakes.
- Use boolean operations only where cuts are actually needed.
- Use concave collision only for static level geometry.
- Use simple collision for doors, lifts, enemies, pickups, and other moving objects.
- Reuse a small surface palette; each distinct material can remain a separate mesh surface/draw call after baking.
- Prefer occluders, portals/room culling, baked lighting, and MultiMesh props as the level grows. Static baking solves node and live-CSG overhead, but it is not a complete visibility system.

## Texture workflow

Surface painting is brush-wide. For old-school texture alignment with modern materials:

- use world-aligned or triplanar shaders during greybox;
- split trim/detail into its own thin additive brushes;
- keep texel density encoded in shared materials;
- reserve bespoke unwrapped meshes for hero landmarks;
- use decals for signage, grime, blood, and corporate messaging.

Godot's CSG system does not provide a full per-face UV editor. The bake pipeline is designed to make blockout and combat iteration fast, while leaving a clean point to replace selected areas with authored meshes later.
