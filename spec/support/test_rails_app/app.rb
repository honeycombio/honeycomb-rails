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

    get '/api/hello', to: 'hello_api#show'
    get '/api/explode', to: 'hello_api#explode'
  end

  initializer :configure_honeycomb_rails do
    HoneycombRails.configure do |config|
      config.client = Libhoney::TestClient.new
    end
  end
end

class HelloController < ActionController::Base
  class Explosion < RuntimeError; end

  def show
    honeycomb_metadata[:greetee] = 'world'

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

if Rails::VERSION::MAJOR >= 5
  class HelloApiController < ActionController::API
    class Explosion < RuntimeError; end

    def show
      honeycomb_metadata[:greetee] = 'world'
      render json: {status: 'ok', greeting: 'Hello world!'}
    end

    def explode
      raise Explosion, 'kaboom!'
    end
  end
end
