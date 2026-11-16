# Walking SkeletonのTODO

- [x] DB接続を確認するヘルスチェックの正常/異常specを追加してRedを確認
- [x] Active StorageのDB・ファイル往復specを追加し、未導入の失敗を確認
- [x] そのRedをGitHub Actionsでも確認（品質ゲートの検出確認）
- [x] DB migrationと設定・実装を追加してGreenにする
- [x] ローカルでrequest/model/system、lint、脆弱性検査を成功させる
- [x] CIがGreenのmainのみ自動デプロイする構成を作る
- [x] SingaporeのWeb/DB/Diskで起動し、PC/モバイルの表示を確認
- [x] シェル用smoke scriptでDBとActive Storageへ書込み、画像URLから表示を確認
- [x] 同じアプリ実装の再デプロイ後にもDB/画像が残ることを確認
- [x] ログとロールバック経路、pre-deploy失敗時の既存版維持を確認
- [x] README・ADR・対応表・Linear・作業ログへ証跡を残す

商用の弁当登録画面・利用者登録・注文等は後続スライス。ここでは課題の業務テーブルを仮に増やさず、Active Storageのblobを使ってDBとDiskの配線を検証する。

## 確認済みの証跡

- 意図したRed: commit 0c78334 / [CI 43839858719](https://github.com/Lettuce222/hirudoki/actions/runs/43839858719)。新規3specが想定どおり失敗。
- Green: commit 7be7502 / [CI 43840511055](https://github.com/Lettuce222/hirudoki/actions/runs/43840511055)。全6specと4ジョブ成功。
- ローカル: Ruby3.4.12、PostgreSQL18.7。RSpec6例成功、RuboCop33ファイル違反なし、Brakeman警告0、production assetsビルド成功。
- 開発DB/画像往復: blob ID1、4166 bytes、SHA256 `2e29c62b03e514c5a15f289f8fdc0abca6e22d0e91970503c9e2b7e0552c911c`。
- 本番の作成画面: SingaporeのWeb 0.5c-512mb、PostgreSQL 0.1c-256mb/1GB、画像Disk1GB。表示概算は月額$13.55。
- 配置対象main: 7263c9e / [CI 43840809678](https://github.com/Lettuce222/hirudoki/actions/runs/43840809678)、全4ジョブ成功。
- 初回公開: https://hirudoki.onrender.com/ 。PC1280×900、モバイル390×844で見出し・説明文を表示し、横方向のはみ出しなし。
- `/up`: 公開HTTPSでHTTP200。DB接続を含む正常確認。
- 初回deploy: `dep-dbtcthoae00c73acmuv0`。build、pre-deploy、Puma起動の成功をログで確認。
- 本番DB/画像書込み: database=hirudoki_production、blob ID1、key=`4ppjzgfms0mcgift0d9x5vxrtif3`、4166 bytes、SHA256は開発環境と一致。
- Web: `srv-dbtcth0ae00c73acmsm0`、PostgreSQL: `dpg-dbtct60ae00c73acltn0-a`、Blueprint: `exs-dbtcrqjm8hqs73ai0l60`。
- 異常系: ユーザー承認の一時フラグによりpre-deployをDB変更前にexit1で停止（`dep-dbtd14lckfvc73egaap0`）。初回deployがLiveのままであることをRender画面で確認し、失敗後の`/up`と画像もHTTP200・同SHA256を確認した。DBを壊すmigrationは投入していない。
- 後始末: 一時フラグを削除しSave only。Environment上の該当行0件を確認。
- CI連携: Render設定画面でAfter CI Checks Passを確認。PR#7のmain commit 0882537、[CI 43842947041](https://github.com/Lettuce222/hirudoki/actions/runs/43842947041)の成功後、自動で`dep-dbtd2rqjnfac73d85vig`が開始された。
- 再デプロイ成功: 0882537がLive、Trigger=Auto-Deploy。インスタンスが`qgnzd`から`d28tj`へ切り替わった後、smoke scriptは既存blob ID1・同じkey・同じSHA256を返した（アップロードの再作成なし）。
- 再デプロイ後の外部取得: `/up`も同じ画像URLもHTTP200。画像のSHA256は `2e29c62b03e514c5a15f289f8fdc0abca6e22d0e91970503c9e2b7e0552c911c` で一致。
- ロールバック経路: Deploys→過去の成功deploy→Rollbackリンク（初回deployの`/rollback`）を確認。今回は実ロールバックは行わず、旧版維持は上記pre-deploy失敗で検証した。コードを戻してもDBを自動復元しないため後方互換migrationを維持する。

## 確認範囲

画像は公開アップロード画面ではなく、認証済みの運用シェルからActive Storage APIで投入した検証用PNG。画像の受入方針はPNG/JPEG/WebP・5MB以下とし、フォーム側の強制と画像なしの代替表示はLET-30/LET-31で実装する。画像の変換・業務用の添付モデルは未実装であり、ここで確認したのはDBとストレージの配線・配信・永続化である。
