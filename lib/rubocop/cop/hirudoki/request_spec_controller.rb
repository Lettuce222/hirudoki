module RuboCop
  module Cop
    module Hirudoki
      class RequestSpecController < Base
        RESTRICT_ON_SEND = %i[get post patch put delete head options process].freeze
        PATH_MSG = "Name the request spec after a single controller, including its namespace."
        ROUTE_MSG = "Send requests using a named route helper directly."

        def on_new_investigation
          root, spec = File.expand_path(processed_source.file_path).split("/spec/requests/", 2)
          return unless spec
          return if spec.end_with?("_spec.rb") &&
            File.file?(File.join(root, "app/controllers", spec.sub(/_spec\.rb\z/, "_controller.rb")))

          add_global_offense(PATH_MSG)
        end

        def on_send(node)
          return if node.receiver
          return if node.first_argument&.send_type? && node.first_argument.method_name.to_s.end_with?("_path", "_url")

          add_offense(node, message: ROUTE_MSG)
        end
      end
    end
  end
end
