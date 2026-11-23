module RuboCop
  module Cop
    module Hirudoki
      class DeterministicSpecDate < Base
        MSG = "Use a fixed date or read the clock inside travel_to with an explicit reference time."
        DURATION_MSG = "Express elapsed time with its unit, such as 59.seconds."
        RANDOM_MSG = "Use a fixed date for example data."

        def_node_matcher :clock_read?, <<~PATTERN
          {
            (send (const {nil? cbase} {:Date :DateTime :Time}) {:current :now :today :tomorrow :yesterday})
            (send (const {nil? cbase} :Time) :new)
            (send (send (const {nil? cbase} :Time) :zone) {:now :today :tomorrow :yesterday})
            (send (send _ {:second :seconds :minute :minutes :hour :hours :day :days :week :weeks :month :months :year :years}) {:ago :from_now :since :until})
          }
        PATTERN
        def_node_matcher :random_date?, "(send (const (const {nil? cbase} :Faker) {:Date :Time}) _ ...)"
        def_node_matcher :unitless_travel?, "(send nil? :travel {int float} ...)"

        def on_send(node)
          if random_date?(node)
            add_offense(node, message: RANDOM_MSG)
          elsif unitless_travel?(node)
            add_offense(node, message: DURATION_MSG)
          elsif clock_read?(node) && !inside_fixed_clock?(node)
            add_offense(node)
          end
        end

        private

        def inside_fixed_clock?(node)
          node.each_ancestor(:block).any? do |block|
            call = block.send_node
            next unless call.receiver.nil? && %i[travel_to freeze_time].include?(call.method_name)
            next unless call.first_argument && !call.first_argument.hash_type?

            node.source_range.begin_pos >= call.source_range.end_pos
          end
        end
      end
    end
  end
end
