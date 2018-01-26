require 'honeycomb-rails/config'
require 'honeycomb-rails/constants'

module HoneycombRails
  module Overrides
    module ActionControllerInstrumentation
      def append_info_to_payload(payload)
        super

        metadata = honeycomb_metadata || {}

        metadata.merge!(honeycomb_user_metadata)

        if HoneycombRails.config.record_flash?
          flash.each do |k, v|
            metadata[:"flash_#{k}"] = v
          end
        end

        # Attach to ActiveSupport::Instrumentation payload for consumption by
        # subscribers/process_action.rb
        payload[Constants::EVENT_METADATA_KEY] = metadata
      end

      def honeycomb_user_metadata
        if defined?(@honeycomb_user_proc)
          return @honeycomb_user_proc.call(self)
        end

        case HoneycombRails.config.record_user
        when :detect
          honeycomb_detect_user_methods!
          honeycomb_user_metadata
        when :devise
          honeycomb_user_metadata_devise
        when Proc
          @honeycomb_user_proc = HoneycombRails.config.record_user
          honeycomb_user_metadata
        when nil, false
          {}
        else
          raise "Invalid value for HoneycombRails.config.record_user: #{HoneycombRails.config.record_user.inspect}"
        end
      end

      def honeycomb_user_metadata_devise
        if respond_to?(:current_user) and current_user
          {
            current_user_id: current_user.id,
            current_user_email: current_user.email,
            current_user_admin: !!current_user.try(:admin?),
          }
        else
          {}
        end
      end

      def honeycomb_detect_user_methods!
        if respond_to?(:current_user)
          # This could be more sophisticated, but it'll do for now
          HoneycombRails.config.record_user = :devise
        else
          logger.error "HoneycombRails.config.record_user = :detect but couldn't detect user methods; disabling user recording."
          HoneycombRails.config.record_user = false
        end
      end
    end
    module ActionControllerFilters
      def self.included(controller_class)
        controller_class.around_action :honeycomb_attach_exception_metadata
      end

      def honeycomb_attach_exception_metadata
        begin
          yield
        rescue StandardError => exception
          honeycomb_metadata[:exception_class] = exception.class.to_s
          honeycomb_metadata[:exception_message] = exception.message
          if HoneycombRails.config.capture_exception_backtraces
            honeycomb_metadata[:exception_source] = Rails.backtrace_cleaner.clean(exception.backtrace)
          end

          raise
        end
      end
    end
  end
end
