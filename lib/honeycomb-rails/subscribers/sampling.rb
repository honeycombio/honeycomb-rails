module HoneycombRails
  module Subscribers
    module Sampling
      def sample_event_if_required(honeycomb_event, notification_event)
        case HoneycombRails.config.sample_rate
        when Proc
          honeycomb_event.sample_rate = HoneycombRails.config.sample_rate.call(
            notification_event.name,
            notification_event.payload,
          )
        when Integer
          if HoneycombRails.config.sample_rate > 1
            honeycomb_event.sample_rate = HoneycombRails.config.sample_rate
          end
        end
      end
    end
  end
end
