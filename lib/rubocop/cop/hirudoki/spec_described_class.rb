require "active_support/inflector"

module RuboCop
  module Cop
    module Hirudoki
      class SpecDescribedClass < Base
        MSG = "Describe the class or module corresponding to this spec file."
        RESTRICT_ON_SEND = %i[describe context example_group feature].freeze

        def on_send(node)
          return unless top_level_group?(node)

          subject = node.first_argument
          return if subject&.const_type? && matching_path?(subject.const_name)

          add_offense(subject || node.loc.selector)
        end

        private

        def top_level_group?(node)
          receiver = node.receiver
          return false unless receiver.nil? || (receiver.const_type? && receiver.const_name == "RSpec")

          node.each_ancestor(:block).none? do |block|
            block.send_node != node && RESTRICT_ON_SEND.include?(block.send_node.method_name)
          end
        end

        def matching_path?(class_name)
          relative_path = File.expand_path(processed_source.file_path).split("/spec/", 2).last.delete_suffix("_spec.rb")
          category, path = relative_path.split("/", 2)
          expected = ActiveSupport::Inflector.underscore(class_name)
          case category
          when "requests"
            expected.end_with?("_controller") && path == expected.delete_suffix("_controller")
          when "models"
            path&.delete_prefix("concerns/") == expected
          when "rubocop"
            relative_path == expected.sub(/\Arubo_cop\//, "rubocop/")
          else
            path == expected
          end
        end
      end
    end
  end
end
