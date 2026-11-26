# ADR 0025: Rails UIで利用者・管理者画面のフォームと外観を揃える

- Status: Accepted
- Date: 2026-11-26
- Linear: LET-38 / LET-50

## Context

利用者向けの共通レイアウトは最大幅が30remで、PCの一覧でも領域が狭い。項目ラベル、入力欄、エラー表示も画面ごとに組み立てていた。定期注文設定の一覧、登録、編集について、PCとスマートフォンで操作できる試作を用意し、2026年11月26日に承認を得た。

## Decision

- [Rails UI](https://railsui.com/docs/forms)のフォームビルダーとHoundのフォーム・ボタンのスタイルを利用する。バージョンはGemfileで固定し、対応するHoundの `forms.css` と `buttons.css` を `app/assets/tailwind/railsui` に置き、Tailwindのビルドに取り込む。フォームビルダーは初期化時に読み込む。
- 利用者・管理者のページ枠、表、フォームエラー、パンくずはERBの共通パーシャルで描画する。ページ枠が見出し、主要操作、幅を持つ。各画面のERBでは項目、列、レコードの表示内容を記述する。
- 一覧はPCの幅を使い、フォームは短い項目をPCで2列、スマートフォンで1列にする。住所はフォームの幅全体を使う。登録と編集は同じフォームを描画し、保存後は一覧へ戻る。
- 定期注文設定の実装を本人が承認した後、ログインと利用者登録を含む全画面へ適用する指示を受けた。Rails UIのフォームビルダーはApplicationControllerで既定にする。

## Consequences

PCとスマートフォンの表示を1つのERBで扱い、共通部品の変更を利用する画面へ反映できる。Rails UIのバージョンを上げる際はフォームビルダーと取り込んだスタイルを合わせて確認する。[ADR 0004](0004-use-hotwire-and-tailwind.md)のERB、Hotwire、Tailwind CSSの構成を継続する。
