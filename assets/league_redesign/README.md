# League redesign asset kit

Artwork generated from the approved League mockup on 2026-11-14. Version 2 uses the softer finish requested by the user: reduced reflections, glow, bevels and shadows.

- 16 transparent icon PNGs, including all 8 configured trophy upgrades.
- 12 transparent, text-free component PNGs.
- 11 Godot StyleBoxTexture resources with initial nine-patch margins.
- `manifest.json`: sprite dimensions, source rectangles, hashes and upgrade ID mappings.
- `preview.html` / `preview.png`: asset contact sheets.
- `source/`: unmodified generated sheets and approved mockup.

Text, amounts, rank numbers, info symbol, level segments and progress bars must be rendered by Godot. Medal centers are intentionally blank. Keep the existing HUD and bottom navigation assets.

The extraction script removes generation haze and detached residue from transparent gutters, trims and adds an 8 px transparent border. Panels are exported at half sheet resolution for mobile nine-patch borders. Header and summary motifs retain their approved composition. UI integration: `ui/trophy_panel.gd`. Economy data is unchanged.

Rebuild: `python tools/package_league_assets.py` (Pillow, NumPy, SciPy; original generation files must be available at the source path in the script).
