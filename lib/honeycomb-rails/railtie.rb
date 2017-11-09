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
      dataset = HoneycombRails.config.dataset
      @libhoney = Libhoney::Client.new(writekey: writekey, dataset: dataset)
    end

    config.after_initialize do
      Subscribers::ProcessAction.new(@libhoney).subscribe!
    end
  end
end
