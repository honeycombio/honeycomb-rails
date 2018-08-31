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
    attr_reader :honeycomb_metadata, :logger

    def initialize
      @honeycomb_metadata = {}
      @logger = FakeLogger.new
    end

    include FakeInstrumentation
    include HoneycombRails::Overrides::ActionControllerInstrumentation
  end
  class FakeAuthenticatedController < FakeController
    # Devise-like #current_user method
    attr_accessor :current_user
  end
  class FakeAuthenticatedAPIController < FakeController
    # Simulate a particular configuration of Devise that has a
    # #current_api_user method
    attr_accessor :current_api_user
  end

  let(:payload) { {} }
  subject { FakeController.new }

  it 'adds whatever is present in #honeycomb_metadata' do
    subject.honeycomb_metadata[:argle] = :bargle

    subject.append_info_to_payload(payload)

    expect(payload).to include(:honeycomb_metadata)
    expect(payload[:honeycomb_metadata]).to include(argle: :bargle)
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

  describe 'Devise-like controller in an API configuration with #current_api_user' do
    subject { FakeAuthenticatedAPIController.new }

    describe 'if config.record_user is :devise_api' do
      before { HoneycombRails.config.record_user = :devise_api }

      it 'adds information about the current user if set' do
        subject.current_api_user = User.new(42, 'test@example.com', true)

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
        subject.current_api_user = User.new(42, 'test@example.com', true)

        subject.append_info_to_payload(payload)

        expect(payload).to include(:honeycomb_metadata)
        expect(payload[:honeycomb_metadata]).to include(current_user_id: 42)
        expect(payload[:honeycomb_metadata]).to include(current_user_email: 'test@example.com')
        expect(payload[:honeycomb_metadata]).to include(current_user_admin: true)
      end

      it 'sets config.record_user to :devise_api for the next run' do
        subject.append_info_to_payload(payload)
        expect(HoneycombRails.config.record_user).to eq :devise_api
      end
    end

    describe 'if config.record_user is nil' do
      before { HoneycombRails.config.record_user = nil }

      it 'does not record the current user even if set' do
        subject.current_api_user = User.new(42, 'test@example.com', true)

        subject.append_info_to_payload(payload)

        expect(payload).to include(:honeycomb_metadata)
        expect(payload[:honeycomb_metadata]).to_not include(:current_user_id, :current_user_email, :current_user_admin)
      end
    end

    describe 'if config.record_user is false' do
      before { HoneycombRails.config.record_user = false }

      it 'does not record the current user even if set' do
        subject.current_api_user = User.new(42, 'test@example.com', true)

        subject.append_info_to_payload(payload)

        expect(payload).to include(:honeycomb_metadata)
        expect(payload[:honeycomb_metadata]).to_not include(:current_user_id, :current_user_email, :current_user_admin)
      end
    end
  end
end
