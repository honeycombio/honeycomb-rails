require 'honeycomb-rails/subscribers/active_record'

RSpec.describe HoneycombRails::Subscribers::ActiveRecord do
  let(:fakehoney) { Libhoney::TestClient.new }

  subject { described_class.new(fakehoney) }

  FakeBind = Struct.new(:name, :value)

  let(:test_payload) { {
    sql: 'SELECT "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT ?',
    name: 'User Load',
    connection_id: 42,
    statement_name: nil,
    binds: [FakeBind.new('LIMIT', 1)],
  } }

  def simulate_event(payload: {}, start: Time.now, finish: Time.now + 1)
    subject.call(
      'sql.active_record',
      start,
      finish,
      'abcdef0123456',
      test_payload.merge(payload),
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
