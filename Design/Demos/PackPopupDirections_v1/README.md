# Ba hướng popup — v1

Ba ảnh concept chưa duyệt, không chỉnh runtime.

1. `01_benefit_gifts.png`: Quyền lợi chính + quà kèm — lợi ích chính chữ lớn, hình nhỏ bên cạnh, các quà phụ gom trong tray.
2. `02_pit_pass.png`: Vé đua / Pit pass — thẻ khía cạnh, đường xé và stub thanh toán.
3. `03_gift_showcase.png`: Hộp quà trưng bày — gift box/podium trung tâm, danh sách phần thưởng theo hàng.

Mỗi board gồm sáu pack theo thứ tự: starter_1, weekly_s, offer_noads_bundle, income_x2, no_ads, char_my. Giá là fallback USD trong data/iap.json; runtime lấy giá từ store. Tên reward Zielinski theo dữ liệu hiện hành, title My về đội bạn theo i18n.

QA: đối chiếu số lượng, giá và caveat từ output. Bản 02 hàng mảnh nhân vật lặp số 30 trong tên và cột số; cần đổi tên thành “Mảnh Zielinski” khi triển khai. Bản 03 vẫn có mechanic cạnh hộp quà ở starter/weekly, lớn hơn mong muốn của prompt. Không thấy lỗi số lượng hay giá. Mỗi ảnh 1254×1254 theo output thực tế của built-in tool; chưa upscale.

Prompt riêng ở `*_prompt.txt`, prompt set ở `prompts.json`, provenance ở `manifest.json`. Raw ở `output/imagegen/pack_popup_directions_v1/`.
