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
    end

    # Whether to record flash messages.
    attr_writer :record_flash
    # Whether to record flash messages.
    def record_flash?
      !!@record_flash
    end

    # If set, determines how to record the current user during request processing. Set to `nil` or `false` to disable.
    #
    # Valid values:
    #
    #  * `:devise` - if your app uses Devise for authentication
    #  * `:detect` - autodetect how to determine the current user
    #  * `nil`, `false` - disable recording current user
    #
    # You can also pass a Proc, which will be called with the current controller
    # instance during each request, and which should return a hash of metadata
    # about the current user.
    attr_accessor :record_user

    # The Honeycomb dataset to send request events to.
    attr_accessor :dataset
    # The Honeycomb dataset to send ActiveRecord query events to.
    attr_accessor :db_dataset
    # The Honeycomb write key for your team.
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
