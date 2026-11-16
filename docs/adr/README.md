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



