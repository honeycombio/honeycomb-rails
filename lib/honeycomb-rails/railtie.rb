require 'honeycomb-rails/initializers'
require 'honeycomb-rails/overrides'
require 'honeycomb-rails/subscribers'

module HoneycombRails
  class Railtie < ::Rails::Railtie
    include Initializers::LibhoneyFromEnv

    initializer 'honeycomb.config' do
      set_libhoney_from_env!
    end

    initializer 'honeycomb.subscribe_notifications' do
      Subscribers::ProcessAction.new(libhoney).subscribe!
    end

    initializer 'honeycomb.action_controller_overrides', after: :action_controller do
      ::ActionController::Instrumentation.prepend(Overrides::ActionControllerInstrumentation)
    end
  end
end
