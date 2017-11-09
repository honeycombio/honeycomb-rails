require 'honeycomb-rails/overrides/action_controller_instrumentation'

RSpec.describe HoneycombRails::Overrides::ActionControllerInstrumentation do
  # set up conditions this override expects from a real ActionController

  User = Struct.new(:id, :email, :admin?)

  module FakeInstrumentation
    def append_info_to_payload(payload)
    end
  end
  class FakeController
    attr_reader :flash, :honeycomb_metadata
    attr_accessor :current_user

    def initialize
      @honeycomb_metadata = {}
      @flash = {}
    end

    include FakeInstrumentation
    include HoneycombRails::Overrides::ActionControllerInstrumentation
  end

  let(:payload) { {} }
  subject { FakeController.new }

  it 'adds whatever is present in #honeycomb_metadata' do
    subject.honeycomb_metadata[:argle] = :bargle

    subject.append_info_to_payload(payload)

    expect(payload).to include(:honeycomb_metadata)
    expect(payload[:honeycomb_metadata]).to include(argle: :bargle)
  end

  it 'adds the flash error to the payload if present' do
    subject.flash[:error] = 'Invalid email address'

    subject.append_info_to_payload(payload)

    expect(payload).to include(:honeycomb_metadata)
    expect(payload[:honeycomb_metadata]).to include(flash_error: 'Invalid email address')
  end

  it 'adds the flash notice to the payload if present' do
    subject.flash[:notice] = 'Fired ze missiles.'

    subject.append_info_to_payload(payload)

    expect(payload).to include(:honeycomb_metadata)
    expect(payload[:honeycomb_metadata]).to include(flash_notice: 'Fired ze missiles.')
  end

  it 'adds information about the current user if set' do
    subject.current_user = User.new(42, 'test@example.com', true)

    subject.append_info_to_payload(payload)

    expect(payload).to include(:honeycomb_metadata)
    expect(payload[:honeycomb_metadata]).to include(current_user_id: 42)
    expect(payload[:honeycomb_metadata]).to include(current_user_email: 'test@example.com')
    expect(payload[:honeycomb_metadata]).to include(current_user_admin: true)
  end
end
