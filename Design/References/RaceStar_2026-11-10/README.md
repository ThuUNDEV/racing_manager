# Race Star — bằng chứng quan sát trực tiếp

Ngày 10/11/2026, Google Play Games trên Windows, cửa sổ game đang chơi do người dùng chỉ ra. Người dùng chọn bản mới nhất làm mục tiêu; chưa đọc được version/build trong ứng dụng. Không coi số phiên bản trên iOS là phiên bản đã cài ở đây.

- `gear_overview.png`: tab túi, Standard/Elite Gear, giá x1/x10, INVENTORY, EQUIPPED 3/30.
- `standard_gear.png`: modal Standard Gear, Rare 85%, Epic 15%.
- `elite_gear.png`: modal Elite Gear, Epic 85%, Legendary 15%.
- `balaclava.png`: thẻ Balaclava +20 kiếm / +20 khiên, năm vị trí sao tối, 0/10. Panel kết quả đua phía trên không phải kết quả mở gói.

Ảnh chụp nguyên cửa sổ làm bằng chứng nội bộ, có tên tài khoản. Không đưa vào asset gameplay hoặc xuất bản cùng sản phẩm.

Chỉ điều hướng, cuộn và xem thông tin. Không thực hiện giao dịch, mở pack, nâng sao hay đổi đội hình. Do vòng đua tự chạy, tiền/gem và thứ hạng thay đổi giữa các ảnh. Những thay đổi đó không chứng minh nguồn nhận gear.

Quan sát chưa hoàn tất: cửa sổ game biến mất sau khi đọc một phần kho. Chưa xác minh coupon, toàn bộ catalog, ý nghĩa 3/30, tăng sao, phạm vi bonus hoặc xử lý đồ trùng. Xem [thiết kế v0.2](../../14_Driver_Equipment.md).

**Bổ sung từ người dùng sau phiên quan sát, ngày 10/11/2026:** mở gói nhận phụ kiện; món đã sở hữu quy đổi mảnh để nâng level; sở hữu phụ kiện tự tăng sức mạnh toàn đội; Equipped 3/30 nghĩa là sở hữu 3 trong tổng 30 phụ kiện; một coupon đổi một lượt mở gói. Các điểm này đã đưa vào thiết kế v0.3, thay các mục chưa rõ tương ứng ở ghi chú quan sát phía trên. Chưa xác nhận lượng mảnh, mảnh riêng/chung, bảng level, quan hệ sao/level hoặc coupon theo loại gói.

**Xác nhận tiếp từ người dùng, đưa vào v0.4:** mảnh riêng từng phụ kiện; nâng level chỉ tiêu mảnh; hai loại coupon Standard/Elite riêng; ưu tiên coupon trước gem. Không còn chờ xác minh các điểm này. Vẫn chưa có lượng mảnh khi trùng, bảng ngưỡng level, quan hệ sao/level, nguồn coupon và hành vi x10 khi chỉ có 1–9 coupon.

**Xác nhận và yêu cầu tiếp, đưa vào v0.5:** sao thể hiện level; số mảnh cần nâng và giới hạn level phải cấu hình được. Quan hệ sao/level đã rõ; bảng ngưỡng và trần level là dữ liệu cân bằng, không cần chép cố định số 10 hoặc 5 từ ảnh. Giá trị cụ thể, level khởi đầu, lượng mảnh trùng và chỉ số mỗi level chưa được chốt.

Lượt mở lại cùng ngày: đọc thêm các hàng thẻ dấu hỏi và thấy ranh giới viền xanh → tím; chưa đủ để đếm trọn danh mục. Sau khi cuộn kho, cửa sổ game tiếp tục biến mất. Hộp “An unexpected error has occurred” thuộc Google Play Games. Log cục bộ `Logs/Service.log` ghi lúc 15:10:27 +07:00: `One or more KiwiVM child process died: (2265029157 - Gpu)`, sau đó crosvm thoát lúc 15:10:34 với mã `0xe180001d`. Xác nhận tiến trình GPU giả lập bị lỗi; chưa xác định nguyên nhân gốc hoặc chứng minh thao tác cuộn là nguyên nhân. Dừng tự động điều khiển để tránh tái diễn; không tiếp tục mở game để thử lại. Không suy diễn các hàng chưa đọc thành cơ chế nâng sao.
