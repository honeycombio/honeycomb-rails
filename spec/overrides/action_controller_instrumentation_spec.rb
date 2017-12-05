require 'honeycomb-rails/overrides/action_controller_instrumentation'

RSpec.describe HoneycombRails::Overrides::ActionControllerInstrumentation do
    after { HoneycombRails.reset_config_to_default! }

  # set up conditions this override expects from a real ActionController

  User = Struct.new(:id, :email, :admin?)

  module FakeInstrumentation
    def append_info_to_payload(payload)
    end
  end
  class FakeLogger < Array
    def error(message)
      push(message)
    end
  end
  class FakeController
    attr_reader :flash, :honeycomb_metadata, :logger

    # Noop so we can test honeycomb_attach_exception_metadata in peace
    def self.around_action(*args); end

    def initialize
      @honeycomb_metadata = {}
      @flash = {}
      @logger = FakeLogger.new
    end

    include FakeInstrumentation
    include HoneycombRails::Overrides::ActionControllerInstrumentation
    include HoneycombRails::Overrides::ActionControllerFilters
  end
  class FakeAuthenticatedController < FakeController
    # Devise-like #current_user method
    attr_accessor :current_user
  end

  let(:payload) { {} }
  subject { FakeController.new }

  it 'adds whatever is present in #honeycomb_metadata' do
    subject.honeycomb_metadata[:argle] = :bargle

    subject.append_info_to_payload(payload)

    expect(payload).to include(:honeycomb_metadata)
    expect(payload[:honeycomb_metadata]).to include(argle: :bargle)
  end

  it 'adds the flash alert to the payload if present' do
    subject.flash[:alert] = 'The missiles, they are coming'

    subject.append_info_to_payload(payload)

    expect(payload).to include(:honeycomb_metadata)
    expect(payload[:honeycomb_metadata]).to include(flash_alert: 'The missiles, they are coming')
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

  describe 'when capturing exceptions by default' do
    it 'should captures the exception metadata' do
      caught = false
      begin
        subject.honeycomb_attach_exception_metadata do
            raise RuntimeError, 'kaboom!'
        end
      rescue Exception => e
        caught = true
      end

      expect(caught).to eq true
      expect(subject.honeycomb_metadata).to include(exception_class: 'RuntimeError')
      expect(subject.honeycomb_metadata).to include(exception_message: 'kaboom!')
    end
  end

  describe 'if config.record_flash is false' do
    before { HoneycombRails.config.record_flash = false }

    it 'does not record the flash' do
      subject.flash[:alert] = 'The missiles, they are coming'
      subject.flash[:error] = 'Invalid email address'
      subject.flash[:notice] = 'Fired ze missiles.'

      subject.append_info_to_payload(payload)

      expect(payload).to include(:honeycomb_metadata)
      expect(payload[:honeycomb_metadata]).to_not include(:flash_alert, :flash_error, :flash_notice)
    end
  end

  describe 'controller without #current_user' do
    describe 'if config.record_user is :detect' do
      before { HoneycombRails.config.record_user = :detect }

      it 'does not record the current user even if set' do
        subject.append_info_to_payload(payload)

        expect(payload).to include(:honeycomb_metadata)
        expect(payload[:honeycomb_metadata]).to_not include(:current_user_id, :current_user_email, :current_user_admin)
      end

      it 'logs the detection failure' do
        subject.append_info_to_payload(payload)
        expect(subject.logger).to include(/detect.*user/i)
      end

      it 'sets config.record_user to false for the next run' do
        subject.append_info_to_payload(payload)
        expect(HoneycombRails.config.record_user).to eq false
      end
    end
  end

  describe 'Devise-like controller with #current_user' do
    subject { FakeAuthenticatedController.new }

    describe 'if config.record_user is :devise' do
      before { HoneycombRails.config.record_user = :devise }

      it 'adds information about the current user if set' do
        subject.current_user = User.new(42, 'test@example.com', true)

        subject.append_info_to_payload(payload)

        expect(payload).to include(:honeycomb_metadata)
        expect(payload[:honeycomb_metadata]).to include(current_user_id: 42)
        expect(payload[:honeycomb_metadata]).to include(current_user_email: 'test@example.com')
        expect(payload[:honeycomb_metadata]).to include(current_user_admin: true)
      end
    end

    describe 'if config.record_user is :detect' do
      before { HoneycombRails.config.record_user = :detect }

      it 'adds information about the current user if set' do
        subject.current_user = User.new(42, 'test@example.com', true)

        subject.append_info_to_payload(payload)

        expect(payload).to include(:honeycomb_metadata)
        expect(payload[:honeycomb_metadata]).to include(current_user_id: 42)
        expect(payload[:honeycomb_metadata]).to include(current_user_email: 'test@example.com')
        expect(payload[:honeycomb_metadata]).to include(current_user_admin: true)
      end

      it 'sets config.record_user to :devise for the next run' do
        subject.append_info_to_payload(payload)
        expect(HoneycombRails.config.record_user).to eq :devise
      end
    end

    describe 'if config.record_user is nil' do
      before { HoneycombRails.config.record_user = nil }

      it 'does not record the current user even if set' do
        subject.current_user = User.new(42, 'test@example.com', true)

        subject.append_info_to_payload(payload)

        expect(payload).to include(:honeycomb_metadata)
        expect(payload[:honeycomb_metadata]).to_not include(:current_user_id, :current_user_email, :current_user_admin)
      end
    end

    describe 'if config.record_user is false' do
      before { HoneycombRails.config.record_user = false }

      it 'does not record the current user even if set' do
        subject.current_user = User.new(42, 'test@example.com', true)

        subject.append_info_to_payload(payload)

        expect(payload).to include(:honeycomb_metadata)
        expect(payload[:honeycomb_metadata]).to_not include(:current_user_id, :current_user_email, :current_user_admin)
      end
    end

    describe 'if config.record_user is a block' do
      before do
        HoneycombRails.config.record_user = ->(controller) {
          {logged_in: !!controller.current_user}
        }
      end

      it 'runs the block on the controller instance to populate the metadata' do
        subject.current_user = User.new(42, 'test@example.com', true)

        subject.append_info_to_payload(payload)

        expect(payload).to include(:honeycomb_metadata)
        expect(payload[:honeycomb_metadata]).to include(logged_in: true)
      end
    end
  end
end
