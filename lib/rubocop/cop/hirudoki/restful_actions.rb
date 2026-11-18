require_relative "method_visibility"

module RuboCop
  module Cop
    module Hirudoki
      class RestfulActions < Base
        include MethodVisibility

        MSG = "Public method `%<method>s` must be a standard REST action. Extract a resource or make the helper private."
        ACTIONS = %i[index show new create edit update destroy].freeze

        def on_def(node)
          return if ACTIONS.include?(node.method_name)

          owner = node.each_ancestor(:class, :module, :sclass).first
          return unless owner&.class_type? && owner.identifier.const_name.end_with?("Controller")
          return unless method_visibility(node) == :public

          add_offense(node.loc.name, message: format(MSG, method: node.method_name))
        end
      end
    end
  end
end
