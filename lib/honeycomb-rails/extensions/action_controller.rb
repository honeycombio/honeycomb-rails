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

        # Hash of metadata to be added to the event we will send to Honeycomb
        # for the current request.
        #
        # To annotate the event with custom information (e.g. from a particular
        # controller action), just add data to this hash: e.g.
        #
        #     honeycomb_metadata[:num_posts] = @posts.size
        #
        # @return [Hash<String=>Any>]
        attr_reader :honeycomb_metadata
      end
    end
  end
end
