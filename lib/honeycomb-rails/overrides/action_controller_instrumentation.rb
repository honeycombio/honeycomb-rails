module HoneycombRails
  module Overrides
    module ActionControllerInstrumentation
      def append_info_to_payload(payload)
        super

        metadata = {}

        # TODO generify this
        if current_user
          metadata[:current_user_id] = current_user.id
          metadata[:current_user_email] = current_user.email
          metadata[:current_user_admin] = current_user.try(:admin?) ? true : false
        end

        # TODO optionalise this
        metadata[:flash_error] = flash[:error] if flash[:error]
        metadata[:flash_notice] = flash[:notice] if flash[:notice]

        # Attach to ActiveSupport::Instrumentation payload for consumption by
        # subscribers/process_action.rb
        # TODO constantify this
        payload[:honeycomb_metadata] = metadata
      end
    end
  end
end
