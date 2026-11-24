# Free Gifts UI assets v1

12 transparent PNG assets reconstructed from the approved image demo using the
built-in image_gen tool, then cropped and alpha-cleaned. No text or quantities
are baked into the textures. The live shop uses ui/shop_free_gift_card.gd for
the featured gem card and two ticket reward rows. The gem action claims the
daily free reward first, then uses the existing rewarded-ad placement, including
its cooldown and daily limit. It returns to the free claim on the next day. Its section
header keeps the shared racing ribbon for consistency with other shop sections.

## Godot setup

- Cards: use PanelContainer, assign styles/card_*.tres to Theme Overrides > Styles > Panel.
- Buttons: use Button, assign styles/button_*.tres to the normal style. Add button text as native text. Hover and pressed states can use duplicates with modulate_color adjusted. Disabled styling should be set separately.
- Quantity: use PanelContainer with styles/quantity_pill.tres and a child Label (x5 / x1).
- Icons: use TextureRect, Expand Mode = Ignore Size, Stretch Mode = Keep Aspect Centered.
- Header: use header_cyan.png in TextureRect and overlay icon_gift.png plus a Label.
- All root PNGs are high resolution; styles/textures contains smaller versions for 9-slice skin resources with mobile-sized corners.

Recommended layout at 390px viewport width: 12px outer margins, 8px vertical gaps,
one daily card around 112px high, then three reward rows around 88px high.
Use HBoxContainer inside each card, 56-64px icon, flexible text column, and a
108-120px action button with a 44px minimum touch height. Use the existing play
icon from the project for video buttons. Keep text and quantities in Labels so
localization and reward values can update.

Recommended text: dark navy #0D2D50, white on buttons, dark green/blue outline
on the corresponding buttons. Adjust font size for localized labels.

## Asset map

- header_cyan: cyan header, checkered motif on the right.
- card_daily_gold: daily reward background.
- card_gems_lavender: free gems background.
- card_gear_mint: gear ticket background.
- card_driver_blue: driver ticket background.
- button_claim_green / button_video_blue: blank button backgrounds.
- quantity_pill: blank quantity badge.
- icon_gem / icon_gear_ticket / icon_driver_ticket / icon_gift: isolated icons.

See manifest.json for source cell rectangles and dimensions. To regenerate
crops, run tools/export_free_gifts_assets.py with the original clean sheet path.

Generation prompt: reconstruct the approved Free Gifts demo as a transparent
3-column by 4-row sheet of twelve isolated text-free UI elements, in the exact
asset-map order above; preserve the soft casual racing style, colors, rounded
borders and glossy buttons; remove all labels, quantities, inner icons and
buttons from card backgrounds, remove scenery, and separate all reward icons.
