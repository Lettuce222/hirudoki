# ADR 0009: RSpec・Capybara・SeleniumでTDDを行う

- Status: Accepted
- Date: 2026-11-16
- Linear: LET-12
- External information checked: 2026-11-16

## Context

PDFはmodel specとsystem specを要求する。ユーザーは全ての開発をt-wadaのTDD（Red-Green-Refactor）で行い、機能を満たした段階で提出相当の品質を揃えることを指定している。Hotwireを採用しているため、JavaScriptを含む画面の確認が必要。

## Decision

- RSpec Rails 8を基盤とし、model/service/request/systemの各層を責務で使い分ける。
- system specはCapybara＋Selenium＋headless Chromeを標準とする。PCとモバイルのviewportを検証する。
- ローカルとCIはChromeを使用する。Selenium Managerが対応driverを管理する。既存Braveも比較したが、実機検証でbrowser 155とdriver 157の不一致が出たため標準に採用しない。
- FactoryBotで必要最小限のデータを作り、Rails time helpersで時刻を固定する。
- 通常のDBテストはtransactional fixturesを使用する。競合テストは別接続・非transaction方式を個別設計する。
- テスト実行方式をローカルとGitHub Actionsで揃える。実行結果の確認前にCI成功済みとは扱わない。
- 各仕様についてTODO→意図したRed→最小実装でGreen→Refactorを繰り返す。詳細は`docs/testing/tdd.md`。

## Alternatives considered

- Minitest: Rails標準だが、課題のspec指定と既存RSpec基盤に合わせてRSpecを選ぶ。
- rack_testだけのsystem spec: 高速だがJavaScriptを実行しないため、Hotwireの主要導線の保証として不十分。
- Playwright専用テスト基盤: 有力だが、RSpecのsystem specと別のランナー・言語を増やす必要がない。
- DatabaseCleanerの一律導入: RSpec system specはtransactionを扱えるため、通常ケースには追加しない。
- 本番seed依存のテスト: 日付や既存状態の影響を受けるため採用しない。

## Consequences

実ブラウザとdriverの初回取得が必要になる。速度重視の業務ルールはmodel/service specで検証し、system specは利用者の主要シナリオに集中する。品質・モバイル・テストを後工程へ分離しない。

## Sources

- [RSpec Rails system specs](https://rspec.info/features/8-0/rspec-rails/system-specs/system-specs/)
- [Capybara](https://github.com/teamcapybara/capybara)
- [Selenium Manager](https://www.selenium.dev/documentation/selenium_manager/)
- [FactoryBot Rails](https://github.com/thoughtbot/factory_bot_rails)
