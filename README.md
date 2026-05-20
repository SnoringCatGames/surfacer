# Surfacer 2.0

_This is still under development and not ready for use._

This project aims to port the original [Surfacer](https://github.com/SnoringCatGames/surfacer) framework to GDExtension and Godot 4.0.

## Building

This repo expects a **workspace-sibling layout** — see [bootstrapper](https://github.com/SnoringCatGames/bootstrapper) for the umbrella project and `scripts/bootstrap-workspace.ps1`, which clones all required sibling repos (snore_core, godot-cpp, googletest, godot) into the workspace root in one go. Once siblings are in place, build with `scons sc_dev=yes sc_tests=yes` from this directory.
