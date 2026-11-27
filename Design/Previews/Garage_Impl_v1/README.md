# Garage implementation v1

Chuẩn đối chiếu: `Design/Concepts/Garage_Redesign_v2/{01-car,02-parts,03-look}.png` (đã được người dùng chấp nhận).

Ảnh runtime: `320_tab0.png` … `412_tab2.png`, 9 ảnh. Tab 0 = Xe; 1 = Phụ tùng; 2 = Ngoại hình. Logical width 320/390/412, tỷ lệ 390×845. Harness: `tests/garage_redesign_ui_test.gd`, ngôn ngữ Việt, save tạm, 120K coins, 100 gem, hai Pico sở hữu, cấp 40/30/20/10. Chụp Vulkan Forward+, cửa sổ screen 1, Dummy audio.

Đã lặp chỉnh: giảm showroom ở màn hẹp, giảm chiều cao thẻ phụ tùng, wrap CTA/nhãn decal, thu gọn stat chip, ghim footer. Kiểm tra kích thước 3 mục × 3 rộng × 8 ngôn ngữ; kiểm tra guard bản nháp, lưu màu, và giao dịch từ CTA.

## Sai lệch còn lại so concept

- Dùng năm thân xe 3D hiện có theo yêu cầu; hình xe/đèn/kính/decal khác ảnh AI. Không thay asset model của người dùng. Nền xưởng dùng asset hiện có; showroom được nén chiều cao, đặc biệt tại 320, nên tỷ lệ cảnh khác concept.
- HUD/nav dùng khung game hiện hành, thứ tự Shop/Túi/Đua/Đội/Giải; không sao chép HUD Lv12 hay thứ tự nav trong concept.
- Icon phụ tùng tái dùng ExpansionArt, không phải icon đất sét trong ảnh. Swatch là Control native có viền chọn, không phải sprite bóng nổi.
- Tab Xe dùng stat chip gọn; ở 320 cần cuộn để xem hàng xe kế tiếp. Các xe cùng màu mặc định nếu chưa tùy chỉnh, đúng save; không giả màu/sở hữu theo ảnh.
- Chỉ số thật của fixture khoảng 62,2 / 46 / 46 / 42,4 do Pricing hiện tại dùng đường cong và hệ số riêng, khác 54/44/42/40 trong tài liệu 15 cũ. Giá nâng engine 40→41 hiện khoảng 1,43K, lấy dữ liệu thật.
- Test i18n không có khóa mới thiếu; kiểm toàn repo vẫn báo lệch xuống dòng và chuỗi Việt sẵn có ngoài phạm vi. Bộ test renderer vẫn báo resource/RID còn sống lúc thoát (cũng có trong garage_car_preview_test).

Chưa đạt đồng nhất mỹ thuật tuyệt đối với concept. Nếu cần bước polish tiếp, cần quyết định có bổ sung bộ icon đất sét riêng và chỉnh artwork/model xưởng hay giữ asset hiện có. Không có quyết định chặn luồng Garage hiện tại.

## File thay đổi trong công việc này

- ui/garage_page.gd
- ui/main.gd (chỉ tích hợp shell Đội/Garage, giữ các thay đổi khác có sẵn)
- i18n/en.json, vi.json, id.json, ms.json, th.json, ja.json, ko.json, zh_Hans.json
- tests/garage_redesign_ui_test.gd (mới)
- tests/asset_layout_test.gd (hỗ trợ shell Control của Đội)
- Design/34_Layer_Layout_Spec.md (bổ sung Garage v2)
- Thư mục bằng chứng này (9 PNG + README).

Không thay gameplay, Pricing, balance, save schema, race_view.gd hoặc race_world_3d.gd; không commit, không tạo branch, không dùng RaceStar art, không sinh asset mới.
