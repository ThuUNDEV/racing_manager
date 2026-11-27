# Garage 3D stage trial — 27 November 2026

User requested a trial of a real 3D platform/floor beneath the existing car, with the illustrated workshop retained behind it.

Implementation: `ui/garage_showroom_stage.gd` constructs a matte blue round platform, rounded rim, blue/cream geometric checker skirt, peach tiled floor and illustrated rear wall. Only the upper 53.5% of the existing showroom texture appears on that wall; the baked platform is excluded through material UVs. The floor, platform, car and shadows share the same perspective camera. Directional shadows are enabled for Garage previews; existing contact shadows remain at wheel ground height. The car rotates while the stage stays fixed.

`CarPreview.showroom_3d` is opt-in and enabled only by GaragePage. Collection thumbnails and other previews retain their previous rendering. Existing pearl paint/ink changes in car_preview.gd were preserved. No car mesh, race renderer, pricing, balance or save-data changes. No generated bitmap assets.

Evidence: `showroom_{320,390,412}_{90,145,210}.png` crops and matching full-screen PNGs. Vulkan runtime, temporary XDG_DATA_HOME, --economy-test, screen 1 and Dummy audio.

Checks passed:
- garage_showroom_stage_test: regular-preview isolation; platform top at wheel ground height; whole platform and every body mesh's bounds fit at three widths, five body families and three angles; drag rotates car independently; opt-out hides the stage.
- garage_selection_ui_test: all 15 selections at three widths, matching thumbnails, paint/decal preservation, purchase/default appearance and saved customisation.
- Render logs contain no parse/script errors. The main preview still reports resource/RID cleanup warnings when exiting.

Reproduce captures: XDG_DATA_HOME=$(mktemp -d) RM_LANG=vi godot --path . --screen 1 --audio-driver Dummy -s res://tests/garage_stage_preview.gd -- --economy-test

This is a first visual pass. The rear wall remains an illustration; side props are cropped according to the camera framing. Mobile GPU performance has not been measured.
