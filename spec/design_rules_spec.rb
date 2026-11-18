require "pathname"
require "rubocop"

RSpec.describe "設計ルール" do
  let(:application_path) { Pathname.new(__dir__).join("../app").expand_path }
  let(:standard_directories) { %w[assets channels controllers helpers javascript jobs mailers models views] }

  it "app直下にはRails標準のディレクトリだけを置く" do
    directories = application_path.children.select(&:directory?).map { |path| path.basename.to_s }

    expect(directories - standard_directories).to be_empty,
      "標準外の層を作らず、フォームオブジェクトなどのドメインモデルはapp/modelsに置いてください"
  end

  it "クラス・モジュール・定数にServiceやPresenterという名前を付けない" do
    offenders = application_path.glob("**/*.rb").flat_map do |file|
      source = RuboCop::ProcessedSource.from_file(file, RUBY_VERSION.to_f)
      expect(source.valid_syntax?).to be(true), "#{file}のRuby構文を修正してください"

      source.ast&.each_node(:class, :module, :casgn)&.filter_map do |node|
        name = node.casgn_type? ? node.children[1].to_s : node.children.first.const_name
        "#{file}:#{node.first_line} (#{name})" if name.split("::").any? { |part| part.match?(/(?:Service|Presenter)\z/) }
      end || []
    end

    expect(offenders).to be_empty,
      "Service・Presenterではなく業務を表す名前のモデルにしてください: #{offenders.join(', ')}"
  end
end
