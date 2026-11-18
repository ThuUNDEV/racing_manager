# Soft Miniature UI integrated into Godot

Implemented on 2026-11-17 using the reviewed Soft Miniature asset pack and `Design/Demos/SoftMiniature/layout-review.html` as the layout reference.

## Result

- Shared blue resource HUD, warm ivory panels, orange primary actions, blue secondary actions and five fixed, equal navigation tabs with visible labels.
- Race: stage/facilities row, actual income per minute, daily gift entry, 190px live circuit, single-column vehicle upgrades and income upgrades below. The whole body scrolls between the fixed HUD and navigation.
- Bag: three-column equipment inventory and shortcut to the actual Shop pack controls.
- Team: two-column driver roster with larger portraits, correct live ownership/level/power states, and existing recruit/select/upgrade details.
- Garage: miniature workshop background and Pico showroom art, three functional sub-tabs, actual car stats and existing paint/decal editing.
- League and Shop: shared surfaces and typography, two-column offers, compact descriptions, full reward contents in details, live prices and purchase eligibility.
- Daily rewards, settings, profile, facilities, ad controls and other dialogs use the shared palette and surfaces while retaining their state and callbacks.

The source pack covers one showroom model and a subset of portraits/illustrations. Existing art remains for uncovered models and equipment. The race board and moving cars remain procedural representations of actual simulation geometry. No economy, simulation or save schema was changed.

## Screenshots from the running game

Three viewports: 320×568, 390×778 and 412×915. Files are named by width and screen: `390_tab_0.png` (Race), `390_tab_1.png` (Bag), `390_tab_2.png` (Team), `390_tab_3.png` (League), `390_tab_4.png` (Shop), `390_garage_0.png`, `390_daily.png`, `390_settings.png`, `390_pack_detail.png`, and `390_race_income.png`. Other widths follow the same names.

## Verification

See `validation.json` and the logs in `validation/`. 42 test scripts pass, including real-render integration, button sizing, touch scrolling, popup dismissal, offline report, Shop purchases with a mock provider, loading and splash handoff, race geometry, and gameplay/core regression checks. The button skin check covers 741 visible button instances/states across screens and widths.

The new `tests/soft_miniature_ui_test.gd` checks page bounds, fixed navigation, one-column upgrades, two-column roster, Garage tabs, seven daily rewards, settings, live prices, real upgrade spending/shortfall and coupon pack opening. It uses an isolated test save and produces the screenshots with:

```sh
RM_LANG=vi godot --path . --rendering-method gl_compatibility \
  -s res://tests/soft_miniature_ui_test.gd -- --capture
```

Four existing tests still fail, with the same failures reproduced using the pre-integration UI/i18n snapshot:

| Test | Existing assertion failure |
| --- | --- |
| `state_test` | Hard-coded Ticket Marketing rate `8.25075` differs from current economy data. |
| `gear_ui_test` | Expects the word `coupon` in a payment button whose payment is presented by icon and amount. |
| `ads_v1_test` | One expected validation-message substring differs from the current validator output. |
| `daily_rewards_ui_test` | Existing login-row visibility assertion and expectation that the Shop dot clears despite unspent newly claimed coupons. |

Legacy assertions tied to replaced artwork were updated for the new gem texture, orange action face, 190px race height, wide offline button geometry and separate 16px flag artwork/44px touch target. Some older tests emit existing ObjectDB cleanup warnings; the new integration run exits without runtime or resource-leak errors.
