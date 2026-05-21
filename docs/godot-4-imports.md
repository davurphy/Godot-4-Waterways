# Godot 4 Import Notes

These notes document the current Godot 4 import expectations for Waterways textures and scenes.

## Data Texture Rules

Flow, foam, distance, pressure, and WaterSystem maps are numeric data. Treat them differently from ordinary color textures.

Recommended import settings for user-supplied data maps:

- compression: lossless or uncompressed
- normal map: disabled
- mipmaps: disabled unless the exact shader/runtime path has been validated
- VRAM/block compression: disabled
- lossy formats such as JPEG or lossy WebP: unsupported for data maps
- neutral flow: preserve `(0.5, 0.5)` in `R/G`

Linear PNG is the current practical interchange format. Higher precision formats can be used if the project validates import precision and runtime readback.

## Generated Maps

Generated River and WaterSystem maps are created as Godot texture resources at bake time, not through `.import` files. In saved scenes, the generated bake resources are written as external `.res` files under `res://waterways_bakes/<scene-derived-folder>/`.

After a successful bake:

- `River.flow_foam_noise` and `River.dist_pressure` hold generated textures.
- `River.bake_data` records texture references, channel metadata, import profile, source metadata, and padded-atlas layout.
- `WaterSystem.system_map` holds the generated system map.
- `WaterSystem.bake_data` records texture references, world bounds, world-to-map transform, source River paths, channel metadata, import profile, and source metadata.

For saved scenes, normal bake actions overwrite the currently assigned external `bake_data.resource_path`. If no external resource exists yet, Waterways creates a deterministic scene-owned path such as `res://waterways_bakes/scenes_validation_waterways_authoring_smoke_validation/SmokeRiver.river_bake.res` or `SmokeWaterSystem.water_system_bake.res`. Duplicate node names receive deterministic suffixes based on scene-relative node paths.

Unsaved scenes cannot derive a scene-owned folder. In that case, generated maps remain temporary editor-memory resources, and the inspector warning asks you to save the scene and rebake before F6 or export.

## Current Bundled Import Profiles

The active Godot 4 port includes `.import` metadata for bundled assets and validation fixtures.

Data-safe fixtures:

- `scenes/validation/textures/imported_neutral_flow_rg.png.import`
- `scenes/validation/textures/imported_dist_pressure_data.png.import`

Both use uncompressed import, normal-map import disabled, mipmaps disabled, and `detect_3d/compress_to=0`.

Bundled Waterways data or packed-map inputs:

- `addons/waterways/textures/flow_offset_noise.png.import`: uncompressed, normal-map import disabled, mipmaps disabled.
- `addons/waterways/textures/lava_normal_bump.png.import`: uncompressed, normal-map import disabled, mipmaps disabled.
- `addons/waterways/textures/foam_noise.png.import`: uncompressed, normal-map import disabled, mipmaps enabled for the current visual/noise path.

Bundled visual textures:

- `addons/waterways/textures/water1_normal_bump.png.import`: uncompressed normal-map import with mipmaps enabled.
- `addons/waterways/textures/lava_emission.png.import`: compressed visual emission texture with normal-map import disabled.
- `addons/waterways/textures/debug_pattern.png.import`: compressed debug visual texture.
- `addons/waterways/textures/debug_arrow.svg.import`: compressed debug visual texture.

Icons under `addons/waterways/icons/` are editor UI assets, not map data.

## Scene Imports

Godot does not create `.import` files for `.tscn` scenes. The validation scenes under `scenes/validation/` are source scenes that should be opened and saved by Godot 4.6+ when they are intentionally changed.

Some small plugin UI scenes still come from the legacy scene-file shape but have been loaded by the Godot 4 editor path during the port. If you make structural UI scene edits, open and save them in Godot 4 after the manual edit so Godot can normalize any scene metadata.

## Active Shader Resources

Active Godot 4 code and scenes reference `.gdshader` files.

Legacy `.shader` counterparts may remain in the add-on folder during the port as reference material or migration mirrors. Do not use them as the active Godot 4 shader paths unless they are deliberately revalidated.

## Validation

Use `River -> Validate Data Textures` on a selected River to check:

- readable texture image data
- source path or generated/resource-owned status
- import profile warnings for project textures
- neutral flow preservation for imported flow maps

Use `WaterSystem -> Validate Map Sampling` after generating a WaterSystem map to check coverage, source paths, bounds sampling, and wet-target assignment for validation scenes that opt into those checks.
