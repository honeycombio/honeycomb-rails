require 'honeycomb-rails/subscribers/active_record'

RSpec.describe HoneycombRails::Subscribers::ActiveRecord do
  let(:fakehoney) { Libhoney::TestClient.new }

  subject { described_class.new(fakehoney) }

  FakeBind = Struct.new(:name, :value)

  def simulate_event(start: Time.now, finish: Time.now + 1)
    subject.call(
      'sql.active_record',
      start,
      finish,
      'abcdef0123456',
      {
        sql: 'SELECT "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT ?',
        name: 'User Load',
        connection_id: 42,
        statement_name: nil,
        binds: [FakeBind.new('LIMIT', 1)],
      },
    )
  end

  it 'sends an event describing the query run' do
    simulate_event

    expect(fakehoney.events.size).to eq 1
    event = fakehoney.events[0]

    expect(event.data).to include(sql: /SELECT/, name: 'User Load')
  end

  it 'records the query duration in the event' do
    start = Time.now
    finish = start + 2
    simulate_event(start: start, finish: finish)

    expect(fakehoney.events[0].data).to include(duration: 2000)
  end

  it 'records the query binds in the event' do
    simulate_event

    expect(fakehoney.events[0].data).to include(bind_LIMIT: 1)
  end

  it 'records information about the location in the code that made the query' do
    simulate_event

    expect(fakehoney.events[0].data).to include(:local_stack)
  end
end
