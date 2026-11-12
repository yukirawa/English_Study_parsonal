#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
QMAKE="${QMAKE:-/usr/bin/qmake6}"
APP_ID="io.github.yukirawa.ShikouEigo"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$REPO_DIR"

echo "==> Building release binary with Rust + Qt 6"
QMAKE="$QMAKE" cargo build --release

BIN="$REPO_DIR/target/release/shikou-eigo"
[[ -x "$BIN" ]] || { echo "release binary not found: $BIN" >&2; exit 1; }

echo "==> Installing to $PREFIX"
install -d "$PREFIX/bin"
install -d "$PREFIX/share/applications"
install -d "$PREFIX/share/icons/hicolor/scalable/apps"
install -d "$PREFIX/share/metainfo"

install -m 755 "$BIN" "$PREFIX/bin/shikou-eigo"
install -m 644 "packaging/$APP_ID.desktop" "$PREFIX/share/applications/$APP_ID.desktop"
install -m 644 "assets/icons/hicolor/scalable/apps/$APP_ID.svg" \
  "$PREFIX/share/icons/hicolor/scalable/apps/$APP_ID.svg"
install -m 644 "packaging/$APP_ID.metainfo.xml" "$PREFIX/share/metainfo/$APP_ID.metainfo.xml"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$PREFIX/share/applications" || true
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$PREFIX/share/applications" || true
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$PREFIX/share/applications" || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f "$PREFIX/share/icons/hicolor" || true
fi

echo "==> Installed successfully"
echo "    Binary:   $PREFIX/bin/shikou-eigo"
echo "    Desktop:  $PREFIX/share/applications/$APP_ID.desktop"
echo "    Metadata: $PREFIX/share/metainfo/$APP_ID.metainfo.xml"
