module RoboticEditor
  module RoboticallyEdits
    module Adapter
      class Base
        attr_accessor :abase_url, :callback_options, :configuration, :instance, :klass, :settings

        def initialize(configuration)
          ensure_loadable
          self.configuration = configuration
          self.settings = configuration.settings
        end

        def create_callbacks!(klass)
          self.klass = klass
          self.callback_options = {}
          create_method_to_callback
          create_callback
        end

        def ensure_unique_url!(instance)
          @url_owners = nil
          self.instance = instance

          handle_url!
          handle_duplicate_url! unless settings.allow_duplicates
        end

        def initialize_urls!(klass)
          self.klass = klass
          klass_previous_instances do |instance|
            ensure_unique_url_for! instance
          end
        end

        def url_attribute(instance)
          # Retrieve from database record if there are errors on attribute_to_urlify
          if !is_new?(instance) && is_present?(instance.errors[settings.attribute_to_urlify])
            self.instance = instance
            read_attribute instance_from_db, settings.url_attribute
          else
            read_attribute instance, settings.url_attribute
          end
        end

        def self.ensure_loadable
          raise "The #{self} adapter cannot be loaded" unless loadable?
          RoboticEditor::RoboticallyEdits::Adapter.add_loaded_adapter self
        end

        def self.loadable?
          orm_class
        rescue NameError
          false
        end

      private

        def create_callback
          klass.send klass_callback_method, :ensure_unique_url, callback_options
        end

        def klass_callback_method
          settings.sync_url ? klass_sync_url_callback_method : klass_non_sync_url_callback_method
        end

        def klass_sync_url_callback_method
          configuration.settings.callback_method
        end

        def klass_non_sync_url_callback_method
          case configuration.settings.callback_method
          when :before_save
            :before_create
          else # :before_validation
            callback_options[:on] = :create
            configuration.settings.callback_method
          end
        end

        def create_method_to_callback
          klass.class_eval <<-"END"
            def #{settings.url_attribute}
              acts_as_url_configuration.adapter.url_attribute self
            end
          END
        end

        def ensure_loadable
          self.class.ensure_loadable
        end

        # NOTE: The <tt>instance</tt> here is not the cached instance but a block variable
        # passed from <tt>klass_previous_instances</tt>, just to be clear
        def ensure_unique_url_for!(instance)
          instance.send :ensure_unique_url
          instance.save
        end


        def orm_class
          self.class.orm_class
        end

        def primary_key
          instance.class.primary_key
        end

      end
    end
  end
end
