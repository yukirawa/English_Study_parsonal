# 試験向英語学習

Rust + Qt 6 / QML で作る Linux 向け英語学習アプリです。英文本文を入力すると単語を抽出し、各単語の上にある日本語訳欄に、学習者自身が訳を入力できます。自動翻訳は使いません。

## 特徴

- 英文本文の入力欄
- 単語の自動抽出（同じ綴りでも出現位置ごとに独立した訳を入力可能）
- 単語ごとの日本語訳入力欄
- 翻訳済み単語の表示
- 翻訳件数のカウント
- JSON 形式での保存・読み込み
- KDE Plasma 向けの Breeze 風デザイン
- ライト／ダークテーマ対応
- Tab / Shift+Tab での翻訳欄移動

## 必要環境

- Rust 1.88 以上
- Qt 6.10 以上
- Qt Quick / QML
- C++ ビルドツールチェーン（QtBridge の生成コード用）
- CMake 3.24 以上
- Ninja

Arch Linux の場合:

```bash
sudo pacman -S --needed rust qt6-base qt6-declarative cmake ninja
```

## ビルドと実行

このリポジトリの `qmake` は Qt 6 を指す必要があります。Qt 5 が優先されている環境では `QMAKE` を指定してください。

```bash
QMAKE=/usr/bin/qmake6 cargo run
```

通常は次のようにビルドします。

```bash
QMAKE=/usr/bin/qmake6 cargo build --release
```

起動:

```bash
QMAKE=/usr/bin/qmake6 cargo run --release
```

または直接:

```bash
./target/release/shikou-eigo
```

## テスト

```bash
QMAKE=/usr/bin/qmake6 cargo test
QMAKE=/usr/bin/qmake6 cargo clippy --all-targets -- -D warnings
```

QML の静的チェック:

```bash
/usr/lib/qt6/bin/qmllint src/Main.qml
```

## インストール

リリースビルドを作成した後、次のようにインストールできます。

```bash
install -Dm755 target/release/shikou-eigo ~/.local/bin/shikou-eigo
install -Dm644 packaging/io.github.yukirawa.ShikouEigo.desktop \
  ~/.local/share/applications/io.github.yukirawa.ShikouEigo.desktop
install -Dm644 assets/icons/hicolor/scalable/apps/io.github.yukirawa.ShikouEigo.svg \
  ~/.local/share/icons/hicolor/scalable/apps/io.github.yukirawa.ShikouEigo.svg
install -Dm644 packaging/io.github.yukirawa.ShikouEigo.metainfo.xml \
  ~/.local/share/metainfo/io.github.yukirawa.ShikouEigo.metainfo.xml
```

システム全体にインストールする場合は `~/.local` を `/usr/local` に置き換えてください。

## 使い方

1. 上部の「英文本文」欄に英文を入力します。
2. 入力した本文が下に単語単位で表示されます。
3. 各単語の上にある翻訳欄に日本語訳を入力します。同じ綴りでも出現位置ごとに独立して入力できます。
4. Tab / Shift+Tab で翻訳欄を移動できます。
5. 保存先を選んで JSON 形式で保存します。
6. 次回は同じ JSON ファイルを開くと続きから学習できます。

ショートカット:

- `Ctrl+N`: 新規
- `Ctrl+O`: 開く
- `Ctrl+S`: 保存
- `Ctrl+Shift+S`: 名前を付けて保存
- `Ctrl+Q`: 終了

## データ形式

保存データは人間が読める JSON です。

```json
{
  "format_version": 1,
  "source_text": "This is a test.",
  "translations": {
    "test#1": "テスト"
  }
}
```

`translations` のキーは `単語#出現順` です。同じ綴りの単語でも、出現位置ごとに別の訳を入力できます。

## 技術構成

- Rust 2024 edition
- Qt 6 / QML
- QtBridge
- serde / serde_json
- KDE Plasma のシステムカラースキームに追従する配色

Rust 側が状態と学習ロジックを持ちます。GUI は QML、Rust と QML の接続は QtBridge が生成する安全なバインディングで行います。手書きの C++ は含みません。

## ライセンス

GPL-3.0-only
