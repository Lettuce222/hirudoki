require "active_support/inflector"

module RuboCop
  module Cop
    module Hirudoki
      class ControllerBase < Base
        MSG = "Inherit directly from %<base>s."
        FRAMEWORK_BASES = {
          "application_controller.rb" => "ActionController::Base",
          "health_controller.rb" => "Rails::HealthController",
          "user_sessions_controller.rb" => "Devise::SessionsController",
          "admin/sessions_controller.rb" => "Devise::SessionsController"
        }.freeze

        def on_class(node)
          return unless node.identifier.short_name.end_with?("Controller")

          path = processed_source.file_path.split("app/controllers/").last
          base = FRAMEWORK_BASES.fetch(path) { directory_base(path) }
          parent = node.parent_class
          return if parent&.const_type? && matches_base?(node, parent, base)

          add_offense(parent || node.identifier, message: format(MSG, base:))
        end

        private

        def directory_base(path)
          directories = path.split("/")
          filename = directories.pop
          directories.pop if filename == "base_controller.rb"
          return "ApplicationController" if directories.empty?

          ActiveSupport::Inflector.camelize((directories + [ "base_controller" ]).join("/"))
        end

        def matches_base?(node, parent, base)
          return true if parent.const_name == base
          return false if parent.absolute?

          node.each_ancestor(:module, :class).any? do |scope|
            "#{scope.identifier.parent_module_name}::#{parent.const_name}" == base
          end
        end
      end
    end
  end
end
