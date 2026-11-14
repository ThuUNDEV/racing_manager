"""Declare production art jobs and their source-file coverage."""
import json
from pathlib import Path
from PIL import Image
from build_clean_modern_assets import ROOT, OUT, relative

jobs = []


def job(key, sources, grid=None, description='', transparent=True, reference=None):
    items = []
    for index, source in enumerate(sources):
        source = source if isinstance(source, str) else source.as_posix()
        if source.startswith(str(ROOT).replace('\\', '/') + '/'):
            source = source[len(str(ROOT)) + 1:]
        item = {'source': source}
        if grid:
            cols, rows = grid
            item['rect'] = [(index % cols) / cols, (index // cols) / rows, 1 / cols, 1 / rows]
        items.append(item)
    jobs.append({'id': key, 'items': items, 'grid': grid, 'description': description,
                 'transparent': transparent, 'reference': reference})


def files(folder, suffix='.png'):
    return [p.relative_to(ROOT).as_posix() for p in sorted((ROOT / folder).glob('*' + suffix))]


surface = 'assets/racing_ui_hd/surfaces/'
job('core_surfaces', [surface + name + '.png' for name in [
    'panel_body', 'hud_bar', 'button_upgrade', 'button_claim', 'button_race',
    'button_nav', 'button_cancel', 'button_menu', 'button_amber']], [3, 3],
    'Blank skins in order: white panel, blue HUD pill, green upgrade pill; green claim pill, blue slanted selected nav, white slanted inactive nav; disabled silver pill, blue square menu skin, gold reward pill.')
job('core_icons', files('assets/racing_ui_hd/icons'), [5, 5],
    'One recognizable illustrative game icon per cell in listed source order. Keep character identity, cash green, gems/trophies gold, red and blue racing cars, other elements blue/silver. Last four cells empty.')
job('core_controls', files('assets/racing_ui_hd/controls') + files('assets/racing_ui_hd/icons/reactions') + files('assets/racing_ui_hd/icons', '.svg'), [4, 4],
    'Controls in listed order; readable alert, arrow, checks, double chevrons, plus, gold A rarity badge, empty/gold stars, off/on toggle, four expressive round reaction faces, red X close. No labels except A and symbols intrinsic to controls.')
for path in files('assets/racing_ui_hd_expansion/sheets'):
    job('expansion_' + Path(path).stem, [path], description='Faithful repaint of supplied existing atlas. Preserve every object identity, position, cell grid, orientation, spacing and alpha. Silver-blue materials, cheerful polished cartoon linework. Neutral paintable silver body for garage vehicles; top-down cars point up.', reference=path)
for path in files('assets/iap_offers/sheets') + files('assets/iap_offers/illustrations'):
    opaque = Path(path).stem in ['feature_scenes', 'recruit_scenes', 'resource_scenes', 'ui_panels', 'hero_driver_my', 'hero_income_x2', 'hero_starter']
    job('iap_' + Path(path).stem, [path], description='Repaint actual offer art in identical composition/grid. Keep same recognizable characters, gestures and identities, all objects fully visible. Clean white/blue sporty garage, fresh green and gold economic rewards. No text, prices or labels. Character cutouts and buttons transparent; full scene illustrations and background cards opaque. Background cards should remain 2x2 blank panels with subtle decoration and central empty content area.', transparent=not opaque, reference=path)
for path in files('assets/startup_loading'):
    job('startup_' + Path(path).stem, [path], description='Preserve existing scene composition and camera angle, reskin to bright clean modern sport racing pit garage with white-blue architecture and tasteful blue speed graphics. No UI, no loading bars or text. Car cutout retains angle and centered silhouette.', transparent=Path(path).stem == 'loading_car', reference=path)
job('tutorial_linh', ['assets/tutorial/linh_expressions.png'], description='Same friendly Vietnamese female tutorial guide Linh, same three expressions and poses in three horizontal cells: smile, pointing, excited. Preserve identity, face, hairstyle and exact positions; white/blue sporty team outfit, bright clean cartoon. Transparent cutouts, no text.', reference='assets/tutorial/linh_expressions.png')
for path in files('assets/workshop_gp/atlases'):
    job('workshop_' + Path(path).stem, [path], description='Faithful repaint of supplied legacy game atlas, same item count, same grid, same icon identities and positions. Clean modern cartoon silver/blue materials, semantic green money, gold rewards. Keep all racing car paint colors and orientations distinct. Transparent gaps, no added labels.', reference=path)
for path in files('assets/workshop_gp/portraits') + files('assets/workshop_gp/rewards'):
    job('workshop_' + Path(path).stem, [path], description='Faithful repaint same recognizable subject, composition and pose in clean modern white/blue sporty cartoon style; do not change character identity.', transparent=Path(path).stem != 'offline_garage', reference=path)
for path in files('assets/workshop_gp/shop/textures'):
    job('shop_' + Path(path).stem, [path], description='Faithful repaint of supplied shop art; same cell positions, objects and counts. White/blue clean modern sporty garage style, gold rewards and green cash. No text, no prices, no UI labels.', transparent=Path(path).stem == 'shop_icons', reference=path)
job('shop_catalog_preview', files('assets/workshop_gp/shop/preview'), description='Recreate the existing asset preview sheet as a new clean-modern art catalog preview; keep asset count, ordering and arrangement, no invented UI screenshot. Pale backdrop and blue/green assets.', transparent=False, reference='assets/workshop_gp/shop/preview/asset_sheet.png')
for path in files('assets/workshop_gp/textures'):
    job('track_' + Path(path).stem, [path], description='Preserve exact top-down racetrack geometry and road locations from reference; this texture aligns to gameplay track JSON, so road centerlines must not move. Only repaint scenery to brighter clean modern cartoon style, natural grass and neutral asphalt, white-red curbs. No labels or overlays.', transparent=False, reference=path)
job('city_header', ['assets/racing_ui_hd/backgrounds/racetrack_background.png'], description='Same dense cheerful racing-city artwork, streets, cars, spectator buildings and palm trees, preserve camera and layout. Clean modern cartoon detailing, bright white/blue buildings. No text, no UI.', transparent=False, reference='assets/racing_ui_hd/backgrounds/racetrack_background.png')
job('ad_boost', files('assets/ads_income_boost'), [3, 1],
    'Left cell: blank blue sport slanted boost-ticket button with green cash and small gold double reward motif; center: distinct bundles of green cash and coins; right: blank white-blue ticket panel with blue rim. No text or numbers. Each artwork entirely within own cell. Preserve separability.')
vectors = files('assets/workshop_gp/icons/vector', '.svg')
job('utility_icons', vectors, [7, 6], '42 small utility icons in exact listed row-major order. Simple legible blue-slate or blue/silver symbols, designed for pale backgrounds, clean smooth rounded strokes. Read file basenames as identities. No text or labels, plain recognizable silhouettes. No enclosing circle unless icon identity needs one.')
for source in files('assets/workshop_gp/icons/vector_dark', '.svg'):
    key = Path(source).stem
    index = next(i for i, item in enumerate(jobs[-1]['items']) if Path(item['source']).stem == key)
    jobs[-1]['items'].append({'source': source, 'rect': jobs[-1]['items'][index]['rect']})
job('legacy_ui_components', files('assets/workshop_gp/ui', '.svg'), [4, 8],
    '31 blank reusable UI components, in basename order. Interpret old names as function not colors: app_background pale blue rectangle, danger red, disabled silver, orange buttons NOW blue (normal/hover/pressed differences), secondary white, success green, capsule white, cream card NOW white, locked pale gray, selected pale blue, checkboxes, empty tray, blue spinner, neutral translucent overlay rectangle, white modal panel, blue slanted selected nav, red dot, graphite panel NOW white-blue, blue progress fill, pale progress track, slider knob and track, stat chip white-blue, white toast, toggles off gray/on blue, tooltip arrow blue-white, white pointing tutorial hand. All sprites isolated, ample transparent gaps. No words or numbers, no dark navy panels.')
job('shop_ui_components', files('assets/workshop_gp/shop/ui', '.svg'), [4, 2],
    '8 blank UI surfaces in basename order: disabled gray, hover green, normal green, pressed darker green, white-blue card, white-blue currency pill, blue-and-pale pass panel, pale gold reward panel. No symbols, no text.')
job('badges', files('assets/workshop_gp/badges', '.svg'), [3, 2],
    'Six distinct clean modern cartoon racing medals and league shields in order. medals 1 gold, 2 silver, 3 bronze; pro blue/gold race shield, rookie blue/silver race shield, semi-pro blue/green race shield. No text; intrinsic podium digits 1/2/3 allowed on medals. Transparent background.')
job('branding', files('assets/workshop_gp/branding', '.svg'), [2, 1],
    'Left: rounded-square app icon with cute blue racing car and checkered flag, clean modern sporty cartoon. Right: wide bright white-blue racing pit-lane splash background without text. Keep art inside separate equal cells.', transparent=False)
for folder in sorted((ROOT / 'assets/workshop_gp/vfx').iterdir()):
    if folder.is_dir():
        sources = files(relative(folder), '.svg')
        if sources:
            rows = (len(sources) + 3) // 4
            job('vfx_' + folder.name, sources, [4, rows],
                f'Frame-by-frame sprite animation for {folder.name}, {len(sources)} frames in exact row-major chronological order, four columns. Smooth progression, same center in every cell. Clean modern cartoon colors: blue/cyan and silver sparkle; gold coins for coin_spin and reward_burst, green/blue upgrade arrows, multicolor pastel confetti, white-blue finish flash, blue player selection ring. Preserve effect purpose. No text, no UI backgrounds. Isolated transparent sprites, generous gaps, no glow haze over transparent regions. Final unused cells empty.')

for entry in jobs:
    if entry.get('reference'):
        with Image.open(ROOT / entry['reference']) as image:
            entry['transparent'] = 'A' in image.getbands() and image.getchannel('A').getextrema()[0] == 0

all_sources = [item['source'] for entry in jobs for item in entry['items']]
inventory = json.loads((OUT / 'source_inventory.json').read_text(encoding='utf-8'))
assert len(all_sources) == len(set(all_sources)), 'Duplicate source coverage'
assert set(all_sources) == {item['source'] for item in inventory}, set(item['source'] for item in inventory) - set(all_sources)
(OUT / 'generation_plan.json').write_text(json.dumps(jobs, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'jobs': len(jobs), 'source_files': len(all_sources), 'job_ids': [entry['id'] for entry in jobs]}))
