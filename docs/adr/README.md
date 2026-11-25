# Architecture Decision Records

このディレクトリには、「ひるどき」の設計・技術・運用に関する重要な意思決定を記録する。

## 運用ルール

- ファイル名は `NNNN-kebab-case-title.md` とする。
- 番号は連番とし、一度割り当てた番号を再利用しない。
- 検討中は `Proposed`、合意後は `Accepted` とする。
- 決定を変更するときは過去のADRを書き換えず、新しいADRから `Superseded` にする。
- 採用案だけでなく、判断基準、比較した選択肢、トレードオフを残す。
- 外部サービスの料金や仕様など変化し得る情報には確認日と一次情報へのリンクを付ける。
- 実装とADRが食い違った場合は、同じ変更内でADRも更新する。

## Status

- `Proposed`: 検討中
- `Accepted`: 合意済み
- `Rejected`: 検討したが不採用
- `Superseded`: 後続ADRにより置き換え済み

## Index

| ADR | Status | Decision |
|---|---|---|
| [0000](0000-use-architecture-decision-records.md) | Accepted | 重要な意思決定をADRで記録する |
| [0001](0001-deliver-production-ready-vertical-slices.md) | Accepted | 本番稼働可能な縦方向のスライスで開発する |
| [0002](0002-use-rails-full-stack.md) | Accepted | Railsフルスタックを採用する |
| [0003](0003-select-hosting-platform.md) | Accepted | ホスティング基盤としてRenderを採用する |
| [0004](0004-use-hotwire-and-tailwind.md) | Accepted | ERB、Hotwire、Tailwind CSSを採用する |
| [0005](0005-use-devise-for-authentication.md) | Accepted | 利用者と管理者の認証にDeviseを採用する |
| [0006](0006-track-decisions-and-delivery-in-linear.md) | Accepted | 意思決定待ちと実装進捗をLinearで管理する |
| [0007](0007-use-a-single-wall-clock-work-log.md) | Accepted | 作業時間を単一の壁時計で記録する |
| [0008](0008-pin-runtime-and-dependency-versions.md) | Accepted | Ruby 3.4.12・Rails 8.1.4.1・PostgreSQL 18を固定する |
| [0009](0009-use-rspec-capybara-and-red-green-refactor.md) | Accepted | RSpec・Capybara・SeleniumでTDDを行う |
| [0010](0010-use-a-private-submission-repository.md) | Accepted | 個人の非公開リポジトリで準備し提出時に採点者へ共有する |
| [0011](0011-retain-vips-after-image-processing-upgrade.md) | Accepted | image_processing 2系への更新でVipsの直接依存を維持する |
| [0012](0012-deploy-with-blueprint-ci-gate-and-persistent-disk.md) | Accepted | BlueprintとDB/画像Diskの分離で本番を構築する |
| [0013](0013-gate-deploys-on-tested-ci-checks.md) | Accepted | CI成功を本番反映の条件とする |
| [0014](0014-enforce-design-rules-with-static-checks.md) | Accepted | 機械判定できる設計ルールをRuboCopと構造specへ移す |
| [0015](0015-enforce-restful-controller-actions-with-a-local-cop.md) | Accepted | controllerのpublicメソッドをローカルcopで標準7アクションに限定する |
| [0016](0016-require-approved-screen-flows-before-ux-changes.md) | Accepted | UX変更は画面遷移の本人承認後に実装する |
| [0017](0017-check-accessibility-with-axe-in-system-specs.md) | Accepted | system specでaxeのアクセシビリティ検査を行う |
| [0018](0018-use-smtp-for-registration-mail.md) | Accepted | 登録確認メールの配送にBrevoのSMTPを使う |
| [0019](0019-enforce-catalog-constraints.md) | Accepted | 弁当タイプを弁当に持たせ、提供日ごとの重複をRailsで防ぐ |
| [0020](0020-separate-administrator-access.md) | Accepted | 管理者の認証と画面を利用者から分ける |
| [0021](0021-use-deterministic-dates-in-specs.md) | Accepted | specの入力日は固定し、現在に依存する仕様は基準日時を明示する |
| [0022](0022-use-one-controller-base-per-namespace.md) | Accepted | コントローラの継承をディレクトリ構成に揃える |
| [0023](0023-order-cutoff-in-japan.md) | Accepted | 日本時間10:00から当日分を締め切る |
| [0024](0024-serialize-order-writes-and-key-recurring-generation.md) | Proposed | 注文の同時受付と同日の定期注文の二重生成を防ぐ |
