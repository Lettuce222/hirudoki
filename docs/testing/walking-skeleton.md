# Walking SkeletonのTODO

- [ ] DB接続を確認するヘルスチェックの正常/異常specを追加してRedを確認
- [ ] Active StorageのDB・ファイル往復specを追加し、未導入の失敗を確認
- [ ] そのRedをGitHub Actionsでも確認（品質ゲートの検出確認）
- [ ] DB migrationと設定・実装を追加してGreenにする
- [ ] ローカルでrequest/model/system、lint、脆弱性検査を成功させる
- [ ] CIがGreenのmainのみ自動デプロイする構成を作る
- [ ] SingaporeのWeb/DB/Diskで起動し、PC/モバイルの表示を確認
- [ ] シェル用smoke scriptでDBとActive Storageへ書込み、画像URLから表示を確認
- [ ] 同じcommitの再デプロイ後にもDB/画像が残ることを確認
- [ ] ログとロールバック経路、pre-deploy失敗時の既存版維持を確認
- [ ] README・ADR・対応表・Linear・作業ログへ証跡を残す

商用の弁当登録画面・利用者登録・注文等は後続スライス。ここでは課題の業務テーブルを仮に増やさず、Active Storageのblobを使ってDBとDiskの配線を検証する。
