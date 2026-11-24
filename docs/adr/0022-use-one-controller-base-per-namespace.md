# ADR 0022: コントローラの継承をディレクトリ構成に揃える

- Status: Accepted
- Date: 2026-11-24
- Linear: LET-30

## 決定

直下のコントローラはRails標準の `ApplicationController` を継承する。名前空間に共通の基底クラスを置く場合は `BaseController` とする。たとえば `Admin::BentosController` の直接の親は `Admin::BaseController`、その親は `ApplicationController` になる。将来 `Admin::Reports::BaseController` を置く場合、その親は `Admin::BaseController` になる。

同じ名前空間の一部だけで使う振る舞いは、必要なコントローラでConcernを明示的に読み込む。弁当・日別献立・配達エリアは保存後の遷移とエラー表示を共有する。管理トップにも共通する管理者認証とキャッシュ制御は、管理画面の基底クラスが担当する。

## 検証

RuboCopの `Hirudoki/ControllerBase` は、配置ディレクトリに応じた直接の親を検査する。RailsのヘルスチェックとDeviseのセッションはフレームワークの実装を利用するため、該当ファイルと親クラスの組み合わせを指定する。
