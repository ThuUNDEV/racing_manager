# Car demo match v5 — 27 November 2026

Reference: `reference.png`, supplied directly by the user. Scope approved: shared
playable 3D models and Shop visuals; the focused race renderer integration was
separately approved in chat. Original reference preserved without changes.

Implemented: five rebuilt native model families, lofted domed bodies and painted
canopies, rounded fenders, deeper tires, warm rims, class-specific headlights,
chunky painted spoilers. Shop and Garage share the actual models. Epic finishes
share one material helper with racing; racing respects car/paint/decal snapshots.
No prices, balance, inventory, save schema or translations were edited here.

## Visual comparison

`cars_and_finishes.png` shows the actual runtime models at a larger size.
The cars are fuller, smoother and larger in the Shop than the previous render.
The demo remains the art direction, rather than an exact sculpt: its integrated
fenders, complex reflected lighting and hand-shaped flame patterns are still more
refined. Apex retains the game's Ruby red default rather than the illustration's
purple; the selected product colours and identities are kept intact.

Shop captures cover 320/390/412 logical widths in Vietnamese. The existing card
layout, labels, prices, controls and scroll behaviour were retained. No new text
or label sizing was introduced. `race_runtime.png` shows the real racing screen;
model/paint selection for all five families is additionally checked by regression.

## Verification

- `car_demo_match_capture.gd --economy-test`: zero failures, headless and Vulkan;
  five race families, Epic coats, retained decals, per-signature mesh reuse,
  snapshot stability, and removal of Epic coats on return to ordinary paint.
- `epic_garage_test.gd --economy-test`: zero failures.
- `race_world_3d_test.gd --economy-test`: zero failures, headless and Vulkan;
  simulation position, circuit projection, camera gestures and resize checks.
- Final Shop screenshots: 320/390/412, with temporary user-data directories,
  secondary display and Dummy audio.
- Changed tracked source/model files pass `git diff --check`.

Existing main-screen harnesses report resource/RID cleanup warnings at shutdown.
No parse, shader-compilation or runtime script errors appeared in passing runs.
One initial Vulkan launch failed to create a device; the subsequent launch passed.
Godot MCP project/script tools were unavailable, so CLI validation and real Vulkan
captures were used. No image generation tool was used; the deliverable is native
procedural 3D geometry and shaders, not raster substitutes.
