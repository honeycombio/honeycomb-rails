module HoneycombRails
  # Configuration for the Honeycomb Rails integration.
  #
  # Specify this at app initialization time via {configure}.
  class Config
    def initialize
      @dataset = 'rails'
      @db_dataset = 'active_record'
      @record_flash = true
      @record_user = :detect
      @logger = Rails.logger
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
    # * :detect - autodetect how to determine the current user
    # * nil, false - disable recording current user
    #
    # You can also pass a Proc, which will be called with the current controller
    # instance during each request, and which should return a hash of metadata
    # about the current user.
    attr_accessor :record_user

    # Send request events to the Honeycomb dataset with this name (default:
    # 'rails'). Set to nil or an empty string to disable.
    attr_accessor :dataset

    # Send ActiveRecord query events to the Honeycomb dataset with this name
    # (default: 'active_record'). Set to nil or empty string to disable.
    attr_accessor :db_dataset

    # The Honeycomb write key for your team (must be specified).
    attr_accessor :writekey
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
