# Low-poly race car

- `race_car.tscn`: editable native Godot 4 scene; drag into a 3D scene.
- `race_car.glb`: portable model with embedded materials.
- Front points along -Z, up is +Y. Ground at Y=0; origin centered between wheels.
- Approximate dimensions: 1.82 × 1.17 × 2.85 units (width × height × length).
- Four named wheel pivots: LeftFrontWheel, RightFrontWheel, LeftRearWheel, RightRearWheel. Rotate on local X for rolling.
- Change Body_Paint_Blue to recolor body, wing, roof and hubs. Make materials unique per car instance when assigning team colors.
- Materials and geometry only; no textures, animation, collision or vehicle controller included.
- Rebuild: `godot --headless --path . --script tools/models/build_race_car.gd`.
