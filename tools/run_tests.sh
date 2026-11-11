#!/usr/bin/env bash
# Chạy toàn bộ test headless. Dùng cho máy dev và CI.
# Biến môi trường GODOT trỏ tới tệp thực thi Godot (mặc định: godot trong PATH).
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

echo "== Import project (cập nhật class cache) =="
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

fail=0
for t in big_number_test economy_test data_test golden_test sim_test traffic_test garage_test gear_test gear_ui_test state_test upgrade_test boot_test; do
  echo ""
  echo "##### $t #####"
  out="$("$GODOT" --headless --path . -s "res://tests/$t.gd" 2>&1)"
  code=$?
  printf '%s\n' "$out" | sed 's/\x1b\[[0-9;]*m//g'
  # Godot có thể thoát 0 dù script lỗi cú pháp: kiểm tra thêm nội dung.
  if [ $code -ne 0 ] || printf '%s' "$out" | grep -Eq 'SCRIPT ERROR|Parse Error|  FAIL '; then
    echo ">>> $t: THẤT BẠI (exit $code)"
    fail=1
  else
    echo ">>> $t: đạt"
  fi
done

if [ $fail -ne 0 ]; then
  echo ""; echo "CÓ TEST THẤT BẠI"; exit 1
fi
echo ""; echo "TẤT CẢ TEST ĐẠT"
