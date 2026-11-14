# Daily reward artwork

Approved reference: `Design/Previews/daily_rewards_approved.png` (922×1706).

The initial flat-panel implementation was rejected. The replacement uses the reference-registered `skin.png`: a text-free transparent skin retaining the approved ribbon, sculpted cards and tabs, chest, milestone panel and button. `today.png` is the selected gold card skin. `art.png` contains dynamic reward icons. All labels, amounts, live state and buttons are native controls. Source-coordinate geometry is uniformly scaled, never stretched independently.

`art.png` is a 3×3 transparent atlas: ribbon, chest, Pro tickets; Standard tickets, All-Star tickets, Elite tickets; gem, gem cluster, gift. Active regions are defined in `ui/daily_rewards_popup.gd`. All skin and art textures use mipmaps and linear filtering. No gameplay reward data is baked into the background.
