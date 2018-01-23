module HoneycombRails
  module Extensions
    module ActionController
      module InstanceMethods
        # Hash of metadata to be added to the event we will send to Honeycomb
        # for the current request.
        #
        # To annotate the event with custom information (e.g. from a particular
        # controller action), just add data to this hash: e.g.
        #
        #     honeycomb_metadata[:num_posts] = @posts.size
        #
        # @return [Hash<String=>Any>]
        def honeycomb_metadata
          @honeycomb_metadata ||= {}
        end
      end
    end
  end
end
