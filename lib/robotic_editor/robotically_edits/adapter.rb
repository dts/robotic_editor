require "robotic_editor/robotically_edits/adapter/base"
require "robotic_editor/robotically_edits/adapter/active_record"

module RoboticEditor
  module RoboticallyEdits
    module Adapter
      def self.add_loaded_adapter(adapter)
        @loaded_adapters << adapter
      end

      def self.load_available
        @loaded_adapters = []
        constants.each do |name|
          adapter = const_get(name)
          adapter.load if adapter.loadable?
        end
      end

      def self.first_available
        @loaded_adapters[0]
      end
    end
  end
end
