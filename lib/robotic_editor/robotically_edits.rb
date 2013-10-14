require 'robotic_editor/robotically_edits/adapter'

module RoboticEditor
  module RoboticallyEdits
    def self.noko_parentify node
      parent = node.parent

      # make a copy of the parent of <node>, to contain everything after
      # <node>.
      after_node = parent.clone
      # empty it out:
      after_node.children.each { |c| c.remove }
      
      # move every sibling after <node> in to the <after_node>
      while sib = node.next_sibling do
        sib.remove
        puts "Adding sib #{sib} '#{sib.text.length}'"
        after_node.add_child sib and puts "Added" if sib.text.length != 0
      end

      # now remove <node>
      node.remove
      
      # and add it after the thing that used to be our parent:
      parent.add_next_sibling node
      
      # and insert our next thing:
      node.add_next_sibling after_node

      # and ensure our old parent still has contents, otherwise we can wipe it out:
      parent.remove if parent.text.length == 0
    end

    def self.edit_robotically(the_content)
      doc = Nokogiri::HTML(the_content)
      doc.css('img').each_with_index do |img,i|
        # drop any style:
        style = img.attr(:style);
        img.set_attribute(:style,'');
        
        # make every image top-level
        while img.parent.name == "p" do
          noko_parentify img
        end

        src = img.attr(:src)

        id = /.*\/(.*?)\/.*?$/.match(src)[1] rescue nil
        picture = RedactorRails::Picture.find(id)

        woverh = picture.width.to_f / picture.height.to_f
        if woverh > 1.2
          partial = "shared/redactor_image_landscape" 
        elsif woverh < 0.8
          partial = "shared/redactor_image_portrait"
        else
          partial = "shared/redactor_image_square" # could be made "square" in future
        end
        puts "INDEX: #{i} , #{ (i % 2==0) ? 'even' : 'odd' }"
        multi_view = ApplicationController.new.render_to_string( :partial => partial , 
                                                                 :locals => { 
                                                                   :image => picture, 
                                                                   :woverh => woverh,
                                                                   :index => i
                                                                 } )

        img.replace(multi_view)
      end
      # <!DOCTYPE><html><body><-- what we're interested in --></body></html>
      # hence children[1],children[0].children:
      doc.children[1].children[0].children.to_s
    end

    module RoboticallyEditsClassMethods
      def robotically_edits(attribute , options = {})
        class_eval do
          define_method attribute do
            RoboticEditor::RoboticallyEdits::edit_robotically(self[attribute])
          end
        end
      end
    end

    module RoboticallyEditsInstanceMethods
      
    end
  end
end
