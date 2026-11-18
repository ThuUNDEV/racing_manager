# Soft Miniature — runtime kit

Approved source assets: `Design/AssetPacks/Soft_Miniature_UI_v1/`.
This runtime copy contains the 2× PNGs, logical-size nine-slice textures/styles and manifest. Original crops, native-size images, restoration sources and catalog remain in the Design pack.

`ui/soft_miniature.gd` owns lookup, semantic aliases, style duplication and cached resizing of raster button faces. Runtime styles reference this directory. The `manifest.json` provenance fields describe the complete source pack; rendering uses `png_2x`.

`facility_garage` is an additional cutout from the previously reviewed `Design/Demos/SoftMiniature/asset_sources/assets/clay_icons.png`: the garage cell was cropped, detached alpha noise removed, and transparent padding added. Its provenance is recorded in the runtime manifest.

Known portrait IDs and the Pico showroom model use the new artwork. Other drivers, vehicle classes, overhead car views and clothing accessories retain their existing matching illustrations. Equipment clothing is not substituted with car parts. The live circuit is drawn from actual TrackLayout/TrafficSim geometry, with a shared presentation projection for road, cars, effects and tutorial targets. Static harbor artwork does not replace the running simulation.

Integration notes and captured game screens: `Design/Previews/Soft_Miniature_Integrated/README.md`.
