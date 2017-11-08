module HoneycombRails
  module Extensions
    module ActionController
      module InstanceMethods
        def self.included(controller_class)
          super

          controller_class.before_action do
            honeycomb_initialize
          end
        end

        def honeycomb_initialize
          @honeycomb_metadata = {}
        end

        attr_reader :honeycomb_metadata
      end
    end
  end
end
