# TDDと確認の運用

## LET-12: テスト構成のTODO

- [x] 実ブラウザのsystem specを追加し実行失敗を確認（matcher誤用とBrave/driver不一致を検出。業務実装のRedとは別の基盤診断）
- [x] Capybaraとheadless Chromeを設定してPC・モバイルを実行（Green）
- [x] setupを整理し、全3specがGreenのまま（Refactor）
- [x] 同じsystem specをGitHub Actions上で実行（[CI 43836448516](https://github.com/Lettuce222/hirudoki/actions/runs/43836448516)、コミットdc81bb5、全4ジョブ成功）

確認日: 2026-11-16。Ruby 3.4.12 / PostgreSQL 18 / headless Chromeでローカル3 examples, 0 failures。CIでもtest・lint・scan_ruby・scan_jsが成功。Braveのdriver不一致はChromeへ統一して解消した。

## 仕様ごとの進め方

1. 対応表の要件IDと対象チケットを確認し、正常系・異常系・境界値のTODOリストをチケットへ書く。
2. 最小の振る舞いを示すテストを1件書いて実行する。意図した理由の失敗を確認してから実装する。依存不足などの失敗は業務テストのRedと区別する。
3. そのテストを通す最小の実装をする。必要に応じて仮実装・三角測量を使い、未検証の一般化を避ける。
4. Greenを保ちながら重複・責務・名前を整理する。Redの途中で別機能を広げない。
5. TODOを一つずつ繰り返す。model specで制約と複数モデルの業務、request specでHTTP/認可、system specで画面操作を検証する。
6. 各スライスで入力エラー・認可・必要な競合条件・PC/モバイルを揃え、開発確認→本番反映→本番スモーク確認まで終えてDoneにする。

PDFで指定されたmodel specとsystem specは実業務の実装とともに書く。requestだけで置き換えない。中身のないモデルをテスト種別を満たす目的で作らない。

## テストデータ・時刻・ブラウザ

- FactoryBotの明示的なfactoryを用意する。通常は必要な関連だけ作成し、本番seedには依存しない。
- transactional fixturesを使う。競合テストは別接続と明示的な後始末を設計する。
- Railsのtime helpersで固定時刻を使い、実時間待ちやsleepに依存しない。
- system specは常にSeleniumのheadless Chrome。Turbo/Stimulusを含む実際のJavaScriptを動かす。
- CI・ローカルともChromeを使う。Selenium Managerが対応するブラウザとドライバーを解決する。既存Braveはバージョン判定とdriverに不一致が出たため標準にはしない。
- PC 1280×900、モバイル390×844を基準にし、追加の崩れ確認も各スライスで行う。初回Chrome/driver取得はネットワークが必要。
- ローカルとCIで `RAILS_ENV=test bin/rails db:prepare`、`bin/rails tailwindcss:build`、`bundle exec rspec` を共通実行する。
