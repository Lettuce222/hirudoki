# ひるどき

日替わり弁当宅配サイト「ひるどき」のRailsアプリケーションです。

## Requirements

- Ruby 3.4.12
- PostgreSQL 18
- Bundler 4.1.0（Gemfile.lock）

バージョン判断は [ADR 0008](docs/adr/0008-pin-runtime-and-dependency-versions.md)、テスト方針は [ADR 0009](docs/adr/0009-use-rspec-capybara-and-red-green-refactor.md) を参照してください。

## Setup

```sh
bundle install
bin/rails db:prepare
```

macOSのHomebrewでは `brew install ruby@3.4 postgresql@18` で用意できます。既存Rubyとの競合を避け、必要ならコマンド実行時に `PATH=/opt/homebrew/opt/ruby@3.4/bin:/opt/homebrew/bin:$PATH` を指定します。`bundle config set --local path vendor/bundle` でローカルGemをプロジェクト内に隔離できます。

PostgreSQLは起動済みである必要があります。Homebrewを使う場合は次のコマンドで起動できます。

```sh
brew services start postgresql@18
```

## Development

RailsとTailwind CSSのwatch processを起動します。

```sh
bin/dev
```

## Test and quality checks

```sh
bundle exec rspec
bundle exec rubocop --no-parallel --cache false
bundle exec brakeman --no-pager
```

system specを含む実行前に `RAILS_ENV=test bin/rails db:prepare` と `bin/rails tailwindcss:build` を実行します。初回はSelenium ManagerによるChrome・driverの取得にネットワークが必要です。詳しいTDD手順は [テスト運用](docs/testing/tdd.md) を参照してください。

## Architecture decisions

重要な意思決定と代替案は [`docs/adr/`](docs/adr/) に記録します。

## Work log

課題に関する全作業を `bin/work-log` で記録します。開始・中断・終了の運用は [`docs/work-log/README.md`](docs/work-log/README.md)、提出用の集計は [`docs/work-log/summary.md`](docs/work-log/summary.md) を参照してください。エージェントは [`AGENTS.md`](AGENTS.md) と [work-log skill](.agents/skills/work-log/SKILL.md) に従います。

## Requirement traceability

PDFの要件・受入確認方法・Linearチケットの対応は [要件対応表](docs/requirements/traceability.md) を参照してください。実装後のテスト・本番確認の証跡も同表の要件IDと関連付けます。

## Deployment

RenderのBlueprintで `render.yaml` を読み込みます。buildは `bin/render-build.sh`、pre-deployは `bin/render-pre-deploy.sh`、起動はPumaです。`/up` はDB接続を含むヘルスチェックです。DB接続情報とSECRET_KEY_BASEはRenderが生成・注入します。

本番URL: https://hirudoki.onrender.com/ 。検証記録は [Walking Skeleton](docs/testing/walking-skeleton.md) を参照してください。

Active Storageの3テーブルは、画像メタデータ・添付関連・variant管理のために追加しています。PDF指定の業務8テーブルの代わりではありません。現段階の画像配線確認では業務用の仮テーブルは作りません。

認証された本番シェルから `bin/rails runner script/storage-smoke.rb` を実行すると、同じblobを再利用して保存済み画像を検証し、表示用pathとチェックサムを出力します。これは公開のアップロード機能ではありません。後続の弁当管理ではPNG/JPEG/WebP・5MB以下の入力制約と画像なし時の代替表示を実装します。

Deviseは依存を導入済みで、利用者・管理者の認証モデルと画面は後続タスクで実装します。
