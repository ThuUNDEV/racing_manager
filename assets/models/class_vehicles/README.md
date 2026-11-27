# Vehicles by race discipline

Native Godot meshes created for Racing Manager on 2026-11-27. No downloaded or AI image assets.

| Class | Runtime scene | Identity |
| --- | --- | --- |
| Racing | `../race_car/{pico,nova,apex,titan,zenith}.tscn` | Existing Garage tier models |
| Rally | `rally.tscn` | Hatchback, roof rack, spotlights, treaded tires |
| Stock Car | `stock.tscn` | Wide closed body, splitter, rear spoiler |
| Superbike | `bike.tscn` | Two wheels, fairing, fork, rider and helmet |
| Speedster | `speed.tscn` | Narrow open-wheel body, front/rear wings |
| Monster Truck | `monster.tscn` | Raised pickup, oversized tires, exposed axles |

Rebuild scenes with `godot --headless --path . -s res://tools/models/build_class_vehicles.gd`.
Render icons with `XDG_DATA_HOME=$(mktemp -d) godot --path . --screen 1 --audio-driver Dummy -s res://tools/models/render_class_vehicles.gd`.
Each transparent PNG is 192×192 and rendered from the same runtime model; mipmaps must stay enabled.

`ui/car_appearance.gd` resolves race discipline separately from Garage vehicle tier.
The circuit's track determines its vehicle discipline, keeping all cars tied to the displayed race,
including pending switches and restored checkpoints. Garage opts into the managed facility's class.
Shop previews continue to describe the underlying shared Garage vehicle and cosmetics.

Meshes face -Z, rest on Y=0 and expose Body/Roof paint panels. Child wheel assemblies
end in Wheel so the renderer can roll them. Class geometry changes presentation only;
shared Garage statistics, prices, ownership and simulation balance are preserved.

## Revision 2 — sculpted Soft Miniature vehicles

Rebuilt after review of the first blocky models. The generator extends
`tools/models/build_race_car.gd` to reuse Racing's curved body and segmented
cabin surfaces. Bevelled small parts, blue glazing, clear-coated paint, sculpted
tire sidewalls, recessed alloy wheels, headlight housings and discipline-specific
trim replace the first-pass primitives. Superbike has a tucked rider and curved
helmet visor; Monster has a pickup bed and visible suspension.

Decorative geometry is merged by material. Repeated wheels share mesh resources;
wheel radius metadata controls rolling speed. Generated mesh LODs reduce detail
at race scale while closeups retain the source surfaces. Body, Roof and Cabin_Glass remain
separate for paint, livery and windshield effects. Gallery, individual 512×512
model renders and runtime captures are in `Design/Previews/Class_Vehicles_v2/`.
