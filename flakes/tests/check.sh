#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PYTHONDONTWRITEBYTECODE=1
fish -n assets/config/fish/config.fish
find assets/config/hypr -name "*.lua" -exec luac -p {} \;
python3 -m unittest discover -s tests -v
PYTHONPATH="$PWD/assets/config/quickshell:$PWD/assets/config/quickshell/services" \
  python3 -m unittest discover -s assets/config/quickshell/tests -q
CARGO_TARGET_DIR="$PWD/.check-target" cargo test --locked --manifest-path assets/theme-manager/Cargo.toml
