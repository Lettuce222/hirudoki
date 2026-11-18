# ADR 0017 — system specでaxeのアクセシビリティ検査を行う

- Status: Accepted
- Date: 2026-11-19
- Linear: LET-25

## 背景と判断

画面変更によるアクセシビリティの回帰を、プルリクエストとmainへのpushで検出する。既存のChrome system specは、CSSとJavaScriptを読み込んだ状態で画面を開く。その画面を`axe-core-capybara`と`axe-core-rspec`で検査し、違反があればRSpecを失敗させる。

最初の対象はホーム全体で、PCとモバイルの両方をWCAG 2.2 A・AAに対応するaxeのルールで検査する。今後の主要画面やフォームのエラー状態は、対象のsystem specで検査を追加する。キーボードでの操作や読み上げ順は手動でも確認する。

独立したaxe CLIジョブも検討した。ログインや入力後の状態を作る手順がsystem specと重複するため、既存のRSpecで同じブラウザーを使う構成を選んだ。

Chrome 158はCapybara 3.40がブラウザーデータの消去に使うワイルドカードのオリジンを拒否する。Capybaraの通常のリセットを使い、そのCDP呼び出しだけをCookieの消去とRailsテストサーバーのオリジンのストレージ消去に置き換える。消去時のエラーはテストの失敗として伝わる。Chromeのプロセスは次のテストで再利用する。

## 参照

- [axe-core-rspecのマッチャー](https://github.com/dequelabs/axe-core-gems/tree/develop/packages/axe-core-rspec)
- [axe-coreのWCAGルール一覧](https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md)
- [Capybara 3.40のChromeセッション終了処理](https://github.com/teamcapybara/capybara/blob/3.40.0/lib/capybara/selenium/driver_specializations/chrome_driver.rb)
- [Chrome DevTools Protocolのストレージ操作](https://chromedevtools.github.io/devtools-protocol/tot/Storage/)
