#!/bin/bash
# mini-key 設定アプリをビルドして .app バンドルを作る。
# CLI(ch57x-keyboard-tool) のビルド → .app 組み立て → 署名 まで一括。
set -e
# Homebrew の場所（Apple Silicon=/opt/homebrew, Intel=/usr/local）を両対応
if command -v brew >/dev/null 2>&1; then export PATH="$(brew --prefix)/bin:$PATH"; fi
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# 必要ツールの確認
for t in cargo swiftc; do
    if ! command -v "$t" >/dev/null 2>&1; then
        echo "エラー: '$t' が見つかりません。" >&2
        [ "$t" = cargo ]  && echo "  → brew install rust" >&2
        [ "$t" = swiftc ] && echo "  → xcode-select --install" >&2
        exit 1
    fi
done

DIR="$(cd "$(dirname "$0")" && pwd)"        # .../gui
REPO="$(cd "$DIR/.." && pwd)"               # リポジトリ直下
APP="$DIR/build/mini-key.app"
TOOL="$REPO/ch57x-keyboard-tool/target/release/ch57x-keyboard-tool"

echo "==> CLI ツールをビルド（未ビルドのときのみ）"
if [ ! -x "$TOOL" ]; then
    ( cd "$REPO/ch57x-keyboard-tool" && cargo build --release )
fi

echo "==> .app を組み立て"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$DIR/Info.plist"   "$APP/Contents/Info.plist"
cp "$DIR/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$TOOL"             "$APP/Contents/Resources/ch57x-keyboard-tool"   # CLI を同梱

echo "==> Swift コンパイル"
swiftc -O -o "$APP/Contents/MacOS/mini-key" "$DIR/MiniKeyGUI.swift" "$DIR/main.swift"

echo "==> アドホック署名"
codesign --force --deep --sign - "$APP" 2>/dev/null || echo "(署名スキップ)"

echo "==> 完了: $APP"
