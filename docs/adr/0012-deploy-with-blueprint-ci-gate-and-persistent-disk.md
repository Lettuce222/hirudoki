# ADR 0012: Blueprint・CI成功条件・DBとDiskの分離でデプロイする

- Status: Accepted
- Date: 2026-11-16
- Linear: LET-13

## Context

業務仕様の実装前に本番のDB・ストレージまで動くことを確認する。RenderではPersistent Diskをbuild/pre-deployから利用できないため、migrationと画像書込みを分離する。

## Decision

- `render.yaml`を構成の正本とし、Singaporeにnative Ruby Web、PostgreSQL 18、1GBの画像Diskを作る。
- Webは0.5c-512mb、DBは0.1c-256mb・1GB。作成画面の実料金を確認してから作成する。
- mainのCIが成功した場合だけ自動デプロイする（checksPass）。初回作成時も対象commitのCI成功を確認する。
- buildでは依存取得とassets:precompileのみ。pre-deployでDB migrationを行い、画像Diskには触らない。
- 画像は実行中のインスタンスでActive Storageへアップロードし、`/opt/render/project/src/storage`へ保存する。
- 画像の受入方針はPNG/JPEG/WebP・5MB以下とする。公開フォームでの検証と代替表示は後続の弁当管理・献立表示で実装する。Walking Skeletonでは認証済みシェル専用の検証画像を使う。
- SECRET_KEY_BASEはRenderで生成し、接続情報と同様に環境変数で渡す。現在は外部サービスの暗号化credentialsを使わないためmaster.keyを転送しない。
- ヘルスチェックは最小のDBクエリを含む。DB接続失敗は503とし詳細を外部へ出さない。
- 認証されたシェル専用のsmoke scriptでActive StorageのDBレコード・ファイルを往復し、再デプロイ後に同じID/key/チェックサムを確認する。
- pre-deployが破壊的操作前に失敗するテスト用フラグを用意し、現行版の維持を実確認する。確認後はフラグを解除する。

## Alternatives considered

- build中のmigrationや画像seed: buildをDB状態に結び付け、画像Diskにもアクセスできないため採用しない。
- Docker: この段階ではnative runtimeの公式経路を優先する。
- 新しい検証用業務テーブルや公開アップロード画面: 指定DBの役割や攻撃面を増やすため作らない。Active Storage自身のblobで配線を検証する。
- 永続Disk以外のオブジェクトストレージ: スケールには有利だが、今回の単一インスタンスには追加契約を避ける。

## Consequences

Diskにより再デプロイ時には短い停止を許容する。DBのschema変更は後方互換を保ち、コードのロールバックでDBまで自動復元されると考えない。実際の起動・保存確認の結果は`docs/testing/walking-skeleton.md`へ追記する。

## Sources

- [Blueprint reference](https://render.com/docs/blueprint-spec)
- [Persistent disks](https://render.com/docs/disks)
- [Deploy steps and CI integration](https://render.com/docs/deploys)
