# Perk cards runtime verification

Implemented approved A layout in `ui/shop_perk_card.gd`, connected by `ui/shop_page.gd`. Income×2 remains in Special packs; ×3/upgrade/Offline+ remain in More perks. Existing Shop section ordering is unchanged. The new card's horizontal gutter is12logical in the current Shop shell (4existing +8inset). Hero atlas is `assets/perk_cards_v1/heroes.png`; all text, badges and prices are independent controls. Online and offline benefits remain separate.

`en/vi/id_<width>.png` are native Godot captures of the actual card component at320/390/412logical. All four SKU presentations are shown together only in this layout fixture. `shop_income_x2_390.png` and `shop_income_x3_390.png` capture the actual Shop integration, respecting SKU visibility. These are renderer output, not generated mockups.

Validation: `tests/perk_cards_ui_test.gd` checks all8languages ×3widths ×4cards, height150–228, gutter, complete labels, CTA≥44, no art/text/button overlap, SKU signal routing, ownership/upgrade visibility, busy state and long localized store price. `tests/iap_test.gd` verifies grants/pending/restore/save behavior and passes. `tools/i18n_check.py` reports no missing keys or placeholder differences; its existing unrelated newline/hardcoded-string warnings remain.

Run with a separate XDG_DATA_HOME and `--headless --audio-driver Dummy --path . -s tests/perk_cards_ui_test.gd`. To capture, omit headless and use `--screen 1 --audio-driver Dummy --rendering-method gl_compatibility -s tests/perk_cards_ui_test.gd -- --capture`. Tests do not use the player's save. No commit was created.
