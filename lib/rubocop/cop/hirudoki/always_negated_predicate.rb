require "digest/sha2"

module RuboCop
  module Cop
    module Hirudoki
      class AlwaysNegatedPredicate < Base
        MSG = "Every direct call to this predicate is negated. Give the inverse a positive name."

        def on_def(node)
          add_offense(node.loc.name) if always_negated_names.include?(node.method_name)
        end
        alias on_defs on_def

        def external_dependency_checksum
          Digest::SHA256.hexdigest(always_negated_names.map(&:to_s).sort.join("\n"))
        end

        private

        def always_negated_names
          @always_negated_names ||= find_always_negated_names
        end

        def find_always_negated_names
          sources = source_paths.grep(/\.rb\z/).map do |path|
            RuboCop::ProcessedSource.from_file(path, target_ruby_version, parser_engine:)
          end
          return [] unless sources.all?(&:valid_syntax?)

          nodes = sources.filter_map(&:ast).flat_map do |ast|
            ast.each_node(:def, :defs, :send, :csend, :sym, :str).to_a
          end
          definitions = nodes.filter_map { |node| node.method_name if node.type?(:def, :defs) }.tally
          calls = nodes.select { |node| node.type?(:send, :csend) }.group_by(&:method_name)
          indirect_names = nodes.filter_map { |node| node.value.to_s if node.type?(:sym, :str) }.to_set
          templates = source_paths.grep(/\.erb\z/).map { |path| File.read(path) }

          definitions.filter_map do |name, count|
            next unless count == 1 && name.to_s.end_with?("?")
            next if indirect_names.include?(name.to_s) || templates.any? { |template| template.include?(name.to_s) }

            uses = calls.fetch(name, [])
            name if uses.any? && uses.all? { |call| call.send_type? && negated?(call) }
          end
        end

        def negated?(call)
          expression = call
          negated = false
          loop do
            parent = expression.parent
            if parent&.send_type? && parent.method_name == :! && parent.receiver.equal?(expression)
              negated = !negated
            elsif !parent&.begin_type? || !parent.children.one?
              return negated
            end
            expression = parent
          end
        end

        def source_paths
          @source_paths ||= Dir.glob("{app,config,lib,script}/**/*.{rb,erb}", base: config.base_dir_for_path_parameters)
            .map { |path| File.join(config.base_dir_for_path_parameters, path) }
        end
      end
    end
  end
end
