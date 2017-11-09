if !defined?(Rails)
  raise LoadError, 'honeycomb-rails requires Rails (maybe you meant libhoney?)'
end

require 'honeycomb-rails/config'

module HoneycombRails
  class << self
    def configure
      raise "Please pass a block to #{name}#configure" unless block_given?

      yield config
      config
    end
  end
end

require 'honeycomb-rails/railtie'
