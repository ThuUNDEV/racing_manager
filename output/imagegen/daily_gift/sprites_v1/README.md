# Daily Gift concept sprite extraction v1

Source: `../daily_gift_concept_v1.png` (1024 × 1536).

- `icons/`: 23 individual art/icon PNGs with alpha extracted using the art-tools MCP `remove_background` tool, refine=true. Original crop dimensions and positions are preserved.
- `composites/`: 26 rectangle crops of UI components, cards, badges and groups. These retain their original background, baked labels and overlapping artwork; they are reference composites, not empty production skins.
- `text_crops/`: 20 raster label crops with the original background. Prefer live localized text in game.
- `manifest.json`: source rectangles, output dimensions, alpha checks and tool provenance.
- `contact_sheet.png`: visual inventory.
- `extract_sprites.py`: reproducible extraction script; requires Pillow and access to the art-tools server.

The source is one flattened concept image. Hidden pixels behind text/icons cannot be recovered by cropping or background removal. Empty panels/buttons would need a separate reconstruction pass.
