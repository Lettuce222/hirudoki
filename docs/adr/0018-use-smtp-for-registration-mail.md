# ADR 0018: 利用者登録の確認メールをBrevoのSMTPで送る

- Status: Accepted
- Date: 2026-11-19
- Linear: LET-26

登録前にメールアドレスを確認することは、PDFの登録要件に加えて本人が指定した。確認メールから氏名・電話番号・パスワードの入力へ進む。プロトタイプ第5版を本人が承認した。

本番はAction MailerからBrevoのSMTPリレーへSTARTTLSで接続する。送信元を確認したうえで、SMTPログインとキーをRenderの環境変数に置く。独自ドメインを用意していないため、受信者に表示される送信元がBrevoのアドレスに置き換わる場合がある。Resendも検討したが、任意の利用者へ配信するにはドメイン認証が必要になる。開発はファイル配送、テストはAction Mailerのテスト配送を使う。

再送間隔を1分、リンクの有効期限を30分とした。未確認の利用者を users に作らず、registration_invitations にアドレスと最終送信日時（sent_at）を保持する。再送は1分以上空くため、送信日時で各回を区別できる。署名付きリンクに発行時の sent_at を含め、招待の現在値と照合する。再送が失敗すると日時の更新もロールバックされ、直前のリンクを使える。登録成功時には同じトランザクションで招待の user_id に新しい利用者を記録する。登録リンクは user_id が空の招待だけに使える。初回発行・最終送信・登録の日時は、招待の created_at と sent_at、利用者の created_at から確認する。

[Brevoの送信者要件](https://help.brevo.com/hc/en-us/articles/14925263522578-Comply-with-Gmail-Yahoo-and-Microsoft-s-requirements-for-email-senders)・[Resendのドメイン認証](https://resend.com/docs/dashboard/domains/introduction)
