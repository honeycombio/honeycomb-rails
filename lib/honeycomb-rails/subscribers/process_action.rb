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
        if event.payload.key?(:honeycomb_metadata)
          data.merge!(event.payload[:honeycomb_metadata])
        end

        @libhoney.send_now(data)
      end
    end
  end
end
