# Pack popup — corrected v2

Approved source: Design/Demos/SoftMiniature/approved/pack_popup_benefit_gifts_v1/01_benefit_gifts.png. Compare images use complete popup frames plus shadow margins, uniformly scaled to a 390px card width. Raw game screenshots are preserved, with no frame stretching.

review_after.json records resolved findings, live panel measurements and validation. measurements.json contains the final 3-width captures plus a genuinely scrolling 320×568 starter_3 fixture; locale_measurements.json preserves the separate 8-language inspection. native_measurements.json and starter_1_vi_886x1920.png verify native resolution.

The capture harness uses an isolated save and a ready-to-purchase presentation fixture only; no actual purchase is invoked and eligibility/grant logic is unchanged.

Run with --quick for image captures, no flag for locale layout inspection, or --native for the native viewport. Every graphical run must use --screen 1 --audio-driver Dummy and temporary XDG_DATA_HOME, per CLAUDE.md. Existing resource/ObjectDB warnings on engine shutdown remain recorded in the logs.
