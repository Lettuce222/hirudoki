require "rails_helper"
require "pathname"
require "rubocop"

RSpec.describe "設計ルール" do
  let(:application_path) { Pathname.new(__dir__).join("../app").expand_path }
  let(:standard_directories) { %w[assets channels controllers helpers javascript jobs mailers models views] }

  it "app直下にはRails標準のディレクトリだけを置く" do
    directories = application_path.children.select(&:directory?).map { |path| path.basename.to_s }
    unexpected_directories = directories - standard_directories

    expect(unexpected_directories).to be_empty,
      "許可されていないディレクトリ: #{unexpected_directories.join(', ')}。ドメインモデルはapp/modelsに置いてください"
  end

  it "アプリケーションのすべてのテーブルに必須の作成日時と更新日時がある" do
    missing_timestamps = ApplicationRecord.with_connection do |connection|
      rails_metadata_tables = [ connection.pool.schema_migration.table_name, connection.pool.internal_metadata.table_name ]
      (connection.tables - rails_metadata_tables).reject do |table|
        required_columns = connection.columns(table).reject(&:null).map(&:name)
        %w[created_at updated_at].all? { |name| required_columns.include?(name) }
      end
    end

    expect(missing_timestamps).to be_empty
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
