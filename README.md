# surfacer

> **Status: rewrite in progress.** This branch (`master`) is intentionally
> minimal during active development; the real code lives on `dev`.

A 2D platformer character / pathfinding framework for Godot
(client-side prediction, surface-aware movement, pathfinding across
platforms). Originally written for Godot 3 in GDScript; being rewritten
for Godot 4 in C++ as a GDExtension, with a planned dynamic-pathfinding
mode that doesn't require pre-parsing a static platform graph.

## Branches

| Branch | Content |
|---|---|
| `master` (this) | Minimal during the rewrite — just this README. |
| `dev` | Active Godot 4 + C++/GDExtension development. |
| `godot3` | Preserved Godot 3 GDScript version (pre-rewrite). |
| `asset-lib-v0.7.0` | Pinned reference for the Godot Asset Library entry. |

## Where to go next

- Current work in progress: `git checkout dev`
- Stable Godot 3 version: `git checkout godot3`
- Umbrella project: [bootstrapper](https://github.com/SnoringCatGames/bootstrapper)
