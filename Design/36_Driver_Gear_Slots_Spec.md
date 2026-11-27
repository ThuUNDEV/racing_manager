# Lắp/gỡ trang bị theo từng tay đua — đặc tả v0.2

Ngày: 27/11/2026. Trạng thái: **đề xuất theo lựa chọn của người dùng, chưa triển khai**. Không sửa runtime, `data/gear.json` hay save khi chưa có yêu cầu triển khai.

Đảo ngược nguyên tắc "sở hữu = hiệu lực toàn đội" trong [14_Driver_Equipment.md](14_Driver_Equipment.md) §3. Nếu triển khai, §3 và §7 của file 14 phải sửa theo.

## 1. Quyết định đã chốt (27/11/2026)

- **Phương án B**: bonus gear = tổng các món đang lắp cho **mọi tay đua đã sở hữu**, không chỉ tay đang chạy.
- **Mỗi tay đua có 8 ô cố định**. Số ô không đổi theo level tay đua và không phân loại ô theo loại đồ (ô tự do).

## 2. Hiện trạng liên quan

- `GameState.gear_owned`: `gear_id -> {level, shards}`. `gear_power_bonus()` hiện cộng đều cho `player_stats()` từ mọi món sở hữu.
- Một tay chạy mỗi lúc (`active_driver_id`). 12 tay đua, 30 phụ kiện.

## 3. Quy tắc

1. Mỗi tay đua sở hữu có 8 ô tự do.
2. Một món chỉ lắp cho **một** tay tại một thời điểm. Lắp món đang ở tay khác thì hỏi xác nhận chuyển.
3. Gỡ trả món về kho, không mất level/mảnh. Lắp/gỡ miễn phí.
4. Bonus = tổng `attack/defense` theo level của mọi món đang lắp (ở bất kỳ tay nào) × `power_per_point`. Món trong kho chưa lắp không cộng.
5. Đổi tay đua không đổi bonus gear. Lắp/gỡ chỉ áp từ cuộc đua kế tiếp, không sửa `race_snapshot` đang chạy.
6. Nhận trùng, đổi mảnh, nâng level theo kho chung như file 14.
7. Bộ đếm: `Sở hữu N/30` và `Đang lắp M`.

## 4. Cảnh báo cân bằng

12 tay × 8 ô = 96 ô, nhiều hơn 30 phụ kiện. Chỉ cần 4 tay là có 32 ô. Vì bonus cộng dồn mọi tay, nên **tay nào giữ đồ cũng không ảnh hưởng Power**. Người chơi chỉ cần lắp đủ món là có toàn bộ bonus, y như hiện tại. Cơ chế này là thao tác thêm, không tạo lựa chọn chiến thuật. Nếu muốn có đánh đổi, cần một trong:
- Giảm số ô (tổng ô < 30), hoặc
- Chỉ tính bonus cho tay đang chạy (phương án A cũ), hoặc
- Món lắp ở tay nào thì thêm hiệu ứng riêng theo tay đó.

## 5. Dữ liệu và save

- `data/gear.json`: thêm `gear_slots_per_driver` (int > 0, hiện 8). Validate trong `_validate_gear()`.
- Save (bump `schema_version`, có migration): `gear_loadout: { driver_id: [gear_id, ...] }`, độ dài ≤ số ô.
- Migration từ save cũ: tự lắp mọi món đang sở hữu, ưu tiên tay đang chạy rồi tới các tay khác theo thứ tự sở hữu, để Power không đổi.
- Sanitize khi load: bỏ id không tồn tại, món không sở hữu, tay chưa sở hữu, món lắp trùng nhiều tay (giữ tay đầu), cắt theo số ô. Món bị loại về kho, không mất.
- Lắp/gỡ là giao dịch, rollback khi lưu lỗi, chặn khi `save_blocked` hoặc `phase == "save_error"`.
- Món mới nhận: đề xuất tự lắp vào ô trống của tay đang chạy để người chơi không mất bonus vì quên lắp (cần chốt).

## 6. API đề xuất (`game/game_state.gd`)

`gear_slots_per_driver()`, `gear_equipped_by(gear_id) -> String`, `equip_gear(driver_id, gear_id) -> bool`, `unequip_gear(driver_id, gear_id) -> bool`, `auto_equip() -> bool`; `gear_bonus()` chỉ tính món có trong `gear_loadout`. Chuỗi hiển thị qua `I18n.t()`.

## 7. UI (cần concept trước khi dựng)

- Trang Gear: thẻ món có nhãn `Đang lắp: <tên tay>`; popup chi tiết có Lắp/Gỡ.
- Trang Tay đua: lưới 8 ô dưới tay đang chọn; chạm ô trống mở bộ chọn; nút `Lắp tự động`.
- Hiện Power trước/sau khi lắp/gỡ.
- Soft Miniature, concept lưu `Design/Concepts/`, theo quy trình `CLAUDE.md`.

## 8. Nghiệm thu

- Một món không bao giờ ở hai tay; lắp thêm khi đủ 8 ô bị từ chối.
- Power = tổng món đã lắp ở mọi tay; đổi tay đua không đổi Power.
- Lắp/gỡ giữa cuộc đua không đổi `race_snapshot`.
- Save cũ migrate đúng, Power không đổi; lỗi lưu rollback.
- Test headless mới trong `tests/`, chạy với `RM_LANG=vi`; chạy `tools/i18n_check.py`.

## 9. Câu hỏi mở

1. Xử lý cảnh báo §4 theo hướng nào?
2. Món mới nhận có tự lắp không?
