# ADR 0014: 機械判定できる設計ルールを静的検証へ移す

- Status: Accepted
- Date: 2026-11-19
- Linear: LET-12

## Context

ユーザーはpotetoさんの開発スタイルを参考に、AGENTS.mdの注意書きよりも実行して違反を検出する仕組みを優先する方針を指定した。構造と命名は既存の正規表現によるspecで一部だけ検査されていた。名前空間付きの宣言や定数代入でこの検査を回避できた。

## Decision

| 対象 | 検証場所 |
|---|---|
| app直下のディレクトリはassets/channels/controllers/helpers/javascript/jobs/mailers/models/viewsに限定 | spec/design_rules_spec.rb |
| app内のクラス・モジュール・定数名の各名前空間要素をService/Presenterで終えない | 同spec。既存RuboCopのRuby ASTを解析し、宣言と定数代入を検査 |
| specのグループ内で定数・クラス・モジュールを直接定義しない | RSpec/LeakyConstantDeclaration |
| グループの外側のローカル変数をexample内の共有データにしない | RSpec/LeakyLocalVariable |
| モデルの一意性バリデーションに対応するDBのunique indexを用意する | Rails/UniqueValidationWithoutIndex |

rubocop-rspec 3.10系を開発・テスト依存として採用し、上記2つのcopだけを有効にする。exampleの入力データはletを使う。example生成用のループ変数、example内の計算結果、期待値のリテラルまで一律にlet化することは要求しない。定数の差し替えを検証するstub_constも許容する。

利用者のメールアドレス所有確認を登録前に行うというユーザーの追加指定に従い、mailersは許可する。メール不要・mailers禁止という途中の指示は撤回された。通知全般を対象外とするPDFのX-006と区別し、本人が追加した登録フローとして扱う。

機械判定できる禁止事項はAGENTS.mdから削除し、既存のCIのlint/testジョブで失敗させる。ドメインの名詞として適切か、標準7アクションで表せるか、モデルとDBの制約が業務に十分か、テストの文章が仕様として読めるかなど、意味の判断が必要な指針は残す。一意性のcopはdb/schema.rbに基づく検査であり、条件付きバリデーションなどの対象外ケースやNOT NULL・外部キー・CHECK制約の整合性までは保証しない。

## Alternatives considered

- AGENTS.mdと検証側に同じ禁止事項を残す: 正本が分散し、エージェントの記憶へ依存するため採用しない。
- 正規表現の追加: 名前空間や定数代入、文字列・コメントとの区別をRuby構文として扱えないためASTへ置き換える。
- 独自copや全RSpec copの一括導入: 既存copで足りる検査の保守と無関係な整形を増やすため採用しない。
- controllerのアクション数や行数だけで設計を合否判定: 元の「可能な限り」という指針を過度に厳格化し、意味の妥当性を保証しないため採用しない。

## Consequences

構造specはRailsやDBを起動せず実行できる。RuboCopは開発・テスト依存なので本番依存は増やさない。規約の追加・変更には検証コードを変更する。AST検査はRubyファイルの静的な宣言が対象で、実行時のconst_setなどによる動的な定義や業務設計の妥当性は保証しない。

## Sources

- [ユーザーが参照したpoteto-mode解説記事（/correctの節）](https://agmazon.com/blog/articles/technology/202610/pstack-poteto-mode-guide-ja.html)
- [RuboCop RSpec公式cop一覧](https://docs.rubocop.org/rubocop-rspec/latest/cops_rspec.html)
- [RuboCop Rails公式cop一覧](https://docs.rubocop.org/rubocop-rails/latest/cops_rails.html#railsuniquevalidationwithoutindex)
