# Workshop GP — Theme directions v1

Bốn demo nhạc cụ tổng hợp nguyên bản theo yêu cầu ngày 14/11/2026. Đây là bản phác thảo sáng tác/phối khí để nghe và chọn hướng; guitar, bass, keyboard và trống đều được tổng hợp bằng DSP, chưa phải bản thu nhạc cụ thật hay master phát hành. Chưa thay nhạc đang chạy trong game.

| Bản | Tempo | Ý tưởng phối khí |
| --- | --- | --- |
| A — Sporty Electronic | 124 BPM | Kick bốn nhịp, synth bass, arpeggio, lead sáng; năng động và hiện đại. |
| B — Electro Funk | 112 BPM | Bass đảo phách, guitar ngắt tiếng, electric keys, trống điện tử; vui và có độ nảy. |
| C — Electronic Rock | 138 BPM | Power chord guitar tổng hợp méo tiếng hai bên stereo, bass, snare mạnh, synth lead; cạnh tranh và tăng tốc. |
| D — Upbeat Groove | 104 BPM | Bass groove, keyboard, tiếng pluck và shaker nhẹ; cảm giác phát triển, nâng cấp. |

Mỗi bản gồm 20 ô nhịp: intro 2 ô, chủ đề 8 ô, break 2 ô, biến tấu 6 ô và kết 2 ô; có đuôi hiệu ứng 1,4 giây. Các bản có tempo và hòa âm riêng, khai thác motif lên/xuống liên quan để so sánh hướng phối khí. WAV stereo 44.100 Hz, 16-bit. Có fade đầu/cuối cho bản nghe thử; các file này chưa được biên tập thành loop liền mạch.

Mở `listen.html` để nghe từng bản hoặc `ABCD_comparison.wav` để nghe liên tiếp A → B → C → D, cách nhau 1 giây. Trình nghe tự dừng bản cũ khi bật bản khác. `manifest.json` ghi độ dài, peak và RMS thực tế.

Tái tạo bằng `python render_demos.py` (cần numpy và scipy). Không dùng sample ngoài, dịch vụ tạo nhạc hay lời hát.
