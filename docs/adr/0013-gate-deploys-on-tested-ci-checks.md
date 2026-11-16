# ADR 0013: CIの成功を本番反映の条件にする

- Status: Accepted
- Date: 2026-11-16
- Linear: LET-11 / LET-25

## Decision

GitHub Actionsのtest、lint、scan_ruby、scan_jsを品質ゲートにする。RSpec（model/request/systemを含む）、RuboCop、Brakeman、bundler-audit、importmap auditを実行する。ローカルもREADMEとbin/ciに記載した同じコマンドを使う。

新specを先にpushして意図したRedをCIで確認し、実装後のGreenを確認する。RenderはmainのchecksPassを条件にデプロイする。GitHub Freeのprivateリポジトリではmain保護を強制できないため、PRと成功したheadの確認を運用として守る。

## Alternatives considered

- CIを省略: 環境差と失敗の取りこぼしがあるため不採用。
- commitごとの無条件デプロイ: Redを本番へ出す可能性があるため不採用。
- GitHub Proへアップグレードしてmain保護: 有効だが、そのためだけの新しい課金はせず現在の制約を明記する。

## Verification

- 基盤のGreen: [main CI 43838589975](https://github.com/Lettuce222/hirudoki/actions/runs/43838589975)
- Walking Skeleton受入specの意図したRed: [CI 43839858719](https://github.com/Lettuce222/hirudoki/actions/runs/43839858719)、commit 0c78334。既存healthがDBを確認せず、Active StorageのDBテーブルが未導入であることを検出。
- 実装後のGreenと本番結果は`docs/testing/walking-skeleton.md`へ記録する。
