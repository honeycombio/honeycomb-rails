require 'honeycomb-rails/subscribers/sampling'

require 'active_support/core_ext/hash'
require 'active_support/notifications'
require 'rails'

module HoneycombRails
  module Subscribers
    class ActiveRecord
      include Sampling

      def initialize(honeybuilder)
        @honeybuilder = honeybuilder
      end

      def subscribe!
        ::ActiveSupport::Notifications.subscribe(/sql.active_record/) do |*args|
          call(*args)
        end
      end

      def call(*args)
        event = ActiveSupport::Notifications::Event.new(*args)
        data = event.payload.slice(:name, :connection_id)
        data[:sql] = event.payload[:sql].strip
        event.payload[:binds].each do |b|
          case b
          when Array
            data["bind_#{ b[0].name }".to_sym] = b[1]
          else
            data["bind_#{ b.name }".to_sym] = b.value
          end
        end
        data[:duration] = event.duration

        # NOTE: Backtraces can be very verbose! Keep an eye on the data that gets sent
        #       into Honeycomb and, if needed, experiment with BacktraceCleaner's
        #       filters and silencers to trim down the noise.
        data[:local_stack] = Rails.backtrace_cleaner.clean(caller)

        honeycomb_event = @honeybuilder.event
        honeycomb_event.add(data)

        sample_event_if_required(honeycomb_event, event)

        honeycomb_event.send
      end
    end
  end
end
