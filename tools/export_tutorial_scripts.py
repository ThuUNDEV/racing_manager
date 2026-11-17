"""Export one reviewable Vietnamese script per runtime tutorial definition."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOALS = {
    'A1_welcome': ('Nhận đội', 'Biết Linh là ai và mục tiêu cùng xây dựng đội đua.'),
    'A2_car': ('Theo dõi cuộc đua', 'Nhận ra xe của đội, hiểu xe tự đua và biết xem hạng.'),
    'A3_income': ('Nguồn tiền', 'Tìm ô tiền mỗi giây, hiểu các yếu tố tác động, tự nâng doanh thu và quan sát số tăng ngay.'),
    'A4_engine': ('Nâng Động cơ đầu tiên', 'Mua một cấp Động cơ và hiểu nâng cấp áp dụng từ lượt sau.'),
    'A6_result': ('Kết quả cuộc đua', 'Phân biệt tiền thưởng lượt đua với cúp dành cho top 3.'),
    'A7_race2': ('Sức mạnh đội', 'Nhìn thấy nâng cấp được áp dụng và hiểu ý nghĩa Power.'),
    'U2_league': ('Nâng cấp bằng cúp', 'Tự dùng cúp mua một nâng cấp tốc độ, xem chỉ số trước–sau và hiểu áp dụng từ lượt tiếp theo.'),
    'U4_shop': ('Mở phụ kiện đầu tiên', 'Dùng coupon mở đúng một gói và hiểu phụ kiện tăng Power cho đội.'),
    'U3_bag': ('Quản lý phụ kiện', 'Biết Túi giữ phụ kiện, đồ trùng thành mảnh và đủ mảnh thì nâng cấp.'),
    'U5_drivers': ('Tuyển tay đua', 'Dùng coupon tuyển một tay đua và biết nơi xem, chọn người lái.'),
    'U6_garage': ('Chọn xe', 'Hiểu giá trị xe mới, nâng cấp riêng từng xe và nơi đổi diện mạo.'),
    'U7_class': ('Chọn bộ môn', 'Hiểu mỗi bộ môn có chỉ số ưu tiên để định hướng đầu tư.'),
    'C1_offline': ('Thu nhập khi vắng mặt', 'Hiểu tỷ lệ và giới hạn thời gian tích lũy thu nhập offline.'),
    'C2_trophy': ('Đủ cúp để đầu tư', 'Nhắc dùng số cúp đang đủ mua nâng cấp.'),
    'C4_star': ('Mốc sao doanh thu', 'Hiểu lợi ích tăng doanh thu ở mốc cấp gần nhất.'),
    'C5_shards': ('Đủ mảnh nâng phụ kiện', 'Nhắc nâng đúng món phụ kiện đã đủ mảnh.'),
    'C6_weaker': ('Tay đua mạnh hơn', 'Nhắc xem tay đua sở hữu có tổng chỉ số tốt hơn người đang lái.'),
}
FINISH = {
    'revenue_upgrade_and_acknowledge': 'Mua một lần nâng Ticket Marketing, thấy số tiền mỗi giây trước–sau và xác nhận kết quả.',
    'read_all': 'Đọc và xác nhận hết các nhịp thoại.',
    'engine_level_1_and_acknowledge': 'Động cơ đạt ít nhất cấp 1, rồi đọc và xác nhận câu sau nâng cấp.',
    'acknowledge_result': 'Đọc hai phần kết quả và phần thưởng, rồi đóng bảng kết quả.',
    'perform_action_and_acknowledge': 'Thực hiện thao tác được hướng dẫn thành công, rồi xác nhận kết quả; không yêu cầu mua thêm lần nữa.',
    'acknowledge_or_condition_resolved': 'Xác nhận mẹo, hoặc tình huống được giải quyết khi mẹo còn đang hiện.',
}


def main():
    manifest = json.loads((ROOT / 'data/tutorial.json').read_text())
    vi = json.loads((ROOT / 'i18n/vi.json').read_text())
    destination = ROOT / 'Design/Tutorials'
    destination.mkdir(exist_ok=True)
    index = ['# Các tutorial độc lập',
             'Mỗi tutorial có một file dữ liệu chạy thật và một bản kịch bản để đọc riêng. Bộ điều phối chọn thời điểm; overlay chỉ lo hiển thị và tương tác. ID cũ được giữ để tương thích save.',
             'Tiến độ từng tutorial lưu riêng: chưa bắt đầu → đang chạy (stage, nhịp thoại) → hoàn thành. Vừa hiện lời thoại chưa được tính hoàn thành. Mở gói xong chuyển sang xác nhận, không chỉ nút mua tiếp. Với tutorial dạy một cơ chế, người chơi phải thực hiện thao tác thật và quan sát kết quả; bấm Tiếp chỉ chuyển lời thoại, không thay cho thao tác.',
             '| ID | Tutorial | Mục đích |\n|---|---|---|']
    for group in ['onboarding', 'features', 'tips']:
        for uri in manifest[group]:
            relative = uri.removeprefix('res://')
            lesson = json.loads((ROOT / relative).read_text())
            id = lesson['id']
            title, goal = GOALS[id]
            trigger = lesson['trigger']
            if 'completed_races' in trigger:
                start = f"Sau {trigger['completed_races']} lượt hoàn tất, hướng dẫn ở `{trigger['tab']}`."
                if trigger.get("wait"):
                    start += " Chờ đủ cúp mua nâng cấp được hướng dẫn."
            elif 'after' in trigger:
                start = f"Sau tutorial `{trigger['after']}`."
                if trigger.get('wait'):
                    start += f" Chờ điều kiện `{trigger['wait']}`."
            else:
                start = f"Điều kiện `{trigger.get('when', trigger.get('condition', ''))}`."
            out = [f'# {id} — {title}', f'**Mục đích:** {goal}', f'**Bắt đầu:** {start}',
                   '**Hoàn thành:** ' + FINISH[lesson['completion']],
                   f'**Nguồn chạy thật:** [{relative}](../../{relative}).',
                   '## Kịch bản']
            for stage, spec in lesson['stages'].items():
                variants = spec.get('variants', {'': spec})
                for variant, text_spec in variants.items():
                    out.append(f'### Stage {stage}' + (f' — {variant}' if variant else ''))
                    key = text_spec['text'].removeprefix('@')
                    for page, text in enumerate(vi[key].split('\n\n')):
                        out.append(f'**Nhịp {page + 1}:**\n\n> {text}')
                    out.append(f'Khóa lời thoại: `{key}`.')
            out += ['## Kiểm tra riêng',
                    f'`godot --path . -s res://tools/preview_tutorial_story.gd -- --lesson={id}`',
                    'Bản thử dùng save riêng, chuẩn bị sẵn điều kiện của tutorial này. Các số `%s`, `%d` được thay bằng trạng thái thật.',
                    'Với tutorial tính năng, thêm `--from=shop` (hoặc `bag`, `league`, `team`, `race`) để kiểm tra tự kích hoạt và dẫn đường từ tab khác.',
                    '## Sửa và đồng bộ',
                    'Sửa mục tiêu, điều kiện, stage hoặc mục tiêu chỉ dẫn trong file JSON tương ứng; sửa lời trong `i18n/vi.json` theo khóa trên. Chạy `python3 tools/export_tutorial_scripts.py` để cập nhật tài liệu.']
            (destination / f'{id}.md').write_text('\n\n'.join(out) + '\n')
            index.append(f'| [{id}]({id}.md) | {title} | {goal} |')
    index += ['## Thứ tự và điều phối',
              'Phần làm quen chạy theo thứ tự trong danh sách `onboarding` của `data/tutorial.json`. Các tutorial tính năng theo mốc 2/3/4/5/7/10 lượt. Mẹo chỉ hiện khi đúng tình huống. Mỗi lúc chỉ một tutorial chiếm callout.',
              'Tutorial tính năng tự xuất hiện từ bất kỳ tab nào khi đủ điều kiện, sau khi đóng modal hoặc bảng kết quả. Bàn tay dẫn tới đúng tab; Garage có thêm bước Đội → Garage. Chỉ hoàn tất dẫn đường khi tới đúng nơi. Đọc mục đích rồi thì không lặp khi vào tab. Rời tutorial đang dở sẽ được dẫn trở lại, giữ nguyên tiến độ.',
              'Cơ chế game (mua, trao quà, mô phỏng đua) vẫn dùng logic thật, không nằm trong kịch bản. Đổi phần thưởng hoặc điều kiện game cần kiểm tra logic tương ứng.',
              '## Kiểm tra',
              '`tutorial_lessons_test.gd` kiểm tra từng định nghĩa, chạy riêng, save giữa thao tác, save sau mở gói, không chi tiền lặp và tương thích save cũ. Các test tutorial hiện có vẫn kiểm tra luồng toàn game.']
    # Keep the comparison table contiguous in Markdown.
    intro = '\n\n'.join(index[:3])
    table = '\n'.join(index[3:21])
    rest = '\n\n'.join(index[21:])
    (destination / 'README.md').write_text(intro + '\n\n' + table + '\n\n' + rest + '\n')


if __name__ == '__main__':
    main()
