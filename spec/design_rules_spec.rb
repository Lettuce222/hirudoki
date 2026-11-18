require "rails_helper"

# 設計ルールのうち、RuboCopでは表現できない構造のルールを検証する。
# 生成されたコードをレビューで直すのではなく、検証の仕組みで守る。
RSpec.describe "設計ルール" do
  it "app/services ディレクトリを作らない" do
    expect(Dir.exist?(Rails.root.join("app/services"))).to be(false)
  end

  it "app/models 配下のクラス名・モジュール名に Service を使わない" do
    offenders = Dir[Rails.root.join("app/models/**/*.rb")].select do |file|
      File.read(file).match?(/^\s*(?:class|module)\s+\w*Service\b/)
    end

    expect(offenders).to eq([])
  end
end
