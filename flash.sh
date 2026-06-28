#!/bin/bash
# コマンドラインから本体に設定を書き込む（GUIを使わない場合）。
#   使い方:  sudo ./flash.sh [設定ファイル.yaml]
# macOS では HID インターフェースの取得に root 権限が必要なため sudo 必須。
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$DIR/ch57x-keyboard-tool/target/release/ch57x-keyboard-tool"
CONFIG="${1:-$HOME/Library/Application Support/mini-key/keypad.yaml}"

if [ ! -x "$BIN" ]; then
    echo "CLI が未ビルドです。先に: ( cd ch57x-keyboard-tool && cargo build --release )" >&2
    exit 1
fi
if [ ! -f "$CONFIG" ]; then
    echo "設定ファイルが見つかりません: $CONFIG" >&2
    echo "keypad.example.yaml をコピーして編集してください。" >&2
    exit 1
fi
exec "$BIN" upload "$CONFIG"
