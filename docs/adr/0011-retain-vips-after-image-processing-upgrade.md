# ADR 0011: image_processing更新時もVips依存を維持する

- Status: Accepted
- Date: 2026-11-16
- Linear: LET-27
- Related PR: #4

## Context

全PRのマージ依頼に従いDependabotのimage_processing 1.14.0→2.2.0を確認した。2系ではruby-vipsとmini_magickが任意依存になり、今回のlockfile更新では両方とも削除されていた。Railsの画像variant処理で従来のVipsを使うには明示的な依存が必要。

## Decision

image_processing 2.2.0を採用し、従来のVipsを維持するためGemfileにruby-vips 2.3系を直接指定する。Gemfile.lockで実バージョンを固定する。既存Dockerfileのlibvipsと整合させる。

`require: false`で、従来の間接依存時と同様に画像処理時だけロードする。通常のRails起動・JavaScript監査にもlibvipsを必須ロードしない。直接依存化した際のCIでlibvips不在による起動失敗を検出し、この遅延ロードを明示した。

## Alternatives considered

- 依存を追加しない: 画像処理時にLoadErrorとなるため採用しない。
- MiniMagickへ変更: 別の画像処理エンジンとOS依存を増やす必要がなく、従来どおりVipsを選ぶ。
- 更新を保留: ユーザーは現在の全PRのマージを依頼しており、必要な移行対応とCI確認をして採用する。

## Consequences

CIでGemの導入と既存specを確認する。実画像のアップロード・変換・本番永続化の受入確認はLET-27で行う。現時点で画像機能が実装・検証済みという意味ではない。ローカルや本番で画像変換を実行する環境にはlibvipsが必要。

## Source

- [image_processing公式Changelog: 2.0.0の任意依存化](https://github.com/janko/image_processing/blob/master/CHANGELOG.md)
