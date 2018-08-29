require 'rails'
require 'action_controller/railtie'

require 'honeycomb-rails'


class TestApp < Rails::Application
  # some minimal config Rails expects to be present
  if Rails::VERSION::MAJOR < 4
    config.secret_token = 'test' * 8
  else
    config.secret_key_base = 'test'
  end

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
end

class HelloController < ActionController::API
  class Explosion < RuntimeError; end

  def show
    if Rails::VERSION::MAJOR < 4
      render text: 'Hello world!'
    else
      render plain: 'Hello world!'
    end
  end

  def explode
    raise Explosion, 'kaboom!'
  end
end
