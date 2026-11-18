require "rubocop"

module RuboCop
  module Cop
    module Hirudoki
      module MethodVisibility
        include VisibilityHelp

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
