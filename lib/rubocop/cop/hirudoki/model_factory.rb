module RuboCop
  module Cop
    module Hirudoki
      class ModelFactory < Base
        RESTRICT_ON_SEND = %i[new create create!].freeze
        MSG = "Use Factory Bot to build or create test records."

        def on_send(node)
          receiver = node.receiver
          receiver = described_model(node) if described_class?(receiver)
          return unless receiver&.const_type? && cop_config.fetch("Models").include?(receiver.const_name)

          add_offense(node.loc.selector)
        end

        private

        def_node_matcher :described_class?, "(send nil? :described_class)"
        def_node_matcher :example_group_model, "(send {nil? (const nil? :RSpec)} {:describe :context} $const ...)"

        def described_model(node)
          node.each_ancestor(:block) do |block|
            model = example_group_model(block.send_node)
            return model if model
          end
          nil
        end
      end
    end
  end
end
