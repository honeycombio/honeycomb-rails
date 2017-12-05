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

      module InstanceCaptureExceptionsFilters
        def self.included(controller_class)
          controller_class.around_action do |base, block|
            begin
              block.call
            rescue Exception => exception
              honeycomb_metadata[:exception_class] = exception.class.to_s
              honeycomb_metadata[:exception_message] = exception.message
              honeycomb_metadata[:exception_source] = Rails.backtrace_cleaner.clean(exception.backtrace)

              raise
            end
          end
        end
      end
    end
  end
end
