require_relative "method_visibility"

module RuboCop
  module Cop
    module Hirudoki
      class StrongParametersMethod < Base
        include MethodVisibility

        RESTRICT_ON_SEND = %i[expect permit].freeze
        MSG = "Declare permitted attributes in a private *_params method."

        def on_send(node)
          return unless request_params?(node.receiver)
          return if node.method?(:expect) && node.arguments.all?(&:sym_type?)

          method = node.each_ancestor(:def, :defs).first
          return if method&.def_type? && method.method_name.end_with?("_params") && method_visibility(method) == :private

          add_offense(node.loc.selector)
        end
        alias on_csend on_send

        private

        def request_params?(receiver)
          while receiver&.call_type?
            return true if receiver.method?(:params) && (receiver.receiver.nil? || receiver.receiver.self_type?)

            receiver = receiver.receiver
          end
          false
        end
      end
    end
  end
end
