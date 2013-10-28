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

    def self.proc_img img , i
      # drop any style:
      style = img.attr(:style);
      img.set_attribute(:style,'');

      # make every image top-level
      while img.parent.name == "p" do
        noko_parentify img
      end

      src = img.attr(:src)

      id = /.*\/(.*?)\/.*?$/.match(src)[1] rescue nil
      picture = RedactorRails::Picture.find(id) rescue nil
      return unless picture

      woverh = picture.width.to_f / picture.height.to_f
      if woverh > 1.2
        partial = "shared/redactor_image_landscape" 
      elsif woverh < 0.8
        partial = "shared/redactor_image_portrait"
      else
        partial = "shared/redactor_image_square" # could be made "square" in future
      end

      multi_view = render_partial partial , { :image => picture, :woverh => woverh, :index => i } 

      img.replace(multi_view)
    end
    
    def self.proc_iframe(iframe,index)
      width = iframe.attr(:width).to_f
      height = iframe.attr(:height).to_f
      woverh = width/height

      if woverh > 1.2
        partial = "robotic_editor/iframe_landscape" 
      elsif woverh < 0.8
        partial = "robotic_editor/iframe_portrait"
      else
        partial = "robotic_editor/iframe_landscape" # could be made "square" in future
      end

      iframe.replace(render_partial(partial,{ :content => iframe , :woverh => woverh , :index => index }))
    end

    def self.render_partial(partial , locals)
      ApplicationController.new.render_to_string( :partial => partial ,
                                                  :locals => locals )
    end

    def self.edit_robotically(the_content)
      doc = Nokogiri::HTML(the_content)
      doc.css('img,iframe').each_with_index do |tag,i|
        if tag.name == 'iframe'
          proc_iframe tag,i
        elsif tag.name == 'img'
          proc_img tag,i
        end
      end
      # <!DOCTYPE><html><body><-- what we're interested in --></body></html>
      # hence children[1],children[0].children:
      doc.children[1].children[0].children.to_s
    end

    def self.summarize the_content, max_length
      doc = Nokogiri::HTML(the_content)
      
      text = doc.text().gsub(/\s+/,' ').lstrip
      
      text[0..max_length] + ( text.length < max_length ? "...":"")
    end

    module RoboticallyEditsClassMethods
      def robotically_summarizes(attribute , options = {})
        class_eval do
          define_method options[:as] || attribute+"_"+summary do
            return nil unless self[attribute].presence
            RoboticEditor::RoboticallyEdits::summarize(self[attribute],options[:max_length] || 300)
          end
        end
      end
      def robotically_edits(attribute , options = {})
        class_eval do
          define_method options[:as] || attribute do
            return nil unless self[attribute].presence
            RoboticEditor::RoboticallyEdits::edit_robotically(self[attribute])
          end
        end
      end
    end

    module RoboticallyEditsInstanceMethods
      
    end
  end
end
