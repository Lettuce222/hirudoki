# ひるどき

日替わり弁当宅配サイト「ひるどき」のRailsアプリケーションです。

## Requirements

- Ruby 3.4.13（`.ruby-version`）
- PostgreSQL 18
- Bundler 4.1.0（`Gemfile.lock`）

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

認証された本番シェルから `bin/rails runner script/storage-smoke.rb` を実行すると、同じblobを再利用して保存済み画像を検証し、表示用pathとチェックサムを出力します。

## 確認用データとテストアカウント

開発環境のセットアップ後に、次のコマンドで確認用データを投入します。

```sh
bin/rails runner db/seeds/demo.rb
```

| 役割 | ログイン画面 | 開発環境のメールアドレス | 開発環境のパスワード |
|---|---|---|---|
| 利用者 | `/users/sign_in` | `demo-user@example.test` | `hirudoki-local-user` |
| 管理者 | `/admin/sign_in` | `demo-admin@example.test` | `hirudoki-local-admin` |

和食・洋食・中華・ヘルシーの日替わり弁当と配達エリアを登録します。実行日の日本時間を基準に、当日から14日先まで各日4タイプの献立を用意します。利用者には月曜から金曜までの定期注文設定を登録します。

- 利用者でログインすると献立一覧が開きます。提供日で絞り込み、受付中の献立から注文できます。
- 管理者の「定期注文生成」では、受付期間内の平日を指定して注文を生成できます。同じ日を再度指定すると、生成済みの設定がスキップされたことを確認できます。

本番ではRenderのシェルで、提出用として用意した管理者・利用者のメールアドレスとパスワードをそれぞれ `SEED_ADMIN_EMAIL`、`SEED_ADMIN_PASSWORD`、`SEED_USER_EMAIL`、`SEED_USER_PASSWORD` に設定し、`RAILS_ENV=production bin/rails runner db/seeds/demo.rb` を実行します。本番のログイン情報は提出時に別途共有します。

動作確認期間が変わったら、このコマンドを再実行して新しい提供日を補います。作成済みのアカウントのパスワード・既存の定期設定・登録済みの同日同タイプの献立はそのまま使います。既存献立の弁当が非販売のときは、実行結果に対象の日付とタイプを表示します。

## 指定以外のテーブル

- `registration_invitations` はメール確認前の招待と送信日時を保持するために追加しています。登録が済んだ招待を利用者に紐づけ、リンクの再利用を防ぎます。
- `active_storage_blobs`、`active_storage_attachments`、`active_storage_variant_records` は、弁当画像のメタデータ、弁当との関連、変換済み画像をRails標準のActive Storageで管理するために追加しています。

## 利用者登録とメール

利用者はメールのリンクを開いてから氏名・電話番号・パスワードを登録します。メール確認が済むまでは registration_invitations に招待を記録します。リンクには発行時の sent_at を含め、招待の最終送信日時と照合します。再送時は同じ招待の行をロックし、送信に成功すると新しいリンクだけが使えるようになります。登録と同じトランザクションで招待に利用者を紐づけ、その後はリンクを使えなくします。招待の created_at と sent_at に初回発行と最終送信の日時が残り、利用者の created_at から登録日時を確認できます。リンクは30分有効、同一アドレスへの再送は1分後からです。登録用パスワードは半角英数字・記号で6〜72文字とし、空白は使えません。

送信元の MAIL_FROM はアプリの起動時に読み込むため、変更後は再起動してください。未設定時の送信元は`ひるどき <registration@example.test>`です。開発時のメールは tmp/mail に保存します。本番では Render の Environment に MAIL_FROM（確認済みの送信元）、SMTP_USERNAME、SMTP_PASSWORD を設定します。初期設定は smtp-relay.brevo.com の587番ポートでSTARTTLSを使います。別の配信先を使う場合は SMTP_ADDRESS と SMTP_PORT で指定できます。メール内のURLは Render の RENDER_EXTERNAL_HOSTNAME を使います。

トップの弁当写真は[毒島みるく撮影の鮭のり弁当（CC0）](https://commons.wikimedia.org/wiki/File:Nori_bento_with_grilled_salmon_lunch_box_of_Lawson.jpg)です。

## 管理者ログイン

管理用URLは `/admin` です。管理者を作成するには、対象環境で `SEED_ADMIN_EMAIL` と `SEED_ADMIN_PASSWORD` を設定して `bin/rails db:seed` を実行します。管理者の氏名は `SEED_ADMIN_NAME` で指定でき、省略時は「管理者」です。シードは同じメールアドレスの管理者がいれば既存の認証情報を保ちます。初期化後はシード用のパスワードを環境から外せます。
