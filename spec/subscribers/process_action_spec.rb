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

  it 'massages the "format" property' do
    simulate_event(payload: {format: 'format:*/*'})

    expect(fakehoney.events[0].data).to include(format: 'all')
  end

  it 'merges in metadata from :honeycomb_metadata' do
    simulate_event(payload: {honeycomb_metadata: {user_id: 42}})

    expect(fakehoney.events[0].data).to include(user_id: 42)
  end
end
