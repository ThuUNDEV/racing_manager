# Pack Popup Redesign v1

Ảnh concept chưa duyệt; không chỉnh runtime.

- `concept.png`: sáu popup theo lưới 3 × 2, cùng header, hero, khối lợi ích, vùng thưởng và CTA.
- `prompt.txt` / `prompts.json`: prompt đầy đủ và ảnh tham chiếu.
- `manifest.json`: nguồn dữ liệu, công cụ, model agent, kích thước và QA.

Số liệu lấy từ `data/iap.json`, nhãn từ `i18n/vi.json`. `char_my` có title “My về đội bạn” và tên reward Zielinski theo dữ liệu hiện hành. Giá USD là `price_fallback`; runtime phải dùng giá store trả về.

Đã đối chiếu hình: 150 / 3 Pro / 3 Standard / 1 giờ; 300 / 6 All-Star / 4 Elite / 4 giờ; no-ads bundle + 300 gem + 3 All-Star; ×2 online và thưởng đua (không offline, không cộng dồn boost); no_ads + 100 gem; Zielinski + 30 mảnh + 100 gem + 3 Elite. Không phát hiện lỗi chữ rõ ràng khi xem toàn ảnh. Đây là ảnh concept để duyệt bố cục và mỹ thuật, chưa phải sprite runtime.
