# Phủ asset theo phạm vi MVP

| Màn / hệ thống | Asset đã có | Nơi xem |
|---|---|---|
| Đua | Ba track/centerline, tám xe, marker, thanh vị trí, tài nguyên, nâng cấp hai cột, năm tab | Gallery → Đường đua; đổi track dưới khung đua |
| Tay đua | An/Bình/Chi; bust/avatars; card thường/chọn/khóa; icon huấn luyện | Gallery → Tay đua |
| Garage | Xe lớn, bốn icon bộ phận, cơ sở, card upgrade, trạng thái nút | Gallery → Garage |
| Giải đấu | Ba cúp, ba huy hiệu, thumbnail ba track, progress, xong/tiếp theo/khóa | Gallery → Giải đấu |
| Shop MVP | Hộp quà, túi tiền, nhận/đã nhận, icon cửa hàng | Gallery → Cửa hàng |
| Kết quả | Cúp/huy chương, cờ đích, bảng tám xe, thưởng, tiếp tục, overlay | Gallery → Kết quả; `components/result_dialog.tscn` |
| Offline | Túi tiền, clock/offline, thông tin thưởng, CTA, overlay | Gallery → Thu nhập vắng mặt; `components/offline_dialog.tscn` |
| Nhiệm vụ | Icon nhiệm vụ, progress, nhận/đang làm/đã nhận | Gallery → Nhiệm vụ |
| Cài đặt | Gear, nhạc, loa/mute, rung, giảm chuyển động, info, toggle, checkbox | Gallery → Cài đặt |
| Mùa giải | Cúp, huy hiệu thăng hạng, progress, phần thưởng, CTA | Gallery → Tổng kết mùa; `components/season_dialog.tscn` |
| Onboarding | Tay đua, chỉ dẫn, sáu bước, bàn tay tutorial, arrow, skip/CTA | Gallery → Hướng dẫn |
| Thông báo | Toast, empty state, close/back/next, check/lock/unlock, warning/help, confirm/cancel | `components/`, `ui/`, `icons/vector*` |
| VFX | Upgrade, reward burst, confetti, finish flash, coin spin, player ring | Gallery → Thư viện asset |
| Audio | UI, upgrade, reward, unlock, nhiệm vụ, finish, promotion, countdown, xe vượt, lốp; hai engine/two music loops | Gallery → Thư viện asset |
| Nhận diện/tải | App icon vector, splash, loading spinner | `branding/`, `ui/loading_spinner.svg` |

Tổng nội dung: ba track, ba tay đua, tám màu của một xe, tám props, tám vật phẩm thưởng, sáu huy hiệu/huy chương. Không cần art cho PvP, gacha, nhiều class xe hoặc IAP vì các phần đó ngoài phạm vi MVP.

Số tiền/chỉ số/kết quả trong gallery chỉ để duyệt UI; không ghi đè gameplay. Luật thắng thua và tiến trình tiếp tục thuộc code game.
