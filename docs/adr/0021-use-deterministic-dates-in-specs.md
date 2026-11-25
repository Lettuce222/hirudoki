# ADR 0021: specで扱う日付と経過時間

- Status: Accepted
- Date: 2026-11-24
- Linear: LET-30

## 方針

| 検証すること | specでの表し方 |
| --- | --- |
| 登録・検索に渡す日付 | 固定日を使う。同じ提供日で登録・検索するなら、一つの `served_on` を共有する。うるう日から翌月への絞り込みなら `Date.new(2028, 2, 29)` とその翌日が例になる。 |
| 今日や締切によって結果が変わる処理 | 基準日時を固定し、アプリのタイムゾーンで期待値を書く。10時締切なら、例えば `travel_to(Time.zone.local(2028, 2, 29, 9, 59, 59))` で締切直前を再現し、そこから1秒進める。 |
| 再送間隔・リンクの有効期間 | `travel 59.seconds` や `travel 30.minutes` のように、仕様で使う単位を残す。経過時間だけが条件なら `freeze_time` で時計を止めてから進められる。 |

## 静的解析

`Hirudoki/DeterministicSpecDate` は `spec/**/*.rb`（Factory Botも含む）に適用する。実行時の時計を読む代表的な呼び出し（`Date.current`、`Time.zone.now`、`2.days.from_now` など）、Fakerによる日時生成、数値だけの `travel` を指摘する。

`travel_to` または `freeze_time` に基準日時を渡したブロック内では時計を参照できる。共通のフックで時計を設定するspecでは、入力値や期待値もその基準日時から計算する。copは別のフックや独自ヘルパーの実行順を推論しない。どの暦日が仕様を表すか、秒と分のどちらが読みやすいかはレビューで確認する。

## 判断の参考

37signalsのFizzyでも、日別一覧は固定日のパラメータ、期間の解釈は明示的な基準日時で検証している。[日別一覧のテスト](https://github.com/basecamp/fizzy/blob/60c5be7a935dc6ba1a5dbfe180d78ddb005083d1/test/controllers/events/days_controller_test.rb#L8-L16)・[期間の解釈のテスト](https://github.com/basecamp/fizzy/blob/60c5be7a935dc6ba1a5dbfe180d78ddb005083d1/test/models/time_window_parser_test.rb#L3-L19)
