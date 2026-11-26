module RuboCop
  module Cop
    module Hirudoki
      class ControllerSetters < Base
        MSG = "Assign one matching instance variable in a set_* method using only read operations."
        READ_METHODS = %i[
          [] active asc_by_display_order asc_by_postal_code blob current_user daily_menu
          delivery_area_id_in_database desc_by_created_at expect find find_by image includes joins limit
          on_sale or order orders params preload recurring_order_settings reviews to_a where
        ].freeze
        VALUE_TYPES = %i[array cbase const false float hash if int ivar lvar nil pair str sym true].freeze

        def on_def(node)
          name = node.method_name.to_s
          if name.start_with?("set_")
            assignment = node.body
            expected = :"@#{name.delete_prefix('set_')}"
            return if assignment&.ivasgn_type? && assignment.name == expected && read_expression?(assignment.expression)
          else
            return unless assigns_instance_variable?(node.body) && before_action?(node)
          end

          add_offense(node.loc.name)
        end

        def on_block(node)
          return unless node.send_node.method?(:before_action) && assigns_instance_variable?(node.body)

          add_offense(node.send_node.loc.selector)
        end
        alias on_numblock on_block

        private

        def assigns_instance_variable?(body)
          body&.each_node(:ivasgn)&.any?
        end

        def before_action?(node)
          body = node.each_ancestor(:class).first&.body
          statements = body&.begin_type? ? body.children : [ body ]
          statements.any? do |statement|
            statement&.send_type? && statement.method?(:before_action) &&
              statement.arguments.any? { |argument| argument.sym_type? && argument.value == node.method_name }
          end
        end

        def read_expression?(expression)
          expression&.each_node&.all? do |node|
            node.call_type? ? READ_METHODS.include?(node.method_name) : VALUE_TYPES.include?(node.type)
          end
        end
      end
    end
  end
end
