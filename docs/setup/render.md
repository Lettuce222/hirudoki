# Renderの準備と終了手順

対象チケット: LET-22（アカウント準備）、LET-24（実デプロイ）、LET-27（画像永続化）。

## 準備状況（2026-11-16）

- 個人アカウントの作成・メール確認・My Workspaceへのログイン: 確認済み。
- ワークスペースはHobby。有料Web/DB/Diskの利用と有料ワークスペースへのアップグレードは区別する。
- 支払い方法: ユーザーが登録完了。Billingを再読込し未登録表示が消えたことを確認。カード情報をリポジトリへ残さない。
- GitHub接続: 個人のLettuce222をGit Deployment Credentialsで確認済み。新規Web ServiceのSource Codeで`Lettuce222 / hirudoki`だけが選択肢に表示されることを確認した。
- リージョン: ADR 0003どおりSingapore。WebとPostgreSQLを同リージョンで作成し、内部接続URLを使う。
- この準備段階ではWeb/DB/Diskはまだ作成していない。

## デプロイ時の確認

1. Git Deployment Credentials / GitHub app接続を確認する。リポジトリ権限は個人の対象リポジトリに限定する。
2. mainとCIの結果を確認してから、LET-24でWeb/DBを構成する。
3. Ruby 3.4.12、PostgreSQL 18、Singaporeを明示する。
4. 画像用DiskはWebと同じサービスに接続し、build/pre-deployからDiskへアクセスしない。
5. 初期構築の実料金は作成画面で確認し、Billingで作成後の利用額を確認する。

## 採点終了後に停止する場合

採点期間中は稼働を維持する。以下は手順の記録であり、現時点で削除を実行しない。

1. 採点終了を確認し、必要なソース・DBバックアップ・画像を保存する。
2. 対象Web、PostgreSQL、Diskの名前とIDを実物で特定する。
3. 自動デプロイを停止する。Webだけの停止で全費用が止まると考えず、DB・Disk・ワークスペースプラン・その他の利用を個別に確認する。
4. 不要になった対象リソースだけを管理画面の削除手順に従って削除する。DBとDiskの削除はデータを失う操作なので、実行前にユーザーの明示的な指示を確認する。
5. BillingのUnbilled ChargesとInvoice Historyを確認する。既に発生した利用料は、削除してもなかったことにはならない。
6. 不要になったGitHub連携のアクセス権も見直す。

## Sources

- [Render Regions](https://render.com/docs/regions)
- [Connect your Git provider](https://render.com/docs/git-provider)
- [Render Dashboard](https://render.com/docs/render-dashboard)
- [Persistent Disks](https://render.com/docs/disks)
- [Render Pricing](https://render.com/pricing)
