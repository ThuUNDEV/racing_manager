# Garage usability pass — 27 November 2026

Changes implement the screenshot review requested in this chat, superseding the older Garage v2/v3 layout where the Car summary preceded the section tabs.

- Fixed showroom height across all three sections: 104 logical pixels at width 320; 170 at 390/412. Section tabs now remain at y218 / y292 / y294 respectively.
- Car identity, stats and actions live below the tabs in one scroll region with the collection. Removed the nested collection scroll, outer blue collection frame and oversized equipped button.
- Blue selection styling for section tabs, quantity, selected part/card and cosmetics. Orange remains the primary purchase/save action. Removed stacked card shadows and decorative dividers.
- Secondary labels use Nunito weight 750, with larger stat names, part levels, paint/decal names and collection text. Car name can wrap independently of the rank badge.
- Parts footer shows the selected stat's before/after value alongside levels and the real purchase cost. Progress bars are subdued.
- Inactive actions have flat, readable surfaces; equipped state is a green status label. Cosmetic changes retain the existing preview/draft/save/guard behavior.

Evidence: `after_runtime_{320,390,412}_tab{0,1,2}.png`, with corresponding `geometry_*.json`. Tab 0 = Cars, 1 = Parts, 2 = Appearance. Vulkan viewport captures, isolated test save, screen 1, Dummy audio. Capture fixture uses 949K cash and part levels 153/83/59/28 to resemble the supplied screenshots. Appearance captures show an unsaved teal/lightning draft.

Validation: garage_redesign_ui_test (three widths, eight languages, draft guard/save, live preview, collection reachability and real upgrade transaction); garage_test (transactions, cosmetics persistence/rollback); garage_review_v3_capture assertions (all four parts and all 8 paints / 4 decals visible, touch targets at least 44px). Godot reports resource/RID cleanup warnings on shutdown. No price, balance, car asset or save-data implementation changes.
