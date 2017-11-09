if !defined?(Rails)
  raise LoadError, 'honeycomb-rails requires Rails (maybe you meant libhoney?)'
end

require 'honeycomb-rails/config'

module HoneycombRails
  class << self
    # Run this at app initialization time to configure honeycomb-rails. e.g.
    #
    #     HoneycombRails.configure do |conf|
    #       conf.writekey = 'abc123def'
    #     end
    #
    # See {Config} for available options.
    #
    # @yield [Config] the singleton config.
    def configure
      raise "Please pass a block to #{name}#configure" unless block_given?

      yield config
      config
    end
  end
end

require 'honeycomb-rails/railtie'
