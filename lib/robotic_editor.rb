require 'robotic_editor/robotically_edits'
require 'robotic_editor/version'

RoboticEditor::RoboticallyEdits::Adapter.load_available

module RoboticEditor
  class Engine < Rails::Engine
    isolate_namespace RoboticEditor
  end
end
