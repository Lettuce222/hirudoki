require "rubocop"

module RuboCop
  module Cop
    module Hirudoki
      class RestfulActions < Base
        include VisibilityHelp

        MSG = "Public method `%<method>s` must be a standard REST action. Extract a resource or make the helper private."
        ACTIONS = %i[index show new create edit update destroy].freeze

        def on_def(node)
          return if ACTIONS.include?(node.method_name)

          owner = node.each_ancestor(:class, :module, :sclass).first
          return unless owner&.class_type? && owner.identifier.const_name.end_with?("Controller")
          return unless method_visibility(node) == :public

          add_offense(node.loc.name, message: format(MSG, method: node.method_name))
        end

        private

        def method_visibility(node)
          declaration = visibility_inline_on_def?(node.parent) ? node.parent : node
          modifier = declaration.right_siblings.reverse.find do |sibling|
            visibility_inline_on_method_name?(sibling, method_name: node.method_name)
          end
          return modifier.method_name if modifier
          return node.parent.method_name if visibility_inline_on_def?(node.parent)
          return :private if node.method_name == :initialize

          node_visibility(node)
        end
      end
    end
  end
end
