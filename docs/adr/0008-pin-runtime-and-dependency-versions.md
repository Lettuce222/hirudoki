# ADR 0008: Ruby 3.4.12・Rails 8.1.4.1・PostgreSQL 18を採用する

- Status: Accepted
- Date: 2026-11-16
- Linear: LET-14
- External information checked: 2026-11-16

## Context

Walking SkeletonはローカルにあったRuby 4.0.1で生成した暫定構成だった。本番はRenderのnative Rubyを使う予定であり、ローカル・CI・本番の差を減らし、30時間内のデプロイを優先する。

## Decision

- RubyはRenderの現行標準3.4.12に固定し、`.ruby-version`をGemfileから参照する。Dockerfileの値も合わせる。
- Railsは現在の8.1.4.1をGemfile.lockで固定する。Gemfileの許容範囲内でも、提出までは意図せずlockfileを更新しない。
- PostgreSQLは18を使う。ローカルは18.7。本番も18を明示し、マイナーバージョンはマネージドDBの更新に従う。
- RSpec Railsは8系。その他の全GemはGemfile.lock（プラットフォームとチェックサムを含む）を正本とする。
- ローカルGemはignoreされた`vendor/bundle`に配置する。個人のシェル設定や既存Rubyのリンクは変更しない。
- CIは同じ`.ruby-version`とlockfileでセットアップする。本番の実ビルドとDB接続はLET-24で検証し、公式対応の確認と実デプロイ成功を混同しない。
- 更新が必要な場合は、対象を絞って更新し、全spec・静的検査・本番スモークを確認する。

## Alternatives considered

- Ruby 4.0.1を維持: ローカルでは動くが、Renderの現行標準と異なる。新規の課題なので移行互換性の都合もなく、3.4.12を選ぶ。
- Ruby 4をDockerで持ち込む: バージョンの自由度は高いが、今回はnative Rubyで構成を小さくする。
- PostgreSQL 17等に下げる: 18はローカルにありRenderでも正式対応しているため、下げる理由がない。
- 依存を常に最新へ更新: 機能実装と無関係の変化が増えるため、課題中はlockfileを固定する。

## Consequences

Ruby 4用のGemを使い回せないため再インストールが必要だが、環境を再現しやすくなる。Renderの将来の標準変更にも依存しない。

## Sources

- [Render Ruby version](https://render.com/docs/ruby-version)
- [Render Rails 8 deployment](https://render.com/docs/deploy-rails-8)
- [Render PostgreSQL version support](https://render.com/docs/postgresql-upgrading)
- [RSpec Rails supported versions](https://github.com/rspec/rspec-rails)
- [ruby/setup-ruby](https://github.com/ruby/setup-ruby)
