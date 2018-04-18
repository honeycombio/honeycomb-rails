require 'rails'
require 'action_controller/railtie'

require 'honeycomb-rails'


class TestApp < Rails::Application
  # some minimal config Rails expects to be present
  config.secret_key_base = 'test'
  config.eager_load = true

  routes.append do
    get '/hello', to: 'hello#show'
    get '/explode', to: 'hello#explode'
  end

  initializer :configure_honeycomb_rails do
    HoneycombRails.configure do |config|
      config.client = Libhoney::TestClient.new
    end
  end

  # TODO shouldn't write log/development.log
end

class HelloController < ActionController::Base
  class Explosion < RuntimeError; end

  def show
    render plain: 'Hello world!'
  end

  def explode
    raise Explosion, 'kaboom!'
  end
end
