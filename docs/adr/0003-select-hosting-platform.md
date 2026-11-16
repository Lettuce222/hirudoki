# ADR 0003: ホスティング基盤を選定する

- Status: Accepted
- Date: 2026-11-16
- External information checked: 2026-11-16

## Context

提出物には、採点者が動作確認できるURL、PostgreSQLの永続データ、弁当画像の永続ストレージが必要である。デプロイ経験のあるサービスはない。有料の最小プランは利用できる。

30時間の制約があるため、最安値よりも次の条件を優先する。

1. RailsとPostgreSQLの初回デプロイが短時間で完了する。
2. GitHubから継続的にデプロイできる。
3. 画像を少ない構成要素で永続化できる。
4. マイグレーション、環境変数、ログ、TLSを扱いやすい。
5. 採点時にスリープや期限切れで停止しない。
6. 構成と判断をリポジトリから説明できる。

## Decision

ホスティング基盤としてRenderを採用する。

想定構成は次のとおり。

- Render paid Web Service
- Render PostgreSQL
- Rails Active Storage用のRender Persistent Disk
- Singaporeリージョン
- `render.yaml` による構成管理
- paid Web Serviceのpre-deploy commandによるマイグレーション

概算はWeb Serviceが月額約7 USD、PostgreSQLが月額約6 USD、Persistent Diskが1 GBあたり月額0.25 USDで、合計約13.25 USDからとなる。実際の請求は利用期間、税、通信量などに依存する。

## Options Considered

### Render

#### Advantages

- Rails 8とPostgreSQLの公式デプロイ手順がある。
- GitHub連携、自動デプロイ、TLS、ログ、環境変数が揃っている。
- `render.yaml` でWeb ServiceとPostgreSQLをコード化できる。
- Persistent Diskを `/opt/render/project/src/storage` にマウントし、Active Storageの画像を外部ストレージ契約なしで永続化できる。
- paid Web Serviceではpre-deploy commandを利用できる。

#### Disadvantages

- Persistent Diskを付けると単一インスタンスに制限され、ゼロダウンタイムデプロイが無効になる。
- Persistent Diskにはbuild、pre-deploy、one-off jobからアクセスできない。
- 最小プランのメモリには余裕が少ない。

今回の単一インスタンスの試験用アプリでは、数秒のデプロイ停止と水平スケール不可は許容できると判断した。

Sources:

- [Deploy a Rails 8 App on Render](https://render.com/docs/deploy-rails-8)
- [Render Blueprints](https://render.com/docs/infrastructure-as-code)
- [Persistent Disks](https://render.com/docs/disks)
- [Render Pricing](https://render.com/pricing)

### Railway

#### Advantages

- GitHubからの自動デプロイに対応する。
- PostgreSQL、Persistent Volume、S3互換Storage Bucketを同じプラットフォームで用意できる。
- Hobbyは月額5 USDの基本料金が利用料金へ充当され、CPU、メモリ、ストレージは使用量課金となる。
- HobbyでもVolumeを利用できる。

#### Disadvantages

- アプリ、DB、CPU、メモリの使用量によって最終費用が変動し、RenderやHerokuの小規模固定プランより見積もりに幅がある。
- 公式資料ではデータベースをDockerイメージまたはテンプレートとして展開する構成であり、今回の短時間の選定ではRenderのRails 8専用手順より確認事項が多い。
- 汎用的なRailpackまたはDockerのデプロイ経路を理解する必要がある。

有力な第二候補だが、初回利用時の予測可能性を優先して第一候補にはしなかった。

Sources:

- [Railway Pricing Plans](https://docs.railway.com/pricing/plans)
- [Railway Build and Deploy](https://docs.railway.com/build-deploy)
- [Railway Data and Storage](https://docs.railway.com/data-storage)
- [Railway Volumes](https://docs.railway.com/volumes/reference)

### Heroku

#### Advantages

- Rails 8向けの公式チュートリアルがあり、Railsの運用実績が長い。
- CLI、ログ、環境変数、リリース、PostgreSQLの導線が成熟している。
- Basic dynoは月額最大7 USD、Essential-0 PostgreSQLは月額最大5 USDで、アプリとDBは約12 USDから構成できる。

#### Disadvantages

- dynoのファイルシステムは一時的で、再起動やデプロイで画像が消える。
- Active StorageにはS3などの外部オブジェクトストレージまたは追加アドオンが必要になり、アカウント、秘密情報、料金、障害点が増える。
- 月額5 USDのEco dynoは休止するため、採点用にはBasic以上が必要になる。

Railsのデプロイ自体は有力だが、画像永続化を含めた構成要素の少なさでRenderを下回ると判断した。

Sources:

- [Getting Started on Heroku with Rails 8](https://devcenter.heroku.com/articles/getting-started-with-rails8)
- [Heroku Usage and Billing](https://devcenter.heroku.com/articles/usage-and-billing)
- [Active Storage on Heroku](https://devcenter.heroku.com/articles/active-storage-on-heroku)
- [Provisioning Heroku Postgres](https://devcenter.heroku.com/articles/provisioning-heroku-postgres)

### Fly.io

#### Advantages

- Rails向けの公式導線があり、`fly.toml` とCLIで構成を管理できる。
- MachineとVolumeを細かく構成できる。
- 512 MBの共有CPU Machineは月額約4.39 USD、Volumeは1 GBあたり月額0.15 USDから利用できる。

#### Disadvantages

- 公式に推奨されるManaged Postgresは最小でも月額38 USDにストレージ料金が加わり、今回の用途には割高である。
- Machine、Volume、リージョン、`fly.toml`、release commandなど、PaaSとしてはインフラ判断が多い。
- 柔軟性の代わりに、初めての利用でトラブルシュートする範囲が広い。

学習目的や細かなインフラ制御には魅力があるが、30時間の技術試験では費用と運用負荷が見合わないと判断した。

Sources:

- [Rails Hosting on Fly.io](https://fly.io/rails/)
- [Fly.io Pricing](https://fly.io/pricing/)
- [Fly.io Managed Postgres](https://fly.io/docs/mpg/)

## Consequences

### Positive

- Rails、PostgreSQL、画像永続化を一つの管理画面に集約できる。
- 最初の本番デプロイを早期に完了しやすい。
- インフラ構成とマイグレーション方法をリポジトリに残せる。

### Negative

- Render固有の設定を学ぶ必要がある。
- Persistent Diskによりデプロイ時に短時間停止する。
- 将来水平スケールする場合は、画像をオブジェクトストレージへ移行する必要がある。

