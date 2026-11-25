class DocumentColumnMeanings < ActiveRecord::Migration[8.1]
  def change
    change_column_comment :orders, :quantity, from: nil, to: "この注文の弁当の個数。キャンセル後も個数を履歴として保持する"
    change_column_comment :orders, :unit_price, from: nil, to: "注文時点の弁当1個あたりの税抜価格（円）"
    change_column_comment :orders, :unit_discount, from: nil, to: "注文時点の弁当1個あたりの税抜割引額（円）。手動注文は0円"
    change_column_comment :orders, :total_amount, from: nil, to: "この注文の割引後の税込合計（円）。消費税の1円未満を切り捨てて保存する"
    change_column_comment :orders, :delivery_address, from: nil, to: "この注文で指定した配達先。次回の初期値には最新の注文の住所を使う"
    change_column_comment :orders, :status, from: nil, to: "注文済・受取済・キャンセル済。キャンセル済の注文は残数と同日注文数の集計から除外する"

    change_column_comment :bentos, :price, from: nil, to: "弁当1個あたりの現在の税抜価格（円）。価格変更前の注文額には影響しない"
    change_column_comment :bentos, :bento_type, from: nil, to: "和食・洋食・中華・ヘルシーのいずれか。同じ提供日に同じタイプは1献立まで"
    change_column_comment :bentos, :display_order, from: nil, to: "同じ提供日の献立では小さい値の弁当を先に表示する"
    change_column_comment :bentos, :on_sale, from: nil, to: "販売中の弁当だけが利用者の献立閲覧・注文の対象となる"
    change_column_comment :daily_menus, :capacity, from: nil, to: "この献立の手動注文の提供数上限（個）。残数はキャンセル済を除く注文個数を引いて求める"
    change_column_comment :daily_menus, :served_on, from: nil, to: "日本時間で弁当を提供する日。当日分の手動注文は午前10時に締め切る"
    change_column_comment :delivery_areas, :postal_code, from: nil, to: "ハイフンなしの半角数字7桁。先頭の0も保持する"
    change_column_comment :delivery_areas, :active, from: nil, to: "新規注文で選択できる配達エリアかどうか。無効化しても既存注文の参照は保持する"

    change_column_comment :registration_invitations, :sent_at, from: nil, to: "最後の確認メールの送信時刻。再送時に更新して以前の登録リンクを失効させる"
    change_column_comment :registration_invitations, :user_id, from: nil, to: "この招待で登録した利用者。未使用の招待はNULL"
    change_column_comment :users, :email, from: nil, to: "利用者ログイン用のメールアドレス。利用者内で一意"
    change_column_comment :users, :encrypted_password, from: nil, to: "Deviseが認証に使うbcryptハッシュ"
    change_column_comment :administrators, :email, from: nil, to: "管理者ログイン用のメールアドレス。利用者とは別に一意"
    change_column_comment :administrators, :encrypted_password, from: nil, to: "管理者認証に使うbcryptハッシュ"

    change_column_comment :active_storage_attachments, :name, from: nil, to: "添付先モデルに定義した関連名。弁当画像の関連名はimage"
    change_column_comment :active_storage_blobs, :key, from: nil, to: "ストレージ内でファイルを特定するキー。元のファイル名はfilenameに保存する"
    change_column_comment :active_storage_variant_records, :variation_digest, from: nil, to: "元画像に適用する変換内容のダイジェスト。同じ変換結果を再利用するために使う"
  end
end
