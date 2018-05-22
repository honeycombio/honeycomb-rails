require 'honeycomb-rails/subscribers/process_action'

RSpec.describe HoneycombRails::Subscribers::ProcessAction do
  let(:fakehoney) { Libhoney::TestClient.new }

  subject { described_class.new(fakehoney) }

  TEST_PAYLOAD = {
    controller: :widgets,
    action: :index,
    method: 'GET',
    path: '/widgets',
    format: :html,
    status: 200,
    db_runtime: 123,
    view_runtime: 42,
    headers: {'action_dispatch.request_id': '0123beefcafe'},
  }.freeze

  def simulate_event(payload: {}, start: Time.now, finish: Time.now + 1)
    subject.call(
      'process_action.action_controller',
      start,
      finish,
      'abcdef0123456',
      TEST_PAYLOAD.merge(payload),
    )
  end

  it 'sends an event describing the request processing' do
    simulate_event

    expect(fakehoney.events.size).to eq 1
    event = fakehoney.events[0]

    expect(event.data).to include(
      :controller,
      :action,
      :method,
      :path,
      :format,
      :status,
      :db_runtime,
      :view_runtime,
    )
  end

  it 'records the event duration as duration_ms' do
    start = Time.now
    finish = start + 2
    simulate_event(start: start, finish: finish)

    expect(fakehoney.events[0].data).to include(:duration_ms)
    expect(fakehoney.events[0].data[:duration_ms]).to eq 2000
  end

  it 'records the Rails-supplied request id as request_id' do
    simulate_event(payload: {headers: {'action_dispatch.request_id': '456beefcafe'}})

    expect(fakehoney.events[0].data).to include(request_id: '456beefcafe')
  end

  it 'massages the "format" property' do
    simulate_event(payload: {format: 'format:*/*'})

    expect(fakehoney.events[0].data).to include(format: 'all')
  end

  it 'merges in metadata from :honeycomb_metadata' do
    simulate_event(payload: {honeycomb_metadata: {user_id: 42}})

    expect(fakehoney.events[0].data).to include(user_id: 42)
  end

  describe 'exception reporting' do
    def simulate_exception
      # produce an exception with a meaningful backtrace
      begin
        raise 'Oops'
      rescue => e
      end
      expect(e.backtrace).to be_an Array

      simulate_event(payload: {
        exception: [e.class.name, e.message],
        exception_object: e,
        status: nil, # how ActionController seems to do it
      })
    end

    describe 'by default' do
      it 'captures the exception class and message' do
        simulate_exception

        expect(fakehoney.events[0].data).to include(
          exception_class: 'RuntimeError',
          exception_message: 'Oops',
        )
      end

      it 'records an HTTP status code indicating error' do
        simulate_exception

        expect(fakehoney.events[0].data).to include(status: 500)
      end

      it 'records the backtrace in exception_source' do
        simulate_exception

        event = fakehoney.events[0]
        expect(event.data[:exception_source]).to be_an Array
      end

      it 'strips off raw exception info from the payload' do
        simulate_exception
        expect(fakehoney.events[0].data).to_not include(:exception, :exception_object)
      end
    end

    describe 'with config.capture_exceptions = false' do
      before(:all) { HoneycombRails.config.capture_exceptions = false }
      after(:all) { HoneycombRails.reset_config_to_default! }

      it 'does not capture the exception class and message' do
        simulate_exception

        expect(fakehoney.events[0].data).to_not include(:exception_class, :exception_message)
      end

      it 'records an HTTP status code indicating error' do
        simulate_exception

        expect(fakehoney.events[0].data).to include(status: 500)
      end

      it 'does not record exception_source' do
        simulate_exception
        expect(fakehoney.events[0].data).to_not include(:exception_source)
      end

      it 'strips off raw exception info from the payload' do
        simulate_exception
        expect(fakehoney.events[0].data).to_not include(:exception, :exception_object)
      end
    end

    describe 'with config.capture_exception_backtraces = false' do
      before(:all) { HoneycombRails.config.capture_exception_backtraces = false }
      after(:all) { HoneycombRails.reset_config_to_default! }

      it 'captures the exception class and message' do
        simulate_exception

        expect(fakehoney.events[0].data).to include(
          exception_class: 'RuntimeError',
          exception_message: 'Oops',
        )
      end

      it 'records an HTTP status code indicating error' do
        simulate_exception

        expect(fakehoney.events[0].data).to include(status: 500)
      end

      it 'does not record exception_source' do
        simulate_exception
        expect(fakehoney.events[0].data).to_not include(:exception_source)
      end

      it 'strips off raw exception info from the payload' do
        simulate_exception
        expect(fakehoney.events[0].data).to_not include(:exception, :exception_object)
      end
    end
  end

  describe 'sample_rate' do
    after { HoneycombRails.reset_config_to_default! }

    it 'samples events if set to > 1' do
      old_seed = srand 1227
      HoneycombRails.config.sample_rate = 3
      simulate_event
      simulate_event
      srand old_seed

      expect(fakehoney.events.size).to eq 1
      event = fakehoney.events[0]

      expect(event.sample_rate).to eq 3
    end

    it 'does not sample events if set to 0' do
      HoneycombRails.config.sample_rate = 0

      simulate_event
      simulate_event

      expect(fakehoney.events.size).to eq 2
      expect(fakehoney.events[0].sample_rate).to eq 1
    end

    it 'does not sample events if set to 1' do
      HoneycombRails.config.sample_rate = 1

      simulate_event
      simulate_event

      expect(fakehoney.events.size).to eq 2
      expect(fakehoney.events[0].sample_rate).to eq 1
    end

    it 'does not sample events if set to a non-Integer' do
      HoneycombRails.config.sample_rate = 0.5

      simulate_event
      simulate_event

      expect(fakehoney.events.size).to eq 2
      expect(fakehoney.events[0].sample_rate).to eq 1
    end

    it 'samples events dynamically if passed a Proc' do
      HoneycombRails.config.sample_rate = Proc.new do |payload|
        payload[:should_use_sample_rate]
      end
      old_seed = srand 1203
      simulate_event(payload: {should_use_sample_rate: 3})
      simulate_event(payload: {should_use_sample_rate: 3})
      simulate_event(payload: {should_use_sample_rate: 3})
      simulate_event(payload: {should_use_sample_rate: 1})
      simulate_event(payload: {should_use_sample_rate: 1})
      srand old_seed

      expect(fakehoney.events.size).to eq 3

      expect(fakehoney.events.map(&:sample_rate)).to eq [3, 1, 1]
    end
  end
end
