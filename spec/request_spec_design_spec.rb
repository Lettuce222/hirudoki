require "rails_helper"
require "rubocop"

RSpec.describe "リクエストspecの設計ルール" do
  let(:routes) { Rails.application.routes.routes }
  let(:request_specs) { Rails.root.join("spec/requests").glob("**/*_spec.rb") }

  def request_controller(file)
    file.relative_path_from(Rails.root.join("spec/requests")).to_s.delete_suffix("_spec.rb")
  end

  it "ルートを持つアプリのコントローラーとリクエストspecのパスが一対一で対応する" do
    controllers = routes.filter_map { |route| route.defaults[:controller] }.uniq.select do |controller|
      Rails.root.join("app/controllers/#{controller}_controller.rb").file?
    end

    expect(request_specs.map { |file| request_controller(file) }).to match_array(controllers)
  end

  it "各リクエストspecは対応するコントローラーのルートヘルパーでリクエストする" do
    violations = request_specs.flat_map do |file|
      source = RuboCop::ProcessedSource.from_file(file, RUBY_VERSION.to_f)
      requests = source.ast.each_node(:send).select do |node|
        node.receiver.nil? && %i[get post patch put delete head options process].include?(node.method_name)
      end
      controllers_by_request = requests.to_h { |node| [ node, route_controllers(node) ] }
      issues = controllers_by_request.filter_map do |node, controllers|
        next if controllers == [ request_controller(file) ]

        "#{file.relative_path_from(Rails.root)}:#{node.first_line} (#{node.source})"
      end
      issues << "#{file.relative_path_from(Rails.root)} にHTTPリクエストがありません" if requests.empty?
      issues
    end

    expect(violations).to be_empty, "対象コントローラーのルートヘルパーを直接指定してください。\n#{violations.join("\n")}"
  end

  def route_controllers(request)
    helper = request.first_argument
    return [] unless helper&.send_type? && helper.method_name.to_s.end_with?("_path", "_url")

    name = helper.method_name.to_s.sub(/_(path|url)\z/, "")
    named_route = Rails.application.routes.named_routes[name]
    return [] unless named_route

    # Railsは同じパスでHTTPメソッドだけ異なるルートにも同じヘルパーを使う。
    routes.select do |route|
      route.path.spec.to_s == named_route.path.spec.to_s && route.verb == request.method_name.upcase.to_s
    end.filter_map { |route| route.defaults[:controller] }.uniq
  end
end
