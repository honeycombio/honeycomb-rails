require 'honeycomb-rails/constants'

require 'active_support/core_ext/hash'
require 'active_support/notifications'

module HoneycombRails
  module Subscribers
    class ProcessAction
      def initialize(libhoney)
        @libhoney = libhoney
      end

      def subscribe!
        ::ActiveSupport::Notifications.subscribe(/process_action.action_controller/) do |*args|
          call(*args)
        end
      end

      def call(*args)
        event = ::ActiveSupport::Notifications::Event.new(*args)

        # These are the keys we're interested in! Skipping noisy keys (:headers, :params) for now.
        data = event.payload.slice(:controller, :action, :method, :path, :format,
                                  :status, :db_runtime, :view_runtime,
                                  :exception, :exception_object)

        if request_id = event.payload[:headers][:'action_dispatch.request_id']
          data[:request_id] = request_id
        end

        # Massage data to return "all" as the :format if not set
        if !data[:format] || data[:format] == "format:*/*"
          data[:format] = "all"
        end

        # strip off exception fields for more friendly formatting
        exception_info = data.delete(:exception)
        exception = data.delete(:exception_object)

        if exception_info
          exception_class, exception_message = exception_info

          # Apparently these notifications don't include the `status` field if
          # an exception occurred while handling the request, even though the
          # response certainly does end up with a status code set. We'd like to
          # report that status code, so we reuse the same status code lookup
          # table that ActionController uses. This looks janky, but it's how the
          # standard Rails logging does it too... :|
          #
          # https://github.com/rails/rails/blob/37b373a8d2a1cd132bbde51cd5a3abd4ecee433b/actionpack/lib/action_controller/log_subscriber.rb#L27
          data[:status] ||= ActionDispatch::ExceptionWrapper.status_code_for_exception(exception_class)

          if HoneycombRails.config.capture_exceptions
            data[:exception_class] = exception_class
            data[:exception_message] = exception_message

            if exception && HoneycombRails.config.capture_exception_backtraces
              data[:exception_source] = ::Rails.backtrace_cleaner.clean(exception.backtrace)
            end

          end
        end

        # Pull top-level attributes off of the ActiveSupport Event.
        data[:duration_ms] = event.duration

        # Add anything we added in our controller-level instrumentation (see
        # overrides/action_controller_instrumentation.rb)
        if event.payload.key?(Constants::EVENT_METADATA_KEY)
          data.merge!(event.payload[Constants::EVENT_METADATA_KEY])
        end

        honeycomb_event = @libhoney.event
        honeycomb_event.add(data)

        case HoneycombRails.config.sample_rate
        when Proc
          honeycomb_event.sample_rate = HoneycombRails.config.sample_rate.call(event.payload)
        when Integer
          if HoneycombRails.config.sample_rate > 1
            honeycomb_event.sample_rate = HoneycombRails.config.sample_rate
          end
        end

        honeycomb_event.send
      end
    end
  end
end
