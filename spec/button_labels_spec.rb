require "nokogiri"
require "pathname"
require "action_view"
require "rubocop"

RSpec.describe "ボタンの文言" do
  # 新しい操作を追加するときに、その名詞形をここでレビューする。
  let(:labels) { %w[利用者登録 確認メール送信 登録 保存 確認メール再送 絞り込み] }
  let(:root) { Pathname.new(__dir__).parent }

  it "ビューのHTMLボタンには承認した名詞を表示する" do
    files = root.glob("app/views/**/*.html.erb")
    selector = "button, [role=button], a.primary, a.secondary, input[type=submit], input[type=button], input[type=reset]"
    files.each do |file|
      Nokogiri::HTML5.parse(file.read).css(selector).each do |control|
        label = control.name == "input" ? control["value"] : control.text.strip
        expect(labels).to include(label), "#{file.relative_path_from(root)}: #{label.inspect}"
      end
    end
  end

  it "Railsのボタンヘルパーには承認した名詞を明示する" do
    root.glob("app/views/**/*.html.erb").each do |file|
      ruby = ActionView::Template::Handlers::ERB.erb_implementation.new(file.read).src
      source = RuboCop::ProcessedSource.new(ruby, RUBY_VERSION.to_f)
      expect(source.valid_syntax?).to be(true), file.to_s
      source.ast&.each_node(:send) do |call|
        next unless %i[button_tag button_to submit submit_tag button].include?(call.method_name) || button_link?(call)

        argument = call.first_argument
        label = argument&.str_type? ? argument.value : nil
        expect(labels).to include(label), "#{file.relative_path_from(root)}: #{call.source}"
      end
    end
  end

  def button_link?(call)
    return false unless call.method?(:link_to)

    options = call.last_argument
    return false unless options&.hash_type?

    options.pairs.any? do |pair|
      key, value = pair.key, pair.value
      next false unless key.sym_type? && (value.str_type? || value.sym_type?)

      case key.value
      when :role then value.value.to_s == "button"
      when :class then (value.value.to_s.split & %w[primary secondary]).any?
      end
    end
  end
end
