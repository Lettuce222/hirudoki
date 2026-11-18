# ADR 0015: controllerのpublicメソッドをローカルcopで標準7アクションに限定する

- Status: Accepted
- Date: 2026-11-19
- Linear: LET-12

## Context

ユーザーはcontrollerのpublicメソッドを標準7アクションに限定したいと指定した。公式rubocop-railsのRails/ActionOrderは順序だけを検査する。外部のrubocop-guardrailsには同目的のGuardrails/RestfulActionsがあるが、ユーザーはこの規約だけのために依存を追加するより自分で小さなcopを持つ方針を示した。

## Decision

既存RuboCopのBaseとVisibilityHelpを使い、Hirudoki/RestfulActionsをlib/rubocop/cop/hirudokiに実装する。追加gemは不要。.rubocop.ymlから読み込み、app/controllers/**/*_controller.rbを対象に有効化する。

- Controllerで終わるクラスのpublicなdefはindex/show/new/create/edit/update/destroyだけを許可する。
- private/protectedの補助メソッドは許可する。ブロック、インライン、定義後の名前指定、publicへの切り替えを検査する。
- クラスメソッド、controller以外の内部クラス、Concernのmoduleは対象外。
- 自動修正はしない。リソースへ分割するか補助メソッドをprivateにするかは意味の判断が必要なため、違反箇所に修正方針を表示する。

AGENTS.mdから7アクションの記述を削除し、禁止事項の正本をcopへ移す。ADR 0014で残していた「可能な限り」という7アクション方針は、この明確な検査対象に限り厳格な規約へ変更する。

## Alternatives considered

- rubocop-guardrails: 目的に合う既存実装はあるが、今回は1規約のための外部依存を追加しない。
- Rails/ActionOrder: 追加アクションの禁止を保証しない。
- 正規表現でdefを列挙: Rubyの可視性や名前空間、内部クラスを区別しにくい。
- Rails起動後の全publicメソッドをspecで検査: Concernや動的定義も含められるが、フレームワークから継承したメソッドなどの除外設計が必要。今回の自前controller内の宣言に対するlintとは分ける。

## Consequences

既存CIのlintで規約違反を検出し、cop自体のspecもtestで実行する。Rails・DBなしでcopのTDDを行える。Rubyの全てのメタプログラミングを解釈するものではなく、alias/define_methodやConcern・継承を経由したメソッドの追加・公開は保証範囲に含めない。

## Sources

- [RuboCopのカスタムcop開発](https://docs.rubocop.org/rubocop/latest/development.html)
- [Rails/ActionOrder](https://docs.rubocop.org/rubocop-rails/latest/cops_rails.html#railsactionorder)
- [比較したrubocop-guardrails](https://github.com/carldaws/rubocop-guardrails)
