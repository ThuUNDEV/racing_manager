# Shop UI validation — 2026-11-16

Changed source files: `ui/shop_page.gd`, `ui/shop_demo_skin.gd`, `ui/shop_reference_shell.gd`, `tests/shop_spotlight_test.gd` (existing untracked Shop test extended). No catalog, purchase service or translation table changed; all copy reuses existing en/vi keys.

Offers now share one design-unit layout and a white frame with an 18-unit radius and 3-unit blue border. All purchase buttons share the existing green buy skin. Starter adds a blue section header, with a single catalog purchase-limit label. Perks use transparent atlas sprites; characters use transparent portraits rather than screenshot crops. All reward icons and values come from PackUi and render above the purchase slot. Additional reward rows increase card height. Info targets stay at least 44×44 real pixels and clear titles, copy and rewards. Secondary text #304e74 on white has 8.51:1 contrast. The fixed Shop title now uses I18n instead of an image with baked Vietnamese text.

## Validation

- `python3 tools/i18n_check.py`: PASS (`python` is unavailable here). Existing unused-key/newline warnings remain.
- `tools/run_tests.sh`: 32/36 PASS. The original file has CRLF, so its unchanged contents were normalized in `/tmp/shop_run_tests.sh` for Bash and its working-directory line pointed to this project. The repository script's EOL was preserved.
- Full-suite failures, all reproduced with the original Shop files in an isolated temporary project: `gear_ui_test` (coupon button); `state_test` (Ticket Marketing income); `ads_v1_test` (invalid-data diagnostic count); `daily_rewards_ui_test` (login row label and notification dots).
- `shop_spotlight_test`: PASS in native OpenGL, both en/vi and 320/390/412. Checks actual icon resources/counts, card/reward/buy containment, title/copy clearance from 44px info targets, complete copy, live prices, Starter 1/2/3, purchase and detail routing, and end-of-scroll traversal.
- `shop_redesign_test`: PASS.
- `upgrade_grid_ui_test`: PASS in native OpenGL. Its six generated non-Shop PNGs were restored byte-for-byte from pre-run copies.
- `shop_ui_test`: 1 failure, identical on the original Shop (Settings toggle count).
- `shop_blue_demo_test`: 3 failures, identical on the original Shop (legacy scroll-position assertion). Its touch scrolling, info tap, actual mock purchase, prices and other assertions pass.
- Native `shop_snapshot_test`: all 9 old golden comparisons fail before and after. Goldens were left unchanged; they already describe a different page. This remains unresolved, and the suite is not globally green.
- Godot also prints resource-leak warnings at shutdown in the baseline and current UI tests.
- `git diff --ignore-cr-at-eol --check` passes for edited UI files. Existing EOL was preserved. No add/commit/stash/revert was performed.

## Visual review

Inspected both supplied reference PNGs before editing. Rendered the six configurations with a real Godot renderer and checked the top plus every scroll viewport down to the final login-reward row: Starter, perks, recruits, Daily Gift, open packs, daily offers, gems, cash, tickets, additional perks, combos, weekly offers and remaining drivers. No observed card-edge clipping, missing reward icon or overlapping purchase button. Long Vietnamese copy fits at 320px. Starter uses the existing transparent Linh portrait instead of the previous blue-cap screenshot crop.

For each `<lang>` in `en`, `vi` and `<width>` in `320`, `390`, `412`:

- `shop_fixed_<lang>_<width>.png`: native top viewport.
- `shop_fixed_<lang>_<width>_scroll_<offset>.png`: native screenshots covering the entire scroll.
- `shop_fixed_<lang>_<width>_starter_2.png`, `_starter_3.png`: later Starter states.
- `shop_fixed_<lang>_<width>_full.png`: full-page image stitched from native scrolling captures; fixed header/footer appear once. Native viewport captures are authoritative at stitch seams.

Logs: `shop_fixed_suite.log`, `shop_fixed_i18n.log`, `shop_fixed_layout.log`, `shop_fixed_comparison.log`.
