require 'honeycomb-rails/extensions'
require 'honeycomb-rails/overrides'
require 'honeycomb-rails/subscribers'

require 'libhoney'

module HoneycombRails
  class Railtie < ::Rails::Railtie
    initializer 'honeycomb.action_controller_extensions', after: :action_controller do
      ::ActionController::Base.include(Extensions::ActionController::InstanceMethods)

      if defined?(::ActionController::API) # Rails 5 and above
        ::ActionController::API.include(Extensions::ActionController::InstanceMethods)
      end
    end

    initializer 'honeycomb.action_controller_overrides', after: :action_controller do
      ::ActionController::Base.include(Overrides::ActionControllerInstrumentation)

      if defined?(::ActionController::API) # Rails 5 and above
        ::ActionController::API.include(Overrides::ActionControllerInstrumentation)
      end
    end

    # set up libhoney after application initialization so that any config in
    # the app's config/initializers has taken effect.
    config.after_initialize do
      HoneycombRails.config.logger ||= ::Rails.logger

      @libhoney = HoneycombRails.config.client || begin
        writekey = HoneycombRails.config.writekey
        default_dataset = HoneycombRails.config.dataset
        if writekey.blank? || default_dataset.blank?
          missing = writekey.blank? ? 'writekey' : 'dataset'
          warn "No #{missing} defined! (Check your config's `#{missing}` value in config/initializers/honeycomb.rb) No events will be sent to Honeycomb."
          Libhoney::NullClient.new
        else
          Libhoney::Client.new(
            writekey: writekey,
            dataset: default_dataset,
            user_agent_addition: HoneycombRails::USER_AGENT_SUFFIX,
          )
        end
      end
    end

    config.after_initialize do
      req_builder = @libhoney.builder
      Subscribers::ProcessAction.new(req_builder).subscribe!

      if !HoneycombRails.config.db_dataset.blank?
        db_builder = @libhoney.builder
        db_builder.dataset = HoneycombRails.config.db_dataset
        Subscribers::ActiveRecord.new(db_builder).subscribe!
      end
    end
  end
end
