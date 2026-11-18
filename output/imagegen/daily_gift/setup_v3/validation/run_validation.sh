#!/usr/bin/env bash
set -euo pipefail
validation_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd -- "$validation_dir/../../../../.." && pwd)"
validation_root="$(mktemp -d /tmp/daily-gift-v3-validation.XXXXXX)"
mkdir -p "$validation_root/assets"
ln -s "$project_root/assets/daily_gift_v3" "$validation_root/assets/daily_gift_v3"
cp "$validation_dir/qa_assets.gd" "$validation_root/qa_assets.gd"
cat > "$validation_root/project.godot" <<'EOF'
config_version=5
[application]
config/name="Daily Gift asset QA"
[rendering]
renderer/rendering_method="gl_compatibility"
EOF
godot --headless --editor --path "$validation_root" --import > "$validation_root/import.log" 2>&1
godot --path "$validation_root" --rendering-method gl_compatibility --script qa_assets.gd
printf 'Validation output: %s/captures\n' "$validation_root"
