module HoneycombRails
  class Config
    def initialize
      @record_flash = true
      @record_user = :detect
    end

    attr_writer :record_flash
    def record_flash?
      !!@record_flash
    end

    attr_accessor :record_user
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