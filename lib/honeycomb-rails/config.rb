module HoneycombRails
  # Configuration for the Honeycomb Rails integration.
  #
  # Specify this at app initialization time via {configure}.
  class Config
    def initialize
      @dataset = 'rails'
      @db_dataset = 'active_record'
      @record_flash = false
      @record_user = :detect
      @capture_exceptions = true
      @capture_exception_backtraces = true
      @sample_rate = 1
    end

    # Whether to record flash messages (default: true).
    attr_writer :record_flash
    # Whether to record flash messages (default: true).
    def record_flash?
      !!@record_flash
    end

    # If set, routes HoneycombRails-specific log output to this logger
    # (defaults to Rails.logger)
    attr_accessor :logger

    # If set, determines how to record the current user during request processing (default: :detect). Set to nil or false to disable.
    #
    # Valid values:
    #
    # * :devise - if your app uses Devise for authentication
    # * :devise_api - if your app uses Devise for authentication in an 'api' namespace
    # * :detect - autodetect how to determine the current user
    # * nil, false - disable recording current user
    #
    # You can also pass a Proc, which will be called with the current controller
    # instance during each request, and which should return a hash of metadata
    # about the current user.
    attr_accessor :record_user

    # Override the default Libhoney::Client used to send events to Honeycomb.
    # If this is specified, {#writekey} will be ignored.
    # @api private
    attr_accessor :client

    # Send request events to the Honeycomb dataset with this name (default:
    # 'rails'). Set to nil or an empty string to disable.
    attr_accessor :dataset

    # Send ActiveRecord query events to the Honeycomb dataset with this name
    # (default: 'active_record'). Set to nil or empty string to disable.
    attr_accessor :db_dataset

    # The Honeycomb write key for your team (must be specified).
    attr_accessor :writekey

    # @!attribute sample_rate
    # If set, determines how to record the sample rate for a given Honeycomb
    # event. (default: 1, do not sample)
    #
    # Valid values:
    # * Integer > 1 - sample Honeycomb events at a constant rate
    # * 1 - disable sampling on this dataset; capture all events
    #
    # You can also pass a block, which will be called with the
    # event type and the ActiveSupport::Notifications payload that was used to
    # populate the Honeycomb event, and which should return a sample rate for
    # the request or database query in question. For example, to sample
    # successful (200) requests and read (SELECT) queries at 100:1 and all other
    # requests at 1:1:
    #
    # @example Dynamic sampling with a block
    #   config.sample_rate do |event_type, payload|
    #     case event_type
    #     when 'sql.active_record'
    #       if payload[:sql] =~ /^SELECT/
    #         100
    #       else
    #         1
    #       end
    #     when 'process_action.action_controller'
    #       if payload[:status] == 200
    #         100
    #       else
    #         1
    #       end
    #     end
    #   end

    attr_writer :sample_rate

    def sample_rate(&block)
      if block
        self.sample_rate = block
      else
        @sample_rate
      end
    end

    # If set to true, captures exception class name / message along with Rails
    # request events. (default: true)
    attr_accessor :capture_exceptions

    # If set to true, captures backtraces when capturing exception metadata.
    # No-op if capture_exceptions is false. (default: true)
    attr_accessor :capture_exception_backtraces
  end

  class << self
    # @api private
    def config
      @config ||= Config.new
    end

    # For test use only
    # @api private
    def reset_config_to_default!
      @config = Config.new
    end
  end
end
