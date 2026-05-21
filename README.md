# Waterways

Waterways is a Godot add-on for authoring river meshes and baking flow, foam, distance, pressure, and water-system maps from editable river curves.

This workspace currently contains the in-progress Godot 4.6+ port of the add-on. The active add-on lives in `addons/waterways`. The Godot 3 source snapshot is kept under `legacy/godot-3/addons/waterways` as reference material only.

For the minimal `0.2.2` package, copy `addons/waterways` into a Godot 4.6+ project and enable the plugin. Source-repo QA fixtures such as `scenes/validation/`, `spec-driven/`, `audit/`, and generated `waterways_bakes/` resources are intentionally not part of the minimal add-on package.

## Godot 4 Port Docs

- [Godot 4 User Guide](docs/godot-4-user-guide.md)
- [Godot 3 Migration Notes](docs/godot-3-migration.md)
- [Godot 4 Import Notes](docs/godot-4-imports.md)
- [Godot 4 Runtime And Buoyancy Notes](docs/godot-4-runtime-buoyancy.md)
- [Godot 4 Release Checklist](docs/godot-4-release-checklist.md)

## Credits And Acknowledgements

Waterways was originally created by Kasper Arnklit Frandsen and released under the MIT License. This Godot 4 port keeps the original MIT licensing and attribution.

Arnklit Frandsen thanked his patrons Marcus Richter, Dmitriy Keane, spacechace0, Johannes Wuesnch, Winston, and Little Mouse Games for their support, and credited several people in the Godot community for helping shape the project:

- Winston contributed code to the project, including the axis constraint system.
- Zylann helped with terrain-related questions, and his plugin code served as a recurring reference for editor-plugin techniques.
- HungryProton helped with the custom gizmos used for river editing tools.
- Rodzilla helped work out how to generate the flow and foam textures; much of the map-rendering approach was directly inspired by Material Maker.

The flowmap shader implementation was heavily inspired by Catlike Coding's article on flow texture distortion: [Texture Distortion](https://catlikecoding.com/unity/tutorials/flow/texture-distortion/).

## Current Validation Status

The Godot 4 port has passed targeted human-assisted validation for editor River workflows, shader/material checks, and River/WaterSystem bake checks in this workspace. Runtime and Buoyant behavior is covered by automated probes and validation scenes; visible runtime confirmation should still be recorded before final packaging.

Agent-local checks are limited to static scans and headless Godot editor-load/parser probes. Headless checks do not prove visible editor, shader, bake, or runtime behavior.

In the source workspace, use Godot 4.6+ to open `project.godot`, enable the Waterways plugin, and run the validation scenes under `scenes/validation/` when preparing a release or changing behavior.

After regenerating River or WaterSystem maps in a saved scene, Waterways writes the generated bake data to scene-owned external resources under `res://waterways_bakes/<scene-derived-folder>/`. Save the scene after baking so F6, exports, and future editor loads use those external `.res` references. Unsaved scenes keep temporary in-memory bake data and ask you to save, then rebake.

## 0.2.2 Release Candidate Notes

Version `0.2.2` is a Godot 4 parity-focused release candidate for the original Godot 3.x Waterways add-on. It is not a major new-feature release.

Large-scene bake performance budgets are deferred for this release candidate. For ordinary authoring, use River `baking_resolution` 0 to 2 and WaterSystem `system_bake_resolution` 0 to 2; higher settings are stress/final-check settings and may visibly stall the editor. There is no user-facing bake cancel button yet, but guarded bake failures clean up temporary renderer nodes and close the River progress window.
