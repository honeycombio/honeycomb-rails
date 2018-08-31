RSpec.describe "instrumented Rails #{Rails::VERSION::MAJOR} app", integration: true, type: :request do
  before(:all) { TestApp.initialize! }
  after(:all) { HoneycombRails.reset_config_to_default! }

  after { HoneycombRails.config.client.reset }

  def emitted_event
    events = HoneycombRails.config.client.events
    expect(events.size).to eq(1)
    events[0]
  end

  describe 'default configuration' do

    it 'sends events for each successful request' do
      get '/hello'

      expect(response.status).to eq(200)

      event = emitted_event
      expect(event.data).to include(
        controller: HelloController.name,
        action: 'show',
        method: 'GET',
        path: '/hello',
        status: 200,
      )
    end

    it 'includes custom fields set on #honeycomb_metadata' do
      get '/hello'

      expect(emitted_event.data).to include(greetee: 'world')
    end

    it 'sends events for requests we failed to handle, recording exception details' do
      get '/explode'

      expect(response.status).to eq(500)

      event = emitted_event
      expect(event.data).to include(
        exception_class: HelloController::Explosion.name,
        exception_message: 'kaboom!',
        status: 500,
      )

      if Rails::VERSION::MAJOR > 4
        # we only support capturing exception_source on Rails 5+
        expect(event.data[:exception_source]).to be_an Array
      end
    end

  end

  if Rails::VERSION::MAJOR >= 5
    describe 'API-only app' do

      it 'sends events for each successful request' do
        get '/api/hello'

        expect(response.status).to eq(200)

        event = emitted_event
        expect(event.data).to include(
          controller: HelloApiController.name,
          action: 'show',
          method: 'GET',
          path: '/api/hello',
          status: 200,
        )
      end

      it 'includes custom fields set on #honeycomb_metadata' do
        get '/api/hello'

        expect(emitted_event.data).to include(greetee: 'world')
      end

      it 'sends events for requests we failed to handle, recording exception details' do
        get '/api/explode'

        expect(response.status).to eq(500)

        event = emitted_event
        expect(event.data).to include(
          exception_class: HelloApiController::Explosion.name,
          exception_message: 'kaboom!',
          status: 500,
        )

        expect(event.data[:exception_source]).to be_an Array
      end

    end
  end

  describe 'with config.capture_exceptions = false' do
    before { HoneycombRails.config.capture_exceptions = false }
    after { HoneycombRails.config.capture_exceptions = true }

    it 'sends events for requests we failed to handle, but omits exception details' do
      get '/explode'

      expect(response.status).to eq(500)

      event = emitted_event
      expect(event.data).to include(status: 500)
      expect(event.data).to_not include(:exception_class, :exception_message, :exception_source)
    end

  end
end
