# Rewarded-ad income boost — ticket option A

Integrated in `ui/ads_race_controls.gd`. The modal renders on a dedicated
CanvasLayer above the clipped race view and dims the full viewport.

## New transparent PNGs
- ticket_panel.png: cream ticket panel, orange border, navy blank header.
- cash_bundles.png: grouped green cash banknotes; no gold coin currency.
- boost_ticket_button.png: orange slanted ticket with transparent side cutouts
  and a cream footer. Main-screen entry option C, with live cash/×2/video labels;
  when the boost is active, the entry switches to a navy panel with green border,
  explicit ĐANG ×2 label, countdown and remaining-time bar.

The boost and rank panels share 6 px top/bottom HUD insets and an 8 px gap.
The ticket uses an AtlasTexture region to exclude transparent source padding.

## Reuse existing assets
- Orange CTA: res://assets/racing_ui_hd/surfaces/button_amber.png
- Close: res://assets/racing_ui_hd/icons/close_red.svg
- Racing accent: res://assets/racing_ui_hd/icons/flag.png

## Composition
Keep Vietnamese labels, multiplier, duration and CTA text as live UI text.
Title: THU NHẬP ×2
Duration: 30 phút
Body: Xem quảng cáo để nhân đôi thu nhập.
CTA: Xem quảng cáo
Secondary: Để sau
Use the actual configured multiplier/duration when integrated.
Clock and video-play glyphs use live UI text; the dashed separator uses UI shapes.
Panel has side ticket notches: preserve its full silhouette when scaling;
do not use a standard 9-slice through the notches.
