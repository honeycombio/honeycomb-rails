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
                                  :status, :db_runtime, :view_runtime)

        # Massage data to return "all" as the :format if not set
        if !data[:format] || data[:format] == "format:*/*"
          data[:format] = "all"
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
