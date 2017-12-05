require 'honeycomb-rails/extensions'
require 'honeycomb-rails/overrides'
require 'honeycomb-rails/subscribers'

require 'libhoney'

module HoneycombRails
  class Railtie < ::Rails::Railtie
    initializer 'honeycomb.action_controller_extensions', after: :action_controller do
      ::ActionController::Base.include(Extensions::ActionController::InstanceMethods)
    end

    initializer 'honeycomb.action_controller_overrides', after: :action_controller do
      ::ActionController::Base.include(Overrides::ActionControllerInstrumentation)
    end

    # set up libhoney after application initialization so that any config in
    # the app's config/initializers has taken effect.
    config.after_initialize do
      writekey = HoneycombRails.config.writekey
      @libhoney = Libhoney::Client.new(writekey: writekey)
    end

    config.after_initialize do
      subscribers = []

      if !HoneycombRails.config.dataset.blank?
        req_builder = @libhoney.builder
        req_builder.dataset = HoneycombRails.config.dataset
        subscribers.push(Subscribers::ProcessAction.new(req_builder))
      end

      if !HoneycombRails.config.db_dataset.blank?
        db_builder = @libhoney.builder
        db_builder.dataset = HoneycombRails.config.db_dataset
        subscribers.push(Subscribers::ActiveRecord.new(db_builder))
      end

      if subscribers.empty?
        HoneycombRails.config.logger.warn("No subscribers defined (are both HoneycombRails.config.dataset and HoneycombRails.config.db_dataset both blank?")
      end

      subscribers.each(&:subscribe!)
    end
  end
end
