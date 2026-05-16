# プロジェクト概要

2026/05/11 開催の勉強会「[AI時代のFlutter開発スペシャル](https://classmethod.connpass.com/event/389468/)」で発表したデモアプリ。
詳細は [README.md](README.md) を参照。

## 技術スタック

- Flutter SDK 3.41.5（`.fvmrc` で固定）
- ターゲットプラットフォーム: macOS のみ

## よく使うコマンド

`fvm` 経由で `.fvmrc` 指定の Flutter SDK を使う。

```bash
# アプリの実行
fvm flutter run -d macos

# テストの実行
fvm flutter test

# コード解析
fvm flutter analyze

# 依存パッケージの取得
fvm flutter pub get
```

## ディレクトリ構成

- `lib/` — アプリケーションコード（ページごとに1ファイル）
- `test/` — テストコード
- `macos/` — macOS プラットフォーム固有コード

## コーディング規約

- `analysis_options.yaml` の lint ルール（flutter_lints）に従う
- `fvm flutter analyze` で警告が出ないようにする
