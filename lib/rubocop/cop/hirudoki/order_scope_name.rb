module RuboCop
  module Cop
    module Hirudoki
      class OrderScopeName < Base
        RESTRICT_ON_SEND = %i[scope].freeze
        MSG = "Name this scope %<expected>s."

        def_node_matcher :ordered_scope, <<~PATTERN
          (send nil? :scope $sym (block _ (args) (send nil? :order $_ ...)))
        PATTERN
        def_node_matcher :column_and_direction, "(hash (pair (sym $_) (sym ${:asc :desc})) ...)"

        def on_send(node)
          ordered_scope(node) do |name, first_argument|
            column, direction = first_argument.sym_type? ? [ first_argument.value, :asc ] : column_and_direction(first_argument)
            next unless column

            expected = "#{direction}_by_#{column}"
            add_offense(name, message: format(MSG, expected:)) unless name.value.to_s == expected
          end
        end
      end
    end
  end
end
