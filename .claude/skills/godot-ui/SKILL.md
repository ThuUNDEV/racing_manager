---
name: godot-ui
description: Build native Godot 4 UI from reference screenshots.
---

# Godot UI Builder

When a UI screenshot is provided:

1. Analyze the visual layout, dimensions, colors,
   typography, spacing and icons.
2. Inspect the existing Godot project.
3. Create native Control nodes and reusable scenes.
4. Use containers, anchors and size flags.
5. Use Theme and StyleBoxFlat for styling.
6. Preserve the reference layout.
7. Support the target screen resolution.
8. Run the scene and capture a screenshot if tools permit.
9. Compare the result with the reference.
10. Fix visual differences iteratively.

Rules:
- Never flatten the UI into a single image.
- Do not modify unrelated scenes.
- Reuse existing assets when possible.
- Report missing assets.
