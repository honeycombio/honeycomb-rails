require 'honeycomb-rails/config'
require 'honeycomb-rails/constants'

module HoneycombRails
  module Overrides
    module ActionControllerInstrumentation
      def append_info_to_payload(payload)
        super

        metadata = honeycomb_metadata

        # TODO generify this
        if current_user
          metadata[:current_user_id] = current_user.id
          metadata[:current_user_email] = current_user.email
          metadata[:current_user_admin] = current_user.try(:admin?) ? true : false
        end

        if HoneycombRails.config.record_flash?
          metadata[:flash_error] = flash[:error] if flash[:error]
          metadata[:flash_notice] = flash[:notice] if flash[:notice]
        end

        # Attach to ActiveSupport::Instrumentation payload for consumption by
        # subscribers/process_action.rb
        payload[Constants::EVENT_METADATA_KEY] = metadata
      end
    end
  end
end
