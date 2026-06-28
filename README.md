# mini-key-mac

3キー＋ノブの安価なマクロパッド **3KV1（USB ID `0x514c:0x8851`）** を **macOS** から設定するためのツール一式です。付属の設定ソフトが Windows 専用（`MINI KeyBoard.exe`）で Mac から設定できない問題を解決します。

> A macOS configurator (CLI + native GUI) for the cheap "3 keys + 1 knob" macro pad
> **3KV1 (USB `0x514c:8851`)**, whose bundled config tool is Windows-only.

<!-- スクリーンショットを置く場合: docs/screenshot.png -->

## できること

- 各キー（KEY1/2/3）とノブ（左回し・押し込み・右回し）に、キー操作・ショートカット・メディアキーを割り当て
- 設定は**デバイス本体のフラッシュに保存**されるので、書き込み後はどの PC でもそのまま動作（ソフト常駐不要）
- **ネイティブ GUI アプリ**（SwiftUI）とコマンドライン（YAML）の 2 通り
- **プロファイル**機能：用途別の割り当てセットを複数保存してワンタッチ切替

## 動作環境

- Apple Silicon Mac（Intel はソースからビルドすれば可）
- 対象デバイス: USB `0x514c:0x8851`（3 キー + 1 ノブ。製品名 "3KV1"）

## セキュリティについて

このデバイスは **USB HID（キーボード類）としてのみ**振る舞い、ストレージやネットワークを偽装しません。挿しただけで任意コードが実行されることは構造上ありません（macOS に autorun は無い）。唯一の本質的リスクは「キーボードである以上キー入力を送れる」点（BadUSB）で、これは全キーボード共通です。

## ビルド

```sh
# 1) 前提ツール（未導入なら）
xcode-select --install     # swiftc / clang / git
brew install rust          # cargo（CLI のビルド用）

# 2) クローンしてビルド
git clone https://github.com/octopusv/mini-key-mac.git
cd mini-key-mac
bash gui/build.sh          # CLI ビルド → .app 組み立て → 署名 を一括
# => gui/build/mini-key.app が生成されます

# 3) 起動
open gui/build/mini-key.app
```

Apple Silicon / Intel どちらでも、そのマシンでビルドすれば動きます。

GUI を使わず CLI だけ使う場合:

```sh
( cd ch57x-keyboard-tool && cargo build --release )
```

## 使い方（GUI）

1. `gui/build/mini-key.app` を開く（必要ならアプリケーションフォルダへドラッグ）
2. 各キー／ノブをドロップダウンで選ぶ（一覧に無い操作は「カスタム…」で `cmd-shift-4` のように入力可）
3. **「本体に書き込む」** → macOS の管理者パスワードダイアログで認証 → 反映
4. プロファイルを切り替えれば用途別の割り当てを一括変更

設定・プロファイルは `~/Library/Application Support/mini-key/`（`keypad.yaml` / `profiles.json`）に保存されます。

## 使い方（CLI）

```sh
cp keypad.example.yaml keypad.yaml   # 編集して割り当てを記述
sudo ./flash.sh keypad.yaml          # 本体へ書き込み（HID 取得に root 必須）
```

利用可能なキー名一覧:

```sh
./ch57x-keyboard-tool/target/release/ch57x-keyboard-tool show-keys
```

## 仕組み / このデバイス特有の注意

土台は [`kriomant/ch57x-keyboard-tool`](https://github.com/kriomant/ch57x-keyboard-tool)。`0x514c:0x8851` はこのツールが標準対応する機種と異なり、実機での検証から以下が判明しています（`ch57x-keyboard-tool/` に取り込んだ変更点）:

- 同じ `0x514c` でも 16 キー版(`0x8850`)の `0xfd` プロトコルではなく、**従来の `0xfe`（`ch57x-1` / k884x）プロトコル**で動作
- 内部キー ID: ボタン = `1/2/3`、ノブ ccw/press/cw = `16/17/18`
- 書き込み用 OUT エンドポイント = `0x02`（既定の `0x04` ではない。自動フォールバックを追加）

変更箇所: `ch57x-keyboard-tool/src/config.rs`（`0x514c:0x8851` を `ch57x-1` として登録）、`src/main.rs`（エンドポイント自動探索）。

## ライセンス / クレジット

- 本リポジトリ: MIT（`LICENSE`）
- `ch57x-keyboard-tool/`: [kriomant/ch57x-keyboard-tool](https://github.com/kriomant/ch57x-keyboard-tool) の改変版（MIT OR Apache-2.0、原ライセンスは `ch57x-keyboard-tool/LICENSE`）

GUI アプリのアイコン・SwiftUI コードは本リポジトリのオリジナルです。
